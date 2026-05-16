--[[
    HasuCC_Data.lua — Hasu's Interrupt Tracker
    Spec-specific CC ability data with talent conditions.

    Provides:
      HasuCCData.SPEC_CC_DATA       — per-specID list of CC abilities
      HasuCCData.CC_SPELL_LOOKUP    — flat spellID → {name,class,dr,baseCd} map
      HasuCCData.FindMyCCAbilities  — populate ccAddonUsers[myName] from spellbook + talent tree

    Each SPEC_CC_DATA entry:
      spellID                : WoW spell ID
      name                   : English display name (localized names come from the spell itself)
      baseCd                 : Fallback CD in seconds (0 = no CD / no timer needed)
                               For self, GetSpellBaseCooldown() is used instead (reflects talents).
      requireTalent          : (optional) talent spellID — only show this CC if the talent is active
      extraChargeTalent      : (optional) talent spellID — if active, maxCharges = 2
      cooldownReducingTalent : (optional) talent spellID — if active, reduce the CD by cdReduction
      cdReduction            : (optional) seconds to subtract from baseCd when cooldownReducingTalent
                               is active. If specified, the reduced CD is used even if
                               GetSpellBaseCooldown doesn't reflect the talent reduction.
      cooldownReducingTalent2: (optional) SECOND talent that also reduces CD. Used when multiple
                               talents can reduce the same spell (e.g. Holy Priest: Châtiment +
                               Nova sacrée both reduce Holy Word: Chastise).
      cdReduction2           : (optional) reduction for cooldownReducingTalent2.
      cdNullifyTalent        : (optional) talent that makes the spell instant (CD ≈ 1s).
                               e.g. DK Death Grip: Portée de la mort (276079) makes Death Grip have no CD.
                               e.g. Paladin Turn Evil: Renvoi du mal (460720) makes Turn Evil instant.
      replacedByTalent       : (optional) if this talent is active, HIDE this spell (replaced by another).
                               e.g. Mage Cone of Cold replaced by Ice Nova when Froid glacial active.
                               e.g. DH Vengeance Sigil of Misery replaced by Sigil of Chains.
      castTime               : (optional) cast/incantation time in seconds. When the player starts
                               casting this spell (UNIT_SPELLCAST_START), the CC bar displays this
                               countdown so the team can see the cast progress.
                               e.g. Mage Polymorph: 1.5s cast time.
]]

HasuCCData = HasuCCData or {}

-- Forward declaration so FindMyCCAbilities (defined below) can resolve
-- IsPlayerTalent and GetPlayerTalentRank as upvalues instead of (nil)
-- global lookups. Without this, the closure captures nil at compile time
-- and crashes with "attempt to call a nil value" when invoked.
local IsPlayerTalent
local GetPlayerTalentRank

-- ============================================================
--  SPEC_CC_DATA
--  SpecID → ordered list of CC ability definitions.
--  Interrupts are included here so the CC window shows a
--  complete picture of a player's utility.
-- ============================================================
HasuCCData.SPEC_CC_DATA = {

    -- ── DEATH KNIGHT ─────────────────────────────────────────
    -- Blood = 250 | Frost = 251 | Unholy = 252
    -- ─────────────────────────────────────────────────────────
    [250] = { -- Blood DK
        { spellID = 47528,   name = "Mind Freeze",         baseCd = 15,
          cooldownReducingTalent = 378848, cdReduction = 3 }, -- Soif algide
        { spellID = 45524,   name = "Chains of Ice",       baseCd = 12,
          requireTalent = 204485 }, -- Frozen Prison talent required
        { spellID = 221562,  name = "Asphyxiate",          baseCd = 45  },
        { spellID = 49576,   name = "Death Grip",          baseCd = 15,
          extraChargeTalent = 356367, -- Écho de la mort
          cdNullifyTalent = 276079 }, -- Portée de la mort: instant
        { spellID = 43265,   name = "Death and Decay",     baseCd = 15,
          requireTalent = 273952,
          extraChargeTalent = 356367 }, -- Poigne des morts (Blood: 15s), 2 charges avec Écho de la mort
        { spellID = 207167,  name = "Blinding Sleet",      baseCd = 60  },
        { spellID = 108199,  name = "Grip of the Undying", baseCd = 90  },
        { spellID = 1263569, name = "Abominable Limb",     baseCd = 120 },
    },
    [251] = { -- Frost DK
        { spellID = 47528,   name = "Mind Freeze",         baseCd = 15,
          cooldownReducingTalent = 378848, cdReduction = 3 },
        { spellID = 45524,   name = "Chains of Ice",       baseCd = 12,
          requireTalent = 204485 }, -- Frozen Prison talent required
        { spellID = 221562,  name = "Asphyxiate",          baseCd = 45  },
        { spellID = 49576,   name = "Death Grip",          baseCd = 15,
          extraChargeTalent = 356367,
          cdNullifyTalent = 276079 }, -- Portée de la mort: instant
        { spellID = 43265,   name = "Death and Decay",     baseCd = 30,
          requireTalent = 273952,
          extraChargeTalent = 356367,
          forceBaseCd = true }, -- Frost: 30s, 2 charges avec Écho de la mort
        { spellID = 207167,  name = "Blinding Sleet",      baseCd = 60  },
    },
    [252] = { -- Unholy DK
        { spellID = 47528,   name = "Mind Freeze",         baseCd = 15,
          cooldownReducingTalent = 378848, cdReduction = 3 },
        { spellID = 45524,   name = "Chains of Ice",       baseCd = 12,
          requireTalent = 204485 }, -- Frozen Prison talent required
        { spellID = 221562,  name = "Asphyxiate",          baseCd = 45  },
        { spellID = 49576,   name = "Death Grip",          baseCd = 15,
          extraChargeTalent = 356367,
          cdNullifyTalent = 276079 }, -- Portée de la mort: instant
        { spellID = 43265,   name = "Death and Decay",     baseCd = 25,
          requireTalent = 273952,
          extraChargeTalent = 356367,
          forceBaseCd = true }, -- Unholy: 25s, 2 charges avec Écho de la mort
        { spellID = 207167,  name = "Blinding Sleet",      baseCd = 60  },
    },

    -- ── PALADIN ──────────────────────────────────────────────
    -- Holy = 65 | Protection = 66 | Retribution = 70
    -- ─────────────────────────────────────────────────────────
    [70] = { -- Retribution Paladin (Vindicte)
        { spellID = 96231,   name = "Rebuke",              baseCd = 15  },
        { spellID = 853,     name = "Hammer of Justice",   baseCd = 45,
          cooldownReducingTalent = 234299, cdReduction = 15 },
        { spellID = 115750,  name = "Blinding Light",      baseCd = 90,
          cooldownReducingTalent = 469325, cdReduction = 15 },
        { spellID = 10326,   name = "Turn Evil",           baseCd = 15,
          cdNullifyTalent = 460720 }, -- Renvoi du mal amélioration: rend instantané
    },
    [66] = { -- Protection Paladin
        { spellID = 96231,   name = "Rebuke",              baseCd = 15  },
        { spellID = 853,     name = "Hammer of Justice",   baseCd = 45,
          cooldownReducingTalent = 234299, cdReduction = 15 },
        { spellID = 115750,  name = "Blinding Light",      baseCd = 90,
          cooldownReducingTalent = 469325, cdReduction = 15 },
        { spellID = 10326,   name = "Turn Evil",           baseCd = 15,
          cdNullifyTalent = 460720 }, -- Renvoi du mal amélioration: rend instantané
        { spellID = 375576,  name = "Divine Toll",         baseCd = 60,
          cooldownReducingTalent = 379391, cdReduction = 15 },
        { spellID = 31935,   name = "Avenger's Shield",    baseCd = 15  },
    },
    [65] = { -- Holy Paladin (Sacré) — no Rebuke
        { spellID = 853,     name = "Hammer of Justice",   baseCd = 45,
          cooldownReducingTalent = 234299, cdReduction = 15 },
        { spellID = 115750,  name = "Blinding Light",      baseCd = 90,
          cooldownReducingTalent = 469325, cdReduction = 15 },
        { spellID = 10326,   name = "Turn Evil",           baseCd = 15,
          cdNullifyTalent = 460720 }, -- Renvoi du mal amélioration: rend instantané
    },

    -- ── MAGE ─────────────────────────────────────────────────
    -- Arcane = 62 | Fire = 63 | Frost = 64
    -- ─────────────────────────────────────────────────────────
    [62] = { -- Arcane Mage
        { spellID = 2139,    name = "Counterspell",        baseCd = 25,
          cooldownReducingTalent = 382297, cdReduction = 5 },
        { spellID = 122,     name = "Frost Nova",          baseCd = 30,
          extraChargeTalent = 205036 },
        { spellID = 118,     name = "Polymorph",           baseCd = 0, castTime = 1.5,
          cdNullifyTalent = 205036 }, -- Icy Veins makes it instant (no cast time)
        { spellID = 113724,  name = "Ring of Frost",       baseCd = 45  },
        { spellID = 383121,  name = "Mass Polymorph",      baseCd = 60  },
        { spellID = 31661,   name = "Dragon's Breath",     baseCd = 45  },
        { spellID = 157980,  name = "Supernova",           baseCd = 45  },
        { spellID = 120,     name = "Cone of Cold",        baseCd = 25,
          replacedByTalent = 386763 }, -- Hidden if Froid glacial active (Ice Nova replaces)
        { spellID = 157997,  name = "Ice Nova",            baseCd = 25,
          requireTalent = 386763 },
    },
    [63] = { -- Fire Mage
        { spellID = 2139,    name = "Counterspell",        baseCd = 25,
          cooldownReducingTalent = 382297, cdReduction = 5 },
        { spellID = 122,     name = "Frost Nova",          baseCd = 30,
          extraChargeTalent = 205036 },
        { spellID = 118,     name = "Polymorph",           baseCd = 0, castTime = 1.5,
          cdNullifyTalent = 205036 }, -- Icy Veins makes it instant (no cast time)
        { spellID = 113724,  name = "Ring of Frost",       baseCd = 45  },
        { spellID = 383121,  name = "Mass Polymorph",      baseCd = 60  },
        { spellID = 31661,   name = "Dragon's Breath",     baseCd = 45  },
        { spellID = 157980,  name = "Supernova",           baseCd = 45  },
        { spellID = 120,     name = "Cone of Cold",        baseCd = 25,
          replacedByTalent = 386763 }, -- Hidden if Froid glacial active (Ice Nova replaces)
        { spellID = 157997,  name = "Ice Nova",            baseCd = 25,
          requireTalent = 386763 },
    },
    [64] = { -- Frost Mage
        { spellID = 2139,    name = "Counterspell",        baseCd = 25,
          cooldownReducingTalent = 382297, cdReduction = 5 },
        { spellID = 122,     name = "Frost Nova",          baseCd = 30,
          extraChargeTalent = 205036 },
        { spellID = 118,     name = "Polymorph",           baseCd = 0, castTime = 1.5,
          cdNullifyTalent = 205036 }, -- Icy Veins makes it instant (no cast time)
        { spellID = 113724,  name = "Ring of Frost",       baseCd = 45  },
        { spellID = 383121,  name = "Mass Polymorph",      baseCd = 60  },
        { spellID = 31661,   name = "Dragon's Breath",     baseCd = 45  },
        { spellID = 157980,  name = "Supernova",           baseCd = 45  },
        { spellID = 120,     name = "Cone of Cold",        baseCd = 25,
          replacedByTalent = 386763 }, -- Hidden if Froid glacial active (Ice Nova replaces)
        { spellID = 157997,  name = "Ice Nova",            baseCd = 25,
          requireTalent = 386763 },
    },

    -- ── DEMON HUNTER ─────────────────────────────────────────
    -- Havoc = 577 | Vengeance = 581 | Dévoration = 1480
    -- ─────────────────────────────────────────────────────────
    [577] = { -- Havoc DH (Dévastation) — uses Chaos Nova (NOT Void Nova)
        { spellID = 183752,  name = "Disrupt",             baseCd = 15  },
        { spellID = 179057,  name = "Chaos Nova",          baseCd = 60  },
        { spellID = 217832,  name = "Imprison",            baseCd = 45  },
        { spellID = 207684,  name = "Sigil of Misery",     baseCd = 120,
          cooldownReducingTalent = 320418, cdReduction = 30 }, -- Sceau Amélioré
    },
    [581] = { -- Vengeance DH — uses Chaos Nova, has Sigil of Chains + Silence
        { spellID = 183752,  name = "Disrupt",             baseCd = 15  },
        { spellID = 179057,  name = "Chaos Nova",          baseCd = 60  },
        { spellID = 217832,  name = "Imprison",            baseCd = 45  },
        { spellID = 207684,  name = "Sigil of Misery",     baseCd = 120,
          cooldownReducingTalent = 320418, cdReduction = 30 },
        { spellID = 202138,  name = "Sigil of Chains",     baseCd = 90  }, -- Sigil de chaînes
        { spellID = 202137,  name = "Sigil of Silence",    baseCd = 90  }, -- Sigil de silence (1.5 min)
    },
    [1480] = { -- Dévoration DH — uses Void Nova INSTEAD of Chaos Nova (WoW 12.0 Midnight)
        { spellID = 183752,  name = "Disrupt",             baseCd = 15  },
        { spellID = 1234195, name = "Void Nova",           baseCd = 60  },
        { spellID = 217832,  name = "Imprison",            baseCd = 45  },
        { spellID = 207684,  name = "Sigil of Misery",     baseCd = 120,
          cooldownReducingTalent = 320418, cdReduction = 30 },
    },

    -- ── EVOKER ───────────────────────────────────────────────
    -- Devastation = 1467 | Preservation = 1468 | Augmentation = 1473
    -- ─────────────────────────────────────────────────────────
    [1473] = { -- Augmentation Evoker
        { spellID = 372048,  name = "Oppressive Roar",     baseCd = 90,
          cooldownReducingTalent = 374346, cdReduction = 30, forceShow = true,
          castAliasIDs = { [406971] = true } }, -- Roaring Intimidation modifier
        { spellID = 351338,  name = "Quell",               baseCd = 20  },
        { spellID = 368970,  name = "Tail Swipe",          baseCd = 180,
          cooldownReducingTalent = 375443, cdReduction = 120, forceShow = true },
        { spellID = 357214,  name = "Wing Buffet",         baseCd = 180,
          cooldownReducingTalent = 368838, cdReduction = 120, forceShow = true },
    },
    [1467] = { -- Devastation Evoker
        { spellID = 372048,  name = "Oppressive Roar",     baseCd = 90,
          cooldownReducingTalent = 374346, cdReduction = 30, forceShow = true,
          castAliasIDs = { [406971] = true } }, -- Roaring Intimidation modifier
        { spellID = 351338,  name = "Quell",               baseCd = 20  },
        { spellID = 368970,  name = "Tail Swipe",          baseCd = 180,
          cooldownReducingTalent = 375443, cdReduction = 120, forceShow = true },
        { spellID = 357214,  name = "Wing Buffet",         baseCd = 180,
          cooldownReducingTalent = 368838, cdReduction = 120, forceShow = true },
    },
    [1468] = { -- Preservation Evoker (no Quell)
        { spellID = 372048,  name = "Oppressive Roar",     baseCd = 90,
          cooldownReducingTalent = 374346, cdReduction = 30, forceShow = true,
          castAliasIDs = { [406971] = true } }, -- Roaring Intimidation modifier
        { spellID = 368970,  name = "Tail Swipe",          baseCd = 180,
          cooldownReducingTalent = 375443, cdReduction = 120, forceShow = true },
        { spellID = 357214,  name = "Wing Buffet",         baseCd = 180,
          cooldownReducingTalent = 368838, cdReduction = 120, forceShow = true },
    },

    -- ── MONK ─────────────────────────────────────────────────
    -- Brewmaster = 268 | Windwalker = 269 | Mistweaver = 270
    -- ─────────────────────────────────────────────────────────
    [269] = { -- Windwalker Monk
        { spellID = 116705,  name = "Spear Hand Strike",   baseCd = 15,
          forceBaseCd = true }, -- always 15s, no talent reduction
        { spellID = 115078,  name = "Paralysis",           baseCd = 45,
          extraChargeTalent = 344359,
          cooldownReducingTalent = 344359, cdReduction = 15 },
        { spellID = 119381,  name = "Leg Sweep",           baseCd = 60,
          extraChargeTalent = 344359,
          cooldownReducingTalent = 344359, cdReduction = 10 },
        { spellID = 116844,  name = "Ring of Peace",       baseCd = 45,
          cooldownReducingTalent = 450448, cdReduction = 5 },
        { spellID = 198898,  name = "Song of Chi-Ji",      baseCd = 30  },
    },
    [270] = { -- Mistweaver Monk (no Spear Hand Strike in 12.0)
        { spellID = 115078,  name = "Paralysis",           baseCd = 45,
          extraChargeTalent = 344359,
          cooldownReducingTalent = 344359, cdReduction = 15 },
        { spellID = 119381,  name = "Leg Sweep",           baseCd = 60,
          extraChargeTalent = 344359,
          cooldownReducingTalent = 344359, cdReduction = 10 },
        { spellID = 116844,  name = "Ring of Peace",       baseCd = 45,
          cooldownReducingTalent = 450448, cdReduction = 5 },
        { spellID = 198898,  name = "Song of Chi-Ji",      baseCd = 30  },
    },
    [268] = { -- Brewmaster Monk
        { spellID = 116705,  name = "Spear Hand Strike",   baseCd = 15,
          forceBaseCd = true }, -- always 15s, no talent reduction
        { spellID = 115078,  name = "Paralysis",           baseCd = 45,
          extraChargeTalent = 344359,
          cooldownReducingTalent = 344359, cdReduction = 15 },
        { spellID = 119381,  name = "Leg Sweep",           baseCd = 60,
          extraChargeTalent = 344359,
          cooldownReducingTalent = 344359, cdReduction = 10 },
        { spellID = 116844,  name = "Ring of Peace",       baseCd = 45,
          cooldownReducingTalent = 450448, cdReduction = 5 },
        { spellID = 198898,  name = "Song of Chi-Ji",      baseCd = 30  },
    },

    -- ── WARLOCK ──────────────────────────────────────────────
    -- Affliction = 265 | Demonology = 266 | Destruction = 267
    -- ─────────────────────────────────────────────────────────
    [265] = { -- Affliction Warlock
        { spellID = 119910,  name = "Spell Lock",          baseCd = 25  }, -- Command Demon
        { spellID = 6789,    name = "Mortal Coil",         baseCd = 45  },
        { spellID = 5484,    name = "Howl of Terror",      baseCd = 40  },
        { spellID = 30283,   name = "Shadowfury",          baseCd = 60  },
        { spellID = 1122,    name = "Summon Infernal",     baseCd = 90  },
        { spellID = 5782,    name = "Fear",                baseCd = 2,   -- 1.4s cast time
          requireTalent = 281490 }, -- Requires talent
        { spellID = 710,     name = "Banish",              baseCd = 2,   -- 1.3s cast time
          requireTalent = 281490 },
    },
    [266] = { -- Demonology Warlock
        { spellID = 119910,  name = "Spell Lock",          baseCd = 25  },
        { spellID = 6789,    name = "Mortal Coil",         baseCd = 45  },
        { spellID = 5484,    name = "Howl of Terror",      baseCd = 40  },
        { spellID = 30283,   name = "Shadowfury",          baseCd = 60  },
        { spellID = 1122,    name = "Summon Infernal",     baseCd = 90  },
        { spellID = 5782,    name = "Fear",                baseCd = 2,   -- 1.4s cast time
          requireTalent = 281490 },
        { spellID = 710,     name = "Banish",              baseCd = 2,   -- 1.3s cast time
          requireTalent = 281490 },
    },
    [267] = { -- Destruction Warlock
        { spellID = 119910,  name = "Spell Lock",          baseCd = 25  },
        { spellID = 6789,    name = "Mortal Coil",         baseCd = 45  },
        { spellID = 5484,    name = "Howl of Terror",      baseCd = 40  },
        { spellID = 30283,   name = "Shadowfury",          baseCd = 60  },
        { spellID = 1122,    name = "Summon Infernal",     baseCd = 90  },
        { spellID = 5782,    name = "Fear",                baseCd = 2,   -- 1.4s cast time
          requireTalent = 281490 },
        { spellID = 710,     name = "Banish",              baseCd = 2,   -- 1.3s cast time
          requireTalent = 281490 },
    },

    -- ── DRUID ────────────────────────────────────────────────
    -- Balance = 102 | Feral = 103 | Guardian = 104 | Restoration = 105
    -- ─────────────────────────────────────────────────────────
    [102] = { -- Balance Druid
        { spellID = 78675,   name = "Solar Beam",          baseCd = 60,
          cooldownReducingTalent = 202918, cdReduction = 15 },
        { spellID = 132469,  name = "Typhoon",             baseCd = 30,
          cooldownReducingTalent = 400140, cdReduction = 5 },
        { spellID = 102359,  name = "Mass Entanglement",   baseCd = 30  },
        { spellID = 102793,  name = "Ursol's Vortex",      baseCd = 60  },
        { spellID = 99,      name = "Incapacitating Roar", baseCd = 30  },
        { spellID = 5211,    name = "Mighty Bash",         baseCd = 60  },
        { spellID = 33786,   name = "Cyclone",             baseCd = 2,   -- 1.3s cast time
          requireTalent = 389625 },
        { spellID = 339,     name = "Entangling Roots",    baseCd = 2,   -- 1.3s cast time
          requireTalent = 389625 },
    },
    [103] = { -- Feral Druid
        { spellID = 106839,  name = "Skull Bash",          baseCd = 15  },
        { spellID = 33786,   name = "Cyclone",             baseCd = 2,   -- 1.3s cast time
          requireTalent = 389625 },
        { spellID = 132469,  name = "Typhoon",             baseCd = 30,
          cooldownReducingTalent = 400140, cdReduction = 5 },
        { spellID = 102359,  name = "Mass Entanglement",   baseCd = 30  },
        { spellID = 102793,  name = "Ursol's Vortex",      baseCd = 60  },
        { spellID = 99,      name = "Incapacitating Roar", baseCd = 30  },
        { spellID = 5211,    name = "Mighty Bash",         baseCd = 60  },
        { spellID = 339,     name = "Entangling Roots",    baseCd = 2,   -- 1.3s cast time
          requireTalent = 389625 },
    },
    [104] = { -- Guardian Druid
        { spellID = 106839,  name = "Skull Bash",          baseCd = 15  },
        { spellID = 33786,   name = "Cyclone",             baseCd = 2,   -- 1.3s cast time
          requireTalent = 389625 },
        { spellID = 132469,  name = "Typhoon",             baseCd = 30,
          cooldownReducingTalent = 400140, cdReduction = 5 },
        { spellID = 102359,  name = "Mass Entanglement",   baseCd = 30  },
        { spellID = 102793,  name = "Ursol's Vortex",      baseCd = 60  },
        { spellID = 99,      name = "Incapacitating Roar", baseCd = 30  },
        { spellID = 5211,    name = "Mighty Bash",         baseCd = 60  },
        { spellID = 339,     name = "Entangling Roots",    baseCd = 2,   -- 1.3s cast time
          requireTalent = 389625 },
    },
    [105] = { -- Restoration Druid (no Skull Bash in 12.0)
        { spellID = 33786,   name = "Cyclone",             baseCd = 2,   -- 1.3s cast time
          requireTalent = 389625 },
        { spellID = 132469,  name = "Typhoon",             baseCd = 30,
          cooldownReducingTalent = 400140, cdReduction = 5 },
        { spellID = 102359,  name = "Mass Entanglement",   baseCd = 30  },
        { spellID = 102793,  name = "Ursol's Vortex",      baseCd = 60  },
        { spellID = 99,      name = "Incapacitating Roar", baseCd = 30  },
        { spellID = 5211,    name = "Mighty Bash",         baseCd = 60  },
        { spellID = 339,     name = "Entangling Roots",    baseCd = 2,   -- 1.3s cast time
          requireTalent = 389625 },
    },

    -- ── HUNTER ───────────────────────────────────────────────
    -- Beast Mastery = 253 | Marksmanship = 254 | Survival = 255
    -- ─────────────────────────────────────────────────────────
    [253] = { -- Beast Mastery Hunter
        { spellID = 147362,  name = "Counter Shot",        baseCd = 24,
          forceBaseCd = true }, -- prevent talent from incorrectly reducing CD
        { spellID = 19577,   name = "Intimidation",        baseCd = 60,
          cooldownReducingTalent = 459507, cdReduction = 20 },
        { spellID = 187650,  name = "Freezing Trap",       baseCd = 30,
          cooldownReducingTalent = 343247, cdReduction = 5 },
        { spellID = 109248,  name = "Binding Shot",        baseCd = 45  },
        { spellID = 187698,  name = "Tar Trap",            baseCd = 30,
          cooldownReducingTalent = 343247, cdReduction = 5 },
    },
    [254] = { -- Marksmanship Hunter
        { spellID = 147362,  name = "Counter Shot",        baseCd = 24,
          forceBaseCd = true }, -- prevent talent from incorrectly reducing CD
        { spellID = 474421,  name = "Intimidation (MM)",   baseCd = 60  }, -- Marksmanship-specific Intimidation
        { spellID = 19577,   name = "Intimidation",        baseCd = 60,
          cooldownReducingTalent = 459507, cdReduction = 20 },
        { spellID = 187650,  name = "Freezing Trap",       baseCd = 30,
          cooldownReducingTalent = 343247, cdReduction = 5 },
        { spellID = 109248,  name = "Binding Shot",        baseCd = 45  },
        { spellID = 187698,  name = "Tar Trap",            baseCd = 30,
          cooldownReducingTalent = 343247, cdReduction = 5 },
    },
    [255] = { -- Survival Hunter
        { spellID = 187707,  name = "Muzzle",              baseCd = 15  },
        { spellID = 19577,   name = "Intimidation",        baseCd = 60,
          cooldownReducingTalent = 459507, cdReduction = 20 },
        { spellID = 187650,  name = "Freezing Trap",       baseCd = 30,
          cooldownReducingTalent = 343247, cdReduction = 5 },
        { spellID = 109248,  name = "Binding Shot",        baseCd = 45  },
        { spellID = 187698,  name = "Tar Trap",            baseCd = 30,
          cooldownReducingTalent = 343247, cdReduction = 5 },
    },

    -- ── PRIEST ───────────────────────────────────────────────
    -- Discipline = 256 | Holy = 257 | Shadow = 258
    -- ─────────────────────────────────────────────────────────
    [258] = { -- Shadow Priest
        { spellID = 15487,   name = "Silence",             baseCd = 30  }, -- interrupt
        { spellID = 8122,    name = "Psychic Scream",      baseCd = 40,
          cooldownReducingTalent = 196704, cdReduction = 10 },
        { spellID = 1250691, name = "Void Tendrils",       baseCd = 30,
          requireTalent = 391109 }, -- Shadow-exclusive talent
        { spellID = 9484,    name = "Shackle Undead",      baseCd = 0   },
    },
    [257] = { -- Holy Priest (Sacré) — no Silence, no Void Tendrils
        { spellID = 88625,   name = "Holy Word: Chastise", baseCd = 60,
          cooldownReducingTalent = 585, cdReduction = 4,
          cooldownReducingTalent2 = 132157, cdReduction2 = 4 }, -- Châtiment + Nova sacrée
        { spellID = 8122,    name = "Psychic Scream",      baseCd = 40,
          cooldownReducingTalent = 196704, cdReduction = 10 },
        { spellID = 9484,    name = "Shackle Undead",      baseCd = 0   },
    },
    [256] = { -- Discipline Priest — no Silence, no Void Tendrils
        { spellID = 8122,    name = "Psychic Scream",      baseCd = 40,
          cooldownReducingTalent = 196704, cdReduction = 10 },
        { spellID = 9484,    name = "Shackle Undead",      baseCd = 0   },
    },

    -- ── WARRIOR ──────────────────────────────────────────────
    -- Arms = 71 | Fury = 72 | Protection = 73
    -- ─────────────────────────────────────────────────────────
    [71] = { -- Arms Warrior
        { spellID = 6552,    name = "Pummel",              baseCd = 14  }, -- interrupt
        { spellID = 107570,  name = "Storm Bolt",          baseCd = 27  },
        { spellID = 46968,   name = "Shockwave",           baseCd = 40,
          cooldownReducingTalent = 275339, cdReduction = 15 },
        { spellID = 5246,    name = "Intimidating Shout",  baseCd = 75  },
        { spellID = 12323,   name = "Piercing Howl",       baseCd = 90  },
    },
    [72] = { -- Fury Warrior
        { spellID = 6552,    name = "Pummel",              baseCd = 14  },
        { spellID = 107570,  name = "Storm Bolt",          baseCd = 27  },
        { spellID = 46968,   name = "Shockwave",           baseCd = 40,
          cooldownReducingTalent = 275339, cdReduction = 15 },
        { spellID = 5246,    name = "Intimidating Shout",  baseCd = 75  },
        { spellID = 12323,   name = "Piercing Howl",       baseCd = 90  },
    },
    [73] = { -- Protection Warrior
        { spellID = 6552,    name = "Pummel",              baseCd = 14  },
        { spellID = 107570,  name = "Storm Bolt",          baseCd = 27  },
        { spellID = 46968,   name = "Shockwave",           baseCd = 40,
          cooldownReducingTalent = 275339, cdReduction = 15 },
        { spellID = 5246,    name = "Intimidating Shout",  baseCd = 75  },
        { spellID = 12323,   name = "Piercing Howl",       baseCd = 90  },
        { spellID = 385952,  name = "Shield Charge",       baseCd = 45  }, -- Charge de bouclier
    },

    -- ── SHAMAN ───────────────────────────────────────────────
    -- Elemental = 262 | Enhancement = 263 | Restoration = 264
    -- ─────────────────────────────────────────────────────────
    [262] = { -- Elemental Shaman
        { spellID = 57994,   name = "Wind Shear",          baseCd = 12  }, -- interrupt
        { spellID = 51514,   name = "Hex",                 baseCd = 30,
          cooldownReducingTalent = 204268, cdReduction = 15 }, -- Voodoo Mastery
        { spellID = 192058,  name = "Capacitor Totem",     baseCd = 55,
          extraChargeTalent = 265046,
          cooldownReducingTalent = 265046, cdReductionPerRank = 10 }, -- Charge statique: -10s par rang (rang 1 ou 2)
        { spellID = 51485,   name = "Earthgrab Totem",     baseCd = 25  },
        { spellID = 51490,   name = "Thunderstorm",        baseCd = 30  },
    },
    [263] = { -- Enhancement Shaman
        { spellID = 57994,   name = "Wind Shear",          baseCd = 12  },
        { spellID = 51514,   name = "Hex",                 baseCd = 30,
          cooldownReducingTalent = 204268, cdReduction = 15 }, -- Voodoo Mastery
        { spellID = 192058,  name = "Capacitor Totem",     baseCd = 55,
          extraChargeTalent = 265046,
          cooldownReducingTalent = 265046, cdReductionPerRank = 10 }, -- Charge statique: -10s par rang (rang 1 ou 2)
        { spellID = 51485,   name = "Earthgrab Totem",     baseCd = 25  },
        { spellID = 51490,   name = "Thunderstorm",        baseCd = 30  },
    },
    [264] = { -- Restoration Shaman (30s Wind Shear)
        { spellID = 57994,   name = "Wind Shear",          baseCd = 30  },
        { spellID = 51514,   name = "Hex",                 baseCd = 30,
          cooldownReducingTalent = 204268, cdReduction = 15 }, -- Voodoo Mastery
        { spellID = 192058,  name = "Capacitor Totem",     baseCd = 55,
          extraChargeTalent = 265046,
          cooldownReducingTalent = 265046, cdReductionPerRank = 10 }, -- Charge statique: -10s par rang (rang 1 ou 2)
        { spellID = 51485,   name = "Earthgrab Totem",     baseCd = 25  },
        { spellID = 51490,   name = "Thunderstorm",        baseCd = 30  },
    },

    -- ── ROGUE ────────────────────────────────────────────────
    -- Assassination = 259 | Outlaw = 260 | Subtlety = 261
    -- ─────────────────────────────────────────────────────────
    [259] = { -- Assassination Rogue
        { spellID = 1766,    name = "Kick",                baseCd = 15  }, -- interrupt
        { spellID = 2094,    name = "Blind",               baseCd = 120,
          cooldownReducingTalent = 200733, cdReduction = 60 },
        { spellID = 1776,    name = "Gouge",               baseCd = 25  },
        { spellID = 703,     name = "Garrote (Silence)",   baseCd = 6,
          requireTalent = 196861 }, -- Fil de fer: Garrote silences the target
    },
    [260] = { -- Outlaw Rogue (Hors-la-loi)
        { spellID = 1766,    name = "Kick",                baseCd = 15  },
        { spellID = 2094,    name = "Blind",               baseCd = 120,
          cooldownReducingTalent = 200733, cdReduction = 60 },
        { spellID = 1776,    name = "Gouge",               baseCd = 25  },
    },
    [261] = { -- Subtlety Rogue (Finesse)
        { spellID = 1766,    name = "Kick",                baseCd = 15  },
        { spellID = 2094,    name = "Blind",               baseCd = 120,
          cooldownReducingTalent = 200733, cdReduction = 60 },
        { spellID = 1776,    name = "Gouge",               baseCd = 25  },
    },
}

-- ============================================================
--  CC_SPELL_LOOKUP
--  Flat spellID → {name, class, dr, baseCd} for EVERY spell
--  in SPEC_CC_DATA. Built automatically below.
--  Used by: CCCAST handler (reception), playerCastFrame detection.
-- ============================================================
local CLASS_FOR_SPEC = {
    [250]="DEATHKNIGHT", [251]="DEATHKNIGHT", [252]="DEATHKNIGHT",
    [65]="PALADIN",      [66]="PALADIN",       [70]="PALADIN",
    [62]="MAGE",         [63]="MAGE",          [64]="MAGE",
    [577]="DEMONHUNTER", [581]="DEMONHUNTER", [1480]="DEMONHUNTER",
    [1467]="EVOKER",     [1468]="EVOKER",      [1473]="EVOKER",
    [268]="MONK",        [269]="MONK",         [270]="MONK",
    [265]="WARLOCK",     [266]="WARLOCK",      [267]="WARLOCK",
    [102]="DRUID",       [103]="DRUID",        [104]="DRUID",  [105]="DRUID",
    [253]="HUNTER",      [254]="HUNTER",       [255]="HUNTER",
    [256]="PRIEST",      [257]="PRIEST",        [258]="PRIEST",
    [71]="WARRIOR",      [72]="WARRIOR",        [73]="WARRIOR",
    [262]="SHAMAN",      [263]="SHAMAN",        [264]="SHAMAN",
    [259]="ROGUE",       [260]="ROGUE",         [261]="ROGUE",
}

HasuCCData.CC_SPELL_LOOKUP = {}
for specID, list in pairs(HasuCCData.SPEC_CC_DATA) do
    local cls = CLASS_FOR_SPEC[specID] or "UNKNOWN"
    for _, entry in ipairs(list) do
        local existing = HasuCCData.CC_SPELL_LOOKUP[entry.spellID]
        if not existing then
            HasuCCData.CC_SPELL_LOOKUP[entry.spellID] = {
                name                    = entry.name,
                class                   = cls,
                dr                      = "CC",
                baseCd                  = entry.baseCd,
                cooldownReducingTalent  = entry.cooldownReducingTalent,
                cdReduction             = entry.cdReduction,
                cdReductionPerRank      = entry.cdReductionPerRank,
                cooldownReducingTalent2 = entry.cooldownReducingTalent2,
                cdReduction2            = entry.cdReduction2,
                cdNullifyTalent         = entry.cdNullifyTalent,
                replacedByTalent        = entry.replacedByTalent,
                extraChargeTalent       = entry.extraChargeTalent,
                forceBaseCd             = entry.forceBaseCd,
            }
        else
            -- Spell defined in multiple specs (e.g. Death and Decay 15/25/30s):
            -- keep the highest baseCd as fallback for the flat lookup,
            -- and OR the forceBaseCd flag so cast handler uses the safer path.
            if (entry.baseCd or 0) > (existing.baseCd or 0) then
                existing.baseCd = entry.baseCd
            end
            if entry.forceBaseCd then existing.forceBaseCd = true end
        end
    end
end

-- ============================================================
--  GetSpellDataForCurrentSpec(spellID)
--  Returns the spec-specific data entry for the local player's
--  current specialization, falling back to CC_SPELL_LOOKUP if
--  the spell isn't defined for that spec.
--  Used by cast handler to get the correct baseCd for spells
--  that vary by spec (e.g. Death and Decay 15/25/30s).
-- ============================================================
HasuCCData.GetSpellDataForCurrentSpec = function(spellID)
    local specIndex = GetSpecialization and GetSpecialization()
    if specIndex then
        local ok, sid = pcall(GetSpecializationInfo, specIndex)
        if ok and sid and HasuCCData.SPEC_CC_DATA[sid] then
            for _, entry in ipairs(HasuCCData.SPEC_CC_DATA[sid]) do
                if entry.spellID == spellID then return entry end
            end
        end
    end
    return HasuCCData.CC_SPELL_LOOKUP[spellID]
end

-- ============================================================
--  FindMyCCAbilities
--  Detects the local player's CC abilities using:
--    1. GetSpecializationInfo() → look up SPEC_CC_DATA[specID]
--    2. IsSpellKnown / IsPlayerSpell → verify spell is actually known
--    3. requireTalent check via same spell-known API
--    4. extraChargeTalent check for charge count
--    5. GetSpellBaseCooldown → talent-modified actual CD
--
--  Populates ccAddonUsers[myName]:
--    .ccs[spellID] = {name, baseCd, cdEnd (preserved), maxCharges, icon}
--    .ccOrder = ordered list of active CC spellIDs
--    .specID, .isSelf, .class, .hasAddon, .activeTalents
-- ============================================================
HasuCCData.FindMyCCAbilities = function(myName, myClass, ccAddonUsers)
    if not myName or not myClass then return end

    local specIndex = GetSpecialization and GetSpecialization()
    local specID    = nil
    if specIndex then
        local ok, sid = pcall(GetSpecializationInfo, specIndex)
        if ok and sid and sid > 0 then specID = sid end
    end

    local ccList = specID and HasuCCData.SPEC_CC_DATA[specID]
    if not ccList then
        -- No spec data: create an empty self entry so the window shows the player
        if not ccAddonUsers[myName] then
            ccAddonUsers[myName] = {
                class         = myClass,
                specID        = specID or 0,
                isSelf        = true,
                hasAddon      = true,
                activeTalents = {},
                ccs           = {},
                ccOrder       = {},
            }
        end
        return
    end

    -- Preserve existing cdEnd values
    local prev = ccAddonUsers[myName] or {}
    local oldCcs = prev.ccs or {}

    local newCcs   = {}
    local newOrder = {}

    for _, entry in ipairs(ccList) do
        -- Lua 5.1 has no goto/continue — use repeat...until true + break
        repeat
            local spellID = entry.spellID

            -- ── Skip interrupts: they belong to the interrupt window ──
            -- These are excluded from the player's CC list entirely so they
            -- can never accidentally appear in the CC tracker, even if a
            -- legacy ccSpellState[specID][spellID] toggle is set to true.
            if HasuCCData.INTERRUPT_SPELL_IDS
               and HasuCCData.INTERRUPT_SPELL_IDS[spellID] then
                break
            end

            -- ── requireTalent check (uses full C_Traits scan) ─────────
            if entry.requireTalent then
                if not IsPlayerTalent(entry.requireTalent) then
                    break
                end
            end

            -- ── replacedByTalent: HIDE spell if its replacement talent is active ──
            -- e.g. Mage Cone of Cold hidden when Froid glacial (Ice Nova replaces it)
            if entry.replacedByTalent then
                if IsPlayerTalent(entry.replacedByTalent) then
                    break
                end
            end

            -- ── Is the spell itself known? ────────────────────────
            local spellKnown = false
            do
                local ok, r = pcall(IsSpellKnown, spellID)
                if ok and r then spellKnown = true end
            end
            if not spellKnown then
                local ok, r = pcall(IsPlayerSpell, spellID)
                if ok and r then spellKnown = true end
            end
            -- Fallback: scan C_Traits for talents that are spells themselves
            -- (e.g. Evoker dragon abilities like Oppressive Roar 372048,
            -- Tail Swipe, Wing Buffet — these may not appear in IsSpellKnown
            -- but are detectable via the talent tree).
            if not spellKnown then
                if IsPlayerTalent(spellID) then spellKnown = true end
            end
            -- Inferred-known fallback: if a CD-reducing or extra-charge talent
            -- for this spell is active, the spell MUST be in the player's tree
            -- (since these talents require the base spell as a prerequisite).
            -- This rescues sorts like Evoker Oppressive Roar when the base spell
            -- ID can't be matched via IsSpellKnown / C_Traits definitionID.
            if not spellKnown and entry.cooldownReducingTalent then
                if IsPlayerTalent(entry.cooldownReducingTalent) then spellKnown = true end
            end
            if not spellKnown and entry.cooldownReducingTalent2 then
                if IsPlayerTalent(entry.cooldownReducingTalent2) then spellKnown = true end
            end
            if not spellKnown and entry.extraChargeTalent then
                if IsPlayerTalent(entry.extraChargeTalent) then spellKnown = true end
            end
            if not spellKnown and entry.cdNullifyTalent then
                if IsPlayerTalent(entry.cdNullifyTalent) then spellKnown = true end
            end
            -- forceShow: bypass spellKnown check entirely. Used for spells like
            -- Evoker dragon abilities that aren't reliably detectable via any of
            -- the IsSpellKnown/IsPlayerSpell/IsPlayerTalent paths in WoW 12.0
            -- (their talent definitionID.spellID does not match the cast spellID).
            if entry.forceShow then spellKnown = true end
            -- For 0-CD spells (Fear, Polymorph…) always include.
            -- Only skip if baseCd > 0 and spell truly not known.
            if not spellKnown and entry.baseCd > 0 then
                break
            end

            -- ── Get actual CD from GetSpellBaseCooldown ───────────
            -- WoW 12.0+ sometimes returns the GCD (1500ms) or the per-charge
            -- recharge time instead of the real base CD (e.g. Death Grip
            -- with Echo of Death talent returns ~2000ms, or Death and Decay
            -- which returns 15s in combat regardless of spec). Guard against
            -- garbage values by rejecting anything < 5s when entry.baseCd
            -- is meaningfully larger, and never accepting a value smaller
            -- than ~50% of entry.baseCd — UNLESS a cooldownReducingTalent is
            -- active, in which case a reduced CD is legitimately expected.
            -- forceBaseCd: bypass GetSpellBaseCooldown entirely (use for spells
            -- known to return wrong values, e.g. Death and Decay).
            local actualCd = entry.baseCd
            if entry.baseCd > 0 and not entry.forceBaseCd then
                local ok_cd, ms = pcall(GetSpellBaseCooldown, spellID)

                -- If GetSpellBaseCooldown succeeds and returns valid data (>= 5s),
                -- use it (possibly reduced by talent). Otherwise use baseCd as fallback.
                if ok_cd and ms and ms >= 5000 then
                    local cd = math.floor(ms / 1000 + 0.5)
                    local talentRank = entry.cooldownReducingTalent and GetPlayerTalentRank(entry.cooldownReducingTalent) or 0
                    local cdReducerActive = entry.cooldownReducingTalent and talentRank > 0
                    local talent2Active = entry.cooldownReducingTalent2 and IsPlayerTalent(entry.cooldownReducingTalent2)

                    -- If talent reduces CD and is active, apply the reduction manually
                    -- in case GetSpellBaseCooldown doesn't reflect the talent
                    if cdReducerActive and (entry.cdReduction or entry.cdReductionPerRank) then
                        local reduction = entry.cdReductionPerRank and (entry.cdReductionPerRank * talentRank)
                                          or entry.cdReduction
                        actualCd = entry.baseCd - reduction
                        -- Stack second talent reduction if active
                        if talent2Active and entry.cdReduction2 then
                            actualCd = actualCd - entry.cdReduction2
                        end
                        if actualCd < 1 then actualCd = 1 end
                    elseif talent2Active and entry.cdReduction2 then
                        -- Only second talent active
                        actualCd = math.max(1, entry.baseCd - entry.cdReduction2)
                    else
                        -- Stricter validation: accept CD only if it's at least 75%
                        -- of expected baseCd. This rejects the 15s GCD-modifier
                        -- value that some spells return in combat.
                        local minAccept = math.floor(entry.baseCd * 0.75)
                        -- If a cdReducer is defined for this spell, the API may
                        -- legitimately return the reduced CD even if we couldn't
                        -- detect the talent as active (C_Traits can miss talents
                        -- whose definitionID.spellID differs from the spell's
                        -- cast ID — common for Evoker dragon talents). Accept
                        -- the reduced value too.
                        if entry.cooldownReducingTalent and entry.cdReduction then
                            local reducedMin = math.floor((entry.baseCd - entry.cdReduction) * 0.95)
                            if reducedMin > 0 and reducedMin < minAccept then
                                minAccept = reducedMin
                            end
                        end
                        if cd >= 1 and (entry.baseCd < 10 or cd >= minAccept) then
                            actualCd = cd
                        end
                    end
                else
                    -- GetSpellBaseCooldown failed, returned 0, or returned garbage.
                    -- Use baseCd as fallback, but check if talent reduces it.
                    local talentRank = entry.cooldownReducingTalent and GetPlayerTalentRank(entry.cooldownReducingTalent) or 0
                    local talent2Active = entry.cooldownReducingTalent2 and IsPlayerTalent(entry.cooldownReducingTalent2)
                    actualCd = entry.baseCd
                    if talentRank > 0 then
                        local reduction = entry.cdReductionPerRank and (entry.cdReductionPerRank * talentRank)
                                          or entry.cdReduction or 0
                        actualCd = actualCd - reduction
                    end
                    if talent2Active and entry.cdReduction2 then
                        actualCd = actualCd - entry.cdReduction2
                    end
                    if actualCd < 1 then actualCd = 1 end
                end
            end

            -- ── cdNullifyTalent: makes spell instant (CD = 1) ──
            -- e.g. DK Portée de la mort makes Death Grip instant
            -- e.g. Paladin Renvoi du mal (improved) makes Turn Evil instant
            if entry.cdNullifyTalent and IsPlayerTalent(entry.cdNullifyTalent) then
                actualCd = 1
            end

            -- ── extraChargeTalent ─────────────────────────────────
            local maxCharges = 1
            if entry.extraChargeTalent then
                if IsPlayerTalent(entry.extraChargeTalent) then maxCharges = 2 end
            end

            -- DEBUG: Log ALL CCs to compare baseCd (data) vs GetSpellBaseCooldown (actual)
            -- Use /run HasuCCData.DEBUG_AUDIT = true ; HasuCCData.FindMyCCAbilities(...)
            -- to enable. This helps identify wrong baseCd values per class/spec.
            if HasuCCData.DEBUG_AUDIT then
                local apiCd = 0
                local ok_api, ms = pcall(GetSpellBaseCooldown, spellID)
                if ok_api and ms then apiCd = math.floor(ms / 1000 + 0.5) end
                local talentActive = entry.cooldownReducingTalent and IsPlayerTalent(entry.cooldownReducingTalent)
                local marker = ""
                if entry.baseCd ~= apiCd and apiCd > 0 then marker = " |cFFFF0000<-- MISMATCH|r" end
                print(string.format(
                    "|cFFFFFF00[Audit]|r spellID=%d %s | data=%ds | API=%ds | talent=%s active=%s | actualCd=%ds%s",
                    spellID, entry.name, entry.baseCd, apiCd,
                    tostring(entry.cooldownReducingTalent or "none"),
                    tostring(talentActive), actualCd, marker))
            end

            -- ── Icon ──────────────────────────────────────────────
            local icon = oldCcs[spellID] and oldCcs[spellID].icon
            if not icon then
                local ok_ic, tex = pcall(C_Spell.GetSpellTexture, spellID)
                if ok_ic and tex then icon = tex end
            end

            newCcs[spellID] = {
                name       = entry.name,
                baseCd     = actualCd,
                cdEnd      = oldCcs[spellID] and oldCcs[spellID].cdEnd or 0,
                maxCharges = maxCharges,
                icon       = icon,
                castTime   = entry.castTime,  -- For spells with incantation time
            }
            table.insert(newOrder, spellID)

        until true  -- end of pseudo-continue block
    end

    ccAddonUsers[myName] = {
        class         = myClass,
        specID        = specID or 0,
        isSelf        = true,
        hasAddon      = true,
        activeTalents = {},   -- for self we use IsSpellKnown, not needed here
        ccs           = newCcs,
        ccOrder       = newOrder,
    }
end

-- ============================================================
--  INTERRUPT_SPELL_IDS
--  Spells that are tracked by the interrupt window and should
--  therefore be hidden by default in the CC window.
--  Users can re-enable them per spec in /hasu cc.
-- ============================================================
HasuCCData.INTERRUPT_SPELL_IDS = {
    [47528]=true,   -- Mind Freeze        (DK)
    [96231]=true,   -- Rebuke             (Paladin)
    [2139]=true,    -- Counterspell       (Mage)
    [183752]=true,  -- Disrupt            (DH)
    [351338]=true,  -- Quell              (Evoker)
    [116705]=true,  -- Spear Hand Strike  (Monk)
    [57994]=true,   -- Wind Shear         (Shaman)
    [1766]=true,    -- Kick               (Rogue)
    [6552]=true,    -- Pummel             (Warrior)
    [147362]=true,  -- Counter Shot       (BM/MM Hunter)
    [187707]=true,  -- Muzzle             (Survival Hunter)
    [15487]=true,   -- Silence            (Shadow Priest)
    [106839]=true,  -- Skull Bash         (Feral/Guardian Druid)
    [78675]=true,   -- Solar Beam         (Balance Druid — interrupt+silence)
}

-- ============================================================
--  GetPlayerTalentRank(spellID)
--  Returns the rank (0, 1, 2…) of the given talent. 0 if not active.
-- ============================================================
GetPlayerTalentRank = function(spellID)
    if not (C_ClassTalents and C_ClassTalents.GetActiveConfigID) then
        -- Fallback: only know if active (rank 1) or not (rank 0)
        local ok1, r1 = pcall(IsPlayerSpell, spellID)
        if ok1 and r1 then return 1 end
        return 0
    end
    local okC, configID = pcall(C_ClassTalents.GetActiveConfigID)
    if not okC or not configID then return 0 end
    local okI, ci = pcall(C_Traits.GetConfigInfo, configID)
    if not okI or not ci or not ci.treeIDs then return 0 end

    local target = tostring(spellID)
    -- Scan ALL trees (class, spec, hero, and dragon talents for Evokers/Dracthyr).
    -- Previously only treeIDs[1] was scanned, which missed spec-tree talents like
    -- Roaring Intimidation (374346) for Evokers — causing the CD reduction not to apply.
    for _, treeID in ipairs(ci.treeIDs) do
        local okN, nodeIDs = pcall(C_Traits.GetTreeNodes, treeID)
        if okN and nodeIDs then
            for _, nodeID in ipairs(nodeIDs) do
                local ok3, ni = pcall(C_Traits.GetNodeInfo, configID, nodeID)
                if ok3 and ni and ni.activeEntry and (ni.activeRank or 0) > 0 then
                    local ok4, ei = pcall(C_Traits.GetEntryInfo, configID, ni.activeEntry.entryID)
                    if ok4 and ei and ei.definitionID then
                        local ok5, di = pcall(C_Traits.GetDefinitionInfo, ei.definitionID)
                        if ok5 and di and di.spellID then
                            local sok, s = pcall(tostring, di.spellID)
                            local match = (sok and s == target)
                            if not match then
                                local nok, n = pcall(tonumber, di.spellID)
                                if nok and n and n == spellID then match = true end
                            end
                            if match then return ni.activeRank or 1 end
                        end
                    end
                end
            end
        end
    end
    return 0
end
HasuCCData.GetPlayerTalentRank = GetPlayerTalentRank

-- ============================================================
--  IsPlayerTalent(spellID)
--  Returns true if the local player currently has this talent
--  active. Uses IsPlayerSpell first (fast path), then falls
--  back to a full C_Traits tree scan for passive talents.
--  NOTE: assigned to the forward-declared local at top of file.
-- ============================================================
IsPlayerTalent = function(spellID)
    -- Fast path
    local ok1, r1 = pcall(IsPlayerSpell, spellID)
    if ok1 and r1 then return true end
    local ok2, r2 = pcall(IsSpellKnown, spellID)
    if ok2 and r2 then return true end

    -- Full talent-tree scan via C_Traits
    return GetPlayerTalentRank(spellID) > 0
end
HasuCCData.IsPlayerTalent = IsPlayerTalent

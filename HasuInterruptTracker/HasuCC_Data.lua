--[[
    HasuCC_Data.lua — Hasu's Interrupt Tracker
    Spec-specific CC ability data with talent conditions.

    Provides:
      HasuCCData.SPEC_CC_DATA       — per-specID list of CC abilities
      HasuCCData.CC_SPELL_LOOKUP    — flat spellID → {name,class,dr,baseCd} map
      HasuCCData.FindMyCCAbilities  — populate ccAddonUsers[myName] from spellbook + talent tree

    Each SPEC_CC_DATA entry:
      spellID          : WoW spell ID
      name             : English display name (localized names come from the spell itself)
      baseCd           : Fallback CD in seconds (0 = no CD / no timer needed)
                         For self, GetSpellBaseCooldown() is used instead (reflects talents).
      requireTalent    : (optional) talent spellID — only show this CC if the talent is active
      extraChargeTalent: (optional) talent spellID — if active, maxCharges = 2
]]

HasuCCData = HasuCCData or {}

-- Forward declaration so FindMyCCAbilities (defined below) can resolve
-- IsPlayerTalent as an upvalue instead of a (nil) global lookup.
-- Without this, requireTalent / extraChargeTalent checks silently no-op
-- because the local declaration further down is not yet in scope when
-- the FindMyCCAbilities closure is compiled.
local IsPlayerTalent

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
        { spellID = 47528,   name = "Mind Freeze",         baseCd = 15  },
        { spellID = 45524,   name = "Chains of Ice",       baseCd = 0   },
        { spellID = 221562,  name = "Asphyxiate",          baseCd = 45  },
        { spellID = 49576,   name = "Death Grip",          baseCd = 25,
          extraChargeTalent = 356367 }, -- Écho de la mort → 2 charges
        { spellID = 43265,   name = "Death and Decay",     baseCd = 30,
          requireTalent = 273952 },     -- Poigne des morts: enables pull/CC use
        { spellID = 207167,  name = "Blinding Sleet",      baseCd = 60  },
        { spellID = 108199,  name = "Grip of the Undying", baseCd = 45  }, -- Emprise de Fielsang
        { spellID = 1263569, name = "Abominable Limb",     baseCd = 120 }, -- Membre abominable
    },
    [251] = { -- Frost DK
        { spellID = 47528,   name = "Mind Freeze",         baseCd = 15  },
        { spellID = 45524,   name = "Chains of Ice",       baseCd = 0   },
        { spellID = 221562,  name = "Asphyxiate",          baseCd = 45  },
        { spellID = 49576,   name = "Death Grip",          baseCd = 25,
          extraChargeTalent = 356367 },
        { spellID = 43265,   name = "Death and Decay",     baseCd = 30,
          requireTalent = 273952 },
        { spellID = 207167,  name = "Blinding Sleet",      baseCd = 60  },
    },
    [252] = { -- Unholy DK
        { spellID = 47528,   name = "Mind Freeze",         baseCd = 15  },
        { spellID = 45524,   name = "Chains of Ice",       baseCd = 0   },
        { spellID = 221562,  name = "Asphyxiate",          baseCd = 45  },
        { spellID = 49576,   name = "Death Grip",          baseCd = 25,
          extraChargeTalent = 356367 },
        { spellID = 43265,   name = "Death and Decay",     baseCd = 30,
          requireTalent = 273952 },
        { spellID = 207167,  name = "Blinding Sleet",      baseCd = 60  },
    },

    -- ── PALADIN ──────────────────────────────────────────────
    -- Holy = 65 | Protection = 66 | Retribution = 70
    -- ─────────────────────────────────────────────────────────
    [70] = { -- Retribution Paladin (Vindicte)
        { spellID = 96231,   name = "Rebuke",              baseCd = 15  },
        { spellID = 853,     name = "Hammer of Justice",   baseCd = 60  },
        { spellID = 115750,  name = "Blinding Light",      baseCd = 90  },
        { spellID = 10326,   name = "Turn Evil",           baseCd = 15  },
    },
    [66] = { -- Protection Paladin
        { spellID = 96231,   name = "Rebuke",              baseCd = 15  },
        { spellID = 853,     name = "Hammer of Justice",   baseCd = 60  },
        { spellID = 115750,  name = "Blinding Light",      baseCd = 90  },
        { spellID = 10326,   name = "Turn Evil",           baseCd = 15  },
        { spellID = 375576,  name = "Divine Toll",         baseCd = 60  }, -- Glas divin
        { spellID = 31935,   name = "Avenger's Shield",    baseCd = 15  }, -- Bouclier du vengeur
    },
    [65] = { -- Holy Paladin (Sacré) — no Rebuke
        { spellID = 853,     name = "Hammer of Justice",   baseCd = 60  },
        { spellID = 115750,  name = "Blinding Light",      baseCd = 90  },
        { spellID = 10326,   name = "Turn Evil",           baseCd = 15  },
    },

    -- ── MAGE ─────────────────────────────────────────────────
    -- Arcane = 62 | Fire = 63 | Frost = 64
    -- ─────────────────────────────────────────────────────────
    [62] = { -- Arcane Mage
        { spellID = 2139,    name = "Counterspell",        baseCd = 24  },
        { spellID = 122,     name = "Frost Nova",          baseCd = 30,
          extraChargeTalent = 205036 }, -- Garde glaciale → 2 charges
        { spellID = 118,     name = "Polymorph",           baseCd = 0   },
        { spellID = 113724,  name = "Ring of Frost",       baseCd = 45  },
        { spellID = 383121,  name = "Mass Polymorph",      baseCd = 60  },
        { spellID = 31661,   name = "Dragon's Breath",     baseCd = 20  },
        { spellID = 157980,  name = "Supernova",           baseCd = 25  },
        { spellID = 120,     name = "Cone of Cold",        baseCd = 12  },
        { spellID = 157997,  name = "Ice Nova",            baseCd = 25,
          requireTalent = 386763 }, -- Froid glacial (replaces/augments Cone of Cold)
    },
    [63] = { -- Fire Mage
        { spellID = 2139,    name = "Counterspell",        baseCd = 24  },
        { spellID = 122,     name = "Frost Nova",          baseCd = 30,
          extraChargeTalent = 205036 },
        { spellID = 118,     name = "Polymorph",           baseCd = 0   },
        { spellID = 113724,  name = "Ring of Frost",       baseCd = 45  },
        { spellID = 383121,  name = "Mass Polymorph",      baseCd = 60  },
        { spellID = 31661,   name = "Dragon's Breath",     baseCd = 20  },
        { spellID = 157980,  name = "Supernova",           baseCd = 25  },
        { spellID = 120,     name = "Cone of Cold",        baseCd = 12  },
        { spellID = 157997,  name = "Ice Nova",            baseCd = 25,
          requireTalent = 386763 },
    },
    [64] = { -- Frost Mage
        { spellID = 2139,    name = "Counterspell",        baseCd = 24  },
        { spellID = 122,     name = "Frost Nova",          baseCd = 30,
          extraChargeTalent = 205036 },
        { spellID = 118,     name = "Polymorph",           baseCd = 0   },
        { spellID = 113724,  name = "Ring of Frost",       baseCd = 45  },
        { spellID = 383121,  name = "Mass Polymorph",      baseCd = 60  },
        { spellID = 31661,   name = "Dragon's Breath",     baseCd = 20  },
        { spellID = 157980,  name = "Supernova",           baseCd = 25  },
        { spellID = 120,     name = "Cone of Cold",        baseCd = 12  },
        { spellID = 157997,  name = "Ice Nova",            baseCd = 25,
          requireTalent = 386763 },
    },

    -- ── DEMON HUNTER ─────────────────────────────────────────
    -- Havoc = 577 | Vengeance = 581
    -- ─────────────────────────────────────────────────────────
    [577] = { -- Havoc DH (Dévastation)
        { spellID = 183752,  name = "Disrupt",             baseCd = 15  },
        { spellID = 179057,  name = "Chaos Nova",          baseCd = 60  },
        { spellID = 1234195, name = "Void Nova",           baseCd = 90  }, -- TODO: verify spell ID in WoW 12.0
        { spellID = 217832,  name = "Imprison",            baseCd = 45  },
        -- Sigil of Misery: talent 320418 (Improved Sigil) reduces the CD;
        -- handled automatically via GetSpellBaseCooldown, no data key needed.
        { spellID = 207684,  name = "Sigil of Misery",     baseCd = 90  },
    },
    [581] = { -- Vengeance DH
        { spellID = 183752,  name = "Disrupt",             baseCd = 15  },
        { spellID = 179057,  name = "Chaos Nova",          baseCd = 60  },
        { spellID = 1234195, name = "Void Nova",           baseCd = 90  }, -- TODO: verify spell ID in WoW 12.0
        { spellID = 217832,  name = "Imprison",            baseCd = 45  },
        { spellID = 207684,  name = "Sigil of Misery",     baseCd = 90  },
        { spellID = 202138,  name = "Sigil of Chains",     baseCd = 90  }, -- Sigil de chaînes
        { spellID = 202137,  name = "Sigil of Silence",    baseCd = 60  }, -- Sigil de silence
    },

    -- ── EVOKER ───────────────────────────────────────────────
    -- Devastation = 1467 | Preservation = 1468 | Augmentation = 1473
    -- ─────────────────────────────────────────────────────────
    [1473] = { -- Augmentation Evoker
        { spellID = 372048,  name = "Oppressive Roar",     baseCd = 120 },
        { spellID = 351338,  name = "Quell",               baseCd = 18  }, -- interrupt
        { spellID = 368970,  name = "Tail Swipe",          baseCd = 90  },
        { spellID = 357214,  name = "Wing Buffet",         baseCd = 40  },
    },
    [1467] = { -- Devastation Evoker
        { spellID = 372048,  name = "Oppressive Roar",     baseCd = 120 },
        { spellID = 351338,  name = "Quell",               baseCd = 20  }, -- interrupt
        { spellID = 368970,  name = "Tail Swipe",          baseCd = 90  },
        { spellID = 357214,  name = "Wing Buffet",         baseCd = 40  },
    },
    [1468] = { -- Preservation Evoker (no Quell)
        { spellID = 372048,  name = "Oppressive Roar",     baseCd = 120 },
        { spellID = 368970,  name = "Tail Swipe",          baseCd = 90  },
        { spellID = 357214,  name = "Wing Buffet",         baseCd = 40  },
    },

    -- ── MONK ─────────────────────────────────────────────────
    -- Brewmaster = 268 | Windwalker = 269 | Mistweaver = 270
    -- ─────────────────────────────────────────────────────────
    [269] = { -- Windwalker Monk
        { spellID = 116705,  name = "Spear Hand Strike",   baseCd = 15  }, -- interrupt
        { spellID = 115078,  name = "Paralysis",           baseCd = 15,
          extraChargeTalent = 344359 }, -- Arts antiques → up to 2 charges
        { spellID = 119381,  name = "Leg Sweep",           baseCd = 45,
          extraChargeTalent = 344359 },
        { spellID = 116844,  name = "Ring of Peace",       baseCd = 45  },
        { spellID = 198898,  name = "Song of Chi-Ji",      baseCd = 30  },
    },
    [270] = { -- Mistweaver Monk (no Spear Hand Strike in 12.0)
        { spellID = 115078,  name = "Paralysis",           baseCd = 15,
          extraChargeTalent = 344359 },
        { spellID = 119381,  name = "Leg Sweep",           baseCd = 45,
          extraChargeTalent = 344359 },
        { spellID = 116844,  name = "Ring of Peace",       baseCd = 45  },
        { spellID = 198898,  name = "Song of Chi-Ji",      baseCd = 30  },
    },
    [268] = { -- Brewmaster Monk
        { spellID = 116705,  name = "Spear Hand Strike",   baseCd = 15  },
        { spellID = 115078,  name = "Paralysis",           baseCd = 15,
          extraChargeTalent = 344359 },
        { spellID = 119381,  name = "Leg Sweep",           baseCd = 45,
          extraChargeTalent = 344359 },
        { spellID = 116844,  name = "Ring of Peace",       baseCd = 45  },
        { spellID = 198898,  name = "Song of Chi-Ji",      baseCd = 30  },
    },

    -- ── WARLOCK ──────────────────────────────────────────────
    -- Affliction = 265 | Demonology = 266 | Destruction = 267
    -- ─────────────────────────────────────────────────────────
    [265] = { -- Affliction Warlock
        { spellID = 119910,  name = "Spell Lock",          baseCd = 24  }, -- Command Demon
        { spellID = 6789,    name = "Mortal Coil",         baseCd = 45  },
        { spellID = 5484,    name = "Howl of Terror",      baseCd = 40  },
        { spellID = 30283,   name = "Shadowfury",          baseCd = 30  },
        { spellID = 1122,    name = "Summon Infernal",     baseCd = 180 },
        { spellID = 5782,    name = "Fear",                baseCd = 0   },
        { spellID = 710,     name = "Banish",              baseCd = 30  },
    },
    [266] = { -- Demonology Warlock
        { spellID = 119910,  name = "Spell Lock",          baseCd = 24  },
        { spellID = 6789,    name = "Mortal Coil",         baseCd = 45  },
        { spellID = 5484,    name = "Howl of Terror",      baseCd = 40  },
        { spellID = 30283,   name = "Shadowfury",          baseCd = 30  },
        { spellID = 1122,    name = "Summon Infernal",     baseCd = 180 },
        { spellID = 5782,    name = "Fear",                baseCd = 0   },
        { spellID = 710,     name = "Banish",              baseCd = 30  },
    },
    [267] = { -- Destruction Warlock
        { spellID = 119910,  name = "Spell Lock",          baseCd = 24  },
        { spellID = 6789,    name = "Mortal Coil",         baseCd = 45  },
        { spellID = 5484,    name = "Howl of Terror",      baseCd = 40  },
        { spellID = 30283,   name = "Shadowfury",          baseCd = 30  },
        { spellID = 1122,    name = "Summon Infernal",     baseCd = 180 },
        { spellID = 5782,    name = "Fear",                baseCd = 0   },
        { spellID = 710,     name = "Banish",              baseCd = 30  },
    },

    -- ── DRUID ────────────────────────────────────────────────
    -- Balance = 102 | Feral = 103 | Guardian = 104 | Restoration = 105
    -- ─────────────────────────────────────────────────────────
    [102] = { -- Balance Druid
        { spellID = 78675,   name = "Solar Beam",          baseCd = 60  },
        { spellID = 132469,  name = "Typhoon",             baseCd = 30  },
        { spellID = 102359,  name = "Mass Entanglement",   baseCd = 30  },
        { spellID = 102793,  name = "Ursol's Vortex",      baseCd = 60  },
        { spellID = 99,      name = "Incapacitating Roar", baseCd = 30  },
        { spellID = 5211,    name = "Mighty Bash",         baseCd = 60  },
        { spellID = 33786,   name = "Cyclone",             baseCd = 0   },
        { spellID = 339,     name = "Entangling Roots",    baseCd = 0   },
    },
    [103] = { -- Feral Druid
        { spellID = 106839,  name = "Skull Bash",          baseCd = 15  }, -- interrupt
        { spellID = 33786,   name = "Cyclone",             baseCd = 0   },
        { spellID = 132469,  name = "Typhoon",             baseCd = 30  },
        { spellID = 102359,  name = "Mass Entanglement",   baseCd = 30  },
        { spellID = 102793,  name = "Ursol's Vortex",      baseCd = 60  },
        { spellID = 99,      name = "Incapacitating Roar", baseCd = 30  },
        { spellID = 5211,    name = "Mighty Bash",         baseCd = 60  },
        { spellID = 339,     name = "Entangling Roots",    baseCd = 0   },
    },
    [104] = { -- Guardian Druid
        { spellID = 106839,  name = "Skull Bash",          baseCd = 15  },
        { spellID = 33786,   name = "Cyclone",             baseCd = 0   },
        { spellID = 132469,  name = "Typhoon",             baseCd = 30  },
        { spellID = 102359,  name = "Mass Entanglement",   baseCd = 30  },
        { spellID = 102793,  name = "Ursol's Vortex",      baseCd = 60  },
        { spellID = 99,      name = "Incapacitating Roar", baseCd = 30  },
        { spellID = 5211,    name = "Mighty Bash",         baseCd = 60  },
        { spellID = 339,     name = "Entangling Roots",    baseCd = 0   },
    },
    [105] = { -- Restoration Druid (no Skull Bash in 12.0)
        { spellID = 33786,   name = "Cyclone",             baseCd = 0   },
        { spellID = 132469,  name = "Typhoon",             baseCd = 30  },
        { spellID = 102359,  name = "Mass Entanglement",   baseCd = 30  },
        { spellID = 102793,  name = "Ursol's Vortex",      baseCd = 60  },
        { spellID = 99,      name = "Incapacitating Roar", baseCd = 30  },
        { spellID = 5211,    name = "Mighty Bash",         baseCd = 60  },
        { spellID = 339,     name = "Entangling Roots",    baseCd = 0   },
    },

    -- ── HUNTER ───────────────────────────────────────────────
    -- Beast Mastery = 253 | Marksmanship = 254 | Survival = 255
    -- ─────────────────────────────────────────────────────────
    [253] = { -- Beast Mastery Hunter
        { spellID = 147362,  name = "Counter Shot",        baseCd = 24  }, -- interrupt
        { spellID = 19577,   name = "Intimidation",        baseCd = 60  },
        { spellID = 187650,  name = "Freezing Trap",       baseCd = 25  },
        { spellID = 109248,  name = "Binding Shot",        baseCd = 45  },
        { spellID = 187698,  name = "Tar Trap",            baseCd = 30  },
    },
    [254] = { -- Marksmanship Hunter
        { spellID = 147362,  name = "Counter Shot",        baseCd = 24  },
        { spellID = 19577,   name = "Intimidation",        baseCd = 60  },
        { spellID = 187650,  name = "Freezing Trap",       baseCd = 25  },
        { spellID = 109248,  name = "Binding Shot",        baseCd = 45  },
        { spellID = 187698,  name = "Tar Trap",            baseCd = 30  },
    },
    [255] = { -- Survival Hunter
        { spellID = 187707,  name = "Muzzle",              baseCd = 15  }, -- interrupt
        { spellID = 19577,   name = "Intimidation",        baseCd = 60  },
        { spellID = 187650,  name = "Freezing Trap",       baseCd = 25  },
        { spellID = 109248,  name = "Binding Shot",        baseCd = 45  },
        { spellID = 187698,  name = "Tar Trap",            baseCd = 30  },
    },

    -- ── PRIEST ───────────────────────────────────────────────
    -- Discipline = 256 | Holy = 257 | Shadow = 258
    -- ─────────────────────────────────────────────────────────
    [258] = { -- Shadow Priest
        { spellID = 15487,   name = "Silence",             baseCd = 30  }, -- interrupt
        { spellID = 8122,    name = "Psychic Scream",      baseCd = 45  },
        { spellID = 1250691, name = "Void Tendrils",       baseCd = 30  },
        { spellID = 9484,    name = "Shackle Undead",      baseCd = 0   },
    },
    [257] = { -- Holy Priest (Sacré) — no Silence
        { spellID = 88625,   name = "Holy Word: Chastise", baseCd = 60  },
        { spellID = 8122,    name = "Psychic Scream",      baseCd = 45  },
        { spellID = 1250691, name = "Void Tendrils",       baseCd = 30  },
        { spellID = 9484,    name = "Shackle Undead",      baseCd = 0   },
    },
    [256] = { -- Discipline Priest — no Silence
        { spellID = 8122,    name = "Psychic Scream",      baseCd = 45  },
        { spellID = 1250691, name = "Void Tendrils",       baseCd = 30  },
        { spellID = 9484,    name = "Shackle Undead",      baseCd = 0   },
    },

    -- ── WARRIOR ──────────────────────────────────────────────
    -- Arms = 71 | Fury = 72 | Protection = 73
    -- ─────────────────────────────────────────────────────────
    [71] = { -- Arms Warrior
        { spellID = 6552,    name = "Pummel",              baseCd = 15  }, -- interrupt
        { spellID = 107570,  name = "Storm Bolt",          baseCd = 30  },
        { spellID = 46968,   name = "Shockwave",           baseCd = 40  },
    },
    [72] = { -- Fury Warrior
        { spellID = 6552,    name = "Pummel",              baseCd = 15  },
        { spellID = 107570,  name = "Storm Bolt",          baseCd = 30  },
        { spellID = 46968,   name = "Shockwave",           baseCd = 40  },
    },
    [73] = { -- Protection Warrior
        { spellID = 6552,    name = "Pummel",              baseCd = 15  },
        { spellID = 107570,  name = "Storm Bolt",          baseCd = 30  },
        { spellID = 46968,   name = "Shockwave",           baseCd = 40  },
        { spellID = 385952,  name = "Shield Charge",       baseCd = 20  }, -- Charge de bouclier
    },

    -- ── SHAMAN ───────────────────────────────────────────────
    -- Elemental = 262 | Enhancement = 263 | Restoration = 264
    -- ─────────────────────────────────────────────────────────
    [262] = { -- Elemental Shaman
        { spellID = 57994,   name = "Wind Shear",          baseCd = 12  }, -- interrupt
        { spellID = 51514,   name = "Hex",                 baseCd = 0   },
        { spellID = 192058,  name = "Capacitor Totem",     baseCd = 60,
          extraChargeTalent = 265046 }, -- Charge statique → 2 charges
        { spellID = 51485,   name = "Earthgrab Totem",     baseCd = 30  },
        { spellID = 51490,   name = "Thunderstorm",        baseCd = 45  },
    },
    [263] = { -- Enhancement Shaman
        { spellID = 57994,   name = "Wind Shear",          baseCd = 12  },
        { spellID = 51514,   name = "Hex",                 baseCd = 0   },
        { spellID = 192058,  name = "Capacitor Totem",     baseCd = 60,
          extraChargeTalent = 265046 },
        { spellID = 51485,   name = "Earthgrab Totem",     baseCd = 30  },
    },
    [264] = { -- Restoration Shaman (30s Wind Shear)
        { spellID = 57994,   name = "Wind Shear",          baseCd = 30  },
        { spellID = 51514,   name = "Hex",                 baseCd = 0   },
        { spellID = 192058,  name = "Capacitor Totem",     baseCd = 60,
          extraChargeTalent = 265046 },
        { spellID = 51485,   name = "Earthgrab Totem",     baseCd = 30  },
    },

    -- ── ROGUE ────────────────────────────────────────────────
    -- Assassination = 259 | Outlaw = 260 | Subtlety = 261
    -- ─────────────────────────────────────────────────────────
    [259] = { -- Assassination Rogue
        { spellID = 1766,    name = "Kick",                baseCd = 15  }, -- interrupt
        { spellID = 2094,    name = "Blind",               baseCd = 120 },
        { spellID = 1776,    name = "Gouge",               baseCd = 15  },
        { spellID = 703,     name = "Garrote (Silence)",   baseCd = 15,
          requireTalent = 196861 }, -- Fil de fer: Garrote silences the target
    },
    [260] = { -- Outlaw Rogue (Hors-la-loi)
        { spellID = 1766,    name = "Kick",                baseCd = 15  },
        { spellID = 2094,    name = "Blind",               baseCd = 120 },
        { spellID = 1776,    name = "Gouge",               baseCd = 15  },
    },
    [261] = { -- Subtlety Rogue (Finesse)
        { spellID = 1766,    name = "Kick",                baseCd = 15  },
        { spellID = 2094,    name = "Blind",               baseCd = 120 },
        { spellID = 1776,    name = "Gouge",               baseCd = 15  },
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
    [577]="DEMONHUNTER", [581]="DEMONHUNTER",
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
        if not HasuCCData.CC_SPELL_LOOKUP[entry.spellID] then
            HasuCCData.CC_SPELL_LOOKUP[entry.spellID] = {
                name   = entry.name,
                class  = cls,
                dr     = "CC",
                baseCd = entry.baseCd,
            }
        end
    end
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
                if not IsPlayerTalent(entry.requireTalent) then break end
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
            -- For 0-CD spells (Fear, Polymorph…) always include.
            -- Only skip if baseCd > 0 and spell truly not known.
            if not spellKnown and entry.baseCd > 0 then break end

            -- ── Get actual CD from GetSpellBaseCooldown ───────────
            -- WoW 12.0+ sometimes returns the GCD (1500ms) or the per-charge
            -- recharge time instead of the real base CD (e.g. Death Grip
            -- with Echo of Death talent returns ~2000ms). Guard against
            -- garbage values by rejecting anything < 5s when entry.baseCd
            -- is meaningfully larger, and never accepting a value smaller
            -- than ~50% of entry.baseCd.
            local actualCd = entry.baseCd
            if entry.baseCd > 0 then
                local ok_cd, ms = pcall(GetSpellBaseCooldown, spellID)
                if ok_cd and ms and ms >= 5000 then
                    local cd = math.floor(ms / 1000 + 0.5)
                    local minAccept = math.floor(entry.baseCd * 0.5)
                    if cd >= 1 and (entry.baseCd < 10 or cd >= minAccept) then
                        actualCd = cd
                    end
                end
            end

            -- ── extraChargeTalent ─────────────────────────────────
            local maxCharges = 1
            if entry.extraChargeTalent then
                if IsPlayerTalent(entry.extraChargeTalent) then maxCharges = 2 end
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
    if not (C_ClassTalents and C_ClassTalents.GetActiveConfigID) then return false end
    local okC, configID = pcall(C_ClassTalents.GetActiveConfigID)
    if not okC or not configID then return false end
    local okI, ci = pcall(C_Traits.GetConfigInfo, configID)
    if not okI or not ci or not ci.treeIDs then return false end
    local treeID = ci.treeIDs[1]
    if not treeID then return false end
    local okN, nodeIDs = pcall(C_Traits.GetTreeNodes, treeID)
    if not okN or not nodeIDs then return false end

    local target = tostring(spellID)
    for _, nodeID in ipairs(nodeIDs) do
        local ok3, ni = pcall(C_Traits.GetNodeInfo, configID, nodeID)
        if ok3 and ni and ni.activeEntry and (ni.activeRank or 0) > 0 then
            local ok4, ei = pcall(C_Traits.GetEntryInfo, configID, ni.activeEntry.entryID)
            if ok4 and ei and ei.definitionID then
                local ok5, di = pcall(C_Traits.GetDefinitionInfo, ei.definitionID)
                if ok5 and di and di.spellID then
                    local sok, s = pcall(tostring, di.spellID)
                    if sok and s == target then return true end
                    local nok, n = pcall(tonumber, di.spellID)
                    if nok and n and n == spellID then return true end
                end
            end
        end
    end
    return false
end
HasuCCData.IsPlayerTalent = IsPlayerTalent

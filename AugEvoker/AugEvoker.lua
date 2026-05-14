-- ============================================================
--  AugEvoker v8.2
--  Colonnes : Joueur | #Pr | Presc% | #EM
-- ============================================================

local ADDON_VERSION = "8.2"

local PRESCIENCE_BUFF_ID = 410089
local PRESCIENCE_CAST_ID = 409311
local EBON_MIGHT_CAST_ID = 395152  -- seul ID pertinent pour SPELL_CAST_SUCCESS

-- Noms exacts récupérés au runtime
local PRESC_SPELL_NAME = nil

local uptimeData   = {}  -- [name] = {prStart,prTotal,prActive,prExpiry, prCount,emCount}
local segmentStart = 0
local frozen      = false  -- true = stats figées (fin de donjon)
local frozenChannel = nil  -- canal mémorisé au moment du freeze
local freezeTime  = nil   -- GetTime() au moment du freeze (fige segDur)

-- Forward-declaration : SaveSettings est défini bas dans le fichier mais
-- référencé par le handler OnDragStop de mainFrame (créé avant la définition).
local SaveSettings

local function TruncateName(name, maxLen)
    maxLen = maxLen or 16
    if #name <= maxLen then return name end
    return name:sub(1, maxLen-2).."..."
end

local function EnsurePlayer(name)
    if not uptimeData[name] then
        uptimeData[name] = {prStart=nil,prTotal=0,prActive=false,prCount=0,emCount=0}
    end
    return uptimeData[name]
end

local function ResetData()
    uptimeData   = {}
    segmentStart = 0
    frozen       = false
    frozenChannel = nil
    freezeTime   = nil
end

-- Fige les données : clôture les segments Presc ouverts, arrête l'accumulation
local function FreezeData()
    if frozen then return end
    local t = GetTime()
    for _, d in pairs(uptimeData) do
        if d.prActive and d.prStart then
            d.prTotal  = d.prTotal + (t - d.prStart)
            d.prStart  = nil; d.prActive = false; d.prExpiry = nil
        end
    end
    frozen     = true
    freezeTime = t   -- fige segDur : les % ne bougent plus après ce point
    -- Mémorise le canal (on est encore en groupe à ce moment)
    if IsInRaid() then frozenChannel = "RAID"
    elseif IsInGroup() then frozenChannel = "PARTY"
    else frozenChannel = nil end
end

local function GetPRUptime(name)
    local d = uptimeData[name]
    if not d then return 0 end
    if segmentStart == 0 then return 0 end  -- pas encore de segment actif
    -- Si figé : on utilise freezeTime pour que segDur reste constant
    local now = frozen and freezeTime or GetTime()
    local segDur = math.max(1, now - segmentStart)
    local total = d.prTotal or 0
    if d.prActive and d.prStart then total = total + (now - d.prStart) end
    return math.min(100, (total / segDur) * 100)
end

local function GetPrCount(name)
    local d = uptimeData[name]
    return d and d.prCount or 0
end

local function GetEmCount(name)
    local d = uptimeData[name]
    return d and d.emCount or 0
end

-- ============================================================
--  SCAN UNIT_AURA
-- ============================================================
local function IsGroupUnit(unit)
    if unit == "player" then return true end
    local prefix = unit:match("^(%a+)%d+$")
    return prefix == "party" or prefix == "raid"
end

local function ScanUnit(unit)
    if frozen then return end  -- stats figées, on ne met plus à jour
    if not unit or not UnitExists(unit) then return end
    if not IsGroupUnit(unit) then return end
    local name = UnitName(unit)
    if not name or issecretvalue(name) or name == UNKNOWN then return end

    local d = EnsurePlayer(name)
    local foundPR    = false
    local foundExpiry = nil  -- expirationTime de l'aura Prescience

    local i = 1
    while true do
        local aura = C_UnitAuras.GetAuraDataByIndex(unit, i, "HELPFUL")
        if not aura then break end
        local sid      = aura.spellId
        local auraName = aura.name
        local matched  = false
        if sid and not issecretvalue(sid) then
            if sid == PRESCIENCE_BUFF_ID or sid == PRESCIENCE_CAST_ID then matched = true end
        elseif auraName and not issecretvalue(auraName) then
            if PRESC_SPELL_NAME and auraName == PRESC_SPELL_NAME then matched = true end
            if not matched then
                local low = auraName:lower()
                if low:find("prescience", 1, true) then matched = true end
            end
        end
        if matched then
            -- Filtre : on ne compte que NOTRE Prescience (pas celles des autres Aug Evokers)
            local src = aura.sourceUnit
            if src and UnitIsUnit(src, "player") then
                foundPR = true
                local exp = aura.expirationTime
                if exp and not issecretvalue(exp) and exp > 0 then
                    foundExpiry = exp
                end
            end
            break
        end
        i = i + 1
    end

    local t = GetTime()
    if foundPR then
        if not d.prActive then
            -- Première détection du buff : nouveau cast
            d.prActive = true; d.prStart = t
            d.prCount  = (d.prCount or 0) + 1
            d.prExpiry = foundExpiry
            if segmentStart == 0 then segmentStart = t end
        elseif foundExpiry and d.prExpiry and foundExpiry > d.prExpiry + 1.0 then
            -- L'expiration a avancé de >1s = refresh / nouveau cast sur cible déjà buffée
            d.prCount  = (d.prCount or 0) + 1
            d.prExpiry = foundExpiry
        end
    elseif d.prActive then
        d.prActive = false
        d.prExpiry = nil
        if d.prStart then d.prTotal = d.prTotal + (t - d.prStart); d.prStart = nil end
    end
end

local function ScanAllUnits()
    ScanUnit("player")
    if IsInRaid() then
        for i = 1, GetNumGroupMembers() do ScanUnit("raid"..i) end
    elseif IsInGroup() then
        for i = 1, GetNumSubgroupMembers(0) do ScanUnit("party"..i) end
    end
end

local function GetGroupMembers()
    local members = {}
    local function addUnit(unit)
        if not UnitExists(unit) then return end
        local name = UnitName(unit)
        if not name or issecretvalue(name) or name == UNKNOWN or name == "" then return end
        members[name] = unit
    end
    addUnit("player")
    if IsInRaid() then
        for i = 1, GetNumGroupMembers() do addUnit("raid"..i) end
    elseif IsInGroup() then
        for i = 1, GetNumSubgroupMembers(0) do addUnit("party"..i) end
    end
    return members
end

-- ============================================================
--  EVENTS
-- ============================================================
local classCache = {}
local eventFrame = CreateFrame("Frame")

eventFrame:RegisterEvent("UNIT_AURA")
eventFrame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
eventFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
eventFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("CHALLENGE_MODE_COMPLETED")
eventFrame:RegisterEvent("SCENARIO_COMPLETED")

local playerGUID = nil

eventFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "PLAYER_REGEN_DISABLED" then
        if frozen then return end  -- stats figées
        if segmentStart == 0 then segmentStart = GetTime() end

    elseif event == "PLAYER_REGEN_ENABLED" then
        if frozen then return end  -- stats figées
        -- Fin de combat : on checkpointe le temps sans réinitialiser prActive.
        -- Si on remettait prActive=false puis appelait ScanAllUnits(), ScanUnit verrait
        -- foundPR=true + prActive=false et incrémenterait prCount à tort.
        local t = GetTime()
        for _, d in pairs(uptimeData) do
            if d.prActive and d.prStart then
                d.prTotal = d.prTotal + (t - d.prStart)
                d.prStart = t   -- repart de maintenant, prActive reste true
            end
        end
        -- Pas de ScanAllUnits : UNIT_AURA se déclenchera naturellement

    elseif event == "UNIT_AURA" then
        local unit = ...
        if unit then ScanUnit(unit) end
        -- UpdateDisplay est géré par le ticker 0.1s (évite les appels massifs en raid)

    elseif event == "COMBAT_LOG_EVENT_UNFILTERED" then
        if frozen then return end  -- stats figées, on ignore le CLEU
        local _, subEvent, _,
              sourceGUID, _, _, _,
              _, destName, _, _,
              spellID = CombatLogGetCurrentEventInfo()

        -- Éclat d'Ébène
        if subEvent == "SPELL_CAST_SUCCESS"
        and sourceGUID == playerGUID
        and spellID and not issecretvalue(spellID)
        and spellID == EBON_MIGHT_CAST_ID
        then
            local t = GetTime()
            if segmentStart == 0 then segmentStart = t end
            -- S'assure que le joueur est dans uptimeData (cas où aucun Presc n'a encore été casté)
            local playerName = UnitName("player")
            if playerName and not issecretvalue(playerName) then
                EnsurePlayer(playerName)
            else
                playerName = nil
            end
            -- emCount = nombre de fois où chaque joueur a reçu le buff EM
            -- (le joueur lui-même + tous les membres avec Prescience active)
            for name, d in pairs(uptimeData) do
                if (playerName and name == playerName) or d.prActive then
                    d.emCount = (d.emCount or 0) + 1
                end
            end

        -- Alerte décès : quelqu'un du groupe est mort
        elseif subEvent == "UNIT_DIED" and destName and not issecretvalue(destName) then
            -- Vérifie si les alertes décès sont activées dans les options
            local showDeathAlert = true
            if AugEvokerDB and AugEvokerDB.deathAlerts == false then showDeathAlert = false end

            if showDeathAlert then
                local isGroupMember = (destName == UnitName("player"))
                if not isGroupMember then
                    if IsInRaid() then
                        for i = 1, GetNumGroupMembers() do
                            if UnitName("raid"..i) == destName then isGroupMember = true; break end
                        end
                    elseif IsInGroup() then
                        for i = 1, GetNumSubgroupMembers(0) do
                            if UnitName("party"..i) == destName then isGroupMember = true; break end
                        end
                    end
                end
                if isGroupMember then
                    DEFAULT_CHAT_FRAME:AddMessage(string.format("|cFFFF4444[AugEvoker]|r ☠ %s est mort", destName))
                end
            end
        end

    elseif event == "CHALLENGE_MODE_COMPLETED" then
        -- Fin de donjon M+
        FreezeData()
        DEFAULT_CHAT_FRAME:AddMessage("|cFF33CC99[AugEvoker]|r M+ terminé — stats figées. Clique sur |cFFFFAA00Envoyer|r.")

    elseif event == "SCENARIO_COMPLETED" then
        -- Fin de donjon normal / héroïque
        FreezeData()
        DEFAULT_CHAT_FRAME:AddMessage("|cFF33CC99[AugEvoker]|r Donjon terminé — stats figées. Clique sur |cFFFFAA00Envoyer|r.")


    elseif event == "GROUP_ROSTER_UPDATE" then
        -- Changement de groupe : juste rescan, ne pas effacer les données
        -- Si figé, on préserve classCache (groupe vide = impossible de repeupler)
        if not frozen then
            classCache = {}
            ScanAllUnits()
        end

    elseif event == "PLAYER_ENTERING_WORLD" then
        -- Chaque changement de zone = nouvelle run, SAUF si stats figées
        -- (écran de chargement en cours de donjon ne doit pas effacer les données)
        if not frozen then
            classCache = {}
            ResetData()
        end
        ScanAllUnits()
    end
end)

-- ============================================================
--  INTERFACE
-- ============================================================
local ROW_H    = 20
local TITLE_H  = 20
local HDR_H    = 18
local FOOTER_H = 28
local MAX_ROWS = 8
local mainFrame = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
mainFrame:SetSize(320, 100)
mainFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
mainFrame:SetMovable(true)
mainFrame:EnableMouse(true)
mainFrame:RegisterForDrag("LeftButton")
mainFrame:SetScript("OnDragStart", mainFrame.StartMoving)
mainFrame:SetScript("OnDragStop", function()
    mainFrame:StopMovingOrSizing()
    SaveSettings()
end)
mainFrame:SetClampedToScreen(true)
mainFrame:SetResizable(true)
mainFrame:SetResizeBounds(200, 80, 500, 400)
mainFrame:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8", edgeFile="Interface\\Buttons\\WHITE8X8", edgeSize=1})
mainFrame:SetBackdropColor(0.07, 0.07, 0.07, 0.96)
mainFrame:SetBackdropBorderColor(0.20, 0.10, 0.30, 1)

-- ── Barre de titre ───────────────────────────────────────────
local titleBg = mainFrame:CreateTexture(nil, "BACKGROUND", nil, 1)
titleBg:SetPoint("TOPLEFT",  mainFrame, "TOPLEFT",  1, -1)
titleBg:SetPoint("TOPRIGHT", mainFrame, "TOPRIGHT", -1, -1)
titleBg:SetHeight(TITLE_H)
titleBg:SetColorTexture(0.15, 0.07, 0.25, 1)

local titleText = mainFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
titleText:SetPoint("LEFT", mainFrame, "LEFT", 8, 0)
titleText:SetPoint("TOP",  mainFrame, "TOP",  0, -1)
titleText:SetHeight(TITLE_H)
titleText:SetJustifyH("LEFT")
titleText:SetJustifyV("MIDDLE")
titleText:SetText("|cFFBB88FFAug Evoker|r  |cFF555555v"..ADDON_VERSION.."|r")

local closeBtn = CreateFrame("Button", nil, mainFrame, "UIPanelCloseButton")
closeBtn:SetSize(20, 20)
closeBtn:SetPoint("TOPRIGHT", mainFrame, "TOPRIGHT", 2, 2)

-- ── Barre de colonnes (header) ───────────────────────────────
local hdrBg = mainFrame:CreateTexture(nil, "BACKGROUND", nil, 1)
hdrBg:SetPoint("TOPLEFT",  mainFrame, "TOPLEFT",  1, -(TITLE_H+1))
hdrBg:SetPoint("TOPRIGHT", mainFrame, "TOPRIGHT", -1, -(TITLE_H+1))
hdrBg:SetHeight(HDR_H)
hdrBg:SetColorTexture(0.11, 0.05, 0.18, 1)

local function MakeHdr(text, xLeft, w, justify)
    local fs = mainFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    fs:SetPoint("TOPLEFT", mainFrame, "TOPLEFT", xLeft, -(TITLE_H+1))
    fs:SetSize(w, HDR_H)
    fs:SetJustifyH(justify or "LEFT")
    fs:SetJustifyV("MIDDLE")
    fs:SetTextColor(0.60, 0.45, 0.80, 1)
    fs:SetText(text)
end
MakeHdr("Joueur",   8,  136, "LEFT")
MakeHdr("#Pr",    146,   36, "RIGHT")
MakeHdr("Presc%", 184,   58, "RIGHT")
MakeHdr("#EM",    244,   60, "RIGHT")

-- Séparateur sous le header
local sepLine = mainFrame:CreateTexture(nil, "OVERLAY")
sepLine:SetPoint("TOPLEFT",  mainFrame, "TOPLEFT",  0, -(TITLE_H+HDR_H+1))
sepLine:SetPoint("TOPRIGHT", mainFrame, "TOPRIGHT", 0, -(TITLE_H+HDR_H+1))
sepLine:SetHeight(1)
sepLine:SetColorTexture(0.22, 0.10, 0.35, 1)

-- ── Menu canal ───────────────────────────────────────────────
local selectedChannel = "PARTY"
local channelOptions = {
    {label="Groupe",    value="PARTY"},
    {label="Raid",      value="RAID"},
    {label="Guilde",    value="GUILD"},
    {label="Officiers", value="OFFICER"},
    {label="Zone",      value="SAY"},
}

local channelMenu = CreateFrame("Frame", "AugEvokerChannelMenu", UIParent, "BackdropTemplate")
channelMenu:SetSize(120, #channelOptions*20+8)
channelMenu:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8", edgeFile="Interface\\Buttons\\WHITE8X8", edgeSize=1})
channelMenu:SetBackdropColor(0.07, 0.07, 0.07, 0.97)
channelMenu:SetBackdropBorderColor(0.25, 0.12, 0.40, 1)
channelMenu:SetFrameStrata("DIALOG")
channelMenu:Hide()
channelMenu:SetScript("OnLeave", function()
    C_Timer.After(0.25, function() if not channelMenu:IsMouseOver() then channelMenu:Hide() end end)
end)

local channelBtns = {}
for i, opt in ipairs(channelOptions) do
    local btn = CreateFrame("Button", nil, channelMenu)
    btn:SetSize(112, 18)
    btn:SetPoint("TOPLEFT", channelMenu, "TOPLEFT", 4, -4-(i-1)*20)
    local hl = btn:CreateTexture(nil, "BACKGROUND")
    hl:SetAllPoints(); hl:SetColorTexture(0.3, 0.15, 0.5, 0)
    local fs = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    fs:SetAllPoints(); fs:SetJustifyH("LEFT"); fs:SetText("  "..opt.label)
    fs:SetTextColor(0.85, 0.85, 0.85, 1)
    btn:SetScript("OnEnter", function() hl:SetColorTexture(0.3, 0.15, 0.5, 0.5) end)
    btn:SetScript("OnLeave", function()
        hl:SetColorTexture(0, 0, 0, 0)
        local sel = selectedChannel == opt.value
        fs:SetTextColor(sel and 0.5 or 0.85, sel and 1.0 or 0.85, sel and 0.5 or 0.85, 1)
    end)
    btn:SetScript("OnClick", function()
        selectedChannel = opt.value
        for j, b in ipairs(channelBtns) do
            local sel = channelOptions[j].value == selectedChannel
            b.fs:SetTextColor(sel and 0.5 or 0.85, sel and 1.0 or 0.85, sel and 0.5 or 0.85, 1)
        end
        channelMenu:Hide()
    end)
    btn.fs = fs
    channelBtns[i] = btn
end

-- ── Footer avec boutons ──────────────────────────────────────
local footerBg = mainFrame:CreateTexture(nil, "BACKGROUND", nil, 1)
footerBg:SetPoint("BOTTOMLEFT",  mainFrame, "BOTTOMLEFT",  1, 1)
footerBg:SetPoint("BOTTOMRIGHT", mainFrame, "BOTTOMRIGHT", -1, 1)
footerBg:SetHeight(FOOTER_H - 2)
footerBg:SetColorTexture(0.10, 0.05, 0.16, 1)

local function MakeBtn(parent, text, w)
    local btn = CreateFrame("Button", nil, parent, "BackdropTemplate")
    btn:SetSize(w, 18)
    btn:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8", edgeFile="Interface\\Buttons\\WHITE8X8", edgeSize=1})
    btn:SetBackdropColor(0.20, 0.09, 0.32, 1)
    btn:SetBackdropBorderColor(0.35, 0.18, 0.55, 1)
    local fs = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    fs:SetAllPoints(); fs:SetText(text); fs:SetTextColor(0.85, 0.70, 1, 1)
    btn.fs = fs
    btn:SetScript("OnEnter", function() btn:SetBackdropColor(0.30, 0.14, 0.46, 1) end)
    btn:SetScript("OnLeave", function() btn:SetBackdropColor(0.20, 0.09, 0.32, 1) end)
    return btn
end

-- Helper pour ajouter tooltips aux boutons
local function SetButtonTooltip(btn, text)
    btn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(text)
        GameTooltip:Show()
    end)
    btn:SetScript("OnLeave", function() GameTooltip:Hide() end)
end

local reportBtn = MakeBtn(mainFrame, "Envoyer", 88)
reportBtn:SetPoint("BOTTOMLEFT", mainFrame, "BOTTOMLEFT", 8, 5)
SetButtonTooltip(reportBtn, "Envoyer les stats du combat dans le canal sélectionné")
reportBtn:SetScript("OnClick", function()
    -- Résolution du canal
    local channel
    if frozen and frozenChannel then
        channel = frozenChannel
    else
        channel = selectedChannel
        if IsInRaid() then
            if channel == "PARTY" then channel = "RAID" end
        elseif IsInGroup() then
            if channel == "RAID" then channel = "PARTY" end
        else
            if channel == "PARTY" or channel == "RAID" then channel = "SAY" end
        end
    end
    -- Construction de la liste : on ne garde que les joueurs effectivement
    -- buffés (ct > 0). Les 0% pollueraient le rapport partagé sans apporter
    -- d'info utile aux autres. Le joueur lui-même est filtré aussi (il ne
    -- se Prescience pas lui-même donc ct=0). Pour voir ses propres stats,
    -- la fenêtre principale in-game continue d'afficher tout le monde.
    local list = {}
    local source = frozen and uptimeData or GetGroupMembers()
    for name, _ in pairs(source) do
        local ct = GetPrCount(name)
        if ct > 0 then
            list[#list+1] = {name=name, emCt=GetEmCount(name), pr=GetPRUptime(name), ct=ct}
        end
    end
    table.sort(list, function(a,b)
        if math.abs(a.pr - b.pr) > 0.001 then return a.pr > b.pr end
        return a.name < b.name
    end)
    if #list == 0 then
        DEFAULT_CHAT_FRAME:AddMessage("|cFF33CC99[AugEvoker]|r Aucun joueur buffé à reporter.")
        return
    end
    -- Envoi direct depuis OnClick = pas de taint
    local lines = {}
    lines[#lines+1] = "[AugEvoker] --------------------"
    for i, d in ipairs(list) do
        local shortName = TruncateName(d.name:match("^(%S+)") or d.name, 14)
        local prStr = d.pr>=1 and math.floor(d.pr).."%" or "-"
        lines[#lines+1] = i..". "..shortName.." - Presc:x"..d.ct.." "..prStr.." EM:x"..d.emCt
    end
    lines[#lines+1] = "[AugEvoker] --------------------"
    -- Envoi séquentiel avec délai : sinon WoW throttle/réordonne les messages
    -- côté serveur quand on en envoie plusieurs d'affilée (ordre mélangé dans
    -- le chat des destinataires). 0.15s entre chaque suffit pour préserver
    -- l'ordre sans rendre l'envoi trop lent.
    local DELAY = 0.15
    for i, line in ipairs(lines) do
        C_Timer.After((i-1) * DELAY, function()
            local ok, err = pcall(function() SendChatMessage(line, channel) end)
            if not ok then
                DEFAULT_CHAT_FRAME:AddMessage("|cFFFF4444[AugEvoker]|r Erreur envoi (canal: "..channel.."): "..(err or "?"))
            end
        end)
    end
end)

local chanBtn = MakeBtn(mainFrame, "v", 28)
chanBtn:SetPoint("LEFT", reportBtn, "RIGHT", 3, 0)
SetButtonTooltip(chanBtn, "Sélectionner le canal d'envoi\n(Groupe, Raid, Guilde, etc.)")
chanBtn:SetScript("OnClick", function()
    if channelMenu:IsShown() then channelMenu:Hide()
    else
        channelMenu:ClearAllPoints()
        channelMenu:SetPoint("BOTTOMLEFT", chanBtn, "TOPLEFT", 0, 2)
        channelMenu:Show()
    end
end)

-- Poignée de redimensionnement (coin bas-droit)
local resizeGrip = CreateFrame("Button", nil, mainFrame)
resizeGrip:SetSize(14, 14)
resizeGrip:SetPoint("BOTTOMRIGHT", mainFrame, "BOTTOMRIGHT", -2, 2)
local gripTex = resizeGrip:CreateTexture(nil, "OVERLAY")
gripTex:SetAllPoints()
gripTex:SetColorTexture(0.4, 0.2, 0.6, 0.6)
-- Resize horizontal uniquement : la hauteur est recalculée par ResizeFrame
-- selon le nombre de lignes, donc un resize vertical serait annulé aussitôt.
resizeGrip:SetScript("OnMouseDown", function() mainFrame:StartSizing("RIGHT") end)
resizeGrip:SetScript("OnMouseUp",   function() mainFrame:StopMovingOrSizing(); SaveSettings() end)

-- ── Lignes de données ────────────────────────────────────────
local CLASS_COLORS = {
    WARRIOR={0.78,0.61,0.43}, PALADIN={0.96,0.55,0.73}, HUNTER={0.67,0.83,0.45},
    ROGUE={1.00,0.96,0.41},   PRIEST={1.00,1.00,1.00},  DEATHKNIGHT={0.77,0.12,0.23},
    SHAMAN={0.00,0.44,0.87},  MAGE={0.41,0.80,0.94},    WARLOCK={0.58,0.51,0.79},
    MONK={0.00,1.00,0.59},    DRUID={1.00,0.49,0.04},   DEMONHUNTER={0.64,0.19,0.79},
    EVOKER={0.20,0.58,0.50},
}

local function GetClassColor(name)
    if not classCache[name] then
        local function try(unit)
            if not UnitExists(unit) then return end
            if UnitName(unit) == name then
                local _, cf = UnitClass(unit)
                if cf then classCache[name] = cf; return true end
            end
        end
        if not try("player") then
            if IsInRaid() then
                local cnt = GetNumGroupMembers()
                for i = 1, cnt do if try("raid"..i) then break end end
            else
                local cnt = GetNumSubgroupMembers(0)
                for i = 1, cnt do if try("party"..i) then break end end
            end
        end
    end
    local cc = classCache[name] and CLASS_COLORS[classCache[name]]
    if cc then return cc[1], cc[2], cc[3] end
    return 0.9, 0.9, 0.9
end

local DATA_Y0 = TITLE_H + HDR_H + 2  -- top des données depuis le haut

local rows = {}
for i = 1, MAX_ROWS do
    local y = -(DATA_Y0 + (i-1)*ROW_H)
    local row = {}

    row.bg = mainFrame:CreateTexture(nil, "BACKGROUND", nil, 2)
    row.bg:SetPoint("TOPLEFT",  mainFrame, "TOPLEFT",  1, y)
    row.bg:SetPoint("TOPRIGHT", mainFrame, "TOPRIGHT", -1, y)
    row.bg:SetHeight(ROW_H)
    row.bg:SetColorTexture(0.07, 0.07, 0.07, 1)

    row.accent = mainFrame:CreateTexture(nil, "ARTWORK")
    row.accent:SetPoint("TOPLEFT", mainFrame, "TOPLEFT", 1, y)
    row.accent:SetSize(3, ROW_H)
    row.accent:SetColorTexture(0.5, 0.5, 0.5, 1)

    -- Barre Presc% (fond de la ligne, largeur = %)
    row.prBar = mainFrame:CreateTexture(nil, "ARTWORK", nil, 1)
    row.prBar:SetPoint("TOPLEFT", mainFrame, "TOPLEFT", 4, y)
    row.prBar:SetHeight(ROW_H)
    row.prBar:SetWidth(1)
    row.prBar:SetTexture("Interface\\TargetingFrame\\UI-StatusBar")
    row.prBar:SetVertexColor(0.3, 0.6, 1.0, 0.45)

    row.name = mainFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    row.name:SetPoint("TOPLEFT", mainFrame, "TOPLEFT", 8, y)
    row.name:SetSize(136, ROW_H)
    row.name:SetJustifyH("LEFT"); row.name:SetJustifyV("MIDDLE")
    row.name:SetWordWrap(false); row.name:SetText("")

    row.ct = mainFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    row.ct:SetPoint("TOPLEFT", mainFrame, "TOPLEFT", 146, y)
    row.ct:SetSize(36, ROW_H); row.ct:SetJustifyH("RIGHT"); row.ct:SetJustifyV("MIDDLE")
    row.ct:SetText("")

    row.pr = mainFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    row.pr:SetPoint("TOPLEFT", mainFrame, "TOPLEFT", 184, y)
    row.pr:SetSize(58, ROW_H); row.pr:SetJustifyH("RIGHT"); row.pr:SetJustifyV("MIDDLE")
    row.pr:SetText("")

    row.em = mainFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    row.em:SetPoint("TOPLEFT", mainFrame, "TOPLEFT", 244, y)
    row.em:SetSize(60, ROW_H); row.em:SetJustifyH("RIGHT"); row.em:SetJustifyV("MIDDLE")
    row.em:SetText("")

    row.bg:Hide(); row.accent:Hide(); row.prBar:Hide()
    row.name:Hide(); row.ct:Hide(); row.pr:Hide(); row.em:Hide()
    rows[i] = row
end

local function ResizeFrame(n)
    mainFrame:SetHeight(DATA_Y0 + math.max(1, n)*ROW_H + FOOTER_H)
end

local function UptimeColor(pct)
    if pct >= 80 then return 0.2, 1.0, 0.3
    elseif pct >= 50 then return 1.0, 0.85, 0.0
    elseif pct >= 20 then return 1.0, 0.45, 0.0
    else return 0.5, 0.5, 0.5 end
end

-- ── Affichage ────────────────────────────────────────────────
local function UpdateDisplay()
    -- Indicateur visuel dans le titre si stats figées
    if frozen then
        titleText:SetText("|cFFBB88FFAug Evoker|r  |cFF555555v"..ADDON_VERSION.."|r  |cFFFFAA00[FIGÉ]|r")
    else
        titleText:SetText("|cFFBB88FFAug Evoker|r  |cFF555555v"..ADDON_VERSION.."|r")
    end
    local list = {}
    if frozen then
        -- Stats figées : on affiche uptimeData directement (groupe peut être vide)
        for name, _ in pairs(uptimeData) do
            list[#list+1] = {name=name, emCt=GetEmCount(name), pr=GetPRUptime(name), ct=GetPrCount(name)}
        end
    else
        for name, _ in pairs(GetGroupMembers()) do
            list[#list+1] = {name=name, emCt=GetEmCount(name), pr=GetPRUptime(name), ct=GetPrCount(name)}
        end
    end
    table.sort(list, function(a, b)
        if math.abs(a.pr - b.pr) > 0.001 then return a.pr > b.pr end
        return a.name < b.name
    end)
    local shown = math.min(#list, MAX_ROWS)
    for i = 1, MAX_ROWS do
        local row = rows[i]; local data = list[i]
        if data and i <= shown then
            local cr, cg, cb = GetClassColor(data.name)
            row.bg:Show()
            row.accent:SetColorTexture(cr, cg, cb, 0.85); row.accent:Show()

            -- Barre Presc% (toute la largeur de la ligne, proportionnelle au %)
            local frameW = mainFrame:GetWidth() - 5
            local prW = math.max(0, math.floor(data.pr / 100 * frameW))
            if prW > 0 then
                row.prBar:SetVertexColor(cr, cg, cb, 0.75)
                row.prBar:SetWidth(prW); row.prBar:Show()
            else row.prBar:Hide() end

            row.name:SetTextColor(1, 1, 1, 1)
            row.name:SetText(TruncateName(data.name)); row.name:Show()
            if data.ct > 0 then row.ct:SetTextColor(0.8, 0.8, 0.8, 1); row.ct:SetText(tostring(data.ct))
            else row.ct:SetTextColor(0.3, 0.3, 0.3, 1); row.ct:SetText("0") end
            row.ct:Show()
            if data.pr >= 1 then
                local r,g,b = UptimeColor(data.pr)
                row.pr:SetTextColor(r, g, b, 1); row.pr:SetText(string.format("%.0f%%", data.pr))
            else row.pr:SetTextColor(0.3, 0.3, 0.3, 1); row.pr:SetText("—") end
            row.pr:Show()
            if data.emCt > 0 then
                row.em:SetTextColor(0.85, 0.6, 1.0, 1); row.em:SetText(tostring(data.emCt))
            else row.em:SetTextColor(0.3, 0.3, 0.3, 1); row.em:SetText("—") end
            row.em:Show()
        else
            row.bg:Hide(); row.accent:Hide(); row.prBar:Hide()
            row.name:Hide(); row.ct:Hide(); row.pr:Hide(); row.em:Hide()
        end
    end
    ResizeFrame(shown)
end

local optionsBtn = MakeBtn(mainFrame, "Opt", 28)
optionsBtn:SetPoint("LEFT", chanBtn, "RIGHT", 3, 0)
SetButtonTooltip(optionsBtn, "Ouvrir les paramètres\n(Couleurs, polices, textures)")
optionsBtn:SetScript("OnClick", function()
    if AugEvokerOpts then AugEvokerOpts:Toggle() end
end)

-- Fonction centralisée pour basculer freeze/unfreeze
local function ToggleFrozen()
    if frozen then
        ResetData()
        ScanAllUnits()
        DEFAULT_CHAT_FRAME:AddMessage("|cFF33CC99[AugEvoker]|r Stats dégelées — nouvelle session.")
    else
        FreezeData()
        DEFAULT_CHAT_FRAME:AddMessage("|cFF33CC99[AugEvoker]|r Stats figées. Clique sur |cFFFFAA00Envoyer|r pour partager.")
    end
end

-- Bouton Geler / Dégeler (freeze manuel pour donjons normaux/héroïques)
local freezeBtn = MakeBtn(mainFrame, "Geler", 52)
freezeBtn:SetPoint("LEFT", optionsBtn, "RIGHT", 3, 0)
freezeBtn:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:SetText(frozen and "Dégeler pour une nouvelle session" or "Figer les stats du combat actuel")
    GameTooltip:Show()
end)
freezeBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
freezeBtn:SetScript("OnClick", function()
    ToggleFrozen()
end)

-- Mettre à jour le texte du bouton selon l'état
local lastFrozenState = frozen
C_Timer.NewTicker(0.5, function()
    if frozen ~= lastFrozenState then
        lastFrozenState = frozen
        freezeBtn.fs:SetText(frozen and "|cFFFFAA00Dégeler|r" or "Geler")
    end
end)

-- Expose la frame pour Options.lua
AugEvokerMain = mainFrame
AugEvokerMain.rows = rows
AugEvokerMain.titleText = titleText
AugEvokerMain.addonVersion = ADDON_VERSION

-- Mise à jour affichage toutes les 0.1s pour réactivité immédiate
C_Timer.NewTicker(0.1, function()
    if mainFrame:IsShown() then UpdateDisplay() end
end)

-- ============================================================
--  SLASH
-- ============================================================
SLASH_AUGEVOKER1="/aug"
SLASH_AUGEVOKER2="/augevoker"
SlashCmdList["AUGEVOKER"]=function(msg)
    msg=msg and msg:lower() or ""
    if msg=="reset" then
        ResetData(); ScanAllUnits()
        DEFAULT_CHAT_FRAME:AddMessage("|cFF33CC99[AugEvoker]|r Données réinitialisées.")
    elseif msg=="options" or msg=="opt" then
        if AugEvokerOpts then AugEvokerOpts:Toggle() end
    elseif msg=="freeze" or msg=="gel" then
        ToggleFrozen()
    elseif msg=="hide" then mainFrame:Hide()
    elseif msg=="show" then mainFrame:Show()
    elseif msg=="unfreeze" then
        if frozen then ToggleFrozen() else
            DEFAULT_CHAT_FRAME:AddMessage("|cFF33CC99[AugEvoker]|r Stats déjà dégelées.")
        end
    elseif msg=="report" or msg=="r" then
        -- SendChatMessage depuis un slash command est tainted par WoW.
        -- Utiliser le bouton "Envoyer" de l'interface à la place.
        DEFAULT_CHAT_FRAME:AddMessage("|cFF33CC99[AugEvoker]|r Utilise le bouton |cFFFFAA00Envoyer|r dans la fenêtre.")
        mainFrame:Show()
    elseif msg=="scan" then
        for name,unit in pairs(GetGroupMembers()) do
            local i=1
            while true do
                local aura=C_UnitAuras.GetAuraDataByIndex(unit,i,"HELPFUL")
                if not aura then break end
                local sid=aura.spellId
                local aname=aura.name
                local sidStr=(sid and not issecretvalue(sid)) and tostring(sid) or "SECRET"
                local nameStr=(aname and not issecretvalue(aname)) and aname or "SECRET"
                DEFAULT_CHAT_FRAME:AddMessage(string.format("|cFF33CC99[AugScan]|r %s: [%s] '%s'",name,sidStr,nameStr))
                i=i+1
            end
        end
    else
        if mainFrame:IsShown() then mainFrame:Hide() else mainFrame:Show() end
    end
end

-- ============================================================
--  SAUVEGARDE / CHARGEMENT (SavedVariables = AugEvokerDB)
-- ============================================================
function SaveSettings()
    if not AugEvokerDB then AugEvokerDB = {} end
    AugEvokerDB.selectedChannel = selectedChannel
    -- Position de la frame
    local point, _, relPoint, x, y = mainFrame:GetPoint()
    if point then
        AugEvokerDB.framePos = {point=point, relPoint=relPoint, x=x, y=y}
    end
    -- Largeur de la frame (la hauteur est calculée selon le nombre de lignes)
    AugEvokerDB.frameSize = {w = mainFrame:GetWidth()}
end

local function LoadSettings()
    if not AugEvokerDB then return end
    -- Canal : juste restaurer la valeur, les boutons UI sont déjà construits à ce stade
    if AugEvokerDB.selectedChannel then
        selectedChannel = AugEvokerDB.selectedChannel
        -- Rafraîchir la couleur des boutons canal (channelBtns est déjà construit)
        for i, b in ipairs(channelBtns) do
            if channelOptions[i] then
                local sel = channelOptions[i].value == selectedChannel
                b.fs:SetTextColor(sel and 0.5 or 0.85, sel and 1.0 or 0.85, sel and 0.5 or 0.85, 1)
            end
        end
    end
    -- Position et taille de la frame
    if AugEvokerDB.framePos then
        local p = AugEvokerDB.framePos
        mainFrame:ClearAllPoints()
        mainFrame:SetPoint(p.point, UIParent, p.relPoint, p.x, p.y)
    end
    if AugEvokerDB.frameSize and AugEvokerDB.frameSize.w then
        mainFrame:SetWidth(AugEvokerDB.frameSize.w)
    end
end

-- Sauvegarde automatique quand le joueur quitte le jeu
local saveFrame = CreateFrame("Frame")
saveFrame:RegisterEvent("PLAYER_LOGOUT")
saveFrame:SetScript("OnEvent", function() SaveSettings() end)

-- Sauvegarde quand on change le canal
for _, btn in ipairs(channelBtns) do
    btn:HookScript("OnClick", function() SaveSettings() end)
end

-- ============================================================
--  INIT
-- ============================================================
local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("PLAYER_LOGIN")
initFrame:SetScript("OnEvent",function(self)
    self:UnregisterAllEvents()
    -- Initialiser la base de données si nécessaire
    AugEvokerDB = AugEvokerDB or {}
    -- GUID du joueur pour filtrer le combat log
    playerGUID = UnitGUID("player")
    -- Récupère les noms exacts des sorts dans la langue du client
    if C_Spell and C_Spell.GetSpellName then
        PRESC_SPELL_NAME = C_Spell.GetSpellName(PRESCIENCE_BUFF_ID)
    end
    -- Charge les paramètres sauvegardés (position, taille, canal, etc.)
    LoadSettings()
    mainFrame:Show()  -- afficher APRÈS LoadSettings pour éviter le scintillement
    C_Timer.After(0.1, function()
        ScanAllUnits()
        UpdateDisplay()
    end)
    DEFAULT_CHAT_FRAME:AddMessage(string.format(
        "|cFF33CC99[AugEvoker]|r v%s — Presc='%s'",
        ADDON_VERSION,
        PRESC_SPELL_NAME or "?"
    ))
end)

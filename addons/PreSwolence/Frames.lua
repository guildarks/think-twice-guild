local addonName, ns = ...

---------------------------------------------------------------------------
-- Constants (static)
---------------------------------------------------------------------------
local function CD_ICON_SIZE() return ns.settings.cdIconSize or 32 end
local CONTAINER_PADDING = 8
local CLASS_COLORS      = RAID_CLASS_COLORS
local IN_RANGE_ALPHA    = 1.0
local FLAT_TEX  = "Interface\\Buttons\\WHITE8X8"
local SPARK_TEX = "Interface\\CastingBar\\UI-CastingBar-Spark"

-- Dynamic helpers — always read live from ns.settings
local function S(key, fallback)
    local v = ns.settings[key]
    if v == nil then return fallback end
    return v
end
local function BAR_WIDTH()     return S("barWidth",     160) end
local function BAR_HEIGHT()    return S("barHeight",    28)  end
local function EM_BAR_HEIGHT() return S("emBarHeight",  22)  end
local function FRAME_SPACING() return S("frameSpacing", 4)   end
local function RANGE_ALPHA()   return S("rangeAlpha",   0.35) end
local function FONT_SIZE()     return S("fontSize",     10)  end

---------------------------------------------------------------------------
-- Forward declarations
---------------------------------------------------------------------------
local container   -- kept as dummy for legacy compat
local cdTracker
local ReflowFrames

---------------------------------------------------------------------------
-- Per-frame drag & save
---------------------------------------------------------------------------
local DEFAULT_POSITIONS = {
    -- Ebon Might per-slot bars (left column)
    em1       = { "CENTER", "UIParent", "CENTER", -300, 100 },
    em2       = { "CENTER", "UIParent", "CENTER", -300,  74 },
    em3       = { "CENTER", "UIParent", "CENTER", -300,  48 },
    em4       = { "CENTER", "UIParent", "CENTER", -300,  22 },
    -- Prescience per-slot bars (right column)
    slot1     = { "CENTER", "UIParent", "CENTER", -100, 100 },
    slot2     = { "CENTER", "UIParent", "CENTER", -100,  72 },
    slot3     = { "CENTER", "UIParent", "CENTER", -100,  40 },
    slot4     = { "CENTER", "UIParent", "CENTER", -100,   8 },
    cdTracker = { "CENTER", "UIParent", "CENTER", -100, -28 },
    -- Searing Scales tank bars
    tank1     = { "CENTER", "UIParent", "CENTER", -100, -60 },
    tank2     = { "CENTER", "UIParent", "CENTER", -100, -88 },
}

local function SaveFramePos(key, frame)
    if not PreSwolenceDB then return end
    if not PreSwolenceDB.framePositions then PreSwolenceDB.framePositions = {} end
    local point, _, relPoint, x, y = frame:GetPoint()
    PreSwolenceDB.framePositions[key] = { point=point, relPoint=relPoint, x=x, y=y }
end

local function RestoreFramePos(key, frame, default)
    local pos = PreSwolenceDB and PreSwolenceDB.framePositions and PreSwolenceDB.framePositions[key]
    frame:ClearAllPoints()
    if pos then
        frame:SetPoint(pos.point, UIParent, pos.relPoint, pos.x, pos.y)
    else
        frame:SetPoint(default[1], _G[default[2]] or UIParent, default[3], default[4], default[5])
    end
end

local function MakeDraggable(frame, posKey, defaultPos)
    frame:SetMovable(true)
    frame:SetClampedToScreen(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", function(self)
        if not ns.settings.locked and not InCombatLockdown() then self:StartMoving() end
    end)
    frame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        SaveFramePos(posKey, self)
    end)
    frame:SetScript("OnMouseUp", function(self, button)
        if button == "RightButton" then
            if not ns.optionsFrame and ns.BuildOptionsPanel then ns.BuildOptionsPanel() end
            if ns.optionsFrame then ns.optionsFrame:SetShown(not ns.optionsFrame:IsShown()) end
        end
    end)
    RestoreFramePos(posKey, frame, defaultPos)
end

---------------------------------------------------------------------------
-- Reflow: just show/hide — positions are independent
---------------------------------------------------------------------------
ReflowFrames = function()
    if InCombatLockdown() then return end

    local showEM = S("showEbonMight", true)
    -- hiddenSlots: table of booleans keyed by "pres_1".."pres_4", "em_1".."em_4", "tank_1"
    local hidden = ns.settings.hiddenSlots or {}
    if ns.emFrames then
        for i = 1, ns.NUM_SLOTS do
            if ns.emFrames[i] then
                local t = ns.targets and ns.targets[i]
                local isDPS = not t or (not t.isHealer and not t.isTank)
                local show = showEM and ns.unitTokens[i] and isDPS and not hidden["em_" .. i]
                ns.emFrames[i]:SetShown(show and true or false)
                if show then ns.emFrames[i]:UpdateUnitInfo() end
            end
        end
    end
    local showPres = ns.settings.showFrames and S("showPrescience", true)
    for i = 1, ns.NUM_SLOTS do
        local frame = ns.frames[i]
        if frame then
            local show = showPres and ns.unitTokens[i] and not hidden["pres_" .. i]
            frame:SetShown(show and true or false)
        end
    end
    -- Tank frames (Searing Scales)
    if ns.tankFrames then
        for i = 1, (ns.TANK_SLOTS or 1) do
            local tf = ns.tankFrames[i]
            local hasUnit = ns.tankUnitTokens and ns.tankUnitTokens[i]
            if tf then
                local show = ns.settings.showFrames and hasUnit and not hidden["tank_" .. i]
                tf:SetShown(show and true or false)
                if show then tf:UpdateUnitInfo() end
            end
        end
    end
    if cdTracker then
        cdTracker:SetShown(ns.settings.showFrames and ns.settings.showCDTracker and true or false)
    end
end

ns.ReflowFrames = ReflowFrames

---------------------------------------------------------------------------
-- Dummy container (legacy compat for UpdateFrameScale etc.)
---------------------------------------------------------------------------
local function CreateContainer()
    if not container then
        container = CreateFrame("Frame", "PreSwolenceContainer", UIParent)
        container:SetSize(1, 1); container:SetPoint("CENTER"); container:Hide()
    end
    ns.container = container
end

---------------------------------------------------------------------------
-- Ebon Might self-buff bar
---------------------------------------------------------------------------
local function CreateEbonMightFrame(slot)
    local posKey = "em" .. slot
    local defaultPos = {
        "CENTER", "UIParent", "CENTER",
        -200,
        100 - (slot - 1) * (22 + 4)  -- stacked below each other by default
    }

    local frameName = "PreSwolenceEbonMight" .. slot
    local frame = _G[frameName] or CreateFrame("Frame", frameName, UIParent, "BackdropTemplate")
    frame:SetParent(UIParent)
    frame:ClearAllPoints()
    frame:SetSize(BAR_WIDTH(), EM_BAR_HEIGHT())

    if frame.initialized then
        RestoreFramePos(posKey, frame, defaultPos)
        return frame
    end
    frame.initialized = true

    frame:SetBackdrop({
        bgFile = FLAT_TEX,
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = false, edgeSize = ns:GetEdgeSize(10),
        insets = { left = 2, right = 2, top = 2, bottom = 2 },
    })
    frame:SetBackdropColor(0.06, 0.04, 0.10, 0.92)
    frame:SetBackdropBorderColor(S("emInactiveBorderR",0.28), S("emInactiveBorderG",0.10), S("emInactiveBorderB",0.42), S("emShowBorder",true) and 1 or 0)

    -- Dark track
    local track = frame:CreateTexture(nil, "BACKGROUND")
    track:SetTexture(FLAT_TEX)
    track:SetVertexColor(0.08, 0.05, 0.14, 1)
    track:SetPoint("TOPLEFT",     frame, "TOPLEFT",     2, -2)
    track:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -2, 2)

    -- Fill bar
    local timerBar = CreateFrame("StatusBar", nil, frame)
    timerBar:SetPoint("TOPLEFT",     frame, "TOPLEFT",     2, -2)
    timerBar:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -2, 2)
    timerBar:SetStatusBarTexture(ns:GetBarTexture(FLAT_TEX))
    timerBar:SetMinMaxValues(0, 1)
    timerBar:SetValue(0)
    timerBar:SetStatusBarColor(S("emFullR",0.957), S("emFullG",0.447), S("emFullB",0.714), 0.78)
    timerBar:EnableMouse(false)
    frame.timerBar = timerBar

    -- Accent line
    local accent = frame:CreateTexture(nil, "ARTWORK")
    accent:SetTexture(FLAT_TEX)
    accent:SetVertexColor(S("emAccentR",0.72), S("emAccentG",0.28), S("emAccentB",1.0), 1)
    accent:SetSize(3, EM_BAR_HEIGHT() - 4)
    accent:SetPoint("LEFT", frame, "LEFT", 2, 0)
    frame.accent = accent

    -- Spark
    local spark = timerBar:CreateTexture(nil, "OVERLAY")
    spark:SetSize(10, EM_BAR_HEIGHT() + 4)
    spark:SetPoint("CENTER", timerBar:GetStatusBarTexture(), "RIGHT", 0, 0)
    spark:SetTexture(SPARK_TEX)
    spark:SetBlendMode("ADD")
    spark:SetVertexColor(0.8, 0.4, 1.0, 1)
    spark:Hide()
    frame.spark = spark

    -- Name text (left)
    local nameText = timerBar:CreateFontString(nil, "OVERLAY")
    nameText:SetFont(ns:GetFontPath("Fonts\\FRIZQT__.TTF"), FONT_SIZE() - 1, S("fontOutline","OUTLINE"))
    nameText:SetPoint("LEFT",  frame, "LEFT",  8, 0)
    nameText:SetPoint("RIGHT", frame, "RIGHT", -30, 0)
    nameText:SetJustifyH("LEFT")
    nameText:SetText("|cffF472B6Ebon Might|r")
    frame.nameText = nameText

    -- Timer text (right)
    local timerText = timerBar:CreateFontString(nil, "OVERLAY")
    timerText:SetFont(ns:GetFontPath("Fonts\\FRIZQT__.TTF"), FONT_SIZE(), S("fontOutline","OUTLINE"))
    timerText:SetPoint("RIGHT", frame, "RIGHT", -5, 0)
    timerText:SetJustifyH("RIGHT")
    timerText:SetText("")
    frame.timerText = timerText

    frame.buffDuration = nil

    function frame:UpdateTimer(remaining)
        if remaining and remaining > 0 then
            local dur = self.buffDuration or ns.EBON_MIGHT_DURATION
            self.timerBar:SetValue(remaining / dur)
            self.timerText:SetText(format("%.1f", remaining))
            local pct = remaining / dur
            if pct > 0.4 then
                self.timerBar:SetStatusBarColor(S("emFullR",0.52), S("emFullG",0.18), S("emFullB",0.82), 0.78)
            elseif pct > 0.2 then
                self.timerBar:SetStatusBarColor(S("emMidR",0.80), S("emMidG",0.45), S("emMidB",0.0), 0.82)
            else
                self.timerBar:SetStatusBarColor(S("emLowR",0.9), S("emLowG",0.15), S("emLowB",0.15), 0.85)
            end
            self.spark:Show()
        else
            self.timerBar:SetValue(0)
            self.timerText:SetText("")
            self.spark:Hide()
        end
    end

    -- Update name from unit token
    function frame:UpdateUnitInfo()
        local unit = ns.unitTokens[slot]
        if unit and UnitExists(unit) then
            self.nameText:SetText("|cffaa44ff[EM]|r " .. (UnitName(unit) or "?"))
        else
            self.nameText:SetText("|cffaa44ffEbon Might|r")
        end
    end

    -- Range fade (reuse Prescience range check)
    local rangeElapsed = 0
    frame:SetScript("OnUpdate", function(self, dt)
        rangeElapsed = rangeElapsed + dt
        if rangeElapsed < 0.3 then return end
        rangeElapsed = 0
        local unit = ns.unitTokens[slot]
        if unit and UnitExists(unit) then
            local ok, inRange = pcall(C_Spell.IsSpellInRange, ns.EBON_MIGHT_CAST_ID, unit)
            if ok and not issecretvalue(inRange) and inRange == false then
                self:SetAlpha(RANGE_ALPHA())
            else
                self:SetAlpha(IN_RANGE_ALPHA)
            end
        end
    end)

    MakeDraggable(frame, posKey, defaultPos)
    frame:SetShown(false)
    return frame
end

---------------------------------------------------------------------------
-- Target slot frame (modern flat style)
---------------------------------------------------------------------------

local function CreateTargetFrame(slot)
    local frame = _G["PreSwolenceFrame" .. slot] or CreateFrame("Button", "PreSwolenceFrame" .. slot, UIParent, "SecureUnitButtonTemplate")
    frame:SetParent(UIParent)
    frame:ClearAllPoints()
    frame.slot = slot
    frame:SetSize(BAR_WIDTH(), BAR_HEIGHT())
    frame:SetAttribute("type1", "spell")
    frame:SetAttribute("spell", "Prescience")
    frame:SetAttribute("type2", "target")
    frame:RegisterForClicks("AnyUp")

    if frame.initialized then
        -- Frame already built, just update sizes/colors
        local posKey2 = "slot" .. slot
        RestoreFramePos(posKey2, frame, DEFAULT_POSITIONS[posKey2] or DEFAULT_POSITIONS.slot1)
        if frame.barFrame then
            local borderAlpha = S("presShowBorder", true) and 1 or 0
            frame.barFrame:SetBackdropBorderColor(S("presInactiveBorderR",0.35), S("presInactiveBorderG",0.35), S("presInactiveBorderB",0.35), borderAlpha)
        end
        if frame.accent then frame.accent:SetSize(3, BAR_HEIGHT() - 4) end
        if frame.spark  then frame.spark:SetSize(10, BAR_HEIGHT() + 4) end
        if frame.nameText  then frame.nameText:SetFont(ns:GetFontPath("Fonts\\FRIZQT__.TTF"), FONT_SIZE(), S("fontOutline","OUTLINE")) end
        if frame.timerText then frame.timerText:SetFont(ns:GetFontPath("Fonts\\FRIZQT__.TTF"), FONT_SIZE(), S("fontOutline","OUTLINE")) end
        return frame
    end
    frame.initialized = true

    local barFrame = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    barFrame:SetAllPoints()
    barFrame:SetBackdrop({
        bgFile = FLAT_TEX,
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = false, edgeSize = ns:GetEdgeSize(10),
        insets = { left = 2, right = 2, top = 2, bottom = 2 },
    })
    barFrame:SetBackdropColor(0.06, 0.06, 0.08, 0.92)
    local borderAlpha = S("presShowBorder", true) and 1 or 0
    barFrame:SetBackdropBorderColor(S("presInactiveBorderR",0.35), S("presInactiveBorderG",0.35), S("presInactiveBorderB",0.35), borderAlpha)
    barFrame:EnableMouse(false)
    frame.barFrame = barFrame

    -- Dark track
    local track = barFrame:CreateTexture(nil, "BACKGROUND")
    track:SetTexture(FLAT_TEX)
    track:SetVertexColor(0.03, 0.03, 0.04, 1)
    track:SetPoint("TOPLEFT",     barFrame, "TOPLEFT",     2, -2)
    track:SetPoint("BOTTOMRIGHT", barFrame, "BOTTOMRIGHT", -2, 2)

    -- Fill
    local timerBar = CreateFrame("StatusBar", nil, barFrame)
    timerBar:SetPoint("TOPLEFT",     barFrame, "TOPLEFT",     2, -2)
    timerBar:SetPoint("BOTTOMRIGHT", barFrame, "BOTTOMRIGHT", -2, 2)
    timerBar:SetStatusBarTexture(ns:GetBarTexture(FLAT_TEX))
    timerBar:SetMinMaxValues(0, 1)
    timerBar:SetValue(0)
    timerBar:SetStatusBarColor(0.655, 0.545, 0.980, 0.72)
    timerBar:EnableMouse(false)
    frame.timerBar = timerBar

    -- Left accent line (class-coloured later)
    local accent = barFrame:CreateTexture(nil, "ARTWORK")
    accent:SetTexture(FLAT_TEX)
    accent:SetVertexColor(0.5, 0.5, 0.5, 1)
    accent:SetSize(3, BAR_HEIGHT() - 4)
    accent:SetPoint("LEFT", barFrame, "LEFT", 2, 0)
    frame.accent = accent

    -- Spark
    local spark = timerBar:CreateTexture(nil, "OVERLAY")
    spark:SetSize(10, BAR_HEIGHT() + 4)
    spark:SetPoint("CENTER", timerBar:GetStatusBarTexture(), "RIGHT", 0, 0)
    spark:SetTexture(SPARK_TEX)
    spark:SetBlendMode("ADD")
    spark:Hide()
    frame.spark = spark

    -- Name text
    local nameText = timerBar:CreateFontString(nil, "OVERLAY")
    nameText:SetFont(ns:GetFontPath("Fonts\\FRIZQT__.TTF"), FONT_SIZE(), S("fontOutline","OUTLINE"))
    nameText:SetPoint("LEFT",  barFrame, "LEFT",  8, 0)
    nameText:SetPoint("RIGHT", barFrame, "RIGHT", -30, 0)
    nameText:SetJustifyH("LEFT")
    nameText:SetText("Slot " .. slot)
    frame.nameText = nameText

    -- Timer text
    local timerText = timerBar:CreateFontString(nil, "OVERLAY")
    timerText:SetFont(ns:GetFontPath("Fonts\\FRIZQT__.TTF"), FONT_SIZE(), S("fontOutline","OUTLINE"))
    timerText:SetPoint("RIGHT", barFrame, "RIGHT", -5, 0)
    timerText:SetJustifyH("RIGHT")
    frame.timerText = timerText

    frame:SetScript("OnAttributeChanged", function(self, name, value)
        if name == "unit" then self:UpdateUnitInfo() end
    end)

    function frame:UpdateUnitInfo()
        local unit = self:GetAttribute("unit")
        if not unit or not UnitExists(unit) then return end
        self.nameText:SetShown(not S("hideName", false))
        self.nameText:SetTextColor(S("nameColorR",1), S("nameColorG",1), S("nameColorB",1), 1)
        self.nameText:SetText(UnitName(unit) or "?")
        local _, class = UnitClass(unit)
        local color = class and CLASS_COLORS[class]
        if color then
            self.barFrame:SetBackdropColor(color.r * 0.12, color.g * 0.12, color.b * 0.12, 0.92)
            self.accent:SetVertexColor(color.r, color.g, color.b, 1)
        end
    end

    frame.buffDuration = nil

    function frame:UpdateTimer(remaining)
        local showBorder = S("presShowBorder", true)
        if remaining and remaining > 0 then
            local bAlpha = showBorder and 1 or 0
            self.barFrame:SetBackdropBorderColor(S("presActiveBorderR",0.20), S("presActiveBorderG",0.80), S("presActiveBorderB",0.20), bAlpha)
            local dur = self.buffDuration or ns.PRESCIENCE_DURATION
            self.timerBar:SetValue(remaining / dur)
            self.timerText:SetShown(S("ssShowTimer", true))
            if self.iconTimer then self.iconTimer:SetShown(S("ssShowTimer", true)) end
            self.timerText:SetTextColor(S("timerColorR",1), S("timerColorG",1), S("timerColorB",1), 1)
            self.timerText:SetText(format("%.0f", remaining))
            local pct = remaining / dur
            if pct > 0.5 then
                self.timerBar:SetStatusBarColor(S("presFullR",0.12), S("presFullG",0.72), S("presFullB",0.18), 0.75)
            elseif pct > 0.25 then
                self.timerBar:SetStatusBarColor(S("presMidR",0.85), S("presMidG",0.62), S("presMidB",0.0), 0.78)
            else
                self.timerBar:SetStatusBarColor(S("presLowR",0.85), S("presLowG",0.12), S("presLowB",0.12), 0.82)
            end
            self.spark:Show()
        else
            local bAlpha = S("presShowBorder", true) and 1 or 0
            self.barFrame:SetBackdropBorderColor(S("presInactiveBorderR",0.35), S("presInactiveBorderG",0.35), S("presInactiveBorderB",0.35), bAlpha)
            self.timerBar:SetValue(0)
            self.timerText:SetText("")
            self.spark:Hide()
        end
    end

    -- Range fade
    local rangeElapsed = 0
    frame:SetScript("OnUpdate", function(self, dt)
        rangeElapsed = rangeElapsed + dt
        if rangeElapsed < 0.2 then return end
        rangeElapsed = 0
        local unit = self:GetAttribute("unit")
        if not unit or not UnitExists(unit) then return end
        local ok, inRange = pcall(C_Spell.IsSpellInRange, ns.PRESCIENCE_CAST_ID, unit)
        if ok and not issecretvalue(inRange) and inRange == false then
            self:SetAlpha(RANGE_ALPHA())
        else
            self:SetAlpha(IN_RANGE_ALPHA)
        end
    end)

    if ClickCastFrames then ClickCastFrames[frame] = true end

    local posKey = "slot" .. slot
    MakeDraggable(frame, posKey, DEFAULT_POSITIONS[posKey] or DEFAULT_POSITIONS.slot1)
    frame:SetShown(false)
    return frame
end

---------------------------------------------------------------------------
-- Prescience CD tracker (wide bar style to match)
---------------------------------------------------------------------------
local function CreateCDTracker()
    local CAST_ID = ns.PRESCIENCE_CAST_ID

    cdTracker = _G["PreSwolenceCDTracker"] or CreateFrame("Frame", "PreSwolenceCDTracker", UIParent, "BackdropTemplate")
    cdTracker:SetParent(UIParent)
    cdTracker:ClearAllPoints()
    cdTracker:SetSize(BAR_WIDTH(), CD_ICON_SIZE())
    if cdTracker.initialized then
        cdTracker:Show()
        RestoreFramePos("cdTracker", cdTracker, DEFAULT_POSITIONS.cdTracker)
        return cdTracker
    end
    cdTracker.initialized = true
    cdTracker:EnableMouse(false)
    cdTracker:SetBackdrop({
        bgFile = FLAT_TEX,
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = false, edgeSize = ns:GetEdgeSize(10),
        insets = { left = 2, right = 2, top = 2, bottom = 2 },
    })
    cdTracker:SetBackdropColor(0.05, 0.05, 0.07, 0.88)
    cdTracker:SetBackdropBorderColor(0.545, 0.360, 0.965, 0.9)

    -- Icon
    local iconFrame = CreateFrame("Frame", nil, cdTracker)
    iconFrame:SetSize(CD_ICON_SIZE() - 4, CD_ICON_SIZE() - 4)
    iconFrame:SetPoint("LEFT", cdTracker, "LEFT", 3, 0)
    cdTracker.iconFrame = iconFrame  -- expose for UpdateFrameSettings

    local icon = iconFrame:CreateTexture(nil, "BACKGROUND")
    icon:SetAllPoints()
    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    local cooldown = CreateFrame("Cooldown", nil, iconFrame, "CooldownFrameTemplate")
    cooldown:SetAllPoints()
    cooldown:SetDrawEdge(true)
    cooldown:SetDrawSwipe(true)
    cooldown:SetSwipeColor(0, 0, 0, 0.75)
    cdTracker.cooldown = cooldown

    local chargeText = iconFrame:CreateFontString(nil, "OVERLAY")
    chargeText:SetFont(ns:GetFontPath("Fonts\\FRIZQT__.TTF"), 11, S("fontOutline","OUTLINE"))
    chargeText:SetPoint("BOTTOMRIGHT", iconFrame, "BOTTOMRIGHT", -1, 1)
    cdTracker.chargeText = chargeText

    -- Label
    local label = cdTracker:CreateFontString(nil, "OVERLAY")
    label:SetFont(ns:GetFontPath("Fonts\\FRIZQT__.TTF"), FONT_SIZE(), S("fontOutline","OUTLINE"))
    label:SetPoint("LEFT", iconFrame, "RIGHT", 5, 4)
    label:SetText("|cff55aaffPrescience|r")

    -- Thin recharge bar below label
    local chargeBarBg = cdTracker:CreateTexture(nil, "ARTWORK")
    chargeBarBg:SetTexture(FLAT_TEX)
    chargeBarBg:SetVertexColor(0.08, 0.08, 0.12, 1)
    chargeBarBg:SetPoint("LEFT",  iconFrame, "RIGHT", 5, -5)
    chargeBarBg:SetPoint("RIGHT", cdTracker, "RIGHT", -4, -5)
    chargeBarBg:SetHeight(4)

    local chargeBarFill = CreateFrame("StatusBar", nil, cdTracker)
    chargeBarFill:SetPoint("LEFT",  iconFrame, "RIGHT", 5, -5)
    chargeBarFill:SetPoint("RIGHT", cdTracker, "RIGHT", -4, -5)
    chargeBarFill:SetHeight(4)
    chargeBarFill:SetStatusBarTexture(FLAT_TEX)
    chargeBarFill:SetMinMaxValues(0, 1)
    chargeBarFill:SetValue(0)
    chargeBarFill:SetStatusBarColor(0.545, 0.360, 0.965, 0.9)
    cdTracker.chargeBarFill = chargeBarFill

    ---------------------------------------------------------------------------
    local trackedCharges     = 2
    local trackedMaxCharges  = 2
    local trackedRechargeDur = 12
    local rechargeStartTime  = nil

    local function TrySyncFromAPI()
        local ok, charges = pcall(C_Spell.GetSpellCharges, CAST_ID)
        if not ok or issecretvalue(charges) or not charges then return false end
        local cur, maxC = charges.currentCharges, charges.maxCharges
        local cdStart, cdDur = charges.cooldownStartTime, charges.cooldownDuration
        if issecretvalue(cur) or issecretvalue(maxC) or not cur or not maxC then return false end
        if not issecretvalue(cdDur) and cdDur and cdDur > 0 then trackedRechargeDur = cdDur end
        trackedCharges = cur; trackedMaxCharges = maxC
        if not issecretvalue(cdStart) and cdStart and cdStart > 0
            and not issecretvalue(cdDur) and cdDur and cdDur > 0 and cur < maxC then
            rechargeStartTime = cdStart
            cooldown:SetCooldown(cdStart, cdDur)
        elseif cur >= maxC then
            rechargeStartTime = nil; cooldown:Clear()
        end
        return true
    end

    local function OnPrescienceCast()
        trackedCharges = math.max(0, trackedCharges - 1)
        if trackedCharges == trackedMaxCharges - 1 then
            rechargeStartTime = GetTime()
            cooldown:SetCooldown(rechargeStartTime, trackedRechargeDur)
        end
    end
    cdTracker.OnPrescienceCast = OnPrescienceCast

    local cdEventFrame = CreateFrame("Frame")
    cdEventFrame:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
    cdEventFrame:SetScript("OnEvent", function(_, event, unit, castGUID, spellID)
        if unit ~= "player" then return end
        if issecretvalue(spellID) or spellID ~= CAST_ID then return end
        OnPrescienceCast()
    end)

    local iconResolved = false
    local function TrySetIcon()
        local ok, tex
        ok, tex = pcall(C_Spell.GetSpellTexture, CAST_ID)
        if ok and tex and not issecretvalue(tex) then icon:SetTexture(tex); return true end
        if C_SpellBook and C_SpellBook.FindSpellBookSlotForSpell then
            ok, tex = pcall(function()
                local slot = C_SpellBook.FindSpellBookSlotForSpell(CAST_ID)
                if slot then return C_SpellBook.GetSpellBookItemTexture(slot, Enum.SpellBookSpellBank.Player) end
            end)
            if ok and tex and not issecretvalue(tex) then icon:SetTexture(tex); return true end
        end
        if GetSpellTexture then
            ok, tex = pcall(GetSpellTexture, CAST_ID)
            if ok and tex and not issecretvalue(tex) then icon:SetTexture(tex); return true end
        end
        return false
    end
    iconResolved = TrySetIcon()

    local elapsed = 0
    cdTracker:SetScript("OnUpdate", function(self, dt)
        elapsed = elapsed + dt
        if elapsed < 0.1 then return end
        elapsed = 0
        if not iconResolved then iconResolved = TrySetIcon() end
        local apiWorked = TrySyncFromAPI()
        if not apiWorked then
            if rechargeStartTime then
                local e = GetTime() - rechargeStartTime
                if e >= trackedRechargeDur then
                    trackedCharges = math.min(trackedMaxCharges, trackedCharges + 1)
                    if trackedCharges < trackedMaxCharges then
                        rechargeStartTime = rechargeStartTime + trackedRechargeDur
                        cooldown:SetCooldown(rechargeStartTime, trackedRechargeDur)
                    else
                        rechargeStartTime = nil; cooldown:Clear()
                    end
                end
            end
        end
        chargeText:SetText(trackedMaxCharges > 1 and trackedCharges or "")
        local basePct = trackedCharges / trackedMaxCharges
        local rechargePct = 0
        if trackedCharges < trackedMaxCharges and rechargeStartTime then
            rechargePct = math.min((GetTime() - rechargeStartTime) / trackedRechargeDur, 1) / trackedMaxCharges
        end
        chargeBarFill:SetValue(math.min(basePct + rechargePct, 1))
        if trackedCharges >= trackedMaxCharges then
            cdTracker:SetBackdropBorderColor(0.22, 0.72, 0.28, 0.9)
        elseif trackedCharges > 0 then
            cdTracker:SetBackdropBorderColor(0.82, 0.62, 0.0, 0.9)
        else
            cdTracker:SetBackdropBorderColor(0.82, 0.12, 0.12, 0.9)
        end
    end)

    TrySyncFromAPI()
    MakeDraggable(cdTracker, "cdTracker", DEFAULT_POSITIONS.cdTracker)
    cdTracker:SetShown(false)
    return cdTracker
end

---------------------------------------------------------------------------
-- Tank frame (Searing Scales / Ecaille torride)
-- Style: icon + name + timer + duration bar (like CDTracker)
---------------------------------------------------------------------------

local function CreateTankFrame(tankSlot)
    local posKey    = "tank" .. tankSlot
    local defaultPos = DEFAULT_POSITIONS[posKey] or DEFAULT_POSITIONS.tank1
    local SS_CAST_ID = ns.SEARING_SCALES_CAST_ID or 370817

    local frameName = "PreSwolenceTankFrame" .. tankSlot
    -- Force fresh creation if the old frame was a bar-style frame
    local frame = _G[frameName]
    if frame and frame.initialized and not frame.isIconStyle then
        -- Old bar-style frame — destroy and recreate
        frame:Hide()
        frame:SetParent(nil)
        _G[frameName] = nil
        frame = nil
    end
    frame = frame or CreateFrame("Frame", frameName, UIParent, "BackdropTemplate")
    frame:SetParent(UIParent)
    frame:ClearAllPoints()
    frame.tankSlot = tankSlot

    local sz = S("ssIconSize", 32)
    frame:SetSize(BAR_WIDTH(), sz)

    if frame.initialized then
        -- Already icon-style — just refresh sizes/fonts
        RestoreFramePos(posKey, frame, defaultPos)
        frame:SetSize(BAR_WIDTH(), sz)
        if frame.iconFrame   then frame.iconFrame:SetSize(sz - 4, sz - 4) end
        if frame.label       then frame.label:SetFont(ns:GetFontPath("Fonts\\FRIZQT__.TTF"), FONT_SIZE(), S("fontOutline","OUTLINE")) end
        if frame.tankName    then frame.tankName:SetFont(ns:GetFontPath("Fonts\\FRIZQT__.TTF"), FONT_SIZE() - 1, S("fontOutline","OUTLINE")) end
        if frame.timerText   then frame.timerText:SetFont(ns:GetFontPath("Fonts\\FRIZQT__.TTF"), FONT_SIZE(), S("fontOutline","OUTLINE")) end
        if frame.durationBar then frame.durationBar:SetStatusBarTexture(ns:GetBarTexture(FLAT_TEX)) end
        local bi = S("ssShowBorder", true) and 1 or 0
        frame:SetBackdropBorderColor(S("ssInactiveBorderR",0.55), S("ssInactiveBorderG",0.22), S("ssInactiveBorderB",0.05), bi)
        return frame
    end
    frame.initialized = true
    frame.isIconStyle  = true

    ---------------------------------------------------------------------------
    -- Backdrop
    ---------------------------------------------------------------------------
    frame:SetBackdrop({
        bgFile   = FLAT_TEX,
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = false, edgeSize = ns:GetEdgeSize(10),
        insets = { left = 2, right = 2, top = 2, bottom = 2 },
    })
    frame:SetBackdropColor(0.06, 0.04, 0.01, 0.92)
    local bi0 = S("ssShowBorder", true) and 1 or 0
    frame:SetBackdropBorderColor(S("ssInactiveBorderR",0.55), S("ssInactiveBorderG",0.22), S("ssInactiveBorderB",0.05), bi0)

    ---------------------------------------------------------------------------
    -- Spell icon
    ---------------------------------------------------------------------------
    local iconFrame = CreateFrame("Frame", nil, frame)
    iconFrame:SetSize(sz - 4, sz - 4)
    iconFrame:SetPoint("LEFT", frame, "LEFT", 3, 0)
    frame.iconFrame = iconFrame

    local icon = iconFrame:CreateTexture(nil, "BACKGROUND")
    icon:SetAllPoints()
    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    frame.icon = icon

    -- Icon border
    local iconBorder = iconFrame:CreateTexture(nil, "OVERLAY")
    iconBorder:SetTexture("Interface\\Buttons\\UI-Quickslot-Depress")
    iconBorder:SetAllPoints()

    -- Swipe cooldown overlay
    local cooldown = CreateFrame("Cooldown", nil, iconFrame, "CooldownFrameTemplate")
    cooldown:SetAllPoints()
    cooldown:SetDrawEdge(true)
    cooldown:SetDrawSwipe(true)
    cooldown:SetSwipeColor(0, 0, 0, 0.75)
    frame.cooldown = cooldown

    ---------------------------------------------------------------------------
    -- Text to the right of the icon
    ---------------------------------------------------------------------------
    -- Spell name (top)
    local label = frame:CreateFontString(nil, "OVERLAY")
    label:SetFont(ns:GetFontPath("Fonts\\FRIZQT__.TTF"), FONT_SIZE(), S("fontOutline","OUTLINE"))
    label:SetPoint("TOPLEFT",  iconFrame, "TOPRIGHT", 5, -2)
    label:SetPoint("TOPRIGHT", frame,     "TOPRIGHT", -38, -2)
    label:SetJustifyH("LEFT")
    label:SetText("|cffff8833" .. (ns.SEARING_SCALES_NAME or "Écaille torride") .. "|r")
    frame.label = label

    -- Tank name (bottom)
    local tankName = frame:CreateFontString(nil, "OVERLAY")
    tankName:SetFont(ns:GetFontPath("Fonts\\FRIZQT__.TTF"), FONT_SIZE() - 1, S("fontOutline","OUTLINE"))
    tankName:SetPoint("BOTTOMLEFT",  iconFrame, "BOTTOMRIGHT", 5, 2)
    tankName:SetPoint("BOTTOMRIGHT", frame,     "BOTTOMRIGHT", -40, 2)
    tankName:SetJustifyH("LEFT")
    tankName:SetTextColor(0.85, 0.85, 0.85, 1)
    tankName:SetText("")
    frame.tankName = tankName

    -- Timer (right, aligned with label)
    local timerText = frame:CreateFontString(nil, "OVERLAY")
    timerText:SetFont(ns:GetFontPath("Fonts\\FRIZQT__.TTF"), FONT_SIZE(), S("fontOutline","OUTLINE"))
    timerText:SetPoint("RIGHT", frame, "TOPRIGHT", -5, -(sz / 2) + 1)
    timerText:SetJustifyH("RIGHT")
    timerText:SetTextColor(1, 0.85, 0.1, 1)
    timerText:SetText("")
    frame.timerText = timerText

    -- Stack count (icon corner, bottom-right)
    local stackText = iconFrame:CreateFontString(nil, "OVERLAY")
    stackText:SetFont(ns:GetFontPath("Fonts\\FRIZQT__.TTF"), FONT_SIZE() + 1, "OUTLINE")
    stackText:SetPoint("BOTTOMRIGHT", iconFrame, "BOTTOMRIGHT", -1, 1)
    stackText:SetTextColor(1, 0.9, 0.1, 1)
    stackText:SetText("")
    frame.stackText = stackText

    ---------------------------------------------------------------------------
    -- Duration bar (thin, below the text)
    ---------------------------------------------------------------------------
    local durationBarBg = frame:CreateTexture(nil, "ARTWORK")
    durationBarBg:SetTexture(FLAT_TEX)
    durationBarBg:SetVertexColor(0.08, 0.05, 0.02, 1)
    durationBarBg:SetPoint("LEFT",  iconFrame, "BOTTOMRIGHT", 5, 2)
    durationBarBg:SetPoint("RIGHT", frame,     "BOTTOMRIGHT", -5, 2)
    durationBarBg:SetHeight(3)
    frame.durationBarBg = durationBarBg

    local durationBar = CreateFrame("StatusBar", nil, frame)
    durationBar:SetPoint("LEFT",  iconFrame, "BOTTOMRIGHT", 5, 2)
    durationBar:SetPoint("RIGHT", frame,     "BOTTOMRIGHT", -5, 2)
    durationBar:SetHeight(3)
    durationBar:SetStatusBarTexture(ns:GetBarTexture(FLAT_TEX))
    durationBar:SetMinMaxValues(0, 1)
    durationBar:SetValue(0)
    durationBar:SetStatusBarColor(S("ssFullR",0.9), S("ssFullG",0.45), S("ssFullB",0.05), 0.9)
    frame.durationBar = durationBar

    -- Apply show/hide settings
    durationBar:SetShown(S("ssShowDurationBar", true))
    durationBarBg:SetShown(S("ssShowDurationBar", true))
    timerText:SetShown(S("ssShowTimer", true))

    ---------------------------------------------------------------------------
    -- Icon resolution
    ---------------------------------------------------------------------------
    local iconResolved = false
    local function TrySetIcon()
        local ok, tex = pcall(C_Spell.GetSpellTexture, SS_CAST_ID)
        if ok and tex and not issecretvalue(tex) then icon:SetTexture(tex); return true end
        if GetSpellTexture then
            ok, tex = pcall(GetSpellTexture, SS_CAST_ID)
            if ok and tex and not issecretvalue(tex) then icon:SetTexture(tex); return true end
        end
        icon:SetTexture("Interface\\Icons\\ability_evoker_scarlet")
        return false
    end
    iconResolved = TrySetIcon()

    ---------------------------------------------------------------------------
    -- UpdateTimer
    ---------------------------------------------------------------------------
    function frame:UpdateTimer(remaining)
        local dur = self.buffDuration or ns.SEARING_SCALES_DURATION
        if remaining and remaining > 0 then
            local pct = (dur > 0) and math.min(remaining / dur, 1) or 1
            self.durationBar:SetValue(pct)
            if pct > 0.5 then
                self.durationBar:SetStatusBarColor(S("ssFullR",0.9), S("ssFullG",0.45), S("ssFullB",0.05), 0.9)
            elseif pct > 0.25 then
                self.durationBar:SetStatusBarColor(S("ssMidR",0.85), S("ssMidG",0.62), S("ssMidB",0.0), 0.9)
            else
                self.durationBar:SetStatusBarColor(S("ssLowR",0.85), S("ssLowG",0.12), S("ssLowB",0.12), 0.9)
            end
            -- Timer — format mm:ss if >= 60s, else just seconds
            if S("ssShowTimer", true) then
                local r = math.floor(remaining)
                if r >= 60 then
                    self.timerText:SetText(format("%d:%02d", math.floor(r/60), r%60))
                else
                    self.timerText:SetText(tostring(r))
                end
            end
            -- Active border (buff present)
            local ba = S("ssShowBorder", true) and 1 or 0
            self:SetBackdropBorderColor(S("ssActiveBorderR",0.9), S("ssActiveBorderG",0.55), S("ssActiveBorderB",0.1), ba)
        else
            self.durationBar:SetValue(0)
            self.timerText:SetText("")
            -- Inactive border (buff absent)
            local bi = S("ssShowBorder", true) and 1 or 0
            self:SetBackdropBorderColor(S("ssInactiveBorderR",0.55), S("ssInactiveBorderG",0.22), S("ssInactiveBorderB",0.05), bi)
        end
    end

    ---------------------------------------------------------------------------
    -- UpdateUnitInfo
    ---------------------------------------------------------------------------
    function frame:UpdateUnitInfo()
        local unit = ns.tankUnitTokens and ns.tankUnitTokens[tankSlot]
        if unit and UnitExists(unit) then
            local uName = UnitName(unit) or "?"
            local _, class = UnitClass(unit)
            local color = class and CLASS_COLORS and CLASS_COLORS[class]
            self.tankName:SetShown(S("ssShowTankName", true))
            self.tankName:SetText(uName)
            if color then
                self:SetBackdropColor(color.r * 0.10, color.g * 0.10, color.b * 0.10, 0.92)
            end
        else
            self.tankName:SetText("")
        end
        if not iconResolved then iconResolved = TrySetIcon() end
    end

    ---------------------------------------------------------------------------
    -- Range fade + icon resolution loop
    ---------------------------------------------------------------------------
    local rangeElapsed = 0
    frame:SetScript("OnUpdate", function(self, dt)
        rangeElapsed = rangeElapsed + dt
        if rangeElapsed < 0.2 then return end
        rangeElapsed = 0
        if not iconResolved then iconResolved = TrySetIcon() end
        local unit = ns.tankUnitTokens and ns.tankUnitTokens[tankSlot]
        if not unit or not UnitExists(unit) then return end
        local ok, inRange = pcall(C_Spell.IsSpellInRange, SS_CAST_ID, unit)
        if ok and not issecretvalue(inRange) and inRange == false then
            self:SetAlpha(RANGE_ALPHA())
        else
            self:SetAlpha(IN_RANGE_ALPHA)
        end
    end)

    MakeDraggable(frame, posKey, defaultPos)
    frame:SetShown(false)
    return frame
end

---------------------------------------------------------------------------
-- Initialize
---------------------------------------------------------------------------

local function InitializeFrames()
    CreateContainer()  -- dummy for compat

    ns.emFrames = {}
    for i = 1, ns.NUM_SLOTS do
        ns.emFrames[i] = CreateEbonMightFrame(i)
    end

    for i = 1, ns.NUM_SLOTS do
        ns.frames[i] = CreateTargetFrame(i)
    end

    -- Tank frames (Searing Scales)
    ns.tankFrames = ns.tankFrames or {}
    for i = 1, (ns.TANK_SLOTS or 1) do
        ns.tankFrames[i] = CreateTankFrame(i)
    end

    cdTracker = CreateCDTracker()

    ns:UpdateFrameScale()
    ns:UpdateFrameVisibility()
end

function ns:UpdateFrameScale()
    local scale = ns.settings.frameScale or 1.0
    if ns.tankFrames then
        for i = 1, (ns.TANK_SLOTS or 1) do
            if ns.tankFrames[i] then ns.tankFrames[i]:SetScale(scale) end
        end
    end
    if ns.emFrames then
        for i = 1, ns.NUM_SLOTS do
            if ns.emFrames[i] then ns.emFrames[i]:SetScale(scale) end
        end
    end
    for i = 1, ns.NUM_SLOTS do
        if ns.frames[i] then ns.frames[i]:SetScale(scale) end
    end
    if cdTracker then cdTracker:SetScale(scale) end
end

function ns:UpdateFrameVisibility()
    if InCombatLockdown() then return end
    ReflowFrames()
end

function ns:InitializeFrames()
    C_Timer.After(0, InitializeFrames)
end


---------------------------------------------------------------------------
-- RefreshSettings: update existing frames without recreating them
-- Called by sliders/colour pickers for live preview
---------------------------------------------------------------------------
function ns:RefreshSettings()
    if not container then return end

    -- Scale all frames
    ns:UpdateFrameScale()

    -- Ebon Might per-slot bars
    if ns.emFrames then
        local emBA = S("emShowBorder", true) and 1 or 0
        for i = 1, ns.NUM_SLOTS do
            local ef = ns.emFrames[i]
            if ef then
                ef:SetSize(BAR_WIDTH(), EM_BAR_HEIGHT())
                ef:SetBackdropBorderColor(S("emInactiveBorderR",0.28), S("emInactiveBorderG",0.10), S("emInactiveBorderB",0.42), emBA)
                if ef.accent    then ef.accent:SetVertexColor(S("emAccentR",0.72), S("emAccentG",0.28), S("emAccentB",1.0), 1) end
                if ef.accent    then ef.accent:SetSize(3, EM_BAR_HEIGHT() - 4) end
                if ef.spark     then ef.spark:SetSize(10, EM_BAR_HEIGHT() + 4) end
                if ef.timerBar  then ef.timerBar:SetStatusBarTexture(ns:GetBarTexture(FLAT_TEX)) end
                if ef.nameText  then ef.nameText:SetFont(ns:GetFontPath("Fonts\\FRIZQT__.TTF"), FONT_SIZE() - 1, S("fontOutline","OUTLINE")) end
                if ef.timerText then ef.timerText:SetFont(ns:GetFontPath("Fonts\\FRIZQT__.TTF"), FONT_SIZE(), S("fontOutline","OUTLINE")) end
            end
        end
    end

    -- Prescience target frames
    for i = 1, ns.NUM_SLOTS do
        local f = ns.frames[i]
        if f then
            f:SetSize(BAR_WIDTH(), BAR_HEIGHT())
            local presBA = S("presShowBorder", true) and 1 or 0
            if f.barFrame then
                f.barFrame:SetBackdropBorderColor(S("presInactiveBorderR",0.35), S("presInactiveBorderG",0.35), S("presInactiveBorderB",0.35), presBA)
            end
            if f.timerBar  then f.timerBar:SetStatusBarTexture(ns:GetBarTexture(FLAT_TEX)) end
            if f.accent    then f.accent:SetSize(3, BAR_HEIGHT() - 4) end
            if f.spark     then f.spark:SetSize(10, BAR_HEIGHT() + 4) end
            if f.nameText  then
                f.nameText:SetFont(ns:GetFontPath("Fonts\\FRIZQT__.TTF"), FONT_SIZE(), S("fontOutline","OUTLINE"))
                f.nameText:SetTextColor(S("nameColorR",1), S("nameColorG",1), S("nameColorB",1), 1)
                f.nameText:SetShown(not S("hideName", false))
            end
            if f.timerText then
                f.timerText:SetFont(ns:GetFontPath("Fonts\\FRIZQT__.TTF"), FONT_SIZE(), S("fontOutline","OUTLINE"))
                f.timerText:SetTextColor(S("timerColorR",1), S("timerColorG",1), S("timerColorB",1), 1)
                f.timerText:SetShown(not S("hideTimer", false))
            end
        end
    end

    -- CD Tracker: icon size + recharge bar texture
    if cdTracker then
        local iconSz = CD_ICON_SIZE()
        cdTracker:SetSize(BAR_WIDTH(), iconSz)
        if cdTracker.iconFrame then
            cdTracker.iconFrame:SetSize(iconSz - 4, iconSz - 4)
        end
        if cdTracker.chargeBarFill then
            cdTracker.chargeBarFill:SetStatusBarTexture(ns:GetBarTexture(FLAT_TEX))
        end
        -- Show/hide charges text
        if cdTracker.chargeText then
            cdTracker.chargeText:SetShown(S("showCharges", true))
        end
        -- Show/hide recharge bar
        if cdTracker.chargeBarFill then
            cdTracker.chargeBarFill:SetShown(S("showRechargeBar", true))
        end
        -- Show/hide cooldown swipe
        if cdTracker.cooldown then
            cdTracker.cooldown:SetShown(S("showCooldownSwipe", true))
        end
    end

    -- Tank frames (Searing Scales) — resize + refresh fonts/textures
    if ns.tankFrames then
        for i = 1, (ns.TANK_SLOTS or 1) do
            local tf = ns.tankFrames[i]
            if tf then
                local sz = S("ssIconSize", 32)
                tf:SetSize(BAR_WIDTH(), sz)
                if tf.iconFrame   then tf.iconFrame:SetSize(sz - 4, sz - 4) end
                if tf.durationBar then tf.durationBar:SetStatusBarTexture(ns:GetBarTexture(FLAT_TEX)) end
                if tf.label       then tf.label:SetFont(ns:GetFontPath("Fonts\\FRIZQT__.TTF"), FONT_SIZE(), S("fontOutline","OUTLINE")) end
                if tf.tankName    then tf.tankName:SetFont(ns:GetFontPath("Fonts\\FRIZQT__.TTF"), FONT_SIZE() - 1, S("fontOutline","OUTLINE")) end
                if tf.timerText   then tf.timerText:SetFont(ns:GetFontPath("Fonts\\FRIZQT__.TTF"), FONT_SIZE(), S("fontOutline","OUTLINE")) end
                local bi = S("ssShowBorder", true) and 1 or 0
                tf:SetBackdropBorderColor(S("ssInactiveBorderR",0.55), S("ssInactiveBorderG",0.22), S("ssInactiveBorderB",0.05), bi)
            end
        end
    end

    ReflowFrames()
end

function ns:RefreshTankFrames()
    if not ns.tankFrames then return end
    for i = 1, (ns.TANK_SLOTS or 1) do
        local tf = ns.tankFrames[i]
        local hasUnit = ns.tankUnitTokens and ns.tankUnitTokens[i]
        if tf then
            tf:SetShown(ns.settings.showFrames and hasUnit and true or false)
            if hasUnit then tf:UpdateUnitInfo() end
            -- Rescan Searing Scales
            if ns.BuffTracker then
                ns.BuffTracker:ScanTankUnit(i, hasUnit)
            end
        end
    end
end

function ns:DestroyFrames()
    if ns.emFrames then
        for i = 1, ns.NUM_SLOTS do
            if ns.emFrames[i] then
                ns.emFrames[i]:Hide()
                ns.emFrames[i]:SetParent(nil)
                ns.emFrames[i] = nil
            end
        end
        ns.emFrames = nil
    end
    if cdTracker then
        cdTracker:Hide()
        cdTracker:SetParent(nil)
        cdTracker = nil
    end
    for i = 1, ns.NUM_SLOTS do
        if ns.frames[i] then
            ns.frames[i]:Hide()
            ns.frames[i]:SetParent(nil)
            ns.frames[i] = nil
        end
    end
    if ns.tankFrames then
        for i = 1, (ns.TANK_SLOTS or 1) do
            if ns.tankFrames[i] then
                ns.tankFrames[i]:Hide()
                ns.tankFrames[i]:SetParent(nil)
                ns.tankFrames[i] = nil
            end
        end
        ns.tankFrames = nil
    end
end

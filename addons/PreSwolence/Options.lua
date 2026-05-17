local addonName, ns = ...

---------------------------------------------------------------------------
-- Default visual settings (merged into ns.settings on load)
---------------------------------------------------------------------------
local VISUAL_DEFAULTS = {
    -- Layout
    barWidth        = 160,
    barHeight       = 28,
    emBarHeight     = 22,
    frameSpacing    = 4,
    frameScale      = 1.0,
    -- Container
    containerAlpha  = 0.88,
    containerR      = 0.04, containerG = 0.04, containerB = 0.06,
    borderR         = 0.18, borderG    = 0.18, borderB    = 0.22,
    containerShowBorder = true,
    -- Prescience bar colours (full)
    presFullR  = 0.12, presFullG  = 0.72, presFullB  = 0.18,
    presMidR   = 0.85, presMidG   = 0.62, presMidB   = 0.00,
    presLowR   = 0.85, presLowG   = 0.12, presLowB   = 0.12,
    presActiveBorderR   = 0.20, presActiveBorderG   = 0.80, presActiveBorderB   = 0.20,
    presInactiveBorderR = 0.60, presInactiveBorderG = 0.20, presInactiveBorderB = 0.20,
    presShowBorder = true,
    -- Ebon Might bar colours
    emFullR    = 0.52, emFullG    = 0.18, emFullB    = 0.82,
    emMidR     = 0.80, emMidG     = 0.45, emMidB     = 0.00,
    emLowR     = 0.90, emLowG     = 0.15, emLowB     = 0.15,
    emAccentR           = 0.72, emAccentG           = 0.28, emAccentB           = 1.00,
    emActiveBorderR     = 0.62, emActiveBorderG     = 0.22, emActiveBorderB     = 0.92,
    emInactiveBorderR   = 0.28, emInactiveBorderG   = 0.10, emInactiveBorderB   = 0.42,
    emShowBorder        = true,
    -- Font
    fontSize    = 10,
    fontOutline = "OUTLINE",
    -- Visibility
    showPrescience = true,
    showEbonMight  = true,
    showFrames     = true,
    showCDTracker  = true,
    hiddenSlots    = {},
    locked        = false,
    -- Range
    rangeAlpha    = 0.35,
    -- ElvUI / ToxiUI
    elvuiSync        = false,
    -- Texte
    hideName         = false,
    hideTimer        = false,
    nameColorR       = 1.0,   nameColorG = 1.0,   nameColorB = 1.0,
    timerColorR      = 1.0,   timerColorG = 1.0,  timerColorB = 1.0,
    -- Icône
    cdIconSize       = 28,
    showCharges      = true,
    showRechargeBar  = true,
    showCooldownSwipe = true,
    -- Texture
    customBarTex     = nil,
    -- Écaille torride (Searing Scales)
    ssIconSize          = 32,
    ssShowTimer         = true,
    ssShowDurationBar   = true,
    ssShowTankName      = true,
    ssShowBorder        = true,
    ssActiveBorderR     = 0.90, ssActiveBorderG   = 0.55, ssActiveBorderB   = 0.10,
    ssInactiveBorderR   = 0.55, ssInactiveBorderG = 0.22, ssInactiveBorderB = 0.05,
    ssFullR   = 0.90, ssFullG = 0.45, ssFullB = 0.05,
    ssMidR    = 0.85, ssMidG  = 0.62, ssMidB  = 0.00,
    ssLowR    = 0.85, ssLowG  = 0.12, ssLowB  = 0.12,
}

-- Merge defaults into saved settings
local function ApplyVisualDefaults()
    for k, v in pairs(VISUAL_DEFAULTS) do
        if ns.settings[k] == nil then
            ns.settings[k] = v
        end
    end
end

---------------------------------------------------------------------------
-- Helpers
---------------------------------------------------------------------------
local function RGBToHex(r, g, b)
    return format("%02X%02X%02X", math.floor(r*255), math.floor(g*255), math.floor(b*255))
end

-- Rebuild all frames from scratch using current settings
local applyTimer = nil
local function ApplySettings()
    ns:SaveData()
    if ns.RefreshSettings then
        ns:RefreshSettings()
    end
end
local function ApplySettingsDebounced()
    if applyTimer then applyTimer:Cancel() end
    applyTimer = C_Timer.NewTimer(0.3, function()
        applyTimer = nil
        ApplySettings()
    end)
end

---------------------------------------------------------------------------
-- Widget builders
---------------------------------------------------------------------------

-- Section header
local function CreateHeader(parent, text, yOffset)
    local fs = parent:CreateFontString(nil, "OVERLAY")
    fs:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
    fs:SetTextColor(0.82, 0.68, 0.25, 1)
    fs:SetPoint("TOPLEFT", parent, "TOPLEFT", 10, yOffset)
    fs:SetText(text)
    -- Separator line
    local line = parent:CreateTexture(nil, "ARTWORK")
    line:SetTexture("Interface\\Buttons\\WHITE8X8")
    line:SetVertexColor(0.82, 0.68, 0.25, 0.4)
    line:SetHeight(1)
    line:SetPoint("TOPLEFT",  fs, "BOTTOMLEFT",  0, -2)
    line:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -10, 0)
    line:SetPoint("TOP", fs, "BOTTOM", 0, -2)
    return fs
end

-- Label
local function CreateLabel(parent, text, x, y)
    local fs = parent:CreateFontString(nil, "OVERLAY")
    fs:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
    fs:SetTextColor(0.85, 0.85, 0.85, 1)
    fs:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    fs:SetText(text)
    return fs
end

-- Slider  (returns slider widget)
local function CreateSlider(parent, label, min, max, step, settingKey, x, y, width, callback)
    width = width or 180
    local lbl = CreateLabel(parent, label, x, y)

    local slider = CreateFrame("Slider", nil, parent, "OptionsSliderTemplate")
    slider:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y - 18)
    slider:SetWidth(width)
    slider:SetMinMaxValues(min, max)
    slider:SetValueStep(step)
    slider:SetObeyStepOnDrag(true)
    slider:SetValue(ns.settings[settingKey] or VISUAL_DEFAULTS[settingKey] or min)

    -- Override default Blizzard labels
    slider.Low:SetText(tostring(min))
    slider.High:SetText(tostring(max))
    slider.Text:SetText("")

    -- Value display
    local valText = parent:CreateFontString(nil, "OVERLAY")
    valText:SetFont("Fonts\\FRIZQT__.TTF", 9, "OUTLINE")
    valText:SetTextColor(1, 1, 1, 1)
    valText:SetPoint("TOP", slider, "BOTTOM", 0, 2)
    valText:SetText(tostring(ns.settings[settingKey] or VISUAL_DEFAULTS[settingKey] or min))

    slider:SetScript("OnValueChanged", function(self, val)
        val = math.floor(val / step + 0.5) * step
        ns.settings[settingKey] = val
        valText:SetText(format(step < 0.1 and "%.2f" or (step < 1 and "%.1f" or "%d"), val))
        if callback then callback(val) end
        ApplySettingsDebounced()
    end)
    return slider
end

-- Checkbox
local function CreateCheckbox(parent, label, settingKey, x, y, callback)
    local cb = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
    cb:SetPoint("TOPLEFT", parent, "TOPLEFT", x - 2, y)
    cb:SetSize(24, 24)
    cb:SetChecked(ns.settings[settingKey] == true or (ns.settings[settingKey] == nil and VISUAL_DEFAULTS[settingKey] == true))
    local lbl = parent:CreateFontString(nil, "OVERLAY")
    lbl:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
    lbl:SetTextColor(0.85, 0.85, 0.85, 1)
    lbl:SetPoint("LEFT", cb, "RIGHT", 2, 0)
    lbl:SetText(label)
    cb:SetScript("OnClick", function(self)
        local checked = self:GetChecked() and true or false
        ns.settings[settingKey] = checked
        if callback then callback(checked) end
    end)
    return cb
end

-- Colour swatch (opens ColorPickerFrame)
local function CreateColorSwatch(parent, label, rKey, gKey, bKey, x, y, callback)
    CreateLabel(parent, label, x + 28, y + 4)

    local swatch = CreateFrame("Button", nil, parent)
    swatch:SetSize(24, 24)
    swatch:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)

    -- Outer white border (always visible against dark bg)
    local outerBorder = swatch:CreateTexture(nil, "BACKGROUND")
    outerBorder:SetAllPoints()
    outerBorder:SetTexture("Interface\\Buttons\\WHITE8X8")
    outerBorder:SetVertexColor(0.7, 0.7, 0.7, 1)

    local bg = swatch:CreateTexture(nil, "BORDER")
    bg:SetPoint("TOPLEFT",     swatch, "TOPLEFT",     2, -2)
    bg:SetPoint("BOTTOMRIGHT", swatch, "BOTTOMRIGHT", -2, 2)
    bg:SetTexture("Interface\\Buttons\\WHITE8X8")
    local r = ns.settings[rKey] or VISUAL_DEFAULTS[rKey] or 1
    local g = ns.settings[gKey] or VISUAL_DEFAULTS[gKey] or 1
    local b = ns.settings[bKey] or VISUAL_DEFAULTS[bKey] or 1
    bg:SetVertexColor(r, g, b, 1)
    swatch.bg = bg

    local border = swatch:CreateTexture(nil, "OVERLAY")
    border:SetPoint("TOPLEFT", -1, 1)
    border:SetPoint("BOTTOMRIGHT", 1, -1)
    border:SetTexture("Interface\\Buttons\\WHITE8X8")
    border:SetVertexColor(0, 0, 0, 0)

    swatch:SetScript("OnClick", function(self)
        local function onChange(restore)
            local nr, ng, nb
            if restore then
                nr, ng, nb = ColorPickerFrame:GetPreviousValues()
            else
                nr, ng, nb = ColorPickerFrame:GetColorRGB()
            end
            ns.settings[rKey] = nr
            ns.settings[gKey] = ng
            ns.settings[bKey] = nb
            self.bg:SetVertexColor(nr, ng, nb, 1)
            if callback then callback(nr, ng, nb) end
        end

        ColorPickerFrame:SetupColorPickerAndShow({
            r = ns.settings[rKey] or 1,
            g = ns.settings[gKey] or 1,
            b = ns.settings[bKey] or 1,
            swatchFunc  = onChange,
            cancelFunc  = onChange,
        })
    end)
    return swatch
end

---------------------------------------------------------------------------
-- Build the options panel
---------------------------------------------------------------------------
local optionsFrame

local function BuildOptionsPanel()
    optionsFrame = CreateFrame("Frame", "PreSwolenceOptions", UIParent, "BackdropTemplate")
    optionsFrame:SetSize(660, 640)
    optionsFrame:SetPoint("CENTER")
    optionsFrame:SetFrameStrata("DIALOG")
    optionsFrame:SetMovable(true)
    optionsFrame:EnableMouse(true)
    optionsFrame:RegisterForDrag("LeftButton")
    optionsFrame:SetScript("OnDragStart", function(self) self:StartMoving() end)
    optionsFrame:SetScript("OnDragStop",  function(self) self:StopMovingOrSizing() end)
    optionsFrame:Hide()
    optionsFrame:SetBackdrop({
        bgFile   = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = false, edgeSize = 16,
        insets = { left = 5, right = 5, top = 5, bottom = 5 },
    })
    optionsFrame:SetBackdropColor(0.06, 0.06, 0.09, 0.97)
    optionsFrame:SetBackdropBorderColor(0.82, 0.68, 0.25, 1)

    -- Title bar
    local titleBar = optionsFrame:CreateTexture(nil, "ARTWORK")
    titleBar:SetTexture("Interface\\Buttons\\WHITE8X8")
    titleBar:SetVertexColor(0.10, 0.10, 0.14, 1)
    titleBar:SetPoint("TOPLEFT",  optionsFrame, "TOPLEFT",  6, -6)
    titleBar:SetPoint("TOPRIGHT", optionsFrame, "TOPRIGHT", -6, -6)
    titleBar:SetHeight(28)
    local title = optionsFrame:CreateFontString(nil, "OVERLAY")
    title:SetFont("Fonts\\FRIZQT__.TTF", 14, "OUTLINE")
    title:SetTextColor(0.82, 0.68, 0.25, 1)
    title:SetPoint("TOP", optionsFrame, "TOP", 0, -14)
    title:SetText("Augtracker  |cffaaaaaaOptions|r")

    local closeBtn = CreateFrame("Button", nil, optionsFrame, "UIPanelCloseButton")
    closeBtn:SetPoint("TOPRIGHT", optionsFrame, "TOPRIGHT", -2, -2)
    closeBtn:SetScript("OnClick", function() optionsFrame:Hide() end)

    -- Bottom buttons
    local applyBtn = CreateFrame("Button", nil, optionsFrame, "UIPanelButtonTemplate")
    applyBtn:SetSize(100, 24)
    applyBtn:SetPoint("BOTTOMRIGHT", optionsFrame, "BOTTOMRIGHT", -10, 8)
    applyBtn:SetText("Appliquer")
    applyBtn:SetScript("OnClick", function()
        ns:SaveData()
        if ns.RebuildFrames then ns:RebuildFrames() end
        ns:Print("Paramètres appliqués.")
    end)
    local resetBtn = CreateFrame("Button", nil, optionsFrame, "UIPanelButtonTemplate")
    resetBtn:SetSize(100, 24)
    resetBtn:SetPoint("RIGHT", applyBtn, "LEFT", -6, 0)
    resetBtn:SetText("Réinitialiser")
    resetBtn:SetScript("OnClick", function()
        for k, v in pairs(VISUAL_DEFAULTS) do ns.settings[k] = v end
        optionsFrame:Hide(); optionsFrame = nil
        BuildOptionsPanel(); optionsFrame:Show()
        ApplySettings()
        ns:Print("Paramètres réinitialisés.")
    end)

    -- Scroll area
    local scroll = CreateFrame("ScrollFrame", nil, optionsFrame, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT",     optionsFrame, "TOPLEFT",     10, -42)
    scroll:SetPoint("BOTTOMRIGHT", optionsFrame, "BOTTOMRIGHT", -28, 40)
    local content = CreateFrame("Frame", nil, scroll)
    content:SetSize(620, 1100)
    scroll:SetScrollChild(content)

    -- ---------------------------------------------------------------
    -- Left tab system (main categories)
    -- ---------------------------------------------------------------
    local tabW = 120
    local tabs, pages = {}, {}

    local function CreateTab(label, idx)
        local btn = CreateFrame("Button", nil, content)
        btn:SetSize(tabW, 26)
        btn:SetPoint("TOPLEFT", content, "TOPLEFT", 0, -(idx - 1) * 30)
        local bg = btn:CreateTexture(nil, "BACKGROUND")
        bg:SetAllPoints(); bg:SetTexture("Interface\\Buttons\\WHITE8X8")
        bg:SetVertexColor(0.10, 0.10, 0.14, 1); btn.bg = bg
        local hl = btn:CreateTexture(nil, "HIGHLIGHT")
        hl:SetAllPoints(); hl:SetTexture("Interface\\Buttons\\WHITE8X8")
        hl:SetVertexColor(0.82, 0.68, 0.25, 0.15); hl:SetBlendMode("ADD")
        local lbl = btn:CreateFontString(nil, "OVERLAY")
        lbl:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
        lbl:SetAllPoints(); lbl:SetJustifyH("CENTER"); lbl:SetJustifyV("MIDDLE")
        lbl:SetText(label); lbl:SetTextColor(0.75, 0.75, 0.75, 1); btn.lbl = lbl
        tabs[idx] = btn
        return btn
    end

    local function ShowPage(idx)
        for i, p in ipairs(pages) do
            p:SetShown(i == idx)
            if tabs[i] then
                if i == idx then
                    tabs[i].bg:SetVertexColor(0.18, 0.14, 0.06, 1)
                    tabs[i].lbl:SetTextColor(1.0, 0.85, 0.30, 1)
                else
                    tabs[i].bg:SetVertexColor(0.10, 0.10, 0.14, 1)
                    tabs[i].lbl:SetTextColor(0.75, 0.75, 0.75, 1)
                end
            end
        end
    end

    local function MakePage()
        local p = CreateFrame("Frame", nil, content)
        p:SetPoint("TOPLEFT",     content, "TOPLEFT",  tabW + 12, 0)
        p:SetPoint("BOTTOMRIGHT", content, "BOTTOMRIGHT", 0, 0)
        p:Hide()
        table.insert(pages, p)
        return p
    end

    -- Vertical separator
    local sep = content:CreateTexture(nil, "ARTWORK")
    sep:SetTexture("Interface\\Buttons\\WHITE8X8")
    sep:SetVertexColor(0.82, 0.68, 0.25, 0.35)
    sep:SetWidth(1)
    sep:SetPoint("TOPLEFT",    content, "TOPLEFT",  tabW + 6, -4)
    sep:SetPoint("BOTTOMLEFT", content, "BOTTOMLEFT", tabW + 6, 4)

    local y

    -- ===================================================================
    -- PAGE 1 — Général
    -- ===================================================================
    local t1 = CreateTab("|TInterface\\Icons\\INV_Misc_Gear_01:14|t  Général", 1)
    local p1 = MakePage()
    t1:SetScript("OnClick", function() ShowPage(1) end)
    y = -8
    CreateHeader(p1, "Visibilité", y) y = y - 22
    CreateCheckbox(p1, "Afficher les barres Prescience", "showPrescience", 10, y, function(v)
        ApplySettingsDebounced()
    end) y = y - 26
    CreateCheckbox(p1, "Afficher le tracker Prescience (icône)", "showCDTracker", 10, y, function(v)
        ApplySettingsDebounced()
    end) y = y - 26
    CreateCheckbox(p1, "Afficher les barres Ebon Might", "showEbonMight", 10, y, function(v)
        ApplySettingsDebounced()
    end) y = y - 26
    CreateCheckbox(p1, "Verrouiller la position", "locked", 10, y) y = y - 36

    CreateHeader(p1, "Masquer des barres par slot", y) y = y - 18
    -- Helper: toggle a hidden slot key and reflow
    local function ToggleSlotHidden(key, val)
        if not ns.settings.hiddenSlots then ns.settings.hiddenSlots = {} end
        ns.settings.hiddenSlots[key] = val
        ns:SaveData()
        if ns.ReflowFrames then ns.ReflowFrames() end
    end
    local function IsHidden(key)
        return ns.settings.hiddenSlots and ns.settings.hiddenSlots[key]
    end

    -- Build slot labels dynamically (name if assigned, else "Slot N")
    local function SlotLabel(i)
        local t = ns.targets and ns.targets[i]
        if t and t.name then return t.name end
        return "Slot " .. i
    end

    -- Grid layout (pixel-exact):
    --   label: x=10, width=135
    --   col centres: Prescience=220, EbonMight=340, Tank=450
    --   checkbox (18px) is placed so its centre aligns with the col centre
    local subY  = y
    local lblW  = 135
    local cbSz  = 18
    local col1c = 220   -- Prescience centre x
    local col2c = 330   -- Ebon Might centre x
    local col3c = 440   -- Éc. Torride centre x
    local function ColX(centre) return centre - cbSz / 2 end

    -- Column headers (centred text above each cb column)
    local function MakeHdr(text, cx)
        local h = p1:CreateFontString(nil, "OVERLAY")
        h:SetFont("Fonts\\FRIZQT__.TTF", 9, "OUTLINE")
        h:SetTextColor(0.6, 0.6, 0.6, 1)
        -- Centre the text over the column
        h:SetPoint("TOP", p1, "TOPLEFT", cx, subY)
        h:SetJustifyH("CENTER")
        h:SetText(text)
    end
    MakeHdr("Prescience",  col1c)
    MakeHdr("Ebon Might",  col2c)
    MakeHdr("Éc. Torride", col3c)

    subY = subY - 20

    local numSlots = ns.NUM_SLOTS or 4
    for i = 1, numSlots do
        local rowY  = subY - (i - 1) * 22
        local captI = i

        local function IsNonDPS()
            local t = ns.targets and ns.targets[captI]
            return t and (t.isHealer or t.isTank)
        end

        -- Row label
        local lbl = p1:CreateFontString(nil, "OVERLAY")
        lbl:SetFont("Fonts\\FRIZQT__.TTF", 9, "OUTLINE")
        lbl:SetTextColor(0.85, 0.85, 0.85, 1)
        lbl:SetPoint("TOPLEFT", p1, "TOPLEFT", 10, rowY)
        lbl:SetWidth(lblW)
        lbl:SetJustifyH("LEFT")
        lbl:SetText("Slot " .. i)
        p1:HookScript("OnShow", function() lbl:SetText(SlotLabel(captI)) end)

        -- Prescience cb
        local cbP = CreateFrame("CheckButton", nil, p1, "UICheckButtonTemplate")
        cbP:SetSize(cbSz, cbSz)
        cbP:SetPoint("TOPLEFT", p1, "TOPLEFT", ColX(col1c), rowY + 1)
        cbP:SetChecked(not IsHidden("pres_" .. i))
        cbP:SetScript("OnClick", function(self)
            ToggleSlotHidden("pres_" .. captI, not self:GetChecked())
        end)
        p1:HookScript("OnShow", function() cbP:SetChecked(not IsHidden("pres_" .. captI)) end)

        -- Ebon Might cb (DPS only)
        local cbE = CreateFrame("CheckButton", nil, p1, "UICheckButtonTemplate")
        cbE:SetSize(cbSz, cbSz)
        cbE:SetPoint("TOPLEFT", p1, "TOPLEFT", ColX(col2c), rowY + 1)
        cbE:SetChecked(not IsHidden("em_" .. i))
        cbE:SetScript("OnClick", function(self)
            ToggleSlotHidden("em_" .. captI, not self:GetChecked())
        end)
        p1:HookScript("OnShow", function()
            local nonDPS = IsNonDPS()
            cbE:SetShown(not nonDPS)
            if nonDPS then
                ToggleSlotHidden("em_" .. captI, true)
            else
                cbE:SetChecked(not IsHidden("em_" .. captI))
            end
        end)

        -- Écaille torride cb (tank slots only)
        if i <= (ns.TANK_SLOTS or 1) then
            local cbT = CreateFrame("CheckButton", nil, p1, "UICheckButtonTemplate")
            cbT:SetSize(cbSz, cbSz)
            cbT:SetPoint("TOPLEFT", p1, "TOPLEFT", ColX(col3c), rowY + 1)
            cbT:SetChecked(not IsHidden("tank_" .. i))
            cbT:SetScript("OnClick", function(self)
                ToggleSlotHidden("tank_" .. captI, not self:GetChecked())
            end)
            p1:HookScript("OnShow", function() cbT:SetChecked(not IsHidden("tank_" .. captI)) end)
        end
    end

    y = subY - numSlots * 22 - 10

    CreateHeader(p1, "Taille & Échelle", y) y = y - 24
    CreateSlider(p1, "Largeur des barres", 100, 300, 2, "barWidth",    10, y, 180) y = y - 52
    CreateSlider(p1, "Hauteur (Prescience)", 16, 50, 1, "barHeight",   10, y, 180) y = y - 52
    CreateSlider(p1, "Hauteur (Ebon Might)", 14, 40, 1, "emBarHeight", 10, y, 180) y = y - 52
    CreateSlider(p1, "Espacement entre barres", 0, 20, 1, "frameSpacing", 10, y, 180) y = y - 52
    CreateSlider(p1, "Échelle globale", 0.5, 2.0, 0.05, "frameScale", 10, y, 180,
        function(v) if ns.UpdateFrameScale then ns:UpdateFrameScale() end end) y = y - 52

    CreateHeader(p1, "Fondu hors de portée", y) y = y - 24
    CreateSlider(p1, "Opacité hors de portée", 0.0, 1.0, 0.05, "rangeAlpha", 10, y, 180)

    -- ===================================================================
    -- PAGE 2 — Conteneur
    -- ===================================================================
    local t2 = CreateTab("|TInterface\\Icons\\INV_Misc_PocketWatch_01:14|t  Conteneur", 2)
    local p2 = MakePage()
    t2:SetScript("OnClick", function() ShowPage(2) end)
    y = -8
    CreateHeader(p2, "Arrière-plan du conteneur", y) y = y - 24
    CreateSlider(p2, "Opacité du fond", 0.0, 1.0, 0.05, "containerAlpha", 10, y, 200) y = y - 52
    CreateHeader(p2, "Couleur du fond", y) y = y - 28
    CreateColorSwatch(p2, "Fond",    "containerR","containerG","containerB", 10, y) y = y - 30
    CreateCheckbox(p2, "Afficher le cadre du conteneur", "containerShowBorder", 10, y, function()
        ApplySettingsDebounced()
    end) y = y - 30
    CreateColorSwatch(p2, "Bordure", "borderR","borderG","borderB", 10, y)

    -- ===================================================================
    -- PAGE 3 — Prescience
    -- ===================================================================
    local t3 = CreateTab("|TInterface\\Icons\\Ability_Evoker_Prescience:14|t  Prescience", 3)
    local p3 = MakePage()
    t3:SetScript("OnClick", function() ShowPage(3) end)
    y = -8
    CreateHeader(p3, "Couleurs de la barre Prescience", y) y = y - 24
    CreateLabel(p3, "La couleur change selon le temps restant :", 10, y) y = y - 20
    CreateColorSwatch(p3, "> 50%  (plein)",    "presFullR","presFullG","presFullB", 10, y) y = y - 30
    CreateColorSwatch(p3, "25-50% (milieu)",   "presMidR","presMidG","presMidB",   10, y) y = y - 30
    CreateColorSwatch(p3, "< 25%  (faible)",   "presLowR","presLowG","presLowB",   10, y) y = y - 46
    CreateHeader(p3, "Bordure active / inactive", y) y = y - 24
    CreateCheckbox(p3, "Afficher le cadre", "presShowBorder", 10, y, function()
        ApplySettingsDebounced()
    end) y = y - 30
    CreateColorSwatch(p3, "Bordure active",   "presActiveBorderR","presActiveBorderG","presActiveBorderB", 10, y) y = y - 30
    CreateColorSwatch(p3, "Bordure inactive", "presInactiveBorderR","presInactiveBorderG","presInactiveBorderB", 10, y)

    -- ===================================================================
    -- PAGE 4 — Ebon Might
    -- ===================================================================
    local t4 = CreateTab("|TInterface\\Icons\\Ability_Evoker_EbonMight:14|t  Ebon Might", 4)
    local p4 = MakePage()
    t4:SetScript("OnClick", function() ShowPage(4) end)
    y = -8
    CreateHeader(p4, "Couleurs de la barre Ebon Might", y) y = y - 24
    CreateLabel(p4, "Dégradé selon le temps restant :", 10, y) y = y - 20
    CreateColorSwatch(p4, "> 40%  (plein)",  "emFullR","emFullG","emFullB", 10, y) y = y - 30
    CreateColorSwatch(p4, "20-40% (milieu)", "emMidR","emMidG","emMidB",   10, y) y = y - 30
    CreateColorSwatch(p4, "< 20%  (faible)", "emLowR","emLowG","emLowB",   10, y) y = y - 46
    CreateHeader(p4, "Accent (ligne gauche)", y) y = y - 24
    CreateColorSwatch(p4, "Couleur accent", "emAccentR","emAccentG","emAccentB", 10, y) y = y - 46
    CreateHeader(p4, "Bordure active / inactive", y) y = y - 24
    CreateCheckbox(p4, "Afficher le cadre", "emShowBorder", 10, y, function()
        ApplySettingsDebounced()
    end) y = y - 30
    CreateColorSwatch(p4, "Bordure active",   "emActiveBorderR","emActiveBorderG","emActiveBorderB", 10, y) y = y - 30
    CreateColorSwatch(p4, "Bordure inactive", "emInactiveBorderR","emInactiveBorderG","emInactiveBorderB", 10, y)

    -- ===================================================================
    -- PAGE 5 — Apparence (sous-onglets ElvUI/ToxiUI style)
    -- ===================================================================
    local t5 = CreateTab("|TInterface\\Icons\\Achievement_GuildPerk_EverybodysFriend:14|t  Apparence", 5)
    local p5 = MakePage()
    t5:SetScript("OnClick", function() ShowPage(5) end)

    -- Sub-tab bar inside p5
    local subTabH  = 24
    local subTabW  = 90
    local subTabs  = {}
    local subPages = {}

    local subTabBar = CreateFrame("Frame", nil, p5)
    subTabBar:SetHeight(subTabH + 4)
    subTabBar:SetPoint("TOPLEFT",  p5, "TOPLEFT",  0, 0)
    subTabBar:SetPoint("TOPRIGHT", p5, "TOPRIGHT", 0, 0)

    -- Sub-tab separator line
    local subSep = subTabBar:CreateTexture(nil, "ARTWORK")
    subSep:SetTexture("Interface\\Buttons\\WHITE8X8")
    subSep:SetVertexColor(0.82, 0.68, 0.25, 0.5)
    subSep:SetHeight(1)
    subSep:SetPoint("BOTTOMLEFT",  subTabBar, "BOTTOMLEFT",  0, 0)
    subSep:SetPoint("BOTTOMRIGHT", subTabBar, "BOTTOMRIGHT", 0, 0)

    local function CreateSubTab(label, idx)
        local btn = CreateFrame("Button", nil, subTabBar)
        btn:SetSize(subTabW, subTabH)
        btn:SetPoint("LEFT", subTabBar, "LEFT", (idx - 1) * (subTabW + 2), 0)
        local bg = btn:CreateTexture(nil, "BACKGROUND")
        bg:SetAllPoints(); bg:SetTexture("Interface\\Buttons\\WHITE8X8")
        bg:SetVertexColor(0.12, 0.12, 0.16, 1); btn.bg = bg
        local hl = btn:CreateTexture(nil, "HIGHLIGHT")
        hl:SetAllPoints(); hl:SetTexture("Interface\\Buttons\\WHITE8X8")
        hl:SetVertexColor(0.82, 0.68, 0.25, 0.15); hl:SetBlendMode("ADD")
        local lbl = btn:CreateFontString(nil, "OVERLAY")
        lbl:SetFont("Fonts\\FRIZQT__.TTF", 9, "OUTLINE")
        lbl:SetAllPoints(); lbl:SetJustifyH("CENTER"); lbl:SetJustifyV("MIDDLE")
        lbl:SetText(label); lbl:SetTextColor(0.75, 0.75, 0.75, 1); btn.lbl = lbl
        subTabs[idx] = btn
        return btn
    end

    local function ShowSubPage(idx)
        for i, sp in ipairs(subPages) do
            sp:SetShown(i == idx)
            if subTabs[i] then
                if i == idx then
                    subTabs[i].bg:SetVertexColor(0.18, 0.14, 0.06, 1)
                    subTabs[i].lbl:SetTextColor(1.0, 0.85, 0.30, 1)
                else
                    subTabs[i].bg:SetVertexColor(0.12, 0.12, 0.16, 1)
                    subTabs[i].lbl:SetTextColor(0.75, 0.75, 0.75, 1)
                end
            end
        end
    end

    local function MakeSubPage()
        local sp = CreateFrame("Frame", nil, p5)
        sp:SetPoint("TOPLEFT",     p5, "TOPLEFT",  0, -(subTabH + 8))
        sp:SetPoint("BOTTOMRIGHT", p5, "BOTTOMRIGHT", 0, 0)
        sp:Hide()
        table.insert(subPages, sp)
        return sp
    end

    -- ---------------------------------------------------------------
    -- SUB-PAGE A — Général (ElvUI/ToxiUI sync)
    -- ---------------------------------------------------------------
    local stA = CreateSubTab("Général", 1)
    local spA = MakeSubPage()
    stA:SetScript("OnClick", function() ShowSubPage(1) end)
    y = -8

    -- Detected addon info
    local infoText = spA:CreateFontString(nil, "OVERLAY")
    infoText:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
    infoText:SetTextColor(0.6, 0.6, 0.6, 1)
    infoText:SetPoint("TOPLEFT", spA, "TOPLEFT", 10, y)
    infoText:SetText("Aucun addon UI détecté")
    -- Update on show
    spA:SetScript("OnShow", function()
        local detected = {}
        if ElvUI and ElvUI[1] then table.insert(detected, "|cff1784d1ElvUI|r") end
        if ToxiUI then table.insert(detected, "|cffff6600ToxiUI|r") end
        if #detected > 0 then
            infoText:SetText("Addons détectés : " .. table.concat(detected, ", "))
        else
            infoText:SetText("|cffff4444Aucun addon UI (ElvUI/ToxiUI) détecté|r")
        end
    end)
    y = y - 24

    CreateHeader(spA, "Synchronisation automatique", y) y = y - 24
    CreateCheckbox(spA, "Activer la synchro ElvUI / ToxiUI", "elvuiSync", 10, y, function(val)
        ns.settings.elvuiSync = val
        ns:SaveData()
        if val then
            if ns.ApplyElvUIStyle then ns:ApplyElvUIStyle()
            else ns:Print("|cffff4444Module ElvUI non chargé.|r") end
        else
            if ns.RebuildFrames then ns:RebuildFrames() end
        end
    end) y = y - 30

    local syncBtn = CreateFrame("Button", nil, spA, "UIPanelButtonTemplate")
    syncBtn:SetSize(180, 22)
    syncBtn:SetPoint("TOPLEFT", spA, "TOPLEFT", 10, y)
    syncBtn:SetText("Appliquer style ElvUI/ToxiUI")
    syncBtn:SetScript("OnClick", function()
        if ns.ApplyElvUIStyle then ns:ApplyElvUIStyle()
        else ns:Print("|cffff4444Module ElvUI non chargé.|r") end
    end)
    y = y - 36

    CreateHeader(spA, "Aperçu des valeurs lues", y) y = y - 24
    local previewText = spA:CreateFontString(nil, "OVERLAY")
    previewText:SetFont("Fonts\\FRIZQT__.TTF", 9, "OUTLINE")
    previewText:SetTextColor(0.75, 0.75, 0.75, 1)
    previewText:SetPoint("TOPLEFT", spA, "TOPLEFT", 10, y)
    previewText:SetJustifyH("LEFT")
    previewText:SetWidth(350)
    -- Refresh preview on show
    spA:HookScript("OnShow", function()
        local lines = {}
        local fp = ns.settings.elvuiFontName or ns.settings.elvuiFontPath
        local bt = ns.settings.elvuiBarTexName or ns.settings.elvuiBarTex
        local es = ns.settings.elvuiEdgeSize
        local br = ns.settings.elvuiBorderR
        table.insert(lines, "Police    : " .. (fp  and "|cff00ff00"..fp.."|r"  or "|cffff4444non sync|r"))
        table.insert(lines, "Texture   : " .. (bt  and "|cff00ff00"..bt.."|r"  or "|cffff4444non sync|r"))
        table.insert(lines, "Bordure   : " .. (es  and "|cff00ff00"..es.."|r"  or "|cffff4444non sync|r"))
        table.insert(lines, "Couleur   : " .. (br  and string.format("|cff00ff00%.2f / %.2f / %.2f|r",
            ns.settings.elvuiBorderR, ns.settings.elvuiBorderG, ns.settings.elvuiBorderB)
            or "|cffff4444non sync|r"))
        previewText:SetText(table.concat(lines, "\n"))
    end)

    -- ---------------------------------------------------------------
    -- SUB-PAGE B — Texte
    -- ---------------------------------------------------------------
    local stB = CreateSubTab("Texte", 2)
    local spB = MakeSubPage()
    stB:SetScript("OnClick", function() ShowSubPage(2) end)
    y = -8

    CreateHeader(spB, "Police des textes", y) y = y - 24
    -- Font size (reuse existing slider)
    CreateSlider(spB, "Taille de la police", 7, 18, 1, "fontSize", 10, y, 200) y = y - 52

    -- Font outline dropdown (simulate with buttons)
    CreateLabel(spB, "Contours extérieurs :", 10, y) y = y - 20
    local outlines = {"OUTLINE", "THICKOUTLINE", "MONOCHROME", ""}
    local outlineLabels = {"Outline", "Thick Outline", "Monochrome", "Aucun"}
    local outlineBtns = {}
    for i, outline in ipairs(outlines) do
        local ob = CreateFrame("Button", nil, spB)
        ob:SetSize(95, 20)
        ob:SetPoint("TOPLEFT", spB, "TOPLEFT", 10 + (i-1) * 100, y)
        local bg = ob:CreateTexture(nil, "BACKGROUND"); bg:SetAllPoints()
        bg:SetTexture("Interface\\Buttons\\WHITE8X8"); bg:SetVertexColor(0.12, 0.12, 0.16, 1); ob.bg = bg
        local hl = ob:CreateTexture(nil, "HIGHLIGHT"); hl:SetAllPoints()
        hl:SetTexture("Interface\\Buttons\\WHITE8X8"); hl:SetVertexColor(0.82, 0.68, 0.25, 0.15); hl:SetBlendMode("ADD")
        local lbl = ob:CreateFontString(nil, "OVERLAY"); lbl:SetFont("Fonts\\FRIZQT__.TTF", 9, "OUTLINE")
        lbl:SetAllPoints(); lbl:SetJustifyH("CENTER"); lbl:SetJustifyV("MIDDLE")
        lbl:SetText(outlineLabels[i]); lbl:SetTextColor(0.75, 0.75, 0.75, 1); ob.lbl = lbl
        ob.outlineVal = outline
        outlineBtns[i] = ob
        local function RefreshOutline()
            local cur = ns.settings.fontOutline or "OUTLINE"
            for _, b in ipairs(outlineBtns) do
                if b.outlineVal == cur then
                    b.bg:SetVertexColor(0.18, 0.14, 0.06, 1); b.lbl:SetTextColor(1, 0.85, 0.3, 1)
                else
                    b.bg:SetVertexColor(0.12, 0.12, 0.16, 1); b.lbl:SetTextColor(0.75, 0.75, 0.75, 1)
                end
            end
        end
        ob:SetScript("OnClick", function() ns.settings.fontOutline = outline; RefreshOutline(); ApplySettingsDebounced() end)
        ob:SetScript("OnShow", RefreshOutline)
    end
    y = y - 30

    CreateHeader(spB, "Couleur du texte", y) y = y - 24
    CreateColorSwatch(spB, "Texte nom (couleur de classe)", "nameColorR","nameColorG","nameColorB", 10, y) y = y - 30
    CreateColorSwatch(spB, "Texte timer", "timerColorR","timerColorG","timerColorB", 10, y) y = y - 30

    CreateHeader(spB, "Masquer éléments", y) y = y - 24
    CreateCheckbox(spB, "Masquer le nom", "hideName",  10, y) y = y - 26
    CreateCheckbox(spB, "Masquer le timer", "hideTimer", 10, y)

    -- ---------------------------------------------------------------
    -- SUB-PAGE C — Icône
    -- ---------------------------------------------------------------
    local stC = CreateSubTab("Icône", 3)
    local spC = MakeSubPage()
    stC:SetScript("OnClick", function() ShowSubPage(3) end)
    y = -8

    CreateHeader(spC, "Tracker Prescience (icône)", y) y = y - 24
    CreateSlider(spC, "Taille de l'icône", 16, 48, 1, "cdIconSize", 10, y, 200) y = y - 52
    CreateCheckbox(spC, "Afficher les charges", "showCharges", 10, y) y = y - 26
    CreateCheckbox(spC, "Afficher la barre de recharge", "showRechargeBar", 10, y) y = y - 26
    CreateCheckbox(spC, "Afficher le cooldown animé (swipe)", "showCooldownSwipe", 10, y)

    -- ---------------------------------------------------------------
    -- SUB-PAGE D — Couleur personnalisée
    -- ---------------------------------------------------------------
    local stD = CreateSubTab("Couleur", 4)
    local spD = MakeSubPage()
    stD:SetScript("OnClick", function() ShowSubPage(4) end)
    y = -8

    CreateHeader(spD, "Couleur de la barre Prescience", y) y = y - 24
    CreateLabel(spD, "La couleur change selon le temps restant :", 10, y) y = y - 20
    CreateColorSwatch(spD, "> 50%  (plein)",    "presFullR","presFullG","presFullB", 10, y) y = y - 30
    CreateColorSwatch(spD, "25-50% (milieu)",   "presMidR","presMidG","presMidB",   10, y) y = y - 30
    CreateColorSwatch(spD, "< 25%  (faible)",   "presLowR","presLowG","presLowB",   10, y) y = y - 46

    CreateHeader(spD, "Couleur de la barre Ebon Might", y) y = y - 24
    CreateColorSwatch(spD, "> 40%  (plein)",  "emFullR","emFullG","emFullB", 10, y) y = y - 30
    CreateColorSwatch(spD, "20-40% (milieu)", "emMidR","emMidG","emMidB",   10, y) y = y - 30
    CreateColorSwatch(spD, "< 20%  (faible)", "emLowR","emLowG","emLowB",   10, y) y = y - 46

    CreateHeader(spD, "Accent & Bordures", y) y = y - 24
    CreateColorSwatch(spD, "Accent Ebon Might",  "emAccentR","emAccentG","emAccentB", 10, y) y = y - 30
    CreateColorSwatch(spD, "Fond conteneur",     "containerR","containerG","containerB", 10, y) y = y - 30
    CreateColorSwatch(spD, "Bordure conteneur",  "borderR","borderG","borderB", 10, y)

    -- ---------------------------------------------------------------
    -- SUB-PAGE E — Texture barre
    -- ---------------------------------------------------------------
    local stE = CreateSubTab("Texture", 5)
    local spE = MakeSubPage()
    stE:SetScript("OnClick", function() ShowSubPage(5) end)
    y = -8

    CreateHeader(spE, "Texture des barres de statut", y) y = y - 24
    CreateLabel(spE, "Texture actuelle :", 10, y) y = y - 18

    local texLabel = spE:CreateFontString(nil, "OVERLAY")
    texLabel:SetFont("Fonts\\FRIZQT__.TTF", 9, "OUTLINE")
    texLabel:SetTextColor(0.5, 0.8, 1, 1)
    texLabel:SetPoint("TOPLEFT", spE, "TOPLEFT", 10, y)
    texLabel:SetText(ns.settings.elvuiBarTexName or ns.settings.customBarTex or "Défaut (solide)")
    y = y - 20

    -- Preview bar
    local previewBarBg = spE:CreateTexture(nil, "BACKGROUND")
    previewBarBg:SetTexture("Interface\\Buttons\\WHITE8X8")
    previewBarBg:SetVertexColor(0.1, 0.1, 0.1, 1)
    previewBarBg:SetSize(300, 20)
    previewBarBg:SetPoint("TOPLEFT", spE, "TOPLEFT", 10, y)
    local previewBar = CreateFrame("StatusBar", nil, spE)
    previewBar:SetSize(300, 20)
    previewBar:SetPoint("TOPLEFT", spE, "TOPLEFT", 10, y)
    previewBar:SetMinMaxValues(0, 1)
    previewBar:SetValue(0.7)
    previewBar:SetStatusBarColor(0.2, 0.6, 1, 0.9)
    y = y - 30

    local function RefreshTexPreview()
        local tex = ns:GetBarTexture("Interface\\Buttons\\WHITE8X8")
        previewBar:SetStatusBarTexture(tex)
        texLabel:SetText(ns.settings.elvuiBarTexName or ns.settings.customBarTex or "Défaut (solide)")
    end
    spE:SetScript("OnShow", RefreshTexPreview)

    -- Built-in texture list (always available without LSM)
    CreateHeader(spE, "Textures intégrées", y) y = y - 20
    local builtinTextures = {
        { name = "Solide",      path = "Interface\\Buttons\\WHITE8X8" },
        { name = "Blizzard",    path = "Interface\\TargetingFrame\\UI-StatusBar" },
        { name = "BantoBar",    path = "Interface\\AddOns\\!Beautycase\\media\\statusbar\\BantoBar" },
        { name = "Aluminium",   path = "Interface\\AddOns\\!Beautycase\\media\\statusbar\\Aluminium" },
    }
    for _, tex in ipairs(builtinTextures) do
        local tb = CreateFrame("Button", nil, spE)
        tb:SetSize(130, 20)
        tb:SetPoint("TOPLEFT", spE, "TOPLEFT", 10, y)
        local bg = tb:CreateTexture(nil, "BACKGROUND"); bg:SetAllPoints()
        bg:SetTexture("Interface\\Buttons\\WHITE8X8"); bg:SetVertexColor(0.12, 0.12, 0.16, 1)
        local hl = tb:CreateTexture(nil, "HIGHLIGHT"); hl:SetAllPoints()
        hl:SetTexture("Interface\\Buttons\\WHITE8X8"); hl:SetVertexColor(0.82, 0.68, 0.25, 0.15); hl:SetBlendMode("ADD")
        local lbl = tb:CreateFontString(nil, "OVERLAY"); lbl:SetFont("Fonts\\FRIZQT__.TTF", 9, "OUTLINE")
        lbl:SetAllPoints(); lbl:SetJustifyH("CENTER"); lbl:SetJustifyV("MIDDLE")
        lbl:SetText(tex.name); lbl:SetTextColor(0.75, 0.75, 0.75, 1)
        tb:SetScript("OnClick", function()
            ns.settings.customBarTex = tex.path
            ns.settings.elvuiBarTex  = nil
            ns.settings.elvuiBarTexName = tex.name
            ApplySettingsDebounced(); RefreshTexPreview()
        end)
        y = y - 26
    end

    -- LSM textures (if available)
    CreateHeader(spE, "Textures LibSharedMedia", y) y = y - 20
    local LSM = LibStub and LibStub("LibSharedMedia-3.0", true)
    if LSM then
        local lsmTextures = LSM:HashTable("statusbar")
        local count = 0
        for name, path in pairs(lsmTextures) do
            if count >= 20 then break end  -- limit display
            count = count + 1
            local lb = CreateFrame("Button", nil, spE)
            lb:SetSize(200, 20)
            lb:SetPoint("TOPLEFT", spE, "TOPLEFT", 10, y)
            local bg = lb:CreateTexture(nil, "BACKGROUND"); bg:SetAllPoints()
            bg:SetTexture("Interface\\Buttons\\WHITE8X8"); bg:SetVertexColor(0.12, 0.12, 0.16, 1)
            local hl = lb:CreateTexture(nil, "HIGHLIGHT"); hl:SetAllPoints()
            hl:SetTexture("Interface\\Buttons\\WHITE8X8"); hl:SetVertexColor(0.82, 0.68, 0.25, 0.15); hl:SetBlendMode("ADD")
            local lbl = lb:CreateFontString(nil, "OVERLAY"); lbl:SetFont("Fonts\\FRIZQT__.TTF", 9, "OUTLINE")
            lbl:SetAllPoints(); lbl:SetJustifyH("CENTER"); lbl:SetJustifyV("MIDDLE")
            lbl:SetText(name); lbl:SetTextColor(0.75, 0.75, 0.75, 1)
            local capPath = path
            lb:SetScript("OnClick", function()
                ns.settings.customBarTex  = capPath
                ns.settings.elvuiBarTex   = capPath
                ns.settings.elvuiBarTexName = name
                ApplySettingsDebounced(); RefreshTexPreview()
            end)
            y = y - 26
        end
    else
        local noLSM = spE:CreateFontString(nil, "OVERLAY")
        noLSM:SetFont("Fonts\\FRIZQT__.TTF", 9, "OUTLINE")
        noLSM:SetTextColor(0.5, 0.5, 0.5, 1)
        noLSM:SetPoint("TOPLEFT", spE, "TOPLEFT", 10, y)
        noLSM:SetText("LibSharedMedia non disponible\n(installez un addon UI pour plus de textures)")
    end

    -- Show default sub-page
    ShowSubPage(1)

    -- ===================================================================
    -- PAGE 6 — Écaille Torride
    -- ===================================================================
    local t6 = CreateTab("|TInterface\\Icons\\spell_fire_fire:14|t  Éc. Torride", 6)
    local p6 = MakePage()
    t6:SetScript("OnClick", function() ShowPage(6) end)
    y = -8

    CreateHeader(p6, "Icône Écaille Torride", y) y = y - 24
    CreateSlider(p6, "Taille de l'icône", 20, 60, 1, "ssIconSize", 10, y, 200, function(v)
        -- Live resize all tank frames
        if ns.tankFrames then
            for i = 1, (ns.TANK_SLOTS or 1) do
                local tf = ns.tankFrames[i]
                if tf then
                    tf:SetSize(ns.settings.barWidth or 160, v)
                    if tf.iconFrame then tf.iconFrame:SetSize(v - 4, v - 4) end
                end
            end
        end
    end) y = y - 52
    CreateCheckbox(p6, "Afficher le timer", "ssShowTimer", 10, y, function(val)
        if ns.tankFrames then
            for i = 1, (ns.TANK_SLOTS or 1) do
                local tf = ns.tankFrames[i]
                if tf then
                    if tf.timerText then tf.timerText:SetShown(val) end
                    if tf.iconTimer then tf.iconTimer:SetShown(val) end
                end
            end
        end
    end) y = y - 30
    CreateCheckbox(p6, "Afficher la barre de durée", "ssShowDurationBar", 10, y, function(val)
        if ns.tankFrames then
            for i = 1, (ns.TANK_SLOTS or 1) do
                local tf = ns.tankFrames[i]
                if tf then
                    if tf.durationBar    then tf.durationBar:SetShown(val) end
                    if tf.durationBarBg  then tf.durationBarBg:SetShown(val) end
                end
            end
        end
    end) y = y - 46

    CreateHeader(p6, "Couleurs de la bordure", y) y = y - 24
    CreateLabel(p6, "Bordure active (buff présent) :", 10, y) y = y - 20
    CreateColorSwatch(p6, "Active",   "ssActiveBorderR","ssActiveBorderG","ssActiveBorderB", 10, y) y = y - 30
    CreateColorSwatch(p6, "Inactive", "ssInactiveBorderR","ssInactiveBorderG","ssInactiveBorderB", 10, y) y = y - 46

    CreateHeader(p6, "Couleurs de la barre de durée", y) y = y - 24
    CreateColorSwatch(p6, "> 50%  (plein)",  "ssFullR","ssFullG","ssFullB", 10, y) y = y - 30
    CreateColorSwatch(p6, "25-50% (milieu)", "ssMidR","ssMidG","ssMidB",   10, y) y = y - 30
    CreateColorSwatch(p6, "< 25%  (faible)", "ssLowR","ssLowG","ssLowB",   10, y) y = y - 46

    CreateHeader(p6, "Affichage", y) y = y - 24
    CreateCheckbox(p6, "Afficher le nom du tank", "ssShowTankName", 10, y) y = y - 26
    CreateCheckbox(p6, "Afficher le cadre", "ssShowBorder", 10, y)

    -- ===================================================================
    ShowPage(1)
    ns.optionsFrame = optionsFrame
end

ns.BuildOptionsPanel = function() BuildOptionsPanel() end

---------------------------------------------------------------------------
-- Hook into RebuildFrames so Frames.lua picks up new settings
---------------------------------------------------------------------------
function ns:RebuildFrames()
    -- Frames.lua reads ns.settings at build time — just reinitialize
    if ns.DestroyFrames then ns:DestroyFrames() end
    ns.frames = {}
    ns.buttons = {}
    if ns.InitializeFrames then ns:InitializeFrames() end
    C_Timer.After(0.1, function()
        ns:ResolveAllTargets()
    end)
end

---------------------------------------------------------------------------
-- Register with Blizzard addon panel (shows in Interface > Addons)
---------------------------------------------------------------------------
local function RegisterBlizzardPanel()
    local panel = CreateFrame("Frame")
    panel.name = "Augtracker"

    local title = panel:CreateFontString(nil, "ARTWORK")
    title:SetFont("Fonts\\FRIZQT__.TTF", 16, "OUTLINE")
    title:SetPoint("TOPLEFT", 16, -16)
    title:SetText("|cff55aaffAugtracker|r")

    local sub = panel:CreateFontString(nil, "ARTWORK")
    sub:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")
    sub:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -4)
    sub:SetTextColor(0.7, 0.7, 0.7, 1)
    sub:SetText("Prescience & Ebon Might tracker pour Evoker Augmentation")

    local openBtn = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    openBtn:SetSize(160, 28)
    openBtn:SetPoint("TOPLEFT", sub, "BOTTOMLEFT", 0, -16)
    openBtn:SetText("Ouvrir les options")
    openBtn:SetScript("OnClick", function()
        if not ns.optionsFrame then BuildOptionsPanel() end
        ns.optionsFrame:SetShown(not ns.optionsFrame:IsShown())
        SettingsPanel:Hide()
    end)

    if Settings and Settings.RegisterCanvasLayoutCategory then
        local category = Settings.RegisterCanvasLayoutCategory(panel, "Augtracker")
        Settings.RegisterAddOnCategory(category)
    else
        InterfaceOptions_AddCategory(panel)
    end
end

---------------------------------------------------------------------------
-- Extend slash command
---------------------------------------------------------------------------
local origSlash = SlashCmdList["PRESWOLENCE"]
SlashCmdList["PRESWOLENCE"] = function(msg)
    local cmd = msg:match("^%S+") or ""
    if cmd:lower() == "config" or cmd:lower() == "options" or cmd:lower() == "opt" then
        if not ns.optionsFrame then BuildOptionsPanel() end
        ns.optionsFrame:SetShown(not ns.optionsFrame:IsShown())
    else
        if origSlash then origSlash(msg) end
    end
end

---------------------------------------------------------------------------
-- Init hook: merge defaults and register panel after addon loads
---------------------------------------------------------------------------
local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("PLAYER_LOGIN")
initFrame:SetScript("OnEvent", function(self)
    self:UnregisterEvent("PLAYER_LOGIN")
    ApplyVisualDefaults()
    RegisterBlizzardPanel()
end)

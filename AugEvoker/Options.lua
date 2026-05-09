-- ============================================================
--  AugEvoker Options Panel
-- ============================================================

local AugEvokerOpts = {}

-- Paramètres par défaut
local defaults = {
    -- Fond
    bgR=0.07, bgG=0.07, bgB=0.07, bgA=0.96,
    -- Bordure
    bdR=0.20, bdG=0.10, bdB=0.30, bdA=1.0,
    -- Titre
    titleR=0.73, titleG=0.53, titleB=1.0,
    -- Header bg
    hdrR=0.11, hdrG=0.05, hdrB=0.18,
    -- Barre Presc alpha
    prBarA=0.75,
    -- Barre EM alpha
    emBarA=0.75,
    -- Taille police
    fontSize=10,
    -- Texture barre
    barTex="Interface\\TargetingFrame\\UI-StatusBar",
    -- ElvUI sync
    elvuiSync=false,
}

-- Sauvegarde
-- AugEvokerDB est chargé par WoW depuis SavedVariables APRES le chargement du fichier.
-- S est un proxy SANS cache local : __index lit AugEvokerDB (ou defaults si la
-- clé est absente), __newindex écrit dans AugEvokerDB. Faire rawset(S,...) ici
-- est PIÈGE : __newindex ne se redéclenche plus si la clé existe déjà dans la
-- table brute, et les writes suivants ne sont plus persistés. C'était le bug
-- "mes options ne se sauvegardent pas".

-- Forward-declaration : DOIT être avant le handler ADDON_LOADED, sinon la
-- closure capture _G.ApplySettings (toujours nil) au lieu de l'upvalue local.
local ApplySettings

local S = setmetatable({}, {
    __index = function(t, k)
        if AugEvokerDB and AugEvokerDB[k] ~= nil then return AugEvokerDB[k] end
        return defaults[k]
    end,
    __newindex = function(t, k, v)
        AugEvokerDB = AugEvokerDB or {}
        AugEvokerDB[k] = v
    end,
})

local initSettingsFrame = CreateFrame("Frame")
initSettingsFrame:RegisterEvent("ADDON_LOADED")
initSettingsFrame:SetScript("OnEvent", function(self, event, addonName)
    if addonName ~= "AugEvoker" then return end
    self:UnregisterAllEvents()
    AugEvokerDB = AugEvokerDB or {}
    if ApplySettings then ApplySettings() end
end)

-- ── Helpers UI ───────────────────────────────────────────────
local function MakeBg(parent, r,g,b,a)
    local t = parent:CreateTexture(nil,"BACKGROUND")
    t:SetAllPoints(); t:SetColorTexture(r,g,b,a)
    return t
end

local function MakeText(parent, text, size, r,g,b)
    local fs = parent:CreateFontString(nil,"OVERLAY","GameFontNormal")
    fs:SetFont("Fonts\\FRIZQT__.TTF", size or 11)
    fs:SetText(text)
    fs:SetTextColor(r or 1, g or 1, b or 1, 1)
    return fs
end

local function MakeSlider(parent, label, minV, maxV, step, val, onChange)
    local frame = CreateFrame("Frame", nil, parent)
    frame:SetSize(280, 32)

    local lbl = frame:CreateFontString(nil,"OVERLAY","GameFontNormalSmall")
    lbl:SetPoint("TOPLEFT",frame,"TOPLEFT",0,0)
    lbl:SetTextColor(0.8,0.8,0.8,1)

    local slider = CreateFrame("Slider", nil, frame, "OptionsSliderTemplate")
    slider:SetPoint("TOPLEFT",frame,"TOPLEFT",0,-16)
    slider:SetSize(220,16)
    slider:SetMinMaxValues(minV, maxV)
    slider:SetValueStep(step)
    slider:SetValue(val)
    slider:SetObeyStepOnDrag(true)

    local valTxt = frame:CreateFontString(nil,"OVERLAY","GameFontNormalSmall")
    valTxt:SetPoint("LEFT",slider,"RIGHT",6,0)
    valTxt:SetTextColor(1,1,0.5,1)
    valTxt:SetText(tostring(val))

    local function update(self, v)
        v = math.floor(v / step + 0.5) * step
        valTxt:SetText(string.format(step < 1 and "%.2f" or "%d", v))
        lbl:SetText(label..": "..valTxt:GetText())
        if onChange then onChange(v) end
    end
    slider:SetScript("OnValueChanged", update)
    update(slider, val)

    frame.slider = slider
    return frame
end

local function MakeColorSwatch(parent, label, r,g,b, onChange)
    local frame = CreateFrame("Button", nil, parent)
    frame:SetSize(180, 22)

    local swatch = CreateFrame("Button", nil, frame, "BackdropTemplate")
    swatch:SetSize(18,18)
    swatch:SetPoint("LEFT",frame,"LEFT",0,0)
    swatch:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",edgeFile="Interface\\Buttons\\WHITE8X8",edgeSize=1})
    swatch:SetBackdropColor(r,g,b,1)
    swatch:SetBackdropBorderColor(0.5,0.5,0.5,1)

    local lbl = frame:CreateFontString(nil,"OVERLAY","GameFontNormalSmall")
    lbl:SetPoint("LEFT",swatch,"RIGHT",6,0)
    lbl:SetText(label)
    lbl:SetTextColor(0.8,0.8,0.8,1)

    local cr,cg,cb = r,g,b
    swatch:SetScript("OnClick", function()
        local info = {}
        info.r, info.g, info.b = cr, cg, cb
        info.hasOpacity = false
        info.swatchFunc = function()
            cr, cg, cb = ColorPickerFrame:GetColorRGB()
            swatch:SetBackdropColor(cr, cg, cb, 1)
            if onChange then onChange(cr, cg, cb) end
        end
        info.cancelFunc = function(prev)
            if prev then
                cr, cg, cb = prev.r, prev.g, prev.b
                swatch:SetBackdropColor(cr, cg, cb, 1)
                if onChange then onChange(cr, cg, cb) end
            end
        end
        ColorPickerFrame:SetupColorPickerAndShow(info)
    end)

    frame.swatch = swatch
    frame.SetColor = function(self, r2,g2,b2)
        cr,cg,cb = r2,g2,b2
        swatch:SetBackdropColor(cr,cg,cb,1)
    end
    return frame
end

local function MakeCheckbox(parent, label, val, onChange)
    local cb = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
    cb:SetSize(24,24)
    cb:SetChecked(val)
    local lbl = cb:CreateFontString(nil,"OVERLAY","GameFontNormalSmall")
    lbl:SetPoint("LEFT",cb,"RIGHT",4,0)
    lbl:SetText(label)
    lbl:SetTextColor(0.8,0.8,0.8,1)
    cb:SetScript("OnClick",function(self)
        if onChange then onChange(self:GetChecked()) end
    end)
    return cb
end

-- ── Fenêtre principale Options ────────────────────────────────
local optFrame = CreateFrame("Frame","AugEvokerOptions",UIParent,"BackdropTemplate")
optFrame:SetSize(500,420)
optFrame:SetPoint("CENTER",UIParent,"CENTER",0,0)
optFrame:SetMovable(true); optFrame:EnableMouse(true)
optFrame:RegisterForDrag("LeftButton")
optFrame:SetScript("OnDragStart",optFrame.StartMoving)
optFrame:SetScript("OnDragStop",optFrame.StopMovingOrSizing)
optFrame:SetFrameStrata("HIGH")
optFrame:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",edgeFile="Interface\\Buttons\\WHITE8X8",edgeSize=1})
optFrame:SetBackdropColor(0.08,0.08,0.10,0.98)
optFrame:SetBackdropBorderColor(0.30,0.15,0.50,1)
optFrame:Hide()

-- Titre
local optTitle = CreateFrame("Frame",nil,optFrame,"BackdropTemplate")
optTitle:SetPoint("TOPLEFT",optFrame,"TOPLEFT",1,-1)
optTitle:SetPoint("TOPRIGHT",optFrame,"TOPRIGHT",-1,-1)
optTitle:SetHeight(28)
optTitle:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8"})
optTitle:SetBackdropColor(0.15,0.07,0.25,1)
local optTitleTxt = optTitle:CreateFontString(nil,"OVERLAY","GameFontNormal")
optTitleTxt:SetPoint("LEFT",optTitle,"LEFT",10,0)
optTitleTxt:SetAllPoints()
optTitleTxt:SetJustifyH("LEFT"); optTitleTxt:SetJustifyV("MIDDLE")
optTitleTxt:SetText("|cFFAA77FFAug Evoker|r  Options")

local optClose = CreateFrame("Button",nil,optFrame,"UIPanelCloseButton")
optClose:SetSize(22,22)
optClose:SetPoint("TOPRIGHT",optFrame,"TOPRIGHT",2,2)

-- ── Onglets ───────────────────────────────────────────────────
local tabs = {"Général","Apparence","Texte","Texture","ElvUI"}
local tabBtns = {}
local tabPanels = {}

-- Forward-declarations des menus dropdown (créés plus loin dans le fichier)
local fontMenu, texMenu, outlineMenu
-- Forward-declarations des widgets référencés par le tab ElvUI
local fontDropLabel, fontPreview, texDropLabel, texPreview, bgColorSwatch

local function ShowTab(idx)
    -- Ferme tous les dropdowns ouverts
    if fontMenu then fontMenu:Hide() end
    if texMenu then texMenu:Hide() end
    if outlineMenu then outlineMenu:Hide() end
    for i,p in ipairs(tabPanels) do
        p:SetShown(i==idx)
    end
    for i,b in ipairs(tabBtns) do
        if i==idx then
            b:SetBackdropColor(0.22,0.10,0.35,1)
            b.fs:SetTextColor(1,0.85,1,1)
        else
            b:SetBackdropColor(0.10,0.05,0.16,1)
            b.fs:SetTextColor(0.6,0.5,0.7,1)
        end
    end
end

for i,name in ipairs(tabs) do
    local btn = CreateFrame("Button",nil,optFrame,"BackdropTemplate")
    btn:SetSize(88,24)
    btn:SetPoint("TOPLEFT",optFrame,"TOPLEFT",4+(i-1)*92,-30)
    btn:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",edgeFile="Interface\\Buttons\\WHITE8X8",edgeSize=1})
    btn:SetBackdropColor(0.10,0.05,0.16,1)
    btn:SetBackdropBorderColor(0.25,0.12,0.40,1)
    local fs = btn:CreateFontString(nil,"OVERLAY","GameFontNormalSmall")
    fs:SetAllPoints(); fs:SetText(name); fs:SetTextColor(0.6,0.5,0.7,1)
    btn.fs = fs
    btn:SetScript("OnClick",function() ShowTab(i) end)
    tabBtns[i] = btn

    local panel = CreateFrame("Frame",nil,optFrame)
    panel:SetPoint("TOPLEFT",optFrame,"TOPLEFT",4,-58)
    panel:SetPoint("BOTTOMRIGHT",optFrame,"BOTTOMRIGHT",-4,40)
    panel:Hide()
    tabPanels[i] = panel
end

-- Séparateur sous les onglets
local tabSep = optFrame:CreateTexture(nil,"OVERLAY")
tabSep:SetColorTexture(0.25,0.12,0.40,1)
tabSep:SetPoint("TOPLEFT",optFrame,"TOPLEFT",0,-54)
tabSep:SetPoint("TOPRIGHT",optFrame,"TOPRIGHT",0,-54)
tabSep:SetHeight(1)

-- Boutons Apply/Reset en bas
local applyBtn = CreateFrame("Button",nil,optFrame,"BackdropTemplate")
applyBtn:SetSize(100,22)
applyBtn:SetPoint("BOTTOMRIGHT",optFrame,"BOTTOMRIGHT",-8,8)
applyBtn:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",edgeFile="Interface\\Buttons\\WHITE8X8",edgeSize=1})
applyBtn:SetBackdropColor(0.15,0.30,0.15,1)
applyBtn:SetBackdropBorderColor(0.30,0.60,0.30,1)
local applyTxt = applyBtn:CreateFontString(nil,"OVERLAY","GameFontNormalSmall")
applyTxt:SetAllPoints(); applyTxt:SetText("Appliquer"); applyTxt:SetTextColor(0.5,1,0.5,1)

local resetBtn = CreateFrame("Button",nil,optFrame,"BackdropTemplate")
resetBtn:SetSize(100,22)
resetBtn:SetPoint("RIGHT",applyBtn,"LEFT",-6,0)
resetBtn:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",edgeFile="Interface\\Buttons\\WHITE8X8",edgeSize=1})
resetBtn:SetBackdropColor(0.30,0.10,0.10,1)
resetBtn:SetBackdropBorderColor(0.60,0.20,0.20,1)
local resetTxt = resetBtn:CreateFontString(nil,"OVERLAY","GameFontNormalSmall")
resetTxt:SetAllPoints(); resetTxt:SetText("Réinitialiser"); resetTxt:SetTextColor(1,0.5,0.5,1)

-- ── Tab 1 : Général ───────────────────────────────────────────
local p1 = tabPanels[1]
local function AddSection(panel, text, y)
    local fs = panel:CreateFontString(nil,"OVERLAY","GameFontNormal")
    fs:SetPoint("TOPLEFT",panel,"TOPLEFT",8,y)
    fs:SetTextColor(0.75,0.55,1,1)
    fs:SetText(text)
    local line = panel:CreateTexture(nil,"OVERLAY")
    line:SetColorTexture(0.30,0.15,0.50,0.6)
    line:SetPoint("TOPLEFT",panel,"TOPLEFT",8,y-14)
    line:SetPoint("TOPRIGHT",panel,"TOPRIGHT",-8,y-14)
    line:SetHeight(1)
    return fs
end

AddSection(p1,"Visibilité",-8)
local cbPresc = MakeCheckbox(p1,"Afficher colonne Presc",true,function(v) S.showPresc=v end)
cbPresc:SetPoint("TOPLEFT",p1,"TOPLEFT",12,-28)
local cbEM = MakeCheckbox(p1,"Afficher colonne EM",true,function(v) S.showEM=v end)
cbEM:SetPoint("TOPLEFT",p1,"TOPLEFT",12,-52)
local cbCt = MakeCheckbox(p1,"Afficher colonne #Pr",true,function(v) S.showCt=v end)
cbCt:SetPoint("TOPLEFT",p1,"TOPLEFT",12,-76)

AddSection(p1,"Comportement",-104)
local cbAutoReset = MakeCheckbox(p1,"Reset auto au début du combat",true,function(v) S.autoReset=v end)
cbAutoReset:SetPoint("TOPLEFT",p1,"TOPLEFT",12,-124)

-- ── Tab 2 : Apparence ─────────────────────────────────────────
local p2 = tabPanels[2]
AddSection(p2,"Couleur du fond",-8)

bgColorSwatch = MakeColorSwatch(p2,"Fond principal",S.bgR,S.bgG,S.bgB,function(r,g,b)
    S.bgR,S.bgG,S.bgB=r,g,b
    if ApplySettings then ApplySettings() end
end)
bgColorSwatch:SetPoint("TOPLEFT",p2,"TOPLEFT",12,-28)

local bdColorSwatch = MakeColorSwatch(p2,"Bordure",S.bdR,S.bdG,S.bdB,function(r,g,b)
    S.bdR,S.bdG,S.bdB=r,g,b
end)
bdColorSwatch:SetPoint("TOPLEFT",p2,"TOPLEFT",12,-52)

local titleColorSwatch = MakeColorSwatch(p2,"Titre",S.titleR,S.titleG,S.titleB,function(r,g,b)
    S.titleR,S.titleG,S.titleB=r,g,b
    if ApplySettings then ApplySettings() end
end)
titleColorSwatch:SetPoint("TOPLEFT",p2,"TOPLEFT",12,-76)

AddSection(p2,"Opacité des barres",-104)
local prBarSlider = MakeSlider(p2,"Barre Presc",0,1,0.05,S.prBarA,function(v) S.prBarA=v end)
prBarSlider:SetPoint("TOPLEFT",p2,"TOPLEFT",12,-124)

local emBarSlider = MakeSlider(p2,"Barre EM",0,1,0.05,S.emBarA,function(v) S.emBarA=v end)
emBarSlider:SetPoint("TOPLEFT",p2,"TOPLEFT",12,-168)

local bgAlphaSlider = MakeSlider(p2,"Opacité fond",0,1,0.05,S.bgA,function(v) S.bgA=v end)
bgAlphaSlider:SetPoint("TOPLEFT",p2,"TOPLEFT",12,-212)

-- ── Tab 3 : Texte ─────────────────────────────────────────────
local p3 = tabPanels[3]
AddSection(p3,"Police",-8)

-- Polices WoW de base (garanties valides)
local baseFonts = {
    {name="Par défaut",  path="Fonts\\FRIZQT__.TTF"},
    {name="Arial Narrow",path="Fonts\\ARIALN.TTF"},
    {name="Morpheus",    path="Fonts\\MORPHEUS.TTF"},
    {name="Skurri",      path="Fonts\\skurri.TTF"},
    {name="2002",        path="Fonts\\2002.TTF"},
    {name="2002 Bold",   path="Fonts\\2002B.TTF"},
}

-- Polices addon (ElvUI / ToxiUI) — ajoutées si les fichiers existent
local addonFontCandidates = {
    -- ElvUI
    {name="M 500", path="Interface\\AddOns\\ElvUI\\Core\\Media\\Fonts\\M 500.ttf"},
    {name="M 700", path="Interface\\AddOns\\ElvUI\\Core\\Media\\Fonts\\M 700.ttf"},
    {name="M 900", path="Interface\\AddOns\\ElvUI\\Core\\Media\\Fonts\\M 900.ttf"},
    -- ToxiUI (peut avoir les mêmes ou des variantes)
    {name="M 500", path="Interface\\AddOns\\ToxiUI\\Media\\Fonts\\M 500.ttf"},
    {name="M 700", path="Interface\\AddOns\\ToxiUI\\Media\\Fonts\\M 700.ttf"},
    {name="M 900", path="Interface\\AddOns\\ToxiUI\\Media\\Fonts\\M 900.ttf"},
}

-- La fontList est construite LAZILY à la première ouverture du dropdown
-- pour que SharedMedia soit déjà rempli par ElvUI/ToxiUI
local fontList = nil
local function BuildFontList()
    if fontList then return end
    fontList = {}
    local seen = {}

    -- SharedMedia en priorité (contient déjà tout)
    local LSM = LibStub and LibStub("LibSharedMedia-3.0", true)
    if LSM then
        local smFonts = LSM:HashTable("font")
        for fname, fpath in pairs(smFonts) do
            if not seen[fname:lower()] then
                fontList[#fontList+1] = {name=fname, path=fpath}
                seen[fname:lower()] = true
            end
        end
    end

    -- Polices addon candidates si pas déjà dans SharedMedia
    for _, f in ipairs(addonFontCandidates) do
        if not seen[f.name:lower()] then
            -- Vérifie si la police est valide avec un test temporaire
            local tmp = UIParent:CreateFontString(nil, "ARTWORK")
            local ok = pcall(function() tmp:SetFont(f.path, 12) end)
            if ok and tmp:GetFont() and tmp:GetFont() ~= "" then
                fontList[#fontList+1] = {name=f.name, path=f.path}
                seen[f.name:lower()] = true
            end
            tmp:Hide()
        end
    end

    -- Polices WoW de base (si pas déjà présentes)
    for _, f in ipairs(baseFonts) do
        if not seen[f.name:lower()] then
            fontList[#fontList+1] = {name=f.name, path=f.path}
            seen[f.name:lower()] = true
        end
    end

    table.sort(fontList, function(a,b) return a.name:lower() < b.name:lower() end)
end

-- Helper : SetFont sécurisé — retourne true si la police a bien été appliquée
local function SafeSetFont(fs, path, size)
    local ok = pcall(function() fs:SetFont(path, size or 11) end)
    if ok then
        local f = fs:GetFont()
        if f and f ~= "" then return true end
    end
    -- Fallback garanti
    fs:SetFont("Fonts\\FRIZQT__.TTF", size or 11)
    return false
end

-- Dropdown de sélection police
local fontDropdownOpen = false
local fontDropdownMenu = nil

-- Nom de la police courante pour affichage initial
local function GetCurrentFontName()
    if not S.customFont then return "Par défaut" end
    -- Cherche dans baseFonts
    for _, f in ipairs(baseFonts) do
        if f.path == S.customFont then return f.name end
    end
    -- Extrait le nom depuis le chemin
    return S.customFont:match("([^\\/]+)%.%a+$") or "Personnalisée"
end

local fontDropBtn = CreateFrame("Button", nil, p3, "BackdropTemplate")
fontDropBtn:SetSize(240, 22)
fontDropBtn:SetPoint("TOPLEFT", p3, "TOPLEFT", 12, -28)
fontDropBtn:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8", edgeFile="Interface\\Buttons\\WHITE8X8", edgeSize=1})
fontDropBtn:SetBackdropColor(0.12, 0.06, 0.20, 1)
fontDropBtn:SetBackdropBorderColor(0.35, 0.18, 0.55, 1)

fontDropLabel = fontDropBtn:CreateFontString(nil,"OVERLAY","GameFontNormalSmall")
fontDropLabel:SetPoint("LEFT", fontDropBtn, "LEFT", 8, 0)
fontDropLabel:SetPoint("RIGHT", fontDropBtn, "RIGHT", -20, 0)
fontDropLabel:SetJustifyH("LEFT")
fontDropLabel:SetTextColor(0.9, 0.8, 1, 1)
fontDropLabel:SetText(GetCurrentFontName())

local fontDropArrow = fontDropBtn:CreateFontString(nil,"OVERLAY","GameFontNormalSmall")
fontDropArrow:SetPoint("RIGHT", fontDropBtn, "RIGHT", -4, 0)
fontDropArrow:SetText("▼")
fontDropArrow:SetTextColor(0.6, 0.5, 0.8, 1)

-- Preview du texte avec la police choisie
fontPreview = p3:CreateFontString(nil, "OVERLAY")
fontPreview:SetPoint("TOPLEFT", fontDropBtn, "BOTTOMLEFT", 0, -6)
fontPreview:SetSize(240, 20)
fontPreview:SetJustifyH("LEFT")
SafeSetFont(fontPreview, S.customFont or "Fonts\\FRIZQT__.TTF", S.fontSize or 11)
fontPreview:SetText("AugEvoker — Aperçu de la police")
fontPreview:SetTextColor(0.8, 0.7, 1, 1)

-- Panneau dropdown (scrollable si beaucoup de polices)
local ROW_H = 22
local MAX_VISIBLE = 10
fontMenu = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
fontMenu:SetSize(240, MAX_VISIBLE * ROW_H + 6)  -- taille initiale, redimensionnée à l'ouverture
fontMenu:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8", edgeFile="Interface\\Buttons\\WHITE8X8", edgeSize=1})
fontMenu:SetBackdropColor(0.08, 0.04, 0.14, 0.97)
fontMenu:SetBackdropBorderColor(0.35, 0.18, 0.55, 1)
fontMenu:SetFrameStrata("DIALOG")
fontMenu:Hide()

local scrollFrame = CreateFrame("ScrollFrame", nil, fontMenu)
scrollFrame:SetPoint("TOPLEFT", fontMenu, "TOPLEFT", 3, -3)
scrollFrame:SetPoint("BOTTOMRIGHT", fontMenu, "BOTTOMRIGHT", -3, 3)

local scrollContent = CreateFrame("Frame", nil, scrollFrame)
scrollContent:SetSize(234, MAX_VISIBLE * ROW_H)
scrollFrame:SetScrollChild(scrollContent)

-- Scrollbar (créée une fois, réutilisée)
local fontScrollBar = CreateFrame("Slider", nil, fontMenu, "UIPanelScrollBarTemplate")
fontScrollBar:SetPoint("TOPRIGHT", fontMenu, "TOPRIGHT", -2, -18)
fontScrollBar:SetPoint("BOTTOMRIGHT", fontMenu, "BOTTOMRIGHT", -2, 18)
fontScrollBar:SetMinMaxValues(0, 0)
fontScrollBar:SetValueStep(ROW_H)
fontScrollBar:SetValue(0)
fontScrollBar:SetScript("OnValueChanged", function(self, val) scrollFrame:SetVerticalScroll(val) end)
fontMenu:SetScript("OnMouseWheel", function(_, delta)
    fontScrollBar:SetValue(fontScrollBar:GetValue() - delta * ROW_H * 2)
end)

local fontMenuBtns = {}
fontDropBtn:SetScript("OnClick", function()
    if fontMenu:IsShown() then
        fontMenu:Hide()
        return
    end
    -- Construit la liste si pas encore fait
    BuildFontList()
    -- Reconstruit les boutons du menu
    for _, b in ipairs(fontMenuBtns) do b:Hide() end
    fontMenuBtns = {}
    local visibleH = math.min(#fontList, MAX_VISIBLE) * ROW_H + 6
    scrollContent:SetSize(234, #fontList * ROW_H)
    fontMenu:SetSize(240, visibleH)
    -- Met à jour la scrollbar
    local maxScroll = math.max(0, #fontList * ROW_H - (visibleH - 6))
    fontScrollBar:SetMinMaxValues(0, maxScroll)
    fontScrollBar:SetValue(0)
    fontScrollBar:SetShown(maxScroll > 0)
    for i, f in ipairs(fontList) do
        local row = fontMenuBtns[i] or CreateFrame("Button", nil, scrollContent)
        row:SetSize(234, ROW_H)
        row:SetPoint("TOPLEFT", scrollContent, "TOPLEFT", 0, -(i-1)*ROW_H)
        local rowBg = row.bg or row:CreateTexture(nil,"BACKGROUND")
        rowBg:SetAllPoints(); rowBg:SetColorTexture(0,0,0,0); row.bg = rowBg
        local rowTxt = row.txt
        if not rowTxt then
            rowTxt = row:CreateFontString(nil,"OVERLAY")
            rowTxt:SetPoint("LEFT",row,"LEFT",6,0)
            rowTxt:SetPoint("RIGHT",row,"RIGHT",-4,0)
            rowTxt:SetJustifyH("LEFT")
            row.txt = rowTxt
        end
        SafeSetFont(rowTxt, f.path, 11)
        local sel = (S.customFont == f.path)
        rowTxt:SetText((sel and "|cFFAA77FF✓ |r" or "  ") .. f.name)
        rowTxt:SetTextColor(sel and 1 or 0.8, sel and 0.85 or 0.8, 1, 1)
        row:SetScript("OnEnter", function() rowBg:SetColorTexture(0.3,0.15,0.5,0.5) end)
        row:SetScript("OnLeave", function() rowBg:SetColorTexture(0,0,0,0) end)
        row:SetScript("OnClick", function()
            S.customFont = f.path
            fontDropLabel:SetText(f.name)
            SafeSetFont(fontPreview, f.path, S.fontSize or 11)
            for j, b2 in ipairs(fontMenuBtns) do
                local s2 = (S.customFont == fontList[j].path)
                b2.txt:SetText((s2 and "|cFFAA77FF✓ |r" or "  ") .. fontList[j].name)
                b2.txt:SetTextColor(s2 and 1 or 0.8, s2 and 0.85 or 0.8, 1, 1)
            end
            fontMenu:Hide()
            if ApplySettings then ApplySettings() end
        end)
        row:Show()
        fontMenuBtns[i] = row
    end
    fontMenu:ClearAllPoints()
    fontMenu:SetPoint("TOPLEFT", fontDropBtn, "BOTTOMLEFT", 0, -2)
    fontMenu:Show()
    fontMenu:Raise()
end)

-- Ferme le dropdown si on clique ailleurs
fontMenu:SetScript("OnHide", function() fontDropArrow:SetText("▼") end)
fontMenu:SetScript("OnShow", function() fontDropArrow:SetText("▲") end)

AddSection(p3,"Taille de police",-88)
local fontSlider = MakeSlider(p3,"Taille",8,16,1,S.fontSize,function(v)
    S.fontSize=v
    SafeSetFont(fontPreview, S.customFont or "Fonts\\FRIZQT__.TTF", v)
    if ApplySettings then ApplySettings() end
end)
fontSlider:SetPoint("TOPLEFT",p3,"TOPLEFT",12,-108)

AddSection(p3,"Contour & Ombre",-155)

local outlineOptions = {
    {name="Aucun",              flag=""},
    {name="Outline",            flag="OUTLINE"},
    {name="Thick",              flag="THICKOUTLINE"},
    {name="Mono",               flag="MONOCHROME"},
    {name="Mono Outline",       flag="MONOCHROME,OUTLINE"},
    {name="Mono Thick",         flag="MONOCHROME,THICKOUTLINE"},
    {name="Shadow Outline",     flag="OUTLINE",        shadow=true},
    {name="Shadow Thick",       flag="THICKOUTLINE",   shadow=true},
}

local currentOutlineIdx = 1
for i, o in ipairs(outlineOptions) do
    if (S.fontOutline or "") == o.flag and (S.fontShadow or false) == (o.shadow or false) then
        currentOutlineIdx = i; break
    end
end

local outlineDropBtn = CreateFrame("Button", nil, p3, "BackdropTemplate")
outlineDropBtn:SetSize(240, 22)
outlineDropBtn:SetPoint("TOPLEFT", p3, "TOPLEFT", 12, -175)
outlineDropBtn:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8", edgeFile="Interface\\Buttons\\WHITE8X8", edgeSize=1})
outlineDropBtn:SetBackdropColor(0.12, 0.06, 0.20, 1)
outlineDropBtn:SetBackdropBorderColor(0.35, 0.18, 0.55, 1)

local outlineLabel = outlineDropBtn:CreateFontString(nil,"OVERLAY","GameFontNormalSmall")
outlineLabel:SetPoint("LEFT", outlineDropBtn, "LEFT", 8, 0)
outlineLabel:SetPoint("RIGHT", outlineDropBtn, "RIGHT", -20, 0)
outlineLabel:SetJustifyH("LEFT")
outlineLabel:SetTextColor(0.9, 0.8, 1, 1)
outlineLabel:SetText(outlineOptions[currentOutlineIdx].name)

local outlineArrow = outlineDropBtn:CreateFontString(nil,"OVERLAY","GameFontNormalSmall")
outlineArrow:SetPoint("RIGHT", outlineDropBtn, "RIGHT", -4, 0)
outlineArrow:SetText("▼"); outlineArrow:SetTextColor(0.6, 0.5, 0.8, 1)

outlineMenu = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
outlineMenu:SetSize(240, #outlineOptions * 22 + 6)
outlineMenu:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8", edgeFile="Interface\\Buttons\\WHITE8X8", edgeSize=1})
outlineMenu:SetBackdropColor(0.08, 0.04, 0.14, 0.97)
outlineMenu:SetBackdropBorderColor(0.35, 0.18, 0.55, 1)
outlineMenu:SetFrameStrata("DIALOG")
outlineMenu:Hide()

local outlineBtns = {}
for i, o in ipairs(outlineOptions) do
    local row = CreateFrame("Button", nil, outlineMenu)
    row:SetSize(234, 22)
    row:SetPoint("TOPLEFT", outlineMenu, "TOPLEFT", 3, -3 - (i-1)*22)
    local rowBg = row:CreateTexture(nil,"BACKGROUND"); rowBg:SetAllPoints(); rowBg:SetColorTexture(0,0,0,0)
    local rowTxt = row:CreateFontString(nil,"OVERLAY","GameFontNormalSmall")
    rowTxt:SetPoint("LEFT", row, "LEFT", 6, 0); rowTxt:SetJustifyH("LEFT")
    rowTxt:SetText((i==currentOutlineIdx and "|cFFAA77FF✓ |r" or "  ") .. o.name)
    rowTxt:SetTextColor(i==currentOutlineIdx and 1 or 0.8, i==currentOutlineIdx and 0.85 or 0.8, 1, 1)
    row:SetScript("OnEnter", function() rowBg:SetColorTexture(0.3,0.15,0.5,0.5) end)
    row:SetScript("OnLeave", function() rowBg:SetColorTexture(0,0,0,0) end)
    row:SetScript("OnClick", function()
        currentOutlineIdx = i
        S.fontOutline = o.flag
        S.fontShadow  = o.shadow or false
        outlineLabel:SetText(o.name)
        for j, b2 in ipairs(outlineBtns) do
            b2.txt:SetText((j==i and "|cFFAA77FF✓ |r" or "  ") .. outlineOptions[j].name)
            b2.txt:SetTextColor(j==i and 1 or 0.8, j==i and 0.85 or 0.8, 1, 1)
        end
        outlineMenu:Hide()
        if ApplySettings then ApplySettings() end
    end)
    row.txt = rowTxt
    outlineBtns[i] = row
end

outlineDropBtn:SetScript("OnClick", function()
    if outlineMenu:IsShown() then outlineMenu:Hide(); return end
    outlineMenu:ClearAllPoints()
    outlineMenu:SetPoint("TOPLEFT", outlineDropBtn, "BOTTOMLEFT", 0, -2)
    outlineMenu:Show(); outlineMenu:Raise()
    outlineArrow:SetText("▲")
end)
outlineMenu:SetScript("OnHide", function() outlineArrow:SetText("▼") end)

AddSection(p3,"Couleurs des textes",-212)
local nameColorSwatch = MakeColorSwatch(p3,"Nom (sans classe)",1,1,1,function(r,g,b)
    S.nameR,S.nameG,S.nameB=r,g,b
end)
nameColorSwatch:SetPoint("TOPLEFT",p3,"TOPLEFT",12,-232)

local hdrColorSwatch = MakeColorSwatch(p3,"En-têtes colonnes",0.60,0.45,0.80,function(r,g,b)
    S.hdrR2,S.hdrG2,S.hdrB2=r,g,b
end)
hdrColorSwatch:SetPoint("TOPLEFT",p3,"TOPLEFT",12,-256)

-- ── Tab 4 : Texture ───────────────────────────────────────────
local p4 = tabPanels[4]
AddSection(p4,"Texture des barres",-8)

-- Textures WoW de base garanties
local baseTextures = {
    {name="Default",      path="Interface\\TargetingFrame\\UI-StatusBar"},
    {name="Blizzard",     path="Interface\\PaperDollInfoFrame\\UI-Character-Skills-Bar"},
    {name="Smooth",       path="Interface\\Buttons\\WHITE8X8"},
    {name="Flat",         path="Interface\\RaidFrame\\Raid-Bar-Hp-Fill"},
    {name="BantoBar",     path="Interface\\AddOns\\ElvUI\\Core\\Media\\Textures\\StatusBars\\BantoBar"},
    {name="Blizzard Ch.", path="Interface\\AddOns\\ElvUI\\Core\\Media\\Textures\\StatusBars\\Blizzard Charcoal"},
    {name="Details Flat", path="Interface\\AddOns\\Details\\images\\statusbar\\flat"},
}

local texList = nil
local function BuildTexList()
    if texList then return end
    texList = {}
    local seen = {}
    -- SharedMedia en priorité
    local LSM = LibStub and LibStub("LibSharedMedia-3.0", true)
    if LSM then
        local smTex = LSM:HashTable("statusbar")
        for tname, tpath in pairs(smTex) do
            if not seen[tname:lower()] then
                texList[#texList+1] = {name=tname, path=tpath}
                seen[tname:lower()] = true
            end
        end
    end
    -- Base si pas dans SharedMedia
    for _, t in ipairs(baseTextures) do
        if not seen[t.name:lower()] then
            texList[#texList+1] = {name=t.name, path=t.path}
            seen[t.name:lower()] = true
        end
    end
    table.sort(texList, function(a,b) return a.name:lower() < b.name:lower() end)
end

-- Nom de la texture courante
local function GetCurrentTexName()
    if not S.barTex then return "Default" end
    for _, t in ipairs(baseTextures) do
        if t.path == S.barTex then return t.name end
    end
    return S.barTex:match("([^\\/]+)$") or "Personnalisée"
end

-- Dropdown texture
local TEX_ROW_H = 28
local TEX_MAX_VIS = 10
local texDropBtn = CreateFrame("Button", nil, p4, "BackdropTemplate")
texDropBtn:SetSize(260, 24)
texDropBtn:SetPoint("TOPLEFT", p4, "TOPLEFT", 12, -28)
texDropBtn:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8", edgeFile="Interface\\Buttons\\WHITE8X8", edgeSize=1})
texDropBtn:SetBackdropColor(0.12, 0.06, 0.20, 1)
texDropBtn:SetBackdropBorderColor(0.35, 0.18, 0.55, 1)

texDropLabel = texDropBtn:CreateFontString(nil,"OVERLAY","GameFontNormalSmall")
texDropLabel:SetPoint("LEFT", texDropBtn, "LEFT", 8, 0)
texDropLabel:SetPoint("RIGHT", texDropBtn, "RIGHT", -20, 0)
texDropLabel:SetJustifyH("LEFT"); texDropLabel:SetTextColor(0.9, 0.8, 1, 1)
texDropLabel:SetText(GetCurrentTexName())

local texDropArrow = texDropBtn:CreateFontString(nil,"OVERLAY","GameFontNormalSmall")
texDropArrow:SetPoint("RIGHT", texDropBtn, "RIGHT", -4, 0)
texDropArrow:SetText("▼"); texDropArrow:SetTextColor(0.6, 0.5, 0.8, 1)

-- Preview de la texture sélectionnée
texPreview = p4:CreateTexture(nil, "ARTWORK")
texPreview:SetPoint("TOPLEFT", texDropBtn, "BOTTOMLEFT", 0, -6)
texPreview:SetSize(260, 18)
texPreview:SetTexture(S.barTex or "Interface\\TargetingFrame\\UI-StatusBar")
texPreview:SetVertexColor(0.3, 0.6, 1, 0.9)

-- Menu dropdown texture
texMenu = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
texMenu:SetSize(260, TEX_MAX_VIS * TEX_ROW_H + 6)
texMenu:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8", edgeFile="Interface\\Buttons\\WHITE8X8", edgeSize=1})
texMenu:SetBackdropColor(0.08, 0.04, 0.14, 0.97)
texMenu:SetBackdropBorderColor(0.35, 0.18, 0.55, 1)
texMenu:SetFrameStrata("DIALOG"); texMenu:Hide()

local texScrollFrame = CreateFrame("ScrollFrame", nil, texMenu)
texScrollFrame:SetPoint("TOPLEFT", texMenu, "TOPLEFT", 3, -3)
texScrollFrame:SetPoint("BOTTOMRIGHT", texMenu, "BOTTOMRIGHT", -3, 3)

local texScrollContent = CreateFrame("Frame", nil, texScrollFrame)
texScrollContent:SetSize(254, TEX_MAX_VIS * TEX_ROW_H)
texScrollFrame:SetScrollChild(texScrollContent)

local texScrollBar = CreateFrame("Slider", nil, texMenu, "UIPanelScrollBarTemplate")
texScrollBar:SetPoint("TOPRIGHT", texMenu, "TOPRIGHT", -2, -18)
texScrollBar:SetPoint("BOTTOMRIGHT", texMenu, "BOTTOMRIGHT", -2, 18)
texScrollBar:SetMinMaxValues(0, 0); texScrollBar:SetValueStep(TEX_ROW_H); texScrollBar:SetValue(0)
texScrollBar:SetScript("OnValueChanged", function(self, val) texScrollFrame:SetVerticalScroll(val) end)
texMenu:SetScript("OnMouseWheel", function(_, delta)
    texScrollBar:SetValue(texScrollBar:GetValue() - delta * TEX_ROW_H * 2)
end)

local texMenuBtns = {}
texDropBtn:SetScript("OnClick", function()
    if texMenu:IsShown() then texMenu:Hide(); return end
    BuildTexList()
    for _, b in ipairs(texMenuBtns) do b:Hide() end
    texMenuBtns = {}
    local visH = math.min(#texList, TEX_MAX_VIS) * TEX_ROW_H + 6
    texScrollContent:SetSize(254, #texList * TEX_ROW_H)
    texMenu:SetSize(260, visH)
    local maxScroll = math.max(0, #texList * TEX_ROW_H - (visH - 6))
    texScrollBar:SetMinMaxValues(0, maxScroll); texScrollBar:SetValue(0)
    texScrollBar:SetShown(maxScroll > 0)

    for i, t in ipairs(texList) do
        local row = CreateFrame("Button", nil, texScrollContent)
        row:SetSize(254, TEX_ROW_H)
        row:SetPoint("TOPLEFT", texScrollContent, "TOPLEFT", 0, -(i-1)*TEX_ROW_H)
        -- Fond avec la texture (toute la largeur)
        local bg = row:CreateTexture(nil, "BACKGROUND")
        bg:SetPoint("TOPLEFT", row, "TOPLEFT", 2, -4)
        bg:SetPoint("BOTTOMRIGHT", row, "BOTTOMRIGHT", -2, 4)
        bg:SetTexture(t.path); bg:SetVertexColor(0.3, 0.6, 1, 0.6)
        -- Highlight hover
        local hl = row:CreateTexture(nil, "ARTWORK")
        hl:SetAllPoints(); hl:SetColorTexture(0.3, 0.15, 0.5, 0)
        -- Label sur overlay, aligné à gauche
        local lbl = row:CreateFontString(nil,"OVERLAY","GameFontNormalSmall")
        lbl:SetPoint("LEFT", row, "LEFT", 6, 0)
        lbl:SetPoint("RIGHT", row, "RIGHT", -4, 0)
        lbl:SetJustifyH("LEFT")
        local sel = (S.barTex == t.path)
        lbl:SetText((sel and "|cFFAA77FF✓ |r" or "") .. t.name)
        lbl:SetTextColor(sel and 1 or 0.85, sel and 0.85 or 0.85, 1, 1)
        row:SetScript("OnEnter", function() hl:SetColorTexture(0.3,0.15,0.5,0.4) end)
        row:SetScript("OnLeave", function() hl:SetColorTexture(0,0,0,0) end)
        row:SetScript("OnClick", function()
            S.barTex = t.path
            texDropLabel:SetText(t.name)
            texPreview:SetTexture(t.path)
            for j, b2 in ipairs(texMenuBtns) do
                local s2 = (S.barTex == texList[j].path)
                b2.lbl:SetText((s2 and "|cFFAA77FF✓ |r" or "") .. texList[j].name)
                b2.lbl:SetTextColor(s2 and 1 or 0.85, s2 and 0.85 or 0.85, 1, 1)
            end
            texMenu:Hide()
            if ApplySettings then ApplySettings() end
        end)
        row.lbl = lbl
        texMenuBtns[i] = row; row:Show()
    end
    texMenu:ClearAllPoints()
    texMenu:SetPoint("TOPLEFT", texDropBtn, "BOTTOMLEFT", 0, -2)
    texMenu:Show(); texMenu:Raise()
    texDropArrow:SetText("▲")
end)
texMenu:SetScript("OnHide", function() texDropArrow:SetText("▼") end)

-- ── Tab 5 : ElvUI ─────────────────────────────────────────────
local p5 = tabPanels[5]
AddSection(p5,"Synchronisation automatique",-8)

local detectedTxt = p5:CreateFontString(nil,"OVERLAY","GameFontNormalSmall")
detectedTxt:SetPoint("TOPLEFT",p5,"TOPLEFT",12,-28)

local function RefreshElvDetection()
    local E = ElvUI and ElvUI[1]
    if E then
        local isToxiUI = (ToxiUI ~= nil)
        detectedTxt:SetText("Addon détecté : |cFF00FF00"..(isToxiUI and "ToxiUI" or "ElvUI").."|r")
        return true
    end
    detectedTxt:SetText("Addon détecté : |cFFFF4444Aucun|r")
    return false
end
-- Détecte au chargement ET quand on affiche le tab
RefreshElvDetection()

local cbElvSync = MakeCheckbox(p5,"Activer la synchro ElvUI / ToxiUI",S.elvuiSync,function(v)
    S.elvuiSync=v
end)
cbElvSync:SetPoint("TOPLEFT",p5,"TOPLEFT",12,-52)

local syncBtn = CreateFrame("Button",nil,p5,"BackdropTemplate")
syncBtn:SetSize(200,24)
syncBtn:SetPoint("TOPLEFT",p5,"TOPLEFT",12,-80)
syncBtn:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",edgeFile="Interface\\Buttons\\WHITE8X8",edgeSize=1})
syncBtn:SetBackdropColor(0.15,0.07,0.25,1)
syncBtn:SetBackdropBorderColor(0.60,0.40,0.90,1)
local syncTxt = syncBtn:CreateFontString(nil,"OVERLAY","GameFontNormalSmall")
syncTxt:SetAllPoints(); syncTxt:SetText("|cFFFF9900Appliquer style ElvUI/ToxiUI|r")

syncBtn:SetScript("OnClick",function()
    RefreshElvDetection()
    local E = ElvUI and ElvUI[1]
    if not E then
        DEFAULT_CHAT_FRAME:AddMessage("|cFFAA77FF[AugEvoker]|r ElvUI/ToxiUI non détecté.")
        return
    end
    -- Police
    if E.media and E.media.normFont then
        S.customFont = E.media.normFont
        if fontDropLabel then fontDropLabel:SetText(S.customFont:match("([^\\/]+)$") or "ElvUI") end
        if fontPreview then SafeSetFont(fontPreview, S.customFont, S.fontSize or 11) end
    end
    -- Texture
    if E.media and E.media.normTex then
        S.barTex = E.media.normTex
        if texDropLabel then texDropLabel:SetText(S.barTex:match("([^\\/]+)$") or "ElvUI") end
        if texPreview then texPreview:SetTexture(S.barTex) end
    end
    -- Couleur fond
    local db = E.db and E.db.profile
    if db then
        local cc = db.general and db.general.backdropfadecolor
        if cc then
            S.bgR,S.bgG,S.bgB = cc.r,cc.g,cc.b
            if bgColorSwatch then bgColorSwatch:SetColor(cc.r,cc.g,cc.b) end
        end
    end
    S.elvuiSync = true
    -- Applique immédiatement
    if ApplySettings then ApplySettings() end
    DEFAULT_CHAT_FRAME:AddMessage("|cFFAA77FF[AugEvoker]|r Style ElvUI/ToxiUI appliqué.")
end)

AddSection(p5,"Aperçu des valeurs",-112)
local previewTxt = p5:CreateFontString(nil,"OVERLAY","GameFontNormalSmall")
previewTxt:SetPoint("TOPLEFT",p5,"TOPLEFT",12,-132)
previewTxt:SetTextColor(0.6,0.8,1,1)
previewTxt:SetText("Police : défaut\nTexture : défaut\nCouleur : non définie")

-- Mise à jour de l'aperçu
syncBtn:HookScript("OnClick",function()
    local fontName = S.customFont and S.customFont:match("([^\\]+)$") or "défaut"
    local texName  = S.barTex and S.barTex:match("([^\\]+)$") or "défaut"
    local colStr   = S.bgR and string.format("%.2f / %.2f / %.2f",S.bgR,S.bgG,S.bgB) or "non définie"
    previewTxt:SetText("Police : "..fontName.."\nTexture : "..texName.."\nCouleur : "..colStr)
end)

-- ── Fonction Apply ────────────────────────────────────────────
ApplySettings = function()
    if not AugEvokerMain then return end
    local mf = AugEvokerMain

    -- Fond
    mf:SetBackdropColor(S.bgR,S.bgG,S.bgB,S.bgA)
    mf:SetBackdropBorderColor(S.bdR,S.bdG,S.bdB,1)

    -- Les vraies textures de fond visibles sont les row.bg (sublevel 2, au-dessus du backdrop)
    if mf.rows then
        for _, row in ipairs(mf.rows) do
            if row.bg then
                row.bg:SetColorTexture(S.bgR, S.bgG, S.bgB, math.max(S.bgA or 0.96, 0.1))
            end
        end
    end

    -- Titre couleur — on reconstruit le texte avec le bon |cFF...| car
    -- SetTextColor est écrasé par les codes couleur inline
    if mf.titleText then
        local ver = mf.addonVersion or ""
        local tr = math.floor((S.titleR or 0.73)*255)
        local tg = math.floor((S.titleG or 0.53)*255)
        local tb = math.floor((S.titleB or 1.0 )*255)
        mf.titleText:SetText(string.format("|cFF%02X%02X%02XAug Evoker|r  |cFF555555v%s|r", tr, tg, tb, ver))
    end

    -- Barres : opacité
    if mf.rows then
        for _,row in ipairs(mf.rows) do
            if row.prBar then
                local cr,cg,cb = 0.3,0.6,1
                row.prBar:SetVertexColor(cr,cg,cb,S.prBarA)
            end
            if row.emBar then
                row.emBar:SetVertexColor(0.8,0.4,1.0,S.emBarA)
            end
            -- Texture
            if row.prBar and S.barTex then
                row.prBar:SetTexture(S.barTex)
            end
            if row.emBar and S.barTex then
                row.emBar:SetTexture(S.barTex)
            end
        end
    end

    -- Police
    local font = S.customFont or "Fonts\\FRIZQT__.TTF"
    local size = S.fontSize or 10
    if mf.rows then
        for _,row in ipairs(mf.rows) do
            local outline = S.fontOutline or ""
            if row.name then row.name:SetFont(font,size,outline) end
            if row.ct   then row.ct:SetFont(font,size,outline) end
            if row.pr   then row.pr:SetFont(font,size,outline) end
            if row.em   then row.em:SetFont(font,size,outline) end
            -- Ombre
            local hasShadow = S.fontShadow or false
            if row.name then row.name:SetShadowOffset(hasShadow and 1 or 0, hasShadow and -1 or 0) end
            if row.ct   then row.ct:SetShadowOffset(hasShadow and 1 or 0, hasShadow and -1 or 0) end
            if row.pr   then row.pr:SetShadowOffset(hasShadow and 1 or 0, hasShadow and -1 or 0) end
            if row.em   then row.em:SetShadowOffset(hasShadow and 1 or 0, hasShadow and -1 or 0) end
        end
    end

    -- Les valeurs sont déjà écrites dans AugEvokerDB via le metatable __newindex
    DEFAULT_CHAT_FRAME:AddMessage("|cFFAA77FF[AugEvoker]|r Paramètres appliqués.")
end

applyBtn:SetScript("OnClick", ApplySettings)
resetBtn:SetScript("OnClick", function()
    -- Vide AugEvokerDB en place (ne pas remplacer la référence)
    for k in pairs(AugEvokerDB or {}) do AugEvokerDB[k] = nil end
    if ApplySettings then ApplySettings() end
    DEFAULT_CHAT_FRAME:AddMessage("|cFFAA77FF[AugEvoker]|r Paramètres réinitialisés — /reload pour rafraîchir les contrôles.")
end)

optFrame:SetScript("OnHide", function()
    if fontMenu then fontMenu:Hide() end
    if texMenu then texMenu:Hide() end
    if outlineMenu then outlineMenu:Hide() end
end)

-- Affiche l'onglet 1 par défaut
ShowTab(1)

-- ── API publique ──────────────────────────────────────────────
function AugEvokerOpts:Show()
    optFrame:Show()
    optFrame:Raise()
end

function AugEvokerOpts:Hide()
    optFrame:Hide()
end

function AugEvokerOpts:Toggle()
    if optFrame:IsShown() then optFrame:Hide() else optFrame:Show(); optFrame:Raise() end
end

function AugEvokerOpts:ApplySettings()
    ApplySettings()
end

_G.AugEvokerOpts = AugEvokerOpts

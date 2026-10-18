local addonName, ns = ...

---------------------------------------------------------------------------
-- ElvUI / oUF Integration
-- Reads ElvUI's active theme and applies fonts, bar textures,
-- backdrop style and colours to PreSwolence frames.
---------------------------------------------------------------------------

local E, C  -- ElvUI engine + config, populated on login
local oUF   -- oUF handle (optional)

---------------------------------------------------------------------------
-- Helpers
---------------------------------------------------------------------------

-- Safe read from a nested table path; returns nil if any key is missing
local function deep(t, ...)
    for _, k in ipairs({...}) do
        if type(t) ~= "table" then return nil end
        t = t[k]
    end
    return t
end

---------------------------------------------------------------------------
-- Detect ElvUI / oUF
---------------------------------------------------------------------------

local function DetectElvUI()
    -- ElvUI exposes a global table "ElvUI" with [1] = Engine
    if type(ElvUI) == "table" and ElvUI[1] then
        E = ElvUI[1]
        C = E and E.db and E.db.profile
        if E then
            -- ToxiUI is built on ElvUI — detect by its global
            local label = (type(ToxiUI) ~= "nil") and "|cffff6600ToxiUI|r" or "|cff1784d1ElvUI|r"
            ns:Print(label .. " détecté — synchronisation disponible.")
        end
    end

    -- oUF (standalone or embedded in ElvUI)
    if oUF_Vanilla then
        oUF = oUF_Vanilla
    elseif type(oUF) == "table" then
        -- already set
    elseif E and E.oUF then
        oUF = E.oUF
    end
end

---------------------------------------------------------------------------
-- Read style values from ElvUI
---------------------------------------------------------------------------

-- Returns the LSM font path ElvUI is using for unitframes/general
local function GetElvUIFont()
    if not E then return nil end
    local LSM = E.LSM or (LibStub and LibStub("LibSharedMedia-3.0", true))
    if not LSM then return nil end

    -- ElvUI stores font names in db.profile.general.font or unitframe font
    local fontName = deep(C, "general", "font")
                  or deep(C, "unitframe", "font")
    if fontName then
        local path = LSM:Fetch("font", fontName)
        if path then return path, fontName end
    end

    -- Fallback: ask ElvUI's media lib directly for its default
    if E.media and E.media.normFont then
        return E.media.normFont, "ElvUI Default"
    end

    return nil
end

-- Returns the LSM statusbar texture ElvUI is using
local function GetElvUIBarTexture()
    if not E then return nil end
    local LSM = E.LSM or (LibStub and LibStub("LibSharedMedia-3.0", true))
    if not LSM then return nil end

    local texName = deep(C, "general", "normTex")
               or deep(C, "unitframe", "statusbar")
    if texName then
        local path = LSM:Fetch("statusbar", texName)
        if path then return path, texName end
    end

    if E.media and E.media.normTex then
        return E.media.normTex, "ElvUI Default"
    end

    return nil
end

-- Returns ElvUI's backdrop / border style info
local function GetElvUIBackdrop()
    if not E then return nil end
    -- ElvUI uses CreateBackdrop; we read its preferred edgeSize and flat tex
    local edgeSize   = deep(C, "general", "borderSize") or 10
    local classColor = deep(C, "general", "classMainColor")
    return {
        edgeSize   = edgeSize,
        classColor = classColor,
    }
end

-- Returns a colour table {r,g,b} for ElvUI's class colour or theme colour
local function GetElvUIThemeColor()
    if not E then return nil end

    -- Try class colour first (player's class)
    local _, class = UnitClass("player")
    if class and E.db and E.db.profile then
        local cc = deep(C, "general", "backdropfadecolor")
        if cc then return {r = cc.r, g = cc.g, b = cc.b} end
    end

    -- Fallback: ElvUI gold/blue accent
    if E.media and E.media.rgbvaluecolor then
        local c = E.media.rgbvaluecolor
        return {r = c[1], g = c[2], b = c[3]}
    end

    return nil
end

---------------------------------------------------------------------------
-- Apply ElvUI style to PreSwolence frames
---------------------------------------------------------------------------

function ns:ApplyElvUIStyle()
    if not ns.settings.elvuiSync then return end
    if not E then
        ns:Print("|cffff4444ElvUI non détecté|r — synchronisation ignorée.")
        return
    end

    local fontPath, fontName  = GetElvUIFont()
    local barTex,  barTexName = GetElvUIBarTexture()
    local backdropInfo        = GetElvUIBackdrop()
    local themeColor          = GetElvUIThemeColor()
    local changed = {}

    -- 1. Font
    if fontPath then
        ns.settings.elvuiFontPath = fontPath
        ns.settings.elvuiFontName = fontName
        table.insert(changed, "Police: " .. (fontName or fontPath))
    end

    -- 2. Bar texture
    if barTex then
        ns.settings.elvuiBarTex     = barTex
        ns.settings.elvuiBarTexName = barTexName
        table.insert(changed, "Texture: " .. (barTexName or barTex))
    end

    -- 3. Border edgeSize
    if backdropInfo then
        ns.settings.elvuiEdgeSize = backdropInfo.edgeSize
        table.insert(changed, "Bordure: taille " .. backdropInfo.edgeSize)
    end

    -- 4. Theme colour → container border
    if themeColor then
        ns.settings.elvuiBorderR = themeColor.r
        ns.settings.elvuiBorderG = themeColor.g
        ns.settings.elvuiBorderB = themeColor.b
        table.insert(changed, string.format("Couleur thème: %.2f/%.2f/%.2f",
            themeColor.r, themeColor.g, themeColor.b))
    end

    ns:SaveData()
    if #changed > 0 then
        ns:Print("|cff1784d1ElvUI sync|r — " .. table.concat(changed, ", "))
    end

    -- Rebuild frames to apply new style
    if ns.RebuildFrames then ns:RebuildFrames() end
end

---------------------------------------------------------------------------
-- Expose helpers to Frames.lua so S() picks them up transparently
---------------------------------------------------------------------------

-- Returns the font path to use: ElvUI's if sync enabled, else saved setting
function ns:GetFontPath(fallback)
    if ns.settings.elvuiSync and ns.settings.elvuiFontPath then
        return ns.settings.elvuiFontPath
    end
    return fallback or "Fonts\\FRIZQT__.TTF"
end

-- Returns the statusbar texture: ElvUI's if sync enabled, else default
function ns:GetBarTexture(fallback)
    -- Manual override takes priority
    if ns.settings.customBarTex then
        return ns.settings.customBarTex
    end
    if ns.settings.elvuiSync and ns.settings.elvuiBarTex then
        return ns.settings.elvuiBarTex
    end
    return fallback or "Interface\\Buttons\\WHITE8X8"
end

-- Returns the border edgeSize
function ns:GetEdgeSize(fallback)
    if ns.settings.elvuiSync and ns.settings.elvuiEdgeSize then
        return ns.settings.elvuiEdgeSize
    end
    return fallback or 10
end

-- Returns container border colour (respects ElvUI theme or manual setting)
function ns:GetBorderColor()
    if ns.settings.elvuiSync and ns.settings.elvuiBorderR then
        return ns.settings.elvuiBorderR,
               ns.settings.elvuiBorderG,
               ns.settings.elvuiBorderB
    end
    local S = ns.settings
    return S.borderR or 0.18, S.borderG or 0.18, S.borderB or 0.22
end

---------------------------------------------------------------------------
-- Auto-detect on login
---------------------------------------------------------------------------

local elvuiFrame = CreateFrame("Frame")
elvuiFrame:RegisterEvent("PLAYER_LOGIN")
elvuiFrame:SetScript("OnEvent", function(self, event)
    self:UnregisterEvent("PLAYER_LOGIN")
    DetectElvUI()
    -- Auto-apply if enabled
    if ns.settings.elvuiSync then
        -- Slight delay so ElvUI finishes its own init
        C_Timer.After(1, function()
            ns:ApplyElvUIStyle()
        end)
    end
end)

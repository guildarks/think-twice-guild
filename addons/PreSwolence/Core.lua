local addonName, ns = ...

-- Binding header/names (must be globals for Bindings.xml)
BINDING_HEADER_PRESWOLENCE = "PreSwolence"
_G["BINDING_NAME_CLICK PreSwolenceButton1:LeftButton"] = "Cast Prescience on Target 1"
_G["BINDING_NAME_CLICK PreSwolenceButton2:LeftButton"] = "Cast Prescience on Target 2"
_G["BINDING_NAME_CLICK PreSwolenceButton3:LeftButton"] = "Cast Prescience on Target 3"
_G["BINDING_NAME_CLICK PreSwolenceButton4:LeftButton"] = "Cast Prescience on Target 4"

ns.NUM_SLOTS = 4
ns.PRESCIENCE_BUFF_ID     = 410089
ns.PRESCIENCE_CAST_ID     = 409311
ns.PRESCIENCE_DURATION    = 18
ns.PRESCIENCE_NAME        = "Prescience"

ns.EBON_MIGHT_BUFF_ID     = 395296
ns.EBON_MIGHT_CAST_ID     = 395152
ns.EBON_MIGHT_DURATION    = 11.1
ns.EBON_MIGHT_NAME        = "Ebon Might"

-- Searing Scales (tank buff)
ns.SEARING_SCALES_BUFF_ID  = 360827  -- Écailles torrides (TWW)
ns.SEARING_SCALES_CAST_ID  = 370817  -- cast ID (fallback)
ns.SEARING_SCALES_DURATION = 30
ns.SEARING_SCALES_NAME     = "Écailles torrides"

-- Tank slots (separate from DPS slots)
ns.TANK_SLOTS     = 1

-- State
ns.targets        = {}
ns.unitTokens     = {}
ns.buttons        = {}
ns.frames         = {}
ns.pendingChanges = {}
ns.settings       = {}
ns.tankTargets    = {}
ns.tankUnitTokens = {}

function ns:IsPrescience(val)
    if issecretvalue(val) or val == nil then return false end
    if type(val) == "string" then
        return val == self.PRESCIENCE_NAME
    end
    return val == self.PRESCIENCE_BUFF_ID
end

function ns:Print(msg)
    print("|cff33ff99Augtracker|r: " .. msg)
end

---------------------------------------------------------------------------
-- Name -> unit token resolution
---------------------------------------------------------------------------
function ns:ResolveNameToUnit(name)
    if not name then return nil end
    local searchName = name:lower()

    local function checkUnit(unit)
        local uName, uRealm = UnitName(unit)
        if not uName then return false end
        if uName:lower() == searchName then return true end
        local fullName = (uRealm and uRealm ~= "") and (uName .. "-" .. uRealm) or uName
        return fullName:lower() == searchName
    end

    if IsInRaid() then
        for i = 1, 40 do
            local unit = "raid" .. i
            if UnitExists(unit) and checkUnit(unit) then
                return unit
            end
        end
    else
        for i = 1, 4 do
            local unit = "party" .. i
            if UnitExists(unit) and checkUnit(unit) then
                return unit
            end
        end
        if checkUnit("player") then
            return "player"
        end
    end
    return nil
end

---------------------------------------------------------------------------
-- Resolve all assigned targets
---------------------------------------------------------------------------
function ns:ResolveAllTargets()
    for slot = 1, ns.NUM_SLOTS do
        local target = ns.targets[slot]
        if target then
            local unit = ns:ResolveNameToUnit(target.name)
            ns.unitTokens[slot] = unit
            ns:UpdateButtonUnit(slot, unit)
            ns:UpdateFrameUnit(slot, unit)
        else
            ns.unitTokens[slot] = nil
            ns:UpdateButtonUnit(slot, nil)
            ns:UpdateFrameUnit(slot, nil)
        end
        ns:NotifyBuffTracker(slot)
    end

    -- Resolve tank unit tokens for Searing Scales tracker
    for i = 1, ns.TANK_SLOTS do
        local t = ns.tankTargets and ns.tankTargets[i]
        if t then
            ns.tankUnitTokens[i] = ns:ResolveNameToUnit(t.name)
        else
            ns.tankUnitTokens[i] = nil
        end
    end

    if ns.RefreshTankFrames then ns:RefreshTankFrames() end
end

---------------------------------------------------------------------------
-- SecureActionButton attribute updates (combat-safe)
---------------------------------------------------------------------------
function ns:UpdateButtonUnit(slot, unit)
    local btn = ns.buttons[slot]
    if not btn then return end

    if InCombatLockdown() then
        table.insert(ns.pendingChanges, { type = "button", slot = slot, unit = unit })
        return
    end

    btn:SetAttribute("unit", unit or "none")
end

function ns:UpdateFrameUnit(slot, unit)
    local frame = ns.frames[slot]
    if not frame then return end

    if InCombatLockdown() then
        table.insert(ns.pendingChanges, { type = "frame", slot = slot, unit = unit })
        return
    end

    frame:SetAttribute("unit", unit or nil)

    if ns.ReflowFrames then
        ns:ReflowFrames()
    end
end

function ns:FlushPendingChanges()
    if InCombatLockdown() then return end

    for _, change in ipairs(ns.pendingChanges) do
        if change.type == "button" then
            ns:UpdateButtonUnit(change.slot, change.unit)
        elseif change.type == "frame" then
            ns:UpdateFrameUnit(change.slot, change.unit)
        end
    end

    if #ns.pendingChanges > 0 then
        ns:Print("Queued changes applied.")
        wipe(ns.pendingChanges)
    end
end

---------------------------------------------------------------------------
-- Assign / clear targets
---------------------------------------------------------------------------
function ns:AssignTarget(slot, name)
    if slot < 1 or slot > ns.NUM_SLOTS then
        ns:Print("Slot must be 1-" .. ns.NUM_SLOTS .. ".")
        return
    end
    if not name or name == "" then return end

    -- Duplicate check — auto-move
    for i = 1, ns.NUM_SLOTS do
        if i ~= slot and ns.targets[i] and ns.targets[i].name:lower() == name:lower() then
            ns:Print("Moved " .. ns.targets[i].name .. " from slot " .. i .. " to slot " .. slot .. ".")
            ns:ClearTarget(i)
            break
        end
    end

    local unit = ns:ResolveNameToUnit(name)
    local class = unit and select(2, UnitClass(unit)) or "UNKNOWN"
    local displayName = name

    if unit then
        local uName, uRealm = UnitName(unit)
        displayName = (uRealm and uRealm ~= "") and (uName .. "-" .. uRealm) or uName
    end

    ns.targets[slot] = { name = displayName, class = class }
    ns.unitTokens[slot] = unit

    if InCombatLockdown() then
        table.insert(ns.pendingChanges, { type = "button", slot = slot, unit = unit })
        table.insert(ns.pendingChanges, { type = "frame",  slot = slot, unit = unit })
        ns:Print("Target " .. slot .. " set to " .. displayName .. " (will apply when combat ends).")
    else
        ns:UpdateButtonUnit(slot, unit)
        ns:UpdateFrameUnit(slot, unit)
        local status = unit and ("resolved to " .. unit) or "not in group yet"
        ns:Print("Target " .. slot .. " set to " .. displayName .. " (" .. status .. ").")
    end

    ns:SaveData()
    ns:NotifyBuffTracker(slot)
end

function ns:ClearTarget(slot)
    if slot < 1 or slot > ns.NUM_SLOTS then
        ns:Print("Slot must be 1-" .. ns.NUM_SLOTS .. ".")
        return
    end

    local prev = ns.targets[slot]
    if not prev then return end

    ns.targets[slot]    = nil
    ns.unitTokens[slot] = nil
    ns:UpdateButtonUnit(slot, nil)
    ns:UpdateFrameUnit(slot, nil)
    ns:SaveData()
    ns:NotifyBuffTracker(slot)
    ns:Print("Cleared slot " .. slot .. " (" .. prev.name .. ").")
end

---------------------------------------------------------------------------
-- Auto-assign DPS in party groups
---------------------------------------------------------------------------
function ns:AutoAssignDungeon()
    if not IsInGroup() then
        if not ns.autoAssigned then return end
        for i = 1, ns.NUM_SLOTS do
            if ns.targets[i] and ns.targets[i].auto then
                ns:ClearTarget(i)
            end
        end
        ns.autoAssigned = false
        return
    end

    -- Build set of manually-assigned names currently in group
    local manualNames = {}
    for i = 1, ns.NUM_SLOTS do
        if ns.targets[i] and not ns.targets[i].auto then
            if ns:ResolveNameToUnit(ns.targets[i].name) then
                manualNames[ns.targets[i].name:lower()] = i
            end
        end
    end

    -- Collect ALL group members (exclude player), sorted: DPS first, then HEALER, then TANK
    local candidates = { dps = {}, healer = {}, tank = {} }
    local seen = {}

    local function TryAddUnit(unit)
        if not UnitExists(unit) then return end
        if UnitIsUnit(unit, "player") then return end
        local uName, uRealm = UnitName(unit)
        if not uName then return end
        local fullName = (uRealm and uRealm ~= "") and (uName .. "-" .. uRealm) or uName
        if seen[fullName] then return end
        seen[fullName] = true
        local _, class = UnitClass(unit)
        local role = UnitGroupRolesAssigned(unit)
        if issecretvalue(role) then role = "NONE" end
        local entry = { name = fullName, class = class or "UNKNOWN" }
        if role == "HEALER" then
            table.insert(candidates.healer, entry)
        elseif role == "TANK" then
            table.insert(candidates.tank, entry)
        else
            table.insert(candidates.dps, entry)
        end
    end

    if IsInRaid() then
        for i = 1, GetNumGroupMembers() do TryAddUnit("raid" .. i) end
    else
        for i = 1, 4 do TryAddUnit("party" .. i) end
    end

    local allCandidates = {}
    for _, e in ipairs(candidates.dps) do
        e.isDPS = true; e.isHealer = false; e.isTank = false
        table.insert(allCandidates, e)
    end
    for _, e in ipairs(candidates.healer) do
        e.isDPS = false; e.isHealer = true; e.isTank = false
        table.insert(allCandidates, e)
    end
    for _, e in ipairs(candidates.tank) do
        e.isDPS = false; e.isHealer = false; e.isTank = true
        table.insert(allCandidates, e)
    end

    ns.tankTargets    = {}
    ns.tankUnitTokens = {}
    for i, e in ipairs(candidates.tank) do
        ns.tankTargets[i]    = { name = e.name, class = e.class }
        ns.tankUnitTokens[i] = ns:ResolveNameToUnit(e.name)
    end
    if ns.RefreshTankFrames then
        C_Timer.After(0.1, function() ns:RefreshTankFrames() end)
    end

    if #allCandidates < 1 then return end

    local changed = false
    local autoIdx = 1
    for i = 1, ns.NUM_SLOTS do
        local current = ns.targets[i]

        -- Skip slots that are manually assigned and still in group
        if current and not current.auto and manualNames[current.name:lower()] then
            goto continue_slot
        end

        -- Advance past candidates already in manual slots
        while autoIdx <= #allCandidates and manualNames[allCandidates[autoIdx].name:lower()] do
            autoIdx = autoIdx + 1
        end

        if autoIdx <= #allCandidates then
            if not current or current.name ~= allCandidates[autoIdx].name then
                local c = allCandidates[autoIdx]
                ns.targets[i] = {
                    name     = c.name,
                    class    = c.class,
                    auto     = true,
                    isHealer = c.isHealer,
                    isTank   = c.isTank,
                    isDPS    = c.isDPS,
                }
                changed = true
            end
            autoIdx = autoIdx + 1
        else
            if current and current.auto then
                ns.targets[i] = nil
                changed = true
            end
        end

        ::continue_slot::
    end

    ns.autoAssigned = true
    if changed then
        ns:SaveData()
        local assigned = math.min(#allCandidates, ns.NUM_SLOTS)
        ns:Print(string.format("Auto-assignation: %d cibles (%dDPS / %dHeal / %dTank).",
            assigned, #candidates.dps, #candidates.healer, #candidates.tank))
    end

    C_Timer.After(0, function()
        ns:ResolveAllTargets()
    end)
end

function ns:NotifyBuffTracker(slot)
    if ns.BuffTracker and ns.BuffTracker.OnTargetChanged then
        ns.BuffTracker:OnTargetChanged(slot)
    end
end

---------------------------------------------------------------------------
-- SavedVariables
---------------------------------------------------------------------------
local DEFAULTS = {
    targets           = {},
    containerPosition = nil,
    framePositions    = {},
    settings = {
        locked      = false,
        showFrames  = true,
        hiddenSlots = {},
        showCDTracker = true,
        frameScale  = 1.0,
    },
}

function ns:LoadSavedVariables()
    if not PreSwolenceDB then
        PreSwolenceDB = CopyTable(DEFAULTS)
    end

    for k, v in pairs(DEFAULTS) do
        if PreSwolenceDB[k] == nil then
            PreSwolenceDB[k] = CopyTable(v)
        end
    end
    for k, v in pairs(DEFAULTS.settings) do
        if PreSwolenceDB.settings[k] == nil then
            PreSwolenceDB.settings[k] = v
        end
    end

    ns.targets  = PreSwolenceDB.targets
    ns.settings = PreSwolenceDB.settings

    -- Remove duplicate targets (same name in multiple slots)
    local seen = {}
    for slot = 1, ns.NUM_SLOTS do
        local t = ns.targets[slot]
        if t then
            local key = t.name:lower()
            if seen[key] then
                ns.targets[slot] = nil
            else
                seen[key] = true
            end
        end
    end
end

function ns:SaveData()
    if PreSwolenceDB then
        PreSwolenceDB.targets  = ns.targets
        PreSwolenceDB.settings = ns.settings
    end
end

---------------------------------------------------------------------------
-- Create SecureActionButtons
---------------------------------------------------------------------------
function ns:CreateButtons()
    for i = 1, ns.NUM_SLOTS do
        local btn = CreateFrame("Button", "PreSwolenceButton" .. i, UIParent, "SecureActionButtonTemplate")
        btn:SetAttribute("type",  "spell")
        btn:SetAttribute("spell", "Prescience")
        btn:SetAttribute("unit",  "none")
        btn:RegisterForClicks("AnyUp", "AnyDown")
        btn:Hide()
        ns.buttons[i] = btn
    end
end

---------------------------------------------------------------------------
-- Spec gate: Augmentation Evoker only (class 13, spec index 3)
---------------------------------------------------------------------------
local EVOKER_CLASS_ID         = 13
local AUGMENTATION_SPEC_INDEX = 3

local function IsAugmentationEvoker()
    return select(3, UnitClass("player")) == EVOKER_CLASS_ID
        and GetSpecialization() == AUGMENTATION_SPEC_INDEX
end

---------------------------------------------------------------------------
-- Event frame
---------------------------------------------------------------------------
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")

local function EnableAddon()
    eventFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
    eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")

    ns:CreateButtons()
    ns:InitializeFrames()
    ns.BuffTracker:Enable()
    ns:Print("Loaded. Type /swole help for commands.")

    C_Timer.After(1, function()
        ns:AutoAssignDungeon()
        ns:ResolveAllTargets()
    end)

    ns.enabled = true
end

local function DisableAddon()
    eventFrame:UnregisterEvent("GROUP_ROSTER_UPDATE")
    eventFrame:UnregisterEvent("PLAYER_ENTERING_WORLD")
    eventFrame:UnregisterEvent("PLAYER_REGEN_ENABLED")

    ns.BuffTracker:Disable()

    if ns.DestroyFrames then ns:DestroyFrames() end
    for i = 1, ns.NUM_SLOTS do
        if ns.buttons[i] then ns.buttons[i]:Hide() end
    end

    if ns.enabled then
        ns:Print("Disabled (not Augmentation spec).")
    end

    ns.enabled = false
end

eventFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "ADDON_LOADED" then
        local loaded = ...
        if loaded ~= addonName then return end
        self:UnregisterEvent("ADDON_LOADED")

        if select(3, UnitClass("player")) ~= EVOKER_CLASS_ID then return end

        ns:LoadSavedVariables()
        self:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")

        if IsAugmentationEvoker() then
            EnableAddon()
        else
            self:RegisterEvent("PLAYER_LOGIN")
        end

    elseif event == "PLAYER_LOGIN" then
        self:UnregisterEvent("PLAYER_LOGIN")
        if not IsAugmentationEvoker() then return end
        EnableAddon()

    elseif event == "PLAYER_SPECIALIZATION_CHANGED" then
        if IsAugmentationEvoker() then
            if not ns.enabled then EnableAddon() end
            return
        end
        if ns.enabled then DisableAddon() end

    elseif event == "GROUP_ROSTER_UPDATE" or event == "PLAYER_ENTERING_WORLD" then
        if InCombatLockdown() then
            ns.resolveOnCombatEnd = true
            return
        end
        ns:AutoAssignDungeon()
        ns:ResolveAllTargets()

    elseif event == "PLAYER_REGEN_ENABLED" then
        ns:FlushPendingChanges()
        if not ns.resolveOnCombatEnd then return end
        ns.resolveOnCombatEnd = false
        ns:AutoAssignDungeon()
        ns:ResolveAllTargets()
    end
end)

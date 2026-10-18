local addonName, ns = ...

local BuffTracker = {}
ns.BuffTracker = BuffTracker

-- Prescience IDs
local CAST_ID           = ns.PRESCIENCE_CAST_ID
local BUFF_ID           = ns.PRESCIENCE_BUFF_ID
local FALLBACK_DURATION = ns.PRESCIENCE_DURATION

-- Ebon Might IDs
local EM_CAST_ID           = ns.EBON_MIGHT_CAST_ID
local EM_BUFF_ID           = ns.EBON_MIGHT_BUFF_ID
local EM_FALLBACK_DURATION = ns.EBON_MIGHT_DURATION

BuffTracker.debug = false

-- Per-tank state (Searing Scales)
BuffTracker.ssExpirationTimes = {}
BuffTracker.ssDurations       = {}
BuffTracker.ssActive          = {}

-- Per-slot state (Prescience)
BuffTracker.expirationTimes = {}
BuffTracker.durations       = {}
BuffTracker.castTimes       = {}
BuffTracker.active          = {}

-- Per-slot state (Ebon Might)
BuffTracker.emExpirationTimes = {}
BuffTracker.emDurations       = {}
BuffTracker.emActive          = {}

local function dbg(msg)
    if BuffTracker.debug then
        ns:Print("|cffAAAAFF[debug]|r " .. msg)
    end
end

---------------------------------------------------------------------------
-- Events and timer
---------------------------------------------------------------------------
local eventFrame
local timerFrame
local timerElapsed = 0

---------------------------------------------------------------------------
-- Public API
---------------------------------------------------------------------------
function BuffTracker:GetRemainingTime(slot)
    if not self.active[slot] then return nil end

    local expTime = self.expirationTimes[slot]
    if expTime then
        local remaining = expTime - GetTime()
        return remaining > 0 and remaining or nil
    end

    local castTime = self.castTimes[slot]
    if castTime then
        local remaining = FALLBACK_DURATION - (GetTime() - castTime)
        return remaining > 0 and remaining or nil
    end

    return nil
end

---------------------------------------------------------------------------
-- Target changed (called by Core)
---------------------------------------------------------------------------
function BuffTracker:OnTargetChanged(slot)
    self.expirationTimes[slot]   = nil
    self.durations[slot]         = nil
    self.castTimes[slot]         = nil
    self.active[slot]            = false
    self.emExpirationTimes[slot] = nil
    self.emDurations[slot]       = nil
    self.emActive[slot]          = false

    local unit = ns.unitTokens[slot]
    if unit and UnitExists(unit) then
        -- ScanUnit effectue les deux scans (Prescience + Ebon Might)
        -- et appelle UpdateFrameStatus + UpdateEbonMightFrameStatus
        self:ScanUnit(slot, unit)
        return
    end

    -- Aucune unité : mettre à jour les frames avec l'état réinitialisé
    self:UpdateFrameStatus(slot)
    self:UpdateEbonMightFrameStatus(slot)
end

---------------------------------------------------------------------------
-- Aura scanning via C_UnitAuras (12.0 compatible)
-- Single pass: detects Prescience and Ebon Might simultaneously.
---------------------------------------------------------------------------
function BuffTracker:ScanUnit(slot, unit)
    local foundPrescience = false
    local foundEbonMight  = false
    local anyReadable     = false

    local i = 1
    while true do
        -- Stop early once both buffs have been found
        if foundPrescience and foundEbonMight then break end

        local aura = C_UnitAuras.GetAuraDataByIndex(unit, i, "HELPFUL")
        if not aura then break end

        local spellId = aura.spellId
        if not issecretvalue(spellId) and spellId then
            anyReadable = true

            if not foundPrescience and (spellId == BUFF_ID or spellId == CAST_ID) then
                foundPrescience = true
                local exp = aura.expirationTime
                if not issecretvalue(exp) and exp and exp > 0 then
                    self.expirationTimes[slot] = exp
                    local dur = aura.duration
                    if not issecretvalue(dur) and dur and dur > 0 then
                        self.durations[slot] = dur
                    end
                end

            elseif not foundEbonMight and (spellId == EM_BUFF_ID or spellId == EM_CAST_ID) then
                foundEbonMight = true
                local exp = aura.expirationTime
                if not issecretvalue(exp) and exp and exp > 0 then
                    self.emExpirationTimes[slot] = exp
                    local dur = aura.duration
                    if not issecretvalue(dur) and dur and dur > 0 then
                        self.emDurations[slot] = dur
                    end
                end
            end
        end

        i = i + 1
    end

    -- Prescience result
    if foundPrescience then
        self.active[slot]    = true
        self.pendingCastTime = nil
        dbg("Scan: Prescience found on slot " .. slot)
    elseif anyReadable and not self.castTimes[slot] then
        self.active[slot]          = false
        self.expirationTimes[slot] = nil
        self.durations[slot]       = nil
    end

    -- Ebon Might result
    if foundEbonMight then
        self.emActive[slot] = true
        dbg("Scan: Ebon Might found on slot " .. slot)
    else
        -- Ne pas écraser si un timer cast est encore actif
        local exp = self.emExpirationTimes[slot]
        if not exp or exp <= GetTime() then
            self.emActive[slot]          = false
            self.emExpirationTimes[slot] = nil
            self.emDurations[slot]       = nil
        end
    end

    self:UpdateFrameStatus(slot)
    self:UpdateEbonMightFrameStatus(slot)
end

function BuffTracker:GetEbonMightRemaining(slot)
    if not self.emActive[slot] then return nil end
    local expTime = self.emExpirationTimes[slot]
    if expTime then
        local remaining = expTime - GetTime()
        return remaining > 0 and remaining or nil
    end
    return nil
end

---------------------------------------------------------------------------
-- Searing Scales scanning
---------------------------------------------------------------------------
function BuffTracker:ScanTankUnit(tankSlot, unit)
    if not unit or not UnitExists(unit) then
        self.ssActive[tankSlot]          = false
        self.ssExpirationTimes[tankSlot] = nil
        self.ssDurations[tankSlot]       = nil
        self:UpdateTankFrameStatus(tankSlot)
        return
    end

    local found = false
    local i     = 1
    while true do
        local aura = C_UnitAuras.GetAuraDataByIndex(unit, i, "HELPFUL")
        if not aura then break end
        local sid = aura.spellId
        if not issecretvalue(sid) and sid then
            if sid == ns.SEARING_SCALES_BUFF_ID or sid == ns.SEARING_SCALES_CAST_ID then
                found = true
                local exp = aura.expirationTime
                if not issecretvalue(exp) and exp and exp > 0 then
                    self.ssExpirationTimes[tankSlot] = exp
                    local dur = aura.duration
                    if not issecretvalue(dur) and dur and dur > 0 then
                        self.ssDurations[tankSlot] = dur
                    end
                end
                -- Capture stack count
                local stacks = aura.applications
                if not issecretvalue(stacks) and stacks then
                    self.ssStacks             = self.ssStacks or {}
                    self.ssStacks[tankSlot]   = stacks
                end
                break
            end
        end
        i = i + 1
    end

    if found then
        self.ssActive[tankSlot] = true
    else
        self.ssActive[tankSlot]          = false
        self.ssExpirationTimes[tankSlot] = nil
        self.ssDurations[tankSlot]       = nil
        self.ssStacks                    = self.ssStacks or {}
        self.ssStacks[tankSlot]          = 0
    end

    self:UpdateTankFrameStatus(tankSlot)
end

function BuffTracker:GetSSRemaining(tankSlot)
    if not self.ssActive[tankSlot] then return nil end
    local exp = self.ssExpirationTimes[tankSlot]
    if exp then
        local r = exp - GetTime()
        return r > 0 and r or nil
    end
    return nil
end

function BuffTracker:UpdateTankFrameStatus(tankSlot)
    local frames = ns.tankFrames
    if not frames or not frames[tankSlot] then return end
    local frame = frames[tankSlot]
    local S     = function(k, d) local v = ns.settings[k]; if v == nil then return d end return v end
    local bA    = S("ssShowBorder", true) and 1 or 0

    if self.ssActive[tankSlot] then
        frame:SetBackdropBorderColor(S("ssActiveBorderR",0.9), S("ssActiveBorderG",0.55), S("ssActiveBorderB",0.1), bA)
        frame.buffDuration = self.ssDurations[tankSlot]
        -- Pass stacks to frame
        local stacks = self.ssStacks and self.ssStacks[tankSlot] or 0
        if frame.stackText then
            frame.stackText:SetText(stacks > 1 and tostring(stacks) or "")
        end
        local remaining = self:GetSSRemaining(tankSlot)
        if remaining and frame.UpdateTimer then frame:UpdateTimer(remaining) end
        self:StartTimer()
    else
        frame:SetBackdropBorderColor(S("ssInactiveBorderR",0.55), S("ssInactiveBorderG",0.22), S("ssInactiveBorderB",0.05), bA)
        if frame.durationBar then frame.durationBar:SetValue(0) end
        if frame.timerText   then frame.timerText:SetText("") end
        if frame.stackText   then frame.stackText:SetText("") end
        frame.buffDuration = nil
    end
end

---------------------------------------------------------------------------
-- Slot lookup by unit token
---------------------------------------------------------------------------
function BuffTracker:SlotForUnit(unit)
    for slot = 1, ns.NUM_SLOTS do
        if ns.unitTokens[slot] == unit then
            return slot
        end
    end

    -- Fallback: GUID comparison for party/raid/player units only
    local prefix = unit and unit:match("^(%a+)")
    if prefix ~= "party" and prefix ~= "raid" and prefix ~= "player" then return nil end

    local guid = UnitGUID(unit)
    if not guid then return nil end

    for slot = 1, ns.NUM_SLOTS do
        local slotUnit = ns.unitTokens[slot]
        if slotUnit and UnitGUID(slotUnit) == guid then
            return slot
        end
    end
    return nil
end

---------------------------------------------------------------------------
-- UNIT_AURA handler (primary tracking method for 12.0)
---------------------------------------------------------------------------
function BuffTracker:OnUnitAura(unit)
    local slot = self:SlotForUnit(unit)
    if slot then
        self:ScanUnit(slot, ns.unitTokens[slot])
        if self.pendingCastTime and not self.active[slot] then
            self:CheckPendingCast(slot)
        end
    end

    -- Also check tank slots for Searing Scales
    for i = 1, ns.TANK_SLOTS do
        local tankUnit = ns.tankUnitTokens and ns.tankUnitTokens[i]
        if tankUnit and UnitExists(tankUnit) then
            -- Guard against secret value taint from UnitIsUnit during encounters
            local ok, same = pcall(UnitIsUnit, unit, tankUnit)
            if ok and not issecretvalue(same) and same then
                self:ScanTankUnit(i, tankUnit)
            elseif not ok then
                -- Fallback: compare unit names
                local n1 = UnitName(unit)
                local n2 = UnitName(tankUnit)
                if n1 and n2 and n1 == n2 then
                    self:ScanTankUnit(i, tankUnit)
                end
            end
        end
    end
end

---------------------------------------------------------------------------
-- Spellcast handler (cast-time fallback for secret expirationTime)
---------------------------------------------------------------------------
function BuffTracker:OnSpellcastSucceeded(unit, castGUID, spellID)
    if unit ~= "player" then return end
    if issecretvalue(spellID) then return end

    -- Prescience cast
    if spellID == CAST_ID then
        self.pendingCastTime = GetTime()
    end

    -- Ebon Might cast — active sur tous les slots trackés
    if spellID == EM_CAST_ID then
        local now = GetTime()
        for slot = 1, ns.NUM_SLOTS do
            if ns.unitTokens[slot] then
                self.emActive[slot]          = true
                self.emExpirationTimes[slot] = now + EM_FALLBACK_DURATION
                self.emDurations[slot]       = EM_FALLBACK_DURATION
                self:UpdateEbonMightFrameStatus(slot)
            end
        end
        self:StartTimer()
        dbg("Ebon Might cast — activé sur tous les slots")
    end

    -- Éruption (395160) — prolonge Ebon Might de 1s sur tous les slots actifs
    if spellID == 395160 then
        for slot = 1, ns.NUM_SLOTS do
            if self.emActive[slot] and self.emExpirationTimes[slot] then
                self.emExpirationTimes[slot] = self.emExpirationTimes[slot] + 1.0
                self:UpdateEbonMightFrameStatus(slot)
                dbg("Éruption — +1s sur slot " .. slot)
            end
        end
    end
end

-- Called from OnUnitAura after ScanUnit — if we just cast Prescience and
-- the scan can't confirm (secret spellIds), the first UNIT_AURA on a
-- tracked unit within a short window is likely the recipient.
function BuffTracker:CheckPendingCast(slot)
    if not self.pendingCastTime then return end
    if GetTime() - self.pendingCastTime > 1.0 then
        self.pendingCastTime = nil
        return
    end

    if not self.active[slot] then
        self.castTimes[slot]  = self.pendingCastTime
        self.active[slot]     = true
        self.pendingCastTime  = nil
        dbg("Pending cast matched to slot " .. slot)
        self:UpdateFrameStatus(slot)
    end
end

---------------------------------------------------------------------------
-- Timer management
---------------------------------------------------------------------------
function BuffTracker:StartTimer()
    if self.timerRunning then return end
    self.timerRunning = true
    timerFrame:SetScript("OnUpdate", function(self, dt)
        timerElapsed = timerElapsed + dt
        if timerElapsed < 0.1 then return end
        timerElapsed = 0
        BuffTracker:UpdateTimers()
    end)
end

function BuffTracker:StopTimer()
    if not self.timerRunning then return end
    self.timerRunning = false
    timerFrame:SetScript("OnUpdate", nil)
end

function BuffTracker:UpdateTimers()
    local anyActive = false

    for slot = 1, ns.NUM_SLOTS do
        -- Prescience timer
        if self.active[slot] then
            local remaining = self:GetRemainingTime(slot)
            if not remaining then
                self.active[slot]          = false
                self.expirationTimes[slot] = nil
                self.durations[slot]       = nil
                self.castTimes[slot]       = nil
                self:UpdateFrameStatus(slot)
            else
                anyActive = true
                self:UpdateFrameTimer(slot, remaining)
            end
        end

        -- Ebon Might timer
        if self.emActive[slot] then
            local rem = self:GetEbonMightRemaining(slot)
            if not rem then
                self.emActive[slot]          = false
                self.emExpirationTimes[slot] = nil
                self.emDurations[slot]       = nil
                self:UpdateEbonMightFrameStatus(slot)
            else
                anyActive = true
                self:UpdateEbonMightFrameTimer(slot, rem)
            end
        end
    end

    -- Searing Scales timers
    for i = 1, (ns.TANK_SLOTS or 1) do
        if self.ssActive[i] then
            local rem = self:GetSSRemaining(i)
            if not rem then
                self.ssActive[i]          = false
                self.ssExpirationTimes[i] = nil
                self.ssDurations[i]       = nil
                self:UpdateTankFrameStatus(i)
            else
                anyActive = true
                local frames = ns.tankFrames
                if frames and frames[i] and frames[i].UpdateTimer then
                    frames[i]:UpdateTimer(rem)
                end
            end
        end
    end

    if not anyActive then
        self:StopTimer()
    end
end

---------------------------------------------------------------------------
-- Frame updates
---------------------------------------------------------------------------
function BuffTracker:UpdateFrameStatus(slot)
    local frame = ns.frames[slot]
    if not frame then return end

    local S  = function(k, d) local v = ns.settings[k]; if v == nil then return d end return v end
    local bA = S("presShowBorder", true) and 1 or 0

    if self.active[slot] then
        frame.barFrame:SetBackdropBorderColor(S("presActiveBorderR",0.2), S("presActiveBorderG",0.8), S("presActiveBorderB",0.2), bA)
        frame.buffDuration = self.durations[slot]
        local remaining = self:GetRemainingTime(slot)
        if remaining then
            frame:UpdateTimer(remaining)
        end
        self:StartTimer()
    else
        frame.barFrame:SetBackdropBorderColor(S("presInactiveBorderR",0.6), S("presInactiveBorderG",0.2), S("presInactiveBorderB",0.2), bA)
        frame.spark:Hide()
        frame.timerBar:SetValue(0)
        frame.timerText:SetText("")
        frame.buffDuration = nil
    end
end

function BuffTracker:UpdateFrameTimer(slot, remaining)
    local frame = ns.frames[slot]
    if not frame or not frame.UpdateTimer then return end
    frame:UpdateTimer(remaining)
end

---------------------------------------------------------------------------
-- Ebon Might frame updates
---------------------------------------------------------------------------
function BuffTracker:UpdateEbonMightFrameStatus(slot)
    local emFrames = ns.emFrames
    if not emFrames then return end
    local frame = emFrames[slot]
    if not frame then return end

    local S  = function(k, d) local v = ns.settings[k]; if v == nil then return d end return v end
    local bA = S("emShowBorder", true) and 1 or 0

    if self.emActive[slot] then
        frame:SetBackdropBorderColor(S("emActiveBorderR",0.62), S("emActiveBorderG",0.22), S("emActiveBorderB",0.92), bA)
        frame.buffDuration = self.emDurations[slot]
        local remaining = self:GetEbonMightRemaining(slot)
        if remaining then frame:UpdateTimer(remaining) end
        self:StartTimer()
    else
        frame:SetBackdropBorderColor(S("emInactiveBorderR",0.28), S("emInactiveBorderG",0.10), S("emInactiveBorderB",0.42), bA)
        if frame.spark     then frame.spark:Hide() end
        if frame.timerBar  then frame.timerBar:SetValue(0) end
        if frame.timerText then frame.timerText:SetText("") end
        frame.buffDuration = nil
    end
end

function BuffTracker:UpdateEbonMightFrameTimer(slot, remaining)
    local emFrames = ns.emFrames
    if not emFrames then return end
    local frame = emFrames[slot]
    if not frame or not frame.UpdateTimer then return end
    frame:UpdateTimer(remaining)
end

---------------------------------------------------------------------------
-- Wire up events (called by Core.lua)
---------------------------------------------------------------------------
function BuffTracker:Enable()
    if not eventFrame then
        eventFrame = CreateFrame("Frame")
        eventFrame:SetScript("OnEvent", function(self, event, ...)
            if event == "UNIT_AURA" then
                BuffTracker:OnUnitAura(...)
            elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
                BuffTracker:OnSpellcastSucceeded(...)
            end
        end)
    end
    eventFrame:RegisterEvent("UNIT_AURA")
    eventFrame:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
    if not timerFrame then
        timerFrame = CreateFrame("Frame")
    end
    self.timerRunning = false
end

function BuffTracker:Disable()
    if eventFrame then
        eventFrame:UnregisterAllEvents()
    end
    if timerFrame then
        timerFrame:SetScript("OnUpdate", nil)
    end
end

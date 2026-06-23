--[[
    RotationManager.lua — Hasu's Interrupt Tracker
    Kick rotation manager: determines who should kick next.

    Integrates as a module via the HasuRotation global.
    Does NOT read locals from LoxxInterruptTracker.lua directly.
    All data is passed as arguments by the main file.
]]

HasuRotation = HasuRotation or {}

local rotationOrder = {}   -- ordered list: { name, name, ... }

-- Rebuild rotation order from current roster.
-- Preserves existing positions for known players; new players appended alphabetically.
function HasuRotation.UpdateRoster(partyAddonUsers, myName)
    if not myName then return end

    -- Map name → current position
    local existing = {}
    for i, n in ipairs(rotationOrder) do existing[n] = i end

    -- Collect all current group members
    local inGroup = { [myName] = true }
    for name in pairs(partyAddonUsers or {}) do inGroup[name] = true end

    -- Separate: known (preserve order) vs new (add alphabetically)
    local known, newPlayers = {}, {}
    for name in pairs(inGroup) do
        if existing[name] then
            table.insert(known, { name = name, pos = existing[name] })
        else
            table.insert(newPlayers, name)
        end
    end
    table.sort(known, function(a, b) return a.pos < b.pos end)
    table.sort(newPlayers)

    local result = {}
    for _, e in ipairs(known)      do table.insert(result, e.name) end
    for _, n in ipairs(newPlayers) do table.insert(result, n)      end

    rotationOrder = result
end

-- Handle incoming ROTATION message from a peer.
-- parts = { "ROTATION", "1=Name", "2=Name", ... }
function HasuRotation.HandleMessage(parts, sender)
    local parsed = {}
    for i = 2, #parts do
        local idx, name = parts[i]:match("^(%d+)=(.+)$")
        if idx and name then
            parsed[tonumber(idx)] = name
        end
    end
    local clean = {}
    for i = 1, #parsed do
        if parsed[i] then table.insert(clean, parsed[i]) end
    end
    if #clean > 0 then
        rotationOrder = clean
    end
end

-- Returns the next kicker's name:
--   1. First player in rotation order who is READY
--   2. If nobody ready: player with shortest remaining CD (in rotation order)
function HasuRotation.GetNextKicker(partyAddonUsers, myName, myKickCdEnd, myExtraKicks, now)
    if #rotationOrder == 0 then return nil end
    now = now or GetTime()

    local function isReady(name)
        if name == myName then
            if (myKickCdEnd or 0) <= now then return true end
            for _, ek in pairs(myExtraKicks or {}) do
                if ek.cdEnd and ek.cdEnd <= now then return true end
            end
            return false
        else
            local info = partyAddonUsers and partyAddonUsers[name]
            return info ~= nil and ((info.cdEnd or 0) <= now)
        end
    end

    local function getRemaining(name)
        if name == myName then
            local rem = (myKickCdEnd or 0) - now
            for _, ek in pairs(myExtraKicks or {}) do
                if ek.cdEnd then rem = math.min(rem, ek.cdEnd - now) end
            end
            return math.max(0, rem)
        else
            local info = partyAddonUsers and partyAddonUsers[name]
            if not info then return math.huge end
            return math.max(0, (info.cdEnd or 0) - now)
        end
    end

    -- Pass 1: first READY in rotation
    for _, name in ipairs(rotationOrder) do
        if isReady(name) then return name end
    end

    -- Pass 2: nobody ready — shortest CD in rotation
    local bestRem, bestName = math.huge, nil
    for _, name in ipairs(rotationOrder) do
        local rem = getRemaining(name)
        if rem < bestRem then bestRem = rem; bestName = name end
    end
    return bestName
end

-- Called each UpdateDisplay tick.
-- Prefixes "▶ " to the name text of the next kicker; removes it from others.
-- Uses inline color so no separate badge frame is needed (avoids overlap with name text).
function HasuRotation.MarkNextKicker(bars, barCount, partyAddonUsers, myName, myKickCdEnd, myExtraKicks, now, showNext)
    local nextKicker = nil
    if showNext then
        nextKicker = HasuRotation.GetNextKicker(partyAddonUsers, myName, myKickCdEnd, myExtraKicks, now)
    end
    for i = 1, barCount do
        local bar = bars[i]
        if bar and bar.nameText and bar.ttPlayerName then
            if nextKicker and bar.ttPlayerName == nextKicker then
                bar.nameText:SetText("|cFF26FF73>|r " .. bar.ttPlayerName)
            else
                bar.nameText:SetText(bar.ttPlayerName)
            end
        end
    end
end


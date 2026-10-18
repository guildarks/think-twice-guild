local addonName, ns = ...

---------------------------------------------------------------------------
-- Slash command handler
---------------------------------------------------------------------------
local function HandleSlashCommand(msg)
    local args = {}
    for word in msg:gmatch("%S+") do
        table.insert(args, word)
    end

    local cmd = args[1] and args[1]:lower() or "help"

    if cmd == "set" then
        local slot = tonumber(args[2])
        if not slot then
            ns:Print("Usage: /swole set <slot> [name]")
            return
        end
        local name = args[3]
        if name then
            ns:AssignTarget(slot, name)
        else
            if not UnitExists("target") then
                ns:Print("You have no target.")
                return
            end
            if not UnitIsPlayer("target") then
                ns:Print("Target must be a player.")
                return
            end
            local uName, realm = UnitName("target")
            local fullName = realm and realm ~= "" and (uName .. "-" .. realm) or uName
            ns:AssignTarget(slot, fullName)
        end

    elseif cmd == "clear" then
        local slot = tonumber(args[2])
        if not slot then
            ns:Print("Usage: /swole clear <slot>")
            return
        end
        ns:ClearTarget(slot)

    elseif cmd == "list" then
        ns:Print("Assigned targets:")
        for i = 1, ns.NUM_SLOTS do
            local t = ns.targets[i]
            if t then
                local unit   = ns.unitTokens[i]
                local status = unit and ("|cff00ff00" .. unit .. "|r") or "|cffff0000not in group|r"
                ns:Print("  " .. i .. ": " .. t.name .. " (" .. t.class .. ") — " .. status)
            else
                ns:Print("  " .. i .. ": |cff888888empty|r")
            end
        end

    elseif cmd == "lock" then
        ns.settings.locked = not ns.settings.locked
        ns:SaveData()
        ns:Print("Frames " .. (ns.settings.locked and "locked." or "unlocked."))

    elseif cmd == "toggle" then
        ns.settings.showFrames = not ns.settings.showFrames
        ns:SaveData()
        ns:Print("Frames " .. (ns.settings.showFrames and "shown." or "hidden."))
        if ns.UpdateFrameVisibility then
            ns:UpdateFrameVisibility()
        end

    elseif cmd == "icon" then
        ns.settings.showCDTracker = not ns.settings.showCDTracker
        ns:SaveData()
        ns:Print("CD tracker " .. (ns.settings.showCDTracker and "shown." or "hidden."))
        if ns.UpdateFrameVisibility then
            ns:UpdateFrameVisibility()
        end

    elseif cmd == "scale" then
        local scale = tonumber(args[2])
        if not scale or scale < 0.5 or scale > 3 then
            ns:Print("Usage: /swole scale <0.5-3.0>")
            return
        end
        ns.settings.frameScale = scale
        ns:SaveData()
        ns:Print("Frame scale set to " .. scale .. ".")
        if ns.UpdateFrameScale then
            ns:UpdateFrameScale()
        end

    elseif cmd == "auto" then
        -- Clear ALL slots and force full reassign
        for i = 1, ns.NUM_SLOTS do
            ns.targets[i] = nil
        end
        ns.autoAssigned = false
        ns:AutoAssignDungeon()
        ns:Print("Auto-assignation forcée.")

    elseif cmd == "emdebug" then
        for i = 1, ns.NUM_SLOTS do
            local unit = ns.unitTokens[i]
            if unit and UnitExists(unit) then
                ns:Print("Slot " .. i .. " (" .. (UnitName(unit) or unit) .. ") auras:")
                local j = 1
                while true do
                    local aura = C_UnitAuras.GetAuraDataByIndex(unit, j, "HELPFUL")
                    if not aura then break end
                    local sid = aura.spellId
                    if sid and not issecretvalue(sid) then
                        ns:Print("  [" .. sid .. "] " .. (aura.name or "?") .. " dur=" .. tostring(aura.duration))
                    end
                    j = j + 1
                end
                ns:Print("  emActive[" .. i .. "]=" .. tostring(ns.BuffTracker.emActive[i]))
            end
        end
        ns:Print("EM_BUFF_ID=" .. tostring(ns.EBON_MIGHT_BUFF_ID) .. " EM_CAST_ID=" .. tostring(ns.EBON_MIGHT_CAST_ID))

    elseif cmd == "tankdebug" then
        -- Scan all auras on tank and print IDs
        local unit = ns.tankUnitTokens and ns.tankUnitTokens[1]
        if not unit or not UnitExists(unit) then
            ns:Print("Aucun tank détecté. Tapez /swole auto d'abord.")
        else
            ns:Print("Auras sur " .. (UnitName(unit) or unit) .. ":")
            local i = 1
            while true do
                local aura = C_UnitAuras.GetAuraDataByIndex(unit, i, "HELPFUL")
                if not aura then break end
                local sid  = aura.spellId
                local name = aura.name or "?"
                if sid and not issecretvalue(sid) then
                    local extra = " dur=" .. tostring(aura.duration) .. " exp=" .. tostring(aura.expirationTime)
                    ns:Print("  [" .. tostring(sid) .. "] " .. name .. extra)
                end
                i = i + 1
            end
            ns:Print("SS_BUFF_ID=" .. tostring(ns.SEARING_SCALES_BUFF_ID))
            ns:Print("ssActive[1]=" .. tostring(ns.BuffTracker.ssActive[1]))
            ns:Print("GetTime=" .. tostring(GetTime()))
            local exp = ns.BuffTracker.ssExpirationTimes[1]
            ns:Print("ssExp[1]=" .. tostring(exp) .. " remaining=" .. tostring(exp and (exp - GetTime()) or "nil"))
        end

    elseif cmd == "tankinfo" then
        ns:Print("tankTargets:")
        for i = 1, (ns.TANK_SLOTS or 1) do
            local t = ns.tankTargets    and ns.tankTargets[i]
            local u = ns.tankUnitTokens and ns.tankUnitTokens[i]
            ns:Print("  tank" .. i .. ": " .. (t and t.name or "nil") .. " unit=" .. tostring(u))
        end
        ns:Print("tankFrames: " .. tostring(ns.tankFrames and ns.tankFrames[1] and "exists" or "nil"))

    elseif cmd == "debug" then
        ns.BuffTracker.debug = not ns.BuffTracker.debug
        ns:Print("Debug mode " .. (ns.BuffTracker.debug and "ON" or "OFF"))

    elseif cmd == "scan" then
        for i = 1, ns.NUM_SLOTS do
            local unit = ns.unitTokens[i]
            if unit and UnitExists(unit) then
                local idx = 1
                while true do
                    local aura = C_UnitAuras.GetAuraDataByIndex(unit, idx, "HELPFUL")
                    if not aura then break end
                    ns:Print("  Slot " .. i .. ": " .. tostring(aura.name) ..
                        " (id=" .. tostring(aura.spellId) .. " src=" .. tostring(aura.sourceUnit) .. ")")
                    idx = idx + 1
                end
                if idx == 1 then
                    ns:Print("  Slot " .. i .. ": no auras on " .. unit)
                end
            else
                ns:Print("  Slot " .. i .. ": no unit")
            end
        end

    elseif cmd == "reset" then
        if PreSwolenceDB then PreSwolenceDB.framePositions = {} end
        ns:Print("Positions réinitialisées — rechargez (/reload) pour appliquer.")

    elseif cmd == "help" then
        ns:Print("Commands:")
        ns:Print("  /swole set <1-4> [name] — assign target (uses current target if no name)")
        ns:Print("  /swole clear <1-4> — clear a slot")
        ns:Print("  /swole list — show assigned targets")
        ns:Print("  /swole lock — toggle frame lock")
        ns:Print("  /swole toggle — show/hide frames")
        ns:Print("  /swole icon — show/hide CD tracker icon")
        ns:Print("  /swole scale <0.5-3.0> — frame scale")
        ns:Print("  /swole auto — force re-auto-assign (DPS > Heal > Tank)")
        ns:Print("  /swole reset — réinitialiser les positions des barres")

    else
        ns:Print("Unknown command. Type /swole help for usage.")
    end
end

SLASH_PRESWOLENCE1              = "/swole"
SLASH_PRESWOLENCE2              = "/preswolence"
SlashCmdList["PRESWOLENCE"]     = HandleSlashCommand

---------------------------------------------------------------------------
-- Unit frame right-click context menu
---------------------------------------------------------------------------
local UNIT_MENU_TAGS = {
    "MENU_UNIT_SELF",
    "MENU_UNIT_PLAYER",
    "MENU_UNIT_PARTY",
    "MENU_UNIT_RAID",
    "MENU_UNIT_RAID_PLAYER",
    "MENU_UNIT_FRIEND",
}

for _, tag in ipairs(UNIT_MENU_TAGS) do
    Menu.ModifyMenu(tag, function(ownerRegion, rootDescription, contextData)
        if not ns.enabled then return end
        if not contextData then return end

        local name   = contextData.name
        local server = contextData.server
        local unit   = contextData.unit

        -- Raid frames may not populate name/server; fall back to UnitName
        if not name and unit and UnitExists(unit) then
            local uName, uRealm = UnitName(unit)
            name   = uName
            server = uRealm
        end

        if not name then return end

        local fullName = server and server ~= "" and (name .. "-" .. server) or name

        rootDescription:CreateDivider()
        local submenu = rootDescription:CreateButton("PreSwolence")

        for i = 1, ns.NUM_SLOTS do
            local current = ns.targets[i]
            local label   = "Set Target " .. i
            if current and current.name:lower() == fullName:lower() then
                label = label .. " |cff00ff00(current)|r"
            end
            submenu:CreateButton(label, function()
                ns:AssignTarget(i, fullName)
            end)
        end

        submenu:CreateDivider()
        submenu:CreateButton("Clear from slots", function()
            for i = 1, ns.NUM_SLOTS do
                if ns.targets[i] and ns.targets[i].name:lower() == fullName:lower() then
                    ns:ClearTarget(i)
                end
            end
        end)
    end)
end

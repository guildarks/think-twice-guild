-- JumpBip Addon - Makes a sound when you jump

local jumpBipFrame = CreateFrame("Frame")
jumpBipFrame:RegisterEvent("PLAYER_JUMPING")
jumpBipFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "PLAYER_JUMPING" then
        -- Play a simple beep sound
        PlaySoundFile("Sound\\Doodad\\BellTollMedium.ogg", "Master")
        print("|cff00ff00[JumpBip]|r You jumped! 🎯")
    end
end)

-- Fallback: If PLAYER_JUMPING doesn't work, use a timer to detect jumping
local lastWasInAir = false
local jumpDetectionFrame = CreateFrame("Frame")
jumpDetectionFrame:SetScript("OnUpdate", function(self)
    local unit = "player"
    local inAir = not (IsPlayerInWorld() and UnitIsOnGround(unit))

    if inAir and not lastWasInAir then
        -- Jump detected
        PlaySoundFile("Sound\\Doodad\\BellTollMedium.ogg", "Master")
        print("|cff00ff00[JumpBip]|r Jump detected! 🎯")
    end

    lastWasInAir = inAir
end)

print("|cff00ff00JumpBip|r addon loaded! You will hear a beep when you jump 🔊")

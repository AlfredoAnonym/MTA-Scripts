-- Event to play sound for all players
addEvent("playSoundForAll", true)
addEventHandler("playSoundForAll", root, function(soundFile)
    -- Play the sound for all players
    for _, player in ipairs(getElementsByType("player")) do
        triggerClientEvent(player, "playClientSound", player, soundFile)
    end
end)
-- Variables
local guiWindow = nil
local isGUIVisible = false

-- Function to create and toggle the GUI
function toggleGUI()
    if not guiWindow then
        outputDebugString("Creating Soundboard GUI", 3) -- Debug: GUI creation (keep this)
        -- Create the GUI window when first opened
        guiWindow = guiCreateWindow(0.35, 0.25, 0.3, 0.5, "Soundboard", true)
        guiWindowSetSizable(guiWindow, false)
        
        -- Create 15 buttons with "Sound X" names
        for i = 1, 15 do
            local button = guiCreateButton(0.1, 0.05 + (i - 1) * 0.06, 0.8, 0.05, "Sound " .. i, true, guiWindow)
            addEventHandler("onClientGUIClick", button, function()
                triggerServerEvent("playSoundForAll", localPlayer, "sounds/sound" .. i .. ".mp3")
            end, false)
        end
    end
    
    -- Toggle visibility
    isGUIVisible = not isGUIVisible
    guiSetVisible(guiWindow, isGUIVisible)
    showCursor(isGUIVisible)
end

-- Bind F3 to toggle the GUI
bindKey("f3", "down", toggleGUI)

-- Show chat prompt when resource starts
addEventHandler("onClientResourceStart", resourceRoot, function()
    outputChatBox("Press F3 to access the Soundboard!", 255, 255, 0) -- Yellow text
    outputDebugString("Soundboard resource started", 3) -- Debug: Resource start (keep this)
end)

-- Clean up when resource stops
addEventHandler("onClientResourceStop", resourceRoot, function()
    if guiWindow then
        destroyElement(guiWindow)
        outputDebugString("Soundboard GUI destroyed", 3) -- Debug: GUI cleanup (keep this)
    end
end)

-- Event to play the sound
addEvent("playClientSound", true)
addEventHandler("playClientSound", root, function(soundFile)
    local sound = playSound(soundFile)
    if sound then
        setSoundVolume(sound, 1.0) -- Adjust volume if needed
    else
        outputDebugString("Failed to play sound: " .. soundFile, 1) -- Debug: Sound failure (keep this for errors)
    end
end)
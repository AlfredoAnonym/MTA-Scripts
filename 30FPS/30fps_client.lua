-- Client-side: Force 30 FPS for a specific racing map
-- Register the event at the top to ensure it's available
addEvent("onClientReceiveForceFPSServerFPS", true)

local targetMapName = "[30FPS] Driveable Yosemite" -- The map to force 30 FPS on
local forcedFPS = 30 -- FPS cap
local originalFPS = nil -- Will be set by the server
local currentMap = nil -- Track the current map
local isFPSForced = false -- Track if FPS is currently capped for the target map
local checkTimer = nil -- Timer for checking the current map

-- Handle receiving the server's FPS limit
addEventHandler("onClientReceiveForceFPSServerFPS", resourceRoot, function(serverFPS)
    originalFPS = serverFPS
    -- If FPS is currently capped but shouldn't be, reset it
    if isFPSForced and currentMap then
        local raceResource = getResourceFromName("race")
        if raceResource and getResourceState(raceResource) == "running" then
            local mapRoot = getResourceRootElement(raceResource)
            if mapRoot then
                local mapName = getElementData(mapRoot, "mapname") or ""
                if mapName and normalizeMapName(mapName) ~= normalizeMapName(targetMapName) then
                    resetFPS("onClientReceiveForceFPSServerFPS")
                end
            end
        end
    end
end)

-- Function to normalize map names (remove case sensitivity, trim spaces, and remove non-printable characters)
function normalizeMapName(name)
    if not name then return "" end
    -- Remove non-printable characters (e.g., newlines, tabs)
    name = string.gsub(name, "%c", "")
    -- Remove extra spaces between words
    name = string.gsub(name, "%s+", " ")
    -- Remove any special characters that might cause issues (keep alphanumeric and basic punctuation)
    name = string.gsub(name, "[^%w%s%[%]]", "")
    -- Trim leading and trailing whitespace
    name = string.gsub(name, "^%s*(.-)%s*$", "%1")
    -- Convert to lowercase
    return string.lower(name)
end

-- Function to reset FPS
function resetFPS(caller)
    if isFPSForced then -- Only reset if FPS was forced
        if not originalFPS then
            originalFPS = 60 -- Fallback if server FPS not received
        end
        setFPSLimit(originalFPS)
        isFPSForced = false
        outputChatBox("#55FF55[Race] #FFFFFFRestored original FPS to " .. tostring(originalFPS) .. ".", 255, 255, 255, true)
    end
end

-- Function to apply FPS cap
function applyFPSCap(mapName)
    local normalizedMap = normalizeMapName(mapName)
    local normalizedTarget = normalizeMapName(targetMapName)

    -- Apply FPS cap if this is the target map
    if normalizedMap == normalizedTarget then
        if not isFPSForced then
            setFPSLimit(forcedFPS) -- Cap FPS to 30
            isFPSForced = true
            outputChatBox("#FF5555[Race] #FFFFFFThis map (" .. mapName .. ") is configured to run at 30 FPS.", 255, 255, 255, true)
        end
    else
        -- Reset FPS if this is a non-target map and FPS is currently forced
        if isFPSForced then
            resetFPS("applyFPSCap")
        end
    end

    currentMap = mapName -- Update the current map
end

-- Fallback: Periodically check the current map
local function checkCurrentMap()
    if not currentMap then
        return
    end

    local normalizedMap = normalizeMapName(currentMap)
    local normalizedTarget = normalizeMapName(targetMapName)

    if normalizedMap == normalizedTarget then
        return -- Do not reset FPS if on the target map
    end

    if isFPSForced then
        resetFPS("checkCurrentMap")
    else
        if isTimer(checkTimer) then
            killTimer(checkTimer)
            checkTimer = nil
            outputDebugString("Check timer stopped: FPS is not forced")
        end
    end
end

-- Apply FPS cap when the map starts
addEvent("onClientMapStarting", true)
addEventHandler("onClientMapStarting", root, function(mapInfo)
    local mapName = mapInfo.name -- Get the map name from the event
    applyFPSCap(mapName)
end)

-- Initialize current map when the resource starts
addEventHandler("onClientResourceStart", resourceRoot, function()
    -- Notify the server that the client is ready to receive the FPS
    triggerServerEvent("onClientReadyForFPS", resourceRoot)
    -- Retry if server FPS not received after 5, 10, 15, and 20 seconds
    setTimer(function()
        if not originalFPS then
            triggerServerEvent("onClientRequestServerFPS", resourceRoot)
        end
    end, 5000, 1)
    setTimer(function()
        if not originalFPS then
            triggerServerEvent("onClientRequestServerFPS", resourceRoot)
        end
    end, 10000, 1)
    setTimer(function()
        if not originalFPS then
            triggerServerEvent("onClientRequestServerFPS", resourceRoot)
        end
    end, 15000, 1)
    setTimer(function()
        if not originalFPS then
            originalFPS = 60
        end
    end, 20000, 1)
    -- Initialize current map
    local raceResource = getResourceFromName("race")
    if raceResource and getResourceState(raceResource) == "running" then
        local mapRoot = getResourceRootElement(raceResource)
        if mapRoot then
            currentMap = getElementData(mapRoot, "mapname") or ""
            -- Apply FPS cap if joining mid-race on the target map
            if currentMap and normalizeMapName(currentMap) == normalizeMapName(targetMapName) then
                setFPSLimit(forcedFPS)
                isFPSForced = true
            end
        end
    end
    -- Start the timer after a delay to ensure the map is fully loaded
    setTimer(function()
        if not checkTimer then
            checkTimer = setTimer(checkCurrentMap, 10000, 0)
            outputDebugString("Check timer started")
        end
    end, 5000, 1)
end)

-- Reset FPS when the map stops
addEvent("onClientMapStopping", true)
addEventHandler("onClientMapStopping", root, function()
    if isFPSForced then
        resetFPS("onClientMapStopping")
    end
end)

-- Reset FPS when the race state changes
addEvent("onClientRaceStateChanging", true)
addEventHandler("onClientRaceStateChanging", root, function(newState)
    -- Only reset FPS for specific states that occur after the map has started
    if isFPSForced and (newState == "timesup" or newState == "everyonefinished" or newState == "postfinish") then
        resetFPS("onClientRaceStateChanging")
    end
end)

-- Reset FPS if the player dies
addEventHandler("onClientPlayerWasted", localPlayer, function()
    if isFPSForced and currentMap then
        local normalizedMap = normalizeMapName(currentMap)
        local normalizedTarget = normalizeMapName(targetMapName)
        if normalizedMap ~= normalizedTarget then
            resetFPS("onClientPlayerWasted")
        end
    end
end)

-- Reset FPS when the resource stops (safety net)
addEventHandler("onClientResourceStop", resourceRoot, function()
    if isFPSForced then
        resetFPS("onClientResourceStop")
    end
end)

-- Add a command to manually reset FPS
addCommandHandler("resetfps", function()
    if isFPSForced then
        resetFPS("/resetfps")
        outputChatBox("#55FF55[Race] #FFFFFFManually restored original FPS to " .. tostring(originalFPS) .. ".", 255, 255, 255, true)
    else
        outputChatBox("#FF5555[Race] #FFFFFFFPS is not currently capped.", 255, 255, 255, true)
    end
end)
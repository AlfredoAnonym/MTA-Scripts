-- Server-side: Fetch the server's FPS limit and send it to clients
local readyClients = {} -- Track clients that are ready to receive FPS

addEventHandler("onResourceStart", resourceRoot, function()
    local serverFPS = getServerConfigSetting("fpslimit") or 60 -- Default to 60 if not set
    outputDebugString("Server FPS limit: " .. tostring(serverFPS))
    -- Don't trigger the event here; wait for clients to signal readiness
end)

-- Wait for the client to signal it's ready before sending the FPS
addEvent("onClientReadyForFPS", true)
addEventHandler("onClientReadyForFPS", resourceRoot, function()
    local serverFPS = getServerConfigSetting("fpslimit") or 60
    readyClients[client] = true -- Mark the client as ready
    outputDebugString("Client ready, sending server FPS: " .. tostring(serverFPS) .. " to " .. getPlayerName(client))
    triggerClientEvent(client, "onClientReceiveForceFPSServerFPS", resourceRoot, serverFPS)
end)

-- Handle client request for server FPS
addEvent("onClientRequestServerFPS", true)
addEventHandler("onClientRequestServerFPS", resourceRoot, function()
    local serverFPS = getServerConfigSetting("fpslimit") or 60
    if readyClients[client] then
        outputDebugString("Client requested server FPS: " .. tostring(serverFPS) .. " for " .. getPlayerName(client))
        triggerClientEvent(client, "onClientReceiveForceFPSServerFPS", resourceRoot, serverFPS)
    else
        outputDebugString("Client requested server FPS but not ready yet: " .. getPlayerName(client))
    end
end)

-- Clean up when a player quits
addEventHandler("onPlayerQuit", root, function()
    readyClients[source] = nil
end)
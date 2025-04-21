-- Whitelist file path
local whitelistFile = "whitelist.json"

-- Load whitelist from file or use default if file doesn’t exist
local function loadWhitelist()
    if fileExists(whitelistFile) then
        local file = fileOpen(whitelistFile)
        if file then
            local data = fileRead(file, fileGetSize(file))
            fileClose(file)
            local loaded = fromJSON(data)
            if loaded and type(loaded) == "table" then
                outputDebugString("Whitelist loaded from " .. whitelistFile .. ": " .. toJSON(loaded))
                return loaded
            end
        end
    end
    -- Default whitelist if no file exists
    return {
        ["080209AF2E09E389F6C55AFB6B5A5A54"] = true,
        ["ANOTHERSERIALHERE1234567890ABCDEF"] = true
    }
end

-- Save whitelist to file
local function saveWhitelist(whitelist)
    local file = fileCreate(whitelistFile)
    if file then
        fileWrite(file, toJSON(whitelist))
        fileClose(file)
        outputDebugString("Whitelist saved to " .. whitelistFile .. ": " .. toJSON(whitelist))
    else
        outputDebugString("Failed to save whitelist to " .. whitelistFile .. "!")
    end
end

-- Initial load
local whitelist = loadWhitelist()

-- Country code for Poland
local allowedCountry = "PL"

-- Check player on connect with GeoIP API
addEventHandler("onPlayerConnect", root, function(playerNick, playerIP, playerUsername, playerSerial, cancelFunc)
    outputDebugString("Player connecting: " .. playerNick .. " (Serial: " .. playerSerial .. ", IP: " .. playerIP .. ")")
    
    -- Check if serial is in whitelist first (faster rejection)
    if not whitelist[playerSerial] then
        outputDebugString("Connection denied for " .. playerNick .. ": Serial not in whitelist.")
        cancelEvent(true, "You are not on the whitelist!")
        return
    end
    
    -- Fetch country from ip-api.com
    fetchRemote("http://ip-api.com/json/" .. playerIP, function(response, errno, playerNick, playerSerial)
        if errno ~= 0 then
            outputDebugString("GeoIP fetch failed for " .. playerNick .. ": Error " .. errno)
            cancelEvent(true, "Unable to verify your country. Connection denied.")
            return
        end
        
        local data = fromJSON(response)
        local country = data and data.countryCode or "Unknown"
        outputDebugString("Country detected for " .. playerNick .. ": " .. country)
        
        -- Allow only Poland (PL), block all others
        if country ~= allowedCountry then
            outputDebugString("Connection denied for " .. playerNick .. ": Country (" .. country .. ") not allowed.")
            cancelEvent(true, "This server is restricted to Polish players only.")
        else
            outputDebugString("Connection allowed for " .. playerNick .. ": Country and serial check passed.")
        end
    end, "", true, playerNick, playerSerial)
end)

-- Function to add serial
function addSerialToWhitelist(serial, player)
    if not serial or type(serial) ~= "string" or #serial ~= 32 then
        outputDebugString("Failed to add serial: Invalid format (" .. tostring(serial) .. ")")
        if player then outputChatBox("Invalid serial format!", player, 255, 0, 0) end
        return false
    end
    
    if whitelist[serial] then
        outputDebugString("Failed to add serial: " .. serial .. " already exists in whitelist.")
        if player then outputChatBox("This serial is already whitelisted!", player, 255, 0, 0) end
        return false
    end
    
    whitelist[serial] = true
    saveWhitelist(whitelist) -- This saves to whitelist.json
    outputDebugString("Serial added to whitelist: " .. serial .. " by " .. (player and getPlayerName(player) or "manual"))
    if player then 
        outputChatBox("Serial " .. serial .. " added to whitelist!", player, 0, 255, 0)
        triggerClientEvent(player, "receiveWhitelist", player, whitelist)
    end
    return true
end

-- Function to remove serial
function removeSerialFromWhitelist(serial, player)
    if not whitelist[serial] then
        outputDebugString("Failed to remove serial: " .. serial .. " not found in whitelist.")
        if player then outputChatBox("This serial is not on the whitelist!", player, 255, 0, 0) end
        return false
    end
    
    whitelist[serial] = nil
    saveWhitelist(whitelist) -- This saves to whitelist.json
    outputDebugString("Serial removed from whitelist: " .. serial .. " by " .. (player and getPlayerName(player) or "manual"))
    if player then 
        outputChatBox("Serial " .. serial .. " removed from whitelist!", player, 0, 255, 0)
        triggerClientEvent(player, "receiveWhitelist", player, whitelist)
    end
    return true
end

-- Admin command to open GUI
addCommandHandler("whitelist", function(player)
    if hasObjectPermissionTo(player, "general.adminpanel", false) then
        outputDebugString("Whitelist GUI opened by " .. getPlayerName(player))
        triggerClientEvent(player, "openWhitelistGUI", player)
    else
        outputDebugString("Access denied for " .. getPlayerName(player) .. ": No admin permissions.")
        outputChatBox("You don't have permission to use this command!", player, 255, 0, 0)
    end
end)

-- Event handlers for GUI actions
addEvent("addSerialFromGUI", true)
addEventHandler("addSerialFromGUI", root, function(serial)
    if hasObjectPermissionTo(client, "general.adminpanel", false) then
        addSerialToWhitelist(serial, client)
    else
        outputDebugString("Unauthorized attempt to add serial by " .. getPlayerName(client))
    end
end)

addEvent("removeSerialFromGUI", true)
addEventHandler("removeSerialFromGUI", root, function(serial)
    if hasObjectPermissionTo(client, "general.adminpanel", false) then
        removeSerialFromWhitelist(serial, client)
    else
        outputDebugString("Unauthorized attempt to remove serial by " .. getPlayerName(client))
    end
end)

-- Function to get whitelist for GUI display
addEvent("requestWhitelist", true)
addEventHandler("requestWhitelist", root, function()
    if hasObjectPermissionTo(client, "general.adminpanel", false) then
        outputDebugString("Whitelist data sent to " .. getPlayerName(client))
        triggerClientEvent(client, "receiveWhitelist", client, whitelist)
    end
end)

-- Kick function for already connected players
function checkAndKickPlayers()
    for _, player in ipairs(getElementsByType("player")) do
        local playerIP = getPlayerIP(player) or "0.0.0.0"
        local serial = getPlayerSerial(player)
        
        fetchRemote("http://ip-api.com/json/" .. playerIP, function(response, errno, player)
            if errno ~= 0 then
                outputDebugString("GeoIP fetch failed for " .. getPlayerName(player) .. ": Error " .. errno)
                kickPlayer(player, "Server", "Unable to verify your country. Kicked.")
                return
            end
            
            local data = fromJSON(response)
            local country = data and data.countryCode or "Unknown"
            outputDebugString("Country detected for " .. getPlayerName(player) .. ": " .. country)
            
            if country ~= allowedCountry then
                outputDebugString("Kicking " .. getPlayerName(player) .. ": Country (" .. country .. ") not allowed.")
                kickPlayer(player, "Server", "This server is restricted to Polish players only.")
            elseif not whitelist[serial] then
                outputDebugString("Kicking " .. getPlayerName(player) .. ": Serial not in whitelist.")
                kickPlayer(player, "Server", "You are not on the whitelist!")
            end
        end, "", true, player)
    end
end

-- Run the kick check every 10 seconds
setTimer(checkAndKickPlayers, 10000, 0)

-- Run check immediately when a player joins
addEventHandler("onPlayerJoin", root, function()
    checkAndKickPlayers()
end)
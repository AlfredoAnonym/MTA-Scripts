local screenW, screenH = guiGetScreenSize()
local window = nil
local whitelistGrid = nil

local function closeWhitelistGUI()
    if window and isElement(window) then
        destroyElement(window)
        window = nil
        whitelistGrid = nil
        showCursor(false)
    end
end

addEvent("openWhitelistGUI", true)
addEventHandler("openWhitelistGUI", root, function()
    if window and isElement(window) then
        closeWhitelistGUI()
        return
    end
    
    window = guiCreateWindow((screenW - 400) / 2, (screenH - 300) / 2, 400, 300, "Whitelist Manager", false)
    guiWindowSetSizable(window, false)
    showCursor(true)
    
    local closeXButton = guiCreateButton(370, 5, 20, 20, "X", false, window) -- Top-right "X" button
    local serialEdit = guiCreateEdit(10, 30, 380, 30, "", false, window)
    local addButton = guiCreateButton(10, 70, 185, 30, "Add Serial", false, window)
    local removeButton = guiCreateButton(205, 70, 185, 30, "Remove Serial", false, window)
    local closeButton = guiCreateButton(150, 260, 100, 30, "Close", false, window) -- New "Close" button at bottom
    whitelistGrid = guiCreateGridList(10, 110, 380, 140, false, window) -- Adjusted height to fit Close button
    guiGridListAddColumn(whitelistGrid, "Serials", 0.9)
    
    addEventHandler("onClientGUIClick", addButton, function()
        local serial = guiGetText(serialEdit)
        triggerServerEvent("addSerialFromGUI", localPlayer, serial)
        guiSetText(serialEdit, "")
    end, false)
    
    addEventHandler("onClientGUIClick", removeButton, function()
        local selected = guiGridListGetSelectedItem(whitelistGrid)
        if selected ~= -1 then
            local serial = guiGridListGetItemText(whitelistGrid, selected, 1)
            triggerServerEvent("removeSerialFromGUI", localPlayer, serial)
        end
    end, false)
    
    addEventHandler("onClientGUIClick", closeXButton, closeWhitelistGUI, false)
    addEventHandler("onClientGUIClick", closeButton, closeWhitelistGUI, false) -- Same function for new button
    
    triggerServerEvent("requestWhitelist", localPlayer)
end)

addEvent("receiveWhitelist", true)
addEventHandler("receiveWhitelist", root, function(whitelistData)
    if not window or not isElement(window) or not whitelistGrid then return end
    guiGridListClear(whitelistGrid)
    for serial in pairs(whitelistData) do
        guiGridListAddRow(whitelistGrid, serial)
    end
end)
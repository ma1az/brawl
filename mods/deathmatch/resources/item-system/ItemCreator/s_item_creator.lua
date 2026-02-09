-- ITEM CREATOR BY MAXIME
function spawnItem (thePlayer, targetPlayerID, itemID, itemValue )
	-- check permissions
	if not (exports.integration:isPlayerSeniorAdmin(thePlayer) or exports.integration:isPlayerScripter(thePlayer)) then
		outputChatBox("Error: You do not have permission (Senior Admin+) to use this.", thePlayer, 255, 0, 0)
		return
	end

	-- find target player
	local targetPlayer = false
	for _, player in ipairs(getElementsByType("player")) do
		if getElementData(player, "playerid") == tonumber(targetPlayerID) then
			targetPlayer = player
			break
		end
	end

	if targetPlayer then
		local success = giveItem(targetPlayer, tonumber(itemID), tostring(itemValue), nil, true)
		if success then
			outputChatBox("Spawned item " .. itemID .. " for " .. getPlayerName(targetPlayer) .. ".", thePlayer, 0, 255, 0)
		else
			outputChatBox("Error: Failed to give item (Unknown error).", thePlayer, 255, 0, 0)
		end
	else
		outputChatBox("Target player not found (ID: "..tostring(targetPlayerID)..").", thePlayer, 255, 0, 0)
	end
end
addEvent("itemCreator:spawnItem", true)
addEventHandler("itemCreator:spawnItem", getRootElement(), spawnItem)
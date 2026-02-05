--[[
* ***********************************************************************************************************************
* Copyright (c) 2015 Brawl Roleplay - All Rights Reserved
* All rights reserved. This program and the accompanying materials are private property belongs to Brawl Roleplay
* Unauthorized copying of this file, via any medium is strictly prohibited
* Proprietary and confidential
* ***********************************************************************************************************************
]]

addEvent( 'flash:battery:drain', true )
addEventHandler( 'flash:battery:drain', resourceRoot, function( batt, dbid )
	local item, slot = getFlashLightItem( client, dbid )
	if item and item[2] ~= batt then
		exports['item-system']:updateItemValue( client, slot, batt )
	end
end)


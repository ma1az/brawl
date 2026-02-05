--[[
* ***********************************************************************************************************************
* Copyright (c) 2015 Brawl Roleplay - All Rights Reserved
* All rights reserved. This program and the accompanying materials are private property belongs to Brawl Roleplay
* Unauthorized copying of this file, via any medium is strictly prohibited
* Proprietary and confidential
* ***********************************************************************************************************************
]]

function syncFuel(ifuel, battery_)
	if ifuel then
		setElementData( source, 'fuel', ifuel, false )
	end
	if battery_ then
		setElementData( source, 'battery', battery_, false )
	end
end
addEvent( "syncFuel", true )
addEventHandler( "syncFuel" , root, syncFuel)
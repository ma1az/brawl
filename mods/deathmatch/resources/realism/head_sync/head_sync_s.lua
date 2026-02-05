--[[
* ***********************************************************************************************************************
* Copyright (c) 2015 Brawl Roleplay - All Rights Reserved
* All rights reserved. This program and the accompanying materials are private property belongs to Brawl Roleplay
* Unauthorized copying of this file, via any medium is strictly prohibited
* Proprietary and confidential
* ***********************************************************************************************************************
]]

function syncHeads(nearby_players, dir)
	for dbid, player in pairs( nearby_players ) do
		triggerLatentServerEvent( player, 'realism:lookat:sync', source, dir )
	end
end
addEvent( 'realism:lookat:sync', true )
addEventHandler( 'realism:lookat:sync' , root, syncHeads)
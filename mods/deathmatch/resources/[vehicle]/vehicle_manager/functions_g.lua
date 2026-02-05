--[[
* ***********************************************************************************************************************
* Copyright (c) 2015 Brawl Roleplay - All Rights Reserved
* All rights reserved. This program and the accompanying materials are private property belongs to Brawl Roleplay
* Unauthorized copying of this file, via any medium is strictly prohibited
* Proprietary and confidential
* ***********************************************************************************************************************
]]

function canAccessVehicleManager( player )
	return exports.integration:isPlayerTrialAdmin( player ) or exports.integration:isPlayerVCTMember( player ) or exports.integration:isPlayerScripter( player )
end
function updateNametagColor(thePlayer)
	if source then thePlayer = source end
	if getElementData(thePlayer, "loggedin") ~= 1 then -- Not logged in
		setPlayerNametagColor(thePlayer, 127, 127, 127)
	elseif (exports.integration:isPlayerLeadScripter(thePlayer) and getElementData(thePlayer, "admin_level") == 10 ) and getElementData(thePlayer, "duty_admin") == 1 and getElementData(thePlayer, "hiddenadmin") == 0 then -- Scripter Duty
		setPlayerNametagColor(thePlayer, 191, 94, 243)
	elseif (exports.integration:isPlayerOwner(thePlayer) and getElementData(thePlayer, "admin_level") == 7 ) and getElementData(thePlayer, "duty_admin") == 1 and getElementData(thePlayer, "hiddenadmin") == 0 then -- Scripter Duty
		setPlayerNametagColor(thePlayer, 144, 55, 191)
	elseif (exports.integration:isPlayerGeneralManager(thePlayer) and getElementData(thePlayer, "admin_level") == 6 ) and getElementData(thePlayer, "duty_admin") == 1 and getElementData(thePlayer, "hiddenadmin") == 0 then -- Scripter Duty
		setPlayerNametagColor(thePlayer, 194, 108, 240)
	elseif (exports.integration:isPlayerHeadAdmin(thePlayer) and getElementData(thePlayer, "admin_level") == 5 ) and getElementData(thePlayer, "duty_admin") == 1 and getElementData(thePlayer, "hiddenadmin") == 0 then -- Scripter Duty
		setPlayerNametagColor(thePlayer, 195, 156, 214)
	elseif (exports.integration:isPlayerLeadAdmin(thePlayer) and getElementData(thePlayer, "admin_level") == 4 ) and getElementData(thePlayer, "duty_admin") == 1 and getElementData(thePlayer, "hiddenadmin") == 0 then -- UAT Duty
		setPlayerNametagColor(thePlayer, 103, 103, 214)
	elseif (exports.integration:isPlayerSeniorAdmin(thePlayer) and getElementData(thePlayer, "admin_level") == 3 ) and getElementData(thePlayer, "duty_admin") == 1 and getElementData(thePlayer, "hiddenadmin") == 0 then -- Admin on duty
		setPlayerNametagColor(thePlayer, 140, 140, 230)
	elseif (exports.integration:isPlayerAdmin(thePlayer) and getElementData(thePlayer, "admin_level") == 2 ) and getElementData(thePlayer, "duty_admin") == 1 and getElementData(thePlayer, "hiddenadmin") == 0 then -- Admin on duty
		setPlayerNametagColor(thePlayer, 183, 183, 237)
	elseif (exports.integration:isPlayerTrialAdmin(thePlayer) and getElementData(thePlayer, "admin_level") == 1 ) and getElementData(thePlayer, "duty_admin") == 1 and getElementData(thePlayer, "hiddenadmin") == 0 then -- Admin on duty
		setPlayerNametagColor(thePlayer, 206, 206, 240)
	elseif exports.integration:isPlayerSupporter(thePlayer) and (getElementData(thePlayer, "duty_supporter") == 1) and getElementData(thePlayer, "hiddenadmin") == 0 then
		setPlayerNametagColor(thePlayer, 70, 200, 30)
	elseif exports.donators:hasPlayerPerk(thePlayer, 11) then
		setElementData(thePlayer, "donation:nametag", true, true)
		if getElementData(thePlayer, "nametag_on") then
			setPlayerNametagColor(thePlayer, 167, 133, 63)
		else
			setPlayerNametagColor(thePlayer, 255, 255, 255)
		end
	else
		setPlayerNametagColor(thePlayer, 255, 255, 255)
	end
end
addEvent("updateNametagColor", true)
addEventHandler("updateNametagColor", getRootElement(), updateNametagColor)

for key, value in ipairs( getElementsByType( "player" ) ) do
	updateNametagColor( value )
end

function toggleGoldenNametag()
	if not getElementData(client, "donation:nametag") and not getElementData(client, "donation:lifeTimeNameTag") then
		return
	end

	setElementData(client, "lifeTimeNameTag_on", not getElementData(client, "lifeTimeNameTag_on"), true)
	setElementData(client, "nametag_on", not getElementData(client, "nametag_on"), true)
	updateNametagColor(client)
end
addEvent("global:toggleGoldenNametag", true)
addEventHandler("global:toggleGoldenNametag", getRootElement(), toggleGoldenNametag)


-- PUBLIC PHONES
addEventHandler( "onResourceStart", getResourceRootElement( ),
	function( )
		local result = mysql:query("SELECT id, x, y, z, dimension FROM publicphones")
		if result then
			while true do
				row = mysql:fetch_assoc(result)
				if not (row) then
					break
				end
				local id = tonumber(row["id"])
					
				local x = tonumber(row["x"])
				local y = tonumber(row["y"])
				local z = tonumber(row["z"])
					
				local dimension = tonumber(row["dimension"])
				
				local shape = createColSphere(x, y, z, 3)
				exports.pool:allocateElement(shape)
				setElementDimension(shape, dimension)
				exports.anticheat:changeProtectedElementDataEx(shape, "dbid", id, true)
			end
			mysql:free_result(result)
		end
	end
)

function SmallestID( ) -- finds the smallest ID in the SQL instead of auto increment
	local result = mysql:query_fetch_assoc("SELECT MIN(e1.id+1) AS nextID FROM publicphones AS e1 LEFT JOIN publicphones AS e2 ON e1.id +1 = e2.id WHERE e2.id IS NULL")
	if result then
		local id = tonumber(result["nextID"]) or 1
		return id
	end
	return false
end

function addPhone(thePlayer, commandName)
	if (exports.integration:isPlayerTrialAdmin(thePlayer)) then
		local x, y, z = getElementPosition(thePlayer)
		local dimension = getElementDimension(thePlayer)
		
		local id = SmallestID()
		local query = mysql:query_free("INSERT INTO publicphones SET id=" .. mysql:escape_string(id) .. ", x="  .. mysql:escape_string(x) .. ", y=" .. mysql:escape_string(y) .. ", z=" .. mysql:escape_string(z) .. ", dimension=" .. mysql:escape_string(dimension))
		
		if (query) then
			
			local shape = createColSphere(x, y, z, 3)
			exports.pool:allocateElement(shape)
			setElementDimension(shape, dimension)
			exports.anticheat:changeProtectedElementDataEx(shape, "dbid", id, true)
			
			outputChatBox("Public Phone spawned with ID #" .. id .. ".", thePlayer, 0, 255, 0)
		else
			outputChatBox("Error 200001 - Report on forums.", thePlayer, 255, 0, 0)
		end
	end
end
addCommandHandler("addphone", addPhone, false, false)

function getNearbyPhones(thePlayer, commandName)
	if (exports.integration:isPlayerTrialAdmin(thePlayer)) then
		local posX, posY, posZ = getElementPosition(thePlayer)
		outputChatBox("Nearby Phones:", thePlayer, 255, 126, 0)
		local count = 0
		
		for k, theColshape in ipairs(getElementsByType("colshape", getResourceRootElement())) do
			local x, y = getElementPosition(theColshape)
			local distance = getDistanceBetweenPoints2D(posX, posY, x, y)
			if (distance<=20) then
				local dbid = getElementData(theColshape, "dbid")
				outputChatBox("   Public Phone with ID " .. dbid .. ".", thePlayer, 255, 126, 0)
				count = count + 1
			end
		end
		
		if (count==0) then
			outputChatBox("   None.", thePlayer, 255, 126, 0)
		end
	end
end
addCommandHandler("nearbyphones", getNearbyPhones, false, false)

function delPhone(thePlayer, commandName, id)
	if exports.integration:isPlayerTrialAdmin(thePlayer) then
		local id = tonumber(id)
		if not id then
			outputChatBox( "SYNTAX: /" .. commandName .. " [id]", thePlayer, 255, 194, 14 )
		else
			local colShape = nil
			
			for key, value in ipairs(getElementsByType("colshape", getResourceRootElement())) do
				if getElementData(value, "dbid") == id then
					colShape = value
				end
			end
			
			if (colShape) then
				local id = getElementData(colShape, "dbid")
				local result = mysql:query_free("DELETE FROM publicphones WHERE id=" .. mysql:escape_string(id))
				
				outputChatBox("Phone #" .. id .. " deleted.", thePlayer)
				destroyElement(colShape)
			else
				outputChatBox("You are not in a Pay n Spray.", thePlayer, 255, 0, 0)
			end
		end
	end
end
addCommandHandler("delphone", delPhone, false, false)


-- ============================================================
-- PUBLIC PHONE: Distance monitoring + Call cost system
-- ============================================================
local PUBLIC_PHONE_MAX_DISTANCE = 5        -- max distance in units from the phone
local PUBLIC_PHONE_WARNING_TIME  = 5000    -- 5 seconds to return
local PUBLIC_PHONE_RATE_PER_SEC  = 0.305   -- $/second (same as cellphone rate)
local PUBLIC_PHONE_MAX_COST      = 5000    -- cap

local publicPhoneData = {} -- per-player tracking table

--- Called when a public phone call is initiated (ringing or hotline connect).
--- Starts distance monitoring from the phone position.
function startPublicPhoneMonitor(thePlayer)
	local col = getElementData(thePlayer, "call.col")
	if not col or not isElement(col) then return end

	-- Kill any existing monitor first
	stopPublicPhoneMonitor(thePlayer)

	local phoneX, phoneY, phoneZ = getElementPosition(col)

	publicPhoneData[thePlayer] = {
		phoneX        = phoneX,
		phoneY        = phoneY,
		phoneZ        = phoneZ,
		callStartTime = nil,   -- set when actually connected
		warningActive = false,
		warningTimer  = nil,
		checkTimer    = nil,
	}

	-- Check distance every second
	publicPhoneData[thePlayer].checkTimer = setTimer(checkPublicPhoneDistance, 1000, 0, thePlayer)
end

--- Called when the other party picks up (call connected).
--- Starts the billing clock.
function connectPublicPhoneCall(thePlayer)
	if publicPhoneData[thePlayer] then
		publicPhoneData[thePlayer].callStartTime = getTickCount()
	end
end

--- Periodic distance check for a player on a public phone.
function checkPublicPhoneDistance(thePlayer)
	if not isElement(thePlayer) or not publicPhoneData[thePlayer] then
		stopPublicPhoneMonitor(thePlayer)
		return
	end

	local data = publicPhoneData[thePlayer]
	local px, py, pz = getElementPosition(thePlayer)
	local distance = getDistanceBetweenPoints3D(px, py, pz, data.phoneX, data.phoneY, data.phoneZ)

	if distance > PUBLIC_PHONE_MAX_DISTANCE then
		if not data.warningActive then
			data.warningActive = true
			outputChatBox("WARNING: You are too far from the public phone! Return within 5 seconds or the call will end.", thePlayer, 255, 165, 0)
			data.warningTimer = setTimer(function()
				if publicPhoneData[thePlayer] then
					outputChatBox("You moved too far from the public phone. Call disconnected.", thePlayer, 255, 0, 0)
					triggerEvent("phone:cancelPhoneCall", thePlayer)
				end
			end, PUBLIC_PHONE_WARNING_TIME, 1)
		end
	else
		if data.warningActive then
			data.warningActive = false
			if data.warningTimer and isTimer(data.warningTimer) then
				killTimer(data.warningTimer)
				data.warningTimer = nil
			end
			outputChatBox("You returned to the public phone. The call continues.", thePlayer, 0, 255, 0)
		end
	end
end

--- Called when a public phone call ends. Calculates duration & cost.
function endPublicPhoneCall(thePlayer)
	if not publicPhoneData[thePlayer] then return end

	local data = publicPhoneData[thePlayer]

	-- Only charge if the call was actually connected
	if data.callStartTime then
		local callDurationMs = getTickCount() - data.callStartTime
		local callDurationSec = math.floor(callDurationMs / 1000)

		-- Format duration nicely
		local minutes = math.floor(callDurationSec / 60)
		local seconds = callDurationSec % 60
		local durationText
		if minutes > 0 then
			durationText = minutes .. " minute" .. (minutes > 1 and "s" or "") .. " and " .. seconds .. " second" .. (seconds ~= 1 and "s" or "")
		else
			durationText = seconds .. " second" .. (seconds ~= 1 and "s" or "")
		end

		-- Calculate cost
		local cost = math.ceil(callDurationSec * PUBLIC_PHONE_RATE_PER_SEC)
		if cost > PUBLIC_PHONE_MAX_COST then cost = PUBLIC_PHONE_MAX_COST end

		if cost > 0 then
			local bankMoney = tonumber(getElementData(thePlayer, "bankmoney")) or 0
			if bankMoney >= cost then
				exports.anticheat:changeProtectedElementDataEx(thePlayer, "bankmoney", bankMoney - cost, false)
				outputChatBox("Public phone call ended. Duration: " .. durationText .. ". You have been charged $" .. cost .. ".", thePlayer, 255, 165, 0)
				exports.hud:sendBottomNotification(thePlayer, "Public Phone", "$" .. cost .. " has been withdrawn from your bank account for a " .. durationText .. " call.")
			else
				-- Take what they have
				local charged = bankMoney
				if bankMoney > 0 then
					exports.anticheat:changeProtectedElementDataEx(thePlayer, "bankmoney", 0, false)
				end
				outputChatBox("Public phone call ended. Duration: " .. durationText .. ". Charge: $" .. cost .. " (insufficient funds).", thePlayer, 255, 0, 0)
				exports.hud:sendBottomNotification(thePlayer, "Public Phone", "Insufficient funds. $" .. charged .. " withdrawn (owed $" .. cost .. ") for a " .. durationText .. " call.")
			end
		else
			outputChatBox("Public phone call ended. Duration: " .. durationText .. ". No charges.", thePlayer, 255, 165, 0)
		end
	else
		outputChatBox("Public phone call ended. The call was not connected. No charges.", thePlayer, 200, 200, 200)
	end

	stopPublicPhoneMonitor(thePlayer)
end

--- Kills all timers and cleans up tracking data for a player.
function stopPublicPhoneMonitor(thePlayer)
	if publicPhoneData[thePlayer] then
		local data = publicPhoneData[thePlayer]
		if data.checkTimer and isTimer(data.checkTimer) then
			killTimer(data.checkTimer)
		end
		if data.warningTimer and isTimer(data.warningTimer) then
			killTimer(data.warningTimer)
		end
		publicPhoneData[thePlayer] = nil
	end
end

--- Clean up on resource stop
addEventHandler("onResourceStop", getResourceRootElement(),
	function()
		for player, _ in pairs(publicPhoneData) do
			stopPublicPhoneMonitor(player)
		end
	end
)


-- ============================================================
-- Garbage Collector Job System – Server
-- ============================================================

local mysql = exports.mysql

-- State tables
local trashObjects   = {}   -- trashId (int)   → object element
local loadZones      = {}   -- colShape element → vehicle element
local dumpCol        = nil  -- dump zone colshape
local dumpTimers     = {}   -- vehicle element  → timer
local pickupDebounce   = {}   -- serial (string)   → getTickCount()
local trashPickupLocks = {}   -- trashId (int)     → true (lock while pickup is in progress)
local vehicleLastLoad  = {}   -- vehicle element   → timestamp (last trash loaded)
local loadCooldowns    = {}   -- vehicle element   → getTickCount() (10s cooldown between loads)

local LOAD_COOLDOWN_MS = 10000  -- 10 seconds between loading trash
local VEHICLE_INACTIVE_SECONDS = 3600  -- 1 hour = reset storage

-- ============================================================
-- Utility helpers
-- ============================================================

local function getNow()
	local t = getRealTime()
	return t and t.timestamp or 0
end

local function isGarbageVehicle(vehicle)
	if not isElement(vehicle) or getElementType(vehicle) ~= "vehicle" then return false end
	if getElementModel(vehicle) ~= 408 then return false end
	local jobData = getElementData(vehicle, "job")
	if jobData == nil then return true end
	return tonumber(jobData) == GARBAGE_JOB_ID
end

local function getPlayerGarbageCapacity(player)
	local level = math.max(tonumber(getElementData(player, "jobLevel")) or 1, 1)
	return GARBAGE_BASE_CAPACITY + (level - 1) * GARBAGE_CAPACITY_PER_LEVEL
end

--- Unified notification wrapper (HUD bottom bar)
local function notifyPlayer(player, msg)
	if isElement(player) then
		exports.hud:sendBottomNotification(player, "Garbage Collector:", msg)
	end
end

-- ============================================================
-- Database
-- ============================================================

local function ensureTables()
	dbExec(mysql:getConn(), [[
		CREATE TABLE IF NOT EXISTS `garbage_locations` (
			`id`             INT NOT NULL AUTO_INCREMENT,
			`x`              FLOAT NOT NULL,
			`y`              FLOAT NOT NULL,
			`z`              FLOAT NOT NULL,
			`rx`             FLOAT NOT NULL DEFAULT 0,
			`ry`             FLOAT NOT NULL DEFAULT 0,
			`rz`             FLOAT NOT NULL DEFAULT 0,
			`interior`       INT NOT NULL DEFAULT 0,
			`dimension`      INT NOT NULL DEFAULT 0,
			`trash_type`     INT NOT NULL DEFAULT 1,
			`next_available` INT NOT NULL DEFAULT 0,
			`created_by`     INT NOT NULL DEFAULT 0,
			`created_at`     TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
			PRIMARY KEY (`id`)
		)
	]])
	-- Add rotation columns if the table already existed without them
	dbExec(mysql:getConn(), "ALTER TABLE `garbage_locations` ADD COLUMN IF NOT EXISTS `rx` FLOAT NOT NULL DEFAULT 0")
	dbExec(mysql:getConn(), "ALTER TABLE `garbage_locations` ADD COLUMN IF NOT EXISTS `ry` FLOAT NOT NULL DEFAULT 0")
	dbExec(mysql:getConn(), "ALTER TABLE `garbage_locations` ADD COLUMN IF NOT EXISTS `rz` FLOAT NOT NULL DEFAULT 0")
end

-- ============================================================
-- Trash object spawning
-- ============================================================

local function spawnTrash(row)
	local id = tonumber(row.id)
	if not id then return nil end

	local trashType = tonumber(row.trash_type) or 1
	local model     = GARBAGE_TRASH_MODELS[trashType] or 1337
	local x, y, z   = tonumber(row.x), tonumber(row.y), tonumber(row.z)
	local rx, ry, rz = tonumber(row.rx) or 0, tonumber(row.ry) or 0, tonumber(row.rz) or 0
	local interior   = tonumber(row.interior)  or 0
	local dimension  = tonumber(row.dimension) or 0
	local nextAvail  = tonumber(row.next_available) or 0

	local obj = createObject(model, x, y, z, rx, ry, rz)
	if not obj then return nil end

	setElementInterior(obj, interior)
	setElementDimension(obj, dimension)
	setElementFrozen(obj, true)

	-- Synced data (clients need these for holograms & tracking)
	setElementData(obj, "garbage:trashId",       id,        true)
	setElementData(obj, "garbage:trashType",     trashType, true)
	setElementData(obj, "garbage:nextAvailable", nextAvail, true)

	trashObjects[id] = obj
	return obj
end

local function loadTrashLocations()
	local qh = mysql:query("SELECT * FROM garbage_locations")
	if not qh then
		outputDebugString("[Garbage] Failed to query garbage_locations.", 1)
		return
	end
	local row = mysql:fetch_assoc(qh)
	while row do
		spawnTrash(row)
		row = mysql:fetch_assoc(qh)
	end
	mysql:free_result(qh)
end

-- ============================================================
-- Carry state management
-- ============================================================

local function clearPlayerCarry(player)
	if not isElement(player) then return end

	-- Detach and destroy the visual carry prop
	local carryObj = getElementData(player, "garbage:carryObject")
	if isElement(carryObj) then
		local boneRes = getResourceFromName("bone_attach")
		if boneRes and getResourceState(boneRes) == "running" then
			exports.bone_attach:detachElementFromBone(carryObj)
		end
		destroyElement(carryObj)
	end

	-- Stop any active animation (direct MTA call + global wrapper)
	setPedAnimation(player)
	exports.global:removeAnimation(player)

	-- Reset all carry-related element data
	-- carrying is synced (true) so clients see the change
	exports.anticheat:changeProtectedElementDataEx(player, "garbage:carrying",     false, true)
	exports.anticheat:changeProtectedElementDataEx(player, "garbage:carryObject",  nil,   false)
	exports.anticheat:changeProtectedElementDataEx(player, "garbage:carryTrashId", nil,   false)
	exports.anticheat:changeProtectedElementDataEx(player, "garbage:loading",      false, false)
end

local function attachCarryObject(player)
	local obj = createObject(GARBAGE_CARRY_MODEL, 0, 0, 0)
	if not obj then return false end

	setObjectScale(obj, 0.53)
	setElementDimension(obj, getElementDimension(player))
	setElementInterior(obj, getElementInterior(player))
	setElementCollisionsEnabled(obj, false)

	local boneRes = getResourceFromName("bone_attach")
	if boneRes and getResourceState(boneRes) == "running" then
		-- Bone 3 = spine; centered in front of body at chest level
		exports.bone_attach:attachElementToBone(obj, player, 3, 0.0, 0.38, 0.22, 0, 0, 0)
	else
		attachElements(obj, player, 0.0, 0.38, 0.22)
	end

	exports.anticheat:changeProtectedElementDataEx(player, "garbage:carryObject", obj,  false)
	exports.anticheat:changeProtectedElementDataEx(player, "garbage:carrying",    true, true)
	return true
end

-- ============================================================
-- Levelling
-- ============================================================

local function levelUpGarbageJob(player, amount)
	local charID = getElementData(player, "dbid")
	if not charID then return end

	local curLevel    = tonumber(getElementData(player, "jobLevel"))    or 1
	local curProgress = tonumber(getElementData(player, "jobProgress")) or 0
	local req         = GARBAGE_LEVEL_REQUIREMENTS[curLevel]

	local newProgress = curProgress + amount
	local newLevel    = curLevel

	while req and newProgress >= req do
		newProgress = newProgress - req
		newLevel    = newLevel + 1
		req         = GARBAGE_LEVEL_REQUIREMENTS[newLevel]
	end

	if newLevel ~= curLevel then
		dbExec(mysql:getConn(),
			"UPDATE jobs SET jobLevel=?, jobProgress=? WHERE jobID=? AND jobCharID=?",
			newLevel, newProgress, GARBAGE_JOB_ID, charID)
		notifyPlayer(player, "Congratulations! You are now level " .. newLevel .. ".")
	else
		dbExec(mysql:getConn(),
			"UPDATE jobs SET jobProgress=? WHERE jobID=? AND jobCharID=?",
			newProgress, GARBAGE_JOB_ID, charID)
	end

	exports["job-system"]:fetchJobInfoForOnePlayer(player)
end

-- ============================================================
-- Dump timer helpers
-- ============================================================

local function cancelDumpTimer(vehicle)
	if dumpTimers[vehicle] and isTimer(dumpTimers[vehicle]) then
		killTimer(dumpTimers[vehicle])
	end
	dumpTimers[vehicle] = nil
end

-- ============================================================
-- Load zone (back of the Trashmaster)
-- ============================================================

local function finalizeLoad(player, vehicle)
	if not isElement(player) or not isElement(vehicle) then return end

	local capacity = getPlayerGarbageCapacity(player)
	local curLoad  = tonumber(getElementData(vehicle, "garbage:load")) or 0

	-- Clear carry state first (removes prop + animation)
	clearPlayerCarry(player)

	if curLoad >= capacity then
		notifyPlayer(player, "The Trashmaster is full. Drive to the dump to unload.")
		return
	end

	curLoad = curLoad + 1
	exports.anticheat:changeProtectedElementDataEx(vehicle, "garbage:load", curLoad, true)

	-- Track last load time for inactivity reset
	vehicleLastLoad[vehicle] = getNow()
	loadCooldowns[vehicle] = getTickCount()

	-- RP action visible to nearby players
	exports.global:sendLocalMeAction(player, "tosses a bag of garbage into the back of the Trashmaster.")
	notifyPlayer(player, "Loaded: " .. curLoad .. "/" .. capacity .. " bags. Drive to the green blip to dump & earn money.")
end

local function handleLoadZoneHit(hitElement, matchingDimension)
	if not matchingDimension then return end
	if not isElement(hitElement) or getElementType(hitElement) ~= "player" then return end
	if getPedOccupiedVehicle(hitElement) then return end
	if (tonumber(getElementData(hitElement, "job")) or 0) ~= GARBAGE_JOB_ID then return end
	if not getElementData(hitElement, "garbage:carrying") then return end
	if getElementData(hitElement, "garbage:loading") then return end

	local vehicle = loadZones[source]
	if not isGarbageVehicle(vehicle) then return end

	-- 10 second cooldown between loads
	local lastLoad = loadCooldowns[vehicle] or 0
	local now = getTickCount()
	if (now - lastLoad) < LOAD_COOLDOWN_MS then
		local remaining = math.ceil((LOAD_COOLDOWN_MS - (now - lastLoad)) / 1000)
		notifyPlayer(hitElement, "Wait " .. remaining .. " seconds before loading more trash.")
		return
	end

	local capacity = getPlayerGarbageCapacity(hitElement)
	local curLoad  = tonumber(getElementData(vehicle, "garbage:load")) or 0
	if curLoad >= capacity then
		notifyPlayer(hitElement, "The Trashmaster is full. Drive to the dump to unload.")
		return
	end

	-- Lock loading state & play put-down animation
	exports.anticheat:changeProtectedElementDataEx(hitElement, "garbage:loading", true, false)
	setPedAnimation(hitElement, "CARRY", "putdwn", 500, false, false, false, false)

	-- Capture player reference for timer closure
	local player = hitElement
	setTimer(function()
		if not isElement(player) then return end
		finalizeLoad(player, vehicle)
		exports.anticheat:changeProtectedElementDataEx(player, "garbage:loading", false, false)
	end, 700, 1)
end

local function createLoadZone(vehicle)
	if not isGarbageVehicle(vehicle) then return end
	if getElementData(vehicle, "garbage:loadZone") then return end

	local col = createColSphere(0, 0, 0, GARBAGE_LOAD_RADIUS)
	attachElements(col, vehicle, GARBAGE_LOAD_OFFSET.x, GARBAGE_LOAD_OFFSET.y, GARBAGE_LOAD_OFFSET.z)
	setElementDimension(col, getElementDimension(vehicle))
	setElementInterior(col, getElementInterior(vehicle))
	setElementData(col, "garbage:loadZone", true, false)
	addEventHandler("onColShapeHit", col, handleLoadZoneHit)

	loadZones[col] = vehicle
	exports.anticheat:changeProtectedElementDataEx(vehicle, "garbage:loadZone", col, false)

	if not getElementData(vehicle, "garbage:load") then
		exports.anticheat:changeProtectedElementDataEx(vehicle, "garbage:load", 0, true)
	end
end

local function destroyLoadZone(vehicle)
	local col = getElementData(vehicle, "garbage:loadZone")
	if isElement(col) then
		loadZones[col] = nil
		destroyElement(col)
	end
	exports.anticheat:changeProtectedElementDataEx(vehicle, "garbage:loadZone", nil, false)
end

local function refreshVehicleLoadZones()
	for _, v in ipairs(getElementsByType("vehicle")) do
		if isGarbageVehicle(v) then
			createLoadZone(v)
		end
	end
end

-- Find the nearest garbage Trashmaster to a player (fallback when colshape doesn't fire)
local function findNearestTrashmaster(player)
	local px, py, pz = getElementPosition(player)
	local dim = getElementDimension(player)
	local int = getElementInterior(player)
	local bestVeh  = nil
	local bestDist = 8.0  -- generous range

	for _, v in ipairs(getElementsByType("vehicle")) do
		if isGarbageVehicle(v)
			and getElementDimension(v) == dim
			and getElementInterior(v) == int then
			local vx, vy, vz = getElementPosition(v)
			local dist = getDistanceBetweenPoints3D(px, py, pz, vx, vy, vz)
			if dist < bestDist then
				bestDist = dist
				bestVeh  = v
			end
		end
	end

	return bestVeh
end

-- ============================================================
-- Manual load request (client fallback when colshape doesn't fire)
-- ============================================================

addEvent("garbage:requestLoad", true)
addEventHandler("garbage:requestLoad", root, function()
	local player = client
	if not isElement(player) then return end
	if getPedOccupiedVehicle(player) then return end
	if (tonumber(getElementData(player, "job")) or 0) ~= GARBAGE_JOB_ID then return end
	if not getElementData(player, "garbage:carrying") then return end
	if getElementData(player, "garbage:loading") then return end

	local vehicle = findNearestTrashmaster(player)
	if not vehicle then
		notifyPlayer(player, "No Trashmaster nearby.")
		return
	end

	-- 10 second cooldown between loads
	local lastLoad = loadCooldowns[vehicle] or 0
	local now = getTickCount()
	if (now - lastLoad) < LOAD_COOLDOWN_MS then
		local remaining = math.ceil((LOAD_COOLDOWN_MS - (now - lastLoad)) / 1000)
		notifyPlayer(player, "Wait " .. remaining .. " seconds before loading more trash.")
		return
	end

	-- Ensure this vehicle has a load zone (create one if missing)
	if not getElementData(vehicle, "garbage:loadZone") then
		createLoadZone(vehicle)
	end

	local capacity = getPlayerGarbageCapacity(player)
	local curLoad  = tonumber(getElementData(vehicle, "garbage:load")) or 0
	if curLoad >= capacity then
		notifyPlayer(player, "The Trashmaster is full. Drive to the dump to unload.")
		return
	end

	-- Lock loading state & play put-down animation
	exports.anticheat:changeProtectedElementDataEx(player, "garbage:loading", true, false)
	setPedAnimation(player, "CARRY", "putdwn", 500, false, false, false, false)

	setTimer(function()
		if not isElement(player) then return end
		finalizeLoad(player, vehicle)
		exports.anticheat:changeProtectedElementDataEx(player, "garbage:loading", false, false)
	end, 700, 1)
end)

-- ============================================================
-- Pickup request (triggered from client)
-- ============================================================

addEvent("garbage:requestPickup", true)
addEventHandler("garbage:requestPickup", root, function(trash)
	local player = client
	if not isElement(player) then return end

	-- Server-side debounce (2 seconds per player)
	local serial = getPlayerSerial(player)
	local tick   = getTickCount()
	if pickupDebounce[serial] and (tick - pickupDebounce[serial]) < 2000 then return end
	pickupDebounce[serial] = tick

	-- ---- Validation ----

	if not isElement(trash) or getElementType(trash) ~= "object" then return end

	if (tonumber(getElementData(player, "job")) or 0) ~= GARBAGE_JOB_ID then
		notifyPlayer(player, "You are not employed as a garbage collector.")
		return
	end

	if getPedOccupiedVehicle(player) then
		notifyPlayer(player, "Exit the vehicle first.")
		return
	end

	if getElementData(player, "garbage:carrying") then
		notifyPlayer(player, "You are already carrying garbage.")
		return
	end

	local trashId = getElementData(trash, "garbage:trashId")
	if not trashId then return end

	if getElementDimension(trash) ~= getElementDimension(player) then return end
	if getElementInterior(trash) ~= getElementInterior(player) then return end

	local px, py, pz = getElementPosition(player)
	local tx, ty, tz = getElementPosition(trash)
	if getDistanceBetweenPoints3D(px, py, pz, tx, ty, tz) > GARBAGE_PICKUP_DISTANCE then
		notifyPlayer(player, "Move closer to the garbage.")
		return
	end

	-- Cooldown check
	local nextAvail = tonumber(getElementData(trash, "garbage:nextAvailable")) or 0
	local now       = getNow()
	if nextAvail > now then
		local rem = nextAvail - now
		notifyPlayer(player, string.format("This garbage respawns in %02d:%02d.", math.floor(rem / 60), rem % 60))
		return
	end

	-- Per-trash lock: prevent two players from picking the same bin simultaneously
	if trashPickupLocks[trashId] then
		notifyPlayer(player, "Someone else is already collecting this garbage.")
		return
	end
	trashPickupLocks[trashId] = true

	-- Re-check cooldown after acquiring lock (another player may have just set it)
	local nextAvailRecheck = tonumber(getElementData(trash, "garbage:nextAvailable")) or 0
	local nowRecheck       = getNow()
	if nextAvailRecheck > nowRecheck then
		trashPickupLocks[trashId] = nil
		local rem = nextAvailRecheck - nowRecheck
		notifyPlayer(player, string.format("This garbage respawns in %02d:%02d.", math.floor(rem / 60), rem % 60))
		return
	end

	-- ---- Execute pickup ----

	-- Apply cooldown on the trash object (synced to ALL players via element data)
	local newCooldown = nowRecheck + GARBAGE_COOLDOWN_SECONDS
	setElementData(trash, "garbage:nextAvailable", newCooldown, true)
	dbExec(mysql:getConn(), "UPDATE garbage_locations SET next_available=? WHERE id=?", newCooldown, trashId)

	-- Lock carry state immediately (prevents double-pickup)
	exports.anticheat:changeProtectedElementDataEx(player, "garbage:carrying",     true,    true)
	exports.anticheat:changeProtectedElementDataEx(player, "garbage:carryTrashId", trashId, false)

	-- Attach bag and trigger client-side carry animation
	if attachCarryObject(player) then
		exports.global:sendLocalMeAction(player, "bends over and picks up a bag of garbage.")
		notifyPlayer(player, "Garbage collected! Take it to the back of a Trashmaster (408).")
		notifyPlayer(player, "Green blip on map = Dump location. Load trash first, then drive there.")
		triggerClientEvent(player, "garbage:startCarryAnim", player)
	else
		clearPlayerCarry(player)
		-- Rollback cooldown since pickup failed
		setElementData(trash, "garbage:nextAvailable", 0, true)
		dbExec(mysql:getConn(), "UPDATE garbage_locations SET next_available=0 WHERE id=?", trashId)
		notifyPlayer(player, "Failed to pick up garbage. Try again.")
	end

	-- Release the per-trash lock
	trashPickupLocks[trashId] = nil
end)

-- ============================================================
-- Dump zone
-- ============================================================

local function handleDumpHit(element, matchingDimension)
	if not matchingDimension then return end
	if not isElement(element) or getElementType(element) ~= "vehicle" then return end
	if not isGarbageVehicle(element) then return end

	local driver = getVehicleOccupant(element, 0)
	if not driver then return end
	if (tonumber(getElementData(driver, "job")) or 0) ~= GARBAGE_JOB_ID then return end
	if dumpTimers[element] then return end

	local curLoad = tonumber(getElementData(element, "garbage:load")) or 0
	if curLoad <= 0 then
		notifyPlayer(driver, "The Trashmaster is empty. Collect some garbage first.")
		return
	end

	notifyPlayer(driver, "Hold still for " .. math.floor(GARBAGE_DUMP_WAIT_MS / 1000) .. " seconds to unload...")

	-- Capture references for the timer closure
	local vehicle   = element
	local theDriver = driver

	dumpTimers[vehicle] = setTimer(function()
		dumpTimers[vehicle] = nil

		if not isElement(vehicle) or not isElement(theDriver) then return end
		if not isElementWithinColShape(vehicle, dumpCol) then return end
		if getVehicleOccupant(vehicle, 0) ~= theDriver then return end

		local load = tonumber(getElementData(vehicle, "garbage:load")) or 0
		if load <= 0 then
			notifyPlayer(theDriver, "The Trashmaster is empty.")
			return
		end

		-- Calculate pay
		local totalPay = 0
		for i = 1, load do
			totalPay = totalPay + math.random(GARBAGE_PAY_MIN, GARBAGE_PAY_MAX)
		end

		-- Apply
		exports.anticheat:changeProtectedElementDataEx(vehicle, "garbage:load", 0, true)
		exports.global:giveMoney(theDriver, totalPay)

		-- RP actions
		exports.global:sendLocalMeAction(theDriver,
			"operates the Trashmaster's compactor, dumping " .. load .. " bags of garbage.")
		exports.global:sendLocalDoAction(theDriver,
			"The garbage is compacted and disposed of properly.")

		notifyPlayer(theDriver, "Dumped " .. load .. " bags and earned $" .. totalPay .. ".")
		levelUpGarbageJob(theDriver, load)
	end, GARBAGE_DUMP_WAIT_MS, 1)
end

local function handleDumpLeave(element, matchingDimension)
	if not matchingDimension then return end
	if not isElement(element) or getElementType(element) ~= "vehicle" then return end
	cancelDumpTimer(element)
end

-- ============================================================
-- Inactivity reset (1 hour of no activity resets vehicle storage)
-- ============================================================

local function checkVehicleInactivity()
	local now = getNow()
	for vehicle, lastActivity in pairs(vehicleLastLoad) do
		if isElement(vehicle) then
			local inactiveSeconds = now - lastActivity
			if inactiveSeconds >= VEHICLE_INACTIVE_SECONDS then
				local curLoad = tonumber(getElementData(vehicle, "garbage:load")) or 0
				if curLoad > 0 then
					exports.anticheat:changeProtectedElementDataEx(vehicle, "garbage:load", 0, true)
					outputDebugString("[Garbage] Reset vehicle storage due to 1 hour inactivity.")
				end
				-- Clear tracking for this vehicle
				vehicleLastLoad[vehicle] = nil
				loadCooldowns[vehicle] = nil
			end
		else
			-- Vehicle no longer exists, clean up
			vehicleLastLoad[vehicle] = nil
			loadCooldowns[vehicle] = nil
		end
	end
end

-- ============================================================
-- Vehicle events
-- ============================================================

addEventHandler("onElementDestroy", root, function()
	if getElementType(source) == "vehicle" then
		destroyLoadZone(source)
		cancelDumpTimer(source)
		-- Clean up inactivity tracking
		vehicleLastLoad[source] = nil
		loadCooldowns[source] = nil
	end
end)

-- When a vehicle respawns, re-create the load zone (attached colshape gets destroyed)
addEventHandler("onVehicleRespawn", root, function()
	if isGarbageVehicle(source) then
		local vehicle = source  -- capture for timer closure (source is invalid inside timers)
		-- Destroy old first (if any), then create fresh
		destroyLoadZone(vehicle)
		-- Reset inactivity tracking on respawn
		vehicleLastLoad[vehicle] = nil
		loadCooldowns[vehicle] = nil
		setTimer(function()
			if isElement(vehicle) and isGarbageVehicle(vehicle) then
				createLoadZone(vehicle)
			end
		end, 1000, 1)
	end
end)

-- Unified data-change handler for both vehicles and players
addEventHandler("onElementDataChange", root, function(dataName, oldValue)
	if dataName ~= "job" then return end

	local eType = getElementType(source)
	if eType == "vehicle" then
		-- Vehicle job changed → create or destroy the load zone
		if isGarbageVehicle(source) then
			createLoadZone(source)
		else
			destroyLoadZone(source)
		end
	elseif eType == "player" then
		-- Player switched away from garbage job while carrying → clean up
		if tonumber(oldValue) == GARBAGE_JOB_ID
			and (tonumber(getElementData(source, "job")) or 0) ~= GARBAGE_JOB_ID then
			clearPlayerCarry(source)
		end
	end
end)

-- Block vehicle entry while carrying garbage
addEventHandler("onVehicleStartEnter", root, function(player, seat)
	if seat ~= 0 then return end
	if not getElementData(player, "garbage:carrying") then return end

	-- Stale-flag safety: if the carry object no longer exists, just clean up
	local carryObj = getElementData(player, "garbage:carryObject")
	if not isElement(carryObj) then
		clearPlayerCarry(player)
		return
	end

	notifyPlayer(player, "Load the garbage into the Trashmaster first.")
	cancelEvent()
end)

-- Cancel dump timer when the driver exits
addEventHandler("onVehicleExit", root, function(player, seat)
	if seat ~= 0 then return end
	cancelDumpTimer(source)
end)

-- ============================================================
-- Player lifecycle
-- ============================================================

addEventHandler("onPlayerQuit", root, function()
	clearPlayerCarry(source)
	local serial = getPlayerSerial(source)
	if serial then pickupDebounce[serial] = nil end
end)

addEventHandler("onPlayerWasted", root, function()
	clearPlayerCarry(source)
end)

-- ============================================================
-- GM / Owner trash relocation (object-mover save hook)
-- ============================================================

-- Listen for the object-mover's saved event.
addEvent("objectMover:onSaved", true)
addEventHandler("objectMover:onSaved", root, function(player, element, cx, cy, cz, rx, ry, rz)
	if not isElement(element) or getElementType(element) ~= "object" then return end

	local trashId = getElementData(element, "garbage:trashId")
	if not trashId then return end   -- not a garbage object → let other handlers deal with it

	-- Save new position and rotation to database
	setElementFrozen(element, true)
	setElementCollisionsEnabled(element, true)
	dbExec(mysql:getConn(), "UPDATE garbage_locations SET x=?, y=?, z=?, rx=?, ry=?, rz=? WHERE id=?", cx, cy, cz, rx, ry, rz, trashId)

	if isElement(player) then
		outputChatBox("Saved garbage location #" .. trashId .. ".", player, 0, 255, 0)
	end
end)

-- ============================================================
-- Admin commands
-- ============================================================

addCommandHandler("createtrash", function(player, cmd, trashType)
	if not exports.integration:isPlayerTrialAdmin(player) then return end

	trashType = tonumber(trashType)
	if not trashType or not GARBAGE_TRASH_MODELS[trashType] then
		outputChatBox("SYNTAX: /" .. cmd .. " [type 1-7]", player, 255, 194, 14)
		return
	end

	local x, y, z   = getElementPosition(player)
	local interior   = getElementInterior(player)
	local dimension  = getElementDimension(player)
	local createdBy  = tonumber(getElementData(player, "account:id")) or 0

	local id = mysql:query_insert_free(
		"INSERT INTO garbage_locations (x, y, z, rx, ry, rz, interior, dimension, trash_type, next_available, created_by) VALUES (?, ?, ?, 0, 0, 0, ?, ?, ?, 0, ?)",
		x, y, z, interior, dimension, trashType, createdBy)

	if id then
		spawnTrash({
			id = id, x = x, y = y, z = z,
			rx = 0, ry = 0, rz = 0,
			interior = interior, dimension = dimension,
			trash_type = trashType, next_available = 0,
		})
		outputChatBox("Garbage location created — ID: " .. id, player, 0, 255, 0)
	else
		outputChatBox("Failed to create garbage location.", player, 255, 0, 0)
	end
end, false, false)

addCommandHandler("deltrash", function(player, cmd, trashId)
	if not exports.integration:isPlayerTrialAdmin(player) then return end

	trashId = tonumber(trashId)
	if not trashId or trashId <= 0 then
		outputChatBox("SYNTAX: /" .. cmd .. " [trash id]  (use /nearbytrash to find IDs)", player, 255, 194, 14)
		return
	end

	local obj = trashObjects[trashId]
	if not obj or not isElement(obj) then
		outputChatBox("Garbage location #" .. trashId .. " does not exist or is not loaded.", player, 255, 0, 0)
		return
	end

	destroyElement(obj)
	trashObjects[trashId] = nil

	dbExec(mysql:getConn(), "DELETE FROM garbage_locations WHERE id=?", trashId)
	outputChatBox("Garbage location #" .. trashId .. " deleted.", player, 0, 255, 0)

	local adminID = tonumber(getElementData(player, "account:id")) or 0
	outputDebugString("[Garbage] Admin (ID:" .. adminID .. ") deleted trash location #" .. trashId)
end, false, false)

addCommandHandler("nearbytrash", function(player, cmd)
	if not exports.integration:isPlayerTrialAdmin(player) then return end

	local px, py, pz = getElementPosition(player)
	local dim = getElementDimension(player)
	local int = getElementInterior(player)
	local found = 0

	local results = {}
	for id, obj in pairs(trashObjects) do
		if isElement(obj)
			and getElementDimension(obj) == dim
			and getElementInterior(obj) == int then
			local x, y, z = getElementPosition(obj)
			local dist = getDistanceBetweenPoints3D(px, py, pz, x, y, z)
			if dist <= 50 then
				table.insert(results, { id = id, dist = dist })
				found = found + 1
			end
		end
	end

	if found == 0 then
		outputChatBox("No garbage locations within 50 units.", player, 255, 194, 14)
		return
	end

	table.sort(results, function(a, b) return a.dist < b.dist end)
	outputChatBox("=== Nearby Garbage Locations ===", player, 0, 255, 0)
	for i = 1, math.min(#results, 10) do
		local r = results[i]
		outputChatBox("  #" .. r.id .. "  —  " .. string.format("%.1f", r.dist) .. " units away", player, 255, 255, 255)
	end
end, false, false)

addCommandHandler("listtrash", function(player, cmd)
	if not exports.integration:isPlayerTrialAdmin(player) then return end

	local count = 0
	for _ in pairs(trashObjects) do count = count + 1 end

	if count == 0 then
		outputChatBox("No garbage locations exist.", player, 255, 194, 14)
		return
	end

	outputChatBox("=== Garbage Locations (" .. count .. " total) ===", player, 0, 255, 0)
	local shown = 0
	for id, obj in pairs(trashObjects) do
		if shown >= 20 then
			outputChatBox("  ... and " .. (count - shown) .. " more. Use /nearesttrash for nearby.", player, 255, 194, 14)
			break
		end
		if isElement(obj) then
			local x, y, z = getElementPosition(obj)
			outputChatBox("  #" .. id .. "  —  (" .. string.format("%.1f, %.1f, %.1f", x, y, z) .. ")", player, 255, 255, 255)
			shown = shown + 1
		else
			trashObjects[id] = nil
		end
	end
end, false, false)

-- ============================================================
-- Resource lifecycle
-- ============================================================

addEventHandler("onResourceStart", resourceRoot, function()
	ensureTables()
	loadTrashLocations()

	-- Create the dump zone collision sphere
	dumpCol = createColSphere(
		GARBAGE_DUMP_POSITION.x, GARBAGE_DUMP_POSITION.y, GARBAGE_DUMP_POSITION.z,
		GARBAGE_DUMP_RADIUS)
	setElementData(dumpCol, "garbage:dumpCol", true, false)
	addEventHandler("onColShapeHit",   dumpCol, handleDumpHit)
	addEventHandler("onColShapeLeave", dumpCol, handleDumpLeave)

	-- Attach load zones to already-existing Trashmasters
	refreshVehicleLoadZones()

	-- Delayed re-scans to catch vehicles spawned by other resources that start later
	setTimer(refreshVehicleLoadZones, 5000,  1)
	setTimer(refreshVehicleLoadZones, 15000, 1)
	setTimer(refreshVehicleLoadZones, 30000, 1)

	-- Periodic re-scan every 60 seconds for any new Trashmasters
	setTimer(refreshVehicleLoadZones, 60000, 0)

	-- Check for inactive vehicles every 5 minutes and reset their storage
	setTimer(checkVehicleInactivity, 300000, 0)

	local count = 0
	for _ in pairs(trashObjects) do count = count + 1 end
	outputDebugString("[Garbage] System loaded — " .. count .. " trash locations.")
end)

addEventHandler("onResourceStop", resourceRoot, function()
	for _, player in ipairs(getElementsByType("player")) do
		clearPlayerCarry(player)
	end
	for vehicle in pairs(dumpTimers) do
		cancelDumpTimer(vehicle)
	end
	-- Clean up tracking tables
	vehicleLastLoad = {}
	loadCooldowns = {}
end)

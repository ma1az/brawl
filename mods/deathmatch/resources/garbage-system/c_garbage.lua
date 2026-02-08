-- ============================================================
-- Garbage Collector Job System – Client
-- ============================================================

local localPlayer   = getLocalPlayer()
local trashObjects  = {}      -- object element → true
local garbageActive = false
local dumpBlip      = nil
local dumpMarker    = nil
local lastAttempt   = 0       -- getTickCount of last E press

local ATTEMPT_COOLDOWN = 2000 -- ms between pickup attempts (client-side)

local sx, sy = guiGetScreenSize()

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

local function getPlayerGarbageCapacity()
	local level = math.max(tonumber(getElementData(localPlayer, "jobLevel")) or 1, 1)
	return GARBAGE_BASE_CAPACITY + (level - 1) * GARBAGE_CAPACITY_PER_LEVEL
end

-- ============================================================
-- Trash object tracking
-- ============================================================

local function refreshTrashObjects()
	trashObjects = {}
	-- NOTE: use getElementsByType("object") WITHOUT resourceRoot filter
	-- because the trash objects are created SERVER-side (their parent is root, not our resourceRoot)
	for _, obj in ipairs(getElementsByType("object")) do
		if getElementData(obj, "garbage:trashId") then
			trashObjects[obj] = true
		end
	end
end

-- ============================================================
-- Hologram rendering (3D text above trash)
-- ============================================================

local function drawHologramText(x, y, z, title, subtitle, scale)
	local px, py = getScreenFromWorldPosition(x, y, z + 1.0)
	if not px then return end

	local a = math.floor(math.min(255, 220 * scale))

	-- Title (shadow + text)
	dxDrawText(title, px + 1, py + 1, px + 1, py + 1,
		tocolor(0, 0, 0, a), 2.2 * scale, "default-bold", "center", "bottom")
	dxDrawText(title, px, py, px, py,
		tocolor(235, 235, 235, a), 2.2 * scale, "default-bold", "center", "bottom")

	-- Subtitle
	if subtitle then
		local sa = math.floor(a * 0.85)
		dxDrawText(subtitle, px + 1, py + 1, px + 1, py + 1,
			tocolor(0, 0, 0, sa), 1.6 * scale, "default", "center", "top")
		dxDrawText(subtitle, px, py, px, py,
			tocolor(210, 210, 210, sa), 1.6 * scale, "default", "center", "top")
	end
end

local function renderGarbageHolograms()
	if not garbageActive then return end

	local cx, cy, cz = getCameraMatrix()
	local now = getNow()

	for obj in pairs(trashObjects) do
		if isElement(obj) then
			local x, y, z = getElementPosition(obj)
			local dist = getDistanceBetweenPoints3D(x, y, z, cx, cy, cz)

			if dist <= 25 then
				local scale = 1 - (dist / 25)
				if scale > 0.15 then
					local nextAvail = tonumber(getElementData(obj, "garbage:nextAvailable")) or 0
					if nextAvail <= now then
						drawHologramText(x, y, z, "Garbage", "Press  E  to collect", scale)
					else
						local rem  = nextAvail - now
						local mins = math.floor(rem / 60)
						local secs = rem % 60
						drawHologramText(x, y, z, "Garbage",
							string.format("Cooldown: %02d:%02d", mins, secs), scale)
					end
				end
			end
		else
			-- Stale element — remove from table
			trashObjects[obj] = nil
		end
	end
end

-- ============================================================
-- Vehicle HUD overlay (load/level info)
-- ============================================================

local function renderGarbageOverlay()
	if not garbageActive then return end

	local veh = getPedOccupiedVehicle(localPlayer)
	if not veh or getPedOccupiedVehicleSeat(localPlayer) ~= 0 then return end
	if not isGarbageVehicle(veh) then return end

	local load        = tonumber(getElementData(veh, "garbage:load")) or 0
	local capacity    = getPlayerGarbageCapacity()
	local jobLevel    = tonumber(getElementData(localPlayer, "jobLevel"))    or 1
	local jobProgress = tonumber(getElementData(localPlayer, "jobProgress")) or 0

	local boxW, boxH = 300, 96  -- Increased by 20% from 250x80
	local boxX, boxY = sx - boxW - 20, 200

	dxDrawRectangle(boxX, boxY, boxW, boxH, tocolor(0, 0, 0, 160))
	dxDrawText("Garbage Collector", boxX + 10, boxY + 8, boxX + boxW - 10, boxY + 28,
		tocolor(255, 255, 255, 230), 1.2, "default-bold", "left", "top")
	dxDrawText("Level: " .. jobLevel .. "  |  Progress: " .. jobProgress,
		boxX + 10, boxY + 36, boxX + boxW - 10, boxY + 54,
		tocolor(220, 220, 220, 220), 1.2, "default", "left", "top")
	dxDrawText("Load: " .. load .. " / " .. capacity,
		boxX + 10, boxY + 60, boxX + boxW - 10, boxY + 84,
		tocolor(120, 220, 120, 220), 1.2, "default-bold", "left", "top")
end

-- ============================================================
-- Pickup logic
-- ============================================================

local function findNearestTrash()
	local px, py, pz = getElementPosition(localPlayer)
	local dim = getElementDimension(localPlayer)
	local int = getElementInterior(localPlayer)

	local bestObj  = nil
	local bestDist = GARBAGE_PICKUP_DISTANCE  -- max pickup range

	for obj in pairs(trashObjects) do
		if isElement(obj)
			and getElementDimension(obj) == dim
			and getElementInterior(obj) == int then
			local x, y, z = getElementPosition(obj)
			local dist = getDistanceBetweenPoints3D(px, py, pz, x, y, z)
			if dist < bestDist then
				bestDist = dist
				bestObj  = obj
			end
		end
	end

	return bestObj
end

local function attemptPickup()
	if not garbageActive then return end

	-- Client-side debounce
	local now = getTickCount()
	if (now - lastAttempt) < ATTEMPT_COOLDOWN then return end
	lastAttempt = now

	-- Quick client-side checks (real validation happens server-side)
	if getPedOccupiedVehicle(localPlayer) then return end
	if getElementData(localPlayer, "garbage:carrying") then return end

	local trash = findNearestTrash()
	if not trash then return end

	-- Send to server for authoritative pickup
	triggerServerEvent("garbage:requestPickup", localPlayer, trash)
end

-- ============================================================
-- Job state management
-- ============================================================

local function setGarbageJobActive(active)
	garbageActive = active

	if active then
		refreshTrashObjects()
		if not dumpBlip or not isElement(dumpBlip) then
			-- Bulldozer icon on the map
			dumpBlip = createBlip(
				GARBAGE_DUMP_POSITION.x, GARBAGE_DUMP_POSITION.y, GARBAGE_DUMP_POSITION.z,
				11, 2, 0, 255, 0, 255)
		end
		if not dumpMarker or not isElement(dumpMarker) then
			-- Green circle marker on the ground at the dump location
			dumpMarker = createMarker(
				GARBAGE_DUMP_POSITION.x, GARBAGE_DUMP_POSITION.y, GARBAGE_DUMP_POSITION.z - 1,
				"cylinder", 6.0, 100, 200, 50, 150)
		end
	else
		if isElement(dumpBlip) then
			destroyElement(dumpBlip)
		end
		dumpBlip = nil
		if isElement(dumpMarker) then
			destroyElement(dumpMarker)
		end
		dumpMarker = nil
	end
end

-- Exported functions (called by job-system)
function displayGarbageJob()
	setGarbageJobActive(true)
end

function resetGarbageJob()
	setGarbageJobActive(false)
end

-- ============================================================
-- Render handler
-- ============================================================

addEventHandler("onClientRender", root, function()
	renderGarbageHolograms()
	renderGarbageOverlay()
end)

-- ============================================================
-- Element streaming handlers
-- ============================================================

addEventHandler("onClientResourceStart", resourceRoot, function()
	refreshTrashObjects()
	if (tonumber(getElementData(localPlayer, "job")) or 0) == GARBAGE_JOB_ID then
		setGarbageJobActive(true)
	end
end)

addEventHandler("onClientElementStreamIn", root, function()
	if getElementType(source) == "object" and getElementData(source, "garbage:trashId") then
		trashObjects[source] = true
	end
end)

addEventHandler("onClientElementStreamOut", root, function()
	trashObjects[source] = nil
end)

addEventHandler("onClientElementDestroy", root, function()
	trashObjects[source] = nil
end)

-- Detect job changes on the local player
addEventHandler("onClientElementDataChange", localPlayer, function(dataName)
	if dataName == "job" then
		if (tonumber(getElementData(localPlayer, "job")) or 0) == GARBAGE_JOB_ID then
			setGarbageJobActive(true)
		else
			setGarbageJobActive(false)
		end
	end
end)

-- ============================================================
-- GM / Owner trash movement (right-click → object-mover)
-- ============================================================

addEventHandler("onClientClick", root, function(button, state, _, _, _, _, _, element)
	if button ~= "right" or state ~= "down" then return end
	if not isElement(element) or getElementType(element) ~= "object" then return end
	if not getElementData(element, "garbage:trashId") then return end

	if exports.integration:isPlayerGeneralManager(localPlayer)
		or exports.integration:isPlayerOwner(localPlayer) then
		exports["object-mover"]:startObjectMove(element)
	end
end)

-- ============================================================
-- Carry animation (applied client-side for smooth results)
-- ============================================================

local carryAnimTimer = nil

local function stopCarryAnim()
	if carryAnimTimer and isTimer(carryAnimTimer) then
		killTimer(carryAnimTimer)
	end
	carryAnimTimer = nil
end

addEvent("garbage:startCarryAnim", true)
addEventHandler("garbage:startCarryAnim", localPlayer, function()
	stopCarryAnim()
	setPedAnimation(localPlayer, "CARRY", "crry_prtial", 500, false, false, false, true)
	-- Only re-apply if the player punches (FIGHT animation blocks). Walking/running is allowed.
	carryAnimTimer = setTimer(function()
		if not getElementData(localPlayer, "garbage:carrying") then
			stopCarryAnim()
			return
		end
		local block = getPedAnimation(localPlayer)
		if block and (block == "FIGHT_B" or block == "FIGHT_C" or block == "FIGHT_D" or block == "FIGHT_E") then
			setPedAnimation(localPlayer, "CARRY", "crry_prtial", 500, false, false, false, true)
		end
	end, 500, 0)
end)

-- Stop carry anim when carrying ends
addEventHandler("onClientElementDataChange", localPlayer, function(dataName)
	if dataName == "garbage:carrying" then
		if not getElementData(localPlayer, "garbage:carrying") then
			stopCarryAnim()
		end
	end
end)

-- ============================================================
-- Auto-load: detect when carrying garbage near a Trashmaster
-- ============================================================

local lastLoadAttempt = 0

local function checkNearbyTrashmaster()
	if not garbageActive then return end
	if not getElementData(localPlayer, "garbage:carrying") then return end
	if getElementData(localPlayer, "garbage:loading") then return end
	if getPedOccupiedVehicle(localPlayer) then return end

	local now = getTickCount()
	if (now - lastLoadAttempt) < 2000 then return end

	local px, py, pz = getElementPosition(localPlayer)
	local dim = getElementDimension(localPlayer)
	local int = getElementInterior(localPlayer)

	for _, v in ipairs(getElementsByType("vehicle")) do
		if isGarbageVehicle(v)
			and getElementDimension(v) == dim
			and getElementInterior(v) == int then
			local vx, vy, vz = getElementPosition(v)
			local dist = getDistanceBetweenPoints3D(px, py, pz, vx, vy, vz)
			if dist < 5.0 then
				lastLoadAttempt = now
				triggerServerEvent("garbage:requestLoad", localPlayer)
				return
			end
		end
	end
end

-- Check every 500ms while carrying
setTimer(function()
	if garbageActive and getElementData(localPlayer, "garbage:carrying") then
		checkNearbyTrashmaster()
	end
end, 500, 0)

-- ============================================================
-- Key binding
-- ============================================================

bindKey("e", "down", attemptPickup)

local objects = {}
local oldDimension = nil
local safeToSpawn = true
local dimensionChangeTimer = nil

function fallProtection(intx, inty, intz)
	local x, y, z = getElementPosition(localPlayer)
	local dim = getElementDimension(localPlayer)
	if ((intz - z) > 5 or getPedSimplestTask(localPlayer) == "TASK_SIMPLE_IN_AIR") and getElementData(localPlayer, "loggedin") == 1 and dim ~= 0 and not getElementData(localPlayer, "pd:snakecam") and not getElementData(localPlayer, "freecamTV:state") then
		outputChatBox("Warning: We detected a fall! Teleporting you to the interior entrance...", 0, 255, 0)
		triggerServerEvent("fallProtectionRespawn", root, intx, inty, intz)
	end
end

function isSafeToSpawn()
	if safeToSpawn then
		setElementFrozen(localPlayer, false)
		x, y, z = getElementPosition(localPlayer)
		setTimer(fallProtection, 2000, 1, x, y, z)
	else
		setTimer(isSafeToSpawn, 500, 1)
	end
end

function clearObjectsInDimension(dimension)
	if not objects[dimension] then return end
	for id, object in ipairs(objects[dimension]) do
		if object.object and isElement(object.object) then
			destroyElement(object.object)
			object.object = nil
		end
	end
	objects[dimension] = nil
end

function clearAllDimensionObjects()
	-- Collect keys first to avoid modifying the table during iteration
	local dimensions = {}
	for dimension in pairs(objects) do
		dimensions[#dimensions + 1] = dimension
	end
	for _, dimension in ipairs(dimensions) do
		clearObjectsInDimension(dimension)
	end
end

function streamDimensionIn(dimension)
	for id, data in ipairs(objects[dimension] or {}) do
		-- Clean up any pre-existing object for this entry
		if data.object and isElement(data.object) then
			destroyElement(data.object)
			data.object = nil
		end

		local obj = createObject(data.model, data.x, data.y, data.z, data.rot_x, data.rot_y, data.rot_z)

		if not obj or not isElement(obj) then
			outputDebugString("[OBJECT-SYSTEM] Failed to create object model=" .. tostring(data.model) .. " id=" .. tostring(data.id), 2)
		else
			data.object = obj
			setElementDimension(obj, dimension)
			setElementInterior(obj, data.interior)
			setElementCollisionsEnabled(obj, data.is_solid)
			setElementDoubleSided(obj, data.is_double_sided)
			setElementData(obj, "object:dbid", data.id, false)
			setElementAlpha(obj, data.alpha or 255)

			if data.scale then
				setObjectScale(obj, data.scale)
			end
			
			if data.is_breakable then
				setObjectBreakable(obj, data.is_breakable)
			end
		end
	end

	safeToSpawn = true
end

addEvent("onClientInteriorChange", true)

addEvent("object:sync", true)
addEventHandler("object:sync", root, function (dimensionObjects, dimension)
	clearObjectsInDimension(dimension)
	objects[dimension] = dimensionObjects
	streamDimensionIn(dimension)
end)

addEvent("object:safeTrue", true)
addEventHandler("object:safeTrue", resourceRoot, function ()
	safeToSpawn = true
end)

addEvent("object:clear", true)
addEventHandler("object:clear", root, clearObjectsInDimension)

addEventHandler("onClientPreRender", root, function ()
    local currentDimension = getElementDimension(localPlayer)
    
    if currentDimension == oldDimension then
        return
    end

    -- Debounce rapid dimension changes (e.g. during teleportation)
    -- to prevent mass create/destroy cycles that cause crashes
    if isTimer(dimensionChangeTimer) then
        killTimer(dimensionChangeTimer)
    end

    local newDim = currentDimension
    oldDimension = currentDimension

    dimensionChangeTimer = setTimer(function()
        dimensionChangeTimer = nil

        -- Verify the dimension hasn't changed again during the delay
        local actualDim = getElementDimension(localPlayer)
        if actualDim ~= newDim then
            return
        end

        clearAllDimensionObjects()
        if newDim ~= 0 then
            safeToSpawn = false
            setElementFrozen(localPlayer, true)
            setTimer(isSafeToSpawn, 500, 1)

            if not objects[newDim] then
                triggerServerEvent("object:requestsync", localPlayer, newDim)
            else
                streamDimensionIn(newDim)
            end
        end
        triggerServerEvent("onPlayerInteriorChange", root, getElementInterior(localPlayer), newDim)
    end, 100, 1)
end)

addEventHandler("onClientResourceStart", resourceRoot, function ()
	setTimer(function()
		setOcclusionsEnabled(false) -- to fix the object streaming issue (extreme low draw distance)
	end, 10000, 1)
end)
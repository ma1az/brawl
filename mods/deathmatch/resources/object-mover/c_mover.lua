-- ============================================================
-- Object Mover – Client
-- A reusable furniture-style placement / movement system.
--
-- EXPORTED API:
--   startObjectMove( element [, options] )   – begin editing
--   stopObjectMove()                         – force-stop
--   isMoving()                               – returns bool
--
-- CONTROLS (while editing):
--   W/A/S/D         – Move (camera-relative on XY plane)
--   Q / E           – Move down / up
--   Scroll Wheel    – Rotate Z (yaw)
--   Arrow Up/Down   – Rotate X (pitch)
--   Arrow Left/Right– Rotate Y (roll)
--   Ctrl + Rotate   – Reset that axis to 0
--   Shift + Rotate  – Fast rotate
--   Alt  + Move     – Slow move
--   Shift + Move    – Fast move
--   G               – Toggle snap grid
--   H               – Toggle surface snap
--   F               – Confirm / Save placement
--   Left Click      – Cancel (restore original position)
--   Right Click     – Hold for free camera+character movement
-- ============================================================

local sX, sY = guiGetScreenSize()

-- State --
local movingObject      = nil
local originalPos       = nil   -- {x,y,z,rx,ry,rz}
local realPos           = {x=0, y=0, z=0}
local currentRotX       = 0
local currentRotY       = 0
local currentRotZ       = 0
local activeKeys        = {}
local snapEnabled       = false
local surfaceSnapEnabled= false
local freeLookActive    = false
local lastSyncTick      = 0
local callbackOnSave    = nil
local callbackOnCancel  = nil

-- Fonts --
local font_bold    = "default-bold"
local font_default = "default"

-- ============================================================
-- Internal helpers (defined FIRST so they exist before use)
-- ============================================================

local function isCtrlDown()
	return getKeyState("lctrl") or getKeyState("rctrl")
end

local function restoreControls()
	toggleControl("fire", true)
	toggleControl("aim_weapon", true)
	toggleControl("look_around", true)
	toggleControl("jump", true)
	toggleControl("sprint", true)
	toggleControl("walk", true)
	toggleControl("forwards", true)
	toggleControl("backwards", true)
	toggleControl("left", true)
	toggleControl("right", true)
end

local function lockEditingControls()
	toggleControl("fire", false)
	toggleControl("aim_weapon", false)
	toggleControl("look_around", false)
	toggleControl("jump", false)
	toggleControl("sprint", false)
	toggleControl("walk", false)
end

local function unlockMovementControls()
	toggleControl("forwards", true)
	toggleControl("backwards", true)
	toggleControl("left", true)
	toggleControl("right", true)
	toggleControl("sprint", true)
	toggleControl("walk", true)
	toggleControl("jump", true)
	toggleControl("aim_weapon", true)
	toggleControl("look_around", true)
end

local function syncToServer()
	if not movingObject or not isElement(movingObject) then return end
	local now = getTickCount()
	if now - lastSyncTick < 80 then return end
	lastSyncTick = now
	local x, y, z = getElementPosition(movingObject)
	local rx, ry, rz = getElementRotation(movingObject)
	triggerServerEvent("objectMover:syncPos", localPlayer, movingObject, x, y, z, rx, ry, rz)
end

-- Forward declarations for render/key handlers
local renderLoop
local keyHandler

local function cleanup()
	if not movingObject then return end
	local obj = movingObject
	movingObject = nil

	removeEventHandler("onClientRender", root, renderLoop)
	removeEventHandler("onClientKey",    root, keyHandler)

	if isElement(obj) then
		setElementCollisionsEnabled(obj, true)
		setElementFrozen(obj, true)
	end

	restoreControls()
	freeLookActive = false

	-- Always hide all cursors on exit so the player isn't stuck
	if isCursorShowing() then
		triggerEvent("cursorHide", root)
	end
	showCursor(false)

	activeKeys = {}
	callbackOnSave   = nil
	callbackOnCancel = nil
end

local function confirmPlacement()
	if not movingObject or not isElement(movingObject) then cleanup() return end

	local x, y, z = getElementPosition(movingObject)
	local rx, ry, rz = getElementRotation(movingObject)

	triggerServerEvent("objectMover:saved", localPlayer, movingObject, x, y, z, rx, ry, rz)

	if callbackOnSave then
		callbackOnSave(movingObject, x, y, z, rx, ry, rz)
	end

	local obj = movingObject
	cleanup()
	if isElement(obj) then
		setElementCollisionsEnabled(obj, true)
	end
end

local function cancelPlacement()
	if not movingObject or not isElement(movingObject) then cleanup() return end

	local ox, oy, oz    = originalPos.x, originalPos.y, originalPos.z
	local orx, ory, orz = originalPos.rx, originalPos.ry, originalPos.rz

	setElementPosition(movingObject, ox, oy, oz)
	setElementRotation(movingObject, orx, ory, orz)

	triggerServerEvent("objectMover:cancelled", localPlayer, movingObject, ox, oy, oz, orx, ory, orz)

	if callbackOnCancel then
		callbackOnCancel(movingObject)
	end

	local obj = movingObject
	cleanup()
	if isElement(obj) then
		setElementCollisionsEnabled(obj, true)
	end
end

-- ============================================================
-- HUD overlay
-- ============================================================

local function drawHUD()
	local panelW, panelH = 270, 340
	local panelX = sX - panelW - 20
	local panelY = sY * 0.1

	dxDrawRectangle(panelX, panelY, panelW, panelH, tocolor(0,0,0,180))
	dxDrawText("Object Mover", panelX, panelY + 10, panelX + panelW, panelY + 30,
		tocolor(255,255,255,255), 1, font_bold, "center", "top")

	local controls = {
		{"Move",             "W, A, S, D"},
		{"Up / Down",        "E / Q"},
		{"Rotate Z (Yaw)",   "Scroll"},
		{"Rotate X (Pitch)", "Arrow Up/Down"},
		{"Rotate Y (Roll)",  "Arrow Left/Right"},
		{"Reset Rotation",   "Ctrl + Rotate Key"},
		{"Fast Rotate/Move", "Shift"},
		{"Slow Move",        "Alt"},
		{"Snap Grid ("..(snapEnabled and "On" or "Off")..")", "G"},
		{"Snap Surface ("..(surfaceSnapEnabled and "On" or "Off")..")", "H"},
		{"Confirm Place",    "F"},
		{"Cancel",           "Left Click"},
		{"Free Look/Walk",   "Hold Right Click"},
	}

	for i, c in ipairs(controls) do
		local y = panelY + 40 + (i-1) * 22
		dxDrawText(c[1], panelX + 10, y, panelX + panelW, y + 20,
			tocolor(200,200,200,255), 1, font_default, "left", "top")
		dxDrawText(c[2], panelX, y, panelX + panelW - 10, y + 20,
			tocolor(255,255,255,255), 1, font_default, "right", "top")
	end
end

-- ============================================================
-- Render loop
-- ============================================================

renderLoop = function()
	if not movingObject or not isElement(movingObject) then cleanup() return end

	-- ---- Free-look: track mouse2 state every frame (like 3DEditor) ----
	local mouse2Down = getKeyState("mouse2")
	if mouse2Down and not freeLookActive then
		-- Right click pressed: hide the M-key cursor and enable free movement
		freeLookActive = true
		if isCursorShowing() then
			triggerEvent("cursorHide", root)
		end
		showCursor(false)
		unlockMovementControls()
	elseif not mouse2Down and freeLookActive then
		-- Right click released: restore the M-key cursor and lock controls
		freeLookActive = false
		triggerEvent("cursorShow", root)
		lockEditingControls()
	end

	-- While free-looking, skip object movement but still draw HUD
	if freeLookActive then
		drawHUD()
		return
	end

	-- ---- Movement ----
	local moveSpeed = 0.05
	if activeKeys["lshift"] then moveSpeed = 0.1 end
	if activeKeys["lalt"]   then moveSpeed = 0.01 end

	local camX, camY, camZ, camTX, camTY, camTZ = getCameraMatrix()
	local vecX = camTX - camX
	local vecY = camTY - camY
	local vecLen = math.sqrt(vecX*vecX + vecY*vecY)

	if vecLen > 0 then
		vecX = vecX / vecLen
		vecY = vecY / vecLen

		local moved = false

		if activeKeys["w"] then
			realPos.x = realPos.x + vecX * moveSpeed
			realPos.y = realPos.y + vecY * moveSpeed
			moved = true
		end
		if activeKeys["s"] then
			realPos.x = realPos.x - vecX * moveSpeed
			realPos.y = realPos.y - vecY * moveSpeed
			moved = true
		end

		local rightX =  vecY
		local rightY = -vecX

		if activeKeys["d"] then
			realPos.x = realPos.x + rightX * moveSpeed
			realPos.y = realPos.y + rightY * moveSpeed
			moved = true
		end
		if activeKeys["a"] then
			realPos.x = realPos.x - rightX * moveSpeed
			realPos.y = realPos.y - rightY * moveSpeed
			moved = true
		end

		-- Vertical
		if activeKeys["e"] then realPos.z = realPos.z + moveSpeed; moved = true end
		if activeKeys["q"] then realPos.z = realPos.z - moveSpeed; moved = true end

		-- ---- Apply snapping ----
		local finalX, finalY, finalZ = realPos.x, realPos.y, realPos.z

		if snapEnabled then
			local step = 0.1
			finalX = math.floor(finalX / step + 0.5) * step
			finalY = math.floor(finalY / step + 0.5) * step
			finalZ = math.floor(finalZ / step + 0.5) * step
		end

		if surfaceSnapEnabled then
			local hit, hX, hY, hZ = processLineOfSight(
				finalX, finalY, finalZ + 2,
				finalX, finalY, finalZ - 100,
				true, true, false, true, true, false, false, false, movingObject)
			if hit then
				local distToBase = getElementDistanceFromCentreOfMassToBaseOfModel(movingObject) or 0
				finalZ = hZ + distToBase
			end
		end

		setElementPosition(movingObject, finalX, finalY, finalZ)
		setElementRotation(movingObject, currentRotX, currentRotY, currentRotZ)

		if moved then syncToServer() end
	end

	-- ---- Arrow key rotation (pitch X / roll Y) ----
	local rotSpeed = 1
	if activeKeys["lshift"] then rotSpeed = 5 end
	if activeKeys["lalt"]   then rotSpeed = 0.2 end
	if snapEnabled then rotSpeed = 45 end

	local rotChanged = false

	if activeKeys["arrow_u"] then
		currentRotX = currentRotX + rotSpeed
		rotChanged = true
	end
	if activeKeys["arrow_d"] then
		currentRotX = currentRotX - rotSpeed
		rotChanged = true
	end
	if activeKeys["arrow_l"] then
		currentRotY = currentRotY + rotSpeed
		rotChanged = true
	end
	if activeKeys["arrow_r"] then
		currentRotY = currentRotY - rotSpeed
		rotChanged = true
	end

	if rotChanged then
		setElementRotation(movingObject, currentRotX, currentRotY, currentRotZ)
		syncToServer()
	end

	-- ---- Visual grid ----
	if snapEnabled then
		local gx, gy, gz = getElementPosition(movingObject)
		local gridSize = 5
		local step = 1.0
		local startX = math.floor(gx/step)*step - math.floor(gridSize/2)*step
		local startY = math.floor(gy/step)*step - math.floor(gridSize/2)*step
		for i = 0, gridSize do
			local lx = startX + i * step
			dxDrawLine3D(lx, startY, gz, lx, startY + gridSize * step, gz, tocolor(255,255,255,100), 1)
			local ly = startY + i * step
			dxDrawLine3D(startX, ly, gz, startX + gridSize * step, ly, gz, tocolor(255,255,255,100), 1)
		end
	end

	-- Force input to game (not GUI)
	guiSetInputEnabled(false)

	drawHUD()
end

-- ============================================================
-- Key handler
-- ============================================================

keyHandler = function(key, state)
	if not movingObject then return end

	-- During free-look, block M key so cursor doesn't pop back
	if key == "m" and freeLookActive then
		cancelEvent()
		return
	end

	local ctrlDown = isCtrlDown()

	-- Track movement modifier keys
	if key == "w" or key == "a" or key == "s" or key == "d"
		or key == "q" or key == "e"
		or key == "lalt" or key == "lshift" then
		activeKeys[key] = state
	end

	-- Ctrl + arrow resets the corresponding rotation axis to 0
	if (key == "arrow_u" or key == "arrow_d") and state and ctrlDown then
		currentRotX = 0
		setElementRotation(movingObject, currentRotX, currentRotY, currentRotZ)
		syncToServer()
		return
	end
	if (key == "arrow_l" or key == "arrow_r") and state and ctrlDown then
		currentRotY = 0
		setElementRotation(movingObject, currentRotX, currentRotY, currentRotZ)
		syncToServer()
		return
	end

	-- Track arrow keys for rotation
	if key == "arrow_u" or key == "arrow_d" or key == "arrow_l" or key == "arrow_r" then
		activeKeys[key] = state
	end

	-- Block player walking while editing (unless free-looking)
	if not freeLookActive then
		if (key == "w" or key == "a" or key == "s" or key == "d" or key == "space") and state then
			cancelEvent()
		end
	end

	-- ---- Toggle snaps ----
	if key == "g" and state then
		snapEnabled = not snapEnabled
	end
	if key == "h" and state then
		surfaceSnapEnabled = not surfaceSnapEnabled
	end

	-- ---- Rotation Z via scroll wheel ----
	if key == "mouse_wheel_up" and state then
		if ctrlDown then
			currentRotZ = 0
		else
			local plus = 1
			if activeKeys["lshift"] then plus = 5 end
			if snapEnabled then plus = 45 end
			currentRotZ = currentRotZ + plus
		end
		setElementRotation(movingObject, currentRotX, currentRotY, currentRotZ)
		syncToServer()
	end
	if key == "mouse_wheel_down" and state then
		if ctrlDown then
			currentRotZ = 0
		else
			local plus = 1
			if activeKeys["lshift"] then plus = 5 end
			if snapEnabled then plus = 45 end
			currentRotZ = currentRotZ - plus
		end
		setElementRotation(movingObject, currentRotX, currentRotY, currentRotZ)
		syncToServer()
	end

	-- ---- Confirm (F) ----
	if key == "f" and state then
		confirmPlacement()
		cancelEvent()
		return
	end

	-- ---- Cancel (Left Click) ----
	if key == "mouse1" and state then
		cancelPlacement()
		cancelEvent()
		return
	end

	-- Sync position on key release
	if not state then
		if key == "w" or key == "a" or key == "s" or key == "d" or key == "q" or key == "e" then
			syncToServer()
		end
		if key == "arrow_u" or key == "arrow_d" or key == "arrow_l" or key == "arrow_r" then
			syncToServer()
		end
	end
end

-- ============================================================
-- Public API (defined AFTER helpers so all references resolve)
-- ============================================================

function startObjectMove(object, options)
	if not isElement(object) or getElementType(object) ~= "object" then return false end
	if movingObject then stopObjectMove() end

	options = options or {}

	movingObject = object
	local x, y, z = getElementPosition(object)
	local rx, ry, rz = getElementRotation(object)
	originalPos = {x=x, y=y, z=z, rx=rx, ry=ry, rz=rz}
	realPos     = {x=x, y=y, z=z}
	currentRotX = rx
	currentRotY = ry
	currentRotZ = rz

	snapEnabled       = options.snapGrid    or false
	surfaceSnapEnabled= options.surfaceSnap or false
	callbackOnSave    = options.onSave
	callbackOnCancel  = options.onCancel

	activeKeys     = {}
	freeLookActive = false

	setElementCollisionsEnabled(object, false)
	setElementFrozen(object, true)

	-- Lock controls for editing
	lockEditingControls()

	-- Hide the M-key cursor by telling the account resource to cancel its own cursor
	-- (MTA cursor is per-resource, so we must ask the account resource to hide its own)
	if isCursorShowing() then
		triggerEvent("cursorHide", root)
	end
	showCursor(false)

	addEventHandler("onClientRender", root, renderLoop)
	addEventHandler("onClientKey",    root, keyHandler)

	-- Notify the player
	if not options.silent then
		outputChatBox("Object Mover: Use WASD to move, Scroll to rotate, F to save, Left Click to cancel.", 255, 255, 255)
		outputChatBox("Object Mover: Arrow keys for pitch/roll. Hold Right Click for free movement.", 200, 200, 200)
	end

	return true
end

function stopObjectMove()
	cleanup()
end

function isMoving()
	return movingObject ~= nil
end

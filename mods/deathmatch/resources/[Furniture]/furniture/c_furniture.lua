-- Configuration for disabling default interior furniture
-- Note: 'roomID' usually corresponds to the main Interior ID (e.g., 3 for varied houses), but strictly refers to the Room ID parameter of setInteriorFurnitureEnabled.
local disabledFurnitureRooms = {
    [2] = true,
    [3] = true,
    [4] = true,
    -- Add more room IDs here as needed, e.g.:
    -- [5] = true,
}

addEventHandler("onClientResourceStart", resourceRoot, function()
    for roomID, _ in pairs(disabledFurnitureRooms) do
        local result = setInteriorFurnitureEnabled(roomID, false)
        outputConsole("Furniture: Disable Room ID " .. tostring(roomID) .. " = " .. tostring(result))
    end
end)

-- Debug command to test specific room IDs live
addCommandHandler("togglefurn", function(cmd, id)
    local roomID = tonumber(id)
    if roomID then
        local result = setInteriorFurnitureEnabled(roomID, false)
        outputChatBox("Furniture: Disabled Room ID " .. roomID .. " (Result: " .. tostring(result) .. ")", 255, 255, 0)
    else
        outputChatBox("Syntax: /togglefurn [RoomID]", 255, 0, 0)
    end
end)


Furnitures = {}
local activeKeys = {}
local hifiBoxes = {}
local sX, sY = guiGetScreenSize()
local lastClick = 0
local showEditInterface = false
local show_hifi = false
local selectedFurniture = nil
local selectedHifi = nil
local realPos = {x=0, y=0, z=0}
local snapEnabled = false
local surfaceSnapEnabled = false

local font_bold = dxCreateFont("files/1.ttf",11)
local font_default = dxCreateFont("files/2.ttf",8)
local fontA = dxCreateFont("files/5.ttf",9)
local actions = {
	{" Arrange Furniture", false, "Furnitures.editFurniture()"},
	{" Remove Furniture", false, "Furnitures.pickUpFurniture()"},
	{" Close Menu",false,"Furnitures.closeMenu()"}
}
local lastClick = 0
local hifiAnim = "+"
local hifiYoffset = 0
local hifiXoffset = 0
local hifiZoffset = {}
local showHifiIcon = true
local hifiImages = {}
local img = dxCreateTexture("files/hifinote.png")
local hifiStoreTable = {}
local white = tocolor(255,255,255,255)
function dxDrawImage3D(x,y,z,w,h,m,c,r,...)
        local lx, ly, lz = x+w, y+h, (z+tonumber(r or 0)) or z
	return dxDrawMaterialLine3D(x,y,z, lx, ly, lz, m, h, c or white, ...)
end
local font3 = dxCreateFont("files/5.ttf",12)
function Furnitures.draw()
	if getElementData(localPlayer, "Furniture->isFurnitureOnHand") and selectedFurniture then
		-- New UI Overlay
		local panelW, panelH = 250, 250
		local panelX = sX - panelW - 20
		local panelY = sY * 0.1 -- Moved down 10%
		
		dxDrawRectangle(panelX, panelY, panelW, panelH, tocolor(0, 0, 0, 180))
		dxDrawText("Controls", panelX, panelY + 10, panelX + panelW, panelY + 30, tocolor(255, 255, 255, 255), 1, font_bold, "center", "top")
        
		
		-- X Close Button on Overlay REMOVED (Now in Editor Menu)
		-- dxDrawText("X", panelX + panelW - 25, panelY + 5, panelX + panelW - 5, panelY + 25, tocolor(255, 100, 100, 200), 1, font_bold, "center", "center")
		
		local controls = {
			{"Move", "W, A, S, D"},
			{"Up / Down", "E / Q"},
			{"Rotate", "Scroll"},
			{"Fast Rotate", "Shift + Scroll"},
			{"Slow Move", "Alt + Move"},
			{"Snap Grid ("..(snapEnabled and "On" or "Off")..")", "G"},
			{"Snap Surface ("..(surfaceSnapEnabled and "On" or "Off")..")", "H"},
			{"Place", "F"},
			{"Cancel", "Right Click"}
		}
		
		-- Debug Info storage
		local debugVecLen = 0
		
		for i, control in ipairs(controls) do
			local y = panelY + 40 + (i-1) * 22
			dxDrawText(control[1], panelX + 10, y, panelX + panelW, y + 20, tocolor(200, 200, 200, 255), 1, font_default, "left", "top")
			dxDrawText(control[2], panelX, y, panelX + panelW - 10, y + 20, tocolor(255, 255, 255, 255), 1, font_default, "right", "top")
		end
		
		-- Force Input to Game
		guiSetInputEnabled(false)
		
		if moveHandle then
		local screenx, screeny, worldx, worldy, worldz = getCursorPosition()
        local px, py, pz = getCameraMatrix()
        local hit, x, y, z, elementHit = processLineOfSight ( px, py, pz, worldx, worldy, worldz )
			if lastClick+50 <= getTickCount() then
				lastClick = getTickCount()
				--setElementPosition(selectedFurniture,x,y,z)
				triggerServerEvent("Furnitures->setPos",localPlayer,localPlayer,selectedFurniture,{x,y,z,Furnitures.getRotation()})
			end
		end
		
	end
	
	hifiXoffset = 0
	
	dim2 = getElementDimension(localPlayer)
	dim2 = tonumber(dim2)
	int2 = getElementInterior(localPlayer)
	int2 = tonumber(int2)
	

	if not selectedFurniture then return end



    -- Visual Grid
    if snapEnabled then
        local gx, gy, gz = getElementPosition(selectedFurniture)
        local gridSize = 5
        local step = 1.0
        local startX, startY = math.floor(gx/step)*step - math.floor(gridSize/2)*step, math.floor(gy/step)*step - math.floor(gridSize/2)*step
        
        for i = 0, gridSize do
            -- Vertical lines
            local lx = startX + i * step
            dxDrawLine3D(lx, startY, gz, lx, startY + gridSize * step, gz, tocolor(255, 255, 255, 100), 1)
            -- Horizontal lines
            local ly = startY + i * step
            dxDrawLine3D(startX, ly, gz, startX + gridSize * step, ly, gz, tocolor(255, 255, 255, 100), 1)
        end
    end

	-- New Movement Logic
	local moveSpeed = 0.05
	if activeKeys["lshift"] then moveSpeed = 0.1 end
	if activeKeys["lalt"] then moveSpeed = 0.01 end

	local x, y, z = getElementPosition(selectedFurniture)
    -- Use realPos for accumulation if not initialized
    if realPos.x == 0 and realPos.y == 0 and realPos.z == 0 then
        realPos = {x=x, y=y, z=z}
    end

	local camX, camY, camZ, camTX, camTY, camTZ = getCameraMatrix()
	
	-- Calculate forward vector on XY plane
	local vecX = camTX - camX
	local vecY = camTY - camY
	-- Normalize
	local vecLen = math.sqrt(vecX*vecX + vecY*vecY)
	
	-- Safety check for NaN
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
		
		local rightX = vecY
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
		
		-- Vertical Movement
		if activeKeys["e"] then
			realPos.z = realPos.z + moveSpeed
			moved = true
		end
		if activeKeys["q"] then
			realPos.z = realPos.z - moveSpeed
			moved = true
		end
        
        -- Force update if snap keys are pressed (implicit update)
        -- We handle this by checking if we are in edit mode
        if getElementData(localPlayer, "Furniture->isFurnitureOnHand") then
             -- Always calculate position to allow G/H toggle to update immediately
            local finalX, finalY, finalZ = realPos.x, realPos.y, realPos.z
            
            if snapEnabled then
                local step = 0.1
                finalX = math.floor(finalX / step + 0.5) * step
                finalY = math.floor(finalY / step + 0.5) * step
                finalZ = math.floor(finalZ / step + 0.5) * step
            end

            if surfaceSnapEnabled then
                -- Raycast down to find floor (Start higher, scan deeper)
                -- Corrected arguments: startX, startY, startZ, endX, endY, endZ, checkBuildings, checkVehicles, checkPeds, checkObjects, checkDummies, seeThroughStuff, ignoreSomeObjectForCamera, ignoredElement
                local hit, hX, hY, hZ = processLineOfSight(finalX, finalY, finalZ + 2, finalX, finalY, finalZ - 100, true, true, false, true, true, false, false, selectedFurniture)
                if hit then
                     -- Get distance from center to base to place it ON the floor
                    local distToBase = getElementDistanceFromCentreOfMassToBaseOfModel(selectedFurniture) or 0
                    finalZ = hZ + distToBase
                end
            end

			setElementPosition(selectedFurniture, finalX, finalY, finalZ)
        end
	end

	--
	if not showEditInterface then return end
	
	local x, y, z = getElementPosition(selectedFurniture)
	local wX, wY = getScreenFromWorldPosition(x, y, z)
	if wX and wY and (getDistanceFromElement(localPlayer, selectedFurniture) < 4 or getElementData(localPlayer, "Furniture->isFurnitureOnHand")) then
        dxDrawRectangle(wX - 170/2, wY - 150/2, 170, 110, tocolor(0, 0, 0, 120))
        dxDrawRectangle(wX - 170/2, wY - 150/2, 170, 20, tocolor(0, 0, 0, 170))
        dxDrawRectangle(wX - 170/2, wY - 150/2+20, 170, 2, tocolor(unpack(color["rgb"])))
        for i = 0, #actions - 1 do
            dxDrawRectangle(wX - 170/2, wY - 150/2 + i * 24 + 26, 170, 20, tocolor(0, 0, 0, 120))
    
            dxDrawText(actions[i + 1][1], wX - 170/2+5, wY - 150/2 + i * 24 + 24, 170 + wX - 170/2+5, 20 + wY - 150/2 + i * 24 + 26, tocolor(255, 255, 255, 255), 1, fontA, "left", "center", false ,false, false, true)
            dxDrawText("Furniture Management",wX - 170/2, wY - 150/2, 170 + wX - 170/2, 20 + wY - 150/2,tocolor(255,255,255,255),1,font_bold,"center","center",false,false,true,true)
            -- X Close Button removed from here (moved to overlay)
        end	
	elseif not (getElementData(localPlayer, "Furniture->isFurnitureOnHand")) then
        -- Only close if NOT in edit mode. If in edit mode, keep open even if far/offscreen (logic handled by wX check preventing draw, but not closing state)
		setElementData(selectedFurniture, "Furniture->used", false)
		selectedFurniture = nil
		showEditInterface = false
	end
end
addEventHandler("onClientRender", root, Furnitures.draw)

function nearByID()
	dim,int = tonumber(getElementDimension(localPlayer)), tonumber(getElementInterior(localPlayer))
	for k,v in ipairs(getElementsByType("object")) do
		dim2,int2 = tonumber(getElementDimension(v)), tonumber(getElementInterior(v))
		if (dim2 == dim) and (int2 == int) and tonumber(getElementModel(v)) == 2100 then
			return getElementData(v,"dbid")
		else
			return 0
		end
	end
end
function Furnitures.editFurniture()
	local data = {}
	--setElementAlpha(localPlayer,255)
	--setFreecamDisabled()
	--setCameraTarget(localPlayer)
	triggerServerEvent("Furnitures->attachFurniture", localPlayer, localPlayer, selectedFurniture, data)
	showEditInterface = false -- Reverted: Menu hides when arranging
    triggerEvent("Furnitures->ForceEditorState", localPlayer, true) -- Open Editor Menu
end
function Furnitures.closeMenu()
		setElementData(selectedFurniture, "Furniture->used", false)
		selectedFurniture = nil
		showEditInterface = false
end

function Furnitures.pickUpFurniture()
	if #myFurnitures + 1 > 10 then 
		outputChatBox("You cannot place more of this object!",255,0,0)
		return
	end
	if showed_myFurnitures then
		myFurnitures = {}
		load_my_furnitures()
	end
	triggerServerEvent("Furnitures->destroyFurniture", localPlayer, localPlayer, selectedFurniture)
	selectedFurniture = nil
	showEditInterface = false
end

function Furnitures.openHifi()
	showEditInterface = false
	show_hifi = true
end
local hifi_scroll = 0
local selectedHifiKey = 0
local maxHifiShow = 9
local font1 = dxCreateFont("files/5.ttf",9.7)
function Furnitures.drawHifi()
	if not show_hifi or not selectedHifi then return end
	dxDrawRectangle(sX/2 - 400/2-4, sY/2 - 170/2-6-4, 400+8, 186+8, tocolor(0, 0, 0, 120))
	dxDrawRectangle(sX/2 - 400/2, sY/2 - 170/2-6, 400, 186, tocolor(10,10,10,150))
	baslik = color["hex"].."Brawl#ffffff HI-FI"
	dxDrawRectangle(sX/2 - 400/2, sY/2 - 170/2-6, dxGetTextWidth(baslik,0.97,font1)+20, 20, tocolor(10,10,10,150))
	dxDrawText(baslik,sX/2 - 400/2+4, sY/2 - 170/2-6, dxGetTextWidth(baslik,0.97,font1)+24, 20+(sY/2 - 170/2-6),tocolor(255,255,255),1,font1,"left","center",false,false,false,true)
	dxDrawRectangle(sX/2 - 400/2, sY/2 - 170/2-6+19, dxGetTextWidth(baslik,1,font1)+20, 1, tocolor(unpack(color["rgb"])))
	
	if selectedHifiKey > 0 then
		dxDrawText("Current Channel: "..color["hex"]..radio_channels[selectedHifiKey][1] or "n/a",sX/2 - 400/2+4, sY/2 - 170/2-6+25, dxGetTextWidth(baslik,0.97,font1)+24, 20+(sY/2 - 170/2-6+25),tocolor(255,255,255),1,font1,"left","top",false,false,false,true)
	else
		dxDrawText("field channel: "..color["hex"].."n/a",sX/2 - 400/2+4, sY/2 - 170/2-6+25, dxGetTextWidth(baslik,0.97,font1)+24, 20+(sY/2 - 170/2-6+25),tocolor(255,255,255),1,font1,"left","top",false,false,false,true)
	end
	-- Channel List
	dxDrawRectangle(sX/2 - 400/2 + 396-150, sY/2 - 170/2, 150, 170, tocolor(0, 0, 0, 120))
	local line = 0
	for k, v in ipairs(radio_channels) do
		line = line + 1
		if (k > hifi_scroll and line < maxHifiShow) then
			dxDrawRectangle(sX/2 - 400/2 + 396-150, sY/2 - 170/2 + (k-1) * 22, 150, 20, tocolor(0, 0, 0, 120))
			if selectedHifiKey == k then
				dxDrawText(v[1],sX/2 - 400/2 + 396-150, sY/2 - 170/2 + (k-1) * 22, 150 + sX/2 - 400/2 + 396-150, 20 + sY/2 - 170/2 + (k-1) * 22,tocolor(unpack(color["rgb"])),1,font_default,"center","center",false,false,true,true)
			else
				dxDrawText(v[1],sX/2 - 400/2 + 396-150, sY/2 - 170/2 + (k-1) * 22, 150 + sX/2 - 400/2 + 396-150, 20 + sY/2 - 170/2 + (k-1) * 22,tocolor(255,255,255,255),1,font_default,"center","center",false,false,true,true)
			end
		end
	end
	
	drawButton("Turn Off Sound",sX/2 - 400/2, sY/2 - 170/2 + 100,150,20,"#eb4d4baa",false, false, false, nil, true)
	drawButton("Close Panel",sX/2 - 400/2, sY/2 - 170/2 + 125,150,20,"#74b9ffaa",false, false, false, nil, true)
	--dxDrawRectangle(sX/2 - 400/2, sY/2 - 170/2 + 100, dxGetTextWidth("Mute the sound       ",1,font_bold)+5, 20, tocolor(255, 0, 0, 120)) -- Stop
	--dxDrawText("Sesi Kapat",sX/2 - 400/2+5, sY/2 - 170/2 + 100, dxGetTextWidth("Sesi Kapat",1,font_bold)+5, 20,tocolor(255,255,255),1,font_bold,"left","top")

	--dxDrawRectangle(sX/2 - 400/2, sY/2 - 170/2 + 100+25, dxGetTextWidth("Sesi Kapat       ",1,font_bold)+5, 20, tocolor(0, 0, 255, 120)) -- Stop
	--dxDrawText("Paneli Kapat",sX/2 - 400/2+5, sY/2 - 170/2 + 100+25, dxGetTextWidth("Sesi Kapat",1,font_bold)+5, 25,tocolor(255,255,255),1,font_bold,"left","top")

	--[[
	local row = 0
	for k, v in ipairs(getElementsByType("object")) do
		if tonumber(getElementDimension(v)) == tonumber(getElementDimension(localPlayer)) and tonumber(getElementModel(v)) == 2100 then
			row = row + 1
			local distance = getDistanceFromElement(selectedHifi, v)
			if distance/30 < 1 then
				local color = tocolor(255, 255, 255, 120)
				if distance/30 <= 0.6 then
					color = tocolor(138, 218, 140, 120)
				else
					color = tocolor(205, 55, 55, 120)
				end
				dxDrawRectangle(sX/2 - 400/2 + 20, sY/2 - 170/2 + (row - 1) * 22 + 20, 170, 20, tocolor(0, 0, 0, 120))
				dxDrawRectangle(sX/2 - 400/2 + 20, sY/2 - 170/2 + (row - 1) * 22 + 20, distance/30 * 170, 20, color)
				dxDrawText("Channel: #"..row,sX/2 - 400/2 + 20, sY/2 - 170/2 + (row - 1) * 22 + 20, 170 + sX/2 - 400/2 + 20, 20 + sY/2 - 170/2 + (row - 1) * 22 + 20,tocolor(255,255,255,255),1,font_default,"center","center",false,false,true,true)
			end
		end
	end
	]]
end
addEventHandler("onClientRender", root, Furnitures.drawHifi)


function Furnitures.click(button, state, _, _, _, _, _, element)
	if button == "right" and state == "down" then
		if element and isElement(element) then
			if getElementData(element, "Furnitures->isFurniture") then
				 if getElementData(element, "Furnitures->owner") == getElementData(localPlayer, "dbid") then
					showEditInterface = true
					if #actions == 4 then
						table.remove(actions, 4)
					end
					if getElementModel(element) == 2100 then
					
						selectedHifi = element
						table.insert(actions, {" Hifi Management", false, "Furnitures.openHifi()"})
					elseif getElementModel(element) == 2482 then
						selectedObject = element
						table.insert(actions, {"Shelf Management", false, "Furnitures.openWeaponController()"})
					end
					selectedFurniture = element
                    local rx, ry, rz = getElementPosition(selectedFurniture)
                    realPos = {x=rx, y=ry, z=rz} -- Init Real Pos
					setElementData(selectedFurniture, "Furniture->used", true)
					myFurnitures = {}
					load_my_furnitures()
				 end
			end
		end
	end
	if getElementData(localPlayer, "Furniture->isFurnitureOnHand") then
		if button == "left" and state == "down" and selectedFurniture then
            -- Overlay X button check REMOVED (Handled by Editor Menu)
            -- if isInBox(panelX + panelW - 25, panelY + 5, 20, 20) then
            --     local _x, _y, _z = getElementPosition(selectedFurniture)
            --     local _, _, _rot = getElementRotation(selectedFurniture)
            --     local _int, _dim = getElementInterior(selectedFurniture),getElementDimension(selectedFurniture)
            --     triggerServerEvent("Furnitures->drop", localPlayer, localPlayer, selectedFurniture, _x,_y,_z,_int,_dim,_rot)
            --     setElementData(selectedFurniture, "Furniture->used", false)
            --     setElementData(localPlayer, "Furniture->isFurnitureOnHand", false)
            --     selectedFurniture = nil
            --     activeKeys = {}
            --     return
            -- end

			moveHandle = true
			return
			
		elseif button == "left" and state == "up" then
			moveHandle = false
			
			return
		elseif button == "right" and state == "down" and selectedFurniture then
			-- Logic from 'F' key to Finish/Drop
			local _x, _y, _z = getElementPosition(selectedFurniture)
			local _, _, _rot = getElementRotation(selectedFurniture)
			local _int, _dim = getElementInterior(selectedFurniture),getElementDimension(selectedFurniture)
			triggerServerEvent("Furnitures->drop", localPlayer, localPlayer, selectedFurniture, _x,_y,_z,_int,_dim,_rot)
			setElementData(selectedFurniture, "Furniture->used", false)
			setElementData(localPlayer, "Furniture->isFurnitureOnHand", false)
			selectedFurniture = nil
			activeKeys = {}
			return
		end
	end
	if button == "left" and state == "down" and showEditInterface then
		if not isElement(selectedFurniture) then
            showEditInterface = false
            return
        end
        local x, y, z = getElementPosition(selectedFurniture)
        if not x then return end
		local wX, wY = getScreenFromWorldPosition(x, y, z)
        if not wX or not wY then return end -- Guard against off-screen clicks
        
		for i = 0, #actions - 1 do
			if isInBox(wX - 170/2, wY - 150/2 + i * 24 + 26, 170, 20) then
				loadstring(actions[i + 1][3])()
				return
			end
        end	
	
	end
	if button == "left" and state == "down" and show_hifi and selectedHifi then
		if isInBox(sX/2 - 400/2, sY/2 - 170/2 + 100, dxGetTextWidth("Turn off the sound      ",1,font_bold)+5, 20) then -- Stop
			local data = getElementData(selectedHifi, "Furnitures->Hifi")
			if tonumber(data.state) == 0 then 
				outputChatBox("Hi-fi is already off.",255,0,0)
				return
			end
			selectedHifiKey = 0
			for k, v in ipairs(getElementsByType("object")) do
				if tonumber(getElementDimension(v)) == tonumber(getElementDimension(localPlayer)) and tonumber(getElementModel(v)) == 2100 then
					local data = {id = k}
					triggerServerEvent("Furnitures->removeSound", localPlayer, localPlayer, data, selectedHifi)
				end
			end
			setElementData(selectedHifi, "Furnitures->Hifi", {channel = 1, state = 0})
			return
		end
		if isInBox(sX/2 - 400/2, sY/2 - 170/2 + 100+25, dxGetTextWidth("Close Menu       ",1,font_bold)+5, 20) then
		
			show_hifi = false
			return
		end
		for k, v in ipairs(radio_channels) do

			if isInBox(sX/2 - 400/2 + 396-150, sY/2 - 170/2 + (k-1) * 22, 150, 20) then
				selectedHifiKey = k
				for k, v in ipairs(getElementsByType("object")) do
					if tonumber(getElementDimension(v)) == tonumber(getElementDimension(localPlayer)) and tonumber(getElementModel(v)) == 2100 then
						local x, y, z = getElementPosition(v)
						triggerServerEvent("Furnitures->removeSound", localPlayer, localPlayer, {id = k})
						--
					
						local distance = getDistanceFromElement(selectedHifi, v)
						local data = {id = k, x, y, z, getElementDimension(v), getElementInterior(v), distance, k, tonumber(getElementData(selectedHifi, "Furnitures->Hifi").channel)}
				
						triggerServerEvent("Furnitures->playSound",	localPlayer, localPlayer, data, selectedHifi)
					end
				end
				setElementData(selectedHifi, "Furnitures->Hifi", {channel = k, state = 1})
			end
		end
	end
end
addEventHandler("onClientClick", root, Furnitures.click)


local soundBoxes = {}
local hifiState = {}
addEvent("Furnitures->playSoundC", true)
addEventHandler("Furnitures->playSoundC", root, function(data,object)
	local sound = playSound3D(tostring(radio_channels[data[8]][2]), data[1], data[2], data[3])
	if sound then

	end
	setElementDimension(sound, data[4])
	setElementInterior(sound, data[5])

	soundBoxes[data[7]] = sound
	x,y,z = getElementPosition(object)
	
	table.insert(hifiBoxes,{data.id,{x,y,z}})
	hifiState[data.id] = true

end)

addEvent("Furnitures->removeSoundC", true)
addEventHandler("Furnitures->removeSoundC", root, function(data,object)
	local key = tonumber(data.id)
	if isElement(soundBoxes[key]) then destroyElement(soundBoxes[key]) end
	
	table.remove(hifiBoxes,key)
	hifiState[data.id] = false
end)
function disableArrows(key,state)
	if selectedFurniture then
		if key == "arrow_r" or key == "arrow_l" or key == "arrow_u" or key == "arrow_d" then
			cancelEvent()
		end
	end
end
addEventHandler("onClientKey",root,disableArrows)

function Furnitures.onKey(key, state)
	if getElementData(localPlayer, "Furniture->isFurnitureOnHand") then
		-- Track movement keys manually to ensure they work even if getKeyState fails
		if key == "w" or key == "a" or key == "s" or key == "d" or key == "q" or key == "e" or key == "lalt" or key == "lshift" then
			activeKeys[key] = state
		end
		
		-- Prevent player movement while editing furniture
		if (key == "w" or key == "a" or key == "s" or key == "d" or key == "space") and state then
			cancelEvent()
		end
	end

	-- Sync on key release to prevent lag/twitching
	if not state and getElementData(localPlayer, "Furniture->isFurnitureOnHand") and selectedFurniture then
		if key == "w" or key == "a" or key == "s" or key == "d" or key == "q" or key == "e" then
			local x, y, z = getElementPosition(selectedFurniture)
            local _, _, rot = getElementRotation(selectedFurniture)
			triggerServerEvent("Furnitures->setPos", localPlayer, localPlayer, selectedFurniture, {x, y, z, rot})
		end
	end

    if key == "g" and state then
        snapEnabled = not snapEnabled
    end
    if key == "h" and state then
        surfaceSnapEnabled = not surfaceSnapEnabled
    end

	if show_hifi then
		if key == "mouse_wheel_down" or key == "pgdn" then
			if hifi_scroll < #radio_channels - maxHifiShow then
				hifi_scroll = hifi_scroll + 1		
			end
		end
		if key == "mouse_wheel_up" or key == "pgup" then
			if hifi_scroll > 0 then
				hifi_scroll = hifi_scroll - 1		
			end
		end
	end
	if selectedFurniture then
		if key == "mouse_wheel_up" and state then
			local rx, ry, rz = getElementRotation(selectedFurniture)
			local plus = 1
			if activeKeys["lshift"] then
				plus = 5
			end
            if snapEnabled then plus = 45 end
			setElementRotation(selectedFurniture, rx, ry, rz + plus)
			-- Sync rotation immediately as it is distinct event
			local x, y, z = getElementPosition(selectedFurniture)
            local _, _, newRot = getElementRotation(selectedFurniture)
			triggerServerEvent("Furnitures->setPos", localPlayer, localPlayer, selectedFurniture, {x, y, z, newRot})
		end	
		if key == "mouse_wheel_down" and state then
			local rx, ry, rz = getElementRotation(selectedFurniture)
			local plus = 1
			if activeKeys["lshift"] then
				plus = 5
			end
            if snapEnabled then plus = 45 end
			setElementRotation(selectedFurniture,rx, ry, rz - plus)
			-- Sync rotation immediately
			local x, y, z = getElementPosition(selectedFurniture)
            local _, _, newRot = getElementRotation(selectedFurniture)
			triggerServerEvent("Furnitures->setPos", localPlayer, localPlayer, selectedFurniture, {x, y, z, newRot})
		end
	end
	if key == "f" and state and selectedFurniture and getElementData(localPlayer, "Furniture->isFurnitureOnHand") then
		local _x, _y, _z = getElementPosition(selectedFurniture)
		local _, _, _rot = getElementRotation(selectedFurniture)
		local _int, _dim = getElementInterior(selectedFurniture),getElementDimension(selectedFurniture)
		local data = {x = _x, y = _y, z = _z, int = _int, dim = _dim, rot = _rot}
		triggerServerEvent("Furnitures->drop", localPlayer, localPlayer, selectedFurniture, _x,_y,_z,_int,_dim,_rot)
		setElementData(selectedFurniture, "Furniture->used", false)
		setElementData(localPlayer, "Furniture->isFurnitureOnHand", false)
		selectedFurniture = nil
		activeKeys = {} -- Reset keys on drop
	end
	if not selectedFurniture then return end
	if key == "pgup" or key == "pgdn" and state then cancelEvent() end
end
addEventHandler("onClientKey", root, Furnitures.onKey)
function Furnitures.getRotation()
	cam = Camera.matrix:getRotation():getZ()
	cam2 = tonumber(string.format("%.0f",cam)) -- Full integers
	return cam2 or 0
end


function isInBox(xS,yS,wS,hS)
	if(isCursorShowing()) then
		local cursorX, cursorY = getCursorPosition()
		cursorX, cursorY = cursorX*sX, cursorY*sY
		if(cursorX >= xS and cursorX <= xS+wS and cursorY >= yS and cursorY <= yS+hS) then
			return true
		else
			return false
		end
	end	
end

function Furnitures.cancelEdit()
    if selectedFurniture and getElementData(localPlayer, "Furniture->isFurnitureOnHand") then
        local _x, _y, _z = getElementPosition(selectedFurniture)
        local _, _, _rot = getElementRotation(selectedFurniture)
        local _int, _dim = getElementInterior(selectedFurniture),getElementDimension(selectedFurniture)
        triggerServerEvent("Furnitures->drop", localPlayer, localPlayer, selectedFurniture, _x,_y,_z,_int,_dim,_rot)
        setElementData(selectedFurniture, "Furniture->used", false)
        setElementData(localPlayer, "Furniture->isFurnitureOnHand", false)
        selectedFurniture = nil
        activeKeys = {}
    end
end
addEvent("Furnitures->CancelEdit", true)
addEventHandler("Furnitures->CancelEdit", root, Furnitures.cancelEdit)

addEvent("Furnitures->receiveElement", true)
addEventHandler("Furnitures->receiveElement", root, function(element)
	selectedFurniture = element
    local rx, ry, rz = getElementPosition(selectedFurniture)
    realPos = {x=rx, y=ry, z=rz} -- Init Real Pos
	setElementRotation(selectedFurniture,0,0,Furnitures.getRotation())
end)

function getDistanceFromElement(from, to)
	if not from or not to then return end
	local x, y, z = getElementPosition(from)
	local x1, y1, z1 = getElementPosition(to)
	return getDistanceBetweenPoints3D(x, y, z, x1, y1, z1)
end
local showDrawn = false
local showState = "first"

function RemoveHEXColorCode( s )
    return s:gsub( '#%x%x%x%x%x%x', '' ) or s
end


--bundan sonrasını ekle.

addEvent("createFurnObject",true)
addEventHandler("createFurnObject",root,function(data)
	if data["placed"] == 1 then

		local obj = createObject(data["model"], data["x"],data["y"],data["z"], 0, 0, data["rot"])
		
		setElementData(obj,"furnObject",true)
		setElementData(obj, "Furnitures->isFurniture", true)
		setElementData(obj, "Furnitures->id", data["id"])
		setElementData(obj, "Furnitures->owner", data["owner"])
		setElementData(obj, "Furnitures->Hifi", {channel = 1, state = 0})
		setElementData(obj, "Furnitures->data", data["allData"])
		setElementDimension(obj, data["dimension"])
		setElementInterior(obj, data["interior"])
		setElementDoubleSided(obj, true)
		outputChatBox("Furniture created successfully.")
	end
end)

addEvent("destroyFurnObject",true)
addEventHandler("destroyFurnObject",root,function(int,dim)
	for k,v in ipairs(getElementsByType("object")) do
		int2,dim2 = getElementInterior(v),getElementDimension(v)
		if (int == int2) and (dim == dim2) then
			destroyElement(v)
			outputChatBox("Furniture removed successfully.")
		end
	end
end)

function Furnitures.openWeaponController()
	if selectedObject and isElement(selectedObject) then
		local object = createObject(355, 0, 0, 0)
		
		setElementDimension(object, getElementDimension(selectedObject))
		setElementInterior(object, getElementInterior(selectedObject))
		attachElements(object, selectedObject, 0.4, -0.2, 1.1, 90, -10, 180)
		outputChatBox("AK-47 branded gun was successfully left on the table.", 255, 255, 255, true)
	end
end

-- Disable Jump/Fire/Aim while editing
addEventHandler("onClientElementDataChange", localPlayer, function(key, oldValue)
    if key == "Furniture->isFurnitureOnHand" then
        local isOn = getElementData(source, key)
        toggleControl("jump", not isOn)
        toggleControl("fire", not isOn)
        toggleControl("aim_weapon", not isOn)
    end
end)
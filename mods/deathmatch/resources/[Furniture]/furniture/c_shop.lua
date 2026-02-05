
local PREVIEW_POS = Vector3(0, 0, -100)
local previewObject = nil
local originalMatrix = nil


local font1 = dxCreateFont("files/gtahero.ttf", 10)

local shopPed = createPed(240, 1878.3759765625, -2457.3212890625, 13.579086303711)
setElementRotation(shopPed, 0, 0, 87.861724853516)
setElementFrozen(shopPed,true)	
setElementDimension(shopPed, 205)
setElementInterior(shopPed, 27)
setElementData(shopPed,"furniture:ped",true)

addEventHandler("onClientRender", getRootElement(), 
function()
	dxDrawTextOnElement(shopPed, "#D73333[BOT] #FFFFFF  Furniture store", 1, 20, 0, 0, 255, 255, 1.4, font1)
end)

local key = 1--selectedRow
local showShop = false
local selectedCategory = 1
local lastClick = 0
function pedDamage()
	if(getElementData(source, "furniture:ped")) then
		cancelEvent()
	end
end
addEventHandler("onClientPedDamage",  getRootElement(), pedDamage)

function PedClick(button, state, absX, absY, wx, wy, wz, element)
	if element and getElementData(element,"furniture:ped") then
		if state == "down" and button == "right" and showShop == false then
			local x, y, z = getElementPosition(getLocalPlayer())
			if getDistanceBetweenPoints3D(x, y, z, wx, wy, wz) <= 4 then
				showShop = true
				loadGui()
			end
		end
	end
end
addEventHandler("onClientClick", getRootElement(), PedClick, true)

function loadGui()
	startPreview()
	selectedCategory = 1
	key = 1
	addEventHandler("onClientClick",root,clickShop)
	bindKey("a","down",backKey)--geri
	bindKey("arrow_l","down",backKey)--geri
	bindKey("arrow_r","down",nextKey)--ileri
	bindKey("enter","down",orderFurniture)

	bindKey("arrow_u","down",backCategory)--yukarı
	bindKey("arrow_d","down",nextCategory)--aşağı
	showCursor(true)
	bindKey("d","down",nextKey)--ileri
	bindKey("backspace","down",closePanel)
	addEventHandler("onClientRender",root,drawnShop)
    setElementFrozen(localPlayer, true) -- Prevent moving/falling while in shop
end
function closePanel()
	removeEventHandler("onClientClick",root,clickShop)
	removeEventHandler("onClientRender",root,drawnShop)
	showShop = false
	showCursor(false)
    setElementFrozen(localPlayer, false) -- Unfreeze player
	stopPreview()
	unbindKey("a","down",backKey)--geri
	
	unbindKey("enter","down",orderFurniture)	
	unbindKey("arrow_l","down",backKey)--geri
	unbindKey("arrow_r","down",nextKey)--ileri
	
	unbindKey("d","down",nextKey)--ileri

	unbindKey("arrow_u","down",backCategory)--yukarı
	unbindKey("arrow_d","down",nextCategory)--aşağı
	
	unbindKey("backspace","down",closePanel)
end

function backKey()
	if key <= 1 then
		return
	end
	key = key - 1
	updatePreview()
end

function orderFurniture()
	
		lastClick = getTickCount()
		if #myFurnitures + 1 > 10 then 
			outputChatBox("[!]#ffffff You can only hold 10 unplaced items in your inventory!",255,0,0,true)
			return
		end
		
		triggerServerEvent("Furnitures->buy", localPlayer, localPlayer, selectedCategory, key)
		myFurnitures[#myFurnitures + 1] = {}
		-- Note: Success/Failure message is now handled by the server
end

function backCategory()
	if selectedCategory <= 1 then
		return
	end
	selectedCategory = selectedCategory -1
	key = 1
	updatePreview()
end

function nextCategory()
	if selectedCategory >= #furnitures then
		return
	end
	selectedCategory = selectedCategory + 1
	key = 1
	updatePreview()
end

function nextKey()
	if key >= #furnitures[selectedCategory] then
		return
	end
	key = key + 1
	updatePreview()
end

local sx, sy = guiGetScreenSize()
local font = dxCreateFont("files/5.ttf",10)
local font_small = dxCreateFont("files/5.ttf",9)
local font_big = dxCreateFont("files/5.ttf",50)

function drawnShop()
	-- Adjusted Layout: Dock List to Right, Controls to Bottom
	
	-- 1. Category/Item List (Right Side)
	local listW = 200
	local listX = sx - listW - 50 -- 50px padding from right
	local listY = sy/2 - 450/2
	
	-- Background for list
	dxDrawRectangle(listX, listY, listW, 450, tocolor(0,0,0,100))
	dxDrawRectangle(listX + 4, listY + 4, listW - 8, 20, tocolor(35,35,35,180)) -- Header
	dxDrawText(" Categories", listX + 10, listY + 4, listX + listW - 10, listY + 24, tocolor(255,255,255), 1, font_small, "left", "center")

	for i,v in ipairs(furnitures) do
		-- Hover check
		if isInBox2(listX, listY + 30 + 23 * i, listW, 23, getCursorPos()) then -- Simplified hover
			if getKeyState("mouse1") and lastClick+200 <= getTickCount() then
				lastClick = getTickCount()
				selectedCategory = i
				key = 1
				updatePreview()
			end
		end
		
		local catColor = tocolor(255,255,255)
		local catText = v.name
		if selectedCategory == i then
			catColor = tocolor(unpack(color["rgb"]))
			catText = " "..v.name
		end
		dxDrawText(catText, listX + 10, listY + 30 + 23 * i, listX + listW - 10, listY + 53 + 23*i, catColor, 1, font_small, "left", "center")
	end

	-- 2. Footer (Info & Buttons) (Bottom Center)
	local footerW = 600
	local footerH = 100 -- Increased height to fit text and buttons
	local footerX = sx/2 - footerW/2
	local footerY = sy - footerH - 50 -- 50px padding from bottom

	-- Background for Footer
	dxDrawRectangle(footerX, footerY, footerW, footerH, tocolor(0,0,0,150))
	
	if key >= 0 and furnitures[selectedCategory] and furnitures[selectedCategory][key] then
		local item = furnitures[selectedCategory][key]
		local infoText = "Furniture Name: "..item.name.."\nPrice: $"..item.price
		if item.isModding then infoText = infoText .. " (Mod Object)" end
		
		-- Draw Info Text (Top half of footer)
		dxDrawText(infoText, footerX, footerY + 10, footerX + footerW, footerY + 50, tocolor(255,255,255), 1, font, "center", "top")
	end

	-- Draw Buttons (Bottom half of footer)
    -- Using helper function variables for button placement
    -- But drawButton uses direct coordinates.
    local btnW = 150
    local btnH = 30
    local btnY = footerY + footerH - 40
    
	drawButton("Buy", footerX + footerW/2 - btnW - 10, btnY, btnW, btnH, color["hex"].."aa", false, false, false, nil, true)
	drawButton("Cancel", footerX + footerW/2 + 10, btnY, btnW, btnH, "#c0392baa", false, false, false, nil, true)

    -- Navigation Arrows (Floating)
    local arrowSize = 60
    local leftArrowX = sx * 0.2
    local rightArrowX = sx * 0.8 - arrowSize

    dxDrawText("", leftArrowX, sy/2 - arrowSize/2, leftArrowX + arrowSize, sy/2 + arrowSize/2, tocolor(255,255,255), 1, font_big, "center", "center")
    dxDrawText("", rightArrowX, sy/2 - arrowSize/2, rightArrowX + arrowSize, sy/2 + arrowSize/2, tocolor(255,255,255), 1, font_big, "center", "center")

end

function getCursorPos()
	local cX, cY = getCursorPosition()
	if cX then return cX * sx, cY * sy else return 0,0 end
end

function clickShop(button, state)
	if button == "left" and state == "down" then
        -- List interaction handled in loop? No, clickShop is event based.
        -- Re-implement input logic for new layout.
        
        local listW = 200
        local listX = sx - listW - 50
        local listY = sy/2 - 450/2
        
        local cx, cy = getCursorPos()

		for i,v in ipairs(furnitures) do
			if isInBox2(listX, listY + 30 + 23 * i, listW, 23, cx, cy) then
				selectedCategory = i
				key = 1
				updatePreview()
				return
			end
		end
	
        -- Arrows
        local arrowSize = 60
        local leftArrowX = sx * 0.2
        local rightArrowX = sx * 0.8 - arrowSize

		if isInBox2(leftArrowX, sy/2 - arrowSize/2, arrowSize, arrowSize, cx, cy) then	
			if key > 1 then
				key = key - 1
                updatePreview()
			end
		end
		if isInBox2(rightArrowX, sy/2 - arrowSize/2, arrowSize, arrowSize, cx, cy) then
            if furnitures[selectedCategory] and key < #furnitures[selectedCategory] then
				key = key + 1
				updatePreview()
			end	
		end
		
        -- Footer Buttons
        local footerW = 600
        local footerH = 100
        local footerX = sx/2 - footerW/2
        local footerY = sy - footerH - 50
        local btnW = 150
        local btnH = 30
        local btnY = footerY + footerH - 40
        
        -- Buy
		if isInBox2(footerX + footerW/2 - btnW - 10, btnY, btnW, btnH, cx, cy) then
			if #myFurnitures + 1 > 10 then 
				outputChatBox("[!]#ffffff You can only hold 10 unplaced items in your inventory!",255,0,0,true)
				return
			end
			triggerServerEvent("Furnitures->buy", localPlayer, localPlayer, selectedCategory, key)
			myFurnitures[#myFurnitures + 1] = {}
			return
		end
        
        -- Cancel
		if isInBox2(footerX + footerW/2 + 10, btnY, btnW, btnH, cx, cy) then
			closePanel()
			return
		end
	end
end

function isInSlot(x, y, w, h)
	local cX, cY = getCursorPosition()
	cX, cY = cX * sx, cY * sy
	if isInBox2(x, y, w, h, cX, cY) then
		return true
	else
		return false
	end
end
function isInBox2(dX, dY, dSZ, dM, eX, eY)
    if(eX >= dX and eX <= dX+dSZ and eY >= dY and eY <= dY+dM) then
        return true
    else
        return false
    end
end


function dxDrawTextOnElement(TheElement,text,height,distance,R,G,B,alpha,size,font,...)
	local x1, y1, z1 = getElementPosition(TheElement)
	local x2, y2, z2 = getCameraMatrix()
	local distance = distance or 20
	local height = height or 1

	if (isLineOfSightClear(x1, y1, z1+2, x2, y2, z2, ...)) then
		local sx, sy = getScreenFromWorldPosition(x1, y1, z1+height)
		if(sx) and (sy) then
			local distanceBetweenPoints = getDistanceBetweenPoints3D(x1, y1, z1, x2, y2, z2)
			if(distanceBetweenPoints < distance) then
				dxDrawText(text, sx+2, sy+2, sx, sy, tocolor(R or 255, G or 255, B or 255, alpha or 255), (size or 1)-(distanceBetweenPoints / distance), font or "arial", "center", "center", false, false, false, true, false)

            end
		end
	end
end

-- 3D Preview Logic
function startPreview()
	-- Store original camera state just in case, only if not already stored (to avoid overwriting with preview pos)
    if not originalMatrix then
        local x,y,z,lx,ly,lz = getCameraMatrix()
        originalMatrix = {x,y,z,lx,ly,lz}
    end

	if not previewObject and furnitures[selectedCategory] and furnitures[selectedCategory][key] then
		local model = furnitures[selectedCategory][key].model
		if model then
			previewObject = createObject(model, PREVIEW_POS)
			setElementDimension(previewObject, getElementDimension(localPlayer))
			setElementInterior(previewObject, getElementInterior(localPlayer))
			setElementCollisionsEnabled(previewObject, false)
		end
	end
	
	-- setTime(12, 0) -- Good lighting (Client side only)
	updateCamera()
	addEventHandler("onClientRender", root, renderPreview)
end

function updatePreview()
	if previewObject and furnitures[selectedCategory] and furnitures[selectedCategory][key] then
		local model = furnitures[selectedCategory][key].model
		if model then
			setElementModel(previewObject, model)
            -- Wait a frame for model to load/update bounding box properly, or call immediately
            setTimer(updateCamera, 50, 1) 
		end
	elseif not previewObject then
		-- If object didn't exist (maybe first item was invalid), try creating it
		startPreview()
	end
end

function renderPreview()
	if previewObject then
		local rx, ry, rz = getElementRotation(previewObject)
		setElementRotation(previewObject, rx, ry, rz + 0.5) -- Rotate slowly
	end
end

function stopPreview()
	if previewObject then
		destroyElement(previewObject)
		previewObject = nil
	end
	removeEventHandler("onClientRender", root, renderPreview)

    -- Force camera reset to original position if available, else target player
    if originalMatrix then
        setCameraMatrix(unpack(originalMatrix))
        setTimer(function() setCameraTarget(localPlayer) end, 100, 1) -- Ensure control is returned after a brief moment
    else
        setCameraTarget(localPlayer)
    end
    originalMatrix = nil
end

function updateCamera()
	-- Ensure Vector3 is valid, otherwise fallback
	local px, py, pz = 0, 0, -100
	if PREVIEW_POS then px, py, pz = PREVIEW_POS.x, PREVIEW_POS.y, PREVIEW_POS.z end

    -- Dynamic Camera Fit
    local dist = 3.5 -- Default distance
    local centerZ = 0
    if previewObject and isElement(previewObject) then
        local minX, minY, minZ, maxX, maxY, maxZ = getElementBoundingBox(previewObject)
        if minX then
            local width = maxX - minX
            local depth = maxY - minY
            local height = maxZ - minZ
            
            local maxDim = math.max(width, depth, height)
            dist = math.max(maxDim * 3.5, 4.0) -- Increased multiplier for better fit
            centerZ = (minZ + maxZ) / 2
        end
    end

	local cx, cy, cz = px + 0, py + dist, pz + centerZ + (dist * 0.4) -- Look from slight angle
    -- Target is the object center
    local tx, ty, tz = px, py, pz + centerZ

	setCameraMatrix(cx, cy, cz, tx, ty, tz)
end
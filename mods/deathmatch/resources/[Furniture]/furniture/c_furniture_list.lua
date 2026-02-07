local sx, sy = guiGetScreenSize()
myFurnitures = {}

local awesomeFont = dxCreateFont("files/5.ttf",10)
local awesomeFontM = dxCreateFont("files/5.ttf",9)

local selectedItem = 0
local showTexture = false
local currentRow = 1
local latestRow = 1
local maxRow = math.floor(sx/90)

local activeTab = "homepage"
local activeAltTab = false
local activeTabS = {{" Home Page","homepage"}, {" Furniture","furn"}, {" Coatings","texs"}}
local activeAltTabs = {
	["homepage"] = {},
	["furn"] = {},
	["texs"] = {
		{"Wall Coverings", "walltexs"},
		{"Floor/Ceiling Coverings", "floortexs"},
		{"Door Coverings", "doortexs"},
	}
}

local s_color = {84, 160, 255}
local hex = "#54a0ff"

-- 3D Preview state
local previewObject = nil
local previewRotation = 0
local previewModel = -1

local showed_myFurnitures = false
local requested = false
local selected_furniture = 0
local lastClick = 0

-- Sell Menu State
local sellMenu = {
    show = false,
    x = 0,
    y = 0,
    itemIndex = 0
}
local lastSellTime = 0

-- Furniture access granted by interior owner (synced from server)
-- This is duplicated from c_furniture.lua because both files need to check access
local hasFurnitureAccess = false

-- Sync furniture access permission from server (also exists in c_furniture.lua)
addEvent("Furnitures->syncAccessList", true)
addEventHandler("Furnitures->syncAccessList", root, function(accessGranted)
    hasFurnitureAccess = accessGranted or false
end)

local AlphaArray = {}
for i=0, 99 do
	AlphaArray[i] = 0
end
local TextAlphaArray = {}
for i=0, 999 do
	TextAlphaArray[i] = 0
end

function draw()
	if not showed_myFurnitures then return end
	
	if getElementInterior(localPlayer) == 0 and getElementDimension(localPlayer) == 0 then
		executeCommandHandler("editor")
		return
	end

	mx,my,mw,mh = 0, sy-150, sx, 150
	dxDrawRectangle(mx,my,mw,mh,tocolor(25,25,25,240))
	dxDrawRectangle(mx,my,mw,30,tocolor(35,35,35,230))
    
    -- Close Button (X)
    local closeHover = isInBox(mx+mw-30, my, 30, 30)
    dxDrawRectangle(mx+mw-30, my, 30, 30, closeHover and tocolor(200, 50, 50, 255) or tocolor(200, 50, 50, 200))
    dxDrawText("X", mx+mw-30, my, mx+mw, my+30, tocolor(255, 255, 255, 255), 1, awesomeFont, "center", "center")

	tabRowHeight = 0
	altTabHeight = 0
	for k,v in pairs(activeTabS) do
		text = v[1]
		if activeTab == v[2] then
		
			dxDrawText(text,mx+10+tabRowHeight,my+5,mw,30,tocolor(s_color[1],s_color[2],s_color[3]),1,awesomeFont,"left","top")
			
			
			for index, row in ipairs(activeAltTabs[v[2]]) do
				if activeAltTab == row[2] then
					dxDrawText(row[1],mx+15+tabRowHeight+(dxGetTextWidth(text,1,awesomeFont))+altTabHeight,my+5,mw,30,tocolor(s_color[1],s_color[2],s_color[3]),1,awesomeFontM,"left","top")
				else
					dxDrawText(row[1],mx+15+tabRowHeight+(dxGetTextWidth(text,1,awesomeFont))+altTabHeight,my+5,mw,30,tocolor(225,225,225,225),1,awesomeFontM,"left","top")
				end

				altTabHeight = altTabHeight + 10 + dxGetTextWidth(row[1], 1, awesomeFontM)
			end

		else
			dxDrawText(text,mx+10+tabRowHeight,my+5,mw,30,tocolor(255,255,255),1,awesomeFont,"left","top")
		end
		tabRowHeight = tabRowHeight + 15 + dxGetTextWidth(text,1,awesomeFont)
	end
	if activeTab == "homepage" then
		dxDrawText("Furniture Management:\nYou can place the furniture you bought from the furniture store in your home here.\nYou can cover the walls, floor, ceiling and doors in your home.\nWhen placing the furniture, it is positioned where you click with the mouse.", mx+10, my+40, mw, mh, tocolor(255, 255, 255), 1, awesomeFont, "left", "top")
	elseif activeTab == "furn" then
		-- Name-only horizontal list
		local itemW = 120
		local itemH = 24
		local itemPad = 6
		local startY = my + 35
		local cols = math.floor((mw - 30) / (itemW + itemPad))
		for index, value in ipairs(myFurnitures) do
			local col = (index - 1) % cols
			local row = math.floor((index - 1) / cols)
			local itemX = mx + 15 + col * (itemW + itemPad)
			local itemY = startY + row * (itemH + itemPad)
			local name = findNameByModel(tonumber(value.model)) or "Unknown"
			
			if selected_furniture == index then
				dxDrawRectangle(itemX, itemY, itemW, itemH, tocolor(s_color[1], s_color[2], s_color[3], 40))
				dxDrawRectangle(itemX, itemY + itemH - 2, itemW, 2, tocolor(s_color[1], s_color[2], s_color[3]))
				dxDrawText(name, itemX + 5, itemY, itemX + itemW - 5, itemY + itemH, tocolor(s_color[1], s_color[2], s_color[3]), 1, awesomeFontM, "center", "center", true)
			else
				dxDrawRectangle(itemX, itemY, itemW, itemH, tocolor(30, 30, 30, 180))
				dxDrawText(name, itemX + 5, itemY, itemX + itemW - 5, itemY + itemH, tocolor(220, 220, 220), 1, awesomeFontM, "center", "center", true)
			end
		end

		-- 3D Preview (no box, just the object in front of camera)
		if selected_furniture > 0 and myFurnitures[selected_furniture] and not getElementData(localPlayer, "Furniture->isFurnitureOnHand") then
			local pvModel = tonumber(myFurnitures[selected_furniture].model)
			updateFurniturePreview(pvModel)
		else
			clearFurniturePreview()
		end
	elseif activeTab == "texs" then
		if activeAltTab then
			latestRow = currentRow + maxRow - 1
			-- left
			dxDrawRectangle(mx, my+30, 20, mh-15, tocolor(30, 30, 30, 120))
			dxDrawText("", mx, my+30, 20+mx, mh-15+(my+30), tocolor(255, 255, 255), 1, awesomeFont, "center", "center")
			--right
			dxDrawRectangle(sx-20, my+30, 20, mh-15, tocolor(30, 30, 30, 120))
			dxDrawText("", sx-20, my+30, 20+sx-20, mh-15+(my+30), tocolor(255, 255, 255), 1, awesomeFont, "center", "center")
			
			for index, value in ipairs(textures[activeAltTab]) do

				if index >= currentRow and index <= latestRow then
					index = index - currentRow + 1
					if fileExists(value[1]) then
						dxDrawImage(mx+25+((index-1)*86),my+30,84,84,value[1])
					end
					dxDrawRectangle(mx+25+((index-1)*86),my+114,84,20,tocolor(20,20,20,160))
					
					if selected_furniture == index then
						dxDrawText("Buy ("..value.price.."$)",mx+25+((index-1)*86),my+114,84+(mx+25+((index-1)*86)),20+(my+114),tocolor(255,255,255,255),1,awesomeFontM,"center","center")
						dxDrawText("Buy ("..value.price.."$)",mx+25+((index-1)*86),my+114,84+(mx+25+((index-1)*86)),20+(my+114),tocolor(s_color[1],s_color[2],s_color[3]),1,awesomeFontM,"center","center")
					else
						dxDrawText(value.name,mx+25+((index-1)*86),my+114,84+(mx+25+((index-1)*86)),20+(my+114),tocolor(255,255,255,255),1,awesomeFontM,"center","center")
					end
				end
			end
		end
	end
    
    -- Draw Sell Context Menu
    if sellMenu.show and sellMenu.itemIndex > 0 and myFurnitures[sellMenu.itemIndex] then
        local sx, sy = sellMenu.x, sellMenu.y
        local item = myFurnitures[sellMenu.itemIndex]
        local width, height = 150, 70
        
        -- Ensure menu stays on screen
        if sx + width > mw + mx then sx = mw + mx - width end
        if sy + height > mh + my then sy = mh + my - height end -- Clamped to panel area basically

        dxDrawRectangle(sx, sy, width, height, tocolor(40, 40, 40, 255))
        dxDrawRectangle(sx, sy, width, 25, tocolor(30, 30, 30, 255)) -- Title
        dxDrawText("Options", sx, sy, sx+width, sy+25, tocolor(255,255,255), 1, awesomeFont, "center", "center")
        
        -- Sell Button
        local hoverSell = isInBox(sx, sy+25, width, 20)
        dxDrawRectangle(sx, sy+25, width, 20, hoverSell and tocolor(60, 60, 60, 255) or tocolor(50, 50, 50, 255))
        dxDrawText("Sell (60%)", sx, sy+25, sx+width, sy+45, tocolor(200, 50, 50), 1, awesomeFontM, "center", "center")

        -- Close Button
        local hoverClose = isInBox(sx, sy+45, width, 20)
        dxDrawRectangle(sx, sy+45, width, 20, hoverClose and tocolor(60, 60, 60, 255) or tocolor(50, 50, 50, 255))
        dxDrawText("Close", sx, sy+45, sx+width, sy+65, tocolor(255, 255, 255), 1, awesomeFontM, "center", "center")
    end
end
addEventHandler("onClientRender", root, draw)

local lastPurchaseTime = 0
function onClientClick(button, state)
	if (button == "left" or button == "right") and state == "down" and showed_myFurnitures then
		
		mx,my,mw,mh = 0, sy-150, sx, 150
        
        -- Handle Sell Menu Clicks (Left click only for menu options)
        if sellMenu.show and button == "left" then
            local sx, sy = sellMenu.x, sellMenu.y
            local width, height = 150, 70
            
            -- Sell Button Click
             if isInBox(sx, sy+25, width, 20) then
                local currently = getTickCount()
                if (currently - lastSellTime) < 60000 then -- 60 seconds cooldown
                    local remaining = math.ceil((60000 - (currently - lastSellTime)) / 1000)
                    outputChatBox("You must wait " .. remaining .. " seconds before selling another item.", 255, 0, 0)
                    return
                end
                
                if myFurnitures[sellMenu.itemIndex] then
                    triggerServerEvent("Furnitures->sell", localPlayer, localPlayer, myFurnitures[sellMenu.itemIndex].id)
                    lastSellTime = getTickCount()
                end
                sellMenu.show = false
                return
            end
            
            -- Close Button Click
            if isInBox(sx, sy+45, width, 20) then
                sellMenu.show = false
                return
            end
            
            -- Click outside closes menu? Optional, but good UX.
            if not isInBox(sx, sy, width, height) then
                sellMenu.show = false
            end
        end
		
		tabRowHeight = 0
		altTabHeight = 0
		
        -- Close (X) Click
		if isInBox(mx+mw-30, my, 30, 30) then
            if getElementData(localPlayer, "Furniture->isFurnitureOnHand") then
                triggerEvent("Furnitures->CancelEdit", localPlayer)
            end
            showed_myFurnitures = false
            selected_furniture = 0
            myFurnitures = {}
            clearFurniturePreview()
            if isElement(window) then destroyElement(window) end
            if isElement(texW) then  destroyElement(texW) end
            return
        end

		for k,v in pairs(activeTabS) do
			text = v[1]
			
			if activeTab == v[2] then
				for index, row in ipairs(activeAltTabs[v[2]]) do
					if isInBox(mx+15+tabRowHeight+(dxGetTextWidth(text,1,awesomeFont))+altTabHeight,my+5,dxGetTextWidth(row[1], 1, awesomeFontM),30) then
						activeAltTab = row[2]
						currentRow = 1
					end
					altTabHeight = altTabHeight + 10 + dxGetTextWidth(row[1], 1, awesomeFontM)
				end
			end
			if isInBox(mx+10+tabRowHeight-2,my,dxGetTextWidth(text,1,awesomeFont)+4,30) then
				activeTab = v[2]
			end
			
			tabRowHeight = tabRowHeight + 15 + dxGetTextWidth(text,1,awesomeFont)
		end
		if activeTab == "furn" then
			local itemW = 120
			local itemH = 24
			local itemPad = 6
			local startY = my + 35
			local cols = math.floor((mw - 30) / (itemW + itemPad))
			for index, value in ipairs(myFurnitures) do
				local col = (index - 1) % cols
				local row = math.floor((index - 1) / cols)
				local hitX = mx + 15 + col * (itemW + itemPad)
				local hitY = startY + row * (itemH + itemPad)
				if isInBox(hitX, hitY, itemW, itemH) then
                    if button == "right" or button == "extra" then
                        sellMenu.show = true
                        sellMenu.x = hitX + 60
                        sellMenu.y = hitY
                        sellMenu.itemIndex = index
                    elseif button == "left" then
                        if selected_furniture ~= index then
                            selected_furniture = index
                        else
                            if getElementData(localPlayer, "Furniture->isFurnitureOnHand") then
                                outputChatBox("You are already arranging a piece of furniture.", 255, 255, 255, true)
                                return
                            end
                            if tonumber(myFurnitures[selected_furniture].model) == 2224 and getFurnituresCount(2224, getElementDimension(localPlayer)) > 0 then
                                outputChatBox("You have reached the limit for placing this object!", 255, 255, 255, true)
                                return
                            end
                            if tonumber(myFurnitures[selected_furniture].model) == 2232 and getFurnituresCount(2232, getElementDimension(localPlayer)) + 1 > 4 then
                                outputChatBox("You have reached the limit for placing this object!", 255, 255, 255, true)
                                return
                            end
                            triggerServerEvent("Furnitures->create", localPlayer, localPlayer, myFurnitures[selected_furniture])
                            table.remove(myFurnitures, selected_furniture)
                            selected_furniture = -1
                        end
                    end
				end
			end
		elseif activeTab == "texs" and activeAltTab then
			if isInBox(sx-20, my+30, 20, mh-15) then-- sağa
				if currentRow < #textures[activeAltTab] - (maxRow - 1) then
					currentRow = currentRow + 1
				end
				return
			end
			if isInBox(mx, my+30, 20, mh-15) then-- sola
				if currentRow > 1 then
					currentRow = currentRow - 1
				end
				return
			end
			for index, value in ipairs(textures[activeAltTab]) do

				if isInBox(mx+25+((index-1)*86),my+30,84,84) then
					executeCommandHandler("editor")
					openTextureEditor(value[1],0,value.price)
				end
			end
		end
	end
end
addEventHandler("onClientClick", root, onClientClick)



-- Helper function to check if an interior is government-owned (type 2)
local function isGovernmentInterior(dimension)
	if dimension <= 0 then return false end
	local dbid, entrance, exit, interiorType, interiorElement = exports['interior_system']:findProperty(nil, dimension)
	if interiorElement then
		local interiorStatus = getElementData(interiorElement, "status")
		return interiorStatus and interiorStatus.type == 2
	end
	return false
end

addCommandHandler("editor", function(command)
	dimension = getElementDimension(localPlayer)
	local isGovInt = isGovernmentInterior(dimension)
	local isAdminOnDutyCheck = exports.integration:isPlayerAdmin(localPlayer) and exports.global:isAdminOnDuty(localPlayer)
	
	-- Check if player has interior key, admin on duty, or granted furniture access
	local hasInteriorKey = exports.global:hasItem(localPlayer, 4, dimension) or exports.global:hasItem(localPlayer, 5, dimension)
	local hasFurnAccess = hasFurnitureAccess -- Variable synced from server when entering interior
	
	-- Allow if: has key item 4/5 OR admin on duty OR (government interior AND admin on duty) OR granted furniture access
	if hasInteriorKey or isAdminOnDutyCheck or (isGovInt and isAdminOnDutyCheck) or hasFurnAccess then
		x,y,z = getElementPosition(localPlayer)
		interior,dimension = tonumber(getElementInterior(localPlayer)),tonumber(getElementDimension(localPlayer))
		if not showed_myFurnitures then
			--setElementAlpha(localPlayer,0)
			--maxlimit = {x-25,y-25,z-60,x+25,y+25,z+25}
			--setFreecamEnabled(x,y,z+5,maxlimit,interior,dimension)

			showed_myFurnitures = true
			myFurnitures = {}
			load_my_furnitures()
		else
			--setElementAlpha(localPlayer,255)
			--setFreecamDisabled()
			--setCameraTarget(localPlayer)
			showed_myFurnitures = false
			selected_furniture = 0
			myFurnitures = {}
			clearFurniturePreview()
			if isElement(window) then destroyElement(window) end
			if isElement(texW) then  destroyElement(texW) end
		end
	else
		outputChatBox("You do not have access to the furniture editor in this interior.", 255, 0, 0)
	end
end)



addEvent("Furnitures->ForceEditorState", true)
addEventHandler("Furnitures->ForceEditorState", root, function(state)
    showed_myFurnitures = state
    if state then
        myFurnitures = {}
        load_my_furnitures()
    else
        showed_myFurnitures = false
        selected_furniture = 0
        myFurnitures = {}
        clearFurniturePreview()
        if isElement(window) then destroyElement(window) end
        if isElement(texW) then  destroyElement(texW) end
    end
end)

addEvent("closeTexPanel",true)
addEventHandler("closeTexPanel",root,function() 
	showTexture = false
	selectedItem = 0

end)

addEvent("openTexPanel",true)
addEventHandler("openTexPanel",root,function() 
	showTexture = true

end)

function getFurnituresCount(model, dimension)
	if model and dimension then
		local count = 0
		for k, v in ipairs(getElementsByType("object")) do
			if tonumber(getElementDimension(v)) == tonumber(dimension) and tonumber(getElementModel(v)) == tonumber(model) then
				count = count + 1
			end
		end
		return count
	end
end

function clearFurniturePreview()
	if isElement(previewObject) then
		destroyElement(previewObject)
	end
	previewObject = nil
	previewModel = -1
end

function updateFurniturePreview(model)
	-- Create or recreate if model changed
	if model ~= previewModel then
		clearFurniturePreview()
		local cx, cy, cz, tx, ty, tz = getCameraMatrix()
		if not cx then return end
		previewObject = createObject(model, cx, cy, cz)
		if not isElement(previewObject) then return end
		setElementCollisionsEnabled(previewObject, false)
		setElementDimension(previewObject, getElementDimension(localPlayer))
		setElementInterior(previewObject, getElementInterior(localPlayer))
		setElementDoubleSided(previewObject, true)
		setElementFrozen(previewObject, true)
		setElementAlpha(previewObject, 240)
		-- Auto-scale based on bounding box to fit nicely
		local minX, minY, minZ, maxX, maxY, maxZ = getElementBoundingBox(previewObject)
		if minX then
			local sizeX = math.abs(maxX - minX)
			local sizeY = math.abs(maxY - minY)
			local sizeZ = math.abs(maxZ - minZ)
			local maxSize = math.max(sizeX, sizeY, sizeZ)
			if maxSize > 0 then
				local targetSize = 0.22
				local scale = targetSize / maxSize
				setObjectScale(previewObject, scale)
			end
		end
		previewModel = model
	end

	-- Update position each frame: place slightly right of center, close to camera
	if isElement(previewObject) then
		local cx, cy, cz, tx, ty, tz = getCameraMatrix()
		if cx then
			-- Forward vector
			local fwdX, fwdY, fwdZ = tx - cx, ty - cy, tz - cz
			local fwdLen = math.sqrt(fwdX*fwdX + fwdY*fwdY + fwdZ*fwdZ)
			if fwdLen > 0 then
				fwdX, fwdY, fwdZ = fwdX/fwdLen, fwdY/fwdLen, fwdZ/fwdLen
				-- Right vector (cross forward with world up)
				local rightX = fwdY
				local rightY = -fwdX
				-- Position: 1.5 forward, 0.5 right, 0.15 down from camera center
				local dist = 1.5
				local wx = cx + fwdX * dist + rightX * 0.5
				local wy = cy + fwdY * dist + rightY * 0.5
				local wz = cz + fwdZ * dist - 0.15
				setElementPosition(previewObject, wx, wy, wz)
			end
		end
		previewRotation = (previewRotation + 0.5) % 360
		setElementRotation(previewObject, 350, 0, previewRotation)
	end
end

function load_my_furnitures()
	triggerServerEvent("Furnitures->loadMyFurnitures", localPlayer, getElementData(localPlayer, "dbid"))
end
load_my_furnitures()
setElementData(localPlayer, "Furniture->isFurnitureOnHand",false)
addEvent("GetMyFurnitures", true)
addEventHandler("GetMyFurnitures", root, function(data)
	myFurnitures = {}
	myFurnitures = data
	requested = true
end)

function findNameByModel(model)
	for i=1, #furnitures do
		for i2, v in ipairs(furnitures[i]) do
			if tonumber(v.model) == model then
				return v.name
			end
		end
	end
	return false
end

function isInBox(xS,yS,wS,hS)
	if(isCursorShowing()) then
		local cursorX, cursorY = getCursorPosition()
		cursorX, cursorY = cursorX*sx, cursorY*sy
		if(cursorX >= xS and cursorX <= xS+wS and cursorY >= yS and cursorY <= yS+hS) then
			return true
		else
			return false
		end
	end	
end
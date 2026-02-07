local connection = exports['fur_mysql']:getConnection()
local mysql = exports.fur_mysql
addEventHandler("onResourceStart", root, 
    function(startedRes)
        if getResourceName(startedRes) == "fur_mysql" then
            connection = exports['fur_mysql']:getConnection()
            restartResource(getThisResource())
        end
    end
)

Async:setPriority("low")
--Async:setDebug(true)

-- ============================================================================
-- FURNITURE ACCESS SYSTEM - MUST BE DECLARED BEFORE canPlayerManageFurniture
-- ============================================================================

Furnitures = {}
local attachedFurnitures = {}
local cache = {}

-- Furniture access list: furnitureAccessList[interiorDimension][playerDBID] = true
-- Allows interior owners to grant furniture editing permissions to other players
local furnitureAccessList = {}

-- Check if player has granted furniture access for an interior
function checkPlayerFurnitureAccess(player, interiorDim)
    if not player or not interiorDim then return false end
    local playerID = getElementData(player, "dbid")
    if not playerID then return false end
    interiorDim = tonumber(interiorDim)
    if not interiorDim then return false end
    if furnitureAccessList[interiorDim] and furnitureAccessList[interiorDim][tonumber(playerID)] then
        return true
    end
    return false
end

-- Grant furniture access to a player for an interior
function grantFurnitureAccess(interiorDim, playerDBID)
    interiorDim = tonumber(interiorDim)
    playerDBID = tonumber(playerDBID)
    if not interiorDim or not playerDBID then return false end
    if not furnitureAccessList[interiorDim] then
        furnitureAccessList[interiorDim] = {}
    end
    furnitureAccessList[interiorDim][playerDBID] = true
    return true
end

-- Revoke furniture access from a player for an interior
function revokeFurnitureAccess(interiorDim, playerDBID)
    interiorDim = tonumber(interiorDim)
    playerDBID = tonumber(playerDBID)
    if not interiorDim or not playerDBID then return false end
    if furnitureAccessList[interiorDim] then
        furnitureAccessList[interiorDim][playerDBID] = nil
    end
    return true
end

-- Get list of players with furniture access for an interior (for debugging/admin)
function getFurnitureAccessList(interiorDim)
    interiorDim = tonumber(interiorDim)
    if not interiorDim then return {} end
    return furnitureAccessList[interiorDim] or {}
end

-- ============================================================================
-- PERMISSION CHECK FUNCTION
-- ============================================================================

function canPlayerManageFurniture(player, furniture)
    local playerID = getElementData(player, "dbid")
    local furnitureOwner = getElementData(furniture, "Furnitures->owner")
    
    -- 1. If user is admin (check integration export), they can always manage
    if exports.integration:isPlayerAdmin(player) then
        return true
    end

    -- 2. Check if furniture is placed in an interior
    local dim = getElementDimension(furniture)
    
    -- Debugging
    -- outputChatBox("Debug: FurnID: " .. tostring(getElementData(furniture, "Furnitures->id")) .. " Dim: " .. tostring(dim) .. " PlrID: " .. tostring(playerID), player)

    if dim > 0 then
        -- It's inside an interior. Check interior ownership.
        -- Using findProperty from interior_system (exported)
        local dbid, entrance, exit, type, interiorElement = exports['interior_system']:findProperty(player, dim)
        
        if interiorElement then
            local interiorStatus = getElementData(interiorElement, "status")
            local interiorOwner = tonumber(interiorStatus.owner)
            
            -- Debugging
            -- outputChatBox("Debug: IntOwner: " .. tostring(interiorOwner) .. " MyID: " .. tostring(playerID), player)

            -- If player owns the interior, they can manage the furniture
            if interiorOwner == tonumber(playerID) then
                return true
            end
            -- Also check for faction ownership/permissions if needed (optional but good for business/faction ints)
            if exports.factions:isPlayerInFaction(player, interiorStatus.faction) and exports.factions:hasMemberPermissionTo(player, interiorStatus.faction, "manage_interiors") then
                return true
            end
            
            -- Check if player has been granted furniture access by the interior owner
            if furnitureAccessList[dim] and furnitureAccessList[dim][tonumber(playerID)] then
                return true
            end
        end
        -- STRICT INTERIOR RULE: If inside an interior, ONLY the interior owner (or faction/admin/granted access) can manage.
        -- We do NOT fall back to checking the furniture item owner.
        return false
    else
        -- 3. If outside (dim 0), fall back to original furniture owner check
        if tonumber(furnitureOwner) == tonumber(playerID) then
            return true
        end
    end

    -- 4. If it's an unplaced item (in hand/inventory context, though this function mainly checks existing objects), check owner
    if not isElement(furniture) then
        -- If just data passed, logic might differ, but here we assume element
        return false
    end
    
    return false
end

--Jesse [LOG]
--!!!!! !!!!!---
-- Örnek tablo verisi: {furnitures: {id,x,y,z,interior,dimension,rotation,model,owner,placed,texture} }
--!!!!! !!!!!---
--Jesse [LOG]
-- tablo verisi start:
-- cache[dbid]
-- tablo verisi end:
addEventHandler("onResourceStart", getResourceRootElement(),
    function()
    	if not connection then return end
    	dbQuery(function(query)
            local query, query_lines = dbPoll(query, 0)
            if query_lines > 0 then
                Async:foreach(query, function(v)
				    local id = tonumber(v["id"])          
					local x 		= tonumber(v["x"])
					local y 		= tonumber(v["y"])
					local z 		= tonumber(v["z"])
					local rot 		= tonumber(v["rotation"])
					local interior  = tonumber(v["interior"])
					local dimension = tonumber(v["dimension"])
					local model 	= tonumber(v["model"])
					local owner 	= tonumber(v["owner"])
					local placed 	= tonumber(v["placed"])
					------------------------------------------
					cache[id] = {
						["id"] = id,
						["x"] = x,
						["y"] = y,
						["z"] = z,
						["rot"] = rot,
						["interior"] = interior,
						["dimension"] = dimension,
						["model"] = model,
						["placed"] = placed,
						["allData"] = v,
						["owner"] = owner,
 					}
 					
 					loadObjectWhereID(id)
					
 					
				end)   
				outputDebugString("[Success] Loading furnitures has finished successfully. Loaded: " .. query_lines .. " furnitures!")

			end
		end, connection, "SELECT * FROM `furnitures`")  
	                    
    end 
)
--[[
addEventHandler("onPlayerInteriorChange", getRootElement( ),
	function( a, b, toDimension, toInterior)	
		if toDimension ~= 0 then
			setElementData(source,"oldint",toInterior)
			setElementData(source,"olddim",toDimension)
			Async:foreach(cache, function(v) 
				if v["interior"] == toInterior then
					if v["dimension"] == toDimension then
						triggerClientEvent(source,"createFurnObject",source,v)
						
					end
				end
		  end)
		else
			Async:foreach(cache, function(v) 
				if v["interior"] == getElementData(source,"oldint") then
					if v["dimension"] == getElementData(source,"olddim") then
						triggerClientEvent(source,"destroyFurnObject",source,v["interior"],v["dimension"])
					end
				end
			end)
		end
	end
)
addEventHandler("onPlayerSpawn", root, function()
		toInterior = getElementInterior(source)
		toDimension = getElementDimension(source)
		if toDimension ~= 0 then
			setElementData(source,"oldint",toInterior)
			setElementData(source,"olddim",toDimension)
			Async:foreach(cache, function(v) 
				if v["interior"] == toInterior then
					if v["dimension"] == toDimension then
						triggerClientEvent(source,"createFurnObject",source,v)
					end
				end
		    end)
		end
	end
)
]]--
function loadObjectWhereID(dbid)
	local data = cache[dbid]
	
	if data["placed"] == 1 then
		local obj = createObject(data["model"], data["x"],data["y"],data["z"], 0, 0, data["rot"])
		
		setElementData(obj, "Furnitures->isFurniture", true)
		setElementData(obj, "Furnitures->id", data["id"])
		setElementData(obj, "Furnitures->owner", data["owner"])
		setElementData(obj, "Furnitures->Hifi", {channel = 1, state = 0})
		setElementData(obj, "Furnitures->data", data["allData"])
		setElementDimension(obj, data["dimension"])
		setElementInterior(obj, data["interior"])
		setElementDoubleSided(obj, true)
		
	end
end

function Furnitures.loadMyFurnitures(dbid, targetPlayer)
	if not dbid then return end
	local playerForCallback = targetPlayer or source
	local myFurnitures = {}
	--insertQuery = dbPoll(dbQuery(connection,"SELECT * FROM furnitures WHERE owner = " .. dbid .. " AND placed = 0"),-1)
	dbQuery(function(queryHandle, player)
		local result, rows, err = dbPoll(queryHandle, 0)
		if rows > 0 then
			for k, v in pairs(result) do                
				local id_ = tonumber(v["id"])
				local x_ 		= tonumber(v["x"])
				local y_ 		= tonumber(v["y"])
				local z_ 		= tonumber(v["z"])
				local rot_ 		= tonumber(v["rotation"])
				local interior_  = tonumber(v["interior"])
				local dimension_ = tonumber(v["dimension"])
				local model_ 	= tonumber(v["model"])
				local owner_ 	= tonumber(v["owner"])
				local placed_ 	= tonumber(v["placed"])
				------------------------------------------
				myFurnitures[#myFurnitures + 1] = {id = id_, x = x_, y = y_, z = z_, rot = rot_, interior = interior_, dimension = dimension_, model = model_, owner = owner_, placed = placed_}
			end         
			triggerClientEvent(player, "GetMyFurnitures", player, myFurnitures)
		else
			-- Send empty list so client clears stale data
			triggerClientEvent(player, "GetMyFurnitures", player, {})
		end

	end, {playerForCallback}, connection, "SELECT * FROM furnitures WHERE owner = ? AND placed = 0", dbid)
end
addEvent("Furnitures->loadMyFurnitures", true)
addEventHandler("Furnitures->loadMyFurnitures", root, Furnitures.loadMyFurnitures)

function Furnitures.attachFurniture(player, furniture, data)
	if not canPlayerManageFurniture(player, furniture) then
		outputChatBox("You do not own this furniture or this property.", player, 255, 0, 0)
		return
	end

	attachedFurnitures[player] = furniture
	
	--attachElements(attachedFurnitures[player], player, 0, 1)
	setElementData(player, "Furniture->isFurnitureOnHand", true)
	setElementCollisionsEnabled(attachedFurnitures[player], false)
	
	-- Notify client that edit is allowed
	triggerClientEvent(player, "Furnitures->allowEdit", player)
end
addEvent("Furnitures->attachFurniture", true)
addEventHandler("Furnitures->attachFurniture", root, Furnitures.attachFurniture)

function Furnitures.setPosition(player,furniture,data)
	x,y,z,rot = unpack(data)
	setElementPosition(attachedFurnitures[player],x,y,z)
	--setElementRotation(attachedFurnitures[player],0,0,rot)
end
addEvent("Furnitures->setPos", true)
addEventHandler("Furnitures->setPos", root, Furnitures.setPosition)

function Furnitures.destroy(player, furniture)
	if not canPlayerManageFurniture(player, furniture) then
		outputChatBox("You do not own this furniture or this property.", player, 255, 0, 0)
		return
	end

	local playerID = getElementData(player, "dbid")
	setElementData(player, "Furniture->isFurnitureOnHand", false)

	-- Update ownership to the player picking it up, so it goes into THEIR inventory
	local furnID = getElementData(furniture, "Furnitures->id")
	dbExec(connection, "UPDATE furnitures SET placed = ?, owner = ? WHERE id = ?", 0, playerID, furnID)
	
	-- Update cached owner/data if needed, though destruction usually clears it from world
	-- We should also update cache table to reflect new owner for subsequent re-loads
	if cache[furnID] then
		cache[furnID].placed = 0
		cache[furnID].owner = playerID
	end

	if isElement(furniture) then destroyElement(furniture) end

	-- Refresh the player's furniture inventory list immediately
	Furnitures.loadMyFurnitures(playerID, player)
end
addEvent("Furnitures->destroyFurniture", true)
addEventHandler("Furnitures->destroyFurniture", root, Furnitures.destroy)

function Furnitures.drop(player, furniture, x,y,z,int,dim,rot)
	local id = getElementData(furniture, "Furnitures->id")
	
	-- We verify management permission on drop too, just in case
	if not canPlayerManageFurniture(player, furniture) then
		outputChatBox("You cannot place furniture here.", player, 255, 0, 0)
		return
	end

	attachedFurnitures[player] = nil
	detachElements(furniture, player)
	setElementPosition(furniture, x,y,z)
	setElementRotation(furniture, 0, 0, rot)
	setElementInterior(furniture,int)
	setElementDimension(furniture,dim)
	setElementCollisionsEnabled(furniture, true)
	

	dbExec(connection, "UPDATE furnitures SET x=?, y=?, z=?, interior=?, dimension=?, rotation=?, placed=1 WHERE id=?", x, y, z, int, dim, rot, id)

end
addEvent("Furnitures->drop", true)
addEventHandler("Furnitures->drop", root, Furnitures.drop)

-- Cancel placement (item was placed from inventory/shop) - return to inventory
function Furnitures.cancelPlace(player, furniture)
	if not isElement(furniture) then return end
	local id = getElementData(furniture, "Furnitures->id")
	if not id then return end

	attachedFurnitures[player] = nil
	setElementData(player, "Furniture->isFurnitureOnHand", false)

	-- Set placed=0 to return to inventory
	dbExec(connection, "UPDATE furnitures SET placed = 0 WHERE id = ?", id)

	if cache[id] then
		cache[id].placed = 0
	end

	if isElement(furniture) then destroyElement(furniture) end

	-- Refresh the player's furniture inventory list immediately
	local playerID = getElementData(player, "dbid")
	if playerID then
		Furnitures.loadMyFurnitures(playerID, player)
	end
end
addEvent("Furnitures->cancelPlace", true)
addEventHandler("Furnitures->cancelPlace", root, Furnitures.cancelPlace)

-- Cancel arrangement (existing furniture was being moved) - restore original position
function Furnitures.cancelArrange(player, furniture, origX, origY, origZ, origRot)
	if not isElement(furniture) then return end
	local id = getElementData(furniture, "Furnitures->id")

	attachedFurnitures[player] = nil
	setElementData(player, "Furniture->isFurnitureOnHand", false)

	-- Restore original position/rotation
	detachElements(furniture, player)
	setElementPosition(furniture, origX, origY, origZ)
	setElementRotation(furniture, 0, 0, origRot)
	setElementCollisionsEnabled(furniture, true)

	-- No DB update needed - position stays as it was before
end
addEvent("Furnitures->cancelArrange", true)
addEventHandler("Furnitures->cancelArrange", root, Furnitures.cancelArrange)

function Furnitures.buy(client, category, key)
	local category = tonumber(category)
	local key = tonumber(key)
	
	if not category or not key or not furnitures[category] or not furnitures[category][key] then
		return
	end

	local item = furnitures[category][key]
	local price = item.price
	local model = item.model
	
	if exports.global:takeMoney(client, price) then
		local owner = getElementData(client, "dbid")
		dbExec(connection, "INSERT INTO furnitures SET owner = ?, model = ?", owner, model)
		outputChatBox("[!]#ffffff Congratulations, you have successfully purchased the furniture!", client, 0, 255, 0, true)
		
		-- Refresh the player's furniture list if strictly needed, or let them do it.
		-- Based on original code, it didn't strictly auto-refresh instantly, but c_shop appended to myFurnitures.
		-- We can trigger an update if we want, but sticking to core logic first.
		Furnitures.loadMyFurnitures(owner)
	else
		outputChatBox("[!]#ffffff You don't have enough money!", client, 255, 0, 0, true)
	end
end
addEvent("Furnitures->buy", true)
addEventHandler("Furnitures->buy", root, Furnitures.buy)

function Furnitures.delete(id)
	dbExec(connection, "DELETE FROM furnitures WHERE id = ?", id)
	--dbExec(mysql:getConnection(),"DELETE FROM furnitures WHERE id='" .. (id) .. "' LIMIT 1")
end
addEvent("Furnitures->delete", true)
addEventHandler("Furnitures->delete", root, Furnitures.delete)

function findPriceByModel(model)
	for i, category in ipairs(furnitures) do
		for j, item in ipairs(category) do
			if item.model == model then
				return item.price
			end
		end
	end
	return 0
end

function Furnitures.sell(client, dbid)
    local dbid = tonumber(dbid)
    if not dbid or not cache[dbid] then return end
    
    local itemData = cache[dbid]
    local owner = tonumber(itemData.owner)
    
    -- Check ownership (this is usually called from inventory context)
    -- If selling from inventory, strict owner check is fine currently, 
    -- as we updated owner on pickup.
    if owner ~= getElementData(client, "dbid") and not exports.integration:isPlayerAdmin(client) then
        outputChatBox("You do not own this furniture.", client, 255, 0, 0)
        return
    end

    local price = findPriceByModel(itemData.model)
    local refund = math.floor(price * 0.6)

    if exports.global:giveMoney(client, refund) then
        outputChatBox("[Furniture] You sold the item for $" .. refund .. " (60% refund).", client, 0, 255, 0)
        
        -- Delete from DB and Cache
        Furnitures.delete(dbid)
        
        -- Remove from cache
        cache[dbid] = nil
        
        -- Refresh client
        Furnitures.loadMyFurnitures(owner)
    else
        outputChatBox("Error processing refund.", client, 255, 0, 0)
    end
end
addEvent("Furnitures->sell", true)
addEventHandler("Furnitures->sell", root, Furnitures.sell)

function Furnitures.create(player, data)
	local rot = getPedRotation(player)
	local x, y, z = getElementPosition(player)
	dbExec(connection, "UPDATE furnitures SET x = ?, y = ?, z = ?, rotation = ?, placed = ?, interior = ?, dimension = ? WHERE id = ?", x, y, z, rot, 1, getElementInterior(player), getElementDimension(player), data.id)

	local interior  = getElementInterior(player)
	local dimension = getElementDimension(player)
	local model 	= tonumber(data.model)
	local owner 	= tonumber(data.owner)
	------------------------------------------
	local obj = createObject(model, x, y, z, 0, 0, rot)
	setElementData(obj, "Furnitures->isFurniture", true)
	setElementData(obj, "Furnitures->id", tonumber(data.id))
	setElementData(obj, "Furnitures->owner", owner)
	setElementData(obj, "Furnitures->data", data)
	setElementDimension(obj, dimension)
	setElementInterior(obj, interior)
	setElementDoubleSided(obj, true)
	
	setElementData(obj, "Furniture->used", true)
	setElementData(player, "Furniture->isFurnitureOnHand", true)
	
	Furnitures.attachFurniture(player, obj, data)
	triggerClientEvent(player, "Furnitures->receiveElement", player, obj)
end
addEvent("Furnitures->create", true)
addEventHandler("Furnitures->create", root, Furnitures.create)

addEventHandler("onPlayerQuit", getRootElement(), function()
	local obj = attachedFurnitures[source]
	if obj then
		local data = getElementData(obj, "Furnitures->data") or {}
		setElementPosition(obj, data.x, data.y, data.z)
		setElementRotation(obj, data.rotation)
		
		setElementCollisionsEnabled(obj, true)
		setElementData(obj, "Furniture->used", false)
		attachedFurnitures[source] = nil
	end
end)
local hifiScale = {}
addEvent("Furnitures->playSound", true)
addEventHandler("Furnitures->playSound", root, function(_, data, object)
	if not canPlayerManageFurniture(client, object) then
		return
	end

	setElementData(object,"dbid",data.id)
	hifiScale[data.id] = setTimer(function(object1,dbid)
		setObjectScale(object,getObjectScale(object)+0.07)
		setTimer(function()
			setObjectScale(object1,getObjectScale(object1)-0.07)
		end,150,1,object1)
	end, 3500,0,object,data.id)
	triggerClientEvent(getRootElement(), "Furnitures->playSoundC", getRootElement(), data,object)
end)	

addEvent("Furnitures->removeSound", true)
addEventHandler("Furnitures->removeSound", root, function(_, data, object)
	if not canPlayerManageFurniture(client, object) then
		return
	end

	if isTimer(hifiScale[data.id]) then 
		killTimer(hifiScale[data.id])
	end
	triggerClientEvent(getRootElement(), "Furnitures->removeSoundC", getRootElement(), data,object)
end)

-- ============================================================================
-- FURNITURE ACCESS COMMANDS
-- Allows interior owners to grant/revoke furniture editing permissions
-- ============================================================================

-- /furnadd [player] - Grant furniture access to a player
addCommandHandler("furnadd", function(player, cmd, ...)
    local targetName = table.concat({...}, " ")
    
    if not targetName or targetName == "" then
        outputChatBox("SYNTAX: /" .. cmd .. " [player name/id]", player, 255, 194, 14)
        outputChatBox("Grants furniture editing access to the specified player for this interior.", player, 255, 194, 14)
        return
    end
    
    -- Check if player is inside an interior
    local dim = getElementDimension(player)
    if dim <= 0 then
        outputChatBox("You must be inside an interior to use this command.", player, 255, 0, 0)
        return
    end
    
    -- Get interior data
    local dbid, entrance, exit, type, interiorElement = exports['interior_system']:findProperty(player, dim)
    if not interiorElement then
        outputChatBox("Error: Could not find interior data.", player, 255, 0, 0)
        return
    end
    
    -- Check if player is the interior owner
    local interiorStatus = getElementData(interiorElement, "status")
    local interiorOwner = tonumber(interiorStatus.owner)
    local playerID = tonumber(getElementData(player, "dbid"))
    
    if interiorOwner ~= playerID and not exports.integration:isPlayerAdmin(player) then
        outputChatBox("Only the interior owner can grant furniture access.", player, 255, 0, 0)
        return
    end
    
    -- Find target player
    local targetPlayer, targetPlayerName = exports.global:findPlayerByPartialNick(player, targetName)
    if not targetPlayer then
        return -- findPlayerByPartialNick outputs its own error
    end
    
    local targetDBID = tonumber(getElementData(targetPlayer, "dbid"))
    if not targetDBID then
        outputChatBox("Target player has no valid character.", player, 255, 0, 0)
        return
    end
    
    -- Check if already has access
    if furnitureAccessList[dim] and furnitureAccessList[dim][targetDBID] then
        outputChatBox(targetPlayerName .. " already has furniture access to this interior.", player, 255, 194, 14)
        return
    end
    
    -- Grant access
    grantFurnitureAccess(dim, targetDBID)
    
    -- Sync to target player if they are in the same interior
    if getElementDimension(targetPlayer) == dim then
        triggerClientEvent(targetPlayer, "Furnitures->syncAccess", targetPlayer, true)
        triggerClientEvent(targetPlayer, "Furnitures->syncAccessList", targetPlayer, true)
    end
    
    outputChatBox("You have granted furniture access to " .. targetPlayerName .. ".", player, 0, 255, 0)
    outputChatBox("You have been granted furniture editing access by " .. getPlayerName(player):gsub("_", " ") .. ".", targetPlayer, 0, 255, 0)
end, false, false)

-- /furnremove [player] - Revoke furniture access from a player
addCommandHandler("furnremove", function(player, cmd, ...)
    local targetName = table.concat({...}, " ")
    
    if not targetName or targetName == "" then
        outputChatBox("SYNTAX: /" .. cmd .. " [player name/id]", player, 255, 194, 14)
        outputChatBox("Revokes furniture editing access from the specified player for this interior.", player, 255, 194, 14)
        return
    end
    
    -- Check if player is inside an interior
    local dim = getElementDimension(player)
    if dim <= 0 then
        outputChatBox("You must be inside an interior to use this command.", player, 255, 0, 0)
        return
    end
    
    -- Get interior data
    local dbid, entrance, exit, type, interiorElement = exports['interior_system']:findProperty(player, dim)
    if not interiorElement then
        outputChatBox("Error: Could not find interior data.", player, 255, 0, 0)
        return
    end
    
    -- Check if player is the interior owner
    local interiorStatus = getElementData(interiorElement, "status")
    local interiorOwner = tonumber(interiorStatus.owner)
    local playerID = tonumber(getElementData(player, "dbid"))
    
    if interiorOwner ~= playerID and not exports.integration:isPlayerAdmin(player) then
        outputChatBox("Only the interior owner can revoke furniture access.", player, 255, 0, 0)
        return
    end
    
    -- Find target player
    local targetPlayer, targetPlayerName = exports.global:findPlayerByPartialNick(player, targetName)
    if not targetPlayer then
        return -- findPlayerByPartialNick outputs its own error
    end
    
    local targetDBID = tonumber(getElementData(targetPlayer, "dbid"))
    if not targetDBID then
        outputChatBox("Target player has no valid character.", player, 255, 0, 0)
        return
    end
    
    -- Check if player has access
    if not furnitureAccessList[dim] or not furnitureAccessList[dim][targetDBID] then
        outputChatBox(targetPlayerName .. " does not have furniture access to this interior.", player, 255, 194, 14)
        return
    end
    
    -- Revoke access
    revokeFurnitureAccess(dim, targetDBID)
    
    -- Sync to target player if they are in the same interior
    if getElementDimension(targetPlayer) == dim then
        triggerClientEvent(targetPlayer, "Furnitures->syncAccess", targetPlayer, false)
        triggerClientEvent(targetPlayer, "Furnitures->syncAccessList", targetPlayer, false)
    end
    
    outputChatBox("You have revoked furniture access from " .. targetPlayerName .. ".", player, 0, 255, 0)
    outputChatBox("Your furniture editing access has been revoked by " .. getPlayerName(player):gsub("_", " ") .. ".", targetPlayer, 255, 194, 14)
end, false, false)
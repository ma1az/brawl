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

--Jesse [LOG]
--!!!!! !!!!!---
-- Örnek tablo verisi: {furnitures: {id,x,y,z,interior,dimension,rotation,model,owner,placed,texture} }
--!!!!! !!!!!---
--Jesse [LOG]

Furnitures = {}
local attachedFurnitures = {}
local cache = {}
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

function Furnitures.loadMyFurnitures(dbid)
	if not dbid then return end
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
		end

	end, {source}, connection, "SELECT * FROM furnitures WHERE owner = ? AND placed = 0", dbid)
end
addEvent("Furnitures->loadMyFurnitures", true)
addEventHandler("Furnitures->loadMyFurnitures", root, Furnitures.loadMyFurnitures)

function Furnitures.attachFurniture(player, furniture, data)
	local owner = getElementData(furniture, "Furnitures->owner")
	local playerID = getElementData(player, "dbid")
	if owner ~= playerID and not exports.integration:isPlayerAdmin(player) then
		outputChatBox("You do not own this furniture.", player, 255, 0, 0)
		return
	end

	attachedFurnitures[player] = furniture
	
	--attachElements(attachedFurnitures[player], player, 0, 1)
	setElementData(player, "Furniture->isFurnitureOnHand", true)
	setElementCollisionsEnabled(attachedFurnitures[player], false)
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
	local owner = getElementData(furniture, "Furnitures->owner")
	local playerID = getElementData(player, "dbid")
	if owner ~= playerID and not exports.integration:isPlayerAdmin(player) then
		outputChatBox("You do not own this furniture.", player, 255, 0, 0)
		return
	end

	setElementData(player, "Furniture->isFurnitureOnHand", false)
	dbExec(connection, "UPDATE furnitures SET placed = ? WHERE id = ?", 0, getElementData(furniture, "Furnitures->id"))
	if isElement(furniture) then destroyElement(furniture) end
end
addEvent("Furnitures->destroyFurniture", true)
addEventHandler("Furnitures->destroyFurniture", root, Furnitures.destroy)

function Furnitures.drop(player, furniture, x,y,z,int,dim,rot)
	local id = getElementData(furniture, "Furnitures->id")
	local owner = getElementData(furniture, "Furnitures->owner")
	local playerID = getElementData(player, "dbid")
	
	if owner ~= playerID and not exports.integration:isPlayerAdmin(player) then
		outputChatBox("You do not own this furniture.", player, 255, 0, 0)
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

	if isTimer(hifiScale[data.id]) then 
		killTimer(hifiScale[data.id])
	end
	triggerClientEvent(getRootElement(), "Furnitures->removeSoundC", getRootElement(), data,object)
end)
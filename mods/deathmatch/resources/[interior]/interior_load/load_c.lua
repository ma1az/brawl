--[[
* ***********************************************************************************************************************
* Copyright (c) 2015 Brawl Roleplay - All Rights Reserved
* All rights reserved. This program and the accompanying materials are private property belongs to Brawl Roleplay
* Unauthorized copying of this file, via any medium is strictly prohibited
* Proprietary and confidential
* ***********************************************************************************************************************
]]

-- Defines
INTERIOR_X = 1
INTERIOR_Y = 2
INTERIOR_Z = 3
INTERIOR_INT = 4
INTERIOR_DIM = 5
INTERIOR_ANGLE = 6
INTERIOR_FEE = 7

INTERIOR_TYPE = 1
INTERIOR_DISABLED = 2
INTERIOR_LOCKED = 3
INTERIOR_OWNER = 4
INTERIOR_COST = 5
INTERIOR_SUPPLIES = 6
INTERIOR_FACTION = 7

local streamdistance = 50
local pickupStreamDistance = 250 -- Only create pickups for interiors within this distance
local elevatorsSpawned = { }
local interiorsSpawned = {}
local intsToBeLoaded = {}
local elevatorsToBeLoaded = {}
local done = 0
local debugmode = false

local pickupRefreshRate = 500

function checkNearbyInteriorPickups()
    if getElementData(localPlayer, "account:id") then--== 1 or exports.account:screenStandBy("getState") then
        local px, py, pz = getElementPosition(localPlayer)
        local playerInt = getElementInterior(localPlayer)
        local playerDim = getElementDimension(localPlayer)

        -- Create pickups for nearby interiors
        for interior,_ in pairs(intsToBeLoaded) do
            local dbid = isElement(interior) and getElementData(interior, "dbid") or 0
            if dbid and not interiorsSpawned[ dbid ] then
                local entrance = isElement(interior) and getElementData(interior, "entrance")
                local exit = isElement(interior) and getElementData(interior, "exit")
                if entrance then
                    local ex = entrance.x or entrance[INTERIOR_X]
                    local ey = entrance.y or entrance[INTERIOR_Y]
                    local ez = entrance.z or entrance[INTERIOR_Z]
                    -- Also check exit position for players inside interiors
                    local exitX = exit and (exit.x or exit[INTERIOR_X])
                    local exitY = exit and (exit.y or exit[INTERIOR_Y])
                    local exitZ = exit and (exit.z or exit[INTERIOR_Z])
                    local nearEntrance = false
                    local nearExit = false
                    if ex and ey and ez then
                        nearEntrance = getDistanceBetweenPoints3D(px, py, pz, ex, ey, ez) <= pickupStreamDistance
                    end
                    if exitX and exitY and exitZ and playerDim > 0 then
                        nearExit = getDistanceBetweenPoints3D(px, py, pz, exitX, exitY, exitZ) <= pickupStreamDistance
                    end
                    if nearEntrance or nearExit then
                        interiorShowPickups( interior )
                        intsToBeLoaded[ interior ] = nil
                    end
                end
            end
        end

        -- Remove pickups for far-away interiors to free elements
        -- Skip cleanup if player is inside an interior (dim > 0) to preserve exit pickups
        if playerDim == 0 then
            for dbid, pickups in pairs(interiorsSpawned) do
                if pickups and type(pickups) == "table" and pickups[1] and isElement(pickups[1]) then
                    local pickupDim = getElementDimension(pickups[1])
                    -- Only clean up pickups that are in the same dimension as the player (exterior)
                    if pickupDim == 0 then
                        local ex, ey, ez = getElementPosition(pickups[1])
                        local dist = getDistanceBetweenPoints3D(px, py, pz, ex, ey, ez)
                        if dist > pickupStreamDistance * 1.5 then
                            -- Find the interior element to re-queue it
                            for _, int in ipairs(getElementsByType("interior")) do
                                if getElementData(int, "dbid") == dbid then
                                    intsToBeLoaded[int] = true
                                    break
                                end
                            end
                            -- Destroy the pickups
                            if pickups[1] and isElement(pickups[1]) then destroyElement(pickups[1]) end
                            if pickups[2] and isElement(pickups[2]) then destroyElement(pickups[2]) end
                            interiorsSpawned[dbid] = nil
                            done = done - 1
                        end
                    end
                end
            end
        end
    end
    setTimer(checkNearbyInteriorPickups, pickupRefreshRate, 1)
end
setTimer(checkNearbyInteriorPickups, pickupRefreshRate, 1)

function checkNearbyElevatorPickups()
    if getElementData(localPlayer, "account:id") then--== 1 or exports.account:screenStandBy("getState") then
        local px, py, pz = getElementPosition(localPlayer)
        for elevator,_ in pairs(elevatorsToBeLoaded) do
            if isElement(elevator) and getElementChildrenCount(elevator) ~= 2 then
                local entrance = getElementData(elevator, "entrance")
                if entrance then
                    local ex = entrance[1] or entrance[INTERIOR_X]
                    local ey = entrance[2] or entrance[INTERIOR_Y]
                    local ez = entrance[3] or entrance[INTERIOR_Z]
                    if ex and ey and ez then
                        local dist = getDistanceBetweenPoints3D(px, py, pz, ex, ey, ez)
                        if dist <= pickupStreamDistance then
                            interiorShowPickups(elevator)
                            elevatorsToBeLoaded[elevator] = nil
                        end
                    end
                end
            end
        end
    end
    setTimer(checkNearbyElevatorPickups, pickupRefreshRate, 1)
end
setTimer(checkNearbyElevatorPickups, math.ceil(pickupRefreshRate+(pickupRefreshRate/2)), 1)

function interiorShowPickups(element)
    if not isElement(element) then return end
    local dbid = getElementData(element, "dbid")
    local outsidePickup

    if getElementType( element ) == "elevator" then
        if getElementChildrenCount(element) == 2 then --if elevatorsSpawned[dbid] then
            if debugmode then
            outputDebugString("interiorShowPickups returning with  "..tostring(dbid) ..": false, 1" )
            end
            return false, 1
        end
    else
        if interiorsSpawned[dbid] then
            outputDebugString("interiorShowPickups returning with  "..tostring(dbid) ..": false, 2" )
            return false, 2
        end
    end

    local entrance = getElementData( element, "entrance" )
    local exit = getElementData( element, "exit" )
    local int = getElementData( element, "status" )

    if not entrance  then
        outputDebugString("interiorShowPickups returning with  "..tostring(dbid) ..": false, 3" )
        return false, 3
    end

    if not exit  then
        outputDebugString("interiorShowPickups returning with  "..tostring(dbid) ..": false, 4" )
        return false, 4
    end

    if not int  then
        outputDebugString("interiorShowPickups returning with  "..tostring(dbid) ..": false, 5" )
        return false, 5
    end

	local obj =  1318--1316 --1559 --


    if getElementType( element ) == "elevator" then
        outsidePickup = createPickup( entrance[INTERIOR_X], entrance[INTERIOR_Y], entrance[INTERIOR_Z], 3, int[INTERIOR_DISABLED] and 1314 or ( getElementType( element ) == "elevator" and obj or ( int[INTERIOR_TYPE] == 2 and obj  or ( int[INTERIOR_OWNER] < 1 and int[INTERIOR_FACTION] < 1 and ( int[INTERIOR_TYPE] == 1 and 1272 or 1273 ) or obj  ) ) ) )

        if not outsidePickup then
            outputDebugString("interiorShowPickups returning with  "..tostring(dbid) ..": false, 6" )
            return false, 6
        end

        setElementParent(outsidePickup,  element )
        setElementInterior(outsidePickup, entrance[INTERIOR_INT])
        setElementDimension(outsidePickup, entrance[INTERIOR_DIM])
        setElementData(outsidePickup, "dim", entrance[INTERIOR_DIM], false)

        local insidePickup = createPickup( exit[INTERIOR_X], exit[INTERIOR_Y], exit[INTERIOR_Z], 3,  obj )
        setElementParent(insidePickup,  element )
        setElementInterior(insidePickup, exit[INTERIOR_INT])
        setElementDimension(insidePickup, exit[INTERIOR_DIM])
        setElementData(insidePickup, "dim", exit[INTERIOR_DIM], false)

        setElementData(insidePickup, "other", outsidePickup, false)
        setElementData(outsidePickup, "other", insidePickup, false)

        setElementData(insidePickup, "type", "exit", false)
        setElementData(outsidePickup, "type", "entrance", false)

        if getElementType( element ) == "elevator" then
            elevatorsSpawned[dbid] = { outsidePickup, insidePickup }
        else
            interiorsSpawned[dbid] = { outsidePickup, insidePickup }
        end

        done = done + 1
        if debugmode then
            outputDebugString("interiorShowPickups returning with  "..tostring(dbid) ..": true, "..getElementType( element ) == "interior" and 1 or 2 )
        end
        return true, getElementType( element ) == "interior" and 1 or 2
    else
        outsidePickup = entrance.x and createPickup( entrance.x, entrance.y, entrance.z, 3, int.disabled and 1314 or ( getElementType(element) == "elevator" and obj or ( int.type == 2 and obj  or ( int.owner < 1 and int.faction < 1 and ( int.type == 1 and 1272 or 1273 ) or obj  ) ) ) )

        if not outsidePickup then
            outputDebugString("interiorShowPickups returning with  "..tostring(dbid) ..": false, 6" )
            return false, 6
        end

        setElementParent(outsidePickup, element)
        setElementInterior(outsidePickup, entrance.int)
        setElementDimension(outsidePickup, entrance.dim)
        setElementData(outsidePickup, "dim", entrance.dim, false)

        local insidePickup = createPickup( exit.x, exit.y, exit.z, 3,  obj )
        setElementParent(insidePickup, element)
        setElementInterior(insidePickup, exit.int)
        setElementDimension(insidePickup, exit.dim)
        setElementData(insidePickup, "dim", exit.dim, false)

        setElementData(insidePickup, "other", outsidePickup, false)
        setElementData(outsidePickup, "other", insidePickup, false)

        if getElementType(element) == "elevator" then
            elevatorsSpawned[dbid] = { outsidePickup, insidePickup }
        else
            interiorsSpawned[dbid] = { outsidePickup, insidePickup }
        end

        done = done + 1
        if debugmode then
            outputDebugString("interiorShowPickups returning with  "..tostring(dbid) ..": true, "..getElementType(element) == "interior" and 1 or 2 )
        end
        return true, getElementType(element) == "interior" and 1 or 2
    end
end

function interiorRemovePickups(element)
    local dbid = getElementData(element, "dbid")

    if debugmode then
        outputDebugString("interiorRemovePickups running with  "..tostring(dbid) .." ".. getElementType( element ) == "elevator" and  "(elevator)" or "(interior)" )
    end

    if getElementType( element ) == "interior" then
        if not interiorsSpawned[dbid] then
            if debugmode then
                outputDebugString("interiorRemovePickups returning with  "..tostring(dbid) ..": false,  1" )
            end
            return false, 1
        end

        if interiorsSpawned[dbid][1] and isElement( interiorsSpawned[dbid][1] ) then
            destroyElement( interiorsSpawned[dbid][1] )
        end
        if interiorsSpawned[dbid][2] and isElement( interiorsSpawned[dbid][2] ) then
            destroyElement( interiorsSpawned[dbid][2] )
        end

        interiorsSpawned[dbid] = nil
        done = done - 1
        if debugmode then
            outputDebugString("interiorRemovePickups finished resulting on  "..tostring(dbid) .." true, 1" )
        end

        return true, 1
    elseif getElementType( element ) == "elevator" then
        if getElementChildrenCount(element) == 2 then
            if debugmode then
                outputDebugString("interiorRemovePickups returning with  "..tostring(dbid) ..": false,  2" )
            end
            return false, 2
        end
        if elevatorsSpawned[dbid] then
            if isElement(elevatorsSpawned[dbid][1]) then
                destroyElement( elevatorsSpawned[dbid][1])
            end
            if isElement(elevatorsSpawned[dbid][2]) then
                destroyElement( elevatorsSpawned[dbid][2])
            end
        end
        elevatorsSpawned[dbid] = nil
        done = done - 1
        if debugmode then
            outputDebugString("interiorRemovePickups finished resulting on  "..tostring(dbid) .." true, 2" )
        end
        return true, 2
    else
        outputDebugString(" interiorRemovePickupsFail? ")
        outputDebugString("---")
        outputDebugString(tostring(element))
        outputDebugString(tostring(getElementType(element)))
        outputDebugString(tostring(dbid))
        outputDebugString("---")
    end

    if debugmode then
        outputDebugString("interiorRemovePickups finished without result on  "..tostring(dbid) )
    end
    return true
end

function isPickupStreamable(pickup)
    local x,y,z = getElementPosition(pickup)
    if(x > 4092 or x < -4092 or y > 4092 or y < -4092) then
        return false
    end
    return true
end

function stopFakeRotation()
    killTimer(rotateFakeTimer)
    rotateFakeTimer = nil
    outputChatBox("FakeRot timer stopped.")
end
addCommandHandler("stopfakerot", stopFakeRotation)

function schedulePickupLoading( element )
    if element and isElement( element ) then
        -- outputDebugString("schedulePickupLoading("..tostring(element)..")")
        if getElementType( element ) == 'interior' then
            intsToBeLoaded[element] = true
            interiorsSpawned[ getElementData( element, 'dbid' ) or 0 ] = nil
        elseif getElementType( element ) == 'elevator' then
            if not elevatorsToBeLoaded[element] then
                elevatorsToBeLoaded[element] = true
            end
        end
    end
end
addEvent("interior:schedulePickupLoading",true)
addEventHandler("interior:schedulePickupLoading", root, schedulePickupLoading)

function clearElevators()
    elevatorsToBeLoaded = {}
    elevatorsSpawned = {}
end
addEvent("interior:clearElevators",true)
addEventHandler("interior:clearElevators", root,clearElevators)

addEventHandler("onClientResourceStop", getResourceRootElement(getResourceFromName("elevator-system")),
    function(stoppedRes)
        clearElevators()
    end
);

function forcePickupSpawn()
    if exports.integration:isPlayerScripter(localPlayer) then
        interior_initializeSoFar()
    end
end
addCommandHandler("forcepickupspawn", forcePickupSpawn)

function interior_initializeSoFar( forced )
    for _, interior in ipairs( getElementsByType("interior") ) do
        if forced or ( not intsToBeLoaded[ interior ] and not interiorsSpawned[ getElementData(interior, "dbid") or 0 ] ) then
            intsToBeLoaded[interior] = true
        end
    end
end
addEvent( "interior:initializeSoFar", true)
addEventHandler( "interior:initializeSoFar", root, interior_initializeSoFar )


function elevator_initializeSoFar( forced )
    for _, elevator in ipairs(getElementsByType("elevator")) do
        if forced or ( not elevatorsToBeLoaded[ elevator ] and not elevatorsSpawned[ getElementData(elevator, "dbid") or 0 ] ) then
            elevatorsToBeLoaded[elevator] = true
        end
    end
end
addEvent("elevator:initializeSoFar",true)
addEventHandler("elevator:initializeSoFar", root,elevator_initializeSoFar)


addEventHandler( 'onClientElementDestroy', root, function()
    if source and isElement( source ) then
        local dbid = getElementData( source, 'dbid' ) or 0
        if getElementType( source ) == "interior" then
            interiorRemovePickups( source )
            interiorsSpawned[ dbid ] = nil
        elseif getElementType( source ) == "elevator" then
            interiorRemovePickups( source )
            elevatorsSpawned[ dbid ] = nil
        end
    end
end )

addEventHandler("onClientResourceStart", getResourceRootElement( getResourceFromName( 'interior_system') ),
    function( )
        for _, interior in ipairs(getElementsByType("interior")) do
            intsToBeLoaded[interior] = true
            interiorsSpawned[ getElementData(interior,'dbid') ] = false
        end
    end
)

addEventHandler("onClientResourceStart", getResourceRootElement( getResourceFromName( 'elevator-system') ),
    function( )
        for _, elevator in ipairs(getElementsByType("elevator")) do
            elevatorsToBeLoaded[elevator] = true
            elevatorsSpawned[ getElementData(elevator,'dbid') ] = false
        end
    end
)

addEventHandler( 'onClientResourceStart', resourceRoot, function()
    setTimer( elevator_initializeSoFar, 2000, 1, true )
    setTimer( interior_initializeSoFar, 2000, 1, true )
end )

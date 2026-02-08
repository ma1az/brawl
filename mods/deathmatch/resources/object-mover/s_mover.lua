-- ============================================================
-- Object Mover – Server
-- Receives position/rotation updates and the final save event.
-- ============================================================

-- Relay position updates so all clients see the object moving
addEvent("objectMover:syncPos", true)
addEventHandler("objectMover:syncPos", root, function(object, x, y, z, rx, ry, rz)
	if not isElement(object) then return end
	setElementPosition(object, x, y, z)
	setElementRotation(object, rx, ry, rz)
end)

-- When the player confirms ("F") or cancels ("Left Click"), the client
-- tells us.  We forward a custom event so the calling resource can react.
addEvent("objectMover:saved", true)
addEventHandler("objectMover:saved", root, function(object, x, y, z, rx, ry, rz)
	-- Forward to all listening resources (server-side)
	triggerEvent("objectMover:onSaved", root, client, object, x, y, z, rx, ry, rz)
end)

addEvent("objectMover:cancelled", true)
addEventHandler("objectMover:cancelled", root, function(object, ox, oy, oz, orx, ory, orz)
	-- Restore original position
	if isElement(object) then
		setElementPosition(object, ox, oy, oz)
		setElementRotation(object, orx, ory, orz)
	end
	triggerEvent("objectMover:onCancelled", root, client, object)
end)

-- These are the events other resources listen for
addEvent("objectMover:onSaved", false)
addEvent("objectMover:onCancelled", false)

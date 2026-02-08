-- ============================================================
-- Item Move – Editor (rewritten to use object-mover)
-- ============================================================
-- All callers still trigger the same 'item:move' event with an
-- object element.  We hand off to the object-mover resource
-- for the actual movement UI and feed the result back into the
-- existing 'item:move:save' server event so the item-system DB
-- logic is unchanged.
-- ============================================================

local moverResourceName = "object-mover"

local function isMoverAvailable()
  local res = getResourceFromName(moverResourceName)
  return res and getResourceState(res) == "running"
end

local function startMoverForObject(object)
  if not isElement(object) or getElementType(object) ~= "object" then
    return false
  end

  -- Keypad door lock – never allow movement
  local itemID = getElementData(object, "itemID")
  if itemID == 169 then
    return false
  end

  if not isMoverAvailable() then
    outputChatBox("[Item Move] object-mover resource is not running. Contact an admin.", 255, 0, 0)
    return false
  end

  outputChatBox("Moving item. Use the on-screen controls to position it.", 255, 194, 14)

  exports[moverResourceName]:startObjectMove(object, {
    onSave = function(obj, cx, cy, cz, rx, ry, rz)
      if isElement(obj) then
        setElementCollisionsEnabled(obj, true)
        triggerServerEvent("item:move:save", obj, cx, cy, cz, rx, ry, rz)
        outputChatBox("Item position saved.", 0, 255, 0)
      end
    end,
    onCancel = function(obj)
      if isElement(obj) then
        setElementCollisionsEnabled(obj, true)
      end
      outputChatBox("Item movement cancelled.", 255, 194, 14)
    end,
  })
  return true
end

-- ============================================================
-- The canonical 'item:move' event that every resource triggers
-- ============================================================

addEvent('item:move', true)
addEventHandler('item:move', root,
  function(object)
    startMoverForObject(object)
  end, false
)

-- Keep the protect event so P-key protect still works
addEvent('item:move:protect', true)
addEventHandler('item:move:protect', root,
  function()
    triggerServerEvent("protectItem", source, fp)
  end)

-- Clean up on resource stop
addEventHandler('onClientResourceStop', resourceRoot,
  function()
    if isMoverAvailable() and exports[moverResourceName]:isMoving() then
      exports[moverResourceName]:stopObjectMove()
    end
    setElementFrozen(localPlayer, false)
    if getElementAlpha(localPlayer) ~= 255 then
      setElementAlpha(localPlayer, 255)
    end
  end
)

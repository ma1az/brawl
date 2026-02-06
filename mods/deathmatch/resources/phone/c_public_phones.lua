-- MAXIME
local sx, sy = guiGetScreenSize()

function drawPublicPhoneHolograms()
    for _, col in ipairs(getElementsByType("colshape", resourceRoot)) do
        local dbid = getElementData(col, "dbid")
        if dbid then
            local x, y, z = getElementPosition(col)
            local cx, cy, cz = getCameraMatrix()
            local distance = getDistanceBetweenPoints3D(x, y, z, cx, cy, cz)

            if distance <= 30 then
                local px, py = getScreenFromWorldPosition(x, y, z + 1)
                if px and py then
                    local scale = 1 - (distance / 30)
                    if scale > 0.2 then
                        dxDrawText("Public Phone", px + 1, py + 1, px + 1, py + 1, tocolor(0, 0, 0, 255 * scale), 2.5 * scale, "default-bold", "center", "bottom")
                        dxDrawText("Public Phone", px, py, px, py, tocolor(255, 255, 255, 255 * scale), 2.5 * scale, "default-bold", "center", "bottom")
                        
                        dxDrawText("/call <number>", px + 1, py + 1, px + 1, py + 1, tocolor(0, 0, 0, 200 * scale), 2.0 * scale, "default", "center", "top")
                        dxDrawText("/call <number>", px, py, px, py, tocolor(235, 235, 235, 200 * scale), 2.0 * scale, "default", "center", "top")
                    end
                end
            end
        end
    end
end
addEventHandler("onClientRender", root, drawPublicPhoneHolograms)

bindKey("jump", "down",
    function()
        if getElementData(localPlayer, "call.col") then
            triggerServerEvent("phone:cancelPhoneCall", localPlayer)
        end
    end
)

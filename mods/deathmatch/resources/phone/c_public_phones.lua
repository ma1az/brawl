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

                        dxDrawText("Right-click or /call <number>", px + 1, py + 1, px + 1, py + 1, tocolor(0, 0, 0, 200 * scale), 2.0 * scale, "default", "center", "top")
                        dxDrawText("Right-click or /call <number>", px, py, px, py, tocolor(235, 235, 235, 200 * scale), 2.0 * scale, "default", "center", "top")
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

-- ============================================================
-- RIGHT-CLICK CONTEXT MENU FOR PUBLIC PHONES
-- ============================================================
function publicPhoneRightClick(button, state, absX, absY, wx, wy, wz, element)
    if button ~= "right" or state ~= "down" then return end

    local nearbyCol = nil
    for _, col in ipairs(getElementsByType("colshape", resourceRoot)) do
        if isElementWithinColShape(localPlayer, col) then
            nearbyCol = col
            break
        end
    end

    if not nearbyCol then return end
    if getElementData(localPlayer, "calling") then return end

    local rcMenu = exports.rightclick:create("Public Phone")

    local rowCall = exports.rightclick:addRow("Make a Call")
    addEventHandler("onClientGUIClick", rowCall, function(btn)
        if btn == "left" then
            exports.rightclick:destroy(rcMenu)
            openDialPadUI()
        end
    end, false)

    local rowClose = exports.rightclick:addRow("Close")
    addEventHandler("onClientGUIClick", rowClose, function(btn)
        if btn == "left" then
            exports.rightclick:destroy(rcMenu)
        end
    end, false)
end
addEventHandler("onClientClick", root, publicPhoneRightClick)

-- ============================================================
-- SHARED THEME COLORS
-- ============================================================
local COL_BG          = tocolor(25, 28, 30, 240)
local COL_HEADER      = tocolor(18, 20, 22, 255)
local COL_DISPLAY_BG  = tocolor(40, 44, 48, 255)
local COL_DISPLAY_TXT = tocolor(160, 240, 160, 255)
local COL_PLACEHOLDER = tocolor(100, 100, 100, 180)
local COL_BTN         = tocolor(50, 54, 58, 255)
local COL_BTN_HOVER   = tocolor(72, 78, 84, 255)
local COL_BTN_TXT     = tocolor(240, 240, 240, 255)
local COL_BTN_SUB     = tocolor(140, 145, 150, 255)
local COL_CALL_BTN    = tocolor(28, 120, 55, 255)
local COL_CALL_HOVER  = tocolor(38, 165, 70, 255)
local COL_DEL_BTN     = tocolor(150, 95, 18, 255)
local COL_DEL_HOVER   = tocolor(195, 125, 25, 255)
local COL_CLOSE_BTN   = tocolor(130, 28, 28, 255)
local COL_CLOSE_HOVER = tocolor(175, 38, 38, 255)
local COL_HANGUP_BTN  = tocolor(160, 30, 30, 255)
local COL_HANGUP_HOVER= tocolor(200, 40, 40, 255)
local COL_TITLE       = tocolor(190, 195, 200, 255)
local COL_ERROR       = tocolor(255, 75, 75, 255)
local COL_SEPARATOR   = tocolor(60, 65, 70, 200)
local COL_GLOW        = tocolor(50, 130, 70, 60)
local COL_WHITE       = tocolor(240, 240, 240, 255)
local COL_YELLOW      = tocolor(255, 210, 80, 255)
local COL_GREEN       = tocolor(100, 220, 100, 255)
local COL_DIM         = tocolor(130, 135, 140, 255)
local COL_COST        = tocolor(255, 180, 80, 255)

-- ============================================================
-- LAYOUT CONSTANTS
-- ============================================================
local PAD_W = 270
local PAD_H = 432
local PAD_X = (sx - PAD_W) / 2
local PAD_Y = (sy - PAD_H) / 2

-- Forward-declare callScreen so functions above can reference it
local callScreen

-- ============================================================
-- HELPERS
-- ============================================================
local function isMouseIn(rx, ry, rw, rh)
    if not isCursorShowing() then return false end
    local cx, cy = getCursorPosition()
    if not cx then return false end
    cx, cy = cx * sx, cy * sy
    return cx >= rx and cx <= rx + rw and cy >= ry and cy <= ry + rh
end

local function drawRRect(x, y, w, h, color, r)
    r = r or 4
    dxDrawRectangle(x + r, y, w - 2 * r, h, color)
    dxDrawRectangle(x, y + r, w, h - 2 * r, color)
    dxDrawRectangle(x + 1, y + 1, r, r, color)
    dxDrawRectangle(x + w - r - 1, y + 1, r, r, color)
    dxDrawRectangle(x + 1, y + h - r - 1, r, r, color)
    dxDrawRectangle(x + w - r - 1, y + h - r - 1, r, r, color)
end

-- ============================================================
-- DX DIAL PAD UI (number entry screen)
-- ============================================================
local dialPad = {
    visible    = false,
    number     = "",
    errorMsg   = nil,
    errorTimer = nil,
}

local numButtons    = {}
local actionButtons = {}

local function buildButtonLayout()
    numButtons    = {}
    actionButtons = {}

    local labels = {
        { "1", "" },    { "2", "ABC" },  { "3", "DEF" },
        { "4", "GHI" }, { "5", "JKL" },  { "6", "MNO" },
        { "7", "PQRS" },{ "8", "TUV" },  { "9", "WXYZ" },
        { "*", "" },    { "0", "" },     { "#", "" },
    }

    local btnW, btnH = 68, 54
    local gap = 9
    local cols = 3
    local gridW = cols * btnW + (cols - 1) * gap
    local startX = PAD_X + (PAD_W - gridW) / 2
    local startY = PAD_Y + 100

    for i, info in ipairs(labels) do
        local row = math.floor((i - 1) / 3)
        local col = (i - 1) % 3
        table.insert(numButtons, {
            x = startX + col * (btnW + gap),
            y = startY + row * (btnH + gap),
            w = btnW, h = btnH,
            digit = info[1], sub = info[2],
        })
    end

    local actY = startY + 4 * (btnH + gap) + 10
    local actW = (gridW - 2 * gap) / 3
    local actH = 44

    actionButtons = {
        { x = startX,                    y = actY, w = actW, h = actH, label = "DEL",   action = "del" },
        { x = startX + actW + gap,       y = actY, w = actW, h = actH, label = "CALL",  action = "call" },
        { x = startX + 2*(actW + gap),   y = actY, w = actW, h = actH, label = "CLOSE", action = "close" },
    }
end
buildButtonLayout()

function openDialPadUI()
    if dialPad.visible or callScreen.visible then return end
    dialPad.visible  = true
    dialPad.number   = ""
    dialPad.errorMsg = nil
    showCursor(true)
    addEventHandler("onClientRender", root, renderDialPad)
    addEventHandler("onClientClick",  root, dialPadClick)
end

function closeDialPadUI()
    if not dialPad.visible then return end
    dialPad.visible  = false
    dialPad.number   = ""
    dialPad.errorMsg = nil
    if dialPad.errorTimer and isTimer(dialPad.errorTimer) then
        killTimer(dialPad.errorTimer)
        dialPad.errorTimer = nil
    end
    removeEventHandler("onClientRender", root, renderDialPad)
    removeEventHandler("onClientClick",  root, dialPadClick)
    showCursor(false)
end

function renderDialPad()
    if not dialPad.visible then return end

    -- Shadow
    dxDrawRectangle(PAD_X + 4, PAD_Y + 4, PAD_W, PAD_H, tocolor(0, 0, 0, 80))
    -- Background
    drawRRect(PAD_X, PAD_Y, PAD_W, PAD_H, COL_BG, 6)
    -- Header
    drawRRect(PAD_X, PAD_Y, PAD_W, 40, COL_HEADER, 6)
    dxDrawRectangle(PAD_X, PAD_Y + 34, PAD_W, 6, COL_HEADER)
    dxDrawText("PUBLIC PHONE", PAD_X, PAD_Y + 5, PAD_X + PAD_W, PAD_Y + 40,
        COL_TITLE, 1.2, "default-bold", "center", "center")
    dxDrawRectangle(PAD_X + 15, PAD_Y + 42, PAD_W - 30, 1, COL_SEPARATOR)

    -- Display
    local dX, dY, dW, dH = PAD_X + 20, PAD_Y + 52, PAD_W - 40, 38
    drawRRect(dX, dY, dW, dH, COL_DISPLAY_BG, 4)

    if dialPad.errorMsg then
        dxDrawText(dialPad.errorMsg, dX, dY, dX + dW, dY + dH,
            COL_ERROR, 1.3, "default-bold", "center", "center")
    elseif #dialPad.number == 0 then
        dxDrawText("Enter number...", dX, dY, dX + dW, dY + dH,
            COL_PLACEHOLDER, 1.1, "default", "center", "center")
    else
        dxDrawText(dialPad.number, dX, dY, dX + dW, dY + dH,
            COL_DISPLAY_TXT, 1.4, "default-bold", "center", "center")
    end

    -- Number buttons
    for _, btn in ipairs(numButtons) do
        local hover = isMouseIn(btn.x, btn.y, btn.w, btn.h)
        drawRRect(btn.x, btn.y, btn.w, btn.h, hover and COL_BTN_HOVER or COL_BTN, 5)
        if btn.sub ~= "" then
            dxDrawText(btn.digit, btn.x, btn.y + 3, btn.x + btn.w, btn.y + btn.h * 0.58,
                COL_BTN_TXT, 1.6, "default-bold", "center", "center")
            dxDrawText(btn.sub, btn.x, btn.y + btn.h * 0.48, btn.x + btn.w, btn.y + btn.h - 3,
                COL_BTN_SUB, 0.85, "default", "center", "center")
        else
            dxDrawText(btn.digit, btn.x, btn.y, btn.x + btn.w, btn.y + btn.h,
                COL_BTN_TXT, 1.6, "default-bold", "center", "center")
        end
    end

    -- Action buttons
    for _, btn in ipairs(actionButtons) do
        local hover = isMouseIn(btn.x, btn.y, btn.w, btn.h)
        local bg
        if btn.action == "call" then
            bg = hover and COL_CALL_HOVER or COL_CALL_BTN
            if hover then drawRRect(btn.x - 2, btn.y - 2, btn.w + 4, btn.h + 4, COL_GLOW, 6) end
        elseif btn.action == "del" then
            bg = hover and COL_DEL_HOVER or COL_DEL_BTN
        else
            bg = hover and COL_CLOSE_HOVER or COL_CLOSE_BTN
        end
        drawRRect(btn.x, btn.y, btn.w, btn.h, bg, 5)
        dxDrawText(btn.label, btn.x, btn.y, btn.x + btn.w, btn.y + btn.h,
            COL_BTN_TXT, 1.15, "default-bold", "center", "center")
    end
end

function dialPadClick(button, state)
    if button ~= "left" or state ~= "down" then return end
    if not dialPad.visible then return end

    for _, btn in ipairs(numButtons) do
        if isMouseIn(btn.x, btn.y, btn.w, btn.h) then
            if #dialPad.number < 15 then
                dialPad.number = dialPad.number .. btn.digit
                dialPad.errorMsg = nil
            end
            return
        end
    end

    for _, btn in ipairs(actionButtons) do
        if isMouseIn(btn.x, btn.y, btn.w, btn.h) then
            if btn.action == "del" then
                if #dialPad.number > 0 then
                    dialPad.number = string.sub(dialPad.number, 1, -2)
                end
            elseif btn.action == "call" then
                if #dialPad.number > 0 then
                    local num = dialPad.number
                    closeDialPadUI()
                    triggerServerEvent("phone:publicPhoneDial", localPlayer, num)
                else
                    dialPad.errorMsg = "Enter a number!"
                    if dialPad.errorTimer and isTimer(dialPad.errorTimer) then
                        killTimer(dialPad.errorTimer)
                    end
                    dialPad.errorTimer = setTimer(function()
                        dialPad.errorMsg = nil
                    end, 1500, 1)
                end
            elseif btn.action == "close" then
                closeDialPadUI()
            end
            return
        end
    end

    if not isMouseIn(PAD_X, PAD_Y, PAD_W, PAD_H) then
        closeDialPadUI()
    end
end

-- ============================================================
-- CALL-IN-PROGRESS SCREEN (replaces dial pad during a call)
-- ============================================================
-- States: "dialing", "ringing", "connected", "ended"
callScreen = {
    visible     = false,
    phoneNumber = "",
    status      = "",       -- "dialing" / "ringing" / "connected" / "ended"
    statusText  = "",
    startTick   = 0,        -- getTickCount when connected
    duration    = 0,        -- seconds elapsed
    cost        = 0,
    endMsg      = "",       -- message shown on end
    endTimer    = nil,
    countTimer  = nil,
}

local RATE_PER_SEC = 0.305
local MAX_COST     = 5000

local CS_W = 270
local CS_H = 260
local CS_X = (sx - CS_W) / 2
local CS_Y = (sy - CS_H) / 2

-- Hangup button layout
local HU_W, HU_H = 130, 44
local HU_X = CS_X + (CS_W - HU_W) / 2
local HU_Y = CS_Y + CS_H - HU_H - 18

function openCallScreen(phoneNumber, status)
    closeDialPadUI() -- ensure dial pad is closed
    if callScreen.visible then return end
    callScreen.visible     = true
    callScreen.phoneNumber = tostring(phoneNumber)
    callScreen.status      = status or "dialing"
    callScreen.statusText  = getStatusLabel(callScreen.status)
    callScreen.startTick   = 0
    callScreen.duration    = 0
    callScreen.cost        = 0
    callScreen.endMsg      = ""
    showCursor(true)
    addEventHandler("onClientRender", root, renderCallScreen)
    addEventHandler("onClientClick",  root, callScreenClick)
end

function updateCallScreen(status, extraMsg)
    if not callScreen.visible then return end
    callScreen.status     = status
    callScreen.statusText = getStatusLabel(status)

    if status == "connected" then
        callScreen.startTick = getTickCount()
        -- Start counting timer
        if callScreen.countTimer and isTimer(callScreen.countTimer) then
            killTimer(callScreen.countTimer)
        end
        callScreen.countTimer = setTimer(function()
            if callScreen.visible and callScreen.status == "connected" then
                callScreen.duration = math.floor((getTickCount() - callScreen.startTick) / 1000)
                local rawCost = math.ceil(callScreen.duration * RATE_PER_SEC)
                callScreen.cost = rawCost < MAX_COST and rawCost or MAX_COST
            end
        end, 500, 0)
    elseif status == "ended" then
        callScreen.endMsg = extraMsg or ""
        if callScreen.countTimer and isTimer(callScreen.countTimer) then
            killTimer(callScreen.countTimer)
            callScreen.countTimer = nil
        end
        -- Auto-close after 5 seconds
        callScreen.endTimer = setTimer(closeCallScreen, 5000, 1)
    end
end

function closeCallScreen()
    if not callScreen.visible then return end
    callScreen.visible = false
    if callScreen.countTimer and isTimer(callScreen.countTimer) then
        killTimer(callScreen.countTimer)
        callScreen.countTimer = nil
    end
    if callScreen.endTimer and isTimer(callScreen.endTimer) then
        killTimer(callScreen.endTimer)
        callScreen.endTimer = nil
    end
    removeEventHandler("onClientRender", root, renderCallScreen)
    removeEventHandler("onClientClick",  root, callScreenClick)
    showCursor(false)
end

function getStatusLabel(status)
    if status == "dialing"   then return "Dialing..."   end
    if status == "ringing"   then return "Ringing..."    end
    if status == "connected" then return "Connected"     end
    if status == "ended"     then return "Call Ended"    end
    return status or ""
end

function formatDuration(secs)
    local m = math.floor(secs / 60)
    local s = secs % 60
    return string.format("%02d:%02d", m, s)
end

function renderCallScreen()
    if not callScreen.visible then return end

    -- Shadow + background
    dxDrawRectangle(CS_X + 4, CS_Y + 4, CS_W, CS_H, tocolor(0, 0, 0, 80))
    drawRRect(CS_X, CS_Y, CS_W, CS_H, COL_BG, 6)

    -- Header
    drawRRect(CS_X, CS_Y, CS_W, 40, COL_HEADER, 6)
    dxDrawRectangle(CS_X, CS_Y + 34, CS_W, 6, COL_HEADER)
    dxDrawText("PUBLIC PHONE", CS_X, CS_Y + 5, CS_X + CS_W, CS_Y + 40,
        COL_TITLE, 1.2, "default-bold", "center", "center")
    dxDrawRectangle(CS_X + 15, CS_Y + 42, CS_W - 30, 1, COL_SEPARATOR)

    -- Phone number
    dxDrawText("#" .. callScreen.phoneNumber, CS_X, CS_Y + 52, CS_X + CS_W, CS_Y + 80,
        COL_WHITE, 1.5, "default-bold", "center", "center")

    -- Status text with pulsating dots for dialing/ringing
    local statusColor = COL_DIM
    local displayStatus = callScreen.statusText
    if callScreen.status == "dialing" or callScreen.status == "ringing" then
        statusColor = COL_YELLOW
        -- Animate dots
        local dots = math.floor(getTickCount() / 500) % 4
        displayStatus = string.sub(displayStatus, 1, -4) .. string.rep(".", dots)
    elseif callScreen.status == "connected" then
        statusColor = COL_GREEN
    elseif callScreen.status == "ended" then
        statusColor = COL_ERROR
    end
    dxDrawText(displayStatus, CS_X, CS_Y + 85, CS_X + CS_W, CS_Y + 108,
        statusColor, 1.15, "default-bold", "center", "center")

    -- Duration & cost (shown when connected or ended)
    if callScreen.status == "connected" or callScreen.status == "ended" then
        local durText = formatDuration(callScreen.duration)
        dxDrawText(durText, CS_X, CS_Y + 115, CS_X + CS_W, CS_Y + 145,
            COL_WHITE, 2.0, "default-bold", "center", "center")

        dxDrawText("Cost: $" .. callScreen.cost, CS_X, CS_Y + 148, CS_X + CS_W, CS_Y + 170,
            COL_COST, 1.1, "default-bold", "center", "center")
    end

    -- End message
    if callScreen.status == "ended" and callScreen.endMsg ~= "" then
        dxDrawText(callScreen.endMsg, CS_X + 10, CS_Y + 172, CS_X + CS_W - 10, CS_Y + 195,
            COL_DIM, 0.95, "default", "center", "center")
    end

    -- Hangup / Close button
    local hover = isMouseIn(HU_X, HU_Y, HU_W, HU_H)
    local btnLabel, btnBg, btnHover
    if callScreen.status == "ended" then
        btnLabel = "CLOSE"
        btnBg    = COL_CLOSE_BTN
        btnHover = COL_CLOSE_HOVER
    else
        btnLabel = "HANG UP"
        btnBg    = COL_HANGUP_BTN
        btnHover = COL_HANGUP_HOVER
    end
    drawRRect(HU_X, HU_Y, HU_W, HU_H, hover and btnHover or btnBg, 5)
    dxDrawText(btnLabel, HU_X, HU_Y, HU_X + HU_W, HU_Y + HU_H,
        COL_BTN_TXT, 1.2, "default-bold", "center", "center")
end

function callScreenClick(button, state)
    if button ~= "left" or state ~= "down" then return end
    if not callScreen.visible then return end

    if isMouseIn(HU_X, HU_Y, HU_W, HU_H) then
        if callScreen.status == "ended" then
            closeCallScreen()
        else
            triggerServerEvent("phone:cancelPhoneCall", localPlayer)
        end
    end
end

-- ============================================================
-- SERVER EVENTS FOR CALL SCREEN UPDATES
-- ============================================================
addEvent("phone:publicCallStatus", true)
addEventHandler("phone:publicCallStatus", root, function(status, phoneNumber, extraMsg)
    if status == "dialing" or status == "ringing" then
        if not callScreen.visible then
            openCallScreen(phoneNumber, status)
        else
            updateCallScreen(status, extraMsg)
        end
    elseif status == "connected" then
        if not callScreen.visible then
            openCallScreen(phoneNumber, "connected")
        else
            updateCallScreen("connected")
        end
    elseif status == "ended" then
        if callScreen.visible then
            updateCallScreen("ended", extraMsg)
        end
    end
end)

-- ============================================================
-- CLEANUP
-- ============================================================
-- Auto-close dial pad if a call starts via /call command
addEventHandler("onClientElementDataChange", localPlayer, function(dataName)
    if dataName == "calling" and getElementData(localPlayer, "calling") then
        closeDialPadUI()
    end
end)

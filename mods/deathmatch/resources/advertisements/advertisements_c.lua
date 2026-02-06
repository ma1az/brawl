local AdvertisementsWindow = setmetatable({
    developmentMode = false,
    url = 'http://mta/local/advertisements.htm',

    setResults = function (self, results, page, totalPages)
        self:executeJavascript("vm.setResults('"..self.javascriptJsonEncode(results, true).."', "..page..", "..totalPages..");")
    end;

    setCurrentAdvertisement = function (self, result)
        self:executeJavascript("vm.setCurrentAdvertisement('"..self.javascriptJsonEncode(result, true).."');")
    end;

    canViewAdvertisements = function (self)
        return not getElementData(localPlayer, "adminjailed")
            and getElementData(localPlayer, "jailed") ~= 1
            and getElementData(localPlayer, "dbid")
    end;

    pushInsufficientFunds = function (self, isFaction)
        self:executeJavascript('vm.setPushInsufficientFunds('..tostring(isFaction)..');')
    end;

    initUserData = function (self)
        local factions = {}
        local factionData = getElementData(localPlayer, "faction")
        if type(factionData) == "table" then
            for factionId in pairs(factionData) do
                if exports.factions:hasMemberPermissionTo(localPlayer, factionId, "make_ads") then
                    factions[factionId] = exports.factions:getFactionName(factionId)
                end
            end
        end

        local isAdmin = exports.integration:isPlayerTrialAdmin(localPlayer)
        local dbid = getElementData(localPlayer, "dbid") or 0

        self:executeJavascript("vm.initUserData('"..self.javascriptJsonEncode(factions, true).."', "..tostring(isAdmin)..", "..dbid..");")
    end;

    pushCooldown = function (self)
        self:executeJavascript('vm.pushCooldown();')
    end;
}, {
    __index = BrowserManager
})

-- /ads command handler
addCommandHandler('ads', function ()
    if getElementData(localPlayer, "loggedin") ~= 1 then return end

    -- Block opening if the player shouldn't see ads
    if not AdvertisementsWindow:isOpen() and not AdvertisementsWindow:canViewAdvertisements() then
        return
    end

    -- Toggle the window
    AdvertisementsWindow:toggle()

    if AdvertisementsWindow:isOpen() then
        showCursor(true)
        guiSetInputMode('no_binds')

        local function onDocumentReady()
            removeEventHandler("onClientBrowserDocumentReady", AdvertisementsWindow.browser, onDocumentReady)
            AdvertisementsWindow:initUserData()
            triggerServerEvent('advertisements:fetch-page', localPlayer)
        end
        addEventHandler("onClientBrowserDocumentReady", AdvertisementsWindow.browser, onDocumentReady)
    else
        showCursor(false)
        guiSetInputMode('allow_binds')
    end
end, false, false)

-- ========================
-- Server -> Client events
-- ========================
addEvent('advertisements:receive-page', true)
addEventHandler('advertisements:receive-page', root, function (results, page, totalPages)
    if AdvertisementsWindow:isOpen() then
        AdvertisementsWindow:setResults(results, page, totalPages)
    end
end)

addEvent('advertisements:close-browser', true)
addEventHandler('advertisements:close-browser', root, function ()
    if AdvertisementsWindow:isOpen() then
        AdvertisementsWindow:close()
    end
    showCursor(false)
    guiSetInputMode('allow_binds')
end)

addEvent('advertisements:push-insufficient-funds', true)
addEventHandler('advertisements:push-insufficient-funds', root, function (isFaction)
    if AdvertisementsWindow:isOpen() then
        AdvertisementsWindow:pushInsufficientFunds(isFaction)
    end
end)

addEvent('advertisements:push-cooldown', true)
addEventHandler('advertisements:push-cooldown', root, function ()
    if AdvertisementsWindow:isOpen() then
        AdvertisementsWindow:pushCooldown()
    end
end)

addEvent('advertisements:receive-single', true)
addEventHandler('advertisements:receive-single', root, function (result)
    if AdvertisementsWindow:isOpen() then
        AdvertisementsWindow:setCurrentAdvertisement(result)
    end
end)

-- ========================
-- Browser -> Client events (forwarded to server)
-- ========================
addEvent('advertisements:fetch-page', true)
addEventHandler('advertisements:fetch-page', root, function (page, section)
    triggerServerEvent('advertisements:fetch-page', localPlayer, page, section)
end)

addEvent('advertisements:fetch-single', true)
addEventHandler('advertisements:fetch-single', root, function (id)
    triggerServerEvent('advertisements:fetch-single', localPlayer, id)
end)

addEvent('advertisements:post-advertisement', true)
addEventHandler('advertisements:post-advertisement', root, function (advertisement)
    local parsed = fromJSON(advertisement)
    if parsed then
        triggerServerEvent('advertisements:post-advertisement', localPlayer, parsed)
    end
end)

addEvent('advertisements:push', true)
addEventHandler('advertisements:push', root, function (id)
    triggerServerEvent('advertisements:push', localPlayer, id)
end)

addEvent('advertisements:delete', true)
addEventHandler('advertisements:delete', root, function (id)
    triggerServerEvent('advertisements:delete', localPlayer, id)
end)

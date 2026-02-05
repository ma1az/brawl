local cmdAntiSPAM = {
    {"pm",1,3000,"CMD_SAY"},
    {"Quickreplay",1,3000,"CMD_HELP"},
}
function preventCommandSpam(command)
    for i,v in ipairs(cmdAntiSPAM) do
        if v[1] == command then
        local data = getElementData(source,v[4])
            if data then
            local spam = data+1
                if spam >= v[2] then
                    cancelEvent()
                    outputChatBox ("★ [Server Security] Stop spamming PM!", source, 255, 125, 0, false)
                else
                    setElementData(source,v[4],spam)
                end
            else
                setElementData(source,v[4],0)
                setTimer(removeSPAMData,v[3],1,source,v[4])
            end
        end
    end
end
addEventHandler("onPlayerCommand", getRootElement(), preventCommandSpam)

function removeSPAMData(player,data)
    if isElement(player) then
        removeElementData(player,data)
    end
end
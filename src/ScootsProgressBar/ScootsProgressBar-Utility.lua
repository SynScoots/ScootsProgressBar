local storage = ScootsProgressBar.storage
local core = ScootsProgressBar.core
local options = ScootsProgressBar.options
local frames = ScootsProgressBar.frames
local interface = ScootsProgressBar.interface
local utility
local lookup = ScootsProgressBar.lookup

utility = {
    ['serverTime'] = function()
        local nowTime = time()
    
        if(ScootsProgressBar.timestampOffset == nil or (ScootsProgressBar.timestampOffsetCalcTime + 60) < nowTime) then
            local _, serverDay, serverMonth, serverYear = CalendarGetDate()
            local serverHour, serverMinute = GetGameTime()
            
            ScootsProgressBar.timestampOffset = time({
                ['year'] = serverYear,
                ['month'] = serverMonth,
                ['day'] = serverDay,
                ['hour'] = serverHour,
                ['min'] = serverMinute,
                ['sec'] = time() % 60,
            }) - nowTime
            
            ScootsProgressBar.timestampOffsetCalcTime = nowTime
        end
        
        return nowTime + ScootsProgressBar.timestampOffset
    end,
    ['clientTime'] = function()
        return ScootsProgressBar.initialTime + (GetTime() - ScootsProgressBar.initialGetTime)
    end,
    ['storeCurrentPlayer'] = function()
        if(core.player == nil) then
            storage.characters = storage.characters or {}
            local guid = UnitGUID('player')
            
            storage.characters[guid] = {
                ['guid'] = guid,
                ['name'] = UnitName('player'),
                ['race'] = UnitRace('player'),
                ['class'] = UnitClass('player'),
            }
            
            core.player = storage.characters[guid]
        end
        
        core.player.timestamp = time()
        core.player.level = UnitLevel('player')
    end,
    ['deleteOldCharacters'] = function()
        storage.options = storage.options or {
            ['autoDeleteOldCharacters'] = true,
            ['autoDeleteOldCharactersDelay'] = 28,
        }
        
        if(storage.options.autoDeleteOldCharacters == false) then
            return
        end
        
        local cutoff = time() - (storage.options.autoDeleteOldCharactersDelay * 86400)
        
        for _, character in pairs(storage.characters) do
            if(character.guid ~= core.player.guid and character.timestamp < cutoff) then
                utility.deleteAllDataForCharacter(character.guid)
            end
        end
    end,
    ['deleteAllDataForCharacter'] = function(guid)
        storage.dayStartAttunes.character[guid] = nil
        storage.bank[guid] = nil
        storage.instances[guid] = nil
        storage.options.activeProfile[guid] = nil
        storage.characters[guid] = nil
    end,
    ['setDayStartAttunes'] = function()
        if(storage.dayStartAttunes == nil or storage.dayStartAttunes.date ~= date('%Y-%m-%d')) then
            storage.dayStartAttunes = {
                ['date'] = date('%Y-%m-%d'),
                ['character'] = {},
                ['account'] = {},
            }
            
            attunes, attunesTF, attunesWF, attunesLF = CalculateAttunedCount()
            storage.dayStartAttunes.account.exAffixes = {
                ['base'] = attunes,
                ['tf'] = attunesTF,
                ['wf'] = attunesWF,
                ['lf'] = attunesLF,
            }
            
            attunes, attunesTF, attunesWF, attunesLF = CalculateAttunedCount(2)
            storage.dayStartAttunes.account.incAffixes = {
                ['base'] = attunes,
                ['tf'] = attunesTF,
                ['wf'] = attunesWF,
                ['lf'] = attunesLF,
            }
        end
        
        if(storage.dayStartAttunes.character[core.player.guid] == nil) then
            storage.dayStartAttunes.character[core.player.guid] = {}
            
            local attunes, attunesTF, attunesWF, attunesLF = CalculateAttunedCount(1)
            storage.dayStartAttunes.character[core.player.guid].exAffixes = {
                ['base'] = attunes,
                ['tf'] = attunesTF,
                ['wf'] = attunesWF,
                ['lf'] = attunesLF,
            }
            
            attunes, attunesTF, attunesWF, attunesLF = CalculateAttunedCount(3)
            storage.dayStartAttunes.character[core.player.guid].incAffixes = {
                ['base'] = attunes,
                ['tf'] = attunesTF,
                ['wf'] = attunesWF,
                ['lf'] = attunesLF,
            }
        end
    end,
    ['getTimeForNextWintergrasp'] = function()
        local timeUntilNext = GetWintergraspWaitTime()
        local inProgress = false
        local certain = true
        
        if((timeUntilNext or 0) ~= 0) then
            storage.lastSeenWGTime = time() + timeUntilNext
        else
            if((select(2, GetInstanceInfo())) == 'none') then
                inProgress = true
            end
            
            if(storage.lastSeenWGTime ~= nil) then
                local nextWGTime = storage.lastSeenWGTime
                local nowTime = time()
                
                if(nextWGTime < nowTime) then
                    certain = false
                    
                    while(nextWGTime < nowTime) do
                        nextWGTime = nextWGTime + (2.5 * 60 * 60) + 600 -- WG is +2:30:00 from last end, ~10 min completion time
                    end
                end
                
                timeUntilNext = nextWGTime - nowTime
            end
        end
        
        return timeUntilNext, inProgress, certain
    end,
    ['isBarValid'] = function(key)
        local isValid = options.get(key .. '-enabled')
        
        if(key == 'bagattune' and not ScootsProgressBar.prestiged) then
            isValid = false
        elseif(key == 'zoneattunes' and not ScootsProgressBar.itemDBLoaded) then
            isValid = false
        end
        
        return isValid
    end,
    ['getActiveBar'] = function()
        local activeBar = options.get('active')
    
        if(not utility.isBarValid(activeBar)) then
            for _, bar in ipairs(core.barOrder) do
                if(utility.isBarValid(bar.key)) then
                    activeBar = bar.key
                    break
                end
            end
        end
        
        return activeBar
    end,
    ['getNextActiveBar'] = function()
        local allow = false
        
        for _, bar in ipairs(core.barOrder) do
            if(bar.key == options.get('active')) then
                allow = true
            elseif(allow) then
                if(utility.isBarValid(bar.key)) then
                    return bar.key
                end
            end
        end
        
        for _, bar in ipairs(core.barOrder) do
            if(bar.key == options.get('active')) then
                return bar.key
            end
        
            if(utility.isBarValid(bar.key)) then
                return bar.key
            end
        end
        
        return options.get('active')
    end,
    ['getValuesForAttuneExp'] = function(containerMap, values)
        local newCount = 0
        local newPercent = 0
        
        for _, data in pairs(containerMap) do
            local bagId = data[1]
            
            for slotId = data[2][1], data[2][2] do
                local itemLink = Custom_GetItemLinkBySlot(bagId, slotId)
                
                if(itemLink) then
                    local itemId = CustomExtractItemId(itemLink)
                    local attuneProgress = tonumber(GetItemLinkAttuneProgress(itemLink) or 0)
                    local isAttuneableAtAll = (IsAttunableBySomeone(itemId) or 0) ~= 0
                    local isAttuneable = (CanAttuneItemHelper(itemId) or 0) > 0
                    local isBound = Custom_IsItemSoulbound(bagId, bagSlotId)
                    
                    if((isAttuneable or (isAttuneableAtAll and not isBound and ScootsProgressBar.prestiged)) and attuneProgress < 100) then
                        newCount = newCount + 1
                        newPercent = newPercent + attuneProgress
                    end
                end
            end
        end
        
        if(newCount > 0) then
            newPercent = newPercent / newCount
        end
        
        local changed = false
        
        if(values == nil) then
            values = {
                ['itemCount'] = newCount,
                ['percent'] = newPercent,
            }
            changed = true
        else
            if(values.itemCount ~= newCount or values.percent ~= newPercent) then
                values.itemCount = newCount
                values.percent = newPercent
                changed = true
            end
        end
        
        return values, changed
    end,
    ['displayChatMessage'] = function(message, isError)
        if(isError == true) then
            message = table.concat({
                '|cffff3333',
                message,
                '|r ',
            }, '')
        end
    
        message = table.concat({
            '|cff99fa99',
            ScootsProgressBar.title,
            '|r ',
            message,
        }, '')
    
        local printed = false
    
        for chatFrameIndex = 1, NUM_CHAT_WINDOWS do
            local chatFrame = _G['ChatFrame' .. tostring(chatFrameIndex)]
            
            if(chatFrame and chatFrame:IsEventRegistered('CHAT_MSG_SYSTEM')) then
                chatFrame:AddMessage(message)
                printed = true
            end
        end
        
        if(printed == false) then
            DEFAULT_CHAT_FRAME:AddMessage(message)
        end
    end,
    ['displayToast'] = function(message)
        UIErrorsFrame:AddMessage(table.concat({
            '|cff99fa99',
            ScootsProgressBar.title,
            '|r ',
            message,
        }, ''), 1, 1, 1, 1)
    end,
    ['getNewCurrencyValue'] = function(itemId)
        local name, quantity
        
        if(itemId == '_GOLD') then
            quantity = math.floor(GetMoney() / 10000)
            name = GOLD_AMOUNT:gsub('%s*%%d%s*', '')
        else
            for currencyIndex = 1, GetCurrencyListSize() do
                local _, _, _, _, _, currencyQuantity, _, _, currencyItemId = GetCurrencyListInfo(currencyIndex)
                
                if(currencyItemId == itemId) then
                    quantity = currencyQuantity
                    name = GetItemInfoCustom(itemId)
                    break
                end
            end
        end
        
        return {
            ['name'] = name,
            ['quantity'] = quantity
        }
    end,
    ['getNewItemsValue'] = function(itemId)
        local name = GetItemInfoCustom(itemId)
        local quantity = GetCustomGameData(13, itemId) or 0
    
        if(options.get('items-include-bank')) then
            quantity = storage.bank[core.player.guid].items[itemId] or 0
        end
    
        for bagIndex = 0, 4 do
            for slotIndex = 1, GetContainerNumSlots(bagIndex) do
                local _, itemCount, _, _, _, _, itemLink = GetContainerItemInfo(bagIndex, slotIndex)
                
                if(itemLink) then
                    if(itemId == CustomExtractItemId(itemLink)) then
                        quantity = quantity + itemCount
                    end
                end
            end
        end
        
        return {
            ['name'] = name,
            ['quantity'] = quantity
        }
    end,
    ['getItemCount'] = function(findItemId)
        local count = 0
    
        for bagIndex = -2, 4 do
            if(bagIndex ~= -1) then
                for slotIndex = 1, GetContainerNumSlots(bagIndex) do
                    local _, itemCount, _, _, _, _, itemLink = GetContainerItemInfo(bagIndex, slotIndex)
                    local itemId = CustomExtractItemId(itemLink)
                    
                    if(itemId == findItemId) then
                        count = count + itemCount
                    end
                end
            end
        end
        
        for slotIndex = 1, 23 do
            local itemLink = GetInventoryItemLink('player', slotIndex)
            if(itemId == findItemId) then
                count = count + GetInventoryItemCount('player', slotIndex)
            end
        end
        
        count = count + GetCustomGameData(13, findItemId)
        
        return count
    end,
    ['scanBank'] = function()
        if(storage.bank == nil or storage.bank[core.player.guid] == nil) then
            storage.bank = storage.bank or {}
            storage.bank[core.player.guid] = {
                ['timestamp'] = 0,
                ['items'] = {},
            }
        end
        
        if(not core.bankIsOpen) then
            return
        end
        
        local bank = {
            ['timestamp'] = utility.serverTime(),
            ['items'] = {},
        }
        
        for _, bagIndex in ipairs(lookup.bankContainerSlots) do
            for slotIndex = 1, GetContainerNumSlots(bagIndex) do
                local _, itemCount, _, _, _, _, itemLink = GetContainerItemInfo(bagIndex, slotIndex)
                
                if(itemLink) then
                    local itemId = CustomExtractItemId(itemLink)
                    bank.items[itemId] = (bank.items[itemId] or 0) + itemCount
                end
            end
        end
        
        storage.bank[core.player.guid] = bank
        core.update['items'] = true
    end,
    ['countActiveBars'] = function()
        local count = 0
    
        for key, _ in pairs(core.definedBars) do
            if(utility.isBarValid(key)) then
                count = count + 1
            end
        end
        
        return math.max(1, count)
    end,
    ['getFirstActiveBar'] = function()
        for index = 1, #core.barOrder do
            if(utility.isBarValid(core.barOrder[index].key)) then
                return core.barOrder[index].key
            end
        end
        
        return utility.getActiveBar()
    end,
    ['getLastActiveBar'] = function()
        for index = #core.barOrder, 1, -1 do
            if(utility.isBarValid(core.barOrder[index].key)) then
                return core.barOrder[index].key
            end
        end
        
        return utility.getActiveBar()
    end,
    ['getActiveBarAtIndex'] = function(index)
        local counter = 1
        
        for _, data in ipairs(core.barOrder) do
            if(utility.isBarValid(data.key)) then
                if(counter == index) then
                    return data.key
                end
                
                counter = counter + 1
            end
        end
        
        return utility.getActiveBar()
    end,
    ['addTooltipDoubleLine'] = function(leftText, rightText)
        GameTooltip:AddDoubleLine(
            leftText,
            rightText,
            HIGHLIGHT_FONT_COLOR.r,
            HIGHLIGHT_FONT_COLOR.g,
            HIGHLIGHT_FONT_COLOR.b,
            NORMAL_FONT_COLOR.r,
            NORMAL_FONT_COLOR.g,
            NORMAL_FONT_COLOR.b
        )
        
        local numLines = GameTooltip:NumLines()
        return _G['GameTooltipTextLeft' .. numLines], _G['GameTooltipTextRight' .. numLines]
    end,
    ['clearOldInstances'] = function()
        local nowTime = utility.serverTime()
        local lockoutTime = nowTime - 3600
    
        for charGuid, charInstances in pairs(storage.instances) do
            if(charInstances.timestamp < lookup.raidResetTime and (charInstances.timestamp + 3600) < nowTime) then
                charInstances[charGuid] = nil
            else
                for zoneId, instance in pairs(charInstances.active) do
                    if((not instance.isRaid and instance.timestamp < lookup.dungeonResetTime) or (instance.isRaid and instance.timestamp < lookup.raidResetTime)) then
                        if(instance.timestamp > lockoutTime) then
                            table.insert(charInstances.reset, instance)
                        end
                        
                        charInstances.active[zoneId] = nil
                    end
                end
                
                for index = #charInstances.reset, 1, -1 do
                    if(charInstances.reset[index].timestamp < lockoutTime) then
                        table.remove(charInstances.reset, index)
                    end
                end
            end
        end
        
        if(storage.instances[core.player.guid] == nil) then
            storage.instances[core.player.guid] = {
                ['active'] = {},
                ['reset'] = {},
            }
        end
        
        storage.instances[core.player.guid].timestamp = nowTime
    end,
    ['maintainInstanceResetTime'] = function()
        local serverTime = utility.serverTime()
        lookup.dungeonResetTime = time({
            ['year'] = tonumber(date('%Y', serverTime)),
            ['month'] = tonumber(date('%m', serverTime)),
            ['day'] = tonumber(date('%d', serverTime)),
            ['hour'] = 4,
            ['min'] = 0,
            ['sec'] = 0,
        })
        
        if(lookup.dungeonResetTime > serverTime) then
            lookup.dungeonResetTime = lookup.dungeonResetTime - 86400
        end
        
        --
        
        local dayOfWeek = CalendarGetDate()
        local offset = dayOfWeek - 4 -- 1 = Sunday, 7 = Saturday
        
        if(offset < 0) then
            offset = offset + 7
        end
        
        lookup.raidResetTime = lookup.dungeonResetTime - (offset * 86400)
        
        core.queueAction('maintain-instance-reset-time', (lookup.dungeonResetTime + 86400) - serverTime, function()
            utility.maintainInstanceResetTime()
        end)
    end,
    ['getDungeonChallengeEncounters'] = function(zoneId)
        local zoneData = lookup.dungeonChallenges[zoneId]
        
        if(zoneData == nil) then
            return nil, nil
        end
        
        return zoneData[1], zoneData[2]
    end,
    ['getDungeonChallenge'] = function()
        local isChallenge, isSpeedrun, speedrunRemains = false, false, 0
        
        for index = 1, 40 do
            local name, _, _, _, _, duration, ends, _, _, _, spellId = UnitAura('player', index)
            
            if(name == nil) then
                break
            end
            
            if(lookup.dungeonChallengeSpellIds[spellId]) then
                isChallenge = true
                
                if(ends and ends > 0) then
                    speedrunRemains = ends - GetTime()
                    isSpeedrun = true
                end
            end
            
            if(isChallenge and isSpeedrun and (speedrunRemains or 0) > 0) then
                break
            end
        end
        
        return isChallenge, isSpeedrun, speedrunRemains
    end,
    ['formatTimeLeft'] = function(timeLeft, allowMs)
        if(timeLeft) then
            allowMs = allowMs ~= false
        
            if(timeLeft <= 0) then
                return '0'
            elseif(timeLeft >= 3600) then
                return string.format('%d:%02d:%02d', math.floor(timeLeft / 3600), math.floor((timeLeft % 3600) / 60), math.floor(timeLeft % 60))
            elseif(timeLeft >= 10) then
                return string.format('%02d:%02d', math.floor((timeLeft % 3600) / 60), math.floor(timeLeft % 60))
            else
                return string.format('%.1f', timeLeft)
            end
        end
    end,
    ['humanTime'] = function(seconds)
        if(not seconds) then
            return
        end
        
        local hours = math.floor(seconds / 3600)
        local minutes = math.floor((seconds % 3600) / 60)
        seconds = math.floor(seconds % 60)
        
        local output = {}
        
        if(hours > 0) then
            table.insert(output, string.format('%d hour', hours))
        end
        
        if(minutes > 0) then
            table.insert(output, string.format('%d minute', minutes))
        end
        
        if(seconds > 0) then
            table.insert(output, string.format('%d second', seconds))
        end
        
        if(#output == 3) then
            return string.format('%s, %s, and %s', output[1], output[2], output[3])
        elseif(#output == 2) then
            return string.format('%s, and %s', output[1], output[2])
        end
        
        return output[1]
    end,
}

for funcName, func in pairs(utility) do
    ScootsProgressBar.utility[funcName] = func
end

utility = ScootsProgressBar.utility
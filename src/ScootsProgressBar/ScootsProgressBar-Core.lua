local storage = ScootsProgressBar.storage
local core
local options = ScootsProgressBar.options
local frames = ScootsProgressBar.frames
local interface = ScootsProgressBar.interface
local utility = ScootsProgressBar.utility
local lookup = ScootsProgressBar.lookup

core = {
    ['definedBars'] = {},
    ['barEvents'] = {},
    ['updateFunctionMap'] = {},
    ['textFormatFunctionMap'] = {},
    ['tooltipLineFunctionMap'] = {},
    ['init'] = function()
        core.timer = 0
        core.prevLoop = 0
        core.update = {}
        core.delayedUpdate = {}
        core.actionQueue = {}
        core.values = {}
        core.waitForAreaChange = {}
        
        lookup.blizzardMainMenuExpBar_Update = MainMenuExpBar_Update
        lookup.blizzardReputationWatchBar_Update = ReputationWatchBar_Update
        lookup.blizzardTextStatusBar_UpdateTextString = TextStatusBar_UpdateTextString
        lookup.blizzardUIParent_ManageFramePositions = UIParent_ManageFramePositions
        
        TextStatusBar_UpdateTextString = function(frame, ...)
            if(frame == MainMenuExpBar and options.get('hide-blizzard')) then
                return
            end
            
            return lookup.blizzardTextStatusBar_UpdateTextString(frame, ...)
        end
        
        UIParent_ManageFramePositions = function(...)
            local out = lookup.blizzardUIParent_ManageFramePositions(...)
            
            interface.reAnchorStanceBar()
            core.queueAction('auto-re-anchor-stance-bar', 0.05, interface.reAnchorStanceBar)
            
            return out
        end
        
        lookup.initialTime = time()
        lookup.initialGetTime = GetTime()
        lookup.prestiged = bit.band(CMCGetMultiClassEnabled(), 0x7f) >= 2 or bit.band(CMCGetMultiClassEnabled(), 0x80) ~= 0
        lookup.itemDBLoaded = ItemLocIsLoaded() ~= nil
        lookup.maxAttunes = {
            ['character'] = 0,
            ['account'] = 0,
            ['affixes'] = CalculateAttunableAffixCount(),
        }
        
        for itemId = 1, MAX_ITEMID do
            local itemTags = GetItemTagsCustom(itemId)
            
            if(itemTags and bit.band(itemTags, 96) == 64) then
                lookup.maxAttunes.account = lookup.maxAttunes.account + 1

                if(CanAttuneItemHelper(itemId) > 0) then
                    lookup.maxAttunes.character = lookup.maxAttunes.character + 1
                end
            end
        end
        
        local savedStorage = _G['SCOOTSPROGRESSBAR_STORAGE']
        
        if(savedStorage ~= nil) then
            for key, value in pairs(savedStorage) do
                storage[key] = value
            end
        end
        
        utility.storeCurrentPlayer()
        utility.setDayStartAttunes()
        
        if(storage.timerStart and (storage.timerEnd or 0) < time()) then
            storage.timerStart = nil
            storage.timerEnd = nil
        end
        
        utility.maintainInstanceResetTime()
        options.load()
        utility.deleteOldCharacters()
        core.preCacheOrder()
        
        lookup.percentFormat = string.format('%%.%df', options.get('percent-precision'))
        
        options.build()
        interface.build()
        
        for key, _ in pairs(core.definedBars) do
            interface.getBar(key)
            core.doUpdate(key)
        end
        
        core.setMode(options.get('mode'))
        
        core.attachAllEvents()
        
        interface.applyHideBlizzard()
        interface.reAnchorStanceBar()
        interface.applyVehicleTempOptions(VehicleMenuBar:IsShown() ~= nil)
        
        VehicleMenuBar:HookScript('OnShow', function()
            interface.applyVehicleTempOptions(true)
        end)
        
        VehicleMenuBar:HookScript('OnHide', function()
            interface.applyVehicleTempOptions(false)
        end)
    end,
    ['attachAllEvents'] = function()
        core.eventMap = {}
    
        local eventList = {
            ['BANKFRAME_OPENED'] = true,
            ['BANKFRAME_CLOSED'] = true,
            ['CHAT_MSG_SYSTEM'] = true,
            ['PLAYER_LOGOUT'] = true,
            ['ZONE_CHANGED_NEW_AREA'] = true,
            ['PLAYER_ENTERING_WORLD'] = true,
            ['PLAYER_LEVEL_UP'] = true,
        }
    
        for key, events in pairs(core.barEvents) do
            for _, event in ipairs(events) do
                core.eventMap[event] = core.eventMap[event] or {}
                table.insert(core.eventMap[event], key)
                eventList[event] = true
            end
        end
        
        for event, _ in pairs(eventList) do
            if(event:match('^SYNASTRIA_')) then
                RegisterForCustomEvent(event, function()
                    core.eventHandler(frames.main, event)
                end)
            else
                frames.main:RegisterEvent(event)
            end
        end
        
        frames.main:SetScript('OnUpdate', core.loopHandler)
    end,
    ['eventHandler'] = function(self, event, arg1)
        if(core.eventMap and core.eventMap[event]) then
            for _, key in ipairs(core.eventMap[event]) do
                core.update[key] = true
            end
        end
        
        if(event == 'ZONE_CHANGED_NEW_AREA' or event == 'PLAYER_ENTERING_WORLD') then
            local timeUntilNextWG = GetWintergraspWaitTime()
            if((timeUntilNextWG or 0) ~= 0) then
                storage.lastSeenWGTime = time() + timeUntilNextWG
            end
            
            utility.clearOldInstances()
        end
        
        if(event == 'CHAT_MSG_SYSTEM') then
            core.handleSystemMessage(arg1)
            return
        end
        
        if(event == 'BANKFRAME_OPENED') then
            core.bankIsOpen = true
            utility.scanBank()
            return
        end
        
        if(event == 'BANKFRAME_CLOSED') then
            core.bankIsOpen = false
            return
        end
        
        if(event == 'PLAYER_LEVEL_UP') then
            core.player.level = UnitLevel('player')
        
            if(frames.options and frames.options.optionPages and frames.options.optionPages.data and frames.options.optionPages.data.drawCharacters) then
                frames.options.optionPages.data.drawCharacters()
            end
            
            interface.applyHideBlizzard()
            
            return
        end
    
        if(event == 'ADDON_LOADED') then
            if(arg1 == 'ScootsProgressBar') then
                SynastriaSafeInvoke('ScootsProgressBar__init')
            end
            
            return
        end
        
        if(event == 'PLAYER_LOGOUT') then
            utility.storeCurrentPlayer()
            _G['SCOOTSPROGRESSBAR_STORAGE'] = storage
            return
        end
    end,
    ['loopHandler'] = function(self, elapsed)
        core.timer = core.timer + elapsed
        
        if((core.prevLoop + 0.025) > core.timer) then
            return
        end
        
        core.prevLoop = core.timer
        
        interface.dragPositionCallback(self)
        
        -- Delayed update
        for key, when in pairs(core.delayedUpdate) do
            if(when <= core.timer) then
                core.update[key] = true
                core.delayedUpdate[key] = nil
            end
        end
        
        -- Action queue
        if(#core.actionQueue > 0) then
            for index = #core.actionQueue, 1, -1 do
                if(core.actionQueue[index].when <= core.timer) then
                    core.actionQueue[index].callback()
                    table.remove(core.actionQueue, index)
                end
            end
        end
        
        -- Do update
        if(core.mode == 'single') then
            if(core.active and core.update[core.active]) then
                core.doUpdate(core.active)
            end
            
            if(core.tooltipFontStrings) then
                for key, _ in pairs(core.definedBars) do
                    if(key ~= core.active and core.update[key] and (utility.isBarValid(key) or utility.getActiveBar() == key)) then
                        core.updateTooltip(key)
                    end
                end
            end
        else
            for key, _ in pairs(core.definedBars) do
                if(core.update[key] and (utility.isBarValid(key) or utility.getActiveBar() == key)) then
                    core.doUpdate(key)
                end
            end
        end
        
        -- Wait for area change
        if(core.waitingForAreaChange and core.waitingForAreaChange ~= Custom_GetCurrentZone()) then
            core.waitingForAreaChange = nil
            
            for zoneId, callback in pairs(core.waitForAreaChange) do
                if(not callback()) then
                    core.waitForAreaChange[Custom_GetCurrentZone()] = callback
                end
                
                core.waitForAreaChange[zoneId] = nil
            end
        end
        
        -- Reputation auto state
        if(core.update['reputation'] and options.get('reputation-follow-tracked') and not options.get('reputation-enabled') and GetWatchedFactionInfo() ~= nil) then
            options.set('reputation-enabled', true, true)
            core.prepareUpdate('reputation', 'reputation-enabled', true)
        end
    end,
    ['handleSystemMessage'] = function(message)
        local patterns = {
            ['advance-dungeon-challenge'] = '|cff%x%x%x%x%x%xYou\'ve made progress with dungeon challenge, current timer is |cff%x%x%x%x%x%x(%d[%d%.:]*)|cff%x%x%x%x%x%x! There are |cff%x%x%x%x%x%x([1-9]%d?) |cff%x%x%x%x%x%xremaining encounters%.',
            ['finish-dungeon-challenge'] = '^|cff%x%x%x%x%x%xYou completed this dungeon challenge in |cff%x%x%x%x%x%x(%d[%d%.:]*)|cff%x%x%x%x%x%x!$',
            ['failed-dungeon-challenge'] = '^|cff%x%x%x%x%x%xYou have failed the dungeon challenge ',
            ['instance-reset'] = INSTANCE_RESET_SUCCESS:gsub('%s*%%s%s*', ''),
            ['wintergrasp-soon'] = '^|cff%x%x%x%x%x%xWintergrasp will begin in (%d+) minutes!$',
            ['wintergrasp-now'] = '^|cff%x%x%x%x%x%xWintergrasp has begun!$'
        }
        
        local event, test
        for key, pattern in pairs(patterns) do
            test = {message:match(pattern)}
            
            if(test and test[1]) then
                event = key
                break
            end
        end
        
        if(test and event) then
            local currentZoneId = Custom_GetCurrentZone()
        
            if(event == 'advance-dungeon-challenge') then
                local instance = core.getActiveInstance(currentZoneId)
                
                instance.challengeStarted = true
                instance.encountersRemain = tonumber(test[2])
                
                core.update['dungeonchallenge'] = true
            elseif(event == 'finish-dungeon-challenge') then
                local instance = core.getActiveInstance(currentZoneId)
                
                instance.challengeStarted = true
                instance.challengeComplete = true
                instance.encountersRemain = 0
                
                if(instance.isSpeedrun and not instance.speedrunFailed) then
                    instance.speedrunComplete = true
                end
                
                core.update['dungeonchallenge'] = true
                core.update['dungeonspeedrun'] = true
            elseif(event == 'failed-dungeon-challenge') then
                local instance = core.getActiveInstance(currentZoneId)
                
                if(instance == nil) then
                    core.waitingForAreaChange = currentZoneId
                    core.waitForAreaChange[currentZoneId] = core.failDungeonChallenge
                    return
                end
                
                core.failDungeonChallenge(currentZoneId)
            elseif(event == 'instance-reset') then
                local instances = storage.instances[core.player.guid]
                
                for zoneId, instance in pairs(instances.active) do
                    if(currentZoneId ~= zoneId) then
                        core.resetInstance(zoneId)
                    end
                end
                
                core.update['instancecap'] = true
            elseif(event == 'wintergrasp-soon') then
                storage.lastSeenWGTime = time() + (tonumber(test[1]) * 60)
            elseif(event == 'wintergrasp-now') then
                storage.lastSeenWGTime = time()
            end
        end
    end,
    ['getActiveInstance'] = function(zoneId)
        local instance
        local numEncounters, isRaid = utility.getDungeonChallengeEncounters(zoneId)
        
        if(numEncounters) then
            instance = storage.instances[core.player.guid].active[zoneId]
            
            if(instance == nil) then
                instance = {
                    ['timestamp'] = utility.serverTime(),
                    ['zoneId'] = zoneId,
                    ['challengeStarted'] = false,
                    ['challengeComplete'] = false,
                    ['challengeFailed'] = false,
                    ['encountersTotal'] = numEncounters,
                    ['encountersRemain'] = numEncounters,
                    ['isRaid'] = isRaid,
                    ['isLfg'] = IsInLFGDungeon(),
                    ['isSpeedrun'] = false,
                }
                
                storage.instances[core.player.guid].active[zoneId] = instance
            end
            
            if(not instance.challengeStarted) then
                local isChallenge, isSpeedrun, speedrunLeft = utility.getDungeonChallenge()
                
                if(isChallenge) then
                    instance.challengeStarted = true
                    
                    if(isSpeedrun and not instance.isSpeedrun) then
                        instance.isSpeedrun = true
                        instance.speedrunStart = speedrunLeft
                        instance.speedrunCurrent = speedrunLeft
                        instance.speedrunComplete = false
                        instance.speedrunFailed = false
                    end
                end
            end
        end
        
        return instance
    end,
    ['failDungeonChallenge'] = function(zoneId)
        if(zoneId == nil) then
            zoneId = Custom_GetCurrentZone()
        end
    
        local instance = core.getActiveInstance(zoneId)
        
        if(instance == nil) then
            return false
        end
        
        instance.challengeStarted = true
        instance.challengeFailed = true
        
        if(instance.isSpeedrun) then
            instance.speedrunFailed = true
        end
        
        core.update['dungeonchallenge'] = true
        core.update['dungeonspeedrun'] = true
        
        return true
    end,
    ['resetInstance'] = function(zoneId)
        local instances = storage.instances[core.player.guid]
        
        if(instances.active[zoneId] ~= nil) then
            table.insert(instances.reset, instances.active[zoneId])
            instances.active[zoneId] = nil
        end
    end,
    ['delayUpdate'] = function(key, delay)
        local doWhen = core.timer + delay
        
        if(core.delayedUpdate[key] == nil or core.delayedUpdate[key] > doWhen) then
            core.delayedUpdate[key] = doWhen
        end
    end,
    ['queueAction'] = function(key, delay, callback)
        if(key ~= nil and #core.actionQueue) then
            for queueIndex, data in ipairs(core.actionQueue) do
                if(data.key == key) then
                    table.remove(core.actionQueue, queueIndex)
                    break
                end
            end
        end
        
        table.insert(core.actionQueue, {
            ['key'] = key,
            ['when'] = core.timer + delay,
            ['callback'] = callback,
        })
    end,
    ['preCacheOrder'] = function()
        core.barOrder = {}
        
        for key, _ in pairs(core.definedBars) do
            table.insert(core.barOrder, {
                ['key'] = key,
                ['order'] = options.get(key .. '-order') or 999
            })
        end
        
        table.sort(core.barOrder, function(barA, barB)
            return barA.order < barB.order
        end)
        
        for index = 1, #core.barOrder do
            core.barOrder[index].order = index
            options.set(core.barOrder[index].key .. '-order', index)
        end
    end,
    ['setMode'] = function(mode)
        core.mode = mode
        
        if(core.mode == 'single') then
            core.setActive(utility.getActiveBar())
            interface.hideAllExcept(core.active)
            core.doUpdate(core.active)
        else
            interface.showAllEnabled()
        end
        
        if(interface.built) then
            interface.applyDimensions()
        end
        
        interface.renderBarValues()
        interface.setBarPositions()
        interface.setBorderPositions()
        interface.drawSegments()
    end,
    ['setActive'] = function(key)
        if(core.mode == 'single') then
            if(core.active and frames.bars[core.active]) then
                interface.getBar(core.active):Hide()
            end
        end
        
        core.active = key
        options.set('active', key)
        
        if(core.mode == 'single') then
            interface.getBar(core.active):Show()
        end
    end,
    ['cycleActive'] = function()
        if(core.mode == 'single') then
            local nextActive = utility.getNextActiveBar()
            
            if(nextActive == core.active) then
                return
            end
            
            core.setActive(nextActive)
        end
    end,
    ['prepareUpdate'] = function(barKey, key, value)
        if(not barKey or not core.definedBars[barKey]) then
            core.updateGeneralSetting(key, value)
        else
            if(key:match('%-colour$')) then
                interface.applyColours(barKey)
                return
            end
            
            if(key == barKey .. '-enabled') then
                core.preCacheOrder()
                
                if(value == true) then
                    core.doUpdate(barKey)
                end
                
                interface.setBarPositions()
                interface.setBorderPositions()
                interface.drawSegments()
                
                if(core.mode == 'single') then
                    if(barKey == core.active and value == false) then
                        core.cycleActive()
                    elseif(value == true and not utility.isBarValid(core.active)) then
                        core.cycleActive()
                    end
                else
                    interface.showAllEnabled()
                    interface.applyDimensions()
                end
                
                return
            end
            
            core.update[barKey] = true
        end
    end,
    ['updateGeneralSetting'] = function(key, value)
        if(interface.applyVisualGeneralOption(key, value)) then
            return
        end
            
        if(key:match('%-order$')) then
            if(core.mode == 'multi') then
                interface.setBarPositions()
            end
            
            return
        end
        
        if(key == 'mode') then
            core.setMode(value)
            return
        end
        
        if(key == 'percent-precision') then
            lookup.percentFormat = string.format('%%.%df', options.get('percent-precision'))
        
            for barKey, _ in pairs(frames.bars) do
                if((utility.isBarValid(barKey) or utility.getActiveBar() == barKey) and core.values[barKey]) then
                    frames.bars[barKey].text:SetText(core.translateFormat(barKey))
                end
            end
            
            return
        end
    end,
    ['doUpdate'] = function(key)
        if(utility.isBarValid(key) or utility.getActiveBar() == key) then
            core.update[key] = nil
            
            if(core.updateFunctionMap[key] and core.updateFunctionMap[key](key)) then
                interface.getBar(key)
                interface.applyColours(key)
                interface.renderBarValues(key)
                core.updateTooltip(key)
            end
        end
    end,
    ['translateFormat'] = function(key)
        local text = core.values[key].textFormat
        
        if(core.values[key] == nil) then
            return ''
        end
        
        if(core.textFormatFunctionMap[key]) then
            text = core.textFormatFunctionMap[key](text)
        end
        
        if(core.values[key].currentValue and type(core.values[key].currentValue) == 'number') then
            text = text:gsub('{C}', string.format('%d', core.values[key].currentValue))
            text = text:gsub('{S}', (core.values[key].currentValue == 1) and '' or 's')
            text = text:gsub('{ES}', (core.values[key].currentValue == 1) and '' or 'es')
        end
        
        if(core.values[key].maxValue and type(core.values[key].maxValue) == 'number') then
            text = text:gsub('{M}', string.format('%d', core.values[key].maxValue))
        end
        
        if(core.values[key].percent) then
            text = text:gsub('{P}', string.format(lookup.percentFormat, core.values[key].percent))
        end
        
        return text
    end,
    ['setValuesForAttuneCounts'] = function(key, newValue, newMax)
        local newFormat = options.get(key .. '-format')
        
        if(core.values[key] == nil) then
            core.values[key] = {
                ['textFormat'] = newFormat,
                ['maxValue'] = newMax,
                ['currentValue'] = newValue,
                ['percent'] = 0
            }
            
            if(newMax > 0) then
                core.values[key].percent = (newValue / newMax) * 100
            end
            
            return true
        else
            if(core.values[key].textFormat ~= newFormat or core.values[key].currentValue ~= newValue) then
                core.values[key].textFormat = newFormat
                core.values[key].maxValue = newMax
                core.values[key].currentValue = newValue
                core.values[key].percent = 0
                
                if(newMax > 0) then
                    core.values[key].percent = (newValue / newMax) * 100
                end
                
                return true
            end
        end
        
        return false
    end,
    ['attachTooltipInfo'] = function()
        if(core.mode == 'single' and options.get('tooltip-display') == 'visible') then
            core.attachTooltipInfoLine(utility.getActiveBar())
        else
            local counter = 0
            
            for _, data in ipairs(core.barOrder) do
                if(utility.isBarValid(data.key)) then
                    core.attachTooltipInfoLine(data.key)
                    counter = counter + 1
                end
            end
            
            if(counter == 0) then
                core.attachTooltipInfoLine(utility.getActiveBar())
            end
        end
    end,
    ['attachTooltipInfoLine'] = function(key)
        local _, rightFontString = utility.addTooltipDoubleLine(core.getTooltipInfoLineContent(key))
        core.tooltipFontStrings = core.tooltipFontStrings or {}
        core.tooltipFontStrings[key] = rightFontString
    end,
    ['getTooltipInfoLineContent'] = function(key)
        local leftText, rightText
        
        if(core.tooltipLineFunctionMap[key] ~= nil) then
            leftText, rightText = core.tooltipLineFunctionMap[key]()
        else
            leftText = core.definedBars[key]
            rightText = string.format(
                '%d / %d (' .. lookup.percentFormat .. '%%)',
                core.values[key].currentValue,
                core.values[key].maxValue,
                core.values[key].percent
            )
        end
        
        return leftText, rightText
    end,
    ['updateTooltip'] = function(key)
        if(core.tooltipFontStrings and core.tooltipFontStrings[key]) then
            if(core.update[key] and core.updateFunctionMap[key]) then
                core.updateFunctionMap[key](key)
            end
            
            local _, rightText = core.getTooltipInfoLineContent(key)
            core.tooltipFontStrings[key]:SetText(rightText)
        end
    end,
}

frames.main:SetScript('OnEvent', core.eventHandler)
frames.main:RegisterEvent('ADDON_LOADED')

function ScootsProgressBar__init()
    local doLoop = true
    frames.main:SetScript('OnUpdate', function()
        if(doLoop and Custom_GetCurrentZoneOur() ~= nil and Custom_GetCurrentZone() ~= nil and CalculateAttunableAffixCount() ~= nil) then
            doLoop = false
            core.init()
        end
    end)
end

for funcName, func in pairs(core) do
    ScootsProgressBar.core[funcName] = func
end

core = ScootsProgressBar.core
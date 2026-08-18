local storage = ScootsProgressBar.storage
local core
local options = ScootsProgressBar.options
local frames = ScootsProgressBar.frames
local interface = ScootsProgressBar.interface
local utility = ScootsProgressBar.utility
local lookup = ScootsProgressBar.lookup

core = {
    ['definedBars'] = {
        ['experience'] = {
            'PLAYER_LEVEL_UP',
            'PLAYER_XP_UPDATE',
        },
        ['reputation'] = {
            'UPDATE_FACTION',
        },
        ['equipattune'] = {
            'SYNASTRIA_ITEM_ATTUNE_PCT_CHANGED',
            'SYNASTRIA_ATTUNE_BAR_CHANGED',
            'PLAYER_EQUIPMENT_CHANGED',
            'UNIT_INVENTORY_CHANGED',
        },
        ['bagattune'] = {
            'SYNASTRIA_ITEM_ATTUNE_PCT_CHANGED',
            'SYNASTRIA_ATTUNE_BAR_CHANGED',
            'BAG_UPDATE',
        },
        ['attunebar'] = {
            'SYNASTRIA_ITEM_ATTUNE_PCT_CHANGED',
            'SYNASTRIA_ATTUNE_BAR_CHANGED',
        },
        ['charattunes'] = {
            'SYNASTRIA_ITEM_ATTUNED',
        },
        ['accattunes'] = {
            'SYNASTRIA_ITEM_ATTUNED',
        },
        ['affixattunes'] = {
            'SYNASTRIA_ITEM_ATTUNED',
        },
        ['zoneattunes'] = {
            'SYNASTRIA_ITEM_ATTUNED',
            'ZONE_CHANGED_NEW_AREA',
            'PLAYER_ENTERING_WORLD',
        },
        ['questtoken'] = {
            'QUEST_TURNED_IN',
        },
        ['currency'] = {
            'PLAYER_MONEY',
            'CURRENCY_DISPLAY_UPDATE',
            'CHAT_MSG_COMBAT_HONOR_GAIN',
        },
        ['items'] = {
            'BAG_UPDATE',
            'SYNASTRIA_RESOURCE_BAG_CHANGED',
        },
        ['dailyattunes'] = {
            'SYNASTRIA_ITEM_ATTUNED',
        },
        ['instancecap'] = {
            'ZONE_CHANGED_NEW_AREA',
            'PLAYER_ENTERING_WORLD',
        },
        ['bagspace'] = {
            'BAG_UPDATE',
        },
        ['wintergrasp'] = {
            'ZONE_CHANGED_NEW_AREA',
            'PLAYER_ENTERING_WORLD',
        },
        ['dungeonchallenge'] = {
            'ZONE_CHANGED_NEW_AREA',
            'PLAYER_ENTERING_WORLD',
            'UNIT_AURA',
            'PLAYER_AURAS_CHANGED',
        },
        ['dungeonspeedrun'] = {
            'ZONE_CHANGED_NEW_AREA',
            'PLAYER_ENTERING_WORLD',
            'UNIT_AURA',
            'PLAYER_AURAS_CHANGED',
        },
        ['freetimer'] = {
            'ZONE_CHANGED_NEW_AREA',
            'PLAYER_ENTERING_WORLD',
        },
    },
    ['toastables'] = {
        'currency',
        'items',
    },
    ['init'] = function()
        core.timer = 0
        core.prevLoop = 0
        core.update = {}
        core.delayedUpdate = {}
        core.actionQueue = {}
        core.values = {}
        core.toasts = {}
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
        
        ScootsProgressBar.prestiged = bit.band(CMCGetMultiClassEnabled(), 0x7f) >= 2 or bit.band(CMCGetMultiClassEnabled(), 0x80) ~= 0
        ScootsProgressBar.itemDBLoaded = ItemLocIsLoaded() ~= nil
        ScootsProgressBar.initialTime = time()
        ScootsProgressBar.initialGetTime = GetTime()
        ScootsProgressBar.maxAttunes = {
            ['character'] = 0,
            ['account'] = 0,
            ['affixes'] = CalculateAttunableAffixCount(),
        }
        
        for itemId = 1, MAX_ITEMID do
            local itemTags = GetItemTagsCustom(itemId)
            
            if(itemTags and bit.band(itemTags, 96) == 64) then
                ScootsProgressBar.maxAttunes.account = ScootsProgressBar.maxAttunes.account + 1

                if(CanAttuneItemHelper(itemId) > 0) then
                    ScootsProgressBar.maxAttunes.character = ScootsProgressBar.maxAttunes.character + 1
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
        
        core.updateFunctionMap = {
            ['experience'] = core.updateExperience,
            ['reputation'] = core.updateReputation,
            ['equipattune'] = core.updateEquipAttuning,
            ['bagattune'] = core.updateBagAttuning,
            ['attunebar'] = core.updateAttuneBarAttuning,
            ['charattunes'] = core.updateCharacterAttunes,
            ['accattunes'] = core.updateAccountAttunes,
            ['affixattunes'] = core.updateAffixAttunes,
            ['zoneattunes'] = core.updateZoneAttunes,
            ['questtoken'] = core.updateQuestTokens,
            ['currency'] = core.updateCurrency,
            ['items'] = core.updateItems,
            ['dailyattunes'] = core.updateDailyAttunes,
            ['instancecap'] = core.updateInstanceCap,
            ['bagspace'] = core.updateBagSpace,
            ['wintergrasp'] = core.updateWintergrasp,
            ['dungeonchallenge'] = core.updateDungeonChallenge,
            ['dungeonspeedrun'] = core.updateDungeonSpeedrun,
            ['freetimer'] = core.updateFreeTimer,
        }
        
        for key, _ in pairs(core.definedBars) do
            interface.getBar(key)
            core.doUpdate(key)
        end
        
        core.setMode(options.get('mode'))
        
        core.attachAllEvents()
        
        interface.applyHideBlizzard()
        interface.reAnchorStanceBar()
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
    
        for key, events in pairs(core.definedBars) do
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
        
        interface.mainFrameInterfaceLoop(self)
        
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
        
        -- Toasts
        for _, key in ipairs(core.toastables) do
            if(core.update[key] and not core.toasts[key]) then
                core.doToasts(key)
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
                
                core.doUpdate('dungeonchallenge')
            elseif(event == 'finish-dungeon-challenge') then
                local instance = core.getActiveInstance(currentZoneId)
                
                instance.challengeStarted = true
                instance.challengeComplete = true
                instance.encountersRemain = 0
                
                if(instance.isSpeedrun and not instance.speedrunFailed) then
                    instance.speedrunComplete = true
                end
                
                core.doUpdate('dungeonchallenge')
                core.doUpdate('dungeonspeedrun')
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
        
        core.doUpdate('dungeonchallenge')
        core.doUpdate('dungeonspeedrun')
        
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
    ['updateTooltip'] = function(key)
        if(core.tooltipFontStrings and core.tooltipFontStrings[key]) then
            if(core.update[key] and core.updateFunctionMap[key]) then
                core.updateFunctionMap[key](key)
            end
            
            local _, rightText = core.getTooltipInfoLineContent(key)
            core.tooltipFontStrings[key]:SetText(rightText)
        end
    end,
    ['translateFormat'] = function(key)
        local textDisplay = core.values[key].textFormat
        
        if(core.values[key] == nil) then
            return ''
        end
        
        -- {C}, {M}
        if(core.values[key].currentValue and core.values[key].maxValue) then
            if(key == 'wintergrasp') then
                textDisplay = textDisplay:gsub('{C}', core.values[key].currentValue)
                textDisplay = textDisplay:gsub('{M}', core.values[key].maxValue)
            elseif(key == 'dungeonspeedrun' or key == 'freetimer') then
                textDisplay = textDisplay:gsub('{C}', utility.formatTimeLeft(core.values[key].currentValue))
                textDisplay = textDisplay:gsub('{M}', utility.formatTimeLeft(core.values[key].maxValue))
            else
                textDisplay = textDisplay:gsub('{C}', string.format('%d', core.values[key].currentValue))
                textDisplay = textDisplay:gsub('{M}', string.format('%d', core.values[key].maxValue))
            end
        end
        
        -- {P}
        if(core.values[key].percent) then
            textDisplay = textDisplay:gsub('{P}', string.format(lookup.percentFormat, core.values[key].percent))
        end
        
        -- {S}
        if(core.values[key].currentValue) then
            if(key == 'affixattunes') then
                textDisplay = textDisplay:gsub('{S}', (core.values[key].currentValue == 1) and '' or 'es')
            elseif(key ~= 'experience' and key ~= 'reputation' and key ~= 'currency' and key ~= 'items' and key ~= 'wintergrasp' and key ~= 'dungeonspeedrun' and key ~= 'freetimer') then
                textDisplay = textDisplay:gsub('{S}', (core.values[key].currentValue == 1) and '' or 's')
            end
        end
        
        -- {N}
        if(core.values[key].name) then
            if(key == 'reputation' or key == 'currency' or key == 'items') then
                textDisplay = textDisplay:gsub('{N}', core.values[key].name)
            end
        end
        
        -- {L}
        if(key == 'experience' and core.values[key].level) then
            textDisplay = textDisplay:gsub('{L}', string.format('%d', core.values[key].level))
        elseif(key == 'reputation' and core.values[key].standingId) then
            textDisplay = textDisplay:gsub('{L}', _G['FACTION_STANDING_LABEL' .. tostring(core.values[key].standingId)])
        end
        
        -- {C}
        if((key == 'equipattune' or key == 'bagattune' or key == 'attunebar') and core.values[key].itemCount) then
            textDisplay = textDisplay:gsub('{C}', string.format('%d', core.values[key].itemCount))
        end
        
        -- {U}
        if(key == 'wintergrasp') then
            textDisplay = textDisplay:gsub('{U}', core.values[key].certain and '' or ' (uncertain)')
        end
        
        -- {RC}, {RP}, {R:}
        if(key == 'experience') then
            if((core.values[key].rested or 0) == 0) then
                textDisplay = textDisplay:gsub('{R[CP]}', '')
                textDisplay = textDisplay:gsub('{R:.-}', '')
            else
                textDisplay = textDisplay:gsub('{RC}', string.format('%d', core.values[key].rested))
                textDisplay = textDisplay:gsub('{RP}', string.format(lookup.percentFormat, core.values[key].restedPercent))
                textDisplay = textDisplay:gsub('{R:(.-)}', '%1')
            end
        end
        
        return textDisplay
    end,
    ['updateExperience'] = function(key)
        local newFormat = options.get('experience-format')
        local newLevel = UnitLevel('player')
        local newMax = UnitXPMax('player')
        local newValue = UnitXP('player')
        local newRested = GetXPExhaustion()
        
        if(newLevel == 80) then
            if(core.values[key] == nil) then
                core.values[key] = {
                    ['textFormat'] = 'Max level',
                    ['level'] = newLevel,
                    ['percent'] = 0,
                    ['restedPercent'] = 0
                }
                
                return true
            elseif(core.values[key].level ~= newLevel) then
                options.set('experience-enabled', false, true)
                core.prepareUpdate(key, 'experience-enabled', false)
            
                core.values[key].textFormat = 'Max level'
                core.values[key].level = newLevel
                core.values[key].percent = 0
                core.values[key].restedPercent = 0
                
                return true
            end
            
            return false
        else
            if(core.values[key] == nil) then
                core.values[key] = {
                    ['textFormat'] = newFormat,
                    ['level'] = newLevel,
                    ['maxValue'] = newMax,
                    ['currentValue'] = newValue,
                    ['percent'] = (newValue / newMax) * 100,
                    ['rested'] = newRested,
                    ['restedPercent'] = (((newRested or 0) > 0) and ((newRested / newMax) * 100)) or 0,
                }
                
                return true
            elseif(core.values[key].textFormat ~= newFormat or core.values[key].level ~= newLevel or core.values[key].maxValue ~= newMax or core.values[key].currentValue ~= newValue or core.values[key].rested ~= newRested) then
                core.values[key].textFormat = newFormat
                core.values[key].level = newLevel
                core.values[key].maxValue = newMax
                core.values[key].currentValue = newValue
                core.values[key].percent = (newValue / newMax) * 100
                core.values[key].rested = newRested
                core.values[key].restedPercent = (((newRested or 0) > 0) and ((newRested / newMax) * 100)) or 0
                
                return true
            end
        end
        
        return false
    end,
    ['updateReputation'] = function(key)
        local newFormat = options.get('reputation-format')
        local newName, newStanding, newMin, newMax, newValue = GetWatchedFactionInfo()
        
        if(newName == nil) then
            if(options.get('reputation-follow-tracked')) then
                options.set('reputation-enabled', false, true)
                core.prepareUpdate('reputation', 'reputation-enabled', false)
                
                return false
            end
        
            if(core.values[key] == nil) then
                core.values[key] = {
                    ['textFormat'] = 'No tracked reputation',
                    ['percent'] = 0
                }
                
                return true
            elseif(core.values[key].name ~= nil) then
                core.values[key].textFormat = 'No tracked reputation'
                core.values[key].percent = 0
                core.values[key].name = nil
                
                return true
            end
            
            return false
        else
            newMax = newMax - newMin
            newValue = newValue - newMin
            
            if(core.values[key] == nil) then
                core.values[key] = {
                    ['textFormat'] = newFormat,
                    ['name'] = newName,
                    ['maxValue'] = newMax,
                    ['currentValue'] = newValue,
                    ['percent'] = (newValue / newMax) * 100,
                    ['standingId'] = newStanding,
                }
                
                return true
            elseif(core.values[key].textFormat ~= newFormat or core.values[key].maxValue ~= newMax or core.values[key].currentValue ~= newValue or core.values[key].standingId ~= newStanding) then
                core.values[key].textFormat = newFormat
                core.values[key].name = newName
                core.values[key].maxValue = newMax
                core.values[key].currentValue = newValue
                core.values[key].percent = (newValue / newMax) * 100
                core.values[key].standingId = newStanding
                
                return true
            end
        end
        
        return false
    end,
    ['updateEquipAttuning'] = function(key)
        local newFormat = options.get('equipattune-format')
        local newValues, changed = utility.getValuesForAttuneExp({
            {0xff, {0, 17}}
        }, core.values[key])
        
        if(newValues.itemCount == 0) then
            newFormat = options.get('equipattune-format-noitems')
        end
        
        if(core.values[key] == nil) then
            core.values[key] = newValues
            core.values[key].textFormat = newFormat
            changed = true
        else
            if(core.values[key].textFormat ~= newFormat) then
                core.values[key].textFormat = newFormat
                changed = true
            end
        end
        
        return changed
    end,
    ['updateBagAttuning'] = function(key)
        local newFormat = options.get('bagattune-format')
        
        local containerMap = {
            {0xff, {options.get('bagattune-include-equipped') == true and 0 or 23, 38}}
        }
        
        for bagId, bagIndex in pairs(lookup.bagIdMap) do
            local slots = GetContainerNumSlots(bagIndex)
            
            if(slots > 0) then
                table.insert(containerMap, {bagId, {0, slots - 1}})
            end
        end
        
        local newValues, changed = utility.getValuesForAttuneExp(containerMap, core.values[key])
        
        if(newValues.itemCount == 0) then
            newFormat = options.get('bagattune-format-noitems')
        end
        
        if(core.values[key] == nil) then
            core.values[key] = newValues
            core.values[key].textFormat = newFormat
            changed = true
        else
            if(core.values[key].textFormat ~= newFormat) then
                core.values[key].textFormat = newFormat
                changed = true
            end
        end
        
        return changed
    end,
    ['updateAttuneBarAttuning'] = function(key)
        local newFormat = options.get('attunebar-format')
        local newCount = 0
        local newPercent = 0
        local slotCount = GetCustomGameData(42, 0) or 0
        
        if(slotCount == 0) then
            newFormat = options.get('attunebar-format-nounlock')
        else
            for slotIndex = 0, (slotCount - 1) do
                local item = CustomGetItemInAttuneBarSlot(slotIndex)
                
                if(item ~= nil) then
                    newCount = newCount + 1
                    newPercent = newPercent + tonumber(GetItemLinkAttuneProgress(item.link) or 0)
                end
            end
            
            if(newCount == 0) then
                newFormat = options.get('attunebar-format-noitems')
            else
                newPercent = math.min(100, newPercent / newCount)
            end
        end
        
        if(core.values[key] == nil) then
            core.values[key] = {
                ['textFormat'] = newFormat,
                ['itemCount'] = newCount,
                ['percent'] = newPercent,
            }
            
            return true
        else
            if(core.values[key].textFormat ~= newFormat or core.values[key].itemCount ~= newCount or core.values[key].percent ~= newPercent) then
                core.values[key].textFormat = newFormat
                core.values[key].itemCount = newCount
                core.values[key].percent = newPercent
                
                return true
            end
        end
        
        return false
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
    ['updateCharacterAttunes'] = function(key)
        return core.setValuesForAttuneCounts(key, CalculateAttunedCount(1), ScootsProgressBar.maxAttunes.character)
    end,
    ['updateAccountAttunes'] = function(key)
        return core.setValuesForAttuneCounts(key, CalculateAttunedCount(), ScootsProgressBar.maxAttunes.account)
    end,
    ['updateAffixAttunes'] = function(key)
        return core.setValuesForAttuneCounts(key, CalculateAttunedAffixCount(), ScootsProgressBar.maxAttunes.affixes)
    end,
    ['updateZoneAttunes'] = function(key)
        local attunedCount = 0
        local itemCount = 0
        local currentZoneName = Custom_GetZoneName(Custom_GetCurrentZoneOur())
        
        for _, itemId in ipairs(ItemLocGetAllItemsInZone(-1, 0, 0, 1, 1)) do
            if(CanAttuneItemHelper(itemId) > 0) then
                ItemLocSetSourceSort(itemId, 3)
                
                local isAttuned = GetItemAttuneForge(itemId) >= 0
                local sourceCount = ItemLocGetSourceCount(itemId) or 0
                
                for index = 1, sourceCount do
                    local _, _, _, chance, _, _, zoneName = ItemLocGetSourceAt(itemId, index)
                    
                    if(chance < options.get('zoneattunes-min-chance')) then
                        break
                    end
                    
                    if(zoneName == currentZoneName) then
                        itemCount = itemCount + 1
                        
                        if(isAttuned) then
                            attunedCount = attunedCount + 1
                        end
                        
                        break
                    end
                end
            end
        end
        
        local changed = core.setValuesForAttuneCounts(key, attunedCount, itemCount)
        
        if(itemCount == 0) then
            core.values[key].textFormat = 'No attuneable items in ' .. currentZoneName
        end
        
        return changed
    end,
    ['updateQuestTokens'] = function(key)
        core.delayUpdate(key, 1)
    
        local newFormat = options.get('questtoken-format')
        local newValue = GetCustomGameData(29, 1692)
        
        if(newValue == 100) then
            newValue = 0
        end
        
        if(core.values[key] == nil) then
            core.values[key] = {
                ['textFormat'] = newFormat,
                ['maxValue'] = 100,
                ['currentValue'] = newValue,
                ['percent'] = newValue,
            }
            
            return true
        elseif(core.values[key].textFormat ~= newFormat or core.values[key].currentValue ~= newValue) then
            core.values[key].textFormat = newFormat
            core.values[key].currentValue = newValue
            core.values[key].percent = newValue
            
            return true
        end
        
        return false
    end,
    ['doToasts'] = function(key)
        core.toasts[key] = true
        
        if(not options.get(key .. '-toast-on-reach-target') and not options.get(key .. '-chat-on-reach-target')) then
            return
        end
        
        if(core.values[key] ~= nil) then
            local newValue, newName
            local newItem = options.get(key .. '-id')
            local newMax = options.get(key .. '-target')
            
            if(newItem ~= nil and core.values[key].itemId == newItem and core.values[key].maxValue == newMax) then
                local fetchedValues
                
                if(key == 'currency') then
                    fetchedValues = utility.getNewCurrencyValue(newItem)
                elseif(key == 'items') then
                    fetchedValues = utility.getNewItemsValue(newItem)
                end
                
                if(fetchedValues) then
                    newValue = fetchedValues.quantity
                    newName = fetchedValues.name
                end
                
                if(newValue ~= nil and newName ~= nil and core.values[key].maxValue > core.values[key].currentValue and newValue >= newMax) then
                    local message = string.format('You have collected %d × %s!', newMax, (select(2, GetItemInfoCustom(newItem))))
                
                    if(options.get(key .. '-toast-on-reach-target')) then
                        utility.displayToast(message)
                    end
                    
                    if(options.get(key .. '-chat-on-reach-target')) then
                        utility.displayChatMessage(message)
                    end
                end
            end
        end
    end,
    ['updateCurrency'] = function(key)
        local newFormat = options.get('currency-format')
        local newItem = options.get('currency-id')
        local fetchedValues

        if(newItem ~= nil) then
            fetchedValues = utility.getNewCurrencyValue(newItem)
        end
        
        core.toasts[key] = nil
        
        if(newItem == nil or fetchedValues.quantity == nil) then
            newFormat = options.get('currency-format-noselected')
        
            if(core.values[key] == nil) then
                core.values[key] = {
                    ['textFormat'] = newFormat,
                    ['percent'] = 0,
                }
                
                return true
            elseif(core.values[key].itemId ~= nil) then
                core.values[key].textFormat = newFormat
                core.values[key].itemId = nil
                core.values[key].percent = 0
                
                return true
            end
        else
            local newValue = fetchedValues.quantity
            local newName = fetchedValues.name
            local newMax = options.get('currency-target')
            local newPercent = math.min(100, (newValue / newMax) * 100)
        
            if(core.values[key] == nil) then
                core.values[key] = {
                    ['textFormat'] = newFormat,
                    ['itemId'] = newItem,
                    ['name'] = newName,
                    ['maxValue'] = newMax,
                    ['currentValue'] = newValue,
                    ['percent'] = newPercent,
                }
                
                return true
            elseif(core.values[key].itemId ~= newItem or core.values[key].currentValue ~= newValue or core.values[key].maxValue ~= newMax) then
                core.values[key].textFormat = newFormat
                core.values[key].itemId = newItem
                core.values[key].name = newName
                core.values[key].maxValue = newMax
                core.values[key].currentValue = newValue
                core.values[key].percent = newPercent
                
                return true
            end
        end
        
        return false
    end,
    ['updateItems'] = function(key)
        utility.scanBank()
        
        local newFormat = options.get('items-format')
        local newItem = options.get('items-id')
        
        core.toasts[key] = nil
        
        if(newItem == nil) then
            newFormat = options.get('items-format-noselected')
        
            if(core.values[key] == nil) then
                core.values[key] = {
                    ['textFormat'] = newFormat,
                    ['percent'] = 0,
                }
                
                return true
            elseif(core.values[key].itemId ~= nil) then
                core.values[key].textFormat = newFormat
                core.values[key].itemId = nil
                core.values[key].percent = 0
                
                return true
            end
        else
            local fetchedValues = utility.getNewItemsValue(newItem)
            local newValue = fetchedValues.quantity
            local newName = fetchedValues.name
            local newMax = options.get('items-target')
            local newPercent = math.min(100, (newValue / newMax) * 100)
        
            if(core.values[key] == nil) then
                core.values[key] = {
                    ['textFormat'] = newFormat,
                    ['itemId'] = newItem,
                    ['name'] = newName,
                    ['maxValue'] = newMax,
                    ['currentValue'] = newValue,
                    ['percent'] = newPercent,
                }
                
                return true
            elseif(core.values[key].itemId ~= newItem or core.values[key].currentValue ~= newValue or core.values[key].maxValue ~= newMax) then
                core.values[key].textFormat = newFormat
                core.values[key].itemId = newItem
                core.values[key].name = newName
                core.values[key].maxValue = newMax
                core.values[key].currentValue = newValue
                core.values[key].percent = newPercent
                
                return true
            end
        end
        
        return false
    end,
    ['updateDailyAttunes'] = function(key)
        local newFormat = options.get('dailyattunes-format')
        local newMax = options.get('dailyattunes-target')
        
        local start, now, optionsString
        
        if(options.get('dailyattunes-char-or-acc') == 'char') then
            if(options.get('dailyattunes-count-affixes')) then
                start = storage.dayStartAttunes.character[core.player.guid].incAffixes.base
                now = CalculateAttunedCount(3)
                optionsString = 'c+a:%d'
            else
                start = storage.dayStartAttunes.character[core.player.guid].exAffixes.base
                now = CalculateAttunedCount(1)
                optionsString = 'c-a:%d'
            end
        else
            if(options.get('dailyattunes-count-affixes')) then
                start = storage.dayStartAttunes.account.incAffixes.base
                now = CalculateAttunedCount(2)
                optionsString = 'a+a:%d'
            else
                start = storage.dayStartAttunes.account.exAffixes.base
                now = CalculateAttunedCount()
                optionsString = 'a-a:%d'
            end
        end
        
        local newValue = now - start
        local newPercent = math.min(100, (newValue / newMax) * 100)
        optionsString = string.format(optionsString, newMax)
        
        if(core.values[key] == nil) then
            core.values[key] = {
                ['textFormat'] = newFormat,
                ['maxValue'] = newMax,
                ['currentValue'] = newValue,
                ['percent'] = newPercent,
                ['optionsString'] = optionsString,
            }
            
            return true
        elseif(core.values[key].textFormat ~= newFormat or core.values[key].maxValue ~= newMax or core.values[key].currentValue ~= newValue) then
            if(newValue >= newMax and core.values[key].currentValue < core.values[key].maxValue and core.values[key].optionsString == optionsString) then
                local message = string.format('You have attuned %d new items today!', newMax)
            
                if(options.get('freetimer-toast-on-end')) then
                    utility.displayToast(message)
                end
                
                if(options.get('freetimer-chat-on-end')) then
                    utility.displayChatMessage(message)
                end
            end
            
            core.values[key].textFormat = newFormat
            core.values[key].maxValue = newMax
            core.values[key].currentValue = newValue
            core.values[key].percent = newPercent
            core.values[key].optionsString = optionsString
            
            return true
        end
        
        return false
    end,
    ['updateInstanceCap'] = function(key)
        core.delayUpdate(key, 1)
        
        utility.clearOldInstances()
        
        local newFormat = options.get('instancecap-format')
        local newMax = 40
        local newValue = newMax

        for _, instances in pairs(storage.instances) do
            newValue = newValue - #instances.reset
            
            for _, _ in pairs(instances.active) do
                newValue = newValue - 1
            end
        end
        
        newValue = math.max(0, newValue)
        newPercent = (newValue / newMax) * 100
        
        if(core.values[key] == nil) then
            core.values[key] = {
                ['textFormat'] = newFormat,
                ['maxValue'] = newMax,
                ['currentValue'] = newValue,
                ['percent'] = newPercent,
            }
            
            return true
        elseif(core.values[key].textFormat ~= newFormat or core.values[key].currentValue ~= newValue) then
            core.values[key].textFormat = newFormat
            core.values[key].currentValue = newValue
            core.values[key].percent = newPercent
            
            return true
        end
        
        return false
    end,
    ['updateBagSpace'] = function(key)
        local newFormat = options.get('bagspace-format')
        local newMax = 0
        local newValue = 0
    
        for bagIndex = 0, 4 do
            local containerSlots = GetContainerNumSlots(bagIndex)
            newMax = newMax + containerSlots
            newValue = newValue + containerSlots
        
            for slotIndex = 1, containerSlots do
                local itemLink = select(7, GetContainerItemInfo(bagIndex, slotIndex))
                
                if(itemLink) then
                    newValue = newValue - 1
                end
            end
        end
        
        local newPercent = (newValue / newMax) * 100
        
        if(core.values[key] == nil) then
            core.values[key] = {
                ['textFormat'] = newFormat,
                ['maxValue'] = newMax,
                ['currentValue'] = newValue,
                ['percent'] = newPercent,
            }
            
            return true
        elseif(core.values[key].textFormat ~= newFormat or core.values[key].maxValue ~= newMax or core.values[key].currentValue ~= newValue) then
            core.values[key].textFormat = newFormat
            core.values[key].maxValue = newMax
            core.values[key].currentValue = newValue
            core.values[key].percent = newPercent
            
            return true
        end
        
        return false
    end,
    ['updateWintergrasp'] = function(key)
        core.delayUpdate(key, 0.25)
        
        local timeUntilNext, inProgress, certain = utility.getTimeForNextWintergrasp()
        
        if(timeUntilNext == nil) then
            if(core.values[key] == nil) then
                core.values[key] = {
                    ['textFormat'] = '<Unable to query Wintergrasp>',
                    ['percent'] = 0,
                }
                
                return true
            elseif(core.values[key].percent ~= 0) then
                core.values[key].textFormat = '<Unable to query Wintergrasp>'
                core.values[key].percent = 0
                
                return true
            end
        else
            local newFormat = options.get('wintergrasp-format')
            local newValue = string.format('%d:%02d:%02d', math.floor(timeUntilNext / 3600), math.floor((timeUntilNext % 3600) / 60), timeUntilNext % 60)
            local newPercent = math.max(0, 100 - ((timeUntilNext / 9000) * 100))
            
            if(certain and inProgress) then
                newFormat = options.get('wintergrasp-format-inprogress')
            end
            
            if(core.values[key] == nil) then
                core.values[key] = {
                    ['textFormat'] = newFormat,
                    ['maxValue'] = '2:30:00',
                    ['currentValue'] = newValue,
                    ['percent'] = newPercent,
                    ['inProgress'] = inProgress,
                    ['certain'] = certain,
                }
                
                return true
            elseif(core.values[key].textFormat ~= newFormat or core.values[key].currentValue ~= newValue or core.values[key].certain ~= certain) then
                core.values[key].textFormat = newFormat
                core.values[key].maxValue = '2:30:00'
                core.values[key].currentValue = newValue
                core.values[key].percent = newPercent
                core.values[key].inProgress = inProgress
                core.values[key].certain = certain
                
                return true
            end
        end
        
        return false
    end,
    ['updateDungeonChallenge'] = function(key)
        local newFormat = options.get('dungeonchallenge-format')
        local currentZoneId = Custom_GetCurrentZone()
        local instance = core.getActiveInstance(currentZoneId)
        
        if(instance and not instance.challengeStarted) then
            local isChallenge = utility.getDungeonChallenge()
            
            if(not isChallenge) then
                instance = nil
            end
        end
        
        if(instance == nil or instance.challengeStarted == false) then
            newFormat = options.get('dungeonchallenge-format-noactive')
            
            if(core.values[key] == nil) then
                core.values[key] = {
                    ['textFormat'] = newFormat,
                    ['percent'] = 0,
                }
                
                return true
            elseif(core.values[key].currentValue ~= nil) then
                core.values[key].textFormat = newFormat
                core.values[key].percent = 0
                core.values[key].currentValue = nil
                
                return true
            end
        else
            local newComplete, newFailed = false, false
            local newMax = instance.encountersTotal
            local newValue = instance.encountersTotal - instance.encountersRemain
            local newPercent = (newValue / newMax) * 100
        
            if(instance.challengeComplete) then
                newValue = instance.encountersTotal
                newPercent = 100
            elseif(instance.challengeFailed) then
                newFormat = options.get('dungeonchallenge-format-failed')
                newValue = 0
                newPercent = 0
            end
            
            if(core.values[key] == nil) then
                core.values[key] = {
                    ['textFormat'] = newFormat,
                    ['maxValue'] = newMax,
                    ['currentValue'] = newValue,
                    ['percent'] = newPercent,
                }
                
                return true
            elseif(core.values[key].textFormat ~= newFormat or core.values[key].textFormat ~= newMax or core.values[key].textFormat ~= newValue) then
                core.values[key].textFormat = newFormat
                core.values[key].maxValue = newMax
                core.values[key].currentValue = newValue
                core.values[key].percent = newPercent
                
                return true
            end
        end
        
        return false
    end,
    ['updateDungeonSpeedrun'] = function(key)
        local newFormat = options.get('dungeonspeedrun-format')
        
        local currentZoneId = Custom_GetCurrentZone()
        local instance = core.getActiveInstance(currentZoneId)
        
        if(instance ~= nil and instance.isSpeedrun and not instance.speedrunComplete and not instance.speedrunFailed) then
            local speedrunLeft = select(3, utility.getDungeonChallenge())
            
            if((speedrunLeft or 0) > 0) then
                instance.speedrunCurrent = speedrunLeft
                
                core.delayUpdate(key, 0.05)
            else
                instance.speedrunFailed = true
                instance.speedrunCurrent = 0
            end
        end
        
        if(instance == nil or not instance.isSpeedrun) then
            newFormat = options.get('dungeonspeedrun-format-noactive')
        
            if(core.values[key] == nil) then
                core.values[key] = {
                    ['textFormat'] = newFormat,
                    ['percent'] = 0,
                }
                
                return true
            elseif(core.values[key].currentValue ~= nil) then
                core.values[key].textFormat = newFormat
                core.values[key].percent = 0
                core.values[key].complete = nil
                core.values[key].failed = nil
                core.values[key].currentValue = nil
                
                return true
            end
        else
            local newMax = instance.speedrunStart
            local newValue = instance.speedrunCurrent
            local newPercent = ((instance.speedrunStart - instance.speedrunCurrent) / instance.speedrunStart) * 100
            local newComplete = instance.speedrunComplete
            local newFailed = instance.speedrunFailed
        
            if(core.values[key] == nil) then
                core.values[key] = {
                    ['textFormat'] = newFormat,
                    ['maxValue'] = newMax,
                    ['currentValue'] = newValue,
                    ['percent'] = newPercent,
                    ['complete'] = newComplete,
                    ['failed'] = newFailed,
                }
                
                return true
            elseif(core.values[key].textFormat ~= newFormat
                or core.values[key].maxValue ~= newMax
                or core.values[key].currentValue ~= newValue
                or core.values[key].percent ~= newPercent
                or core.values[key].complete ~= newComplete
                or core.values[key].failed ~= newFailed
            ) then
                core.values[key].textFormat = newFormat
                core.values[key].maxValue = newMax
                core.values[key].currentValue = newValue
                core.values[key].percent = newPercent
                core.values[key].complete = newComplete
                core.values[key].failed = newFailed
                
                return true
            end
        end
        
        return false
    end,
    ['updateFreeTimer'] = function(key)
        local newFormat = options.get('freetimer-format')
        local nowTime = utility.clientTime()
        
        if(storage.timerStart == nil) then
            newFormat = options.get('freetimer-format-noset')
            
            if(core.values[key] == nil) then
                core.values[key] = {
                    ['textFormat'] = newFormat,
                    ['percent'] = 0,
                }
                
                return true
            elseif(core.values[key].currentValue ~= nil) then
                core.values[key].textFormat = newFormat
                core.values[key].percent = 0
                core.values[key].currentValue = nil
                
                return true
            end
        elseif((storage.timerEnd or 0) < nowTime) then
            newFormat = options.get('freetimer-format-finished')
            
            if(core.values[key] == nil) then
                core.values[key] = {
                    ['textFormat'] = newFormat,
                    ['percent'] = 100,
                }
                
                return true
            elseif(core.values[key].currentValue ~= nil) then
                core.values[key].textFormat = newFormat
                core.values[key].percent = 100
                core.values[key].currentValue = nil
                
                local message = string.format('Your %s timer has finished.', utility.humanTime(math.floor(storage.timerEnd - storage.timerStart)))
            
                if(options.get('freetimer-toast-on-end')) then
                    utility.displayToast(message)
                end
                
                if(options.get('freetimer-chat-on-end')) then
                    utility.displayChatMessage(message)
                end
                
                return true
            end
        else
            local newMax = math.floor(storage.timerEnd - storage.timerStart)
            local newValue = nowTime - storage.timerStart
            local newPercent = math.min(100, (newValue / newMax) * 100)
            
            newValue = newMax - newValue
            
            if(core.values[key] == nil) then
                core.values[key] = {
                    ['textFormat'] = newFormat,
                    ['maxValue'] = newMax,
                    ['currentValue'] = newValue,
                    ['percent'] = newPercent,
                }
            elseif(core.values[key].textFormat ~= newFormat or core.values[key].maxValue ~= newMax or core.values[key].currentValue ~= newValue) then
                core.values[key].textFormat = newFormat
                core.values[key].maxValue = newMax
                core.values[key].currentValue = newValue
                core.values[key].percent = newPercent
            end
            
            core.delayUpdate(key, 0.05)
            
            return true
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
        local leftText, rightText = core.getTooltipInfoLineContent(key)
        local _, rightFontString = utility.addTooltipDoubleLine(leftText, rightText)
        core.tooltipFontStrings = core.tooltipFontStrings or {}
        core.tooltipFontStrings[key] = rightFontString
    end,
    ['getTooltipInfoLineContent'] = function(key)
        local leftText, rightText
        local values = core.values[key]
        
        if(key == 'experience') then
            leftText = 'Experience'
            
            if(UnitLevel('player') == 80) then
                rightText = 'At max level'
            else
                rightText = string.format(
                    '%d / %d (' .. lookup.percentFormat .. '%%)',
                    values.currentValue,
                    values.maxValue,
                    values.percent
                )
                
                if((values.rested or 0) > 0) then
                    rightText = rightText .. string.format(' (' .. lookup.percentFormat .. '%% rested)', values.percent)
                end
            end
        elseif(key == 'reputation') then
            if(values.name ~= nil) then
                leftText = values.name
                rightText = string.format(
                    '%s - %d / %d (' .. lookup.percentFormat .. '%%)',
                    _G['FACTION_STANDING_LABEL' .. tostring(values.standingId)],
                    values.currentValue,
                    values.maxValue,
                    values.percent
                )
            else
                leftText = 'Reputation'
                rightText = 'None selected'
            end
        elseif(key == 'equipattune' or key == 'bagattune' or key == 'attunebar') then
            leftText = (key == 'equipattune' and 'Equipped Items') or (key == 'bagattune' and 'Inventory Equipment') or 'Attune Bar'
            
            if(values.itemCount == 0) then
                rightText = 'Not attuning any items'
            else
                rightText = string.format(
                    'Attuning %d item%s (' .. lookup.percentFormat .. '%%)',
                    values.itemCount,
                    values.itemCount ~= 1 and 's' or '',
                    values.percent
                )
            end
        elseif(key == 'charattunes' or key == 'accattunes' or key == 'affixattunes' or key == 'zoneattunes' or key == 'dailyattunes') then
            leftText = (key == 'charattunes' and 'Character Attunes') or (key == 'accattunes' and 'Account Attunes') or (key == 'affixattunes' and 'Affix Attunes') or (key == 'zoneattunes' and 'Zone Attunes') or (key == 'dailyattunes' and 'Daily Attunes')
            rightText = string.format(
                '%d / %d (' .. lookup.percentFormat .. '%%)',
                values.currentValue,
                values.maxValue,
                values.percent
            )
        elseif(key == 'questtoken' or key == 'instancecap' or key == 'bagspace') then
            leftText = (key == 'questtoken' and 'Quest Token') or (key == 'instancecap' and 'Instances available') or (key == 'bagspace' and 'Free bag space')
            rightText = string.format(
                '%d / %d',
                values.currentValue,
                values.maxValue
            )
        elseif(key == 'dungeonchallenge') then
            leftText = 'Dungeon challenge'
            
            if(values.currentValue ~= nil) then
                rightText = string.format(
                    '%d / %d',
                    values.currentValue,
                    values.maxValue
                )
            else
                rightText = 'None active'
            end
        elseif(key == 'currency' or key == 'items') then
            if(values.itemId ~= nil) then
                leftText = values.itemName
                rightText = string.format(
                    '%d / %d (' .. lookup.percentFormat .. '%%)',
                    values.currentValue,
                    values.maxValue,
                    values.percent
                )
            else
                leftText = key == 'currency' and 'Currency' or 'Items'
                rightText = 'None selected'
            end
        elseif(key == 'wintergrasp') then
            leftText = (key == 'wintergrasp' and 'Wintergrasp') or (key == 'dungeonspeedrun' and 'Dungeon speedrun') or (key == 'freetimer' and 'Free timer')
            rightText = string.format(
                '%s%s',
                values.currentValue,
                values.certain and '' or ' (?)'
            )
        elseif(key == 'dungeonspeedrun' or key == 'freetimer') then
            leftText = (key == 'dungeonspeedrun' and 'Dungeon speedrun') or (key == 'freetimer' and 'Free timer')
            
            if(values.currentValue and values.maxValue) then
                rightText = string.format(
                    '%s / %s',
                    utility.formatTimeLeft(values.currentValue),
                    utility.formatTimeLeft(values.maxValue)
                )
            else
                rightText = 'None active'
            end
        end
    
        return leftText, rightText
    end,
    ['startTimer'] = function()
        local hours, minutes, seconds = options.get('freetimer-hours'), options.get('freetimer-minutes'), options.get('freetimer-seconds')
        
        seconds = seconds + (minutes * 60) + (hours * 3600)
        
        if(seconds == 0) then
            return
        end
        
        storage.timerStart = utility.clientTime()
        storage.timerEnd = storage.timerStart + seconds
        core.doUpdate('freetimer')
    end,
    ['stopTimer'] = function()
        if((storage.timerStart or 0) > 0) then
            core.update['freetimer'] = true
        end
        
        storage.timerStart = nil
        storage.timerEnd = nil
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
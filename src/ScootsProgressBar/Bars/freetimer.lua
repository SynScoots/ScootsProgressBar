local storage = ScootsProgressBar.storage
local core = ScootsProgressBar.core
local options = ScootsProgressBar.options
local frames = ScootsProgressBar.frames
local interface = ScootsProgressBar.interface
local utility = ScootsProgressBar.utility
local lookup = ScootsProgressBar.lookup

local key = 'freetimer'

--============--
----- CORE -----
--============--

core.definedBars[key] = 'Free timer'

core.barEvents[key] = {
    'ZONE_CHANGED_NEW_AREA',
    'PLAYER_ENTERING_WORLD',
}

core.updateFunctionMap[key] = function()
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
end

core.textFormatFunctionMap[key] = function(text)
    if(core.values[key].currentValue) then
        text = text:gsub('{C}', utility.formatTimeLeft(core.values[key].currentValue))
    end
    
    if(core.values[key].maxValue) then
        text = text:gsub('{M}', utility.formatTimeLeft(core.values[key].maxValue))
    end
    
    return text
end

core.tooltipLineFunctionMap[key] = function()
    local leftText = core.definedBars[key]
    local rightText
    
    if(core.values[key].currentValue and core.values[key].maxValue) then
        rightText = string.format(
            '%s / %s',
            utility.formatTimeLeft(core.values[key].currentValue),
            utility.formatTimeLeft(core.values[key].maxValue)
        )
    else
        rightText = 'None active'
    end
    
    return leftText, rightText
end

local stopTimer = function()
    if((storage.timerStart or 0) > 0) then
        core.update['freetimer'] = true
    end
    
    storage.timerStart = nil
    storage.timerEnd = nil
end

--===========--
-- INTERFACE --
--===========--

interface.applyColoursFunctionMap[key] = function(bar)
    local colour
    local bgColour = options.get('freetimer-background-colour')
        
    if(core.values[key].percent == 100) then
        colour = options.get('freetimer-finished-colour')
    else
        colour = options.get('freetimer-colour')
    end
    
    bar.progress:SetVertexColor(colour.r, colour.g, colour.b, colour.a)
    bar.background:SetVertexColor(bgColour.r, bgColour.g, bgColour.b, bgColour.a)
end

interface.mouseInterceptScriptHooks['OnMouseUp'] = interface.mouseInterceptScriptHooks['OnMouseUp'] or {}
table.insert(interface.mouseInterceptScriptHooks['OnMouseUp'], function(self, mouseButton)
    if(IsShiftKeyDown() and options.get('freetimer-enabled')) then
        if(mouseButton == 'LeftButton') then
            local hours, minutes, seconds = options.get('freetimer-hours'), options.get('freetimer-minutes'), options.get('freetimer-seconds')
            
            seconds = seconds + (minutes * 60) + (hours * 3600)
            
            if(seconds == 0) then
                return
            end
            
            storage.timerStart = utility.clientTime()
            storage.timerEnd = storage.timerStart + seconds
            core.doUpdate(key)
        elseif(mouseButton == 'RightButton') then
            if((storage.timerStart or 0) > 0) then
                core.update['freetimer'] = true
            end
            
            storage.timerStart = nil
            storage.timerEnd = nil
        end
    end
end)

table.insert(interface.tooltipExtraLineCallbacks, function()
    if(utility.isBarValid(key) or utility.getActiveBar() == key) then
        GameTooltip:AddLine(' ', nil, nil, nil, true)
        utility.addTooltipDoubleLine('Shift + left click', 'Start timer')
        utility.addTooltipDoubleLine('Shift + right click', 'Stop timer')
    end
end)

--===========--
--- OPTIONS ---
--===========--

options.defaultCategories[key] = {
    ['enabled'] = false,
    ['order'] = 20,
    ['format'] = 'Timer - {C} / {M}',
    ['background-colour'] = {['r'] = 1, ['g'] = 1, ['b'] = 1, ['a'] = 1},
    ['colour'] = {['r'] = 0.90, ['g'] = 0.82, ['b'] = 0.65, ['a'] = 1},
    ['finished-colour'] = {['r'] = 0.35, ['g'] = 0.05, ['b'] = 0.25, ['a'] = 1},
    ['hours'] = 0,
    ['minutes'] = 1,
    ['seconds'] = 0,
    ['toast-on-end'] = false,
    ['chat-on-end'] = false,
    ['format-noset'] = 'No timer set',
    ['format-finished'] = 'Timer finished',
}

options.optionPageDefinitions[key] = {
    ['framename'] = 'FreeTimer',
    ['title'] = core.definedBars[key],
    ['description'] = 'A timer you can set to whatever you like. (Re)start the timer by shift-left-clicking on the bar, stop the timer by shift-right-clicking on the bar.',
    ['callback'] = function(data)
        local fields = options.defineStandardOptions(data, {
            ['formatHint'] = {
                {'{C}', 'Current timer'},
                {'{M}', 'Max timer'},
                {'{P}', 'Percent progress'},
            },
        })
        
        for _, field in ipairs({
            {
                ['key'] = 'finished-colour',
                ['type'] = 'colour',
                ['framename'] = 'ColourPicker-Finished',
                ['text'] = 'Finished colour',
            },
            {
                ['key'] = 'hours',
                ['type'] = 'increment-text',
                ['framename'] = 'Hours',
                ['label'] = 'Hours',
                ['increment'] = 1,
                ['min'] = 0,
                ['width'] = 40,
            },
            {
                ['key'] = 'minutes',
                ['type'] = 'increment-text',
                ['framename'] = 'Minutes',
                ['label'] = 'Minutes',
                ['increment'] = 1,
                ['min'] = 0,
                ['max'] = 59,
                ['width'] = 40,
            },
            {
                ['key'] = 'seconds',
                ['type'] = 'increment-text',
                ['framename'] = 'Seconds',
                ['label'] = 'Seconds',
                ['increment'] = 1,
                ['min'] = 0,
                ['max'] = 59,
                ['width'] = 40,
            },
            {
                ['key'] = 'toast-on-end',
                ['type'] = 'checkbox',
                ['framename'] = 'ToastOnEnd',
                ['label'] = 'Toast on reaching target',
                ['tooltip'] = 'Displays a message in the centre of the screen when the timer ends.',
            },
            {
                ['key'] = 'chat-on-end',
                ['type'] = 'checkbox',
                ['framename'] = 'ChatOnEnd',
                ['label'] = 'Chat message on reaching target',
                ['tooltip'] = 'Displays a message in the chat when the timer ends.',
            },
            {
                ['key'] = 'format-noset',
                ['type'] = 'reset-text',
                ['framename'] = 'FormatNoSet',
                ['label'] = 'Text when no timer set',
                ['resetValue'] = options.defaults['freetimer-format-noset'],
                ['resetText'] = 'Apply default',
                ['width'] = 250,
            },
            {
                ['key'] = 'format-finished',
                ['type'] = 'reset-text',
                ['framename'] = 'FormatFinished',
                ['label'] = 'Text when timer finished',
                ['resetValue'] = options.defaults['freetimer-format-finished'],
                ['resetText'] = 'Apply default',
                ['width'] = 250,
            },
            {
                ['key'] = 'start-timer',
                ['type'] = 'button',
                ['framename'] = 'StartTimer',
                ['width'] = 120,
                ['text'] = 'Start timer',
                ['callback'] = function()
                    core.startTimer()
                end,
            },
            {
                ['key'] = 'stop-timer',
                ['type'] = 'button',
                ['framename'] = 'StopTimer',
                ['width'] = 120,
                ['text'] = 'Stop timer',
                ['callback'] = function()
                    core.stopTimer()
                end,
            },
        }) do
            field.key = string.format('%s-%s', key, field.key)
            field.framename = string.format('%s-%s', data.framename, field.framename)
            table.insert(fields, field)
        end
    
        return fields
    end,
}
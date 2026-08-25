local storage = ScootsProgressBar.storage
local core = ScootsProgressBar.core
local options = ScootsProgressBar.options
local frames = ScootsProgressBar.frames
local interface = ScootsProgressBar.interface
local utility = ScootsProgressBar.utility
local lookup = ScootsProgressBar.lookup

local key = 'wintergrasp'

--============--
----- CORE -----
--============--

core.definedBars[key] = 'Wintergrasp'

core.barEvents[key] = {
    'ZONE_CHANGED_NEW_AREA',
    'PLAYER_ENTERING_WORLD',
}

core.updateFunctionMap[key] = function()
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
end

core.textFormatFunctionMap[key] = function(text)
    if(core.values[key].currentValue) then
        text = text:gsub('{C}', core.values[key].currentValue)
    end
    
    if(core.values[key].maxValue) then
        text = text:gsub('{M}', core.values[key].maxValue)
    end
    
    text = text:gsub('{U}', core.values[key].certain and '' or ' (uncertain)')
    
    return text
end

core.tooltipLineFunctionMap[key] = function()
    local leftText = core.definedBars[key]
    local rightText = string.format(
        '%s%s',
        core.values[key].currentValue,
        core.values[key].certain and '' or ' (?)'
    )
    
    return leftText, rightText
end

--===========--
-- INTERFACE --
--===========--

interface.applyColoursFunctionMap[key] = function(bar)
    local colour
    local bgColour = options.get('wintergrasp-background-colour')
    
    if(not core.values[key].certain or not core.values[key].inProgress) then
        colour = options.get('wintergrasp-colour')
    else
        colour = options.get('wintergrasp-inprogress-colour')
    end
    
    bar.progress:SetVertexColor(colour.r, colour.g, colour.b, colour.a)
    bar.background:SetVertexColor(bgColour.r, bgColour.g, bgColour.b, bgColour.a)
end

--===========--
--- OPTIONS ---
--===========--

options.defaultCategories[key] = {
    ['enabled'] = false,
    ['order'] = 17,
    ['format'] = 'Wintergrasp{U} - {C}',
    ['background-colour'] = {['r'] = 1, ['g'] = 1, ['b'] = 1, ['a'] = 1},
    ['colour'] = {['r'] = 0.55, ['g'] = 0.55, ['b'] = 0.20, ['a'] = 1},
    ['inprogress-colour'] = {['r'] = 0.4675, ['g'] = 0.4675, ['b'] = 0.17, ['a'] = 1},
    ['format-inprogress'] = 'In progress',
}

options.optionPageDefinitions[key] = {
    ['framename'] = 'Wintergrasp',
    ['title'] = core.definedBars[key],
    ['description'] = table.concat({
        'Time until the next Wintergrasp.',
        'You need to visit the overworld while Wintergrasp is not in-progress to get a timer, and need to have done so since the last battle for the timer to not be considered "uncertain".',
    }, '\n\n'),
    ['callback'] = function(data)
        local fields = options.defineStandardOptions(data, {
            ['formatHint'] = {
                {'{C}', 'Current timer'},
                {'{M}', 'Max timer'},
                {'{P}', 'Percent progress'},
                {'{U}', ' (Uncertain)'},
            },
        })
        
        for _, field in ipairs({
            {
                ['key'] = 'inprogress-colour',
                ['type'] = 'colour',
                ['framename'] = 'ColourPicker-InProgress',
                ['text'] = 'In-progress colour',
            },
            {
                ['key'] = 'format-inprogress',
                ['type'] = 'reset-text',
                ['framename'] = 'FormatInProgress',
                ['label'] = 'Text when in progress',
                ['resetValue'] = options.defaults['wintergrasp-format-inprogress'],
                ['resetText'] = 'Apply default',
                ['width'] = 250,
            },
        }) do
            field.key = string.format('%s-%s', key, field.key)
            field.framename = string.format('%s-%s', data.framename, field.framename)
            table.insert(fields, field)
        end
    
        return fields
    end,
}
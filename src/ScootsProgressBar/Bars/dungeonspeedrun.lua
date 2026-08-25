local storage = ScootsProgressBar.storage
local core = ScootsProgressBar.core
local options = ScootsProgressBar.options
local frames = ScootsProgressBar.frames
local interface = ScootsProgressBar.interface
local utility = ScootsProgressBar.utility
local lookup = ScootsProgressBar.lookup

local key = 'dungeonspeedrun'

--============--
----- CORE -----
--============--

core.definedBars[key] = 'Dungeon speedrun'

core.barEvents[key] = {
    'ZONE_CHANGED_NEW_AREA',
    'PLAYER_ENTERING_WORLD',
    'UNIT_AURA',
    'PLAYER_AURAS_CHANGED',
}

core.updateFunctionMap[key] = function()
    utility.clearOldInstances()
    
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

--===========--
-- INTERFACE --
--===========--

interface.applyColoursFunctionMap[key] = function(bar)
    local colour
    local bgColour = options.get('dungeonspeedrun-background-colour')
    
    if(core.values[key].success) then
        colour = options.get('dungeonspeedrun-success-colour')
    elseif(core.values[key].failed) then
        colour = options.get('dungeonspeedrun-failed-colour')
    else
        colour = options.get('dungeonspeedrun-colour')
    end
    
    bar.progress:SetVertexColor(colour.r, colour.g, colour.b, colour.a)
    bar.background:SetVertexColor(bgColour.r, bgColour.g, bgColour.b, bgColour.a)
end

--===========--
--- OPTIONS ---
--===========--

options.defaultCategories[key] = {
    ['enabled'] = false,
    ['order'] = 19,
    ['format'] = 'Dungeon speedrun - {C} / {M} ({P}%)',
    ['background-colour'] = {['r'] = 1, ['g'] = 1, ['b'] = 1, ['a'] = 1},
    ['colour'] = {['r'] = 0.35, ['g'] = 0.2, ['b'] = 0.85, ['a'] = 1},
    ['success-colour'] = {['r'] = 0.0, ['g'] = 0.75, ['b'] = 0.35, ['a'] = 1},
    ['failed-colour'] = {['r'] = 0.85, ['g'] = 0.1, ['b'] = 0.2, ['a'] = 1},
    ['format-noactive'] = 'No speed challenge active',
}

options.optionPageDefinitions[key] = {
    ['framename'] = 'DungeonSpeedrun',
    ['title'] = core.definedBars[key],
    ['description'] = 'Time left to improve your fastest run of a dungeon.',
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
                ['key'] = 'success-colour',
                ['type'] = 'colour',
                ['framename'] = 'ColourPicker-Success',
                ['text'] = 'Success colour',
            },
            {
                ['key'] = 'failed-colour',
                ['type'] = 'colour',
                ['framename'] = 'ColourPicker-Failed',
                ['text'] = 'Failed colour',
            },
            {
                ['key'] = 'format-noactive',
                ['type'] = 'reset-text',
                ['framename'] = 'FormatNoActive',
                ['label'] = 'Text when no speedrun in progress',
                ['resetValue'] = options.defaults[data.key .. '-format-noactive'],
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
local storage = ScootsProgressBar.storage
local core = ScootsProgressBar.core
local options = ScootsProgressBar.options
local frames = ScootsProgressBar.frames
local interface = ScootsProgressBar.interface
local utility = ScootsProgressBar.utility
local lookup = ScootsProgressBar.lookup

local key = 'dungeonchallenge'

--============--
----- CORE -----
--============--

core.definedBars[key] = 'Dungeon challenge'

core.barEvents[key] = {
    'ZONE_CHANGED_NEW_AREA',
    'PLAYER_ENTERING_WORLD',
    'UNIT_AURA',
    'PLAYER_AURAS_CHANGED',
}

core.updateFunctionMap[key] = function()
    utility.clearOldInstances()
    
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
end

core.tooltipLineFunctionMap[key] = function()
    local leftText = core.definedBars[key]
    local rightText
    
    if(core.values[key].currentValue ~= nil) then
        rightText = string.format(
            '%d / %d',
            core.values[key].currentValue,
            core.values[key].maxValue
        )
    else
        rightText = 'None active'
    end
    
    return leftText, rightText
end

--===========--
--- OPTIONS ---
--===========--

options.defaultCategories[key] = {
    ['enabled'] = false,
    ['order'] = 18,
    ['format'] = 'Dungeon challenge - {C} / {M}',
    ['background-colour'] = {['r'] = 1, ['g'] = 1, ['b'] = 1, ['a'] = 1},
    ['colour'] = {['r'] = 0.05, ['g'] = 0.25, ['b'] = 0.22, ['a'] = 1},
    ['format-noactive'] = 'No dungeon challenge active',
    ['format-failed'] = 'Challenge failed',
}

options.optionPageDefinitions[key] = {
    ['framename'] = 'ScootsProgressBar-Options-DungeonChallenge',
    ['description'] = 'Progress towards completing the current dungeon challenge.',
    ['callback'] = function(data)
        local fields = options.defineStandardOptions(data)
        
        for _, field in ipairs({
            {
                ['key'] = 'format-noactive',
                ['type'] = 'reset-text',
                ['framename'] = 'FormatNoActive',
                ['label'] = 'Text when no challenge in progress',
                ['resetValue'] = options.defaults['dungeonchallenge-format-noactive'],
                ['resetText'] = 'Apply default',
                ['width'] = 250,
            },
            {
                ['key'] = 'format-failed',
                ['type'] = 'reset-text',
                ['framename'] = 'FormatFailed',
                ['label'] = 'Text when challenge failed',
                ['resetValue'] = options.defaults['dungeonchallenge-format-failed'],
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
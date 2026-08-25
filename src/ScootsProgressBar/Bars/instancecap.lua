local storage = ScootsProgressBar.storage
local core = ScootsProgressBar.core
local options = ScootsProgressBar.options
local frames = ScootsProgressBar.frames
local interface = ScootsProgressBar.interface
local utility = ScootsProgressBar.utility
local lookup = ScootsProgressBar.lookup

local key = 'instancecap'

--============--
----- CORE -----
--============--

core.definedBars[key] = 'Instance cap'

core.barEvents[key] = {
    'ZONE_CHANGED_NEW_AREA',
    'PLAYER_ENTERING_WORLD',
}

core.updateFunctionMap[key] = function()
    core.delayUpdate(key, 1)
    
    utility.clearOldInstances()
    core.getActiveInstance(Custom_GetCurrentZone())
    
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
end

core.tooltipLineFunctionMap[key] = function()
    local leftText = 'Instances available'
    local rightText = string.format(
        '%d / %d',
        core.values[key].currentValue,
        core.values[key].maxValue
    )
    
    return leftText, rightText
end

--===========--
--- OPTIONS ---
--===========--

options.defaultCategories[key] = {
    ['enabled'] = false,
    ['order'] = 15,
    ['format'] = 'Instances available - {C} / {M}',
    ['background-colour'] = {['r'] = 1, ['g'] = 1, ['b'] = 1, ['a'] = 1},
    ['colour'] = {['r'] = 0.75, ['g'] = 0.65, ['b'] = 0.95, ['a'] = 1},
}

options.optionPageDefinitions[key] = {
    ['framename'] = 'InstanceCap',
    ['title'] = core.definedBars[key],
    ['description'] = 'How many instances you have available to enter.',
    ['callback'] = options.defineStandardOptions,
}
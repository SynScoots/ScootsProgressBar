local storage = ScootsProgressBar.storage
local core = ScootsProgressBar.core
local options = ScootsProgressBar.options
local frames = ScootsProgressBar.frames
local interface = ScootsProgressBar.interface
local utility = ScootsProgressBar.utility
local lookup = ScootsProgressBar.lookup

local key = 'questtoken'

--============--
----- CORE -----
--============--

core.definedBars[key] = 'Quest token'

core.barEvents[key] = {
    'QUEST_TURNED_IN',
}

core.updateFunctionMap[key] = function()
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
end

core.tooltipLineFunctionMap[key] = function()
    local leftText = core.definedBars[key]
    rightText = string.format(
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
    ['order'] = 11,
    ['format'] = 'Quest Auto-Complete Token - {C} / {M}',
    ['background-colour'] = {['r'] = 1, ['g'] = 1, ['b'] = 1, ['a'] = 1},
    ['colour'] = {['r'] = 0.9, ['g'] = 0.8, ['b'] = 0.5, ['a'] = 1},
}

options.optionPageDefinitions[key] = {
    ['framename'] = 'QuestToken',
    ['title'] = core.definedBars[key],
    ['description'] = 'Progress towards getting a Quest Auto-Complete Token. Requires Loremaster achievement.',
    ['callback'] = options.defineStandardOptions,
}
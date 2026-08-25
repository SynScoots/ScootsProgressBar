local storage = ScootsProgressBar.storage
local core = ScootsProgressBar.core
local options = ScootsProgressBar.options
local frames = ScootsProgressBar.frames
local interface = ScootsProgressBar.interface
local utility = ScootsProgressBar.utility
local lookup = ScootsProgressBar.lookup

local key = 'bagspace'

--============--
----- CORE -----
--============--

core.definedBars[key] = 'Free bag space'

core.barEvents[key] = {
    'BAG_UPDATE',
}

core.updateFunctionMap[key] = function()
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
end

core.tooltipLineFunctionMap[key] = function()
    local leftText = core.definedBars[key]
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
    ['order'] = 16,
    ['format'] = 'Free bag space - {C} / {M}',
    ['background-colour'] = {['r'] = 1, ['g'] = 1, ['b'] = 1, ['a'] = 1},
    ['colour'] = {['r'] = 0.55, ['g'] = 0.38, ['b'] = 0.18, ['a'] = 1},
}

options.optionPageDefinitions[key] = {
    ['framename'] = 'BagSpace',
    ['title'] = core.definedBars[key],
    ['description'] = 'How many bag slots you have remaining.',
    ['callback'] = options.defineStandardOptions,
}
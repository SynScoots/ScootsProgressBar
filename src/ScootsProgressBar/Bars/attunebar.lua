local storage = ScootsProgressBar.storage
local core = ScootsProgressBar.core
local options = ScootsProgressBar.options
local frames = ScootsProgressBar.frames
local interface = ScootsProgressBar.interface
local utility = ScootsProgressBar.utility
local lookup = ScootsProgressBar.lookup

local key = 'attunebar'

--============--
----- CORE -----
--============--

core.definedBars[key] = 'Attune bar'

core.barEvents[key] = {
    'SYNASTRIA_ITEM_ATTUNE_PCT_CHANGED',
    'SYNASTRIA_ATTUNE_BAR_CHANGED',
}

core.updateFunctionMap[key] = function()
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
end

core.textFormatFunctionMap[key] = function(text)
    if(core.values[key].itemCount) then
        text = text:gsub('{C}', string.format('%d', core.values[key].itemCount))
        text = text:gsub('{S}', (core.values[key].itemCount == 1) and '' or 's')
        text = text:gsub('{ES}', (core.values[key].itemCount == 1) and '' or 'es')
    end
    
    return text
end

core.tooltipLineFunctionMap[key] = function()
    local leftText = core.definedBars[key]
    local rightText
            
    if(core.values[key].itemCount == 0) then
        rightText = 'Not attuning any items'
    else
        rightText = string.format(
            'Attuning %d item%s (' .. lookup.percentFormat .. '%%)',
            core.values[key].itemCount,
            core.values[key].itemCount ~= 1 and 's' or '',
            core.values[key].percent
        )
    end
    
    return leftText, rightText
end

--===========--
--- OPTIONS ---
--===========--

options.defaultCategories[key] = {
    ['enabled'] = false,
    ['order'] = 5,
    ['format'] = 'Attuning {C} item{S} - {P}% (Attune bar)',
    ['background-colour'] = {['r'] = 1, ['g'] = 1, ['b'] = 1, ['a'] = 1},
    ['colour'] = {['r'] = 0.55, ['g'] = 0.3, ['b'] = 0.1, ['a'] = 1},
    ['format-nounlock'] = 'You have not yet unlocked the Attune Bar',
    ['format-noitems'] = 'Not attuning any items on the Attune Bar',
}

options.optionPageDefinitions[key] = {
    ['framename'] = 'ScootsProgressBar-Options-AttuneBar',
    ['description'] = 'Progress towards attuning items in the Attune Bar.',
    ['callback'] = function(data)
        local fields = options.defineStandardOptions(data, {
            ['formatHint'] = {
                {'{C}', 'Item count'},
                {'{P}', 'Percent progress'},
                {'{S}', 's (plural)'},
                {'{ES}', 'es (plural)'},
            }
        })
        
        for _, field in ipairs({
            {
                ['key'] = 'format-nounlock',
                ['type'] = 'reset-text',
                ['framename'] = 'FormatNoUnlocked',
                ['label'] = 'Text when bar not unlocked',
                ['resetValue'] = options.defaults['attunebar-format-nounlock'],
                ['resetText'] = 'Apply default',
                ['width'] = 250,
            },
            {
                ['key'] = 'format-noitems',
                ['type'] = 'reset-text',
                ['framename'] = 'FormatNoItems',
                ['label'] = 'Text when no items',
                ['resetValue'] = options.defaults['attunebar-format-noitems'],
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
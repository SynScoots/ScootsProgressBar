local storage = ScootsProgressBar.storage
local core = ScootsProgressBar.core
local options = ScootsProgressBar.options
local frames = ScootsProgressBar.frames
local interface = ScootsProgressBar.interface
local utility = ScootsProgressBar.utility
local lookup = ScootsProgressBar.lookup

local key = 'equipattune'

lookup.equipAttuneBagMap = {
    {0xff, {0, 17}},
}

--============--
----- CORE -----
--============--

core.definedBars[key] = 'Equipped items'

core.barEvents[key] = {
    'SYNASTRIA_ITEM_ATTUNE_PCT_CHANGED',
    'SYNASTRIA_ATTUNE_BAR_CHANGED',
    'PLAYER_EQUIPMENT_CHANGED',
    'UNIT_INVENTORY_CHANGED',
}

core.updateFunctionMap[key] = function()
    local newFormat = options.get('equipattune-format')
    local changed = utility.setValuesForAttuneExp(lookup.equipAttuneBagMap, key)
    
    if(core.values[key].itemCount == 0) then
        newFormat = options.get('equipattune-format-noitems')
    end
    
    if(core.values[key].textFormat ~= newFormat) then
        core.values[key].textFormat = newFormat
        changed = true
    end
    
    return changed
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
    ['enabled'] = true,
    ['order'] = 3,
    ['format'] = 'Attuning {C} item{S} - {P}% (Equipped)',
    ['background-colour'] = {['r'] = 1, ['g'] = 1, ['b'] = 1, ['a'] = 1},
    ['colour'] = {['r'] = 0, ['g'] = 0.55, ['b'] = 0.6, ['a'] = 1},
    ['format-noitems'] = 'Not attuning any equipped items',
}

options.optionPageDefinitions[key] = {
    ['framename'] = 'ScootsProgressBar-Options-EquipAttune',
    ['description'] = 'Progress towards attuning all equipped items.',
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
                ['key'] = 'format-noitems',
                ['type'] = 'reset-text',
                ['framename'] = 'FormatNoItems',
                ['label'] = 'Text when no items',
                ['resetValue'] = options.defaults['equipattune-format-noitems'],
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
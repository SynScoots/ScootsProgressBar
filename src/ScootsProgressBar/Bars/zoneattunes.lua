local storage = ScootsProgressBar.storage
local core = ScootsProgressBar.core
local options = ScootsProgressBar.options
local frames = ScootsProgressBar.frames
local interface = ScootsProgressBar.interface
local utility = ScootsProgressBar.utility
local lookup = ScootsProgressBar.lookup

local key = 'zoneattunes'

--============--
----- CORE -----
--============--

core.definedBars[key] = 'Zone attunes'

core.barEvents[key] = {
    'SYNASTRIA_ITEM_ATTUNED',
    'ZONE_CHANGED_NEW_AREA',
    'PLAYER_ENTERING_WORLD',
}

core.updateFunctionMap[key] = function()
    local attunedCount = 0
    local itemCount = 0
    local currentZoneId = Custom_GetCurrentZoneOur()
    local currentZoneName = Custom_GetZoneName(currentZoneId)
    
    for _, itemId in ipairs(ItemLocGetAllItemsInZone(-1, 0, 0, 1, 1)) do
        local canAttune = false
        
        if(options.get('zoneattunes-char-or-acc') == 'char') then
            if(CanAttuneItemHelper(itemId) > 0) then
                canAttune = true
            end
        else
            if((IsAttunableBySomeone(itemId) or 0) ~= 0) then
                canAttune = true
            end
        end
    
        if(canAttune) then
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
    
    if(core.values[key].zoneId == nil or core.values[key].zoneId ~= currentZoneId) then
        core.values[key].zoneId = currentZoneId
        changed = true
    end
    
    if(itemCount == 0) then
        local newFormat = options.get('zoneattunes-format-noitems')
        
        if(core.values[key].textFormat ~= newFormat) then
            changed = true
        end
        
        core.values[key].textFormat = newFormat
    end
    
    return changed
end

core.textFormatFunctionMap[key] = function(text)
    if(core.values[key].itemCount) then
        text = text:gsub('{Z}', Custom_GetZoneName(Custom_GetCurrentZoneOur()))
        text = text:gsub('{S}', (core.values[key].itemCount == 1) and '' or 's')
        text = text:gsub('{ES}', (core.values[key].itemCount == 1) and '' or 'es')
    end
    
    return text
end

--===========--
--- OPTIONS ---
--===========--

options.defaultCategories[key] = {
    ['enabled'] = true,
    ['order'] = 9,
    ['format'] = 'Zone Attunes - {C} / {M} ({P}%)',
    ['background-colour'] = {['r'] = 1, ['g'] = 1, ['b'] = 1, ['a'] = 1},
    ['colour'] = {['r'] = 0.4, ['g'] = 0.95, ['b'] = 0.8, ['a'] = 1},
    ['min-chance'] = 0.001,
    ['char-or-acc'] = 'char',
    ['format-noitems'] = 'No attuneable items in {Z}',
}

options.optionPageDefinitions[key] = {
    ['framename'] = 'ZoneAttunes',
    ['title'] = core.definedBars[key],
    ['description'] = 'Progress towards attuning all items sourced from the current zone.',
    ['callback'] = function(data)
        local fields = options.defineStandardOptions(data, {
            ['formatHint'] = {
                {'{C}', 'Current amount'},
                {'{M}', 'Max amount'},
                {'{P}', 'Percent progress'},
                {'{Z}', 'Current zone'},
                {'{S}', 's (plural)'},
                {'{ES}', 'es (plural)'},
            }
        })
        
        for _, field in ipairs({
            {
                ['key'] = 'min-chance',
                ['framename'] = 'MinChance',
                ['type'] = 'range-slider',
                ['label'] = 'Minimum drop chance %',
                ['increment'] = 0.001,
                ['min'] = 0,
                ['max'] = 100,
            },
            {
                ['key'] = 'char-or-acc',
                ['type'] = 'dropdown',
                ['framename'] = 'CharOrAcc',
                ['label'] = 'Include',
                ['choices'] = {
                    {
                        ['name'] = 'Current character attunes only',
                        ['value'] = 'char',
                    },
                    {
                        ['name'] = 'Whole account attunes',
                        ['value'] = 'acc',
                    },
                },
            },
            {
                ['key'] = 'format-noitems',
                ['type'] = 'reset-text',
                ['framename'] = 'FormatNoItems',
                ['tooltip'] = 'Text format',
                ['tooltipExtra'] = {
                    {'{Z}', 'Current zone'},
                },
                ['label'] = 'Text when no attuneable items',
                ['resetValue'] = options.defaults['zoneattunes-format-noitems'],
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
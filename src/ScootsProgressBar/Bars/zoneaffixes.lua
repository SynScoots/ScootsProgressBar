local storage = ScootsProgressBar.storage
local core = ScootsProgressBar.core
local options = ScootsProgressBar.options
local frames = ScootsProgressBar.frames
local interface = ScootsProgressBar.interface
local utility = ScootsProgressBar.utility
local lookup = ScootsProgressBar.lookup

local key = 'zoneaffixes'

--============--
----- CORE -----
--============--

core.definedBars[key] = 'Zone affixes'

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
        
        if(options.get('zoneaffixes-char-or-acc') == 'char') then
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
            
            for itemIndex = 1, sourceCount do
                local _, _, _, chance, _, _, zoneName = ItemLocGetSourceAt(itemId, itemIndex)
                
                if(chance < options.get('zoneaffixes-min-chance')) then
                    break
                end
                
                if(zoneName == currentZoneName) then
                    local _, tags2 = GetItemTagsCustom(itemId)
                    
                    if(tags2 and bit.band(tags2, 0x10) ~= 0) then
                        local poss1, poss2, done1, done2 = GetItemAffixMask(itemId)
                        
                        if(poss1 and (poss1 ~= 0 or poss2 ~= 0)) then
                            for affixIndex = 1, 32 do
                                local mask = bit.lshift(1, affixIndex - 1)
                                
                                if(bit.band(mask, poss1) ~= 0 or bit.band(mask, poss2) ~= 0) then
                                    itemCount = itemCount + 1
                                    
                                    if(bit.band(mask, done1) ~= 0 or bit.band(mask, done2) ~= 0) then
                                        attunedCount = attunedCount + 1
                                    end
                                end
                            end
                        end
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
        local newFormat = options.get('zoneaffixes-format-noitems')
        
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
    ['order'] = 10,
    ['format'] = 'Zone Affixes - {C} / {M} ({P}%)',
    ['background-colour'] = {['r'] = 1, ['g'] = 1, ['b'] = 1, ['a'] = 1},
    ['colour'] = {['r'] = 0.15, ['g'] = 0.05, ['b'] = 0.75, ['a'] = 1},
    ['min-chance'] = 0.001,
    ['char-or-acc'] = 'char',
    ['format-noitems'] = 'No attuneable affixed items in {Z}',
}

options.optionPageDefinitions[key] = {
    ['framename'] = 'ZoneAffixes',
    ['title'] = core.definedBars[key],
    ['description'] = 'Progress towards attuning all item affixes sourced from the current zone.',
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
                ['resetValue'] = options.defaults['zoneaffixes-format-noitems'],
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
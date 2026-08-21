local storage = ScootsProgressBar.storage
local core = ScootsProgressBar.core
local options = ScootsProgressBar.options
local frames = ScootsProgressBar.frames
local interface = ScootsProgressBar.interface
local utility = ScootsProgressBar.utility
local lookup = ScootsProgressBar.lookup

local key = 'currency'

--============--
----- CORE -----
--============--

core.definedBars[key] = 'Currency'

core.barEvents[key] = {
    'PLAYER_MONEY',
    'CURRENCY_DISPLAY_UPDATE',
    'CHAT_MSG_COMBAT_HONOR_GAIN',
}

core.updateFunctionMap[key] = function()
    local newFormat = options.get('currency-format')
    local newItem = options.get('currency-id')
    local newValue, newName

    if(newItem ~= nil) then
        if(newItem == '_GOLD') then
            newValue = math.floor(GetMoney() / 10000)
            newName = GOLD_AMOUNT:gsub('%s*%%d%s*', '')
        else
            for currencyIndex = 1, GetCurrencyListSize() do
                local _, _, _, _, _, currencyQuantity, _, _, currencyItemId = GetCurrencyListInfo(currencyIndex)
                
                if(currencyItemId == newItem) then
                    newValue = currencyQuantity
                    newName = GetItemInfoCustom(newItem)
                    break
                end
            end
        end
    end

    if(newItem == nil or newValue == nil) then
        newFormat = options.get('currency-format-noselected')

        if(core.values[key] == nil) then
            core.values[key] = {
                ['textFormat'] = newFormat,
                ['percent'] = 0,
            }
            
            return true
        elseif(core.values[key].itemId ~= nil) then
            core.values[key].textFormat = newFormat
            core.values[key].itemId = nil
            core.values[key].percent = 0
            
            return true
        end
    else
        local newMax = options.get('currency-target')
        local newPercent = math.min(100, (newValue / newMax) * 100)
        local optionsString = string.format('%d-%d', newItem, newMax)

        if(core.values[key] == nil) then
            core.values[key] = {
                ['textFormat'] = newFormat,
                ['itemId'] = newItem,
                ['name'] = newName,
                ['maxValue'] = newMax,
                ['currentValue'] = newValue,
                ['percent'] = newPercent,
                ['optionsString'] = optionsString
            }
            
            return true
        elseif(core.values[key].itemId ~= newItem or core.values[key].currentValue ~= newValue or core.values[key].maxValue ~= newMax) then
            if(core.values[key].itemId ~= nil and newValue >= newMax and core.values[key].currentValue < core.values[key].maxValue and core.values[key].optionsString == optionsString) then
                local message = string.format('You have collected %d × %s!', newMax, (select(2, GetItemInfoCustom(newItem))))
            
                if(options.get('currency-toast-on-reach-target')) then
                    utility.displayToast(message)
                end
                
                if(options.get('currency-chat-on-reach-target')) then
                    utility.displayChatMessage(message)
                end
            end
            
            core.values[key].textFormat = newFormat
            core.values[key].itemId = newItem
            core.values[key].name = newName
            core.values[key].maxValue = newMax
            core.values[key].currentValue = newValue
            core.values[key].percent = newPercent
            core.values[key].optionsString = optionsString
            
            return true
        end
    end

    return false
end

core.textFormatFunctionMap[key] = function(text)
    if(core.values[key].itemId ~= nil) then
        text = text:gsub('{N}', core.values[key].name)
    end
    
    return text
end

core.tooltipLineFunctionMap[key] = function()
    local leftText = core.definedBars[key]
    local rightText
    
    if(core.values[key].itemId ~= nil) then
        rightText = string.format(
            '%d / %d (' .. lookup.percentFormat .. '%%)',
            core.values[key].currentValue,
            core.values[key].maxValue,
            core.values[key].percent
        )
    else
        rightText = 'None selected'
    end
    
    return leftText, rightText
end

--===========--
--- OPTIONS ---
--===========--

options.defaultCategories[key] = {
    ['enabled'] = false,
    ['order'] = 12,
    ['format'] = '{N} - {C} / {M} ({P}%)',
    ['background-colour'] = {['r'] = 1, ['g'] = 1, ['b'] = 1, ['a'] = 1},
    ['colour'] = {['r'] = 0.55, ['g'] = 0, ['b'] = 0.15, ['a'] = 1},
    ['id'] = lookup.NONE_VAL,
    ['target'] = 100,
    ['toast-on-reach-target'] = false,
    ['chat-on-reach-target'] = false,
    ['format-noselected'] = 'No currency selected',
}

options.optionPageDefinitions[key] = {
    ['framename'] = 'ScootsProgressBar-Options-Currency',
    ['description'] = 'Progress towards getting a certain quantity of a currency.',
    ['callback'] = function(data)
        local fields = options.defineStandardOptions(data, {
            ['formatHint'] = {
                {'{N}', 'Currency name'},
                {'{C}', 'Current amount'},
                {'{M}', 'Max amount'},
                {'{P}', 'Percent progress'},
                {'{ES}', 'es (plural)'},
            },
        })
        
        for _, field in ipairs({
            {
                ['key'] = 'target',
                ['type'] = 'increment-text',
                ['framename'] = 'TargetQuantity',
                ['label'] = 'Target quantity',
                ['increment'] = 1,
                ['min'] = 1,
                ['width'] = 70,
            },
            {
                ['key'] = 'id',
                ['type'] = 'currency-picker',
                ['framename'] = 'CurrencySelect',
                ['label'] = 'Select currency',
            },
            {
                ['key'] = 'toast-on-reach-target',
                ['type'] = 'checkbox',
                ['framename'] = 'ToastOnGoal',
                ['label'] = 'Toast on reaching target',
                ['tooltip'] = 'Displays a message in the centre of the screen when you reach your target quantity.',
            },
            {
                ['key'] = 'chat-on-reach-target',
                ['type'] = 'checkbox',
                ['framename'] = 'ChatOnGoal',
                ['label'] = 'Chat message on reaching target',
                ['tooltip'] = 'Displays a message in the chat when you reach your target quantity.',
            },
            {
                ['key'] = 'format-noselected',
                ['type'] = 'reset-text',
                ['framename'] = 'FormatNoSelected',
                ['label'] = 'Text when no selected currency',
                ['resetValue'] = options.defaults['format-noselected'],
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
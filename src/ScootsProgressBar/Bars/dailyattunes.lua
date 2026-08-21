local storage = ScootsProgressBar.storage
local core = ScootsProgressBar.core
local options = ScootsProgressBar.options
local frames = ScootsProgressBar.frames
local interface = ScootsProgressBar.interface
local utility = ScootsProgressBar.utility
local lookup = ScootsProgressBar.lookup

local key = 'dailyattunes'

--============--
----- CORE -----
--============--

core.definedBars[key] = 'Daily attunes'

core.barEvents[key] = {
    'SYNASTRIA_ITEM_ATTUNED',
}

core.updateFunctionMap[key] = function()
    local newFormat = options.get('dailyattunes-format')
    local newMax = options.get('dailyattunes-target')
    
    local start, now, optionsString
    
    if(options.get('dailyattunes-char-or-acc') == 'char') then
        if(options.get('dailyattunes-count-affixes')) then
            start = storage.dayStartAttunes.character[core.player.guid].incAffixes.base
            now = CalculateAttunedCount(3)
            optionsString = 'c+a:%d'
        else
            start = storage.dayStartAttunes.character[core.player.guid].exAffixes.base
            now = CalculateAttunedCount(1)
            optionsString = 'c-a:%d'
        end
    else
        if(options.get('dailyattunes-count-affixes')) then
            start = storage.dayStartAttunes.account.incAffixes.base
            now = CalculateAttunedCount(2)
            optionsString = 'a+a:%d'
        else
            start = storage.dayStartAttunes.account.exAffixes.base
            now = CalculateAttunedCount()
            optionsString = 'a-a:%d'
        end
    end
    
    local newValue = now - start
    local newPercent = math.min(100, (newValue / newMax) * 100)
    optionsString = string.format(optionsString, newMax)
    
    if(core.values[key] == nil) then
        core.values[key] = {
            ['textFormat'] = newFormat,
            ['maxValue'] = newMax,
            ['currentValue'] = newValue,
            ['percent'] = newPercent,
            ['optionsString'] = optionsString,
        }
        
        return true
    elseif(core.values[key].textFormat ~= newFormat or core.values[key].maxValue ~= newMax or core.values[key].currentValue ~= newValue) then
        if(newValue >= newMax and core.values[key].currentValue < core.values[key].maxValue and core.values[key].optionsString == optionsString) then
            local message = string.format('You have attuned %d new items today!', newMax)
        
            if(options.get('dailyattunes-toast-on-reach-target')) then
                utility.displayToast(message)
            end
            
            if(options.get('dailyattunes-chat-on-reach-target')) then
                utility.displayChatMessage(message)
            end
        end
        
        core.values[key].textFormat = newFormat
        core.values[key].maxValue = newMax
        core.values[key].currentValue = newValue
        core.values[key].percent = newPercent
        core.values[key].optionsString = optionsString
        
        return true
    end
    
    return false
end

--===========--
--- OPTIONS ---
--===========--

options.defaultCategories[key] = {
    ['enabled'] = false,
    ['order'] = 14,
    ['format'] = 'Daily attunes - {C} / {M} ({P}%)',
    ['background-colour'] = {['r'] = 1, ['g'] = 1, ['b'] = 1, ['a'] = 1},
    ['colour'] = {['r'] = 0.05, ['g'] = 0.10, ['b'] = 0.20, ['a'] = 1},
    ['target'] = 100,
    ['toast-on-reach-target'] = false,
    ['chat-on-reach-target'] = false,
    ['char-or-acc'] = 'char',
    ['count-affixes'] = true,
}

options.optionPageDefinitions[key] = {
    ['framename'] = 'ScootsProgressBar-Options-DailyAttunes',
    ['description'] = 'Progress towards a daily goal of attunes.',
    ['callback'] = function(data)
        local fields = options.defineStandardOptions(data)
        
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
                ['key'] = 'count-affixes',
                ['type'] = 'checkbox',
                ['framename'] = 'CountAffixes',
                ['label'] = 'Include extra affixes for already-attuned items',
            },
        }) do
            field.key = string.format('%s-%s', key, field.key)
            field.framename = string.format('%s-%s', data.framename, field.framename)
            table.insert(fields, field)
        end
    
        return fields
    end,
}
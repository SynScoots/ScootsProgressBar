local storage = ScootsProgressBar.storage
local core = ScootsProgressBar.core
local options = ScootsProgressBar.options
local frames = ScootsProgressBar.frames
local interface = ScootsProgressBar.interface
local utility = ScootsProgressBar.utility
local lookup = ScootsProgressBar.lookup

local key = 'reputation'

lookup.reputationStandingMap = {
    [1] = 'hated',
    [2] = 'hostile',
    [3] = 'unfriendly',
    [4] = 'neutral',
    [5] = 'friendly',
    [6] = 'honoured',
    [7] = 'revered',
    [8] = 'exalted',
}

--============--
----- CORE -----
--============--

core.definedBars[key] = 'Reputation'

core.barEvents[key] = {
    'UPDATE_FACTION',
}

core.updateFunctionMap[key] = function()
    local newFormat = options.get('reputation-format')
    local newName, newStanding, newMin, newMax, newValue = GetWatchedFactionInfo()
    
    if(newName == nil) then
        if(options.get('reputation-follow-tracked')) then
            options.set('reputation-enabled', false, true)
            core.prepareUpdate('reputation', 'reputation-enabled', false)
            
            return false
        end
    
        if(core.values[key] == nil) then
            core.values[key] = {
                ['textFormat'] = 'No tracked reputation',
                ['percent'] = 0
            }
            
            return true
        elseif(core.values[key].name ~= nil) then
            core.values[key].textFormat = 'No tracked reputation'
            core.values[key].percent = 0
            core.values[key].name = nil
            
            return true
        end
        
        return false
    else
        newMax = newMax - newMin
        newValue = newValue - newMin
        
        if(core.values[key] == nil) then
            core.values[key] = {
                ['textFormat'] = newFormat,
                ['name'] = newName,
                ['maxValue'] = newMax,
                ['currentValue'] = newValue,
                ['percent'] = (newValue / newMax) * 100,
                ['standingId'] = newStanding,
            }
            
            return true
        elseif(core.values[key].textFormat ~= newFormat or core.values[key].maxValue ~= newMax or core.values[key].currentValue ~= newValue or core.values[key].standingId ~= newStanding) then
            core.values[key].textFormat = newFormat
            core.values[key].name = newName
            core.values[key].maxValue = newMax
            core.values[key].currentValue = newValue
            core.values[key].percent = (newValue / newMax) * 100
            core.values[key].standingId = newStanding
            
            return true
        end
    end
    
    return false
end

core.textFormatFunctionMap[key] = function(text)
    if(core.values[key].name ~= nil) then
        text = text:gsub('{N}', core.values[key].name)
        text = text:gsub('{L}', _G['FACTION_STANDING_LABEL' .. tostring(core.values[key].standingId)])
    end
    
    return text
end

core.tooltipLineFunctionMap[key] = function()
    local leftText, rightText

    if(core.values[key].name ~= nil) then
        leftText = core.values[key].name
        rightText = string.format(
            '%s - %d / %d (' .. lookup.percentFormat .. '%%)',
            _G['FACTION_STANDING_LABEL' .. tostring(core.values[key].standingId)],
            core.values[key].currentValue,
            core.values[key].maxValue,
            core.values[key].percent
        )
    else
        leftText = core.definedBars[key]
        rightText = 'None selected'
    end
    
    return leftText, rightText
end

--===========--
-- INTERFACE --
--===========--

interface.applyColoursFunctionMap[key] = function(bar)
    local bgColour = options.get('reputation-background-colour')
    
    if(core.values[key].name ~= nil) then
        local colour = options.get(string.format('%s-%s-colour', key, lookup.reputationStandingMap[core.values[key].standingId]))
        bar.progress:SetVertexColor(colour.r, colour.g, colour.b, colour.a)
    end
    
    bar.background:SetVertexColor(bgColour.r, bgColour.g, bgColour.b, bgColour.a)
end

interface.postCreationPositionTexturesFunctionMap[key] = function(bar)
    if(core.values[key] == nil or (core.values[key].standingId or 4) > 3) then
        bar.background:SetPoint('TOPRIGHT', bar, 'TOPRIGHT', fromRight, fromTop)
        bar.background:SetPoint('BOTTOMRIGHT', bar, 'BOTTOMRIGHT', fromRight, fromBottom)
        
        bar.progress:SetPoint('TOPLEFT', bar, 'TOPLEFT', fromLeft, fromTop)
        bar.progress:SetPoint('BOTTOMLEFT', bar, 'BOTTOMLEFT', fromLeft, fromBottom)
    else
        bar.background:SetPoint('TOPLEFT', bar, 'TOPLEFT', fromLeft, fromTop)
        bar.background:SetPoint('BOTTOMLEFT', bar, 'BOTTOMLEFT', fromLeft, fromBottom)
        
        bar.progress:SetPoint('TOPRIGHT', bar, 'TOPRIGHT', fromRight, fromTop)
        bar.progress:SetPoint('BOTTOMRIGHT', bar, 'BOTTOMRIGHT', fromRight, fromBottom)
    end
end

interface.postUpdatePositionTexturesFunctionMap[key] = function(bar)
    if(core.values[key].standingId ~= nil) then
        interface.postCreationPositionTexturesFunctionMap[key](bar)
    end
end

--===========--
--- OPTIONS ---
--===========--

options.defaultCategories[key] = {
    ['enabled'] = true,
    ['order'] = 2,
    ['format'] = '{N} - {C} / {M} ({P}%) - {L}',
    ['background-colour'] = {['r'] = 1, ['g'] = 1, ['b'] = 1, ['a'] = 1},
    ['exalted-colour'] = {['r'] = 0, ['g'] = 0.6, ['b'] = 0.1, ['a'] = 1},
    ['revered-colour'] = {['r'] = 0, ['g'] = 0.6, ['b'] = 0.1, ['a'] = 1},
    ['honoured-colour'] = {['r'] = 0, ['g'] = 0.6, ['b'] = 0.1, ['a'] = 1},
    ['friendly-colour'] = {['r'] = 0, ['g'] = 0.6, ['b'] = 0.1, ['a'] = 1},
    ['neutral-colour'] = {['r'] = 0.9, ['g'] = 0.7, ['b'] = 0, ['a'] = 1},
    ['unfriendly-colour'] = {['r'] = 0.75, ['g'] = 0.27, ['b'] = 0, ['a'] = 1},
    ['hostile-colour'] = {['r'] = 0.8, ['g'] = 0.3, ['b'] = 0.22, ['a'] = 1},
    ['hated-colour'] = {['r'] = 0.8, ['g'] = 0.3, ['b'] = 0.22, ['a'] = 1},
    ['follow-tracked'] = false,
}

options.optionPageDefinitions[key] = {
    ['framename'] = 'Reputation',
    ['title'] = core.definedBars[key],
    ['description'] = 'Progress towards the next reputational standing with your tracked faction.',
    ['callback'] = function(data)
        local fields = options.defineStandardOptions(data, {
            ['excludeMainColour'] = true,
            ['formatHint'] = {
                {'{N}', 'Faction name'},
                {'{C}', 'Current amount'},
                {'{M}', 'Max amount'},
                {'{P}', 'Percent progress'},
                {'{L}', 'Current standing'},
            }
        })
        
        for _, field in ipairs({
            {
                ['key'] = 'exalted-colour',
                ['type'] = 'colour',
                ['framename'] = 'ColourPicker-Exalted',
                ['text'] = 'Exalted colour',
            },
            {
                ['key'] = 'revered-colour',
                ['type'] = 'colour',
                ['framename'] = 'ColourPicker-Revered',
                ['text'] = 'Revered colour',
            },
            {
                ['key'] = 'honoured-colour',
                ['type'] = 'colour',
                ['framename'] = 'ColourPicker-Honoured',
                ['text'] = 'Honoured colour',
            },
            {
                ['key'] = 'friendly-colour',
                ['type'] = 'colour',
                ['framename'] = 'ColourPicker-Friendly',
                ['text'] = 'Friendly colour',
            },
            {
                ['key'] = 'neutral-colour',
                ['type'] = 'colour',
                ['framename'] = 'ColourPicker-Neutral',
                ['text'] = 'Neutral colour',
            },
            {
                ['key'] = 'unfriendly-colour',
                ['type'] = 'colour',
                ['framename'] = 'ColourPicker-Unfriendly',
                ['text'] = 'Unfriendly colour',
            },
            {
                ['key'] = 'hostile-colour',
                ['type'] = 'colour',
                ['framename'] = 'ColourPicker-Hostile',
                ['text'] = 'Hostile colour',
            },
            {
                ['key'] = 'hated-colour',
                ['type'] = 'colour',
                ['framename'] = 'ColourPicker-Hated',
                ['text'] = 'Hated colour',
            },
            {
                ['key'] = 'follow-tracked',
                ['type'] = 'checkbox',
                ['framename'] = 'FollowTracked',
                ['label'] = 'Follow tracked reputation state',
                ['tooltip'] = 'When checked, this bar will automatically enable / disable itself when you track / untrack a reputation.',
            },
        }) do
            field.key = string.format('%s-%s', key, field.key)
            field.framename = string.format('%s-%s', data.framename, field.framename)
            table.insert(fields, field)
        end
    
        return fields
    end,
}
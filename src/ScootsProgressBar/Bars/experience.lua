local storage = ScootsProgressBar.storage
local core = ScootsProgressBar.core
local options = ScootsProgressBar.options
local frames = ScootsProgressBar.frames
local interface = ScootsProgressBar.interface
local utility = ScootsProgressBar.utility
local lookup = ScootsProgressBar.lookup

local key = 'experience'

--============--
----- CORE -----
--============--

core.definedBars[key] = 'Experience'

core.barEvents[key] = {
    'PLAYER_LEVEL_UP',
    'PLAYER_XP_UPDATE',
}

core.updateFunctionMap[key] = function()
    local newFormat = options.get('experience-format')
    local newLevel = UnitLevel('player')
    local newMax = UnitXPMax('player')
    local newValue = UnitXP('player')
    local newRested = GetXPExhaustion()
    
    if(newLevel == 80) then
        local newFormat = options.get('experience-format-maxlevel')
    
        if(core.values[key] == nil) then
            core.values[key] = {
                ['textFormat'] = newFormat,
                ['level'] = newLevel,
                ['percent'] = 0,
                ['restedPercent'] = 0
            }
            
            return true
        elseif(core.values[key].level ~= newLevel) then
            options.set('experience-enabled', false, true)
            core.prepareUpdate(key, 'experience-enabled', false)
        
            core.values[key].textFormat = newFormat
            core.values[key].level = newLevel
            core.values[key].percent = 0
            core.values[key].restedPercent = 0
            
            return true
        end
        
        return false
    else
        if(core.values[key] == nil) then
            core.values[key] = {
                ['textFormat'] = newFormat,
                ['level'] = newLevel,
                ['maxValue'] = newMax,
                ['currentValue'] = newValue,
                ['percent'] = (newValue / newMax) * 100,
                ['rested'] = newRested,
                ['restedPercent'] = (((newRested or 0) > 0) and ((newRested / newMax) * 100)) or 0,
            }
            
            return true
        elseif(core.values[key].textFormat ~= newFormat or core.values[key].level ~= newLevel or core.values[key].maxValue ~= newMax or core.values[key].currentValue ~= newValue or core.values[key].rested ~= newRested) then
            core.values[key].textFormat = newFormat
            core.values[key].level = newLevel
            core.values[key].maxValue = newMax
            core.values[key].currentValue = newValue
            core.values[key].percent = (newValue / newMax) * 100
            core.values[key].rested = newRested
            core.values[key].restedPercent = (((newRested or 0) > 0) and ((newRested / newMax) * 100)) or 0
            
            return true
        end
    end
    
    return false
end

core.textFormatFunctionMap[key] = function(text)
    if(core.values[key].level < 80) then
        text = text:gsub('{L}', string.format('%d', core.values[key].level))
        
        if((core.values[key].rested or 0) == 0) then
            text = text:gsub('{R[CP]}', '')
            text = text:gsub('{R:.-}', '')
        else
            text = text:gsub('{RC}', string.format('%d', core.values[key].rested))
            text = text:gsub('{RP}', string.format(lookup.percentFormat, core.values[key].restedPercent))
            text = text:gsub('{R:(.-)}', '%1')
        end
    end
    
    return text
end

core.tooltipLineFunctionMap[key] = function()
    local leftText = core.definedBars[key]
    local rightText
    
    if(UnitLevel('player') == 80) then
        rightText = 'At max level'
    else
        rightText = string.format(
            '%d / %d (' .. lookup.percentFormat .. '%%)',
            core.values[key].currentValue,
            core.values[key].maxValue,
            core.values[key].percent
        )
        
        if((core.values[key].rested or 0) > 0) then
            rightText = rightText .. string.format(' (' .. lookup.percentFormat .. '%% rested)', core.values[key].percent)
        end
    end
    
    return leftText, rightText
end

--===========--
-- INTERFACE --
--===========--

interface.applyColoursFunctionMap[key] = function(bar)
    local colour
    local bgColour = options.get('experience-background-colour')
    local pendingColour = options.get('experience-pendingrested-colour')
    
    if((core.values[key].rested or 0) == 0) then
        colour = options.get('experience-colour')
    else
        colour = options.get('experience-rested-colour')
    end
    
    bar.progress:SetVertexColor(colour.r, colour.g, colour.b, colour.a)
    bar.background:SetVertexColor(bgColour.r, bgColour.g, bgColour.b, bgColour.a)
    bar.pending:SetVertexColor(pendingColour.r, pendingColour.g, pendingColour.b, pendingColour.a)
end

interface.barSizeAdjustmentFunctionMap[key] = function(width, progressPercent, progressWidth, backgroundWidth)
    if(core.values[key].restedPercent > 0) then
        local pendingWidth
        
        if((progressPercent + core.values[key].restedPercent) < 100) then
            pendingWidth = width * ((core.values[key].restedPercent or 0) / 100)
            backgroundWidth = width * (1 - (((progressPercent or 0) + (core.values[key].restedPercent or 0)) / 100))
        else
            pendingWidth = width * (1 - ((progressPercent or 0) / 100))
            backgroundWidth = 0
        end
        
        if(pendingWidth > 0) then
            frames.bars[key].pending:Show()
            frames.bars[key].pending:SetWidth(pendingWidth)
        else
            frames.bars[key].pending:Hide()
        end
    end
    
    return progressWidth, backgroundWidth
end

interface.alterBarCreationFunctionMap[key] = function(bar)
    bar.pending = bar:CreateTexture(nil, 'BACKGROUND')
    bar.pending:SetTexture(barTexture, true)
    bar.pending:SetHorizTile(true)
end

interface.setBarTextureFunctionMap[key] = function(bar, texture)
    bar.pending:SetTexture(texture, true)
end

--===========--
--- OPTIONS ---
--===========--

options.defaultCategories[key] = {
    ['enabled'] = true,
    ['order'] = 1,
    ['format'] = 'Level {L} - {C} / {M} ({P}%){R: - ({RP}% rested)}',
    ['background-colour'] = {['r'] = 1, ['g'] = 1, ['b'] = 1, ['a'] = 1},
    ['colour'] = {['r'] = 0.58, ['g'] = 0, ['b'] = 0.55, ['a'] = 1},
    ['rested-colour'] = {['r'] = 0, ['g'] = 0.39, ['b'] = 0.88, ['a'] = 1},
    ['pendingrested-colour'] = {['r'] = 0, ['g'] = 0.68, ['b'] = 1, ['a'] = 1},
    ['format-maxlevel'] = 'Max level',
}

options.optionPageDefinitions[key] = {
    ['framename'] = 'Experience',
    ['title'] = core.definedBars[key],
    ['description'] = 'Progress towards next level-up.',
    ['callback'] = function(data)
        local fields = options.defineStandardOptions(data, {
            ['formatHint'] = {
                {'{C}', 'Current amount'},
                {'{M}', 'Max amount'},
                {'{P}', 'Percent progress'},
                {'{L}', 'Current level'},
                {'{R:...}', 'Only displayed when rested'},
                {'{RC}', 'Rested amount'},
                {'{RP}', 'Rested percent'},
            },
        })
        
        for _, field in ipairs({
            {
                ['key'] = 'rested-colour',
                ['type'] = 'colour',
                ['framename'] = 'ColourPicker-Rested',
                ['text'] = 'Rested colour',
            },
            {
                ['key'] = 'pendingrested-colour',
                ['type'] = 'colour',
                ['framename'] = 'ColourPicker-PendingRested',
                ['text'] = 'Pending rested colour',
            },
            {
                ['key'] = 'format-maxlevel',
                ['type'] = 'reset-text',
                ['framename'] = 'FormatMaxLevel',
                ['label'] = 'Text when at max level',
                ['resetValue'] = options.defaults['experience-format-maxlevel'],
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
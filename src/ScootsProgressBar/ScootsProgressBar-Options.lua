local storage = ScootsProgressBar.storage
local core = ScootsProgressBar.core
local options
local frames = ScootsProgressBar.frames
local interface = ScootsProgressBar.interface
local utility = ScootsProgressBar.utility
local lookup = ScootsProgressBar.lookup

options = {
    ['defaultCategories'] = {
        -- category = {key = { defaultValue [, characterSpecific=false] } }
        ['_'] = {
            ['active'] = 'experience',
        },
        ['general'] = {
            ['mode'] = 'single',
            ['hide-blizzard'] = false,
            ['re-anchor-stance-bar'] = false,
            ['non-interactive'] = false,
            ['tooltip-display'] = 'all',
            ['percent-precision'] = 1,
        },
        ['appearance'] = {
            ['use-flat-texture'] = false,
            ['show-text'] = 'always',
            ['text-size'] = 12,
            ['text-colour'] = {['r'] = 1, ['g'] = 1, ['b'] = 1, ['a'] = 1},
            ['text-alignment'] = 'CENTER',
            ['width'] = lookup.NONE_VAL,
            ['height'] = 12,
            ['segments'] = 20,
            ['borders'] = 'each-bar',
            ['side-borders'] = false,
            ['multi-mode-sizing'] = 'multiply',
            ['overall-opacity'] = 100,
        },
        ['position'] = {
            ['pos-x'] = 0,
            ['pos-y'] = 1,
            ['allow-dragging'] = true,
            ['clamp-to-screen'] = true,
            ['pos-anchor'] = 'BOTTOM',
            ['strata'] = 'MEDIUM',
        },
    ----
['freetimer'] = {

},
    },
    ['mimicBlizzardDefaultCategories'] = {
        ['general'] = {
            ['mode'] = 'single',
            ['hide-blizzard'] = true,
            ['re-anchor-stance-bar'] = false,
        },
        ['appearance'] = {
            ['use-flat-texture'] = false,
            ['text-size'] = 10,
            ['text-alignment'] = 'CENTER',
            ['width'] = 1012,
            ['height'] = 12,
            ['segments'] = 20,
            ['borders'] = 'each-bar',
            ['side-borders'] = false,
            ['multi-mode-sizing'] = 'multiply',
            ['overall-opacity'] = 100,
        },
        ['position'] = {
            ['pos-x'] = 0,
            ['pos-y'] = 41,
            ['pos-anchor'] = 'BOTTOM',
            ['strata'] = 'MEDIUM',
        },
    },
    ['optionPageDefinitions'] = {},
    ['load'] = function()
        if(UnitLevel('player') == 80) then
            options.defaultCategories.experience['enabled'] = false
        
            if(GetWatchedFactionInfo() ~= nil) then
                options.defaultCategories._.active = 'reputation'
            else
                options.defaultCategories._.active = 'charattunes'
            end
        end
        
        storage.options = storage.options or {
            ['autoDeleteOldCharacters'] = true,
            ['autoDeleteOldCharactersDelay'] = 28,
        }
        
        if(options.defaults == nil or (storage.options.profiles == nil or storage.options.profiles['Default'] == nil)) then
            options.defaults = {}
            storage.options.profiles = storage.options.profiles or {}
            
            if(MainMenuBarArtFrame and MainMenuBarArtFrame:IsVisible()) then
                for category, optionList in pairs(options.mimicBlizzardDefaultCategories) do
                    for key, value in pairs(optionList) do
                        options.defaultCategories[category][key] = value
                    end
                end
                
                for category, optionList in pairs(options.defaultCategories) do
                    if(core.definedBars[category]) then
                        for key, _ in pairs(optionList) do
                            if(key == 'background-colour') then
                                options.defaultCategories[category][key].r = 0
                                options.defaultCategories[category][key].g = 0
                                options.defaultCategories[category][key].b = 0
                                options.defaultCategories[category][key].a = 0.5
                            end
                        end
                    end
                end
            else
                options.defaultCategories.appearance.width = UIParent:GetWidth()
            end
            
            local populateDefault = false
            if(storage.options.profiles['Default'] == nil) then
                storage.options.profiles['Default'] = {}
                populateDefault = true
            end
            
            for category, optionList in pairs(options.defaultCategories) do
                local prefix = (core.definedBars[category] and (category .. '-')) or ''
                
                for key, value in pairs(optionList) do
                    key = prefix .. key
                    
                    if(value == lookup.NONE_VAL) then
                        value = nil
                    end
                    
                    options.defaults[key] = value
                    
                    if(populateDefault) then
                        storage.options.profiles['Default'][key] = options.defaults[key]
                    end
                end
            end
        end
        
        storage.options.activeProfile = storage.options.activeProfile or {}
        storage.options.activeProfile[core.player.guid] = storage.options.activeProfile[core.player.guid] or 'Default'
        
        if(storage.options.profiles[storage.options.activeProfile[core.player.guid]] == nil) then
            storage.options.activeProfile[core.player.guid] = 'Default'
        end
        
        local activeProfile = storage.options.profiles[storage.options.activeProfile[core.player.guid]]
            
        for category, optionList in pairs(options.defaultCategories) do
            local prefix = (core.definedBars[category] and (category .. '-')) or ''
            
            for key, value in pairs(optionList) do
                key = prefix .. key
                
                local value = activeProfile[key]
                if(value == nil) then
                    value = options.defaults[key]
                end
                
                activeProfile[key] = value
            end
        end
    end,
    ['get'] = function(key)
        return storage.options.profiles[storage.options.activeProfile[core.player.guid]][key]
    end,
    ['set'] = function(key, value, applyToField)
        storage.options.profiles[storage.options.activeProfile[core.player.guid]][key] = value
        
        if(applyToField == true and options.fieldKeys and options.fieldKeys[key]) then
            options.fieldKeys[key].applyExternalValue(value)
        end
    end,
    ['open'] = function()
        if(frames.options ~= nil) then
            InterfaceOptionsFrame_OpenToCategory(frames.options.main)
        end
    end,
    ['build'] = function()
        if(frames.options ~= nil) then
            return
        end
        
        options.optionPageDefinitions['general'] = {
            ['framename'] = 'ScootsProgressBar-Options-General',
            ['title'] = 'General options',
            ['description'] = nil,
            ['callback'] = options.defineGeneralOptions,
        }
        
        options.optionPageDefinitions['appearance'] = {
            ['framename'] = 'ScootsProgressBar-Options-Appearance',
            ['title'] = 'Appearance options',
            ['description'] = nil,
            ['callback'] = options.defineAppearanceOptions,
        }
        
        options.optionPageDefinitions['position'] = {
            ['framename'] = 'ScootsProgressBar-Options-Position',
            ['title'] = 'Position options',
            ['description'] = nil,
            ['callback'] = options.definePositionOptions,
        }
        
        options.optionPageDefinitions['profiles'] = {
            ['framename'] = 'ScootsProgressBar-Options-Profiles',
            ['title'] = 'Manage profiles',
            ['description'] = 'Profiles allow you to have different options on different characters.',
            ['special'] = 'profiles',
        }
        
        options.optionPageDefinitions['data'] = {
            ['framename'] = 'ScootsProgressBar-Options-Data',
            ['title'] = 'Manage data',
            ['description'] = string.format(
                '%s persistantly stores some per-character data for certain bars (%s, %s, and %s for example).',
                ScootsProgressBar.title,
                core.definedBars.items,
                core.definedBars.dailyattunes,
                core.definedBars.instancecap
            ),
            ['special'] = 'data',
        }
        
        frames.options = {}
        InterfaceOptionsFrame:SetWidth(math.max(900, InterfaceOptionsFrame:GetWidth()))
        
        options.createOptionsInterface()
    end,
    ['setActiveProfile'] = function(profile)
        storage.options.activeProfile[core.player.guid] = profile
        options.load()
        
        for category, optionList in pairs(options.defaultCategories) do
            local prefix = (core.definedBars[category] and (category .. '-')) or ''
            
            if(category ~= '_') then
                for key, _ in pairs(optionList) do
                    key = prefix .. key
                    core.prepareUpdate(category, key, options.get(key))
                    
                    if(options.fieldKeys and options.fieldKeys[key]) then
                        options.fieldKeys[key].applyExternalValue(options.get(key))
                    end
                end
            end
        end
        
        core.preCacheOrder()
        options.sortMenuLinks()
        frames.options.profileSelect.refresh(profile)
        
        if(frames.options.optionPages.profiles and frames.options.optionPages.profiles.drawExistingProfiles) then
            frames.options.optionPages.profiles.drawExistingProfiles()
        end
        
        collectgarbage()
    end,
    ['defineGeneralOptions'] = function(data)
        return {
            {
                ['key'] = 'mode',
                ['type'] = 'radio',
                ['framename'] = data.framename .. '-Mode',
                ['label'] = 'Mode',
                ['choices'] = {
                    {
                        ['name'] = 'Single',
                        ['value'] = 'single',
                        ['tooltip'] = 'Show only a single enabled bar at a time. Left-click to cycle to the next enabled bar.',
                    },
                    {
                        ['name'] = 'Multi',
                        ['value'] = 'multi',
                        ['tooltip'] = 'Show all enabled bars at once.',
                    },
                },
            },
            {
                ['key'] = 'hide-blizzard',
                ['type'] = 'checkbox',
                ['framename'] = data.framename .. '-HideBlizzard',
                ['label'] = 'Hide Blizzard experience bar',
            },
            {
                ['key'] = 're-anchor-stance-bar',
                ['type'] = 'checkbox',
                ['framename'] = data.framename .. '-ReAnchorStanceBar',
                ['label'] = 'Re-anchor Blizzard stance bar',
                ['tooltip'] = string.format('Anchor the Blizzard stance bar to the %s frame.', ScootsProgressBar.title),
            },
            {
                ['key'] = 'non-interactive',
                ['type'] = 'checkbox',
                ['framename'] = data.framename .. '-NonInteractive',
                ['label'] = 'Make bar non-interactive',
                ['tooltip'] = 'With this option enabled you will no-longer be able to left-click to cycle through bars (in single mode), left-click-and-drag to move the bar, or right-click to open options.',
            },
            {
                ['key'] = 'tooltip-display',
                ['type'] = 'dropdown',
                ['framename'] = data.framename .. '-TooltipDisplay',
                ['label'] = 'Tooltip display',
                ['tooltip'] = table.concat({
                    'Shows a tooltip displaying the tracked information when hovering over the bar.',
                    '"Visible bars only" and "All enabled bars" are only distinct when "Mode" is set to "Single".',
                    'Requires that the "Make bar non-interactive" option be disabled.',
                }, '\n\n'),
                ['choices'] = {
                    {
                        ['name'] = 'Don\'t display tooltip',
                        ['value'] = 'none',
                    },
                    {
                        ['name'] = 'Visible bars only',
                        ['value'] = 'visible',
                    },
                    {
                        ['name'] = 'All enabled bars',
                        ['value'] = 'all',
                    },
                },
            },
            {
                ['key'] = 'percent-precision',
                ['type'] = 'increment-text',
                ['framename'] = data.framename .. '-TextSize',
                ['label'] = 'Percentage precision',
                ['increment'] = 1,
                ['width'] = 50,
                ['min'] = 0,
                ['max'] = 15,
                ['tooltip'] = 'How many decimal places the percentage text should be rounded to.',
            },
            {
                ['key'] = 'mimic-blizzard',
                ['type'] = 'button',
                ['framename'] = data.framename .. '-MimicBlizzard',
                ['width'] = 120,
                ['text'] = 'Mimic Blizzard',
                ['tooltip'] = 'Set size and position to mimic the default Blizzard experience bar.',
                ['callback'] = function()
                    options.doConfirm({
                        ['text'] = 'This action cannot be automatically un-done.\n\nAny custom positioning/sizing will need to be re-done manually.\n\nContinue?',
                        ['callback'] = function()
                            options.mimicBlizzard()
                        end
                    })
                end,
            },
        }
    end,
    ['defineAppearanceOptions'] = function(data)
        return {
            {
                ['key'] = 'use-flat-texture',
                ['type'] = 'checkbox',
                ['framename'] = data.framename .. '-UseFlatTexture',
                ['label'] = 'Use flat texture for bars',
            },
            {
                ['key'] = 'show-text',
                ['type'] = 'dropdown',
                ['framename'] = data.framename .. '-ShowText',
                ['label'] = 'Show text',
                ['tooltip'] = '"On-hover" requires that you not have made the bar non-interactive.',
                ['choices'] = {
                    {
                        ['name'] = 'Never',
                        ['value'] = 'never',
                    },
                    {
                        ['name'] = 'On-hover',
                        ['value'] = 'hover',
                    },
                    {
                        ['name'] = 'Always',
                        ['value'] = 'always',
                    },
                },
            },
            {
                ['key'] = 'text-size',
                ['type'] = 'increment-text',
                ['framename'] = data.framename .. '-TextSize',
                ['label'] = 'Text size',
                ['increment'] = 1,
                ['width'] = 50,
                ['min'] = 1,
            },
            {
                ['key'] = 'text-colour',
                ['type'] = 'colour',
                ['framename'] = data.framename .. '-ColourPicker-TextColour',
                ['text'] = 'Text colour',
            },
            {
                ['key'] = 'text-alignment',
                ['type'] = 'choice-slider',
                ['framename'] = data.framename .. '-TextAlignment',
                ['label'] = 'Text alignment',
                ['callbackWhileDragging'] = true,
                ['choices'] = {
                    {
                        ['name'] = 'Left',
                        ['value'] = 'LEFT',
                    },
                    {
                        ['name'] = 'Centre',
                        ['value'] = 'CENTER',
                    },
                    {
                        ['name'] = 'Right',
                        ['value'] = 'RIGHT',
                    },
                },
            },
            {
                ['key'] = 'width',
                ['type'] = 'increment-text',
                ['framename'] = data.framename .. '-Width',
                ['label'] = 'Width',
                ['increment'] = 0.1,
                ['min'] = 0.1,
                ['resetText'] = 'Full width',
                ['resetCallback'] = function()
                    return UIParent:GetWidth()
                end,
            },
            {
                ['key'] = 'height',
                ['type'] = 'increment-text',
                ['framename'] = data.framename .. '-Height',
                ['label'] = 'Height',
                ['increment'] = 0.1,
                ['min'] = 0.1,
            },
            {
                ['key'] = 'segments',
                ['type'] = 'range-slider',
                ['framename'] = data.framename .. '-Segments',
                ['label'] = 'Segments',
                ['increment'] = 1,
                ['min'] = 1,
                ['max'] = 100,
                ['tooltip'] = 'Draw vertical lines on the bar to split into this many segments.',
                ['callbackWhileDragging'] = true,
            },
            {
                ['key'] = 'borders',
                ['type'] = 'dropdown',
                ['framename'] = data.framename .. '-Borders',
                ['label'] = 'Borders',
                ['tooltip'] = '"Whole frame" and "Each bar" are only distinct when Mode is set to "Multi".',
                ['choices'] = {
                    {
                        ['name'] = 'None',
                        ['value'] = 'none',
                    },
                    {
                        ['name'] = 'Whole frame',
                        ['value'] = 'frame',
                    },
                    {
                        ['name'] = 'Each bar',
                        ['value'] = 'each-bar',
                    },
                },
            },
            {
                ['key'] = 'side-borders',
                ['type'] = 'checkbox',
                ['framename'] = data.framename .. '-SideBorders',
                ['label'] = 'Borders include side-pieces',
            },
            {
                ['key'] = 'multi-mode-sizing',
                ['type'] = 'dropdown',
                ['framename'] = data.framename .. '-MultiModeSizing',
                ['label'] = 'Multi-mode sizing',
                ['tooltip'] = table.concat({
                    'How the size of the frame is handled when Mode is set to "Multi".',
                    '',
                    '|cffffffff' .. 'Compress' .. '|r',
                    'Visible bars are stacked and compressed to fit the frame height.',
                    '',
                    '|cffffffff' .. 'Multiply' .. '|r',
                    'Visible bars are stacked and the frame height is multiplied by the number of visible bars.',
                }, '\n'),
                ['choices'] = {
                    {
                        ['name'] = 'Compress',
                        ['value'] = 'compress',
                    },
                    {
                        ['name'] = 'Multiply',
                        ['value'] = 'multiply',
                    },
                },
            },
            {
                ['key'] = 'overall-opacity',
                ['type'] = 'range-slider',
                ['framename'] = data.framename .. '-OverallOpacity',
                ['label'] = 'Overall Opacity',
                ['increment'] = 1,
                ['min'] = 0,
                ['max'] = 100,
                ['callbackWhileDragging'] = true,
            },
            {
                ['key'] = 'hide-all-backgrounds',
                ['type'] = 'button',
                ['framename'] = data.framename .. '-HideAllBackgrounds',
                ['width'] = 120,
                ['text'] = 'Hide all backgrounds',
                ['tooltip'] = 'Set all backgrounds to be transparent.',
                ['callback'] = function()
                    options.doConfirm({
                        ['text'] = 'This action cannot be automatically un-done.\n\nAny custom opacity for backgrounds will need to be re-done manually.\n\nContinue?',
                        ['callback'] = function()
                            options.setAllBackgroundsToAlpha(0)
                        end
                    })
                end,
            },
            {
                ['key'] = 'show-all-backgrounds',
                ['type'] = 'button',
                ['framename'] = data.framename .. '-ShowAllBackgrounds',
                ['width'] = 120,
                ['text'] = 'Show all backgrounds',
                ['tooltip'] = 'Set all backgrounds to be opaque.',
                ['callback'] = function()
                    options.doConfirm({
                        ['text'] = 'This action cannot be automatically un-done.\n\nAny custom opacity for backgrounds will need to be re-done manually.\n\nContinue?',
                        ['callback'] = function()
                            options.setAllBackgroundsToAlpha(1)
                        end
                    })
                end,
            },
        }
    end,
    ['definePositionOptions'] = function(data)
        return {
            {
                ['key'] = 'pos-x',
                ['type'] = 'increment-text',
                ['framename'] = data.framename .. '-PosX',
                ['label'] = 'X position',
                ['increment'] = 0.1,
                ['width'] = 70,
            },
            {
                ['key'] = 'pos-y',
                ['type'] = 'increment-text',
                ['framename'] = data.framename .. '-PosY',
                ['label'] = 'Y position',
                ['increment'] = 0.1,
                ['width'] = 70,
            },
            {
                ['key'] = 'allow-dragging',
                ['type'] = 'checkbox',
                ['framename'] = data.framename .. '-AllowDragging',
                ['label'] = 'Allow dragging',
                ['tooltip'] = 'Left-click-and-drag to move the bar around.',
            },
            {
                ['key'] = 'clamp-to-screen',
                ['type'] = 'checkbox',
                ['framename'] = data.framename .. '-ClampToScreen',
                ['label'] = 'Clamp to screen',
            },
            {
                ['key'] = 'pos-anchor',
                ['type'] = 'dropdown',
                ['framename'] = data.framename .. '-PosY',
                ['label'] = 'Anchor point',
                ['callbackWhileDragging'] = true,
                ['choices'] = {
                    {
                        ['name'] = 'TOPLEFT',
                        ['value'] = 'TOPLEFT',
                    },
                    {
                        ['name'] = 'TOP',
                        ['value'] = 'TOP',
                    },
                    {
                        ['name'] = 'TOPRIGHT',
                        ['value'] = 'TOPRIGHT',
                    },
                    {
                        ['name'] = 'LEFT',
                        ['value'] = 'LEFT',
                    },
                    {
                        ['name'] = 'CENTER',
                        ['value'] = 'CENTER',
                    },
                    {
                        ['name'] = 'RIGHT',
                        ['value'] = 'RIGHT',
                    },
                    {
                        ['name'] = 'BOTTOMLEFT',
                        ['value'] = 'BOTTOMLEFT',
                    },
                    {
                        ['name'] = 'BOTTOM',
                        ['value'] = 'BOTTOM',
                    },
                    {
                        ['name'] = 'BOTTOMRIGHT',
                        ['value'] = 'BOTTOMRIGHT',
                    },
                },
            },
            {
                ['key'] = 'strata',
                ['type'] = 'choice-slider',
                ['framename'] = data.framename .. '-Strata',
                ['label'] = 'Frame strata',
                ['tooltip'] = 'The higher the strata, the more UI elements the bar will appear in front of.',
                ['callbackWhileDragging'] = true,
                ['choices'] = {
                    {
                        ['name'] = 'BACKGROUND',
                        ['value'] = 'BACKGROUND',
                    },
                    {
                        ['name'] = 'LOW',
                        ['value'] = 'LOW',
                    },
                    {
                        ['name'] = 'MEDIUM',
                        ['value'] = 'MEDIUM',
                    },
                    {
                        ['name'] = 'HIGH',
                        ['value'] = 'HIGH',
                    },
                    {
                        ['name'] = 'DIALOG',
                        ['value'] = 'DIALOG',
                    },
                    {
                        ['name'] = 'FULLSCREEN',
                        ['value'] = 'FULLSCREEN',
                    },
                },
            },
        }
    end,
    ['defineStandardOptions'] = function(barData, optionData)
        optionData = optionData or {}
    
        local fields = {
            {
                ['key'] = barData.key .. '-enabled',
                ['type'] = 'checkbox',
                ['framename'] = barData.framename .. '-Enabled',
                ['label'] = 'Enabled',
                ['callback'] = function(barKey, key, value)
                    frames.options.menuLinks[barKey].fade(not value)
                end,
            },
            {
                ['key'] = barData.key .. '-order',
                ['type'] = 'reorder-buttons',
                ['framename'] = barData.framename .. '-Order',
                ['label'] = 'Re-order',
            },
            {
                ['key'] = barData.key .. '-format',
                ['type'] = 'reset-text',
                ['framename'] = barData.framename .. '-Format',
                ['label'] = 'Text format',
                ['tooltip'] = 'Text format',
                ['tooltipExtra'] = optionData.formatHint or {
                    {'{C}', 'Current amount'},
                    {'{M}', 'Max amount'},
                    {'{P}', 'Percent progress'},
                    {'{S}', 's (plural)'},
                    {'{ES}', 'es (plural)'},
                },
                ['resetValue'] = options.defaults[barData.key .. '-format'],
                ['resetText'] = 'Apply default',
                ['width'] = 250,
            },
            {
                ['key'] = barData.key .. '-background-colour',
                ['type'] = 'colour',
                ['framename'] = barData.framename .. '-ColourPicker-Background',
                ['text'] = 'Background colour',
            }
        }
        
        if(optionData.excludeMainColour ~= true) then
            table.insert(fields, {
                ['key'] = barData.key .. '-colour',
                ['type'] = 'colour',
                ['framename'] = barData.framename .. '-ColourPicker-Main',
                ['text'] = 'Main colour',
            })
        end
        
        return fields
    end,
    ['doConfirm'] = function(data)
        StaticPopupDialogs[data.key or 'ScootsProgressBar_CONFIRM_DIALOGUE'] = {
            ['text'] = data.text,
            ['button1'] = data.yesText or OKAY,
            ['button2'] = data.noText or CANCEL,
            ['timeout'] = 0,
            ['exclusive'] = 1,
            ['whileDead'] = 1,
            ['hideOnEscape'] = 1,
            ['OnAccept'] = data.callback,
            ['OnCancel'] = function() end,
            ['OnHide'] = function() end,
        }
        
        local dialogueFrame = StaticPopup_Show(data.key or 'ScootsProgressBar_CONFIRM_DIALOGUE')
        local dialogueFrameStrata = dialogueFrame:GetFrameStrata()
        
        dialogueFrame:SetFrameStrata('TOOLTIP')
        
        if(dialogueFrame.ScootsProgressBarHooked == nil) then
            dialogueFrame:HookScript('OnHide', function()
                dialogueFrame:SetFrameStrata(dialogueFrameStrata)
            end)
        end
    end,
    ['setAllBackgroundsToAlpha'] = function(alpha)
        for key, value in pairs(options.defaults) do
            if(key:match('%-background%-colour$')) then
                local current = options.get(key)
                
                options.set(key, {['r'] = current.r, ['g'] = current.g, ['b'] = current.b, ['a'] = alpha}, true)
            end
        end
            
        for key, _ in pairs(core.definedBars) do
            interface.applyColours(key)
        end
    end,
    ['mimicBlizzard'] = function()
        for category, optionList in pairs(options.mimicBlizzardDefaultCategories) do
            for key, value in pairs(optionList) do
                if(options.get(key) ~= value) then
                    options.set(key, value, true)
                    core.prepareUpdate(category, key, value)
                end
            end
        end
                
        for category, optionList in pairs(options.defaultCategories) do
            if(core.definedBars[category]) then
                for key, _ in pairs(optionList) do
                    if(key == 'background-colour') then
                        key = string.format('%s-%s', category, key)
                        local colour = options.get(key)
                        
                        if(colour.r ~= 0 or colour.g ~= 0 or colour.b ~= 0 or colour.a ~= 0.5) then
                            local value = {['r'] = 0, ['g'] = 0, ['b'] = 0, ['a'] = 0.5}
                            options.set(key, value, true)
                            core.prepareUpdate(category, key, value)
                        end
                    end
                end
            end
        end
    end,
}

for funcName, func in pairs(options) do
    ScootsProgressBar.options[funcName] = func
end

options = ScootsProgressBar.options
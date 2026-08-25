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
            ['adjust-for-vehicle'] = false,
            ['non-interactive'] = false,
            ['tooltip-display'] = 'all',
            ['percent-precision'] = 1,
        },
        ['appearance'] = {
            ['use-flat-texture'] = false,
            ['width'] = lookup.NONE_VAL,
            ['height'] = 12,
            ['segments'] = 20,
            ['borders'] = 'each-bar',
            ['side-borders'] = false,
            ['multi-mode-sizing'] = 'multiply',
            ['overall-opacity'] = 100,
        },
        ['text'] = {
            ['show-text'] = 'always',
            ['text-size'] = 12,
            ['text-outline'] = 'OUTLINE',
            ['text-colour'] = {['r'] = 1, ['g'] = 1, ['b'] = 1, ['a'] = 1},
            ['text-alignment'] = 'CENTER',
            ['nudge-text-horizontal'] = 0,
            ['text-vertical-alignment'] = 'MIDDLE',
            ['nudge-text-vertical'] = 0,
        },
        ['position'] = {
            ['pos-x'] = 0,
            ['pos-y'] = 1,
            ['allow-dragging'] = true,
            ['clamp-to-screen'] = true,
            ['pos-anchor'] = 'BOTTOM',
            ['strata'] = 'MEDIUM',
            ['min-interactive-strata'] = 'MEDIUM',
        },
    },
    ['mimicBlizzardDefaultCategories'] = {
        ['general'] = {
            ['mode'] = 'single',
            ['hide-blizzard'] = true,
            ['re-anchor-stance-bar'] = false,
            ['adjust-for-vehicle'] = true,
        },
        ['appearance'] = {
            ['use-flat-texture'] = false,
            ['width'] = 1012,
            ['height'] = 12,
            ['segments'] = 20,
            ['borders'] = 'each-bar',
            ['side-borders'] = false,
            ['multi-mode-sizing'] = 'multiply',
            ['overall-opacity'] = 100,
        },
        ['text'] = {
            ['text-size'] = 10,
            ['text-outline'] = 'OUTLINE',
            ['text-alignment'] = 'CENTER',
            ['text-vertical-alignment'] = 'TOP',
            ['nudge-text-vertical'] = 1,
        },
        ['position'] = {
            ['pos-x'] = 0,
            ['pos-y'] = 41,
            ['pos-anchor'] = 'BOTTOM',
            ['strata'] = 'MEDIUM',
            ['min-interactive-strata'] = 'HIGH',
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
    ['build'] = function()
        if(frames.options ~= nil) then
            return
        end
        
        ScootsLibOptions.registerCustomField('scootsprogressbar-reorder-buttons', options.processOptionReorderButtons, function(fieldData, prevType)
            return ((fieldData.label or '') ~= ''), 0, 0
        end)
        
        options.optionPageDefinitions['general'] = {
            ['framename'] = 'General',
            ['title'] = 'General options',
            ['description'] = nil,
            ['callback'] = options.defineGeneralOptions,
        }
        
        options.optionPageDefinitions['text'] = {
            ['framename'] = 'Text',
            ['title'] = 'Text options',
            ['description'] = nil,
            ['callback'] = options.defineTextOptions,
        }
        
        options.optionPageDefinitions['appearance'] = {
            ['framename'] = 'Appearance',
            ['title'] = 'Appearance options',
            ['description'] = nil,
            ['callback'] = options.defineAppearanceOptions,
        }
        
        options.optionPageDefinitions['position'] = {
            ['framename'] = 'Position',
            ['title'] = 'Position options',
            ['description'] = nil,
            ['callback'] = options.definePositionOptions,
        }
        
        options.optionPageDefinitions['profiles'] = {
            ['framename'] = 'Profiles',
            ['title'] = 'Manage profiles',
            ['description'] = 'Profiles allow you to have different options on different characters.',
            ['special'] = true,
            ['callback'] = options.buildProfileManager,
        }
        
        options.optionPageDefinitions['data'] = {
            ['framename'] = 'Data',
            ['title'] = 'Manage data',
            ['description'] = string.format(
                '%s persistantly stores some per-character data for certain bars (%s, %s, and %s for example).',
                ScootsProgressBar.title,
                core.definedBars.items,
                core.definedBars.dailyattunes,
                core.definedBars.instancecap
            ),
            ['special'] = true,
            ['callback'] = options.buildDataManager,
        }
        
        frames.options = {}
        options.fieldKeys = {}
        frames.options.main = ScootsLibOptions.core.createOptionsInterface(
            frames.options,
            options.fieldKeys,
            {
                ['framename'] = 'ScootsProgressBar-Options',
                ['title'] = ScootsProgressBar.title,
                ['version'] = ScootsProgressBar.version,
                ['optionGetCallback'] = options.get,
                ['optionChangeCallback'] = function(pageKey, fieldKey, value)
                    options.set(fieldKey, value)
                    core.prepareUpdate(pageKey, fieldKey, value)
                end,
            },
            options.optionPageDefinitions,
            function()
                frames.options.menuLinks.general.select()
                frames.options.contentHolder.setActiveChild(frames.options.optionPages.general)
                options.sortMenuLinks()
                
                for key, menuLink in pairs(frames.options.menuLinks) do
                    menuLink.fade(options.get(key .. '-enabled') == false)
                end
            end
        )
        
        frames.options.profileSelect = ScootsLibOptions.core.insertOptionsDropdown({
            ['framename'] = 'ScootsProgressBar-Options-ProfileSelect',
            ['parent'] = frames.options.main,
            ['defaultValue'] = storage.options.activeProfile[core.player.guid],
            ['label'] = 'Profile',
            ['tooltip'] = 'Profiles allow you to have different options on different characters.',
            ['callback'] = function(self, profile)
                options.setActiveProfile(profile)
            end,
            ['choices'] = function()
                local profileList = {}
                
                for key, _ in pairs(storage.options.profiles) do
                    table.insert(profileList, {
                        ['name'] = key,
                        ['value'] = key,
                    })
                end
                
                table.sort(profileList, function(profileA, profileB)
                    if(profileA.value == 'Default') then
                        return true
                    elseif(profileB.value == 'Default') then
                        return false
                    end
                    
                    return profileA.name < profileB.name
                end)
                
                return profileList
            end,
        })
        
        frames.options.profileSelect:SetPoint('TOPRIGHT', frames.options.main, 'TOPRIGHT', -16, -20)
    end,
    ['sortMenuLinks'] = function()
        frames.options.menuLinks['general']:SetPoint('TOPLEFT', frames.options.menuScrollChild, 'TOPLEFT', 0, -8)
        local height = frames.options.menuLinks['general']:GetHeight() + 8
        
        frames.options.menuLinks['text']:SetPoint('TOPLEFT', frames.options.menuLinks['general'], 'BOTTOMLEFT', 0, 0)
        height = height + frames.options.menuLinks['text']:GetHeight()
        
        frames.options.menuLinks['appearance']:SetPoint('TOPLEFT', frames.options.menuLinks['text'], 'BOTTOMLEFT', 0, 0)
        height = height + frames.options.menuLinks['appearance']:GetHeight()
        
        frames.options.menuLinks['position']:SetPoint('TOPLEFT', frames.options.menuLinks['appearance'], 'BOTTOMLEFT', 0, 0)
        height = height + frames.options.menuLinks['position']:GetHeight()
        
        frames.options.menuLinks['profiles']:SetPoint('TOPLEFT', frames.options.menuLinks['position'], 'BOTTOMLEFT', 0, 0)
        height = height + frames.options.menuLinks['profiles']:GetHeight()
        
        frames.options.menuLinks['data']:SetPoint('TOPLEFT', frames.options.menuLinks['profiles'], 'BOTTOMLEFT', 0, 0)
        height = height + frames.options.menuLinks['data']:GetHeight()
        
        local prevLink = frames.options.menuLinks['data']
        local first = true
        
        for index, data in ipairs(core.barOrder) do
            if(options.optionPageDefinitions[data.key]) then
                local offset = (first and 10) or 0
                
                local menuLink = frames.options.menuLinks[data.key]
                menuLink:SetPoint('TOPLEFT', prevLink, 'BOTTOMLEFT', 0, 0 - offset)
                menuLink.fade(options.get(data.key .. '-enabled') == false)
                
                prevLink = menuLink
                height = height + menuLink:GetHeight() + offset
                first = nil
            end
        end
        
        frames.options.menuScrollChild:SetHeight(height + 8)
    end,
    ['buildProfileManager'] = function(data)
        local height = 0
    
        local createNew = ScootsLibOptions.core.insertOptionsGroup({
            ['framename'] = data.framename .. '-CreateNew',
            ['parent'] = data.parent,
            ['label'] = 'Create new profile',
            ['width'] = 400,
            ['callback'] = function(group, header)
                group.getDefaultProfileName = function()
                    local name = string.format('%s - %s %s', core.player.name, core.player.race, core.player.class)
                    local tryNameCount = 1
                    
                    while(storage.options.profiles[name] ~= nil) do
                        name = string.format('%s (%d)', name:gsub(' %(%d+%)$', ''), tryNameCount)
                        tryNameCount = tryNameCount + 1
                    end
                    
                    return name
                end
                
                --
                
                group.info = group:CreateFontString(nil, 'OVERLAY', 'GameFontNormalSmall')
                group.info:SetPoint('TOPLEFT', header, 'BOTTOMLEFT', 0, -10)
                group.info:SetWidth(380)
                group.info:SetJustifyH('LEFT')
                group.info:SetWordWrap(true)
                group.info:SetText('New profiles are created as clones of the currently selected profile.')
                
                height = group.info:GetHeight()
                
                --
                
                local textbox = ScootsLibOptions.core.insertOptionsTextField({
                    ['framename'] = data.framename .. '-CreateNew-Textbox',
                    ['parent'] = group,
                    ['label'] = 'Profile name',
                    ['width'] = 280,
                    ['justify'] = 'LEFT',
                    ['default'] = group.getDefaultProfileName(),
                    ['callback'] = function(self, value)
                        if(self.suppressCallback) then
                            self.suppressCallback = nil
                            return
                        end
                        
                        group.error:Hide()
                    end,
                })
                
                textbox:SetPoint('TOPLEFT', group.info, 'BOTTOMLEFT', 0, -20)
        
                textbox:SetScript('OnEditFocusLost', function(self)
                    if(self:GetText():gsub('^%s+', ''):gsub('%s+$', '') == '') then
                        self.suppressCallback = true
                        self:SetText(group.getDefaultProfileName())
                    end
                end)
                
                --
                
                group.error = group:CreateFontString(nil, 'OVERLAY', 'GameFontNormalSmall')
                group.error:SetPoint('TOPLEFT', textbox, 'BOTTOMLEFT', 0, 0)
                group.error:SetTextColor(1, 0, 0)
                group.error:Hide()
                
                --
        
                local button = ScootsLibOptions.core.insertOptionsButton({
                    ['framename'] = data.framename .. '-CreateNew-Button',
                    ['parent'] = group,
                    ['width'] = 100,
                    ['text'] = 'Create',
                    ['callback'] = function()
                        local profileName = textbox:GetText():gsub('^%s+', ''):gsub('%s+$', '')
                        
                        if(profileName == '') then
                            group.error:SetText('Profile name cannot be blank')
                            group.error:Show()
                            return
                        elseif(storage.options.profiles[profileName] ~= nil) then
                            group.error:SetText('A profile with that name already exists.')
                            group.error:Show()
                            return
                        end
                        
                        storage.options.profiles[profileName] = {}
                        
                        for key, value in pairs(storage.options.profiles[storage.options.activeProfile[core.player.guid]]) do
                            storage.options.profiles[profileName][key] = value
                        end
                        
                        options.setActiveProfile(profileName)
                        data.parent.drawExistingProfiles()
                        textbox:SetText(group.getDefaultProfileName())
                    end,
                })
                
                button:SetPoint('LEFT', textbox, 'RIGHT', 0, 0)
                
                --
                
                return height + math.max(textbox:GetHeight(), button:GetHeight()) + 40
            end,
        })
        
        height = height + createNew:GetHeight() + 10
        
        --
        
        local headers = {
            ['name'] = data.parent:CreateFontString(nil, 'OVERLAY', 'GameFontNormalSmall'),
            ['used'] = data.parent:CreateFontString(nil, 'OVERLAY', 'GameFontNormalSmall'),
        }
        
        headers.name:SetPoint('TOPLEFT', createNew, 'BOTTOMLEFT', 4, -10)
        headers.name:SetText(' \nProfile')
        headers.name:SetJustifyH('LEFT')
        
        headers.used:SetPoint('TOPLEFT', headers.name, 'TOPRIGHT', 5, 0)
        headers.used:SetText('Used by\ncharacters')
        headers.used:SetJustifyH('CENTER')
        headers.used:SetWidth(60)
        
        headers.name:SetWidth(-4 + 400 - (4 + headers.used:GetWidth() + 4 + 50 + 4 + 50 + 4))
        
        height = height + headers.name:GetHeight() + 2
        
        data.parent.drawExistingProfiles = function()
            local profileList = {}
            
            for key, _ in pairs(storage.options.profiles) do
                table.insert(profileList, key)
            end
            
            table.sort(profileList, function(profileA, profileB)
                if(profileA == 'Default') then
                    return true
                elseif(profileB == 'Default') then
                    return false
                end
                
                return profileA < profileB
            end)
            
            --
            
            data.objects = data.objects or {}
            
            local prev = headers
            local tableHeight = 0
            
            local profileUsage = {}
            
            for _, profile in pairs(storage.options.activeProfile) do
                profileUsage[profile] = (profileUsage[profile] or 0) + 1
            end
            
            --
            
            for index, profile in ipairs(profileList) do
                local objects = data.objects[index]
            
                if(objects == nil) then
                    table.insert(data.objects, {
                        ['name'] = data.parent:CreateFontString(nil, 'OVERLAY', 'GameFontHighlightSmall'),
                        ['used'] = data.parent:CreateFontString(nil, 'OVERLAY', 'GameFontHighlightSmall'),
                        ['background'] = data.parent:CreateTexture(nil, 'ARTWORK'),
                        ['reset'] = ScootsLibOptions.core.insertOptionsButton({
                            ['framename'] = data.framename .. '-Reset-' .. tostring(index),
                            ['parent'] = data.parent,
                            ['width'] = 50,
                            ['text'] = 'Reset',
                            ['tooltip'] = 'Reset all options back to the addon default values for this profile.',
                            ['callback'] = function(self)
                                options.doConfirm({
                                    ['text'] = 'This will reset all options for this profile back to the addon default values.\n\nThis action cannot be automatically undone.\n\nContinue?',
                                    ['callback'] = function()
                                        storage.options.profiles[self.profile] = {}
                                        
                                        if(self.profile == storage.options.activeProfile[core.player.guid]) then
                                            options.setActiveProfile(self.profile)
                                        end
                                    end,
                                })
                            end,
                        }),
                        ['delete'] = ScootsLibOptions.core.insertOptionsButton({
                            ['framename'] = data.framename .. '-Delete-' .. tostring(index),
                            ['parent'] = data.parent,
                            ['width'] = 50,
                            ['text'] = 'Delete',
                            ['callback'] = function(self)
                                options.doConfirm({
                                    ['text'] = string.format('Are you sure you want to delete the profile "%s"?\n\nThis action cannot be automatically undone.', self.profile),
                                    ['callback'] = function()
                                        storage.options.profiles[self.profile] = nil
                                        
                                        if(self.profile == storage.options.activeProfile[core.player.guid]) then
                                            options.setActiveProfile('Default')
                                        end
                                        
                                        data.parent.drawExistingProfiles()
                                    end,
                                })
                            end,
                        }),
                    })
                    
                    objects = data.objects[index]
                    
                    objects.name:SetJustifyH('LEFT')
                    objects.name:SetWordWrap(true)
                    objects.name:SetNonSpaceWrap(true)
                    objects.name:SetWidth(headers.name:GetWidth())
                    
                    objects.used:SetPoint('TOPLEFT', objects.name, 'TOPRIGHT', 4, 0)
                    objects.used:SetJustifyH('CENTER')
                    objects.used:SetWidth(headers.used:GetWidth())
                    
                    objects.background:SetPoint('TOPLEFT', objects.name, 'TOPLEFT', -4, 2)
                    objects.background:SetPoint('BOTTOMLEFT', objects.name, 'BOTTOMLEFT', -4, -2)
                    objects.background:SetWidth(400)
                    objects.background:SetTexture(0.7, 0.7, 1, 0.1)
                    
                    objects.reset:SetPoint('LEFT', objects.used, 'RIGHT', 4, 0)
                    objects.delete:SetPoint('LEFT', objects.reset, 'RIGHT', 4, 0)
                end
                
                objects.name:Show()
                objects.used:Show()
                objects.reset:Show()
                
                if(index % 2 == 1) then
                    objects.background:Show()
                else
                    objects.background:Hide()
                end
                
                if(profile ~= 'Default') then
                    objects.delete:Show()
                else
                    objects.delete:Hide()
                end
                
                objects.name:SetPoint('TOPLEFT', prev.name, 'BOTTOMLEFT', 0, -4)
                objects.name:SetText(profile)
                objects.name:SetHeight(0)
                objects.name:SetHeight(math.max(objects.name:GetHeight(), objects.reset:GetHeight()))
                
                objects.used:SetHeight(objects.name:GetHeight())
                objects.used:SetText(tostring(profileUsage[profile] or 0))
                
                objects.reset.profile = profile
                objects.delete.profile = profile
                
                height = height + objects.name:GetHeight() + 4
                prev = objects
            end
            
            for index = (#profileList + 1), #data.objects do
                local objects = data.objects[index]
                
                objects.name:Hide()
                objects.used:Hide()
                objects.background:Hide()
                objects.reset:Hide()
                objects.delete:Hide()
            end
            
            --
            
            return tableHeight
        end
        
        height = height + data.parent.drawExistingProfiles() + 10
        
        --
        
        return createNew, height
    end,
    ['buildDataManager'] = function(data)
        local height = 0
    
        local autoDeleteOptions = ScootsLibOptions.core.insertOptionsGroup({
            ['framename'] = data.framename .. '-AutoDelete',
            ['parent'] = data.parent,
            ['width'] = 400,
            ['callback'] = function(group)
                local groupHeight = 10
                
                local checkbox = ScootsLibOptions.core.insertOptionsCheckbox({
                    ['framename'] = data.framename .. '-AutoDelete',
                    ['parent'] = group,
                    ['label'] = 'Auto-delete character data after',
                    ['defaultState'] = storage.options.autoDeleteOldCharacters,
                    ['callback'] = function(self, value)
                        storage.options.autoDeleteOldCharacters = value
                    end,
                })
                
                checkbox:SetPoint('TOPLEFT', group, 'TOPLEFT', 10, -10)
                
                --
                
                textbox = ScootsLibOptions.core.insertOptionsIncrementTextField({
                    ['framename'] = data.framename .. '-AutoDeleteDelay',
                    ['parent'] = group,
                    ['label'] = 'days of inactivity.',
                    ['width'] = 50,
                    ['justify'] = 'CENTER',
                    ['default'] = storage.options.autoDeleteOldCharactersDelay,
                    ['increment'] = 1,
                    ['min'] = 1,
                    ['callback'] = function(self, value)
                        storage.options.autoDeleteOldCharactersDelay = value
                    end,
                })
                
                textbox:SetPoint('LEFT', checkbox.label, 'RIGHT', 2 + textbox.incrementDown:GetWidth() + 1, 0)
                
                textbox.label:ClearAllPoints()
                textbox.label:SetPoint('LEFT', textbox.incrementUp, 'RIGHT', 2, 0)
                
                groupHeight = groupHeight + math.max(checkbox:GetHeight(), textbox:GetHeight()) + 10
                
                --
                
                group.info = group:CreateFontString(nil, 'OVERLAY', 'GameFontHighlightSmall')
                group.info:SetPoint('TOPLEFT', checkbox, 'BOTTOMLEFT', 0, -10)
                group.info:SetWidth(380)
                group.info:SetJustifyH('LEFT')
                group.info:SetWordWrap(true)
                group.info:SetText('Character data auto-deletion occurs when you login to a character, or when you reload your UI.')
                
                groupHeight = groupHeight + group.info:GetHeight() + 10
                
                --
                
                return groupHeight
            end,
        })
        
        height = height + autoDeleteOptions:GetHeight() + 10
        
        --
        
        local headers = {
            ['char'] = data.parent:CreateFontString(nil, 'OVERLAY', 'GameFontNormalSmall'),
            ['seen'] = data.parent:CreateFontString(nil, 'OVERLAY', 'GameFontNormalSmall'),
        }
        
        headers.char:SetPoint('TOPLEFT', autoDeleteOptions, 'BOTTOMLEFT', 4, -10)
        headers.char:SetText('Character')
        headers.char:SetJustifyH('LEFT')
        
        headers.seen:SetPoint('TOPLEFT', headers.char, 'TOPRIGHT', 5, 0)
        headers.seen:SetText('Last seen')
        headers.seen:SetJustifyH('LEFT')
        headers.seen:SetWidth(150)
        
        headers.char:SetWidth(-4 + 400 - (4 + headers.seen:GetWidth() + 4 + 50 + 4))
        
        height = height + headers.char:GetHeight() + 2
        
        data.parent.drawCharacters = function()
            local characterList = {}
            
            for _, character in pairs(storage.characters) do
                table.insert(characterList, character)
            end
            
            table.sort(characterList, function(characterA, characterB)
                if(characterA.guid == core.player.guid) then
                    return true
                elseif(characterB.guid == core.player.guid) then
                    return false
                elseif(characterA.name == characterB.name) then
                    return characterA.timestamp < characterB.timestamp
                end
                
                return characterA.name < characterB.name
            end)
            
            --
            
            data.objects = data.objects or {}
            
            local prev = headers
            local tableHeight = 0
            
            --
            
            for index, character in ipairs(characterList) do
                local objects = data.objects[index]
            
                if(objects == nil) then
                    table.insert(data.objects, {
                        ['char'] = data.parent:CreateFontString(nil, 'OVERLAY', 'GameFontHighlightSmall'),
                        ['seen'] = data.parent:CreateFontString(nil, 'OVERLAY', 'GameFontHighlightSmall'),
                        ['background'] = data.parent:CreateTexture(nil, 'ARTWORK'),
                        ['delete'] = ScootsLibOptions.core.insertOptionsButton({
                            ['framename'] = data.framename .. '-Delete-' .. tostring(index),
                            ['parent'] = data.parent,
                            ['width'] = 50,
                            ['text'] = 'Delete',
                            ['callback'] = function(self)
                                utility.deleteAllDataForCharacter(self.guid)
                                data.parent.drawCharacters()
                            
                                if(frames.options.optionPages.profiles and frames.options.optionPages.profiles.drawExistingProfiles) then
                                    frames.options.optionPages.profiles.drawExistingProfiles()
                                end
                            end,
                        }),
                    })
                    
                    objects = data.objects[index]
                    
                    objects.char:SetJustifyH('LEFT')
                    objects.char:SetWidth(headers.char:GetWidth())
                    
                    objects.seen:SetPoint('TOPLEFT', objects.char, 'TOPRIGHT', 4, 0)
                    objects.seen:SetJustifyH('LEFT')
                    objects.seen:SetWidth(headers.seen:GetWidth())
                    
                    objects.background:SetPoint('TOPLEFT', objects.char, 'TOPLEFT', -4, 2)
                    objects.background:SetPoint('BOTTOMLEFT', objects.char, 'BOTTOMLEFT', -4, -2)
                    objects.background:SetWidth(400)
                    objects.background:SetTexture(0.7, 0.7, 1, 0.1)
                    
                    objects.delete:SetPoint('LEFT', objects.seen, 'RIGHT', 4, 0)
                end
                
                objects.char:Show()
                objects.seen:Show()
                objects.delete:Show()
                
                if(index % 2 == 1) then
                    objects.background:Show()
                else
                    objects.background:Hide()
                end
                
                if(character.guid ~= core.player.guid) then
                    objects.seen:SetText(date('%d %B %Y\n%H:%M', character.timestamp):gsub('^0', ''))
                    objects.delete:Show()
                else
                    objects.seen:SetText('Now')
                    objects.delete:Hide()
                end
                
                objects.char:SetPoint('TOPLEFT', prev.char, 'BOTTOMLEFT', 0, -4)
                objects.char:SetText(string.format('%s\nLevel %d %s %s', character.name, character.level, character.race, character.class))
                objects.char:SetHeight(math.max(objects.char:GetHeight(), objects.delete:GetHeight()))
                
                objects.seen:SetHeight(objects.char:GetHeight())
                
                objects.delete.guid = character.guid
                
                height = height + objects.char:GetHeight() + 4
                prev = objects
            end
            
            for index = (#characterList + 1), #data.objects do
                local objects = data.objects[index]
                
                objects.char:Hide()
                objects.seen:Hide()
                objects.background:Hide()
                objects.delete:Hide()
            end
            
            --
            
            return tableHeight
        end
        
        height = height + data.parent.drawCharacters() + 10
        
        --
        
        return autoDeleteOptions, height
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
                ['key'] = 'adjust-for-vehicle',
                ['type'] = 'checkbox',
                ['framename'] = data.framename .. '-LockToVehicle',
                ['label'] = 'Adjust for Blizzard vehicle UI',
                ['tooltip'] = 'When the Blizzard vehicle UI is shown, set an appropriate width/position of the bar to match.',
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
    ['defineTextOptions'] = function(data)
        return {
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
                ['key'] = 'text-outline',
                ['type'] = 'dropdown',
                ['framename'] = data.framename .. '-TextOutline',
                ['label'] = 'Outline',
                ['tooltip'] = '"On-hover" requires that you not have made the bar non-interactive.',
                ['choices'] = {
                    {
                        ['name'] = 'None',
                        ['value'] = nil,
                    },
                    {
                        ['name'] = 'Normal',
                        ['value'] = 'OUTLINE',
                    },
                    {
                        ['name'] = 'Thick',
                        ['value'] = 'THICKOUTLINE',
                    },
                },
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
                ['label'] = 'Alignment',
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
                ['key'] = 'nudge-text-horizontal',
                ['type'] = 'increment-text',
                ['framename'] = data.framename .. '-NudgeTextHorizontal',
                ['label'] = 'Nudge horizontally',
                ['increment'] = 1,
            },
            {
                ['key'] = 'text-vertical-alignment',
                ['type'] = 'choice-slider',
                ['framename'] = data.framename .. '-TextVerticalAlignment',
                ['label'] = 'Vertical alignment',
                ['callbackWhileDragging'] = true,
                ['choices'] = {
                    {
                        ['name'] = 'Bottom',
                        ['value'] = 'BOTTOM',
                    },
                    {
                        ['name'] = 'Middle',
                        ['value'] = 'MIDDLE',
                    },
                    {
                        ['name'] = 'Top',
                        ['value'] = 'TOP',
                    },
                },
            },
            {
                ['key'] = 'nudge-text-vertical',
                ['type'] = 'increment-text',
                ['framename'] = data.framename .. '-NudgeTextVertical',
                ['label'] = 'Nudge vertically',
                ['increment'] = 1,
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
                    {
                        ['name'] = 'FULLSCREEN_DIALOG',
                        ['value'] = 'FULLSCREEN_DIALOG',
                    },
                    {
                        ['name'] = 'TOOLTIP',
                        ['value'] = 'TOOLTIP',
                    },
                },
            },
            {
                ['key'] = 'min-interactive-strata',
                ['type'] = 'choice-slider',
                ['framename'] = data.framename .. '-MinInteractiveStrata',
                ['label'] = 'Minimum interactive strata',
                ['tooltip'] = table.concat({
                    'This option allows you to increase the priority for interacting with the bar without changing how it is displayed.',
                    'If set to a lower value than the "Frame strata" option, that value will be used instead.',
                }, '\n\n'),
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
                    {
                        ['name'] = 'FULLSCREEN_DIALOG',
                        ['value'] = 'FULLSCREEN_DIALOG',
                    },
                    {
                        ['name'] = 'TOOLTIP',
                        ['value'] = 'TOOLTIP',
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
                ['type'] = 'scootsprogressbar-reorder-buttons',
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
    ['processOptionReorderButtons'] = function(pageData, fieldData)
        return options.insertOptionsReorderButtons({
            ['key'] = pageData.key,
            ['framename'] = fieldData.framename,
            ['parent'] = pageData.parent,
            ['label'] = fieldData.label,
            ['size'] = fieldData.size,
            ['callback'] = function()
                core.prepareUpdate('_', fieldData.key)
            end,
        })
    end,
    ['insertOptionsReorderButtons'] = function(data)
        local buttonDown, buttonUp
    
        data.reorderButtonsSetOrder = function(adjust)
            local current = options.get(data.key .. '-order')
            
            if(adjust == 0) then
                if(current == #core.barOrder) then
                    buttonDown:Disable()
                else
                    buttonDown:Enable()
                end
            
                if(current == 1) then
                    buttonUp:Disable()
                else
                    buttonUp:Enable()
                end
                
                return
            end
            
            if(adjust == -1 and current == 1) then
                return
            end
            
            if(adjust == 1 and current == #core.barOrder) then
                return
            end
            
            local found = false
            
            local currentIndex
            for index = 1, #core.barOrder do
                if(core.barOrder[index].key == data.key) then
                    currentIndex = index
                    break
                end
            end
            
            core.barOrder[currentIndex].order = core.barOrder[currentIndex].order + adjust
            options.set(core.barOrder[currentIndex].key .. '-order', core.barOrder[currentIndex].order)
            
            core.barOrder[currentIndex + adjust].order = core.barOrder[currentIndex + adjust].order - adjust
            options.set(core.barOrder[currentIndex + adjust].key .. '-order', core.barOrder[currentIndex + adjust].order)
            
            table.sort(core.barOrder, function(barA, barB)
                return barA.order < barB.order
            end)
            
            data.callback()
            
            options.sortMenuLinks()
            data.reorderButtonsSetOrder(0)
        end
        
        --
        
        buttonDown = CreateFrame('Button', data.framename .. '-OrderUp', data.parent)
        buttonDown:SetSize(data.size or 24, data.size or 24)
        
        buttonDown:SetNormalTexture('Interface\\Buttons\\UI-ScrollBar-ScrollDownButton-Up')
        buttonDown:SetPushedTexture('Interface\\Buttons\\UI-ScrollBar-ScrollDownButton-Down')
        buttonDown:SetDisabledTexture('Interface\\Buttons\\UI-ScrollBar-ScrollDownButton-Disabled')
        buttonDown:SetHighlightTexture('Interface\\Buttons\\UI-Common-MouseHilight', 'ADD')
        
        if(data.label) then
            buttonDown.label = buttonDown:CreateFontString(nil, 'OVERLAY', 'GameFontHighlightSmall')
            buttonDown.label:SetPoint('BOTTOMLEFT', buttonDown, 'TOPLEFT', 0, 0)
            buttonDown.label:SetText(data.label)
        end
        
        buttonDown:SetScript('OnClick', function()
            data.reorderButtonsSetOrder(1)
        end)
    
        --
        
        buttonUp = CreateFrame('Button', data.framename .. '-OrderUp', data.parent)
        buttonUp:SetSize(data.size or 24, data.size or 24)
        buttonUp:SetPoint('LEFT', buttonDown, 'RIGHT', 5, 0)
        
        buttonUp:SetNormalTexture('Interface\\Buttons\\UI-ScrollBar-ScrollUpButton-Up')
        buttonUp:SetPushedTexture('Interface\\Buttons\\UI-ScrollBar-ScrollUpButton-Down')
        buttonUp:SetDisabledTexture('Interface\\Buttons\\UI-ScrollBar-ScrollUpButton-Disabled')
        buttonUp:SetHighlightTexture('Interface\\Buttons\\UI-Common-MouseHilight', 'ADD')
        
        buttonUp:SetScript('OnClick', function()
            data.reorderButtonsSetOrder(-1)
        end)
        
        --
        
        for _, texture in pairs({
            buttonDown:GetNormalTexture(),
            buttonDown:GetPushedTexture(),
            buttonDown:GetDisabledTexture(),
            buttonDown:GetHighlightTexture(),
            buttonUp:GetNormalTexture(),
            buttonUp:GetPushedTexture(),
            buttonUp:GetDisabledTexture(),
            buttonUp:GetHighlightTexture(),
        }) do
            texture:ClearAllPoints()
            texture:SetAllPoints()
            texture:SetTexCoord(0.15, 0.85, 0.15, 0.85)
        end
        
        data.parent:HookScript('OnShow', function()
            data.reorderButtonsSetOrder(0)
        end)
        
        data.reorderButtonsSetOrder(0)
        
        buttonDown.applyExternalValue = function() end
        
        return buttonDown
    end,
}

for funcName, func in pairs(options) do
    ScootsProgressBar.options[funcName] = func
end

options = ScootsProgressBar.options
local storage = ScootsProgressBar.storage
local core = ScootsProgressBar.core
local options
local frames = ScootsProgressBar.frames
local interface = ScootsProgressBar.interface
local utility = ScootsProgressBar.utility
local lookup = ScootsProgressBar.lookup

local NONE_VAL = {}

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
            ['width'] = NONE_VAL,
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
        ['experience'] = {
            ['enabled'] = true,
            ['order'] = 1,
            ['format'] = 'Level {L} - {C} / {M} ({P}%){R: - ({RP}% rested)}',
            ['background-colour'] = {['r'] = 1, ['g'] = 1, ['b'] = 1, ['a'] = 1},
            ['colour'] = {['r'] = 0.58, ['g'] = 0, ['b'] = 0.55, ['a'] = 1},
            ['rested-colour'] = {['r'] = 0, ['g'] = 0.39, ['b'] = 0.88, ['a'] = 1},
            ['pendingrested-colour'] = {['r'] = 0, ['g'] = 0.68, ['b'] = 1, ['a'] = 1},
        },
        ['reputation'] = {
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
        },
        ['equipattune'] = {
            ['enabled'] = true,
            ['order'] = 3,
            ['format'] = 'Attuning {C} item{S} - {P}% (Equipped)',
            ['background-colour'] = {['r'] = 1, ['g'] = 1, ['b'] = 1, ['a'] = 1},
            ['colour'] = {['r'] = 0, ['g'] = 0.55, ['b'] = 0.6, ['a'] = 1},
            ['format-noitems'] = 'Not attuning any equipped items',
        },
        ['bagattune'] = {
            ['enabled'] = false,
            ['order'] = 4,
            ['format'] = 'Attuning {C} item{S} - {P}% (Inventory)',
            ['background-colour'] = {['r'] = 1, ['g'] = 1, ['b'] = 1, ['a'] = 1},
            ['colour'] = {['r'] = 0.35, ['g'] = 0, ['b'] = 0.6, ['a'] = 1},
            ['include-equipped'] = false,
            ['format-noitems'] = 'Not attuning any items in bags',
        },
        ['attunebar'] = {
            ['enabled'] = false,
            ['order'] = 5,
            ['format'] = 'Attuning {C} item{S} - {P}% (Attune bar)',
            ['background-colour'] = {['r'] = 1, ['g'] = 1, ['b'] = 1, ['a'] = 1},
            ['colour'] = {['r'] = 0.55, ['g'] = 0.3, ['b'] = 0.1, ['a'] = 1},
            ['format-nounlock'] = 'You have not yet unlocked the Attune Bar',
            ['format-noitems'] = 'Not attuning any items on the Attune Bar',
        },
        ['charattunes'] = {
            ['enabled'] = true,
            ['order'] = 6,
            ['format'] = 'Character Attunes - {C} / {M} ({P}%)',
            ['background-colour'] = {['r'] = 1, ['g'] = 1, ['b'] = 1, ['a'] = 1},
            ['colour'] = {['r'] = 0.3, ['g'] = 0.45, ['b'] = 0.6, ['a'] = 1},
            ['colour'] = {['r'] = 0.55, ['g'] = 0.3, ['b'] = 0.1, ['a'] = 1},
            ['colour'] = {['r'] = 0.35, ['g'] = 0, ['b'] = 0.6, ['a'] = 1},
            ['colour'] = {['r'] = 0, ['g'] = 0.55, ['b'] = 0.6, ['a'] = 1},
        },
        ['accattunes'] = {
            ['enabled'] = false,
            ['order'] = 7,
            ['format'] = 'Account Attunes - {C} / {M} ({P}%)',
            ['background-colour'] = {['r'] = 1, ['g'] = 1, ['b'] = 1, ['a'] = 1},
            ['colour'] = {['r'] = 0.95, ['g'] = 0.7, ['b'] = 0.8, ['a'] = 1},
        },
        ['affixattunes'] = {
            ['enabled'] = false,
            ['order'] = 8,
            ['format'] = 'Affix Attunes - {C} / {M} ({P}%)',
            ['background-colour'] = {['r'] = 1, ['g'] = 1, ['b'] = 1, ['a'] = 1},
            ['colour'] = {['r'] = 0.4, ['g'] = 0.45, ['b'] = 0.5, ['a'] = 1},
        },
        ['zoneattunes'] = {
            ['enabled'] = true,
            ['order'] = 9,
            ['format'] = 'Zone Attunes - {C} / {M} ({P}%)',
            ['background-colour'] = {['r'] = 1, ['g'] = 1, ['b'] = 1, ['a'] = 1},
            ['colour'] = {['r'] = 0.4, ['g'] = 0.95, ['b'] = 0.8, ['a'] = 1},
            ['min-chance'] = 0.001,
        },
        ['questtoken'] = {
            ['enabled'] = false,
            ['order'] = 10,
            ['format'] = 'Quest Auto-Complete Token - {C} / {M}',
            ['background-colour'] = {['r'] = 1, ['g'] = 1, ['b'] = 1, ['a'] = 1},
            ['colour'] = {['r'] = 0.9, ['g'] = 0.8, ['b'] = 0.5, ['a'] = 1},
        },
        ['currency'] = {
            ['enabled'] = false,
            ['order'] = 11,
            ['format'] = '{N} - {C} / {M} ({P}%)',
            ['background-colour'] = {['r'] = 1, ['g'] = 1, ['b'] = 1, ['a'] = 1},
            ['colour'] = {['r'] = 0.55, ['g'] = 0, ['b'] = 0.15, ['a'] = 1},
            ['id'] = NONE_VAL,
            ['target'] = 100,
            ['toast-on-reach-target'] = false,
            ['chat-on-reach-target'] = false,
            ['format-noselected'] = 'No currency selected',
        },
        ['items'] = {
            ['enabled'] = false,
            ['order'] = 12,
            ['format'] = '{N} - {C} / {M} ({P}%)',
            ['background-colour'] = {['r'] = 1, ['g'] = 1, ['b'] = 1, ['a'] = 1},
            ['colour'] = {['r'] = 0.8, ['g'] = 0.45, ['b'] = 0.2, ['a'] = 1},
            ['id'] = NONE_VAL,
            ['target'] = 100,
            ['include-bank'] = false,
            ['toast-on-reach-target'] = false,
            ['chat-on-reach-target'] = false,
            ['format-noselected'] = 'No item selected',
        },
        ['dailyattunes'] = {
            ['enabled'] = false,
            ['order'] = 13,
            ['format'] = 'Daily attunes - {C} / {M} ({P}%)',
            ['background-colour'] = {['r'] = 1, ['g'] = 1, ['b'] = 1, ['a'] = 1},
            ['colour'] = {['r'] = 0.05, ['g'] = 0.10, ['b'] = 0.20, ['a'] = 1},
            ['target'] = 100,
            ['toast-on-reach-target'] = false,
            ['chat-on-reach-target'] = false,
            ['char-or-acc'] = 'char',
            ['count-affixes'] = true,
        },
        ['instancecap'] = {
            ['enabled'] = false,
            ['order'] = 14,
            ['format'] = 'Instances available - {C} / {M}',
            ['background-colour'] = {['r'] = 1, ['g'] = 1, ['b'] = 1, ['a'] = 1},
            ['colour'] = {['r'] = 0.75, ['g'] = 0.65, ['b'] = 0.95, ['a'] = 1},
        },
        ['bagspace'] = {
            ['enabled'] = false,
            ['order'] = 15,
            ['format'] = 'Free bag space - {C} / {M}',
            ['background-colour'] = {['r'] = 1, ['g'] = 1, ['b'] = 1, ['a'] = 1},
            ['colour'] = {['r'] = 0.55, ['g'] = 0.38, ['b'] = 0.18, ['a'] = 1},
        },
        ['wintergrasp'] = {
            ['enabled'] = false,
            ['order'] = 16,
            ['format'] = 'Wintergrasp{U} - {C}',
            ['background-colour'] = {['r'] = 1, ['g'] = 1, ['b'] = 1, ['a'] = 1},
            ['colour'] = {['r'] = 0.55, ['g'] = 0.55, ['b'] = 0.20, ['a'] = 1},
            ['inprogress-colour'] = {['r'] = 0.4675, ['g'] = 0.4675, ['b'] = 0.17, ['a'] = 1},
            ['format-inprogress'] = 'In progress',
        },
        ['dungeonchallenge'] = {
            ['enabled'] = false,
            ['order'] = 17,
            ['format'] = 'Dungeon challenge - {C} / {M}',
            ['background-colour'] = {['r'] = 1, ['g'] = 1, ['b'] = 1, ['a'] = 1},
            ['colour'] = {['r'] = 0.05, ['g'] = 0.25, ['b'] = 0.22, ['a'] = 1},
            ['format-noactive'] = 'No dungeon challenge active',
            ['format-failed'] = 'Challenge failed',
        },
        ['dungeonspeedrun'] = {
            ['enabled'] = false,
            ['order'] = 18,
            ['format'] = 'Dungeon speedrun - {C} / {M} ({P}%)',
            ['background-colour'] = {['r'] = 1, ['g'] = 1, ['b'] = 1, ['a'] = 1},
            ['colour'] = {['r'] = 0.35, ['g'] = 0.2, ['b'] = 0.85, ['a'] = 1},
            ['success-colour'] = {['r'] = 0.0, ['g'] = 0.75, ['b'] = 0.35, ['a'] = 1},
            ['failed-colour'] = {['r'] = 0.85, ['g'] = 0.1, ['b'] = 0.2, ['a'] = 1},
            ['format-noactive'] = 'No speed challenge active',
        },
        ['freetimer'] = {
            ['enabled'] = false,
            ['order'] = 19,
            ['format'] = 'Timer - {C} / {M}',
            ['background-colour'] = {['r'] = 1, ['g'] = 1, ['b'] = 1, ['a'] = 1},
            ['colour'] = {['r'] = 0.90, ['g'] = 0.82, ['b'] = 0.65, ['a'] = 1},
            ['finished-colour'] = {['r'] = 0.35, ['g'] = 0.05, ['b'] = 0.25, ['a'] = 1},
            ['hours'] = 0,
            ['minutes'] = 1,
            ['seconds'] = 0,
            ['toast-on-end'] = false,
            ['chat-on-end'] = false,
            ['format-noset'] = 'No timer set',
            ['format-finished'] = 'Timer finished',
        },
    },
    ['mimicBlizzardDefaultCategories'] = {
        ['general'] = {
            ['mode'] = 'single',
            ['hide-blizzard'] = true,
            ['re-anchor-stance-bar'] = true,
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
                    
                    if(value == NONE_VAL) then
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
    ['getOptionPageDefinitions'] = function()
        local output = {
            ['general'] = {
                ['framename'] = 'ScootsProgressBar-Options-General',
                ['title'] = 'General Options',
                ['description'] = nil,
                ['callback'] = options.defineGeneralOptions,
            },
            ['position'] = {
                ['framename'] = 'ScootsProgressBar-Options-Position',
                ['title'] = 'Position Options',
                ['description'] = nil,
                ['callback'] = options.definePositionOptions,
            },
            ['appearance'] = {
                ['framename'] = 'ScootsProgressBar-Options-Appearance',
                ['title'] = 'Appearance Options',
                ['description'] = nil,
                ['callback'] = options.defineAppearanceOptions,
            },
            ['profiles'] = {
                ['framename'] = 'ScootsProgressBar-Options-Profiles',
                ['title'] = 'Manage profiles',
                ['description'] = 'Profiles allow you to have different options on different characters.',
                ['special'] = 'profiles',
            },
            ['data'] = {
                ['framename'] = 'ScootsProgressBar-Options-Data',
                ['title'] = 'Manage data',
                ['special'] = 'data',
            },
            ['experience'] = {
                ['framename'] = 'ScootsProgressBar-Options-Experience',
                ['title'] = 'Experience',
                ['description'] = 'Progress towards next level-up.',
                ['callback'] = options.defineExperienceOptions,
            },
            ['reputation'] = {
                ['framename'] = 'ScootsProgressBar-Options-Reputation',
                ['title'] = 'Tracked Reputation',
                ['description'] = 'Progress towards the next reputational standing with your tracked faction.',
                ['callback'] = options.defineReputationOptions,
            },
            ['equipattune'] = {
                ['framename'] = 'ScootsProgressBar-Options-EquipAttune',
                ['title'] = 'Equipped Attunement',
                ['description'] = 'Progress towards attuning all equipped items.',
                ['callback'] = options.defineEquipAttuneOptions,
            },
            ['bagattune'] = {
                ['framename'] = 'ScootsProgressBar-Options-BagAttune',
                ['title'] = 'Inventory Attunement',
                ['description'] = 'Progress towards attuning all items in your inventory.',
                ['callback'] = options.defineBagAttuneOptions,
                ['skip'] = (not ScootsProgressBar.prestiged),
            },
            ['attunebar'] = {
                ['framename'] = 'ScootsProgressBar-Options-AttuneBar',
                ['title'] = 'Attune Bar',
                ['description'] = 'Progress towards attuning items in the Attune Bar.',
                ['callback'] = options.defineAttuneBarOptions,
            },
            ['charattunes'] = {
                ['framename'] = 'ScootsProgressBar-Options-CharacterAttunes',
                ['title'] = 'Character Attunes',
                ['description'] = 'Progress towards attuning all items useable by your character.',
                ['callback'] = options.defineStandardOptions,
            },
            ['accattunes'] = {
                ['framename'] = 'ScootsProgressBar-Options-AccountAttunes',
                ['title'] = 'Account Attunes',
                ['description'] = 'Progress towards attuning all items in the game.',
                ['callback'] = options.defineStandardOptions,
            },
            ['affixattunes'] = {
                ['framename'] = 'ScootsProgressBar-Options-AffixAttunes',
                ['title'] = 'Affix Attunes',
                ['description'] = 'Progress towards attuning all affixes in the game.',
                ['callback'] = options.defineAffixAttunesOptions,
            },
            ['zoneattunes'] = {
                ['framename'] = 'ScootsProgressBar-Options-ZoneAttunes',
                ['title'] = 'Zone Attunes',
                ['description'] = 'Progress towards attuning all items sourced from the current zone.',
                ['callback'] = options.defineZoneAttuneOptions,
                ['skip'] = (not ScootsProgressBar.itemDBLoaded),
            },
            ['questtoken'] = {
                ['framename'] = 'ScootsProgressBar-Options-QuestToken',
                ['title'] = 'Quest Token',
                ['description'] = 'Progress towards getting a Quest Auto-Complete Token. Requires Loremaster achievement.',
                ['callback'] = options.defineStandardOptions,
            },
            ['currency'] = {
                ['framename'] = 'ScootsProgressBar-Options-Currency',
                ['title'] = 'Currency',
                ['description'] = 'Progress towards getting a certain quantity of a currency.',
                ['callback'] = options.defineCurrencyOptions,
            },
            ['items'] = {
                ['framename'] = 'ScootsProgressBar-Options-Items',
                ['title'] = 'Items',
                ['description'] = 'Progress towards getting a certain quantity of an item.',
                ['callback'] = options.defineItemsOptions,
            },
            ['dailyattunes'] = {
                ['framename'] = 'ScootsProgressBar-Options-DailyAttunes',
                ['title'] = 'Daily Attunes',
                ['description'] = 'Progress towards a daily goal of attunes.',
                ['callback'] = options.defineDailyAttunesOptions,
            },
            ['instancecap'] = {
                ['framename'] = 'ScootsProgressBar-Options-InstanceCap',
                ['title'] = 'Instance Cap',
                ['description'] = 'How many instances you have available to enter.',
                ['callback'] = options.defineStandardOptions,
            },
            ['bagspace'] = {
                ['framename'] = 'ScootsProgressBar-Options-BagSpace',
                ['title'] = 'Bag Space',
                ['description'] = 'How many bag slots you have remaining.',
                ['callback'] = options.defineStandardOptions,
            },
            ['wintergrasp'] = {
                ['framename'] = 'ScootsProgressBar-Options-Wintergrasp',
                ['title'] = 'Wintergrasp',
                ['description'] = 'Time until the next Wintergrasp.\n\nYou need to visit the overworld while Wintergrasp is not in-progress to get a timer, and need to have done so since the last battle for the timer to not be considered "uncertain".',
                ['callback'] = options.defineWintergraspOptions,
            },
            ['dungeonchallenge'] = {
                ['framename'] = 'ScootsProgressBar-Options-DungeonChallenge',
                ['title'] = 'Dungeon Challenge',
                ['description'] = 'Progress towards completing the current dungeon challenge.',
                ['callback'] = options.defineDungeonChallengeOptions,
            },
            ['dungeonspeedrun'] = {
                ['framename'] = 'ScootsProgressBar-Options-DungeonSpeedrun',
                ['title'] = 'Dungeon Speedrun',
                ['description'] = 'Time left to improve your fastest run of a dungeon.',
                ['callback'] = options.defineDungeonSpeedrunOptions,
            },
            ['freetimer'] = {
                ['framename'] = 'ScootsProgressBar-Options-FreeTimer',
                ['title'] = 'Free Timer',
                ['description'] = 'A timer you can set to whatever you like. (Re)start the timer by shift-left-clicking on the bar, stop the timer by shift-right-clicking on the bar.',
                ['callback'] = options.defineFreeTimerOptions,
            },
        }
        
        output.data.description = string.format(
            '%s persistantly stores some per-character data for certain bars (%s, %s, and %s for example).',
            ScootsProgressBar.title,
            output.items.title,
            output.dailyattunes.title,
            output.instancecap.title
        )
        
        return output
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
    ['defineExperienceOptions'] = function(data)
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
                ['key'] = data.key .. '-rested-colour',
                ['type'] = 'colour',
                ['framename'] = data.framename .. '-ColourPicker-Rested',
                ['text'] = 'Rested colour',
            },
            {
                ['key'] = data.key .. '-pendingrested-colour',
                ['type'] = 'colour',
                ['framename'] = data.framename .. '-ColourPicker-PendingRested',
                ['text'] = 'Pending rested colour',
            },
        }) do
            table.insert(fields, field)
        end
    
        return fields
    end,
    ['defineReputationOptions'] = function(data)
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
                ['key'] = data.key .. '-exalted-colour',
                ['type'] = 'colour',
                ['framename'] = data.framename .. '-ColourPicker-Exalted',
                ['text'] = 'Exalted colour',
            },
            {
                ['key'] = data.key .. '-revered-colour',
                ['type'] = 'colour',
                ['framename'] = data.framename .. '-ColourPicker-Revered',
                ['text'] = 'Revered colour',
            },
            {
                ['key'] = data.key .. '-honoured-colour',
                ['type'] = 'colour',
                ['framename'] = data.framename .. '-ColourPicker-Honoured',
                ['text'] = 'Honoured colour',
            },
            {
                ['key'] = data.key .. '-friendly-colour',
                ['type'] = 'colour',
                ['framename'] = data.framename .. '-ColourPicker-Friendly',
                ['text'] = 'Friendly colour',
            },
            {
                ['key'] = data.key .. '-neutral-colour',
                ['type'] = 'colour',
                ['framename'] = data.framename .. '-ColourPicker-Neutral',
                ['text'] = 'Neutral colour',
            },
            {
                ['key'] = data.key .. '-unfriendly-colour',
                ['type'] = 'colour',
                ['framename'] = data.framename .. '-ColourPicker-Unfriendly',
                ['text'] = 'Unfriendly colour',
            },
            {
                ['key'] = data.key .. '-hostile-colour',
                ['type'] = 'colour',
                ['framename'] = data.framename .. '-ColourPicker-Hostile',
                ['text'] = 'Hostile colour',
            },
            {
                ['key'] = data.key .. '-hated-colour',
                ['type'] = 'colour',
                ['framename'] = data.framename .. '-ColourPicker-Hated',
                ['text'] = 'Hated colour',
            },
            {
                ['key'] = data.key .. '-follow-tracked',
                ['type'] = 'checkbox',
                ['framename'] = data.framename .. '-FollowTracked',
                ['label'] = 'Follow tracked reputation state',
                ['tooltip'] = 'When checked, this bar will automatically enable / disable itself when you track / untrack a reputation.',
            },
        }) do
            table.insert(fields, field)
        end
        
        return fields
    end,
    ['defineEquipAttuneOptions'] = function(data)
        local fields = options.defineStandardOptions(data, {
            ['formatHint'] = {
                {'{C}', 'Item count'},
                {'{P}', 'Percent progress'},
                {'{S}', 's (plural)'},
            }
        })
        
        table.insert(fields, {
            ['key'] = data.key .. '-format-noitems',
            ['type'] = 'reset-text',
            ['framename'] = data.framename .. '-FormatNoItems',
            ['label'] = 'Text when no items',
            ['resetValue'] = options.defaults[data.key .. '-format-noitems'],
            ['resetText'] = 'Apply default',
            ['width'] = 250,
        })
        
        return fields
    end,
    ['defineBagAttuneOptions'] = function(data)
        local fields = options.defineStandardOptions(data, {
            ['formatHint'] = {
                {'{C}', 'Item count'},
                {'{P}', 'Percent progress'},
                {'{S}', 's (plural)'},
            }
        })
        
        for _, field in ipairs({
            {
                ['key'] = data.key .. '-include-equipped',
                ['type'] = 'checkbox',
                ['framename'] = data.framename .. '-IncludeEquipped',
                ['label'] = 'Include equipped items',
            },
            {
                ['key'] = data.key .. '-format-noitems',
                ['type'] = 'reset-text',
                ['framename'] = data.framename .. '-FormatNoItems',
                ['label'] = 'Text when no items',
                ['resetValue'] = options.defaults[data.key .. '-format-noitems'],
                ['resetText'] = 'Apply default',
                ['width'] = 250,
            },
        }) do
            table.insert(fields, field)
        end
    
        return fields
    end,
    ['defineAttuneBarOptions'] = function(data)
        local fields = options.defineStandardOptions(data, {
            ['formatHint'] = {
                {'{C}', 'Item count'},
                {'{P}', 'Percent progress'},
                {'{S}', 's (plural)'},
            }
        })
        
        for _, field in ipairs({
            {
                ['key'] = data.key .. '-format-nounlock',
                ['type'] = 'reset-text',
                ['framename'] = data.framename .. '-FormatNoUnlocked',
                ['label'] = 'Text when bar not unlocked',
                ['resetValue'] = options.defaults[data.key .. '-format-nounlock'],
                ['resetText'] = 'Apply default',
                ['width'] = 250,
            },
            {
                ['key'] = data.key .. '-format-noitems',
                ['type'] = 'reset-text',
                ['framename'] = data.framename .. '-FormatNoItems',
                ['label'] = 'Text when no items',
                ['resetValue'] = options.defaults[data.key .. '-format-noitems'],
                ['resetText'] = 'Apply default',
                ['width'] = 250,
            },
        }) do
            table.insert(fields, field)
        end
        
        return fields
    end,
    ['defineAffixAttunesOptions'] = function(data)
        local fields = options.defineStandardOptions(data, {
            ['formatHint'] = {
                {'{C}', 'Current amount'},
                {'{M}', 'Max amount'},
                {'{P}', 'Percent progress'},
                {'{S}', 'es (plural)'},
            },
        })
        
        return fields
    end,
    ['defineZoneAttuneOptions'] = function(data)
        local fields = options.defineStandardOptions(data)
        
        table.insert(fields, {
            ['key'] = data.key .. '-min-chance',
            ['framename'] = data.framename .. '-MinChance',
            ['type'] = 'range-slider',
            ['parent'] = data.parent,
            ['label'] = 'Minimum drop chance %',
            ['increment'] = 0.001,
            ['min'] = 0,
            ['max'] = 100,
        })
        
        return fields
    end,
    ['defineCurrencyOptions'] = function(data)
        local fields = options.defineStandardOptions(data, {
            ['formatHint'] = {
                {'{N}', 'Currency name'},
                {'{C}', 'Current amount'},
                {'{M}', 'Max amount'},
                {'{P}', 'Percent progress'},
            },
        })
        
        for _, field in ipairs({
            {
                ['key'] = data.key .. '-target',
                ['type'] = 'increment-text',
                ['framename'] = data.framename .. '-TargetQuantity',
                ['label'] = 'Target quantity',
                ['increment'] = 1,
                ['min'] = 1,
                ['width'] = 70,
            },
            {
                ['key'] = data.key .. '-id',
                ['type'] = 'currency-picker',
                ['framename'] = data.framename .. '-CurrencySelect',
                ['label'] = 'Select currency',
            },
            {
                ['key'] = data.key .. '-toast-on-reach-target',
                ['type'] = 'checkbox',
                ['framename'] = data.framename .. '-ToastOnGoal',
                ['label'] = 'Toast on reaching target',
                ['tooltip'] = 'Displays a message in the centre of the screen when you reach your target quantity.',
            },
            {
                ['key'] = data.key .. '-chat-on-reach-target',
                ['type'] = 'checkbox',
                ['framename'] = data.framename .. '-ChatOnGoal',
                ['label'] = 'Chat message on reaching target',
                ['tooltip'] = 'Displays a message in the chat when you reach your target quantity.',
            },
            {
                ['key'] = data.key .. '-format-noselected',
                ['type'] = 'reset-text',
                ['framename'] = data.framename .. '-FormatNoSelected',
                ['label'] = 'Text when no selected currency',
                ['resetValue'] = options.defaults[data.key .. '-format-noselected'],
                ['resetText'] = 'Apply default',
                ['width'] = 250,
            },
        }) do
            table.insert(fields, field)
        end
    
        return fields
    end,
    ['defineItemsOptions'] = function(data)
        local fields = options.defineStandardOptions(data, {
            ['formatHint'] = {
                {'{N}', 'Item name'},
                {'{C}', 'Current amount'},
                {'{M}', 'Max amount'},
                {'{P}', 'Percent progress'},
            },
        })
        
        for _, field in ipairs({
            {
                ['key'] = data.key .. '-target',
                ['type'] = 'increment-text',
                ['framename'] = data.framename .. '-TargetQuantity',
                ['label'] = 'Target quantity',
                ['increment'] = 1,
                ['min'] = 1,
                ['width'] = 70,
            },
            {
                ['key'] = data.key .. '-id',
                ['type'] = 'item-picker',
                ['framename'] = data.framename .. '-ItemSelect',
                ['label'] = 'Choose item',
            },
            {
                ['key'] = data.key .. '-include-bank',
                ['type'] = 'checkbox',
                ['framename'] = data.framename .. '-IncludeBank',
                ['label'] = 'Include bank',
                ['tooltip'] = 'Includes items in your bank for your current count.\n\nYou must have visited the bank with this addon enabled for it to know the contents of your bank.',
            },
            {
                ['key'] = data.key .. '-toast-on-reach-target',
                ['type'] = 'checkbox',
                ['framename'] = data.framename .. '-ToastOnGoal',
                ['label'] = 'Toast on reaching target',
                ['tooltip'] = 'Displays a message in the centre of the screen when you reach your target quantity.',
            },
            {
                ['key'] = data.key .. '-chat-on-reach-target',
                ['type'] = 'checkbox',
                ['framename'] = data.framename .. '-ChatOnGoal',
                ['label'] = 'Chat message on reaching target',
                ['tooltip'] = 'Displays a message in the chat when you reach your target quantity.',
            },
            {
                ['key'] = data.key .. '-format-noselected',
                ['type'] = 'reset-text',
                ['framename'] = data.framename .. '-FormatNoSelected',
                ['label'] = 'Text when no selected item',
                ['resetValue'] = options.defaults[data.key .. '-format-noselected'],
                ['resetText'] = 'Apply default',
                ['width'] = 250,
            },
        }) do
            table.insert(fields, field)
        end
    
        return fields
    end,
    ['defineDailyAttunesOptions'] = function(data)
        local fields = options.defineStandardOptions(data)
        
        for _, field in ipairs({
            {
                ['key'] = data.key .. '-target',
                ['type'] = 'increment-text',
                ['framename'] = data.framename .. '-TargetQuantity',
                ['label'] = 'Target quantity',
                ['increment'] = 1,
                ['min'] = 1,
                ['width'] = 70,
            },
            {
                ['key'] = data.key .. '-toast-on-reach-target',
                ['type'] = 'checkbox',
                ['framename'] = data.framename .. '-ToastOnGoal',
                ['label'] = 'Toast on reaching target',
                ['tooltip'] = 'Displays a message in the centre of the screen when you reach your target quantity.',
            },
            {
                ['key'] = data.key .. '-chat-on-reach-target',
                ['type'] = 'checkbox',
                ['framename'] = data.framename .. '-ChatOnGoal',
                ['label'] = 'Chat message on reaching target',
                ['tooltip'] = 'Displays a message in the chat when you reach your target quantity.',
            },
            {
                ['key'] = data.key .. '-char-or-acc',
                ['type'] = 'dropdown',
                ['framename'] = data.framename .. '-CharOrAcc',
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
                ['key'] = data.key .. '-count-affixes',
                ['type'] = 'checkbox',
                ['framename'] = data.framename .. '-CountAffixes',
                ['label'] = 'Include extra affixes for already-attuned items',
            },
        }) do
            table.insert(fields, field)
        end
        
        return fields
    end,
    ['defineWintergraspOptions'] = function(data)
        local fields = options.defineStandardOptions(data, {
            ['formatHint'] = {
                {'{C}', 'Current timer'},
                {'{M}', 'Max timer'},
                {'{P}', 'Percent progress'},
                {'{U}', ' (Uncertain)'},
            },
        })
        
        for _, field in ipairs({
            {
                ['key'] = data.key .. '-inprogress-colour',
                ['type'] = 'colour',
                ['framename'] = data.framename .. '-ColourPicker-InProgress',
                ['text'] = 'In-progress colour',
            },
            {
                ['key'] = data.key .. '-format-inprogress',
                ['type'] = 'reset-text',
                ['framename'] = data.framename .. '-FormatInProgress',
                ['label'] = 'Text when in progress',
                ['resetValue'] = options.defaults[data.key .. '-format-inprogress'],
                ['resetText'] = 'Apply default',
                ['width'] = 250,
            },
        }) do
            table.insert(fields, field)
        end
        
        return fields
    end,
    ['defineDungeonChallengeOptions'] = function(data)
        local fields = options.defineStandardOptions(data)
        
        for _, field in ipairs({
            {
                ['key'] = data.key .. '-format-noactive',
                ['type'] = 'reset-text',
                ['framename'] = data.framename .. '-FormatNoActive',
                ['label'] = 'Text when no challenge in progress',
                ['resetValue'] = options.defaults[data.key .. '-format-noactive'],
                ['resetText'] = 'Apply default',
                ['width'] = 250,
            },
            {
                ['key'] = data.key .. '-format-failed',
                ['type'] = 'reset-text',
                ['framename'] = data.framename .. '-FormatFailed',
                ['label'] = 'Text when challenge failed',
                ['resetValue'] = options.defaults[data.key .. '-format-failed'],
                ['resetText'] = 'Apply default',
                ['width'] = 250,
            },
        }) do
            table.insert(fields, field)
        end
        
        return fields
    end,
    ['defineDungeonSpeedrunOptions'] = function(data)
        local fields = options.defineStandardOptions(data, {
            ['formatHint'] = {
                {'{C}', 'Current timer'},
                {'{M}', 'Max timer'},
                {'{P}', 'Percent progress'},
            },
        })
        
        for _, field in ipairs({
            {
                ['key'] = data.key .. '-success-colour',
                ['type'] = 'colour',
                ['framename'] = data.framename .. '-ColourPicker-Success',
                ['text'] = 'Success colour',
            },
            {
                ['key'] = data.key .. '-failed-colour',
                ['type'] = 'colour',
                ['framename'] = data.framename .. '-ColourPicker-Failed',
                ['text'] = 'Failed colour',
            },
            {
                ['key'] = data.key .. '-format-noactive',
                ['type'] = 'reset-text',
                ['framename'] = data.framename .. '-FormatNoActive',
                ['label'] = 'Text when no speedrun in progress',
                ['resetValue'] = options.defaults[data.key .. '-format-noactive'],
                ['resetText'] = 'Apply default',
                ['width'] = 250,
            },
        }) do
            table.insert(fields, field)
        end
        
        return fields
    end,
    ['defineFreeTimerOptions'] = function(data)
        local fields = options.defineStandardOptions(data, {
            ['formatHint'] = {
                {'{C}', 'Current timer'},
                {'{M}', 'Max timer'},
                {'{P}', 'Percent progress'},
            },
        })
        
        for _, field in ipairs({
            {
                ['key'] = data.key .. '-finished-colour',
                ['type'] = 'colour',
                ['framename'] = data.framename .. '-ColourPicker-Finished',
                ['text'] = 'Finished colour',
            },
            {
                ['key'] = data.key .. '-hours',
                ['type'] = 'increment-text',
                ['framename'] = data.framename .. '-Hours',
                ['label'] = 'Hours',
                ['increment'] = 1,
                ['min'] = 0,
                ['width'] = 40,
            },
            {
                ['key'] = data.key .. '-minutes',
                ['type'] = 'increment-text',
                ['framename'] = data.framename .. '-Minutes',
                ['label'] = 'Minutes',
                ['increment'] = 1,
                ['min'] = 0,
                ['max'] = 59,
                ['width'] = 40,
            },
            {
                ['key'] = data.key .. '-seconds',
                ['type'] = 'increment-text',
                ['framename'] = data.framename .. '-Seconds',
                ['label'] = 'Seconds',
                ['increment'] = 1,
                ['min'] = 0,
                ['max'] = 59,
                ['width'] = 40,
            },
            {
                ['key'] = data.key .. '-toast-on-end',
                ['type'] = 'checkbox',
                ['framename'] = data.framename .. '-ToastOnEnd',
                ['label'] = 'Toast on reaching target',
                ['tooltip'] = 'Displays a message in the centre of the screen when the timer ends.',
            },
            {
                ['key'] = data.key .. '-chat-on-end',
                ['type'] = 'checkbox',
                ['framename'] = data.framename .. '-ChatOnEnd',
                ['label'] = 'Chat message on reaching target',
                ['tooltip'] = 'Displays a message in the chat when the timer ends.',
            },
            {
                ['key'] = data.key .. '-format-noset',
                ['type'] = 'reset-text',
                ['framename'] = data.framename .. '-FormatNoSet',
                ['label'] = 'Text when no timer set',
                ['resetValue'] = options.defaults[data.key .. '-format-noset'],
                ['resetText'] = 'Apply default',
                ['width'] = 250,
            },
            {
                ['key'] = data.key .. '-format-finished',
                ['type'] = 'reset-text',
                ['framename'] = data.framename .. '-FormatFinished',
                ['label'] = 'Text when timer finished',
                ['resetValue'] = options.defaults[data.key .. '-format-finished'],
                ['resetText'] = 'Apply default',
                ['width'] = 250,
            },
            {
                ['key'] = 'start-timer',
                ['type'] = 'button',
                ['framename'] = data.framename .. '-StartTimer',
                ['width'] = 120,
                ['text'] = 'Start timer',
                ['callback'] = function()
                    core.startTimer()
                end,
            },
            {
                ['key'] = 'stop-timer',
                ['type'] = 'button',
                ['framename'] = data.framename .. '-StopTimer',
                ['width'] = 120,
                ['text'] = 'Stop timer',
                ['callback'] = function()
                    core.stopTimer()
                end,
            },
        }) do
            table.insert(fields, field)
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
local storage = ScootsProgressBar.storage
local core = ScootsProgressBar.core
local options = ScootsProgressBar.options
local frames = ScootsProgressBar.frames
local interface = ScootsProgressBar.interface
local utility = ScootsProgressBar.utility
local lookup = ScootsProgressBar.lookup

local key = 'charattunes'

--============--
----- CORE -----
--============--

core.definedBars[key] = 'Character attunes'

core.barEvents[key] = {
    'SYNASTRIA_ITEM_ATTUNED',
}

core.updateFunctionMap[key] = function()
    return core.setValuesForAttuneCounts(key, CalculateAttunedCount(1), lookup.maxAttunes.character)
end

--===========--
--- OPTIONS ---
--===========--

options.defaultCategories[key] = {
    ['enabled'] = true,
    ['order'] = 6,
    ['format'] = 'Character Attunes - {C} / {M} ({P}%)',
    ['background-colour'] = {['r'] = 1, ['g'] = 1, ['b'] = 1, ['a'] = 1},
    ['colour'] = {['r'] = 0.3, ['g'] = 0.45, ['b'] = 0.6, ['a'] = 1},
}

options.optionPageDefinitions[key] = {
    ['framename'] = 'ScootsProgressBar-Options-CharacterAttunes',
    ['description'] = 'Progress towards attuning all items useable by your character.',
    ['callback'] = options.defineStandardOptions,
}
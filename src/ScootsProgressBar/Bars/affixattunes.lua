local storage = ScootsProgressBar.storage
local core = ScootsProgressBar.core
local options = ScootsProgressBar.options
local frames = ScootsProgressBar.frames
local interface = ScootsProgressBar.interface
local utility = ScootsProgressBar.utility
local lookup = ScootsProgressBar.lookup

local key = 'affixattunes'

--============--
----- CORE -----
--============--

core.definedBars[key] = 'Affix attunes'

core.barEvents[key] = {
    'SYNASTRIA_ITEM_ATTUNED',
}

core.updateFunctionMap[key] = function()
    return core.setValuesForAttuneCounts(key, CalculateAttunedAffixCount(), lookup.maxAttunes.affixes)
end

--===========--
--- OPTIONS ---
--===========--

options.defaultCategories[key] = {
    ['enabled'] = false,
    ['order'] = 8,
    ['format'] = 'Affix Attunes - {C} / {M} ({P}%)',
    ['background-colour'] = {['r'] = 1, ['g'] = 1, ['b'] = 1, ['a'] = 1},
    ['colour'] = {['r'] = 0.4, ['g'] = 0.45, ['b'] = 0.5, ['a'] = 1},
}

options.optionPageDefinitions[key] = {
    ['framename'] = 'AffixAttunes',
    ['title'] = core.definedBars[key],
    ['description'] = 'Progress towards attuning all affixes in the game.',
    ['callback'] = options.defineStandardOptions,
}
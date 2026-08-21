local storage = ScootsProgressBar.storage
local core = ScootsProgressBar.core
local options = ScootsProgressBar.options
local frames = ScootsProgressBar.frames
local interface = ScootsProgressBar.interface
local utility = ScootsProgressBar.utility
local lookup = ScootsProgressBar.lookup

local key = 'accattunes'

--============--
----- CORE -----
--============--

core.definedBars[key] = 'Account attunes'

core.barEvents[key] = {
    'SYNASTRIA_ITEM_ATTUNED',
}

core.updateFunctionMap[key] = function()
    return core.setValuesForAttuneCounts(key, CalculateAttunedCount(), lookup.maxAttunes.account)
end

--===========--
--- OPTIONS ---
--===========--

options.defaultCategories[key] = {
    ['enabled'] = false,
    ['order'] = 7,
    ['format'] = 'Account Attunes - {C} / {M} ({P}%)',
    ['background-colour'] = {['r'] = 1, ['g'] = 1, ['b'] = 1, ['a'] = 1},
    ['colour'] = {['r'] = 0.95, ['g'] = 0.7, ['b'] = 0.8, ['a'] = 1},
}

options.optionPageDefinitions[key] = {
    ['framename'] = 'ScootsProgressBar-Options-AccountAttunes',
    ['description'] = 'Progress towards attuning all items in the game.',
    ['callback'] = options.defineStandardOptions,
}
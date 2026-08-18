local lookup = {
    ['dungeonChallenges'] = {
        -- Vanilla
        [2437] = {4, false}, -- Ragefire Chasm
        [1581] = {7, false}, -- Deadmines
        [718] = {8, false}, -- Wailing Caverns
        [209] = {8, false}, -- Shadowfang Keep
        [719] = {7, false}, -- Blackfathom Deeps
        [717] = {5, false}, -- Stormwind Stockade
        [491] = {6, false}, -- Razorfen Kraul
        [721] = {5, false}, -- Gnomeregan
        [796] = {7, false}, -- Scarlet Monastery
        [722] = {4, false}, -- Razorfen Downs
        [1337] = {7, false}, -- Uldaman
        [2100] = {8, false}, -- Maraudon
        [1176] = {8, false}, -- Zul'Farrak
        [1477] = {8, false}, -- Sunken Temple
        [1584] = {19, false}, -- Blackrock Depths
        [2557] = {16, false}, -- Dire Maul
        [1583] = {14, false}, -- Blackrock Spire
        [2057] = {13, false}, -- Scholomance
        [2017] = {13, false}, -- Stratholme

        [1977] = {10, true}, -- Zul'Gurub
        [3429] = {6, true}, -- Ruins of Ahn'qiraj
        [2717] = {10, true}, -- Molten Core
        [2677] = {8, true}, -- Blackwing Lair
        [3428] = {9, true}, -- Temple of Ahn'qiraj

        -- Burning Crusade
        [3562] = {3, false}, -- Hellfire Ramparts
        [3713] = {3, false}, -- Blood Furnace
        [3717] = {3, false}, -- Slave Pens
        [3716] = {4, false}, -- Underbog
        [3792] = {4, false}, -- Mana-Tombs
        [3790] = {2, false}, -- Auchenai Crypts
        [2367] = {3, false}, -- Old Hillsbrad
        [3791] = {3, false}, -- Sethekk Halls
        [4131] = {4, false}, -- Magister's Terrace
        [3789] = {4, false}, -- Shadow Labyrinth
        [3714] = {4, false}, -- Shattered Halls
        [3848] = {4, false}, -- Arcatraz
        [2366] = {3, false}, -- Black Morass
        [3847] = {5, false}, -- Botanica
        [3849] = {3, false}, -- Mechanar
        [3715] = {3, false}, -- Steamvault

        [3457] = {11, true}, -- Karazhan
        [3805] = {6, true}, -- Zul'Aman
        [3923] = {2, true}, -- Gruul's Lair
        [3836] = {1, true}, -- Magtheridon's Lair
        [3845] = {4, true}, -- Tempest Keep
        [3607] = {6, true}, -- Serpentshrine Cavern
        [3606] = {5, true}, -- Hyjal Summit
        [3959] = {9, true}, -- Black Temple
        [4075] = {6, true}, -- Sunwell Plateau

        -- Wrath of the Lich King
        [4265] = {5, false}, -- The Nexus
        [206] = {3, false}, -- Utgarde Keep
        [4494] = {5, false}, -- Ahn'kahet
        [4277] = {3, false}, -- Azjol-Nerub
        [4196] = {4, false}, -- Drak'Tharon Keep
        [4415] = {3, false}, -- Violet Hold
        [4416] = {5, false}, -- Gundrak
        [4264] = {4, false}, -- Halls of Stone
        [4272] = {4, false}, -- Halls of Lightning
        [4100] = {4, false}, -- Culling of Stratholme
        [4228] = {4, false}, -- The Oculus
        [1196] = {4, false}, -- Utgarde Pinnacle
        [4820] = {3, false}, -- Halls of Reflection
        [4813] = {3, false}, -- Pit of Saron
        [4809] = {2, false}, -- Forge of Souls
        [4723] = {3, false}, -- Trial of the Champion

        [4603] = {4, true}, -- Vault of Archavon
        [3456] = {15, true}, -- Naxxramas
        [4493] = {1, true}, -- Obsidian Sanctum
        [4500] = {1, true}, -- Eye of Eternity
        [4273] = {14, true}, -- Ulduar
        [2159] = {1, true}, -- Onyxia's Lair
        [4722] = {5, true}, -- Trial of the Crusader
        [4812] = {12, true}, -- Icecrown Citadel
        [4987] = {1, true}, -- Ruby Sanctum
    },
    ['dungeonChallengeSpellIds'] = {
        [80205] = true,
        [80207] = true,
        [80212] = true,
        [80225] = true,
    },
    ['rarityColours'] = {
        [0] = {0.615, 0.615, 0.615},
        [1] = {1, 1, 1},
        [2] = {0.118, 1, 0},
        [3] = {0, 0.439, 0.867},
        [4] = {0.639, 0.208, 0.933},
        [5] = {1, 0.502, 0},
        [6] = {0.902, 0.8, 0.502},
        [7] = {0.902, 0.8, 0.502},
    },
    ['reputationStandingMap'] = {
        [1] = 'hated',
        [2] = 'hostile',
        [3] = 'unfriendly',
        [4] = 'neutral',
        [5] = 'friendly',
        [6] = 'honoured',
        [7] = 'revered',
        [8] = 'exalted',
    },
    ['bagIdMap'] = {
        [0x13] = 1,
        [0x14] = 2,
        [0x15] = 3,
        [0x16] = 4,
    },
    ['bankContainerSlots'] = {-1, 5, 6, 7, 8, 9, 10},
}

for funcName, func in pairs(lookup) do
    ScootsProgressBar.lookup[funcName] = func
end
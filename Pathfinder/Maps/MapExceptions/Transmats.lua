-- Pathfinder transport menu data. It belongs to the pathfinder core rather
-- than the hunting-script configuration, so hunting Script.lua is standalone.
local destinations = { 
    --Hoenn
    ["Pokecenter Lilycove City"]    = {page = 1, answer = 1, state = false},
    ["Pokecenter Slateport"]        = {page = 1, answer = 2, state = false},
    ["Pokecenter Mauville City"]    = {page = 1, answer = 3, state = false},

    ["Pokecenter Oldale Town"]      = {page = 2, answer = 1, state = false},
    ["Pokecenter Petalburg City"]   = {page = 2, answer = 2, state = false},
    ["Pokecenter Rustboro City"]    = {page = 2, answer = 3, state = false},
    ["Pokecenter Dewford Town"]     = {page = 2, answer = 4, state = false},

    ["Pokecenter Verdanturf"]       = {page = 3, answer = 1, state = false},
    ["Pokecenter Fallarbor Town"]   = {page = 3, answer = 2, state = false},
    ["Pokecenter Lavaridge Town"]   = {page = 3, answer = 3, state = false},
    ["Pokecenter Fortree City"]     = {page = 3, answer = 4, state = false},

    ["Pokecenter Mossdeep City"]    = {page = 4, answer = 1, state = false},
    ["Pokecenter Sootopolis City"]  = {page = 4, answer = 2, state = false},
    ["Pokecenter Pacifidlog Town"]  = {page = 4, answer = 3, state = false},
    ["Pokecenter Ever Grande City"] = {page = 4, answer = 4, state = false},

    --Sinnoh
    ["Canalave Pokecenter"]         = {page = 1, answer = 1, state = false},
    ["Pastoria Pokecenter"]         = {page = 1, answer = 2, state = false},
    ["Solaceon Pokecenter"]         = {page = 1, answer = 3, state = false},

    ["Pokecenter Sandgem Town"]     = {page = 2, answer = 1, state = false},
    ["Pokecenter Jubilife City"]    = {page = 2, answer = 2, state = false},
    ["Pokecenter Oreburgh City"]    = {page = 2, answer = 3, state = false},
    ["Pokecenter Floaroma"]         = {page = 2, answer = 4, state = false},

    ["Pokecenter Eterna City"]      = {page = 3, answer = 1, state = false},
    ["Hearthome Pokecenter"]        = {page = 3, answer = 2, state = false},
    ["Veilstone Pokecenter"]        = {page = 3, answer = 3, state = false},
    ["Celestic Pokecenter"]         = {page = 3, answer = 4, state = false},

    ["Pokecenter Snowpoint City"]   = {page = 4, answer = 1, state = false},
    ["Pokecenter Sunyshore"]       = {page = 4, answer = 2, state = false},
    ["Fight Area Pokecenter"]       = {page = 4, answer = 3, state = false},
    ["Pokecenter Survival Area"]    = {page = 4, answer = 4, state = false},

    ["Pokecenter Resort Area"]      = {page = 5, answer = 1, state = false},

    --Kanto
    ["Vermilion City"]              = {page = 1, answer = 1, state = false},
    ["Saffron City"]                = {page = 1, answer = 2, state = false},
    ["Cerulean City"]               = {page = 1, answer = 3, state = false},

    ["Viridian City"]               = {page = 2, answer = 1, state = false},
    ["Pewter City"]                 = {page = 2, answer = 2, state = false},
    ["Lavender Town"]               = {page = 2, answer = 3, state = false},
    ["Celadon City"]                = {page = 2, answer = 4, state = false},
    ["Fuchsia City"]                = {page = 2, answer = 5, state = false},

    --Johto
    ["Olivine City"]                = {page = 1, answer = 1, state = false},
    ["Goldenrod City"]              = {page = 1, answer = 2, state = false},
    ["Blackthorn City"]             = {page = 1, answer = 3, state = false},

    ["Cherrygrove City"]            = {page = 2, answer = 1, state = false},
    ["Violet City"]                 = {page = 2, answer = 2, state = false},
    ["Azalea Town"]                 = {page = 2, answer = 3, state = false},
    ["Ecruteak City"]               = {page = 2, answer = 4, state = false},
    ["Mahogany Town"]               = {page = 2, answer = 5, state = false},
}
return {
    destinations = destinations,
}
local cpath = select(1, ...) or "" -- callee path
local function nTimes(n, f, x) for i = 0, n - 1 do x = f(x) end return x end -- calls n times f(x)
local function rmlast(str) return str:sub(1, -2):match(".+[%./]") or "" end -- removes last dir / file from the callee path
local cppdpath = nTimes(3, rmlast, cpath) -- callee parent of parent dir path

local Lib = require (cppdpath .. "Lib/Lib")

local digways = {}

----------------------
------ Kanto ---------
----------------------

digways["Route 10_C"] = {
    ["Route 10_A"] = {{2, 44}, {1}}
}
digways["Route 10_A"] = {
    ["Route 10_C"] = {{9, 9}, {1}}
}
digways["Route 11"] = {
    ["Route 2_B"] = {{12, 12}, {1}}
}
digways["Route 2_B"] = {
    ["Route 11"] = {{30, 31}, {1}}
}
digways["Route 3"] = {
    ["Route 4"] = {{74, 16}, {1}}
}
digways["Route 4"] = {
    ["Route 3"] = {{9, 20}, {1}}
}

digways["Route 22"] = {
    ["Indigo Plateau"] = {{11, 5}, {1}},
    ["Mt. Silver Exterior"] = {{11, 5}, {2}},
}
digways["Indigo Plateau"] = {
    ["Route 22"] = {{14, 30}, {1}},
    ["Mt. Silver Exterior"] = {{14, 30}, {2}},
}
digways["Mt. Silver Exterior"] = {
    ["Indigo Plateau"] = {{30, 5}, {1}},
    ["Route 22"] = {{30, 5}, {2}},
}

----------------------
------ JOHTO ---------
----------------------

digways["Route 42_D"] = {
    ["Route 42_A"] = {{77, 13}, {1}}
}
digways["Route 42_A"] = {
    ["Route 42_D"] = {{15, 13}, {1}}
}
digways["Route 44"] = {
    ["Blackthorn City"] = {{73, 9}, {1}}
}
digways["Blackthorn City"] = {
    ["Route 44"] = {{49, 16}, {1}}
}
digways["Route 31"] = {
    ["Route 45_A"] = {{53, 10}, {1}}
}
digways["Route 45_A"] = {
    ["Route 31"] = {{8, 5}, {1}}
}
digways["Route 32"] = {
    ["Route 33"] = {{10, 143}, {1}}
}
digways["Route 33"] = {
    ["Route 32"] = {{14, 13}, {1}}
}

----------------------
------ HOENN ---------
----------------------

digways["Ever Grande City_A"] = {
    ["Ever Grande City_B"] = {{29, 56}, {1}}
}
digways["Ever Grande City_B"] = {
    ["Ever Grande City_A"] = {{34, 33}, {1}}
}
digways["Route 116_A"] = {
    ["Route 116_B"] = {{74, 27}, {"Eastern segment of Route 116."}},
    ["Verdanturf Town"] = {{74, 27}, {"Verdanturf Town."}}
}
digways["Route 116_B"] = {
    ["Route 116_A"] = {{97, 24}, {"Western segment of Route 116."}},
    ["Verdanturf Town"] = {{97, 24}, {"Verdanturf Town."}}
}
digways["Verdanturf Town"] = {
    ["Route 116_A"] = {{14, 2}, {"Western segment of Route 116."}},
    ["Route 116_B"] = {{14, 2}, {"Eastern segment of Route 116."}}
}

----------------------
------ SINNOH ---------
----------------------
digways["Route 207_B"] = {
    ["Route 208"] = {{56, 8}, {1}}
}

digways["Route 208"] = {
    ["Route 207_B"] = {{2, 28}, {1}}
}

digways["Mt. Coronet Summit_B"] = {
    ["Route 211_B"] = {{43, 18}, {1}, menuName="Route 211 East"},
    ["Route 211_A"] = {{43, 18}, {2}, menuName="Route 211 West"},
    ["Route 216"] = {{43, 18}, {3}},
}

digways["Route 211_B"] = {
    ["Route 211_A"] = {{59, 23}, {1}, menuName="Route 211 West"},
    ["Route 216"] = {{59, 23}, {2}},
    ["Mt. Coronet Summit_B"] = {{59, 23}, {3}},
}

digways["Route 211_A"] = {
    ["Route 211_B"] = {{37, 21}, {1}, menuName="Route 211 East"},
    ["Route 216"] = {{37, 21}, {2}},
    ["Mt. Coronet Summit_B"] = {{37, 21}, {3}},
}

digways["Route 216"] = {
    ["Route 211_B"] = {{91, 20}, {1}, menuName="Route 211 East"},
    ["Route 211_A"] = {{91, 20}, {2}, menuName="Route 211 West"},
    ["Mt. Coronet Summit_B"] = {{91, 20}, {3}},
}

digways["Pokemon League Sinnoh_A"] = {
    ["Pokemon League Sinnoh_B"] = {{27, 72}, {1}},
    ["Route 224"] = {{27, 72}, {2}},
}

digways["Pokemon League Sinnoh_B"] = {
    ["Pokemon League Sinnoh_A"] = {{29, 58}, {1}},
    ["Route 224"] = {{29, 58}, {2}},
}

digways["Route 224"] = {
    ["Pokemon League Sinnoh_A"] = {{14, 72}, {1}},
    ["Pokemon League Sinnoh_B"] = {{14, 72}, {2}},
}

----------------------
----- NAP ISLAND -----
----------------------

digways["Sleeping Path"] = {
    ["Secret Nap Area"] = {{40, 4}, {1}},
}

digways["Secret Nap Area"] = {
    ["Sleeping Path"] = {{22, 40}, {1}},
}

----------------------
----- HALLOWEEN -----
----------------------

digways["Unison Mountain South Summit"] = {
    ["Sweetsland_A"] = {{34, 9}, {1}},
}

digways["Sweetsland_A"] = {
    ["Unison Mountain South Summit"] = {{17, 49}, {1}},
}

digways["Sweetsland_C"] = {
    ["Sweetsland_E"] = {{39, 11}, {1}},
}

digways["Sweetsland_E"] = {
    ["Sweetsland_C"] = {{12, 7}, {1}},
}
return digways

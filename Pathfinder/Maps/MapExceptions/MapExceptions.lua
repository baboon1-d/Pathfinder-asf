local cpath = select(1, ...) or "" -- callee path
local function nTimes(n, f, x) for i = 0, n - 1 do x = f(x) end return x end -- calls n times f(x)
local function rmlast(str) return str:sub(1, -2):match(".+[%./]") or "" end -- removes last dir / file from the callee path
local cppdpath = nTimes(3, rmlast, cpath) -- callee parent of parent dir path

local Lib = require (cppdpath .. "Lib/Lib")

local mapExceptions = {}

-- Same physical map, but distinct reachable regions separated by one-way
-- ledges. Keep A -> B actionable instead of skipping it as "same map".
-- Never add the reverse edge: B reaches A through Route 205 / Fuego Ironworks.
mapExceptions["Floaroma Meadow_A"] = {
    ["Floaroma Meadow_B"] = {{20, 23, 34, 23}}
}

mapExceptions["Mt. Coronet 2F_A"] = {
    ["Mt. Coronet 2F_B"] = {{8, 2}}
}

mapExceptions["Mt. Coronet 2F_B"] = {
    ["Mt. Coronet 2F_A"] = {{41, 15}}
}

mapExceptions["Pinkan Island Cave_A"] = {
    ["Pinkan Island Cave_B"] = {{47, 40}}
}

mapExceptions["Mineral Site_A"] = {
    ["Mineral Site_B"] = {{11, 15}}
}

mapExceptions["Mineral Site_B"] = {
    ["Mineral Site_A"] = {{11, 17}}
}

mapExceptions["Mineral Site_B"] = {
    ["Mineral Site_A"] = {{11, 17}}
}

mapExceptions["Historical Site_A"] = {
    ["Historical Site_B"] = {{2, 12}},
    ["Historical Site_C"] = {{21, 14}}
}
mapExceptions["Historical Site_B"] = {
    ["Historical Site_A"] = {{2, 14}}
}
mapExceptions["Historical Site_C"] = {
    ["Historical Site_A"] = {{20, 15}}
}
mapExceptions["Feral Site_A"] = {
    ["Feral Site_B"] = {{19, 22}, {19, 21}}
}
mapExceptions["Feral Site_B"] = {
    ["Feral Site_A"] = {{19, 24}, {19, 25}}
}

mapExceptions["Unison Mountain 3F_B"] = {
    ["Unison Mountain 3F_C"] = {{38, 6}}
}

mapExceptions["Unison Mountain 3F_C"] = {
    ["Unison Mountain 3F_B"] = {{63, 73}}
}

mapExceptions["Unison Mountain Summit_A"] = {
    ["Unison Mountain Summit_B"] = {{15, 18}}
}

mapExceptions["Unison Mountain Summit_B"] = {
    ["Unison Mountain Summit_A"] = {{15, 11}}
}

return mapExceptions

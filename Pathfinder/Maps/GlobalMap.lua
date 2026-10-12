local cpath = select(1, ...) or "" -- callee path
local function rmlast(str) return str:sub(1, -2):match(".+[%./]") or "" end -- removes last dir / file from the callee path
local cdpath = rmlast(cpath) -- callee dir path
local cpdpath = rmlast(cdpath) -- callee parent dir path

local Lib = require (cpdpath .. "Lib/Lib")
local _KantoMap = require (cdpath .. "Kanto/KantoMap")
local _JohtoMap = require (cdpath .. "Johto/JohtoMap")
local _HoennMap = require (cdpath .. "Hoenn/HoennMap")
local _SinnohMap = require (cdpath .. "Sinnoh/SinnohMap")
local _LinkMap  = require (cdpath .. "LinkMap")
local _EventMap = require (cdpath .. "Event/EventMap")

return function()

local KantoMap = _KantoMap()
local JohtoMap = _JohtoMap()
local HoennMap = _HoennMap()
local SinnohMap = _SinnohMap()
local LinkMap  = _LinkMap()
local EventMap = _EventMap()

local GlobalMap = {}
-- Region ownership comes from the authored source maps, not map-name guesses.
-- LinkMap adds cross-region edges but must not reclassify their endpoints.
local regions = {}
local function tagRegion(map,region)
    for node in pairs(map) do
        if not regions[node] then regions[node]=region end
        local physical=node:gsub("_%u$", "")
        if not regions[physical] then regions[physical]=region end
    end
end
tagRegion(KantoMap,"Kanto")
tagRegion(JohtoMap,"Johto")
tagRegion(HoennMap,"Hoenn")
tagRegion(SinnohMap,"Sinnoh")

local function mergeMap(t1, t2)
    for key, value in pairs(t2) do
        if not t1[key] then
            t1[key] = value
        elseif type(value) == "table" then
            mergeMap(t1[key], value)
        end
    end
end

mergeMap(GlobalMap, KantoMap)
mergeMap(GlobalMap, JohtoMap)
mergeMap(GlobalMap, HoennMap)
mergeMap(GlobalMap, SinnohMap)
mergeMap(GlobalMap, LinkMap)
mergeMap(GlobalMap, EventMap)

return GlobalMap, regions
end

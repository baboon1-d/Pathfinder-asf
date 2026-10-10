local cpath = select(1, ...) or "" -- callee path
local function nTimes(n, f, x) for i = 0, n - 1 do x = f(x) end return x end -- calls n times f(x)
local function rmlast(str) return str:sub(1, -2):match(".+[%./]") or "" end -- removes last dir / file from the callee path
local cpppdpath = nTimes(4, rmlast, cpath) -- callee parent parent of parent dir path

local _ss = require (cpppdpath .. "Settings/Static_Settings")

return function()

-- local K_SUBWAY = 1
-- if getServer() ~= "None" then
	-- local ss = _ss()
	-- K_SUBWAY = ss.K_SUBWAY
-- end

local SinnohMap = {}
SinnohMap["Iron Island"] = {}
SinnohMap["Transmat Station Sinnoh"] = {["Canalave Pokecenter"]={0.5}, ["Pokecenter Sandgem Town"]={0.5}, ["Pokecenter Jubilife City"]={0.5}, ["Pokecenter Oreburgh City"]={0.5}, ["Pokecenter Floaroma"]={0.5}, ["Pokecenter Eterna City"] = {0.5}, ["Hearthome Pokecenter"] = {0.5}, ["Veilstone Pokecenter"] = {0.5}, ["Celestic Pokecenter"] = {0.5}, ["Pastoria Pokecenter"] = {0.5}, ["Pokecenter Snowpoint City"] = {0.5}, ["Solaceon Pokecenter"] = {0.5}, ["Pokecenter Sunyshore"] = {0.5}, ["Fight Area Pokecenter"] = {0.5}, ["Pokecenter Survival Area"] = {0.5}, ["Pokecenter Resort Area"] = {0.5}}
SinnohMap["Canalave City"] = {["Canalave Pokemart"] = {1}, ["Canalave Pokecenter"] = {1}, ["Route 218 Stop House 2"] = {1}, ["Vermilion City_A"] = {0.5}, ["Olivine City"] = {0.5}, ["Lilycove City Harbor"] = {0.5}, ["Iron Island"] = {1}, ["Vulcan Island Shore"] = {5}, ["Murky Town Ferry"] = {5}}
SinnohMap["Canalave Pokemart"] = {["Canalave City"] = {1}}
SinnohMap["Canalave Pokecenter"] = {["Canalave City"] = {1}, ["Transmat Station Sinnoh"]={0.5}}
SinnohMap["Route 218 Stop House 2"] = {["Canalave City"] = {0.2}, ["Route 218"] = {0.2}}
SinnohMap["Route 218"] = {["Route 218 Stop House 2"] = {1}, ["Route 218 Stop House 1"] = {1}}
SinnohMap["Route 218 Stop House 1"] = {["Jubilife City"] = {0.2}, ["Route 218"] = {0.2}}
SinnohMap["Jubilife City"] = {["Pokecenter Jubilife City"] = {0.2}, ["Mart Jubilife City"] = {1}, ["Route 202"] = {1}, ["Route 204_A"] = {1}, ["Route 203"] = {1}, ["Route 218 Stop House 1"] = {1}, ["Jubilife TV 1F"] = {1}, ["Jubilife House 1"] = {1}, ["Jubilife House 2"] = {1}, ["Jubilife House 3"] = {1}, ["Jubilife Trainers School"] = {1}, ["Jubilife Global Station"] = {1}, ["Poketch Company 1F"] = {1}}
SinnohMap["Mart Jubilife City"] = {["Jubilife City"] = {1}}
SinnohMap["Pokecenter Jubilife City"] = {["Jubilife City"] = {1}, ["Transmat Station Sinnoh"]={0.5}}
SinnohMap["Route 202"] = {["Sandgem Town"] = {1}, ["Jubilife City"] = {1}}
SinnohMap["Sandgem Town"] = {["Route 202"] = {1}, ["Route 201"] = {1}, ["Pokecenter Sandgem Town"] = {1}, ["Mart Sandgem Town"] = {1}, ["Rowan Lab"] = {1}, ["Sandgem Town House"] = {1}, ["Dawn House"] = {1}, ["Route 219"] = {1}}
SinnohMap["Mart Sandgem Town"] = {["Sandgem Town"] = {1}}
SinnohMap["Pokecenter Sandgem Town"] = {["Sandgem Town"] = {1}, ["Transmat Station Sinnoh"]={0.5}}
SinnohMap["Route 201"] = {["Sandgem Town"] = {1}, ["Twinleaf Town"] = {1}, ["Lake Verity"] = {1}}
SinnohMap["Twinleaf Town"] = {["Route 201"] = {1}, ["Twinleaf Town Player House"] = {1}, ["Route 219"] = {1, {["abilities"] = {"surf"}}}, ["Twinleaf Town House 2"] = {1}}
SinnohMap["Route 219"] = {["Twinleaf Town"] = {1}, ["Sandgem Town"] = {1}, ["Route 220"] = {1}}
SinnohMap["Route 220"] = {["Route 219"] = {1}, ["Route 221"] = {1}}
SinnohMap["Route 221"] = {["Route 220"] = {1}, ["Pal Park"] = {1}}
SinnohMap["Pal Park"] = {["Route 221"] = {1}}
SinnohMap["Route 203"] = {["Jubilife City"] = {1}, ["Oreburgh Gate 1F"] = {1}}
SinnohMap["Oreburgh Gate 1F"] = {["Route 203"] = {1}, ["Oreburgh City"] = {1}, ["Oreburgh Gate B1F"] = {1,{["abilities"] = {"rock smash"}}}}
SinnohMap["Oreburgh Gate B1F"] = {["Oreburgh Gate 1F"] = {1}, ["Legends Cave"] = {1,{["abilities"] = {"rock smash"}}}}
SinnohMap["Legends Cave"] = {["Oreburgh Gate B1F"] = {1}}
SinnohMap["Oreburgh City"] = {["Oreburgh Gate 1F"] = {1}, ["Pokecenter Oreburgh City"] = {1}, ["Mart Oreburgh City"] = {1}, ["Route 207_A"] = {1}, ["Oreburgh Mine B1F"] = {1}}
SinnohMap["Mart Oreburgh City"] = {["Oreburgh City"] = {1}}
SinnohMap["Pokecenter Oreburgh City"] = {["Oreburgh City"] = {1}, ["Transmat Station Sinnoh"]={0.5}}
SinnohMap["Oreburgh Mine B1F"] = {["Oreburgh City"] = {1}, ["Oreburgh Mine B2F 1R"] = {1}}
SinnohMap["Oreburgh Mine B2F 1R"] = {["Oreburgh Mine B1F"] = {1}, ["Oreburgh Mine B2F 2R"] = {1}}
SinnohMap["Oreburgh Mine B2F 2R"] = {["Oreburgh Mine B2F 1R"] = {1}, ["Oreburgh Mine B1F"] = {1}}
SinnohMap["Route 207_A"] = {["Oreburgh City"] = {1}}
SinnohMap["Route 207_B"] = {["Mt. Coronet South"] = {1}, ["Route 206_B"] = {1}, ["Route 208"] = {1}}
SinnohMap["Route 207_C"] = {["Mt. Coronet 2F_A"] = {1}}
SinnohMap["Route 204_A"] = {["Jubilife City"] = {1}, ["Ravaged Path_A"] = {1}}
SinnohMap["Route 204_B"] = {["Ravaged Path_B"] = {1}, ["Floaroma Town"] = {1}}
SinnohMap["Ravaged Path_A"] = {["Route 204_A"] = {1}, ["Ravaged Path_B"] = {0.2, {["abilities"] = {"rock smash"}}}}
SinnohMap["Ravaged Path_B"] = {["Ravaged Path_A"] = {0.2, {["abilities"] = {"rock smash"}}}, ["Route 204_B"] = {1}}
SinnohMap["Floaroma Town"] = {["Route 204_B"] = {1}, ["Pokecenter Floaroma"] = {1}, ["Mart Floaroma"] = {1}, ["Route 205_A"] = {1}, ["Floaroma Meadow_B"] = {1}}
SinnohMap["Pokecenter Floaroma"] = {["Floaroma Town"] = {1} ,["Transmat Station Sinnoh"]={0.5}}
SinnohMap["Mart Floaroma"] = {["Floaroma Town"] = {1}}
SinnohMap["Floaroma Meadow_A"] = {["Floaroma Meadow_B"] = {0.2}, ["Fuego Ironworks"] = {1}}
SinnohMap["Floaroma Meadow_B"] = {["Floaroma Town"] = {0.2}}
SinnohMap["Route 205_A"] = {["Floaroma Town"] = {1}, ["Valley Windworks"] = {1}, ["Eterna Forest"] = {1}, ["Route 205_B"] = {0, {["abilities"] = {"cut"}}}, ["Fuego Ironworks"] = {1}}
SinnohMap["Route 205_B"] = {["Route 205_A"] = {0, ["abilities"] = {"cut"}}, ["Eterna City"] = {1}, ["Eterna Forest"] = {1}}
SinnohMap["Valley Windworks"] = {["Route 205_A"] = {{1}}}
SinnohMap["Fuego Ironworks"] = {["Route 205_A"] = {1}, ["Floaroma Meadow_A"] = {0.5}}
SinnohMap["Eterna Forest"] = {["Route 205_A"] = {1}, ["Route 205_B"] = {1}}
SinnohMap["Eterna City"] = {["Route 205_B"] = {1}, ["Pokecenter Eterna City"] = {1}, ["Mart Eterna City"] = {1}, ["Route 211_A"] = {1}, ["Eterna City Stop House"] = {1}}
SinnohMap["Pokecenter Eterna City"] = {["Eterna City"] = {1}, ["Transmat Station Sinnoh"]={0.2}}
SinnohMap["Mart Eterna City"] = {["Eterna City"] = {1}}
SinnohMap["Eterna City Stop House"] = {["Eterna City"] = {1}, ["Route 206_A"] = {1}}
SinnohMap["Route 206_A"] = {["Eterna City Stop House"] = {1}, ["Route 206 Stop House"] = {1}}
SinnohMap["Route 206 Stop House"] = {["Route 206_A"] = {1}, ["Route 206_B"] = {1}}
SinnohMap["Route 206_B"] = {["Route 207_B"] = {1}, ["Route 206 Stop House"] = {1}, ["Route 206_A"] = {1}, ["Wayward Cave"] = {1}}
SinnohMap["Wayward Cave"] = {["Route 206_B"] = {1}}
SinnohMap["Mt. Coronet South"] = {["Route 207_B"] = {1}, ["Route 208"] = {1}, ["Mt. Coronet 2F_A"] = {1}}
SinnohMap["Mt. Coronet 2F_A"] = {["Mt. Coronet South"] = {1}, ["Mt. Coronet 2F_B"] = {1}, ["Route 207_C"] = {1}}
SinnohMap["Mt. Coronet 2F_B"] = {["Mt. Coronet 2F_A"] = {1}, ["Mt. Coronet 3F"] = {1}}
SinnohMap["Mt. Coronet 2F_C"] = {["Mt. Coronet 3F"] = {1}}
SinnohMap["Mt. Coronet 3F"] = {["Mt. Coronet 2F_B"] = {1}, ["Mt. Coronet 2F_C"] = {1}, ["Mt. Coronet Summit_A"]= {1}}
SinnohMap["Mt. Coronet Summit_A"] = {["Mt. Coronet 3F"] = {1}, ["Mt. Coronet 4F_A"] = {1}, ["Mt. Coronet 4F_B"] = {1}}
SinnohMap["Mt. Coronet 4F_A"] = {["Mt. Coronet Summit_A"] = {1}, ["Mt. Coronet 4F_A"] = {1}, ["Mt. Coronet Summit_B"] = {1}}
SinnohMap["Mt. Coronet 4F_B"] = {["Mt. Coronet Summit_A"] = {1}}
SinnohMap["Mt. Coronet Summit_B"] = {["Mt. Coronet 4F_A"] = {1}, ["Mt. Coronet 5F"] = {1}, ["Mt. Coronet Tunnel"] = {1}, ["Route 211_A"] = {0.5}, ["Route 211_B"] = {0.5}, ["Route 216"] = {0.5}}
SinnohMap["Mt. Coronet 5F"] = {["Mt. Coronet 6F"] = {1}, ["Mt. Coronet Summit_B"] = {1}}
SinnohMap["Mt. Coronet 6F"] = {["Mt. Coronet 7F"] = {1}, ["Mt. Coronet 5F"] = {1}}
SinnohMap["Mt. Coronet 7F"] = {["Spear Pillar"] = {1}, ["Mt. Coronet 6F"] = {1}}
SinnohMap["Spear Pillar"] = {["Mt. Coronet 7F"] = {1}}
SinnohMap["Mt. Coronet Tunnel"] = {["Mt. Coronet Summit_B"] = {1}, ["Mt. Coronet Center"] = {1}}
SinnohMap["Mt. Coronet Center"] = {["Mt. Coronet Tunnel"] = {1}, ["Route 211_B"] = {1}, ["Route 211_A"] = {1}, ["Mt. Coronet B1F"] = {1}}
SinnohMap["Route 211_A"] = {["Mt. Coronet Summit_B"] = {0.5}, ["Route 211_B"] = {0.5}, ["Route 216"] = {0.5}, ["Eterna City"] = {1}, ["Mt. Coronet Center"] = {1}}
SinnohMap["Route 211_B"] = {["Mt. Coronet Summit_B"] = {0.5}, ["Route 211_A"] = {0.5}, ["Route 216"] = {0.5}, ["Mt. Coronet Center"] = {1}, ["Celestic Town"] = {1}}
SinnohMap["Route 216"] = {["Mt. Coronet Summit_B"] = {0.5}, ["Route 211_A"] = {0.5}, ["Route 211_B"] = {0.5}, ["Mt. Coronet North"] = {1}, ["Route 217"] = {1}}
SinnohMap["Mt. Coronet North"] = {["Route 216"] = {1}, ["Mt. Coronet B1F"] = {1}}
SinnohMap["Mt. Coronet B1F"] = {["Mt. Coronet North"] = {1}, ["Mt. Coronet Center"] = {1}}
SinnohMap["Route 217"] = {["Route 216"] = {1}, ["Acuity Lakefront"] = {1}}
SinnohMap["Acuity Lakefront"] = {["Route 217"] = {1}, ["Acuity Lakefront"] = {1}, ["Snowpoint City"] ={1}}
SinnohMap["Lake Acuity"] = {["Acuity Lakefront"] = {1}}
SinnohMap["Snowpoint City"] = {["Pokecenter Snowpoint City"] = {1}, ["Acuity Lakefront"] = {1}, ["Mart Snowpoint City"] = {1}, ["Fight Area"] = {1}}
SinnohMap["Pokecenter Snowpoint City"] = {["Snowpoint City"] = {1}, ["Transmat Station Sinnoh"]={0.2}}
SinnohMap["Mart Snowpoint City"] = {["Snowpoint City"] = {1}}
SinnohMap["Celestic Town"] = {["Route 211_B"] = {1}, ["Celestic Pokecenter"] = {1}, ["Route 210 North"] = {1}}
SinnohMap["Celestic Pokecenter"] = {["Celestic Town"] = {1}, ["Transmat Station Sinnoh"] = {1}}
SinnohMap["Route 210 North"] = {["Celestic Town"] = {1}, ["Cave Of Justice"] = {1}, ["Route 210"] = {1}}
SinnohMap["Cave Of Justice"] = {["Route 210 North"] = {1}}
SinnohMap["Route 210"] = {["Route 210 North"] = {1}, ["Route 215"] = {1}, ["Solaceon Town"] = {1}}
SinnohMap["Solaceon Town"] = {["Route 210"] = {1}, ["Solaceon Pokecenter"] = {1}, ["Solaceon Pokemart"] = {1}, ["Pokemon News Press"] = {1}, ["Route 209"] = {1}, ["Maniac Tunnel"] = {1}}
SinnohMap["Solaceon Pokecenter"] = {["Solaceon Town"] = {1}, ["Transmat Station Sinnoh"]={0.2}}
SinnohMap["Solaceon Pokemart"] = {["Solaceon Town"] = {1}}
SinnohMap["Pokemon News Press"] = {["Solaceon Town"] = {1}}
SinnohMap["Maniac Tunnel"] = {["Solaceon Town"] = {1}, ["Route 214"] = {1}}
SinnohMap["Route 209"] = {["Solaceon Town"] = {1}, ["Route 209 Stop House"] = {1}}
SinnohMap["Route 209 Stop House"] = {["Route 209"] = {1}, ["Hearthome City"] = {1}}
SinnohMap["Hearthome City"] = {["Hearthome Pokecenter"] = {1}, ["Route 209 Stop House"] = {1}, ["Mart Hearthome"] = {1}, ["Amity Square Entrance 1"] = {1}, ["Route 208 Stop House"] = {1}, ["Hearthome City Stop House 2"]= {1}}
SinnohMap["Hearthome Pokecenter"] = {["Hearthome City"] = {1}, ["Transmat Station Sinnoh"]={0.2}}
SinnohMap["Mart Hearthome"] = {["Hearthome City"] = {1}}
SinnohMap["Amity Square Entrance 1"] = {["Hearthome City"] = {1}, ["Amity Square"] = {1}}
SinnohMap["Amity Square"] = {["Amity Square Entrance 1"] = {1}}
SinnohMap["Route 208 Stop House"] = {["Hearthome City"] = {1}, ["Route 208"] = {1}}
SinnohMap["Hearthome City Stop House 2"] = {["Hearthome City"] = {1}, ["Route 212 North"] = {1}}
SinnohMap["Route 208"] = {["Route 208 Stop House"] = {1}, ["Mt. Coronet South"] = {1}, ["Route 207_B"] = {0.5}}
SinnohMap["Route 212 North"] = {["Hearthome City Stop House 2"] = {1}, ["Route 212 South"] = {1}}
SinnohMap["Route 212 South"] = {["Route 212 North"] = {1}, ["Pastoria City"] = {1}}
SinnohMap["Pastoria City"] = {["Pastoria Pokecenter"] = {1}, ["Pastoria Pokemart"] = {1}, ["Route 212 South"] = {1}, ["Sinnoh Safari Stop"] = {1}, ["Pastoria City Stop House"] = {1}}
SinnohMap["Pastoria Pokecenter"] = {["Pastoria City"] = {1}, ["Transmat Station Sinnoh"]={0.2}}
SinnohMap["Pastoria Pokemart"] = {["Pastoria City"] = {1}}
SinnohMap["Sinnoh Safari Stop"] = {["Pastoria City"] = {1}, ["Sinnoh Safari Area Zone 2"] = {1}}
SinnohMap["Sinnoh Safari Area Zone 2"] = {["Sinnoh Safari Stop"] = {1}, ["Sinnoh Safari Area Zone 1"] = {1}}
SinnohMap["Sinnoh Safari Area Zone 1"] = {["Sinnoh Safari Area Zone 2"] = {1}, ["Sinnoh Safari Area Zone 4_A"] ={1}, ["Sinnoh Safari Area Zone 4_B"] = {1}}
SinnohMap["Sinnoh Safari Area Zone 4_A"] = {["Sinnoh Safari Area Zone 1"] = {1}, ["Sinnoh Safari Area Zone 5"] = {1}}
SinnohMap["Sinnoh Safari Area Zone 4_B"] = {["Sinnoh Safari Area Zone 4_A"] = {1}, ["Sinnoh Safari Area Zone 3_A"] = {1}}
SinnohMap["Sinnoh Safari Area Zone 4_C"] = {["Sinnoh Safari Area Zone 5"] = {1}}
SinnohMap["Sinnoh Safari Area Zone 3_A"] = {["Sinnoh Safari Area Zone 4_B"] = {1}, ["Sinnoh Safari Area Zone 1"] = {1}}
SinnohMap["Sinnoh Safari Area Zone 3_B"] = {["Sinnoh Safari Area Zone 6"] = {1}, ["Sinnoh Safari Area Zone 3_A"] = {0.5}}
SinnohMap["Sinnoh Safari Area Zone 5"] = {["Sinnoh Safari Area Zone 4_A"] = {1}, ["Sinnoh Safari Area Zone 4_C"] = {1}, ["Sinnoh Safari Area Zone 6"] = {1}}
SinnohMap["Sinnoh Safari Area Zone 6"] = {["Sinnoh Safari Area Zone 5"] = {1}, ["Sinnoh Safari Area Zone 3_B"] = {1}}
SinnohMap["Pastoria City Stop House"] = {["Pastoria City"] =  {1}, ["Route 213_A"] = {1}}
SinnohMap["Route 213_A"] = {["Pastoria City Stop House"] = {1}, ["Route 213 House 1"] = {1}}
SinnohMap["Route 213_B"] = {["Route 213 House 1"] = {1}, ["Valor Lakefront"] = {1}}
SinnohMap["Route 213 House 1"] = {["Route 213_A"] = {1}, ["Route 213_B"] = {1}}
SinnohMap["Valor Lakefront"] = { ["Route 213_B"] = {1}, ["Route 214"] = {1}, ["Route 222"] = {1}, ["Lake Valor"] = {1}}
SinnohMap["Lake Valor"] = {["Valor Lakefront"] = {1}}
SinnohMap["Route 214"] = {["Valor Lakefront"] = {1}, ["Sendoff Spring"] = {1}, ["Route 214 Stop House"] = {1}, ["Maniac Tunnel"] = {1}}
SinnohMap["Sendoff Spring"] = {["Route 214"] = {1}}
SinnohMap["Route 214 Stop House"] = {["Route 214"] = {1}, ["Veilstone City"] = {1}}
SinnohMap["Veilstone City"] = {["Veilstone Pokecenter"] = {1}, ["Route 214 Stop House"] = {1}, ["Veilstone Department Store"]= {1}, ["Route 215 Stop House"] = {1}}
SinnohMap["Veilstone Pokecenter"] = {["Veilstone City"] = {1}, ["Transmat Station Sinnoh"]={0.2}}
SinnohMap["Veilstone Department Store"] = {["Veilstone City"] = {1}}
SinnohMap["Route 215 Stop House"] = {["Veilstone City"] = {1}, ["Route 215"] = {1}}
SinnohMap["Route 215"] = {["Route 210"] = {1}, ["Route 215 Stop House"] = {1}}
SinnohMap["Route 222"] = {["Route 214"] = {1}, ["Route 222 Stop House"] = {1}}
SinnohMap["Route 222 Stop House"] = {["Route 222"] = {1}, ["Sunyshore City"] = {1}}
SinnohMap["Sunyshore City"] = {["Pokecenter Sunyshore"] = {1}, ["Mart Sunyshore City"] = {1}, ["Route 222 Stop House"] = {1}, ["Route 223"] = {1}}
SinnohMap["Pokecenter Sunyshore"] = {["Sunyshore City"] = {1}, ["Transmat Station Sinnoh"]={0.2}}
SinnohMap["Mart Sunyshore City"] = {["Sunyshore City"] = {1}}
SinnohMap["Route 223"] = {["Sunyshore City"] = {1}, ["Pokemon League Sinnoh_A"] = {1}}
SinnohMap["Pokemon League Sinnoh_A"] = {["Route 223"] = {1}, ["Sinnoh Victory Road 1F_A"] = {1}, ["Pokemon League Sinnoh_B"] = {0.5}, ["Route 224"] = {0.5}, ["Pokecenter League Pokemon Sinnoh"] = {1}}
SinnohMap["Pokecenter League Pokemon Sinnoh"] = {["Pokemon League Sinnoh_A"] = {1}}
SinnohMap["Pokemon League Sinnoh_B"] = {["Sinnoh Victory Road 1F_A"] = {1}, ["Sinnoh Pokemon League Grand Floor"] = {1}, ["Pokemon League Sinnoh_A"] = {0.5}, ["Route 224"] = {0.5}}

SinnohMap["Sinnoh Pokemon League Grand Floor"] = {["Pokemon League Sinnoh_B"] = {1}}
SinnohMap["Sinnoh Victory Road 1F_A"] = {["Pokemon League Sinnoh_A"] = {1}, ["Sinnoh Victory Road 2F_A"] = {1}, ["Sinnoh Victory Road 2F_B"] = {1}, ["Sinnoh Victory Road 2F_C"] = {1}, ["Sinnoh Victory Road B1F_A"] = {1}, ["Sinnoh Victory Road B1F_B"] = {1}, ["Pokemon League Sinnoh_B"] = {1}, ["Sinnoh Victory Road B1F Deep Entrance"] = {1}}
SinnohMap["Sinnoh Victory Road 1F_B"] = {["Sinnoh Victory Road B1F_C"] = {1}}
SinnohMap["Sinnoh Victory Road 2F_A"] = {["Sinnoh Victory Road 1F_A"] = {1}}
SinnohMap["Sinnoh Victory Road 2F_B"] = {["Sinnoh Victory Road 1F_A"] = {1}, ["Sinnoh Victory Road 2F_A"] = {0.5}}
SinnohMap["Sinnoh Victory Road 2F_C"] = {["Sinnoh Victory Road 1F_A"] = {1}}
SinnohMap["Sinnoh Victory Road B1F_A"] = {["Sinnoh Victory Road 1F_A"] = {1}, ["Sinnoh Victory Road B1F_B"] = {1}}
SinnohMap["Sinnoh Victory Road B1F_B"] = {["Sinnoh Victory Road 1F_A"] = {1}, ["Sinnoh Victory Road B1F_C"] = {1}}
SinnohMap["Sinnoh Victory Road B1F_C"] = {["Sinnoh Victory Road 1F_B"] = {1}}
SinnohMap["Sinnoh Victory Road B1F Deep Entrance"] = {["Sinnoh Victory Road 1F_A"] = {1}, ["Sinnoh Victory road B1F Deep"] = {1}}
SinnohMap["Sinnoh Victory road B1F Deep"] = {["Sinnoh Victory Road B1F Deep Entrance"] = {1}, ["Sinnoh Victory Road B1F Deep Exit"] = {1}}
SinnohMap["Sinnoh Victory Road B1F Deep Exit"] = {["Sinnoh Victory road B1F Deep"] = {1}, ["Route 224"] = {1}}
SinnohMap["Route 224"] = {["Pokemon League Sinnoh_A"] = {0.5}, ["Pokemon League Sinnoh_B"] = {0.5}, ["Sinnoh Victory Road B1F Deep Exit"] = {1}}
SinnohMap["Fight Area"] = {["Snowpoint City"] = {0.5}, ["Fight Area Pokecenter"] = {1}, ["Route 225 Stop House"] = {1}, ["Fight Area Pokemart"] = {1}}
SinnohMap["Fight Area Pokecenter"] = { ["Fight Area"] = {1}, ["Transmat Station Sinnoh"]={0.2}}
SinnohMap["Fight Area Pokemart"] = {["Fight Area"] = {1}}
SinnohMap["Route 225 Stop House"] = {["Fight Area"] = {1}, ["Route 225"] = {1}}
SinnohMap["Route 225"] = {["Route 225 Stop House"] = {1}, ["Survival Area"] = {1}}
SinnohMap["Survival Area"] = {["Route 225"] = {1}, ["Pokecenter Survival Area"] = {1}, ["Survival Area Pokemart"] = {1}, ["Route 226"] = {1}}
SinnohMap["Pokecenter Survival Area"] = {["Survival Area"] = {1}, ["Transmat Station Sinnoh"]={0.2}}
SinnohMap["Survival Area Pokemart"] = {["Survival Area"] = {1}}
SinnohMap["Route 226"] = {["Survival Area"] = {1}, ["Route 227"] = {1}, ["Route 226 Stop House"] = {1}}
SinnohMap["Route 227"] = {["Route 226"] = {1}, ["Stark Mountain Exterior Pt"] = {1}}
SinnohMap["Stark Mountain Exterior Pt"] = {["Route 227"] = {1}, ["Stark Mountain Entrance Pt"] = {1}}
SinnohMap["Stark Mountain Entrance Pt"] = {["Stark Mountain Exterior Pt"] = {1}, ["Stark Mountain Main Cavern Pt"] = {1}}
SinnohMap["Stark Mountain Main Cavern Pt"] = {["Stark Mountain Entrance Pt"] = {1}}
SinnohMap["Route 226 Stop House"] = {["Route 226"] = {1}, ["Route 228"] = {1}}
SinnohMap["Route 228"] = {["Route 226 Stop House"] = {1}, ["Route 229"] = {1}}
SinnohMap["Route 229"] = {["Route 228"] = {1}, ["Resort Area"] = {1}, ["Route 230"] = {1}}
SinnohMap["Resort Area"] = {["Route 229"] = {1}, ["Pokecenter Resort Area"] = {1}}
SinnohMap["Pokecenter Resort Area"] = {["Resort Area"] = {1}, ["Transmat Station Sinnoh"]={0.2}}
SinnohMap["Route 230"] = {["Route 229"] = {1}, ["Fight Area"] = {1}}






SinnohMap["Dawn House"] = {}
SinnohMap["Jubilife Global Station"] = {}
SinnohMap["Jubilife House 1"] = {}
SinnohMap["Jubilife House 2"] = {}
SinnohMap["Jubilife House 3"] = {}
SinnohMap["Jubilife TV 1F"] = {}
SinnohMap["Jubilife Trainers School"] = {["Jubilife City"] = {1}}
SinnohMap["Lake Verity"] = {}
SinnohMap["Poketch Company 1F"] = {}
SinnohMap["Rowan Lab"] = {}
SinnohMap["Sandgem Town House"] = {["Sandgem Town"] = {1}}
SinnohMap["Twinleaf Town House 2"] = {["Twinleaf Town"] = {1}}
SinnohMap["Twinleaf Town Player House"] = {["Twinleaf Town"] = {1}}

return SinnohMap
end

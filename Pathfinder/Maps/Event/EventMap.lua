local cpath = select(1, ...) or "" -- callee path
local function nTimes(n, f, x) for i = 0, n - 1 do x = f(x) end return x end -- calls n times f(x)
local function rmlast(str) return str:sub(1, -2):match(".+[%./]") or "" end -- removes last dir / file from the callee path
local cpppdpath = nTimes(4, rmlast, cpath) -- callee parent parent of parent dir path

return function()

local EventMap = {}

-- Summer Event
EventMap = {}

EventMap["Kalijodo Path"] = {["Kalijodo Lake"] = {1}, ["Vulcanic Town"] = {1}}
EventMap["Kalijodo Cave B1F"] = {["Kalijodo Cave Entrance"] = {1}, ["Kalijodo Cave B2F"] = {1}}
EventMap["Kalijodo Cave B2F"] = {["Kalijodo Cave B1F"] = {1}}
EventMap["Kalijodo Cave Entrance"] = {["Kalijodo Lake"] = {1}, ["Kalijodo Cave B1F"] = {1}}
EventMap["Kalijodo Lake"] = {["Kalijodo Path"] = {1}, ["Kalijodo Cave Entrance"] = {1}}

EventMap["Vulcanic Town"] = {["Pokecenter Vulcanic Town"] = {1}, ["Vulcan Forest"] = {1}, ["Kalijodo Path"] = {1}, ["Pokemart Vulcanic Town"] = {1}, ["Vulcan Cavern_A"] = {1}, ["Vulcan Island Shore"] = {0.2}, ["Vulcan Cove"] = {0.2}, ["Alto Mare"] = {0.2}}
EventMap["Pokecenter Vulcanic Town"] = {["Vulcanic Town"] = {1}}
EventMap["Pokemart Vulcanic Town"] = {["Vulcanic Town"] = {1}}
EventMap["Vulcan Cavern_A"] = {["Vulcanic Town"] = {1}, ["Vulcan Cavern Cave"] = {1}}
EventMap["Vulcan Cavern Cave"] = {["Vulcan Cavern_B"] = {1}, ["Vulcan Cavern_A"] = {1}}
EventMap["Vulcan Cavern_B"] = {["Vulcan Lava Pit"] = {1}, ["Vulcan Cavern Cave"] = {1}}
EventMap["Vulcan Lava Pit"] = {["Vulcan Cavern_B"] = {1}}

EventMap["Vulcan Island Shore"] = {["Vulcan Path"] = {1}, ["Alto Mare Shore"] = {1}, ["Vulcan Cove"] = {0.2}, ["Vulcanic Town"] = {0.2}, ["Alto Mare"] = {0.2}, ["Lilycove City"] = {0.2}, ["Olivine City"] = {0.2}, ["Vermilion City_A"] = {0.2}, ["Canalave City"] = {0.2}}
EventMap["Vulcan Path"] = {["Vulcan Forest"] = {1}, ["Vulcan Island Shore"] = {1}}
EventMap["Vulcan Forest"] = {["Vulcan Path"] = {1}, ["Vulcanic Town"] = {1}, ["Mt. Summer Exterior 2"] = {1}}

EventMap["Mt. Summer Exterior 2"] = {["Vulcan Forest"] = {1}, ["Mt. Summer 1F 2"] = {1}}
EventMap["Mt. Summer 1F 2"] = {["Mt. Summer Exterior 2"] = {1}, ["Mt. Summer 2F 2"] = {1}}
EventMap["Mt. Summer 2F 2"] = {["Mt. Summer 1F 2"] = {1}, ["Mt. Summer 3F 2"] = {1}}
EventMap["Mt. Summer 3F 2"] = {["Mt. Summer 2F 2"] = {1}, ["Mt. Summer 4F 2"] = {1}}
EventMap["Mt. Summer 4F 2"] = {["Mt. Summer 3F 2"] = {1}}

EventMap["Alto Mare Shore"] = {["Vulcan Island Shore"] = {1}, ["Alto Mare"] = {1}}
EventMap["Alto Mare"] = {["Alto Mare Shore"] = {1}, ["Pokecenter Alto Mare"] = {1}, ["Alto Mare Pokemart"] = {1}, ["Alto Mare West Avenue"] = {1}, ["Vulcan Cove"] = {0.2}, ["Vulcanic Town"] = {0.2}, ["Vulcan Island Shore"] = {0.2}}
EventMap["Pokecenter Alto Mare"] = {["Alto Mare"] = {1}}
EventMap["Alto Mare Pokemart"] = {["Alto Mare"] = {1}}
--EventMap["Alto Mare East Avenue"] = {["Alto Mare"] = {1}, ["Alto Mare National Park"] = {1}}
EventMap["Alto Mare West Avenue"] = {["Alto Mare"] = {1}, ["Alto Mare National Park"] = {1}}
EventMap["Alto Mare National Park"] = { ["Alto Mare West Avenue"] = {1}}

EventMap["Vulcan Cove"] = {["Vulcan Island Shore"] = {0.2}, ["Vulcan Cave B1F"] = {1}, ["Vulcan Plaza"] = {1}, ["Vulcanic Town"] = {0.2}, ["Alto Mare"] = {0.2}}
EventMap["Vulcan Plaza"] = {["Vulcan Cove"] = {1}, ["Vulcan Plaza Pokecenter"] = {1}, ["Vulcan Plaza Pokemart"] = {1}, ["Vulcan Fair"] = {1}}
EventMap["Vulcan Plaza Pokecenter"] = {["Vulcan Plaza"] = {1}}
EventMap["Vulcan Plaza Pokemart"] = {["Vulcan Plaza"] = {1}}
EventMap["Vulcan Fair"] = {["Vulcan Plaza"] = {1}}

EventMap["Vulcan Cave B1F"] = {["Vulcan Cove"] = {1}, ["Vulcan Cave B2F"] = {1}}
EventMap["Vulcan Cave B2F"] = {["Vulcan Cave B1F"] = {1}}


-- Halloween Event
EventMap["Murky Town Ferry"] = {["Murky Town"] = {1}, ["Lilycove City"] = {1}, ["Olivine City"] = {1}, ["Vermilion City_B"] = {1}, ["Canalave City"] = {1}}
EventMap["Murky Town"] = {["Pokecenter Murky Town"] = {1}, ["Murky Town Ferry"] = {1}, ["Murky Path"] = {1}, ["Cemetery Island Ferry"] = {1}, ["Necropolis"] = {1}, ["Serenia Village"] = {1}, ["Ghoul Swamp"] = {1}}
EventMap["Pokecenter Murky Town"] = {["Murky Town"] = {1}}
EventMap["Ghoul Swamp"] = {["Murky Town"] = {1}, ["Unison Mountain South Summit"] = {1}}
EventMap["Unison Mountain South Summit"] = {["Ghoul Swamp"] = {1}, ["Pokecenter Unison Mountain"] = {1}, ["Unison Mountain 3F_A"] = {1}, ["Unison Mountain 1F"] = {1}, ["Sweetsland_A"] = {1}, ["Unison Mountain 3F_C"] = {1}}
EventMap["Pokecenter Unison Mountain"] = {["Unison Mountain South Summit"] = {1}}
EventMap["Unison Mountain 1F"] = {["Unison Mountain South Summit"] = {1}, ["Unison Mountain 2F"] = {1}}
EventMap["Unison Mountain 2F"] = {["Unison Mountain 1F"] = {1}, ["Unison Mountain East Summit"] = {1}}
EventMap["Unison Mountain East Summit"] = {["Unison Mountain 2F"] = {1}, ["Howling Woods"] = {1}}
EventMap["Howling Woods"] = {["Unison Mountain East Summit"] = {1}, ["Dreadtown"] = {1}}
EventMap["Unison Mountain 3F_A"] = {["Unison Mountain South Summit"] = {1}, ["Angel Hill"] = {1}}
EventMap["Unison Mountain 3F_B"] = {["Unison Mountain 3F_C"] = {1}, ["Sweetsland_A"] = {1}}
EventMap["Unison Mountain 3F_C"] = {["Unison Mountain South Summit"] = {1}, ["Unison Mountain 3F_B"] = {1}}
EventMap["Sweetsland_A"] = {["Unison Mountain South Summit"] = {1}, ["Unison Mountain 3F_B"] = {1}, ["Bittersweet Cave 1F_A"] = {1}, ["Bittersweet Cave 2F_A"] = {1}, ["Bittersweet Cave 2F_B"] = {1}, ["Bittersweet Cave 2F_C"] = {1}}
EventMap["Sweetsland_B"] = {["Bittersweet Cave 2F_A"] = {1}}
EventMap["Sweetsland_C"] = {["Bittersweet Cave 2F_B"] = {1}, ["Pokecenter Sweetsland"] = {1}, ["Bittersweet Cave 4F"] = {1}, ["Sweetsland_E"] = {1}, ["Sweetsland Pokemart"] = {1}}
EventMap["Sweetsland_D"] = {["Bittersweet Cave 3F"] = {1}}
EventMap["Sweetsland_E"] = {["Bittersweet Cave 1F_B"] = {1}, ["Unison Mountain Summit_A"] = {1}, ["Sweetsland_C"] = {1}}
EventMap["Pokecenter Sweetsland"] = {["Sweetsland_C"] = {1}}
EventMap["Sweetsland Pokemart"] = {["Sweetsland_C"] = {1}}
EventMap["Bittersweet Cave 1F_A"] = {["Sweetsland_A"] = {1}}
EventMap["Bittersweet Cave 1F_B"] = {["Bittersweet Cave 3F"] = {1}, ["Sweetsland_E"] = {1}}
EventMap["Bittersweet Cave 2F_A"] = {["Sweetsland_A"] = {1}, ["Sweetsland_B"] = {1}}
EventMap["Bittersweet Cave 2F_B"] = {["Sweetsland_A"] = {1}, ["Sweetsland_C"] = {1}, ["Bittersweet Cave 2F_C"] = {1}}
EventMap["Bittersweet Cave 2F_C"] = {["Sweetsland_A"] = {1}}
EventMap["Bittersweet Cave 3F"] = {["Bittersweet Cave 4F"] = {1}, ["Bittersweet Cave 1F_B"] = {1}, ["Sweetsland_D"] = {1}}
EventMap["Bittersweet Cave 4F"] = {["Sweetsland_C"] = {1}, ["Bittersweet Cave 3F"] = {1}}
EventMap["Unison Mountain Summit_A"] = {["Sweetsland_E"] = {1}, ["Unison Mountain Summit_B"] = {1}}
EventMap["Unison Mountain Summit_B"] = {["Unison Mountain Summit_A"] = {1}}
EventMap["Murky Path"] = {["Murky Town"] = {1}, ["Bone Pass"] = {1}}
EventMap["Bone Pass"] ={["Murky Path"] = {1}, ["Road Of Night"] = {1}, ["Sacred Forest"] = {1}}
EventMap["Sacred Forest"] = {["Bone Pass"] = {1}, ["Haunted house 1F"] = {1}}
EventMap["Haunted house 1F"] = {["Haunted house 2F"] = {1}, ["Sacred Forest"] = {1}}
EventMap["Haunted house 2F"] = {["Haunted house 1F"] = {1}, ["Haunted house 3F"] = {1}}
EventMap["Haunted house 3F"] = {["Haunted house 2F"] = {1}}
EventMap["Road Of Night"] ={["Bone Pass"] ={1}, ["Lost Seacoast"] = {1}}
EventMap["Lost Seacoast"] = {["Festival Town"] = {1}, ["Road Of Night"] = {1}}
EventMap["Spooky Path"] = {["Dreadtown Vlads House"] = {1}, ["Uncanny Path"] ={1}}
EventMap["Dreadtown Vlads House"] = {["Dreadtown"] = {1}, ["Spooky Path"] = {1}}
EventMap["Pokecenter Dreadtown"] = {["Dreadtown"] = {1}}
EventMap["Dreadtown"] = {["Pokecenter Dreadtown"] = {1}, ["Mart Dreadtown"] = {1},["Dreadtown Vlads House"] = {1}, ["Howling Woods"] = {1}}
EventMap["Mart Dreadtown"] = {["Dreadtown"] = {1}}
EventMap["Uncanny Path"] = {["Spooky Path"] = {1}, ["Necropolis"] = {1}}
EventMap["Pokecenter Necropolis"] = {["Necropolis"] = {1}}
EventMap["Necropolis"] = {["Dark Valley"] = {1}, ["Uncanny Path"] = {1}, ["Pokecenter Necropolis"] = {1}, ["Murky Town"] = {1}, ["Serenia Village"] = {1}, ["Cemetery Island Ferry"] = {1}}
EventMap["Dark Valley"] = {["Necropolis"] = {1}}
EventMap["Serenia Village"] = {["Murky Town"] = {1}, ["Necropolis"] = {1}, ["Cemetery Island Ferry"] = {1}, ["Angel Hill"] = {1}, ["Serenia Village Tunnel"] = {1}, ["Pokecenter Serenia Village"] = {1}}
EventMap["Pokecenter Serenia Village"] = {["Serenia Village"] = {1}}
EventMap["Angel Hill"] = {["Unison Mountain 3F_A"] = {1}, ["Serenia Village"] = {1}}
EventMap["Serenia Village Tunnel"] = {["Serenia Village"] = {1}, ["Unholy Sands South"] = {1}}
EventMap["Unholy Sands South"] = {["Serenia Village Tunnel"] = {1}, ["Unholy Sands"] = {1}}
EventMap["Unholy Sands"] = {["Unholy Sands South"] = {1}, ["Unholy Sands West"] = {1}}
EventMap["Unholy Sands West"] = {["Unholy Sands"] = {1}}
EventMap["Festival Town"] ={["Cemetery Island_A"] = {1},["Cemetery Island_B"] = {0.5}, ["Lost Seacoast"] = {1}, ["Mart Festival Town"] = {1}, ["Pokecenter Festival Town"] = {1}, ["Illusory Forest"] = {1}}
EventMap["Mart Festival Town"] = {["Festival Town"] = {1}}
EventMap["Pokecenter Festival Town"] = {["Festival Town"] = {1}}
EventMap["Illusory Forest"] = {["Festival Town"] = {1}}
EventMap["Cemetery Island Ferry"] = {["Murky Town"] = {1}, ["Cemetery Island_B"] = {1}, ["Necropolis"] = {1}, ["Serenia Village"] = {1}}
EventMap["Cemetery Island_A"] = {["Festival Town"] = {1}, ["Haunted Cave_A"] = {1}, ["Cemetery Island_B"] = {1}}
EventMap["Cemetery Island_B"] = {["Festival Town"] = {1}, ["Haunted Cave_B"] = {1}, ["Cemetery Island_A"] = {1}, ["Cemetery Island Ferry"] = {1}, ["Memorial Tower 1F"] = {1}}
EventMap["Haunted Cave_A"] = {["Haunted Cave_B"] = {1}, ["Cemetery Island_A"] = {1}}
EventMap["Haunted Cave_B"] = {["Cemetery Island_B"] = {1}}
EventMap["Memorial Tower 1F"] = {["Cemetery Island_B"] = {1}, ["Memorial Tower 2F"] = {1}}
EventMap["Memorial Tower 2F"] = {["Memorial Tower 1F"] = {1}}
-- Christmas Event
EventMap["Cryofrost Brink"] = {["Cryofrost Town"] = {1}, ["Snowfall Valley"] = {1}}
EventMap["Cryofrost Path_A"] = {["Cryofrost Path_B"] = {1, {["abilities"] = {"cut"}}}, ["Cryofrost Path Costume Mart"] = {1}, ["Flake Wood"] = {1}, ["Frost Valley"] = {1}}
EventMap["Cryofrost Path_B"] = {["Cryofrost Path_A"] = {1, {["abilities"] = {"cut"}}}, ["Cryofrost Town"] = {1}}
EventMap["Cryofrost Path Costume Mart"] = {["Cryofrost Path_A"] = {1}}
EventMap["Cryofrost Town"] = {["Cryofrost Brink"] = {1}, ["Cryofrost Path_B"] = {1}, ["Mart Cryofrost Town"] = {1}, ["Pokecenter Cryofrost Town"] = {1}}
EventMap["Flake Wood"] = {["Cryofrost Path_A"] = {1}, ["Viridian City"] = {1}}
EventMap["Frost Valley"] = {["Cryofrost Path_A"] = {1}, ["Frozen Cave Entrance_A"] = {1}}
EventMap["Frozen Cave B1F"] = {["Frozen Cave B2F_B"] = {1}, ["Frozen Cave B2F_C"] = {1}}
EventMap["Frozen Cave B2F_A"] = {["Frozen Cave B2F_B"] = {1, {["abilities"] = {"surf"}}}, ["Frozen Cave Entrance_B"] = {1}}
EventMap["Frozen Cave B2F_B"] = {["Frozen Cave B1F"] = {1}, ["Frozen Cave B2F_A"] = {1, {["abilities"] = {"surf"}}}}
EventMap["Frozen Cave B2F_C"] = {["Frozen Cave B1F"] = {1}}
EventMap["Frozen Cave Entrance_A"] = {["Frost Valley"] = {1}, ["Frozen Cave Entrance_B"] = {1}}
EventMap["Frozen Cave Entrance_B"] = {["Frozen Cave Entrance_A"] = {1}, ["Frozen Cave B2F_A"] = {1}}
EventMap["Mart Cryofrost Town"] = {["Cryofrost Town"] = {1}}
EventMap["Pokecenter Cryofrost Town"] = {["Cryofrost Town"] = {1}}
EventMap["Snowfall Valley"] = {["Cryofrost Brink"] = {1}}
EventMap["Viridian City"] = {["Flake Wood"] = {1}}

--Pinkan
EventMap["Pinkan City"] = {["Pinkan Island Forest"] = {1}, ["Pokecenter Pinkan City"] = {1}, ["Pokemart Pinkan City"] = {1}, ["Pinkan Island Peaks"] = {1}, ["Vermilion City_A"]= {1}, ["Pinkan Lighthouse 1F"]= {1}}
EventMap["Pokecenter Pinkan City"] = {["Pinkan City"] = {1}}
EventMap["Pokemart Pinkan City"] = {["Pinkan City"] = {1}}
EventMap["Pinkan Island Forest"] = {["Pinkan City"] = {1}, ["Pinkan Island Meadow_A"] = {1}, ["Pinkan Island Cliff"] = {1}, ["Pinkan Island Cave_A"] = {1}}
EventMap["Pinkan Island Cliff"] = {["Pinkan Island Forest"] = {1}}
EventMap["Pinkan Island Meadow_A"] = {["Pinkan Island Forest"] = {1}, ["Pinkan Island Meadow Tunnel"] = {1}}
EventMap["Pinkan Island Meadow Tunnel"] = {["Pinkan Island Meadow_A"] = {1}, ["Pinkan Island Meadow_B"] = {1}}
EventMap["Pinkan Island Meadow_B"] = {["Pinkan Island Meadow Tunnel"] = {1}}
EventMap["Pinkan Island Cave_A"] = {["Pinkan Island Forest"] = {1}, ["Pinkan Island Cave_B"] = {1}}
EventMap["Pinkan Island Cave_B"] = {["Pinkan Island Path"] = {1}}
EventMap["Pinkan Island Path"] = {["Pinkan Island Cave_B"] = {1}, ["Pinkan Island Woodlands"] = {1}}
EventMap["Pinkan Island Woodlands"] = {["Pinkan Island Path"] = {1}, ["Pinkan Island Island Woodlans East"] = {1}, ["Pinkan Island Island Woodlans West"] = {1}, ["Pinkan Island Woodlands Clearing"] = {1}}
EventMap["Pinkan Island Island Woodlans East"] = {["Pinkan Island Woodlands"] = {1}}
EventMap["Pinkan Island Island Woodlans West"] = {["Pinkan Island Woodlands"] = {1}}
EventMap["Pinkan Island Woodlands Clearing"] = {["Pinkan Island Woodlands"] = {1}, ["Pinkan Island Vale"] = {1}}
EventMap["Pinkan Island Vale"] = {["Pinkan Island Woodlands Clearing"] = {1}, ["Pinkan Island Mountains"] = {1}}
EventMap["Pinkan Island Mountains"] = {["Pinkan Island Vale"] = {1}, ["Pinkan Island Peaks"] = {1}}
EventMap["Pinkan Island Peaks"] = {["Pinkan Island Mountains"] = {1}, ["Pinkan City"] = {1}}
EventMap["Pinkan Lighthouse 1F"] = {["Pinkan City"] = {1}, ["Pinkan Lighthouse Elevator"] = {1}}
EventMap["Pinkan Lighthouse Elevator"] = {["Pinkan Lighthouse 1F"] = {1}, ["Pinkan Lighthouse 2F"] = {1}}
EventMap["Pinkan Lighthouse 2F"] = {["Pinkan Lighthouse Elevator"] = {1}}
--Matsuki Island (Quai thu co sung`)
EventMap["Matsuki Village"] = {["Matsuki Castle"] = {1}, ["Wastelands"] = {1}, ["Pokecenter Matsuki Village"] = {1}}
EventMap["Pokecenter Matsuki Village"] = {["Matsuki Village"] = {1}}
EventMap["Matsuki Castle"] = {["Matsuki Village"] = {1}, ["Matsuki Courtyard"] = {1}}
EventMap["Matsuki Courtyard"] = {["Matsuki Castle"] = {1}, ["Crystal Cavern"] = {1}}
EventMap["Crystal Cavern"] = {["Matsuki Courtyard"] = {1}}
EventMap["Wastelands"] = {["Matsuki Village"] = {1}, ["Forest Dungeon Entrance"] = {1}, ["Mountain Area Dungeon"] = {1}}
EventMap["Forest Dungeon Entrance"] = {["Forest Maze"] = {1}, ["Wastelands"] = {1}}
EventMap["Forest Maze"] = {["Forest Maze Underground"] = {1}, ["Forest Dungeon Entrance"] = {1}}
EventMap["Forest Maze Underground"] = {["Forest Maze"] = {1}}
EventMap["Mountain Area Dungeon"] = {["Wastelands"] = {1}, ["Mountain Area Maze"] = {1}}
EventMap["Mountain Area Maze"] = {["Mountain Area Dungeon"] = {1}}

--Crater Town
EventMap["Crater Town Shore"] = {["Slateport City"] = {1}, ["Crater Town"] = {1}}
EventMap["Crater Town"] = {["Crater Town Shore"] = {1}, ["Crater Town Pokecenter"] = {1}, ["Crater Town Tunnel"] = {1}}
EventMap["Crater Town Pokecenter"] = {["Crater Town"] = {1}}
EventMap["Crater Town Tunnel"] = {["Crater Town"] = {1}}

--Munchlax Resort
EventMap["Munchlax Resort"] = {["Vermilion City_A"] = {1}, ["Fluffles Wonderland"] = {1}}
EventMap["Fluffles Wonderland"] = {["Munchlax Resort"] = {1}}



-- EventMap["node"] = {["link"] = {distance, {["restrictionType"] = {"restriction"}}}}
return EventMap
end

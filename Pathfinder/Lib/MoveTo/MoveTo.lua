local cpath = select(1, ...) or "" -- callee path
local function nTimes(n, f, x) for i = 0, n - 1 do x = f(x) end return x end -- calls n times f(x)
local function rmlast(str) return str:sub(1, -2):match(".+[%./]") or "" end -- removes last dir / file from the callee path
local cppdpath = nTimes(3, rmlast, cpath) -- callee parent of parent dir path
local cpppdpath = rmlast(cppdpath) -- callee parent parent of parent dir path

local aStar               = require (cppdpath .. "Lib/lua-astar/AStar")
local Lib                 = require (cppdpath .. "Lib/Lib")
local Game                = require (cppdpath .. "Lib/Game")
local Table               = require (cppdpath .. "Lib/Table")
local Work                = require (cppdpath .. "Lib/Work")
local _ss                 = require (cpppdpath .. "Settings/Static_Settings")
local _globalMap          = require (cppdpath .. "Maps/GlobalMap")
local subMaps             = require (cppdpath .. "Maps/MapExceptions/SubstituteMaps")
local mapLinks            = require (cppdpath .. "Maps/MapLink")
local linkExceptions      = require (cppdpath .. "Maps/MapExceptions/LinkExceptions")
local _npcExceptions      = require (cppdpath .. "Maps/MapExceptions/NpcExceptions")
local digways             = require (cppdpath .. "Maps/MapExceptions/Digways")
local mapExceptions       = require (cppdpath .. "Maps/MapExceptions/MapExceptions")
local dialogSolver        = require (cppdpath .. "Lib/MoveTo/DialogSolver")
-- CellCrawl (tự học link theo ô) đã bị tắt: dùng bản giả rỗng để không còn log/hook của nó.
local cellCrawl          = {
    attachPathfinder = function() end,
    getLearnedLinks = function() return {} end,
    logLearnedLinks = function() end,
    setMaxSourceLinkDistance = function() end,
}
local elevatorExceptions  = require (cppdpath .. "Maps/MapExceptions/Elevators")
-- SpawnData is only needed by getMapToPokemon(). Loading it here made every
-- Pathfinder script parse the whole hunt database during startup.
local spawnDataPath       = cppdpath .. "Spawn/SpawnData"
local spawnData           = nil
local function getSpawnDataIndex()
    if spawnData == nil then
        spawnData = require(spawnDataPath)
    end
    return spawnData
end
local transmatExceptions  = require (cppdpath .. "Maps/MapExceptions/Transmats")
local moveAbilities       = {["cut"] = 0, ["surf"] = 0, ["dig"] = 155, ["rock smash"] = 0, ["dive"] = 155}
local workAbilities       = {["headbutt"] = 155, ["dig"] = 0}
local moveItems           = {"Fresh Water", "Marsh Badge", "Zephyr Badge", "Bicycle", "Go-Goggles", "Green Bicycle", "Blue Bicycle", "Yellow Bicycle"}
local globalMap           = {}
local pathSolution        = {}
local settings            = {}
local destStore           = ""
local npcExceptions       = nil
local outlet              = nil
local playerNode          = nil
local from                = nil
local toMap               = nil
local digIndex            = nil
local walkingCheckpoints  = {}

-----------------------------------
----- A* NECESSARY  FUNCTIONS -----
-----------------------------------

-- checks if the link restrictions are matched depending on your team / items.
local function isLinkRestrictionMatched(data)
    if data.items then
        for _, item in ipairs(data.items) do
            if not settings.accountItems[item] then
                return false
            end
        end
    elseif data.abilities then
        for _, ability in ipairs(data.abilities) do
            if not settings.abilitiesIndex[ability] or ability == "dig" and not settings.dig then
                return false
            end
        end
    else error("Pathfinder --> Unknown link restriction.")
    end
    return true
end

-- check for subway paths in Kanto or Johto.
local function isSubwayPath(n1, n2)
    return type(n1) == "string" and type(n2) == "string"
        and string.find(n1, "Subway", 1, true) ~= nil
        and string.find(n2, "Subway", 1, true) ~= nil
end

local function getTransportType(n1, n2)
    if isSubwayPath(n1, n2) then
        return "subway"
    end
    if n1 == "Transmat Station" or n1 == "Transmat Station Sinnoh" then
        return "teleport"
    end
    return nil
end

local function isTransportAvailable(transportType)
    if transportType == nil then
        return true
    end
    return settings.transportAvailable == nil
        or settings.transportAvailable[transportType] ~= false
end

-- return a new table containing only valid links
local function getUsableLinks(fromNode, links)
    local usableLinks = {}
    for link, data in pairs(links) do
        assert(type(data) == "table", "Pathfinder --> Link " .. link .. " data is not a table")
        local isTransportValid = isTransportAvailable(getTransportType(fromNode, link))
        local isLinkValid = isTransportValid and #data == 1
        for i = 2, #data do
            if isTransportValid and isLinkRestrictionMatched(data[i]) then
                isLinkValid = true
                break;
            end
        end
        if isLinkValid then
            usableLinks[#usableLinks + 1] = link
        end
    end
    return usableLinks
end

-- return a table of node, linked to the node n
local function expand(n)
    assert(type(globalMap[n]) == "table", "Pathfinder --> Received node \"" .. n .. "\" doesn't exist in the map.")
    return getUsableLinks(n, globalMap[n])
end

-- Take 2 nodes return dist
local function cost(from, to)
    if type(globalMap[from][to]) == "table" then
        return globalMap[from][to][1]
    end
    return globalMap[from][to]
end

-- return estimated cost of goal, 0 is dijkstra
local function heuristic(n)
    return 0
end

-- return true if destination is reached
local function goal(targets)
    return function(current)
        return Lib.inTable(targets, current)
    end
end

-- call simplification
local simpleAStar = aStar(expand)(cost)(heuristic)

local function refreshTransportAvailability()
    settings.transportConfigured = settings.transportConfigured or {
        subway = true,
        teleport = true,
    }
    settings.transportAvailable = {
        subway = settings.transportConfigured.subway ~= false,
        teleport = settings.transportConfigured.teleport ~= false,
    }
end

---------------------------
--- EXCEPTION  HANDLING ---
---------------------------

-- check for exceptions in table
local function exceptionExist(t, n1, n2)
    return t[n1] and t[n1][n2]
end

local function solveElevatorExce(n1, n2)
    local exce = elevatorExceptions[n1][n2]
    if exce[5] then
        exce[5] = false
        return assert(moveToCell(table.unpack(exce[6])), "Pathfinder --> Error: Elevator exception failed on moving to map for: " .. n1 .. " -> " .. n2)
    else return assert(talkToNpcOnCell(table.unpack(exce[1])), "Pathfinder --> Error: Elevator exception invalid for talking to npc on map: " .. n1 .. " -> " .. n2)
    end
end

local function solveTransmatExce(n2)
    local destination = transmatExceptions.destinations[n2]
    if destination == nil then
        log("Pathfinder --> No Transmat dialog configuration for destination: " .. tostring(n2))
        return false
    end

    if destination.state then
        destination.state = false
        return assert(moveToCell(9, 10), "Pathfinder --> Failed to exit Transmat Station.")
    end
    return assert(talkToNpcOnCell(4, 4), "Pathfinder --> Failed to talk to npc in Transmat Station")
end

local function solveMapExce(mapExceptions, n1, n2)
    local exception = mapExceptions[n1][n2]
    local coords = exception[1]
    if #coords == 2 then
        -- A two-way scripted link does not fire again while the player is still
        -- standing on its arrival cell.  An optional second cell lets us step
        -- off once; the following tick can then step back onto the link.
        if getPlayerX() == coords[1] and getPlayerY() == coords[2] and exception[2] then
            local reset = exception[2]
            return assert(moveToCell(reset[1], reset[2]),
                "Pathfinder --> Error: could not reset map link for: " .. n1 .. " -> " .. n2)
        end
        return assert(moveToCell(coords[1], coords[2]),
            "Pathfinder --> Error: moveToCell invalid for: " .. n1 .. " -> " .. n2)
    elseif #coords == 4 then
        return assert(moveToRectangle(coords[1], coords[2], coords[3], coords[4]),
            "Pathfinder --> Error: moveToRectangle invalid for: " .. n1 .. " -> " .. n2)
    else
        error("Pathfinder --> Error: Unsupported coordinates format for: " .. n1 .. " -> " .. n2)
    end
end

-- check if the nodes are the same map
local function isSameMap(n1, n2)
    return n1:gsub("_%u$", "") == n2:gsub("_%u$", "")
end

-- check if the nodes are the same map
local function isDestination(n1, n2)
    return n1:gsub("_%u$", "") == n2:gsub("_%u$", "") and not exceptionExist(npcExceptions, n1, n2) and not exceptionExist(digways, n1, n2) and not exceptionExist(mapExceptions, n1, n2)
end

-- skip nodes in the path if they are the same map and no exception exist between them
-- return the next destination node and her predecessor for exception handling.
local function getNextNodes()
    local from = playerNode
    while pathSolution[1] and isSameMap(playerNode, pathSolution[1]) do
        local toMap = pathSolution[1]
        -- log(exceptionExist(digways, from, toMap))
        if exceptionExist(npcExceptions, from, toMap) or exceptionExist(digways, from, toMap) or exceptionExist(mapExceptions, from, toMap) then
            return from, toMap
        end
        from = pathSolution[1]
        table.remove(pathSolution, 1)
    end
    return from, pathSolution[1]
end

-- check for exceptions from n1 to n2, and solve it
local function handleException(n1, n2)
	if exceptionExist(npcExceptions, n1, n2) then
        return assert(talkToNpcOnCell(table.unpack(npcExceptions[n1][n2][1])), "Pathfinder --> Error: Exception invalid for: " .. n1 .. " -> " .. n2)
    elseif exceptionExist(elevatorExceptions, n1, n2) then
        return solveElevatorExce(n1, n2)
    elseif exceptionExist(digways, n1, n2) then
        return assert(talkToNpcOnCell(table.unpack(digways[n1][n2][1])), "Pathfinder --> Error: Exception invalid for: " .. n1 .. " -> " .. n2)
    elseif exceptionExist(mapExceptions, n1, n2) then
        return solveMapExce(mapExceptions, n1, n2)
    elseif isSubwayPath(n1, n2) then
        return talkToNpcOnCell(10, 9)
    elseif n1 == "Transmat Station" or n1 == "Transmat Station Sinnoh" then
        return solveTransmatExce(n2)
    end
end

-- return the node coresponding to the current player pos. Also used to return the current map, with submap tag if applicable
local function getPlayerNode(map)
	map = map or getMapName()
	local playerInRectangle = Lib.inRectangle(getPlayerX(), getPlayerY())
	if subMaps[map] then
		for subMap, locs in pairs(subMaps[map]) do
			for _, rect in ipairs(locs) do
				if playerInRectangle(table.unpack(rect)) then
					return subMap
				end
			end
		end
		error("Pathfinder --> sub map could not be defined, map: " .. map .. "  x: " .. getPlayerX() .. "  y: " .. getPlayerY())
	end
	assert(globalMap[map], "Pathfinder -> Location does not exist in the map: " .. tostring(map))
	return map
end

-- return the node coresponding to the current player pos. Also used to return the current map, with submap tag if applicable
local function getMapNode(map, x, y)
	map = map or getMapName()
	local playerInRectangle = Lib.inRectangle(x, y)
	if subMaps[map] then
		for subMap, locs in pairs(subMaps[map]) do
			for _, rect in ipairs(locs) do
				if playerInRectangle(table.unpack(rect)) then
					return subMap
				end
			end
		end
		error("Pathfinder --> sub map could not be defined, map: " .. map .. "  x: " .. getPlayerX() .. "  y: " .. getPlayerY())
	end
	return map
end

-- create a new list replacing maps by all nodes corresponding to them
local function mapsToNodes(mapList)
    local nodeList = {}
    if type(mapList) == "string" then
        mapList = {mapList}
    end
    for _, map in pairs(mapList) do
        if subMaps[map] then  -- if the map has sub maps
            for submap, _ in pairs(subMaps[map]) do
                table.insert(nodeList, submap)
            end
        elseif globalMap[map] then
            table.insert(nodeList, map)
        else error("Pathfinder -> Requested dest does not exist in the map : " .. map)
        end
    end
    return nodeList
end


---------------------
-- DISCOVERING OUTLET
---------------------

local function unsetOutlet()
    outlet = nil
end

local function setOutlet()
    outlet = {}
    outlet.node = toMap
    outlet.fromNode = playerNode
    outlet.found = false
end

local function outletInNode()
    return outlet and playerNode == outlet.node
end

-- discover outlet if possible
local function checkOutlet()
    if outletInNode() then
        return assert(talkToNpcOnCell(table.unpack(digways[playerNode][outlet.fromNode][1])), "Pathfinder -> could not discover outlet, node: " .. playerNode .. " -> " .. outlet.fromNode)
    end
    return false
end

---------------------------
--- FUNCTION FOR MOVETO ---
---------------------------

-- reset path
local function resetPath()
	destStore = ""
	walkingCheckpoints = {}
	from = nil
	toMap = nil
end

local function pointToRectangleDistance(x, y, target)
    if type(target) ~= "table" then
        return nil
    end

    local x1 = tonumber(target[1])
    local y1 = tonumber(target[2])
    local x2 = tonumber(target[3]) or x1
    local y2 = tonumber(target[4]) or y1
    if x1 == nil or y1 == nil or x2 == nil or y2 == nil then
        return nil
    end

    local minX, maxX = math.min(x1, x2), math.max(x1, x2)
    local minY, maxY = math.min(y1, y2), math.max(y1, y2)
    local dx = x < minX and minX - x or (x > maxX and x - maxX or 0)
    local dy = y < minY and minY - y or (y > maxY and y - maxY or 0)
    return dx + dy
end

-- MapLink may contain several doors/exits for the same destination. The old
-- implementation selected one randomly, which could send the player across a
-- large city unnecessarily. Select the closest valid cell/rectangle instead.
local function getNearestMapLink(linkList, x, y)
    if type(linkList) ~= "table" then
        return nil
    end

    local nearest, nearestDistance = nil, math.huge
    for _, target in ipairs(linkList) do
        local distance = pointToRectangleDistance(x, y, target)
        if distance ~= nil and distance < nearestDistance then
            nearest = target
            nearestDistance = distance
        end
    end
    return nearest, nearestDistance
end

local function closestPointOnTarget(x, y, target)
    if type(target) ~= "table" then
        return nil
    end
    local x1 = tonumber(target[1])
    local y1 = tonumber(target[2])
    local x2 = tonumber(target[3]) or x1
    local y2 = tonumber(target[4]) or y1
    if x1 == nil or y1 == nil or x2 == nil or y2 == nil then
        return nil
    end

    return {
        x = math.max(math.min(x, math.max(x1, x2)), math.min(x1, x2)),
        y = math.max(math.min(y, math.max(y1, y2)), math.min(y1, y2)),
    }
end

local function targetCentre(target)
    -- A few legacy MapLink entries are weight-only placeholders rather than
    -- { x, y } / { x1, y1, x2, y2 } coordinates. They are still traversable
    -- through the authored graph, but cannot supply an arrival coordinate.
    if type(target) ~= "table" then
        return nil
    end
    local x1 = tonumber(target[1])
    local y1 = tonumber(target[2])
    local x2 = tonumber(target[3]) or x1
    local y2 = tonumber(target[4]) or y1
    if x1 == nil or y1 == nil or x2 == nil or y2 == nil then
        return nil
    end
    return {
        x = math.floor((x1 + x2) / 2),
        y = math.floor((y1 + y2) / 2),
    }
end

-- Map graph costs describe service/restriction weights.  For regular walking
-- edges, refine that coarse value with the actual distance from the current
-- entry point to the selected MapLink cell.  This replaces random exits with
-- a deterministic shortest walking segment without loading other map files.
local FALLBACK_WALKING_DISTANCE = 20

-- true  = đường "chuẩn": chỉ dùng chi phí đã khai báo trong KantoMap/GlobalMap,
--         không phụ thuộc vị trí bot đang đứng (kết quả luôn giống nhau).
-- false = đường "gần nhất": cộng thêm khoảng cách thật tới cửa (hành vi cũ).
local USE_GRAPH_COST_ONLY = true

local function walkingSegment(fromNode, toNode, x, y)
    if USE_GRAPH_COST_ONLY then
        return tonumber(cost(fromNode, toNode)) or 1, nil, nil
    end
    local linkList = mapLinks[fromNode] and mapLinks[fromNode][toNode]
    if x ~= nil and y ~= nil and linkList ~= nil then
        local target, distance = getNearestMapLink(linkList, x, y)
        if target ~= nil then
            return math.max(1, distance) + (tonumber(cost(fromNode, toNode)) or 1),
                target, closestPointOnTarget(x, y, target)
        end
    end
    return math.max(1, tonumber(cost(fromNode, toNode)) or 1)
        * FALLBACK_WALKING_DISTANCE, nil, nil
end

local function entryPointsFor(nextNode, fromNode, exitPoint)
    if USE_GRAPH_COST_ONLY then
        return { { x = nil, y = nil } }
    end
    if exitPoint ~= nil and isSameMap(fromNode, nextNode) then
        return { exitPoint }
    end

    local reverseLinks = mapLinks[nextNode] and mapLinks[nextNode][fromNode]
    local entries = {}
    if type(reverseLinks) == "table" then
        for _, target in ipairs(reverseLinks) do
            local centre = targetCentre(target)
            if centre ~= nil then
                entries[#entries + 1] = centre
            end
        end
    end

    -- One-way warps and special transitions have no reverse map link.  Keep a
    -- single unknown entry state and use the authored graph weight next time.
    if #entries == 0 then
        entries[1] = { x = nil, y = nil }
    end
    return entries
end

local function routeStateKey(node, x, y)
    return tostring(node) .. "\30" .. tostring(x or "?") .. ":" .. tostring(y or "?")
end

local function newPriorityQueue()
    return { size = 0 }
end

local function pushPriority(queue, priority, key)
    local index = queue.size + 1
    queue.size = index
    queue[index] = { priority = priority, key = key }
    while index > 1 do
        local parent = math.floor(index / 2)
        if queue[parent].priority <= priority then
            break
        end
        queue[index] = queue[parent]
        index = parent
    end
    queue[index] = { priority = priority, key = key }
end

local function popPriority(queue)
    if queue.size == 0 then
        return nil
    end

    local result = queue[1]
    local last = queue[queue.size]
    queue[queue.size] = nil
    queue.size = queue.size - 1
    if queue.size > 0 then
        local index = 1
        while true do
            local left = index * 2
            local right = left + 1
            local child = left
            if right <= queue.size and queue[right].priority < queue[left].priority then
                child = right
            end
            if child > queue.size or queue[child].priority >= last.priority then
                break
            end
            queue[index] = queue[child]
            index = child
        end
        queue[index] = last
    end
    return result
end

local function rebuildRoute(lastKey, states, cameFrom)
    local reversed = {}
    local key = lastKey
    while key ~= nil do
        reversed[#reversed + 1] = states[key].node
        key = cameFrom[key]
    end

    local path = {}
    for index = #reversed, 1, -1 do
        path[#path + 1] = reversed[index]
    end
    return path
end

-- Dijkstra over map-entry states. A state includes the current map node and
-- the known entry cell, allowing each walking map segment to be scored by real
-- local distance. Transport edges retain their configured Static_Settings
-- weights, and disabled services are filtered by getUsableLinks().
local function getTravelPath(startNode, targets)
    local targetSet = {}
    for _, target in ipairs(targets) do
        targetSet[target] = true
    end
    if targetSet[startNode] then
        return { startNode }, 0
    end

    local startX, startY = getPlayerX(), getPlayerY()
    if USE_GRAPH_COST_ONLY then startX, startY = nil, nil end
    local startKey = routeStateKey(startNode, startX, startY)
    local states = {
        [startKey] = { node = startNode, x = startX, y = startY },
    }
    local scores = { [startKey] = 0 }
    local cameFrom = { [startKey] = nil }
    local open = newPriorityQueue()
    pushPriority(open, 0, startKey)

    while true do
        local openEntry = popPriority(open)
        while openEntry ~= nil and scores[openEntry.key] ~= openEntry.priority do
            openEntry = popPriority(open)
        end
        if openEntry == nil then
            return nil, math.huge
        end
        local stateKey = openEntry.key

        local state = states[stateKey]
        if targetSet[state.node] then
            return rebuildRoute(stateKey, states, cameFrom), scores[stateKey]
        end

        local links = globalMap[state.node]
        assert(type(links) == "table", "Pathfinder --> Received node \""
            .. tostring(state.node) .. "\" doesn't exist in the map.")
        for _, nextNode in ipairs(getUsableLinks(state.node, links)) do
            local transportType = getTransportType(state.node, nextNode)
            local segmentCost, exitPoint
            if transportType ~= nil then
                segmentCost = tonumber(cost(state.node, nextNode)) or 1
            else
                segmentCost, _, exitPoint = walkingSegment(state.node, nextNode,
                    state.x, state.y)
            end

            for _, entryPoint in ipairs(entryPointsFor(nextNode, state.node, exitPoint)) do
                local nextKey = routeStateKey(nextNode, entryPoint.x, entryPoint.y)
                local newCost = scores[stateKey] + segmentCost
                if scores[nextKey] == nil or newCost < scores[nextKey] then
                    states[nextKey] = {
                        node = nextNode,
                        x = entryPoint.x,
                        y = entryPoint.y,
                    }
                    scores[nextKey] = newCost
                    cameFrom[nextKey] = stateKey
                    pushPriority(open, newCost, nextKey)
                end
            end
        end
    end
end

local function buildWalkingCheckpoints(path)
    walkingCheckpoints = {}
    if type(path) ~= "table" then
        return
    end

    for index = 1, #path - 1 do
        local fromNode, toNode = path[index], path[index + 1]
        if getTransportType(fromNode, toNode) == nil then
            walkingCheckpoints[#walkingCheckpoints + 1] = {
                from = fromNode,
                to = toNode,
            }
        end
    end
end

local function logWalkingCheckpoints()
    if #walkingCheckpoints == 0 then
        return
    end

    local labels = {}
    for _, checkpoint in ipairs(walkingCheckpoints) do
        labels[#labels + 1] = checkpoint.from .. " -> " .. checkpoint.to
    end
    log("Pathfinder: walking checkpoints: " .. table.concat(labels, " | "))
end

local function errorInPath(from, toMap)
	resetPath()
	Lib.log1time("Pathfinder --> Error in Path: from " .. from .. " to " .. toMap .. " -- Reset and Recalc")
	swapPokemon(getTeamSize(), getTeamSize() - 1)
end

-- try to move with exception, and with the map name if no exception are found.
local function movingApply(from, toMap)
	if not isSameMap(from, getMapName()) then
		-- Unexpectedly changed maps, could be due to black-out or moveToGrass/Water/NormalGround putting us on a link
		errorInPath(from, toMap)
		return true
	end
	Lib.log1time("Path: Maps Remains: " .. #pathSolution .. "  Moving To: --> " .. toMap)
	if handleException(from, toMap) then
		return true
	elseif mapLinks[from] and mapLinks[from][toMap] then
		local mapLink = mapLinks[from][toMap]
		local target = getNearestMapLink(mapLink, getPlayerX(), getPlayerY())
		if target == nil then
			log("Pathfinder: no usable walking checkpoint for "
				.. tostring(from) .. " -> " .. tostring(toMap) .. ".")
			return false
		elseif #target == 2 then
			local okCell = moveToCell(target[1], target[2])
			if not okCell then
				log("Pathfinder: moveToCell(" .. target[1] .. "," .. target[2] .. ") không đi được cho "
					.. tostring(from) .. " -> " .. tostring(toMap)
					.. " | vị trí=(" .. getPlayerX() .. "," .. getPlayerY() .. ")")
			end
			return okCell
		end
		local okRect = moveToRectangle(target[1], target[2], target[3], target[4])
		if not okRect then
			log("Pathfinder: moveToRectangle không đi được cho "
				.. tostring(from) .. " -> " .. tostring(toMap)
				.. " | vị trí=(" .. getPlayerX() .. "," .. getPlayerY() .. ")")
		end
		return okRect
	end
	-- Không có MapLink cho cặp node này: không có bước đi nào được thực hiện, nên
	-- không được báo là đã có action (trước đây return true làm bot tự dừng).
	log("Pathfinder: không có MapLink cho " .. tostring(from) .. " -> " .. tostring(toMap)
		.. " | vị trí=(" .. getPlayerX() .. "," .. getPlayerY() .. ")")
	return false
end

-- remove already crossed nodes then try to move
local function moveWithCalcPath()
    if #pathSolution > 0 then
        if pathSolution[1] == playerNode then
            table.remove(pathSolution, 1)
            from, toMap = getNextNodes()
            if #pathSolution > 0 then
                return movingApply(from, toMap)
            end
            log("Pathfinder: Destination Reached.")
			-- Release dialog ownership as soon as the authoritative map reaches
			-- the destination. Questing remains responsible for the next step.
			from = nil
			toMap = nil
            return false
        else
            return movingApply(from, toMap)
        end
    end
    return false
end

---------------------------
-------- SETTINGS ---------
---------------------------

-- check if the player can use TM / HM moves.
local function validateAbilitiesIndex(dirtyList, abilityList)
    local pokeIndexTable = {}
    local teamSize = getTeamSize()
    for ability, happinessReq in pairs(abilityList) do
        if ability == "dig" and hasItem("Shovel") then
            pokeIndexTable[ability] = 1
        elseif ability == "cut" and hasItem("Tree Axe") then
            pokeIndexTable[ability] = 1
        elseif ability == "rock smash" and hasItem("Pick Axe") then
            pokeIndexTable[ability] = 1
        elseif ability == "surf" then
            pokeIndexTable[ability] = 1
        else
             local pokeIndex = dirtyList[ability]
            if not pokeIndex or teamSize < pokeIndex or not hasMove(pokeIndex, ability) or not (getPokemonHappiness(pokeIndex) > happinessReq) then
                pokeIndexTable[ability] = Game.getPokemonNumberWithMove(ability, happinessReq)
            else pokeIndexTable[ability] = pokeIndex
            end
        end

    end
    return pokeIndexTable
end

-- check if the account has items. We assume items previously validated are always true, to limit API calls.
local function validateItems(currentItems, items)
    local accountItems = {}
    currentItems = currentItems or {}
    for _, item in ipairs(items) do
        if not currentItems[item] then
            accountItems[item] = hasItem(item)
        end
    end
    return accountItems
end

-- init setting on start, uses preset and bot team / items
local function initSettings(ss)
    settings.abilitiesIndex = validateAbilitiesIndex({}, moveAbilities)
    settings.mount = ss.MOUNT
    settings.dig = true
    settings.workOpts = {
    ["dig"] = ss.DIG,
    ["harvest"] = ss.HARVEST,
    ["headbutt"] = ss.HEADBUTT,
    ["discover"] = ss.DISCOVER
    }
    settings.transportConfigured = {
        subway = ss.USE_SUBWAY ~= false,
        teleport = ss.USE_TELEPORT ~= false,
    }
    if settings.workOpts.headbutt and not Game.getPokemonNumberWithMove("Headbutt", 151) then
        log("Pathfinder: Warning, cannot Headbutt trees.")
    end
    if settings.workOpts.dig and not Game.getPokemonNumberWithMove("Dig", 151) then
        log("Pathfinder: Warning, cannot Dig.")
    end
    refreshTransportAvailability()
end

-- try to find a path changing settings
local function findSettings(dest)
    local message = "Pathfinder --> Path Not Found ERROR. From " .. playerNode .. " to " .. destStore .. "."

    for ability, _ in pairs(moveAbilities) do
        if not settings.abilitiesIndex[ability] then
            settings.abilitiesIndex[ability] = 1
            if simpleAStar(goal(dest))(playerNode) then
                error(message .. " A Pokemon with the move " .. ability .. " would open a path.")
            end
        end
    end
    for _, item in ipairs(moveItems) do
        if not settings.accountItems[item] then
            settings.accountItems[item] = 1
            if simpleAStar(goal(dest))(playerNode) then
                error(message .. " Item: " .. item .. " would open a path.")
            end
        end
    end
    error(message)
end

-- main function called by users
local function moveTo(map, dest)
	if not dest then
		dest = map
		map = getMapName()
	end
	refreshTransportAvailability()
	playerNode = getPlayerNode(map)
	dest = mapsToNodes(dest)
	if Lib.useMount(settings.mount) then
		return true
	elseif checkOutlet() then
		return true
	elseif Work.isWorking(map, settings.workOpts) then

		return true
	elseif destStore == table.concat(dest, " | ") then
		return moveWithCalcPath()
	else
		settings.abilitiesIndex = validateAbilitiesIndex(settings.abilitiesIndex, moveAbilities)
		settings.accountItems = validateItems(settings.accountItems, moveItems)
		pathSolution = getTravelPath(playerNode, dest)
		destStore = table.concat(dest, " | ")
		if not pathSolution then return findSettings(dest) end
		buildWalkingCheckpoints(pathSolution)
		log("Path: " .. table.concat(pathSolution,"->"))
		if settings.transportAvailable.subway == false
			or settings.transportAvailable.teleport == false then
			logWalkingCheckpoints()
		end
		return moveWithCalcPath()
	end
	return false
end

local function getPath(start, dest)
	refreshTransportAvailability()
    settings.abilitiesIndex = validateAbilitiesIndex(settings.abilitiesIndex, moveAbilities)
    settings.accountItems = validateItems(settings.accountItems, moveItems)
    return getTravelPath(start, mapsToNodes(dest))
end


-- allow user control for digway shortcuts
local function enableDigPath()
    settings.dig = true
    log("Pathfinder: Dig paths enabled.")
end

local function disableDigPath()
    settings.dig = false
    log("Pathfinder: Dig paths disabled.")
end

local function isDigPathEnabled()
    return settings.dig
end
------------------------
--- GOAL FOR POKEMON -----
------------------------
local function mapsToNodes2(mapList)
    local nodeList = {}
    if type(mapList) == "string" then
        mapList = {mapList}
    end
    for _, map in pairs(mapList) do
        if subMaps[map] then  -- if the map has sub maps
            for submap, _ in pairs(subMaps[map]) do
                table.insert(nodeList, submap)
            end
        elseif globalMap[map] then
            table.insert(nodeList, map)
        end
    end
    return nodeList
end

local DEFAULT_HUNT_CANDIDATE_LIMIT = 40
local MAX_HUNT_CANDIDATE_LIMIT = 64
local tierPriority = { Common = 1, Uncommon = 2, Rare = 3 }

local function getTierValue(data)
    return tierPriority[data.Tier] or 4
end

local function isBetterSpawnCandidate(candidate, current)
    local candidateTier = getTierValue(candidate)
    local currentTier = getTierValue(current)
    if candidateTier ~= currentTier then
        return candidateTier < currentTier
    end
    if candidate.MapType ~= current.MapType then
        return candidate.MapType == "Land"
    end
    return candidate.Map < current.Map
end

local function collectSpawnCandidates(spawnList, isDay, isNoon, isNight,
        isAccountMember, maxLoop)
    local candidatesByMap = {}
    local eligibleCount = 0
    local memberAccount = isAccountMember == true or tonumber(isAccountMember) == 1

    for _, data in ipairs(spawnList) do
        -- A 1 means that period is acceptable. Passing 1,1,1 therefore means
        -- "any time", which is what DailySolaceon requests.
        local timeOk = (tonumber(isDay) == 1 and data.Day == 1)
            or (tonumber(isNoon) == 1 and data.Morning == 1)
            or (tonumber(isNight) == 1 and data.Night == 1)
        local canUseSpawn = not data.FishingOnly or data.FishingOnly == 0

        if timeOk and canUseSpawn and (memberAccount or not data.MemberOnly) then
            eligibleCount = eligibleCount + 1
            local current = candidatesByMap[data.Map]
            if current == nil or isBetterSpawnCandidate(data, current) then
                candidatesByMap[data.Map] = data
            end
        end
    end

    local candidates = {}
    for _, data in pairs(candidatesByMap) do
        candidates[#candidates + 1] = data
    end
    table.sort(candidates, function(a, b)
        local tierA = getTierValue(a)
        local tierB = getTierValue(b)
        if tierA ~= tierB then
            return tierA < tierB
        end
        if a.Map ~= b.Map then
            return a.Map < b.Map
        end
        return a.MapType < b.MapType
    end)

    local requestedLimit = math.floor(tonumber(maxLoop)
        or DEFAULT_HUNT_CANDIDATE_LIMIT)
    requestedLimit = math.max(1, math.min(requestedLimit,
        MAX_HUNT_CANDIDATE_LIMIT))
    while #candidates > requestedLimit do
        candidates[#candidates] = nil
    end

    return candidates, eligibleCount
end

local function findNearestCandidateForTier(start, candidates, tierValue)
    local candidateByNode = {}

    for _, data in ipairs(candidates) do
        if getTierValue(data) == tierValue then
            for _, node in ipairs(mapsToNodes2(data.Map)) do
                local current = candidateByNode[node]
                if current == nil or isBetterSpawnCandidate(data, current) then
                    candidateByNode[node] = data
                end
            end
        end
    end

    if next(candidateByNode) == nil then
        return nil
    end

    local targetNodes = {}
    for node in pairs(candidateByNode) do
        targetNodes[#targetNodes + 1] = node
    end
    local path, cost = getTravelPath(start, targetNodes)
    if not path or #path == 0 then
        return nil
    end

    if cost == nil then
        cost = #path - 1
    end
    return candidateByNode[path[#path]], path, cost
end

-- Find a hunting map without sorting/mutating the shared spawn list or running
-- one A* search per entry. At most MAX_HUNT_CANDIDATE_LIMIT unique maps are
-- considered and a multi-target search is performed once per rarity tier.
local function getMapToPokemon(start, pokemonName, isDay, isNoon, isNight,
        isAccountMember, maxLoop)
    local bestMap, bestPath, bestCost, mapType = nil, nil, math.huge, nil
    local bestTierValue = math.huge
    local spawnList = getSpawnDataIndex()[pokemonName]
    if not spawnList or #spawnList == 0 then
        log("No spawn data for " .. tostring(pokemonName) .. ".")
        return nil
    end

    local candidates, eligibleCount = collectSpawnCandidates(spawnList,
        isDay, isNoon, isNight, isAccountMember, maxLoop)
    if #candidates == 0 then
        log("No eligible non-fishing spawn for " .. tostring(pokemonName) .. ".")
        return nil
    end

    -- Account traversal capabilities are invariant during this lookup.
    refreshTransportAvailability()
    settings.abilitiesIndex = validateAbilitiesIndex(settings.abilitiesIndex,
        moveAbilities)
    settings.accountItems = validateItems(settings.accountItems, moveItems)

    -- Preserve the old cost-first, tier-on-tie behavior without emitting a log
    -- for every individual spawn/map candidate.
    for tierValue = 1, 4 do
        local data, path, cost = findNearestCandidateForTier(start,
            candidates, tierValue)
        if data and ((cost < bestCost)
                or (cost == bestCost and tierValue < bestTierValue)) then
            bestMap = data.Map
            bestPath = path
            bestCost = cost
            mapType = data.MapType
            bestTierValue = tierValue
        end
    end

    if bestMap then
        log(string.format(
            "Pokemon hunt route: %s -> %s (cost=%s, candidates=%d/%d).",
            tostring(pokemonName), tostring(bestMap), tostring(bestCost),
            #candidates, eligibleCount))
    else
        log("No reachable spawn map for " .. tostring(pokemonName) .. ".")
    end

    return bestMap, bestPath, bestCost, mapType
end

------------------------
local pfData     = {
resetPath        = resetPath,
enableDigPath    = enableDigPath,
disableDigPath   = disableDigPath,
isDigPathEnabled = isDigPathEnabled,
exceptionExist   = exceptionExist,
setOutlet        = setOutlet,
unsetOutlet      = unsetOutlet,
outletInNode     = outletInNode,
isSubwayPath     = isSubwayPath,
}

------------------------
-------- HOOKS ---------
------------------------

-- we handle dialogs in DialogSolver
local function onPathfinderDialogMessage(message)
	-- Loading Pathfinder into a quest script must not make it answer unrelated
	-- quest, evolution, HM, or transport dialogs. It owns dialogs only while a
	-- Pathfinder route has an active edge.
	if from == nil or toMap == nil then
		return false
	end
    pfData.from = from
    pfData.toMap = toMap
    pfData.abilitiesIndex = settings.abilitiesIndex
    dialogSolver.solveDialog(message, pfData)
end

local function onPathfinderSystemMessage(message)
    if stringContains(message, "Your Safari Time is over!") then resetPath() end
end

-- load map and settings
local function onPathfinderStart()
    globalMap = assert(_globalMap(), "Pathfinder --> Error : failed to load map")
    local ss = assert(_ss(), "Pathfinder --> Error : failed to load settings")
    npcExceptions = _npcExceptions()
    cellCrawl.attachPathfinder(globalMap, getMapNode)
    initSettings(ss)
end

-- reset path on stop
local function onPathfinderStop()
    resetPath()
end

registerHook("onStart", onPathfinderStart)
registerHook("onDialogMessage", onPathfinderDialogMessage)
registerHook("onSystemMessage", onPathfinderSystemMessage)
registerHook("onStop", onPathfinderStop)

-- return table for users
return {
	moveTo = moveTo,
    getMapNode = getMapNode,
    isSameMap = isSameMap,
	getPath = getPath,
	enableDigPath = enableDigPath,
	disableDigPath = disableDigPath,
	isDigPathEnabled = isDigPathEnabled,
	mapName = getPlayerNode,
    isDestination = isDestination,
    getMapToPokemon = getMapToPokemon,
    getWalkingCheckpoints = function() return walkingCheckpoints end,
    getLearnedMapLinks = cellCrawl.getLearnedLinks,
    logLearnedMapLinks = cellCrawl.logLearnedLinks,
    setCellCrawlLinkDistance = cellCrawl.setMaxSourceLinkDistance,
}

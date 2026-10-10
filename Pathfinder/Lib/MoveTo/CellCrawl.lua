-- Learns directional map-link cells from real map transitions during this run.
--
-- The client exposes link-cell coordinates but not their destination names.  A
-- destination can therefore only be known after the player actually crosses a
-- link.  This module observes that transition and adds the verified source
-- cell to the in-memory MapLink table used by MoveTo.
--
-- It deliberately does not guess reverse links: ledges, warps and story gates
-- can be one-way.  Walking back through a real reverse transition learns that
-- direction separately.

local cpath = select(1, ...) or ""
local function nTimes(n, f, x)
    for _ = 1, n do
        x = f(x)
    end
    return x
end
local function rmlast(path)
    return path:sub(1, -2):match(".+[%./]") or ""
end
local cppdpath = nTimes(3, rmlast, cpath)

local mapLinks = require(cppdpath .. "Maps/MapLink")

local CellCrawl = {}

-- A transition is accepted only when the last observed location was close to
-- a real link cell.  This avoids teaching Pathfinder bogus links after a
-- blackout, teleport, or other server-driven map change.
local MAX_SOURCE_LINK_DISTANCE = 3

local graph = nil
local resolveMapNode = nil
local previous = nil
local learned = {}

local function validMapName(value)
    return type(value) == "string" and value ~= ""
end

local function nearestLinkCell(x, y)
    if type(getMapLinks) ~= "function" then
        return nil
    end

    local ok, links = pcall(getMapLinks)
    if not ok or type(links) ~= "table" then
        return nil
    end

    local nearest = nil
    for _, link in pairs(links) do
        local linkX = tonumber(link.x)
        local linkY = tonumber(link.y)
        if linkX ~= nil and linkY ~= nil then
            local distance = math.abs(x - linkX) + math.abs(y - linkY)
            if nearest == nil or distance < nearest.distance then
                nearest = { x = linkX, y = linkY, distance = distance }
            end
        end
    end
    return nearest
end

local function mapNode(mapName, x, y)
    if resolveMapNode ~= nil then
        local ok, node = pcall(resolveMapNode, mapName, x, y)
        if ok and validMapName(node) then
            return node
        end
    end
    return mapName
end

local function snapshot()
    if type(getMapName) ~= "function"
        or type(getPlayerX) ~= "function"
        or type(getPlayerY) ~= "function" then
        return nil
    end

    local mapName = getMapName()
    if not validMapName(mapName) then
        return nil
    end

    local x = tonumber(getPlayerX())
    local y = tonumber(getPlayerY())
    if x == nil or y == nil then
        return nil
    end

    return {
        map = mapName,
        node = mapNode(mapName, x, y),
        x = x,
        y = y,
        nearestLink = nearestLinkCell(x, y),
    }
end

local function addGraphEdge(fromNode, toNode)
    if graph == nil then
        return false
    end

    graph[fromNode] = graph[fromNode] or {}
    graph[toNode] = graph[toNode] or {}
    if graph[fromNode][toNode] ~= nil then
        return false
    end

    -- This matches the existing Pathfinder graph edge format: { travelCost }.
    graph[fromNode][toNode] = { 1 }
    return true
end

local function addMapLink(fromNode, toNode, cell)
    mapLinks[fromNode] = mapLinks[fromNode] or {}
    if mapLinks[fromNode][toNode] ~= nil then
        return false
    end

    mapLinks[fromNode][toNode] = { { cell.x, cell.y } }
    return true
end

local function rememberTransition(from, to)
    if from == nil or to == nil or from.map == to.map then
        return false
    end

    local sourceCell = from.nearestLink
    if sourceCell == nil or sourceCell.distance > MAX_SOURCE_LINK_DISTANCE then
        log(string.format(
            "Pathfinder CellCrawl: skipped %s -> %s; no verified source link near (%d,%d).",
            from.map, to.map, from.x, from.y))
        return false
    end

    local fromNode = from.node or from.map
    local toNode = to.node or to.map
    if not validMapName(fromNode) or not validMapName(toNode)
        or fromNode == toNode then
        return false
    end

    local addedCell = addMapLink(fromNode, toNode, sourceCell)
    local addedGraph = addGraphEdge(fromNode, toNode)
    if addedCell or addedGraph then
        learned[#learned + 1] = {
            from = fromNode,
            to = toNode,
            x = sourceCell.x,
            y = sourceCell.y,
        }
        log(string.format(
            "Pathfinder CellCrawl: learned %s -> %s at (%d,%d).",
            fromNode, toNode, sourceCell.x, sourceCell.y))
        return true
    end
    return false
end

-- Call from a path-action hook, or manually after a known map transition.
-- It observes state only; it never issues a movement, battle, or dialog action.
function CellCrawl.observe()
    local current = snapshot()
    if current == nil then
        return false
    end

    local learnedTransition = rememberTransition(previous, current)
    previous = current
    return learnedTransition
end

-- MoveTo supplies its merged graph and its sub-map resolver on start.  Keeping
-- the references shared means a learned link is immediately usable by A*.
function CellCrawl.attachPathfinder(globalMap, getMapNode)
    graph = globalMap
    resolveMapNode = getMapNode

    -- CellCrawl's onStart hook is registered before MoveTo's onStart hook.
    -- Re-resolve the first sampled map now that MoveTo's sub-map resolver is
    -- available, so an initial Route/Floor sub-map is learned under its node.
    if previous ~= nil then
        previous.node = mapNode(previous.map, previous.x, previous.y)
    end
end

function CellCrawl.setMaxSourceLinkDistance(distance)
    distance = math.floor(tonumber(distance) or 0)
    if distance < 0 then
        return false
    end
    MAX_SOURCE_LINK_DISTANCE = distance
    return true
end

function CellCrawl.getLearnedLinks()
    return learned
end

function CellCrawl.logLearnedLinks()
    if #learned == 0 then
        log("Pathfinder CellCrawl: no links learned this session.")
        return false
    end

    for _, link in ipairs(learned) do
        log(string.format(
            "Pathfinder CellCrawl link: [\"%s\"] -> [\"%s\"] = {{%d, %d}}",
            link.from, link.to, link.x, link.y))
    end
    return true
end

local function onCellCrawlStart()
    previous = nil
    learned = {}
    CellCrawl.observe()
end

registerHook("onStart", onCellCrawlStart)
registerHook("onPathAction", CellCrawl.observe)

return CellCrawl

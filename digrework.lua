name = "Dig / PokeStop / Berry - Scheduled Regions"
author = "Basculegion Team"
description = "Lich Kanto -> Johto -> Hoenn -> Sinnoh cho Dig/PokeStop/Berry; khong Excavation."

local TASK_ORDER = {"dig", "pokestop", "berry"}
local OPTION_INDEX = {dig=1, berry=2, pokestop=3}
local COOLDOWN = {dig=3*24*3600, berry=4*24*3600, pokestop=2*24*3600}
local SKIP_RETRY_SECONDS = 5
local CONFIRM_EMPTY_READS = 3
-- One ordered tour. Completed regions are not revisited within this tour.
local REGION_ORDER = {"Kanto", "Johto", "Hoenn", "Sinnoh"}
-- Prefer enabled Subway/Teleport for travel, even over a lower walking cost.
-- This does not change which nearby harvest job is selected first.
local PREFER_TRANSPORT = true
-- Unavailable Dig travel shortcuts must not discard the harvest destination.
local FALLBACK_DIG_PATH = true
-- Preserve the three legacy status files and cooldowns; no new account schema.
if type(setOptionName)=="function" and type(setOption)=="function" then
    for _,kind in ipairs(TASK_ORDER) do
        setOptionName(OPTION_INDEX[kind],kind)
        setOption(OPTION_INDEX[kind],true)
    end
end
local function isTaskEnabled(kind)
    return type(getOption)~="function" or getOption(OPTION_INDEX[kind])==true
end

-- Pathfinder Work otherwise independently harvests on travel, including
-- PokeStops even with DIG/HARVEST false. Only this script's VM delegates Work
-- to our single active-API scheduler; restore everything on Stop.
local getSettings = require "Settings/Static_Settings"
-- Work's Dig-menu hook has an index initialized only by Work.isWorking.
-- Since this script delegates that worker, own its Dig menu as well. Capture
-- only that exact hook during module load; other Pathfinder hooks stay intact.
local register=registerHook
registerHook=function(event,fn)
    if event=="onDialogMessage" and fn==onWorkDialogMessage then return end
    return register(event,fn)
end
local workOk,work=pcall(require,"Pathfinder/Lib/Work")
registerHook=register
assert(workOk,work)
local savedSettings, savedWork
local overrides={DIG=false,HARVEST=false,HEADBUTT=false,DISCOVER=false,MOUNT=""}
registerHook("onStart",function()
    local settings=getSettings()
    savedSettings={}
    for k,v in pairs(overrides) do savedSettings[k]={value=settings[k]}; settings[k]=v end
    savedWork=work.isWorking
    work.isWorking=function() return false end
end)
local pf = require "Pathfinder/MoveToApp"
local ActiveHarvestRoute = require "Lib/ActiveHarvestRoute"

local function getNow() return os.time() end
local function formatDuration(sec)
    sec=math.max(math.floor(sec),0)
    return string.format("%dh%02dm%02ds",math.floor(sec/3600),math.floor(sec%3600/60),sec%60)
end

local land_mounts = { "Xmas Bisharp Mount", "Houndoom Mount", "Bicycle" }
local surf_mounts = { "Xmas Greninja Mount", "Lapras Mount", "S Squirtle Mount" }

local DIG_MAPS = {
    "Route 3",
    "Mt. Moon 1F",
    "Mt. Moon B2F_B",
    "Mt. Moon B2F_C",
    "Rock Tunnel 1_A",
    "Rock Tunnel 2_B",
    "Route 15",
    "Route 14",
    "Digletts Cave",
    "Slowpoke Well",
    "Slowpoke Well L1",
    "Mt. Mortar 1F_A",
    "Mt. Mortar 1F_C",
    "Mt. Mortar 1F_B",
    "Dark Cave South_D",
    "Oreburgh Gate B1F",
    "Route 210 North",
    "Route 211_B",
    "Route 211_A",
    "Mt. Coronet Summit_A",
    "Route 209",
    "Maniac Tunnel",
}

local BERRY_MAPS = {
    "Viridian Maze",
    "Route 115",
    "Petalburg Maze",
    "Route 212 North",
    "Route 218",
    "Route 224",
    "Route 228",
}

local POKESTOP_MAPS = {
    "Viridian City",
    "Viridian Forest",
    "Pewter City",
    "Route 3",
    "Cerulean City_B",
    "Route 25",
    "Route 10_A",
    "Route 5_A",
    "Vermilion City",
    "Digletts Cave Entrance 2",
    "Cinnabar Island",
    "Olivine City",
    "Violet City",
    "Route 32",
    "Azalea Town",
    "Ilex Forest",
    "National Park",
    "Ecruteak City",
    "Lake of Rage_A",
    "Route 45_A",
    "Lilycove City",
    "Slateport City",
    "Lavaridge Town",
    "Mossdeep City",
    "Sootopolis City",
    "Pacifidlog Town",
    "Petalburg Woods",
    "Route 115_B",
    "Route 119A",
    "Route 111 Desert",
    "Solaceon Town",
    "Jubilife City",
    "Hearthome City",
    "Veilstone City",
    "Sendoff Spring",
    "Pastoria City",
    "Snowpoint City",
    "Sunyshore City",
    "Celestic Town",
    "Eterna Forest",
}


local function newStatus(label, fileSuffix, allMaps, cooldown)
    local S = { label = label, all = allMaps, doneAt = {}, skipUntil = {}, records = {} }
    local fileName = nil
    local persist = (type(logToFile) == "function" and type(readLinesFromFile) == "function")

    local function append(line)
        if not fileName or not persist then return false end
        local ok, result = pcall(logToFile, fileName, line)
        local written = ok and result ~= false
        if written then S.records[#S.records + 1] = line end
        return written
    end

    function S.load(accName)
        fileName = accName .. fileSuffix
        if not persist then
            log(label .. ": không có logToFile/readLinesFromFile, không thể lưu/tải trạng thái.")
            return
        end

        local ok, lines = pcall(readLinesFromFile, fileName)
        if not ok or type(lines) ~= "table" then
            log("Tạo mới tiến trình " .. label .. " cho tài khoản: " .. accName)
            return
        end

        local loaded = 0
        S.records = {}
        for _, line in ipairs(lines) do
            if type(line) == "string" then
                S.records[#S.records + 1] = line
                local mapName, ts = line:match("^DONE:(.-):([%d%.]+)$")
                if mapName then
                    ts = tonumber(ts)
                    if ts and (S.doneAt[mapName] == nil or ts > S.doneAt[mapName]) then
                        S.doneAt[mapName] = ts
                        loaded = loaded + 1
                    end
                end
            end
        end
        log("Đã tải trạng thái " .. label .. " từ " .. fileName .. " (" .. loaded .. " bản ghi)")
    end

    function S.markDone(mapName)
        local t = getNow()
        if t then
            S.doneAt[mapName] = t
            append("DONE:" .. tostring(mapName) .. ":" .. tostring(t))
        else
            S.doneAt[mapName] = true
        end
    end

    function S.appendRecord(line)
        return append(tostring(line))
    end

    function S.canPersist()
        return persist and fileName ~= nil
    end

    function S.getRecords()
        return S.records
    end

    function S.skip(mapName, seconds)
        local t = getNow()
        S.skipUntil[mapName] = t and (t + (seconds or SKIP_RETRY_SECONDS)) or true
    end

    function S.readyInfo(mapName, now)
        local t = now or getNow()
        local readyAt = 0

        local d = S.doneAt[mapName]
        if d == true then return false, nil end
        if type(d) == "number" then readyAt = math.max(readyAt, d + cooldown) end

        local sk = S.skipUntil[mapName]
        if sk == true then return false, nil end
        if type(sk) == "number" then readyAt = math.max(readyAt, sk) end

        if t == nil then return readyAt == 0, nil end
        return t >= readyAt, readyAt
    end

    function S.readyMaps(now)
        now = now or getNow()
        local list = {}
        for _, m in ipairs(allMaps) do
            if S.readyInfo(m, now) then
                table.insert(list, m)
            end
        end
        return list
    end

    function S.earliest(now)
        now = now or getNow()
        local earliest = nil
        for _, m in ipairs(allMaps) do
            local ready, readyAt = S.readyInfo(m, now)
            if not ready and readyAt and (earliest == nil or readyAt < earliest) then
                earliest = readyAt
            end
        end
        return earliest
    end

    -- Only a genuine completed-harvest cooldown may start a fresh region
    -- tour. Temporary movement/API skips must not send us back after 5s.
    function S.nextHarvestAt(now)
        now=now or getNow()
        if not now then return nil end
        local earliest
        for _,m in ipairs(allMaps) do
            local done=S.doneAt[m]
            local ready=type(done)=="number" and done+cooldown or nil
            if ready and ready>now and (not earliest or ready<earliest) then earliest=ready end
        end
        return earliest
    end

    return S
end



local runner, tasks, inventory, totalItemsCollected, started, tickCount
local function showInventory()
    log("=== DigRework: item phien nay ===")
    local keys={}
    for item in pairs(inventory or {}) do keys[#keys+1]=item end
    table.sort(keys)
    for _,item in ipairs(keys) do log(item.." x"..inventory[item]) end
    log("Tong: "..tostring(totalItemsCollected or 0).." | Thoi gian: "
        ..formatDuration(started and getNow()-started or 0).." | Ticks: "..tostring(tickCount or 0))
end
local function addItemFromString(str)
    local clean=str:gsub("^%[.-%]%s+", "")
    clean=clean:gsub("^You unearthed%s+", ""):gsub("^You have obtained%s+", "")
        :gsub("^You have looted%s+", ""):gsub("^You found%s+", "")
        :gsub("^%s+", ""):gsub("%s+$", "")
    local count,item=clean:match("^(%d+)%s*[xX]%s+(.+)$")
    if not count then item=clean:match("^[Aa]n?%s+(.+)$"); if item then count="1" end end
    if not count then count=clean:match("^(%d+)%s+of them!"); if count then item="Berry" end end
    if not count or not item then return end
    item=item:gsub("[%p]+$", ""):gsub("^%s+", ""):gsub("%s+$", "")
    count=tonumber(count)
    if count and item~="" then
        inventory[item]=(inventory[item] or 0)+count
        totalItemsCollected=totalItemsCollected+count
        log("DigRework: +"..count.."x "..item.." | tong="..totalItemsCollected)
    end
end
function onStart()
    inventory={}; totalItemsCollected=0; tickCount=0; started=getNow()
    local defs={
        dig={label="DigSpot",maps=DIG_MAPS,api=getActiveDigSpots,suffix="_digspot_status.txt"},
        pokestop={label="PokeStop",maps=POKESTOP_MAPS,api=getActivePokestop,suffix="_pokestop_status.txt"},
        berry={label="Berry",maps=BERRY_MAPS,api=getActiveBerryTrees,suffix="_berry_status.txt"}
    }
    tasks={}
    local account=string.lower(getAccountName() or "default")
    for _,kind in ipairs(TASK_ORDER) do
        local task=defs[kind]
        task.name=kind
        task.enabled=function() return isTaskEnabled(task.name) end
        task.status=newStatus(task.label,task.suffix,task.maps,COOLDOWN[kind])
        task.status.load(account)
        tasks[#tasks+1]=task
    end
    runner=ActiveHarvestRoute.new(pf,tasks,{retrySeconds=SKIP_RETRY_SECONDS,
        confirmEmptyReads=CONFIRM_EMPTY_READS,regionOrder=REGION_ORDER,
        preferTransport=PREFER_TRANSPORT,digFallback=FALLBACK_DIG_PATH})
    local land,surf="",""
    for _,item in ipairs(land_mounts) do if hasItem(item) then land=item; break end end
    for _,item in ipairs(surf_mounts) do if hasItem(item) then surf=item; break end end
    setMount(land)
    if surf~="" then setWaterMount(surf) end
    log("DigRework: Dig + PokeStop + Berry chung tuyen; khong Excavation/cart/auto Escape Rope.")
    log("DigRework: Maplists, cooldown va status cu duoc giu. Thu gom local trong vung den luot.")
    log("DigRework: Lich vung "..table.concat(REGION_ORDER," -> ")
        .."; diem bi chan hoan sang luot sau, KHONG ghi DONE.")
end
function onPathAction()
    if not runner then return end
    tickCount=tickCount+1
    -- Preserve explicit avoidance of available trainers; yield after the action.
    if type(getActiveBattlers)=="function" and type(isNpcInteractionsEnabled)=="function"
            and type(disableNpcInteractions)=="function" and isNpcInteractionsEnabled() then
        local ok,battlers=pcall(getActiveBattlers)
        if ok and type(battlers)=="table" and next(battlers) and disableNpcInteractions() then return true end
    end
    return runner.step()
end
function onBattleAction()
    if not isWildBattle() then return attack() or sendUsablePokemon() or sendAnyPokemon() end
    if isOpponentShiny() or (tonumber(getOpponentForm()) or 0)~=0 then
        for _,ball in ipairs({"Ultra Ball","Great Ball","Pokeball"}) do
            if hasItem(ball) and useItem(ball) then return true end
        end
        if sendUsablePokemon() or sendAnyPokemon() then return true end
        fatal("DigRework: Khong bat duoc shiny/form; kiem tra thu cong, khong chay/ha.")
        return
    end
    return run() or attack() or sendUsablePokemon() or sendAnyPokemon()
end
function onDialogMessage(message,options)
    if not runner then return end
    local prompt=(message and message~="" and message) or (options and options.prompt) or ""
    local active=runner.active
    if active and active.map==getMapName() and active.task.name=="dig"
            and math.abs(getPlayerX()-active.x)+math.abs(getPlayerY()-active.y)<=1
            and prompt=="Select a Pokemon that has Dig." then
        for slot=1,getTeamSize() do
            if hasMove(slot,"Dig") and getPokemonHappiness(slot)>=151 then
                pushDialogAnswer(slot); return
            end
        end
        fatal("DigRework: Khong co Pokemon Dig happiness >=151 de tra loi menu.")
        return
    end
    if active and active.map==getMapName()
            and math.abs(getPlayerX()-active.x)+math.abs(getPlayerY()-active.y)<=1
            and active.task.name=="berry" and options and #options>0 then
        local text=string.lower(prompt)
        if text:find("berry",1,true) or text:find("harvest",1,true) then
            for index,choice in ipairs(options) do
                local c=tostring(choice):lower():gsub("^%s+", ""):gsub("%s+$", "")
                if c=="yes" or c:match("^yes[%s%p]") then pushDialogAnswer(index); break end
            end
        end
    end
    if prompt:find("You unearthed",1,true) or prompt:find("You have obtained",1,true)
            or prompt:find("You have looted",1,true) or prompt:find("You found",1,true) then
        addItemFromString(prompt)
    end
end
function onPause() showInventory() end
function onStop()
    showInventory()
    if savedSettings then
        local settings=getSettings()
        for k,entry in pairs(savedSettings) do settings[k]=entry.value end
    end
    if savedWork then work.isWorking=savedWork end
    savedSettings=nil; savedWork=nil; runner=nil
end

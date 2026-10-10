local pf = require "Pathfinder/MoveToApp" -- requesting table with methods
local Hunt = require "Lib/DailySolaceonHunt"
local function newHunt()
    return Hunt.new(pf, require("Pathfinder/Spawn/SpawnData"),
        require("Pathfinder/Maps/GlobalMap")(), require("Pathfinder/Maps/MapExceptions/SubstituteMaps"))
end
local hunt
local current_map = ""
local pokemonName = ""
local accountName =""
local current_server = ""
local lastDate = ""
local dailyStatus = {}
local falseswipe_user_idx = nil
local scrappy_user_idx = nil
local has_scrappy_fs_pokemon = false
local CATCH_HP_THRESHOLD = 20
local foundPokemon = false
local foundPokemonIndex = nil
local moveNearPC = false
local usedPC = false
--Danh sách mount
local land_mount = {
    ["Rayquaza Mount"] = true,
    ["S Togekiss Mount"] = true,
    ["S Magnezone Mount"] = true,
    ["S Sceptile Mount"] = true,
    ["Manectric Mount"] = true,
    ["Volcanion Mount"] = true,
    ["Xmas Houndoom Mount"] = true,
    ["Bicycle"] = true,
}

--Danh sách mount surf
local surf_mount = {
    ["Xmas Snorlax Mount"] = true,
    ["S Lapras Mount"] = true,
    ["Lapras Mount"] = true,
    ["S Tentacruel Mount"] = true,
    ["S Whiscash Mount"] = true,
    ["S Milotic Mount"] = true,
}
function getPokemonWithMove(moveName)
    for i = 1, getTeamSize() do
        if hasMove(i, moveName) then
            return i
        end
    end
    return nil
end

function getPokemonWithAbility(ability)
    for i = 1, getTeamSize() do
        if getPokemonAbility(i) == ability then
            return i
        end
    end
    return nil
end

function getPokemonWithName(name)
    for i = 1, getTeamSize() do
        if getPokemonName(i) == name then
            return i
        end
    end
    return nil
end

function custom_start()
    wildCounter = 0
    startMoney = getMoney()
    for mount_name, _ in pairs(land_mount) do
        if hasItem(mount_name) then
            setMount(mount_name)
            break
        end
    end

    for mount_name, _ in pairs(surf_mount) do
        if hasItem(mount_name) then
            setWaterMount(mount_name)
            break
        end
    end

end

function onStart()
    hunt = newHunt()
    pokemonName = ""
    foundPokemonIndex, usedPC = nil, false
    accountName = string.lower(getAccountName())
    current_server = getServer()

    loadDailyStatus()

    local info = dailyStatus[accountName]
    if info and info.server == current_server and info.date == os.date("%Y-%m-%d") then
        pokemonName = info.pokemon
    end

    falseswipe_user_idx = getPokemonWithMove('False Swipe')
    scrappy_user_idx = getPokemonWithAbility('Scrappy')
    has_scrappy_fs_pokemon = false
    if scrappy_user_idx ~= nil  and falseswipe_user_idx ~= nil then
        if scrappy_user_idx == falseswipe_user_idx then
            has_scrappy_fs_pokemon = true
        end
    end


    return custom_start()
end

function onPathAction()
    current_map = pf.mapName()

    if pokemonName == "" then
        log("Đi nhận nhiệm vụ ở Pokemon News Press")
        if not pf.isSameMap(current_map, "Pokemon News Press") then
            if not pf.moveTo(current_map, "Pokemon News Press") then
                log("Không thể di chuyển đến Pokemon News Press từ " .. current_map)
                return waitForState(250)
            else
                return
            end
        else
            return talkToNpcOnCell(0, 6)
        end
    end

    foundPokemonIndex = getPokemonWithName(pokemonName)

    if getTeamSize() >= 6 and foundPokemonIndex == nil then
        log("Đội hình đã đầy, đi đến Pokecenter gần nhất.")
        if not stringContains(current_map, "Pokecenter") then
           return pf.useNearestPokecenter(current_map)
        else
            return handleReplacePokemon()
        end
    end

    if foundPokemonIndex ~= nil then
        log("Đã bắt được " .. pokemonName .. "")
        log("Trả nhiệm vụ ở Pokemon News Press")
        if not pf.isSameMap(current_map, "Pokemon News Press") then
            if not pf.moveTo(current_map, "Pokemon News Press") then
                log("Không thể di chuyển đến Pokemon News Press từ " .. current_map)
                return waitForState(250)
            else
                return
            end
        else
            return talkToNpcOnCell(0, 6)
        end
    else
        return hunt.step(pokemonName)
    end
end

function onBattleAction()
    local isGhostPokemon = false

    if not isWildBattle() then
	    return attack() or sendAnyPokemon()
    end

    local interested_wild = false
    local is_shiny = isOpponentShiny()
    local is_form = getOpponentForm() ~= 0
    local is_form_shiny = is_shiny or is_form

    interested_wild = is_form_shiny or (getOpponentName() == pokemonName and foundPokemonIndex == nil)
    if interested_wild  then
        if getOpponentName() == pokemonName then
            log("Gặp " .. pokemonName .. ", tiến hành bắt")
        end
     --   if falseswipe_user_idx ~= nil then
         --   if getActivePokemonNumber() ~= falseswipe_user_idx and getPokemonStatus(falseswipe_user_idx) ~= "KO" then
         --       return sendPokemon(falseswipe_user_idx) or sendAnyPokemon() or run()
         --   end

            if is_form_shiny then
                return useItem("Ultra Ball") or useItem("Great Ball") or useItem("Pokeball")
            end
      --  end

        return useItem("Pokeball") or useItem("Great Ball") or useItem("Ultra Ball") or sendAnyPokemon()  or run()

    end

    return run() or attack() or sendAnyPokemon()
end

function onDialogMessage(message)
    if (stringContains(message, "For this edition of the newspaper, we need a") or stringContains(message, "So, can you show me your")) and pokemonName == "" then
       pokemonName = message:match("%[FFA500%](.-)%[%-%]")
       if pokemonName and getMapName() == "Pokemon News Press" then
            log("Pokémon được yêu cầu: " .. pokemonName)
            saveDailyStatus()
        end
    end


    if stringContains(message, "So, can you show me your") then
        if foundPokemonIndex ~= nil then
            return pushDialogAnswer(foundPokemonIndex)
        end
    end

    if stringContains(message, "Come back in:") then
        log("Hôm nay đã hoàn thành nhiệm vụ, hãy quay lại vào ngày mai")
        fatal()
    end
end

function handleReplacePokemon()
    if getTeamSize() < 6 then
        return true
    end

    if not usedPC or not isPCOpen() then
        usedPC = true
        usePC()
        return false
    end

    if isPCOpen() then
        depositPokemonToPC(6)
    end

    return false
end

function loadDailyStatus()
    local lines = readLinesFromFile("daily_status.txt")
    if not lines then
        log("Không đọc được file daily_status.txt")
        return
    end

    dailyStatus = {}

    for _, line in ipairs(lines) do
        -- Mẫu: "AccName ServerName PokemonName YYYY-MM-DD"
        local acc, server, pokemon, date = line:match("^(%S+)%s+(%S+)%s+(%S+)%s+(%d%d%d%d%-%d%d%-%d%d)$")
        if acc and server and pokemon and date then
            dailyStatus[acc] = {
                server = server,
                pokemon = pokemon,
                date = date
            }
            log(string.format("%s | Server: %s | Pokémon: %s | Ngày: %s", acc, server, pokemon, date))
        else
            log("Dòng không hợp lệ: " .. line)
        end
    end
end


function saveDailyStatus()
    -- Load lại dữ liệu cũ
    loadDailyStatus()

    -- Cập nhật thông tin account và server hiện tại
    if not dailyStatus[accountName] then
        dailyStatus[accountName] = {}
    end

    dailyStatus[accountName].server = current_server
    dailyStatus[accountName].pokemon = pokemonName
    dailyStatus[accountName].date = os.date("%Y-%m-%d")  -- dùng ngày hiện tại

    -- Ghi lại file
    local lines = {}
    for acc, info in pairs(dailyStatus) do
        if info and info.pokemon and info.date and info.server then
            log(string.format("Lưu trạng thái Daily | Tài khoản: %s | Server: %s | Pokémon: %s | Ngày: %s",
                acc, info.server, info.pokemon, info.date))
            table.insert(lines, string.format("%s %s %s %s", acc, info.server, info.pokemon, info.date))
        end
    end

    return logToFile("daily_status.txt", lines, true)  -- true = ghi đè file
end

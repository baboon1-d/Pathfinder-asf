name = "Bug Catching - HP IV + Score"
author = "Basculegion"
description = "Daily hunt: top-HP tier 1/2, instant balls tier 3/4; keep best, clean party at Hall PC."

local Score = require "Lib/BugCatchingScore"

-- Start INSIDE the daily Bug Catching Area, immediately after entering.
-- If already part-way through/reloading, set the REAL minutes remaining first.
local MINUTES_REMAINING = 20
local RECTANGLE = {30, 45, 42, 45} -- Edit to your chosen walkable grass rectangle.
local ENABLED_TIERS = {[1]=true, [2]=true, [3]=true, [4]=true}
-- User confirmed Hall trips preserve the SAME contest and remaining time.
local AUTO_PC_CLEANUP = true -- false=stay in Area and use the fallback quota below.
local HALL = "Bug Catching Contest Hall"
local AREA_EXIT = {36, 56} -- Current Area cache link; (25,6) is in Hall. Verify live if map changes.
local HALL_ENTRANCE = {24, 5}
local HALL_PC = {10, 10} -- Terminal vicinity; usePC() finds the real access cell.
-- Fallback only when AUTO_PC_CLEANUP=false. Two ordinary tier 1/2 catches
-- leave three slots for tier 3/4/specials when entering with only the catcher.
local MAX_LOW_TIER_CATCHES = 2 -- 0..5, shared by ordinary tier 1 AND tier 2.
local LOW_TIER_FILL_LAST_MINUTES = 3 -- 0=never lift quota; HP/score filters stay on.
local STOP_AT_SCORE = 0 -- 0=keep hunting; otherwise stop after a catch reaches this score.
local MAX_FALSE_SWIPES = 3 -- Then throw balls even if HP is still above 1 (miss/immunity/PP guard).
local BALLS = {"Ultra Ball", "Great Ball", "Pokeball"}
local MAP = "Bug Catching Area"
local STATS = {"HP", "ATK", "DEF", "SPATK", "SPDEF", "SPD"}

local deadline, catcherId, best, encounter
local stopped = false
local seen = {}
local releasePlan, cleanupWanted = {}, false
local cleanup

local function reportBest()
    if best then
        log(string.format("BugCatching: NOP slot %d %s | IV=%d/186 | HP IV=%d | score=%.1f.",
            best.slot, best.name, best.iv, best.hpIV, best.score))
    else
        log("BugCatching: Chua co Pokemon du diem trong party (khong tinh catcher slot 1).")
    end
end

local function stop(reason)
    if stopped then return end
    stopped = true
    reportBest()
    fatal("BugCatching: " .. reason .. " NPC nop bai do ban tu thao tac.")
end

local function hasBalls()
    for _, ball in ipairs(BALLS) do if hasItem(ball) then return true end end
    return false
end

local function refreshScores()
    local previousId = best and best.id
    local previousScore = best and best.score
    best = nil
    local present = {}
    local records = {}
    for slot=2,getTeamSize() do
        local pokemon = getPokemonName(slot)
        local p = Score.species(pokemon)
        local id = getPokemonDatabaseId(slot)
        local total, hpIV = 0, nil
        local valid = true
        for _, stat in ipairs(STATS) do
            local iv = getPokemonIndividualValue(slot, stat)
            if type(iv) ~= "number" or iv < 0 or iv > 31 or iv ~= math.floor(iv) then
                valid = false
            else total = total + iv end
            if stat == "HP" then hpIV = iv end
        end
        local score = valid and Score.score(pokemon, getPokemonLevel(slot), total, isPokemonShiny(slot))
        local record = {id=id, slot=slot, name=pokemon, iv=total, hpIV=hpIV, score=score,
            shiny=isPokemonShiny(slot), form=getPokemonForm(slot)}
        records[#records+1] = record
        present[id] = true
        if not seen[id] then
            if score then
                log(string.format("BugCatching: BAT slot %d %s tier %d | IV=%d/186 | HP IV=%d | score=%.1f.",
                    slot, pokemon, p.tier, total, hpIV, score))
            else
                log("BugCatching: " .. pokemon .. " - chua tinh duoc diem (tier/IV khong hop le); giu nguyen.")
            end
        end
        if score and (not best or score > best.score
                or (score == best.score and id == previousId)) then best = record end
    end
    seen = present -- Bounded by the party, not a retained history of all captures.
    if best and (not previousScore or best.score > previousScore) then
        cleanupWanted = true
        log(string.format("BugCatching: BEST slot %d %s | score=%.1f (tong 6 IV sau bat).", best.slot, best.name, best.score))
    end
    releasePlan = {}
    for _, record in ipairs(records) do
        if best and record.id ~= best.id and record.id ~= catcherId and record.score
                and record.score <= best.score and not record.shiny and record.form == 0 then
            releasePlan[#releasePlan+1] = record
        end
    end
    table.sort(releasePlan, function(a,b)
        if a.score ~= b.score then return a.score < b.score end
        return a.slot > b.slot
    end)
end

local function lowTierBudgetOpen()
    if AUTO_PC_CLEANUP then return true end
    -- Count authoritative party entries, NOT balls thrown or an in-memory
    -- catch counter. Reload/Stop/Start must not reopen already-used slots.
    local count = 0
    for slot=2,getTeamSize() do
        local p = Score.species(getPokemonName(slot))
        if p and p.tier <= 2 and not isPokemonShiny(slot) and getPokemonForm(slot) == 0 then
            count = count + 1
        end
    end
    local filling = LOW_TIER_FILL_LAST_MINUTES > 0 and deadline
        and deadline - os.time() <= LOW_TIER_FILL_LAST_MINUTES * 60
    return count < MAX_LOW_TIER_CATCHES or filling
end

-- Exact identities are correlation guards, never PC indexes or Lua slots.
local function signature(exceptId)
    local ids, used = {}, {}
    for slot=1,getTeamSize() do
        local id = getPokemonDatabaseId(slot)
        if type(id) ~= "number" or id < 1 or id > 9007199254740991
                or id ~= math.floor(id) or used[id] then return nil end
        used[id] = true
        if id ~= exceptId then ids[#ids+1] = string.format("%.0f", id) end
    end
    return table.concat(ids, ",")
end

local function cleanupMove(x,y)
    if getPlayerX() == x and getPlayerY() == y then return waitForState(250) end
    if not moveToCell(x,y) then stop("Khong di duoc cua Area/Hall; kiem tra toa do.") end
    return true
end

local function pcReady()
    -- The host refresh flag can clear on timeout. A known size (including 0)
    -- also requires a real storage snapshot; never treat that timeout as ready.
    return isPCOpen() and isCurrentPCBoxRefreshed() and getCurrentPCBoxSize() >= 0
end

local function cleanupStep()
    if not AUTO_PC_CLEANUP then return false end
    if not cleanup then
        if not cleanupWanted and getTeamSize() < 6 then return false end
        if #releasePlan == 0 then cleanupWanted = false; return false end
        if not signature() then stop("Database ID khong duy nhat/chinh xac; khong release."); return true end
        cleanup = {stage="exit", since=os.time()}
        log(string.format("BugCatching: Ra Hall qua (%d,%d) don party tai PC; giu catcher/best/shiny/form.",
            AREA_EXIT[1], AREA_EXIT[2]))
    end
    local op, map = cleanup, getMapName()
    if os.time()-op.since >= (op.pending and 10 or 60) then
        stop("Hall/PC release timeout; khong tu gui lai release."); return true
    end
    if op.stage == "exit" then
        if map == MAP then return cleanupMove(AREA_EXIT[1], AREA_EXIT[2]) end
        if map ~= HALL then stop("Ra Area nhung khong toi Hall du kien."); return true end
        op.stage, op.since = "pc", os.time()
    end
    if op.stage == "pc" then
        if map ~= HALL then stop("Roi Hall trong luc don party; dung release."); return true end
        local pending = op.pending
        if pending then
            if not isPCOpen() or math.abs(getPlayerX()-HALL_PC[1])+math.abs(getPlayerY()-HALL_PC[2]) > 3 then
                stop("PC dong/roi PC trong luc cho release; dung kiem tra."); return true
            end
            local current = signature()
            if not best or best.id ~= pending.keepId then
                stop("Best thay doi trong luc cho release; khong release tiep."); return true
            end
            if current == pending.after then
                log("BugCatching: Server xac nhan da release " .. pending.name .. "; tinh lai slot.")
                op.pending, op.since = nil, os.time()
                return waitForState(250)
            end
            if current ~= pending.before then
                stop("Party/best thay doi ngoai release du kien; khong release tiep."); return true
            end
            local safe = false
            for _, target in ipairs(releasePlan) do if target.id == pending.id then safe = true end end
            if not safe then stop("Muc tieu release da thay doi; dung kiem tra."); return true end
            return waitForState(250) -- Accepted request is NOT authoritative removal. Never resend.
        end
        if #releasePlan == 0 then
            if getTeamSize() >= 6 then stop("Party day nhung chi con best/shiny/form/diem chua biet; khong release."); return true end
            op.stage, op.since, cleanupWanted = "return", os.time(), false
        else
            if not isPCOpen() then
                -- Native helper owns approach to the actual PC access tile.
                if not usePC() then stop("Khong mo duoc PC Hall; khong release khi PC dong.") end
                return true
            end
            if not pcReady() then return waitForState(250) end
            if math.abs(getPlayerX()-HALL_PC[1])+math.abs(getPlayerY()-HALL_PC[2]) > 3 then
                stop("PC dang mo khong o vi tri Hall du kien; khong release."); return true
            end
            local target = releasePlan[1] -- Recomputed from current authoritative party slots.
            local before, after = signature(), signature(target.id)
            if not before or not after then stop("Database ID khong duy nhat/chinh xac; khong release."); return true end
            op.pending = {id=target.id, name=target.name, keepId=best.id, before=before, after=after}
            op.since = os.time()
            log(string.format("BugCatching: PC release slot %d %s score=%.1f; giu best slot %d %s.",
                target.slot, target.name, target.score, best.slot, best.name))
            if not releasePokemonFromTeam(target.slot) then stop("PC tu choi release; khong tu gui lai.") end
            return true
        end
    end
    if op.stage == "return" then
        if map == HALL then
            if isPCOpen() and not pcReady() then return waitForState(250) end
            -- Moving closes the real PC session via the host; no fake close API.
            return cleanupMove(HALL_ENTRANCE[1], HALL_ENTRANCE[2])
        end
        if map ~= MAP then stop("Quay lai Area nhung map khong dung."); return true end
        cleanup = nil
        log("BugCatching: Da ve Area; hunt tiep, KHONG reset timer.")
        return waitForState(250)
    end
    return true
end

local function catcherReady()
    if getTeamSize() < 1 or getPokemonDatabaseId(1) ~= catcherId then
        stop("Catcher slot 1 da thay doi; kiem tra lai party."); return false
    end
    if getPokemonHealth(1) <= 0 then
        stop("Catcher KO; dung, khong dua Pokemon vua bat vao danh."); return false
    end
    return true
end

local function timeUp()
    if deadline and os.time() >= deadline then
        stop("Het gio hunt cuc bo. Neu con trong battle, xu ly luot cuoi thu cong.")
        return true
    end
    return false
end

function onStart()
    stopped = false
    setMount("Manectric Mount")
    if getMapName() ~= MAP and not (cleanup and deadline and getMapName() == HALL) then
        stop("Hay tu vao Bug Catching Area truoc Start (Hall/NPC 12,12 do ban thao tac).")
        return
    end
    if MINUTES_REMAINING <= 0 or MINUTES_REMAINING > 20 then
        stop("Cau hinh minutes (0..20] khong hop le."); return
    end
    if type(MAX_LOW_TIER_CATCHES) ~= "number" or MAX_LOW_TIER_CATCHES ~= math.floor(MAX_LOW_TIER_CATCHES)
            or MAX_LOW_TIER_CATCHES < 0 or MAX_LOW_TIER_CATCHES > 5
            or type(LOW_TIER_FILL_LAST_MINUTES) ~= "number"
            or not (LOW_TIER_FILL_LAST_MINUTES >= 0 and LOW_TIER_FILL_LAST_MINUTES <= 20) then
        stop("Cau hinh quota tier 1/2 (0..5) / fill minutes (0..20) khong hop le."); return
    end
    if getTeamSize() < 1 or not hasMove(1, "False Swipe") then
        stop("Can catcher biet False Swipe o slot 1."); return
    end
    catcherId = catcherId or getPokemonDatabaseId(1)
    if not catcherReady() then return end
    if AUTO_PC_CLEANUP and not signature() then
        stop("Database ID khong duy nhat/chinh xac; khong release."); return
    end
    -- Stop/Start in the SAME loaded script must not renew the contest timer.
    deadline = deadline or (os.time() + math.floor(MINUTES_REMAINING * 60))
    refreshScores()
    if timeUp() then return end
    if not hasBalls() then stop("Het bong."); return end
    log(string.format("BugCatching: Con khoang %ds; tier 1/2 chi HP weight=1 (nhom HP cao nhat), tier 3/4 nem bong ngay. Timer server moi la chuan.",
        math.max(0, deadline-os.time())))
    if AUTO_PC_CLEANUP then
        log("BugCatching: Hall PC cleanup BAT: best moi cao diem hon/day party thi don con thuong; giu catcher/best/shiny/form. Quota fallback khong ap dung.")
    else
        log(string.format("BugCatching: PC cleanup TAT. Tier 1/2 thuong toi da %d con; mo quota trong %.1f phut cuoi, van loc HP/diem.",
            MAX_LOW_TIER_CATCHES, LOW_TIER_FILL_LAST_MINUTES))
    end
    log("BugCatching: Reload phai dien lai MINUTES_REMAINING theo timer server.")
end

function onPathAction()
    if stopped then return end
    refreshScores() -- Server party is authoritative; never count a ball as a catch.
    if getMapName() ~= MAP and not (cleanup and getMapName() == HALL) then
        stop("Da roi hunting area; dung de ban nop bai."); return
    end
    if timeUp() or not catcherReady() then return end
    if encounter and encounter.ballThrown and getTeamSize() <= encounter.teamSize then
        encounter.endedAt = encounter.endedAt or os.time()
        if os.time() - encounter.endedAt < 3 then return waitForState(250) end
        stop("Battle da ket thuc sau nem bong nhung chua thay catch trong party; kiem tra thu cong.")
        return
    end
    encounter = nil
    if STOP_AT_SCORE > 0 and best and best.score >= STOP_AT_SCORE then
        stop("Da dat STOP_AT_SCORE."); return
    end
    if cleanupStep() then return end
    if getTeamSize() >= 6 then
        stop("Party day, khong con con thuong co the don; dung de ban nop best."); return
    end
    if not hasBalls() then stop("Het bong."); return end
    if not moveToRectangle(RECTANGLE[1], RECTANGLE[2], RECTANGLE[3], RECTANGLE[4]) then
        stop("Khong di duoc rectangle; chinh lai toa do bai co.")
    end
end

local function chooseEncounter()
    local pokemon, level = getOpponentName(), getOpponentLevel()
    -- Snapshot the WILD's battle HP BEFORE any False Swipe/ball. No party IV
    -- getter is involved in this inference. Max HP remains usable after damage.
    local currentHP, maxHP = getOpponentHealth(), getOpponentMaxHealth()
    local special = isOpponentShiny() or (tonumber(getOpponentForm()) or 0) ~= 0
    local p = Score.species(pokemon)
    local range, reason
    -- Form base stats may differ from the normal species: do not infer its IV.
    if (tonumber(getOpponentForm()) or 0) == 0 then
        range, reason = Score.hpRank(pokemon, level, maxHP)
    else reason = "alternate form: normal base HP not assumed" end
    local bounds = Score.bounds(pokemon, level, range, isOpponentShiny())
    local catch = special or (p and ENABLED_TIERS[p.tier]) or false
    local directBall = special or (p and p.tier >= 3) or false
    if not special and catch and p.tier <= 2 then
        if range and not range.isTop then catch = false end
        if bounds and best and bounds.max <= best.score then catch = false end
        if catch and not lowTierBudgetOpen() then
            catch = false
            log("BugCatching: BO QUA tier 1/2: da du quota, giu cho cho tier 3/4 va shiny/form.")
        end
    end
    if range then
        log(string.format("BugCatching: TRUOC BAT %s | HP battle=%d/%d | baseHP=%d | lv%d => HP IV=%d..%d | HP weight=%.3f (topHP=%d) | score CO THE=%.1f..%.1f | %s.",
            pokemon, currentHP, maxHP, p.baseHP, level, range.min, range.max,
            range.weight, range.topHP,
            bounds.min, bounds.max, catch and "BAT" or "BO QUA"))
    else
        log("BugCatching: TRUOC BAT " .. pokemon .. " | khong suy ra HP IV: " .. tostring(reason)
            .. " | " .. (catch and "BAT (khong loc khi thieu du lieu)." or "BO QUA tier."))
    end
    return {catch=catch, special=special, directBall=directBall, swipes=0, teamSize=getTeamSize()}
end

function onBattleAction()
    if stopped or timeUp() or not catcherReady() then return end
    if not isWildBattle() then stop("Khong phai wild battle; xu ly thu cong."); return end
    if getActivePokemonNumber() ~= 1 then
        stop("Active Pokemon khong phai catcher slot 1; khong tu doi Pokemon."); return
    end
    if getMapName() ~= MAP then stop("Battle ngoai Area; xu ly thu cong."); return end
    if cleanup then
        if cleanup.stage ~= "exit" then stop("Battle bat ngo trong Hall/PC cleanup; dung kiem tra."); return end
        if not isOpponentShiny() and (tonumber(getOpponentForm()) or 0) == 0 then
            if not run() then stop("Khong chay duoc tren duong ra Hall.") end
            return
        end
    end
    encounter = encounter or chooseEncounter()
    -- Protect a shiny/form revealed after the first callback as well.
    if isOpponentShiny() or (tonumber(getOpponentForm()) or 0) ~= 0 then
        encounter.catch, encounter.special, encounter.directBall = true, true, true
    end
    if not encounter.catch then
        if not run() then stop("Khong chay duoc; khong tu tan cong Pokemon.") end
        return
    end
    if getTeamSize() >= 6 then stop("Party day trong battle; khong bat day sang PC."); return end
    if not hasBalls() then stop("Het bong khi gap muc tieu; khong chay/ha muc tieu."); return end
    if not encounter.directBall and getOpponentHealth() > 1
            and encounter.swipes < MAX_FALSE_SWIPES and hasMove(1, "False Swipe")
            and getRemainingPowerPoints(1, "False Swipe") > 0 then
        if useMove("False Swipe") then
            encounter.swipes = encounter.swipes + 1
            return true
        end
    end
    for _, ball in ipairs(BALLS) do
        if hasItem(ball) and useItem(ball) then encounter.ballThrown = true; return true end
    end
    stop("Khong the nem bong; kiem tra battle thu cong (khong attack/run fallback).")
end

function onStop()
    refreshScores()
    reportBest()
end

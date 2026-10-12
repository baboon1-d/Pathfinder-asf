-- One route owner for Dig, PokeStop and Berry. No Excavation/cart handling.
-- Inter-map cost comes from Pathfinder; local ranking is Manhattan distance,
-- NOT a claim of terrain-shortest paths. Core validates talk/movement routes.
local M = {}
local function base(node) return node:gsub("_%u$", "") end
local function cellKey(kind,map,x,y) return kind..":"..map..":"..x..","..y end

function M.new(pf, tasks, config)
    config=config or {}
    local retry=config.retrySeconds or 200
    local confirm=config.confirmEmptyReads or 3
    -- Select nearby work using the original graph cost. Service priority is
    -- applied only to travel towards that fixed goal, not to the union of jobs:
    -- otherwise a local Maze job could lose to a distant station-served map.
    local travelOptions=(config.preferTransport or config.digFallback) and
        {requireActionable=true,preferTransport=config.preferTransport==true,digFallback=config.digFallback==true} or nil
    local empty, failures, blocked, pending, goal = {}, {}, {}, nil, nil
    -- Status skips are exact-string keys. A concrete _B failure must also
    -- exclude its full-map alias (possibly owned by a different task), or
    -- getPath will expand that alias straight back to the failed destination.
    -- Quarantine this physical-map family for navigation only; live local
    -- harvesting remains enabled. This is temporary, never a DONE record.
    local routeBlocked={}
    local order=config.regionOrder
    if order then
        assert(type(order)=="table" and #order>0 and type(pf.getRegion)=="function",
            "DigRework: region schedule requires the matching Pathfinder getRegion module")
        local valid={Kanto=true,Johto=true,Hoenn=true,Sinnoh=true}
        local seen={}
        for _,region in ipairs(order) do
            assert(valid[region] and not seen[region],"DigRework: invalid/duplicate region "..tostring(region))
            seen[region]=true
        end
    end
    local phase,nextTourAt,tourFinished=1,nil,false
    local tourDeferred={}
    -- Valid current-map API snapshots tell us which concrete regions still
    -- contain work. Keep that knowledge while travelling; never re-expand a
    -- known full-map alias to already empty regions on the next through-map.
    local observed={}
    local goalOwners=nil
    local lastLog, unavailableUntil, lastWaitAt = nil, 0, -math.huge
    local R={active=nil}
    local function now() return os.time() end
    local function say(message)
        if message~=lastLog then log("DigRework: "..message); lastLog=message end
    end
    local function wait(ms) return waitForState(ms or 250) end
    local function advanceRegion(reason)
        say("Lich "..order[phase]..": "..reason.."; KHONG quay lai trong luot nay.")
        phase=phase+1
        if phase>#order then
            tourFinished=true; nextTourAt=nil
            for _,task in ipairs(tasks) do
                if task.enabled() and type(task.status.nextHarvestAt)=="function" then
                    local ready=task.status.nextHarvestAt(now())
                    if ready and (not nextTourAt or ready<nextTourAt) then nextTourAt=ready end
                end
            end
            local n=0; for _ in pairs(tourDeferred) do n=n+1 end
            say("Het luot "..table.concat(order," -> ").."; map bi hoan="..n
                .." (KHONG ghi DONE). "..(nextTourAt and "Cho cooldown thu gom cho luot moi."
                    or "Cho lan Start moi; khong tu di lai cac diem bi chan."))
        else say("Lich vung -> "..order[phase]) end
        return wait()
    end
    local function nodeAt(map,x,y)
        local ok,node=pcall(pf.getMapNode,map,x,y)
        if ok and type(node)=="string" then return node end
    end
    local function knownHere(task,node,map)
        local result={}
        for _,target in ipairs(task.maps) do
            if target==node or (target==map and base(node)==map) then
                result[#result+1]=target
            end
        end
        return result
    end
    local function skipHere(task,node,map)
        for _,target in ipairs(knownHere(task,node,map)) do task.status.skip(target,retry) end
    end
    local function validCoordinate(v)
        return type(v)=="number" and v==v and v>=0 and v<math.huge and v==math.floor(v)
    end
    local function scan(task,map)
        if type(task.api)~="function" then return nil end
        local ok,raw=pcall(task.api)
        if not ok or type(raw)~="table" then return nil end
        local result,seen={},{}
        for _,item in pairs(raw) do
            if type(item)~="table" then return nil end
            local x,y=tonumber(item.x),tonumber(item.y)
            if not validCoordinate(x) or not validCoordinate(y) then return nil end
            local node=nodeAt(map,x,y)
            if not node then return nil end -- Unknown subnode is not an empty map.
            local key=cellKey(task.name,map,x,y)
            if not seen[key] then
                result[#result+1]={task=task,x=x,y=y,node=node,key=key,map=map}
                seen[key]=true
            end
        end
        return result
    end
    local function quarantine(spot,reason)
        blocked[spot.key]=now()+retry
        say(spot.task.label.." ("..spot.x..","..spot.y..") "..reason
            .."; thu lai sau "..retry.."s, KHONG ghi DONE.")
        pending=nil
    end
    function R.step()
        if tourFinished then
            if not nextTourAt or now()<nextTourAt then return wait(1000) end
            phase=1; tourFinished=false; nextTourAt=nil
            tourDeferred={}; routeBlocked={}; blocked={}; observed={}
            empty={}; failures={}; pending=nil; goal=nil; goalOwners=nil
            say("Cooldown thu gom da den; bat dau luot "..table.concat(order," -> "))
        end
        local map=getMapName()
        local node=nodeAt(map,getPlayerX(),getPlayerY())
        if not node then
            fatal("DigRework: Khong xac dinh duoc node tai "..map.."; gui map/toa do.")
            return
        end
        local t=now()
        -- Old-map keys are not needed: bound temporary memory while travelling.
        for key,expiry in pairs(blocked) do if expiry<=t then blocked[key]=nil end end
        for key,expiry in pairs(routeBlocked) do if expiry<=t then routeBlocked[key]=nil end end
        local localSpots,remoteNodes,present={},{},{}
        local confirming,anyEnabled=false,false
        for _,task in ipairs(tasks) do
            if task.enabled() then
                anyEnabled=true
                local spots=scan(task,map)
                local k=task.name..":"..node
                if not spots then
                    empty[k]=0; failures[k]=(failures[k] or 0)+1
                    if failures[k]>=8 then
                        skipHere(task,node,map)
                        if order and pf.getRegion(node)==order[phase] then tourDeferred[base(node)]=true end
                        say(task.label.." API/node chua san sang; tam bo qua, KHONG ghi DONE.")
                    elseif #knownHere(task,node,map)>0 then confirming=true end
                else
                    failures[k]=0
                    observed[task]=observed[task] or {}
                    local remaining={}
                    for _,spot in ipairs(spots) do remaining[spot.node]=true end
                    -- Empty confirmation is owned by the persistent status.
                    -- Do not retain an empty snapshot forever: after the
                    -- normal harvest cooldown expires this map is unknown
                    -- again and must be eligible for a fresh inspection.
                    observed[task][base(node)]=next(remaining) and remaining or nil
                    local count=0
                    for _,spot in ipairs(spots) do
                        present[spot.key]=spot
                        if spot.node==node then
                            count=count+1
                            if not blocked[spot.key] then localSpots[#localSpots+1]=spot end
                        elseif not blocked[spot.key] then
                            remoteNodes[spot.node]=remoteNodes[spot.node] or {}
                            remoteNodes[spot.node][task]=true
                        end
                    end
                    -- Unsuffixed map records represent the ENTIRE physical map.
                    -- Never mark one done while any other region still has spots.
                    local here=knownHere(task,node,map)
                    if count==0 then
                        empty[k]=(empty[k] or 0)+1
                        for _,target in ipairs(here) do
                            if target~=map or #spots==0 then
                                if task.status.readyInfo(target,t) then
                                    if empty[k]>=confirm then
                                        task.status.markDone(target)
                                        say(task.label..": xac nhan het diem tai "..target)
                                    else confirming=true end
                                end
                            end
                        end
                    else empty[k]=0 end
                    -- Non-actionable live spots are NOT proof of completion.
                    local usable=false
                    for _,spot in ipairs(localSpots) do if spot.task==task then usable=true end end
                    if count>0 and not usable then
                        skipHere(task,node,map)
                        if order and pf.getRegion(node)==order[phase] then tourDeferred[base(node)]=true end
                    end
                end
            end
        end
        if not anyEnabled then pending=nil; goal=nil; goalOwners=nil; R.active=nil; say("Ca 3 loai dang tat."); return wait(1000) end
        if goal then
            local enabledOwner=false
            for task in pairs(goalOwners or {}) do
                if task.enabled() then enabledOwner=true; break end
            end
            -- Only arrival, explicit task disable, or route failure below
            -- releases a chosen destination. An intermediate map's NPC scan
            -- cannot say anything about a remote goal's continued existence.
            if goal==node or goal==map or not enabledOwner then goal=nil; goalOwners=nil end
        end
        if pending then
            local spot=present[pending.key]
            if not spot or spot.node~=node or not spot.task.enabled() then pending=nil end
        end
        -- Do not let incidental work in a transit region change the schedule.
        -- Its snapshot can still inform later planning; collection waits until
        -- that region's turn. Other Pathfinder scripts keep their old behavior.
        if order and (pf.getRegion(node)~=order[phase] or tourDeferred[base(node)]) then
            localSpots={}; pending=nil; confirming=false
        end
        local spot=pending and present[pending.key]
        if not spot then
            table.sort(localSpots,function(a,b)
                local da=math.abs(a.x-getPlayerX())+math.abs(a.y-getPlayerY())
                local db=math.abs(b.x-getPlayerX())+math.abs(b.y-getPlayerY())
                if da==db then return a.key<b.key end
                return da<db
            end)
            spot=localSpots[1]
        end
        if spot then
            -- Opportunistic harvesting pauses navigation, not its destination.
            -- Keep the remote goal through this map and resume after harvesting.
            R.active=spot
            if spot.task.name=="pokestop" and type(isNpcVisible)=="function"
                    and isNpcVisible("Firebreather Ashton") then
                quarantine(spot,"Firebreather Ashton dang hien dien")
                return wait()
            end
            local pos=getPlayerX()..":"..getPlayerY()
            if not pending then
                pending={key=spot.key,pos=pos,stalled=0}
                say(spot.task.label.." -> "..node.." ("..spot.x..","..spot.y..")")
            elseif pending.pos==pos then pending.stalled=pending.stalled+1
            else pending.pos=pos; pending.stalled=0 end
            if pending.stalled>=8 then quarantine(spot,"khong co tien trinh tuong tac"); return wait() end
            if not isNpcOnCell(spot.x,spot.y) then return wait() end
            -- true can mean walking only. Keep this target until the active API
            -- actually removes it, or the bounded no-progress retry quarantines it.
            if talkToNpcOnCell(spot.x,spot.y) then return true end
            return wait()
        end
        R.active=nil
        if confirming then return wait() end
        local targets,set,owners={},{},{}
        local function add(target,task)
            if routeBlocked[base(target)] or tourDeferred[base(target)] then return end
            if order and not pf.getRegion(target) then
                tourDeferred[base(target)]=true
                say("Hoan "..target..": chua co metadata vung; KHONG ghi DONE.")
                return
            end
            if not set[target] then set[target]=true; targets[#targets+1]=target end
            owners[target]=owners[target] or {}
            owners[target][task]=true
        end
        for _,task in ipairs(tasks) do
            if task.enabled() then
                for _,target in ipairs(task.status.readyMaps(t)) do
                    local remaining=observed[task] and observed[task][target]
                    if remaining then
                        for region in pairs(remaining) do add(region,task) end
                    else add(target,task) end
                end
            end
        end
        for target,remoteOwners in pairs(remoteNodes) do
            for task in pairs(remoteOwners) do add(target,task) end
        end
        -- A blocked/API-unavailable current node cannot be retried by an alias
        -- unsuffixed map target or by a second task on the same physical map.
        if #targets==0 and not goal then
            if order then return advanceRegion("khong con dich san sang (DONE/cooldown/hoan)") end
            local earliest
            for _,expiry in pairs(routeBlocked) do
                if not earliest or expiry<earliest then earliest=expiry end
            end
            for _,task in ipairs(tasks) do
                if task.enabled() then
                    local e=task.status.earliest(t)
                    if e and (not earliest or e<earliest) then earliest=e end
                end
            end
            if t-lastWaitAt>=300 then
                lastWaitAt=t
                if earliest then say("Cho cooldown; diem som nhat con "..math.max(0,earliest-t).."s.")
                else say("Khong co diem san sang.") end
            end
            return wait(1000)
        end
        if not goal and t<unavailableUntil then return wait(1000) end
        if not goal then
            if order then
                local scoped={}
                for _,target in ipairs(targets) do
                    if pf.getRegion(target)==order[phase] then scoped[#scoped+1]=target end
                end
                targets=scoped
                if #targets==0 then return advanceRegion("khong con dich san sang (DONE/cooldown/hoan)") end
            end
            local ok,path,cost=pcall(pf.getPath,node,targets,{requireActionable=true})
            if not ok or type(path)~="table" or #path==0 then
                if order then
                    for _,target in ipairs(targets) do tourDeferred[base(target)]=true end
                    local reason=ok and "khong co tuyen authored"
                        or "getPath error: "..tostring(path):gsub("[\r\n]"," "):sub(1,220)
                    return advanceRegion(reason.."; hoan "..#targets.." dich, KHONG ghi DONE")
                end
                goal=nil; unavailableUntil=t+retry
                local reason=ok and "no authored route to remaining destinations" or tostring(path):gsub("[\r\n]"," "):sub(1,220)
                say("Khong co tuyen kha dung; cho "..retry.."s, KHONG ghi DONE."
                    .." from="..node.." ("..getPlayerX()..","..getPlayerY()..")"
                    .." targets="..#targets.." reason="..reason
                    .." remaining="..table.concat(targets,","):sub(1,240))
                return wait(1000)
            end
            goal=path[#path]
            -- getPath expands a full-map target such as "Route 115" into an
            -- actual _A/_B destination. Preserve that alias's owners as well.
            goalOwners={}
            for task in pairs(owners[goal] or {}) do goalOwners[task]=true end
            for task in pairs(owners[base(goal)] or {}) do goalOwners[task]=true end
            local labels={}
            for task in pairs(goalOwners) do labels[#labels+1]=task.label end
            table.sort(labels)
            say("Tuyen chung -> "..goal.."; cost="..tostring(cost).."; candidates="..#targets
                .."; tasks="..table.concat(labels,"+")..(order and "; region="..order[phase] or "")
                ..(config.preferTransport and "; travel=prefer Subway/Teleport (cost tren la chon dich)" or "")
                ..(config.digFallback and "; digFallback=on" or ""))
        end
        if goal==node or goal==map then
            -- Full-map alias may still contain a different subnode. Those live
            -- nodes were included above; route explicitly to one rather than bounce.
            if next(remoteNodes) then
                local list={}; for target in pairs(remoteNodes) do
                    if not routeBlocked[base(target)] then list[#list+1]=target end
                end
                table.sort(list)
                local ok,path=pcall(pf.getPath,node,list,{requireActionable=true})
                if ok and type(path)=="table" and #path>0 then
                    goal=path[#path]
                    goalOwners=remoteNodes[goal]
                    say("Dich subnode -> "..goal.."; giu dich qua cac map trung gian.")
                end
            end
            if goal==node or goal==map then
                for _,task in ipairs(tasks) do if task.enabled() then skipHere(task,node,map) end end
                if order then tourDeferred[base(node)]=true end
                goal=nil; goalOwners=nil
                return wait()
            end
        end
        local ok,accepted=pcall(pf.moveTo,node,goal,travelOptions)
        if ok and accepted then return true end
        say("Tuyen bi chan toi "..tostring(goal).."; tam bo qua, KHONG ghi DONE."
            .." from="..node.." ("..getPlayerX()..","..getPlayerY()..")"
            .." reason="..(ok and "moveTo returned "..tostring(accepted)
                or tostring(accepted):gsub("[\r\n]"," "):sub(1,220)))
        routeBlocked[base(goal)]=t+retry
        if order then tourDeferred[base(goal)]=true end
        for _,task in ipairs(tasks) do task.status.skip(goal,retry) end
        for _,s in pairs(present) do if s.node==goal then blocked[s.key]=t+retry end end
        goal=nil; goalOwners=nil
        return wait()
    end
    return R
end
return M

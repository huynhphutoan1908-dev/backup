-- =====================================================================
-- HTDC CLEAN ENGINE (DA GO BO 100% CHECK LICENSE & AUTHEN SERVER)
-- TAO BOI DANIEL WORKSHOP - TUONG THICH 100% VOI MENU MOI & INJECTOR CHAY
-- =====================================================================

local Unity = CS.UnityEngine
_G.VinhPcLuaGate = _G.VinhPcLuaGate or {
    allowed = function() return true end,
    state = 'ready',
    scope = 'authorized',
    busy = function() return false end,
    open = function() end,
    set = function() return 'authorized' end,
    start = function(task, ...)
        if CsCoroutine and CsCoroutine.start then
            return CsCoroutine.start(task, ...)
        end
        local co = coroutine.create(task)
        local ok, err = coroutine.resume(co, ...)
        if not ok then print("[HTDC Coroutine Error]: " .. tostring(err)) end
        return co
    end
}
_G.VinhLuaGate = _G.VinhPcLuaGate
_G.HTPS_AUTO_ACTIVATED = true
_G.HTPS_FEATURES_LOADED = true
_G.HTPS_CAMPAIGN_AUTO_ENABLED = true

-- =====================================================================
-- TÍNH NĂNG: Tự Động Chiêu Mộ x10, Nâng Phẩm Tướng 15 Sao, Max 300 Cấp Trang Bị Vai Trò & Nhóm Hạng
-- TRÍCH XUẤT TỪ NGUYENVINHMOD.DLL BẰNG REA ENGINE
-- =====================================================================

local gate = _G.VinhPcLuaGate
-- [BYPASSED AUTHEN GATE CHECK]
if gate.state then return gate.state end
gate.state = 'loading'
local CsCoroutine = setmetatable({start=gate.start},{__index=function(t,k) return (CS and CS.CsCoroutine and CS.CsCoroutine[k]) end})
_G.HTPS_CAMPAIGN_AUTO_ENABLED = false
local ok, message = pcall(function()
if not _G.HTDC_REBUILD_LOADED then
    _G.HTDC_REBUILD_LOADED = true
    _G.HTPS_AUTO_ACTIVATED = true
    _G.HTPS_FEATURES_LOADED = true
    print('HTDC_REBUILD BEGIN 20261115')
-- =====================================================================
-- HTPS AUTO AGENT (SUMMON X10 & SPECIAL EQUIP MAX 300 + IN-GAME UI)
-- =====================================================================
do
    print("=== HTPS AUTO AGENT INITIALIZING ===")
    pcall(function() typeof(CS.UnityEngine.Application):GetProperty("runInBackground"):SetValue(nil, true, nil) end)
    local GO = CS.UnityEngine.GameObject
    local UG = CS.UnityEngine
    _G.HTPS_FindObjectOfType = function(t)
        local O = CS.UnityEngine.Object
        if O.FindObjectOfType then
            return O.FindObjectOfType(t)
        end
        return O.FindFirstObjectByType(t)
    end
    _G.HTPS_FindObjectsOfType = function(t)
        local O = CS.UnityEngine.Object
        if O.FindObjectsOfType then
            return O.FindObjectsOfType(t)
        end
        return O.FindObjectsByType(t, CS.UnityEngine.FindObjectsSortMode.None)
    end
    local BF = CS.System.Reflection.BindingFlags
    local REF_FLAGS = BF.Public | BF.NonPublic | BF.Instance | BF.Static

    _G.HTPS_AUTO = _G.HTPS_AUTO or {
        running = false,
        suppressPopup = false,
        suppressUntil = 0,
        faction = CS.HeroFaction.FORTRESS,
        useScreenFaction = true,
        modeTag = "",
        delay = 0.05,
        batch = 1,
        remain = 0,
        sessionDone = 0,
        totalDone = 0
    }
    _G.HTPS_AUTO.suppressPopup = false
    _G.HTPS_AUTO.suppressUntil = 0
    _G.HTPS_BONUS_SUPPRESS_UNTIL = 0

    local FACTION_LOOKUP = {
        AGI = CS.HeroFaction.FORTRESS,
        FORTRESS = CS.HeroFaction.FORTRESS,
        VIT = CS.HeroFaction.SHADOW,
        SHADOW = CS.HeroFaction.SHADOW,
        STR = CS.HeroFaction.ABYSS,
        ABYSS = CS.HeroFaction.ABYSS,
        DEX = CS.HeroFaction.FOREST,
        FOREST = CS.HeroFaction.FOREST,
        LIGHT = CS.HeroFaction.LIGHT,
        DARK = CS.HeroFaction.DARK
    }

    local BOX_TYPE = typeof(CS.BoxOrbSummon)
    local BOX_FAC_FIELD = BOX_TYPE:GetField("m_FactionSelected", REF_FLAGS)
    local BOX_LIST_FIELD = BOX_TYPE:GetField("m_ListFactionSelect", REF_FLAGS)
    local SFS_TYPE = typeof(CS.SummonFactionSelect)
    local SFS_IMG_FIELD = SFS_TYPE:GetField("m_GoImageSelect", REF_FLAGS)
    local SFS_FAC_FIELD = SFS_TYPE:GetField("m_Faction", REF_FLAGS)

    _G.HTPS_KillSummonPopups = function()
        pcall(function()
            if not _G.HTPS_AUTO then return end
            local now = UG.Time.realtimeSinceStartup
            local activeSummon = _G.HTPS_AUTO.running or (now < (_G.HTPS_AUTO.suppressUntil or 0))
            local activeBonus = _G.HTPS_FORGE_RUNNING or _G.HTPS_SHOP_AUTO_RESET_RUNNING or _G.HTPS_HERO_BAG_EXPAND_RUNNING or _G.HTPS_EXC_AUTO_RUNNING or _G.HTPS_PET_SUMMON_RUNNING or _G.HTPS_PET_AWAKEN_RUNNING or _G.HTPS_LUCKY_SPIN_RUNNING or _G.HTPS_LUCKY_DUST_RUNNING or _G.HTPS_SUPER_LUCKY_SPIN_RUNNING or _G.HTPS_SUPER_LUCKY_YR_RUNNING or _G.HTPS_SHIP_CRAFT_RUNNING or _G.HTPS_AUTO_ALBUM_RUNNING or (now < (_G.HTPS_BONUS_SUPPRESS_UNTIL or 0))
            if not activeSummon and not activeBonus then
                _G.HTPS_AUTO.suppressPopup = false
                return
            end
            if activeSummon then
                local guard = 0
                while guard < 30 do
                    local go = GO.Find("PopupShowBonusEffect2(Clone)")
                    if go == nil then break end
                    go.name = "_DEAD_POPUP_"
                    go:SetActive(false)
                    GO.Destroy(go)
                    guard = guard + 1
                end
            end
            if activeBonus then
                local guard = 0
                while guard < 30 do
                    local go = GO.Find("PopupShowBonusEffect(Clone)") or GO.Find("PopupShowBonus(Clone)") or GO.Find("PopupShowBonusEffectPet(Clone)") or GO.Find("PopupSummonPet(Clone)") or GO.Find("PopupPetStarUpgrade(Clone)")
                    if go == nil then break end
                    go.name = "_DEAD_POPUP_"
                    go:SetActive(false)
                    GO.Destroy(go)
                    guard = guard + 1
                end
                local guard2 = 0
                while guard2 < 30 do
                    local bgo = GO.Find("PopupBlockTouch(Clone)")
                    if bgo == nil then break end
                    bgo.name = "_DEAD_BLOCK_"
                    bgo:SetActive(false)
                    GO.Destroy(bgo)
                    guard2 = guard2 + 1
                end
                local ls = _G.HTPS_FindObjectOfType(typeof(CS.LuckySpinScene))
                if ls then
                    ls:GetType():GetField("m_SpinDiskActive", 60):SetValue(ls, true)
                    local sd = ls:GetType():GetField("m_SpinDisk", 60):GetValue(ls)
                    if sd then
                        sd:GetType():GetField("m_BonusModel", 60):SetValue(sd, nil)
                        if not (_G.HTPS_LUCKY_SPIN_RUNNING or _G.HTPS_LUCKY_DUST_RUNNING) then
                            sd:GetType():GetField("m_RotateVelocity", 60):SetValue(sd, 0)
                            sd:GetType():GetField("m_RotateAcceleration", 60):SetValue(sd, 0)
                        end
                    end
                end
                local sls = _G.HTPS_FindObjectOfType(typeof(CS.SuperLuckySpinScene))
                if sls then
                    sls:GetType():GetField("m_SpinDiskActive", 60):SetValue(sls, true)
                    local ssd = sls:GetType():GetField("m_SpinDisk", 60):GetValue(sls)
                    if ssd then
                        ssd:GetType():GetField("m_BonusModel", 60):SetValue(ssd, nil)
                        if not (_G.HTPS_SUPER_LUCKY_SPIN_RUNNING or _G.HTPS_SUPER_LUCKY_YR_RUNNING) then
                            ssd:GetType():GetField("m_RotateVelocity", 60):SetValue(ssd, 0)
                            ssd:GetType():GetField("m_RotateAcceleration", 60):SetValue(ssd, 0)
                        end
                    end
                end
                local pls = _G.HTPS_FindObjectsOfType(typeof(CS.PanelLoading))
                for i = 0, pls.Length - 1 do
                    local pb = pls[i].transform:Find("PanelBlock")
                    if pb and pb.gameObject.activeSelf then
                        pb.gameObject:SetActive(false)
                    end
                end
            end
        end)
    end

    if not _G.HTPS_POPUP_KILLER_LOOP_V2 then
        _G.HTPS_POPUP_KILLER_LOOP_V2 = true
        CsCoroutine.start(function()
            while true do
                _G.HTPS_KillSummonPopups()
                coroutine.yield(nil)
            end
        end)
    end

    _G.HTPS_GetBoxSelectedFaction = function(box)
        local fac = nil
        pcall(function()
            if box == nil then
                box = _G.HTPS_FindObjectOfType(BOX_TYPE)
            end
            if box ~= nil then
                if BOX_FAC_FIELD then
                    fac = BOX_FAC_FIELD:GetValue(box)
                end
                if fac == nil or fac == CS.HeroFaction.UNKNOWN or tostring(fac):find("UNKNOWN") then
                    if BOX_LIST_FIELD then
                        local lst = BOX_LIST_FIELD:GetValue(box)
                        if lst and lst.Count then
                            for i = 0, lst.Count - 1 do
                                local item = lst[i]
                                if item and SFS_IMG_FIELD and SFS_FAC_FIELD then
                                    local imgGo = SFS_IMG_FIELD:GetValue(item)
                                    if imgGo and imgGo.activeSelf then
                                        fac = SFS_FAC_FIELD:GetValue(item)
                                        break
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end)
        if fac == nil or fac == CS.HeroFaction.UNKNOWN or tostring(fac):find("UNKNOWN") then
            fac = CS.HeroFaction.FORTRESS
        end
        return fac
    end

    _G.HTPS_StartSummon = function(factionKey, countX10, delaySec, batchSize, modeTag)
        local fac = FACTION_LOOKUP[factionKey]
        local useScreen = (factionKey == "CURRENT" or fac == nil)
        if useScreen then
            fac = _G.HTPS_GetBoxSelectedFaction(nil)
        end

        local tag = tostring(modeTag or "CUSTOM")
        local bSize = tonumber(batchSize) or 1
        if bSize <= 1 then
            if tag == "TURBO" or tag == "50X10" then
                bSize = 5
            elseif tag == "FAST" then
                bSize = 2
            end
        end

        local mySessionId = (_G.HTPS_AUTO.sessionId or 0) + 1
        _G.HTPS_AUTO.sessionId = mySessionId
        _G.HTPS_AUTO.faction = fac
        _G.HTPS_AUTO.useScreenFaction = useScreen
        _G.HTPS_AUTO.modeTag = tag
        _G.HTPS_AUTO.remain = tonumber(countX10) or 10
        _G.HTPS_AUTO.delay = tonumber(delaySec) or 0.02
        _G.HTPS_AUTO.batch = bSize
        _G.HTPS_AUTO.sessionDone = 0
        _G.HTPS_AUTO.suppressPopup = true
        _G.HTPS_AUTO.suppressUntil = UG.Time.realtimeSinceStartup + 0.3
        _G.HTPS_AUTO.running = true

        CsCoroutine.start(function()
            while _G.HTPS_AUTO.running and _G.HTPS_AUTO.sessionId == mySessionId do
                if _G.HTPS_AUTO.remain == 0 then
                    _G.HTPS_AUTO.running = false
                    _G.HTPS_AUTO.suppressUntil = UG.Time.realtimeSinceStartup + 0.3
                    break
                end

                if _G.HTPS_AUTO.useScreenFaction then
                    local boxAlive = false
                    pcall(function()
                        local box = _G.HTPS_FindObjectOfType(BOX_TYPE)
                        if box ~= nil and box.gameObject.activeInHierarchy then
                            _G.HTPS_AUTO.faction = _G.HTPS_GetBoxSelectedFaction(box)
                            boxAlive = true
                        end
                    end)
                    if not boxAlive then
                        _G.HTPS_AUTO.running = false
                        _G.HTPS_AUTO.suppressUntil = UG.Time.realtimeSinceStartup + 0.3
                        break
                    end
                end

                local gc = CS.GameContext.GetIntance()
                local nc = CS.NetworkController.GetInstance()
                if not gc or not gc.m_Session or gc.m_Session == "" or not gc.m_UserId or gc.m_UserId <= 0 or not nc then
                    _G.HTPS_AUTO.running = false
                    break
                end

                local reqBatch = _G.HTPS_AUTO.batch or 1
                if _G.HTPS_AUTO.remain > 0 and reqBatch > _G.HTPS_AUTO.remain then
                    reqBatch = _G.HTPS_AUTO.remain
                end
                if reqBatch < 1 then reqBatch = 1 end

                local facStr = tostring(_G.HTPS_AUTO.faction):match("^([%w_]+)")
                facStr = facStr and facStr:lower() or "fortress"

                local req = CS.pbdson.RequestData()
                req.session = gc.m_Session
                for i = 1, reqBatch do
                    local cv = CS.pbdson.CommonVector()
                    cv.aLong:Add(10)
                    cv.aString:Add(facStr)
                    local act = CS.pbdson.PbAction()
                    act.actionId = 212
                    act.data = _G.HTPS_SerializeProto(cv)
                    req.actions:Add(act)
                end

                _G.HTPS_AUTO.suppressUntil = UG.Time.realtimeSinceStartup + 0.3
                local d, ok = _G.HTPS_PutWebRequest(
                    nc.m_UrlGameServer .. "/i/212/" .. tostring(gc.m_UserId),
                    _G.HTPS_SerializeProto(req),
                    8
                )

                local serverErr = nil
                if ok and d then
                    pcall(function()
                        local resp = _G.HTPS_DeserializeProto(d, "pbdson.ResponseData,PbMethodLib")
                        if resp and resp.aAction then
                            for i = 0, resp.aAction.Count - 1 do
                                local a = resp.aAction[i]
                                if a.actionId == 212 and a.data then
                                    local rcv = _G.HTPS_DeserializeProto(a.data, "pbdson.CommonVector,PbMethodLib")
                                    if rcv and rcv.aLong and rcv.aLong.Count > 0 then
                                        CS.BonusModel.ParseBonusReceived(rcv.aLong, true)
                                        _G.HTPS_AUTO.sessionDone = (_G.HTPS_AUTO.sessionDone or 0) + 1
                                        _G.HTPS_AUTO.totalDone = (_G.HTPS_AUTO.totalDone or 0) + 1
                                        if _G.HTPS_AUTO.remain > 0 then
                                            _G.HTPS_AUTO.remain = _G.HTPS_AUTO.remain - 1
                                        end
                                    end
                                elseif a.actionId == 1 and a.data then
                                    local rcv = _G.HTPS_DeserializeProto(a.data, "pbdson.CommonVector,PbMethodLib")
                                    if rcv and rcv.aString and rcv.aString.Count > 0 then
                                        serverErr = tostring(rcv.aString[0])
                                    end
                                end
                            end
                        end
                    end)
                end

                _G.HTPS_KillSummonPopups()
                if serverErr then
                    _G.HTPS_AUTO.running = false
                    _G.HTPS_AUTO.suppressUntil = UG.Time.realtimeSinceStartup + 0.3
                    pcall(function() CS.Toast.ShowToast(serverErr) end)
                    break
                end

                if not _G.HTPS_AUTO.running or _G.HTPS_AUTO.sessionId ~= mySessionId then
                    break
                end

                if (_G.HTPS_AUTO.delay or 0) > 0 and _G.HTPS_AUTO.modeTag ~= "TURBO" then
                    coroutine.yield(UG.WaitForSeconds(_G.HTPS_AUTO.delay))
                else
                    coroutine.yield(nil)
                end
            end
        end)
    end

    _G.HTPS_StopSummon = function()
        _G.HTPS_AUTO.sessionId = (_G.HTPS_AUTO.sessionId or 0) + 1
        _G.HTPS_AUTO.running = false
        _G.HTPS_AUTO.remain = 0
        _G.HTPS_AUTO.suppressUntil = UG.Time.realtimeSinceStartup + 0.3
        pcall(function()
            local nc = CS.NetworkController.GetInstance()
            if nc then
                local fSend = typeof(CS.NetworkController):GetField("m_LstQueuedSendAction", REF_FLAGS)
                local fRecv = typeof(CS.NetworkController):GetField("m_LstQueuedReceiveAction", REF_FLAGS)
                if fSend then
                    local lstS = fSend:GetValue(nc)
                    if lstS then
                        for i = lstS.Count - 1, 0, -1 do
                            if lstS[i] and lstS[i].actionId == 212 then lstS:RemoveAt(i) end
                        end
                    end
                end
                if fRecv then
                    local lstR = fRecv:GetValue(nc)
                    if lstR then
                        for i = lstR.Count - 1, 0, -1 do
                            if lstR[i] and lstR[i].actionId == 212 then lstR:RemoveAt(i) end
                        end
                    end
                end
            end
        end)
        _G.HTPS_KillSummonPopups()
    end

    -- =================================================================
    -- SPECIAL EQUIP UPGRADE (VAI TRÒ / NHÓM HẠNG MAX 300 & PHẨM ĐỒ 15 SAO)
    -- =================================================================
    _G.HTPS_UPGRADE_RUNNING = _G.HTPS_UPGRADE_RUNNING or false
    _G.HTPS_UPGRADE_STATUS = _G.HTPS_UPGRADE_STATUS or "IDLE"
    _G.HTPS_UPGRADE_PROGRESS = _G.HTPS_UPGRADE_PROGRESS or 0
    _G.HTPS_UPGRADE_TARGET = _G.HTPS_UPGRADE_TARGET or 300
    _G.HTPS_UPGRADE_HERO_NAME = _G.HTPS_UPGRADE_HERO_NAME or ""
    _G.HTPS_UPGRADE_TAB_NAME = _G.HTPS_UPGRADE_TAB_NAME or ""

    local function getActiveHeroAndPopup()
        local popGo = GO.Find("PopupSpecialEquipUpgrade(Clone)")
        local pop = nil
        local heroModel = nil
        local tabRankRole = 0
        local tabInfo = 1

        if popGo and popGo.activeInHierarchy then
            pop = popGo:GetComponent(typeof(CS.PopupSpecialEquipUpgrade))
            if pop then
                local pt = typeof(CS.PopupSpecialEquipUpgrade)
                heroModel = pt:GetField("model", REF_FLAGS):GetValue(pop)
                tabRankRole = pt:GetField("currentTabRankRole", REF_FLAGS):GetValue(pop) or 0
                tabInfo = pt:GetField("currentTabInfo", REF_FLAGS):GetValue(pop) or 1
            end
        end

        if not heroModel then
            local hiGo = GO.Find("PanelHeroInfo(Clone)")
            if hiGo and hiGo.activeInHierarchy then
                local hi = hiGo:GetComponent(typeof(CS.PanelHeroInfo))
                if hi then
                    local hit = typeof(CS.PanelHeroInfo)
                    heroModel = hit:GetField("currentHeroModel", REF_FLAGS):GetValue(hi)
                end
            end
        end

        return heroModel, pop, tabRankRole, tabInfo
    end

    _G.HTPS_GetSpecialEquipState = function()
        local h, pop, tabRR, tabInfo = getActiveHeroAndPopup()
        if not h then
            return "NO_HERO"
        end
        local eq = h.epicEquipment
        local atkLv = eq and eq.attackLevel or 0
        local hpLv = eq and eq.hpLevel or 0
        local atkTier = eq and eq.attackTier or 0
        local hpTier = eq and eq.hpTier or 0
        return string.format("HERO|%d|%s|%d|%d|%d|%d|%d|%d|%s|%d/%d|%s",
            h.m_HeroId, tostring(h.m_HeroName), tabRR, tabInfo,
            atkLv, hpLv, atkTier, hpTier,
            tostring(_G.HTPS_UPGRADE_STATUS), _G.HTPS_UPGRADE_PROGRESS, _G.HTPS_UPGRADE_TARGET,
            tostring(_G.HTPS_UPGRADE_TAB_NAME))
    end

    _G.HTPS_StopUpgradeSpecialEquip = function()
        _G.HTPS_UPGRADE_RUNNING = false
        _G.HTPS_UPGRADE_STATUS = "STOPPED"
        return "STOPPED"
    end

    _G.HTPS_StartUpgradeSpecialEquip = function(mode, delaySec)
        if _G.HTPS_UPGRADE_RUNNING then
            return "ALREADY_RUNNING"
        end
        local h, pop, curTabRR, curTabInfo = getActiveHeroAndPopup()
        if not h then
            return "ERR_NO_HERO"
        end

        delaySec = tonumber(delaySec) or 0

        local tasks = {}
        if mode == "CURRENT" then
            local label = (curTabRR == 0) and "Vai trò (Công)" or "Nhóm hạng (Máu)"
            table.insert(tasks, { tabRR = curTabRR, isStar = false, maxVal = 300, label = label })
        elseif mode == "ROLE" or mode == "ATK" then
            table.insert(tasks, { tabRR = 0, isStar = false, maxVal = 300, label = "Vai trò (Công)" })
        elseif mode == "RANK" or mode == "HP" then
            table.insert(tasks, { tabRR = 1, isStar = false, maxVal = 300, label = "Nhóm hạng (Máu)" })
        elseif mode == "BOTH" then
            table.insert(tasks, { tabRR = 0, isStar = false, maxVal = 300, label = "Vai trò (Công)" })
            table.insert(tasks, { tabRR = 1, isStar = false, maxVal = 300, label = "Nhóm hạng (Máu)" })
        elseif mode == "STAR_CURRENT" then
            local label = (curTabRR == 0) and "Phẩm đồ Vai trò" or "Phẩm đồ Nhóm hạng"
            table.insert(tasks, { tabRR = curTabRR, isStar = true, maxVal = 15, label = label })
        elseif mode == "FULL_ALL" then
            table.insert(tasks, { tabRR = 0, isStar = false, maxVal = 300, label = "Vai trò (Công)" })
            table.insert(tasks, { tabRR = 1, isStar = false, maxVal = 300, label = "Nhóm hạng (Máu)" })
            table.insert(tasks, { tabRR = 0, isStar = true, maxVal = 15, label = "Phẩm đồ Vai trò" })
            table.insert(tasks, { tabRR = 1, isStar = true, maxVal = 15, label = "Phẩm đồ Nhóm hạng" })
        else
            local label = (curTabRR == 0) and "Vai trò (Công)" or "Nhóm hạng (Máu)"
            table.insert(tasks, { tabRR = curTabRR, isStar = false, maxVal = 300, label = label })
        end

        _G.HTPS_UPGRADE_RUNNING = true
        _G.HTPS_UPGRADE_STATUS = "RUNNING"
        _G.HTPS_UPGRADE_HERO_NAME = tostring(h.m_HeroName)

        CsCoroutine.start(function()
            local ds = CS.GameContext.GetIntance().dataSender
            local heroId = h.m_HeroId

            local popGo = GO.Find("PopupSpecialEquipUpgrade(Clone)")
            if not popGo or not popGo.activeInHierarchy then
                pcall(function() CS.PopupSpecialEquipUpgrade.ShowUp(h, tasks[1].tabRR, nil) end)
                coroutine.yield(UG.WaitForSeconds(0.35))
            end

            if h.epicEquipment and h.epicEquipment.isLock then
                pcall(function() ds:RequestUpgradeHeroSpecialFistUnlock(heroId) end)
                coroutine.yield(UG.WaitForSeconds(0.3))
            end

            for _, task in ipairs(tasks) do
                if not _G.HTPS_UPGRADE_RUNNING then break end
                local tabRR = task.tabRR
                local isStar = task.isStar
                local maxVal = task.maxVal
                _G.HTPS_UPGRADE_TAB_NAME = task.label
                _G.HTPS_UPGRADE_TARGET = maxVal

                local function getCurVal()
                    local eq = h.epicEquipment
                    if not eq then return 0 end
                    if isStar then
                        return (tabRR == 0) and eq.attackTier or eq.hpTier
                    else
                        return (tabRR == 0) and eq.attackLevel or eq.hpLevel
                    end
                end

                popGo = GO.Find("PopupSpecialEquipUpgrade(Clone)")
                if popGo and popGo.activeInHierarchy then
                    local p = popGo:GetComponent(typeof(CS.PopupSpecialEquipUpgrade))
                    if p then
                        pcall(function()
                            p:OnTabActive(1, tabRR)
                            p:OnTabActive(2, isStar and 2 or 1)
                        end)
                    end
                end

                local curVal = getCurVal()
                _G.HTPS_UPGRADE_PROGRESS = curVal

                local retriesWithoutProgress = 0
                local inFlight = 0
                local lastSendTime = UG.Time.realtimeSinceStartup

                while _G.HTPS_UPGRADE_RUNNING and curVal < maxVal do
                    local newVal = getCurVal()
                    if newVal > curVal then
                        curVal = newVal
                        _G.HTPS_UPGRADE_PROGRESS = curVal
                        inFlight = 0
                        retriesWithoutProgress = 0
                        if curVal >= maxVal then break end
                    end

                    local now = UG.Time.realtimeSinceStartup
                    if inFlight > 0 and (now - lastSendTime > 0.45) then
                        inFlight = 0
                        retriesWithoutProgress = retriesWithoutProgress + 1
                    end

                    if retriesWithoutProgress >= 6 then
                        _G.HTPS_UPGRADE_STATUS = "OUT_OF_MATERIAL_AT_" .. tostring(curVal)
                        _G.HTPS_UPGRADE_RUNNING = false
                        break
                    end

                    if inFlight == 0 and curVal < maxVal then
                        local ok = pcall(function()
                            if isStar then
                                ds:RequestUpgradeHeroSpecialUpgrade(heroId, tabRR)
                            else
                                ds:RequestUpgradeHeroSpecialEnhance(heroId, tabRR)
                            end
                        end)
                        if ok then
                            inFlight = 1
                            lastSendTime = now
                        end
                    end

                    if delaySec > 0 then
                        coroutine.yield(UG.WaitForSeconds(delaySec))
                    else
                        coroutine.yield(nil)
                    end
                end
            end

            if _G.HTPS_UPGRADE_RUNNING then
                _G.HTPS_UPGRADE_STATUS = "DONE"
                _G.HTPS_UPGRADE_RUNNING = false
                pcall(function() CS.Toast.ShowToast("Đã nâng Max cấp thành công!") end)
            end
        end)

        return "STARTED|" .. tostring(h.m_HeroName) .. "|" .. tostring(#tasks)
    end

    -- =================================================================
    -- IN-GAME UI BUTTONS: SPECIAL EQUIP & ORB SUMMON X10
    -- =================================================================
    _G.HTPS_EnsureSpecialEquipButtons = function()
        pcall(function()
            local popGo = GO.Find("PopupSpecialEquipUpgrade(Clone)")
            if not popGo or not popGo.activeInHierarchy then return end

            local ps = popGo.transform:Find("Body/GroupRight/Bgr/PanelStrengthen")
            if ps then
                local btnOrig = ps:Find("ButtonUpgrade")
                local btnAuto = ps:Find("BtnAutoMax300")
                if btnOrig and not btnAuto then
                    btnOrig:GetComponent(typeof(UG.RectTransform)).anchoredPosition = UG.Vector2(-115, -194.3)
                    local cloneGo = GO.Instantiate(btnOrig.gameObject, ps, false)
                    cloneGo.name = "BtnAutoMax300"
                    cloneGo:GetComponent(typeof(UG.RectTransform)).anchoredPosition = UG.Vector2(115, -194.3)
                    local btnComp = cloneGo:GetComponent(typeof(UG.UI.Button))
                    btnComp.onClick = UG.UI.Button.ButtonClickedEvent()
                    btnComp.onClick:AddListener(function()
                        if _G.HTPS_UPGRADE_RUNNING then
                            _G.HTPS_StopUpgradeSpecialEquip()
                        else
                            _G.HTPS_StartUpgradeSpecialEquip("CURRENT", 0)
                        end
                    end)
                    btnAuto = cloneGo.transform
                end
                if btnAuto and btnOrig then
                    btnAuto.gameObject:SetActive(btnOrig.gameObject.activeSelf or _G.HTPS_UPGRADE_RUNNING)
                    local txt = btnAuto:GetComponentInChildren(typeof(UG.UI.Text), true)
                    if txt then
                        if _G.HTPS_UPGRADE_RUNNING then
                            txt.text = "Dừng (" .. tostring(_G.HTPS_UPGRADE_PROGRESS) .. "/" .. tostring(_G.HTPS_UPGRADE_TARGET) .. ")"
                        else
                            txt.text = "Auto Max 300"
                        end
                    end
                end
            end

            local pc = popGo.transform:Find("Body/GroupRight/Bgr/PanelCoordination")
            if pc then
                local btnOrig = pc:Find("ButtonUpgrade")
                local btnAuto = pc:Find("BtnAutoMaxStar")
                if btnOrig and not btnAuto then
                    btnOrig:GetComponent(typeof(UG.RectTransform)).anchoredPosition = UG.Vector2(-115, -194.3)
                    local cloneGo = GO.Instantiate(btnOrig.gameObject, pc, false)
                    cloneGo.name = "BtnAutoMaxStar"
                    cloneGo:GetComponent(typeof(UG.RectTransform)).anchoredPosition = UG.Vector2(115, -194.3)
                    local btnComp = cloneGo:GetComponent(typeof(UG.UI.Button))
                    btnComp.onClick = UG.UI.Button.ButtonClickedEvent()
                    btnComp.onClick:AddListener(function()
                        if _G.HTPS_UPGRADE_RUNNING then
                            _G.HTPS_StopUpgradeSpecialEquip()
                        else
                            _G.HTPS_StartUpgradeSpecialEquip("STAR_CURRENT", 0)
                        end
                    end)
                    btnAuto = cloneGo.transform
                end
                if btnAuto and btnOrig then
                    btnAuto.gameObject:SetActive(btnOrig.gameObject.activeSelf or _G.HTPS_UPGRADE_RUNNING)
                    local txt = btnAuto:GetComponentInChildren(typeof(UG.UI.Text), true)
                    if txt then
                        if _G.HTPS_UPGRADE_RUNNING then
                            txt.text = "Dừng (" .. tostring(_G.HTPS_UPGRADE_PROGRESS) .. "/" .. tostring(_G.HTPS_UPGRADE_TARGET) .. ")"
                        else
                            txt.text = "Auto Max Sao"
                        end
                    end
                end
            end

            local gl = popGo.transform:Find("Body/GroupLeft")
            local btnOrigRef = ps and ps:Find("ButtonUpgrade")
            if gl and btnOrigRef then
                local btnReset = gl:Find("BtnPopupResetLv1")
                if not btnReset then
                    local cloneGo = GO.Instantiate(btnOrigRef.gameObject, gl, false)
                    cloneGo.name = "BtnPopupResetLv1"
                    local rt = cloneGo:GetComponent(typeof(UG.RectTransform))
                    if rt then
                        rt.anchoredPosition = UG.Vector2(0, -215)
                        rt.sizeDelta = UG.Vector2(180, 48)
                    end
                    local btnComp = cloneGo:GetComponent(typeof(UG.UI.Button))
                    btnComp.onClick = UG.UI.Button.ButtonClickedEvent()
                    btnComp.onClick:AddListener(function()
                        if _G.HTPS_RunResetSpecialEquip then
                            _G.HTPS_RunResetSpecialEquip()
                        end
                    end)
                    btnReset = cloneGo.transform
                end
                if btnReset then
                    btnReset.gameObject:SetActive(true)
                    local txt = btnReset:GetComponentInChildren(typeof(UG.UI.Text), true)
                    if txt then
                        local loc = txt.gameObject:GetComponent(typeof(CS.I2.Loc.Localize))
                        if loc then UG.Object.DestroyImmediate(loc) end
                        txt.text = "Hoàn Trả Lv1"
                    end
                end
            end
        end)
    end

    local function createOrbBtn(parentTf, btnOrig, name, posX, posY, onClickFn)
        local cloneGo = GO.Instantiate(btnOrig.gameObject, parentTf, false)
        cloneGo.name = name
        local buttonRect = cloneGo:GetComponent(typeof(UG.RectTransform))
        buttonRect.anchoredPosition = UG.Vector2(posX, posY)
        buttonRect.sizeDelta = UG.Vector2(buttonRect.sizeDelta.x, 36)
        local iconOrb = cloneGo.transform:Find("IconOrb")
        if iconOrb then iconOrb.gameObject:SetActive(false) end
        local txtTf = cloneGo.transform:Find("Text")
        if txtTf then
            local rt = txtTf:GetComponent(typeof(UG.RectTransform))
            rt.anchoredPosition = UG.Vector2(0, 0)
            rt.sizeDelta = UG.Vector2(190, 36)
            local txt = txtTf:GetComponent(typeof(UG.UI.Text))
            txt.alignment = UG.TextAnchor.MiddleCenter
        end
        local btnComp = cloneGo:GetComponent(typeof(UG.UI.Button))
        btnComp.onClick = UG.UI.Button.ButtonClickedEvent()
        btnComp.onClick:AddListener(onClickFn)
        return cloneGo.transform
    end

    _G.HTPS_EnsureSummonOrbButtons = function()
        pcall(function()
            local box = _G.HTPS_FindObjectOfType(typeof(CS.BoxOrbSummon))
            if not box or not box.gameObject.activeInHierarchy then return end

            local p = box.transform
            local b10 = p:Find("ButtonSummon10")
            if not b10 then return end

            local b50 = p:Find("BtnAutoOrb50x10")
            if not b50 then
                b50 = createOrbBtn(p, b10, "BtnAutoOrb50x10", -225, -294, function()
                    if _G.HTPS_AUTO.running and _G.HTPS_AUTO.modeTag == "50X10" then
                        _G.HTPS_StopSummon()
                    else
                        _G.HTPS_StopSummon()
                        _G.HTPS_StartSummon("CURRENT", 50, 0.03, 1, "50X10")
                    end
                end)
            else
                -- Rebind click listener in case script was hot-patched
                if not _G.HTPS_ORB_BTNS_BOUND then
                    local bc = b50:GetComponent(typeof(UG.UI.Button))
                    bc.onClick = UG.UI.Button.ButtonClickedEvent()
                    bc.onClick:AddListener(function()
                        if _G.HTPS_AUTO.running and _G.HTPS_AUTO.modeTag == "50X10" then
                            _G.HTPS_StopSummon()
                        else
                            _G.HTPS_StopSummon()
                            _G.HTPS_StartSummon("CURRENT", 50, 0.03, 1, "50X10")
                        end
                    end)
                end
            end

            local bFast = p:Find("BtnAutoOrbFast")
            if not bFast then
                bFast = createOrbBtn(p, b10, "BtnAutoOrbFast", 0, -294, function()
                    if _G.HTPS_AUTO.running and _G.HTPS_AUTO.modeTag == "FAST" then
                        _G.HTPS_StopSummon()
                    else
                        _G.HTPS_StopSummon()
                        _G.HTPS_StartSummon("CURRENT", -1, 0.06, 1, "FAST")
                    end
                end)
            else
                if not _G.HTPS_ORB_BTNS_BOUND then
                    local bc = bFast:GetComponent(typeof(UG.UI.Button))
                    bc.onClick = UG.UI.Button.ButtonClickedEvent()
                    bc.onClick:AddListener(function()
                        if _G.HTPS_AUTO.running and _G.HTPS_AUTO.modeTag == "FAST" then
                            _G.HTPS_StopSummon()
                        else
                            _G.HTPS_StopSummon()
                            _G.HTPS_StartSummon("CURRENT", -1, 0.06, 1, "FAST")
                        end
                    end)
                end
            end

            local bTurbo = p:Find("BtnAutoOrbTurbo")
            if not bTurbo then
                bTurbo = createOrbBtn(p, b10, "BtnAutoOrbTurbo", 225, -294, function()
                    if _G.HTPS_AUTO.running and _G.HTPS_AUTO.modeTag == "TURBO" then
                        _G.HTPS_StopSummon()
                    else
                        _G.HTPS_StopSummon()
                        _G.HTPS_StartSummon("CURRENT", -1, 0.025, 1, "TURBO")
                    end
                end)
            else
                if not _G.HTPS_ORB_BTNS_BOUND then
                    local bc = bTurbo:GetComponent(typeof(UG.UI.Button))
                    bc.onClick = UG.UI.Button.ButtonClickedEvent()
                    bc.onClick:AddListener(function()
                        if _G.HTPS_AUTO.running and _G.HTPS_AUTO.modeTag == "TURBO" then
                            _G.HTPS_StopSummon()
                        else
                            _G.HTPS_StopSummon()
                            _G.HTPS_StartSummon("CURRENT", -1, 0.025, 1, "TURBO")
                        end
                    end)
                end
            end
            _G.HTPS_ORB_BTNS_BOUND = true

            local done = _G.HTPS_AUTO.sessionDone or 0
            local running = _G.HTPS_AUTO.running
            local tag = _G.HTPS_AUTO.modeTag

            if b50 then
                local t50 = b50:Find("Text"):GetComponent(typeof(UG.UI.Text))
                if running and tag == "50X10" then
                    t50.text = "Dừng (" .. tostring(done) .. "/50)"
                else
                    t50.text = "Xả Nhanh 50x10"
                end
            end
            if bFast then
                local tFast = bFast:Find("Text"):GetComponent(typeof(UG.UI.Text))
                if running and tag == "FAST" then
                    tFast.text = "Dừng Xả (" .. tostring(done) .. "x10)"
                else
                    tFast.text = "Auto Xả Nhanh"
                end
            end
            if bTurbo then
                local tTurbo = bTurbo:Find("Text"):GetComponent(typeof(UG.UI.Text))
                if running and tag == "TURBO" then
                    tTurbo.text = "Dừng Turbo (" .. tostring(done) .. "x10)"
                else
                    tTurbo.text = "Auto Siêu Tốc"
                end
            end
        end)
    end


    -- =================================================================
    -- GERMA / ẤN HƯ KHÔNG (PANEL EP SAO) AUTO MAX + TỰ CHỌN LÍNH CHÌ 10★
    -- =================================================================
    _G.HTPS_EPSAO_RUNNING = _G.HTPS_EPSAO_RUNNING or false
    _G.HTPS_EPSAO_PROGRESS_STR = _G.HTPS_EPSAO_PROGRESS_STR or ""

    _G.HTPS_EnsureEpSaoHook = function()
        if not _G.PanelEpSao or not _G.PanelEpSao.processKEvent then return false end
        if _G.PanelEpSao.processKEvent ~= _G.HTPS_HOOKED_PES_PROCESS then
            _G.HTPS_ORIG_PES_PROCESS = _G.PanelEpSao.processKEvent
            _G.HTPS_HOOKED_PES_PROCESS = function(self, serviceId, bytesData)
                if _G.HTPS_EPSAO_RUNNING and (serviceId == DataSender.UPGRADE_VOID_LEVEL or serviceId == DataSender.UPGRADE_VOID_SKILL) then
                    local _, lstLevelData = debug.getupvalue(_G.HTPS_ORIG_PES_PROCESS, 2)
                    local _, m_HeroInfo = debug.getupvalue(_G.HTPS_ORIG_PES_PROCESS, 3)
                    local _, curIdx = debug.getupvalue(_G.HTPS_ORIG_PES_PROCESS, 4)
                    local _, idxActive = debug.getupvalue(_G.HTPS_ORIG_PES_PROCESS, 5)

                    local cv = NetworkController:instance():deserializeProto(bytesData, DataSender.CommonVector)
                    local lstLong = cv.aLong
                    local newLevel = lstLong[0]
                    lstLong:RemoveAt(0)
                    pcall(function() CS.BonusModel.ParseBonusReceived(lstLong) end)

                    if serviceId == DataSender.UPGRADE_VOID_SKILL then
                        pcall(function()
                            local _, sIdx = debug.getupvalue(PopupSkillVoid.showBonusItemOnUpSkill, 2)
                            local voidData = PanelEpSaoData:instance()
                            local costItemBonus = voidData.lstCostItemBonus:getAt(sIdx or 1)
                            local lstLongItemBonus = ParseArrayTableToListLong(costItemBonus)
                            CS.BonusModel.ParseBonusReceived(lstLongItemBonus)
                        end)
                        pcall(function() PopupSkillVoid:RemoveHeroFromInventory() end)
                    end

                    if lstLevelData and curIdx ~= nil then
                        lstLevelData[curIdx] = newLevel
                        lstLevelData = SetNewListLevelDataActive(lstLevelData)
                        debug.setupvalue(_G.HTPS_ORIG_PES_PROCESS, 2, lstLevelData)
                        SetVoidStatus(lstLevelData, idxActive)
                        if serviceId == DataSender.UPGRADE_VOID_SKILL then
                            pcall(function()
                                if _G.HTPS_LAST_VOID_PUPPETS then
                                    local lstAllHero = CS.PlayerInventory.GetInstance():GetListHeroModel()
                                    for pIdx = 0, _G.HTPS_LAST_VOID_PUPPETS.Count - 1 do
                                        local pid = _G.HTPS_LAST_VOID_PUPPETS[pIdx]
                                        for j = lstAllHero.Count - 1, 0, -1 do
                                            if lstAllHero[j] and lstAllHero[j].m_HeroId == pid then
                                                lstAllHero:RemoveAt(j)
                                                break
                                            end
                                        end
                                    end
                                end
                            end)
                            pcall(function() ReLoadIconSkill(lstLevelData) end)
                        end
                    end
                    return
                end
                return _G.HTPS_ORIG_PES_PROCESS(self, serviceId, bytesData)
            end
            _G.PanelEpSao.processKEvent = _G.HTPS_HOOKED_PES_PROCESS
        end
        return true
    end

    local function getPuppetHeroes10Star(neededCount, excludeHeroId, usedPuppetIds)
        local lstOut = CS.LuaLibrary.CreateNewListLong()
        local lstAll = CS.PlayerInventory.GetInstance():GetListHeroModel()
        for i = 0, lstAll.Count - 1 do
            local h = lstAll[i]
            if h and h.m_HeroId ~= excludeHeroId and not (usedPuppetIds and usedPuppetIds[h.m_HeroId])
                and tonumber(h.m_Star) == 10 and not h:IsHeroLock() and not h.m_LockedInList then
                local hk = tonumber(h.m_HeroKey) or 0
                if CS.HeroModel.IsPuppetHero(hk) or (hk >= 322 and hk <= 327) then
                    lstOut:Add(h.m_HeroId)
                    if lstOut.Count >= neededCount then
                        break
                    end
                end
            end
        end
        return lstOut
    end

    local function openMissingPuppet10Star(deficit)
        if deficit <= 0 then return true end
        local inv = CS.PlayerInventory.GetInstance()
        local gc = CS.GameContext.GetIntance()
        local csNet = CS.NetworkController.GetInstance()
        if not inv or not gc or not csNet then return false end

        local batchOpen = {}
        local remain = deficit

        for pk = 322, 327 do
            if remain <= 0 then break end
            local sh = inv:GetShard(pk)
            if sh and tonumber(sh.m_Number) and tonumber(sh.m_Number) >= 50 then
                local take = math.min(remain, math.floor(tonumber(sh.m_Number) / 50))
                if take > 0 then
                    table.insert(batchOpen, {itemType = 2, itemKey = sh.m_ItemKey, count = take})
                    remain = remain - take
                end
            end
        end

        if remain > 0 then
            local haveChest = tonumber(inv:GetNumberItemConsumable(2070)) or tonumber(inv:CountItemConsumable(2070)) or 0
            if haveChest > 0 then
                local take = math.min(remain, haveChest)
                if take > 0 then
                    table.insert(batchOpen, {itemType = 1, itemKey = 2070, count = take})
                    remain = remain - take
                end
            end
        end

        if #batchOpen == 0 then
            return false
        end

        local req = CS.pbdson.RequestData()
        req.session = gc.m_Session
        for _, item in ipairs(batchOpen) do
            local cv = CS.pbdson.CommonVector()
            cv.aLong:Add(item.itemType)
            cv.aLong:Add(item.itemKey)
            cv.aLong:Add(item.count)
            local act = CS.pbdson.PbAction()
            act.actionId = 254
            act.data = _G.HTPS_SerializeProto(cv)
            req.actions:Add(act)
        end

        local url = csNet.m_UrlGameServer .. "/i/254/" .. tostring(gc.m_UserId)
        local data, ok = _G.HTPS_PutWebRequest(url, _G.HTPS_SerializeProto(req), 8)
        if ok and data then
            local resp = _G.HTPS_DeserializeProto(data, "pbdson.ResponseData,PbMethodLib")
            if resp and resp.aAction then
                for idx = 0, resp.aAction.Count - 1 do
                    local a = resp.aAction[idx]
                    if a.actionId == 254 and a.data then
                        local rcv = _G.HTPS_DeserializeProto(a.data, "pbdson.CommonVector,PbMethodLib")
                        if rcv and rcv.aLong then
                            pcall(function() CS.BonusModel.ParseBonusReceived(rcv.aLong, true) end)
                        end
                    end
                end
                return true
            end
        end
        return false
    end

    _G.HTPS_StopUpgradeEpSao = function()
        _G.HTPS_EPSAO_RUNNING = false
        _G.HTPS_EPSAO_PROGRESS_STR = ""
        return "STOPPED"
    end

    _G.HTPS_StartUpgradeEpSao = function()
        if _G.HTPS_EPSAO_RUNNING then return "ALREADY_RUNNING" end
        local epGo = GO.Find("PanelHeroInfo(Clone)/RightPart/BoxInfo/PanelEnable/PanelEpSao(Clone)")
        if not epGo or not epGo.activeInHierarchy then
            return "NO_PANEL_EPSAO"
        end
        if not _G.HTPS_EnsureEpSaoHook() then
            return "NO_HOOK"
        end

        local _, lstLevelData = debug.getupvalue(_G.HTPS_ORIG_PES_PROCESS, 2)
        local _, m_HeroInfo = debug.getupvalue(_G.HTPS_ORIG_PES_PROCESS, 3)
        if not lstLevelData or not m_HeroInfo then
            return "NO_DATA"
        end

        _G.HTPS_EPSAO_RUNNING = true
        _G.HTPS_EPSAO_PROGRESS_STR = "Đang nâng..."

        CsCoroutine.start(function()
            local heroId = m_HeroInfo.m_HeroId
            local voidData = PanelEpSaoData:instance()
            local ds = DataSender:instance()
            local nc = NetworkController:instance()
            local inv = CS.PlayerInventory.GetInstance()
            local itemKeyUpLevel = 200019
            local usedPuppetIds = {}

            for i = 0, 15 do
                if not _G.HTPS_EPSAO_RUNNING then break end
                local _, curHero = debug.getupvalue(_G.HTPS_ORIG_PES_PROCESS, 3)
                if not curHero or curHero.m_HeroId ~= heroId then
                    _G.HTPS_EPSAO_RUNNING = false
                    break
                end

                _, lstLevelData = debug.getupvalue(_G.HTPS_ORIG_PES_PROCESS, 2)
                local curLv = lstLevelData[i]
                if curLv < 0 then
                    lstLevelData[i] = 0
                    curLv = 0
                end

                local isSkill = (i == 3 or i == 7 or i == 11 or i == 15)
                if not isSkill then
                    local voidIdx
                    if i < 3 then voidIdx = i + 1
                    elseif i < 7 then voidIdx = i
                    elseif i < 11 then voidIdx = i - 1
                    else voidIdx = i - 2 end

                    local levelData = voidData.lstVoid:getAt(voidIdx)
                    local maxLv = levelData.lstCostVoid:count()

                    if curLv < maxLv then
                        _G.HTPS_EPSAO_PROGRESS_STR = string.format("Ô %d/16 (%d/%d)", i + 1, curLv, maxLv)
                        local availCrystal = inv:GetNumberItemConsumable(itemKeyUpLevel)
                        local canSend = 0
                        for lv = curLv + 1, maxLv do
                            local cost = levelData.lstCostVoid:getAt(lv)
                            if availCrystal >= cost then
                                availCrystal = availCrystal - cost
                                canSend = canSend + 1
                            else
                                break
                            end
                        end

                        if canSend <= 0 then
                            pcall(function() CS.Toast.ShowToast("Không đủ Đá Hư Không!") end)
                            _G.HTPS_EPSAO_RUNNING = false
                            break
                        end

                        local targetLv = curLv + canSend
                        debug.setupvalue(_G.HTPS_ORIG_PES_PROCESS, 4, i)
                        for k = 1, canSend do
                            ds:requestUpgradeVoidLevel(heroId, voidIdx - 1)
                        end

                        local t0 = UG.Time.realtimeSinceStartup
                        while _G.HTPS_EPSAO_RUNNING and (UG.Time.realtimeSinceStartup - t0 < 4.5) do
                            while nc.listPbActionReceivedQueue:count() > 0 do
                                nc:processPbActionReceivedQueue()
                            end
                            _, lstLevelData = debug.getupvalue(_G.HTPS_ORIG_PES_PROCESS, 2)
                            if lstLevelData[i] >= targetLv then
                                break
                            end
                            _G.HTPS_EPSAO_PROGRESS_STR = string.format("Ô %d/16 (%d/%d)", i + 1, lstLevelData[i], maxLv)
                            coroutine.yield(nil)
                        end

                        if lstLevelData[i] < maxLv then
                            _G.HTPS_EPSAO_RUNNING = false
                            break
                        end
                    end
                else
                    local skillIdx = math.floor((i + 1) / 4)
                    if curLv < 1 then
                        _G.HTPS_EPSAO_PROGRESS_STR = string.format("Kỹ năng %d/4...", skillIdx)
                        local lstLongCostItem = ParseArrayTableToListLong(voidData.lstCostItem:getAt(skillIdx))
                        local itemFee = CS.LibEvent.ConvertListLongDataToOneItemConsumable(lstLongCostItem)
                        if itemFee ~= nil and itemFee.m_ItemKey ~= -1 then
                            local haveItem = inv:GetNumberItemConsumable(itemFee.m_ItemKey)
                            if haveItem < itemFee.m_Number then
                                pcall(function() CS.Toast.ShowToast("Không đủ nguyên liệu mở Kỹ năng " .. tostring(skillIdx) .. "!") end)
                                _G.HTPS_EPSAO_RUNNING = false
                                break
                            end
                        end

                        local costHero = voidData.lstCostHero:getAt(skillIdx)
                        local lstPuppets = getPuppetHeroes10Star(costHero, heroId, usedPuppetIds)
                        if lstPuppets.Count < costHero then
                            local deficit = costHero - lstPuppets.Count
                            _G.HTPS_EPSAO_PROGRESS_STR = string.format("Mở %d Lính chì 10★...", deficit)
                            openMissingPuppet10Star(deficit)
                            lstPuppets = getPuppetHeroes10Star(costHero, heroId, usedPuppetIds)
                        end
                        if lstPuppets.Count < costHero then
                            pcall(function()
                                CS.Toast.ShowToast(string.format("Không đủ Lính chì 10★ (%d/%d)!", lstPuppets.Count, costHero))
                            end)
                            _G.HTPS_EPSAO_RUNNING = false
                            break
                        end

                        for pIdx = 0, lstPuppets.Count - 1 do
                            usedPuppetIds[lstPuppets[pIdx]] = true
                        end
                        _G.HTPS_LAST_VOID_PUPPETS = lstPuppets
                        debug.setupvalue(_G.HTPS_ORIG_PES_PROCESS, 4, i)
                        debug.setupvalue(PopupSkillVoid.RemoveHeroFromInventory, 2, lstPuppets)
                        debug.setupvalue(PopupSkillVoid.showBonusItemOnUpSkill, 2, skillIdx)
                        ds:requestUpgradeVoidSkill(heroId, skillIdx - 1, lstPuppets)

                        local t0 = UG.Time.realtimeSinceStartup
                        while _G.HTPS_EPSAO_RUNNING and (UG.Time.realtimeSinceStartup - t0 < 4.5) do
                            while nc.listPbActionReceivedQueue:count() > 0 do
                                nc:processPbActionReceivedQueue()
                            end
                            _, lstLevelData = debug.getupvalue(_G.HTPS_ORIG_PES_PROCESS, 2)
                            if lstLevelData[i] >= 1 then
                                break
                            end
                            coroutine.yield(nil)
                        end

                        if lstLevelData[i] < 1 then
                            _G.HTPS_EPSAO_RUNNING = false
                            break
                        end
                    end
                end
            end

            pcall(function()
                CS.GameContext.GetIntance().dataSender:HeroRequestInfo(heroId)
            end)

            if _G.HTPS_EPSAO_RUNNING then
                _G.HTPS_EPSAO_RUNNING = false
                _G.HTPS_EPSAO_PROGRESS_STR = ""
                pcall(function() CS.Toast.ShowToast("Đã nâng Max Ấn & Kỹ năng thành công!") end)
            end
        end)

        return "STARTED_EPSAO"
    end

    _G.HTPS_EnsureEpSaoButtons = function()
        pcall(function()
            local cnt = GO.Find("PanelHeroInfo(Clone)/RightPart/BoxInfo/PanelEnable/PanelEpSao(Clone)/Bgr/Content")
            if not cnt or not cnt.activeInHierarchy then return end
            _G.HTPS_EnsureEpSaoHook()

            local btnTf = cnt.transform:Find("BtnAutoMaxEpSao")
            if not btnTf then
                local hiGo = GO.Find("PanelHeroInfo(Clone)")
                if not hiGo then return end
                local btns = hiGo:GetComponentsInChildren(typeof(UG.UI.Button), true)
                local tmpl = nil
                for i = 0, btns.Length - 1 do
                    if btns[i].name == "ButtonRegress3" or btns[i].name == "ButtonAwake" then
                        tmpl = btns[i].gameObject
                        break
                    end
                end
                if not tmpl then return end

                local cloneGo = GO.Instantiate(tmpl, cnt.transform, false)
                cloneGo.name = "BtnAutoMaxEpSao"
                cloneGo:SetActive(true)
                local rt = cloneGo:GetComponent(typeof(UG.RectTransform))
                rt.anchorMin = UG.Vector2(0.5, 0.5)
                rt.anchorMax = UG.Vector2(0.5, 0.5)
                rt.pivot = UG.Vector2(0.5, 0.5)
                rt.anchoredPosition = UG.Vector2(3, -212)
                rt.sizeDelta = UG.Vector2(180, 50)

                local txt = cloneGo:GetComponentInChildren(typeof(UG.UI.Text), true)
                if txt then
                    local loc = txt.gameObject:GetComponent(typeof(CS.I2.Loc.Localize))
                    if loc then UG.Object.DestroyImmediate(loc) end
                    txt.text = "Auto Max Ấn"
                    txt.fontSize = 19
                end

                local bc = cloneGo:GetComponent(typeof(UG.UI.Button))
                bc.onClick = UG.UI.Button.ButtonClickedEvent()
                bc.onClick:AddListener(function()
                    if _G.HTPS_EPSAO_RUNNING then
                        _G.HTPS_StopUpgradeEpSao()
                    else
                        _G.HTPS_StartUpgradeEpSao()
                    end
                end)
                btnTf = cloneGo.transform
                _G.HTPS_EPSAO_BTN_BOUND = true
            else
                if not _G.HTPS_EPSAO_BTN_BOUND then
                    local bc = btnTf:GetComponent(typeof(UG.UI.Button))
                    bc.onClick = UG.UI.Button.ButtonClickedEvent()
                    bc.onClick:AddListener(function()
                        if _G.HTPS_EPSAO_RUNNING then
                            _G.HTPS_StopUpgradeEpSao()
                        else
                            _G.HTPS_StartUpgradeEpSao()
                        end
                    end)
                    _G.HTPS_EPSAO_BTN_BOUND = true
                end
            end

            if btnTf then
                local txt = btnTf:GetComponentInChildren(typeof(UG.UI.Text), true)
                if txt then
                    if _G.HTPS_EPSAO_RUNNING then
                        txt.text = "Dừng (" .. tostring(_G.HTPS_EPSAO_PROGRESS_STR) .. ")"
                    else
                        txt.text = "Auto Max Ấn"
                    end
                end
            end
        end)
    end

    local origEnsureSpecial = _G.HTPS_EnsureSpecialEquipButtons
    _G.HTPS_EnsureSpecialEquipButtons = function()
        if origEnsureSpecial then origEnsureSpecial() end
        if _G.HTPS_EnsureEpSaoButtons then _G.HTPS_EnsureEpSaoButtons() end
    end


    -- =================================================================
    
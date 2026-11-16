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
-- TÍNH NĂNG: Phó Bản Địa Ngục (DungeonScene Action 504+505), Tự Bơm Máu Khi HP < 70%, Gom 5 Ải/Gói
-- TRÍCH XUẤT TỪ NGUYENVINHMOD.DLL BẰNG REA ENGINE
-- =====================================================================

-- ==================== AUTO PHÓ BẢN ĐỊA NGỤC / THÁM HIỂM (DUNGEON SCENE - TỰ BƠM MÁU, TỰ QUA THƯƠNG NHÂN, GOM 5 ẢI/LẦN) ====================
    _G.HTPS_DUNGEON_RUNNING = false

    _G.HTPS_UpdateDungeonBtnUI = function(stageNum)
        pcall(function()
            if _G.HTPS_BTN_DUNGEON_TXT and not _G.HTPS_BTN_DUNGEON_TXT:Equals(nil) then
                if _G.HTPS_DUNGEON_RUNNING then
                    if stageNum then
                        _G.HTPS_BTN_DUNGEON_TXT.text = string.format("Đang Cày Ải %d [Dừng]", stageNum)
                    else
                        _G.HTPS_BTN_DUNGEON_TXT.text = "Đang Cày... [Dừng]"
                    end
                else
                    _G.HTPS_BTN_DUNGEON_TXT.text = "Auto Phó Bản"
                end
                _G.HTPS_BTN_DUNGEON_TXT.color = UG.Color(0.42, 0.27, 0.14, 1)
            end
        end)
    end

    _G.HTPS_StopAutoDungeon = function()
        _G.HTPS_DUNGEON_RUNNING = false
        _G.HTPS_UpdateDungeonBtnUI()
        return "STOPPED"
    end

    _G.HTPS_ToggleAutoDungeon = function()
        if _G.HTPS_DUNGEON_RUNNING then
            _G.HTPS_DUNGEON_RUNNING = false
            _G.HTPS_UpdateDungeonBtnUI()
            CS.Toast.ShowToast("Đã dừng Auto Phó Bản!")
            return
        end

        local ds = _G.HTPS_FindObjectOfType(typeof(CS.DungeonScene))
        if not ds or ds:Equals(nil) or not ds.gameObject.activeInHierarchy then
            CS.Toast.ShowToast("Hãy mở màn hình Phó Bản trước!")
            return
        end

        _G.HTPS_DUNGEON_RUNNING = true
        _G.HTPS_BONUS_SUPPRESS_UNTIL = 0
        if _G.HTPS_AUTO then _G.HTPS_AUTO.suppressPopup = true end
        _G.HTPS_UpdateDungeonBtnUI()
        CS.Toast.ShowToast("Bắt đầu Auto Phó Bản Siêu Tốc (Tự bơm máu + Tự qua Thương nhân + Không vào trận)!")

        CsCoroutine.start(function()
            local REF_FLAGS = 60
            local gc = CS.GameContext.GetIntance()
            local nc = CS.NetworkController.GetInstance()

            local function cleanDungeonPopups()
                pcall(function()
                    local cvs = GO.Find("Canvas")
                    if cvs then
                        for i = cvs.transform.childCount - 1, 0, -1 do
                            local c = cvs.transform:GetChild(i).gameObject
                            if string.find(c.name, "PopupBattleEnd") or string.find(c.name, "PopupMessage") or string.find(c.name, "PopupShowBonus") then
                                UG.Object.DestroyImmediate(c)
                            end
                        end
                    end
                end)
            end

            local function parseDungeonStatus(lcv)
                if not lcv or not lcv.aVector or lcv.aVector.Count < 3 then return nil end
                local v0 = lcv.aVector[0].aLong
                local v2 = lcv.aVector[2].aLong
                local v3 = lcv.aVector.Count >= 4 and lcv.aVector[3].aLong or nil
                local stg = (v0 and v0.Count >= 2) and tonumber(v0[1]) or 1
                local heroes = {}
                local aliveCount = 0
                if v2 then
                    local hCnt = math.floor(v2.Count / 4)
                    for h = 0, hCnt - 1 do
                        local hk = tonumber(v2[h * 4 + 0]) or 0
                        local star = tonumber(v2[h * 4 + 1]) or 0
                        local lv = tonumber(v2[h * 4 + 2]) or 0
                        local hp = tonumber(v2[h * 4 + 3]) or 0
                        if hp > 0 then aliveCount = aliveCount + 1 end
                        table.insert(heroes, { slot = h, key = hk, star = star, lv = lv, hp = hp })
                    end
                end
                local pots = { 0, 0, 0 }
                if v3 and v3.Count >= 3 then
                    pots[1] = tonumber(v3[0]) or 0
                    pots[2] = tonumber(v3[1]) or 0
                    pots[3] = tonumber(v3[2]) or 0
                end
                return { stage = stg, heroes = heroes, alive = aliveCount, pots = pots }
            end

            -- Lấy trạng thái Phó Bản ban đầu từ Server (Action 500)
            local state = nil
            local reqInit = CS.pbdson.RequestData()
            reqInit.session = gc.m_Session
            local actInit = CS.pbdson.PbAction()
            actInit.actionId = 500
            reqInit.actions:Add(actInit)
            local dataInit, okInit = _G.HTPS_PutWebRequest(nc.m_UrlGameServer .. "/i/500/" .. tostring(gc.m_UserId), _G.HTPS_SerializeProto(reqInit), 8)
            if okInit and dataInit then
                pcall(function()
                    local resp = _G.HTPS_DeserializeProto(dataInit, "pbdson.ResponseData,PbMethodLib")
                    if resp and resp.aAction then
                        for i = 0, resp.aAction.Count - 1 do
                            local a = resp.aAction[i]
                            if a.actionId == 500 and a.data then
                                local lcv = _G.HTPS_DeserializeProto(a.data, "pbdson.ListCommonVector,PbMethodLib")
                                state = parseDungeonStatus(lcv)
                            end
                        end
                    end
                end)
            end

            if not state or state.alive == 0 then
                _G.HTPS_DUNGEON_RUNNING = false
                _G.HTPS_UpdateDungeonBtnUI()
                CS.Toast.ShowToast("Tất cả tướng trong Phó Bản đã hết máu hoặc chưa chọn tướng!")
                return
            end

            local startStage = state.stage
            local stuckCount = 0
            local rotateOffset = 0

            while _G.HTPS_DUNGEON_RUNNING do
                ds = _G.HTPS_FindObjectOfType(typeof(CS.DungeonScene))
                if not ds or ds:Equals(nil) or not ds.gameObject.activeInHierarchy then
                    _G.HTPS_DUNGEON_RUNNING = false
                    break
                end

                _G.HTPS_BONUS_SUPPRESS_UNTIL = 0
                if _G.HTPS_AUTO then _G.HTPS_AUTO.suppressPopup = true end
                _G.HTPS_KillSummonPopups()
                cleanDungeonPopups()

                if state.alive <= 0 then
                    CS.Toast.ShowToast(string.format("Hoàn tất Phó Bản tại Ải %d (Vượt +%d ải)!", state.stage, math.max(0, state.stage - startStage)))
                    _G.HTPS_DUNGEON_RUNNING = false
                    break
                end

                -- Chọn tướng còn sống mạnh nhất (hoặc xoay vòng nếu ải trước bị kẹt)
                local aliveList = {}
                for _, h in ipairs(state.heroes) do
                    if h.hp > 0 then
                        local score = (h.lv * 1000) + (h.star * 500) + (h.hp * 10)
                        if h.key == 638 or h.key == 611 or h.key == 629 or h.key == 542 or h.key == 647 then
                            score = score + 50000
                        end
                        h.score = score
                        table.insert(aliveList, h)
                    end
                end
                table.sort(aliveList, function(a, b) return a.score > b.score end)

                local pickIdx = ((rotateOffset) % #aliveList) + 1
                local chosen = aliveList[pickIdx]
                local bestSlot = chosen.slot

                local req = CS.pbdson.RequestData()
                req.session = gc.m_Session

                -- Tự động bơm bình máu (Action 510) nếu tướng đang chọn có HP < 70%
                if chosen.hp < 70 then
                    local usePotId = nil
                    if chosen.hp <= 40 and state.pots[3] > 0 then
                        usePotId = 2
                    elseif chosen.hp <= 65 and state.pots[2] > 0 then
                        usePotId = 1
                    elseif state.pots[1] > 0 then
                        usePotId = 0
                    elseif state.pots[2] > 0 then
                        usePotId = 1
                    elseif state.pots[3] > 0 then
                        usePotId = 2
                    end
                    if usePotId ~= nil then
                        local cv510 = CS.pbdson.CommonVector()
                        cv510.aLong:Add(bestSlot)
                        cv510.aLong:Add(usePotId)
                        local act510 = CS.pbdson.PbAction()
                        act510.actionId = 510
                        act510.data = _G.HTPS_SerializeProto(cv510)
                        req.actions:Add(act510)
                    end
                end

                -- Gộp 5 ải liên tiếp trong 1 gói mạng: [Action 505(0) qua Thương Nhân + Action 504(bestSlot) đánh ải] x 5 + Action 500 đồng bộ
                for step = 1, 5 do
                    local cv505 = CS.pbdson.CommonVector()
                    cv505.aLong:Add(0)
                    local act505 = CS.pbdson.PbAction()
                    act505.actionId = 505
                    act505.data = _G.HTPS_SerializeProto(cv505)
                    req.actions:Add(act505)

                    local cv504 = CS.pbdson.CommonVector()
                    cv504.aLong:Add(bestSlot)
                    local act504 = CS.pbdson.PbAction()
                    act504.actionId = 504
                    act504.data = _G.HTPS_SerializeProto(cv504)
                    req.actions:Add(act504)
                end

                local act500 = CS.pbdson.PbAction()
                act500.actionId = 500
                req.actions:Add(act500)

                local prevStage = state.stage
                local data, okNet = _G.HTPS_PutWebRequest(nc.m_UrlGameServer .. "/i/504/" .. tostring(gc.m_UserId), _G.HTPS_SerializeProto(req), 8)
                local newState = nil

                if okNet and data then
                    pcall(function()
                        local resp = _G.HTPS_DeserializeProto(data, "pbdson.ResponseData,PbMethodLib")
                        if resp and resp.aAction then
                            for i = 0, resp.aAction.Count - 1 do
                                local a = resp.aAction[i]
                                if a.actionId == 500 and a.data then
                                    local lcv = _G.HTPS_DeserializeProto(a.data, "pbdson.ListCommonVector,PbMethodLib")
                                    newState = parseDungeonStatus(lcv)
                                end
                            end
                        end
                    end)
                end

                if newState then
                    state = newState
                    pcall(function()
                        local txtStage = ds:GetType():GetField("m_TextStage", REF_FLAGS):GetValue(ds)
                        if txtStage then txtStage.text = "Ải " .. tostring(state.stage) end
                    end)
                    _G.HTPS_UpdateDungeonBtnUI(state.stage)

                    if state.stage > prevStage then
                        stuckCount = 0
                        rotateOffset = 0
                    else
                        stuckCount = stuckCount + 1
                        rotateOffset = rotateOffset + 1
                        if stuckCount >= (#aliveList + 2) then
                            CS.Toast.ShowToast(string.format("Đã dừng tại Ải %d (Đã thử hết tướng sống hoặc hoàn tất Phó Bản)!", state.stage))
                            _G.HTPS_DUNGEON_RUNNING = false
                            break
                        end
                    end
                else
                    stuckCount = stuckCount + 1
                    if stuckCount >= 4 then
                        _G.HTPS_DUNGEON_RUNNING = false
                        break
                    end
                end

                coroutine.yield(UG.WaitForSeconds(0.05))
            end

            _G.HTPS_DUNGEON_RUNNING = false
            _G.HTPS_UpdateDungeonBtnUI()
            cleanDungeonPopups()
            pcall(function()
                gc.dataSender:DungeonStatus()
                if ds and not ds:Equals(nil) then ds:HideLoading() end
            end)
        end)
    end

    _G.HTPS_EnsureDungeonButtons = function()
        pcall(function()
            local ds = _G.HTPS_FindObjectOfType(typeof(CS.DungeonScene))
            if not ds or ds:Equals(nil) or not ds.gameObject.activeInHierarchy then return end
            local cvs = GO.Find("Canvas")
            if not cvs then return end
            local btnSkipTf = cvs.transform:Find("ButtonCheckSkip")
            if not btnSkipTf then return end

            local btnAutoTf = cvs.transform:Find("BtnHTPSAutoDungeon")
            if not btnAutoTf then
                local origRt = btnSkipTf:GetComponent(typeof(UG.RectTransform))
                origRt.anchoredPosition = UG.Vector2(-128.0, -143.0)
                origRt.sizeDelta = UG.Vector2(230.0, 64.0)

                local cloneGo = GO.Instantiate(btnSkipTf.gameObject, cvs.transform, false)
                cloneGo.name = "BtnHTPSAutoDungeon"
                cloneGo:SetActive(true)
                local boxChk = cloneGo.transform:Find("BoxCheck")
                if boxChk then UG.Object.DestroyImmediate(boxChk.gameObject) end

                local rt = cloneGo:GetComponent(typeof(UG.RectTransform))
                rt.anchoredPosition = UG.Vector2(128.0, -143.0)
                rt.sizeDelta = UG.Vector2(230.0, 64.0)

                local img = cloneGo:GetComponent(typeof(UG.UI.Image))
                if img then img.raycastTarget = true end

                local txt = cloneGo:GetComponentInChildren(typeof(UG.UI.Text), true)
                if txt then
                    local loc = txt.gameObject:GetComponent(typeof(CS.I2.Loc.Localize))
                    if loc then UG.Object.DestroyImmediate(loc) end
                    local trt = txt.gameObject:GetComponent(typeof(UG.RectTransform))
                    trt.anchorMin = UG.Vector2(0, 0)
                    trt.anchorMax = UG.Vector2(1, 1)
                    trt.anchoredPosition = UG.Vector2(0, 0)
                    trt.sizeDelta = UG.Vector2(0, 0)
                    txt.raycastTarget = true
                    txt.alignment = UG.TextAnchor.MiddleCenter
                    txt.fontSize = 20
                    _G.HTPS_BTN_DUNGEON_TXT = txt
                end
                btnAutoTf = cloneGo.transform
                _G.HTPS_UpdateDungeonBtnUI()
            end

            if btnAutoTf and _G.HTPS_BOUND_DUNGEON_BTN ~= btnAutoTf then
                local bc = btnAutoTf:GetComponent(typeof(UG.UI.Button))
                if bc then
                    bc.onClick = UG.UI.Button.ButtonClickedEvent()
                    bc.onClick:AddListener(function()
                        _G.HTPS_ToggleAutoDungeon()
                    end)
                end
                _G.HTPS_BOUND_DUNGEON_BTN = btnAutoTf
            end
        end)
    end

    
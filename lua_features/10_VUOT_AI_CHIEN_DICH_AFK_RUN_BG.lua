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
-- TÍNH NĂNG: Treo Máy Vượt Ải Tự Động Toàn Thời Gian, Tự Nhận Rương AFK (Action 300+302+303), Tự Đổi Ải Cao Nhất
-- TRÍCH XUẤT TỪ NGUYENVINHMOD.DLL BẰNG REA ENGINE
-- =====================================================================

-- ==================== AUTO VƯỢT ẢI CHIẾN DỊCH CHÍNH (CHẠY NGẦM TOÀN THỜI GIAN: TỰ NHẬN RƯƠNG AFK + ĐỦ CẤP TỰ VƯỢT ẢI) ====================
    if _G.HTPS_CAMPAIGN_AUTO_ENABLED == nil then
        _G.HTPS_CAMPAIGN_AUTO_ENABLED = true
    end
    _G.HTPS_CAMPAIGN_RUNNING = _G.HTPS_CAMPAIGN_AUTO_ENABLED
    _G.HTPS_CAMPAIGN_BUSY = false
    _G.HTPS_CAMPAIGN_LAST_STAGE = nil
    _G.HTPS_CAMPAIGN_LAST_REQLV = nil

    _G.HTPS_UpdateCampaignBtnUI = function(statusText)
        pcall(function()
            if _G.HTPS_BTN_CAMPAIGN_TXT and not _G.HTPS_BTN_CAMPAIGN_TXT:Equals(nil) then
                if _G.HTPS_CAMPAIGN_AUTO_ENABLED then
                    if statusText then
                        _G.HTPS_BTN_CAMPAIGN_TXT.text = statusText
                    else
                        local gc = CS.GameContext.GetIntance()
                        local plv = (gc and tonumber(gc.m_PlayerLevel)) or 1
                        local rlv = tonumber(_G.HTPS_CAMPAIGN_LAST_REQLV) or 0
                        local stg = tonumber(_G.HTPS_CAMPAIGN_LAST_STAGE) or 0
                        if rlv > plv then
                            _G.HTPS_BTN_CAMPAIGN_TXT.text = string.format("Đợi Cấp %d (%d/%d)", rlv, plv, rlv)
                        elseif stg > 0 then
                            _G.HTPS_BTN_CAMPAIGN_TXT.text = string.format("Auto Ải %d [Bật]", stg)
                        else
                            _G.HTPS_BTN_CAMPAIGN_TXT.text = "Auto Ải [Đang Bật]"
                        end
                    end
                else
                    _G.HTPS_BTN_CAMPAIGN_TXT.text = "Auto Vượt Ải [Tắt]"
                end
                _G.HTPS_BTN_CAMPAIGN_TXT.color = UG.Color(0.42, 0.27, 0.14, 1)
            end
        end)
    end

    _G.HTPS_StopAutoCampaign = function()
        _G.HTPS_CAMPAIGN_AUTO_ENABLED = false
        _G.HTPS_CAMPAIGN_RUNNING = false
        _G.HTPS_UpdateCampaignBtnUI()
        return "STOPPED"
    end

    local function killCampaignTutorialAndPopups(didLevelUp)
        pcall(function()
            local cs = _G.HTPS_FindObjectOfType(typeof(CS.CampaignScene))
            if cs and not cs:Equals(nil) and cs.gameObject.activeInHierarchy then
                local hs = cs:GetType():GetField("handSuggest", 60):GetValue(cs)
                if hs and not hs:Equals(nil) then UG.Object.DestroyImmediate(hs) end
                local tutGo = GO.Find("PanelTutorialKeyHoleNew(Clone)")
                if tutGo then UG.Object.DestroyImmediate(tutGo) end
            end
            if didLevelUp then
                local tutGo = GO.Find("PanelTutorialKeyHoleNew(Clone)")
                if tutGo then UG.Object.DestroyImmediate(tutGo) end
                local cvs = GO.Find("Canvas")
                if cvs then
                    for i = cvs.transform.childCount - 1, 0, -1 do
                        local c = cvs.transform:GetChild(i).gameObject
                        if string.find(c.name, "PopupLevelUp") then
                            UG.Object.DestroyImmediate(c)
                        end
                    end
                end
            end
        end)
    end

    local function getBestCampaignLineup()
        local REF_FLAGS = 60
        local inv = CS.PlayerInventory.GetInstance()
        local heroes = {}
        pcall(function()
            local lstH = inv:GetType():GetField("m_LstHeroModel", REF_FLAGS):GetValue(inv)
            if lstH then
                for i = 0, lstH.Count - 1 do
                    local hm = lstH[i]
                    if hm and hm.m_HeroId and hm.m_HeroId > 0 then
                        table.insert(heroes, hm)
                    end
                end
            end
        end)
        table.sort(heroes, function(a, b)
            if (a.m_Level or 0) ~= (b.m_Level or 0) then
                return (a.m_Level or 0) > (b.m_Level or 0)
            end
            return (a.m_Star or 0) > (b.m_Star or 0)
        end)
        local bestPetId = -1
        pcall(function()
            local lstP = inv:GetType():GetField("m_LstPetModel", REF_FLAGS):GetValue(inv)
            if lstP then
                local maxPetLv = -1
                for i = 0, lstP.Count - 1 do
                    local pm = lstP[i]
                    if pm and pm.m_Level and pm.m_Level > maxPetLv then
                        maxPetLv = pm.m_Level
                        bestPetId = pm.m_PetId
                    end
                end
            end
        end)
        return heroes, bestPetId
    end

    local function parseCampaignStatusAndSync(resp)
        local curStage = nil
        local reqLv = nil
        local autoStage = nil
        local hasAwards = false
        local hasLoots = false
        if resp and resp.aAction then
            for i = 0, resp.aAction.Count - 1 do
                local a = resp.aAction[i]
                if (a.actionId == 302 or a.actionId == 303 or a.actionId == 118 or a.actionId == 351 or a.actionId == 9) and a.data then
                    pcall(function()
                        local cv = _G.HTPS_DeserializeProto(a.data, "pbdson.CommonVector,PbMethodLib")
                        if cv and cv.aLong and cv.aLong.Count > 0 then
                            CS.BonusModel.ParseBonusReceived(cv.aLong, true)
                        end
                    end)
                elseif a.actionId == 300 and a.data then
                    pcall(function()
                        local lcv = _G.HTPS_DeserializeProto(a.data, "pbdson.ListCommonVector,PbMethodLib")
                        if lcv and lcv.aVector and lcv.aVector.Count > 0 then
                            local v0 = lcv.aVector[0].aLong
                            if v0 and v0.Count >= 4 then
                                curStage = tonumber(v0[1]) or 1
                                reqLv = tonumber(v0[2]) or 1
                                autoStage = tonumber(v0[3]) or curStage
                                if v0.Count >= 7 then
                                    local goldAw = tonumber(v0[4]) or 0
                                    local expAw = tonumber(v0[6]) or 0
                                    if goldAw > 0 or expAw > 0 then hasAwards = true end
                                end
                            end
                            if lcv.aVector.Count >= 2 then
                                local v1 = lcv.aVector[1].aLong
                                if v1 and v1.Count > 0 then hasLoots = true end
                            end
                            local cs = _G.HTPS_FindObjectOfType(typeof(CS.CampaignScene))
                            if cs and not cs:Equals(nil) and cs.gameObject.activeInHierarchy then
                                cs:ProcessKEvent(300, lcv)
                                cs:HideLoading()
                            end
                        end
                    end)
                end
            end
        end
        if curStage then _G.HTPS_CAMPAIGN_LAST_STAGE = curStage end
        if reqLv then _G.HTPS_CAMPAIGN_LAST_REQLV = reqLv end
        return curStage, reqLv, autoStage, hasAwards, hasLoots
    end

    -- Hàm kiểm tra & tự động: (1) Nhận Rương EXP/Vàng AFK + Rương Đồ + Quà Online, (2) Nếu đủ Cấp -> Tự động vượt ải liên hoàn ngay!
    _G.HTPS_CheckAndAdvanceCampaign = function(isManualTrigger)
        if _G.HTPS_CAMPAIGN_BUSY then return end
        local gc = CS.GameContext.GetIntance()
        local nc = CS.NetworkController.GetInstance()
        if not gc or not nc or not gc.m_Session or gc.m_Session == "" or not gc.m_UserId or gc.m_UserId <= 0 then
            return
        end

        -- Tránh chạy đè khi đang ở trong trận đánh (BattleScene)
        local activeScene = UG.SceneManagement.SceneManager.GetActiveScene().name
        if activeScene == "BattleScene" then
            return
        end

        _G.HTPS_CAMPAIGN_BUSY = true
        pcall(function()
            local lvStart = tonumber(gc.m_PlayerLevel) or 1

            -- BƯỚC 1: Gửi gộp Action 300 (Tính EXP tới hiện tại) -> Action 302 (Nhận EXP/Vàng AFK) -> Action 303 (Nhận Rương Đồ) -> Action 300 (Đồng bộ)
            local reqCollect = CS.pbdson.RequestData()
            reqCollect.session = gc.m_Session
            local a300 = CS.pbdson.PbAction(); a300.actionId = 300; reqCollect.actions:Add(a300)
            local a302 = CS.pbdson.PbAction(); a302.actionId = 302; reqCollect.actions:Add(a302)
            local a303 = CS.pbdson.PbAction(); a303.actionId = 303; reqCollect.actions:Add(a303)
            local a118 = CS.pbdson.PbAction(); a118.actionId = 118; reqCollect.actions:Add(a118)
            local a300b = CS.pbdson.PbAction(); a300b.actionId = 300; reqCollect.actions:Add(a300b)

            local dataC, okC = _G.HTPS_PutWebRequest(nc.m_UrlGameServer .. "/i/300/" .. tostring(gc.m_UserId), _G.HTPS_SerializeProto(reqCollect), 8)
            local curStage, reqLv, autoStage = nil, nil, nil
            if okC and dataC then
                local respC = _G.HTPS_DeserializeProto(dataC, "pbdson.ResponseData,PbMethodLib")
                curStage, reqLv, autoStage = parseCampaignStatusAndSync(respC)
            end
            killCampaignTutorialAndPopups((tonumber(gc.m_PlayerLevel) or lvStart) > lvStart)

            -- Nếu ải treo máy (autoStage) đang thấp hơn ải cao nhất (curStage) -> Tự chuyển treo máy lên ải cao nhất (Action 306) để tối đa EXP!
            if curStage and autoStage and autoStage < curStage then
                local req306 = CS.pbdson.RequestData()
                req306.session = gc.m_Session
                local cv306 = CS.pbdson.CommonVector()
                cv306.aLong:Add(curStage)
                local act306 = CS.pbdson.PbAction()
                act306.actionId = 306
                act306.data = _G.HTPS_SerializeProto(cv306)
                req306.actions:Add(act306)
                _G.HTPS_PutWebRequest(nc.m_UrlGameServer .. "/i/306/" .. tostring(gc.m_UserId), _G.HTPS_SerializeProto(req306), 5)
            end

            local lvAfterCollect = tonumber(gc.m_PlayerLevel) or lvStart
            local startStage = curStage or 1
            local stagesCleared = 0

            -- BƯỚC 2: Hễ đủ Cấp Độ nhân vật (m_PlayerLevel >= reqLv) -> Tự động vượt ải liên hoàn (5 ải/gói) cho tới khi chạm mốc đợi cấp tiếp theo!
            while _G.HTPS_CAMPAIGN_AUTO_ENABLED and curStage and reqLv and (tonumber(gc.m_PlayerLevel) or 1) >= reqLv do
                local heroes, bestPetId = getBestCampaignLineup()
                if #heroes == 0 then break end

                _G.HTPS_UpdateCampaignBtnUI(string.format("Đang Vượt Ải %d...", curStage))

                local prevStage = curStage
                local reqAtk = CS.pbdson.RequestData()
                reqAtk.session = gc.m_Session
                for step = 1, 5 do
                    local cv304 = CS.pbdson.CommonVector()
                    for s = 1, 6 do
                        cv304.aLong:Add(heroes[s] and heroes[s].m_HeroId or -1)
                    end
                    cv304.aLong:Add(bestPetId)
                    local act304 = CS.pbdson.PbAction()
                    act304.actionId = 304
                    act304.data = _G.HTPS_SerializeProto(cv304)
                    reqAtk.actions:Add(act304)
                end
                local actClaimExp = CS.pbdson.PbAction(); actClaimExp.actionId = 302; reqAtk.actions:Add(actClaimExp)
                local actSync = CS.pbdson.PbAction(); actSync.actionId = 300; reqAtk.actions:Add(actSync)

                local dataA, okA = _G.HTPS_PutWebRequest(nc.m_UrlGameServer .. "/i/304/" .. tostring(gc.m_UserId), _G.HTPS_SerializeProto(reqAtk), 8)
                if okA and dataA then
                    local respA = _G.HTPS_DeserializeProto(dataA, "pbdson.ResponseData,PbMethodLib")
                    curStage, reqLv, autoStage = parseCampaignStatusAndSync(respA)
                else
                    break
                end
                killCampaignTutorialAndPopups((tonumber(gc.m_PlayerLevel) or lvStart) > lvStart)

                if curStage and curStage > prevStage then
                    stagesCleared = curStage - startStage
                    -- Luôn đặt treo máy ở ải mới cao nhất (Action 306)
                    if autoStage and autoStage < curStage then
                        local req306 = CS.pbdson.RequestData()
                        req306.session = gc.m_Session
                        local cv306 = CS.pbdson.CommonVector()
                        cv306.aLong:Add(curStage)
                        local act306 = CS.pbdson.PbAction()
                        act306.actionId = 306
                        act306.data = _G.HTPS_SerializeProto(cv306)
                        req306.actions:Add(act306)
                        _G.HTPS_PutWebRequest(nc.m_UrlGameServer .. "/i/306/" .. tostring(gc.m_UserId), _G.HTPS_SerializeProto(req306), 5)
                    end
                    coroutine.yield(UG.WaitForSeconds(0.06))
                else
                    break
                end
            end

            _G.HTPS_UpdateCampaignBtnUI()
            killCampaignTutorialAndPopups((tonumber(gc.m_PlayerLevel) or lvStart) > lvStart)

            local finalLv = tonumber(gc.m_PlayerLevel) or lvAfterCollect
            if stagesCleared > 0 then
                CS.Toast.ShowToast(string.format("⚔️ [Auto Vượt Ải] Đã tự nhận EXP & vượt tới Ải %d (+%d ải, Cấp %d/%d)!",
                    curStage or startStage, stagesCleared, finalLv, reqLv or finalLv))
            elseif finalLv > lvStart then
                CS.Toast.ShowToast(string.format("🎁 [Auto Rương EXP] Lên Cấp %d (Đợi Cấp %d để vượt Ải %d)!",
                    finalLv, reqLv or finalLv, curStage or startStage))
            elseif isManualTrigger then
                CS.Toast.ShowToast(string.format("⚔️ [Auto Vượt Ải: Đang Bật] Đã nhận Rương AFK! Hiện ở Ải %d (Cấp %d/%d, đủ cấp sẽ tự vượt ngay)",
                    curStage or startStage, finalLv, reqLv or finalLv))
            end
        end)
        _G.HTPS_CAMPAIGN_BUSY = false
    end

    _G.HTPS_CollectAllIdleChestsOnce = function(showToastWhenEmpty)
        CsCoroutine.start(function()
            _G.HTPS_CheckAndAdvanceCampaign(showToastWhenEmpty)
        end)
        return true
    end

    _G.HTPS_ToggleAutoCampaign = function()
        if _G.HTPS_CAMPAIGN_AUTO_ENABLED then
            _G.HTPS_CAMPAIGN_AUTO_ENABLED = false
            _G.HTPS_CAMPAIGN_RUNNING = false
            _G.HTPS_UpdateCampaignBtnUI()
            CS.Toast.ShowToast("🛑 Đã TẮT Auto Nhận Rương & Tự Vượt Ải!")
        else
            _G.HTPS_CAMPAIGN_AUTO_ENABLED = true
            _G.HTPS_CAMPAIGN_RUNNING = true
            _G.HTPS_UpdateCampaignBtnUI()
            CsCoroutine.start(function()
                _G.HTPS_CheckAndAdvanceCampaign(true)
            end)
        end
    end

    _G.HTPS_EnsureCampaignButtons = function()
        pcall(function()
            local cs = _G.HTPS_FindObjectOfType(typeof(CS.CampaignScene))
            if not cs or cs:Equals(nil) or not cs.gameObject.activeInHierarchy then return end
            local REF_FLAGS = 60
            local t = cs:GetType()
            local btnBattleGo = t:GetField("m_GoButtonBattle", REF_FLAGS):GetValue(cs)
            if not btnBattleGo then return end
            local cvsTf = btnBattleGo.transform.parent
            if not cvsTf then return end

            local hs = t:GetField("handSuggest", REF_FLAGS):GetValue(cs)
            if hs and not hs:Equals(nil) then UG.Object.DestroyImmediate(hs) end

            local btnAutoTf = cvsTf:Find("BtnHTPSAutoCampaign")
            if not btnAutoTf then
                local origRt = btnBattleGo:GetComponent(typeof(UG.RectTransform))
                origRt.anchoredPosition = UG.Vector2(-118.0, 209.0)
                origRt.sizeDelta = UG.Vector2(210.0, 68.0)

                local cloneGo = GO.Instantiate(btnBattleGo, cvsTf, false)
                cloneGo.name = "BtnHTPSAutoCampaign"
                cloneGo:SetActive(true)
                local rt = cloneGo:GetComponent(typeof(UG.RectTransform))
                rt.anchoredPosition = UG.Vector2(118.0, 209.0)
                rt.sizeDelta = UG.Vector2(210.0, 68.0)

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
                    txt.fontSize = 18
                    _G.HTPS_BTN_CAMPAIGN_TXT = txt
                end
                btnAutoTf = cloneGo.transform
                _G.HTPS_UpdateCampaignBtnUI()
            else
                if not btnAutoTf.gameObject.activeSelf then
                    btnAutoTf.gameObject:SetActive(true)
                end
                local rt = btnAutoTf:GetComponent(typeof(UG.RectTransform))
                if rt then
                    if btnBattleGo.activeSelf then
                        rt.anchoredPosition = UG.Vector2(118.0, 209.0)
                    else
                        rt.anchoredPosition = UG.Vector2(0.0, 209.0)
                    end
                end
                _G.HTPS_UpdateCampaignBtnUI()
            end

            if btnAutoTf and _G.HTPS_BOUND_CAMPAIGN_BTN ~= btnAutoTf then
                local bc = btnAutoTf:GetComponent(typeof(UG.UI.Button))
                if bc then
                    bc.onClick = UG.UI.Button.ButtonClickedEvent()
                    bc.onClick:AddListener(function()
                        _G.HTPS_ToggleAutoCampaign()
                    end)
                end
                _G.HTPS_BOUND_CAMPAIGN_BTN = btnAutoTf
            end
        end)
    end

    -- VÒNG LẶP NGẦM TOÀN THỜI GIAN: Mỗi 15 giây tự nhận Rương EXP/Đồ AFK & hễ đủ Cấp là tự vượt ải ngay lập tức!
    _G.HTPS_CAMPAIGN_BG_TOKEN = (_G.HTPS_CAMPAIGN_BG_TOKEN or 0) + 1
    local myBgToken = _G.HTPS_CAMPAIGN_BG_TOKEN
    CsCoroutine.start(function()
        while _G.HTPS_CAMPAIGN_BG_TOKEN == myBgToken do
            local gc = CS.GameContext.GetIntance()
            if gc and gc.m_Session and gc.m_Session ~= "" and gc.m_UserId and gc.m_UserId > 0 then
                break
            end
            coroutine.yield(UG.WaitForSeconds(1.0))
        end

        coroutine.yield(UG.WaitForSeconds(2.0))
        if _G.HTPS_CAMPAIGN_BG_TOKEN == myBgToken then
            pcall(function()
                if _G.HTPS_CAMPAIGN_AUTO_ENABLED then
                    _G.HTPS_CheckAndAdvanceCampaign(false)
                end
                if _G.HTPS_CollectAndFightSkyIsland then
                    _G.HTPS_CollectAndFightSkyIsland(false)
                end
            end)
        end

        local skyTick = 0
        while _G.HTPS_CAMPAIGN_BG_TOKEN == myBgToken do
            coroutine.yield(UG.WaitForSeconds(15.0))
            if _G.HTPS_CAMPAIGN_BG_TOKEN ~= myBgToken then break end
            pcall(function()
                if _G.HTPS_CAMPAIGN_AUTO_ENABLED then
                    _G.HTPS_CheckAndAdvanceCampaign(false)
                end
                skyTick = skyTick + 1
                if skyTick >= 12 then
                    skyTick = 0
                    if _G.HTPS_CollectAndFightSkyIsland then
                        _G.HTPS_CollectAndFightSkyIsland(false)
                    end
                end
            end)
        end
    end)

    -- =========================================================================
    -- AUTO DÙNG HẾT RƯƠNG / VẬT PHẨM NGẪU NHIÊN & CỐ ĐỊNH (ACTION 254 BATCH)
    -- =========================================================================
    _G.HTPS_AUTO_CHEST_USE_RUNNING = _G.HTPS_AUTO_CHEST_USE_RUNNING or false

    _G.HTPS_StopAutoUseChest = function(silent)
        if _G.HTPS_AUTO_CHEST_USE_RUNNING then
            _G.HTPS_AUTO_CHEST_USE_RUNNING = false
            if not silent then
                CS.Toast.ShowToast("⏹ Đã dừng Auto Dùng Rương!")
            end
        end
    end

    _G.HTPS_RefreshItemListSceneUI = function(itemKey, icObj)
        pcall(function()
            local pii = _G.HTPS_FindObjectOfType(typeof(CS.PopupItemInfo))
            if pii and not pii:Equals(nil) and pii.gameObject.activeInHierarchy then
                pii:ReloadItemInfo()
            end
        end)
        pcall(function()
            local puic = _G.HTPS_FindObjectOfType(typeof(CS.PopupUseItemConsume))
            if puic and not puic:Equals(nil) and puic.gameObject.activeInHierarchy and icObj then
                local icui = puic:GetType():GetField("m_ItemConsumeUI", 60):GetValue(puic)
                if icui and not icui:Equals(nil) then
                    icui:SetItemConsumable(icObj)
                end
            end
        end)
        pcall(function()
            local pss = _G.HTPS_FindObjectOfType(typeof(CS.PopupSummonShard))
            if pss and not pss:Equals(nil) and pss.gameObject.activeInHierarchy and icObj then
                local isui = pss:GetType():GetField("m_ItemShardUI", 60):GetValue(pss)
                if isui and not isui:Equals(nil) then
                    isui:SetItemShard(icObj)
                end
            end
        end)
        pcall(function()
            if not itemKey or not icObj then return end
            if icObj:GetType().Name == "ItemShard" then
                local uis = _G.HTPS_FindObjectsOfType(typeof(CS.ItemShardUI))
                for i = 0, uis.Length - 1 do
                    local u = uis[i]
                    if u and not u:Equals(nil) and u.gameObject.activeInHierarchy then
                        local isd = u:GetType():GetField("m_ItemShard", 60):GetValue(u)
                        if isd and tonumber(isd.m_ItemKey) == tonumber(itemKey) and tonumber(isd.m_ShardType) == tonumber(icObj.m_ShardType) then
                            u:SetItemShard(icObj)
                        end
                    end
                end
            else
                local uis = _G.HTPS_FindObjectsOfType(typeof(CS.ItemConsumableUI))
                for i = 0, uis.Length - 1 do
                    local u = uis[i]
                    if u and not u:Equals(nil) and u.gameObject.activeInHierarchy then
                        local ic = u:GetType():GetField("m_ItemConsumable", 60):GetValue(u)
                        if ic and tonumber(ic.m_ItemKey) == tonumber(itemKey) then
                            local gi = u:GetComponentInParent(typeof(CS.GameItem))
                            if gi and not gi:Equals(nil) then
                                u:SetItemConsumable(icObj)
                            else
                                u:SetItemConsumable(icObj)
                                u:SetItemGrayScaleInScrollview(false)
                            end
                        end
                    end
                end
            end
        end)
    end

    _G.HTPS_ReloadBagGridFull = function()
        pcall(function()
            local ils = _G.HTPS_FindObjectOfType(typeof(CS.ItemListScene))
            if ils and not ils:Equals(nil) and ils.gameObject.activeInHierarchy then
                local dlg = CS.System.Delegate.CreateDelegate(typeof(CS.System.Action), ils, "LoadData")
                if dlg then dlg() end
            end
        end)
    end

    _G.HTPS_ToggleAutoUseChest = function(explicitItem)
        if _G.HTPS_AUTO_CHEST_USE_RUNNING then
            _G.HTPS_StopAutoUseChest(false)
            return
        end

        local ic = explicitItem
        if not ic then
            pcall(function()
                local pss = _G.HTPS_FindObjectOfType(typeof(CS.PopupSummonShard))
                if pss and not pss:Equals(nil) and pss.gameObject.activeInHierarchy then
                    ic = pss:GetType():GetField("m_ItemShard", 60):GetValue(pss)
                end
            end)
        end
        if not ic then
            pcall(function()
                local puic = _G.HTPS_FindObjectOfType(typeof(CS.PopupUseItemConsume))
                if puic and not puic:Equals(nil) and puic.gameObject.activeInHierarchy then
                    ic = puic:GetType():GetField("m_ItemConsume", 60):GetValue(puic)
                end
            end)
        end
        if not ic then
            pcall(function()
                local pii = _G.HTPS_FindObjectOfType(typeof(CS.PopupItemInfo))
                if pii and not pii:Equals(nil) and pii.gameObject.activeInHierarchy then
                    ic = pii:GetType():GetField("m_ItemData", 60):GetValue(pii)
                end
            end)
        end

        local typeName = ic and ic:GetType().Name or ""
        if typeName ~= "ItemConsumable" and typeName ~= "ItemShard" then
            CS.Toast.ShowToast("⚠️ Vui lòng chọn một Rương hoặc Mảnh ghép!")
            return
        end

        if typeName == "ItemShard" then
            local shardType = tonumber(ic.m_ShardType) or 3
            local reqMerge = math.max(1, tonumber(ic.m_RequireToMerge) or 50)
            local startShards = tonumber(ic.m_Number) or 0
            local startSummon = math.floor(startShards / reqMerge)
            if startSummon <= 0 then
                CS.Toast.ShowToast("⚠️ Không đủ mảnh để hợp thành!")
                return
            end

            local itemKey = tonumber(ic.m_ItemKey)
            local itemName = tostring(ic.m_ItemName or ("Mảnh #" .. tostring(itemKey)))

            _G.HTPS_AUTO_CHEST_USE_RUNNING = true
            CS.Toast.ShowToast(string.format("🚀 Bắt đầu Hợp Thành All %d cái từ %d [%s]...", startSummon, startShards, itemName))

            CsCoroutine.start(function()
                local okLoop, errLoop = pcall(function()
                    local gc = CS.GameContext.GetIntance()
                    local nc = CS.NetworkController.GetInstance()
                    local maxPerAction = (shardType == 3) and 200 or 50
                    local maxActionsPerReq = 5
                    local stopReason = nil

                    while _G.HTPS_AUTO_CHEST_USE_RUNNING do
                        local remShards = tonumber(ic.m_Number) or 0
                        local remSummon = math.floor(remShards / reqMerge)
                        if remSummon <= 0 then
                            break
                        end

                        local req = CS.pbdson.RequestData()
                        req.session = gc.m_Session
                        local tempRem = remSummon
                        for b = 1, maxActionsPerReq do
                            if tempRem <= 0 then break end
                            local useCnt = math.min(tempRem, maxPerAction)
                            local cv = CS.pbdson.CommonVector()
                            cv.aLong:Add(shardType)
                            cv.aLong:Add(itemKey)
                            cv.aLong:Add(useCnt)
                            local act = CS.pbdson.PbAction()
                            act.actionId = 254
                            act.data = _G.HTPS_SerializeProto(cv)
                            req.actions:Add(act)
                            tempRem = tempRem - useCnt
                        end

                        _G.HTPS_BONUS_SUPPRESS_UNTIL = 0
                        _G.HTPS_AUTO.suppressPopup = true

                        local data, okReq = _G.HTPS_PutWebRequest(
                            nc.m_UrlGameServer .. "/i/254/" .. tostring(gc.m_UserId),
                            _G.HTPS_SerializeProto(req),
                            10
                        )

                        if not okReq or not data then
                            stopReason = "Lỗi kết nối máy chủ"
                            break
                        end

                        local got254 = false
                        local errMsg = nil
                        local resp = _G.HTPS_DeserializeProto(data, "pbdson.ResponseData,PbMethodLib")
                        if resp and resp.aAction then
                            for i = 0, resp.aAction.Count - 1 do
                                local a = resp.aAction[i]
                                if a.actionId == 254 and a.data then
                                    local rcv = _G.HTPS_DeserializeProto(a.data, "pbdson.CommonVector,PbMethodLib")
                                    if rcv and rcv.aLong and rcv.aLong.Count > 0 then
                                        CS.BonusModel.ParseBonusReceived(rcv.aLong, true)
                                        got254 = true
                                    end
                                elseif a.actionId == 1 and a.data then
                                    local rcv = _G.HTPS_DeserializeProto(a.data, "pbdson.CommonVector,PbMethodLib")
                                    if rcv and rcv.aString and rcv.aString.Count > 0 then
                                        errMsg = tostring(rcv.aString[0])
                                    end
                                end
                            end
                        end

                        _G.HTPS_KillSummonPopups()
                        _G.HTPS_RefreshItemListSceneUI(itemKey, ic)

                        if not got254 then
                            if maxPerAction > 50 then
                                maxPerAction = 50
                                maxActionsPerReq = 2
                            elseif maxPerAction > 10 then
                                maxPerAction = 10
                                maxActionsPerReq = 1
                            elseif maxPerAction > 1 then
                                maxPerAction = 1
                                maxActionsPerReq = 1
                            else
                                stopReason = errMsg or "Không thể hợp thành thêm"
                                break
                            end
                        end

                        coroutine.yield(UG.WaitForSeconds(0.02))
                    end

                    local finalRemShards = tonumber(ic.m_Number) or 0
                    local merged = math.floor(math.max(0, startShards - finalRemShards) / reqMerge)
                    _G.HTPS_AUTO_CHEST_USE_RUNNING = false
                    _G.HTPS_KillSummonPopups()
                    _G.HTPS_ReloadBagGridFull()

                    if finalRemShards < reqMerge then
                        pcall(function()
                            local pss = _G.HTPS_FindObjectOfType(typeof(CS.PopupSummonShard))
                            if pss and not pss:Equals(nil) and pss.gameObject.activeInHierarchy then
                                pss:ClosePopup()
                            end
                        end)
                        pcall(function()
                            local pii = _G.HTPS_FindObjectOfType(typeof(CS.PopupItemInfo))
                            if pii and not pii:Equals(nil) and pii.gameObject.activeInHierarchy then
                                pii:ButtonCloseClick()
                            end
                        end)
                        CS.Toast.ShowToast(string.format("✅ Đã hợp thành hết %d cái từ [%s]!", merged, itemName))
                    elseif stopReason then
                        CS.Toast.ShowToast(string.format("⚠️ Đã hợp thành %d cái [%s] (%s - Còn: %d mảnh)", merged, itemName, stopReason, finalRemShards))
                    else
                        CS.Toast.ShowToast(string.format("✅ Đã hợp thành %d cái [%s] (Còn lại: %d mảnh)", merged, itemName, finalRemShards))
                    end
                end)
                if not okLoop then
                    _G.HTPS_AUTO_CHEST_USE_RUNNING = false
                    CS.Toast.ShowToast("⚠️ Lỗi Hợp Thành All: " .. tostring(errLoop))
                end
            end)
            return
        end

        if tonumber(ic.m_TypeConsume) == 3 then
            CS.Toast.ShowToast("⚠️ Rương tùy chọn vật phẩm không dùng chế độ mở ngẫu nhiên này!")
            return
        end

        local startNum = tonumber(ic.m_Number) or 0
        if startNum <= 0 then
            CS.Toast.ShowToast("⚠️ Đã hết vật phẩm này!")
            return
        end

        local itemKey = tonumber(ic.m_ItemKey)
        local itemName = tostring(ic.m_ItemName or ("Rương #" .. tostring(itemKey)))

        _G.HTPS_AUTO_CHEST_USE_RUNNING = true
        CS.Toast.ShowToast(string.format("🚀 Bắt đầu Auto Dùng Hết %d [%s]...", startNum, itemName))

        CsCoroutine.start(function()
            local okLoop, errLoop = pcall(function()
                local gc = CS.GameContext.GetIntance()
                local nc = CS.NetworkController.GetInstance()
                local maxPerAction = 1000
                local maxActionsPerReq = 5
                local stopReason = nil

                while _G.HTPS_AUTO_CHEST_USE_RUNNING do
                    local rem = tonumber(ic.m_Number) or 0
                    if rem <= 0 then
                        break
                    end

                    local req = CS.pbdson.RequestData()
                    req.session = gc.m_Session
                    local tempRem = rem
                    for b = 1, maxActionsPerReq do
                        if tempRem <= 0 then break end
                        local useCnt = math.min(tempRem, maxPerAction)
                        local cv = CS.pbdson.CommonVector()
                        cv.aLong:Add(1)
                        cv.aLong:Add(itemKey)
                        cv.aLong:Add(useCnt)
                        local act = CS.pbdson.PbAction()
                        act.actionId = 254
                        act.data = _G.HTPS_SerializeProto(cv)
                        req.actions:Add(act)
                        tempRem = tempRem - useCnt
                    end

                    _G.HTPS_BONUS_SUPPRESS_UNTIL = 0
                    _G.HTPS_AUTO.suppressPopup = true

                    local data, okReq = _G.HTPS_PutWebRequest(
                        nc.m_UrlGameServer .. "/i/254/" .. tostring(gc.m_UserId),
                        _G.HTPS_SerializeProto(req),
                        10
                    )

                    if not okReq or not data then
                        stopReason = "Lỗi kết nối máy chủ"
                        break
                    end

                    local got254 = false
                    local errMsg = nil
                    local resp = _G.HTPS_DeserializeProto(data, "pbdson.ResponseData,PbMethodLib")
                    if resp and resp.aAction then
                        for i = 0, resp.aAction.Count - 1 do
                            local a = resp.aAction[i]
                            if a.actionId == 254 and a.data then
                                local rcv = _G.HTPS_DeserializeProto(a.data, "pbdson.CommonVector,PbMethodLib")
                                if rcv and rcv.aLong and rcv.aLong.Count > 0 then
                                    CS.BonusModel.ParseBonusReceived(rcv.aLong, true)
                                    got254 = true
                                end
                            elseif a.actionId == 1 and a.data then
                                local rcv = _G.HTPS_DeserializeProto(a.data, "pbdson.CommonVector,PbMethodLib")
                                if rcv and rcv.aString and rcv.aString.Count > 0 then
                                    errMsg = tostring(rcv.aString[0])
                                end
                            end
                        end
                    end

                    _G.HTPS_KillSummonPopups()
                    _G.HTPS_RefreshItemListSceneUI(itemKey, ic)

                    if not got254 then
                        if maxPerAction > 100 then
                            maxPerAction = 100
                            maxActionsPerReq = 2
                        elseif maxPerAction > 10 then
                            maxPerAction = 10
                            maxActionsPerReq = 1
                        elseif maxPerAction > 1 then
                            maxPerAction = 1
                            maxActionsPerReq = 1
                        else
                            stopReason = errMsg or "Không thể mở thêm rương"
                            break
                        end
                    end

                    coroutine.yield(UG.WaitForSeconds(0.02))
                end

                local finalRem = tonumber(ic.m_Number) or 0
                local opened = math.max(0, startNum - finalRem)
                _G.HTPS_AUTO_CHEST_USE_RUNNING = false
                _G.HTPS_KillSummonPopups()
                _G.HTPS_ReloadBagGridFull()

                if finalRem <= 0 then
                    pcall(function()
                        local puic = _G.HTPS_FindObjectOfType(typeof(CS.PopupUseItemConsume))
                        if puic and not puic:Equals(nil) and puic.gameObject.activeInHierarchy then
                            puic:ClosePopup()
                        end
                    end)
                    pcall(function()
                        local pii = _G.HTPS_FindObjectOfType(typeof(CS.PopupItemInfo))
                        if pii and not pii:Equals(nil) and pii.gameObject.activeInHierarchy then
                            pii:ButtonCloseClick()
                        end
                    end)
                    CS.Toast.ShowToast(string.format("✅ Đã dùng hết %d [%s]!", opened, itemName))
                elseif stopReason then
                    CS.Toast.ShowToast(string.format("⚠️ Đã mở %d [%s] (%s - Còn: %d)", opened, itemName, stopReason, finalRem))
                else
                    CS.Toast.ShowToast(string.format("✅ Đã mở %d [%s] (Còn lại: %d)", opened, itemName, finalRem))
                end
            end)
            if not okLoop then
                _G.HTPS_AUTO_CHEST_USE_RUNNING = false
                CS.Toast.ShowToast("⚠️ Lỗi Auto Dùng Rương: " .. tostring(errLoop))
            end
        end)
    end

    _G.HTPS_EnsureItemInfoButtons = function()
        -- 1. Trên PopupItemInfo (bên cạnh nút Dùng / Hợp thành)
        pcall(function()
            local pii = _G.HTPS_FindObjectOfType(typeof(CS.PopupItemInfo))
            if pii and not pii:Equals(nil) and pii.gameObject.activeInHierarchy then
                local pb = pii:GetType():GetField("m_PanelButton", 60):GetValue(pii)
                local b1 = pii:GetType():GetField("m_GoButtonAction1", 60):GetValue(pii)
                local t1 = pii:GetType():GetField("m_TextAction1", 60):GetValue(pii)
                local ic = pii:GetType():GetField("m_ItemData", 60):GetValue(pii)

                local canAutoUse = false
                local isShardItem = false
                if ic and b1 and b1.activeSelf then
                    local tName = ic:GetType().Name
                    if tName == "ItemConsumable" then
                        local tc = tonumber(ic.m_TypeConsume) or 0
                        local num = tonumber(ic.m_Number) or 0
                        if tc ~= 3 and tc ~= 1 and num > 0 then
                            canAutoUse = true
                        end
                    elseif tName == "ItemShard" then
                        local reqMerge = math.max(1, tonumber(ic.m_RequireToMerge) or 50)
                        local num = tonumber(ic.m_Number) or 0
                        if num >= reqMerge then
                            canAutoUse = true
                            isShardItem = true
                        end
                    end
                end

                if pb and b1 then
                    local existing = pb.transform:Find("BtnHTPSAutoUseChest")
                    local btnGo = existing and existing.gameObject or nil
                    if not btnGo and canAutoUse then
                        btnGo = UG.Object.Instantiate(b1, pb.transform)
                        btnGo.name = "BtnHTPSAutoUseChest"
                        local rt = btnGo:GetComponent(typeof(UG.RectTransform))
                        if rt then
                            rt.sizeDelta = UG.Vector2(175, 60)
                        end
                        local btnComp = btnGo:GetComponent(typeof(UG.UI.Button))
                        if btnComp then
                            btnComp.onClick = UG.UI.Button.ButtonClickedEvent()
                            btnComp.onClick:AddListener(function()
                                _G.HTPS_ToggleAutoUseChest()
                            end)
                        end
                    end

                    if btnGo then
                        if btnGo.activeSelf ~= canAutoUse then
                            btnGo:SetActive(canAutoUse)
                            UG.UI.LayoutRebuilder.ForceRebuildLayoutImmediate(pb:GetComponent(typeof(UG.RectTransform)))
                        end
                        if canAutoUse then
                            local txt = btnGo:GetComponentInChildren(typeof(UG.UI.Text), true)
                            if txt then
                                txt.fontSize = 20
                                if t1 then txt.color = t1.color end
                                if isShardItem then
                                    if _G.HTPS_AUTO_CHEST_USE_RUNNING then
                                        txt.text = "Đang ghép... [Dừng]"
                                    else
                                        txt.text = "Hợp Thành All"
                                    end
                                else
                                    if _G.HTPS_AUTO_CHEST_USE_RUNNING then
                                        txt.text = "Đang mở... [Dừng]"
                                    else
                                        txt.text = "Auto Dùng Hết"
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end)

        -- 2. Trên PopupUseItemConsume (popup chọn số lượng khi đã bấm Dùng)
        pcall(function()
            local puic = _G.HTPS_FindObjectOfType(typeof(CS.PopupUseItemConsume))
            if puic and not puic:Equals(nil) and puic.gameObject.activeInHierarchy then
                local content = puic:GetType():GetField("m_GoContent", 60):GetValue(puic)
                if content then
                    local btnOpenTf = content.transform:Find("ButtonOpen")
                    if btnOpenTf then
                        local btnOpenGo = btnOpenTf.gameObject
                        local rtOpen = btnOpenGo:GetComponent(typeof(UG.RectTransform))
                        if rtOpen then
                            rtOpen.anchoredPosition = UG.Vector2(-95, -128)
                        end
                        local existing = content.transform:Find("BtnHTPSAutoUseChestPopup")
                        local btnGo = existing and existing.gameObject or nil
                        if not btnGo then
                            btnGo = UG.Object.Instantiate(btnOpenGo, content.transform)
                            btnGo.name = "BtnHTPSAutoUseChestPopup"
                            local rt = btnGo:GetComponent(typeof(UG.RectTransform))
                            if rt then
                                rt.anchoredPosition = UG.Vector2(95, -128)
                                rt.sizeDelta = UG.Vector2(175, 60)
                            end
                            local btnComp = btnGo:GetComponent(typeof(UG.UI.Button))
                            if btnComp then
                                btnComp.onClick = UG.UI.Button.ButtonClickedEvent()
                                btnComp.onClick:AddListener(function()
                                    _G.HTPS_ToggleAutoUseChest()
                                end)
                            end
                        end
                        if btnGo then
                            btnGo:SetActive(true)
                            local txt = btnGo:GetComponentInChildren(typeof(UG.UI.Text), true)
                            local origTxt = btnOpenGo:GetComponentInChildren(typeof(UG.UI.Text), true)
                            if txt then
                                txt.fontSize = 20
                                if origTxt then txt.color = origTxt.color end
                                if _G.HTPS_AUTO_CHEST_USE_RUNNING then
                                    txt.text = "Đang mở... [Dừng]"
                                else
                                    txt.text = "Auto Dùng Hết"
                                end
                            end
                        end
                    end
                end
            end
        end)

        -- 3. Trên PopupSummonShard (popup chọn số lượng khi đã bấm Hợp thành mảnh)
        pcall(function()
            local pss = _G.HTPS_FindObjectOfType(typeof(CS.PopupSummonShard))
            if pss and not pss:Equals(nil) and pss.gameObject.activeInHierarchy then
                local content = pss:GetType():GetField("m_GoContent", 60):GetValue(pss)
                if content then
                    local btnSumTf = content.transform:Find("ButtonSummon") or content.transform:Find("ButtonOpen")
                    if not btnSumTf then
                        local ph = pss:GetType():GetField("m_GoPointHandSummon", 60):GetValue(pss)
                        if ph and ph.transform.parent and ph.transform.parent.parent == content.transform then
                            btnSumTf = ph.transform.parent
                        end
                    end
                    if btnSumTf then
                        local btnSumGo = btnSumTf.gameObject
                        local rtSum = btnSumGo:GetComponent(typeof(UG.RectTransform))
                        local origY = rtSum and rtSum.anchoredPosition.y or -128
                        if rtSum then
                            rtSum.anchoredPosition = UG.Vector2(-95, origY)
                        end
                        local existing = content.transform:Find("BtnHTPSAutoSummonShardPopup")
                        local btnGo = existing and existing.gameObject or nil
                        if not btnGo then
                            btnGo = UG.Object.Instantiate(btnSumGo, content.transform)
                            btnGo.name = "BtnHTPSAutoSummonShardPopup"
                            local rt = btnGo:GetComponent(typeof(UG.RectTransform))
                            if rt then
                                rt.anchoredPosition = UG.Vector2(95, origY)
                                rt.sizeDelta = UG.Vector2(175, 60)
                            end
                            local btnComp = btnGo:GetComponent(typeof(UG.UI.Button))
                            if btnComp then
                                btnComp.onClick = UG.UI.Button.ButtonClickedEvent()
                                btnComp.onClick:AddListener(function()
                                    _G.HTPS_ToggleAutoUseChest()
                                end)
                            end
                        end
                        if btnGo then
                            btnGo:SetActive(true)
                            local txt = btnGo:GetComponentInChildren(typeof(UG.UI.Text), true)
                            local origTxt = btnSumGo:GetComponentInChildren(typeof(UG.UI.Text), true)
                            if txt then
                                txt.fontSize = 20
                                if origTxt then txt.color = origTxt.color end
                                if _G.HTPS_AUTO_CHEST_USE_RUNNING then
                                    txt.text = "Đang ghép... [Dừng]"
                                else
                                    txt.text = "Hợp Thành All"
                                end
                            end
                        end
                    end
                end
            end
        end)
    end


    -- =========================================================================
    -- AUTO ĐẢO TRỜI (CELESTIAL ISLAND): THU MỎ + THU/MUA HOA THỦY TIÊN + ƯU TIÊN BOSS & ỦY THÁC ĐẢO QUÁI
    -- =========================================================================
    _G.HTPS_SKY_ISLAND_RUNNING = _G.HTPS_SKY_ISLAND_RUNNING or false

    _G.HTPS_GetSkyIslandTeamIds = function()
        local REF_FLAGS = 60
        local inv = CS.PlayerInventory.GetInstance()
        local validHeroMap = {}
        local heroes = {}
        local bestPet = -1

        pcall(function()
            local lstH = inv:GetType():GetField("m_LstHeroModel", REF_FLAGS):GetValue(inv)
            if lstH then
                for i = 0, lstH.Count - 1 do
                    local hm = lstH[i]
                    local hid = hm and tonumber(hm.m_HeroId) or 0
                    if hid > 0 then
                        validHeroMap[hid] = true
                        table.insert(heroes, hm)
                    end
                end
            end
            table.sort(heroes, function(a, b)
                if (a.m_Level or 0) ~= (b.m_Level or 0) then
                    return (a.m_Level or 0) > (b.m_Level or 0)
                end
                return (a.m_Star or 0) > (b.m_Star or 0)
            end)
            local lstP = inv:GetType():GetField("m_LstPetModel", REF_FLAGS):GetValue(inv)
            if lstP then
                local maxLv = 0
                for i = 0, lstP.Count - 1 do
                    local pm = lstP[i]
                    if pm and (pm.m_Level or 0) > maxLv then
                        maxLv = pm.m_Level or 0
                        bestPet = tonumber(pm.m_PetId) or -1
                    end
                end
            end
        end)

        local teamIds = {0, 0, 0, 0, 0, 0, bestPet}
        local usedHero = {}

        -- Ưu tiên lấy đội hình đã lưu nếu tất cả tướng đó còn nằm trong kho của nick hiện tại
        pcall(function()
            local hf = CS.LineUpSaveLoad.GetFormation(CS.LineUpSaveLoad.KEY_LINEUP_TOWER_1, CS.NumberLineUp.LINEUP_1)
            if hf and hf:CountNumberHero() > 0 then
                local lst = hf:ToListServerHeroId1LineUp()
                if lst and lst.Count >= 6 then
                    for i = 0, 5 do
                        local hid = tonumber(lst[i]) or 0
                        if hid > 0 and validHeroMap[hid] and not usedHero[hid] then
                            teamIds[i + 1] = hid
                            usedHero[hid] = true
                        end
                    end
                    if lst.Count >= 7 then
                        local savedPet = tonumber(lst[6]) or -1
                        if savedPet > 0 then teamIds[7] = savedPet end
                    end
                end
            end
        end)

        -- Lấp đầy các ô trống (hoặc thay thế tướng không hợp lệ) bằng các tướng mạnh nhất trong kho
        local hIdx = 1
        for slot = 1, 6 do
            if (teamIds[slot] or 0) <= 0 then
                while hIdx <= #heroes do
                    local candId = tonumber(heroes[hIdx].m_HeroId) or 0
                    hIdx = hIdx + 1
                    if candId > 0 and not usedHero[candId] then
                        teamIds[slot] = candId
                        usedHero[candId] = true
                        break
                    end
                end
            end
        end

        return teamIds
    end

    _G.HTPS_ParseAction420Bonus = function(aLong)
        pcall(function()
            if not aLong or aLong.Count <= 1 then return end
            local subList = CS.System.Collections.Generic.List(typeof(CS.System.Int64))()
            for i = 1, aLong.Count - 1 do
                subList:Add(aLong[i])
            end
            CS.BonusModel.ParseBonusReceived(subList, true)
        end)
    end

    _G.HTPS_ParseBattleResultBonus = function(rawBytes)
        pcall(function()
            if not rawBytes then return end
            local bRes = _G.HTPS_DeserializeProto(rawBytes, "pbdson.PbListBattleResult,PbMethodLib")
            if bRes and bRes.aBonus and bRes.aBonus.Count > 0 then
                CS.BonusModel.ParseBonusReceived(bRes.aBonus, true)
            end
        end)
    end

    _G.HTPS_CollectAndFightSkyIsland = function(showToastWhenEmpty)
        if _G.HTPS_SKY_ISLAND_RUNNING then
            if showToastWhenEmpty then
                CS.Toast.ShowToast("⏳ Auto Đảo Trời đang chạy...")
            end
            return
        end

        local gc = CS.GameContext.GetIntance()
        local nc = CS.NetworkController.GetInstance()
        if not gc or not gc.m_Session or gc.m_Session == "" or not gc.m_UserId or gc.m_UserId <= 0 or not nc then
            return
        end

        _G.HTPS_SKY_ISLAND_RUNNING = true
        if showToastWhenEmpty then
            CS.Toast.ShowToast("🏝️ Đang kiểm tra & Auto Đảo Trời (Ưu tiên Boss + Ủy thác)...")
        end

        CsCoroutine.start(function()
            local okRun, errRun = pcall(function()
                local teamIds = _G.HTPS_GetSkyIslandTeamIds()
                local hasHero = false
                for i = 1, 6 do
                    if (teamIds[i] or 0) > 0 then hasHero = true; break end
                end

                -- Bước 1: Lấy trạng thái Đảo Trời (411, 425, 417, 418)
                local reqStat = CS.pbdson.RequestData()
                reqStat.session = gc.m_Session
                for _, aid in ipairs({411, 425, 417, 418}) do
                    local act = CS.pbdson.PbAction()
                    act.actionId = aid
                    reqStat.actions:Add(act)
                end

                local dStat, okStat = _G.HTPS_PutWebRequest(
                    nc.m_UrlGameServer .. "/i/411/" .. tostring(gc.m_UserId),
                    _G.HTPS_SerializeProto(reqStat),
                    8
                )
                if not okStat or not dStat then
                    _G.HTPS_SKY_ISLAND_RUNNING = false
                    return
                end

                local daffodil = 0
                local buyLeft = 0
                local buyFee = 10
                local daffodilHarvest = 0
                local mines = {}
                local mineById = {}
                local aliveIslands = {}
                local bossId = 0
                local bossAlive = false
                local bossAssistLeft = 0

                local function parseIslandStatus417(raw417)
                    pcall(function()
                        local lcv = _G.HTPS_DeserializeProto(raw417, "pbdson.ListCommonVector,PbMethodLib")
                        if lcv and lcv.aVector and lcv.aVector.Count > 0 then
                            local v0 = lcv.aVector[0].aLong
                            if v0 and v0.Count >= 1 then
                                daffodil = tonumber(v0[0]) or daffodil
                            end
                            aliveIslands = {}
                            for v = 1, lcv.aVector.Count - 1 do
                                local vec = lcv.aVector[v].aLong
                                if vec and vec.Count >= 2 then
                                    local islId = tonumber(vec[0]) or 0
                                    local enAtk = tonumber(vec[1]) or 0
                                    if islId > 0 and enAtk == 1 then
                                        table.insert(aliveIslands, islId)
                                    end
                                end
                            end
                            table.sort(aliveIslands, function(a, b) return a > b end)
                        end
                    end)
                end

                local function parseBossStatus418(raw418)
                    pcall(function()
                        local rcv = _G.HTPS_DeserializeProto(raw418, "pbdson.CommonVector,PbMethodLib")
                        if rcv and rcv.aLong and rcv.aLong.Count >= 2 then
                            bossId = tonumber(rcv.aLong[0]) or 0
                            bossAlive = (tonumber(rcv.aLong[1]) == 1)
                            if rcv.aLong.Count >= 8 then
                                bossAssistLeft = tonumber(rcv.aLong[7]) or 0
                            end
                        end
                    end)
                end

                local respStat = _G.HTPS_DeserializeProto(dStat, "pbdson.ResponseData,PbMethodLib")
                if respStat and respStat.aAction then
                    for i = 0, respStat.aAction.Count - 1 do
                        local a = respStat.aAction[i]
                        if a.actionId == 411 and a.data then
                            pcall(function()
                                local lcv = _G.HTPS_DeserializeProto(a.data, "pbdson.ListCommonVector,PbMethodLib")
                                if lcv and lcv.aVector and lcv.aVector.Count > 0 then
                                    local v0 = lcv.aVector[0].aLong
                                    if v0 and v0.Count >= 7 then
                                        daffodil = tonumber(v0[1]) or 0
                                        buyLeft = tonumber(v0[4]) or 0
                                        buyFee = tonumber(v0[6]) or 10
                                    end
                                    for v = 1, lcv.aVector.Count - 1 do
                                        local vec = lcv.aVector[v].aLong
                                        if vec and vec.Count == 5 then
                                            local bId = tonumber(vec[0]) or 0
                                            local bType = tonumber(vec[1]) or 0
                                            local col = tonumber(vec[3]) or 0
                                            if bType == 5 then
                                                daffodilHarvest = col
                                            elseif bType == 2 or bType == 3 or bType == 4 then
                                                local mObj = { id = bId, type = bType, col = col }
                                                table.insert(mines, mObj)
                                                mineById[bId] = mObj
                                            end
                                        end
                                    end
                                end
                            end)
                        elseif a.actionId == 425 and a.data then
                            pcall(function()
                                local rcv = _G.HTPS_DeserializeProto(a.data, "pbdson.CommonVector,PbMethodLib")
                                if rcv and rcv.aLong then
                                    local idx = 0
                                    while idx + 2 < rcv.aLong.Count do
                                        local mId = tonumber(rcv.aLong[idx]) or 0
                                        local mCol = tonumber(rcv.aLong[idx + 1]) or 0
                                        if mineById[mId] then
                                            mineById[mId].col = mCol
                                        end
                                        idx = idx + 3
                                    end
                                end
                            end)
                        elseif a.actionId == 417 and a.data then
                            parseIslandStatus417(a.data)
                        elseif a.actionId == 418 and a.data then
                            parseBossStatus418(a.data)
                        end
                    end
                end

                local summaryParts = {}
                local stoneBefore = tonumber(gc.m_StoneOfVoid) or 0
                _G.HTPS_BONUS_SUPPRESS_UNTIL = 0
                _G.HTPS_AUTO.suppressPopup = true

                -- Bước 2: Thu hoạch Mỏ tài nguyên (416) & Hoa Thủy Tiên (426)
                local harvestActions = {}
                if daffodilHarvest > 0 then
                    local act426 = CS.pbdson.PbAction()
                    act426.actionId = 426
                    table.insert(harvestActions, act426)
                end
                for _, m in ipairs(mines) do
                    if (m.col or 0) > 0 then
                        local cv416 = CS.pbdson.CommonVector()
                        cv416.aLong:Add(m.id)
                        cv416.aLong:Add(m.type)
                        local act416 = CS.pbdson.PbAction()
                        act416.actionId = 416
                        act416.data = _G.HTPS_SerializeProto(cv416)
                        table.insert(harvestActions, act416)
                    end
                end

                if #harvestActions > 0 then
                    local idxH = 1
                    local harvestedMines = 0
                    local harvestedDaff = 0
                    while idxH <= #harvestActions do
                        local reqH = CS.pbdson.RequestData()
                        reqH.session = gc.m_Session
                        for b = 1, 5 do
                            if idxH > #harvestActions then break end
                            reqH.actions:Add(harvestActions[idxH])
                            idxH = idxH + 1
                        end
                        local dH, okH = _G.HTPS_PutWebRequest(
                            nc.m_UrlGameServer .. "/i/416/" .. tostring(gc.m_UserId),
                            _G.HTPS_SerializeProto(reqH),
                            8
                        )
                        if okH and dH then
                            pcall(function()
                                local rH = _G.HTPS_DeserializeProto(dH, "pbdson.ResponseData,PbMethodLib")
                                if rH and rH.aAction then
                                    for i = 0, rH.aAction.Count - 1 do
                                        local a = rH.aAction[i]
                                        if (a.actionId == 416 or a.actionId == 9) and a.data then
                                            local rcv = _G.HTPS_DeserializeProto(a.data, "pbdson.CommonVector,PbMethodLib")
                                            if rcv and rcv.aLong and rcv.aLong.Count > 0 then
                                                CS.BonusModel.ParseBonusReceived(rcv.aLong, true)
                                                harvestedMines = harvestedMines + 1
                                            end
                                        elseif a.actionId == 426 and a.data then
                                            local rcv = _G.HTPS_DeserializeProto(a.data, "pbdson.CommonVector,PbMethodLib")
                                            if rcv and rcv.aLong and rcv.aLong.Count > 0 then
                                                local addD = tonumber(rcv.aLong[0]) or 0
                                                daffodil = daffodil + addD
                                                harvestedDaff = harvestedDaff + addD
                                            end
                                        end
                                    end
                                end
                            end)
                        end
                    end
                    if harvestedMines > 0 then
                        table.insert(summaryParts, string.format("Thu %d Mỏ", harvestedMines))
                    end
                    if harvestedDaff > 0 then
                        table.insert(summaryParts, string.format("Nhận +%d Lượt", harvestedDaff))
                    end
                end

                -- Bước 3: Tự động mua thêm tối đa lượt Hoa Thủy Tiên (422)
                local curGem = tonumber(gc.m_Gem) or 0
                local canBuy = 0
                if buyLeft > 0 and buyFee > 0 and curGem >= buyFee then
                    canBuy = math.min(buyLeft, math.floor(curGem / buyFee))
                end
                local boughtTurns = 0
                while canBuy > 0 do
                    local batchBuy = math.min(canBuy, 5)
                    local reqBuy = CS.pbdson.RequestData()
                    reqBuy.session = gc.m_Session
                    for b = 1, batchBuy do
                        local act422 = CS.pbdson.PbAction()
                        act422.actionId = 422
                        reqBuy.actions:Add(act422)
                    end
                    local dB, okB = _G.HTPS_PutWebRequest(
                        nc.m_UrlGameServer .. "/i/422/" .. tostring(gc.m_UserId),
                        _G.HTPS_SerializeProto(reqBuy),
                        8
                    )
                    local got422 = false
                    if okB and dB then
                        pcall(function()
                            local rB = _G.HTPS_DeserializeProto(dB, "pbdson.ResponseData,PbMethodLib")
                            if rB and rB.aAction then
                                for i = 0, rB.aAction.Count - 1 do
                                    local a = rB.aAction[i]
                                    if a.actionId == 422 and a.data then
                                        local rcv = _G.HTPS_DeserializeProto(a.data, "pbdson.CommonVector,PbMethodLib")
                                        if rcv and rcv.aLong and rcv.aLong.Count > 0 then
                                            CS.BonusModel.ParseBonusReceived(rcv.aLong, true)
                                        end
                                        boughtTurns = boughtTurns + 1
                                        daffodil = daffodil + 1
                                        got422 = true
                                    elseif a.actionId == 417 and a.data then
                                        parseIslandStatus417(a.data)
                                    end
                                end
                            end
                        end)
                    end
                    canBuy = canBuy - batchBuy
                    if not got422 then break end
                end
                if boughtTurns > 0 then
                    table.insert(summaryParts, string.format("Mua +%d Lượt", boughtTurns))
                end

                -- Bước 4 (ƯU TIÊN SỐ 1): Dùng lượt Hỗ Trợ Bạn Bè miễn phí (448 -> 423) đánh Boss trước
                local assistUsed = 0
                if bossAlive and bossAssistLeft > 0 then
                    local bestFriendId = 0
                    local reqFr = CS.pbdson.RequestData()
                    reqFr.session = gc.m_Session
                    local act448 = CS.pbdson.PbAction()
                    act448.actionId = 448
                    reqFr.actions:Add(act448)
                    local dFr, okFr = _G.HTPS_PutWebRequest(
                        nc.m_UrlGameServer .. "/i/448/" .. tostring(gc.m_UserId),
                        _G.HTPS_SerializeProto(reqFr),
                        8
                    )
                    if okFr and dFr then
                        pcall(function()
                            local rFr = _G.HTPS_DeserializeProto(dFr, "pbdson.ResponseData,PbMethodLib")
                            if rFr and rFr.aAction and rFr.aAction.Count > 0 then
                                local lpu = _G.HTPS_DeserializeProto(rFr.aAction[0].data, "pbdson.PbListUser,PbMethodLib")
                                if lpu and lpu.aUser and lpu.aUser.Count > 0 then
                                    local maxP = -1
                                    for i = 0, lpu.aUser.Count - 1 do
                                        local u = lpu.aUser[i]
                                        if u and (u.power or 0) > maxP then
                                            maxP = u.power or 0
                                            bestFriendId = tonumber(u.id) or 0
                                        end
                                    end
                                end
                            end
                        end)
                    end

                    if bestFriendId > 0 then
                        for k = 1, bossAssistLeft do
                            if not bossAlive then break end
                            local reqAs = CS.pbdson.RequestData()
                            reqAs.session = gc.m_Session
                            local cv423 = CS.pbdson.CommonVector()
                            cv423.aLong:Add(bestFriendId)
                            local act423 = CS.pbdson.PbAction()
                            act423.actionId = 423
                            act423.data = _G.HTPS_SerializeProto(cv423)
                            reqAs.actions:Add(act423)
                            local act418 = CS.pbdson.PbAction()
                            act418.actionId = 418
                            reqAs.actions:Add(act418)

                            local dAs, okAs = _G.HTPS_PutWebRequest(
                                nc.m_UrlGameServer .. "/i/423/" .. tostring(gc.m_UserId),
                                _G.HTPS_SerializeProto(reqAs),
                                8
                            )
                            if okAs and dAs then
                                pcall(function()
                                    local rAs = _G.HTPS_DeserializeProto(dAs, "pbdson.ResponseData,PbMethodLib")
                                    if rAs and rAs.aAction then
                                        for i = 0, rAs.aAction.Count - 1 do
                                            local a = rAs.aAction[i]
                                            if a.actionId == 423 and a.data then
                                                _G.HTPS_ParseBattleResultBonus(a.data)
                                                assistUsed = assistUsed + 1
                                            elseif a.actionId == 418 and a.data then
                                                parseBossStatus418(a.data)
                                            end
                                        end
                                    end
                                end)
                            else
                                break
                            end
                        end
                    end
                end
                if assistUsed > 0 then
                    table.insert(summaryParts, string.format("Hỗ trợ Boss %d lần", assistUsed))
                end

                -- Bước 5 (ƯU TIÊN SỐ 2): Dồn lượt Hoa Thủy Tiên đánh & quét Boss (bossId = 0) trước khi đánh đảo quái
                local bossAtks = 0
                local bossRounds = 0
                while hasHero and bossAlive and daffodil > 0 and bossRounds < 4 do
                    bossRounds = bossRounds + 1
                    local daffBeforeBoss = daffodil
                    local reqB1 = CS.pbdson.RequestData()
                    reqB1.session = gc.m_Session
                    local cv420 = CS.pbdson.CommonVector()
                    cv420.aLong:Add(bossId)
                    cv420.aLong:Add(daffodil)
                    for _, hid in ipairs(teamIds) do cv420.aLong:Add(hid) end
                    local act420 = CS.pbdson.PbAction()
                    act420.actionId = 420
                    act420.data = _G.HTPS_SerializeProto(cv420)
                    reqB1.actions:Add(act420)
                    local act418 = CS.pbdson.PbAction()
                    act418.actionId = 418
                    reqB1.actions:Add(act418)

                    local dB1, okB1 = _G.HTPS_PutWebRequest(
                        nc.m_UrlGameServer .. "/i/420/" .. tostring(gc.m_UserId),
                        _G.HTPS_SerializeProto(reqB1),
                        8
                    )
                    local needFirstBattle = false
                    local got420 = false
                    if okB1 and dB1 then
                        pcall(function()
                            local rB1 = _G.HTPS_DeserializeProto(dB1, "pbdson.ResponseData,PbMethodLib")
                            if rB1 and rB1.aAction then
                                for i = 0, rB1.aAction.Count - 1 do
                                    local a = rB1.aAction[i]
                                    if a.actionId == 420 and a.data then
                                        local rcv = _G.HTPS_DeserializeProto(a.data, "pbdson.CommonVector,PbMethodLib")
                                        if rcv and rcv.aLong then
                                            _G.HTPS_ParseAction420Bonus(rcv.aLong)
                                        end
                                        got420 = true
                                    elseif a.actionId == 417 and a.data then
                                        parseIslandStatus417(a.data)
                                    elseif a.actionId == 418 and a.data then
                                        parseBossStatus418(a.data)
                                    elseif a.actionId == 1 then
                                        needFirstBattle = true
                                    end
                                end
                                if got420 then
                                    bossAtks = bossAtks + math.max(1, daffBeforeBoss - daffodil)
                                end
                            end
                        end)
                    end

                    -- Nếu cần đánh trực tiếp (Action 419) mở khóa quét hoặc đánh từng trận
                    if (needFirstBattle or not got420) and bossAlive and daffodil > 0 then
                        local reqFirst = CS.pbdson.RequestData()
                        reqFirst.session = gc.m_Session
                        local cvFirst = CS.pbdson.CommonVector()
                        cvFirst.aLong:Add(bossId)
                        for _, hid in ipairs(teamIds) do cvFirst.aLong:Add(hid) end
                        local actFirst = CS.pbdson.PbAction()
                        actFirst.actionId = 419
                        actFirst.data = _G.HTPS_SerializeProto(cvFirst)
                        reqFirst.actions:Add(actFirst)
                        local act418_f = CS.pbdson.PbAction()
                        act418_f.actionId = 418
                        reqFirst.actions:Add(act418_f)

                        local dF, okF = _G.HTPS_PutWebRequest(
                            nc.m_UrlGameServer .. "/i/419/" .. tostring(gc.m_UserId),
                            _G.HTPS_SerializeProto(reqFirst),
                            8
                        )
                        local got419 = false
                        if okF and dF then
                            pcall(function()
                                local rF = _G.HTPS_DeserializeProto(dF, "pbdson.ResponseData,PbMethodLib")
                                if rF and rF.aAction then
                                    for i = 0, rF.aAction.Count - 1 do
                                        local a = rF.aAction[i]
                                        if a.actionId == 419 and a.data then
                                            _G.HTPS_ParseBattleResultBonus(a.data)
                                            got419 = true
                                        elseif a.actionId == 417 and a.data then
                                            parseIslandStatus417(a.data)
                                        elseif a.actionId == 418 and a.data then
                                            parseBossStatus418(a.data)
                                        end
                                    end
                                end
                            end)
                        end
                        if got419 then
                            daffodil = math.max(0, daffodil - 1)
                            bossAtks = bossAtks + 1
                        else
                            break
                        end
                    elseif not got420 then
                        break
                    end
                end
                if bossAtks > 0 then
                    local killStr = (not bossAlive) and " (Đã hạ Boss!)" or ""
                    table.insert(summaryParts, string.format("Đánh Boss %d lần%s", bossAtks, killStr))
                end

                -- Bước 6: Ủy thác (Action 421 - SmashIsland) & dọn toàn bộ Đảo Quái còn lại
                local clearedIslands = 0
                if hasHero and #aliveIslands > 0 and daffodil > 0 then
                    local islandsBefore = #aliveIslands
                    local req421 = CS.pbdson.RequestData()
                    req421.session = gc.m_Session
                    local cv421 = CS.pbdson.CommonVector()
                    for _, hid in ipairs(teamIds) do cv421.aLong:Add(hid) end
                    local act421 = CS.pbdson.PbAction()
                    act421.actionId = 421
                    act421.data = _G.HTPS_SerializeProto(cv421)
                    req421.actions:Add(act421)
                    local act417_s = CS.pbdson.PbAction()
                    act417_s.actionId = 417
                    req421.actions:Add(act417_s)

                    local d421, ok421 = _G.HTPS_PutWebRequest(
                        nc.m_UrlGameServer .. "/i/421/" .. tostring(gc.m_UserId),
                        _G.HTPS_SerializeProto(req421),
                        8
                    )
                    if ok421 and d421 then
                        pcall(function()
                            local r421 = _G.HTPS_DeserializeProto(d421, "pbdson.ResponseData,PbMethodLib")
                            if r421 and r421.aAction then
                                for i = 0, r421.aAction.Count - 1 do
                                    local a = r421.aAction[i]
                                    if a.actionId == 421 and a.data then
                                        local rcv = _G.HTPS_DeserializeProto(a.data, "pbdson.CommonVector,PbMethodLib")
                                        if rcv and rcv.aLong and rcv.aLong.Count > 1 then
                                            _G.HTPS_ParseAction420Bonus(rcv.aLong)
                                        end
                                    elseif a.actionId == 417 and a.data then
                                        parseIslandStatus417(a.data)
                                    elseif a.actionId == 9 and a.data then
                                        local rcv = _G.HTPS_DeserializeProto(a.data, "pbdson.CommonVector,PbMethodLib")
                                        if rcv and rcv.aLong and rcv.aLong.Count > 0 then
                                            CS.BonusModel.ParseBonusReceived(rcv.aLong, true)
                                        end
                                    end
                                end
                            end
                        end)
                        if #aliveIslands < islandsBefore then
                            clearedIslands = clearedIslands + (islandsBefore - #aliveIslands)
                        end
                    end

                    -- Dự phòng: Nếu vẫn còn Đảo Quái chưa chết sau Ủy Thác 421 thì đánh/quét trực tiếp (420 + 419)
                    local islIdx = 1
                    while islIdx <= #aliveIslands and daffodil > 0 do
                        local targetIslId = aliveIslands[islIdx]
                        islIdx = islIdx + 1
                        local reqIsl = CS.pbdson.RequestData()
                        reqIsl.session = gc.m_Session
                        local cv419 = CS.pbdson.CommonVector()
                        cv419.aLong:Add(targetIslId)
                        for _, hid in ipairs(teamIds) do cv419.aLong:Add(hid) end
                        local act419 = CS.pbdson.PbAction()
                        act419.actionId = 419
                        act419.data = _G.HTPS_SerializeProto(cv419)
                        reqIsl.actions:Add(act419)
                        local act417_i = CS.pbdson.PbAction()
                        act417_i.actionId = 417
                        reqIsl.actions:Add(act417_i)

                        local dI, okI = _G.HTPS_PutWebRequest(
                            nc.m_UrlGameServer .. "/i/419/" .. tostring(gc.m_UserId),
                            _G.HTPS_SerializeProto(reqIsl),
                            8
                        )
                        if okI and dI then
                            daffodil = math.max(0, daffodil - 1)
                            pcall(function()
                                local rI = _G.HTPS_DeserializeProto(dI, "pbdson.ResponseData,PbMethodLib")
                                if rI and rI.aAction then
                                    for i = 0, rI.aAction.Count - 1 do
                                        local a = rI.aAction[i]
                                        if a.actionId == 419 and a.data then
                                            _G.HTPS_ParseBattleResultBonus(a.data)
                                            clearedIslands = clearedIslands + 1
                                        elseif a.actionId == 417 and a.data then
                                            parseIslandStatus417(a.data)
                                        elseif a.actionId == 9 and a.data then
                                            local rcv = _G.HTPS_DeserializeProto(a.data, "pbdson.CommonVector,PbMethodLib")
                                            if rcv and rcv.aLong and rcv.aLong.Count > 0 then
                                                CS.BonusModel.ParseBonusReceived(rcv.aLong, true)
                                            end
                                        end
                                    end
                                end
                            end)
                        else
                            break
                        end
                    end
                end
                if clearedIslands > 0 then
                    table.insert(summaryParts, string.format("Ủy thác %d Đảo Quái", clearedIslands))
                end

                _G.HTPS_KillSummonPopups()

                -- Nếu đang đứng ở màn hình Đảo Trời thì đồng bộ lại UI ngay lập tức
                pcall(function()
                    local cs = _G.HTPS_FindObjectOfType(typeof(CS.CelestialScene))
                    if cs and not cs:Equals(nil) and cs.gameObject.activeInHierarchy then
                        local ds = cs:GetType():GetField("m_DataSender", 60):GetValue(cs)
                        if ds then
                            ds:GetCelestialStatus()
                            ds:GetIslandStatus()
                            ds:GetBossVoidStatus()
                        end
                    end
                end)

                local stoneGain = math.max(0, (tonumber(gc.m_StoneOfVoid) or 0) - stoneBefore)
                if #summaryParts > 0 then
                    local stStr = (stoneGain > 0) and string.format(" (+%d Đá Hư Không)", stoneGain) or ""
                    CS.Toast.ShowToast("🏝️ [Auto Đảo Trời] " .. table.concat(summaryParts, " + ") .. stStr .. "!")
                elseif showToastWhenEmpty then
                    CS.Toast.ShowToast("🏝️ [Auto Đảo Trời] Đã thu hoạch & dùng hết toàn bộ lượt Đảo Trời!")
                end
            end)
            _G.HTPS_SKY_ISLAND_RUNNING = false
            if not okRun and showToastWhenEmpty then
                CS.Toast.ShowToast("⚠️ Lỗi Auto Đảo Trời: " .. tostring(errRun))
            end
        end)
    end

    _G.HTPS_EnsureSkyIslandButtons = function()
        pcall(function()
            local cs = _G.HTPS_FindObjectOfType(typeof(CS.CelestialScene))
            if not cs or cs:Equals(nil) or not cs.gameObject.activeInHierarchy then
                return
            end
            local csId = cs:GetInstanceID()
            if _G.HTPS_LAST_SKY_SCENE_ID ~= csId then
                _G.HTPS_LAST_SKY_SCENE_ID = csId
                if _G.HTPS_CollectAndFightSkyIsland and not _G.HTPS_SKY_ISLAND_RUNNING then
                    _G.HTPS_CollectAndFightSkyIsland(false)
                end
            end
            local bs = cs:GetType():GetField("m_GoButtonSmash", 60):GetValue(cs)
            if not bs or bs:Equals(nil) or not bs.transform.parent then
                return
            end
            local parent = bs.transform.parent
            local existing = parent:Find("BtnHTPSAutoSkyIsland")
            local btnGo = existing and existing.gameObject or nil
            if not btnGo then
                btnGo = UG.Object.Instantiate(bs, parent)
                btnGo.name = "BtnHTPSAutoSkyIsland"
                local rt = btnGo:GetComponent(typeof(UG.RectTransform))
                if rt then
                    rt.anchoredPosition = UG.Vector2(-198.0, 7.5)
                    rt.sizeDelta = UG.Vector2(180.0, 65.0)
                end
                local btnComp = btnGo:GetComponent(typeof(UG.UI.Button))
                if btnComp then
                    btnComp.onClick = UG.UI.Button.ButtonClickedEvent()
                    btnComp.onClick:AddListener(function()
                        _G.HTPS_CollectAndFightSkyIsland(true)
                    end)
                end
            end
            if btnGo then
                btnGo:SetActive(true)
                local txt = btnGo:GetComponentInChildren(typeof(UG.UI.Text), true)
                local origTxt = bs:GetComponentInChildren(typeof(UG.UI.Text), true)
                if txt then
                    txt.fontSize = 20
                    if origTxt then txt.color = origTxt.color end
                    if _G.HTPS_SKY_ISLAND_RUNNING then
                        txt.text = "Đang Auto..."
                    else
                        txt.text = "Auto Đảo Trời"
                    end
                end
            end
        end)
    end

    -- =========================================================================
    -- AUTO NÂNG SAO & TỰ ĐỘNG LÊN CẤP TỐI ĐA (5★ -> 15★ E5 + LÍNH CHÌ & PHÔI)
    -- =========================================================================
    _G.HTPS_STAR_UPGRADE_RUNNING = _G.HTPS_STAR_UPGRADE_RUNNING or false
    _G.HTPS_STAR_UPGRADE_STATUS = _G.HTPS_STAR_UPGRADE_STATUS or nil

    local HTPS_STAR_MAX_LV = {
        [1] = 30, [2] = 40, [3] = 60, [4] = 80, [5] = 100,
        [6] = 140, [7] = 160, [8] = 180, [9] = 200, [10] = 250,
        [11] = 260, [12] = 270, [13] = 290, [14] = 310, [15] = 330
    }
    local HTPS_TIER_MAX_LV = {
        [0] = 30, [1] = 40, [2] = 50, [3] = 60, [4] = 80, [5] = 100
    }
    local HTPS_PUPPET_5_BY_FAC = {
        [1] = 358, [2] = 359, [3] = 354, [4] = 355, [5] = 357, [6] = 356
    }
    local HTPS_PUPPET_6_BY_FAC = {
        [1] = 352, [2] = 353, [3] = 348, [4] = 349, [5] = 351, [6] = 350
    }
    local HTPS_RAND_5_SHARD_BY_FAC = {
        [1] = 30005, [2] = 30006, [3] = 30001, [4] = 30003, [5] = 30004, [6] = 30002
    }

    local function htpsEnumToInt(val)
        if val == nil then return 0 end
        if type(val) == "number" then
            if val < 1 or val > 6 then return 0 end
            return val
        end
        local sVal = tostring(val)
        local u = sVal:upper()
        if u:find("UNKNOWN") then return 0 end
        local num = tonumber(sVal:match("(-?%d+)"))
        if num then
            if num < 1 or num > 6 then return 0 end
            return num
        end
        if u:find("DARK") then return 1 end
        if u:find("LIGHT") then return 2 end
        if u:find("SHADOW") then return 3 end
        if u:find("FORTRESS") then return 4 end
        if u:find("FOREST") then return 5 end
        if u:find("ABYSS") then return 6 end
        return 0
    end

    local function htpsResolveBase5Key(heroKey)
        local hk = tonumber(heroKey) or 0
        if hk <= 0 then return 0 end
        local db = CS.DbManager.GetInstance()
        if not db then return hk end
        local hm = db:GetHeroModel(hk)
        if hm and tonumber(hm.m_Star) == 5 then
            return hk
        end
        if not _G.HTPS_BASE5_MAP_CACHE then
            _G.HTPS_BASE5_MAP_CACHE = {}
            for k = 1, 2500 do
                local ok6, k6 = pcall(function() return db:GetKeyHero6StarFromHero5Star(k) end)
                if ok6 and k6 and k6 > 0 then
                    _G.HTPS_BASE5_MAP_CACHE[k6] = k
                end
                local ok10, k10 = pcall(function() return db:GetKeyHero10StarFromHero5Star(k) end)
                if ok10 and k10 and k10 > 0 then
                    _G.HTPS_BASE5_MAP_CACHE[k10] = k
                end
            end
        end
        return _G.HTPS_BASE5_MAP_CACHE[hk] or hk
    end

    local function htpsCloseStarUpgradePopups()
        pcall(function()
            if not _G.HTPS_STAR_UPGRADE_RUNNING then return end
            for _, pName in ipairs({"PopupHeroAwakenResult(Clone)", "PopupShowBonusEffect(Clone)", "PopupShowBonusEffect2(Clone)"}) do
                local go = GO.Find(pName)
                if go and not go:Equals(nil) then
                    go:SetActive(false)
                    UG.Object.DestroyImmediate(go)
                end
            end
        end)
    end

    local function htpsSendBatchUseItems(batchItems)
        if not batchItems or #batchItems == 0 then return false end
        local gc = CS.GameContext.GetIntance()
        local nc = CS.NetworkController.GetInstance()
        if not gc or not nc then return false end
        local req = CS.pbdson.RequestData()
        req.session = gc.m_Session
        for _, item in ipairs(batchItems) do
            local cv = CS.pbdson.CommonVector()
            cv.aLong:Add(item.itemType)
            cv.aLong:Add(item.itemKey)
            cv.aLong:Add(item.count)
            local act = CS.pbdson.PbAction()
            act.actionId = 254
            act.data = _G.HTPS_SerializeProto(cv)
            req.actions:Add(act)
        end
        local url = nc.m_UrlGameServer .. "/i/254/" .. tostring(gc.m_UserId)
        local data, ok = _G.HTPS_PutWebRequest(url, _G.HTPS_SerializeProto(req), 8)
        if ok and data then
            local resp = _G.HTPS_DeserializeProto(data, "pbdson.ResponseData,PbMethodLib")
            if resp and resp.aAction then
                for i = 0, resp.aAction.Count - 1 do
                    local a = resp.aAction[i]
                    if a.actionId == 254 and a.data then
                        local rcv = _G.HTPS_DeserializeProto(a.data, "pbdson.CommonVector,PbMethodLib")
                        if rcv and rcv.aLong then
                            CS.BonusModel.ParseBonusReceived(rcv.aLong, true)
                        end
                    end
                end
                return true
            end
        end
        return false
    end

    _G.HTPS_MaxHeroLevelAndTier = function(hm, showToast)
        if not hm or hm:Equals(nil) then return false end
        local heroId = tonumber(hm.m_HeroId) or 0
        if heroId <= 0 then return false end
        local star = tonumber(hm.m_Star) or 5
        local curLv = tonumber(hm.m_Level) or 1
        local curTier = tonumber(hm:GetTier()) or 0
        local maxTier = tonumber(hm.m_MaxTier) or (star >= 6 and 6 or 5)
        local targetMaxLv = HTPS_STAR_MAX_LV[star] or tonumber(hm.m_MaxLevel) or curLv

        if curLv >= targetMaxLv and curTier >= maxTier then
            if showToast then
                CS.Toast.ShowToast(string.format("Tướng đã đạt cấp tối đa (%d/%d)!", curLv, targetMaxLv))
            end
            return true
        end

        local gc = CS.GameContext.GetIntance()
        local nc = CS.NetworkController.GetInstance()
        if not gc or not nc then return false end
        local qr = nc:GetType():GetField("m_LstQueuedReceiveAction", 60):GetValue(nc)

        local req = CS.pbdson.RequestData()
        req.session = gc.m_Session
        local function addAct(aid, vals)
            local cv = CS.pbdson.CommonVector()
            for _, v in ipairs(vals) do cv.aLong:Add(v) end
            local act = CS.pbdson.PbAction()
            act.actionId = aid
            act.data = _G.HTPS_SerializeProto(cv)
            req.actions:Add(act)
        end

        local simLv = curLv
        local simTier = curTier
        local actionCount = 0

        while simTier < maxTier do
            local tCap = HTPS_TIER_MAX_LV[simTier] or targetMaxLv
            if tCap > targetMaxLv then tCap = targetMaxLv end
            if simLv < tCap then
                addAct(470, {heroId, tCap - simLv})
                simLv = tCap
                actionCount = actionCount + 1
            end
            addAct(205, {heroId})
            simTier = simTier + 1
            actionCount = actionCount + 1
        end

        if simLv < targetMaxLv then
            addAct(470, {heroId, targetMaxLv - simLv})
            simLv = targetMaxLv
            actionCount = actionCount + 1
        end

        if actionCount == 0 then
            return true
        end

        addAct(207, {heroId})
        local firstAid = req.actions[0].actionId
        local url = nc.m_UrlGameServer .. "/i/" .. tostring(firstAid) .. "/" .. tostring(gc.m_UserId)
        local data, ok = _G.HTPS_PutWebRequest(url, _G.HTPS_SerializeProto(req), 8)
        if ok and data then
            local resp = _G.HTPS_DeserializeProto(data, "pbdson.ResponseData,PbMethodLib")
            if resp and resp.aAction and qr then
                for i = 0, resp.aAction.Count - 1 do
                    qr:Add(resp.aAction[i])
                end
            end
        end

        coroutine.yield(nil)
        coroutine.yield(nil)

        pcall(function()
            local phi = _G.HTPS_FindObjectOfType(typeof(CS.PanelHeroInfo))
            if phi and not phi:Equals(nil) and phi.gameObject.activeInHierarchy then
                local inv = CS.PlayerInventory.GetInstance()
                local updatedHm = inv and inv:GetHeroModelById(heroId) or hm
                if updatedHm then
                    phi:GetType():GetField("currentHeroModel", 60):SetValue(phi, updatedHm)
                    local pp = phi:GetType():GetField("m_PanelHeroPoint", 60):GetValue(phi)
                    if pp and pp.gameObject.activeSelf then
                        pp:SetHeroModel(updatedHm)
                    end
                    local pa = phi:GetType():GetField("m_PanelHeroAwaken", 60):GetValue(phi)
                    if pa and pa.gameObject.activeSelf then
                        pa:SetHeroModel(updatedHm)
                    end
                    local pb = phi:GetType():GetField("m_PanelHeroBreakthrough", 60):GetValue(phi)
                    if pb and pb.gameObject.activeSelf then
                        pb:SetHeroModel(updatedHm)
                    end
                    local pe = phi:GetType():GetField("m_PanelHeroEnable", 60):GetValue(phi)
                    if pe and pe.gameObject.activeSelf then
                        pe:SetHeroModel(updatedHm)
                    end
                end
            end
        end)

        if showToast then
            local inv = CS.PlayerInventory.GetInstance()
            local updatedHm = inv and inv:GetHeroModelById(heroId) or hm
            CS.Toast.ShowToast(string.format("Đã nâng tối đa: Cấp %d/%d (Bậc %d/%d)!",
                tonumber(updatedHm.m_Level) or simLv, tonumber(updatedHm.m_MaxLevel) or targetMaxLv,
                tonumber(updatedHm:GetTier()) or simTier, tonumber(updatedHm.m_MaxTier) or maxTier))
        end
        return true
    end

    _G.HTPS_PrepareAndFillStarMaterials = function(curHm, panel)
        if not curHm or not panel then
            return false, "Không tìm thấy bảng nguyên liệu nâng sao!", {}
        end
        local inv = CS.PlayerInventory.GetInstance()
        local db = CS.DbManager.GetInstance()
        local lstH = inv:GetType():GetField("m_LstHeroModel", 60):GetValue(inv)
        local lstS = inv:GetType():GetField("m_LstItemShard", 60):GetValue(inv)
        local lstSlots = panel:GetType():GetField("m_LstHeroMaterialSlot", 60):GetValue(panel)
        if not lstSlots then
            return false, "Không tìm thấy ô nguyên liệu!", {}
        end

        local curHeroId = tonumber(curHm.m_HeroId) or 0
        local curHeroName = tostring(curHm.m_HeroName or "")
        local targetK5 = htpsResolveBase5Key(curHm.m_HeroKey)
        local curFac = htpsEnumToInt(curHm.m_Faction)

        -- Also check if any slot explicitly specifies keyReq > 0 (5★ base key)
        for i = 0, lstSlots.Count - 1 do
            local sl = lstSlots[i]
            if sl and sl.gameObject.activeSelf then
                local kReq = tonumber(sl:GetType():GetField("m_HeroKeyRequire", 60):GetValue(sl)) or -1
                local hmReq = sl:GetType():GetField("m_HeroModelRequire", 60):GetValue(sl)
                if kReq > 0 and hmReq and tonumber(hmReq.m_Star) == 5 then
                    targetK5 = kReq
                end
            end
        end

        local usedIds = {[curHeroId] = true}
        local allSelectedIds = {}

        for i = 0, lstSlots.Count - 1 do
            local sl = lstSlots[i]
            if sl and sl.gameObject.activeSelf then
                local slT = sl:GetType()
                local numReq = tonumber(slT:GetField("m_NumHeroRequire", 60):GetValue(sl)) or 0
                local keyReq = tonumber(slT:GetField("m_HeroKeyRequire", 60):GetValue(sl)) or -1
                local hmReq = slT:GetField("m_HeroModelRequire", 60):GetValue(sl)
                local starReq = (hmReq and tonumber(hmReq.m_Star)) or 5
                local facReq = (hmReq and htpsEnumToInt(hmReq.m_Faction)) or 0
                if facReq == 0 and starReq <= 6 and keyReq == -1 then
                    facReq = curFac
                end

                if numReq > 0 then
                    if keyReq > 0 then
                        -- CASE 1: Cần bản sao tướng cụ thể (VD: bản sao 5★ của tướng đang nâng)
                        local function collectSpecificCopies()
                            local cands = {}
                            for j = 0, lstH.Count - 1 do
                                local h = lstH[j]
                                if h and not usedIds[h.m_HeroId] and not h:IsHeroLock()
                                    and tonumber(h.m_HeroKey) == keyReq and tonumber(h.m_Star) == starReq then
                                    table.insert(cands, h)
                                end
                            end
                            table.sort(cands, function(a, b)
                                local la, lb = tonumber(a.m_Level) or 1, tonumber(b.m_Level) or 1
                                if la ~= lb then return la < lb end
                                return (tonumber(a.m_HeroId) or 0) < (tonumber(b.m_HeroId) or 0)
                            end)
                            return cands
                        end

                        local cands = collectSpecificCopies()
                        if #cands < numReq then
                            local deficit = numReq - #cands
                            local sh = inv:GetShard(keyReq)
                            local shardPerHero = (starReq == 5 and 50) or (starReq == 4 and 30) or 20
                            if sh and tonumber(sh.m_Number) and tonumber(sh.m_Number) >= shardPerHero then
                                local canOpen = math.floor(tonumber(sh.m_Number) / shardPerHero)
                                local toOpen = math.min(deficit, canOpen)
                                if toOpen > 0 then
                                    htpsSendBatchUseItems({{itemType = 2, itemKey = sh.m_ItemKey, count = toOpen}})
                                    cands = collectSpecificCopies()
                                end
                            end
                        end

                        if #cands < numReq then
                            local deficit = numReq - #cands
                            if deficit > 0 and _G.HTPS_OpenHeroFromSelectorChest then
                                local opened = _G.HTPS_OpenHeroFromSelectorChest(keyReq, deficit)
                                if opened > 0 then
                                    cands = collectSpecificCopies()
                                end
                            end
                        end

                        if #cands < numReq then
                            local hmDb = db and db:GetHeroModel(keyReq)
                            local hName = (hmDb and tostring(hmDb.m_HeroName)) or curHeroName
                            return false, string.format("Thiếu %d bản sao %s (%d★)!", numReq - #cands, hName, starReq), {}
                        end

                        local pickedList = CS.System.Collections.Generic.List(typeof(CS.HeroModel))()
                        for k = 1, numReq do
                            local chosen = cands[k]
                            pickedList:Add(chosen)
                            usedIds[chosen.m_HeroId] = true
                            table.insert(allSelectedIds, chosen.m_HeroId)
                        end
                        sl:OnListHeroesSelected(pickedList)

                    elseif starReq == 6 or starReq == 9 or starReq == 10 then
                        -- CASE 2: Cần Lính Chì 6★ (cùng hệ), 9★ (bất kỳ hệ) hoặc 10★ (bất kỳ hệ)
                        local function isPuppetOfStar(h, sReq, fReq)
                            if not h or usedIds[h.m_HeroId] or h:IsHeroLock() then return false end
                            if tonumber(h.m_Star) ~= sReq then return false end
                            if fReq > 0 and htpsEnumToInt(h.m_Faction) ~= fReq then return false end
                            local hk = tonumber(h.m_HeroKey) or 0
                            if sReq == 6 and hk >= 348 and hk <= 353 then return true end
                            if sReq == 9 and hk >= 310 and hk <= 315 then return true end
                            if sReq == 10 and hk >= 322 and hk <= 327 then return true end
                            if CS.HeroModel.IsPuppetHero(hk) then return true end
                            if tostring(h.m_HeroName or ""):lower():find("lính chì") then return true end
                            return false
                        end

                        local function collectPuppets()
                            local cands = {}
                            for j = 0, lstH.Count - 1 do
                                local h = lstH[j]
                                if isPuppetOfStar(h, starReq, facReq) then
                                    table.insert(cands, h)
                                end
                            end
                            return cands
                        end

                        local cands = collectPuppets()
                        if #cands < numReq then
                            local deficit = numReq - #cands
                            local batchOpen = {}

                            -- Ưu tiên mảnh lính chì trong túi mảnh nếu có
                            if starReq == 6 and facReq > 0 then
                                local pKey = HTPS_PUPPET_6_BY_FAC[facReq]
                                local sh = pKey and inv:GetShard(pKey)
                                if sh and tonumber(sh.m_Number) and tonumber(sh.m_Number) >= 50 then
                                    local take = math.min(deficit, math.floor(tonumber(sh.m_Number) / 50))
                                    if take > 0 then
                                        table.insert(batchOpen, {itemType = 2, itemKey = sh.m_ItemKey, count = take})
                                        deficit = deficit - take
                                    end
                                end
                            elseif starReq == 9 or starReq == 10 then
                                local kStart = (starReq == 9) and 310 or 322
                                local kEnd = (starReq == 9) and 315 or 327
                                for pk = kStart, kEnd do
                                    if deficit <= 0 then break end
                                    local sh = inv:GetShard(pk)
                                    if sh and tonumber(sh.m_Number) and tonumber(sh.m_Number) >= 50 then
                                        local take = math.min(deficit, math.floor(tonumber(sh.m_Number) / 50))
                                        if take > 0 then
                                            table.insert(batchOpen, {itemType = 2, itemKey = sh.m_ItemKey, count = take})
                                            deficit = deficit - take
                                        end
                                    end
                                end
                            end

                            -- Mở Rương Lính Chì trong túi vật phẩm vừa đủ số lượng thiếu
                            if deficit > 0 then
                                local chestKey = (starReq == 6 and 2069) or (starReq == 9 and 10027) or (starReq == 10 and 2070) or 0
                                if chestKey > 0 then
                                    local haveChest = tonumber(inv:CountItemConsumable(chestKey)) or 0
                                    if haveChest > 0 then
                                        local take = math.min(deficit, haveChest)
                                        table.insert(batchOpen, {itemType = 1, itemKey = chestKey, count = take})
                                        deficit = deficit - take
                                    end
                                end
                            end

                            if #batchOpen > 0 then
                                htpsSendBatchUseItems(batchOpen)
                                cands = collectPuppets()
                            end
                        end

                        if #cands < numReq then
                            return false, string.format("Thiếu %d Lính Chì %d★!", numReq - #cands, starReq), {}
                        end

                        local pickedList = CS.System.Collections.Generic.List(typeof(CS.HeroModel))()
                        for k = 1, numReq do
                            local chosen = cands[k]
                            pickedList:Add(chosen)
                            usedIds[chosen.m_HeroId] = true
                            table.insert(allSelectedIds, chosen.m_HeroId)
                        end
                        sl:OnListHeroesSelected(pickedList)

                    else
                        -- CASE 3: Cần Tướng Phôi 5★ (hoặc 4★) cùng hệ — tuyệt đối KHÔNG chọn tướng đang nâng hoặc tướng xịn
                        local function getFodderPriority(h)
                            if not h or usedIds[h.m_HeroId] or h:IsHeroLock() then return nil end
                            if tonumber(h.m_Star) ~= starReq then return nil end
                            if facReq > 0 and htpsEnumToInt(h.m_Faction) ~= facReq then return nil end
                            if (tonumber(h.m_Level) or 1) > 1 then return nil end
                            local hk = tonumber(h.m_HeroKey) or 0
                            local base5 = htpsResolveBase5Key(hk)
                            if hk == targetK5 or base5 == targetK5 then return nil end
                            if tostring(h.m_HeroName or "") == curHeroName then return nil end

                            -- 1. Lính chì 5★ (354..359)
                            if hk >= 354 and hk <= 359 then return 1 end
                            if CS.HeroModel.IsPuppetHero(hk) or tostring(h.m_HeroName or ""):lower():find("lính chì") then return 1 end

                            -- Chỉ lấy tướng phôi cơ bản (hk <= 155), bảo vệ toàn bộ tướng mới/tướng xịn (hk > 155)
                            if starReq == 5 and hk > 155 then return nil end

                            local qual = tonumber(h.m_Quality) or 5
                            if qual <= 4 then return 2 end
                            if qual == 5 then return 3 end
                            return 4
                        end

                        local function collectFodder()
                            local cands = {}
                            for j = 0, lstH.Count - 1 do
                                local h = lstH[j]
                                local prio = getFodderPriority(h)
                                if prio then
                                    table.insert(cands, {hero = h, prio = prio, key = tonumber(h.m_HeroKey) or 999})
                                end
                            end
                            table.sort(cands, function(a, b)
                                if a.prio ~= b.prio then return a.prio < b.prio end
                                if a.key ~= b.key then return a.key < b.key end
                                return (tonumber(a.hero.m_HeroId) or 0) < (tonumber(b.hero.m_HeroId) or 0)
                            end)
                            return cands
                        end

                        local cands = collectFodder()
                        if #cands < numReq and starReq == 5 then
                            local deficit = numReq - #cands

                            -- Bước 3A: Kiểm tra mảnh Lính Chì 5★ cùng hệ nếu có
                            local p5Key = HTPS_PUPPET_5_BY_FAC[facReq]
                            if p5Key and deficit > 0 then
                                local shP5 = inv:GetShard(p5Key)
                                if shP5 and tonumber(shP5.m_Number) and tonumber(shP5.m_Number) >= 50 then
                                    local take = math.min(deficit, math.floor(tonumber(shP5.m_Number) / 50))
                                    if take > 0 then
                                        htpsSendBatchUseItems({{itemType = 2, itemKey = shP5.m_ItemKey, count = take}})
                                        cands = collectFodder()
                                        deficit = numReq - #cands
                                    end
                                end
                            end

                            -- Bước 3B: Mở mảnh 5★ ngẫu nhiên đúng hệ (30001..30006) vừa đủ số lượng thiếu
                            local randShardKey = HTPS_RAND_5_SHARD_BY_FAC[facReq]
                            if randShardKey and deficit > 0 then
                                local shRand = inv:GetShard(randShardKey)
                                if shRand and tonumber(shRand.m_Number) and tonumber(shRand.m_Number) >= 50 then
                                    local take = math.min(deficit, math.floor(tonumber(shRand.m_Number) / 50))
                                    if take > 0 then
                                        htpsSendBatchUseItems({{itemType = 2, itemKey = shRand.m_ItemKey, count = take}})
                                        cands = collectFodder()
                                        deficit = numReq - #cands
                                    end
                                end
                            end

                            -- Bước 3C: Nếu vẫn thiếu (hoặc hệ Quang/Ám không có mảnh ngẫu nhiên hệ), mở mảnh tướng phôi 5★ cụ thể đúng hệ (hk <= 155, khác tướng đang nâng)
                            if deficit > 0 and lstS then
                                local shardCands = {}
                                for sIdx = 0, lstS.Count - 1 do
                                    local s = lstS[sIdx]
                                    if s and tonumber(s.m_Star) == 5 and (tonumber(s.m_Number) or 0) >= 50 then
                                        local shk = tonumber(s.m_HeroKey) or 0
                                        if shk > 0 and shk <= 155 and shk ~= targetK5 and htpsResolveBase5Key(shk) ~= targetK5 then
                                            local hmDb = db and db:GetHeroModel(shk)
                                            if hmDb and htpsEnumToInt(hmDb.m_Faction) == facReq and tostring(hmDb.m_HeroName or "") ~= curHeroName then
                                                local qual = tonumber(hmDb.m_Quality) or 5
                                                table.insert(shardCands, {
                                                    itemKey = s.m_ItemKey,
                                                    avail = math.floor((tonumber(s.m_Number) or 0) / 50),
                                                    qual = qual,
                                                    num = tonumber(s.m_Number) or 0,
                                                    hk = shk
                                                })
                                            end
                                        end
                                    end
                                end
                                table.sort(shardCands, function(a, b)
                                    if a.qual ~= b.qual then return a.qual < b.qual end
                                    if a.num ~= b.num then return a.num > b.num end
                                    return a.hk < b.hk
                                end)

                                local batchShards = {}
                                for _, sc in ipairs(shardCands) do
                                    if deficit <= 0 then break end
                                    local take = math.min(deficit, sc.avail)
                                    if take > 0 then
                                        table.insert(batchShards, {itemType = 2, itemKey = sc.itemKey, count = take})
                                        deficit = deficit - take
                                    end
                                end
                                if #batchShards > 0 then
                                    htpsSendBatchUseItems(batchShards)
                                    cands = collectFodder()
                                end
                            end
                        end

                        if #cands < numReq then
                            return false, string.format("Thiếu %d tướng phôi %d★ cùng hệ!", numReq - #cands, starReq), {}
                        end

                        local pickedList = CS.System.Collections.Generic.List(typeof(CS.HeroModel))()
                        for k = 1, numReq do
                            local chosen = cands[k].hero
                            pickedList:Add(chosen)
                            usedIds[chosen.m_HeroId] = true
                            table.insert(allSelectedIds, chosen.m_HeroId)
                        end
                        sl:OnListHeroesSelected(pickedList)
                    end
                end
            end
        end

        return true, "OK", allSelectedIds
    end

    _G.HTPS_DoOneStarUpgradeStep = function(phi)
        if not phi or phi:Equals(nil) or not phi.gameObject.activeInHierarchy then
            return false, "Bảng tướng đã đóng!"
        end
        local curHm = phi:GetType():GetField("currentHeroModel", 60):GetValue(phi)
        if not curHm or curHm:Equals(nil) then
            return false, "Không tìm thấy thông tin tướng!"
        end

        local oldStar = tonumber(curHm.m_Star) or 5
        if oldStar >= 15 then
            _G.HTPS_MaxHeroLevelAndTier(curHm, false)
            return false, "Tướng đã đạt tối đa 15★ (E5)!"
        end

        -- 1. Lên cấp & bậc tối đa của sao hiện tại trước khi thức tỉnh
        _G.HTPS_MaxHeroLevelAndTier(curHm, false)
        curHm = phi:GetType():GetField("currentHeroModel", 60):GetValue(phi)

        -- 2. Chuyển sang đúng Tab nâng sao tương ứng với số sao hiện tại
        local targetTab = (oldStar <= 5 and 3) or (oldStar < 10 and 2) or 4
        local curTab = tonumber(phi:GetType():GetField("m_CurrentTabActive", 60):GetValue(phi)) or 1
        if curTab ~= targetTab then
            phi:OnTabActive(targetTab, targetTab)
            coroutine.yield(nil)
        end

        local panelField = (targetTab == 3 and "m_PanelHeroBreakthrough")
            or (targetTab == 2 and "m_PanelHeroAwaken")
            or "m_PanelHeroEnable"
        local panel = phi:GetType():GetField(panelField, 60):GetValue(phi)
        if not panel or panel:Equals(nil) then
            return false, "Không mở được bảng nâng sao!"
        end

        -- Đảm bảo BoxEnable hiển thị nếu đang ở Tab 4 (tránh bị PanelEpSao che)
        if targetTab == 4 then
            pcall(function()
                local boxEnable = panel.transform:Find("BoxEnable")
                if boxEnable and not boxEnable.gameObject.activeSelf then
                    boxEnable.gameObject:SetActive(true)
                end
                local epGo = panel.transform:Find("PanelEpSao(Clone)")
                if epGo and epGo.gameObject.activeSelf then
                    epGo.gameObject:SetActive(false)
                end
            end)
        end

        panel:SetHeroModel(curHm)
        coroutine.yield(nil)

        -- 3. Chuẩn bị & điền nguyên liệu (tự mở Lính Chì / Phôi vừa đủ trong túi nếu thiếu)
        local okPrep, msgPrep, usedIds = _G.HTPS_PrepareAndFillStarMaterials(curHm, panel)
        if not okPrep then
            return false, msgPrep
        end
        coroutine.yield(nil)

        -- 4. Thực hiện nâng sao
        local targetStar = oldStar + 1
        if targetTab == 3 then
            panel:ButtonBreakthroughClick()
        else
            panel:ButtonAwakenClick()
        end

        local t0 = UG.Time.realtimeSinceStartup
        while UG.Time.realtimeSinceStartup - t0 < 3.0 do
            htpsCloseStarUpgradePopups()
            coroutine.yield(nil)
            local ch = phi:GetType():GetField("currentHeroModel", 60):GetValue(phi)
            if ch and (tonumber(ch.m_Star) or 0) >= targetStar then
                break
            end
        end
        coroutine.yield(UG.WaitForSeconds(0.1))
        htpsCloseStarUpgradePopups()

        local newHm = phi:GetType():GetField("currentHeroModel", 60):GetValue(phi)
        if not newHm or (tonumber(newHm.m_Star) or 0) < targetStar then
            return false, "Nâng sao không thành công (kiểm tra đá tím hoặc nguyên liệu)!"
        end

        -- Xóa triệt để các tướng nguyên liệu đã tiêu hao khỏi PlayerInventory (sửa lỗi C# xóa sót khi đổi tab)
        local inv = CS.PlayerInventory.GetInstance()
        if inv and usedIds then
            for _, uid in ipairs(usedIds) do
                pcall(function() inv:RemoveHeroModel(uid) end)
            end
        end

        -- 5. Tự động nâng Bậc & Cấp tối đa ngay khi lên thêm 1 sao
        _G.HTPS_MaxHeroLevelAndTier(newHm, false)
        newHm = phi:GetType():GetField("currentHeroModel", 60):GetValue(phi)

        -- Đồng bộ lại giao diện tab nâng sao tiếp theo
        pcall(function()
            local newStar = tonumber(newHm.m_Star) or targetStar
            local nextTab = (newStar <= 5 and 3) or (newStar < 10 and 2) or 4
            phi:OnTabActive(nextTab, nextTab)
            local nextField = (nextTab == 3 and "m_PanelHeroBreakthrough")
                or (nextTab == 2 and "m_PanelHeroAwaken")
                or "m_PanelHeroEnable"
            local nextPanel = phi:GetType():GetField(nextField, 60):GetValue(phi)
            if nextPanel and not nextPanel:Equals(nil) then
                nextPanel:SetHeroModel(newHm)
            end
        end)

        return true, string.format("Đã nâng lên %d★ (Cấp %d/%d)!",
            tonumber(newHm.m_Star) or targetStar,
            tonumber(newHm.m_Level) or 1,
            tonumber(newHm.m_MaxLevel) or (HTPS_STAR_MAX_LV[targetStar] or 100))
    end

    _G.HTPS_RunAutoStarUpgrade = function(mode)
        if _G.HTPS_STAR_UPGRADE_RUNNING then
            _G.HTPS_STAR_UPGRADE_RUNNING = false
            CS.Toast.ShowToast("Đã dừng Auto Nâng Sao.")
            return
        end

        local phi = _G.HTPS_FindObjectOfType(typeof(CS.PanelHeroInfo))
        if not phi or phi:Equals(nil) or not phi.gameObject.activeInHierarchy then
            return
        end

        _G.HTPS_STAR_UPGRADE_RUNNING = true
        CsCoroutine.start(function()
            local stepsDone = 0
            local lastMsg = ""
            local okRun, errRun = pcall(function()
                if mode == "MAX_LV_ONLY" then
                    local curHm = phi:GetType():GetField("currentHeroModel", 60):GetValue(phi)
                    _G.HTPS_MaxHeroLevelAndTier(curHm, true)
                elseif mode == "ONE" then
                    local okStep, msgStep = _G.HTPS_DoOneStarUpgradeStep(phi)
                    if okStep then
                        stepsDone = 1
                    end
                    lastMsg = msgStep or ""
                else
                    -- mode == "MAX": Nâng liên tục từng sao + max cấp mỗi sao cho tới 15★ (E5) hoặc hết nguyên liệu
                    while _G.HTPS_STAR_UPGRADE_RUNNING do
                        local curHm = phi:GetType():GetField("currentHeroModel", 60):GetValue(phi)
                        if not curHm or (tonumber(curHm.m_Star) or 0) >= 15 then
                            if curHm then _G.HTPS_MaxHeroLevelAndTier(curHm, false) end
                            lastMsg = "Tướng đã đạt tối đa 15★ (E5) & Max Cấp!"
                            break
                        end
                        local okStep, msgStep = _G.HTPS_DoOneStarUpgradeStep(phi)
                        if okStep then
                            stepsDone = stepsDone + 1
                            lastMsg = msgStep
                            coroutine.yield(UG.WaitForSeconds(0.12))
                        else
                            lastMsg = msgStep or ""
                            break
                        end
                    end
                end
            end)

            _G.HTPS_STAR_UPGRADE_RUNNING = false
            htpsCloseStarUpgradePopups()

            if not okRun then
                CS.Toast.ShowToast("⚠️ Lỗi Auto Nâng Sao: " .. tostring(errRun))
            elseif mode ~= "MAX_LV_ONLY" then
                if stepsDone > 0 then
                    CS.Toast.ShowToast(string.format("✅ Hoàn tất (+%d★): %s", stepsDone, tostring(lastMsg)))
                elseif lastMsg ~= "" then
                    CS.Toast.ShowToast(tostring(lastMsg))
                end
            end
        end)
    end

    _G.HTPS_EnsureHeroStarUpgradeButtons = function()
        pcall(function()
            local phi = _G.HTPS_FindObjectOfType(typeof(CS.PanelHeroInfo))
            if not phi or phi:Equals(nil) or not phi.gameObject.activeInHierarchy then
                return
            end
            if _G.HTPS_IS_PREVIEW_HERO_INFO then
                return
            end

            local curHm = phi:GetType():GetField("currentHeroModel", 60):GetValue(phi)
            local curStar = (curHm and tonumber(curHm.m_Star)) or 5
            local curLv = (curHm and tonumber(curHm.m_Level)) or 1
            local targetMaxLv = HTPS_STAR_MAX_LV[curStar] or (curHm and tonumber(curHm.m_MaxLevel)) or 100

            -- Tìm nút mẫu (ButtonAwake hoặc ButtonBreak)
            local pb = phi:GetType():GetField("m_PanelHeroBreakthrough", 60):GetValue(phi)
            local pa = phi:GetType():GetField("m_PanelHeroAwaken", 60):GetValue(phi)
            local pe = phi:GetType():GetField("m_PanelHeroEnable", 60):GetValue(phi)
            local pp = phi:GetType():GetField("m_PanelHeroPoint", 60):GetValue(phi)

            local tmplBtn = nil
            if pb then
                local b = pb.transform:Find("ButtonBreak")
                if b then tmplBtn = b.gameObject end
            end
            if not tmplBtn and pa then
                local b = pa.transform:Find("BoxAwaken/GroupAction/ButtonAwake")
                if b then tmplBtn = b.gameObject end
            end
            if not tmplBtn then return end

            local function ensureStarBtn(parentTf, btnName, posX, posY, sizeX, sizeY, labelTxt, fontSize, clickMode)
                if not parentTf or parentTf:Equals(nil) then return nil end
                local existing = parentTf:Find(btnName)
                local btnGo = existing and existing.gameObject or nil
                if not btnGo then
                    btnGo = UG.Object.Instantiate(tmplBtn, parentTf, false)
                    btnGo.name = btnName
                    local rt = btnGo:GetComponent(typeof(UG.RectTransform))
                    if rt then
                        rt.anchorMin = UG.Vector2(0.5, 0.5)
                        rt.anchorMax = UG.Vector2(0.5, 0.5)
                        rt.pivot = UG.Vector2(0.5, 0.5)
                        rt.anchoredPosition = UG.Vector2(posX, posY)
                        rt.sizeDelta = UG.Vector2(sizeX, sizeY)
                    end
                    local txt = btnGo:GetComponentInChildren(typeof(UG.UI.Text), true)
                    if txt then
                        local loc = txt.gameObject:GetComponent(typeof(CS.I2.Loc.Localize))
                        if loc then UG.Object.DestroyImmediate(loc) end
                        txt.fontSize = fontSize or 18
                    end
                    local bc = btnGo:GetComponent(typeof(UG.UI.Button))
                    if bc then
                        bc.onClick = UG.UI.Button.ButtonClickedEvent()
                        bc.onClick:AddListener(function()
                            _G.HTPS_RunAutoStarUpgrade(clickMode)
                        end)
                    end
                end
                if btnGo then
                    local showBtn = (clickMode == "MAX_LV_ONLY" and curLv < targetMaxLv) or (clickMode ~= "MAX_LV_ONLY" and curStar < 15)
                    btnGo:SetActive(showBtn)
                    local txt = btnGo:GetComponentInChildren(typeof(UG.UI.Text), true)
                    if txt then
                        txt.text = _G.HTPS_STAR_UPGRADE_RUNNING and "Dừng Auto" or labelTxt
                    end
                end
                return btnGo
            end

            -- 1. Trên PanelBreakthrough (5★ -> 6★)
            if pb and pb.gameObject.activeInHierarchy then
                ensureStarBtn(pb.transform, "BtnHTPSAutoStarOne", -152.0, -213.0, 132.0, 54.0, "Auto +1★", 18, "ONE")
                ensureStarBtn(pb.transform, "BtnHTPSAutoStarMax", 152.0, -213.0, 132.0, 54.0, "Auto Max★", 18, "MAX")
            end

            -- 2. Trên PanelAwaken/BoxAwaken (6★ -> 10★)
            if pa and pa.gameObject.activeInHierarchy then
                local boxAwk = pa.transform:Find("BoxAwaken")
                if boxAwk and boxAwk.gameObject.activeInHierarchy then
                    ensureStarBtn(boxAwk, "BtnHTPSAutoStarOne", -152.0, -226.0, 132.0, 54.0, "Auto +1★", 18, "ONE")
                    ensureStarBtn(boxAwk, "BtnHTPSAutoStarMax", 152.0, -226.0, 132.0, 54.0, "Auto Max★", 18, "MAX")
                end
            end

            -- 3. Trên PanelEnable/BoxEnable (10★ -> 15★ E5)
            if pe and pe.gameObject.activeInHierarchy then
                local boxEn = pe.transform:Find("BoxEnable")
                if boxEn and boxEn.gameObject.activeInHierarchy then
                    ensureStarBtn(boxEn, "BtnHTPSAutoStarOne", -152.0, -226.0, 132.0, 54.0, "Auto +1★", 18, "ONE")
                    ensureStarBtn(boxEn, "BtnHTPSAutoStarMax", 152.0, -226.0, 132.0, 54.0, "Auto Max★", 18, "MAX")
                end
            end

            -- 4. Trên PanelPoint (Tab 1): Nút "Auto +1★" và "Max Cấp" tiện lợi ngay tại Tab Thông Số
            if pp and pp.gameObject.activeInHierarchy then
                ensureStarBtn(pp.transform, "BtnHTPSPointStarOne", 35.0, 184.0, 94.0, 42.0, "Auto +1★", 16, "ONE")
                ensureStarBtn(pp.transform, "BtnHTPSPointMaxLv", 190.0, 184.0, 86.0, 42.0, "Max Cấp", 16, "MAX_LV_ONLY")
            end

            -- 5. Trên PanelSpecialEquip (Tab Trang Bị Đặc Thù): Nút "Auto Nâng 250" & "Hoàn Trả Lv1"
            local pse = _G.HTPS_FindObjectOfType(typeof(CS.PanelSpecialEquip))
            if pse and not pse:Equals(nil) and pse.gameObject.activeInHierarchy then
                local bgrTf = pse.transform:Find("Bgr") or pse.transform
                local eq = curHm and curHm.epicEquipment
                local atkLv = (eq and tonumber(eq.attackLevel)) or 0
                local hpLv = (eq and tonumber(eq.hpLevel)) or 0
                local atkTier = (eq and tonumber(eq.attackTier)) or 1
                local hpTier = (eq and tonumber(eq.hpTier)) or 1

                local function ensureSpecialBtn(btnName, posX, posY, sizeX, sizeY, labelTxt, onClickFn, visible)
                    local existing = bgrTf:Find(btnName)
                    local btnGo = existing and existing.gameObject or nil
                    if not btnGo then
                        btnGo = UG.Object.Instantiate(tmplBtn, bgrTf, false)
                        btnGo.name = btnName
                        local rt = btnGo:GetComponent(typeof(UG.RectTransform))
                        if rt then
                            rt.anchorMin = UG.Vector2(0.5, 0.5)
                            rt.anchorMax = UG.Vector2(0.5, 0.5)
                            rt.pivot = UG.Vector2(0.5, 0.5)
                            rt.anchoredPosition = UG.Vector2(posX, posY)
                            rt.sizeDelta = UG.Vector2(sizeX, sizeY)
                        end
                        local txt = btnGo:GetComponentInChildren(typeof(UG.UI.Text), true)
                        if txt then
                            local loc = txt.gameObject:GetComponent(typeof(CS.I2.Loc.Localize))
                            if loc then UG.Object.DestroyImmediate(loc) end
                            txt.fontSize = 16
                        end
                        local bc = btnGo:GetComponent(typeof(UG.UI.Button))
                        if bc then
                            bc.onClick = UG.UI.Button.ButtonClickedEvent()
                            bc.onClick:AddListener(onClickFn)
                        end
                    end
                    if btnGo then
                        btnGo:SetActive(visible)
                        local txt = btnGo:GetComponentInChildren(typeof(UG.UI.Text), true)
                        if txt then txt.text = labelTxt end
                    end
                end

                local isMax300 = (atkLv >= 300 and hpLv >= 300 and atkTier >= 16 and hpTier >= 16)
                local upgLabel = _G.HTPS_SPECIAL_AUTO_RUNNING and "Dừng Auto" or ((atkLv < 250 or hpLv < 250 or atkTier < 15 or hpTier < 15) and "Auto Nâng 250" or "Auto Max 300")
                ensureSpecialBtn("BtnHTPSSpecialAuto250", -101.0, -242.0, 168.0, 46.0, upgLabel, function()
                    _G.HTPS_RunAutoUpgradeSpecialEquip()
                end, not isMax300 or _G.HTPS_SPECIAL_AUTO_RUNNING)

                local hasResetLv = (atkLv > 0 or hpLv > 0 or atkTier > 1 or hpTier > 1)
                local resetLabel = hasResetLv and "Hoàn Trả Lv1" or "Hoàn Trả (Lv0)"
                ensureSpecialBtn("BtnHTPSSpecialReset", 101.0, -242.0, 168.0, 46.0, resetLabel, function()
                    _G.HTPS_RunResetSpecialEquip()
                end, true)
            end
        end)
    end

    _G.HTPS_GetActiveSpecialEquipHero = function(pse)
        local hm = nil
        pcall(function()
            local phi = _G.HTPS_FindObjectOfType(typeof(CS.PanelHeroInfo))
            if phi and not phi:Equals(nil) and phi.gameObject.activeInHierarchy then
                hm = phi:GetType():GetField("currentHeroModel", 60):GetValue(phi)
            end
            if not hm then
                local popGo = CS.UnityEngine.GameObject.Find("PopupSpecialEquipUpgrade(Clone)")
                if popGo and popGo.activeInHierarchy then
                    local pop = popGo:GetComponent(typeof(CS.PopupSpecialEquipUpgrade))
                    if pop then
                        hm = pop:GetType():GetField("model", 60):GetValue(pop)
                    end
                end
            end
            if not hm and pse and not pse:Equals(nil) then
                hm = pse:GetType():GetField("heroModel", 60):GetValue(pse)
            end
        end)
        return hm
    end

    _G.HTPS_ApplySpecialEquip267 = function(hm, pse, actData)
        pcall(function()
            if not hm or not hm.epicEquipment or not actData then return end
            local lcv = _G.HTPS_DeserializeProto(actData, "pbdson.ListCommonVector,PbMethodLib")
            if lcv and lcv.aVector and lcv.aVector.Count >= 9 then
                local eq = hm.epicEquipment
                local v0 = lcv.aVector[0].aLong
                eq:SetCurrentData(v0[0], v0[1], v0[2], v0[3], v0[4], v0[5], v0[6], v0[7])
                eq:SetNextData(v0[8], v0[9], v0[10], v0[11])
                eq:SetFee(lcv.aVector[3].aLong, lcv.aVector[2].aLong, lcv.aVector[6].aLong, lcv.aVector[4].aLong, lcv.aVector[1].aLong, lcv.aVector[5].aLong)
                local v7 = lcv.aVector[7].aLong
                eq:SetNoti(v7[0] == 1, v7[1] == 1, v7[3] == 1, v7[2] == 1)
                local v8 = lcv.aVector[8].aLong
                eq:SetMaxLevel(tonumber(v8[0]) or 300, tonumber(v8[1]) or 16)
                eq:SetLock(false)
                if pse and not pse:Equals(nil) then
                    pcall(function() pse:GetType():GetField("heroModel", 60):SetValue(pse, hm) end)
                    pcall(function() pse:SetDataPanel(hm) end)
                    pcall(function() pse:ReLoadData() end)
                end
                local popGo = CS.UnityEngine.GameObject.Find("PopupSpecialEquipUpgrade(Clone)")
                if popGo and popGo.activeInHierarchy then
                    local pop = popGo:GetComponent(typeof(CS.PopupSpecialEquipUpgrade))
                    if pop then
                        pcall(function() pop:ReloadData() end)
                    end
                end
            end
        end)
    end

    _G.HTPS_SyncHeroSpecialFromServer = function(hm, pse)
        local gc = CS.GameContext.GetIntance()
        local csNet = CS.NetworkController.GetInstance()
        local urlServer = csNet and csNet.m_UrlGameServer or ""
        if not hm or not gc or urlServer == "" then return end
        local req267 = CS.pbdson.RequestData()
        req267.session = gc.m_Session
        local cv267 = CS.pbdson.CommonVector()
        cv267.aLong:Add(tonumber(hm.m_HeroId) or 0)
        local a267 = CS.pbdson.PbAction()
        a267.actionId = 267; a267.data = _G.HTPS_SerializeProto(cv267)
        req267.actions:Add(a267)
        local d267 = _G.HTPS_PutWebRequest(urlServer .. "/i/267/" .. tostring(gc.m_UserId), _G.HTPS_SerializeProto(req267), 8)
        if d267 then
            local r267 = _G.HTPS_DeserializeProto(d267, "pbdson.ResponseData,PbMethodLib")
            if r267 and r267.aAction then
                for i = 0, r267.aAction.Count - 1 do
                    local act = r267.aAction[i]
                    if act.actionId == 267 and act.data then
                        _G.HTPS_ApplySpecialEquip267(hm, pse, act.data)
                    end
                end
            end
        end
    end

    _G.HTPS_RunResetSpecialEquip = function()
        CsCoroutine.start(function()
            local pse = _G.HTPS_FindObjectOfType(typeof(CS.PanelSpecialEquip))
            local hm = _G.HTPS_GetActiveSpecialEquipHero(pse)
            local eq = hm and hm.epicEquipment
            if not hm or not eq then return end

            _G.HTPS_SyncHeroSpecialFromServer(hm, pse)

            local atkLv = tonumber(eq.attackLevel) or 0
            local hpLv = tonumber(eq.hpLevel) or 0
            local atkTier = tonumber(eq.attackTier) or 1
            local hpTier = tonumber(eq.hpTier) or 1
            if atkLv <= 0 and hpLv <= 0 and atkTier <= 1 and hpTier <= 1 then
                CS.Toast.ShowToast("⚠️ Trang Bị Đặc Thù của [" .. tostring(hm.m_HeroName) .. "] đã ở Cấp 0 (0 Đá nâng đồ)!")
                return
            end

            local heroId = tonumber(hm.m_HeroId) or 0
            local gc = CS.GameContext.GetIntance()
            local inv = CS.PlayerInventory.GetInstance()
            local csNet = CS.NetworkController.GetInstance()
            local urlServer = csNet and csNet.m_UrlGameServer or ""
            if not gc or not inv or urlServer == "" then return end

            local beforeGold = tonumber(gc.m_Gold) or 0
            local beforeStone = tonumber(inv:GetNumberItemConsumable(2028)) or 0
            local beforeHammer = tonumber(inv:GetNumberItemConsumable(2029)) or 0

            local req = CS.pbdson.RequestData()
            req.session = gc.m_Session

            if hm.m_IsLocked == true then
                local cvHeroLock = CS.pbdson.CommonVector()
                cvHeroLock.aLong:Add(heroId); cvHeroLock.aLong:Add(0)
                local aHeroLock = CS.pbdson.PbAction()
                aHeroLock.actionId = 205
                aHeroLock.data = _G.HTPS_SerializeProto(cvHeroLock)
                req.actions:Add(aHeroLock)
                hm.m_IsLocked = false
            end

            if eq.isLock == true then
                local cvLock = CS.pbdson.CommonVector()
                cvLock.aLong:Add(heroId)
                local aLock = CS.pbdson.PbAction()
                aLock.actionId = 269
                aLock.data = _G.HTPS_SerializeProto(cvLock)
                req.actions:Add(aLock)
                eq.isLock = false
            end

            if atkLv > 0 or atkTier > 1 then
                local cv0 = CS.pbdson.CommonVector()
                cv0.aLong:Add(heroId); cv0.aLong:Add(0); cv0.aLong:Add(0)
                local a0 = CS.pbdson.PbAction()
                a0.actionId = 268; a0.data = _G.HTPS_SerializeProto(cv0)
                req.actions:Add(a0)
            end
            if hpLv > 0 or hpTier > 1 then
                local cv1 = CS.pbdson.CommonVector()
                cv1.aLong:Add(heroId); cv1.aLong:Add(1); cv1.aLong:Add(0)
                local a1 = CS.pbdson.PbAction()
                a1.actionId = 268; a1.data = _G.HTPS_SerializeProto(cv1)
                req.actions:Add(a1)
            end

            local cv267 = CS.pbdson.CommonVector()
            cv267.aLong:Add(heroId)
            local a267 = CS.pbdson.PbAction()
            a267.actionId = 267; a267.data = _G.HTPS_SerializeProto(cv267)
            req.actions:Add(a267)

            local d = _G.HTPS_PutWebRequest(urlServer .. "/i/268/" .. tostring(gc.m_UserId), _G.HTPS_SerializeProto(req), 10)
            local serverErr = nil
            local lastBm = nil
            if d then
                local r = _G.HTPS_DeserializeProto(d, "pbdson.ResponseData,PbMethodLib")
                if r and r.aAction then
                    for i = 0, r.aAction.Count - 1 do
                        local act = r.aAction[i]
                        if act.actionId == 268 and act.data then
                            local lcv = _G.HTPS_DeserializeProto(act.data, "pbdson.ListCommonVector,PbMethodLib")
                            if lcv and lcv.aVector and lcv.aVector.Count >= 9 then
                                pcall(function()
                                    lastBm = CS.BonusModel.ParseBonusReceived(lcv.aVector[8].aLong, true)
                                end)
                            end
                        elseif act.actionId == 267 and act.data then
                            _G.HTPS_ApplySpecialEquip267(hm, pse, act.data)
                        elseif act.actionId == 1 and act.data then
                            local cv = _G.HTPS_DeserializeProto(act.data, "pbdson.CommonVector,PbMethodLib")
                            if cv and cv.aString and cv.aString.Count > 0 then
                                serverErr = tostring(cv.aString[0])
                            end
                        end
                    end
                end
            end

            _G.HTPS_EnsureHeroStarUpgradeButtons()
            if serverErr then
                CS.Toast.ShowToast("⚠️ Lỗi Hoàn Trả: " .. serverErr)
            else
                local afterGold = tonumber(gc.m_Gold) or beforeGold
                local afterStone = tonumber(inv:GetNumberItemConsumable(2028)) or beforeStone
                local afterHammer = tonumber(inv:GetNumberItemConsumable(2029)) or beforeHammer
                local gainedGold = math.max(0, afterGold - beforeGold)
                local gainedStone = math.max(0, afterStone - beforeStone)
                local gainedHammer = math.max(0, afterHammer - beforeHammer)

                pcall(function()
                    local cvShow = CS.pbdson.CommonVector()
                    if gainedGold > 0 then
                        cvShow.aLong:Add(1); cvShow.aLong:Add(afterGold); cvShow.aLong:Add(gainedGold)
                    end
                    if gainedStone > 0 then
                        cvShow.aLong:Add(3); cvShow.aLong:Add(1); cvShow.aLong:Add(2028); cvShow.aLong:Add(afterStone); cvShow.aLong:Add(gainedStone)
                    end
                    if gainedHammer > 0 then
                        cvShow.aLong:Add(3); cvShow.aLong:Add(1); cvShow.aLong:Add(2029); cvShow.aLong:Add(afterHammer); cvShow.aLong:Add(gainedHammer)
                    end
                    if cvShow.aLong.Count > 0 then
                        local bmShow = CS.BonusModel.ParseBonusReceived(cvShow.aLong, false)
                        if bmShow then
                            CS.PopupShowBonusEffect.ShowUp(bmShow)
                        end
                    elseif lastBm then
                        CS.PopupShowBonusEffect.ShowUp(lastBm)
                    end
                end)

                CS.Toast.ShowToast(string.format("♻️ Đã hoàn trả [%s] về Lv0! Nhận +%d Đá nâng đồ (Tổng: %d)", tostring(hm.m_HeroName), gainedStone, afterStone))
            end
        end)
    end

    _G.HTPS_RunAutoUpgradeSpecialEquip = function()
        if _G.HTPS_SPECIAL_AUTO_RUNNING then
            _G.HTPS_SPECIAL_AUTO_RUNNING = false
            return
        end
        _G.HTPS_SPECIAL_AUTO_RUNNING = true
        CsCoroutine.start(function()
            local okRun, errRun = pcall(function()
                local pse = _G.HTPS_FindObjectOfType(typeof(CS.PanelSpecialEquip))
                local hm = _G.HTPS_GetActiveSpecialEquipHero(pse)
                local eq = hm and hm.epicEquipment
                if not hm or not eq then return end

                local heroId = tonumber(hm.m_HeroId) or 0
                local gc = CS.GameContext.GetIntance()
                local csNet = CS.NetworkController.GetInstance()
                local urlServer = csNet and csNet.m_UrlGameServer or ""
                if not gc or urlServer == "" then return end

                if eq.isLock == true then
                    local req264 = CS.pbdson.RequestData()
                    req264.session = gc.m_Session
                    local cv264 = CS.pbdson.CommonVector()
                    cv264.aLong:Add(heroId)
                    local a264 = CS.pbdson.PbAction()
                    a264.actionId = 264; a264.data = _G.HTPS_SerializeProto(cv264)
                    req264.actions:Add(a264)
                    _G.HTPS_PutWebRequest(urlServer .. "/i/264/" .. tostring(gc.m_UserId), _G.HTPS_SerializeProto(req264), 8)
                    eq:SetLock(false)
                end

                _G.HTPS_SyncHeroSpecialFromServer(hm, pse)

                local atkLv = tonumber(eq.attackLevel) or 0
                local hpLv = tonumber(eq.hpLevel) or 0
                local atkTier = tonumber(eq.attackTier) or 1
                local hpTier = tonumber(eq.hpTier) or 1

                local targetLv = (atkLv < 250 or hpLv < 250 or atkTier < 15 or hpTier < 15) and 250 or 300
                local targetTier = (targetLv == 250) and 15 or 16

                local allActions = {}
                local maxSteps = math.max(0, targetLv - atkLv, targetLv - hpLv)
                for s = 1, maxSteps do
                    if atkLv + s <= targetLv then
                        table.insert(allActions, { id = 265, t = 0 })
                    end
                    if hpLv + s <= targetLv then
                        table.insert(allActions, { id = 265, t = 1 })
                    end
                end

                local maxTierSteps = math.max(0, targetTier - atkTier, targetTier - hpTier)
                for t = 1, maxTierSteps do
                    if atkTier + t <= targetTier then
                        table.insert(allActions, { id = 266, t = 0 })
                    end
                    if hpTier + t <= targetTier then
                        table.insert(allActions, { id = 266, t = 1 })
                    end
                end

                local idx = 1
                local batchSize = 60
                local stopErr = nil
                while _G.HTPS_SPECIAL_AUTO_RUNNING and idx <= #allActions do
                    local req = CS.pbdson.RequestData()
                    req.session = gc.m_Session
                    local endIdx = math.min(#allActions, idx + batchSize - 1)
                    for k = idx, endIdx do
                        local item = allActions[k]
                        local cv = CS.pbdson.CommonVector()
                        cv.aLong:Add(heroId); cv.aLong:Add(item.t)
                        local a = CS.pbdson.PbAction()
                        a.actionId = item.id; a.data = _G.HTPS_SerializeProto(cv)
                        req.actions:Add(a)
                    end
                    idx = endIdx + 1

                    local d = _G.HTPS_PutWebRequest(urlServer .. "/i/265/" .. tostring(gc.m_UserId), _G.HTPS_SerializeProto(req), 12)
                    if d then
                        local r = _G.HTPS_DeserializeProto(d, "pbdson.ResponseData,PbMethodLib")
                        if r and r.aAction then
                            for i = 0, r.aAction.Count - 1 do
                                local act = r.aAction[i]
                                if act.actionId == 265 and act.data then
                                    local lcv = _G.HTPS_DeserializeProto(act.data, "pbdson.ListCommonVector,PbMethodLib")
                                    if lcv and lcv.aVector and lcv.aVector.Count >= 3 then
                                        pcall(function() CS.BonusModel.ParseBonusReceived(lcv.aVector[2].aLong, true) end)
                                    end
                                elseif act.actionId == 266 and act.data then
                                    local lcv = _G.HTPS_DeserializeProto(act.data, "pbdson.ListCommonVector,PbMethodLib")
                                    if lcv and lcv.aVector and lcv.aVector.Count >= 4 then
                                        pcall(function() CS.BonusModel.ParseBonusReceived(lcv.aVector[3].aLong, true) end)
                                    end
                                elseif act.actionId == 1 and act.data then
                                    local cv = _G.HTPS_DeserializeProto(act.data, "pbdson.CommonVector,PbMethodLib")
                                    if cv and cv.aString and cv.aString.Count > 0 then
                                        stopErr = tostring(cv.aString[0])
                                    end
                                end
                            end
                        end
                    else
                        break
                    end
                    if stopErr then break end
                    coroutine.yield(nil)
                end

                _G.HTPS_SyncHeroSpecialFromServer(hm, pse)
                _G.HTPS_EnsureHeroStarUpgradeButtons()
                if stopErr then
                    CS.Toast.ShowToast(string.format("⚡ [%s] đạt Công Cấp %d (Bậc %d) | Máu Cấp %d (Bậc %d) (%s)",
                        tostring(hm.m_HeroName),
                        tonumber(eq.attackLevel) or 0, tonumber(eq.attackTier) or 1,
                        tonumber(eq.hpLevel) or 0, tonumber(eq.hpTier) or 1, stopErr))
                else
                    CS.Toast.ShowToast(string.format("⚡ [%s]: Công Cấp %d (Bậc %d) | Máu Cấp %d (Bậc %d)!",
                        tostring(hm.m_HeroName),
                        tonumber(eq.attackLevel) or 0, tonumber(eq.attackTier) or 1,
                        tonumber(eq.hpLevel) or 0, tonumber(eq.hpTier) or 1))
                end
            end)
            _G.HTPS_SPECIAL_AUTO_RUNNING = false
            _G.HTPS_EnsureHeroStarUpgradeButtons()
            if not okRun then
                CS.Toast.ShowToast("⚠️ Lỗi Auto Nâng: " .. tostring(errRun))
            end
        end)
    end

    -- =========================================================================
    -- ĐÁNH BOSS BANG HỘI & BOSS LỬA TRẠI (BỎ QUA VÀO TRẬN & AUTO ĐÁNH NHANH)
    -- =========================================================================
    _G.HTPS_FormatBossDamage = function(dmg)
        local n = tonumber(dmg) or 0
        if n >= 1000000000 then
            return string.format("%.2fB", n / 1000000000.0)
        elseif n >= 1000000 then
            return string.format("%.2fM", n / 1000000.0)
        elseif n >= 1000 then
            return string.format("%.1fK", n / 1000.0)
        end
        return tostring(math.floor(n))
    end

    _G.HTPS_CalcBattleResultDamage = function(pbRes)
        local totalDmg = 0
        pcall(function()
            if not pbRes then return end
            local lbd = CS.ListBattleData.Parse(pbRes, true)
            if lbd and lbd.m_LstBattleData and lbd.m_LstBattleData.Count > 0 then
                for b = 0, lbd.m_LstBattleData.Count - 1 do
                    local bd = lbd.m_LstBattleData[b]
                    local pd = bd and bd.m_PointDetail
                    if pd then
                        local lstAtk = pd.m_LstBattlePointAttacker
                        if lstAtk then
                            for i = 0, lstAtk.Count - 1 do
                                local hpd = lstAtk[i]
                                if hpd and hpd.m_PointDamage then
                                    totalDmg = totalDmg + (tonumber(hpd.m_PointDamage) or 0)
                                end
                            end
                        end
                        local petAtk = pd.m_PetBattlePointAttacker
                        if petAtk and petAtk.m_PointDamage then
                            totalDmg = totalDmg + (tonumber(petAtk.m_PointDamage) or 0)
                        end
                    end
                end
            end
        end)
        return totalDmg
    end

    _G.HTPS_GetGuildBossLineupIds = function(isPrayBoss, explicitFormation)
        local inv = CS.PlayerInventory.GetInstance()
        local validHeroMap = {}
        local allHeroes = {}
        local bestPetId = -1

        pcall(function()
            local lstH = inv:GetType():GetField("m_LstHeroModel", 60):GetValue(inv)
            if lstH then
                for i = 0, lstH.Count - 1 do
                    local hm = lstH[i]
                    if hm and hm.m_HeroId and hm.m_HeroId > 0 then
                        validHeroMap[tonumber(hm.m_HeroId)] = hm
                        table.insert(allHeroes, hm)
                    end
                end
            end
        end)

        table.sort(allHeroes, function(a, b)
            local sa, sb = tonumber(a.m_Star) or 0, tonumber(b.m_Star) or 0
            if sa ~= sb then return sa > sb end
            local la, lb = tonumber(a.m_Level) or 0, tonumber(b.m_Level) or 0
            if la ~= lb then return la > lb end
            return (tonumber(a.m_HeroId) or 0) < (tonumber(b.m_HeroId) or 0)
        end)

        pcall(function()
            local lstP = inv:GetType():GetField("m_LstPetModel", 60):GetValue(inv)
            if lstP then
                local maxLv = -1
                for i = 0, lstP.Count - 1 do
                    local pm = lstP[i]
                    local plv = tonumber(pm and pm.m_Level) or 0
                    if pm and plv > maxLv then
                        maxLv = plv
                        bestPetId = tonumber(pm.m_PetId) or -1
                    end
                end
            end
        end)

        local teamIds = {-1, -1, -1, -1, -1, -1, bestPetId}
        local usedHero = {}
        local validCount = 0

        local hf = explicitFormation
        if not hf then
            pcall(function()
                hf = isPrayBoss and CS.SettingManager.GetFormationPrayForFire() or CS.SettingManager.GetFormationGuildBoss()
            end)
        end

        if hf then
            pcall(function()
                local lst = hf:ToListServerHeroId1LineUp()
                if lst and lst.Count >= 6 then
                    for i = 0, 5 do
                        local hid = tonumber(lst[i]) or -1
                        if hid > 0 and validHeroMap[hid] and not usedHero[hid] then
                            teamIds[i + 1] = hid
                            usedHero[hid] = true
                            validCount = validCount + 1
                        end
                    end
                    if lst.Count >= 7 then
                        local savedPet = tonumber(lst[6]) or -1
                        if savedPet > 0 then
                            teamIds[7] = savedPet
                        end
                    end
                end
            end)
        end

        if not explicitFormation and validCount == 0 then
            local hIdx = 1
            for slot = 1, 6 do
                while hIdx <= #allHeroes do
                    local candId = tonumber(allHeroes[hIdx].m_HeroId) or -1
                    hIdx = hIdx + 1
                    if candId > 0 and not usedHero[candId] then
                        teamIds[slot] = candId
                        usedHero[candId] = true
                        validCount = validCount + 1
                        break
                    end
                end
            end
        end

        if (teamIds[7] or -1) <= 0 and bestPetId > 0 then
            teamIds[7] = bestPetId
        end

        return teamIds, validCount
    end

    _G.HTPS_UpdateGuildBossBtnUI = function()
        pcall(function()
            if _G.HTPS_BTN_GUILD_BOSS_TXT and not _G.HTPS_BTN_GUILD_BOSS_TXT:Equals(nil) then
                _G.HTPS_BTN_GUILD_BOSS_TXT.text = _G.HTPS_GUILD_BOSS_RUNNING and "Đang Đánh..." or "Bỏ Qua Đánh"
            end
            if _G.HTPS_BTN_PRAY_BOSS_TXT and not _G.HTPS_BTN_PRAY_BOSS_TXT:Equals(nil) then
                _G.HTPS_BTN_PRAY_BOSS_TXT.text = _G.HTPS_GUILD_BOSS_RUNNING and "Đang Đánh..." or "Bỏ Qua Đánh"
            end
        end)
    end

    _G.HTPS_RunGuildBossSkipBattle = function(singleTurnOnly, explicitFormation)
        if _G.HTPS_GUILD_BOSS_RUNNING then
            _G.HTPS_GUILD_BOSS_RUNNING = false
            _G.HTPS_UpdateGuildBossBtnUI()
            CS.Toast.ShowToast("🛑 Đã dừng Auto Đánh Boss Bang Hội.")
            return
        end

        local gc = CS.GameContext.GetIntance()
        local nc = CS.NetworkController.GetInstance()
        if not gc or not nc then return end

        _G.HTPS_GUILD_BOSS_RUNNING = true
        _G.HTPS_UpdateGuildBossBtnUI()

        CsCoroutine.start(function()
            local totalTurns = 0
            local totalDamage = 0
            local lastBossId = 0
            local lastHpPct = 100
            local stopReason = ""

            local okRun, errRun = pcall(function()
                local teamIds, validCount = _G.HTPS_GetGuildBossLineupIds(false, explicitFormation)
                if validCount <= 0 then
                    stopReason = "⚠️ Không tìm thấy tướng trong đội hình để đánh Boss!"
                    return
                end

                local qr = nc:GetType():GetField("m_LstQueuedReceiveAction", 60):GetValue(nc)

                while _G.HTPS_GUILD_BOSS_RUNNING do
                    local pAtk = _G.HTPS_FindObjectOfType(typeof(CS.PopupGuildBossAttack))
                    local pRaid = _G.HTPS_FindObjectOfType(typeof(CS.PopupGuildRaid))
                    local curGb = nil
                    local gemCostBefore = 0

                    if pAtk and not pAtk:Equals(nil) and pAtk.gameObject.activeInHierarchy then
                        curGb = pAtk:GetType():GetField("m_GuildBoss", 60):GetValue(pAtk)
                        if curGb then
                            lastBossId = tonumber(curGb.m_BossId) or lastBossId
                            lastHpPct = math.floor(((tonumber(curGb.m_PercentHp) or 1) * 100) + 0.5)
                            gemCostBefore = tonumber(curGb.m_GemCostAttack) or 0
                        end
                    end

                    if gemCostBefore > 0 and (tonumber(gc.m_Gem) or 0) < gemCostBefore then
                        stopReason = string.format("⚠️ Không đủ Kim Cương (%d KC) để mua lượt đánh tiếp!", gemCostBefore)
                        break
                    end

                    local gemBefore = tonumber(gc.m_Gem) or 0

                    local req = CS.pbdson.RequestData()
                    req.session = gc.m_Session

                    local cv455 = CS.pbdson.CommonVector()
                    for i = 1, 7 do
                        cv455.aLong:Add(teamIds[i] or -1)
                    end
                    local act455 = CS.pbdson.PbAction()
                    act455.actionId = 455
                    act455.data = _G.HTPS_SerializeProto(cv455)
                    req.actions:Add(act455)

                    local act453 = CS.pbdson.PbAction()
                    act453.actionId = 453
                    req.actions:Add(act453)

                    local act454 = CS.pbdson.PbAction()
                    act454.actionId = 454
                    req.actions:Add(act454)

                    local url = nc.m_UrlGameServer .. "/i/455/" .. tostring(gc.m_UserId)
                    local data, okNet = _G.HTPS_PutWebRequest(url, _G.HTPS_SerializeProto(req), 10)
                    if not okNet or not data then
                        stopReason = "⚠️ Lỗi kết nối máy chủ khi đánh Boss!"
                        break
                    end

                    local resp = _G.HTPS_DeserializeProto(data, "pbdson.ResponseData,PbMethodLib")
                    if not resp or not resp.aAction then
                        stopReason = "⚠️ Dữ liệu phản hồi từ máy chủ không hợp lệ!"
                        break
                    end

                    local gotBattle455 = false
                    local errMsg1 = nil
                    local newBossId = nil
                    local newGemCost = nil

                    for i = 0, resp.aAction.Count - 1 do
                        local a = resp.aAction[i]
                        if a.actionId == 1 and a.data then
                            local cv1 = _G.HTPS_DeserializeProto(a.data, "pbdson.CommonVector,PbMethodLib")
                            if cv1 and cv1.aString and cv1.aString.Count > 0 then
                                errMsg1 = tostring(cv1.aString[0])
                            end
                        elseif a.actionId == 455 and a.data then
                            gotBattle455 = true
                            local pbRes = _G.HTPS_DeserializeProto(a.data, "pbdson.PbListBattleResult,PbMethodLib")
                            if pbRes then
                                if pbRes.aBonus and pbRes.aBonus.Count > 0 then
                                    pcall(function() CS.BonusModel.ParseBonusReceived(pbRes.aBonus, true) end)
                                end
                                local turnDmg = _G.HTPS_CalcBattleResultDamage(pbRes)
                                totalDamage = totalDamage + turnDmg
                                totalTurns = totalTurns + 1
                            end
                        elseif a.actionId == 453 and a.data then
                            local cv453 = _G.HTPS_DeserializeProto(a.data, "pbdson.CommonVector,PbMethodLib")
                            if cv453 and cv453.aLong and cv453.aLong.Count >= 6 then
                                newBossId = tonumber(cv453.aLong[0]) or lastBossId
                                lastBossId = newBossId
                                lastHpPct = tonumber(cv453.aLong[3]) or 0
                                newGemCost = tonumber(cv453.aLong[5]) or -1
                            end
                            if qr then qr:Add(a) end
                        elseif a.actionId == 454 and a.data then
                            if qr then qr:Add(a) end
                        end
                    end

                    if gotBattle455 and gemCostBefore > 0 then
                        local gemAfter = tonumber(gc.m_Gem) or 0
                        if gemAfter == gemBefore then
                            gc.m_Gem = math.max(0, gemBefore - gemCostBefore)
                        end
                    end

                    coroutine.yield(nil)
                    coroutine.yield(nil)

                    -- Đồng bộ ngay giao diện PopupGuildBossAttack sang trạng thái mới (hoặc Boss tiếp theo nếu Boss cũ vừa chết)
                    pcall(function()
                        local curAtk = _G.HTPS_FindObjectOfType(typeof(CS.PopupGuildBossAttack))
                        local curRaid = _G.HTPS_FindObjectOfType(typeof(CS.PopupGuildRaid))
                        if curAtk and not curAtk:Equals(nil) and curAtk.gameObject.activeInHierarchy
                            and curRaid and not curRaid:Equals(nil) then
                            local lstB = curRaid:GetType():GetField("m_LstGuildBoss", 60):GetValue(curRaid)
                            if lstB and newBossId and newBossId >= 1 and newBossId <= lstB.Count then
                                curAtk:SetGuildBoss(lstB[newBossId - 1])
                            end
                        end
                    end)

                    if not gotBattle455 then
                        stopReason = errMsg1 or "Đã hết lượt đánh Boss Bang Hội!"
                        break
                    end

                    if singleTurnOnly then
                        break
                    end

                    if newGemCost and newGemCost < 0 then
                        stopReason = "Đã đánh hết toàn bộ lượt hiện có!"
                        break
                    end

                    coroutine.yield(UG.WaitForSeconds(0.1))
                end
            end)

            _G.HTPS_GUILD_BOSS_RUNNING = false
            _G.HTPS_UpdateGuildBossBtnUI()

            if not okRun then
                CS.Toast.ShowToast("⚠️ Lỗi Đánh Boss: " .. tostring(errRun))
            elseif totalTurns > 0 then
                CS.Toast.ShowToast(string.format("⚔️ [Bỏ Qua Trận] Đã đánh %d lượt Boss %d | Tổng ST: %s | HP Boss còn: %d%%",
                    totalTurns, lastBossId, _G.HTPS_FormatBossDamage(totalDamage), lastHpPct))
            elseif stopReason ~= "" then
                CS.Toast.ShowToast(tostring(stopReason))
            end
        end)
    end

    _G.HTPS_RunPrayBossSkipBattle = function(singleTurnOnly, explicitFormation)
        if _G.HTPS_GUILD_BOSS_RUNNING then
            _G.HTPS_GUILD_BOSS_RUNNING = false
            _G.HTPS_UpdateGuildBossBtnUI()
            CS.Toast.ShowToast("🛑 Đã dừng Auto Đánh Boss Lửa Trại.")
            return
        end

        local gc = CS.GameContext.GetIntance()
        local nc = CS.NetworkController.GetInstance()
        if not gc or not nc then return end

        _G.HTPS_GUILD_BOSS_RUNNING = true
        _G.HTPS_UpdateGuildBossBtnUI()

        CsCoroutine.start(function()
            local totalTurns = 0
            local totalDamage = 0
            local stopReason = ""

            local okRun, errRun = pcall(function()
                local teamIds, validCount = _G.HTPS_GetGuildBossLineupIds(true, explicitFormation)
                if validCount <= 0 then
                    stopReason = "⚠️ Không tìm thấy tướng trong đội hình để đánh Boss Lửa Trại!"
                    return
                end

                local qr = nc:GetType():GetField("m_LstQueuedReceiveAction", 60):GetValue(nc)

                while _G.HTPS_GUILD_BOSS_RUNNING do
                    local req = CS.pbdson.RequestData()
                    req.session = gc.m_Session

                    local cv514 = CS.pbdson.CommonVector()
                    for i = 1, 7 do
                        cv514.aLong:Add(teamIds[i] or -1)
                    end
                    local act514 = CS.pbdson.PbAction()
                    act514.actionId = 514
                    act514.data = _G.HTPS_SerializeProto(cv514)
                    req.actions:Add(act514)

                    local act511 = CS.pbdson.PbAction()
                    act511.actionId = 511
                    req.actions:Add(act511)

                    local act512 = CS.pbdson.PbAction()
                    act512.actionId = 512
                    req.actions:Add(act512)

                    local url = nc.m_UrlGameServer .. "/i/514/" .. tostring(gc.m_UserId)
                    local data, okNet = _G.HTPS_PutWebRequest(url, _G.HTPS_SerializeProto(req), 10)
                    if not okNet or not data then
                        stopReason = "⚠️ Lỗi kết nối máy chủ khi đánh Boss Lửa Trại!"
                        break
                    end

                    local resp = _G.HTPS_DeserializeProto(data, "pbdson.ResponseData,PbMethodLib")
                    if not resp or not resp.aAction then
                        stopReason = "⚠️ Dữ liệu phản hồi từ máy chủ không hợp lệ!"
                        break
                    end

                    local gotBattle514 = false
                    local errMsg1 = nil

                    for i = 0, resp.aAction.Count - 1 do
                        local a = resp.aAction[i]
                        if a.actionId == 1 and a.data then
                            local cv1 = _G.HTPS_DeserializeProto(a.data, "pbdson.CommonVector,PbMethodLib")
                            if cv1 and cv1.aString and cv1.aString.Count > 0 then
                                errMsg1 = tostring(cv1.aString[0])
                            end
                        elseif a.actionId == 514 and a.data then
                            gotBattle514 = true
                            local pbRes = _G.HTPS_DeserializeProto(a.data, "pbdson.PbListBattleResult,PbMethodLib")
                            if pbRes then
                                if pbRes.aBonus and pbRes.aBonus.Count > 0 then
                                    pcall(function() CS.BonusModel.ParseBonusReceived(pbRes.aBonus, true) end)
                                end
                                local turnDmg = _G.HTPS_CalcBattleResultDamage(pbRes)
                                totalDamage = totalDamage + turnDmg
                                totalTurns = totalTurns + 1
                            end
                        elseif (a.actionId == 511 or a.actionId == 512) and a.data then
                            if qr then qr:Add(a) end
                        end
                    end

                    coroutine.yield(nil)
                    coroutine.yield(nil)

                    if not gotBattle514 then
                        stopReason = errMsg1 or "Đã hết lượt đánh Boss Lửa Trại!"
                        break
                    end

                    if singleTurnOnly then
                        break
                    end

                    coroutine.yield(UG.WaitForSeconds(0.1))
                end
            end)

            _G.HTPS_GUILD_BOSS_RUNNING = false
            _G.HTPS_UpdateGuildBossBtnUI()

            if not okRun then
                CS.Toast.ShowToast("⚠️ Lỗi Đánh Boss Lửa Trại: " .. tostring(errRun))
            elseif totalTurns > 0 then
                CS.Toast.ShowToast(string.format("🔥 [Bỏ Qua Trận] Đã đánh %d lượt Boss Lửa Trại | Tổng ST: %s",
                    totalTurns, _G.HTPS_FormatBossDamage(totalDamage)))
            elseif stopReason ~= "" then
                CS.Toast.ShowToast(tostring(stopReason))
            end
        end)
    end

    _G.HTPS_EnsureGuildBossButtons = function()
        pcall(function()
            local REF_FLAGS = 60

            -- 1. Trên PopupGuildBossAttack (Boss Bang Hội 1..60):
            local pAtk = _G.HTPS_FindObjectOfType(typeof(CS.PopupGuildBossAttack))
            local isGuildBossPopupActive = (pAtk and not pAtk:Equals(nil) and pAtk.gameObject.activeInHierarchy)
            if isGuildBossPopupActive then
                local aT = pAtk:GetType()
                local btnAtkGo = aT:GetField("m_GoButtonAttack", REF_FLAGS):GetValue(pAtk)
                if btnAtkGo and not btnAtkGo:Equals(nil) then
                    local boxBossTf = btnAtkGo.transform.parent
                    if boxBossTf then
                        local btnAutoTf = boxBossTf:Find("BtnHTPSQuickGuildBoss")
                        if not btnAutoTf then
                            local cloneGo = GO.Instantiate(btnAtkGo, boxBossTf, false)
                            cloneGo.name = "BtnHTPSQuickGuildBoss"
                            cloneGo:SetActive(true)
                            local iconGemTf = cloneGo.transform:Find("IconGem")
                            if iconGemTf then UG.Object.DestroyImmediate(iconGemTf.gameObject) end

                            local txt = cloneGo:GetComponentInChildren(typeof(UG.UI.Text), true)
                            if txt then
                                local loc = txt.gameObject:GetComponent(typeof(CS.I2.Loc.Localize))
                                if loc then UG.Object.DestroyImmediate(loc) end
                                local trt = txt.gameObject:GetComponent(typeof(UG.RectTransform))
                                if trt then
                                    trt.anchorMin = UG.Vector2(0, 0)
                                    trt.anchorMax = UG.Vector2(1, 1)
                                    trt.anchoredPosition = UG.Vector2(0, 0)
                                    trt.sizeDelta = UG.Vector2(0, 0)
                                end
                                txt.alignment = UG.TextAnchor.MiddleCenter
                                txt.fontSize = 18
                                _G.HTPS_BTN_GUILD_BOSS_TXT = txt
                            end

                            local bc = cloneGo:GetComponent(typeof(UG.UI.Button))
                            if bc then
                                bc.onClick = UG.UI.Button.ButtonClickedEvent()
                                bc.onClick:AddListener(function()
                                    _G.HTPS_RunGuildBossSkipBattle(true, nil)
                                end)
                            end
                            btnAutoTf = cloneGo.transform
                            _G.HTPS_UpdateGuildBossBtnUI()
                        end

                        if btnAutoTf then
                            if not btnAutoTf.gameObject.activeSelf then
                                btnAutoTf.gameObject:SetActive(true)
                            end
                            local origRt = btnAtkGo:GetComponent(typeof(UG.RectTransform))
                            local autoRt = btnAutoTf:GetComponent(typeof(UG.RectTransform))
                            if btnAtkGo.activeSelf then
                                if origRt then
                                    origRt.anchoredPosition = UG.Vector2(-72.0, -237.0)
                                    origRt.sizeDelta = UG.Vector2(138.0, 56.0)
                                end
                                local iconGemTf = btnAtkGo.transform:Find("IconGem")
                                if iconGemTf then
                                    local igRt = iconGemTf:GetComponent(typeof(UG.RectTransform))
                                    if igRt then igRt.anchoredPosition = UG.Vector2(-46.0, 0.0) end
                                end
                                local origTxtTf = btnAtkGo.transform:Find("Text")
                                if origTxtTf then
                                    local otRt = origTxtTf:GetComponent(typeof(UG.RectTransform))
                                    if otRt then otRt.anchoredPosition = UG.Vector2(14.0, 0.0) end
                                end
                                if autoRt then
                                    autoRt.anchoredPosition = UG.Vector2(72.0, -237.0)
                                    autoRt.sizeDelta = UG.Vector2(138.0, 56.0)
                                end
                            else
                                if autoRt then
                                    autoRt.anchoredPosition = UG.Vector2(0.0, -237.0)
                                    autoRt.sizeDelta = UG.Vector2(180.0, 56.0)
                                end
                            end
                            _G.HTPS_UpdateGuildBossBtnUI()
                        end
                    end
                end
            end

            -- 2. Trên PanelPrayBattle (Boss Lửa Trại / Cầu Nguyện sau Boss 60):
            local pPray = _G.HTPS_FindObjectOfType(typeof(CS.PanelPrayBattle))
            local isPrayBossActive = (pPray and not pPray:Equals(nil) and pPray.gameObject.activeInHierarchy)
            if isPrayBossActive then
                local pT = pPray:GetType()
                local btnBattleGo = pT:GetField("m_buttonBattle", REF_FLAGS):GetValue(pPray)
                if btnBattleGo and not btnBattleGo:Equals(nil) then
                    local parentTf = btnBattleGo.transform.parent
                    if parentTf then
                        local btnAutoTf = parentTf:Find("BtnHTPSQuickPrayBoss")
                        if not btnAutoTf then
                            local cloneGo = GO.Instantiate(btnBattleGo, parentTf, false)
                            cloneGo.name = "BtnHTPSQuickPrayBoss"
                            cloneGo:SetActive(true)
                            local hlg = cloneGo:GetComponent(typeof(UG.UI.HorizontalLayoutGroup))
                            if hlg then UG.Object.DestroyImmediate(hlg) end
                            local freeTf = cloneGo.transform:Find("FreeAttack")
                            if freeTf then UG.Object.DestroyImmediate(freeTf.gameObject) end

                            local txt = cloneGo:GetComponentInChildren(typeof(UG.UI.Text), true)
                            if txt then
                                local loc = txt.gameObject:GetComponent(typeof(CS.I2.Loc.Localize))
                                if loc then UG.Object.DestroyImmediate(loc) end
                                local trt = txt.gameObject:GetComponent(typeof(UG.RectTransform))
                                if trt then
                                    trt.anchorMin = UG.Vector2(0, 0)
                                    trt.anchorMax = UG.Vector2(1, 1)
                                    trt.anchoredPosition = UG.Vector2(0, 0)
                                    trt.sizeDelta = UG.Vector2(0, 0)
                                end
                                txt.alignment = UG.TextAnchor.MiddleCenter
                                txt.fontSize = 18
                                _G.HTPS_BTN_PRAY_BOSS_TXT = txt
                            end

                            local bc = cloneGo:GetComponent(typeof(UG.UI.Button))
                            if bc then
                                bc.onClick = UG.UI.Button.ButtonClickedEvent()
                                bc.onClick:AddListener(function()
                                    _G.HTPS_RunPrayBossSkipBattle(true, nil)
                                end)
                            end
                            btnAutoTf = cloneGo.transform
                            _G.HTPS_UpdateGuildBossBtnUI()
                        end

                        if btnAutoTf then
                            if not btnAutoTf.gameObject.activeSelf then
                                btnAutoTf.gameObject:SetActive(true)
                            end
                            local origRt = btnBattleGo:GetComponent(typeof(UG.RectTransform))
                            local autoRt = btnAutoTf:GetComponent(typeof(UG.RectTransform))
                            if btnBattleGo.activeSelf then
                                if origRt then
                                    origRt.anchoredPosition = UG.Vector2(-86.0, -224.2)
                                    origRt.sizeDelta = UG.Vector2(158.0, 56.0)
                                end
                                if autoRt then
                                    autoRt.anchoredPosition = UG.Vector2(86.0, -224.2)
                                    autoRt.sizeDelta = UG.Vector2(158.0, 56.0)
                                end
                            else
                                if autoRt then
                                    autoRt.anchoredPosition = UG.Vector2(0.0, -224.2)
                                    autoRt.sizeDelta = UG.Vector2(170.0, 56.0)
                                end
                            end
                            _G.HTPS_UpdateGuildBossBtnUI()
                        end
                    end
                end
            end

            -- 3. Khi mở bảng chọn đội hình (PopupFormation) từ nút "Đánh" của Boss Bang Hội / Lửa Trại:
            -- Tự động bật tích [✓] Bỏ qua trận đánh và khi bấm "Tấn công" sẽ đánh luôn không cần vào BattleScene!
            if isGuildBossPopupActive or isPrayBossActive then
                local pf = _G.HTPS_FindObjectOfType(typeof(CS.PopupFormation))
                if pf and not pf:Equals(nil) and pf.gameObject.activeInHierarchy then
                    local pfT = pf:GetType()
                    local curCb = pfT:GetField("m_ButtonActionClickCb", REF_FLAGS):GetValue(pf)
                    if curCb and _G.HTPS_BOUND_GUILD_FORMATION_CB ~= curCb then
                        local origCb = curCb
                        local isPray = isPrayBossActive and not isGuildBossPopupActive
                        pf:ShowCheckSkip(true)
                        pf:SetCheckSkip(true)
                        local tglSkip = pfT:GetField("m_ToggleSkip", REF_FLAGS):GetValue(pf)
                        pf:SetActionCallback("Tấn công", function(heroFormation)
                            local skipOn = true
                            pcall(function()
                                if tglSkip and not tglSkip:Equals(nil) and tglSkip.gameObject.activeSelf then
                                    skipOn = tglSkip.isOn
                                end
                            end)
                            if skipOn then
                                pcall(function()
                                    if isPray then
                                        CS.SettingManager.SaveFormationPrayForFire(heroFormation)
                                    else
                                        CS.SettingManager.SaveFormationGuildBoss(heroFormation)
                                    end
                                end)
                                if isPray then
                                    _G.HTPS_RunPrayBossSkipBattle(true, heroFormation)
                                else
                                    _G.HTPS_RunGuildBossSkipBattle(true, heroFormation)
                                end
                            elseif origCb then
                                origCb(heroFormation)
                            end
                        end)
                        _G.HTPS_BOUND_GUILD_FORMATION_CB = pfT:GetField("m_ButtonActionClickCb", REF_FLAGS):GetValue(pf)
                    end
                end
            end
        end)
    end

    -- =========================================================================
    -- AUTO NHIỆM VỤ TỔNG BỘ (TÌM ĐƠN MẢNH BẢO VẬT TÍM -> GIAO NV -> HOÀN THÀNH NHANH -> NHẬN LUÔN)
    -- =========================================================================
    _G.HTPS_UpdateTavernBtnUI = function(customLabel)
        pcall(function()
            if _G.HTPS_BTN_TAVERN_TXT and not _G.HTPS_BTN_TAVERN_TXT:Equals(nil) then
                if customLabel then
                    _G.HTPS_BTN_TAVERN_TXT.text = customLabel
                else
                    _G.HTPS_BTN_TAVERN_TXT.text = _G.HTPS_TAVERN_RUNNING and "Đang Auto... [Dừng]" or "Auto Mảnh Tím"
                end
            end
        end)
    end

    local function htpsIsPurpleArtifactShardQuest(q)
        if not q or not q.m_RewardItem then return false end
        local ri = q.m_RewardItem
        local ok, isPurple = pcall(function()
            return ri:GetType().Name == "ItemShard" and tonumber(ri.m_ShardType) == 3 and tonumber(ri.m_ItemKey) == 4
        end)
        return ok and isPurple or false
    end

    local function htpsPickHeroesForTavernQuest(q, cands, busyHeroIds)
        if not q or not q.m_LstRequirement then return nil end
        local reqCount = q.m_LstRequirement.Count
        if reqCount <= 0 then return nil end

        -- Sắp xếp thứ tự ưu tiên chọn ô có điều kiện khó trước: FACTION(2) / CLASS(3) -> STAR(1) -> NONE(4)
        local order = {}
        for r = 0, reqCount - 1 do
            local req = q.m_LstRequirement[r]
            local rType = tonumber(req.m_RequirementType) or 4
            local prio = (rType == 2 or rType == 3) and 1 or (rType == 1 and 2 or 3)
            table.insert(order, {slotIdx = r, req = req, prio = prio})
        end
        table.sort(order, function(a, b)
            if a.prio ~= b.prio then return a.prio < b.prio end
            return a.slotIdx < b.slotIdx
        end)

        local slotHeroIds = {}
        local tempUsed = {}
        for _, item in ipairs(order) do
            local foundId = nil
            for _, hm in ipairs(cands) do
                local hid = tonumber(hm.m_HeroId)
                if hid and not busyHeroIds[hid] and not tempUsed[hid] and item.req:IsHeroModelSatisfied(hm) then
                    foundId = hid
                    break
                end
            end
            if not foundId then
                return nil
            end
            slotHeroIds[item.slotIdx + 1] = foundId
            tempUsed[foundId] = true
        end

        return slotHeroIds
    end

    local function htpsInspectTavern222ForPurpleShard(raw222)
        local purpleWaitCount = 0
        local otherUnlockedWaitCount = 0
        local otherLockedWaitCount = 0
        pcall(function()
            if not raw222 then return end
            local lcv = _G.HTPS_DeserializeProto(raw222, "pbdson.ListCommonVector,PbMethodLib")
            if lcv and lcv.aVector then
                for k = 1, lcv.aVector.Count - 1, 2 do
                    local v = lcv.aVector[k].aLong
                    if v and v.Count >= 4 then
                        local locked = (tonumber(v[2]) or 0) ~= 0
                        local state = tonumber(v[3]) or 0
                        if state == 0 then
                            local isPurple = (v.Count >= 11 and tonumber(v[7]) == 3 and tonumber(v[8]) == 3 and tonumber(v[9]) == 4)
                            if isPurple then
                                purpleWaitCount = purpleWaitCount + 1
                            elseif locked then
                                otherLockedWaitCount = otherLockedWaitCount + 1
                            else
                                otherUnlockedWaitCount = otherUnlockedWaitCount + 1
                            end
                        end
                    end
                end
            end
        end)
        return purpleWaitCount, otherUnlockedWaitCount, otherLockedWaitCount
    end

    _G.HTPS_RunAutoTavernQuest = function()
        if _G.HTPS_TAVERN_RUNNING then
            _G.HTPS_TAVERN_RUNNING = false
            _G.HTPS_UpdateTavernBtnUI()
            CS.Toast.ShowToast("🛑 Đã dừng Auto Tìm Mảnh Bảo Vật Tím.")
            return
        end

        local ts = CS.TarvenScene.Instance
        if not ts or ts:Equals(nil) or not ts.gameObject.activeInHierarchy then
            CS.Toast.ShowToast("⚠️ Hãy mở màn hình Tổng Bộ trước!")
            return
        end

        local gc = CS.GameContext.GetIntance()
        local nc = CS.NetworkController.GetInstance()
        local inv = CS.PlayerInventory.GetInstance()
        if not gc or not nc or not inv then return end

        _G.HTPS_TAVERN_RUNNING = true
        _G.HTPS_UpdateTavernBtnUI("Đang tìm Mảnh Tím...")

        CsCoroutine.start(function()
            local totalCompleted = 0
            local totalShardsGained = 0
            local totalLocked = 0
            local totalRefreshes = 0
            local stopReason = ""

            local okRun, errRun = pcall(function()
                local qr = nc:GetType():GetField("m_LstQueuedReceiveAction", 60):GetValue(nc)

                -- Lấy danh sách tướng trong kho, ưu tiên tướng sao thấp (5★ -> 6★ -> ...) và cấp thấp trước
                local lstH = inv:GetType():GetField("m_LstHeroModel", 60):GetValue(inv)
                local cands = {}
                if lstH then
                    for i = 0, lstH.Count - 1 do
                        local hm = lstH[i]
                        if hm and hm.m_HeroId and hm.m_HeroId > 0 then
                            table.insert(cands, hm)
                        end
                    end
                end
                table.sort(cands, function(a, b)
                    local sa, sb = tonumber(a.m_Star) or 0, tonumber(b.m_Star) or 0
                    if sa ~= sb then return sa < sb end
                    local la, lb = tonumber(a.m_Level) or 0, tonumber(b.m_Level) or 0
                    if la ~= lb then return la < lb end
                    return (tonumber(a.m_HeroId) or 0) < (tonumber(b.m_HeroId) or 0)
                end)

                local lockedNoHeroQuestIds = {}

                while _G.HTPS_TAVERN_RUNNING do
                    local curTs = CS.TarvenScene.Instance
                    if not curTs or curTs:Equals(nil) or not curTs.gameObject.activeInHierarchy then
                        break
                    end

                    local lstQ = curTs.m_LstQuestInfo
                    local reqNet = CS.pbdson.RequestData()
                    reqNet.session = gc.m_Session
                    local otherWaiting = 0

                    local busyHeroIds = {}
                    local lstBusy = curTs:GetListHeroIdDoingQuest()
                    if lstBusy then
                        for i = 0, lstBusy.Count - 1 do
                            busyHeroIds[tonumber(lstBusy[i])] = true
                        end
                    end

                    if lstQ and lstQ.Count > 0 then
                        for i = 0, lstQ.Count - 1 do
                            local q = lstQ[i]
                            if q then
                                local isPurple = htpsIsPurpleArtifactShardQuest(q)
                                if isPurple then
                                    if q.m_QuestState == 0 then
                                        if not lockedNoHeroQuestIds[q.m_QuestId] then
                                            local pickedIds = htpsPickHeroesForTavernQuest(q, cands, busyHeroIds)
                                            if pickedIds and #pickedIds == q.m_LstRequirement.Count then
                                                -- 1. Giao nhiệm vụ (227)
                                                local cv227 = CS.pbdson.CommonVector()
                                                cv227.aLong:Add(q.m_QuestId)
                                                for _, hid in ipairs(pickedIds) do
                                                    busyHeroIds[hid] = true
                                                    cv227.aLong:Add(hid)
                                                end
                                                local act227 = CS.pbdson.PbAction()
                                                act227.actionId = 227
                                                act227.data = _G.HTPS_SerializeProto(cv227)
                                                reqNet.actions:Add(act227)

                                                -- 2. Hoàn thành nhanh (225)
                                                local cv225 = CS.pbdson.CommonVector()
                                                cv225.aLong:Add(q.m_QuestId)
                                                local act225 = CS.pbdson.PbAction()
                                                act225.actionId = 225
                                                act225.data = _G.HTPS_SerializeProto(cv225)
                                                reqNet.actions:Add(act225)

                                                -- 3. Nhận thưởng luôn (228) -> tướng được giải phóng ngay sau 228
                                                local cv228 = CS.pbdson.CommonVector()
                                                cv228.aLong:Add(q.m_QuestId)
                                                local act228 = CS.pbdson.PbAction()
                                                act228.actionId = 228
                                                act228.data = _G.HTPS_SerializeProto(cv228)
                                                reqNet.actions:Add(act228)
                                            else
                                                lockedNoHeroQuestIds[q.m_QuestId] = true
                                                if not q.m_IsLocked then
                                                    local cv226 = CS.pbdson.CommonVector()
                                                    cv226.aLong:Add(q.m_QuestId)
                                                    local act226 = CS.pbdson.PbAction()
                                                    act226.actionId = 226
                                                    act226.data = _G.HTPS_SerializeProto(cv226)
                                                    reqNet.actions:Add(act226)
                                                    totalLocked = totalLocked + 1
                                                end
                                            end
                                        end
                                    elseif q.m_QuestState == 1 then
                                        local cv225 = CS.pbdson.CommonVector()
                                        cv225.aLong:Add(q.m_QuestId)
                                        local act225 = CS.pbdson.PbAction()
                                        act225.actionId = 225
                                        act225.data = _G.HTPS_SerializeProto(cv225)
                                        reqNet.actions:Add(act225)

                                        local cv228 = CS.pbdson.CommonVector()
                                        cv228.aLong:Add(q.m_QuestId)
                                        local act228 = CS.pbdson.PbAction()
                                        act228.actionId = 228
                                        act228.data = _G.HTPS_SerializeProto(cv228)
                                        reqNet.actions:Add(act228)
                                    elseif q.m_QuestState == 2 then
                                        local cv228 = CS.pbdson.CommonVector()
                                        cv228.aLong:Add(q.m_QuestId)
                                        local act228 = CS.pbdson.PbAction()
                                        act228.actionId = 228
                                        act228.data = _G.HTPS_SerializeProto(cv228)
                                        reqNet.actions:Add(act228)
                                    end
                                elseif q.m_QuestState == 0 then
                                    if q.m_IsLocked then
                                        local cv226 = CS.pbdson.CommonVector()
                                        cv226.aLong:Add(q.m_QuestId)
                                        local act226 = CS.pbdson.PbAction()
                                        act226.actionId = 226
                                        act226.data = _G.HTPS_SerializeProto(cv226)
                                        reqNet.actions:Add(act226)
                                    end
                                    otherWaiting = otherWaiting + 1
                                end
                            end
                        end
                    end

                    _G.HTPS_UpdateTavernBtnUI(string.format("+%d Mảnh (%dđ) [Dừng]", totalShardsGained, totalCompleted))

                    if otherWaiting > 0 then
                        local gemCost = otherWaiting * 30
                        if (tonumber(gc.m_Gem) or 0) < gemCost then
                            stopReason = string.format("⚠️ Không đủ Kim Cương (%d KC) để làm mới %d nhiệm vụ!", gemCost, otherWaiting)
                            if reqNet.actions.Count == 0 then
                                break
                            end
                        else
                            local act224 = CS.pbdson.PbAction()
                            act224.actionId = 224
                            reqNet.actions:Add(act224)
                            totalRefreshes = totalRefreshes + 1
                        end
                    else
                        -- Nếu hết đơn đang chờ, tự động dùng Nhiệm vụ thường (17) hoặc Nhiệm vụ khó (18) nếu có trong túi
                        local scrollBasic = tonumber(inv:GetNumberItemConsumable(17)) or 0
                        local scrollSenior = tonumber(inv:GetNumberItemConsumable(18)) or 0
                        if scrollBasic > 0 or scrollSenior > 0 then
                            local useKey = (scrollSenior > 0) and 18 or 17
                            local useCount = math.min(10, (useKey == 18) and scrollSenior or scrollBasic)
                            for s = 1, useCount do
                                local cv223 = CS.pbdson.CommonVector()
                                cv223.aLong:Add(useKey)
                                local act223 = CS.pbdson.PbAction()
                                act223.actionId = 223
                                act223.data = _G.HTPS_SerializeProto(cv223)
                                reqNet.actions:Add(act223)
                            end
                        elseif reqNet.actions.Count > 0 then
                            local act222 = CS.pbdson.PbAction()
                            act222.actionId = 222
                            reqNet.actions:Add(act222)
                        else
                            stopReason = "🍺 Đã hoàn thành hết toàn bộ đơn nhiệm vụ trong Tổng Bộ!"
                            break
                        end
                    end

                    if reqNet.actions.Count == 0 then
                        break
                    end

                    local firstAid = reqNet.actions[0].actionId
                    local data, okNet = _G.HTPS_PutWebRequest(
                        nc.m_UrlGameServer .. "/i/" .. tostring(firstAid) .. "/" .. tostring(gc.m_UserId),
                        _G.HTPS_SerializeProto(reqNet),
                        10
                    )
                    if not okNet or not data then
                        stopReason = "⚠️ Lỗi kết nối máy chủ khi làm mới Tổng Bộ!"
                        break
                    end

                    local last222 = nil
                    local resp = _G.HTPS_DeserializeProto(data, "pbdson.ResponseData,PbMethodLib")
                    if resp and resp.aAction then
                        for i = 0, resp.aAction.Count - 1 do
                            local a = resp.aAction[i]
                            if (a.actionId == 224 or a.actionId == 223) and a.data then
                                local cv = _G.HTPS_DeserializeProto(a.data, "pbdson.CommonVector,PbMethodLib")
                                if cv and cv.aLong then CS.BonusModel.ParseBonusReceived(cv.aLong, true) end
                            elseif a.actionId == 225 and a.data then
                                local cv = _G.HTPS_DeserializeProto(a.data, "pbdson.CommonVector,PbMethodLib")
                                if cv and cv.aLong and cv.aLong.Count >= 5 then
                                    local sub = CS.pbdson.CommonVector()
                                    for j = 2, cv.aLong.Count - 1 do sub.aLong:Add(cv.aLong[j]) end
                                    pcall(function() CS.BonusModel.ParseBonusReceived(sub.aLong, true) end)
                                end
                            elseif a.actionId == 228 and a.data then
                                local cv = _G.HTPS_DeserializeProto(a.data, "pbdson.CommonVector,PbMethodLib")
                                if cv and cv.aLong and cv.aLong.Count >= 2 then
                                    local sub = CS.pbdson.CommonVector()
                                    for j = 1, cv.aLong.Count - 1 do sub.aLong:Add(cv.aLong[j]) end
                                    pcall(function() CS.BonusModel.ParseBonusReceived(sub.aLong, true) end)
                                    totalCompleted = totalCompleted + 1
                                    if cv.aLong.Count >= 6 then
                                        totalShardsGained = totalShardsGained + (tonumber(cv.aLong[5]) or 0)
                                    end
                                end
                            elseif a.actionId == 222 and a.data then
                                last222 = a
                            end
                        end
                    end

                    _G.HTPS_UpdateTavernBtnUI(string.format("+%d Mảnh (%dđ) [Dừng]", totalShardsGained, totalCompleted))

                    -- Vòng lặp siêu tốc: Nếu đợt làm mới vừa rồi chưa ra đơn Mảnh bảo vật tím nào, tiếp tục gửi 224 ngay lập tức!
                    if last222 then
                        local pWait, uWait, lWait = htpsInspectTavern222ForPurpleShard(last222.data)
                        local fastSpin = 0
                        while _G.HTPS_TAVERN_RUNNING and pWait <= totalLocked and uWait > 0 and lWait == 0 do
                            local gemNeed = uWait * 30
                            if (tonumber(gc.m_Gem) or 0) < gemNeed then
                                stopReason = string.format("⚠️ Không đủ Kim Cương (%d KC) để làm mới tiếp!", gemNeed)
                                break
                            end
                            local reqFast = CS.pbdson.RequestData()
                            reqFast.session = gc.m_Session
                            local a224 = CS.pbdson.PbAction()
                            a224.actionId = 224
                            reqFast.actions:Add(a224)
                            totalRefreshes = totalRefreshes + 1
                            fastSpin = fastSpin + 1

                            local dFast, okFast = _G.HTPS_PutWebRequest(
                                nc.m_UrlGameServer .. "/i/224/" .. tostring(gc.m_UserId),
                                _G.HTPS_SerializeProto(reqFast),
                                10
                            )
                            if not okFast or not dFast then break end
                            local rFast = _G.HTPS_DeserializeProto(dFast, "pbdson.ResponseData,PbMethodLib")
                            if rFast and rFast.aAction then
                                for i = 0, rFast.aAction.Count - 1 do
                                    local a = rFast.aAction[i]
                                    if a.actionId == 224 and a.data then
                                        local cv = _G.HTPS_DeserializeProto(a.data, "pbdson.CommonVector,PbMethodLib")
                                        if cv and cv.aLong then CS.BonusModel.ParseBonusReceived(cv.aLong, true) end
                                    elseif a.actionId == 222 and a.data then
                                        last222 = a
                                    end
                                end
                            end
                            pWait, uWait, lWait = htpsInspectTavern222ForPurpleShard(last222 and last222.data)
                            if fastSpin % 4 == 0 then
                                if qr and last222 then qr:Add(last222) end
                                _G.HTPS_UpdateTavernBtnUI(string.format("+%d Mảnh (%dđ) [Dừng]", totalShardsGained, totalCompleted))
                                coroutine.yield(nil)
                            end
                        end

                        if qr and last222 then
                            qr:Add(last222)
                        end
                    end

                    coroutine.yield(nil)
                    coroutine.yield(nil)
                end
            end)

            _G.HTPS_TAVERN_RUNNING = false
            _G.HTPS_UpdateTavernBtnUI()

            if not okRun then
                CS.Toast.ShowToast("⚠️ Lỗi Auto Tổng Bộ: " .. tostring(errRun))
            elseif totalCompleted > 0 then
                CS.Toast.ShowToast(string.format("🍇 Hoàn tất! Đã nhận +%d Mảnh bảo vật tím (%d đơn hoàn thành nhanh) sau %d lần làm mới!",
                    totalShardsGained, totalCompleted, totalRefreshes))
            elseif stopReason ~= "" then
                CS.Toast.ShowToast(tostring(stopReason))
            else
                CS.Toast.ShowToast("🛑 Đã dừng Auto Tổng Bộ.")
            end
        end)
    end

    _G.HTPS_EnsureTavernButtons = function()
        pcall(function()
            local ts = CS.TarvenScene.Instance
            if not ts or ts:Equals(nil) or not ts.gameObject.activeInHierarchy then return end
            local btnRefreshGo = ts.m_GoButtonRefresh
            if not btnRefreshGo or btnRefreshGo:Equals(nil) then return end
            local boxQuestTf = btnRefreshGo.transform.parent
            if not boxQuestTf then return end

            local btnAutoTf = boxQuestTf:Find("BtnHTPSAutoTavern")
            if not btnAutoTf then
                local btnBasicTf = boxQuestTf:Find("ButtonGenQuestBasic")
                local btnSeniorTf = boxQuestTf:Find("ButtonGenQuestSenior")
                if btnBasicTf then
                    local rtB = btnBasicTf:GetComponent(typeof(UG.RectTransform))
                    if rtB then
                        rtB.anchoredPosition = UG.Vector2(-345.0, -244.0)
                        rtB.sizeDelta = UG.Vector2(195.0, 60.0)
                    end
                end
                if btnSeniorTf then
                    local rtS = btnSeniorTf:GetComponent(typeof(UG.RectTransform))
                    if rtS then
                        rtS.anchoredPosition = UG.Vector2(-120.0, -244.0)
                        rtS.sizeDelta = UG.Vector2(195.0, 60.0)
                    end
                end
                local rtR = btnRefreshGo:GetComponent(typeof(UG.RectTransform))
                if rtR then
                    rtR.anchoredPosition = UG.Vector2(105.0, -244.0)
                    rtR.sizeDelta = UG.Vector2(195.0, 60.0)
                end

                local cloneGo = GO.Instantiate(btnRefreshGo, boxQuestTf, false)
                cloneGo.name = "BtnHTPSAutoTavern"
                cloneGo:SetActive(true)
                local rtA = cloneGo:GetComponent(typeof(UG.RectTransform))
                if rtA then
                    rtA.anchoredPosition = UG.Vector2(335.0, -244.0)
                    rtA.sizeDelta = UG.Vector2(215.0, 60.0)
                end

                local iconGemTf = cloneGo.transform:Find("IconGem")
                if iconGemTf then UG.Object.DestroyImmediate(iconGemTf.gameObject) end

                local txt = cloneGo:GetComponentInChildren(typeof(UG.UI.Text), true)
                if txt then
                    local loc = txt.gameObject:GetComponent(typeof(CS.I2.Loc.Localize))
                    if loc then UG.Object.DestroyImmediate(loc) end
                    local trt = txt.gameObject:GetComponent(typeof(UG.RectTransform))
                    if trt then
                        trt.anchorMin = UG.Vector2(0, 0)
                        trt.anchorMax = UG.Vector2(1, 1)
                        trt.anchoredPosition = UG.Vector2(0, 0)
                        trt.sizeDelta = UG.Vector2(0, 0)
                    end
                    txt.alignment = UG.TextAnchor.MiddleCenter
                    txt.fontSize = 18
                    _G.HTPS_BTN_TAVERN_TXT = txt
                end

                local bc = cloneGo:GetComponent(typeof(UG.UI.Button))
                if bc then
                    bc.onClick = UG.UI.Button.ButtonClickedEvent()
                    bc.onClick:AddListener(function()
                        _G.HTPS_RunAutoTavernQuest()
                    end)
                end
                btnAutoTf = cloneGo.transform
                _G.HTPS_UpdateTavernBtnUI()
            else
                if not btnAutoTf.gameObject.activeSelf then
                    btnAutoTf.gameObject:SetActive(true)
                end
                if not _G.HTPS_BTN_TAVERN_TXT or _G.HTPS_BTN_TAVERN_TXT:Equals(nil) then
                    _G.HTPS_BTN_TAVERN_TXT = btnAutoTf:GetComponentInChildren(typeof(UG.UI.Text), true)
                end
                if not _G.HTPS_TAVERN_RUNNING then
                    _G.HTPS_UpdateTavernBtnUI()
                end
            end
        end)
    end

    -- =========================================================================
    -- ĐÁNH BOSS TÂN TỨ HOÀNG (BỎ QUA VÀO TRẬN - ĐÁNH 1 LẦN MỖI KHI BẤM)
    -- =========================================================================
    _G.HTPS_UpdateTTHBossBtnUI = function(customLabel)
        pcall(function()
            if _G.HTPS_BTN_TTH_BOSS_TXT and not _G.HTPS_BTN_TTH_BOSS_TXT:Equals(nil) then
                if customLabel then
                    _G.HTPS_BTN_TTH_BOSS_TXT.text = customLabel
                else
                    _G.HTPS_BTN_TTH_BOSS_TXT.text = _G.HTPS_TTH_BOSS_RUNNING and "Đang Đánh..." or "Bỏ Qua Đánh"
                end
            end
        end)
    end

    _G.HTPS_GetTTHBossLineupIds = function(explicitFormation)
        local inv = CS.PlayerInventory.GetInstance()
        local validHeroMap = {}
        local allHeroes = {}
        local bestPetId = 0

        pcall(function()
            local lstH = inv:GetType():GetField("m_LstHeroModel", 60):GetValue(inv)
            if lstH then
                for i = 0, lstH.Count - 1 do
                    local hm = lstH[i]
                    if hm and hm.m_HeroId and hm.m_HeroId > 0 then
                        validHeroMap[tonumber(hm.m_HeroId)] = hm
                        table.insert(allHeroes, hm)
                    end
                end
            end
        end)

        table.sort(allHeroes, function(a, b)
            local sa, sb = tonumber(a.m_Star) or 0, tonumber(b.m_Star) or 0
            if sa ~= sb then return sa > sb end
            local la, lb = tonumber(a.m_Level) or 0, tonumber(b.m_Level) or 0
            if la ~= lb then return la > lb end
            return (tonumber(a.m_HeroId) or 0) < (tonumber(b.m_HeroId) or 0)
        end)

        pcall(function()
            local lstP = inv:GetType():GetField("m_LstPetModel", 60):GetValue(inv)
            if lstP then
                local maxLv = -1
                for i = 0, lstP.Count - 1 do
                    local pm = lstP[i]
                    local plv = tonumber(pm and pm.m_Level) or 0
                    if pm and plv > maxLv then
                        maxLv = plv
                        bestPetId = tonumber(pm.m_PetId) or 0
                    end
                end
            end
        end)

        local teamIds = {0, 0, 0, 0, 0, 0, bestPetId}
        local usedHero = {}
        local validCount = 0

        local hf = explicitFormation
        if not hf and _G.TTHLobby and _G.TTHLobby.loadFormation then
            pcall(function()
                hf = _G.TTHLobby:loadFormation()
            end)
        end

        if hf then
            pcall(function()
                local lst = hf:ToListServerHeroId1LineUp()
                if lst and lst.Count >= 6 then
                    for i = 0, 5 do
                        local hid = tonumber(lst[i]) or 0
                        if hid > 0 and validHeroMap[hid] and not usedHero[hid] then
                            teamIds[i + 1] = hid
                            usedHero[hid] = true
                            validCount = validCount + 1
                        end
                    end
                    if lst.Count >= 7 then
                        local savedPet = tonumber(lst[6]) or 0
                        if savedPet > 0 then
                            teamIds[7] = savedPet
                        end
                    end
                end
            end)
        end

        if not explicitFormation and validCount == 0 then
            local hIdx = 1
            for slot = 1, 6 do
                while hIdx <= #allHeroes do
                    local candId = tonumber(allHeroes[hIdx].m_HeroId) or 0
                    hIdx = hIdx + 1
                    if candId > 0 and not usedHero[candId] then
                        teamIds[slot] = candId
                        usedHero[candId] = true
                        validCount = validCount + 1
                        break
                    end
                end
            end
            if validCount > 0 then
                pcall(function()
                    local parts = {}
                    for i = 1, 7 do table.insert(parts, tostring(teamIds[i] or 0)) end
                    CS.UnityEngine.PlayerPrefs.SetString("key_tan_tu_hoang_formation", table.concat(parts, "_"))
                    CS.UnityEngine.PlayerPrefs.Save()
                end)
            end
        end

        if (teamIds[7] or 0) <= 0 and bestPetId > 0 then
            teamIds[7] = bestPetId
        end

        return teamIds, validCount
    end

    local function htpsDispatchTTHLuaAction(actionId, dataBytes)
        pcall(function()
            local lnc = _G.NetworkController and _G.NetworkController:instance()
            if not lnc or not lnc.listEventHandler then return end
            local handlers = {}
            for i, v in ipairs(lnc.listEventHandler:getList()) do
                handlers[i] = v
            end
            for _, h in ipairs(handlers) do
                if h and h.processKEvent then
                    pcall(function() h:processKEvent(actionId, dataBytes) end)
                end
            end
        end)
    end

    _G.HTPS_RunTTHBossSkipBattle = function(singleTurnOnly, explicitFormation)
        if _G.HTPS_TTH_BOSS_RUNNING then
            _G.HTPS_TTH_BOSS_RUNNING = false
            _G.HTPS_UpdateTTHBossBtnUI()
            CS.Toast.ShowToast("🛑 Đã dừng Auto Đánh Boss Tân Tứ Hoàng.")
            return
        end

        local s = _G.TTHDb and _G.TTHDb.status
        if s and (tonumber(s.attacksLeft) or 0) <= 0 then
            if (tonumber(s.buyPrice) or -1) >= 0 then
                local openedBuy = false
                pcall(function()
                    local lnc = _G.NetworkController and _G.NetworkController:instance()
                    if lnc and lnc.listEventHandler then
                        for _, h in ipairs(lnc.listEventHandler:getList()) do
                            if h and h.askBuy then
                                h:askBuy()
                                openedBuy = true
                                break
                            end
                        end
                    end
                end)
                if not openedBuy then
                    CS.Toast.ShowToast("⚠️ Đã hết lượt đánh! Hãy bấm (+) để mua thêm lượt.")
                end
            else
                CS.Toast.ShowToast("Đã hết lượt khiêu chiến hôm nay")
            end
            return
        end

        local gc = CS.GameContext.GetIntance()
        local nc = CS.NetworkController.GetInstance()
        if not gc or not nc then return end

        _G.HTPS_TTH_BOSS_RUNNING = true
        _G.HTPS_UpdateTTHBossBtnUI()

        CsCoroutine.start(function()
            local totalTurns = 0
            local lastTurnDamage = 0
            local bestDamage = tonumber(s and s.myBest) or 0
            local myRank = tonumber(s and s.myRank) or 0
            local curLeft = tonumber(s and s.attacksLeft) or 0
            local stopReason = ""

            local okRun, errRun = pcall(function()
                local teamIds, validCount = _G.HTPS_GetTTHBossLineupIds(explicitFormation)
                if validCount <= 0 then
                    stopReason = "⚠️ Không tìm thấy tướng trong đội hình để đánh Boss Tân Tứ Hoàng!"
                    return
                end

                while _G.HTPS_TTH_BOSS_RUNNING do
                    local curStatus = _G.TTHDb and _G.TTHDb.status
                    if curStatus and (tonumber(curStatus.attacksLeft) or 0) <= 0 then
                        stopReason = "Đã đánh hết lượt hiện có!"
                        break
                    end

                    local req = CS.pbdson.RequestData()
                    req.session = gc.m_Session

                    local cv1912 = CS.pbdson.CommonVector()
                    for i = 1, 7 do
                        cv1912.aLong:Add(teamIds[i] or 0)
                    end
                    local act1912 = CS.pbdson.PbAction()
                    act1912.actionId = 1912
                    act1912.data = _G.HTPS_SerializeProto(cv1912)
                    req.actions:Add(act1912)

                    local act1910 = CS.pbdson.PbAction()
                    act1910.actionId = 1910
                    req.actions:Add(act1910)

                    local act1911 = CS.pbdson.PbAction()
                    act1911.actionId = 1911
                    req.actions:Add(act1911)

                    local url = nc.m_UrlGameServer .. "/i/1912/" .. tostring(gc.m_UserId)
                    local data, okNet = _G.HTPS_PutWebRequest(url, _G.HTPS_SerializeProto(req), 10)
                    if not okNet or not data then
                        stopReason = "⚠️ Lỗi kết nối máy chủ khi đánh Boss Tân Tứ Hoàng!"
                        break
                    end

                    local resp = _G.HTPS_DeserializeProto(data, "pbdson.ResponseData,PbMethodLib")
                    if not resp or not resp.aAction then
                        stopReason = "⚠️ Dữ liệu phản hồi từ máy chủ không hợp lệ!"
                        break
                    end

                    local gotBattle1912 = false
                    local errMsg1 = nil

                    for i = 0, resp.aAction.Count - 1 do
                        local a = resp.aAction[i]
                        if a.actionId == 1 and a.data then
                            local cv1 = _G.HTPS_DeserializeProto(a.data, "pbdson.CommonVector,PbMethodLib")
                            if cv1 and cv1.aString and cv1.aString.Count > 0 then
                                errMsg1 = tostring(cv1.aString[0])
                            end
                        elseif a.actionId == 1912 and a.data then
                            gotBattle1912 = true
                            local pbRes = _G.HTPS_DeserializeProto(a.data, "pbdson.PbListBattleResult,PbMethodLib")
                            if pbRes then
                                if pbRes.aBonus and pbRes.aBonus.Count > 0 then
                                    pcall(function() CS.BonusModel.ParseBonusReceived(pbRes.aBonus, true) end)
                                end
                                local turnDmg = 0
                                pcall(function()
                                    if pbRes.info and pbRes.info.aLong and pbRes.info.aLong.Count > 0 then
                                        turnDmg = tonumber(pbRes.info.aLong[0]) or 0
                                        if pbRes.info.aLong.Count > 1 then
                                            bestDamage = tonumber(pbRes.info.aLong[1]) or bestDamage
                                        end
                                        if pbRes.info.aLong.Count > 2 then
                                            myRank = tonumber(pbRes.info.aLong[2]) or myRank
                                        end
                                        if pbRes.info.aLong.Count > 3 then
                                            curLeft = tonumber(pbRes.info.aLong[3]) or curLeft
                                        end
                                    end
                                end)
                                if turnDmg <= 0 then
                                    turnDmg = _G.HTPS_CalcBattleResultDamage(pbRes)
                                end
                                lastTurnDamage = turnDmg
                                if turnDmg > bestDamage then
                                    bestDamage = turnDmg
                                end
                                totalTurns = totalTurns + 1
                            end
                        elseif (a.actionId == 1910 or a.actionId == 1911) and a.data then
                            htpsDispatchTTHLuaAction(a.actionId, a.data)
                        end
                    end

                    if _G.TTHDb and _G.TTHDb.status then
                        curLeft = tonumber(_G.TTHDb.status.attacksLeft) or curLeft
                        if (tonumber(_G.TTHDb.status.myBest) or 0) > 0 then
                            bestDamage = tonumber(_G.TTHDb.status.myBest) or bestDamage
                        end
                        if (tonumber(_G.TTHDb.status.myRank) or 0) > 0 then
                            myRank = tonumber(_G.TTHDb.status.myRank) or myRank
                        end
                    end

                    if not singleTurnOnly and _G.HTPS_TTH_BOSS_RUNNING then
                        _G.HTPS_UpdateTTHBossBtnUI(string.format("Đánh:%d | Còn:%d", totalTurns, curLeft))
                    end

                    coroutine.yield(nil)

                    if not gotBattle1912 then
                        stopReason = errMsg1 or "Đã hết lượt khiêu chiến hôm nay!"
                        break
                    end

                    if singleTurnOnly then
                        break
                    end

                    if curLeft <= 0 then
                        stopReason = "Đã đánh hết toàn bộ lượt hiện có!"
                        break
                    end

                    coroutine.yield(UG.WaitForSeconds(0.08))
                end
            end)

            _G.HTPS_TTH_BOSS_RUNNING = false
            _G.HTPS_UpdateTTHBossBtnUI()

            local fmtDmg = function(val)
                if _G.TTHDb and _G.TTHDb.formatDamage then
                    return _G.TTHDb.formatDamage(val)
                end
                return _G.HTPS_FormatBossDamage(val)
            end
            local rankStr = myRank > 0 and tostring(myRank) or "--"

            if not okRun then
                CS.Toast.ShowToast("⚠️ Lỗi Đánh Boss Tân Tứ Hoàng: " .. tostring(errRun))
            elseif totalTurns > 0 then
                if singleTurnOnly then
                    CS.Toast.ShowToast(string.format("⚔️ [Bỏ Qua Trận] ST lượt này: %s | ST cao nhất: %s | Hạng: %s | Còn: %d lượt",
                        fmtDmg(lastTurnDamage), fmtDmg(bestDamage), rankStr, curLeft))
                else
                    CS.Toast.ShowToast(string.format("⚔️ [Auto Tân Tứ Hoàng] Đã đánh %d lượt | ST cao nhất: %s | Hạng: %s | Còn: %d lượt",
                        totalTurns, fmtDmg(bestDamage), rankStr, curLeft))
                end
            elseif stopReason ~= "" then
                CS.Toast.ShowToast(tostring(stopReason))
            end
        end)
    end

    _G.HTPS_EnsureTTHBossButtons = function()
        pcall(function()
            local REF_FLAGS = 60

            -- Hook trực tiếp TTHLobby.onAttack để khi bấm nút "Tấn công" gốc -> mở PopupFormation có sẵn tích [✓] Bỏ qua trận đánh
            if _G.TTHLobby and not _G.TTHLobby._htpsHookedOnAttack then
                _G.TTHLobby._htpsHookedOnAttack = true
                _G.TTHLobby.onAttack = function(self)
                    local s = _G.TTHDb and _G.TTHDb.status
                    if s == nil then return end
                    if s.attacksLeft <= 0 then
                        if s.buyPrice >= 0 and self.hub then
                            self.hub:askBuy()
                        else
                            CS.Toast.ShowToast("Đã hết lượt khiêu chiến hôm nay")
                        end
                        return
                    end
                    local lstHeroModel = CS.PlayerInventory.GetInstance():GetListHeroModel()
                    local popup = CS.PopupFormation.ShowUp(lstHeroModel, self:loadFormation())
                    if popup then
                        pcall(function()
                            popup:ShowCheckSkip(true)
                            popup:SetCheckSkip(true)
                        end)
                        local pfT = popup:GetType()
                        local tglSkip = pfT:GetField("m_ToggleSkip", REF_FLAGS):GetValue(popup)
                        popup:SetActionCallback("Tấn công", function(heroFormation)
                            self:saveFormation(heroFormation)
                            local skipOn = true
                            pcall(function()
                                if tglSkip and not tglSkip:Equals(nil) and tglSkip.gameObject.activeSelf then
                                    skipOn = tglSkip.isOn
                                end
                            end)
                            popup:ButtonCloseClick()
                            if skipOn then
                                _G.HTPS_RunTTHBossSkipBattle(true, heroFormation)
                            else
                                _G.TTHDataSender:instance():attack(heroFormation:ToListServerHeroId1LineUp())
                            end
                        end)
                    end
                end
            end

            local lobbyGo = GO.Find("TTHLobby(Clone)")
            local isTTHLobbyActive = (lobbyGo ~= nil and not lobbyGo:Equals(nil) and lobbyGo.activeInHierarchy)
            if not isTTHLobbyActive then return end

            local leftTf = lobbyGo.transform:Find("Left")
            if not leftTf then return end
            local btnAtkTf = leftTf:Find("ButtonAttack")
            if not btnAtkTf then return end
            local btnAtkGo = btnAtkTf.gameObject

            local btnAutoTf = leftTf:Find("BtnHTPSQuickTTHBoss")
            if not btnAutoTf then
                local cloneGo = GO.Instantiate(btnAtkGo, leftTf, false)
                cloneGo.name = "BtnHTPSQuickTTHBoss"
                cloneGo:SetActive(true)
                local costTf = cloneGo.transform:Find("Cost")
                if costTf then UG.Object.DestroyImmediate(costTf.gameObject) end

                local txt = cloneGo:GetComponentInChildren(typeof(UG.UI.Text), true)
                if txt then
                    local loc = txt.gameObject:GetComponent(typeof(CS.I2.Loc.Localize))
                    if loc then UG.Object.DestroyImmediate(loc) end
                    local trt = txt.gameObject:GetComponent(typeof(UG.RectTransform))
                    if trt then
                        trt.anchorMin = UG.Vector2(0, 0)
                        trt.anchorMax = UG.Vector2(1, 1)
                        trt.anchoredPosition = UG.Vector2(0, 0)
                        trt.sizeDelta = UG.Vector2(0, 0)
                    end
                    txt.alignment = UG.TextAnchor.MiddleCenter
                    txt.fontSize = 18
                    _G.HTPS_BTN_TTH_BOSS_TXT = txt
                end

                local bc = cloneGo:GetComponent(typeof(UG.UI.Button))
                if bc then
                    bc.onClick = UG.UI.Button.ButtonClickedEvent()
                    bc.onClick:AddListener(function()
                        _G.HTPS_RunTTHBossSkipBattle(true, nil)
                    end)
                end
                btnAutoTf = cloneGo.transform
                _G.HTPS_UpdateTTHBossBtnUI()
            end

            if btnAutoTf then
                if not btnAutoTf.gameObject.activeSelf then
                    btnAutoTf.gameObject:SetActive(true)
                end
                local bc = btnAutoTf:GetComponent(typeof(UG.UI.Button))
                if bc and _G.HTPS_BOUND_TTH_QUICK_BTN ~= bc then
                    _G.HTPS_BOUND_TTH_QUICK_BTN = bc
                    bc.onClick = UG.UI.Button.ButtonClickedEvent()
                    bc.onClick:AddListener(function()
                        _G.HTPS_RunTTHBossSkipBattle(true, nil)
                    end)
                end
                local origRt = btnAtkGo:GetComponent(typeof(UG.RectTransform))
                local autoRt = btnAutoTf:GetComponent(typeof(UG.RectTransform))
                if origRt then
                    origRt.anchoredPosition = UG.Vector2(-88.0, -218.0)
                    origRt.sizeDelta = UG.Vector2(162.0, 56.0)
                end
                if autoRt then
                    autoRt.anchoredPosition = UG.Vector2(88.0, -218.0)
                    autoRt.sizeDelta = UG.Vector2(162.0, 56.0)
                end
                if not _G.HTPS_TTH_BOSS_RUNNING then
                    _G.HTPS_UpdateTTHBossBtnUI()
                end
            end
        end)
    end

    -- ==================== AUTO N?NG MAX CHI?N H?M (PopupPet / MonsterScene) ====================
    _G.HTPS_UpdatePetBtnUI = function(statusTxt)
        pcall(function()
            if _G.HTPS_BTN_MAX_PET_TXT and not _G.HTPS_BTN_MAX_PET_TXT:Equals(nil) then
                _G.HTPS_BTN_MAX_PET_TXT.text = statusTxt or (_G.HTPS_PET_MAX_RUNNING and "Đang Nâng..." or "Nâng Max Hạm")
            end
            if _G.HTPS_BTN_MAX_ALL_PET_TXT and not _G.HTPS_BTN_MAX_ALL_PET_TXT:Equals(nil) then
                _G.HTPS_BTN_MAX_ALL_PET_TXT.text = _G.HTPS_PET_MAX_RUNNING and "Đang Nâng..." or "Max Tất Cả Hạm"
            end
        end)
    end

    _G.HTPS_RunMaxPet = function(onlyCurrent)
        if _G.HTPS_PET_MAX_RUNNING then
            CS.Toast.ShowToast("Đang nâng cấp Chiến Hạm, vui lòng đợi...")
            return
        end

        local pp = _G.HTPS_FindObjectOfType(typeof(CS.PopupPet))
        local curPetId = nil
        if pp and not pp:Equals(nil) and pp.gameObject.activeInHierarchy then
            local pm = pp:GetType():GetField("m_PetModel", 60):GetValue(pp)
            if pm then curPetId = tonumber(pm.m_PetId) end
        end
        if onlyCurrent and not curPetId then
            CS.Toast.ShowToast("Hãy mở Chiến Hạm cần nâng cấp trước!")
            return
        end

        _G.HTPS_PET_MAX_RUNNING = true
        _G.HTPS_UpdatePetBtnUI("Đang Nâng...")
        CS.Toast.ShowToast(onlyCurrent and "🚢 Đang nâng MAX Cấp độ + Kỹ năng + Cường hóa Chiến Hạm..." or "🚢 Đang nâng MAX toàn bộ tất cả Chiến Hạm...")

        CsCoroutine.start(function()
            local REF_FLAGS = 60
            local ok, err = pcall(function()
                local gc = CS.GameContext.GetIntance()
                local inv = CS.PlayerInventory.GetInstance()
                local db = CS.DbManager.GetInstance()
                local csNet = CS.NetworkController.GetInstance()
                local urlServer = csNet and csNet.m_UrlGameServer or ""
                if not gc or not inv or not db or urlServer == "" then return end

                -- 1. L?y tr?ng th?i Chi?n H?m hi?n t?i t? Server (Action 360)
                local stateMap = {}
                local req360 = CS.pbdson.RequestData()
                req360.session = gc.m_Session
                local a360 = CS.pbdson.PbAction()
                a360.actionId = 360
                req360.actions:Add(a360)
                local d360 = _G.HTPS_PutWebRequest(urlServer .. "/i/360/" .. tostring(gc.m_UserId), _G.HTPS_SerializeProto(req360), 8)
                if d360 then
                    local r360 = _G.HTPS_DeserializeProto(d360, "pbdson.ResponseData,PbMethodLib")
                    if r360 and r360.aAction then
                        for i = 0, r360.aAction.Count - 1 do
                            local a = r360.aAction[i]
                            if a.actionId == 360 and a.data then
                                local lcv = _G.HTPS_DeserializeProto(a.data, "pbdson.ListCommonVector,PbMethodLib")
                                if lcv and lcv.aVector then
                                    for vIdx = 0, lcv.aVector.Count - 1 do
                                        local vec = lcv.aVector[vIdx].aLong
                                        if vec and vec.Count >= 10 then
                                            local pid = tonumber(vec[0])
                                            stateMap[pid] = {
                                                lv = tonumber(vec[1]) or 1,
                                                tier = tonumber(vec[2]) or 1,
                                                sk = { tonumber(vec[3]) or 1, tonumber(vec[4]) or 0, tonumber(vec[5]) or 0, tonumber(vec[6]) or 0 },
                                                ruin = { tonumber(vec[7]) or 0, tonumber(vec[8]) or 0, tonumber(vec[9]) or 0 }
                                            }
                                        end
                                    end
                                end
                            end
                        end
                    end
                end

                local targetIds = {}
                if onlyCurrent and curPetId then
                    table.insert(targetIds, curPetId)
                else
                    local allPets = db:GetListAllPetModel()
                    if allPets then
                        for i = 0, allPets.Count - 1 do
                            local p = allPets[i]
                            if p then table.insert(targetIds, tonumber(p.m_PetId)) end
                        end
                    end
                end

                local acts = {}
                for _, pid in ipairs(targetIds) do
                    local st = stateMap[pid]
                    if not st then
                        table.insert(acts, { id = 361, args = { pid } })
                        st = { lv = 1, tier = 1, sk = { 1, 0, 0, 0 }, ruin = { 0, 0, 0 } }
                    end
                    local curLv = st.lv
                    local curTier = st.tier
                    while curLv < 180 or curTier < 4 do
                        if curLv == 30 and curTier == 1 then
                            table.insert(acts, { id = 363, args = { pid } })
                            curTier = 2
                        elseif curLv == 60 and curTier == 2 then
                            table.insert(acts, { id = 363, args = { pid } })
                            curTier = 3
                        elseif curLv == 90 and curTier == 3 then
                            table.insert(acts, { id = 363, args = { pid } })
                            curTier = 4
                        elseif curLv < 180 then
                            table.insert(acts, { id = 362, args = { pid } })
                            curLv = curLv + 1
                        else
                            break
                        end
                    end
                    for sIdx = 1, 4 do
                        local sLv = math.max(1, st.sk[sIdx] or 1)
                        while sLv < 30 do
                            table.insert(acts, { id = 364, args = { pid, sIdx } })
                            sLv = sLv + 1
                        end
                    end
                    for rIdx = 0, 2 do
                        local rLv = math.max(1, st.ruin[rIdx + 1] or 1)
                        while rLv < 60 do
                            table.insert(acts, { id = 366, args = { pid, rIdx } })
                            rLv = rLv + 1
                        end
                    end
                end

                if #acts == 0 then
                    CS.Toast.ShowToast("✅ Chiến Hạm đã đạt Cấp độ & Kỹ năng tối đa (Lv.180 / Bậc 4 / Skill 30 / Cường hóa 60)!")
                    return
                end

                local idx = 1
                local last360Data = nil
                while idx <= #acts do
                    local req = CS.pbdson.RequestData()
                    req.session = gc.m_Session
                    local batchEnd = math.min(#acts, idx + 79)
                    for b = idx, batchEnd do
                        local item = acts[b]
                        local cv = CS.pbdson.CommonVector()
                        for _, v in ipairs(item.args) do cv.aLong:Add(v) end
                        local pa = CS.pbdson.PbAction()
                        pa.actionId = item.id
                        pa.data = _G.HTPS_SerializeProto(cv)
                        req.actions:Add(pa)
                    end
                    if batchEnd == #acts then
                        local pa360 = CS.pbdson.PbAction()
                        pa360.actionId = 360
                        req.actions:Add(pa360)
                    end

                    _G.HTPS_UpdatePetBtnUI(string.format("Nâng %d%%...", math.floor((batchEnd * 100) / #acts)))
                    local d = _G.HTPS_PutWebRequest(urlServer .. "/i/" .. tostring(acts[idx].id) .. "/" .. tostring(gc.m_UserId), _G.HTPS_SerializeProto(req), 12)
                    if d then
                        local r = _G.HTPS_DeserializeProto(d, "pbdson.ResponseData,PbMethodLib")
                        if r and r.aAction then
                            for i = 0, r.aAction.Count - 1 do
                                local act = r.aAction[i]
                                if (act.actionId == 361 or act.actionId == 362 or act.actionId == 363 or act.actionId == 364 or act.actionId == 366) and act.data then
                                    local cv = _G.HTPS_DeserializeProto(act.data, "pbdson.CommonVector,PbMethodLib")
                                    if cv and cv.aLong then
                                        local startIdx = (act.actionId == 364 or act.actionId == 366) and 3 or ((act.actionId == 361) and 1 or 2)
                                        if cv.aLong.Count > startIdx then
                                            local bonusLongs = CS.System.Collections.Generic.List(typeof(CS.System.Int64))()
                                            for j = startIdx, cv.aLong.Count - 1 do
                                                bonusLongs:Add(cv.aLong[j])
                                            end
                                            CS.BonusModel.ParseBonusReceived(bonusLongs)
                                        end
                                    end
                                elseif act.actionId == 360 and act.data then
                                    last360Data = act.data
                                end
                            end
                        end
                    end
                    idx = batchEnd + 1
                    coroutine.yield(nil)
                end

                local maxedSet = {}
                for _, pid in ipairs(targetIds) do maxedSet[pid] = true end

                local function applyMaxToPetModel(pm)
                    if pm and maxedSet[tonumber(pm.m_PetId)] then
                        pm.m_Activated = true
                        pm.m_Level = 180
                        pm.m_Tier = 4
                        pm.m_Skill1Level = 30
                        pm.m_Skill2Level = 30
                        pm.m_Skill3Level = 30
                        pm.m_Skill4Level = 30
                        pm.m_Ruin1Level = 60
                        pm.m_Ruin2Level = 60
                        pm.m_Ruin3Level = 60
                    end
                end

                pcall(function()
                    local lstInv = inv:GetType():GetField("m_LstPetModel", REF_FLAGS):GetValue(inv)
                    if lstInv then
                        for i = 0, lstInv.Count - 1 do applyMaxToPetModel(lstInv[i]) end
                    end
                end)

                if last360Data then
                    pcall(function() csNet:ProcessPackageEvent(360, last360Data) end)
                end

                pcall(function()
                    local ms = _G.HTPS_FindObjectOfType(typeof(CS.MonsterScene))
                    if ms and not ms:Equals(nil) and ms.gameObject.activeInHierarchy then
                        local lstMs = ms:GetType():GetField("m_LstPetModel", REF_FLAGS):GetValue(ms)
                        if lstMs then
                            for i = 0, lstMs.Count - 1 do applyMaxToPetModel(lstMs[i]) end
                        end
                        local pageIdx = tonumber(ms:GetType():GetField("m_CurrentPageIdx", REF_FLAGS):GetValue(ms)) or 0
                        ms:LoadPage(pageIdx)
                    end
                end)

                pcall(function()
                    local pop = _G.HTPS_FindObjectOfType(typeof(CS.PopupPet))
                    if pop and not pop:Equals(nil) and pop.gameObject.activeInHierarchy then
                        local pm = pop:GetType():GetField("m_PetModel", REF_FLAGS):GetValue(pop)
                        if pm then
                            applyMaxToPetModel(pm)
                            pop:SetPetModel(pm)
                            pop:LoadPetSpine(pm.m_PetId, pm.m_Tier)
                        end
                    end
                end)

                CS.Toast.ShowToast("🚢 Đã nâng MAX Chiến Hạm (Lv.180 + Bậc 4 + 4 Kỹ năng 30/30 + 3 Cường hóa 60/60)!")
            end)

            _G.HTPS_PET_MAX_RUNNING = false
            _G.HTPS_UpdatePetBtnUI()
            if not ok then
                CS.Toast.ShowToast("⚠️ Lỗi nâng Chiến Hạm: " .. tostring(err))
            end
        end)
    end

    _G.HTPS_EnsurePetButtons = function()
        pcall(function()
            local pp = _G.HTPS_FindObjectOfType(typeof(CS.PopupPet))
            if not pp or pp:Equals(nil) or not pp.gameObject.activeInHierarchy then return end
            local REF_FLAGS = 60
            local boxSpine = pp:GetType():GetField("m_GoBoxSpine", REF_FLAGS):GetValue(pp)
            if not boxSpine then return end
            local btnRebirthTf = boxSpine.transform:Find("ButtonRebirth")
            if not btnRebirthTf then return end

            local rebRt = btnRebirthTf:GetComponent(typeof(UG.RectTransform))
            if rebRt then
                rebRt.anchoredPosition = UG.Vector2(-95.0, -184.0)
                rebRt.sizeDelta = UG.Vector2(165.0, 56.0)
            end

            -- N?t 1: N?ng Max H?m hi?n t?i
            local btnMaxTf = boxSpine.transform:Find("BtnHTPSMaxPet")
            if not btnMaxTf then
                local cloneGo = GO.Instantiate(btnRebirthTf.gameObject, boxSpine.transform, false)
                cloneGo.name = "BtnHTPSMaxPet"
                cloneGo:SetActive(true)
                local rt = cloneGo:GetComponent(typeof(UG.RectTransform))
                if rt then
                    rt.anchoredPosition = UG.Vector2(95.0, -184.0)
                    rt.sizeDelta = UG.Vector2(180.0, 56.0)
                end
                local txt = cloneGo:GetComponentInChildren(typeof(UG.UI.Text), true)
                if txt then
                    local loc = txt.gameObject:GetComponent(typeof(CS.I2.Loc.Localize))
                    if loc then UG.Object.DestroyImmediate(loc) end
                    txt.alignment = UG.TextAnchor.MiddleCenter
                    txt.fontSize = 18
                    txt.text = "Nâng Max Hạm"
                    _G.HTPS_BTN_MAX_PET_TXT = txt
                end
                btnMaxTf = cloneGo.transform
            end

            if btnMaxTf then
                btnMaxTf.gameObject:SetActive(true)
                local txt = btnMaxTf:GetComponentInChildren(typeof(UG.UI.Text), true)
                if txt then
                    _G.HTPS_BTN_MAX_PET_TXT = txt
                    if not _G.HTPS_PET_MAX_RUNNING then txt.text = "Nâng Max Hạm" end
                end
                local bc = btnMaxTf:GetComponent(typeof(UG.UI.Button))
                if bc and _G.HTPS_BOUND_MAX_PET_BTN ~= bc then
                    _G.HTPS_BOUND_MAX_PET_BTN = bc
                    bc.onClick = UG.UI.Button.ButtonClickedEvent()
                    bc.onClick:AddListener(function()
                        _G.HTPS_RunMaxPet(true)
                    end)
                end
            end

            -- N?t 2: Max T?t C? H?m
            local btnMaxAllTf = boxSpine.transform:Find("BtnHTPSMaxAllPets")
            if not btnMaxAllTf then
                local cloneGo = GO.Instantiate(btnRebirthTf.gameObject, boxSpine.transform, false)
                cloneGo.name = "BtnHTPSMaxAllPets"
                cloneGo:SetActive(true)
                local rt = cloneGo:GetComponent(typeof(UG.RectTransform))
                if rt then
                    rt.anchoredPosition = UG.Vector2(0.0, 218.0)
                    rt.sizeDelta = UG.Vector2(215.0, 50.0)
                end
                local txt = cloneGo:GetComponentInChildren(typeof(UG.UI.Text), true)
                if txt then
                    local loc = txt.gameObject:GetComponent(typeof(CS.I2.Loc.Localize))
                    if loc then UG.Object.DestroyImmediate(loc) end
                    txt.alignment = UG.TextAnchor.MiddleCenter
                    txt.fontSize = 18
                    txt.text = "Max Tất Cả Hạm"
                    _G.HTPS_BTN_MAX_ALL_PET_TXT = txt
                end
                btnMaxAllTf = cloneGo.transform
            end

            if btnMaxAllTf then
                btnMaxAllTf.gameObject:SetActive(true)
                local txt = btnMaxAllTf:GetComponentInChildren(typeof(UG.UI.Text), true)
                if txt then
                    _G.HTPS_BTN_MAX_ALL_PET_TXT = txt
                    if not _G.HTPS_PET_MAX_RUNNING then txt.text = "Max Tất Cả Hạm" end
                end
                local bc = btnMaxAllTf:GetComponent(typeof(UG.UI.Button))
                if bc and _G.HTPS_BOUND_MAX_ALL_PET_BTN ~= bc then
                    _G.HTPS_BOUND_MAX_ALL_PET_BTN = bc
                    bc.onClick = UG.UI.Button.ButtonClickedEvent()
                    bc.onClick:AddListener(function()
                        _G.HTPS_RunMaxPet(false)
                    end)
                end
            end
        end)
    end


    -- =====================================================================
    -- AUTO UPGRADE ARTIFACT TO MAX STAR (CHAO SAT FIRST -> MOST DUPLICATES, KEEP >= 1)
    -- =====================================================================
    _G.HTPS_ARTIFACT_MAX_RUNNING = false
    _G.HTPS_BTN_MAX_ARTIFACT_TXT = nil
    _G.HTPS_BOUND_MAX_ARTIFACT_BTN = nil
    _G.HTPS_BTN_MAX_ARTIFACT_PII_TXT = nil
    _G.HTPS_BOUND_MAX_ARTIFACT_PII_BTN = nil

    _G.HTPS_UpdateArtifactBtnUI = function(statusText)
        pcall(function()
            local label = statusText or (_G.HTPS_ARTIFACT_MAX_RUNNING and "Đang Nâng..." or "Auto Nâng Max")
            if _G.HTPS_BTN_MAX_ARTIFACT_TXT and not _G.HTPS_BTN_MAX_ARTIFACT_TXT:Equals(nil) then
                _G.HTPS_BTN_MAX_ARTIFACT_TXT.text = label
            end
            if _G.HTPS_BTN_MAX_ARTIFACT_PII_TXT and not _G.HTPS_BTN_MAX_ARTIFACT_PII_TXT:Equals(nil) then
                _G.HTPS_BTN_MAX_ARTIFACT_PII_TXT.text = label
            end
        end)
    end

    _G.HTPS_RunAutoMaxArtifact = function()
        if _G.HTPS_ARTIFACT_MAX_RUNNING then
            CS.Toast.ShowToast("Đang tự động nâng cấp Bảo Vật, vui lòng đợi...")
            return
        end

        local BF = CS.System.Reflection.BindingFlags.Public | CS.System.Reflection.BindingFlags.NonPublic | CS.System.Reflection.BindingFlags.Instance | CS.System.Reflection.BindingFlags.Static
        local p = _G.HTPS_FindObjectOfType(typeof(CS.PopupUpgradeArtifact))
        if p and (p:Equals(nil) or not p.gameObject.activeInHierarchy or not p.gameObject.scene:IsValid()) then
            p = nil
        end

        local pii = _G.HTPS_FindObjectOfType(typeof(CS.PopupItemInfo))
        if pii and (pii:Equals(nil) or not pii.gameObject.activeInHierarchy or not pii.gameObject.scene:IsValid()) then
            pii = nil
        end

        local phe = _G.HTPS_FindObjectOfType(typeof(CS.PanelHeroEquipment))
        if phe and (phe:Equals(nil) or not phe.gameObject.activeInHierarchy or not phe.gameObject.scene:IsValid()) then
            phe = nil
        end

        local heroId = -1
        local artKey = 0
        local curStar = 1
        local fHero, fKey, fStar

        if p then
            local pFields = p:GetType():GetFields(BF)
            for i = 0, pFields.Length - 1 do
                local fn = pFields[i].Name
                if fn == "m_HeroId" then fHero = pFields[i]
                elseif fn == "m_ArtifactKeyUpgrade" then fKey = pFields[i]
                elseif fn == "m_ArtifactStarUpgrade" then fStar = pFields[i]
                end
            end
            heroId = fHero and tonumber(fHero:GetValue(p)) or -1
            artKey = fKey and tonumber(fKey:GetValue(p)) or 0
            curStar = fStar and tonumber(fStar:GetValue(p)) or 1
        elseif phe then
            local pheFields = phe:GetType():GetFields(BF)
            local hm, sa
            for i = 0, pheFields.Length - 1 do
                local fn = pheFields[i].Name
                if fn == "m_HeroModel" then hm = pheFields[i]:GetValue(phe)
                elseif fn == "m_SlotArtifact" then sa = pheFields[i]:GetValue(phe)
                end
            end
            if hm then
                heroId = tonumber(hm.m_HeroId) or -1
                artKey = tonumber(hm.m_ArtifactKey) or 0
                curStar = tonumber(hm.m_ArtifactStar) or 1
            elseif sa then
                local saFields = sa:GetType():GetFields(BF)
                for i = 0, saFields.Length - 1 do
                    if saFields[i].Name == "m_HeroId" then heroId = tonumber(saFields[i]:GetValue(sa)) or -1
                    elseif saFields[i].Name == "m_ItemArtifact" then
                        local ia = saFields[i]:GetValue(sa)
                        if ia then
                            artKey = tonumber(ia.m_ItemKey) or 0
                            curStar = tonumber(ia.m_Star) or 1
                        end
                    end
                end
            end
        end

        if artKey <= 0 then
            CS.Toast.ShowToast("Chưa chọn Bảo Vật cần nâng cấp!")
            return
        end

        local db = CS.DbManager.GetInstance()
        local baseArt = db and db:GetItemArtifactCopy(artKey)
        if not baseArt then
            CS.Toast.ShowToast("Không đọc được dữ liệu Bảo Vật!")
            return
        end

        local maxStar = tonumber(baseArt:GetMaxStar()) or 6
        if curStar >= maxStar then
            CS.Toast.ShowToast("Bảo Vật này đã đạt tối đa " .. tostring(maxStar) .. "★!")
            return
        end

        _G.HTPS_ARTIFACT_MAX_RUNNING = true
        _G.HTPS_UpdateArtifactBtnUI("Đang Nâng...")

        CsCoroutine.start(function()
            pcall(function() CS.UnityEngine.Debug.unityLogger.logEnabled = false end)
            local ok, err = pcall(function()
                local gc = CS.GameContext.GetIntance()
                local inv = CS.PlayerInventory.GetInstance()
                local csNet = CS.NetworkController.GetInstance()
                local urlServer = csNet and csNet.m_UrlGameServer or ""
                if not gc or not inv or not csNet or urlServer == "" then return end

                local heroModel = nil
                local invFields = inv:GetType():GetFields(BF)
                for i = 0, invFields.Length - 1 do
                    if invFields[i].Name == "m_LstHeroModel" then
                        local heroes = invFields[i]:GetValue(inv)
                        if heroes then
                            for hIdx = 0, heroes.Count - 1 do
                                local h = heroes[hIdx]
                                if h and tonumber(h.m_HeroId) == heroId then
                                    heroModel = h
                                    break
                                end
                            end
                        end
                        break
                    end
                end

                if p and p.m_LstSlotMaterial then
                    for s = 0, p.m_LstSlotMaterial.Count - 1 do
                        p.m_LstSlotMaterial[s]:ClearSlot()
                    end
                end

                local upgInfo = db:GetArtifactUpgradeInfo(baseArt.m_Type)
                local costPerStar = upgInfo and tonumber(upgInfo.m_UpgradeCost) or 5400

                local startStar = curStar
                local totalChaoUsed = 0
                local totalPhoiUsed = 0
                local stopReason = nil

                while curStar < maxStar do
                    _G.HTPS_UpdateArtifactBtnUI(string.format("Nâng %d★->%d★", curStar, curStar + 1))
                    local needExp = costPerStar
                    local chaoAvail = 0
                    local fodders = {}

                    local lstArt = inv.m_LstItemArtifact
                    for i = 0, lstArt.Count - 1 do
                        local a = lstArt[i]
                        local k = tonumber(a.m_ItemKey)
                        local st = tonumber(a.m_Star)
                        local num = tonumber(a.m_Number)
                        local used = tonumber(a.m_NumberUsed)
                        local unused = num - used

                        if k == 1 and st == 1 then
                            chaoAvail = math.max(0, unused - 1)
                        elseif k ~= 1 and st == 1 then
                            local reserve = 1
                            if heroId <= 0 and k == artKey and st == curStar then
                                reserve = 2
                            end
                            local avail = unused - reserve
                            if avail > 0 then
                                local fInfo = db:GetArtifactUpgradeInfo(a.m_Type)
                                local expVal = fInfo and (tonumber(fInfo.m_BaseValue) + (st - 1) * tonumber(fInfo.m_UpgradeCost)) or 20
                                table.insert(fodders, {
                                    key = k,
                                    star = st,
                                    avail = avail,
                                    expVal = expVal,
                                    typeId = a.m_Type:GetHashCode()
                                })
                            end
                        end
                    end

                    table.sort(fodders, function(x, y)
                        if x.avail ~= y.avail then return x.avail > y.avail end
                        if x.typeId ~= y.typeId then return x.typeId < y.typeId end
                        return x.key < y.key
                    end)

                    local useChao = math.min(chaoAvail, math.ceil(needExp / 10))
                    local otherExp = 0
                    local chosenPhoi = {}

                    local remExp = needExp - (useChao * 10)
                    if remExp > 0 then
                        for _, f in ipairs(fodders) do
                            if remExp <= 0 or #chosenPhoi >= 7 then break end
                            local take = math.min(f.avail, math.ceil(remExp / f.expVal))
                            if take > 0 then
                                table.insert(chosenPhoi, { key = f.key, star = f.star, count = take })
                                otherExp = otherExp + (take * f.expVal)
                                remExp = needExp - (useChao * 10 + otherExp)
                            end
                        end
                    end

                    if (useChao * 10 + otherExp) < needExp then
                        stopReason = "Không đủ phôi Bảo Vật (đã giữ lại 1 phôi mỗi loại)!"
                        break
                    end

                    if useChao > 0 and otherExp > 0 then
                        local excess = (useChao * 10 + otherExp) - needExp
                        if excess >= 10 then
                            local reduce = math.min(useChao, math.floor(excess / 10))
                            useChao = useChao - reduce
                        end
                    end

                    local req = CS.pbdson.RequestData()
                    req.session = gc.m_Session
                    local act = CS.pbdson.PbAction()
                    act.actionId = 255
                    local cv = CS.pbdson.CommonVector()
                    cv.aLong:Add(heroId)
                    cv.aLong:Add(artKey)
                    cv.aLong:Add(curStar)
                    if useChao > 0 then
                        cv.aLong:Add(1)
                        cv.aLong:Add(1)
                        cv.aLong:Add(useChao)
                    end
                    local stepPhoiCount = 0
                    for _, m in ipairs(chosenPhoi) do
                        cv.aLong:Add(m.key)
                        cv.aLong:Add(m.star)
                        cv.aLong:Add(m.count)
                        stepPhoiCount = stepPhoiCount + m.count
                    end
                    act.data = _G.HTPS_SerializeProto(cv)
                    req.actions:Add(act)

                    local respBytes = _G.HTPS_PutWebRequest(urlServer .. "/i/255/" .. tostring(gc.m_UserId), _G.HTPS_SerializeProto(req), 8)
                    if not respBytes then
                        stopReason = "Lỗi kết nối máy chủ khi nâng Bảo Vật!"
                        break
                    end

                    local resp = _G.HTPS_DeserializeProto(respBytes, "pbdson.ResponseData,PbMethodLib")
                    local stepSuccess = false
                    if resp and resp.aAction then
                        for i = 0, resp.aAction.Count - 1 do
                            local a = resp.aAction[i]
                            if a.actionId == 255 and a.data then
                                stepSuccess = true
                                local rcv = _G.HTPS_DeserializeProto(a.data, "pbdson.CommonVector,PbMethodLib")
                                if rcv and rcv.aLong then
                                    pcall(function() CS.BonusModel.ParseBonusReceived(rcv.aLong, true) end)
                                end
                                curStar = curStar + 1
                                if heroModel then
                                    pcall(function() heroModel:EquipArtifact(artKey, curStar) end)
                                end
                            elseif a.actionId == 1 and a.data then
                                local rcv = _G.HTPS_DeserializeProto(a.data, "pbdson.CommonVector,PbMethodLib")
                                if rcv and rcv.aString and rcv.aString.Count > 0 then
                                    stopReason = tostring(rcv.aString[0])
                                end
                            end
                        end
                    end

                    if not stepSuccess then
                        stopReason = stopReason or "Máy chủ từ chối nâng cấp Bảo Vật!"
                        break
                    end

                    totalChaoUsed = totalChaoUsed + useChao
                    totalPhoiUsed = totalPhoiUsed + stepPhoiCount
                end

                -- ??ng b? giao di?n ngay l?p t?c
                if curStar > startStar then
                    if phe and not phe:Equals(nil) and heroModel then
                        pcall(function() phe:LoadHeroItemsAndStone(heroModel) end)
                    end
                    if p and not p:Equals(nil) and p.gameObject.activeInHierarchy then
                        if curStar >= maxStar then
                            pcall(function() p:ClosePopup() end)
                        elseif heroModel then
                            pcall(function() p:SetArtifactToUpgrade(heroId, heroModel:GetArtifact()) end)
                        end
                    end
                    if pii and not pii:Equals(nil) and pii.gameObject.activeInHierarchy and heroModel then
                        pcall(function()
                            local newArt = heroModel:GetArtifact()
                            if newArt then
                                pii:LoadItem(newArt, false)
                            end
                            local piiFields = pii:GetType():GetFields(BF)
                            for i = 0, piiFields.Length - 1 do
                                if piiFields[i].Name == "m_GoButtonUpgrade" then
                                    local bu = piiFields[i]:GetValue(pii)
                                    if bu then bu:SetActive(curStar < maxStar) end
                                end
                            end
                        end)
                    end
                end

                pcall(function() CS.UnityEngine.Debug.unityLogger.logEnabled = true end)
                if curStar > startStar then
                    CS.Toast.ShowToast(string.format("✅ Đã nâng Bảo Vật: %d★ -> %d★ (Dùng %d Chảo Sắt, %d Phôi)!", startStar, curStar, totalChaoUsed, totalPhoiUsed))
                elseif stopReason then
                    CS.Toast.ShowToast("?? " .. stopReason)
                end
            end)
            pcall(function() CS.UnityEngine.Debug.unityLogger.logEnabled = true end)
            if not ok then
                CS.Toast.ShowToast("Lỗi nâng Bảo Vật: " .. tostring(err))
            end
            _G.HTPS_ARTIFACT_MAX_RUNNING = false
            _G.HTPS_UpdateArtifactBtnUI("Auto Nâng Max")
        end)
    end

    _G.HTPS_EnsureArtifactUpgradeButtons = function()
        local BF = CS.System.Reflection.BindingFlags.Public | CS.System.Reflection.BindingFlags.NonPublic | CS.System.Reflection.BindingFlags.Instance | CS.System.Reflection.BindingFlags.Static

        -- 1. Tr?n PopupUpgradeArtifact (ch? thao t?c khi popup ?ang m? trong scene, tuy?t ??i kh?ng ??ng v?o prefab)
        pcall(function()
            local p = _G.HTPS_FindObjectOfType(typeof(CS.PopupUpgradeArtifact))
            if not p or p:Equals(nil) or not p.gameObject.activeInHierarchy or not p.gameObject.scene:IsValid() then return end

            local body = p.m_GoContent and p.m_GoContent.transform
            if not body then return end
            local boxUpgrade = body:Find("BoxUpgrade")
            if not boxUpgrade then return end
            local btnUpgradeTf = boxUpgrade:Find("ButtonUpgrade")
            if not btnUpgradeTf then return end

            local origRt = btnUpgradeTf:GetComponent(typeof(UG.RectTransform))
            if origRt then
                origRt.anchoredPosition = UG.Vector2(-95.0, -97.2)
            end

            local btnAutoTf = boxUpgrade:Find("BtnHTPSAutoMaxArtifact")
            if not btnAutoTf then
                local cloneGo = GO.Instantiate(btnUpgradeTf.gameObject, boxUpgrade, false)
                cloneGo.name = "BtnHTPSAutoMaxArtifact"
                cloneGo:SetActive(true)
                local rt = cloneGo:GetComponent(typeof(UG.RectTransform))
                if rt then
                    rt.anchoredPosition = UG.Vector2(95.0, -97.2)
                    rt.sizeDelta = UG.Vector2(175.0, 60.0)
                end
                local txt = cloneGo:GetComponentInChildren(typeof(UG.UI.Text), true)
                if txt then
                    local loc = txt.gameObject:GetComponent(typeof(CS.I2.Loc.Localize))
                    if loc then UG.Object.DestroyImmediate(loc) end
                    local checker = txt.gameObject:GetComponent(typeof(CS.TextLocalizeChecker))
                    if checker then UG.Object.DestroyImmediate(checker) end
                    txt.alignment = UG.TextAnchor.MiddleCenter
                    txt.fontSize = 20
                    txt.text = "Auto Nâng Max"
                    _G.HTPS_BTN_MAX_ARTIFACT_TXT = txt
                end
                btnAutoTf = cloneGo.transform
            end

            if btnAutoTf then
                btnAutoTf.gameObject:SetActive(true)
                local txt = btnAutoTf:GetComponentInChildren(typeof(UG.UI.Text), true)
                if txt then
                    _G.HTPS_BTN_MAX_ARTIFACT_TXT = txt
                    if not _G.HTPS_ARTIFACT_MAX_RUNNING then
                        txt.text = "Auto Nâng Max"
                    end
                end
                local bc = btnAutoTf:GetComponent(typeof(UG.UI.Button))
                if bc and _G.HTPS_BOUND_MAX_ARTIFACT_BTN ~= bc then
                    _G.HTPS_BOUND_MAX_ARTIFACT_BTN = bc
                    bc.onClick = UG.UI.Button.ButtonClickedEvent()
                    bc.onClick:AddListener(function()
                        _G.HTPS_RunAutoMaxArtifact()
                    end)
                end
            end
        end)

        -- 2. Tr?n PopupItemInfo (khi b?m v?o B?o V?t ?ang ?eo tr?n t??ng)
        pcall(function()
            local pii = _G.HTPS_FindObjectOfType(typeof(CS.PopupItemInfo))
            if not pii or pii:Equals(nil) or not pii.gameObject.activeInHierarchy or not pii.gameObject.scene:IsValid() then return end

            local f = pii:GetType():GetFields(BF)
            local pb, b1, bu, ic
            for i = 0, f.Length - 1 do
                local fn = f[i].Name
                if fn == "m_PanelButton" then pb = f[i]:GetValue(pii)
                elseif fn == "m_GoButtonAction1" then b1 = f[i]:GetValue(pii)
                elseif fn == "m_GoButtonUpgrade" then bu = f[i]:GetValue(pii)
                elseif fn == "m_ItemData" then ic = f[i]:GetValue(pii)
                end
            end

            local isUpgradableArtifact = false
            if ic and ic:GetType().Name == "ItemArtifact" and bu and bu.activeSelf then
                local curStar = tonumber(ic.m_Star) or 1
                local maxStar = tonumber(ic:GetMaxStar()) or 6
                if curStar < maxStar then
                    isUpgradableArtifact = true
                end
            end

            -- N?u prefab PopupUpgradeArtifact b? m?t trong phi?n hi?n t?i, b?m n?t N?ng C?p g?c c?ng t? ch?y Auto N?ng Max lu?n
            if isUpgradableArtifact and bu then
                local prefabCheck = CS.UnityEngine.Resources.Load("Prefabs/ItemInfo/PopupUpgradeArtifact")
                if not prefabCheck or prefabCheck:Equals(nil) then
                    pii:SetUpgradeCallback(function()
                        _G.HTPS_RunAutoMaxArtifact()
                    end)
                end
            end

            if pb and b1 then
                local existing = pb.transform:Find("BtnHTPSAutoMaxArtPII")
                local btnGo = existing and existing.gameObject or nil
                if not btnGo and isUpgradableArtifact then
                    btnGo = GO.Instantiate(b1, pb.transform, false)
                    btnGo.name = "BtnHTPSAutoMaxArtPII"
                    local rt = btnGo:GetComponent(typeof(UG.RectTransform))
                    if rt then
                        rt.sizeDelta = UG.Vector2(175.0, 60.0)
                    end
                    local txt = btnGo:GetComponentInChildren(typeof(UG.UI.Text), true)
                    if txt then
                        local loc = txt.gameObject:GetComponent(typeof(CS.I2.Loc.Localize))
                        if loc then UG.Object.DestroyImmediate(loc) end
                        local checker = txt.gameObject:GetComponent(typeof(CS.TextLocalizeChecker))
                        if checker then UG.Object.DestroyImmediate(checker) end
                        txt.alignment = UG.TextAnchor.MiddleCenter
                        txt.fontSize = 20
                        txt.text = "Auto Nâng Max"
                        _G.HTPS_BTN_MAX_ARTIFACT_PII_TXT = txt
                    end
                end

                if btnGo then
                    if btnGo.activeSelf ~= isUpgradableArtifact then
                        btnGo:SetActive(isUpgradableArtifact)
                        UG.UI.LayoutRebuilder.ForceRebuildLayoutImmediate(pb:GetComponent(typeof(UG.RectTransform)))
                    end
                    if isUpgradableArtifact then
                        local txt = btnGo:GetComponentInChildren(typeof(UG.UI.Text), true)
                        if txt then
                            _G.HTPS_BTN_MAX_ARTIFACT_PII_TXT = txt
                            if not _G.HTPS_ARTIFACT_MAX_RUNNING then
                                txt.text = "Auto Nâng Max"
                            end
                        end
                        local bc = btnGo:GetComponent(typeof(UG.UI.Button))
                        if bc and _G.HTPS_BOUND_MAX_ARTIFACT_PII_BTN ~= bc then
                            _G.HTPS_BOUND_MAX_ARTIFACT_PII_BTN = bc
                            bc.onClick = UG.UI.Button.ButtonClickedEvent()
                            bc.onClick:AddListener(function()
                                _G.HTPS_RunAutoMaxArtifact()
                            end)
                        end
                    end
                end
            end
        end)
    end

    local origEnsureSpecial3 = _G.HTPS_EnsureSpecialEquipButtons
    _G.HTPS_EnsureSpecialEquipButtons = function()
        if origEnsureSpecial3 then origEnsureSpecial3() end
        if _G.HTPS_EnsureHeroStarUpgradeButtons then _G.HTPS_EnsureHeroStarUpgradeButtons() end
        if _G.HTPS_EnsurePlayerInfoButtons then _G.HTPS_EnsurePlayerInfoButtons() end
        if _G.HTPS_EnsureShopNewButtons then _G.HTPS_EnsureShopNewButtons() end
        if _G.HTPS_EnsureLuckySpinButtons then _G.HTPS_EnsureLuckySpinButtons() end
        if _G.HTPS_EnsureForgeButtons then _G.HTPS_EnsureForgeButtons() end
        if _G.HTPS_EnsureArenaButtons then _G.HTPS_EnsureArenaButtons() end
        if _G.HTPS_EnsureDungeonButtons then _G.HTPS_EnsureDungeonButtons() end
        if _G.HTPS_EnsureEventRaidButtons then _G.HTPS_EnsureEventRaidButtons() end
        if _G.HTPS_EnsureAltarButtons then _G.HTPS_EnsureAltarButtons() end
        if _G.HTPS_EnsureCampaignButtons then _G.HTPS_EnsureCampaignButtons() end
        if _G.HTPS_EnsureItemInfoButtons then _G.HTPS_EnsureItemInfoButtons() end
        if _G.HTPS_EnsureSkyIslandButtons then _G.HTPS_EnsureSkyIslandButtons() end
        if _G.HTPS_EnsureGuildBossButtons then _G.HTPS_EnsureGuildBossButtons() end
        if _G.HTPS_EnsureTavernButtons then _G.HTPS_EnsureTavernButtons() end
        if _G.HTPS_EnsureTTHBossButtons then _G.HTPS_EnsureTTHBossButtons() end
        if _G.HTPS_EnsurePetButtons then _G.HTPS_EnsurePetButtons() end
        if _G.HTPS_EnsureHeroBagExpandButtons then _G.HTPS_EnsureHeroBagExpandButtons() end
        if _G.HTPS_EnsureEXCButtons then _G.HTPS_EnsureEXCButtons() end
        if _G.HTPS_EnsurePetSummonButtons then _G.HTPS_EnsurePetSummonButtons() end
        if _G.HTPS_EnsurePetAwakenButtons then _G.HTPS_EnsurePetAwakenButtons() end
    end
        
    -- =========================================================================
    -- AUTO THIÊN PHÚ / VIỆN TRỢ (HOLY BLESSING) - TỰ NÂNG CẤP & ĐỘT PHÁ SAO
    -- TỰ ĐỘNG MỞ PHÔI TƯỚNG 5★ TỪ MẢNH GHÉP KHI THIẾU
    -- =========================================================================
    
    -- =========================================================================

    -- =========================================================================

    _G.HTPS_HLB_AUTO_RUNNING = false

    _G.HTPS_UpdateHLBBtnUI = function(label)
        pcall(function()
            local go = GO.Find("HLBPanelMain(Clone)/Content/BtnHTPSAutoHLB")
            if go then
                local txt = go:GetComponentInChildren(typeof(UG.UI.Text), true)
                if txt then txt.text = label or (_G.HTPS_HLB_AUTO_RUNNING and "Đang Nâng... [Dừng]" or "Auto Thiên Phú") end
            end
        end)
    end

    -- Hook HLBPanelMain:loadBlessingData to keep canonical state
    if HLBPanelMain and not HLBPanelMain._htps_hooked then
        local origLoad = HLBPanelMain.loadBlessingData
        HLBPanelMain.loadBlessingData = function(self, blessingData)
            _G.HTPS_CurrentHLBPanel = self
            _G.HTPS_CurrentBlessingData = blessingData
            return origLoad(self, blessingData)
        end
        HLBPanelMain._htps_hooked = true
    end

    -- Global helper to open hero from selector chests (Tuỳ chọn L1, L2, etc.)
    _G.HTPS_OpenHeroFromSelectorChest = function(targetK5, countToOpen)
        local inv = CS.PlayerInventory.GetInstance()
        local csDbMng = CS.DbManager.GetInstance()
        local gc = CS.GameContext.GetIntance()
        local nc = CS.NetworkController.GetInstance()
        if not inv or not csDbMng or not gc or not nc or not countToOpen or countToOpen <= 0 then return 0 end

        local chestCandidates = {53, 54, 10028}
        local lstCons = inv:GetType():GetField("m_LstItemConsumable", 60):GetValue(inv)
        local allChestKeys = {}
        for _, k in ipairs(chestCandidates) do table.insert(allChestKeys, k) end
        if lstCons then
            for i = 0, lstCons.Count - 1 do
                local ic = lstCons[i]
                if ic and ic.m_Number > 0 and ic.m_ItemKey ~= 53 and ic.m_ItemKey ~= 54 and ic.m_ItemKey ~= 10028 then
                    if ic.m_BonusPreview and ic.m_BonusPreview.m_LstBonusHero and ic.m_BonusPreview.m_LstBonusHero.Count > 0 then
                        table.insert(allChestKeys, ic.m_ItemKey)
                    end
                end
            end
        end

        local totalOpened = 0
        local remain = countToOpen

        for _, cKey in ipairs(allChestKeys) do
            if remain <= 0 then break end
            local haveNum = tonumber(inv:GetNumberItemConsumable(cKey)) or 0
            if haveNum > 0 then
                local dbIc = csDbMng:GetItemConsumable(cKey)
                if dbIc and dbIc.m_BonusPreview and dbIc.m_BonusPreview.m_LstBonusHero then
                    local lstBH = dbIc.m_BonusPreview.m_LstBonusHero
                    local targetRewardIndex = nil
                    for j = 0, lstBH.Count - 1 do
                        local bh = lstBH[j]
                        if bh and bh.m_HeroKey == targetK5 then
                            targetRewardIndex = (bh.m_IndexReward ~= nil and bh.m_IndexReward >= 0) and bh.m_IndexReward or j
                            break
                        end
                    end

                    if targetRewardIndex ~= nil then
                        local take = math.min(remain, haveNum)
                        local hName = (csDbMng:GetHeroModel(targetK5) and csDbMng:GetHeroModel(targetK5).m_HeroName) or ("Hero " .. targetK5)
                        local cName = dbIc.m_ItemName or ("Rương " .. cKey)
                        CS.Toast.ShowToast(string.format("🎁 Đang mở %d phôi [%s] từ [%s]...", take, hName, cName))

                        local cv = CS.pbdson.CommonVector()
                        cv.aLong:Add(1)
                        cv.aLong:Add(cKey)
                        cv.aLong:Add(take)
                        cv.aLong:Add(targetRewardIndex)

                        local act = CS.pbdson.PbAction()
                        act.actionId = 254
                        act.data = _G.HTPS_SerializeProto(cv)

                        local req = CS.pbdson.RequestData()
                        req.session = gc.m_Session
                        req.actions:Add(act)

                        local url = nc.m_UrlGameServer .. "/i/254/" .. tostring(gc.m_UserId)
                        local data, ok = _G.HTPS_PutWebRequest(url, _G.HTPS_SerializeProto(req), 8)
                        if ok and data then
                            local resp = _G.HTPS_DeserializeProto(data, "pbdson.ResponseData,PbMethodLib")
                            if resp and resp.aAction then
                                for aIdx = 0, resp.aAction.Count - 1 do
                                    local a = resp.aAction[aIdx]
                                    if a.actionId == 254 and a.data then
                                        local rcv = _G.HTPS_DeserializeProto(a.data, "pbdson.CommonVector,PbMethodLib")
                                        if rcv and rcv.aLong then
                                            pcall(function() CS.BonusModel.ParseBonusReceived(rcv.aLong, true) end)
                                        end
                                    end
                                end
                            end
                            totalOpened = totalOpened + take
                            remain = remain - take
                        end
                    end
                end
            end
        end

        return totalOpened
    end

    _G.HTPS_ToggleAutoHLB = function()
        if _G.HTPS_HLB_AUTO_RUNNING then
            _G.HTPS_HLB_AUTO_RUNNING = false
            _G.HTPS_UpdateHLBBtnUI("Auto Thiên Phú")
            CS.Toast.ShowToast("⏹ Đã dừng Auto Thiên Phú!")
            return
        end

        local phi = _G.HTPS_FindObjectOfType(typeof(CS.PanelHeroInfo))
        local curHm = phi and phi:GetType():GetField("currentHeroModel", 60):GetValue(phi)
        if not curHm then
            CS.Toast.ShowToast("⚠️ Vui lòng mở giao diện Tướng / Thiên Phú!")
            return
        end

        local heroId = curHm.m_HeroId
        local heroName = tostring(curHm.m_HeroName or "Tướng")
        local curStar = tonumber(curHm.m_Star) or 0
        if curStar < 10 then
            CS.Toast.ShowToast("⚠️ Thiên phú chỉ mở cho tướng từ 10★ trở lên!")
            return
        end

        _G.HTPS_HLB_AUTO_RUNNING = true
        _G.HTPS_UpdateHLBBtnUI("Đang Nâng... [Dừng]")
        CS.Toast.ShowToast(string.format("🚀 Bắt đầu Auto Thiên Phú (Nâng Max) cho [%s]...", heroName))

        CsCoroutine.start(function()
            local dbMng = _G.HLBDbManager and _G.HLBDbManager:instance()
            local sender = _G.HLBDataSender and _G.HLBDataSender:instance()
            local inv = CS.PlayerInventory.GetInstance()
            local csDbMng = CS.DbManager.GetInstance()
            local maxLv = (dbMng and dbMng:getLevelMax()) or 50

            local totalLevelsUp = 0
            local totalStarsUp = 0
            local stopReason = nil

            local function getLiveBd()
                local uim = UIUpdateMng and UIUpdateMng:instance()
                if uim and uim.listUpdateListener then
                    for i = 1, uim.listUpdateListener:count() do
                        local h = uim.listUpdateListener:getAt(i)
                        if h and h.blessingData and h.blessingData.heroId == heroId and h.blessingData.level then
                            return h.blessingData
                        end
                    end
                end
                local dbBd = dbMng and dbMng:getHeroBlessingModel(heroId)
                if dbBd and dbBd.level then return dbBd end
                return nil
            end

            local function waitMutation()
                local timer = 0
                while sender and sender.pendingMutation and timer < 3.0 do
                    coroutine.yield(UG.WaitForSeconds(0.04))
                    timer = timer + 0.04
                end
                coroutine.yield(UG.WaitForSeconds(0.08))
            end

            local function collectCopies(k5)
                local cands = {}
                local lstH = inv:GetListHeroModel()
                for i = 0, lstH.Count - 1 do
                    local h = lstH[i]
                    if h and h.m_HeroId ~= heroId and not h:IsHeroLock() then
                        if tonumber(h.m_Star) == 5 and (tonumber(h.m_Level) or 1) <= 1 then
                            if tonumber(h.m_HeroKey) == k5 then
                                table.insert(cands, h)
                            end
                        end
                    end
                end
                return cands
            end

            local function openMissingCopies(k5, deficit)
                if deficit <= 0 then return true end
                local remain = deficit

                -- 1. Ưu tiên mở từ mảnh ghép riêng của tướng
                local sh = inv:GetShard(k5)
                local numShards = (sh and tonumber(sh.m_Number)) or 0
                local canOpen = math.floor(numShards / 50)
                local toOpen = math.min(remain, canOpen)
                if toOpen > 0 then
                    CS.Toast.ShowToast(string.format("📦 Đang mở %d phôi 5★ [%s] từ mảnh ghép...", toOpen, heroName))
                    local cv = CS.pbdson.CommonVector()
                    cv.aLong:Add(2)
                    cv.aLong:Add(k5)
                    cv.aLong:Add(toOpen)
                    local act = CS.pbdson.PbAction()
                    act.actionId = 254
                    act.data = _G.HTPS_SerializeProto(cv)
                    local req = CS.pbdson.RequestData()
                    req.session = CS.GameContext.GetIntance().m_Session
                    req.actions:Add(act)
                    local url = CS.NetworkController.GetInstance().m_UrlGameServer .. "/i/254/" .. tostring(CS.GameContext.GetIntance().m_UserId)
                    local data, ok = _G.HTPS_PutWebRequest(url, _G.HTPS_SerializeProto(req), 8)
                    if ok and data then
                        local resp = _G.HTPS_DeserializeProto(data, "pbdson.ResponseData,PbMethodLib")
                        if resp and resp.aAction then
                            for aIdx = 0, resp.aAction.Count - 1 do
                                local a = resp.aAction[aIdx]
                                if a.actionId == 254 and a.data then
                                    local rcv = _G.HTPS_DeserializeProto(a.data, "pbdson.CommonVector,PbMethodLib")
                                    if rcv and rcv.aLong then
                                        pcall(function() CS.BonusModel.ParseBonusReceived(rcv.aLong, true) end)
                                    end
                                end
                            end
                        end
                        remain = remain - toOpen
                    end
                end

                -- 2. Nếu vẫn còn thiếu, tự động lấy từ Rương/Túi Thuyền Viên SS - Tuỳ Chọn L1, L2 hoặc Rương tùy chọn
                if remain > 0 and _G.HTPS_OpenHeroFromSelectorChest then
                    local openedFromChests = _G.HTPS_OpenHeroFromSelectorChest(k5, remain)
                    remain = remain - openedFromChests
                end

                return remain <= 0
            end

            -- Initial state check
            local initBd = getLiveBd()
            if not initBd or (initBd.blessingUnlock == false) then
                if sender then sender:getBlessingStatus(heroId) end
                coroutine.yield(UG.WaitForSeconds(0.35))
                initBd = getLiveBd()
            end

            if not initBd then
                _G.HTPS_HLB_AUTO_RUNNING = false
                _G.HTPS_UpdateHLBBtnUI("Auto Thiên Phú")
                CS.Toast.ShowToast("⚠️ Vui lòng mở bảng Thiên phú trước khi bấm Auto!")
                return
            end

            -- Default to table 1 if none chosen
            if not initBd.skillTableId or initBd.skillTableId <= 0 then
                if sender then sender:selectSkillTable(heroId, 1) end
                waitMutation()
                initBd = getLiveBd()
            end

            local curLv = tonumber(initBd and initBd.level) or 1
            local bStar = tonumber(initBd and initBd.star) or 0

            while _G.HTPS_HLB_AUTO_RUNNING do
                local curBd = getLiveBd()
                if curBd and curBd.heroId == heroId and curBd.level then
                    curLv = math.max(curLv, tonumber(curBd.level) or curLv)
                    bStar = math.max(bStar, tonumber(curBd.star) or bStar)
                end

                local lookupLv = math.min(math.max(1, curLv), maxLv)
                local lvUpInfo = dbMng and dbMng:getLevelUpInfo(lookupLv)
                if not lvUpInfo then
                    stopReason = "Không tìm thấy dữ liệu cấp độ tiếp theo!"
                    break
                end

                local targetStar = tonumber(lvUpInfo.starNext) or 0
                local needStarUp = (targetStar > 0 and bStar < targetStar)

                -- Dừng khi đã đạt cấp 50 VÀ đã đột phá đủ 6 sao
                if curLv >= maxLv and not needStarUp then
                    stopReason = string.format("Đã đạt CẤP TỐI ĐA Thiên phú (Lv %d, %d★)!", maxLv, bStar)
                    break
                end

                if needStarUp then
                    _G.HTPS_UpdateHLBBtnUI(string.format("Đột Phá %d★...", targetStar))

                    local bonusStarCost = lvUpInfo:getBonusCostStarUp()
                    local csLstCost = bonusStarCost:ToListModelObject()
                    local lackMat = false
                    for i = 0, csLstCost.Count - 1 do
                        local c = csLstCost[i]
                        local have = tonumber(inv:GetNumberItemConsumable(c.m_ItemKey)) or 0
                        if have < c.m_Number then
                            lackMat = true
                            local ic = csDbMng:GetItemConsumable(c.m_ItemKey)
                            stopReason = string.format("Thiếu nguyên liệu [%s] (Cần %d, có %d)!",
                                (ic and ic.m_ItemName or ("Vật phẩm #" .. c.m_ItemKey)), c.m_Number, have)
                            break
                        end
                    end
                    if lackMat then break end

                    local k5 = csDbMng:GetKeyHero5StarFromHero10Star(curHm.m_HeroKey)
                    if k5 <= 0 then k5 = curHm.m_HeroKey end
                    local reqCopy = tonumber(lvUpInfo.copy) or 1

                    local cands = collectCopies(k5)
                    if #cands < reqCopy then
                        local deficit = reqCopy - #cands
                        openMissingCopies(k5, deficit)
                        coroutine.yield(UG.WaitForSeconds(0.25))
                        cands = collectCopies(k5)
                    end

                    if #cands < reqCopy then
                        local hmDb = csDbMng:GetHeroModel(k5)
                        local cName = (hmDb and hmDb.m_HeroName) or heroName
                        stopReason = string.format("Không đủ phôi 5★ [%s] (Cần %d, có %d con)!", cName, reqCopy, #cands)
                        break
                    end

                    local lstHeroFoodId = GList:new()
                    for k = 1, reqCopy do
                        lstHeroFoodId:add(cands[k].m_HeroId)
                    end

                    if sender then
                        sender:starUp(heroId, lstHeroFoodId)
                    end
                    waitMutation()
                    coroutine.yield(UG.WaitForSeconds(0.25))

                    bStar = math.max(bStar, targetStar)
                    totalStarsUp = totalStarsUp + 1
                else
                    _G.HTPS_UpdateHLBBtnUI(string.format("Nâng Lv %d...", curLv + 1))

                    local bonusLvCost = lvUpInfo:getBonusCostLevelUp()
                    local csLstCost = bonusLvCost:ToListModelObject()
                    local lackMat = false
                    for i = 0, csLstCost.Count - 1 do
                        local c = csLstCost[i]
                        local have = tonumber(inv:GetNumberItemConsumable(c.m_ItemKey)) or 0
                        if have < c.m_Number then
                            lackMat = true
                            local ic = csDbMng:GetItemConsumable(c.m_ItemKey)
                            stopReason = string.format("Thiếu nguyên liệu [%s] (Cần %d, có %d)!",
                                (ic and ic.m_ItemName or ("Vật phẩm #" .. c.m_ItemKey)), c.m_Number, have)
                            break
                        end
                    end
                    if lackMat then break end

                    if sender then
                        sender:levelUp(heroId)
                    end
                    waitMutation()
                    coroutine.yield(UG.WaitForSeconds(0.08))

                    curLv = curLv + 1
                    totalLevelsUp = totalLevelsUp + 1
                end

                coroutine.yield(UG.WaitForSeconds(0.04))
            end

            _G.HTPS_HLB_AUTO_RUNNING = false
            _G.HTPS_UpdateHLBBtnUI("Auto Thiên Phú")

            if stopReason and (totalLevelsUp == 0 and totalStarsUp == 0) then
                CS.Toast.ShowToast("⚠️ " .. stopReason)
            else
                local msg = string.format("✅ Auto [%s] xong: +%d Cấp, +%d Sao!", heroName, totalLevelsUp, totalStarsUp)
                if stopReason then msg = msg .. " (" .. stopReason .. ")" end
                CS.Toast.ShowToast(msg)
            end
        end)
    end

    _G.HTPS_EnsureHLBButtons = function()
        pcall(function()
            local hlbGo = GO.Find("HLBPanelMain(Clone)")
            if not hlbGo or not hlbGo.activeInHierarchy then return end

            local contentTf = hlbGo.transform:Find("Content")
            if not contentTf then return end

            local btnAuto = contentTf:Find("BtnHTPSAutoHLB")
            if not btnAuto then
                local btnRef = contentTf:Find("PanelAdvance/PanelLevelUp/ButtonLvUp") or contentTf:Find("PanelAdvance/PanelStarUp/ButtonStarUp")
                if btnRef then
                    local cloneGo = GO.Instantiate(btnRef.gameObject, contentTf, false)
                    cloneGo.name = "BtnHTPSAutoHLB"
                    local rt = cloneGo:GetComponent(typeof(UG.RectTransform))
                    rt.anchoredPosition = UG.Vector2(-235.0, -240.0)
                    rt.sizeDelta = UG.Vector2(240.0, 54.0)

                    local notify = cloneGo.transform:Find("GoNotify")
                    if notify then notify.gameObject:SetActive(false) end

                    local btnComp = cloneGo:GetComponent(typeof(UG.UI.Button))
                    btnComp.onClick = UG.UI.Button.ButtonClickedEvent()
                    btnComp.onClick:AddListener(function()
                        _G.HTPS_ToggleAutoHLB()
                    end)
                    btnAuto = cloneGo.transform
                end
            end

            if btnAuto then
                btnAuto.gameObject:SetActive(true)
                local txt = btnAuto:GetComponentInChildren(typeof(UG.UI.Text), true)
                if txt then
                    txt.fontSize = 20
                    if not _G.HTPS_HLB_AUTO_RUNNING then
                        txt.text = "Auto Thiên Phú"
                    end
                end
            end
        end)
    end

    -- =========================================================================
    -- AUTO RÚT ALBUM (MỞ MẢNH ẢNH ĐẾN KHI FULL MỐC / FULL ẢNH)
    -- =========================================================================
    _G.HTPS_AUTO_ALBUM_RUNNING = false
    _G.HTPS_AlbumRollPending = false
    _G.HTPS_CurrentPanelRoll = nil
    _G.HTPS_ALBUM_HOOKED = false

    _G.HTPS_StopAutoAlbum = function(reason)
        if _G.HTPS_AUTO_ALBUM_RUNNING then
            _G.HTPS_AUTO_ALBUM_RUNNING = false
            _G.HTPS_AlbumRollPending = false
            if _G.HTPS_UpdateAlbumBtnUI then
                _G.HTPS_UpdateAlbumBtnUI("AUTO RÚT", false)
            end
            pcall(function()
                for _, pName in ipairs({"PopupShowBonusEffect(Clone)", "PopupShowBonus(Clone)", "PopupShowBonusEffect2(Clone)", "PopupBlockTouch(Clone)"}) do
                    local pGo = GO.Find(pName)
                    if pGo and not pGo:Equals(nil) then
                        pGo:SetActive(false)
                        GO.Destroy(pGo)
                    end
                end
            end)
            if reason and CS.Toast then
                CS.Toast.ShowToast(reason)
            end
        end
    end

    _G.HTPS_FormatAlbumAutoButtonText = function(btnAuto, isRunning, customLabel)
        if not btnAuto then return end
        local txts = btnAuto:GetComponentsInChildren(typeof(UG.UI.Text), true)
        for i = 0, txts.Length - 1 do
            local t = txts[i]
            if t.gameObject.name == "NumRequire" then
                t.gameObject:SetActive(false)
            else
                t.gameObject:SetActive(true)
                local rtT = t:GetComponent(typeof(UG.RectTransform))
                if rtT then
                    rtT.anchorMin = UG.Vector2(0, 0)
                    rtT.anchorMax = UG.Vector2(1, 1)
                    rtT.pivot = UG.Vector2(0.5, 0.5)
                    rtT.offsetMin = UG.Vector2(0, 0)
                    rtT.offsetMax = UG.Vector2(0, 0)
                    rtT.anchoredPosition = UG.Vector2(0, 0)
                    rtT.sizeDelta = UG.Vector2(0, 0)
                end
                t.alignment = CS.UnityEngine.TextAnchor.MiddleCenter
                t.horizontalOverflow = CS.UnityEngine.HorizontalWrapMode.Overflow
                t.verticalOverflow = CS.UnityEngine.VerticalWrapMode.Overflow
                t.fontSize = 18
                t.text = customLabel or (isRunning and "DỪNG AUTO" or "AUTO RÚT")
                t.color = isRunning and UG.Color(1, 0.3, 0.3, 1) or UG.Color(1, 1, 1, 1)
            end
        end
    end

    _G.HTPS_UpdateAlbumBtnUI = function(label, isRunning)
        pcall(function()
            local rollGo = GO.Find("PanelRollPicture")
            if rollGo then
                local btnAuto = rollGo.transform:Find("BtnHTPSAutoRollAlbum")
                                or GO.Find("BtnHTPSAutoRollAlbum")
                if not btnAuto then
                    local tfList = GO.Find("tfListPicAndRoll")
                    if tfList then
                        btnAuto = tfList.transform:Find("PanelRollPicture/BtnHTPSAutoRollAlbum")
                    end
                end
                if btnAuto then
                    _G.HTPS_FormatAlbumAutoButtonText(btnAuto, isRunning, label)
                end
            end
        end)
    end

    _G.HTPS_HookAlbumSystem = function()
        if _G.HTPS_ALBUM_HOOKED then return end
        if _G.PanelRollPictureUI and _G.PanelRollPictureUI.initPanel then
            _G.HTPS_ALBUM_HOOKED = true
            local orig_init = _G.PanelRollPictureUI.initPanel
            _G.PanelRollPictureUI.initPanel = function(self, ...)
                local ret = orig_init(self, ...)
                _G.HTPS_CurrentPanelRoll = self
                pcall(function()
                    if _G.HTPS_EnsureAlbumAutoButtons then
                        _G.HTPS_EnsureAlbumAutoButtons()
                    end
                end)
                return ret
            end

            local orig_disp = _G.PanelRollPictureUI.dispose
            _G.PanelRollPictureUI.dispose = function(self, ...)
                if _G.HTPS_AUTO_ALBUM_RUNNING then
                    _G.HTPS_StopAutoAlbum("Đã đóng giao diện Album!")
                end
                _G.HTPS_CurrentPanelRoll = nil
                if orig_disp then return orig_disp(self, ...) end
            end

            local orig_proc = _G.PanelRollPictureUI.processKEvent
            if orig_proc then
                _G.PanelRollPictureUI.processKEvent = function(self, serviceId, bytesData, ...)
                    if serviceId == 711 and _G.HTPS_AUTO_ALBUM_RUNNING then -- AlbumDataSender.ALBUM_ROLL
                        _G.HTPS_AlbumRollPending = false
                        -- Fast update without popup or flying tween animation
                        local procOk, procErr = pcall(function()
                            local lcv = NetworkController:instance():deserializeProto(bytesData, BaseDataSender.ListCommonVector)
                            local albumId = lcv.aVector[0].aLong[0]
                            local imageId = lcv.aVector[0].aLong[1]
                            local fragmentIndex = lcv.aVector[0].aLong[2]
                            local newFee = lcv.aVector[0].aLong[3]

                            if _G.AlbumStaticVar and _G.AlbumStaticVar.ListPictureInfo then
                                for i = 1, _G.AlbumStaticVar.ListPictureInfo:count() do
                                    local pictureInfo = _G.AlbumStaticVar.ListPictureInfo:getAt(i)
                                    if pictureInfo.albumId == albumId and pictureInfo.pictureId == imageId then
                                        self.isFragmentOwned = pictureInfo.listFragment:getAt(fragmentIndex + 1).fragmentStatus
                                        
                                        -- Instant grid active (no 1.5s delay!)
                                        if self.panelGridPictureUI and self.panelGridPictureUI.SetGridActive then
                                            self.panelGridPictureUI:SetGridActive(fragmentIndex)
                                        end
                                        pictureInfo.listFragment:getAt(fragmentIndex + 1).fragmentStatus = 1

                                        local openedCount = 0
                                        for j = 1, pictureInfo.listFragment:count() do
                                            if pictureInfo.listFragment:getAt(j).fragmentStatus == 1 then
                                                openedCount = openedCount + 1
                                            end
                                        end
                                        self:changeProgress(openedCount, self.imageInfo.numberMax)

                                        if (openedCount == self.imageInfo.numberMax) then
                                            _G.AlbumStaticVar.IsOpenedFullAlbum = true
                                            if self.btnRoll then self.btnRoll:SetActive(false) end
                                        end
                                        self.imageInfo.numberCurrent = openedCount
                                    end
                                end
                            end

                            -- Check complete pictures
                            if (lcv.aVector[1].aLong.Count > 0) then
                                for j = 0, lcv.aVector[1].aLong.Count - 1 do
                                    if j % 2 == 0 then
                                        local aId = lcv.aVector[1].aLong[j]
                                        local pId = lcv.aVector[1].aLong[j + 1]
                                        local pictureComplete = { albumId = aId, pictureId = pId }
                                        if _G.AlbumStaticVar and _G.AlbumStaticVar.ListPictureComplete and not _G.AlbumStaticVar.ListPictureComplete:contains(pictureComplete) then
                                            _G.AlbumStaticVar.ListPictureComplete:add(pictureComplete)
                                        end
                                    end
                                end
                            end

                            -- Credit normal rewards into inventory
                            local bonus = lcv.aVector[2].aLong
                            CS.BonusModel.ParseBonusReceived(bonus)

                            -- Update fee
                            self:changFee(newFee)
                            self.imageInfo.feeOpen = newFee

                            -- Credit extra bonus directly without showing PopupShowBonusEffect!
                            if lcv.aVector[3].aLong.Count > 0 then
                                local bonusExtra = lcv.aVector[3].aLong
                                CS.BonusModel.ParseBonusReceived(bonusExtra)
                            end

                            -- Update material count
                            local newNumberCard = CS.PlayerInventory.GetInstance():GetNumberItemConsumable(PanelAlbumMain.KEY_MATERIAL)
                            if self.panelAlbumMain and self.panelAlbumMain.UpdateCardCount then
                                self.panelAlbumMain:UpdateCardCount(newNumberCard)
                            end
                        end)
                        if not procOk then
                            print("HTPS Auto Album Fast Process Error:", procErr)
                        end
                        return
                    else
                        local res = orig_proc(self, serviceId, bytesData, ...)
                        if serviceId == 711 then
                            _G.HTPS_AlbumRollPending = false
                        end
                        return res
                    end
                end
            end
        end
    end

    _G.HTPS_ToggleAutoAlbum = function()
        if not _G.HTPS_AUTO_ACTIVATED then
            if CS.Toast then CS.Toast.ShowToast("⚠️ Vui lòng kích hoạt bản quyền VIP để dùng tính năng này!") end
            if _G.HTPS_ShowActivationDialog then _G.HTPS_ShowActivationDialog(true) end
            return
        end

        if _G.HTPS_AUTO_ALBUM_RUNNING then
            _G.HTPS_StopAutoAlbum("Đã dừng Auto Rút Album!")
            return
        end

        local albumId = nil
        local pictureId = nil
        local curInfo = nil

        if _G.HTPS_CurrentPanelRoll then
            albumId = _G.HTPS_CurrentPanelRoll.albumId
            pictureId = _G.HTPS_CurrentPanelRoll.pictureId
            curInfo = _G.HTPS_CurrentPanelRoll.imageInfo
        end

        if not albumId or not pictureId then
            if _G.AlbumStaticVar and _G.AlbumStaticVar.CurrentImageInfo then
                albumId = _G.AlbumStaticVar.CurrentImageInfo.albumId
                pictureId = _G.AlbumStaticVar.CurrentImageInfo.pictureId
                curInfo = _G.AlbumStaticVar.CurrentImageInfo
            end
        end

        if not albumId or not pictureId then
            if CS.Toast then CS.Toast.ShowToast("⚠️ Vui lòng mở ảnh trong Album cần rút trước khi bấm Auto!") end
            return
        end

        _G.HTPS_AUTO_ALBUM_RUNNING = true
        _G.HTPS_UpdateAlbumBtnUI("DỪNG AUTO", true)
        if CS.Toast then CS.Toast.ShowToast("🚀 Bắt đầu Auto Rút Album đến khi Full Mốc!") end

        CsCoroutine.start(function()
            local consecutiveErrors = 0
            while _G.HTPS_AUTO_ALBUM_RUNNING do
                -- Auto destroy any stray popups immediately so screen is never blocked
                pcall(function()
                    for _, pName in ipairs({"PopupShowBonusEffect(Clone)", "PopupShowBonus(Clone)", "PopupShowBonusEffect2(Clone)", "PopupBlockTouch(Clone)", "PopupHeroAwakenResult(Clone)"}) do
                        local pGo = GO.Find(pName)
                        if pGo and not pGo:Equals(nil) then
                            pGo:SetActive(false)
                            GO.Destroy(pGo)
                        end
                    end
                end)

                -- 1. Check license key
                if not _G.HTPS_AUTO_ACTIVATED then
                    _G.HTPS_StopAutoAlbum("Mã kích hoạt đã hết hạn!")
                    break
                end

                -- 2. Check UI visible
                local rollGo = GO.Find("PanelRollPicture")
                if not rollGo or not rollGo.activeInHierarchy then
                    _G.HTPS_StopAutoAlbum("Đã đóng giao diện Album!")
                    break
                end

                -- 3. Check current picture completion (check each fragment status)
                local pic = nil
                if _G.AlbumStaticVar and _G.AlbumStaticVar.GetImageInfo then
                    pic = _G.AlbumStaticVar.GetImageInfo(albumId, pictureId)
                end
                if not pic then
                    pic = (_G.HTPS_CurrentPanelRoll and _G.HTPS_CurrentPanelRoll.imageInfo) or (_G.AlbumStaticVar and _G.AlbumStaticVar.CurrentImageInfo)
                end

                local isFullPic = false
                local curCount = 0
                local maxCount = 0

                if pic then
                    maxCount = pic.numberMax or 0
                    if pic.listFragment and pic.listFragment.count and pic.listFragment:count() > 0 then
                        maxCount = pic.listFragment:count()
                        local unopenedCount = 0
                        local openedCount = 0
                        for i = 1, maxCount do
                            local frag = pic.listFragment:getAt(i)
                            if frag and frag.fragmentStatus == 1 then
                                openedCount = openedCount + 1
                            else
                                unopenedCount = unopenedCount + 1
                            end
                        end
                        curCount = openedCount
                        if unopenedCount == 0 and maxCount > 0 then
                            isFullPic = true
                        end
                    elseif pic.numberCurrent and pic.numberMax and pic.numberMax > 0 then
                        curCount = pic.numberCurrent
                        if pic.numberCurrent >= pic.numberMax then
                            isFullPic = true
                        end
                    end
                end

                -- Also check if the game's roll button was hidden by the game engine
                if rollGo then
                    local btnRutGo = rollGo.transform:Find("btnRut")
                    if btnRutGo and not btnRutGo.gameObject.activeSelf then
                        isFullPic = true
                    end
                end

                if isFullPic then
                    _G.HTPS_StopAutoAlbum(string.format("🎉 Chúc mừng! Đã mở hoàn thành 100%% ảnh Album (%d/%d mảnh)!", curCount, maxCount))
                    break
                end

                -- Check Thẻ huyền bí (item id 100045)
                local fee = (pic and pic.feeOpen) or 50
                local curCards = 0
                pcall(function()
                    curCards = CS.PlayerInventory.GetInstance():GetNumberItemConsumable(100045)
                end)
                if curCards < fee then
                    _G.HTPS_StopAutoAlbum(string.format("⚠️ Không đủ Thẻ huyền bí (%d/%d) để tiếp tục rút!", curCards, fee))
                    break
                end

                -- Send Roll Packet
                _G.HTPS_AlbumRollPending = true
                local sendOk = false
                pcall(function()
                    if _G.AlbumDataSender and _G.AlbumDataSender.instance then
                        _G.AlbumDataSender:instance():albumRoll(albumId, pictureId)
                        sendOk = true
                    end
                end)

                if not sendOk then
                    consecutiveErrors = consecutiveErrors + 1
                    if consecutiveErrors > 5 then
                        _G.HTPS_StopAutoAlbum("⚠️ Lỗi gửi gói tin rút Album!")
                        break
                    end
                else
                    consecutiveErrors = 0
                end

                -- Wait for packet response or timeout
                local waitT = 0
                while _G.HTPS_AlbumRollPending and waitT < 0.8 and _G.HTPS_AUTO_ALBUM_RUNNING do
                    coroutine.yield(UG.WaitForSeconds(0.05))
                    waitT = waitT + 0.05
                end

                -- High-speed yield between rolls
                coroutine.yield(UG.WaitForSeconds(0.12))
            end
        end)
    end

    _G.HTPS_EnsureAlbumAutoButtons = function()
        pcall(function()
            if not _G.HTPS_ALBUM_HOOKED then
                _G.HTPS_HookAlbumSystem()
            end

            local rollGo = GO.Find("PanelRollPicture")
            if rollGo and rollGo.activeInHierarchy then
                local btnRut = rollGo.transform:Find("btnRut")
                if btnRut and btnRut.gameObject.activeInHierarchy then
                    local parent = btnRut.parent
                    local btnAuto = parent:Find("BtnHTPSAutoRollAlbum")
                    if not btnAuto then
                        local cloneGo = GO.Instantiate(btnRut.gameObject, parent, false)
                        cloneGo.name = "BtnHTPSAutoRollAlbum"
                        cloneGo:SetActive(true)

                        local rt = cloneGo:GetComponent(typeof(UG.RectTransform))
                        local origRt = btnRut:GetComponent(typeof(UG.RectTransform))
                        if rt and origRt then
                            local w = origRt.sizeDelta.x
                            if w < 50 then w = 150 end
                            rt.anchoredPosition = UG.Vector2(origRt.anchoredPosition.x - w - 15, origRt.anchoredPosition.y)
                        end

                        local icon = cloneGo.transform:Find("icon") or cloneGo.transform:Find("Icon") or cloneGo.transform:Find("Image")
                        if icon and icon.name ~= cloneGo.name then
                            icon.gameObject:SetActive(false)
                        end

                        local feeChild = cloneGo.transform:Find("NumRequire")
                        if feeChild then
                            feeChild.gameObject:SetActive(false)
                        end

                        local bc = cloneGo:GetComponent(typeof(UG.UI.Button))
                        if bc then
                            bc.onClick = UG.UI.Button.ButtonClickedEvent()
                            bc.onClick:AddListener(function()
                                _G.HTPS_ToggleAutoAlbum()
                            end)
                        end
                        btnAuto = cloneGo.transform
                    end

                    if btnAuto then
                        btnAuto.gameObject:SetActive(btnRut.gameObject.activeSelf or _G.HTPS_AUTO_ALBUM_RUNNING)
                        _G.HTPS_FormatAlbumAutoButtonText(btnAuto, _G.HTPS_AUTO_ALBUM_RUNNING)
                    end
                end
            end
        end)
    end

        
    

    -- =========================================================================
    -- AUTO CHẾ TẠO NỘI THẤT / GIA VIÊN & TỰ ĐỘNG TÁI CHẾ TÍM + CAM (GIỮ ĐỒ ĐỎ)
    -- SIÊU TỐC ĐỘ (BATCH RECYCLE & NETWORK SYNCHRONIZATION)
    -- =========================================================================
    _G.HTPS_AUTO_FURNITURE_RUNNING = false
    _G.HTPS_FurnitureCraftPending = false
    _G.HTPS_FurnitureRecyclePending = false
    _G.HTPS_FURNITURE_HOOKED = false
    _G.HTPS_CurrentPanelShop = nil

    -- Suppress raw transport error toast during auto
    if not _G.HTPS_TOAST_FILTER_HOOKED and CS.Toast and CS.Toast.ShowToast then
        _G.HTPS_TOAST_FILTER_HOOKED = true
        local orig_toast = CS.Toast.ShowToast
        CS.Toast.ShowToast = function(msg, ...)
            if _G.HTPS_AUTO_FURNITURE_RUNNING and msg and string.find(tostring(msg), "Error occurs while sending") then
                return
            end
            return orig_toast(msg, ...)
        end
    end

    _G.HTPS_StopAutoFurnitureCraft = function(reason)
        if _G.HTPS_AUTO_FURNITURE_RUNNING then
            _G.HTPS_AUTO_FURNITURE_RUNNING = false
            _G.HTPS_FurnitureCraftPending = false
            _G.HTPS_FurnitureRecyclePending = false
            if _G.HTPS_UpdateFurnitureBtnUI then
                _G.HTPS_UpdateFurnitureBtnUI("⚡ AUTO CHẾ TẠO", false)
            end
            -- Final batch recycle on stop so bag is cleaned up (only Red items left)
            pcall(function()
                CsCoroutine.start(function()
                    _G.HTPS_DoRecyclePurpleAndOrange()
                end)
            end)
            if reason and CS.Toast then
                CS.Toast.ShowToast(reason)
            end
        end
    end

    _G.HTPS_UpdateFurnitureBtnUI = function(label, isRunning)
        pcall(function()
            local goShop = GO.Find("PanelShopFurniture(Clone)") or GO.Find("PanelShopFurniture")
            if not goShop then
                pcall(function()
                    local popupRoot = GO.Find("GroupLuaPopup"); local tfPopup = popupRoot and popupRoot.transform
                    if tfPopup then
                        local c = tfPopup:Find("PanelShopFurniture(Clone)") or tfPopup:Find("PanelShopFurniture")
                        if c then goShop = c.gameObject end
                    end
                end)
            end
            if goShop then
                local btn = goShop.transform:Find("Content/Right/nen_phai_truoc/ButtonAutoCraft")
                if btn then
                    local txt = btn:GetComponentInChildren(typeof(UG.UI.Text), true)
                    if txt then
                        txt.text = label or (isRunning and "⏹ DỪNG AUTO" or "⚡ AUTO CHẾ TẠO")
                        txt.color = isRunning and UG.Color(1, 0.3, 0.3, 1) or UG.Color(1, 1, 1, 1)
                    end
                end
            end
        end)
    end

    _G.HTPS_DoRecyclePurpleAndOrange = function()
        local bag = StaticVar and StaticVar.ListFurnitureItemInBag
        if not bag or bag:count() == 0 then return 0, 0, 0 end

        -- Wait until network line is idle
        local nc = NetworkController:instance()
        local waitT = 0
        while nc.requestInFlight and waitT < 25 do
            coroutine.yield(UG.WaitForSeconds(0.04))
            waitT = waitT + 1
        end

        local listRecycle = GList:new()
        local itemsToRemove = GList:new()
        local pCount, yCount = 0, 0

        for i = 1, bag:count() do
            local item = bag:getAt(i)
            if item and (item.itemQuality == 1 or item.itemQuality == 2) then
                listRecycle:add(item.itemId)
                itemsToRemove:add(item)
                if item.itemQuality == 1 then pCount = pCount + 1 else yCount = yCount + 1 end
            end
        end

        local totalRecycled = listRecycle:count()
        if totalRecycled > 0 then
            for i = 1, itemsToRemove:count() do
                bag:remove(itemsToRemove:getAt(i))
            end
            _G.HTPS_FurnitureRecyclePending = true
            DataSender:instance():decorRecycleFuniture(listRecycle)

            -- Wait for recycle response to complete cleanly
            local recT = 0
            while nc.requestInFlight and recT < 25 do
                coroutine.yield(UG.WaitForSeconds(0.04))
                recT = recT + 1
            end
            coroutine.yield(UG.WaitForSeconds(0.08))
        end
        return totalRecycled, pCount, yCount
    end

    _G.HTPS_CheckAndRotateWishlist = function()
        local db = ShipFurnitureDb:instance()
        local bag = StaticVar and StaticVar.ListFurnitureItemInBag
        local activeShips = db:getListShipIdActive()
        local releaseList = db:GetListHeroKeyRelease()
        local wishList = StaticVar and StaticVar.WishListHero
        if not wishList or not releaseList then return end

        local function isHeroFull(heroKey)
            local res = db:GetListItemCollectionByHeroKey(heroKey)
            if not res or not res.collection or res.collection == '' then return false, 0, 0 end
            local col = gJson.decode(res.collection)
            local totalCol = #col
            if totalCol == 0 then return false, 0, 0 end
            local ownedKeys = {}
            if bag then
                for j = 1, bag:count() do
                    local it = bag:getAt(j)
                    if db:getFurnitureHeroByKey(it.itemKey) == heroKey then
                        ownedKeys[it.itemKey] = true
                    end
                end
            end
            if activeShips then
                for s = 1, activeShips:count() do
                    local sid = activeShips:getAt(s)
                    local ds = StaticVar.DataShip(sid)
                    if ds then
                        for j = 1, ds:count() do
                            local it = ds:getAt(j)
                            if db:getFurnitureHeroByKey(it.itemKey) == heroKey then
                                ownedKeys[it.itemKey] = true
                            end
                        end
                    end
                end
            end
            local distinct = 0
            for _ in pairs(ownedKeys) do distinct = distinct + 1 end
            return (distinct >= totalCol), distinct, totalCol
        end

        local function findNextCandidate()
            local inv = CS.PlayerInventory.GetInstance()
            local lstAll = inv:GetListHeroModel()
            local e5 = CS.CollectionHeroHelper.FilterByStar(CS.CollectionHeroHelper.FilterByQuality(lstAll, 6), 15)
            for i = 0, e5.Count - 1 do
                local hm = e5[i]
                local candKey = hm.m_HeroKey
                if not wishList:contains(candKey) and releaseList:contains(candKey) then
                    local full, dist, tot = isHeroFull(candKey)
                    if not full and tot > 0 then
                        return candKey, tostring(hm.m_HeroName or hm.m_Name)
                    end
                end
            end
            return nil, nil
        end

        local changed = false
        for i = 1, wishList:count() do
            local hk = wishList:getAt(i)
            local full, dist, tot = isHeroFull(hk)
            if full then
                local candKey, candName = findNextCandidate()
                if candKey then
                    wishList:setAt(i, candKey)
                    changed = true
                    if CS.Toast then
                        CS.Toast.ShowToast(string.format("🔄 Tướng đã đủ bộ (%d/%d)! Đã tự đổi sang %s!", dist, tot, candName))
                    end
                end
            end
        end

        if changed then
            DataSender:instance():decorWishList(StaticVar.WishListHero)
        end
    end

    _G.HTPS_TryAutoEquipItemToHeroCabin = function(itemKey, itemId)
        local db = ShipFurnitureDb:instance()
        local itemHero = db:getFurnitureHeroByKey(itemKey)
        if not itemHero or itemHero <= 0 then return end

        local activeShips = db:getListShipIdActive()
        if not activeShips then return end

        for s = 1, activeShips:count() do
            local shipId = activeShips:getAt(s)
            for floorId = 1, 3 do
                local heroId = StaticVar.HeroIdInShip(floorId, shipId)
                if heroId and heroId ~= -1 then
                    local heroModel = CS.PlayerInventory.GetInstance():GetHeroModelById(heroId)
                    if heroModel and heroModel.m_HeroKey == itemHero then
                        local res = db:GetListItemCollectionByHeroKey(itemHero)
                        local col = res and res.collection and res.collection ~= '' and gJson.decode(res.collection) or nil
                        local targetSlot = nil
                        if col then
                            for slot = 1, 18 do
                                if col[slot] == itemKey then
                                    targetSlot = slot
                                    break
                                end
                            end
                        end
                        if targetSlot then
                            local inShip = StaticVar.ListFurnitureItemInShip
                            local inBag = StaticVar.ListFurnitureItemInBag
                            if inShip and inBag then
                                local alreadyEquipped = false
                                for i = 1, inShip:count() do
                                    local it = inShip:getAt(i)
                                    if it.shipId == shipId and it.floorId == floorId and it.spaceId == targetSlot then
                                        if it.itemKey == itemKey then
                                            alreadyEquipped = true
                                        end
                                        break
                                    end
                                end

                                if not alreadyEquipped then
                                    for i = inShip:count(), 1, -1 do
                                        local it = inShip:getAt(i)
                                        if it.shipId == shipId and it.floorId == floorId and it.spaceId == targetSlot then
                                            inBag:add(it)
                                            inShip:removeAt(i)
                                            break
                                        end
                                    end
                                    for j = 1, inBag:count() do
                                        local it = inBag:getAt(j)
                                        if it.itemId == itemId then
                                            inBag:removeAt(j)
                                            it.shipId = shipId
                                            it.floorId = floorId
                                            it.spaceId = targetSlot
                                            inShip:add(it)
                                            break
                                        end
                                    end
                                    local wallPaperId = (res and res.wallPaperId and res.wallPaperId ~= 0) and res.wallPaperId or StaticVar.GetWallIdInShip(floorId, shipId).wallId
                                    local parseData = StaticVar.DataParse(floorId, StaticVar.DataShip(shipId))
                                    CsCoroutine.start(function()
                                        local nc = NetworkController:instance()
                                        local waitNet = 0
                                        while nc.requestInFlight and waitNet < 25 do
                                            coroutine.yield(UG.WaitForSeconds(0.04))
                                            waitNet = waitNet + 1
                                        end
                                        DataSender:instance():decorSaveFloorChanges(parseData, shipId, floorId, wallPaperId)
                                    end)
                                    if CS.Toast then
                                        local heroName = tostring(heroModel.m_HeroName or heroModel.m_Name)
                                        CS.Toast.ShowToast(string.format("⚡ Đã tự động lắp đồ đỏ mới vào phòng của [%s]!", heroName))
                                    end
                                end
                            end
                            return
                        end
                    end
                end
            end
        end
    end

    _G.HTPS_AutoEquipAllCabins = function()
        if not _G.HTPS_AUTO_ACTIVATED then
            if CS.Toast then CS.Toast.ShowToast("⚠️ Vui lòng kích hoạt bản quyền VIP để dùng tính năng này!") end
            if _G.HTPS_ShowActivationDialog then _G.HTPS_ShowActivationDialog(true) end
            return
        end

        CsCoroutine.start(function()
            local db = ShipFurnitureDb:instance()
            local activeShips = db:getListShipIdActive()
            local inShip = StaticVar.ListFurnitureItemInShip
            local inBag = StaticVar.ListFurnitureItemInBag
            local nc = NetworkController:instance()

            if not activeShips or not inShip or not inBag then
                if CS.Toast then CS.Toast.ShowToast("⚠️ Chưa tải xong dữ liệu thuyền/nội thất!") end
                return
            end

            if CS.Toast then CS.Toast.ShowToast("🚀 Đang tự động quét & lắp nội thất chuẩn cho toàn bộ khoang...") end

            local totalRooms = 0
            local totalItemsPlaced = 0

            for s = 1, activeShips:count() do
                local shipId = activeShips:getAt(s)
                for floorId = 1, 3 do
                    local heroId = StaticVar.HeroIdInShip(floorId, shipId)
                    if heroId and heroId ~= -1 then
                        local heroModel = CS.PlayerInventory.GetInstance():GetHeroModelById(heroId)
                        local curHeroKey = heroModel and heroModel.m_HeroKey or -1
                        if curHeroKey > 0 then
                            for i = inShip:count(), 1, -1 do
                                local it = inShip:getAt(i)
                                if it.shipId == shipId and it.floorId == floorId then
                                    inBag:add(it)
                                    inShip:removeAt(i)
                                end
                            end

                            local res = db:GetListItemCollectionByHeroKey(curHeroKey)
                            local col = res and res.collection and res.collection ~= '' and gJson.decode(res.collection) or nil
                            local wallPaperId = (res and res.wallPaperId and res.wallPaperId ~= 0) and res.wallPaperId or StaticVar.GetWallIdInShip(floorId, shipId).wallId

                            local slots = {}
                            if col then
                                for slot = 1, 18 do
                                    local targetKey = col[slot]
                                    if targetKey and targetKey ~= 0 then
                                        for j = 1, inBag:count() do
                                            local it = inBag:getAt(j)
                                            if it.itemKey == targetKey then
                                                slots[slot] = it
                                                inBag:removeAt(j)
                                                break
                                            end
                                        end
                                    end
                                end
                            end

                            -- Strictly general items only for unfilled slots
                            for slot = 1, 18 do
                                if not slots[slot] then
                                    local reqPlaceType = (slot >= 10) and 1 or 2
                                    for j = 1, inBag:count() do
                                        local it = inBag:getAt(j)
                                        local h = db:getFurnitureHeroByKey(it.itemKey)
                                        if not h or h <= 0 then
                                            local pt = it.itemPlaceType
                                            local match = (reqPlaceType == 1 and pt == 1) or (reqPlaceType ~= 1 and pt ~= 1)
                                            if match then
                                                slots[slot] = it
                                                inBag:removeAt(j)
                                                break
                                            end
                                        end
                                    end
                                end
                            end

                            local roomCount = 0
                            for slot = 1, 18 do
                                local it = slots[slot]
                                if it then
                                    it.shipId = shipId
                                    it.floorId = floorId
                                    it.spaceId = slot
                                    inShip:add(it)
                                    roomCount = roomCount + 1
                                end
                            end

                            totalRooms = totalRooms + 1
                            totalItemsPlaced = totalItemsPlaced + roomCount

                            local waitNet = 0
                            while nc.requestInFlight and waitNet < 25 do
                                coroutine.yield(UG.WaitForSeconds(0.04))
                                waitNet = waitNet + 1
                            end

                            local parseData = StaticVar.DataParse(floorId, StaticVar.DataShip(shipId))
                            DataSender:instance():decorSaveFloorChanges(parseData, shipId, floorId, wallPaperId)
                            coroutine.yield(UG.WaitForSeconds(0.12))
                        end
                    end
                end
            end

            pcall(function()
                local goHome = CS.UnityEngine.GameObject.Find('PanelShipDecorHome(Clone)') or CS.UnityEngine.GameObject.Find('PanelShipDecorHome')
                if goHome and goHome.activeInHierarchy then
                    local containers = goHome.transform:Find('TabShips/Containers')
                    if containers and containers.childCount > 0 then
                        local curIdx = 0
                        for i = 0, containers.childCount - 1 do
                            local c = containers:GetChild(i)
                            local imgOff = c:Find('ImageOff')
                            if imgOff and not imgOff.gameObject.activeSelf then
                                curIdx = i
                                break
                            end
                        end
                        local otherIdx = (curIdx + 1) % containers.childCount
                        local otherBtn = containers:GetChild(otherIdx):GetComponent(typeof(CS.UnityEngine.UI.Button))
                        local curBtn = containers:GetChild(curIdx):GetComponent(typeof(CS.UnityEngine.UI.Button))
                        if otherBtn and curBtn then
                            otherBtn.onClick:Invoke()
                            CsCoroutine.start(function()
                                coroutine.yield(UG.WaitForSeconds(0.06))
                                curBtn.onClick:Invoke()
                            end)
                        end
                    end
                end
            end)

            if CS.Toast then
                CS.Toast.ShowToast(string.format("✅ Đã tự động lắp chuẩn cho %d khoang (%d nội thất)! Không lẫn đồ tướng khác!", totalRooms, totalItemsPlaced))
            end
        end)
    end

    _G.HTPS_HookFurnitureSystem = function()
        if _G.HTPS_FURNITURE_HOOKED then return end

        if _G.PanelShipDecorHome and _G.PanelShipDecorHome.initPanel then
            local orig_home_init = _G.PanelShipDecorHome.initPanel
            _G.PanelShipDecorHome.initPanel = function(self, ...)
                local ret = orig_home_init(self, ...)
                _G.HTPS_CurrentPanelDecorHome = self
                pcall(function()
                    if _G.HTPS_EnsureFurnitureButtons then _G.HTPS_EnsureFurnitureButtons() end
                end)
                return ret
            end
        end

        if _G.PanelShopFurniture and _G.PanelShopFurniture.initPanel then
            _G.HTPS_FURNITURE_HOOKED = true

            local orig_init = _G.PanelShopFurniture.initPanel
            _G.PanelShopFurniture.initPanel = function(self, ...)
                local ret = orig_init(self, ...)
                _G.HTPS_CurrentPanelShop = self
                pcall(function()
                    if _G.HTPS_EnsureFurnitureButtons then
                        _G.HTPS_EnsureFurnitureButtons()
                    end
                end)
                return ret
            end

            local orig_disp = _G.PanelShopFurniture.dispose
            _G.PanelShopFurniture.dispose = function(self, ...)
                if _G.HTPS_AUTO_FURNITURE_RUNNING then
                    _G.HTPS_StopAutoFurnitureCraft("Đã đóng giao diện Chế Tạo!")
                end
                _G.HTPS_CurrentPanelShop = nil
                if orig_disp then return orig_disp(self, ...) end
            end

            local orig_proc = _G.PanelShopFurniture.processKEvent
            if orig_proc then
                _G.PanelShopFurniture.processKEvent = function(self, serviceId, bytesData, ...)
                    if serviceId == DataSender.DECOR_CREAT and _G.HTPS_AUTO_FURNITURE_RUNNING then
                        _G.HTPS_FurnitureCraftPending = false
                        pcall(function()
                            local lcv = NetworkController:instance():deserializeProto(bytesData, DataSender.ListCommonVector)
                            local cv1 = lcv.aVector[1]
                            CS.BonusModel.ParseBonusReceived(cv1.aLong)
                            local numberItemCreated = lcv.aVector[0].aLong[0]
                            StaticVar.NumberCreated = numberItemCreated
                            local newNumberMaterial = CS.PlayerInventory.GetInstance():GetNumberItemConsumable(PanelShopFurniture.KEY_MATERIAL)
                            self:setNumberMaterial(newNumberMaterial)
                            self:changeUi(numberItemCreated)

                            local genItem = function(itemId, itemKey, shipId, floorId, spaceId, itemPlaceType, itemQuality, itemPoints)
                                return {
                                    itemId = itemId,
                                    itemKey = itemKey,
                                    shipId = shipId,
                                    floorId = floorId,
                                    spaceId = spaceId,
                                    itemPlaceType = itemPlaceType,
                                    itemQuality = itemQuality,
                                    itemPoints = itemPoints
                                }
                            end

                            local redFound = 0
                            local lastRedName = ""
                            for i = 2, (lcv.aVector.Count - 1) do
                                local fId = lcv.aVector[i].aLong[1]
                                local itemDb = ShipFurnitureDb:instance():getFurniture(fId)
                                local itemPlaceType = ShipFurnitureDb:instance():getFurnitureByImgId(fId).itemPlaceType
                                local itemQuality = itemDb.itemQuality
                                local itemPoints = itemDb.itemPoints
                                local it = genItem(lcv.aVector[i].aLong[0], fId, lcv.aVector[i].aLong[2],
                                    lcv.aVector[i].aLong[3] + 1, lcv.aVector[i].aLong[4], itemPlaceType, itemQuality, itemPoints)
                                StaticVar.ListFurnitureItemInBag:add(it)
                                if itemQuality == 3 then
                                    redFound = redFound + 1
                                    pcall(function()
                                        local imgDb = ShipFurnitureDb:instance():getFurnitureByImgId(fId)
                                        if imgDb and imgDb.itemName then lastRedName = imgDb.itemName end
                                    end)
                                    pcall(function()
                                        if _G.HTPS_TryAutoEquipItemToHeroCabin then
                                            _G.HTPS_TryAutoEquipItemToHeroCabin(fId, lcv.aVector[i].aLong[0])
                                        end
                                    end)
                                end
                            end

                            if self.popupNewItem and self.popupNewItem.gameObject then
                                self.popupNewItem.gameObject:SetActive(false)
                            end

                            if redFound > 0 then
                                pcall(function()
                                    if _G.HTPS_CheckAndRotateWishlist then
                                        _G.HTPS_CheckAndRotateWishlist()
                                    end
                                end)
                                if CS.Toast then
                                    local msg = redFound == 1 and ("🔥 ĐÃ RA ĐỒ ĐỎ: " .. (lastRedName ~= "" and lastRedName or "Món Đỏ")) or string.format("🔥 ĐÃ RA %d ĐỒ ĐỎ!", redFound)
                                    CS.Toast.ShowToast(msg)
                                end
                            end
                        end)
                        return
                    elseif serviceId == DataSender.DECOR_RECYCLE then
                        _G.HTPS_FurnitureRecyclePending = false
                        pcall(function()
                            local cv = NetworkController:instance():deserializeProto(bytesData, DataSender.CommonVector)
                            CS.BonusModel.ParseBonusReceived(cv.aLong)
                            local newHammer = CS.PlayerInventory.GetInstance():GetNumberItemConsumable(PanelShopFurniture.KEY_MATERIAL)
                            if self.setNumberMaterial then self:setNumberMaterial(newHammer) end
                            if self.changeUi then self:changeUi(StaticVar.NumberCreated or (self.GetCurrentNumber and self:GetCurrentNumber()) or 0) end
                        end)
                        return
                    end
                    local res = orig_proc(self, serviceId, bytesData, ...)
                    if serviceId == DataSender.DECOR_CREAT then
                        _G.HTPS_FurnitureCraftPending = false
                    elseif serviceId == DataSender.DECOR_RECYCLE then
                        _G.HTPS_FurnitureRecyclePending = false
                    end
                    return res
                end
            end
        end
    end

    _G.HTPS_ToggleAutoFurnitureCraft = function()
        if not _G.HTPS_AUTO_ACTIVATED then
            if CS.Toast then CS.Toast.ShowToast("⚠️ Vui lòng kích hoạt bản quyền VIP để dùng tính năng này!") end
            if _G.HTPS_ShowActivationDialog then _G.HTPS_ShowActivationDialog(true) end
            return
        end

        if _G.HTPS_AUTO_FURNITURE_RUNNING then
            _G.HTPS_StopAutoFurnitureCraft("Đã dừng Auto Chế Tạo!")
            return
        end

        local goShop = GO.Find("PanelShopFurniture(Clone)") or GO.Find("PanelShopFurniture")
        if not goShop or not goShop.activeInHierarchy then
            if CS.Toast then CS.Toast.ShowToast("⚠️ Vui lòng mở giao diện Chế Tạo Nội Thất trước!") end
            return
        end

        _G.HTPS_AUTO_FURNITURE_RUNNING = true
        _G.HTPS_UpdateFurnitureBtnUI("⏹ DỪNG AUTO", true)
        if CS.Toast then CS.Toast.ShowToast("🚀 Bắt đầu Auto Chế Tạo Siêu Tốc (Gộp tái chế Tím + Cam, giữ lại Đỏ)!") end

        pcall(function()
            if _G.HTPS_CheckAndRotateWishlist then
                _G.HTPS_CheckAndRotateWishlist()
            end
        end)

        CsCoroutine.start(function()
            local nc = NetworkController:instance()
            local consecutiveErrors = 0
            while _G.HTPS_AUTO_FURNITURE_RUNNING do
                -- Auto hide popupNewItem if visible
                pcall(function()
                    local pShop = GO.Find("PanelShopFurniture(Clone)") or GO.Find("PanelShopFurniture")
                    if pShop then
                        local pop = pShop.transform:Find("PopupNewItem")
                        if pop and pop.gameObject.activeSelf then
                            pop.gameObject:SetActive(false)
                        end
                    end
                end)

                -- 1. Check license
                if not _G.HTPS_AUTO_ACTIVATED then
                    _G.HTPS_StopAutoFurnitureCraft("Mã kích hoạt VIP đã hết hạn!")
                    break
                end

                -- 2. Check UI visible
                local shopActive = false
                pcall(function()
                    local pShop = GO.Find("PanelShopFurniture(Clone)") or GO.Find("PanelShopFurniture")
                    if pShop and pShop.activeInHierarchy then shopActive = true end
                end)
                if not shopActive then
                    _G.HTPS_StopAutoFurnitureCraft("Đã đóng giao diện Chế Tạo!")
                    break
                end

                local bag = StaticVar and StaticVar.ListFurnitureItemInBag
                local maxBag = (StaticVar and StaticVar.MaxNumberItem) or 200
                local unitPrice = (StaticVar and StaticVar.UnitPrice) or 300
                local cost10 = unitPrice * 10
                local curHammer = 0
                pcall(function()
                    curHammer = CS.PlayerInventory.GetInstance():GetNumberItemConsumable(2138)
                end)

                -- 3. BATCH RECYCLE: Only trigger recycle when bag is near full (>= 185) OR when out of hammer!
                local bagCount = bag and bag:count() or 0
                if (bagCount + 10 >= maxBag) or (curHammer < cost10) then
                    _G.HTPS_DoRecyclePurpleAndOrange()
                    bagCount = bag and bag:count() or 0
                    pcall(function()
                        curHammer = CS.PlayerInventory.GetInstance():GetNumberItemConsumable(2138)
                    end)
                end

                -- 4. Check if bag is full of RED items
                if bagCount >= maxBag then
                    _G.HTPS_StopAutoFurnitureCraft(string.format("🎉 Túi đồ đã đầy toàn bộ đồ ĐỎ (%d/%d)!", bagCount, maxBag))
                    break
                end

                -- 5. Check hammer
                if curHammer < cost10 then
                    _G.HTPS_StopAutoFurnitureCraft(string.format("⚠️ Không đủ Búa Gỗ (%d/%d) để tiếp tục chế tạo!", curHammer, cost10))
                    break
                end

                -- 6. Ensure network is idle before sending 740
                local waitNet = 0
                while nc.requestInFlight and waitNet < 25 do
                    coroutine.yield(UG.WaitForSeconds(0.04))
                    waitNet = waitNet + 1
                end

                -- 7. Send Craft x10
                _G.HTPS_FurnitureCraftPending = true
                local sendOk = false
                pcall(function()
                    if DataSender and DataSender.instance then
                        DataSender:instance():decorCreateFurniture(1)
                        sendOk = true
                    end
                end)

                if not sendOk then
                    consecutiveErrors = consecutiveErrors + 1
                    if consecutiveErrors > 5 then
                        _G.HTPS_StopAutoFurnitureCraft("⚠️ Lỗi kết nối khi gửi lệnh chế tạo!")
                        break
                    end
                else
                    consecutiveErrors = 0
                end

                -- 8. Wait for response with timeout
                local waitSec = 0
                while _G.HTPS_FurnitureCraftPending and _G.HTPS_AUTO_FURNITURE_RUNNING and waitSec < 1.5 do
                    coroutine.yield(UG.WaitForSeconds(0.04))
                    waitSec = waitSec + 0.04
                end

                if not _G.HTPS_AUTO_FURNITURE_RUNNING then break end

                -- 9. OPTIMAL DELAY (0.22s):
                -- Smooth, super fast (~4-5 crafts / 40-50 items per second) and strictly within server rate limit!
                coroutine.yield(UG.WaitForSeconds(0.22))
            end
        end)
    end

    _G.HTPS_EnsureFurnitureButtons = function()
        pcall(function()
            if not _G.HTPS_FURNITURE_HOOKED then
                _G.HTPS_HookFurnitureSystem()
            end

            -- 1. BUTTON IN PANEL SHOP FURNITURE
            local goShop = GO.Find("PanelShopFurniture(Clone)") or GO.Find("PanelShopFurniture")
            if goShop and goShop.activeInHierarchy then
                local btnBuy10 = goShop.transform:Find("Content/Right/nen_phai_truoc/ButtonBuyx10")
                if btnBuy10 and btnBuy10.gameObject.activeInHierarchy then
                    local parent = btnBuy10.parent
                    local btnAuto = parent:Find("ButtonAutoCraft")
                    if not btnAuto then
                        local cloneGo = GO.Instantiate(btnBuy10.gameObject, parent, false)
                        cloneGo.name = "ButtonAutoCraft"
                        cloneGo:SetActive(true)

                        local pos = btnBuy10.localPosition
                        cloneGo.transform.localPosition = UG.Vector3(pos.x, pos.y + 75, pos.z)
                        local rt = cloneGo:GetComponent(typeof(UG.RectTransform))
                        if rt then
                            rt.sizeDelta = UG.Vector2(195, 56)
                        end

                        for _, cName in ipairs({"NotiDot", "ImagePrice", "UnitPrice"}) do
                            local c = cloneGo.transform:Find(cName)
                            if c then c.gameObject:SetActive(false) end
                        end

                        local txtTf = cloneGo.transform:Find("Text")
                        if txtTf then
                            local txt = txtTf:GetComponent(typeof(UG.UI.Text))
                            if txt then
                                txt.alignment = CS.UnityEngine.TextAnchor.MiddleCenter
                                txt.horizontalOverflow = CS.UnityEngine.HorizontalWrapMode.Overflow
                                txt.verticalOverflow = CS.UnityEngine.VerticalWrapMode.Overflow
                                local trt = txtTf:GetComponent(typeof(UG.RectTransform))
                                if trt then
                                    trt.anchorMin = UG.Vector2(0, 0)
                                    trt.anchorMax = UG.Vector2(1, 1)
                                    trt.offsetMin = UG.Vector2(0, 0)
                                    trt.offsetMax = UG.Vector2(0, 0)
                                end
                                txt.fontSize = 20
                                txt.text = _G.HTPS_AUTO_FURNITURE_RUNNING and "⏹ DỪNG AUTO" or "⚡ AUTO CHẾ TẠO"
                                txt.color = _G.HTPS_AUTO_FURNITURE_RUNNING and UG.Color(1, 0.3, 0.3, 1) or UG.Color(1, 1, 1, 1)
                            end
                        end

                        local bc = cloneGo:GetComponent(typeof(UG.UI.Button))
                        if bc then
                            bc.onClick = UG.UI.Button.ButtonClickedEvent()
                            bc.onClick:AddListener(function()
                                _G.HTPS_ToggleAutoFurnitureCraft()
                            end)
                        end
                        btnAuto = cloneGo.transform
                    end

                    if btnAuto then
                        btnAuto.gameObject:SetActive(true)
                        local txt = btnAuto:GetComponentInChildren(typeof(UG.UI.Text), true)
                        if txt then
                            txt.text = _G.HTPS_AUTO_FURNITURE_RUNNING and "⏹ DỪNG AUTO" or "⚡ AUTO CHẾ TẠO"
                            txt.color = _G.HTPS_AUTO_FURNITURE_RUNNING and UG.Color(1, 0.3, 0.3, 1) or UG.Color(1, 1, 1, 1)
                        end
                    end
                end
            end

            -- 2. BUTTON IN PANEL RECYCLE FURNITURE (QUICK RECYCLE PURPLE + YELLOW)
            local goRecycle = GO.Find("PanelRecyleFurniture(Clone)") or GO.Find("PanelRecyleFurniture")
            if not goRecycle then
                pcall(function()
                    local popupRoot = GO.Find("GroupLuaPopup"); local tfPopup = popupRoot and popupRoot.transform
                    if tfPopup then
                        local c = tfPopup:Find("PanelRecyleFurniture(Clone)") or tfPopup:Find("PanelRecyleFurniture")
                        if c then goRecycle = c.gameObject end
                    end
                end)
            end
            if goRecycle and goRecycle.activeInHierarchy then
                local btnRecycle = goRecycle.transform:Find("LayoutGroup/PanelLeft/ButtonRecycle")
                if btnRecycle and btnRecycle.gameObject.activeInHierarchy then
                    local parent = btnRecycle.parent
                    local btnQuick = parent:Find("ButtonQuickRecycle")
                    if not btnQuick then
                        local cloneGo = GO.Instantiate(btnRecycle.gameObject, parent, false)
                        cloneGo.name = "ButtonQuickRecycle"
                        cloneGo:SetActive(true)

                        local pos = btnRecycle.localPosition
                        cloneGo.transform.localPosition = UG.Vector3(pos.x, pos.y + 65, pos.z)
                        local rt = cloneGo:GetComponent(typeof(UG.RectTransform))
                        if rt then
                            rt.sizeDelta = UG.Vector2(180, 50)
                        end

                        local txtTf = cloneGo.transform:Find("Text")
                        if txtTf then
                            local txt = txtTf:GetComponent(typeof(UG.UI.Text))
                            if txt then
                                txt.alignment = CS.UnityEngine.TextAnchor.MiddleCenter
                                txt.horizontalOverflow = CS.UnityEngine.HorizontalWrapMode.Overflow
                                txt.verticalOverflow = CS.UnityEngine.VerticalWrapMode.Overflow
                                local trt = txtTf:GetComponent(typeof(UG.RectTransform))
                                if trt then
                                    trt.anchorMin = UG.Vector2(0, 0)
                                    trt.anchorMax = UG.Vector2(1, 1)
                                    trt.offsetMin = UG.Vector2(0, 0)
                                    trt.offsetMax = UG.Vector2(0, 0)
                                end
                                txt.fontSize = 18
                                txt.text = "⚡ TÁI CHẾ TÍM + CAM"
                                txt.color = UG.Color(1, 1, 1, 1)
                            end
                        end

                        local bc = cloneGo:GetComponent(typeof(UG.UI.Button))
                        if bc then
                            bc.onClick = UG.UI.Button.ButtonClickedEvent()
                            bc.onClick:AddListener(function()
                                local total, p, y = _G.HTPS_DoRecyclePurpleAndOrange()
                                if total > 0 then
                                    CS.Toast.ShowToast(string.format("♻️ Đã tái chế %d món (Tím: %d, Cam: %d)!", total, p, y))
                                else
                                    CS.Toast.ShowToast("Không có đồ Tím hoặc Cam nào để tái chế!")
                                end
                            end)
                        end
                    end
                end
            end

            -- 3. BUTTON IN PANEL SHIP DECOR HOME (AUTO EQUIP ALL CABINS)
            local goHome = GO.Find("PanelShipDecorHome(Clone)") or GO.Find("PanelShipDecorHome")
            if goHome and goHome.activeInHierarchy then
                local tr = goHome.transform:Find("AnchorTopRight")
                local btnGallery = tr and tr:Find("ButtonGallery")
                if btnGallery and btnGallery.gameObject.activeInHierarchy then
                    local btnAutoEquip = tr:Find("ButtonAutoEquipDecor")
                    if not btnAutoEquip then
                        local cloneGo = GO.Instantiate(btnGallery.gameObject, tr, false)
                        cloneGo.name = "ButtonAutoEquipDecor"
                        cloneGo:SetActive(true)
                        cloneGo.transform.localPosition = UG.Vector3(-49.0, -521.3, 0)
                        local txt = cloneGo.transform:Find("ButtonGalleryDesc")
                        if txt then
                            local tComp = txt:GetComponent(typeof(UG.UI.Text))
                            if tComp then
                                tComp.text = "Auto Lắp"
                                tComp.color = UG.Color(1, 0.9, 0.2, 1)
                            end
                        end
                        local bc = cloneGo:GetComponent(typeof(UG.UI.Button))
                        if bc then
                            bc.onClick:RemoveAllListeners()
                            bc.onClick:AddListener(function()
                                _G.HTPS_AutoEquipAllCabins()
                            end)
                        end
                        btnAutoEquip = cloneGo.transform
                    end
                    if btnAutoEquip then
                        btnAutoEquip.gameObject:SetActive(true)
                    end
                end
            end
        end)
    end

    -- =========================================================================
    -- KHO TƯỚNG: NÚT TỰ ĐỘNG MỞ RỘNG KHO TƯỚNG (CẠNH NÚT SẮP XẾP / DUNG LƯỢNG)
    -- =========================================================================
    _G.HTPS_HERO_BAG_EXPAND_ADDED = _G.HTPS_HERO_BAG_EXPAND_ADDED or 0

    _G.HTPS_GetActiveHeroListScene = function()
        local hs = _G.HTPS_FindObjectOfType(typeof(CS.HeroListNewScene))
        if hs and not hs:Equals(nil) and hs.gameObject.activeInHierarchy then
            return hs
        end
        if CS.HeroListScene then
            local ok, hsOld = pcall(function() return _G.HTPS_FindObjectOfType(typeof(CS.HeroListScene)) end)
            if ok and hsOld and not hsOld:Equals(nil) and hsOld.gameObject.activeInHierarchy then
                return hsOld
            end
        end
        return nil
    end

    _G.HTPS_UpdateHeroBagExpandBtnUI = function()
        pcall(function()
            local btnTf = _G.HTPS_BTN_HERO_BAG_EXPAND_TF
            if not btnTf or btnTf:Equals(nil) then return end
            local img = btnTf:GetComponent(typeof(UG.UI.Image))
            local lblTf = btnTf:Find("Label")
            local txt = lblTf and lblTf:GetComponent(typeof(UG.UI.Text)) or nil
            local tOut = lblTf and lblTf:GetComponent(typeof(UG.UI.Outline)) or nil

            local sortTf = btnTf.parent and btnTf.parent:Find("ButtonSort") or nil
            local sortImg = sortTf and sortTf:GetComponent(typeof(UG.UI.Image)) or nil
            local spSort = (sortImg and sortImg.sprite and not sortImg.sprite:Equals(nil)) and sortImg.sprite or nil
            local spGreen = (_G.HTPS_FindNativeSprite and _G.HTPS_FindNativeSprite("button_green", true)) or nil
            local spYellow = spSort or (_G.HTPS_FindNativeSprite and _G.HTPS_FindNativeSprite("button_yellow", true)) or spGreen

            if _G.HTPS_HERO_BAG_EXPAND_RUNNING then
                if img then
                    if spYellow then
                        img.sprite = spYellow
                        img.type = UG.UI.Image.Type.Sliced
                        img.color = UG.Color(1.0, 0.48, 0.46, 1.0)
                    else
                        img.color = UG.Color(0.78, 0.15, 0.15, 0.98)
                    end
                end
                if txt then
                    local added = tonumber(_G.HTPS_HERO_BAG_EXPAND_ADDED) or 0
                    txt.text = (added > 0) and string.format("Dừng (+%d ô)", added) or "Dừng mở rộng"
                    txt.color = UG.Color(1.0, 0.98, 0.95, 1.0)
                end
                if tOut then tOut.enabled = true end
            else
                if img then
                    local spIdle = spGreen or spYellow
                    if spIdle then
                        img.sprite = spIdle
                        img.type = UG.UI.Image.Type.Sliced
                        img.color = UG.Color(1.0, 1.0, 1.0, 1.0)
                    else
                        img.color = UG.Color(0.13, 0.52, 0.24, 0.98)
                    end
                end
                if txt then
                    txt.text = "Mở rộng kho"
                    if spGreen then
                        txt.color = UG.Color(0.122, 0.408, 0.157, 1.0)
                    elseif spYellow then
                        txt.color = UG.Color(0.510, 0.318, 0.165, 1.0)
                    else
                        txt.color = UG.Color(1.0, 0.98, 0.90, 1.0)
                    end
                end
                if tOut then tOut.enabled = false end
            end
        end)
    end

    _G.HTPS_ToggleAutoExpandHeroBag = function()
        if not _G.HTPS_AUTO_ACTIVATED then
            if CS.Toast then CS.Toast.ShowToast("⚠️ Vui lòng kích hoạt bản quyền VIP để dùng tính năng này!") end
            if _G.HTPS_ShowActivationDialog then _G.HTPS_ShowActivationDialog(true) end
            return
        end

        if _G.HTPS_HERO_BAG_EXPAND_RUNNING then
            _G.HTPS_HERO_BAG_EXPAND_RUNNING = false
            _G.HTPS_UpdateHeroBagExpandBtnUI()
            return
        end

        local hs = _G.HTPS_GetActiveHeroListScene()
        if not hs then return end

        _G.HTPS_HERO_BAG_EXPAND_RUNNING = true
        _G.HTPS_HERO_BAG_EXPAND_ADDED = 0
        _G.HTPS_BONUS_SUPPRESS_UNTIL = 0
        if _G.HTPS_AUTO then _G.HTPS_AUTO.suppressPopup = true end
        _G.HTPS_UpdateHeroBagExpandBtnUI()

        -- Tự động tắt bảng xác nhận mua lẻ (nếu đang mở)
        pcall(function()
            local pConf = GO.Find("PopupConfirm(Clone)")
            if pConf and pConf.activeSelf then pConf:SetActive(false) end
        end)

        CsCoroutine.start(function()
            local REF_FLAGS = 60
            local gc = CS.GameContext.GetIntance()
            local inv = CS.PlayerInventory.GetInstance()
            local csNet = CS.NetworkController.GetInstance()
            local urlServer = csNet and csNet.m_UrlGameServer or ""
            local totalUpgrades = 0
            local addedSlots = 0
            local totalGemSpent = 0
            local firstBaseCap = nil
            local stopReason = ""

            local okLoop, errLoop = pcall(function()
                if not gc or not inv or not csNet or urlServer == "" then return end

                while _G.HTPS_HERO_BAG_EXPAND_RUNNING do
                    _G.HTPS_KillSummonPopups()
                    hs = _G.HTPS_GetActiveHeroListScene()
                    if not hs then
                        _G.HTPS_HERO_BAG_EXPAND_RUNNING = false
                        break
                    end
                    local fMisc = hs:GetType():GetField("m_GoMiscInfo", REF_FLAGS)
                    local miscGo = fMisc and fMisc:GetValue(hs) or nil
                    if miscGo and not miscGo:Equals(nil) and not miscGo.activeInHierarchy then
                        _G.HTPS_HERO_BAG_EXPAND_RUNNING = false
                        break
                    end

                    local availGem = tonumber(gc.m_Gem) or 0
                    local curCost = tonumber(CS.MiscData.m_CostBuyHeroCapacity) or 0
                    if curCost < 0 then
                        stopReason = "Đã đạt giới hạn mở rộng kho tối đa!"
                        _G.HTPS_HERO_BAG_EXPAND_RUNNING = false
                        break
                    end
                    if curCost > 0 and availGem < curCost then
                        local fmtFn = _G.HTPS_FormatExactInt or tostring
                        stopReason = string.format("Không đủ Kim Cương (Cần %s KC)!", fmtFn(curCost))
                        _G.HTPS_HERO_BAG_EXPAND_RUNNING = false
                        break
                    end

                    -- Gộp tối đa 10 lần mở rộng (+50 ô) mỗi gói HTTP (~0.18s) để vừa nhanh vừa dừng tức thì khi bấm Dừng
                    local batchN = 0
                    local simGem = availGem
                    local stepCost = math.max(0, curCost)
                    for k = 1, 10 do
                        if simGem >= stepCost then
                            simGem = simGem - stepCost
                            batchN = k
                            stepCost = stepCost + 100
                        else
                            break
                        end
                    end

                    if batchN <= 0 then
                        local fmtFn = _G.HTPS_FormatExactInt or tostring
                        stopReason = string.format("Không đủ Kim Cương (Cần %s KC)!", fmtFn(curCost))
                        _G.HTPS_HERO_BAG_EXPAND_RUNNING = false
                        break
                    end

                    local req = CS.pbdson.RequestData()
                    req.session = gc.m_Session
                    local emptyBytes = _G.HTPS_SerializeProto(CS.pbdson.CommonVector())
                    for k = 1, batchN do
                        local act = CS.pbdson.PbAction()
                        act.actionId = 234
                        act.data = emptyBytes
                        req.actions:Add(act)
                    end

                    local d = _G.HTPS_PutWebRequest(urlServer .. "/i/234/" .. tostring(gc.m_UserId), _G.HTPS_SerializeProto(req), 10)
                    local got234 = 0
                    local serverErr = nil
                    if d then
                        local r = _G.HTPS_DeserializeProto(d, "pbdson.ResponseData,PbMethodLib")
                        if r and r.aAction then
                            for i = 0, r.aAction.Count - 1 do
                                local act = r.aAction[i]
                                if act.actionId == 234 and act.data then
                                    local cv = _G.HTPS_DeserializeProto(act.data, "pbdson.CommonVector,PbMethodLib")
                                    if cv and cv.aLong and cv.aLong.Count >= 2 then
                                        local prevCap = tonumber(CS.MiscData.m_HeroCapacity) or 0
                                        local newCost = tonumber(cv.aLong[0]) or 0
                                        local newCap = tonumber(cv.aLong[1]) or prevCap
                                        CS.MiscData.m_CostBuyHeroCapacity = newCost
                                        CS.MiscData.m_HeroCapacity = newCap

                                        if not firstBaseCap then
                                            firstBaseCap = newCap - 5
                                        end
                                        got234 = got234 + 1
                                        totalUpgrades = totalUpgrades + 1
                                        addedSlots = math.max(totalUpgrades * 5, newCap - firstBaseCap)
                                        _G.HTPS_HERO_BAG_EXPAND_ADDED = addedSlots

                                        if cv.aLong.Count >= 5 and tonumber(cv.aLong[2]) == 2 then
                                            gc.m_Gem = tonumber(cv.aLong[3]) or gc.m_Gem
                                            totalGemSpent = totalGemSpent + math.abs(tonumber(cv.aLong[4]) or 0)
                                        elseif cv.aLong.Count > 2 then
                                            pcall(function()
                                                local subLongs = CS.System.Collections.Generic.List(typeof(CS.System.Int64))()
                                                for j = 2, cv.aLong.Count - 1 do
                                                    subLongs:Add(cv.aLong[j])
                                                end
                                                CS.BonusModel.ParseBonusReceived(subLongs)
                                            end)
                                        end
                                    end
                                elseif act.actionId == 1 and act.data then
                                    local cv = _G.HTPS_DeserializeProto(act.data, "pbdson.CommonVector,PbMethodLib")
                                    if cv and cv.aString and cv.aString.Count > 0 then
                                        serverErr = tostring(cv.aString[0])
                                    end
                                end
                            end
                        end
                    else
                        serverErr = "Lỗi kết nối máy chủ!"
                    end

                    -- Cập nhật ngay con số Dung lượng Kho Tướng trên màn hình (VD: 1058/1450)
                    pcall(function()
                        if hs and not hs:Equals(nil) then
                            local fTxt = hs:GetType():GetField("m_TextHeroCapacity", REF_FLAGS)
                            local txtCap = fTxt and fTxt:GetValue(hs) or nil
                            if txtCap and not txtCap:Equals(nil) then
                                local lstH = inv:GetListHeroModel()
                                local hCnt = (lstH and lstH.Count) or 0
                                txtCap.text = tostring(hCnt) .. "/" .. tostring(CS.MiscData.m_HeroCapacity)
                            end
                        end
                    end)
                    _G.HTPS_UpdateHeroBagExpandBtnUI()

                    if got234 == 0 or serverErr then
                        stopReason = serverErr or "Đã đạt giới hạn mở rộng kho!"
                        _G.HTPS_HERO_BAG_EXPAND_RUNNING = false
                        break
                    end

                    coroutine.yield(nil)
                end
            end)

            _G.HTPS_HERO_BAG_EXPAND_RUNNING = false
            _G.HTPS_KillSummonPopups()
            _G.HTPS_UpdateHeroBagExpandBtnUI()

            if not okLoop then
                if CS.Toast then CS.Toast.ShowToast("⚠️ Lỗi Mở Rộng Kho: " .. tostring(errLoop)) end
            elseif CS.Toast then
                local fmtFn = _G.HTPS_FormatExactInt or tostring
                local extra = (stopReason ~= "") and (" - " .. stopReason) or ""
                CS.Toast.ShowToast(string.format("📦 Kho Tướng: Đã mở +%s ô (-> %s ô, -%s KC)%s",
                    fmtFn(addedSlots), fmtFn(CS.MiscData.m_HeroCapacity), fmtFn(totalGemSpent), extra))
            end
        end)
    end

    _G.HTPS_EnsureHeroBagExpandButtons = function()
        pcall(function()
            local hs = _G.HTPS_GetActiveHeroListScene()
            if not hs then
                if _G.HTPS_HERO_BAG_EXPAND_RUNNING then
                    _G.HTPS_HERO_BAG_EXPAND_RUNNING = false
                end
                return
            end

            local REF_FLAGS = 60
            local fMisc = hs:GetType():GetField("m_GoMiscInfo", REF_FLAGS)
            local miscGo = fMisc and fMisc:GetValue(hs) or nil
            if not miscGo or miscGo:Equals(nil) then return end

            local parentTf = miscGo.transform
            local sortBtnTf = parentTf:Find("ButtonSort")
            local sortBtnImg = sortBtnTf and sortBtnTf:GetComponent(typeof(UG.UI.Image)) or nil
            local spSort = (sortBtnImg and sortBtnImg.sprite and not sortBtnImg.sprite:Equals(nil)) and sortBtnImg.sprite or nil
            local spGreen = (_G.HTPS_FindNativeSprite and _G.HTPS_FindNativeSprite("button_green", true)) or nil
            local spIdle = spGreen or spSort or (_G.HTPS_FindNativeSprite and _G.HTPS_FindNativeSprite("button_yellow", true)) or nil

            local sortTxtTf = parentTf:Find("ButtonSort/Text")
            local sortTxt = sortTxtTf and sortTxtTf:GetComponent(typeof(UG.UI.Text)) or nil
            local fCapTxt = hs:GetType():GetField("m_TextHeroCapacity", REF_FLAGS)
            local capTxt = fCapTxt and fCapTxt:GetValue(hs) or nil
            local gameFont = (sortTxt and sortTxt.font) or (capTxt and capTxt.font) or UG.Resources.GetBuiltinResource(typeof(UG.Font), "Arial.ttf")

            local btnTf = parentTf:Find("BtnHTPSAutoExpandHeroBag")
            if btnTf and not btnTf:Find("SkinV2") then
                UG.Object.DestroyImmediate(btnTf.gameObject)
                btnTf = nil
            end

            if not btnTf then
                local btnGo = GO("BtnHTPSAutoExpandHeroBag")
                btnGo.transform:SetParent(parentTf, false)
                local mk = GO("SkinV2")
                mk.transform:SetParent(btnGo.transform, false)
                mk:SetActive(false)

                local rt = btnGo:AddComponent(typeof(UG.RectTransform))
                rt.anchorMin = UG.Vector2(0.5, 0.5)
                rt.anchorMax = UG.Vector2(0.5, 0.5)
                rt.pivot = UG.Vector2(0.5, 0.5)
                rt.anchoredPosition = UG.Vector2(132.0, 25.0)
                rt.sizeDelta = UG.Vector2(196.0, 60.0)

                local img = btnGo:AddComponent(typeof(UG.UI.Image))
                if spIdle then
                    img.sprite = spIdle
                    img.type = UG.UI.Image.Type.Sliced
                    img.color = UG.Color(1.0, 1.0, 1.0, 1.0)
                else
                    img.color = UG.Color(0.13, 0.52, 0.24, 0.98)
                end

                local bc = btnGo:AddComponent(typeof(UG.UI.Button))
                bc.targetGraphic = img

                local lblGo = GO("Label")
                lblGo.transform:SetParent(btnGo.transform, false)
                local lrt = lblGo:AddComponent(typeof(UG.RectTransform))
                lrt.anchorMin = UG.Vector2(0, 0)
                lrt.anchorMax = UG.Vector2(1, 1)
                lrt.offsetMin = UG.Vector2(14, 6)
                lrt.offsetMax = UG.Vector2(-14, -3)
                local ltxt = lblGo:AddComponent(typeof(UG.UI.Text))
                ltxt.font = gameFont
                ltxt.fontSize = 22
                ltxt.fontStyle = UG.FontStyle.Normal
                ltxt.alignment = UG.TextAnchor.MiddleCenter
                ltxt.resizeTextForBestFit = true
                ltxt.resizeTextMinSize = 13
                ltxt.resizeTextMaxSize = 22
                ltxt.color = spGreen and UG.Color(0.122, 0.408, 0.157, 1.0) or UG.Color(0.510, 0.318, 0.165, 1.0)
                ltxt.text = "Mở rộng kho"

                local lout = lblGo:AddComponent(typeof(UG.UI.Outline))
                lout.effectColor = UG.Color(0.32, 0.06, 0.05, 1.0)
                lout.effectDistance = UG.Vector2(1.2, -1.2)
                lout.enabled = false

                btnTf = btnGo.transform
            end

            if btnTf then
                _G.HTPS_BTN_HERO_BAG_EXPAND_TF = btnTf
                if not btnTf.gameObject.activeSelf then
                    btnTf.gameObject:SetActive(true)
                end
                _G.HTPS_UpdateHeroBagExpandBtnUI()
                if _G.HTPS_BOUND_HERO_BAG_EXPAND_BTN ~= btnTf then
                    local bc = btnTf:GetComponent(typeof(UG.UI.Button))
                    if bc then
                        bc.onClick:RemoveAllListeners()
                        bc.onClick:AddListener(function()
                            _G.HTPS_ToggleAutoExpandHeroBag()
                        end)
                    end
                    _G.HTPS_BOUND_HERO_BAG_EXPAND_BTN = btnTf
                end
            end
        end)
    end

    -- =========================================================================
    -- AUTO LUYỆN HỒN TƯỚNG (EXCLUSIVE / EXCPanelMain - Action 1908)
    -- Tự động nâng cấp Luyện Hồn đến cấp tối đa (40/40) hoặc dừng ngay khi bấm Dừng / hết nguyên liệu
    -- =========================================================================
    _G.HTPS_EXC_AUTO_RUNNING = _G.HTPS_EXC_AUTO_RUNNING or false

    _G.HTPS_GetLiveEXCPanel = function()
        local found = nil
        pcall(function()
            if _G.UIUpdateMng then
                local mng = _G.UIUpdateMng:instance()
                local lst = mng and mng.listUpdateListener and mng.listUpdateListener.getList and mng.listUpdateListener:getList() or nil
                if lst then
                    for _, h in ipairs(lst) do
                        if type(h) == "table" and not h.disposed and h.goRoot and not h.goRoot:Equals(nil)
                            and h.goRoot.activeInHierarchy and h.btnLevelUp and h.tfPointContainer then
                            found = h
                        end
                    end
                end
            end
        end)
        return found
    end

    _G.HTPS_GetLiveEXCJob = function()
        local found = nil
        pcall(function()
            local nc = (_G.EXCDataSender and _G.EXCDataSender:instance() and _G.EXCDataSender:instance().networkController)
                or (_G.NetworkController and _G.NetworkController:instance()) or nil
            local lst = nc and nc.listEventHandler and nc.listEventHandler.getList and nc.listEventHandler:getList() or nil
            if lst then
                for _, eh in ipairs(lst) do
                    if type(eh) == "table" and type(eh.updateHeroEXC) == "function" and type(eh.processKEvent) == "function" then
                        found = eh
                    end
                end
            end
        end)
        return found
    end

    _G.HTPS_HookEXCPanelClass = function()
        if _G.HTPS_EXC_CLASS_HOOKED then return end
        if type(_G.EXCPanelMain) ~= "table" then return end
        _G.HTPS_EXC_CLASS_HOOKED = true

        local origLoadData = _G.EXCPanelMain.loadData
        if type(origLoadData) == "function" then
            _G.EXCPanelMain.loadData = function(self, model, ...)
                local ret = origLoadData(self, model, ...)
                pcall(function()
                    if _G.HTPS_UpdateEXCBtnUI then
                        _G.HTPS_UpdateEXCBtnUI(self)
                    end
                end)
                return ret
            end
        end

        local origDispose = _G.EXCPanelMain.dispose
        if type(origDispose) == "function" then
            _G.EXCPanelMain.dispose = function(self, ...)
                if _G.HTPS_EXC_AUTO_RUNNING then
                    _G.HTPS_EXC_AUTO_RUNNING = false
                end
                return origDispose(self, ...)
            end
        end
    end

    _G.HTPS_UpdateEXCBtnUI = function(panel)
        pcall(function()
            panel = panel or _G.HTPS_GetLiveEXCPanel()
            local pageLeftTf = nil
            if panel and panel.goRoot and not panel.goRoot:Equals(nil) then
                pageLeftTf = panel.goRoot.transform:Find("Content/PageLeft")
            else
                local popGo = GO.Find("EXCPanelMain(Clone)")
                if popGo and not popGo:Equals(nil) and popGo.activeInHierarchy then
                    pageLeftTf = popGo.transform:Find("Content/PageLeft")
                end
            end
            if not pageLeftTf then return end

            local btnTf = pageLeftTf:Find("BtnHTPSAutoEXC")
            if not btnTf or btnTf:Equals(nil) then return end

            local db = _G.EXCDbManager and _G.EXCDbManager:instance() or nil
            local maxLv = (db and db.getLevelMax and tonumber(db:getLevelMax())) or 40
            local curLv = 0
            if panel and panel.excModel and panel.excModel.level ~= nil then
                curLv = tonumber(panel.excModel.level) or 0
            elseif _G.HTPS_EXC_CUR_LV ~= nil then
                curLv = tonumber(_G.HTPS_EXC_CUR_LV) or 0
            end

            local btnLvUpTf = pageLeftTf:Find("ButtonLvUp")
            local isMax = (curLv >= maxLv)
            if not isMax and btnLvUpTf and not btnLvUpTf.gameObject.activeSelf then
                local txtMaxTf = pageLeftTf:Find("TextMax")
                if txtMaxTf and txtMaxTf.gameObject.activeSelf then
                    isMax = true
                end
            end

            local shouldShow = (not isMax) or (_G.HTPS_EXC_AUTO_RUNNING == true)
            if btnTf.gameObject.activeSelf ~= shouldShow then
                btnTf.gameObject:SetActive(shouldShow)
            end
            if not shouldShow then return end

            local spYellow = (_G.HTPS_FindNativeSprite and _G.HTPS_FindNativeSprite("button_yellow", true)) or nil
            local img = btnTf:GetComponent(typeof(UG.UI.Image))
            if img then
                if spYellow then
                    img.sprite = spYellow
                    img.type = UG.UI.Image.Type.Sliced
                end
                if _G.HTPS_EXC_AUTO_RUNNING then
                    img.color = UG.Color(1.0, 0.48, 0.46, 1.0)
                else
                    img.color = UG.Color(1.0, 1.0, 1.0, 1.0)
                end
            end

            local txtTf = btnTf:Find("Text")
            local txt = (txtTf and txtTf:GetComponent(typeof(UG.UI.Text))) or btnTf:GetComponentInChildren(typeof(UG.UI.Text), true)
            if txt and not txt:Equals(nil) then
                local tOut = txt.gameObject:GetComponent(typeof(UG.UI.Outline))
                if _G.HTPS_EXC_AUTO_RUNNING then
                    txt.text = string.format("Dừng (%d/%d)", curLv, maxLv)
                    txt.color = UG.Color(1.0, 0.98, 0.95, 1.0)
                    if tOut then tOut.enabled = true end
                else
                    txt.text = "Auto Luyện Hồn"
                    if spYellow then
                        txt.color = UG.Color(0.510, 0.318, 0.165, 1.0)
                        if tOut then tOut.enabled = false end
                    else
                        txt.color = UG.Color(1.0, 0.96, 0.86, 1.0)
                        if tOut then tOut.enabled = true end
                    end
                end
            end
        end)
    end

    _G.HTPS_ToggleAutoEXC = function()
        if not _G.HTPS_AUTO_ACTIVATED then
            if CS.Toast then CS.Toast.ShowToast("Vui lòng kích hoạt bản quyền VIP để dùng tính năng này!") end
            if _G.HTPS_ShowActivationDialog then _G.HTPS_ShowActivationDialog(true) end
            return
        end

        if _G.HTPS_EXC_AUTO_RUNNING then
            _G.HTPS_EXC_AUTO_RUNNING = false
            _G.HTPS_UpdateEXCBtnUI()
            return
        end

        local panel = _G.HTPS_GetLiveEXCPanel()
        if not panel or not panel.csHeroModel or not panel.excModel or not _G.EXCDbManager then
            if CS.Toast then CS.Toast.ShowToast("Đang tải dữ liệu Luyện Hồn, vui lòng thử lại sau giây lát!") end
            return
        end

        local db = _G.EXCDbManager:instance()
        local heroModel = panel.csHeroModel
        local heroId = tonumber(heroModel.m_HeroId) or 0
        local heroKey = tonumber(heroModel.m_HeroKey) or 0
        local heroStar = tonumber(heroModel.m_Star) or 0

        if heroId <= 0 then return end
        if db:getHeroDbExcModel(heroKey) == nil then
            if CS.Toast then CS.Toast.ShowToast("Thuyền viên chưa mở khóa Luyện Hồn!") end
            return
        end
        if heroStar < 10 then
            if CS.Toast then CS.Toast.ShowToast("Thuyền viên đạt 10 sao trở lên để mở khóa Luyện Hồn!") end
            return
        end

        local maxLv = tonumber(db:getLevelMax()) or 40
        local startLv = tonumber(panel.excModel.level) or 0
        if startLv >= maxLv then
            if CS.Toast then CS.Toast.ShowToast("Thuyền viên đã đạt cấp Luyện Hồn tối đa!") end
            return
        end

        local inv = CS.PlayerInventory.GetInstance()
        local fmtFn = _G.HTPS_FormatExactInt or tostring

        local function calcAffordableBatch(curLv, maxBatch)
            local usedMat = {}
            local canSteps = 0
            local lackMsg = nil
            for step = 1, maxBatch do
                local simLv = curLv + step - 1
                if simLv >= maxLv then break end
                local info = db:getExcLevelUpInfo(simLv)
                if not info or not info:hasCost() then break end
                local stepOk = true
                local okCost = pcall(function()
                    local csLst = info:getBonusCostLevelUp():ToListModelObject()
                    for i = 0, csLst.Count - 1 do
                        local it = csLst[i]
                        local iKey = tonumber(it.m_ItemKey)
                        local iNeed = tonumber(it.m_Number) or 0
                        if iKey and iNeed > 0 then
                            local have = tonumber(inv:GetNumberItemConsumable(iKey)) or 0
                            local prevUsed = usedMat[iKey] or 0
                            if have < (prevUsed + iNeed) then
                                stepOk = false
                                if step == 1 then
                                    lackMsg = string.format("Không đủ nguyên liệu Luyện Hồn (%s/%s)!",
                                        fmtFn(have), fmtFn(iNeed))
                                end
                                break
                            end
                        end
                    end
                    if stepOk then
                        for i = 0, csLst.Count - 1 do
                            local it = csLst[i]
                            local iKey = tonumber(it.m_ItemKey)
                            local iNeed = tonumber(it.m_Number) or 0
                            if iKey and iNeed > 0 then
                                usedMat[iKey] = (usedMat[iKey] or 0) + iNeed
                            end
                        end
                    end
                end)
                if not okCost then
                    if canSteps == 0 then canSteps = 1 end
                    break
                end
                if not stepOk then break end
                canSteps = canSteps + 1
            end
            return canSteps, lackMsg
        end

        local initSteps, initLack = calcAffordableBatch(startLv, 1)
        if initSteps <= 0 then
            if CS.Toast then CS.Toast.ShowToast(initLack or "Không đủ nguyên liệu Luyện Hồn!") end
            return
        end

        _G.HTPS_EXC_AUTO_RUNNING = true
        _G.HTPS_EXC_CUR_LV = startLv
        _G.HTPS_UpdateEXCBtnUI(panel)

        CsCoroutine.start(function()
            local gc = CS.GameContext.GetIntance()
            local csNet = CS.NetworkController.GetInstance()
            local urlServer = csNet and csNet.m_UrlGameServer or ""
            local curLv = startLv
            local totalUpgrades = 0
            local stopReason = ""
            local userStopped = false

            local okLoop, errLoop = pcall(function()
                if not gc or not inv or not csNet or urlServer == "" then
                    stopReason = "Lỗi kết nối máy chủ!"
                    return
                end

                if _G.EXCDataSender and _G.EXCDataSender:instance() then
                    local t0 = UG.Time.realtimeSinceStartup
                    while _G.HTPS_EXC_AUTO_RUNNING and _G.EXCDataSender:instance().pendingMutation ~= nil
                        and (UG.Time.realtimeSinceStartup - t0) < 1.2 do
                        coroutine.yield(nil)
                    end
                end

                while _G.HTPS_EXC_AUTO_RUNNING do
                    _G.HTPS_KillSummonPopups()

                    local livePanel = _G.HTPS_GetLiveEXCPanel()
                    if not livePanel or not livePanel.csHeroModel or tonumber(livePanel.csHeroModel.m_HeroId) ~= heroId then
                        stopReason = "Đã đóng bảng Luyện Hồn"
                        _G.HTPS_EXC_AUTO_RUNNING = false
                        break
                    end

                    if livePanel.excModel and livePanel.excModel.level ~= nil then
                        curLv = tonumber(livePanel.excModel.level) or curLv
                    end
                    _G.HTPS_EXC_CUR_LV = curLv

                    if curLv >= maxLv then
                        stopReason = "Đạt cấp tối đa"
                        _G.HTPS_EXC_AUTO_RUNNING = false
                        break
                    end

                    local batchN, lackMsg = calcAffordableBatch(curLv, 5)
                    if batchN <= 0 then
                        stopReason = lackMsg or "Không đủ nguyên liệu Luyện Hồn!"
                        _G.HTPS_EXC_AUTO_RUNNING = false
                        break
                    end

                    local req = CS.pbdson.RequestData()
                    req.session = gc.m_Session
                    local cvReq = CS.pbdson.CommonVector()
                    cvReq.aLong:Add(heroId)
                    local reqBytes = _G.HTPS_SerializeProto(cvReq)
                    for k = 1, batchN do
                        local act = CS.pbdson.PbAction()
                        act.actionId = 1908
                        act.data = reqBytes
                        req.actions:Add(act)
                    end

                    local d = _G.HTPS_PutWebRequest(urlServer .. "/i/1908/" .. tostring(gc.m_UserId), _G.HTPS_SerializeProto(req), 10)
                    local got1908 = 0
                    local last1908Data = nil
                    local lastCv0 = nil
                    local serverErr = nil

                    if d then
                        local r = _G.HTPS_DeserializeProto(d, "pbdson.ResponseData,PbMethodLib")
                        if r and r.aAction then
                            for i = 0, r.aAction.Count - 1 do
                                local act = r.aAction[i]
                                if act.actionId == 1908 and act.data then
                                    local lcv = _G.HTPS_DeserializeProto(act.data, "pbdson.ListCommonVector,PbMethodLib")
                                    if lcv and lcv.aVector and lcv.aVector.Count > 0 then
                                        got1908 = got1908 + 1
                                        totalUpgrades = totalUpgrades + 1
                                        last1908Data = act.data
                                        lastCv0 = lcv.aVector[0]
                                        if lcv.aVector.Count > 1 then
                                            local cv1 = lcv.aVector[1]
                                            if cv1 and cv1.aLong and cv1.aLong.Count > 0 then
                                                pcall(function()
                                                    CS.BonusModel.ParseBonusReceived(cv1.aLong)
                                                end)
                                            end
                                        end
                                    end
                                elseif act.actionId == 1 and act.data then
                                    local cv = _G.HTPS_DeserializeProto(act.data, "pbdson.CommonVector,PbMethodLib")
                                    if cv and cv.aString and cv.aString.Count > 0 then
                                        serverErr = tostring(cv.aString[0])
                                    end
                                end
                            end
                        end
                    else
                        serverErr = "Lỗi kết nối máy chủ!"
                    end

                    if last1908Data and lastCv0 and lastCv0.aLong and lastCv0.aLong.Count > 0 then
                        curLv = tonumber(lastCv0.aLong[0]) or curLv
                        _G.HTPS_EXC_CUR_LV = curLv

                        pcall(function()
                            local excJob = _G.HTPS_GetLiveEXCJob()
                            local infoSvcId = (_G.EXCDataSender and _G.EXCDataSender.EXC_INFO) or 1907
                            if excJob then
                                excJob:processKEvent(infoSvcId, last1908Data)
                            end
                            local pNow = _G.HTPS_GetLiveEXCPanel()
                            if pNow and pNow.csHeroModel and tonumber(pNow.csHeroModel.m_HeroId) == heroId then
                                local mdl = db:getHeroExcModel(heroId) or pNow.excModel
                                if mdl then
                                    mdl.heroId = heroId
                                    mdl.heroKey = heroKey
                                    mdl.level = curLv
                                    if mdl.lstPoint and mdl.lstPoint.clear then
                                        mdl.lstPoint:clear()
                                        for k = 1, lastCv0.aLong.Count - 1 do
                                            mdl.lstPoint:add(lastCv0.aLong[k])
                                        end
                                    end
                                    if mdl.configValue then mdl:configValue() end
                                    db:setHeroExcModel(heroId, mdl)
                                    if not excJob or not pNow.excModel or tonumber(pNow.excModel.level) ~= curLv then
                                        pNow:loadData(mdl)
                                    end
                                end
                            end
                            db.hasUpgrade = true
                        end)
                    end

                    _G.HTPS_KillSummonPopups()
                    _G.HTPS_UpdateEXCBtnUI()

                    if not _G.HTPS_EXC_AUTO_RUNNING then
                        userStopped = true
                        break
                    end

                    if got1908 == 0 or serverErr then
                        stopReason = serverErr or "Không thể nâng thêm cấp Luyện Hồn!"
                        _G.HTPS_EXC_AUTO_RUNNING = false
                        break
                    end

                    if curLv >= maxLv then
                        stopReason = "Đạt cấp tối đa"
                        _G.HTPS_EXC_AUTO_RUNNING = false
                        break
                    end

                    coroutine.yield(nil)
                end
            end)

            _G.HTPS_EXC_AUTO_RUNNING = false
            _G.HTPS_KillSummonPopups()
            _G.HTPS_UpdateEXCBtnUI()

            if totalUpgrades > 0 then
                pcall(function()
                    if db then db.hasUpgrade = false end
                    if gc and gc.dataSender then
                        gc.dataSender:HeroRequestInfo(heroId)
                    end
                end)
            end

            if not okLoop then
                if CS.Toast then CS.Toast.ShowToast("Lỗi Auto Luyện Hồn: " .. tostring(errLoop)) end
            elseif CS.Toast then
                if totalUpgrades == 0 and stopReason ~= "" then
                    CS.Toast.ShowToast(stopReason)
                elseif curLv >= maxLv then
                    CS.Toast.ShowToast(string.format("Luyện Hồn hoàn tất: Cấp %d -> %d/%d (Đạt tối đa)!", startLv, curLv, maxLv))
                elseif userStopped then
                    CS.Toast.ShowToast(string.format("Đã dừng Luyện Hồn ở Cấp %d/%d (+%d cấp)", curLv, maxLv, totalUpgrades))
                else
                    local extra = (stopReason ~= "") and (" - " .. stopReason) or ""
                    CS.Toast.ShowToast(string.format("Luyện Hồn: Cấp %d -> %d/%d%s", startLv, curLv, maxLv, extra))
                end
            end
        end)
    end

    _G.HTPS_EnsureEXCButtons = function()
        pcall(function()
            if _G.HTPS_HookEXCPanelClass then _G.HTPS_HookEXCPanelClass() end

            local panel = _G.HTPS_GetLiveEXCPanel()
            local pageLeftTf = nil
            if panel and panel.goRoot and not panel.goRoot:Equals(nil) then
                pageLeftTf = panel.goRoot.transform:Find("Content/PageLeft")
            else
                local popGo = GO.Find("EXCPanelMain(Clone)")
                if popGo and not popGo:Equals(nil) and popGo.activeInHierarchy then
                    pageLeftTf = popGo.transform:Find("Content/PageLeft")
                end
            end

            if not pageLeftTf then
                if _G.HTPS_EXC_AUTO_RUNNING then
                    _G.HTPS_EXC_AUTO_RUNNING = false
                end
                return
            end

            local btnLvUpTf = pageLeftTf:Find("ButtonLvUp")
            if not btnLvUpTf or btnLvUpTf:Equals(nil) then return end

            local btnTf = pageLeftTf:Find("BtnHTPSAutoEXC")
            if btnTf and not btnTf:Find("SkinV1") then
                UG.Object.DestroyImmediate(btnTf.gameObject)
                btnTf = nil
            end

            if not btnTf then
                local cloneGo = GO.Instantiate(btnLvUpTf.gameObject, pageLeftTf, false)
                cloneGo.name = "BtnHTPSAutoEXC"

                local mk = GO("SkinV1")
                mk.transform:SetParent(cloneGo.transform, false)
                mk:SetActive(false)

                local gn = cloneGo.transform:Find("GoNotify")
                if gn then
                    UG.Object.DestroyImmediate(gn.gameObject)
                end

                local rtRef = btnLvUpTf:GetComponent(typeof(UG.RectTransform))
                local rt = cloneGo:GetComponent(typeof(UG.RectTransform))
                if rt and rtRef then
                    rt.anchorMin = rtRef.anchorMin
                    rt.anchorMax = rtRef.anchorMax
                    rt.pivot = rtRef.pivot
                    rt.anchoredPosition = UG.Vector2(100.0, -149.0)
                    rt.sizeDelta = UG.Vector2(206.0, 50.0)
                end

                local spYellow = (_G.HTPS_FindNativeSprite and _G.HTPS_FindNativeSprite("button_yellow", true)) or nil
                local img = cloneGo:GetComponent(typeof(UG.UI.Image))
                if img and spYellow then
                    img.sprite = spYellow
                    img.type = UG.UI.Image.Type.Sliced
                    img.color = UG.Color(1.0, 1.0, 1.0, 1.0)
                end

                local txtTf = cloneGo.transform:Find("Text")
                local txt = (txtTf and txtTf:GetComponent(typeof(UG.UI.Text))) or cloneGo:GetComponentInChildren(typeof(UG.UI.Text), true)
                if txt and not txt:Equals(nil) then
                    local loc = txt.gameObject:GetComponent(typeof(CS.I2.Loc.Localize))
                    if loc then UG.Object.DestroyImmediate(loc) end

                    local shds = txt.gameObject:GetComponents(typeof(UG.UI.Shadow))
                    if shds then
                        for i = 0, shds.Length - 1 do
                            UG.Object.DestroyImmediate(shds[i])
                        end
                    end

                    local trt = txt.gameObject:GetComponent(typeof(UG.RectTransform))
                    if trt then
                        trt.anchorMin = UG.Vector2(0, 0)
                        trt.anchorMax = UG.Vector2(1, 1)
                        trt.offsetMin = UG.Vector2(12, 5)
                        trt.offsetMax = UG.Vector2(-12, -3)
                    end

                    txt.alignment = UG.TextAnchor.MiddleCenter
                    txt.fontStyle = UG.FontStyle.Normal
                    txt.fontSize = 20
                    txt.resizeTextForBestFit = true
                    txt.resizeTextMinSize = 12
                    txt.resizeTextMaxSize = 20
                    txt.text = "Auto Luyện Hồn"
                    txt.color = spYellow and UG.Color(0.510, 0.318, 0.165, 1.0) or UG.Color(1.0, 0.96, 0.86, 1.0)

                    local lout = txt.gameObject:AddComponent(typeof(UG.UI.Outline))
                    lout.effectColor = UG.Color(0.32, 0.06, 0.05, 1.0)
                    lout.effectDistance = UG.Vector2(1.2, -1.2)
                    lout.enabled = (spYellow == nil)
                end

                local bc = cloneGo:GetComponent(typeof(UG.UI.Button))
                if bc then
                    bc.onClick = UG.UI.Button.ButtonClickedEvent()
                end

                btnTf = cloneGo.transform
            end

            if btnTf then
                _G.HTPS_UpdateEXCBtnUI(panel)
                if _G.HTPS_BOUND_EXC_AUTO_BTN ~= btnTf then
                    local bc = btnTf:GetComponent(typeof(UG.UI.Button))
                    if bc then
                        bc.onClick = UG.UI.Button.ButtonClickedEvent()
                        bc.onClick:AddListener(function()
                            _G.HTPS_ToggleAutoEXC()
                        end)
                    end
                    _G.HTPS_BOUND_EXC_AUTO_BTN = btnTf
                end
            end
        end)
    end

    -- ==================== PET SUMMON FAST & AUTO AWAKEN (LUA PET) ====================
    _G.HTPS_PET_SUMMON_RUNNING = _G.HTPS_PET_SUMMON_RUNNING or false
    _G.HTPS_PET_SUMMON_LOCK = _G.HTPS_PET_SUMMON_LOCK or false
    _G.HTPS_PET_SUMMON_COUNT = _G.HTPS_PET_SUMMON_COUNT or 0
    _G.HTPS_PET_SUMMON_STATUS = _G.HTPS_PET_SUMMON_STATUS or ""
    _G.HTPS_PET_MERGE_COUNT = _G.HTPS_PET_MERGE_COUNT or 0
    _G.HTPS_PET_MERGE_STATS = _G.HTPS_PET_MERGE_STATS or { SS = 0, S = 0, PHOI = 0 }
    _G.HTPS_PET_AWAKEN_RUNNING = _G.HTPS_PET_AWAKEN_RUNNING or false
    _G.HTPS_PET_AWAKEN_LOCK = _G.HTPS_PET_AWAKEN_LOCK or false
    _G.HTPS_PET_AWAKEN_STATUS = _G.HTPS_PET_AWAKEN_STATUS or ""

    _G.HTPS_ApplyNativePetBtnStyle = function(btnTf, labelText, isGreen)
        if not btnTf or btnTf:Equals(nil) then return end
        pcall(function()
            local img = btnTf:GetComponent(typeof(UG.UI.Image))
            if img then
                local sp = _G.HTPS_FindNativeSprite(isGreen and "button_green" or "button_yellow", true)
                if sp then
                    img.sprite = sp
                    img.type = UG.UI.Image.Type.Sliced
                end
                img.color = UG.Color(1, 1, 1, 1)
            end
            local txt = btnTf:GetComponentInChildren(typeof(UG.UI.Text), true)
            if txt then
                txt.text = labelText
                txt.resizeTextForBestFit = true
                txt.resizeTextMinSize = 11
                txt.resizeTextMaxSize = 20
                txt.fontSize = 19
                txt.lineSpacing = 0.92
                local outl = txt.gameObject:GetComponent(typeof(UG.UI.Outline))
                if isGreen then
                    txt.color = UG.Color(1, 1, 1, 1)
                    if not outl then outl = txt.gameObject:AddComponent(typeof(UG.UI.Outline)) end
                    outl.effectColor = UG.Color(0.06, 0.26, 0.08, 0.95)
                    outl.effectDistance = UG.Vector2(1.2, -1.2)
                    outl.enabled = true
                else
                    txt.color = UG.Color(0.51, 0.32, 0.16, 1)
                    if outl then outl.enabled = false end
                end
            end
        end)
    end

    _G.HTPS_PetSendActs = function(mainAct, specs)
        local gc = CS.GameContext.GetIntance()
        local csNet = CS.NetworkController.GetInstance()
        if not gc or not gc.m_Session or gc.m_Session == "" or not csNet or not csNet.m_UrlGameServer or csNet.m_UrlGameServer == "" then
            return nil, "invalid_session"
        end
        local req = CS.pbdson.RequestData()
        req.session = gc.m_Session
        for _, sp in ipairs(specs) do
            local a = CS.pbdson.PbAction()
            a.actionId = sp.id
            local cv = CS.pbdson.CommonVector()
            if sp.vals then
                for _, v in ipairs(sp.vals) do cv.aLong:Add(v) end
            end
            a.data = _G.HTPS_SerializeProto(cv)
            req.actions:Add(a)
        end
        local d, okNet, responseCode = _G.HTPS_PutWebRequest(
            csNet.m_UrlGameServer .. "/i/" .. tostring(mainAct) .. "/" .. tostring(gc.m_UserId),
            _G.HTPS_SerializeProto(req),
            12
        )
        if not okNet or not d then return nil, "Mất kết nối server!", responseCode end
        local resp = _G.HTPS_DeserializeProto(d, "pbdson.ResponseData,PbMethodLib")
        if not resp or not resp.aAction then return nil, "Phản hồi không hợp lệ!" end
        local errMsg, results = nil, {}
        for i = 0, resp.aAction.Count - 1 do
            local ra = resp.aAction[i]
            if ra.actionId == 1 and ra.data then
                local rcv = _G.HTPS_DeserializeProto(ra.data, "pbdson.CommonVector,PbMethodLib")
                if rcv and rcv.aString and rcv.aString.Count > 0 then
                    errMsg = tostring(rcv.aString[0])
                else
                    errMsg = "Server lỗi"
                end
            else
                table.insert(results, ra)
            end
        end
        return results, errMsg, responseCode
    end

    _G.HTPS_GetLivePetSummon = function()
        local found = nil
        pcall(function()
            local uiMng = _G.UIUpdateMng and _G.UIUpdateMng:instance()
            local lst = uiMng and uiMng.listUpdateListener and uiMng.listUpdateListener:getList()
            if lst then
                for _, h in ipairs(lst) do
                    if h and not h.disposed and h.btnSummon10 and h.countDownText and h.goRoot and not h.goRoot:Equals(nil) and h.goRoot.activeInHierarchy then
                        found = h
                        break
                    end
                end
            end
            if not found then
                local pdi = _G.PetDataItem and _G.PetDataItem:instance()
                local ps = pdi and pdi.petSummon
                if ps and not ps.disposed and ps.btnSummon10 and ps.goRoot and not ps.goRoot:Equals(nil) and ps.goRoot.activeInHierarchy then
                    found = ps
                end
            end
        end)
        return found
    end

    _G.HTPS_GetLivePetInventory = function()
        local found = nil
        pcall(function()
            local uiMng = _G.UIUpdateMng and _G.UIUpdateMng:instance()
            local lst = uiMng and uiMng.listUpdateListener and uiMng.listUpdateListener:getList()
            if lst then
                for _, h in ipairs(lst) do
                    if h and not h.disposed and h.petPanelAwaken and h.petPanelAwaken.groupUpgrade and h.goRoot and not h.goRoot:Equals(nil) and h.goRoot.activeInHierarchy then
                        found = h
                        break
                    end
                end
            end
        end)
        return found
    end

    _G.HTPS_PetApplySyncData = function(rawData, refreshInventory, skipUiRedraw)
        if not rawData then return false end
        local pdi = _G.PetDataItem and _G.PetDataItem:instance()
        if not pdi or not pdi.petHome then return false end
        local applied = pcall(function()
            pdi.petHome.funcUpgradeStar = nil
            pdi.petHome.funcUpdate = nil
            if not skipUiRedraw then
                local livePI = refreshInventory and _G.HTPS_GetLivePetInventory() or nil
                local livePS = (not refreshInventory) and _G.HTPS_GetLivePetSummon() or nil
                if livePI then
                    pdi.petHome:AssignUpdateUI(function()
                        pcall(function()
                            if livePI.disposed then return end
                            livePI:SetArea(livePI.area)
                            livePI:SetPetListToTab(livePI.m_PetListTabId)
                            pdi.m_ReceivedHeroUpLevelData = true
                            local cur = livePI:GetCurrentPet(livePI.currentPetId)
                            if cur then
                                livePI:MoveToPet(livePI.currentPetId)
                            elseif livePI.petTabList and livePI.petTabList:count() > 0 then
                                livePI:MoveToPet(livePI.petTabList:getAt(1).petId)
                            end
                            if livePI.petExpItemText then
                                livePI.petExpItemText.text = CS.PlayerInventory.GetInstance():GetNumberItemConsumable(3004)
                            end
                            if livePI.petBoxScript then
                                pcall(function() livePI.petBoxScript:UpgradePet() end)
                            end
                        end)
                    end)
                elseif livePS then
                    pdi.petHome:AssignUpdateUI(function()
                        pcall(function()
                            if not livePS.disposed then livePS:SetData() end
                        end)
                    end)
                end
            end
            pdi.petHome:processKEvent(940, rawData)
        end)
        return applied
    end

    _G.HTPS_PetSync940 = function(refreshInventory, skipUiRedraw)
        local pdi = _G.PetDataItem and _G.PetDataItem:instance()
        if not pdi or not pdi.petHome then return false end
        local res, err = _G.HTPS_PetSendActs(940, { {id = 940} })
        if res and #res > 0 and res[1].actionId == 940 and res[1].data then
            local applied = _G.HTPS_PetApplySyncData(res[1].data, refreshInventory, skipUiRedraw)
            return applied, applied and nil or "Chưa đọc được dữ liệu kho Pet"
        end
        return false, err
    end

    _G.HTPS_PetParseCommonBonus = function(ra)
        if ra and ra.data then
            pcall(function()
                local cv = _G.HTPS_DeserializeProto(ra.data, "pbdson.CommonVector,PbMethodLib")
                if cv and cv.aLong and cv.aLong.Count > 0 then
                    CS.BonusModel.ParseBonusReceived(cv.aLong)
                end
            end)
        end
    end

    _G.HTPS_PetIsBagFullErr = function(errMsg)
        if not errMsg then return false end
        local s = tostring(errMsg)
        local sl = s:lower()
        return (s:find("đầy", 1, true) ~= nil) or (sl:find("full", 1, true) ~= nil) or (sl:find("day", 1, true) ~= nil)
    end

    _G.HTPS_PetCreateOps = function(isRunningFn, syncFn, allowLibrary, initialCap, onMergeFn)
        local pdi = _G.PetDataItem:instance()
        local pldb = _G.PetLoadDb:getInstance()
        local inv = CS.PlayerInventory.GetInstance()
        local gc = CS.GameContext.GetIntance()
        local maxStar = pldb:GetMaxStar() or 10
        local starRules = {}
        for _, st in ipairs(pldb:GetListStar().listElement) do starRules[st.star] = st end
        local petsInfo = {}
        for _, inf in ipairs(pldb:GetListPet().listElement) do petsInfo[inf.id] = inf end
        local fmtNum = _G.HTPS_FormatExactInt or tostring
        local knownBagCap = initialCap or 1000
        local needZeroFromTo5 = {}
        for b = 0, 4 do
            local sumZ = (b == 0) and 1 or 0
            for ss = b + 1, 5 do
                sumZ = sumZ + (starRules[ss] and starRules[ss].shard or 0)
            end
            needZeroFromTo5[b] = sumZ
        end

        local ops = {
            pdi = pdi, pldb = pldb, inv = inv, gc = gc,
            maxStar = maxStar, starRules = starRules, petsInfo = petsInfo,
            needZeroFromTo5 = needZeroFromTo5, fmtNum = fmtNum,
            allowLibrary = allowLibrary and true or false,
            allowFodderLibrary = allowLibrary and true or false,
            reservedFodderQuota = nil,
            sessionMerges = 0,
        }
        local function reportProgress(text)
            if ops.onProgress then ops.onProgress(text) end
        end
        ops.getKnownBagCap = function() return knownBagCap end
        ops.setKnownBagCap = function(c)
            if c and c > 0 then knownBagCap = c end
        end

        local lastYieldTime = UG.Time.realtimeSinceStartup
        ops.yieldIfDue = function(force)
            local now = UG.Time.realtimeSinceStartup
            if force or (now - lastYieldTime) >= 0.08 then
                lastYieldTime = now
                coroutine.yield(nil)
            end
        end

        ops.syncNow = function(skipUiRedraw)
            _G.HTPS_BONUS_SUPPRESS_UNTIL = UG.Time.realtimeSinceStartup + 2.0
            if syncFn then return syncFn(skipUiRedraw) end
        end

        ops.sendActsSync = function(mainAct, acts, onActionFn, skipUiRedraw)
            local reqActs = {}
            for _, a in ipairs(acts) do table.insert(reqActs, a) end
            if #reqActs == 0 or reqActs[#reqActs].id ~= 940 then
                table.insert(reqActs, {id = 940})
            end
            _G.HTPS_BONUS_SUPPRESS_UNTIL = UG.Time.realtimeSinceStartup + 2.0
            local r, err = _G.HTPS_PetSendActs(mainAct, reqActs)
            local gotCnt, gotSync = 0, false
            if r then
                for _, ra in ipairs(r) do
                    if ra.actionId == 940 and ra.data then
                        gotSync = _G.HTPS_PetApplySyncData(ra.data, false, skipUiRedraw ~= false) or gotSync
                    elseif ra.actionId == mainAct then
                        gotCnt = gotCnt + 1
                        if onActionFn then
                            onActionFn(ra, gotCnt)
                        else
                            _G.HTPS_PetParseCommonBonus(ra)
                        end
                    end
                end
            end
            if not gotSync then
                gotSync = ops.syncNow(skipUiRedraw ~= false)
            end
            local expected = 0
            for _, action in ipairs(acts) do if action.id == mainAct then expected = expected + 1 end end
            if not err and gotCnt < expected then
                err = string.format("Máy chủ mới xác nhận %d/%d thao tác Pet. Đã đọc lại kho; thử lại sau.", gotCnt, expected)
            elseif not err and not gotSync then
                err = "Đã nhận thao tác nhưng chưa đồng bộ được kho Pet. Thử lại sau."
            end
            return r, err, gotCnt
        end

        ops.getPetById = function(pid)
            for _, p in ipairs(pdi.petOwnedList.listElement) do
                if p.petId == pid then return p end
            end
            return nil
        end

        ops.getPieceMap = function()
            local m = {}
            for _, sh in ipairs(pdi.petPieceList.listElement) do
                m[sh[1]] = sh[2]
            end
            return m
        end

        ops.getShardReq = function(setId)
            local inf = petsInfo[setId]
            local req = inf and tonumber(inf.shardReq) or 50
            return (req and req > 0) and req or 50
        end

        ops.getRankOfSet = function(setId)
            local inf = petsInfo[setId]
            return (inf and tonumber(inf.rank)) or 99
        end

        ops.isMaterialSafe = function(p, selfPetId, excl)
            if not p or (_G.HTPS_IsPreferredPet and _G.HTPS_IsPreferredPet(p)) or (selfPetId and p.petId == selfPetId) or (excl and excl[p.petId]) then
                return false
            end
            return pdi:GetPetEquipped(p.petId) <= 0 and (p.heroId or -1) <= 0
               and (p.level or 1) == 1 and (p.tier or 0) == 0 and (p.changeBasic or 0) == 0
        end

        ops.findSafeSamePets = function(targetSetId, filterFn, excl, selfPetId)
            local res = {}
            for _, p in ipairs(pdi.petOwnedList.listElement) do
                if p.setId == targetSetId and ops.isMaterialSafe(p, selfPetId, excl) then
                    if not filterFn or filterFn(p) then table.insert(res, p) end
                end
            end
            table.sort(res, function(a, b) return (a.petId or 0) < (b.petId or 0) end)
            return res
        end

        local function copyExcl(src, extraId)
            local t = {}
            if src then for k, v in pairs(src) do t[k] = v end end
            if extraId then t[extraId] = true end
            return t
        end

        local function isFodderBlockedSid(sid, mainTargetSetId)
            if not sid then return true end
            if mainTargetSetId and sid == mainTargetSetId then return true end
            local protTid = ops.protectedTargetSetId
            if protTid and protTid > 0 and sid == protTid then return true end
            return false
        end

        -- Builds current protection/fodder snapshot:
        --   Tier 1: D(1)->C(2)->B(3)->A(4) fully usable.
        --   Tier 2: S(5) keeps 1 highest original copy per species (preferring raised/7*/8* originals over 5*/6*/9* fodder packs); all excess S usable.
        --   Tier 3: SS(6) allows ONLY redundant 5* clones (when >=6* exists or >=2x 5* exists, keeping oldest 5* main); 0*-4* and >=6* SS are never fodder.
        local function buildFodderState(mainTargetSetId)
            local sBestBySid = {}
            local ssState = {}
            for _, p in ipairs(pdi.petOwnedList.listElement) do
                local sid = p.setId
                local rk = ops.getRankOfSet(sid)
                local st = p.star or 0
                if rk == 5 and not ops.useAllLowerFodder and not isFodderBlockedSid(sid, mainTargetSetId) then
                    local cur = sBestBySid[sid]
                    local pUnsafe = (not ops.isMaterialSafe(p, nil, nil)) and 1 or 0
                    local cUnsafe = cur and ((not ops.isMaterialSafe(cur, nil, nil)) and 1 or 0) or -1
                    local pNonFod = (st == 7 or st == 8 or st >= 10) and 1 or 0
                    local cNonFod = cur and (((cur.star or 0) == 7 or (cur.star or 0) == 8 or (cur.star or 0) >= 10) and 1 or 0) or -1
                    local cSt = cur and (cur.star or 0) or -1
                    local better = (not cur)
                        or (pUnsafe ~= cUnsafe and pUnsafe > cUnsafe)
                        or (pUnsafe == cUnsafe and pNonFod ~= cNonFod and pNonFod > cNonFod)
                        or (pUnsafe == cUnsafe and pNonFod == cNonFod and st ~= cSt and st > cSt)
                        or (pUnsafe == cUnsafe and pNonFod == cNonFod and st == cSt and (p.petId or 0) < (cur.petId or 0))
                    if better then sBestBySid[sid] = p end
                elseif rk == 6 and not isFodderBlockedSid(sid, mainTargetSetId) then
                    local info = ssState[sid]
                    if not info then
                        info = { has6to9 = false, has10 = false, hasHigh = false, safeFives = {} }
                        ssState[sid] = info
                    end
                    if st >= maxStar then
                        info.has10 = true
                        info.hasHigh = true
                    elseif st >= 6 then
                        info.has6to9 = true
                        info.hasHigh = true
                    elseif st == 5 and ops.isMaterialSafe(p, nil, nil) then
                        table.insert(info.safeFives, p.petId)
                    end
                end
            end
            local protIds = {}
            local protBySid = {}
            for sid, p in pairs(sBestBySid) do
                protIds[p.petId] = true
                protBySid[sid] = p.petId
            end
            local ssMainFiveBySid = {}
            local completedSSSet = {}
            for sid, info in pairs(ssState) do
                if not info.hasHigh and #info.safeFives > 0 then
                    table.sort(info.safeFives)
                    ssMainFiveBySid[sid] = info.safeFives[1]
                    protIds[info.safeFives[1]] = true
                end
                if info.has10 and not info.has6to9 and #info.safeFives == 0 then
                    completedSSSet[sid] = true
                end
            end
            return {
                protIds = protIds,
                protBySid = protBySid,
                ssMainFiveBySid = ssMainFiveBySid,
                ssState = ssState,
                completedSSSet = completedSSSet,
            }
        end

        local function isPetEligibleAsFodder(p, mainTargetSetId, excl, selfPetId, state)
            if not ops.isMaterialSafe(p, selfPetId, excl) then return false end
            if isFodderBlockedSid(p.setId, mainTargetSetId) then return false end
            local rk = ops.getRankOfSet(p.setId)
            if rk <= 4 then return true end
            state = state or buildFodderState(mainTargetSetId)
            if rk == 5 then
                return not state.protIds[p.petId]
            elseif rk == 6 then
                if (p.star or 0) == 5 then
                    return not state.protIds[p.petId]
                end
                return false
            end
            return false
        end

        ops.getProtectedFodderId = function(sid, mainTargetSetId)
            local rk = ops.getRankOfSet(sid)
            if rk ~= 5 or isFodderBlockedSid(sid, mainTargetSetId) then return nil end
            local st = buildFodderState(mainTargetSetId)
            return st.protBySid[sid]
        end

        ops.getCompletedSSSet = function(mainTargetSetId)
            return buildFodderState(mainTargetSetId).completedSSSet
        end

        ops.findSafeFodderSamePets = function(sid, filterFn, excl, selfPetId, mainTargetSetId, state)
            local res = {}
            state = state or buildFodderState(mainTargetSetId)
            for _, p in ipairs(pdi.petOwnedList.listElement) do
                if p.setId == sid and isPetEligibleAsFodder(p, mainTargetSetId, excl, selfPetId, state) then
                    if not filterFn or filterFn(p) then table.insert(res, p) end
                end
            end
            table.sort(res, function(a, b) return (a.petId or 0) < (b.petId or 0) end)
            return res
        end

        local function withProtectedExcl(sid, mainTargetSetId, excl, state)
            if not sid or isFodderBlockedSid(sid, mainTargetSetId) or ops.getRankOfSet(sid) ~= 5 then return excl end
            state = state or buildFodderState(mainTargetSetId)
            local pid = state.protBySid[sid]
            return pid and copyExcl(excl, pid) or excl
        end

        local function getKeepQuota(mainTargetSetId)
            local q = ops.reservedFodderQuota
            if not q or not q.setId or q.setId <= 0 or mainTargetSetId == q.setId then
                return 0, 0, 0
            end
            return (q.star5 or 0), (q.star6 or 0), (q.star9 or 0)
        end

        local function countSafeFodderPets(starVal, excl, selfPetId, mainTargetSetId)
            local state = buildFodderState(mainTargetSetId)
            local cnt = 0
            for _, p in ipairs(pdi.petOwnedList.listElement) do
                if (p.star or 0) == starVal and isPetEligibleAsFodder(p, mainTargetSetId, excl, selfPetId, state) then
                    cnt = cnt + 1
                end
            end
            return cnt
        end

        -- 3-tier fodder set list:
        --   craftableOnly=true  -> D(1)->C(2)->B(3)->A(4)->S(5) (craft bases/packs)
        --   craftableOnly=false -> also includes SS(6) at tail so redundant 5* SS clones are consumed as 5* fodder
        ops.getOrderedFodderSetIds = function(mainTargetSetId, craftableOnly)
            local seen, list = {}, {}
            local maxRk = craftableOnly and 5 or 6
            local function addIfEligible(sid)
                if not sid or seen[sid] or isFodderBlockedSid(sid, mainTargetSetId) then return end
                if ops.getRankOfSet(sid) <= maxRk then
                    seen[sid] = true
                    table.insert(list, sid)
                end
            end
            for sid, _ in pairs(petsInfo) do addIfEligible(sid) end
            for _, p in ipairs(pdi.petOwnedList.listElement) do addIfEligible(p.setId) end
            table.sort(list, function(a, b)
                local ta = (a == mainTargetSetId) and 1 or 0
                local tb = (b == mainTargetSetId) and 1 or 0
                if ta ~= tb then return ta < tb end
                local ra, rb = ops.getRankOfSet(a), ops.getRankOfSet(b)
                if ra ~= rb then return ra < rb end
                return a < b
            end)
            return list
        end

        local function sendMerge946(acts, baseSetOrMap)
            if not acts or #acts == 0 then return nil, nil, 0 end
            local expectedStars = {}
            for _, action in ipairs(acts) do
                local pid = action.vals and action.vals[1]
                local pet = pid and ops.getPetById(pid)
                if pet then expectedStars[pid] = (expectedStars[pid] or pet.star or 0) + 1 end
            end
            local bySid = {}
            local _, err, okCnt = ops.sendActsSync(946, acts, function(ra, idx)
                _G.HTPS_PetParseCommonBonus(ra)
                local sid = (type(baseSetOrMap) == "table") and baseSetOrMap[idx] or baseSetOrMap
                if sid then bySid[sid] = (bySid[sid] or 0) + 1 end
            end, true)
            if not err then
                for pid, star in pairs(expectedStars) do
                    local pet = ops.getPetById(pid)
                    if not pet or (pet.star or 0) < star then
                        err = "Chưa xác nhận sao Pet sau khi ghép. Đã đọc lại kho; thử lại sau."
                        break
                    end
                end
            end
            if okCnt > 0 then
                ops.sessionMerges = (ops.sessionMerges or 0) + okCnt
                if onMergeFn then
                    for sid, cnt in pairs(bySid) do
                        pcall(onMergeFn, sid, cnt)
                    end
                end
            end
            return true, err, okCnt
        end

        ops.foldReadyZeroToFive = function(setId, excl, reserved, selfPetId)
            if ops.getRankOfSet(setId) > 5 then return false end
            local madeAny = false
            local resCount = (reserved and reserved[setId]) or 0
            local protExcl = withProtectedExcl(setId, nil, excl)
            while isRunningFn() do
                local lst = ops.findSafeSamePets(setId, function(p) return (p.star or 0) == 0 end, protExcl, selfPetId)
                local usable = #lst - resCount
                if usable < 22 or inv:GetNumberItemConsumable(2) < 62000 then break end
                local nSets = math.min(math.floor(usable / 22), 9, math.floor(inv:GetNumberItemConsumable(2) / 62000))
                if nSets < 1 then break end
                local idx, acts = 1, {}
                for _ = 1, nSets do
                    local b = lst[idx].petId
                    idx = idx + 1
                    for s = 1, 5 do
                        local vals = {b}
                        for _ = 1, starRules[s].shard do
                            table.insert(vals, lst[idx].petId)
                            idx = idx + 1
                        end
                        table.insert(acts, {id = 946, vals = vals})
                    end
                end
                local _, err, okCnt = sendMerge946(acts, setId)
                if okCnt > 0 then
                    madeAny = true
                    ops.yieldIfDue(false)
                end
                if err or okCnt == 0 then break end
            end
            return madeAny
        end

        ops.foldPartialStepForSet = function(setId, excl, reserved, selfPetId, maxTargetStar, allowFromZero)
            if ops.getRankOfSet(setId) > 5 then return false end
            local maxT = maxTargetStar or 5
            local resCount = (reserved and reserved[setId]) or 0
            local protExcl = withProtectedExcl(setId, nil, excl)
            local bases = ops.findSafeSamePets(setId, function(p)
                local st = p.star or 0
                if allowFromZero then return st >= 0 and st < maxT end
                return st >= 1 and st < maxT
            end, protExcl, selfPetId)
            table.sort(bases, function(a, b)
                if (a.star or 0) ~= (b.star or 0) then return (a.star or 0) > (b.star or 0) end
                return (a.petId or 0) < (b.petId or 0)
            end)
            local crysNow = inv:GetNumberItemConsumable(2)
            for _, bObj in ipairs(bases) do
                local nextS = (bObj.star or 0) + 1
                local rs = starRules[nextS]
                local needZ = rs and rs.shard or 0
                local zeros = ops.findSafeSamePets(setId, function(p) return (p.star or 0) == 0 end, copyExcl(protExcl, bObj.petId), selfPetId)
                if rs and needZ > 0 and (#zeros - resCount) >= needZ and crysNow >= (rs.numItem or 0) then
                    local vals = {bObj.petId}
                    for k = 1, needZ do table.insert(vals, zeros[k].petId) end
                    local _, err, okCnt = sendMerge946({ {id = 946, vals = vals} }, setId)
                    if okCnt > 0 and not err then
                        ops.yieldIfDue(false)
                        return true
                    end
                end
            end
            return false
        end

        -- Batch-fold multiple fodder sets (D..A + unprotected S) into targetStar (4* or 5*) in up to 45 actions per HTTP call.
        ops.batchFoldFodder = function(lowSids, desiredFree, maxTargetStar, allowFromZero, reserveMapFn, excl, selfPetId, maxRankCap)
            local totalMerges, builtTargetAny = 0, false
            local rankCap = maxRankCap or 5
            local function curFree()
                local c = (pdi.petOwnedList and pdi.petOwnedList.listElement and #pdi.petOwnedList.listElement) or 0
                return math.max(0, ops.getKnownBagCap() - c)
            end
            while isRunningFn() and curFree() < desiredFree do
                local state = buildFodderState(nil)
                local acts, actSids = {}, {}
                local used = copyExcl(excl)
                for pid, _ in pairs(state.protIds) do used[pid] = true end
                local crysAvail = inv:GetNumberItemConsumable(2)
                local estFreed = 0
                local freeNeed = desiredFree - curFree()
                for _, sid in ipairs(lowSids) do
                    if #acts >= 45 or estFreed >= freeNeed then break end
                    if ops.getRankOfSet(sid) <= rankCap and not isFodderBlockedSid(sid, nil) then
                        local resCount = reserveMapFn and reserveMapFn(sid) or 0
                        local zeros = ops.findSafeSamePets(sid, function(p) return (p.star or 0) == 0 end, used, selfPetId)
                        local zAvail = #zeros - resCount
                        local zi = 1
                        -- First advance partials 1★..(maxTargetStar-1) that can finish cleanly up to maxTargetStar
                        local partials = ops.findSafeSamePets(sid, function(p)
                            local st = p.star or 0
                            return st >= 1 and st < maxTargetStar
                        end, used, selfPetId)
                        table.sort(partials, function(a, b)
                            if (a.star or 0) ~= (b.star or 0) then return (a.star or 0) > (b.star or 0) end
                            return (a.petId or 0) < (b.petId or 0)
                        end)
                        for _, pb in ipairs(partials) do
                            if #acts >= 45 or estFreed >= freeNeed then break end
                            local pSt = pb.star or 1
                            local stepActs = {}
                            local tmpZi, tmpCrys, tmpZAvail = zi, crysAvail, zAvail
                            local reachedMax = true
                            for ss = pSt + 1, maxTargetStar do
                                local rs = starRules[ss]
                                local sh = rs and rs.shard or 0
                                local cs = rs and rs.numItem or 0
                                if tmpZAvail >= sh and tmpCrys >= cs and (#acts + #stepActs) < 45 then
                                    local vals = {pb.petId}
                                    for _ = 1, sh do
                                        table.insert(vals, zeros[tmpZi].petId)
                                        tmpZi = tmpZi + 1
                                    end
                                    table.insert(stepActs, vals)
                                    tmpZAvail = tmpZAvail - sh
                                    tmpCrys = tmpCrys - cs
                                else
                                    reachedMax = false
                                    break
                                end
                            end
                            -- For 5* pass require completing all the way to 5*; for 4* partial compression allow partial steps
                            if #stepActs > 0 and (allowFromZero or reachedMax) then
                                used[pb.petId] = true
                                for k = zi, tmpZi - 1 do used[zeros[k].petId] = true end
                                zi, crysAvail, zAvail = tmpZi, tmpCrys, tmpZAvail
                                for _, vals in ipairs(stepActs) do
                                    table.insert(acts, {id = 946, vals = vals})
                                    table.insert(actSids, sid)
                                    estFreed = estFreed + (#vals - 1)
                                end
                                if pSt + #stepActs >= maxTargetStar then builtTargetAny = true end
                            end
                        end
                        -- Then pack full 0★ -> maxTargetStar sets from remaining 0★ pool
                        local needPerSet = 1
                        local crysPerSet = 0
                        for ss = 1, maxTargetStar do
                            local rs = starRules[ss]
                            needPerSet = needPerSet + (rs and rs.shard or 0)
                            crysPerSet = crysPerSet + (rs and rs.numItem or 0)
                        end
                        while zAvail >= needPerSet and crysAvail >= crysPerSet
                            and (#acts + maxTargetStar) <= 45 and estFreed < freeNeed do
                            local bId = zeros[zi].petId
                            used[bId] = true
                            zi = zi + 1
                            for ss = 1, maxTargetStar do
                                local sh = starRules[ss].shard or 0
                                local vals = {bId}
                                for _ = 1, sh do
                                    used[zeros[zi].petId] = true
                                    table.insert(vals, zeros[zi].petId)
                                    zi = zi + 1
                                end
                                table.insert(acts, {id = 946, vals = vals})
                                table.insert(actSids, sid)
                            end
                            zAvail = zAvail - needPerSet
                            crysAvail = crysAvail - crysPerSet
                            estFreed = estFreed + (needPerSet - 1)
                            builtTargetAny = true
                        end
                        if allowFromZero and zAvail >= (1 + (starRules[1] and starRules[1].shard or 1))
                            and (#acts + 1) <= 45 and estFreed < freeNeed then
                            local cs1 = starRules[1] and starRules[1].numItem or 0
                            if crysAvail >= cs1 then
                                local bId = zeros[zi].petId
                                used[bId] = true
                                zi = zi + 1
                                zAvail = zAvail - 1
                                for ss = 1, maxTargetStar do
                                    local sh = starRules[ss] and starRules[ss].shard or 0
                                    local cs = starRules[ss] and starRules[ss].numItem or 0
                                    if zAvail < sh or crysAvail < cs or (#acts >= 45) or estFreed >= freeNeed then break end
                                    local vals = {bId}
                                    for _ = 1, sh do
                                        used[zeros[zi].petId] = true
                                        table.insert(vals, zeros[zi].petId)
                                        zi = zi + 1
                                    end
                                    table.insert(acts, {id = 946, vals = vals})
                                    table.insert(actSids, sid)
                                    zAvail = zAvail - sh
                                    crysAvail = crysAvail - cs
                                    estFreed = estFreed + sh
                                end
                            end
                        end
                    end
                end
                if #acts == 0 then break end
                local _, err, okCnt = sendMerge946(acts, actSids)
                totalMerges = totalMerges + okCnt
                ops.yieldIfDue(false)
                if err or okCnt == 0 then break end
            end
            return totalMerges, builtTargetAny
        end

        ops.tryFreeCommonSlots = function(mainTargetSetId, excl, reserved, selfPetId, needSlots)
            local sids = ops.getOrderedFodderSetIds(mainTargetSetId, true)
            local curOwned = (pdi.petOwnedList and pdi.petOwnedList.listElement and #pdi.petOwnedList.listElement) or 0
            local curFree = math.max(0, knownBagCap - curOwned)
            local desiredFree = curFree + math.max(needSlots or 0, 12)
            local resFn = reserved and function(sid) return reserved[sid] or 0 end or nil
            local m5 = ops.batchFoldFodder(sids, desiredFree, 5, false, resFn, excl, selfPetId, 5)
            if m5 > 0 then return true, m5 end
            local m4 = ops.batchFoldFodder(sids, desiredFree, 4, true, resFn, excl, selfPetId, 5)
            return (m4 > 0), m4
        end

        ops.craftSetCopies = function(setId, needCount, allowFoldOnFull, mainTargetSetId, excl, reserved, selfPetId)
            if needCount <= 0 then return 0, nil end
            if not ops.allowLibrary then
                return 0, "Thiếu bản thể trong túi"
            end
            local crafted, craftErr = 0, nil
            local shrinkBatch = false
            while crafted < needCount and isRunningFn() do
                local curOwned = (pdi.petOwnedList and pdi.petOwnedList.listElement and #pdi.petOwnedList.listElement) or 0
                local freeSlots = math.max(0, knownBagCap - curOwned)
                if freeSlots <= 0 then
                    if allowFoldOnFull then
                        ops.syncNow(true)
                        if ops.tryFreeCommonSlots(mainTargetSetId, excl, reserved, selfPetId) then
                            shrinkBatch = false
                        else
                            craftErr = string.format("Túi thú đầy (%d/%d), cần trống thêm %d ô để ghép từ Thư viện", curOwned, math.max(knownBagCap, curOwned), needCount - crafted)
                            break
                        end
                    else
                        craftErr = string.format("Túi thú đầy (%d/%d), cần trống thêm %d ô để ghép từ Thư viện", curOwned, math.max(knownBagCap, curOwned), needCount - crafted)
                        break
                    end
                end

                curOwned = (pdi.petOwnedList and pdi.petOwnedList.listElement and #pdi.petOwnedList.listElement) or 0
                freeSlots = math.max(0, knownBagCap - curOwned)
                local maxStep = shrinkBatch and 1 or math.max(1, math.min(75, freeSlots))
                local batch = math.min(maxStep, needCount - crafted)
                local specs = {}
                for _ = 1, batch do table.insert(specs, {id = 942, vals = {setId}}) end
                reportProgress(string.format("Đổi mảnh: %d/%d", crafted, needCount))
                local _, err, got = ops.sendActsSync(942, specs, nil, true)
                crafted = crafted + got
                reportProgress(string.format("Đổi mảnh: %d/%d", crafted, needCount))
                if err then
                    if _G.HTPS_PetIsBagFullErr(err) then
                        local curAfter = (pdi.petOwnedList and pdi.petOwnedList.listElement and #pdi.petOwnedList.listElement) or 0
                        if allowFoldOnFull and ops.tryFreeCommonSlots(mainTargetSetId, excl, reserved, selfPetId) then
                            shrinkBatch = false
                        elseif got == 0 and batch > 1 then
                            shrinkBatch = true
                        else
                            if got == 0 and batch == 1 and curAfter > 0 then
                                knownBagCap = curAfter
                            end
                            craftErr = string.format("Túi thú đầy (%d/%d), cần trống thêm %d ô để ghép từ Thư viện", curAfter, math.max(knownBagCap, curAfter), needCount - crafted)
                            break
                        end
                    else
                        craftErr = err
                        break
                    end
                else
                    shrinkBatch = false
                end
            end
            return crafted, craftErr
        end

        ops.ensureZeroCopies = function(setId, needCount, allowFoldOnFull, mainTargetSetId, excl, reserved, selfPetId)
            local workExcl = withProtectedExcl(setId, mainTargetSetId, excl)
            local pool = ops.findSafeSamePets(setId, function(p) return (p.star or 0) == 0 end, workExcl, selfPetId)
            if #pool >= needCount then return pool, nil end
            reportProgress(string.format("Bản thể: %d/%d", #pool, needCount))
            local canUseLib = ops.allowLibrary and (ops.allowFodderLibrary or (not mainTargetSetId) or (setId == mainTargetSetId))
            if not canUseLib then
                local pName = (petsInfo[setId] and petsInfo[setId].name) or ("#" .. tostring(setId))
                return pool, string.format("thiếu %d %s trong túi", needCount - #pool, pName)
            end
            local pm = ops.getPieceMap()
            local sReq = ops.getShardReq(setId)
            local canCraft = math.floor((pm[setId] or 0) / sReq)
            if #pool + canCraft < needCount then
                local lack = needCount - (#pool + canCraft)
                local pName = (petsInfo[setId] and petsInfo[setId].name) or ("#" .. tostring(setId))
                return pool, string.format("thiếu %d %s (%s mảnh; Thư viện còn %d con)", lack, pName, fmtNum(lack * sReq), canCraft)
            end
            local _, cErr = ops.craftSetCopies(setId, needCount - #pool, allowFoldOnFull, mainTargetSetId, workExcl, reserved, selfPetId)
            local updated = ops.findSafeSamePets(setId, function(p) return (p.star or 0) == 0 end, workExcl, selfPetId)
            return updated, cErr
        end

        ops.canAffordStarStep = function(targetObj, nextSt)
            local rule = starRules[nextSt]
            if not rule then return false, "Hết mốc sao" end
            local targetPetId = targetObj.petId
            local targetSetId = targetObj.setId
            local pName = (petsInfo[targetSetId] and petsInfo[targetSetId].name) or ("#" .. tostring(targetSetId))
            local orderedSids = ops.getOrderedFodderSetIds(targetSetId, false)
            local fodderState = buildFodderState(targetSetId)
            local pm = ops.allowLibrary and ops.getPieceMap() or {}
            local owned, craft, sReqMap = {}, {}, {}

            local function initSimSet(sid)
                if not owned[sid] then
                    owned[sid] = {}
                    for s = 0, 9 do owned[sid][s] = 0 end
                    sReqMap[sid] = ops.getShardReq(sid)
                    local useLibForSid = ops.allowLibrary and (sid == targetSetId or (ops.allowFodderLibrary and ops.getRankOfSet(sid) <= 5))
                    craft[sid] = useLibForSid and math.floor((pm[sid] or 0) / sReqMap[sid]) or 0
                end
            end
            initSimSet(targetSetId)
            for _, sid in ipairs(orderedSids) do initSimSet(sid) end

            for _, p in ipairs(pdi.petOwnedList.listElement) do
                if owned[p.setId] then
                    local okMat = (p.setId == targetSetId)
                        and ops.isMaterialSafe(p, targetPetId, nil)
                        or isPetEligibleAsFodder(p, targetSetId, nil, targetPetId, fodderState)
                    if okMat then
                        local st = p.star or 0
                        if owned[p.setId][st] ~= nil then
                            owned[p.setId][st] = owned[p.setId][st] + 1
                        end
                    end
                end
            end

            local crys = inv:GetNumberItemConsumable(2)
            local mainCrys = rule.numItem or 0
            if crys < mainCrys then
                return false, string.format("lên %d★ (%s) thiếu %s Đá Thức Tỉnh (cần %s)", nextSt, pName, fmtNum(mainCrys - crys), fmtNum(mainCrys))
            end
            crys = crys - mainCrys

            local sameNeed = (nextSt <= 5) and (rule.shard or 0) or (rule.samePet or 0)
            local tOwned0 = owned[targetSetId][0]
            local tCraft0 = craft[targetSetId]
            if tOwned0 + tCraft0 < sameNeed then
                local shortSame = sameNeed - (tOwned0 + tCraft0)
                local sReqT = sReqMap[targetSetId]
                if ops.allowLibrary then
                    return false, string.format("lên %d★ (%s) thiếu %d con cùng loài (%s mảnh; Thư viện còn %d con)", nextSt, pName, shortSame, fmtNum(shortSame * sReqT), tCraft0)
                else
                    return false, string.format("lên %d★ (%s) thiếu %d con cùng loài trong túi", nextSt, pName, shortSame)
                end
            end
            local takeOwned = math.min(tOwned0, sameNeed)
            owned[targetSetId][0] = owned[targetSetId][0] - takeOwned
            craft[targetSetId] = craft[targetSetId] - (sameNeed - takeOwned)

            local function simAvail0(sid) return (owned[sid][0] or 0) + (craft[sid] or 0) end
            local function simTake0(sid, n)
                local bagTake = math.min(owned[sid][0], n)
                owned[sid][0] = owned[sid][0] - bagTake
                craft[sid] = craft[sid] - (n - bagTake)
            end
            local function simCrysTo5(bSt)
                local sum = 0
                for ss = bSt + 1, 5 do sum = sum + (starRules[ss] and starRules[ss].numItem or 0) end
                return sum
            end

            local crysShort = 0
            local keep5, keep6, keep9 = getKeepQuota(targetSetId)
            local rem5, rem6, rem9 = 0, 0, 0
            for _, sid in ipairs(orderedSids) do
                rem5 = rem5 + (owned[sid][5] or 0)
                rem6 = rem6 + (owned[sid][6] or 0)
                rem9 = rem9 + (owned[sid][9] or 0)
            end
            local function simTryTakeStar(reqStar)
                if reqStar == 5 then
                    if rem5 > keep5 then
                        for i = #orderedSids, 1, -1 do
                            local sid = orderedSids[i]
                            if owned[sid][5] > 0 then
                                owned[sid][5] = owned[sid][5] - 1
                                rem5 = rem5 - 1
                                return true
                            end
                        end
                    end
                    local bestSid, bestBSt = nil, -1
                    local bestTier, bestBagFit = 999, 99
                    for _, sid in ipairs(orderedSids) do
                        local tier = (sid == targetSetId) and 999 or ops.getRankOfSet(sid)
                        if tier <= 5 then
                            local topB = nil
                            for b = 4, 1, -1 do if owned[sid][b] > 0 then topB = b; break end end
                            local candidatesB = {}
                            if topB then table.insert(candidatesB, topB) end
                            if simAvail0(sid) >= needZeroFromTo5[0] then table.insert(candidatesB, 0) end
                            for _, b in ipairs(candidatesB) do
                                local needZ = needZeroFromTo5[b]
                                if simAvail0(sid) >= needZ then
                                    local bagFit = (owned[sid][0] >= needZ) and 0 or 1
                                    local better = false
                                    if not bestSid then
                                        better = true
                                    elseif (b > 0) ~= (bestBSt > 0) then
                                        better = b > 0
                                    elseif bagFit ~= bestBagFit then
                                        better = bagFit < bestBagFit
                                    elseif tier ~= bestTier then
                                        better = tier < bestTier
                                    elseif b ~= bestBSt then
                                        better = b > bestBSt
                                    elseif owned[sid][0] ~= owned[bestSid][0] then
                                        better = owned[sid][0] > owned[bestSid][0]
                                    end
                                    if better then bestSid, bestBSt, bestTier, bestBagFit = sid, b, tier, bagFit end
                                end
                            end
                        end
                    end
                    if not bestSid then return false, "fodder5" end
                    local needC = simCrysTo5(bestBSt)
                    if crys < needC then crysShort = needC - crys; return false, "crys" end
                    crys = crys - needC
                    if bestBSt > 0 then owned[bestSid][bestBSt] = owned[bestSid][bestBSt] - 1 end
                    simTake0(bestSid, needZeroFromTo5[bestBSt])
                    return true
                elseif reqStar == 6 then
                    if rem6 > keep6 then
                        for _, sid in ipairs(orderedSids) do
                            if owned[sid][6] > 0 then
                                owned[sid][6] = owned[sid][6] - 1
                                rem6 = rem6 - 1
                                return true
                            end
                        end
                    end
                    local r6 = starRules[6]
                    local cost6 = r6 and r6.numItem or 35000
                    local same6 = r6 and r6.samePet or 2
                    if crys < cost6 then crysShort = cost6 - crys; return false, "crys" end
                    crys = crys - cost6

                    local bestSid, bestBSt = nil, -1
                    local bestTier, bestHas5 = 999, 99
                    for _, sid in ipairs(orderedSids) do
                        local tier = (sid == targetSetId) and 999 or ops.getRankOfSet(sid)
                        if tier <= 5 then
                            if rem5 > keep5 and owned[sid][5] > 0 and simAvail0(sid) >= same6 then
                                local better = (not bestSid) or (0 < bestHas5) or (0 == bestHas5 and tier < bestTier)
                                if better then bestSid, bestBSt, bestTier, bestHas5 = sid, 5, tier, 0 end
                            else
                                local b = nil
                                for x = 4, 1, -1 do if owned[sid][x] > 0 then b = x; break end end
                                if b and simAvail0(sid) >= needZeroFromTo5[b] + same6 then
                                    local better = (not bestSid) or (1 < bestHas5) or (1 == bestHas5 and (tier < bestTier or (tier == bestTier and b > bestBSt)))
                                    if better then bestSid, bestBSt, bestTier, bestHas5 = sid, b, tier, 1 end
                                elseif simAvail0(sid) >= needZeroFromTo5[0] + same6 then
                                    local better = (not bestSid) or (2 < bestHas5) or (2 == bestHas5 and tier < bestTier)
                                    if better then bestSid, bestBSt, bestTier, bestHas5 = sid, 0, tier, 2 end
                                end
                            end
                        end
                    end
                    if not bestSid then return false, "fodder6" end
                    if bestBSt < 5 then
                        local c5 = simCrysTo5(bestBSt)
                        if crys < c5 then crysShort = c5 - crys; return false, "crys" end
                        crys = crys - c5
                        if bestBSt > 0 then owned[bestSid][bestBSt] = owned[bestSid][bestBSt] - 1 end
                        simTake0(bestSid, needZeroFromTo5[bestBSt])
                    else
                        owned[bestSid][5] = owned[bestSid][5] - 1
                        rem5 = rem5 - 1
                    end
                    simTake0(bestSid, same6)
                    for _ = 1, (r6 and r6.star5Pet or 5) do
                        local ok5, r5 = simTryTakeStar(5)
                        if not ok5 then return false, r5 end
                    end
                    return true
                elseif reqStar == 9 then
                    if rem9 > keep9 then
                        for _, sid in ipairs(orderedSids) do
                            if owned[sid][9] > 0 then
                                owned[sid][9] = owned[sid][9] - 1
                                rem9 = rem9 - 1
                                return true
                            end
                        end
                    end
                    local bestSid, bestBSt, bestTier = nil, -1, 999
                    for _, sid in ipairs(orderedSids) do
                        local tier = (sid == targetSetId) and 999 or ops.getRankOfSet(sid)
                        if tier <= 5 then
                            local chosenB = nil
                            for b = 8, 5, -1 do
                                local bBlocked = (b == 5 and rem5 <= keep5) or (b == 6 and rem6 <= keep6) or (b >= 7 and rem9 < keep9)
                                if not bBlocked and owned[sid][b] > 0 then
                                    local needS0 = 0
                                    for ss = b + 1, 9 do needS0 = needS0 + (starRules[ss] and starRules[ss].samePet or 0) end
                                    if simAvail0(sid) >= needS0 then chosenB = b; break end
                                end
                            end
                            if not chosenB then
                                for b = 4, 0, -1 do
                                    if b == 0 or owned[sid][b] > 0 then
                                        local needS0 = needZeroFromTo5[b]
                                        for ss = 6, 9 do needS0 = needS0 + (starRules[ss] and starRules[ss].samePet or 0) end
                                        if simAvail0(sid) >= needS0 then chosenB = b; break end
                                    end
                                end
                            end
                            if chosenB then
                                local better = false
                                if not bestSid then
                                    better = true
                                elseif (chosenB >= 5) ~= (bestBSt >= 5) then
                                    better = chosenB >= 5
                                elseif chosenB ~= bestBSt then
                                    better = chosenB > bestBSt
                                elseif tier ~= bestTier then
                                    better = tier < bestTier
                                end
                                if better then bestSid, bestBSt, bestTier = sid, chosenB, tier end
                            end
                        end
                    end
                    if not bestSid then return false, "fodder9" end
                    if bestBSt < 5 then
                        local c5 = simCrysTo5(bestBSt)
                        if crys < c5 then crysShort = c5 - crys; return false, "crys" end
                        crys = crys - c5
                        if bestBSt > 0 then owned[bestSid][bestBSt] = owned[bestSid][bestBSt] - 1 end
                        simTake0(bestSid, needZeroFromTo5[bestBSt])
                    else
                        owned[bestSid][bestBSt] = owned[bestSid][bestBSt] - 1
                        if bestBSt == 5 then rem5 = rem5 - 1 elseif bestBSt == 6 then rem6 = rem6 - 1 end
                    end
                    for ss = math.max(6, bestBSt + 1), 9 do
                        local rl = starRules[ss]
                        local needC = rl and rl.numItem or 0
                        if crys < needC then crysShort = needC - crys; return false, "crys" end
                        crys = crys - needC
                        local needSame = rl and rl.samePet or 0
                        if simAvail0(bestSid) < needSame then return false, "fodder9" end
                        simTake0(bestSid, needSame)
                        for _ = 1, (rl and rl.star5Pet or 0) do
                            local ok5, r5 = simTryTakeStar(5)
                            if not ok5 then return false, r5 end
                        end
                        for _ = 1, (rl and rl.star6Pet or 0) do
                            local ok6, r6 = simTryTakeStar(6)
                            if not ok6 then return false, r6 end
                        end
                    end
                    return true
                end
                return false, "unsupported"
            end

            local needLists = {}
            if (rule.star5Pet or 0) > 0 then table.insert(needLists, {star = 5, cnt = rule.star5Pet}) end
            if (rule.star6Pet or 0) > 0 then table.insert(needLists, {star = 6, cnt = rule.star6Pet}) end
            if (rule.star9Pet or 0) > 0 then table.insert(needLists, {star = 9, cnt = rule.star9Pet}) end
            for _, nl in ipairs(needLists) do
                for i = 1, nl.cnt do
                    local okF, failCode = simTryTakeStar(nl.star)
                    if not okF then
                        if failCode == "crys" then
                            return false, string.format("lên %d★ (%s) thiếu %s Đá Thức Tỉnh", nextSt, pName, fmtNum(crysShort))
                        end
                        return false, string.format("lên %d★ (%s) không đủ phôi (D..A/S dư) cho mốc phôi %d★ (thiếu từ ô %d/%d)", nextSt, pName, nl.star, i, nl.cnt)
                    end
                end
            end
            return true, nil
        end

        local function upgradeToFiveBatched(sid, baseObj, stepExcl, mainTargetSetId, excl, reserved, selfPetId, failLabel)
            local baseId = baseObj.petId
            local curSt = baseObj.star or 0
            if curSt >= 5 then return true, nil end
            local workExcl = withProtectedExcl(sid, mainTargetSetId, stepExcl)

            local needTotal, crysTotal = 0, 0
            for ss = curSt + 1, 5 do
                local rs = starRules[ss]
                needTotal = needTotal + (rs and rs.shard or 0)
                crysTotal = crysTotal + (rs and rs.numItem or 0)
            end
            if inv:GetNumberItemConsumable(2) < crysTotal then
                return false, string.format("Thiếu %s Đá Thức Tỉnh (cần %s)", fmtNum(crysTotal - inv:GetNumberItemConsumable(2)), fmtNum(crysTotal))
            end

            local curOwned = (pdi.petOwnedList and pdi.petOwnedList.listElement and #pdi.petOwnedList.listElement) or 0
            local curFree = math.max(0, knownBagCap - curOwned)
            local safeZerosNow = ops.findSafeSamePets(sid, function(p) return (p.star or 0) == 0 end, workExcl, selfPetId)
            local resGap = math.max(0, needTotal - #safeZerosNow)
            if #safeZerosNow >= needTotal or (ops.allowLibrary and (ops.allowFodderLibrary or (not mainTargetSetId) or sid == mainTargetSetId) and curFree >= resGap) then
                local poolZ, zErr = ops.ensureZeroCopies(sid, needTotal, true, mainTargetSetId, workExcl, reserved, selfPetId)
                if #poolZ >= needTotal then
                    local idx, acts = 1, {}
                    for ss = curSt + 1, 5 do
                        local needZ = (starRules[ss] and starRules[ss].shard) or 0
                        local vals = {baseId}
                        for _ = 1, needZ do
                            table.insert(vals, poolZ[idx].petId)
                            idx = idx + 1
                        end
                        table.insert(acts, {id = 946, vals = vals})
                    end
                    local _, err = sendMerge946(acts, sid)
                    if err then return false, err end
                    ops.yieldIfDue(false)
                    return true, nil
                elseif resGap > 0 and zErr then
                    return false, zErr
                end
            end

            for ss = curSt + 1, 5 do
                if not isRunningFn() then return false, "Dừng" end
                local rs = starRules[ss]
                local crysNeed = rs and rs.numItem or 0
                local crysHave = inv:GetNumberItemConsumable(2)
                if crysHave < crysNeed then
                    return false, string.format("Thiếu %s Đá Thức Tỉnh (cần %s)", fmtNum(crysNeed - crysHave), fmtNum(crysNeed))
                end
                local needZ = rs and rs.shard or 0
                local poolZ, zErr = ops.ensureZeroCopies(sid, needZ, true, mainTargetSetId, workExcl, reserved, selfPetId)
                if #poolZ < needZ then return false, zErr or failLabel end
                local vals = {baseId}
                for k = 1, needZ do table.insert(vals, poolZ[k].petId) end
                local _, err = sendMerge946({ {id = 946, vals = vals} }, sid)
                if err then return false, err end
                ops.yieldIfDue(false)
            end
            return true, nil
        end
        ops.upgradeToFiveBatched = upgradeToFiveBatched

        -- Batch-collect/build needCount safe 5* fodder IDs (Tier1 D..A + Tier2 S excess + Tier3 redundant 5* SS): reuses existing 5*, merges bag-ready first, then batches Lib crafts + 946 chains.
        ops.buildBatchFiveFodder = function(needCount, mainTargetSetId, excl, reserved, selfPetId)
            local f5Ids = {}
            if needCount <= 0 then return f5Ids, nil end
            local workExcl = copyExcl(excl)
            local fodderState = buildFodderState(mainTargetSetId)
            local keep5 = getKeepQuota(mainTargetSetId)
            local curSafe5 = (keep5 > 0) and countSafeFodderPets(5, workExcl, selfPetId, mainTargetSetId) or 0
            local initSids = ops.getOrderedFodderSetIds(mainTargetSetId, false)
            for i = #initSids, 1, -1 do
                local sid = initSids[i]
                if #f5Ids >= needCount or (keep5 > 0 and curSafe5 <= keep5) then break end
                local ex = ops.findSafeFodderSamePets(sid, function(p) return (p.star or 0) == 5 end, workExcl, selfPetId, mainTargetSetId, fodderState)
                for _, p in ipairs(ex) do
                    if #f5Ids >= needCount or (keep5 > 0 and curSafe5 <= keep5) then break end
                    workExcl[p.petId] = true
                    table.insert(f5Ids, p.petId)
                    curSafe5 = curSafe5 - 1
                end
            end

            local function simCrysTo5(bSt)
                local sum = 0
                for ss = bSt + 1, 5 do sum = sum + (starRules[ss] and starRules[ss].numItem or 0) end
                return sum
            end

            while #f5Ids < needCount and isRunningFn() do
                reportProgress(string.format("Phôi 5★: %d/%d", #f5Ids, needCount))
                local rem = needCount - #f5Ids
                local orderedSids = ops.getOrderedFodderSetIds(mainTargetSetId, true)
                local stepState = buildFodderState(mainTargetSetId)
                local useLibFod = ops.allowLibrary and ops.allowFodderLibrary
                local pm = useLibFod and ops.getPieceMap() or {}

                local simBag, simPieces = {}, {}
                for _, sid in ipairs(orderedSids) do
                    simBag[sid] = {}
                    for s = 0, 4 do simBag[sid][s] = {} end
                    simPieces[sid] = useLibFod and (pm[sid] or 0) or 0
                end
                for _, p in ipairs(pdi.petOwnedList.listElement) do
                    if simBag[p.setId] and isPetEligibleAsFodder(p, mainTargetSetId, workExcl, selfPetId, stepState) then
                        local st = p.star or 0
                        if simBag[p.setId][st] ~= nil then
                            table.insert(simBag[p.setId][st], p)
                        end
                    end
                end
                for _, sb in pairs(simBag) do
                    for s = 0, 4 do
                        table.sort(sb[s], function(a, b) return (a.petId or 0) < (b.petId or 0) end)
                    end
                end

                local curOwned = (pdi.petOwnedList and pdi.petOwnedList.listElement and #pdi.petOwnedList.listElement) or 0
                local curFree = math.max(0, knownBagCap - curOwned)
                local crysRem = inv:GetNumberItemConsumable(2)
                local jobs, totalCraft, totalMergeActs = {}, 0, 0
                local sawCrysShort = false
                local minCrysNeed = 0

                for _ = 1, rem do
                    local bestJob = nil
                    for _, sid in ipairs(orderedSids) do
                        local tier = (sid == mainTargetSetId) and 999 or ops.getRankOfSet(sid)
                        local res = (reserved and reserved[sid]) or 0
                        local sReq = ops.getShardReq(sid)
                        local bagZ = #simBag[sid][0]
                        local libZ = useLibFod and math.floor(simPieces[sid] / sReq) or 0
                        local availTotal = math.max(0, bagZ + libZ - res)

                        local topB = nil
                        for b = 4, 1, -1 do
                            if #simBag[sid][b] > 0 then topB = b; break end
                        end
                        local candsB = {}
                        if topB then table.insert(candsB, topB) end
                        if availTotal >= needZeroFromTo5[0] then table.insert(candsB, 0) end

                        for _, b in ipairs(candsB) do
                            local needZ = needZeroFromTo5[b]
                            local needC = simCrysTo5(b)
                            if availTotal >= needZ then
                                if crysRem < needC then
                                    sawCrysShort = true
                                    if minCrysNeed == 0 or needC < minCrysNeed then minCrysNeed = needC end
                                elseif (totalMergeActs + (5 - b)) <= 45 then
                                    local bagZAvail = math.max(0, bagZ - res)
                                    local craftNeed = math.max(0, needZ - bagZAvail)
                                    local bagFit = (craftNeed == 0) and 0 or 1
                                    if craftNeed == 0 or ((curFree - totalCraft) >= craftNeed and (totalCraft + craftNeed) <= 70) then
                                        local better = false
                                        if not bestJob then
                                            better = true
                                        elseif (b > 0) ~= (bestJob.b > 0) then
                                            better = b > 0
                                        elseif bagFit ~= bestJob.bagFit then
                                            better = bagFit < bestJob.bagFit
                                        elseif tier ~= bestJob.tier then
                                            better = tier < bestJob.tier
                                        elseif b ~= bestJob.b then
                                            better = b > bestJob.b
                                        elseif bagZ ~= bestJob.bagZ then
                                            better = bagZ > bestJob.bagZ
                                        end
                                        if better then
                                            bestJob = {
                                                sid = sid, b = b, tier = tier, bagFit = bagFit, bagZ = bagZ,
                                                needZ = needZ, craftNeed = craftNeed, needC = needC, sReq = sReq,
                                                takeBag = math.min(needZ, bagZAvail)
                                            }
                                        end
                                    end
                                end
                            end
                        end
                    end
                    if not bestJob then break end
                    if bestJob.b > 0 then
                        local bObj = table.remove(simBag[bestJob.sid][bestJob.b], 1)
                        bestJob.basePetId = bObj.petId
                    end
                    for _ = 1, bestJob.takeBag do
                        table.remove(simBag[bestJob.sid][0], 1)
                    end
                    if bestJob.craftNeed > 0 then
                        simPieces[bestJob.sid] = math.max(0, simPieces[bestJob.sid] - bestJob.craftNeed * bestJob.sReq)
                    end
                    crysRem = crysRem - bestJob.needC
                    totalCraft = totalCraft + bestJob.craftNeed
                    totalMergeActs = totalMergeActs + (5 - bestJob.b)
                    table.insert(jobs, bestJob)
                end

                if #jobs == 0 then
                    if sawCrysShort then
                        local ch = inv:GetNumberItemConsumable(2)
                        return nil, string.format("Thiếu %s Đá Thức Tỉnh (cần %s)", fmtNum(math.max(0, minCrysNeed - ch)), fmtNum(minCrysNeed))
                    end
                    -- Bag free space may be too tight to batch craft all copies at once; fall back for 1 item cleanly
                    local oneId, oneErr = ops.ensureFodder(mainTargetSetId, 5, workExcl, reserved, 2, selfPetId)
                    if not oneId then return nil, oneErr or "Thiếu phôi thường B/A làm phôi 5★" end
                    workExcl[oneId] = true
                    table.insert(f5Ids, oneId)
                else
                    local runMergeWave = true
                    local craftSpecs = {}
                    for _, j in ipairs(jobs) do
                        for _ = 1, j.craftNeed do
                            table.insert(craftSpecs, {id = 942, vals = {j.sid}})
                        end
                    end
                    if #craftSpecs > 0 then
                        reportProgress(string.format("Đổi mảnh: %d bản thể", #craftSpecs))
                        local _, cErr, cGot = ops.sendActsSync(942, craftSpecs, nil, true)
                        if cErr and cGot == 0 then
                            runMergeWave = false
                            ops.syncNow(true)
                            local oneId, oneErr = ops.ensureFodder(mainTargetSetId, 5, workExcl, reserved, 2, selfPetId)
                            if not oneId then return nil, oneErr or cErr end
                            workExcl[oneId] = true
                            table.insert(f5Ids, oneId)
                        end
                    end

                    if runMergeWave then
                        local execExcl = copyExcl(workExcl)
                        for _, j in ipairs(jobs) do
                            if j.basePetId then execExcl[j.basePetId] = true end
                        end
                        local mergeActs, mergeActSids, createdBases = {}, {}, {}
                        local zPools, zIdx = {}, {}
                        for _, j in ipairs(jobs) do
                            if not zPools[j.sid] then
                                zPools[j.sid] = ops.findSafeFodderSamePets(j.sid, function(p) return (p.star or 0) == 0 end, execExcl, selfPetId, mainTargetSetId, stepState)
                                zIdx[j.sid] = 1
                            end
                            local zp = zPools[j.sid]
                            local zi = zIdx[j.sid]
                            if (#zp - zi + 1) >= j.needZ then
                                local bId = j.basePetId
                                if not bId then
                                    bId = zp[zi].petId
                                    execExcl[bId] = true
                                    zi = zi + 1
                                end
                                local jobActs = {}
                                local okJob = true
                                for ss = j.b + 1, 5 do
                                    local sh = (starRules[ss] and starRules[ss].shard) or 0
                                    if (#zp - zi + 1) < sh then okJob = false; break end
                                    local vals = {bId}
                                    for _ = 1, sh do
                                        table.insert(vals, zp[zi].petId)
                                        execExcl[zp[zi].petId] = true
                                        zi = zi + 1
                                    end
                                    table.insert(jobActs, vals)
                                end
                                zIdx[j.sid] = zi
                                if okJob and #jobActs > 0 then
                                    for _, vals in ipairs(jobActs) do
                                        table.insert(mergeActs, {id = 946, vals = vals})
                                        table.insert(mergeActSids, j.sid)
                                    end
                                    table.insert(createdBases, bId)
                                end
                            end
                        end
                        if #mergeActs == 0 then
                            local oneId, oneErr = ops.ensureFodder(mainTargetSetId, 5, workExcl, reserved, 2, selfPetId)
                            if not oneId then return nil, oneErr or "Thiếu phôi thường B/A làm phôi 5★" end
                            workExcl[oneId] = true
                            table.insert(f5Ids, oneId)
                        else
                            reportProgress(string.format("Ghép 5★: %d thao tác", #mergeActs))
                            local _, mErr, mOk = sendMerge946(mergeActs, mergeActSids)
                            ops.yieldIfDue(false)
                            local addedAny = false
                            for _, bId in ipairs(createdBases) do
                                if #f5Ids < needCount then
                                    local p = ops.getPetById(bId)
                                    if p and (p.star or 0) == 5 and not workExcl[bId] then
                                        workExcl[bId] = true
                                        table.insert(f5Ids, bId)
                                        addedAny = true
                                    end
                                end
                            end
                            if not addedAny and mErr and mOk == 0 then
                                return nil, mErr
                            end
                        end
                    end
                end
            end

            if #f5Ids < needCount then return nil, "Dừng" end
            return f5Ids, nil
        end

        ops.ensureFodder = function(mainTargetSetId, reqStar, excl, reserved, depth, selfPetId)
            if not isRunningFn() or (depth or 0) > 8 then return nil, "Dừng" end
            reportProgress(string.format("Ghép phôi %d★", reqStar))
            local orderedSids = ops.getOrderedFodderSetIds(mainTargetSetId, false)
            local craftSids = ops.getOrderedFodderSetIds(mainTargetSetId, true)
            local fodderState = buildFodderState(mainTargetSetId)
            local useLibFod = ops.allowLibrary and ops.allowFodderLibrary
            local pm = useLibFod and ops.getPieceMap() or {}

            local function curAvail0(sid)
                local z = #ops.findSafeFodderSamePets(sid, function(p) return (p.star or 0) == 0 end, excl, selfPetId, mainTargetSetId, fodderState)
                local c = useLibFod and math.floor((pm[sid] or 0) / ops.getShardReq(sid)) or 0
                return math.max(0, z + c - (reserved[sid] or 0)), z, c
            end

            local keep5, keep6, keep9 = getKeepQuota(mainTargetSetId)
            local keepForReq = (reqStar == 5 and keep5) or (reqStar == 6 and keep6) or (reqStar == 9 and keep9) or 0
            local safeReqCnt = (keepForReq > 0) and countSafeFodderPets(reqStar, excl, selfPetId, mainTargetSetId) or 0
            if keepForReq == 0 or safeReqCnt > keepForReq then
                if reqStar == 5 then
                    for i = #orderedSids, 1, -1 do
                        local sid = orderedSids[i]
                        local ex = ops.findSafeFodderSamePets(sid, function(p) return (p.star or 0) == 5 end, excl, selfPetId, mainTargetSetId, fodderState)
                        if #ex > 0 then return ex[1].petId end
                    end
                else
                    for _, sid in ipairs(orderedSids) do
                        local ex = ops.findSafeFodderSamePets(sid, function(p) return (p.star or 0) == reqStar end, excl, selfPetId, mainTargetSetId, fodderState)
                        if #ex > 0 then return ex[1].petId end
                    end
                end
            end

            if reqStar == 5 then
                local bestSid, bestBSt = nil, -1
                local bestTier, bestBagFit, bestZ = 999, 99, -1
                for _, sid in ipairs(craftSids) do
                    local tier = (sid == mainTargetSetId) and 999 or ops.getRankOfSet(sid)
                    local availTotal, ownedZ = curAvail0(sid)
                    local topB = nil
                    for b = 4, 1, -1 do
                        if #ops.findSafeFodderSamePets(sid, function(p) return (p.star or 0) == b end, excl, selfPetId, mainTargetSetId, fodderState) > 0 then topB = b; break end
                    end
                    local candidatesB = {}
                    if topB then table.insert(candidatesB, topB) end
                    if availTotal >= needZeroFromTo5[0] then table.insert(candidatesB, 0) end
                    for _, b in ipairs(candidatesB) do
                        local needZ = needZeroFromTo5[b]
                        if availTotal >= needZ then
                            local bagFit = (ownedZ - (reserved[sid] or 0) >= needZ) and 0 or 1
                            local better = false
                            if not bestSid then
                                better = true
                            elseif (b > 0) ~= (bestBSt > 0) then
                                better = b > 0
                            elseif bagFit ~= bestBagFit then
                                better = bagFit < bestBagFit
                            elseif tier ~= bestTier then
                                better = tier < bestTier
                            elseif b ~= bestBSt then
                                better = b > bestBSt
                            elseif ownedZ ~= bestZ then
                                better = ownedZ > bestZ
                            end
                            if better then bestSid, bestBSt, bestTier, bestBagFit, bestZ = sid, b, tier, bagFit, ownedZ end
                        end
                    end
                end
                if not bestSid then return nil, "Thiếu phôi (D..A/S dư) làm phôi 5★" end

                local baseObj = nil
                if bestBSt > 0 then
                    baseObj = ops.findSafeFodderSamePets(bestSid, function(p) return (p.star or 0) == bestBSt end, excl, selfPetId, mainTargetSetId, fodderState)[1]
                else
                    local curFree5 = math.max(0, ops.getKnownBagCap() - ((pdi.petOwnedList and pdi.petOwnedList.listElement and #pdi.petOwnedList.listElement) or 0))
                    local wantInit5 = (ops.allowLibrary and ops.allowFodderLibrary and curFree5 >= needZeroFromTo5[0]) and needZeroFromTo5[0] or 1
                    local zPool, zErr = ops.ensureZeroCopies(bestSid, wantInit5, true, mainTargetSetId, excl, reserved, selfPetId)
                    if #zPool < 1 then return nil, zErr or "Thiếu bản thể làm phôi 5★" end
                    baseObj = zPool[1]
                end
                local baseId = baseObj.petId
                local stepExcl = copyExcl(excl, baseId)
                local okUp, errUp = upgradeToFiveBatched(bestSid, baseObj, stepExcl, mainTargetSetId, excl, reserved, selfPetId, "Thiếu bản thể làm phôi 5★")
                if not okUp then return nil, errUp end
                return baseId

            elseif reqStar == 6 then
                local r6 = starRules[6]
                local crysR6 = r6 and r6.numItem or 35000
                local sameReq = r6 and r6.samePet or 2
                if inv:GetNumberItemConsumable(2) < crysR6 then
                    return nil, string.format("Thiếu %s Đá Thức Tỉnh (cần %s)", fmtNum(crysR6 - inv:GetNumberItemConsumable(2)), fmtNum(crysR6))
                end
                local bestSid, bestHas5 = nil, 99
                local bestTier, bestBSt = 999, -1
                local safe5For6Base = (keep5 > 0) and countSafeFodderPets(5, excl, selfPetId, mainTargetSetId) or 0
                local allowUse5AsBase = (keep5 == 0) or (safe5For6Base > keep5)
                for _, sid in ipairs(craftSids) do
                    local tier = (sid == mainTargetSetId) and 999 or ops.getRankOfSet(sid)
                    local availTotal = curAvail0(sid)
                    local f5List = allowUse5AsBase and ops.findSafeFodderSamePets(sid, function(p) return (p.star or 0) == 5 end, excl, selfPetId, mainTargetSetId, fodderState) or {}
                    if #f5List > 0 and availTotal >= sameReq then
                        local better = (not bestSid) or (0 < bestHas5) or (0 == bestHas5 and tier < bestTier)
                        if better then bestSid, bestBSt, bestTier, bestHas5 = sid, 5, tier, 0 end
                    else
                        local topB = nil
                        for b = 4, 1, -1 do
                            if #ops.findSafeFodderSamePets(sid, function(p) return (p.star or 0) == b end, excl, selfPetId, mainTargetSetId, fodderState) > 0 then topB = b; break end
                        end
                        if topB and availTotal >= needZeroFromTo5[topB] + sameReq then
                            local better = (not bestSid) or (1 < bestHas5) or (1 == bestHas5 and (tier < bestTier or (tier == bestTier and topB > bestBSt)))
                            if better then bestSid, bestBSt, bestTier, bestHas5 = sid, topB, tier, 1 end
                        elseif availTotal >= needZeroFromTo5[0] + sameReq then
                            local better = (not bestSid) or (2 < bestHas5) or (2 == bestHas5 and tier < bestTier)
                            if better then bestSid, bestBSt, bestTier, bestHas5 = sid, 0, tier, 2 end
                        end
                    end
                end
                if not bestSid then return nil, "Thiếu phôi (D..A/S dư) làm phôi 6★" end

                reserved[bestSid] = (reserved[bestSid] or 0) + sameReq
                local function releaseRes6() reserved[bestSid] = math.max(0, (reserved[bestSid] or 0) - sameReq) end

                local pickedBaseId = nil
                if bestBSt == 5 then
                    pickedBaseId = ops.findSafeFodderSamePets(bestSid, function(p) return (p.star or 0) == 5 end, excl, selfPetId, mainTargetSetId, fodderState)[1].petId
                else
                    local baseObj = nil
                    if bestBSt > 0 then
                        baseObj = ops.findSafeFodderSamePets(bestSid, function(p) return (p.star or 0) == bestBSt end, excl, selfPetId, mainTargetSetId, fodderState)[1]
                    else
                        local curFree6 = math.max(0, ops.getKnownBagCap() - ((pdi.petOwnedList and pdi.petOwnedList.listElement and #pdi.petOwnedList.listElement) or 0))
                        local wantInit6 = (ops.allowLibrary and ops.allowFodderLibrary and curFree6 >= needZeroFromTo5[0]) and needZeroFromTo5[0] or 1
                        local zPool, zErr = ops.ensureZeroCopies(bestSid, wantInit6, true, mainTargetSetId, excl, reserved, selfPetId)
                        if #zPool < 1 then releaseRes6(); return nil, zErr or "Thiếu bản thể làm phôi 6★" end
                        baseObj = zPool[1]
                    end
                    pickedBaseId = baseObj.petId
                    local stepExcl = copyExcl(excl, pickedBaseId)
                    local okUp, errUp = upgradeToFiveBatched(bestSid, baseObj, stepExcl, mainTargetSetId, excl, reserved, selfPetId, "Thiếu bản thể làm phôi 6★")
                    if not okUp then releaseRes6(); return nil, errUp end
                end

                local localExcl = copyExcl(excl, pickedBaseId)
                reportProgress(string.format("Phôi 6★: cần %d phôi 5★", r6.star5Pet or 5))
                local f5Ids, e5 = ops.buildBatchFiveFodder(r6.star5Pet or 5, mainTargetSetId, localExcl, reserved, selfPetId)
                if not f5Ids then releaseRes6(); return nil, e5 end
                for _, f5 in ipairs(f5Ids) do localExcl[f5] = true end
                releaseRes6()
                local sm, smErr = ops.ensureZeroCopies(bestSid, sameReq, true, mainTargetSetId, localExcl, reserved, selfPetId)
                if #sm < sameReq then return nil, smErr or "Thiếu bản thể làm phôi 6★" end
                local vals = {pickedBaseId}
                for k = 1, sameReq do
                    table.insert(vals, sm[k].petId)
                    localExcl[sm[k].petId] = true
                end
                for _, f5Id in ipairs(f5Ids) do table.insert(vals, f5Id) end
                if inv:GetNumberItemConsumable(2) < crysR6 then
                    return nil, string.format("Thiếu %s Đá Thức Tỉnh (cần %s)", fmtNum(crysR6 - inv:GetNumberItemConsumable(2)), fmtNum(crysR6))
                end
                local _, err = sendMerge946({ {id = 946, vals = vals} }, bestSid)
                if err then return nil, err end
                ops.yieldIfDue(false)
                return pickedBaseId

            elseif reqStar == 9 then
                local bestSid, bestBSt, bestTier = nil, -1, 999
                local safe5For9 = (keep5 > 0) and countSafeFodderPets(5, excl, selfPetId, mainTargetSetId) or 0
                local safe6For9 = (keep6 > 0) and countSafeFodderPets(6, excl, selfPetId, mainTargetSetId) or 0
                local safe9For9 = (keep9 > 0) and countSafeFodderPets(9, excl, selfPetId, mainTargetSetId) or 0
                for _, sid in ipairs(craftSids) do
                    local tier = (sid == mainTargetSetId) and 999 or ops.getRankOfSet(sid)
                    local availTotal = curAvail0(sid)
                    local chosenB = nil
                    for b = 8, 5, -1 do
                        local bBlocked = (b == 5 and keep5 > 0 and safe5For9 <= keep5)
                            or (b == 6 and keep6 > 0 and safe6For9 <= keep6)
                            or (b >= 7 and safe9For9 < keep9)
                        if not bBlocked and #ops.findSafeFodderSamePets(sid, function(p) return (p.star or 0) == b end, excl, selfPetId, mainTargetSetId, fodderState) > 0 then
                            local needS0 = 0
                            for ss = b + 1, 9 do needS0 = needS0 + (starRules[ss] and starRules[ss].samePet or 0) end
                            if availTotal >= needS0 then chosenB = b; break end
                        end
                    end
                    if not chosenB then
                        for b = 4, 0, -1 do
                            if b == 0 or #ops.findSafeFodderSamePets(sid, function(p) return (p.star or 0) == b end, excl, selfPetId, mainTargetSetId, fodderState) > 0 then
                                local needS0 = needZeroFromTo5[b]
                                for ss = 6, 9 do needS0 = needS0 + (starRules[ss] and starRules[ss].samePet or 0) end
                                if availTotal >= needS0 then chosenB = b; break end
                            end
                        end
                    end
                    if chosenB then
                        local better = false
                        if not bestSid then
                            better = true
                        elseif (chosenB >= 5) ~= (bestBSt >= 5) then
                            better = chosenB >= 5
                        elseif chosenB ~= bestBSt then
                            better = chosenB > bestBSt
                        elseif tier ~= bestTier then
                            better = tier < bestTier
                        end
                        if better then bestSid, bestBSt, bestTier = sid, chosenB, tier end
                    end
                end
                if not bestSid then return nil, "Thiếu phôi (D..A/S dư) làm phôi 9★" end

                local totalRes9 = 0
                for ss = math.max(6, bestBSt + 1), 9 do totalRes9 = totalRes9 + (starRules[ss] and starRules[ss].samePet or 0) end
                reserved[bestSid] = (reserved[bestSid] or 0) + totalRes9
                local remRes9 = totalRes9
                local function releaseAll9()
                    if remRes9 > 0 then
                        reserved[bestSid] = math.max(0, (reserved[bestSid] or 0) - remRes9)
                        remRes9 = 0
                    end
                end

                local base9Obj = nil
                if bestBSt > 0 then
                    base9Obj = ops.findSafeFodderSamePets(bestSid, function(p) return (p.star or 0) == bestBSt end, excl, selfPetId, mainTargetSetId, fodderState)[1]
                else
                    local zPool, zErr = ops.ensureZeroCopies(bestSid, 1, true, mainTargetSetId, excl, reserved, selfPetId)
                    if #zPool < 1 then releaseAll9(); return nil, zErr or "Thiếu bản thể làm phôi 9★" end
                    base9Obj = zPool[1]
                end
                local base9Id = base9Obj.petId
                local localExcl = copyExcl(excl, base9Id)
                if (base9Obj.star or 0) < 5 then
                    local okUp, errUp = upgradeToFiveBatched(bestSid, base9Obj, localExcl, mainTargetSetId, excl, reserved, selfPetId, "Thiếu bản thể làm phôi 9★")
                    if not okUp then releaseAll9(); return nil, errUp end
                end

                while isRunningFn() do
                    local cur9 = ops.getPetById(base9Id)
                    if not cur9 then releaseAll9(); return nil, "Mất phôi 9★" end
                    if (cur9.star or 0) >= 9 then releaseAll9(); return base9Id end
                    local nextS = (cur9.star or 0) + 1
                    reportProgress(string.format("Phôi 9★: %d★ → %d★", cur9.star or 0, nextS))
                    local rl = starRules[nextS]
                    local needC = rl and rl.numItem or 0
                    if inv:GetNumberItemConsumable(2) < needC then
                        releaseAll9()
                        return nil, string.format("Thiếu %s Đá Thức Tỉnh (cần %s)", fmtNum(needC - inv:GetNumberItemConsumable(2)), fmtNum(needC))
                    end
                    local fodderIds = {}
                    for _ = 1, (rl.star5Pet or 0) do
                        local f5, e5 = ops.ensureFodder(mainTargetSetId, 5, localExcl, reserved, (depth or 0) + 1, selfPetId)
                        if not f5 then releaseAll9(); return nil, e5 end
                        localExcl[f5] = true; table.insert(fodderIds, f5)
                    end
                    for _ = 1, (rl.star6Pet or 0) do
                        local f6, e6 = ops.ensureFodder(mainTargetSetId, 6, localExcl, reserved, (depth or 0) + 1, selfPetId)
                        if not f6 then releaseAll9(); return nil, e6 end
                        localExcl[f6] = true; table.insert(fodderIds, f6)
                    end
                    local needSame = rl.samePet or 0
                    if needSame > 0 then
                        local drop = math.min(remRes9, needSame)
                        reserved[bestSid] = math.max(0, (reserved[bestSid] or 0) - drop)
                        remRes9 = remRes9 - drop
                    end
                    local sm, smErr = ops.ensureZeroCopies(bestSid, needSame, true, mainTargetSetId, localExcl, reserved, selfPetId)
                    if #sm < needSame then releaseAll9(); return nil, smErr or "Thiếu bản thể làm phôi 9★" end
                    local vals = {base9Id}
                    for k = 1, needSame do table.insert(vals, sm[k].petId); localExcl[sm[k].petId] = true end
                    for _, fId in ipairs(fodderIds) do table.insert(vals, fId) end
                    if inv:GetNumberItemConsumable(2) < needC then
                        releaseAll9()
                        return nil, string.format("Thiếu %s Đá Thức Tỉnh (cần %s)", fmtNum(needC - inv:GetNumberItemConsumable(2)), fmtNum(needC))
                    end
                    local _, err = sendMerge946({ {id = 946, vals = vals} }, bestSid)
                    if err then releaseAll9(); return nil, err end
                    ops.yieldIfDue(false)
                end
                releaseAll9()
                return nil, "Đã dừng"
            end
            return nil, "Không hỗ trợ sao phôi " .. tostring(reqStar)
        end

        ops.execStarStep = function(targetPetId)
            local target = ops.getPetById(targetPetId)
            if not target then return false, "Không tìm thấy thú cưng!" end
            local nextSt = (target.star or 0) + 1
            local rule = starRules[nextSt]
            if not rule then return false, "Hết mốc sao" end

            local canStep, reasonMsg = ops.canAffordStarStep(target, nextSt)
            if not canStep then return false, reasonMsg end

            local sameNeed = (nextSt <= 5) and (rule.shard or 0) or (rule.samePet or 0)
            local reserved = { [target.setId] = sameNeed }
            local excl = { [targetPetId] = true }
            local fodderIds = {}
            local stepErr = nil

            if (rule.star5Pet or 0) > 0 then
                local f5Ids, e5 = ops.buildBatchFiveFodder(rule.star5Pet, target.setId, excl, reserved, targetPetId)
                if not f5Ids then
                    stepErr = e5 or "Thiếu phôi 5★ thường B/A"
                else
                    for _, f5 in ipairs(f5Ids) do
                        excl[f5] = true
                        table.insert(fodderIds, f5)
                    end
                end
            end
            if not stepErr then
                for i = 1, (rule.star6Pet or 0) do
                    reportProgress(string.format("Phôi 6★: %d/%d", i - 1, rule.star6Pet))
                    local f6, e6 = ops.ensureFodder(target.setId, 6, excl, reserved, 1, targetPetId)
                    if not f6 then stepErr = e6 or "Thiếu phôi 6★ thường B/A"; break end
                    excl[f6] = true; table.insert(fodderIds, f6)
                end
            end
            if not stepErr and (rule.star9Pet or 0) > 0 then
                local f9, e9 = ops.ensureFodder(target.setId, 9, excl, reserved, 1, targetPetId)
                if not f9 then stepErr = e9 or "Thiếu phôi 9★ thường B/A" else excl[f9] = true; table.insert(fodderIds, f9) end
            end
            if stepErr or not isRunningFn() then return false, stepErr or "Dừng" end

            reserved[target.setId] = 0
            local sm, smErr = ops.ensureZeroCopies(target.setId, sameNeed, nextSt >= 6, target.setId, excl, reserved, targetPetId)
            if #sm < sameNeed then return false, smErr or "Thiếu bản thể cùng loài" end

            local vals = {targetPetId}
            for k = 1, sameNeed do
                table.insert(vals, sm[k].petId)
                excl[sm[k].petId] = true
            end
            for _, fId in ipairs(fodderIds) do table.insert(vals, fId) end

            reportProgress(string.format("Đang nâng %d★ → %d★", target.star or 0, nextSt))
            local _, eUp = sendMerge946({ {id = 946, vals = vals} }, target.setId)
            if eUp then return false, eUp end
            ops.yieldIfDue(false)
            return true, nil
        end

        ops.countSafeFodderPets = countSafeFodderPets

        ops.computeTargetFodderQuota = function(targetSetId)
            if not targetSetId or targetSetId <= 0 then return nil end
            local best = nil
            for _, p in ipairs(pdi.petOwnedList.listElement) do
                if p.setId == targetSetId and (p.star or 0) < maxStar then
                    local eqB = (pdi:GetPetEquipped(p.petId) > 0 or (p.heroId or -1) > 0) and 1 or 0
                    local eqBest = best and ((pdi:GetPetEquipped(best.petId) > 0 or (best.heroId or -1) > 0) and 1 or 0) or -1
                    if not best or eqB > eqBest
                        or (eqB == eqBest and (p.star or 0) > (best.star or 0))
                        or (eqB == eqBest and (p.star or 0) == (best.star or 0) and (p.level or 1) > (best.level or 1)) then
                        best = p
                    end
                end
            end
            if _G.VinhPetControls then
                local selected=_G.VinhPetControls.selectedPet()
                if selected and selected.setId==targetSetId then best=selected end
            end
            local curSt = best and (best.star or 0) or 0
            local nextSt = curSt + 1
            local rule = (nextSt <= maxStar) and starRules[nextSt] or nil
            -- Only reserve fodder required for targetSid's IMMEDIATE next star step (nextSt = curSt + 1):
            -- e.g. 0*..4* -> 5* only needs same-species copies (0 external phôi), so keep 0 locked and let SS/S use all B/A freely!
            local need5 = (rule and rule.star5Pet) or 0
            local need6 = (rule and rule.star6Pet) or 0
            local need9 = (rule and rule.star9Pet) or 0
            local reserveCrys = (rule and rule.numItem) or 0
            return {
                setId = targetSetId,
                curStar = curSt,
                star5 = need5,
                star6 = need6,
                star9 = need9,
                reserveCrys = reserveCrys,
            }
        end

        ops.prebuildTargetFodder = function(targetSetId, quota)
            if not targetSetId or targetSetId <= 0 or not isRunningFn() then return 0 end
            if not quota then quota = ops.computeTargetFodderQuota(targetSetId) end
            if not quota then return 0 end
            local need5 = quota.star5 or 0
            local need6 = quota.star6 or 0
            local need9 = quota.star9 or 0
            if need5 + need6 + need9 <= 0 then return 0 end

            local function curFreeSlots()
                local cur = (pdi.petOwnedList and pdi.petOwnedList.listElement and #pdi.petOwnedList.listElement) or 0
                return math.max(0, knownBagCap - cur)
            end

            _G.HTPS_PET_SUMMON_STATUS = "đúc phôi"
            _G.HTPS_UpdatePetSummonBtnUI()

            local prevLib, prevFodLib, prevQuota = ops.allowLibrary, ops.allowFodderLibrary, ops.reservedFodderQuota
            local startMerges = ops.sessionMerges or 0
            local minKeepCrys = quota.reserveCrys or 0

            local okRun, errRun = pcall(function()
                -- Enable D..A/S-excess Library so clogged 1*..4* bag pets finish cleanly.
                ops.allowLibrary = true
                ops.allowFodderLibrary = true
                ops.reservedFodderQuota = nil

                local orderedSids = ops.getOrderedFodderSetIds(targetSetId, false)
                local fodderState = buildFodderState(targetSetId)
                local prebuildExcl = {}
                local prebuildRes = {}
                local got5, got6, got9 = {}, {}, {}

                local function collectExisting(reqSt, needCap, bucket)
                    if needCap <= #bucket then return end
                    local iStart = (reqSt == 5) and #orderedSids or 1
                    local iEnd = (reqSt == 5) and 1 or #orderedSids
                    local iStep = (reqSt == 5) and -1 or 1
                    for i = iStart, iEnd, iStep do
                        if #bucket >= needCap then break end
                        local sid = orderedSids[i]
                        local lst = ops.findSafeFodderSamePets(sid, function(p) return (p.star or 0) == reqSt end, prebuildExcl, nil, targetSetId, fodderState)
                        for _, p in ipairs(lst) do
                            if #bucket >= needCap then break end
                            prebuildExcl[p.petId] = true
                            table.insert(bucket, p.petId)
                        end
                    end
                end

                collectExisting(5, need5, got5)
                collectExisting(6, need6, got6)
                collectExisting(9, need9, got9)

                local function ensureCraftSpace(minFreeNeed)
                    if curFreeSlots() >= minFreeNeed then return end
                    for _ = 1, 3 do
                        if not isRunningFn() or curFreeSlots() >= minFreeNeed then break end
                        local okF = ops.tryFreeCommonSlots(targetSetId, prebuildExcl, prebuildRes, nil, minFreeNeed - curFreeSlots())
                        if not okF then break end
                    end
                end

                -- 1) Secure 5* phôi (immediate 5*->6* blocker)
                local rem5Need = need5 - #got5
                if rem5Need > 0 and isRunningFn() then
                    ensureCraftSpace(10)
                    local crysSpare = math.max(0, inv:GetNumberItemConsumable(2) - minKeepCrys)
                    local affordable5 = math.min(rem5Need, math.floor(crysSpare / 62000))
                    if affordable5 > 0 then
                        local builtIds = ops.buildBatchFiveFodder(affordable5, targetSetId, prebuildExcl, prebuildRes, nil)
                        if builtIds then
                            for _, id in ipairs(builtIds) do
                                prebuildExcl[id] = true
                                table.insert(got5, id)
                            end
                        end
                    end
                    while #got5 < need5 and isRunningFn() do
                        if inv:GetNumberItemConsumable(2) < minKeepCrys + 32000 then break end
                        ensureCraftSpace(8)
                        local f5Id = ops.ensureFodder(targetSetId, 5, prebuildExcl, prebuildRes, 1, nil)
                        if not f5Id then break end
                        prebuildExcl[f5Id] = true
                        table.insert(got5, f5Id)
                    end
                end

                -- 2) Secure 6* phôi (compresses 5* & clogged 1*..4* pets -> frees substantial bag slots!)
                -- Pause cleanly to resume x10 summoning once immediate 5* + >=2x6* phôi are ready and freeSlots >= 30
                -- (unless all 6* are already done so we can finish 9* below).
                local built6ThisPass = 0
                while #got6 < need6 and isRunningFn() do
                    if #got5 >= need5 and #got6 >= math.min(need6, 2) and (built6ThisPass >= 2 or curFreeSlots() >= 35) and curFreeSlots() >= 30 then
                        break
                    end
                    if inv:GetNumberItemConsumable(2) < minKeepCrys + 35000 then break end
                    ensureCraftSpace(10)
                    local f6Id = ops.ensureFodder(targetSetId, 6, prebuildExcl, prebuildRes, 1, nil)
                    if not f6Id then break end
                    prebuildExcl[f6Id] = true
                    table.insert(got6, f6Id)
                    built6ThisPass = built6ThisPass + 1
                end

                -- 3) Secure 9* phôi (finishes 8* or builds 9* while keeping reserved 5* & 6* untouched)
                while #got9 < need9 and isRunningFn() do
                    if #got5 >= need5 and #got6 >= math.min(need6, 2) and curFreeSlots() >= 35 and #got6 < need6 then
                        break
                    end
                    if inv:GetNumberItemConsumable(2) < minKeepCrys + 60500 then break end
                    ensureCraftSpace(14)
                    local f9Id = ops.ensureFodder(targetSetId, 9, prebuildExcl, prebuildRes, 1, nil)
                    if not f9Id then break end
                    prebuildExcl[f9Id] = true
                    table.insert(got9, f9Id)
                end
            end)

            ops.allowLibrary = prevLib
            ops.allowFodderLibrary = prevFodLib
            ops.reservedFodderQuota = prevQuota
            if not okRun then error(errRun) end
            return (ops.sessionMerges or 0) - startMerges
        end

        ops.sendMerge946 = sendMerge946
        ops.buildFodderState = buildFodderState
        ops.isPetEligibleAsFodder = isPetEligibleAsFodder
        ops.needZeroFromTo5 = needZeroFromTo5
        return ops
    end

    -- Bag-full auto-merge for Pet Fast Summon:
    --   Priority 0 (Focus Mode, target > 0): Focus-max targetSid (1 copy -> 10* before starting #2), prebuild & lock its exact next-step phôi,
    --              overflow to OTHER SS one-by-one toward 10* when bag still crowded (< 25 free).
    --   Default All-SS (target == 0): Advance SS one-by-one (1 shared copy per species toward 10*, skipping stuck pets cleanly).
    --   3-Tier Fodder Pool: D..A (100%), S excess (keeping 1 highest original per species), redundant 5* SS clones ONLY (never 6*/9* SS or single S).
    --   Deep Compression (Priority 3): 0*..4* -> 5*, recycle >=22 completed-10* SS 0*..4* -> 5*, surplus 5* -> 6*, surplus 6* -> 9*.
    _G.HTPS_PetAutoMergeWarehouse = function(ops, isRunningFn)
        local pdi = ops.pdi
        local inv = ops.inv
        local starRules = ops.starRules
        local mergesDone = 0
        local hitCrysShort = false
        local needCommonPhoi = false

        local function isRaisedPet(p)
            return (p.star or 0) > 0 or (p.level or 1) > 1 or (p.tier or 0) > 0
                or (p.changeBasic or 0) > 0 or pdi:GetPetEquipped(p.petId) > 0 or (p.heroId or -1) > 0
        end

        local function countMaxedCopies(sid)
            local cnt = 0
            if not sid or sid <= 0 then return 0 end
            for _, p in ipairs(pdi.petOwnedList.listElement) do
                if p.setId == sid and (p.star or 0) >= ops.maxStar then
                    cnt = cnt + 1
                end
            end
            return cnt
        end

        local function hasUnmaxedCopyOwned(sid)
            if not sid or sid <= 0 then return false end
            for _, p in ipairs(pdi.petOwnedList.listElement) do
                if p.setId == sid and (p.star or 0) < ops.maxStar then
                    return true
                end
            end
            return false
        end

        local function hasHighUnmaxedOwned(sid)
            if _G.VinhPetControls then
                local selected=_G.VinhPetControls.selectedPet()
                if selected and selected.setId==sid then
                    return (selected.star or 0)>=5 and (selected.star or 0)<ops.maxStar
                end
            end
            for _, p in ipairs(pdi.petOwnedList.listElement) do
                local st = p.star or 0
                if p.setId == sid and st >= 5 and st < ops.maxStar then return true end
            end
            return false
        end

        local function getFreeNow()
            local cur = (pdi.petOwnedList and pdi.petOwnedList.listElement and #pdi.petOwnedList.listElement) or 0
            local cap = math.max(ops.getKnownBagCap(), cur)
            return math.max(0, cap - cur), cur, cap
        end

        local function recordStepFail(rsn)
            local rsStr = tostring(rsn or "")
            if rsStr:find("Đá Thức Tỉnh", 1, true) then
                hitCrysShort = true
            elseif rsStr:find("phôi", 1, true) then
                needCommonPhoi = true
            end
        end

        local function mergeRankGroup(targetRank, stopPassAFree, stopPassBFree, useLibSame, allowTempSOnFull, onlySetId)
            if stopPassAFree and stopPassBFree and getFreeNow() >= math.max(stopPassAFree, stopPassBFree) then return 0 end
            local groupMerges = 0
            if onlySetId and onlySetId > 0 then
                _G.HTPS_PET_SUMMON_STATUS = "ghép ƯT"
            else
                _G.HTPS_PET_SUMMON_STATUS = (targetRank == 6) and "ghép SS" or "ghép S"
            end
            _G.HTPS_UpdatePetSummonBtnUI()

            local function getLibCanCount(sid)
                if not useLibSame or not ops.allowLibrary then return 0 end
                local pm = ops.getPieceMap()
                return math.floor((pm[sid] or 0) / ops.getShardReq(sid))
            end

            local function getLibStockCount(sid)
                local pm = ops.getPieceMap()
                return math.floor((pm[sid] or 0) / ops.getShardReq(sid))
            end

            local function calcSamePetNeedToMax(fromStar)
                local need = 0
                for s = (fromStar or 0) + 1, ops.maxStar do
                    local rule = starRules[s]
                    if rule then
                        need = need + ((s <= 5) and (rule.shard or 0) or (rule.samePet or 0))
                    end
                end
                return need
            end

            local function findBestUnmaxedBase(sid, maxAllowedStar)
                local limitStar = maxAllowedStar or ops.maxStar
                if targetRank == 6 and limitStar <= 5 and (hasHighUnmaxedOwned(sid) or (not onlySetId and countMaxedCopies(sid) > 0)) then
                    return nil, 0, 0
                end
                local lst = {}
                local bestHigh = nil
                for _, p in ipairs(pdi.petOwnedList.listElement) do
                    if p.setId == sid then
                        local st = p.star or 0
                        if st < limitStar then
                            table.insert(lst, p)
                        elseif limitStar < ops.maxStar and st < ops.maxStar then
                            if not bestHigh or st > (bestHigh.star or 0)
                                or (st == (bestHigh.star or 0) and (p.level or 1) > (bestHigh.level or 1)) then
                                bestHigh = p
                            end
                        end
                    end
                end
                if onlySetId and _G.VinhPetControls and _G.VinhPetControls.selectedId()>0 then
                    local exact=nil
                    for _,p in ipairs(lst) do if _G.HTPS_IsPreferredPet(p) then exact=p;break end end
                    lst=exact and {exact} or {}
                    bestHigh=nil
                end
                if #lst == 0 then return nil, 0, 0 end
                table.sort(lst, function(a, b)
                    local eqA = (pdi:GetPetEquipped(a.petId) > 0 or (a.heroId or -1) > 0) and 1 or 0
                    local eqB = (pdi:GetPetEquipped(b.petId) > 0 or (b.heroId or -1) > 0) and 1 or 0
                    if eqA ~= eqB then return eqA > eqB end
                    if (a.star or 0) ~= (b.star or 0) then return (a.star or 0) > (b.star or 0) end
                    if (a.level or 1) ~= (b.level or 1) then return (a.level or 1) > (b.level or 1) end
                    if (a.tier or 0) ~= (b.tier or 0) then return (a.tier or 0) > (b.tier or 0) end
                    return (a.petId or 0) < (b.petId or 0)
                end)
                local rawReserve = 0
                if bestHigh then
                    if targetRank == 5 and not onlySetId then
                        -- Non-priority Rank S: at low free bag space don't lock 0* slots; otherwise reserve at most 1 next step
                        if getFreeNow() < 15 then
                            rawReserve = 0
                        else
                            local bNext = (bestHigh.star or 0) + 1
                            local bRule = starRules[bNext]
                            rawReserve = (bRule and ((bNext <= 5) and bRule.shard or bRule.samePet)) or 0
                        end
                    else
                        rawReserve = calcSamePetNeedToMax(bestHigh.star or 0)
                    end
                end
                local reserveZeros = useLibSame and rawReserve or math.max(0, rawReserve - getLibStockCount(sid))
                local base = lst[1]
                local zeros = ops.findSafeSamePets(sid, function(p) return (p.star or 0) == 0 end, nil, base.petId)
                local libCan = useLibSame and getLibCanCount(sid) or 0
                local nextSt = (base.star or 0) + 1
                local stepNeed = (starRules[nextSt] and ((nextSt <= 5) and starRules[nextSt].shard or starRules[nextSt].samePet)) or 1
                if not onlySetId and useLibSame and (base.star or 0) == 0 and not isRaisedPet(base) and #zeros == 0 then
                    return nil, 0, reserveZeros
                end
                if (#zeros + libCan) == 0 or (#zeros + libCan) < reserveZeros + stepNeed then
                    return nil, 0, reserveZeros
                end
                return base, #zeros + libCan - reserveZeros, reserveZeros
            end

            local function ensureFreeSlotsForCraft(needCraftNow, sid, baseId, reserveZeros)
                local freedTemp = false
                while isRunningFn() and getFreeNow() < needCraftNow do
                    local okFree, fCnt = ops.tryFreeCommonSlots(sid, baseId and { [baseId] = true } or {}, { [sid] = reserveZeros }, baseId, needCraftNow - getFreeNow())
                    if okFree then
                        freedTemp = true
                        mergesDone = mergesDone + math.max(1, fCnt or 1)
                    else
                        break
                    end
                end
                if isRunningFn() and getFreeNow() < needCraftNow and ops.getCompletedSSSet then
                    local compMap = ops.getCompletedSSSet(ops.protectedTargetSetId)
                    local compSids = {}
                    for cSid, okC in pairs(compMap) do
                        if okC and cSid ~= sid then table.insert(compSids, cSid) end
                    end
                    if #compSids > 0 then
                        table.sort(compSids)
                        local mc = ops.batchFoldFodder(compSids, getFreeNow() + math.max(needCraftNow - getFreeNow(), 12), 5, false, nil, baseId and { [baseId] = true } or nil, baseId, 6)
                        if (mc or 0) > 0 then
                            freedTemp = true
                            mergesDone = mergesDone + mc
                        end
                    end
                end
                return getFreeNow() >= needCraftNow, freedTemp
            end

            local function ensureTargetBaseInBag(sid)
                if not sid or sid <= 0 then return false end
                if useLibSame and ops.allowLibrary and not hasUnmaxedCopyOwned(sid) and getLibCanCount(sid) >= 2 then
                    local hasRoom = ensureFreeSlotsForCraft(1, sid, nil, 0)
                    if hasRoom or getFreeNow() >= 1 then
                        ops.craftSetCopies(sid, 1)
                    end
                end
                return hasUnmaxedCopyOwned(sid)
            end

            local function runGroupPass(maxAllowedStar, passStopFree)
                if passStopFree and getFreeNow() >= passStopFree then return end
                local bySet = {}
                if onlySetId and onlySetId > 0 then
                    if ops.getRankOfSet(onlySetId) == targetRank then
                        if ensureTargetBaseInBag(onlySetId) then
                            bySet[onlySetId] = true
                        end
                    end
                else
                    for _, p in ipairs(pdi.petOwnedList.listElement) do
                        if ops.getRankOfSet(p.setId) == targetRank and (p.star or 0) < maxAllowedStar then
                            bySet[p.setId] = true
                        end
                    end
                end
                local entries = {}
                for sid, _ in pairs(bySet) do
                    local base, zc = findBestUnmaxedBase(sid, maxAllowedStar)
                    if base then
                        table.insert(entries, {
                            sid = sid,
                            eq = (pdi:GetPetEquipped(base.petId) > 0 or (base.heroId or -1) > 0) and 1 or 0,
                            raised = isRaisedPet(base) and 1 or 0,
                            star = base.star or 0,
                            lv = base.level or 1,
                            zcnt = zc or 0,
                        })
                    end
                end
                table.sort(entries, function(a, b)
                    if a.eq ~= b.eq then return a.eq > b.eq end
                    if a.raised ~= b.raised then return a.raised > b.raised end
                    if a.star ~= b.star then return a.star > b.star end
                    if a.lv ~= b.lv then return a.lv > b.lv end
                    if a.zcnt ~= b.zcnt then return a.zcnt > b.zcnt end
                    return a.sid < b.sid
                end)

                if maxAllowedStar == 5 then
                    -- Hyper-speed wave batching for BOTH Bag-only and Library-enabled 0*..4* -> 5* upgrades (no B/A fodder)
                    while isRunningFn() and not (passStopFree and getFreeNow() >= passStopFree) do
                        local acts, actSids = {}, {}
                        local used = {}
                        local crysAvail = inv:GetNumberItemConsumable(2)
                        local estFree = getFreeNow()
                        for _, ent in ipairs(entries) do
                            if #acts >= 45 or (passStopFree and estFree >= passStopFree) then break end
                            local base, _, reserveZeros = findBestUnmaxedBase(ent.sid, 5)
                            if base and not used[base.petId] and (base.star or 0) < 5 then
                                local zeros = ops.findSafeSamePets(ent.sid, function(p) return (p.star or 0) == 0 end, used, base.petId)
                                local usable = #zeros - reserveZeros
                                local zi = 1
                                local curSt = base.star or 0
                                local plannedAny = false
                                for ss = curSt + 1, 5 do
                                    if #acts >= 45 or (passStopFree and estFree >= passStopFree) then break end
                                    local rs = starRules[ss]
                                    local sh = rs and rs.shard or 0
                                    local cs = rs and rs.numItem or 0
                                    if usable < sh then break end
                                    if crysAvail < cs then
                                        hitCrysShort = true
                                        break
                                    end
                                    local vals = {base.petId}
                                    for _ = 1, sh do
                                        used[zeros[zi].petId] = true
                                        table.insert(vals, zeros[zi].petId)
                                        zi = zi + 1
                                    end
                                    table.insert(acts, {id = 946, vals = vals})
                                    table.insert(actSids, ent.sid)
                                    usable = usable - sh
                                    crysAvail = crysAvail - cs
                                    estFree = estFree + sh
                                    plannedAny = true
                                end
                                if plannedAny then used[base.petId] = true end
                            end
                        end
                        if #acts > 0 then
                            local _, mErr, mOk = ops.sendMerge946(acts, actSids)
                            if mOk > 0 then
                                mergesDone = mergesDone + mOk
                                groupMerges = groupMerges + mOk
                                ops.yieldIfDue(false)
                            end
                            if mErr or mOk == 0 then
                                if mErr then recordStepFail(mErr) end
                                break
                            end
                        elseif useLibSame and ops.allowLibrary then
                            -- Phase B: Batch-craft missing 0* copies from Library for remaining <5* entries
                            local craftSpecs, craftTotal = {}, 0
                            local curFreeNow = getFreeNow()
                            local crysCraft = inv:GetNumberItemConsumable(2)
                            local function collectCraftPlan()
                                craftSpecs, craftTotal = {}, 0
                                curFreeNow = getFreeNow()
                                crysCraft = inv:GetNumberItemConsumable(2)
                                for _, ent in ipairs(entries) do
                                    if craftTotal >= 70 or craftTotal >= curFreeNow then break end
                                    local base, _, reserveZeros = findBestUnmaxedBase(ent.sid, 5)
                                    if base and (base.star or 0) < 5 then
                                        local zeros = ops.findSafeSamePets(ent.sid, function(p) return (p.star or 0) == 0 end, nil, base.petId)
                                        local libCan = getLibCanCount(ent.sid)
                                        local bagUsable = math.max(0, #zeros - reserveZeros)
                                        local availTotal = math.max(0, #zeros + libCan - reserveZeros)
                                        local curSt = base.star or 0
                                        local needTotal = 0
                                        for ss = curSt + 1, 5 do
                                            local rs = starRules[ss]
                                            local sh = rs and rs.shard or 0
                                            local cs = rs and rs.numItem or 0
                                            if availTotal >= needTotal + sh and crysCraft >= cs then
                                                local addCraft = math.max(0, (needTotal + sh) - bagUsable) - math.max(0, needTotal - bagUsable)
                                                if (craftTotal + addCraft) <= curFreeNow and (craftTotal + addCraft) <= 70 then
                                                    needTotal = needTotal + sh
                                                    crysCraft = crysCraft - cs
                                                    craftTotal = craftTotal + addCraft
                                                    for _ = 1, addCraft do
                                                        table.insert(craftSpecs, {id = 942, vals = {ent.sid}})
                                                    end
                                                else
                                                    break
                                                end
                                            else
                                                if availTotal >= needTotal + sh and crysCraft < cs then hitCrysShort = true end
                                                break
                                            end
                                        end
                                    end
                                end
                            end
                            collectCraftPlan()
                            if #craftSpecs == 0 and curFreeNow < 22 then
                                -- Try freeing space once so library-backed <5* entries can craft
                                local didFree = false
                                for _, ent in ipairs(entries) do
                                    local base, _, reserveZeros = findBestUnmaxedBase(ent.sid, 5)
                                    if base and (base.star or 0) < 5 then
                                        local step1 = starRules[(base.star or 0) + 1]
                                        local need1 = step1 and step1.shard or 1
                                        if ensureFreeSlotsForCraft(need1, ent.sid, base.petId, reserveZeros) then
                                            didFree = true
                                            break
                                        end
                                    end
                                end
                                if didFree then collectCraftPlan() end
                            end
                            if #craftSpecs == 0 then break end
                            local _, cErr, cGot = ops.sendActsSync(942, craftSpecs, nil, true)
                            if cErr and cGot == 0 then
                                recordStepFail(cErr)
                                break
                            end
                        else
                            break
                        end
                    end
                    return
                end

                for _, ent in ipairs(entries) do
                    if not isRunningFn() or (passStopFree and getFreeNow() >= passStopFree) then break end
                    while isRunningFn() and not (passStopFree and getFreeNow() >= passStopFree) do
                        local base, _, reserveZeros = findBestUnmaxedBase(ent.sid, maxAllowedStar)
                        if not base or (base.star or 0) >= maxAllowedStar then break end
                        local baseId = base.petId
                        local advancedBase = false
                        while isRunningFn() and not (passStopFree and getFreeNow() >= passStopFree) do
                            local cur = ops.getPetById(baseId)
                            if not cur or (cur.star or 0) >= maxAllowedStar then break end
                            local curSt = cur.star or 0
                            local nextSt = curSt + 1
                            local safeZeros = ops.findSafeSamePets(ent.sid, function(p) return (p.star or 0) == 0 end, nil, baseId)
                            local libCan = useLibSame and getLibCanCount(ent.sid) or 0

                            -- Fast path for 0*..4* -> 5* when full path to 5* is affordable
                            if curSt < 5 and maxAllowedStar <= 5 and ops.upgradeToFiveBatched then
                                local needTo5, crysTo5 = 0, 0
                                for ss = nextSt, 5 do
                                    local rs = starRules[ss]
                                    needTo5 = needTo5 + (rs and rs.shard or 0)
                                    crysTo5 = crysTo5 + (rs and rs.numItem or 0)
                                end
                                if (#safeZeros + libCan) >= (reserveZeros + needTo5) and inv:GetNumberItemConsumable(2) >= crysTo5 then
                                    local craftNeed5 = useLibSame and math.max(0, needTo5 - #safeZeros) or 0
                                    local canBatch5 = (craftNeed5 == 0)
                                    if craftNeed5 > 0 then
                                        if getFreeNow() >= craftNeed5 then
                                            canBatch5 = true
                                        else
                                            local hasSlots5 = ensureFreeSlotsForCraft(craftNeed5, ent.sid, baseId, reserveZeros)
                                            canBatch5 = hasSlots5 or (getFreeNow() >= craftNeed5)
                                        end
                                    end
                                    if canBatch5 then
                                        cur = ops.getPetById(baseId)
                                        if not cur or (cur.star or 0) >= 5 then break end
                                        local startSt = cur.star or 0
                                        local resTbl = (reserveZeros > 0) and { [ent.sid] = reserveZeros } or {}
                                        local okUp5, errUp5 = ops.upgradeToFiveBatched(ent.sid, cur, { [baseId] = true }, ent.sid, nil, resTbl, baseId, "Thiếu bản thể")
                                        if okUp5 then
                                            local stepsDone = math.max(1, 5 - startSt)
                                            mergesDone = mergesDone + stepsDone
                                            groupMerges = groupMerges + stepsDone
                                            advancedBase = true
                                            break
                                        else
                                            recordStepFail(errUp5)
                                            break
                                        end
                                    end
                                end
                            end

                            local stepNeed = (starRules[nextSt] and ((nextSt <= 5) and starRules[nextSt].shard or starRules[nextSt].samePet)) or 1
                            if reserveZeros > 0 and (#safeZeros + libCan) < reserveZeros + stepNeed then break end
                            local stepRule = starRules[nextSt]
                            local needsFodLib = useLibSame and ops.allowFodderLibrary and stepRule
                                and (((stepRule.star5Pet or 0) + (stepRule.star6Pet or 0) + (stepRule.star9Pet or 0)) > 0)
                            local needCraftNow = useLibSame and math.max(0, stepNeed - #safeZeros) or 0
                            local fodFloor = needsFodLib and ((stepRule and (stepRule.star9Pet or 0) > 0) and 18 or 16) or 0
                            local minSlotsNeeded = math.max(needCraftNow + (needsFodLib and 14 or 0), fodFloor)
                            if minSlotsNeeded > 0 then
                                local canNow, canRsn = ops.canAffordStarStep(cur, nextSt)
                                if not canNow then
                                    recordStepFail(canRsn)
                                    break
                                end
                                if getFreeNow() < minSlotsNeeded then
                                    local hasSlots, freedTemp = ensureFreeSlotsForCraft(minSlotsNeeded, ent.sid, baseId, reserveZeros)
                                    if freedTemp then
                                        cur = ops.getPetById(baseId)
                                        if not cur or (cur.star or 0) >= maxAllowedStar then break end
                                        canNow, canRsn = ops.canAffordStarStep(cur, nextSt)
                                        if not canNow then
                                            recordStepFail(canRsn)
                                            break
                                        end
                                    end
                                    local minFallback = needCraftNow + (needsFodLib and ((stepRule and (stepRule.star9Pet or 0) > 0) and 10 or 8) or 0)
                                    if not hasSlots and getFreeNow() < minFallback then
                                        break
                                    end
                                end
                            end
                            local okStep, rsn = ops.execStarStep(baseId)
                            if okStep then
                                mergesDone = mergesDone + 1
                                groupMerges = groupMerges + 1
                                advancedBase = true
                            else
                                recordStepFail(rsn)
                                break
                            end
                        end
                        local curEnd = ops.getPetById(baseId)
                        if not curEnd or (curEnd.star or 0) < maxAllowedStar or not advancedBase then
                            break
                        end
                        if onlySetId then
                            ensureTargetBaseInBag(onlySetId)
                        end
                    end
                end
            end

            -- Pass A: Cleanly condense 0*->5* (same-species copies only, ZERO B/A phôi).
            -- When focusing a single target pet that already has an unmaxed >=5* copy, skip Pass A so all copies go to maxing it first.
            if not (onlySetId and hasHighUnmaxedOwned(onlySetId)) then
                runGroupPass(5, stopPassAFree)
            end
            -- For S, if Pass A already freed >= 10 slots (enough for x10 summon), return immediately without burning B/A phôi
            if targetRank == 5 and stopPassBFree and getFreeNow() >= 10 then return groupMerges end
            -- Pass B: For focused target (onlySetId) advance straight to maxStar;
            --         for All-SS uncapped mode advance evenly star-by-star (6*->10*);
            --         for capped groups advance greedily until stopPassBFree.
            if isRunningFn() and not (stopPassBFree and getFreeNow() >= stopPassBFree) then
                if targetRank == 6 and not stopPassBFree and not onlySetId then
                    for tierMax = 6, ops.maxStar do
                        if not isRunningFn() then break end
                        runGroupPass(tierMax, stopPassBFree)
                    end
                else
                    runGroupPass(ops.maxStar, stopPassBFree)
                end
            end
            return groupMerges
        end

        local _, _, initCap = getFreeNow()
        local focusFreeCap = math.min(80, math.max(40, math.floor(initCap * 0.06)))
        local phoiFree = math.min(80, math.max(40, math.floor(initCap * 0.06)))

        local function getTargetFocusInfo()
            local sid = (_G.HTPS_GetPetTargetSetId and _G.HTPS_GetPetTargetSetId()) or tonumber(_G.HTPS_PET_TARGET_SET_ID) or 0
            local rk = (sid > 0) and ops.getRankOfSet(sid) or 0
            return sid, rk, (sid > 0) and (rk == 6 or rk == 5)
        end

        ops.reservedFodderQuota = nil
        ops.protectedTargetSetId = nil
        local _, _, initTargetValid = getTargetFocusInfo()
        do
            local initTid = (_G.HTPS_GetPetTargetSetId and _G.HTPS_GetPetTargetSetId()) or tonumber(_G.HTPS_PET_TARGET_SET_ID) or 0
            if initTargetValid and initTid > 0 then ops.protectedTargetSetId = initTid end
        end

        local function finishMerge(rsn)
            ops.reservedFodderQuota = nil
            ops.protectedTargetSetId = nil
            ops.allowLibrary = false
            ops.allowFodderLibrary = false
            return mergesDone, rsn
        end

        local function recycleCompletedSSToFive(targetFree)
            if not ops.getCompletedSSSet then return 0, false end
            local compMap = ops.getCompletedSSSet(ops.protectedTargetSetId)
            local compSids = {}
            for sid, ok in pairs(compMap) do
                if ok then table.insert(compSids, sid) end
            end
            if #compSids == 0 then return 0, false end
            table.sort(compSids)
            local mc, builtC = ops.batchFoldFodder(compSids, targetFree, 5, false, nil, nil, nil, 6)
            if (mc or 0) > 0 then mergesDone = mergesDone + mc end
            return mc or 0, builtC
        end

        local function ensureCraftSpaceCommon(minFreeNeed, protectSid, baseId)
            local freed = false
            while isRunningFn() and getFreeNow() < minFreeNeed do
                local okF, fCnt = ops.tryFreeCommonSlots(protectSid, baseId and { [baseId] = true } or {}, {}, baseId, minFreeNeed - getFreeNow())
                if okF then
                    freed = true
                    mergesDone = mergesDone + math.max(1, fCnt or 1)
                else
                    break
                end
            end
            if isRunningFn() and getFreeNow() < minFreeNeed then
                local mc = recycleCompletedSSToFive(getFreeNow() + math.max(minFreeNeed - getFreeNow(), 12))
                if mc > 0 then freed = true end
            end
            return getFreeNow() >= minFreeNeed, freed
        end

        local function buildOverflowSimSnap()
            local orderedSids = ops.getOrderedFodderSetIds(nil, false)
            local fodderState = ops.buildFodderState(nil)
            local pm = ops.getPieceMap()
            local owned, craft, sReqMap = {}, {}, {}
            local rem5, rem6, rem9 = 0, 0, 0
            for _, sid in ipairs(orderedSids) do
                owned[sid] = {}
                for s = 0, 9 do owned[sid][s] = 0 end
                sReqMap[sid] = ops.getShardReq(sid)
                craft[sid] = (ops.getRankOfSet(sid) <= 5) and math.floor((pm[sid] or 0) / sReqMap[sid]) or 0
            end
            for _, p in ipairs(pdi.petOwnedList.listElement) do
                if owned[p.setId] and ops.isPetEligibleAsFodder(p, nil, nil, nil, fodderState) then
                    local st = p.star or 0
                    if owned[p.setId][st] ~= nil then
                        owned[p.setId][st] = owned[p.setId][st] + 1
                        if st == 5 then rem5 = rem5 + 1
                        elseif st == 6 then rem6 = rem6 + 1
                        elseif st == 9 then rem9 = rem9 + 1 end
                    end
                end
            end
            local q = ops.reservedFodderQuota
            return {
                orderedSids = orderedSids,
                owned = owned,
                craft = craft,
                rem5 = rem5,
                rem6 = rem6,
                rem9 = rem9,
                keep5 = (q and q.star5) or 0,
                keep6 = (q and q.star6) or 0,
                keep9 = (q and q.star9) or 0,
                crys = inv:GetNumberItemConsumable(2),
            }
        end

        local function simCandidateReach(snap, sid, curSt, availSame)
            local orderedSids = snap.orderedSids
            local owned, craft = {}, {}
            for _, fSid in ipairs(orderedSids) do
                local src = snap.owned[fSid]
                local dst = {}
                for s = 0, 9 do dst[s] = src[s] end
                owned[fSid] = dst
                craft[fSid] = snap.craft[fSid]
            end
            local rem5, rem6, rem9 = snap.rem5, snap.rem6, snap.rem9
            local keep5, keep6, keep9 = snap.keep5, snap.keep6, snap.keep9
            local crys = snap.crys
            local needZeroFromTo5 = ops.needZeroFromTo5

            local function simAvail0(fSid) return (owned[fSid][0] or 0) + (craft[fSid] or 0) end
            local function simTake0(fSid, n)
                local bagTake = math.min(owned[fSid][0], n)
                owned[fSid][0] = owned[fSid][0] - bagTake
                craft[fSid] = craft[fSid] - (n - bagTake)
            end
            local function simCrysTo5(bSt)
                local sum = 0
                for ss = bSt + 1, 5 do sum = sum + (starRules[ss] and starRules[ss].numItem or 0) end
                return sum
            end

            local function simTryTakeStar(reqStar)
                if reqStar == 5 then
                    if rem5 > keep5 then
                        for i = #orderedSids, 1, -1 do
                            local fSid = orderedSids[i]
                            if owned[fSid][5] > 0 then
                                owned[fSid][5] = owned[fSid][5] - 1
                                rem5 = rem5 - 1
                                return true
                            end
                        end
                    end
                    local bestSid, bestBSt, bestTier, bestBagFit = nil, -1, 999, 99
                    for _, fSid in ipairs(orderedSids) do
                        local tier = ops.getRankOfSet(fSid)
                        if tier <= 5 then
                            local topB = nil
                            for b = 4, 1, -1 do if owned[fSid][b] > 0 then topB = b; break end end
                            local candidatesB = {}
                            if topB then table.insert(candidatesB, topB) end
                            if simAvail0(fSid) >= needZeroFromTo5[0] then table.insert(candidatesB, 0) end
                            for _, b in ipairs(candidatesB) do
                                local needZ = needZeroFromTo5[b]
                                if simAvail0(fSid) >= needZ then
                                    local bagFit = (owned[fSid][0] >= needZ) and 0 or 1
                                    local better = (not bestSid)
                                        or ((b > 0) ~= (bestBSt > 0) and (b > 0))
                                        or ((b > 0) == (bestBSt > 0) and bagFit ~= bestBagFit and bagFit < bestBagFit)
                                        or ((b > 0) == (bestBSt > 0) and bagFit == bestBagFit and tier ~= bestTier and tier < bestTier)
                                        or ((b > 0) == (bestBSt > 0) and bagFit == bestBagFit and tier == bestTier and b ~= bestBSt and b > bestBSt)
                                        or ((b > 0) == (bestBSt > 0) and bagFit == bestBagFit and tier == bestTier and b == bestBSt and owned[fSid][0] > owned[bestSid][0])
                                    if better then bestSid, bestBSt, bestTier, bestBagFit = fSid, b, tier, bagFit end
                                end
                            end
                        end
                    end
                    if not bestSid then return false end
                    local needC = simCrysTo5(bestBSt)
                    if crys < needC then return false end
                    crys = crys - needC
                    if bestBSt > 0 then owned[bestSid][bestBSt] = owned[bestSid][bestBSt] - 1 end
                    simTake0(bestSid, needZeroFromTo5[bestBSt])
                    return true
                elseif reqStar == 6 then
                    if rem6 > keep6 then
                        for _, fSid in ipairs(orderedSids) do
                            if owned[fSid][6] > 0 then
                                owned[fSid][6] = owned[fSid][6] - 1
                                rem6 = rem6 - 1
                                return true
                            end
                        end
                    end
                    local r6 = starRules[6]
                    local cost6 = r6 and r6.numItem or 35000
                    local same6 = r6 and r6.samePet or 2
                    if crys < cost6 then return false end
                    crys = crys - cost6
                    local bestSid, bestBSt, bestTier, bestHas5 = nil, -1, 999, 99
                    for _, fSid in ipairs(orderedSids) do
                        local tier = ops.getRankOfSet(fSid)
                        if tier <= 5 then
                            if rem5 > keep5 and owned[fSid][5] > 0 and simAvail0(fSid) >= same6 then
                                local better = (not bestSid) or (0 < bestHas5) or (0 == bestHas5 and tier < bestTier)
                                if better then bestSid, bestBSt, bestTier, bestHas5 = fSid, 5, tier, 0 end
                            else
                                local b = nil
                                for x = 4, 1, -1 do if owned[fSid][x] > 0 then b = x; break end end
                                if b and simAvail0(fSid) >= needZeroFromTo5[b] + same6 then
                                    local better = (not bestSid) or (1 < bestHas5) or (1 == bestHas5 and (tier < bestTier or (tier == bestTier and b > bestBSt)))
                                    if better then bestSid, bestBSt, bestTier, bestHas5 = fSid, b, tier, 1 end
                                elseif simAvail0(fSid) >= needZeroFromTo5[0] + same6 then
                                    local better = (not bestSid) or (2 < bestHas5) or (2 == bestHas5 and tier < bestTier)
                                    if better then bestSid, bestBSt, bestTier, bestHas5 = fSid, 0, tier, 2 end
                                end
                            end
                        end
                    end
                    if not bestSid then return false end
                    if bestBSt < 5 then
                        local c5 = simCrysTo5(bestBSt)
                        if crys < c5 then return false end
                        crys = crys - c5
                        if bestBSt > 0 then owned[bestSid][bestBSt] = owned[bestSid][bestBSt] - 1 end
                        simTake0(bestSid, needZeroFromTo5[bestBSt])
                    else
                        owned[bestSid][5] = owned[bestSid][5] - 1
                        rem5 = rem5 - 1
                    end
                    simTake0(bestSid, same6)
                    for _ = 1, (r6 and r6.star5Pet or 5) do
                        if not simTryTakeStar(5) then return false end
                    end
                    return true
                elseif reqStar == 9 then
                    if rem9 > keep9 then
                        for _, fSid in ipairs(orderedSids) do
                            if owned[fSid][9] > 0 then
                                owned[fSid][9] = owned[fSid][9] - 1
                                rem9 = rem9 - 1
                                return true
                            end
                        end
                    end
                    local bestSid, bestBSt, bestTier = nil, -1, 999
                    for _, fSid in ipairs(orderedSids) do
                        local tier = ops.getRankOfSet(fSid)
                        if tier <= 5 then
                            local chosenB = nil
                            for b = 8, 5, -1 do
                                local bBlocked = (b == 5 and rem5 <= keep5) or (b == 6 and rem6 <= keep6) or (b >= 7 and rem9 < keep9)
                                if not bBlocked and owned[fSid][b] > 0 then
                                    local needS0 = 0
                                    for ss = b + 1, 9 do needS0 = needS0 + (starRules[ss] and starRules[ss].samePet or 0) end
                                    if simAvail0(fSid) >= needS0 then chosenB = b; break end
                                end
                            end
                            if not chosenB then
                                for b = 4, 0, -1 do
                                    if b == 0 or owned[fSid][b] > 0 then
                                        local needS0 = needZeroFromTo5[b]
                                        for ss = 6, 9 do needS0 = needS0 + (starRules[ss] and starRules[ss].samePet or 0) end
                                        if simAvail0(fSid) >= needS0 then chosenB = b; break end
                                    end
                                end
                            end
                            if chosenB then
                                local better = (not bestSid)
                                    or ((chosenB >= 5) ~= (bestBSt >= 5) and (chosenB >= 5))
                                    or ((chosenB >= 5) == (bestBSt >= 5) and chosenB ~= bestBSt and chosenB > bestBSt)
                                    or ((chosenB >= 5) == (bestBSt >= 5) and chosenB == bestBSt and tier < bestTier)
                                if better then bestSid, bestBSt, bestTier = fSid, chosenB, tier end
                            end
                        end
                    end
                    if not bestSid then return false end
                    if bestBSt < 5 then
                        local c5 = simCrysTo5(bestBSt)
                        if crys < c5 then return false end
                        crys = crys - c5
                        if bestBSt > 0 then owned[bestSid][bestBSt] = owned[bestSid][bestBSt] - 1 end
                        simTake0(bestSid, needZeroFromTo5[bestBSt])
                    else
                        owned[bestSid][bestBSt] = owned[bestSid][bestBSt] - 1
                        if bestBSt == 5 then rem5 = rem5 - 1 elseif bestBSt == 6 then rem6 = rem6 - 1 end
                    end
                    for ss = math.max(6, bestBSt + 1), 9 do
                        local rl = starRules[ss]
                        local needC = rl and rl.numItem or 0
                        if crys < needC then return false end
                        crys = crys - needC
                        local needSame = rl and rl.samePet or 0
                        if simAvail0(bestSid) < needSame then return false end
                        simTake0(bestSid, needSame)
                        for _ = 1, (rl and rl.star5Pet or 0) do
                            if not simTryTakeStar(5) then return false end
                        end
                        for _ = 1, (rl and rl.star6Pet or 0) do
                            if not simTryTakeStar(6) then return false end
                        end
                    end
                    return true
                end
                return false
            end

            local reach = curSt
            if reach < 5 then
                local needTo5, crysTo5 = 0, 0
                for ss = reach + 1, 5 do
                    local rs = starRules[ss]
                    needTo5 = needTo5 + (rs and rs.shard or 0)
                    crysTo5 = crysTo5 + (rs and rs.numItem or 0)
                end
                if availSame < needTo5 or crys < crysTo5 then return curSt end
                availSame = availSame - needTo5
                crys = crys - crysTo5
                reach = 5
            end
            for nextSt = reach + 1, ops.maxStar do
                local rule = starRules[nextSt]
                if not rule then break end
                local mainCrys = rule.numItem or 0
                if crys < mainCrys then break end
                crys = crys - mainCrys
                local sameNeed = rule.samePet or 0
                if availSame < sameNeed then break end
                availSame = availSame - sameNeed
                local okAll = true
                for _ = 1, (rule.star5Pet or 0) do if not simTryTakeStar(5) then okAll = false; break end end
                if not okAll then break end
                for _ = 1, (rule.star6Pet or 0) do if not simTryTakeStar(6) then okAll = false; break end end
                if not okAll then break end
                for _ = 1, (rule.star9Pet or 0) do if not simTryTakeStar(9) then okAll = false; break end end
                if not okAll then break end
                reach = nextSt
            end
            return reach
        end

        local function findNextOverflowSSCandidate(excludeSid, failedRoomAt)
            local crysNow = inv:GetNumberItemConsumable(2)
            local pm = ops.getPieceMap()
            local freeNow = getFreeNow()
            local bySid = {}
            local protTid = ops.protectedTargetSetId
            for _, p in ipairs(pdi.petOwnedList.listElement) do
                local sid = p.setId
                if ops.getRankOfSet(sid) == 6
                   and not (excludeSid and sid == excludeSid)
                   and not (protTid and protTid > 0 and sid == protTid) then
                    local g = bySid[sid]
                    if not g then
                        g = { has10 = false, highList = {}, lowList = {}, bag0Safe = 0 }
                        bySid[sid] = g
                    end
                    local st = p.star or 0
                    if st >= ops.maxStar then
                        g.has10 = true
                    elseif st >= 5 then
                        table.insert(g.highList, p)
                    else
                        table.insert(g.lowList, p)
                        if st == 0 and ops.isMaterialSafe(p, nil, nil) then
                            g.bag0Safe = g.bag0Safe + 1
                        end
                    end
                end
            end

            local function sortBaseList(a, b)
                local eqA = (pdi:GetPetEquipped(a.petId) > 0 or (a.heroId or -1) > 0) and 1 or 0
                local eqB = (pdi:GetPetEquipped(b.petId) > 0 or (b.heroId or -1) > 0) and 1 or 0
                if eqA ~= eqB then return eqA > eqB end
                local rA = isRaisedPet(a) and 1 or 0
                local rB = isRaisedPet(b) and 1 or 0
                if rA ~= rB then return rA > rB end
                if (a.star or 0) ~= (b.star or 0) then return (a.star or 0) > (b.star or 0) end
                if (a.level or 1) ~= (b.level or 1) then return (a.level or 1) > (b.level or 1) end
                if (a.tier or 0) ~= (b.tier or 0) then return (a.tier or 0) > (b.tier or 0) end
                return (a.petId or 0) < (b.petId or 0)
            end

            local preCands = {}
            for sid, g in pairs(bySid) do
                local base = nil
                if #g.highList > 0 then
                    table.sort(g.highList, sortBaseList)
                    base = g.highList[1]
                elseif not g.has10 and #g.lowList > 0 then
                    table.sort(g.lowList, sortBaseList)
                    base = g.lowList[1]
                end
                if base and (failedRoomAt[base.petId] == nil or freeNow > failedRoomAt[base.petId]) then
                    local curSt = base.star or 0
                    local bag0 = g.bag0Safe - ((curSt == 0 and ops.isMaterialSafe(base, nil, nil)) and 1 or 0)
                    local libCan = math.floor((pm[sid] or 0) / ops.getShardReq(sid))
                    local availSame = bag0 + libCan
                    local passQuick = false
                    if curSt < 5 then
                        local needTo5, crysTo5 = 0, 0
                        for ss = curSt + 1, 5 do
                            local rs = starRules[ss]
                            needTo5 = needTo5 + (rs and rs.shard or 0)
                            crysTo5 = crysTo5 + (rs and rs.numItem or 0)
                        end
                        passQuick = (availSame >= needTo5) and (crysNow >= crysTo5)
                    else
                        local rl = starRules[curSt + 1]
                        passQuick = rl and (availSame >= (rl.samePet or 0)) and (crysNow >= (rl.numItem or 0)) or false
                    end
                    if passQuick then
                        table.insert(preCands, {
                            sid = sid,
                            base = base,
                            curSt = curSt,
                            bag0 = bag0,
                            availSame = availSame,
                            eq = (pdi:GetPetEquipped(base.petId) > 0 or (base.heroId or -1) > 0) and 1 or 0,
                            raised = isRaisedPet(base) and 1 or 0,
                        })
                    end
                end
            end

            if #preCands == 0 then return nil end
            local snap = buildOverflowSimSnap()
            local validCands = {}
            for _, c in ipairs(preCands) do
                local okStep1 = true
                if c.curSt >= 5 then
                    okStep1 = ops.canAffordStarStep(c.base, c.curSt + 1)
                end
                if okStep1 then
                    local reachSt = simCandidateReach(snap, c.sid, c.curSt, c.availSame)
                    if c.curSt < 5 and reachSt < 5 then reachSt = c.curSt end
                    if c.curSt >= 5 and reachSt <= c.curSt then reachSt = c.curSt + 1 end
                    if reachSt > c.curSt and (c.curSt >= 5 or reachSt >= 5) then
                        c.reachSt = reachSt
                        table.insert(validCands, c)
                    end
                end
            end

            if #validCands == 0 then return nil end
            table.sort(validCands, function(a, b)
                local a10 = (a.reachSt >= ops.maxStar) and 1 or 0
                local b10 = (b.reachSt >= ops.maxStar) and 1 or 0
                if a10 ~= b10 then return a10 > b10 end
                local a6 = (a.curSt >= 6) and 1 or 0
                local b6 = (b.curSt >= 6) and 1 or 0
                if a6 ~= b6 then return a6 > b6 end
                if a.reachSt ~= b.reachSt then return a.reachSt > b.reachSt end
                if a.curSt ~= b.curSt then return a.curSt > b.curSt end
                if a.eq ~= b.eq then return a.eq > b.eq end
                if a.raised ~= b.raised then return a.raised > b.raised end
                if a.bag0 ~= b.bag0 then return a.bag0 > b.bag0 end
                return a.sid < b.sid
            end)
            return validCands[1]
        end

        local function runOverflowSSOneByOne(stopFreeCap, excludeSid)
            if stopFreeCap and getFreeNow() >= stopFreeCap then return 0 end
            local prevLib, prevFodLib = ops.allowLibrary, ops.allowFodderLibrary
            ops.allowLibrary = true
            ops.allowFodderLibrary = true
            _G.HTPS_PET_SUMMON_STATUS = "ghép SS"
            _G.HTPS_UpdatePetSummonBtnUI()

            local ovMerges = 0
            local failedRoomAt = {}
            local okOv, errOv = pcall(function()
                while isRunningFn() do
                    if stopFreeCap and getFreeNow() >= stopFreeCap then break end
                    local pick = findNextOverflowSSCandidate(excludeSid, failedRoomAt)
                    if not pick then break end

                    local baseId = pick.base.petId
                    local sid = pick.sid
                    local startFree = getFreeNow()
                    local advancedAny = false

                    while isRunningFn() do
                        local cur = ops.getPetById(baseId)
                        if not cur or (cur.star or 0) >= ops.maxStar then break end
                        local curSt = cur.star or 0
                        if curSt < 5 then
                            local safeZeros = ops.findSafeSamePets(sid, function(p) return (p.star or 0) == 0 end, nil, baseId)
                            local pm = ops.getPieceMap()
                            local libCan = math.floor((pm[sid] or 0) / ops.getShardReq(sid))
                            local needTo5, crysTo5 = 0, 0
                            for ss = curSt + 1, 5 do
                                local rs = starRules[ss]
                                needTo5 = needTo5 + (rs and rs.shard or 0)
                                crysTo5 = crysTo5 + (rs and rs.numItem or 0)
                            end
                            if (#safeZeros + libCan) < needTo5 or inv:GetNumberItemConsumable(2) < crysTo5 then
                                break
                            end
                            local craftNeed5 = math.max(0, needTo5 - #safeZeros)
                            if craftNeed5 > 0 and getFreeNow() < craftNeed5 then
                                ensureCraftSpaceCommon(craftNeed5, sid, baseId)
                            end
                            cur = ops.getPetById(baseId)
                            if not cur or (cur.star or 0) >= 5 then break end
                            local prevSt5 = cur.star or 0
                            local ok5, err5 = ops.upgradeToFiveBatched(sid, cur, { [baseId] = true }, sid, nil, {}, baseId, "Thiếu bản thể")
                            if ok5 then
                                local d5 = math.max(1, 5 - prevSt5)
                                mergesDone = mergesDone + d5
                                ovMerges = ovMerges + d5
                                advancedAny = true
                            else
                                recordStepFail(err5)
                                break
                            end
                        else
                            local nextSt = curSt + 1
                            local canNow, canRsn = ops.canAffordStarStep(cur, nextSt)
                            if not canNow then
                                recordStepFail(canRsn)
                                break
                            end
                            local stepRule = starRules[nextSt]
                            local safeZeros = ops.findSafeSamePets(sid, function(p) return (p.star or 0) == 0 end, nil, baseId)
                            local sameNeed = (stepRule and stepRule.samePet) or 0
                            local needCraftNow = math.max(0, sameNeed - #safeZeros)
                            local needsFodLib = stepRule and (((stepRule.star5Pet or 0) + (stepRule.star6Pet or 0) + (stepRule.star9Pet or 0)) > 0) or false
                            local fodFloor = needsFodLib and ((stepRule and (stepRule.star9Pet or 0) > 0) and 18 or 16) or 0
                            local minSlotsNeeded = math.max(needCraftNow + (needsFodLib and 14 or 0), fodFloor)
                            if minSlotsNeeded > 0 and getFreeNow() < minSlotsNeeded then
                                local hasSlots, freedTemp = ensureCraftSpaceCommon(minSlotsNeeded, sid, baseId)
                                if freedTemp then
                                    cur = ops.getPetById(baseId)
                                    if not cur or (cur.star or 0) >= ops.maxStar then break end
                                    canNow, canRsn = ops.canAffordStarStep(cur, (cur.star or 0) + 1)
                                    if not canNow then
                                        recordStepFail(canRsn)
                                        break
                                    end
                                end
                                local minFallback = needCraftNow + (needsFodLib and ((stepRule and (stepRule.star9Pet or 0) > 0) and 10 or 8) or 0)
                                if not hasSlots and getFreeNow() < minFallback then
                                    break
                                end
                            end
                            local okStep, rsn = ops.execStarStep(baseId)
                            if okStep then
                                mergesDone = mergesDone + 1
                                ovMerges = ovMerges + 1
                                advancedAny = true
                            else
                                recordStepFail(rsn)
                                break
                            end
                        end
                    end

                    if not advancedAny then
                        failedRoomAt[baseId] = startFree
                    end
                end
            end)

            ops.allowLibrary = prevLib
            ops.allowFodderLibrary = prevFodLib
            if not okOv then error(errOv) end
            return ovMerges
        end

        local function runFocusTargetUpgrade(isPostBuild, targetSid, targetRank)
            local maxCntBefore = countMaxedCopies(targetSid)
            ops.allowLibrary = false
            ops.allowFodderLibrary = false
            mergeRankGroup(targetRank, nil, nil, false, false, targetSid)
            if isRunningFn() then
                local prevLib, prevFodLib = ops.allowLibrary, ops.allowFodderLibrary
                ops.allowLibrary = true
                ops.allowFodderLibrary = true
                local okT, errT = pcall(mergeRankGroup, targetRank, nil, nil, true, true, targetSid)
                ops.allowLibrary = prevLib
                ops.allowFodderLibrary = prevFodLib
                if not okT then error(errT) end
            end
            local maxCntAfter = countMaxedCopies(targetSid)
            if not isPostBuild and maxCntAfter > maxCntBefore then
                pcall(function()
                    local inf = ops.petsInfo[targetSid]
                    local suffix = (maxCntAfter > 1) and (" #" .. tostring(maxCntAfter)) or ""
                    CS.Toast.ShowToast("Đã nâng MAX" .. suffix .. " " .. tostring(inf and inf.name or "Thú") .. "! Tiếp tục quay & ưu tiên nâng con tiếp theo...")
                end)
            end
            ops.reservedFodderQuota = ops.computeTargetFodderQuota(targetSid)
        end

        local function runPriorityTargetAndSS(isPostBuild)
            local targetSid, targetRank, targetValid = getTargetFocusInfo()
            ops.protectedTargetSetId = (targetValid and targetSid > 0) and targetSid or nil

            -- Priority 0 (Focus Mode): Upgrade targetSid (#1 -> 10* -> #2 -> ...), prebuild & lock its exact next-step phôi,
            -- fold pure-bag D..A/S-excess 0*..4* -> 5*, and if bag still < 25 free slots overflow to OTHER SS one-by-one toward 10*!
            if targetValid and isRunningFn() then
                runFocusTargetUpgrade(isPostBuild, targetSid, targetRank)
                if not isRunningFn() or getFreeNow() >= focusFreeCap then return true end

                if not isPostBuild then
                    -- Step 1: Pure bag 0*..4* -> 5* compression for D..A + excess S ONLY (keeps 1 highest S; NEVER spams new SS 5* clones)
                    ops.allowLibrary = false
                    ops.allowFodderLibrary = false
                    local foldSids = ops.getOrderedFodderSetIds(targetSid, true)
                    local mFold = ops.batchFoldFodder(foldSids, focusFreeCap, 5, false, nil, nil, nil, 5)
                    if (mFold or 0) > 0 then mergesDone = mergesDone + mFold end
                    if not isRunningFn() or getFreeNow() >= focusFreeCap then return true end

                    -- Step 2: Prebuild targetSid's needed 5*/6*/9* phôi & lock quota
                    if ops.reservedFodderQuota and ops.prebuildTargetFodder then
                        local preMerges = ops.prebuildTargetFodder(targetSid, ops.reservedFodderQuota)
                        mergesDone = mergesDone + (preMerges or 0)
                        ops.reservedFodderQuota = ops.computeTargetFodderQuota(targetSid)
                    end
                    if not isRunningFn() or getFreeNow() >= 25 then return true end

                    -- Step 3: Bag still crowded (< 25 free) -> overflow SS phụ one-by-one toward 10* strictly above reserved quota
                    runOverflowSSOneByOne(focusFreeCap, targetSid)
                    if not isRunningFn() or getFreeNow() >= 10 then return true end
                else
                    if ops.reservedFodderQuota and ops.prebuildTargetFodder
                       and (((ops.reservedFodderQuota.star6 or 0) > 0) or ((ops.reservedFodderQuota.star9 or 0) > 0)) then
                        local preMerges = ops.prebuildTargetFodder(targetSid, ops.reservedFodderQuota)
                        mergesDone = mergesDone + (preMerges or 0)
                        ops.reservedFodderQuota = ops.computeTargetFodderQuota(targetSid)
                    end
                    if getFreeNow() < 25 then
                        runOverflowSSOneByOne(focusFreeCap, targetSid)
                    end
                    if not isRunningFn() or getFreeNow() >= 10 then return true end
                end
                return false
            end

            -- Default All-SS mode (targetSid == 0): push every SS (1 shared copy per species) cleanly toward 10*, one by one
            runOverflowSSOneByOne(nil, nil)
            if not isRunningFn() or getFreeNow() >= 10 then
                return true
            end
            return false
        end


        local function compressFodderFiveToSixAndSixToNine(stopFreeTarget, allowFodLib, allowPartial9)
            local builtAny = false
            local prevL, prevFL = ops.allowLibrary, ops.allowFodderLibrary
            ops.allowLibrary = allowFodLib and true or false
            ops.allowFodderLibrary = allowFodLib and true or false
            local okCmp, errCmp = pcall(function()
                local cSids = ops.getOrderedFodderSetIds(nil, true)
                local keep5Lim = math.max((ops.reservedFodderQuota and ops.reservedFodderQuota.star5) or 0, 6)
                local keep6Lim = math.max((ops.reservedFodderQuota and ops.reservedFodderQuota.star6) or 0, 2)

                -- 1) Compress surplus 5* -> 6* (6x 5* -> 1x 6*) above reserved 5* quota
                while isRunningFn() and getFreeNow() < stopFreeTarget do
                    if ops.countSafeFodderPets(5, nil, nil, nil) < (keep5Lim + 6) then break end
                    local state5 = ops.buildFodderState(nil)
                    local pickedBase = nil
                    for _, sid in ipairs(cSids) do
                        local lst = ops.findSafeFodderSamePets(sid, function(p) return (p.star or 0) == 5 end, nil, nil, nil, state5)
                        if #lst > 0 and ops.canAffordStarStep(lst[1], 6) then
                            pickedBase = lst[1]
                            break
                        end
                    end
                    if not pickedBase then break end
                    if allowFodLib and getFreeNow() < 2 then ensureCraftSpaceCommon(2, pickedBase.setId, pickedBase.petId) end
                    local ok6, rsn6 = ops.execStarStep(pickedBase.petId)
                    if ok6 then
                        mergesDone = mergesDone + 1
                        builtAny = true
                    else
                        recordStepFail(rsn6)
                        break
                    end
                end

                -- 2) Compress surplus 6*..8* -> 9* (13x 6* -> 1x 9*) above reserved 6* quota
                local failedNineBases = {}
                while isRunningFn() and getFreeNow() < stopFreeTarget do
                    local pickedBase = nil
                    local state6 = ops.buildFodderState(nil)
                    -- Finish any existing 7*/8* fodder first
                    for _, sid in ipairs(cSids) do
                        for stHigh = 8, 7, -1 do
                            local lst = ops.findSafeFodderSamePets(sid, function(p) return (p.star or 0) == stHigh end, failedNineBases, nil, nil, state6)
                            if #lst > 0 and ops.canAffordStarStep(lst[1], stHigh + 1) then
                                pickedBase = lst[1]
                                break
                            end
                        end
                        if pickedBase then break end
                    end
                    if not pickedBase then
                        local safe6Now = ops.countSafeFodderPets(6, nil, nil, nil)
                        local minNeed6 = allowPartial9 and (keep6Lim + 3) or (keep6Lim + 13)
                        if safe6Now >= minNeed6 then
                            local pm = allowFodLib and ops.getPieceMap() or {}
                            for _, sid in ipairs(cSids) do
                                local lst = ops.findSafeFodderSamePets(sid, function(p) return (p.star or 0) == 6 end, failedNineBases, nil, nil, state6)
                                if #lst > 0 and ops.canAffordStarStep(lst[1], 7) then
                                    if allowPartial9 then
                                        pickedBase = lst[1]
                                        break
                                    else
                                        local zAvail = #ops.findSafeFodderSamePets(sid, function(p) return (p.star or 0) == 0 end, nil, nil, nil, state6)
                                        if allowFodLib then zAvail = zAvail + math.floor((pm[sid] or 0) / ops.getShardReq(sid)) end
                                        if zAvail >= 12 and inv:GetNumberItemConsumable(2) >= 137500 then
                                            pickedBase = lst[1]
                                            break
                                        end
                                    end
                                end
                            end
                        end
                    end
                    if not pickedBase then break end
                    local baseId = pickedBase.petId
                    local advancedBase = false
                    while isRunningFn() do
                        local cur = ops.getPetById(baseId)
                        if not cur or (cur.star or 0) >= 9 then break end
                        local canN, rsnN = ops.canAffordStarStep(cur, (cur.star or 0) + 1)
                        if not canN then
                            recordStepFail(rsnN)
                            break
                        end
                        local okStep, errStep = ops.execStarStep(baseId)
                        if okStep then
                            mergesDone = mergesDone + 1
                            builtAny = true
                            advancedBase = true
                        else
                            recordStepFail(errStep)
                            break
                        end
                    end
                    if not advancedBase then
                        failedNineBases[baseId] = true
                    end
                end
            end)
            ops.allowLibrary = prevL
            ops.allowFodderLibrary = prevFL
            if not okCmp then error(errCmp) end
            return builtAny
        end

        local targetSid, targetRank, targetValid = getTargetFocusInfo()
        ops.protectedTargetSetId = (targetValid and targetSid > 0) and targetSid or nil

        -- Initial compute of target fodder quota (if target set)
        if targetValid and targetSid > 0 then
            ops.reservedFodderQuota = ops.computeTargetFodderQuota(targetSid)
            -- Step 0: Initial Focus Pass for target pet using whatever is immediately available
            runFocusTargetUpgrade(false, targetSid, targetRank)
            ops.reservedFodderQuota = ops.computeTargetFodderQuota(targetSid)
        end

        local _, _, initCap = getFreeNow()
        -- Target free capacity for proactive compaction: keep warehouse around 35-45% free
        local targetCompactionFree = math.min(initCap - 30, math.max(350, math.floor(initCap * 0.40)))
        local craftSids = ops.getOrderedFodderSetIds(nil, true)

        -- =========================================================================
        -- TIER 1: Fast compress all D..A trash pets from 0*..4* into 5* fodder (~8:1 space reduction)
        -- =========================================================================
        if isRunningFn() and getFreeNow() < targetCompactionFree then
            _G.HTPS_PET_SUMMON_STATUS = "nén phôi 5★"
            _G.HTPS_UpdatePetSummonBtnUI()
            ops.allowLibrary = false
            ops.allowFodderLibrary = false

            local m1, built1 = ops.batchFoldFodder(craftSids, targetCompactionFree, 5, false, nil, nil, nil, 5)
            if (m1 or 0) > 0 then mergesDone = mergesDone + m1 end
            if m1 == 0 and inv:GetNumberItemConsumable(2) < (starRules[1] and starRules[1].numItem or 5000) then
                hitCrysShort = true
            end

            -- Recycle excess 0*..4* of completed-10* SS into 5* fodder if available
            if isRunningFn() then
                local mSS, bSS = recycleCompletedSSToFive(targetCompactionFree)
                if (mSS or 0) > 0 then mergesDone = mergesDone + mSS end
            end
        end

        -- =========================================================================
        -- TIER 2 & 3: Compress surplus 5* -> 6* fodder and surplus 6* -> 9* fodder
        -- =========================================================================
        if isRunningFn() and getFreeNow() < targetCompactionFree then
            _G.HTPS_PET_SUMMON_STATUS = "nén phôi 6★-9★"
            _G.HTPS_UpdatePetSummonBtnUI()
            -- Pass 1: bag-only fodder
            compressFodderFiveToSixAndSixToNine(targetCompactionFree, false, true)
            -- Pass 2: with fodder library if needed
            if isRunningFn() and getFreeNow() < targetCompactionFree then
                compressFodderFiveToSixAndSixToNine(targetCompactionFree, true, true)
            end
        end

        -- =========================================================================
        -- TIER 4: Feed 9* and 6* fodder into SS pets (push toward 10*)
        -- =========================================================================
        if isRunningFn() then
            _G.HTPS_PET_SUMMON_STATUS = "ghép SS 10★"
            _G.HTPS_UpdatePetSummonBtnUI()
            if targetValid and targetSid > 0 then
                -- Prebuild any exact remaining fodder for target if needed
                ops.reservedFodderQuota = ops.computeTargetFodderQuota(targetSid)
                if ops.reservedFodderQuota and ops.prebuildTargetFodder
                   and (((ops.reservedFodderQuota.star6 or 0) > 0) or ((ops.reservedFodderQuota.star9 or 0) > 0)) then
                    local preMerges = ops.prebuildTargetFodder(targetSid, ops.reservedFodderQuota)
                    mergesDone = mergesDone + (preMerges or 0)
                    ops.reservedFodderQuota = ops.computeTargetFodderQuota(targetSid)
                end
                runFocusTargetUpgrade(true, targetSid, targetRank)
                ops.reservedFodderQuota = ops.computeTargetFodderQuota(targetSid)
                if isRunningFn() then
                    runOverflowSSOneByOne(targetCompactionFree, targetSid)
                end
            else
                runOverflowSSOneByOne(targetCompactionFree, nil)
            end
        end

        -- =========================================================================
        -- TIER 5: Final Clean-up Fold for any remaining loose 0*..4* trash
        -- =========================================================================
        if isRunningFn() and getFreeNow() < targetCompactionFree then
            ops.allowLibrary = false
            ops.allowFodderLibrary = false
            local mClean = ops.batchFoldFodder(craftSids, targetCompactionFree, 5, false, nil, nil, nil, 5)
            if (mClean or 0) > 0 then mergesDone = mergesDone + mClean end
        end

        -- =========================================================================
        -- EMERGENCY FALLBACK (< 10 free slots)
        -- =========================================================================
        if isRunningFn() and getFreeNow() < 10 then
            ops.allowLibrary = false
            ops.allowFodderLibrary = false
            _G.HTPS_PET_SUMMON_STATUS = "cứu cấp <10"
            _G.HTPS_UpdatePetSummonBtnUI()
            local same6Req = (starRules[6] and starRules[6].samePet) or 2
            local fodState4 = ops.buildFodderState(nil)
            local resFn = function(sid)
                return (#ops.findSafeFodderSamePets(sid, function(p) return (p.star or 0) == 5 end, {}, nil, nil, fodState4) > 0) and same6Req or 0
            end
            local m4 = ops.batchFoldFodder(craftSids, 15, 4, true, resFn, nil, nil, 5)
            mergesDone = mergesDone + m4
            if isRunningFn() and getFreeNow() < 10 then
                local mc4 = recycleCompletedSSToFive(15)
                mergesDone = mergesDone + mc4
            end
            local focusSidEnd, _, focusEnd = getTargetFocusInfo()
            if isRunningFn() and getFreeNow() < 10 then
                ops.reservedFodderQuota = nil
                runOverflowSSOneByOne(targetCompactionFree, focusEnd and focusSidEnd or nil)
                if isRunningFn() and getFreeNow() < 10 then
                    compressFodderFiveToSixAndSixToNine(15, true, true)
                end
            end
        end

        local reason = nil
        if mergesDone == 0 then
            if hitCrysShort then
                reason = "Kho thú đầy, không đủ Đá Thức Tỉnh để tự động ghép thêm!"
            else
                reason = "Kho thú đầy, hết nguyên liệu để ghép (đã giữ an toàn SS & mỗi loài S 1 con chính)!"
            end
        end
        return finishMerge(reason)
    end

    _G.HTPS_GetPetTargetSetId = function()
        if _G.HTPS_PET_TARGET_SET_ID == nil then
            local saved = 0
            pcall(function() saved = UG.PlayerPrefs.GetInt("HTPS_PET_TARGET_SET_ID", 0) or 0 end)
            _G.HTPS_PET_TARGET_SET_ID = saved
        end
        return tonumber(_G.HTPS_PET_TARGET_SET_ID) or 0
    end

    _G.HTPS_SetPetTargetSetId = function(sid)
        local n = tonumber(sid) or 0
        _G.HTPS_PET_TARGET_SET_ID = n
        pcall(function() UG.PlayerPrefs.SetInt("HTPS_PET_TARGET_SET_ID", n) end)
    end

    _G.HTPS_ClosePetTargetDropdown = function()
        pcall(function()
            local psGo = GO.Find("PetSummon(Clone)")
            if not psGo then return end
            local blk = psGo.transform:Find("Content/BlockerHTPSPetTargetDrop")
            if blk then blk.gameObject:SetActive(false) end
        end)
    end

    _G.HTPS_GetPetTargetOptions = function()
        local opts = {
            {
                setId = 0,
                rank = 99,
                isFullyMax = false,
                isEq = 1,
                sortStar = 999,
                sortLv = 9999,
                libCan = 0,
                ownedCnt = 0,
                shortLabel = "Mục tiêu: Tất cả SS",
                labelPlain = "Tất cả SS (Mặc định - nâng đều)",
                labelRich = "<color=#7CFC8A>Tất cả SS</color> (Mặc định - nâng đều)",
            }
        }
        pcall(function()
            local pldb = _G.PetLoadDb and _G.PetLoadDb:getInstance()
            local pdi = _G.PetDataItem and _G.PetDataItem:instance()
            if not pldb or not pdi then return end
            local maxStar = pldb:GetMaxStar() or 10

            local pieceMap = {}
            local pcs = pdi.petPieceList and pdi.petPieceList.listElement
            if pcs then
                for _, sh in ipairs(pcs) do
                    if type(sh) == "table" and sh[1] then
                        pieceMap[sh[1]] = tonumber(sh[2]) or 0
                    end
                end
            end

            local stats = {}
            local own = pdi.petOwnedList and pdi.petOwnedList.listElement
            if own then
                for _, p in ipairs(own) do
                    local sid = p.setId
                    if sid then
                        local st = stats[sid]
                        if not st then
                            st = { ownedCnt = 0, bagZero = 0, isEq = 0, maxCnt = 0, bestStarAny = -1, bestLvAny = -1, unmaxStar = -1, unmaxLv = -1 }
                            stats[sid] = st
                        end
                        st.ownedCnt = st.ownedCnt + 1
                        local pStar = p.star or 0
                        local pLv = p.level or 1
                        if pStar >= maxStar then
                            st.maxCnt = st.maxCnt + 1
                        end
                        if pStar == 0 and pLv <= 1 and (p.tier or 0) == 0 and (p.changeBasic or 0) == 0
                            and pdi:GetPetEquipped(p.petId) <= 0 and (p.heroId or -1) <= 0 then
                            st.bagZero = st.bagZero + 1
                        end
                        if pdi:GetPetEquipped(p.petId) > 0 or (p.heroId or -1) > 0 then
                            st.isEq = 1
                        end
                        if pStar > st.bestStarAny or (pStar == st.bestStarAny and pLv > st.bestLvAny) then
                            st.bestStarAny = pStar
                            st.bestLvAny = pLv
                        end
                        if pStar < maxStar and (pStar > st.unmaxStar or (pStar == st.unmaxStar and pLv > st.unmaxLv)) then
                            st.unmaxStar = pStar
                            st.unmaxLv = pLv
                        end
                    end
                end
            end

            local petList = {}
            local rawList = pldb:GetListPet() and pldb:GetListPet().listElement
            if rawList then
                for _, inf in ipairs(rawList) do
                    local rk = tonumber(inf.rank) or 0
                    if rk == 6 or rk == 5 then
                        local sid = inf.id
                        local name = tostring(inf.name or ("#" .. tostring(sid)))
                        local req = tonumber(inf.shardReq) or 50
                        if req <= 0 then req = 50 end
                        local libCan = math.floor((pieceMap[sid] or 0) / req)
                        local st = stats[sid]
                        local ownedCnt = st and st.ownedCnt or 0
                        local bagZero = st and st.bagZero or 0
                        local isEq = st and st.isEq or 0
                        local maxCnt = st and st.maxCnt or 0
                        local bestStarAny = st and st.bestStarAny or -1
                        local unmaxStar = st and st.unmaxStar or -1
                        local isFullyMax = (ownedCnt > 0 and bestStarAny >= maxStar and unmaxStar < 0)
                        local sortStar = (unmaxStar >= 0) and unmaxStar or bestStarAny
                        local sortLv = (unmaxStar >= 0) and (st and st.unmaxLv or -1) or (st and st.bestLvAny or -1)

                        local rkTxt = (rk == 6) and "SS" or "S"
                        local rkColor = (rk == 6) and "#FFD24D" or "#E09EFF"
                        local infoParts = {}
                        if maxCnt > 0 then
                            table.insert(infoParts, (maxCnt > 1) and ("MAX×" .. maxCnt) or "MAX")
                        end
                        if ownedCnt > 0 then
                            if not isFullyMax then
                                table.insert(infoParts, string.format("%d★", math.max(0, sortStar)))
                            end
                            if isEq == 1 then table.insert(infoParts, "Đeo") end
                            if bagZero > 0 then table.insert(infoParts, "Túi:" .. bagZero) end
                        else
                            table.insert(infoParts, "Chưa có")
                        end
                        if libCan > 0 then table.insert(infoParts, "TV:" .. libCan) end

                        local infoStr = table.concat(infoParts, " • ")
                        local shortStr
                        if isFullyMax then
                            shortStr = string.format("ƯT: %s (MAX%s)", name, (maxCnt > 1) and ("×" .. maxCnt) or "")
                        elseif sortStar > 0 then
                            shortStr = string.format("ƯT: %s (%d★)", name, sortStar)
                        else
                            shortStr = "ƯT: " .. name
                        end

                        table.insert(petList, {
                            setId = sid,
                            rank = rk,
                            name = name,
                            isFullyMax = isFullyMax,
                            isEq = isEq,
                            sortStar = sortStar,
                            sortLv = sortLv,
                            libCan = libCan,
                            ownedCnt = ownedCnt,
                            shortLabel = shortStr,
                            labelPlain = string.format("[%s] %s • %s", rkTxt, name, infoStr),
                            labelRich = string.format("<color=%s>[%s]</color> %s • %s", rkColor, rkTxt, name, infoStr),
                        })
                    end
                end
            end

            table.sort(petList, function(a, b)
                if a.rank ~= b.rank then return a.rank > b.rank end
                if a.isFullyMax ~= b.isFullyMax then return not a.isFullyMax end
                if a.sortStar ~= b.sortStar then return a.sortStar > b.sortStar end
                if a.isEq ~= b.isEq then return a.isEq > b.isEq end
                if a.sortLv ~= b.sortLv then return a.sortLv > b.sortLv end
                if a.libCan ~= b.libCan then return a.libCan > b.libCan end
                if a.ownedCnt ~= b.ownedCnt then return a.ownedCnt > b.ownedCnt end
                return a.setId < b.setId
            end)

            for _, ent in ipairs(petList) do
                table.insert(opts, ent)
            end
        end)
        return opts
    end

    _G.HTPS_RefreshPetTargetButtonLabel = function()
        pcall(function()
            local psGo = GO.Find("PetSummon(Clone)")
            if not psGo then return end
            local btnTf = psGo.transform:Find("Content/Main/BtnHTPSPetTargetDrop")
            if not btnTf then return end
            local lblTf = btnTf:Find("Label")
            local ltxt = lblTf and lblTf:GetComponent(typeof(UG.UI.Text))
            if not ltxt then return end

            local selId = _G.HTPS_GetPetTargetSetId()
            if selId <= 0 then
                ltxt.text = "Mục tiêu: Tất cả SS"
                return
            end
            local pldb = _G.PetLoadDb and _G.PetLoadDb:getInstance()
            local pdi = _G.PetDataItem and _G.PetDataItem:instance()
            local name, maxStar = nil, (pldb and pldb:GetMaxStar() or 10)
            if pldb and pldb:GetListPet() and pldb:GetListPet().listElement then
                for _, inf in ipairs(pldb:GetListPet().listElement) do
                    if inf.id == selId and ((tonumber(inf.rank) or 0) == 6 or (tonumber(inf.rank) or 0) == 5) then
                        name = tostring(inf.name or ("#" .. tostring(selId)))
                        break
                    end
                end
            end
            if not name then
                _G.HTPS_SetPetTargetSetId(0)
                ltxt.text = "Mục tiêu: Tất cả SS"
                return
            end
            local maxCnt, bestStar, unmaxStar = 0, -1, -1
            if pdi and pdi.petOwnedList and pdi.petOwnedList.listElement then
                for _, p in ipairs(pdi.petOwnedList.listElement) do
                    if p.setId == selId then
                        local st = p.star or 0
                        if st >= maxStar then maxCnt = maxCnt + 1 end
                        if st > bestStar then bestStar = st end
                        if st < maxStar and st > unmaxStar then unmaxStar = st end
                    end
                end
            end
            if bestStar >= maxStar and unmaxStar < 0 then
                ltxt.text = string.format("ƯT: %s (MAX%s)", name, (maxCnt > 1) and ("×" .. maxCnt) or "")
            elseif unmaxStar > 0 then
                ltxt.text = string.format("ƯT: %s (%d★)", name, unmaxStar)
            else
                ltxt.text = "ƯT: " .. name
            end
        end)
    end

    _G.HTPS_RebuildPetTargetRows = function()
        pcall(function()
            local psGo = GO.Find("PetSummon(Clone)")
            if not psGo then return end
            local blkTf = psGo.transform:Find("Content/BlockerHTPSPetTargetDrop")
            local listCntTf = blkTf and blkTf:Find("BoxFrame/InnerBg/Viewport/ListContent")
            if not listCntTf then return end

            local b10 = psGo.transform:Find("Content/Main/ButtonSummon10")
            local b10Txt = b10 and b10:GetComponentInChildren(typeof(UG.UI.Text), true)
            local gameFont = (b10Txt and b10Txt.font) or UG.Resources.GetBuiltinResource(typeof(UG.Font), "Arial.ttf")
            local spBtnYellow = _G.HTPS_FindNativeSprite and _G.HTPS_FindNativeSprite("button_yellow", true)
            local spBoxField = _G.HTPS_FindNativeSprite and _G.HTPS_FindNativeSprite("box_field_1", false)
            local spTickGreen = _G.HTPS_FindNativeSprite and _G.HTPS_FindNativeSprite("tick_green", false)

            local opts = _G.HTPS_GetPetTargetOptions()
            local selId = _G.HTPS_GetPetTargetSetId()
            local matched = false
            for _, o in ipairs(opts) do
                if o.setId == selId then matched = true; break end
            end
            if not matched then
                selId = 0
                _G.HTPS_SetPetTargetSetId(0)
            end

            for i = listCntTf.childCount - 1, 0, -1 do
                UG.Object.DestroyImmediate(listCntTf:GetChild(i).gameObject)
            end

            for idx, opt in ipairs(opts) do
                local isSel = (opt.setId == selId)
                local rowGo = GO("RowPet_" .. tostring(idx))
                rowGo.transform:SetParent(listCntTf, false)
                rowGo:AddComponent(typeof(UG.RectTransform))
                local le = rowGo:AddComponent(typeof(UG.UI.LayoutElement))
                le.minHeight = 40
                le.preferredHeight = 40

                local rImg = rowGo:AddComponent(typeof(UG.UI.Image))
                if isSel and spBtnYellow then
                    rImg.sprite = spBtnYellow
                    rImg.type = UG.UI.Image.Type.Sliced
                    rImg.color = UG.Color(1.0, 1.0, 1.0, 1.0)
                elseif spBoxField then
                    rImg.sprite = spBoxField
                    rImg.type = UG.UI.Image.Type.Simple
                    rImg.color = isSel and UG.Color(0.95, 0.78, 0.25, 1.0) or UG.Color(1.0, 1.0, 1.0, 0.94)
                else
                    rImg.color = isSel and UG.Color(0.88, 0.68, 0.18, 0.98) or UG.Color(0.22, 0.16, 0.11, 0.95)
                end

                if spTickGreen then
                    local tkGo = GO("Tick")
                    tkGo.transform:SetParent(rowGo.transform, false)
                    local tkRt = tkGo:AddComponent(typeof(UG.RectTransform))
                    tkRt.anchorMin = UG.Vector2(0, 0.5)
                    tkRt.anchorMax = UG.Vector2(0, 0.5)
                    tkRt.pivot = UG.Vector2(0, 0.5)
                    tkRt.anchoredPosition = UG.Vector2(8, 1)
                    tkRt.sizeDelta = UG.Vector2(22, 20)
                    local tkIm = tkGo:AddComponent(typeof(UG.UI.Image))
                    tkIm.sprite = spTickGreen
                    tkIm.type = UG.UI.Image.Type.Simple
                    tkIm.color = UG.Color(1.0, 1.0, 1.0, 1.0)
                    tkGo:SetActive(isSel)
                end

                local rtGo = GO("Text")
                rtGo.transform:SetParent(rowGo.transform, false)
                local rtrt = rtGo:AddComponent(typeof(UG.RectTransform))
                rtrt.anchorMin = UG.Vector2(0, 0)
                rtrt.anchorMax = UG.Vector2(1, 1)
                rtrt.offsetMin = UG.Vector2((isSel and spTickGreen ~= nil) and 34 or 12, 3)
                rtrt.offsetMax = UG.Vector2(-10, -3)
                local rTxt = rtGo:AddComponent(typeof(UG.UI.Text))
                rTxt.font = gameFont
                rTxt.fontSize = 15
                rTxt.fontStyle = UG.FontStyle.Normal
                rTxt.alignment = UG.TextAnchor.MiddleLeft
                rTxt.resizeTextForBestFit = true
                rTxt.resizeTextMinSize = 10
                rTxt.resizeTextMaxSize = 15
                rTxt.supportRichText = not isSel
                rTxt.text = isSel and opt.labelPlain or opt.labelRich
                rTxt.color = isSel and UG.Color(0.38, 0.20, 0.06, 1.0) or UG.Color(0.96, 0.92, 0.82, 1.0)
                local rOut = rtGo:AddComponent(typeof(UG.UI.Outline))
                rOut.effectColor = UG.Color(0.10, 0.06, 0.03, 1.0)
                rOut.effectDistance = UG.Vector2(1.0, -1.0)
                rOut.enabled = not isSel

                local chosenSid = opt.setId
                local rBtn = rowGo:AddComponent(typeof(UG.UI.Button))
                rBtn.targetGraphic = rImg
                rBtn.onClick:AddListener(function()
                    _G.HTPS_SetPetTargetSetId(chosenSid)
                    _G.HTPS_RefreshPetTargetButtonLabel()
                    _G.HTPS_ClosePetTargetDropdown()
                end)
            end
            _G.HTPS_RefreshPetTargetButtonLabel()
        end)
    end

    _G.HTPS_TogglePetTargetDropdown = function()
        pcall(function()
            local psGo = GO.Find("PetSummon(Clone)")
            if not psGo then return end
            local blkDrop = psGo.transform:Find("Content/BlockerHTPSPetTargetDrop")
            if not blkDrop then return end
            local nextState = not blkDrop.gameObject.activeSelf
            if nextState then
                _G.HTPS_RebuildPetTargetRows()
                blkDrop:SetAsLastSibling()
                local vp = blkDrop:Find("BoxFrame/InnerBg/Viewport")
                local sr = vp and vp:GetComponent(typeof(UG.UI.ScrollRect))
                if sr then sr.verticalNormalizedPosition = 1.0 end
            end
            blkDrop.gameObject:SetActive(nextState)
        end)
    end

    _G.HTPS_UpdatePetSummonBtnUI = function()
        pcall(function()
            local btnTf = _G.HTPS_BOUND_PET_FAST_SUMMON_BTN
            if not btnTf or btnTf:Equals(nil) then return end
            if _G.HTPS_PET_SUMMON_RUNNING then
                local st = _G.HTPS_PET_SUMMON_STATUS
                local cntStr = _G.HTPS_FormatExactInt(_G.HTPS_PET_SUMMON_COUNT or 0)
                local mg = _G.HTPS_PET_MERGE_COUNT or 0
                local mgStr = _G.HTPS_FormatExactInt(mg)
                local lbl
                if st and st ~= "" then
                    lbl = string.format("Đang %s (%s)\nBấm dừng | CM: %s", st, mgStr, cntStr)
                elseif mg > 0 then
                    lbl = string.format("Dừng (%s)\nĐã ghép: %s lần", cntStr, mgStr)
                else
                    lbl = string.format("Dừng (%s)", cntStr)
                end
                _G.HTPS_ApplyNativePetBtnStyle(btnTf, lbl, false)
            else
                _G.HTPS_ApplyNativePetBtnStyle(btnTf, "Chiêu Mộ Nhanh", true)
            end
            if _G.HTPS_RefreshPetTargetButtonLabel then _G.HTPS_RefreshPetTargetButtonLabel() end
        end)
    end

    _G.HTPS_TogglePetFastSummon = function()
        _G.HTPS_ClosePetTargetDropdown()
        if _G.HTPS_PET_SUMMON_RUNNING then
            _G.HTPS_PET_SUMMON_RUNNING = false
            _G.HTPS_PET_SUMMON_STATUS = ""
            _G.HTPS_UpdatePetSummonBtnUI()
            return
        end
        if _G.HTPS_PET_SUMMON_LOCK then return end
        local livePS = _G.HTPS_GetLivePetSummon()
        if not livePS then return end
        _G.HTPS_PET_SUMMON_LOCK = true
        _G.HTPS_PET_SUMMON_RUNNING = true
        _G.HTPS_PET_SUMMON_COUNT = 0
        _G.HTPS_PET_MERGE_COUNT = 0
        _G.HTPS_PET_MERGE_STATS = { SS = 0, S = 0, PHOI = 0 }
        _G.HTPS_PET_SUMMON_STATUS = ""
        _G.HTPS_UpdatePetSummonBtnUI()

        CsCoroutine.start(function()
            local packetIdx = 0
            local usedFree = false
            local knownBagCap = _G.HTPS_PET_KNOWN_BAG_CAP
            local stopToast = nil
            pcall(function()
                local inv = CS.PlayerInventory.GetInstance()
                local pdi = _G.PetDataItem:instance()
                local ops
                ops = _G.HTPS_PetCreateOps(
                    function() return _G.HTPS_PET_SUMMON_RUNNING and (_G.HTPS_GetLivePetSummon() ~= nil) end,
                    function(skipUi)
                        local synced = _G.HTPS_PetSync940(false, skipUi)
                        if not skipUi then _G.HTPS_UpdatePetSummonBtnUI() end
                        return synced
                    end,
                    false,
                    knownBagCap or 1000,
                    function(baseSetId, okCnt)
                        local addN = okCnt or 1
                        _G.HTPS_PET_MERGE_COUNT = (_G.HTPS_PET_MERGE_COUNT or 0) + addN
                        local rk = ops and ops.getRankOfSet(baseSetId) or 99
                        local st = _G.HTPS_PET_MERGE_STATS
                        if rk == 6 then
                            st.SS = (st.SS or 0) + addN
                        elseif rk == 5 then
                            st.S = (st.S or 0) + addN
                        else
                            st.PHOI = (st.PHOI or 0) + addN
                        end
                        _G.HTPS_UpdatePetSummonBtnUI()
                    end
                )
                local estOwned = (pdi.petOwnedList and pdi.petOwnedList.listElement and #pdi.petOwnedList.listElement) or 0
                local estExact = false

                local function runAutoMergeCycle(minNeedSlots, alreadySynced, triggerErrMsg, isProactive)
                    if not alreadySynced or not estExact then
                        _G.HTPS_PetSync940(false, true)
                    end
                    local curOwned = (pdi.petOwnedList and pdi.petOwnedList.listElement and #pdi.petOwnedList.listElement) or 0
                    estOwned = curOwned
                    estExact = true

                    if not knownBagCap then
                        if curOwned > 0 then
                            knownBagCap = (minNeedSlots >= 10 and curOwned >= 985 and curOwned <= 1000) and 1000
                                or (curOwned + ((minNeedSlots >= 10) and 9 or 0))
                        else
                            knownBagCap = 1000
                        end
                    elseif triggerErrMsg and minNeedSlots >= 10 and (knownBagCap - curOwned) >= 10 then
                        knownBagCap = curOwned + 9
                    elseif curOwned > knownBagCap then
                        knownBagCap = curOwned
                    end
                    _G.HTPS_PET_KNOWN_BAG_CAP = knownBagCap
                    ops.setKnownBagCap(knownBagCap)

                    local realFreeBefore = math.max(0, knownBagCap - curOwned)
                    if not triggerErrMsg and not isProactive and realFreeBefore >= minNeedSlots then
                        ops.yieldIfDue(false)
                        return true
                    end

                    _G.HTPS_PET_SUMMON_STATUS = "ghép kho"
                    _G.HTPS_UpdatePetSummonBtnUI()

                    local mergesDone, mergeReason = _G.HTPS_PetAutoMergeWarehouse(ops, function()
                        return _G.HTPS_PET_SUMMON_RUNNING and (_G.HTPS_GetLivePetSummon() ~= nil)
                    end)

                    _G.HTPS_PET_SUMMON_STATUS = ""
                    _G.HTPS_UpdatePetSummonBtnUI()
                    if not _G.HTPS_PET_SUMMON_RUNNING then return false end

                    local afterOwned = (pdi.petOwnedList and pdi.petOwnedList.listElement and #pdi.petOwnedList.listElement) or 0
                    estOwned = afterOwned
                    estExact = true
                    local freeAfter = math.max(0, knownBagCap - afterOwned)
                    local passMin = isProactive and 10 or minNeedSlots
                    if freeAfter >= passMin and (not triggerErrMsg or mergesDone > 0 or afterOwned < curOwned) then
                        ops.yieldIfDue(false)
                        return true
                    end
                    stopToast = mergeReason or string.format("Kho thú chỉ còn %d/%d ô trống (cần >= %d ô để quay %s)!",
                        freeAfter, knownBagCap, minNeedSlots, (minNeedSlots >= 10) and "x10" or "x1")
                    return false
                end

                local lastProactiveCheckOwned = -1
                while _G.HTPS_PET_SUMMON_RUNNING do
                    local psNow = _G.HTPS_GetLivePetSummon()
                    if not psNow then break end
                    _G.HTPS_BONUS_SUPPRESS_UNTIL = UG.Time.realtimeSinceStartup + 2.0

                    local specs = {}
                    local amounts = {}
                    local sentFree = false
                    local needMergeNow = false
                    local mergeMinSlots = 10
                    local mergeIsProactive = false
                    local cdLeft = 999
                    pcall(function()
                        if pdi and pdi.countdownText then
                            cdLeft = pdi.countdownText:GetTimeLeft()
                        end
                    end)
                    if not usedFree and cdLeft <= 0 then
                        usedFree = true
                        sentFree = true
                        table.insert(specs, {id = 948, vals = {-1}})
                        table.insert(amounts, 1)
                    else
                        local compass = inv and inv:GetNumberItemConsumable(3002) or 0
                        if compass >= 10 then
                            local maxBatch = knownBagCap and 25 or 10
                            local batches = math.min(maxBatch, math.floor(compass / 10))
                            if knownBagCap then
                                local freeSlots = math.max(0, knownBagCap - estOwned)
                                local proactiveLimit = math.min(200, math.max(150, math.floor(knownBagCap * 0.18)))
                                if freeSlots < 10 then
                                    batches = 0
                                    needMergeNow = true
                                    mergeMinSlots = 10
                                    mergeIsProactive = false
                                elseif freeSlots < proactiveLimit and (lastProactiveCheckOwned < 0 or estOwned >= lastProactiveCheckOwned + 15) then
                                    batches = 0
                                    needMergeNow = true
                                    mergeMinSlots = 10
                                    mergeIsProactive = true
                                else
                                    batches = math.min(batches, math.max(1, math.floor(freeSlots / 4)))
                                end
                            end
                            for _ = 1, batches do
                                table.insert(specs, {id = 948, vals = {10}})
                                table.insert(amounts, 10)
                            end
                        elseif compass >= 1 then
                            -- Only 1..9 compasses remain (< 10 for x10); finish remaining compasses cleanly via x1
                            local freeSlots = knownBagCap and math.max(0, knownBagCap - estOwned) or compass
                            if knownBagCap and freeSlots < 1 then
                                needMergeNow = true
                                mergeMinSlots = 1
                            else
                                local singleBatches = math.min(compass, freeSlots)
                                for _ = 1, singleBatches do
                                    table.insert(specs, {id = 948, vals = {1}})
                                    table.insert(amounts, 1)
                                end
                            end
                        else
                            stopToast = "Không đủ La Bàn chiêu mộ (3002)!"
                            break
                        end
                    end

                    if needMergeNow then
                        local prevOwned = estOwned
                        if not runAutoMergeCycle(mergeMinSlots, false, nil, mergeIsProactive) then break end
                        if mergeIsProactive and estOwned >= prevOwned then
                            lastProactiveCheckOwned = estOwned
                        else
                            lastProactiveCheckOwned = -1
                        end
                    else
                        -- Skip expensive processKEvent(940) (~170ms) during pure summoning when bag headroom > 35:
                        -- track estOwned directly from tp==2 drops in 0.5ms and only sync 940 near cap or every 8th packet.
                        local estFreeBefore = knownBagCap and math.max(0, knownBagCap - estOwned) or 0
                        local wantSyncPkt = (not knownBagCap) or sentFree or (estFreeBefore <= 35) or (packetIdx % 8 == 0)
                        local reqSpecs = {}
                        for _, s in ipairs(specs) do table.insert(reqSpecs, s) end
                        if wantSyncPkt then table.insert(reqSpecs, {id = 940}) end

                        local res, errMsg = _G.HTPS_PetSendActs(948, reqSpecs)
                        if not res then
                            stopToast = errMsg or "Mất kết nối server!"
                            break
                        end
                        local actIdx, gotInlineSync, petsDropped = 0, false, 0
                        for _, ra in ipairs(res) do
                            if ra.actionId == 940 and ra.data then
                                _G.HTPS_PetApplySyncData(ra.data, false, true)
                                gotInlineSync = true
                            elseif ra.actionId == 948 and ra.data then
                                actIdx = actIdx + 1
                                _G.HTPS_PET_SUMMON_COUNT = _G.HTPS_PET_SUMMON_COUNT + (amounts[actIdx] or 1)
                                pcall(function()
                                    local lcv = _G.HTPS_DeserializeProto(ra.data, "pbdson.ListCommonVector,PbMethodLib")
                                    if lcv and lcv.aVector then
                                        for vi = 0, lcv.aVector.Count - 1 do
                                            local cv = lcv.aVector[vi]
                                            if cv and cv.aLong and cv.aLong.Count > 0 then
                                                local tp = cv.aLong[0]
                                                if tp == 2 then
                                                    local qty = (cv.aLong.Count >= 3 and cv.aLong[2] > 0) and cv.aLong[2] or 1
                                                    petsDropped = petsDropped + qty
                                                end
                                                local startJ = (tp == 3) and 1 or 3
                                                if cv.aLong.Count > startJ then
                                                    local along = CS.LuaLibrary.CreateNewListLong()
                                                    for j = startJ, cv.aLong.Count - 1 do along:Add(cv.aLong[j]) end
                                                    CS.BonusModel.ParseBonusReceived(along)
                                                end
                                            end
                                        end
                                    end
                                end)
                            end
                        end
                        if gotInlineSync then
                            estOwned = (pdi.petOwnedList and pdi.petOwnedList.listElement and #pdi.petOwnedList.listElement) or estOwned
                            estExact = true
                        else
                            estOwned = estOwned + petsDropped
                            estExact = false
                        end

                        pcall(function()
                            if psNow and not psNow.disposed and psNow.lbResourcesText and inv then
                                psNow.lbResourcesText.text = tostring(inv:GetNumberItemConsumable(3002))
                            end
                        end)
                        _G.HTPS_UpdatePetSummonBtnUI()

                        if errMsg then
                            if _G.HTPS_PetIsBagFullErr(errMsg) then
                                local sentTen = false
                                for _, sp in ipairs(specs) do
                                    if sp.vals and sp.vals[1] == 10 then sentTen = true break end
                                end
                                if not runAutoMergeCycle(sentTen and 10 or 1, gotInlineSync, errMsg, false) then break end
                            else
                                stopToast = errMsg
                                break
                            end
                        elseif actIdx == 0 then
                            break
                        else
                            packetIdx = packetIdx + 1
                            ops.yieldIfDue(false)
                        end
                    end
                end
            end)
            _G.HTPS_PET_SUMMON_RUNNING = false
            _G.HTPS_PET_SUMMON_STATUS = ""
            _G.HTPS_BONUS_SUPPRESS_UNTIL = UG.Time.realtimeSinceStartup + 0.5
            pcall(function() _G.HTPS_PetSync940(false) end)
            _G.HTPS_UpdatePetSummonBtnUI()
            _G.HTPS_RefreshPetTargetButtonLabel()
            _G.HTPS_PET_SUMMON_LOCK = false
            pcall(function()
                local cnt = _G.HTPS_PET_SUMMON_COUNT or 0
                local mg = _G.HTPS_PET_MERGE_COUNT or 0
                local stStats = _G.HTPS_PET_MERGE_STATS or {}
                local parts = {}
                if cnt > 0 then table.insert(parts, "Chiêu mộ " .. _G.HTPS_FormatExactInt(cnt) .. " lần") end
                if mg > 0 then
                    local detail = string.format("SS:%d, S:%d, Phôi:%d", stStats.SS or 0, stStats.S or 0, stStats.PHOI or 0)
                    table.insert(parts, string.format("Ghép %s lần (%s)", _G.HTPS_FormatExactInt(mg), detail))
                end
                local summary = table.concat(parts, " | ")
                if stopToast and stopToast ~= "" then
                    local msg = (summary ~= "") and (stopToast .. " (" .. summary .. ")") or stopToast
                    CS.Toast.ShowToast(msg)
                elseif summary ~= "" then
                    CS.Toast.ShowToast("Đã dừng: " .. summary)
                end
            end)
        end)
    end

    _G.HTPS_EnsurePetSummonButtons = function()
        if not _G.HTPS_AUTO_ACTIVATED then return end
        pcall(function()
            local goRoot = GO.Find("PetSummon(Clone)")
            if not goRoot or not goRoot.activeInHierarchy then return end
            local tfContent = goRoot.transform:Find("Content")
            local tfMain = tfContent and tfContent:Find("Main")
            if not tfMain then return end

            local b1 = tfMain:Find("ButtonSummon")
            local bFree = tfMain:Find("ButtonSummonFree")
            local b10 = tfMain:Find("ButtonSummon10")
            local imgCnt = tfMain:Find("ImageCount")
            if not b10 then return end

            local function fitBtnRect(tf, xPos, w)
                if not tf then return end
                local rt = tf:GetComponent(typeof(UG.RectTransform))
                if rt then
                    rt.anchoredPosition = UG.Vector2(xPos, 25)
                    rt.sizeDelta = UG.Vector2(w or 180, 60)
                end
            end
            fitBtnRect(b1, -192, 180)
            fitBtnRect(bFree, -192, 180)
            fitBtnRect(b10, 0, 180)
            if imgCnt then
                local rtC = imgCnt:GetComponent(typeof(UG.RectTransform))
                if rtC then
                    rtC.anchoredPosition = UG.Vector2(-192, 82)
                end
            end

            local btnFast = tfMain:Find("BtnHTPSPetFastSummon")
            if not btnFast then
                local clone = GO.Instantiate(b10.gameObject, tfMain, false)
                clone.name = "BtnHTPSPetFastSummon"
                btnFast = clone.transform
                local iconS = btnFast:Find("IconScroll")
                if iconS then iconS.gameObject:SetActive(false) end
                local iconG = btnFast:Find("IconGem")
                if iconG then iconG.gameObject:SetActive(false) end
                local txtTf = btnFast:Find("Text")
                if txtTf then
                    local tComp = txtTf:GetComponent(typeof(UG.UI.Text))
                    if tComp then tComp.alignment = UG.TextAnchor.MiddleCenter end
                    local rtT = txtTf:GetComponent(typeof(UG.RectTransform))
                    if rtT then
                        rtT.anchorMin = UG.Vector2(0, 0)
                        rtT.anchorMax = UG.Vector2(1, 1)
                        rtT.offsetMin = UG.Vector2(10, 4)
                        rtT.offsetMax = UG.Vector2(-10, -4)
                    end
                end
                local bComp = clone:GetComponent(typeof(UG.UI.Button))
                if bComp then
                    bComp.onClick = UG.UI.Button.ButtonClickedEvent()
                    bComp.onClick:AddListener(function()
                        _G.HTPS_TogglePetFastSummon()
                    end)
                end
            end
            fitBtnRect(btnFast, 192, 178)
            btnFast.gameObject:SetActive(true)

            -- Sync 940 once per freshly opened PetSummon when petPieceList is empty so Library counts display cleanly
            if _G.HTPS_PET_LAST_SYNC_PS_GO ~= goRoot then
                _G.HTPS_PET_LAST_SYNC_PS_GO = goRoot
                local pdiNow = _G.PetDataItem and _G.PetDataItem:instance()
                local pcsEmpty = not pdiNow or not pdiNow.petPieceList or not pdiNow.petPieceList.listElement or #pdiNow.petPieceList.listElement == 0
                if pcsEmpty and not _G.HTPS_PET_SUMMON_RUNNING and not _G.HTPS_PET_SUMMON_LOCK then
                    CsCoroutine.start(function()
                        _G.HTPS_BONUS_SUPPRESS_UNTIL = UG.Time.realtimeSinceStartup + 1.5
                        _G.HTPS_PetSync940(false)
                        _G.HTPS_RefreshPetTargetButtonLabel()
                    end)
                end
            end

            -- Priority Target Pet Dropdown Button + Scrollable Popup
            local b10Txt = b10:GetComponentInChildren(typeof(UG.UI.Text), true)
            local gameFont = (b10Txt and b10Txt.font) or UG.Resources.GetBuiltinResource(typeof(UG.Font), "Arial.ttf")
            local frTf = tfContent:Find("Header/FieldResources")
            local frImg = frTf and frTf:GetComponent(typeof(UG.UI.Image))
            local spBoxField = (frImg and frImg.sprite and not frImg.sprite:Equals(nil)) and frImg.sprite
                or (_G.HTPS_FindNativeSprite and _G.HTPS_FindNativeSprite("box_field_1", false))

            local btnDrop = tfMain:Find("BtnHTPSPetTargetDrop")
            if not btnDrop then
                local dropGo = GO("BtnHTPSPetTargetDrop")
                dropGo.transform:SetParent(tfMain, false)
                local drt = dropGo:AddComponent(typeof(UG.RectTransform))
                drt.anchorMin = UG.Vector2(0.5, 0.0)
                drt.anchorMax = UG.Vector2(0.5, 0.0)
                drt.pivot = UG.Vector2(0.5, 0.0)
                drt.anchoredPosition = UG.Vector2(192, 92)
                drt.sizeDelta = UG.Vector2(242, 42)

                local dimg = dropGo:AddComponent(typeof(UG.UI.Image))
                if spBoxField then
                    dimg.sprite = spBoxField
                    dimg.type = UG.UI.Image.Type.Simple
                    dimg.color = UG.Color(1.0, 1.0, 1.0, 1.0)
                else
                    dimg.color = UG.Color(0.16, 0.12, 0.08, 0.96)
                end

                local dbc = dropGo:AddComponent(typeof(UG.UI.Button))
                dbc.targetGraphic = dimg

                local lblGo = GO("Label")
                lblGo.transform:SetParent(dropGo.transform, false)
                local lrt = lblGo:AddComponent(typeof(UG.RectTransform))
                lrt.anchorMin = UG.Vector2(0, 0)
                lrt.anchorMax = UG.Vector2(1, 1)
                lrt.offsetMin = UG.Vector2(12, 3)
                lrt.offsetMax = UG.Vector2(-28, -3)
                local ltxt = lblGo:AddComponent(typeof(UG.UI.Text))
                ltxt.font = gameFont
                ltxt.fontSize = 15
                ltxt.fontStyle = UG.FontStyle.Normal
                ltxt.alignment = UG.TextAnchor.MiddleCenter
                ltxt.resizeTextForBestFit = true
                ltxt.resizeTextMinSize = 10
                ltxt.resizeTextMaxSize = 15
                ltxt.color = UG.Color(0.99, 0.93, 0.72, 1.0)
                ltxt.text = "Mục tiêu: Tất cả SS"
                local lout = lblGo:AddComponent(typeof(UG.UI.Outline))
                lout.effectColor = UG.Color(0.12, 0.08, 0.04, 1.0)
                lout.effectDistance = UG.Vector2(1.0, -1.0)

                local arrGo = GO("Arrow")
                arrGo.transform:SetParent(dropGo.transform, false)
                local arrRt = arrGo:AddComponent(typeof(UG.RectTransform))
                arrRt.anchorMin = UG.Vector2(1, 0)
                arrRt.anchorMax = UG.Vector2(1, 1)
                arrRt.pivot = UG.Vector2(1, 0.5)
                arrRt.anchoredPosition = UG.Vector2(-8, 0)
                arrRt.sizeDelta = UG.Vector2(20, 0)
                local arrTxt = arrGo:AddComponent(typeof(UG.UI.Text))
                arrTxt.font = gameFont
                arrTxt.fontSize = 13
                arrTxt.alignment = UG.TextAnchor.MiddleCenter
                arrTxt.color = UG.Color(1.0, 0.85, 0.35, 1.0)
                arrTxt.text = "▼"
                local arrOut = arrGo:AddComponent(typeof(UG.UI.Outline))
                arrOut.effectColor = UG.Color(0.12, 0.08, 0.04, 1.0)
                arrOut.effectDistance = UG.Vector2(1.0, -1.0)

                btnDrop = dropGo.transform
                _G.HTPS_RefreshPetTargetButtonLabel()
            end
            btnDrop.gameObject:SetActive(true)

            local blkDrop = tfContent:Find("BlockerHTPSPetTargetDrop")
            if blkDrop and not blkDrop:Find("DimBg") then
                UG.Object.DestroyImmediate(blkDrop.gameObject)
                blkDrop = nil
            end
            if not blkDrop then
                local blkGo = GO("BlockerHTPSPetTargetDrop")
                blkGo.transform:SetParent(tfContent, false)
                local brt = blkGo:AddComponent(typeof(UG.RectTransform))
                brt.anchorMin = UG.Vector2(0, 0)
                brt.anchorMax = UG.Vector2(1, 1)
                brt.offsetMin = UG.Vector2(0, 0)
                brt.offsetMax = UG.Vector2(0, 0)

                local dimGo = GO("DimBg")
                dimGo.transform:SetParent(blkGo.transform, false)
                local drt = dimGo:AddComponent(typeof(UG.RectTransform))
                drt.anchorMin = UG.Vector2(0, 0)
                drt.anchorMax = UG.Vector2(1, 1)
                drt.offsetMin = UG.Vector2(-300, -300)
                drt.offsetMax = UG.Vector2(300, 300)
                local bimg = dimGo:AddComponent(typeof(UG.UI.Image))
                bimg.color = UG.Color(0, 0, 0, 0.42)
                local bbtn = dimGo:AddComponent(typeof(UG.UI.Button))
                bbtn.onClick:AddListener(function()
                    blkGo:SetActive(false)
                end)

                local boxGo = GO("BoxFrame")
                boxGo.transform:SetParent(blkGo.transform, false)
                local xrt = boxGo:AddComponent(typeof(UG.RectTransform))
                xrt.anchorMin = UG.Vector2(0.5, 0.0)
                xrt.anchorMax = UG.Vector2(0.5, 0.0)
                xrt.pivot = UG.Vector2(0.5, 0.0)
                xrt.anchoredPosition = UG.Vector2(105, 140)
                xrt.sizeDelta = UG.Vector2(420, 390)
                local ximg = boxGo:AddComponent(typeof(UG.UI.Image))
                ximg.color = UG.Color(0.78, 0.62, 0.25, 0.98)

                local innerGo = GO("InnerBg")
                innerGo.transform:SetParent(boxGo.transform, false)
                local irt = innerGo:AddComponent(typeof(UG.RectTransform))
                irt.anchorMin = UG.Vector2(0, 0)
                irt.anchorMax = UG.Vector2(1, 1)
                irt.offsetMin = UG.Vector2(2, 2)
                irt.offsetMax = UG.Vector2(-2, -2)
                local iimg = innerGo:AddComponent(typeof(UG.UI.Image))
                iimg.color = UG.Color(0.11, 0.09, 0.07, 0.98)
                local ibtn = innerGo:AddComponent(typeof(UG.UI.Button))
                ibtn.transition = UG.UI.Selectable.Transition.None

                local hdrGo = GO("Header")
                hdrGo.transform:SetParent(innerGo.transform, false)
                local hrt = hdrGo:AddComponent(typeof(UG.RectTransform))
                hrt.anchorMin = UG.Vector2(0, 1)
                hrt.anchorMax = UG.Vector2(1, 1)
                hrt.pivot = UG.Vector2(0.5, 1)
                hrt.anchoredPosition = UG.Vector2(0, -6)
                hrt.sizeDelta = UG.Vector2(-20, 30)
                local htxt = hdrGo:AddComponent(typeof(UG.UI.Text))
                htxt.font = gameFont
                htxt.fontSize = 16
                htxt.alignment = UG.TextAnchor.MiddleCenter
                htxt.color = UG.Color(1.0, 0.86, 0.42, 1.0)
                htxt.text = "Chọn Thú Ưu Tiên Nâng Max (SS trên)"
                local hout = hdrGo:AddComponent(typeof(UG.UI.Outline))
                hout.effectColor = UG.Color(0.05, 0.03, 0.02, 1.0)
                hout.effectDistance = UG.Vector2(1.0, -1.0)

                local vpGo = GO("Viewport")
                vpGo.transform:SetParent(innerGo.transform, false)
                local vprt = vpGo:AddComponent(typeof(UG.RectTransform))
                vprt.anchorMin = UG.Vector2(0, 0)
                vprt.anchorMax = UG.Vector2(1, 1)
                vprt.offsetMin = UG.Vector2(8, 8)
                vprt.offsetMax = UG.Vector2(-8, -38)
                local vpimg = vpGo:AddComponent(typeof(UG.UI.Image))
                vpimg.color = UG.Color(0.06, 0.05, 0.04, 0.92)
                vpGo:AddComponent(typeof(UG.UI.RectMask2D))

                local cntGo = GO("ListContent")
                cntGo.transform:SetParent(vpGo.transform, false)
                local crt = cntGo:AddComponent(typeof(UG.RectTransform))
                crt.anchorMin = UG.Vector2(0, 1)
                crt.anchorMax = UG.Vector2(1, 1)
                crt.pivot = UG.Vector2(0.5, 1)
                crt.anchoredPosition = UG.Vector2(0, 0)
                crt.sizeDelta = UG.Vector2(0, 0)

                local vlg = cntGo:AddComponent(typeof(UG.UI.VerticalLayoutGroup))
                vlg.childControlWidth = true
                vlg.childControlHeight = true
                vlg.childForceExpandWidth = true
                vlg.childForceExpandHeight = false
                vlg.spacing = 4
                vlg.padding = UG.RectOffset(6, 6, 6, 6)

                local csf = cntGo:AddComponent(typeof(UG.UI.ContentSizeFitter))
                csf.verticalFit = UG.UI.ContentSizeFitter.FitMode.PreferredSize

                local sr = vpGo:AddComponent(typeof(UG.UI.ScrollRect))
                sr.content = crt
                sr.viewport = vprt
                sr.horizontal = false
                sr.vertical = true
                sr.movementType = UG.UI.ScrollRect.MovementType.Clamped
                sr.scrollSensitivity = 28

                blkGo:SetActive(false)
                blkDrop = blkGo.transform
            end

            if _G.HTPS_BOUND_PET_TARGET_DROP_BTN ~= btnDrop then
                local dbc = btnDrop:GetComponent(typeof(UG.UI.Button))
                if dbc then
                    dbc.onClick:RemoveAllListeners()
                    dbc.onClick:AddListener(function()
                        _G.HTPS_TogglePetTargetDropdown()
                    end)
                end
                _G.HTPS_BOUND_PET_TARGET_DROP_BTN = btnDrop
                _G.HTPS_RefreshPetTargetButtonLabel()
            end

            if _G.HTPS_BOUND_PET_FAST_SUMMON_BTN ~= btnFast then
                _G.HTPS_BOUND_PET_FAST_SUMMON_BTN = btnFast
            end
            _G.HTPS_UpdatePetSummonBtnUI()
        end)
    end

    _G.HTPS_UpdatePetAwakenBtnUI = function()
        pcall(function()
            local btnTf = _G.HTPS_BOUND_PET_AWAKEN_BTN
            if not btnTf or btnTf:Equals(nil) then return end
            local label = btnTf:GetComponentInChildren(typeof(UG.UI.Text), true)
            if label then
                label.horizontalOverflow = UG.HorizontalWrapMode.Wrap
                label.verticalOverflow = UG.VerticalWrapMode.Truncate
                label.alignment = UG.TextAnchor.MiddleCenter
            end
            if _G.HTPS_PET_AWAKEN_RUNNING then
                local st = (_G.HTPS_PET_AWAKEN_STATUS and _G.HTPS_PET_AWAKEN_STATUS ~= "") and _G.HTPS_PET_AWAKEN_STATUS or "Đang nâng..."
                _G.HTPS_ApplyNativePetBtnStyle(btnTf, "Dừng (" .. st .. ")", false)
                return
            end
            local livePI = _G.HTPS_GetLivePetInventory()
            local isAlreadyMax = false
            if livePI and livePI.petPanelAwaken and livePI.petPanelAwaken.currentPet then
                local cp = livePI.petPanelAwaken.currentPet
                local pldb = _G.PetLoadDb and _G.PetLoadDb:getInstance()
                local maxSt = pldb and pldb:GetMaxStar() or 10
                if (cp.star or 0) >= maxSt then
                    isAlreadyMax = true
                end
            end
            _G.HTPS_ApplyNativePetBtnStyle(btnTf, isAlreadyMax and "Đã đạt sao tối đa" or "Auto Thức Tỉnh", true)
        end)
    end

    _G.HTPS_ToggleAutoPetAwaken = function()
        if _G.HTPS_PET_AWAKEN_RUNNING then
            _G.HTPS_PET_AWAKEN_RUNNING = false
            _G.HTPS_UpdatePetAwakenBtnUI()
            return
        end
        if _G.HTPS_PET_AWAKEN_LOCK then return end
        local livePI = _G.HTPS_GetLivePetInventory()
        if not livePI then return end
        local panelPetId = livePI.petPanelAwaken and livePI.petPanelAwaken.currentPet and livePI.petPanelAwaken.currentPet.petId
        local targetPetId = (panelPetId and panelPetId > 0) and panelPetId or livePI.currentPetId
        if not targetPetId or targetPetId <= 0 then return end
        livePI.currentPetId = targetPetId

        _G.HTPS_PET_AWAKEN_LOCK = true
        _G.HTPS_PET_AWAKEN_RUNNING = true
        _G.HTPS_PET_AWAKEN_STATUS = "Đang đồng bộ..."
        _G.HTPS_UpdatePetAwakenBtnUI()

        CsCoroutine.start(function()
            local finishMsg = nil
            local okAll, errAll = pcall(function()
                local ops = _G.HTPS_PetCreateOps(
                    function() return _G.HTPS_PET_AWAKEN_RUNNING end,
                    function(skipUi)
                        local synced = _G.HTPS_PetSync940(not skipUi, skipUi)
                        if not skipUi then _G.HTPS_UpdatePetAwakenBtnUI() end
                        return synced
                    end,
                    true,
                    1000
                )
                ops.useAllLowerFodder = true
                ops.onProgress = function(text)
                    local pet = ops.getPetById(targetPetId)
                    _G.HTPS_PET_AWAKEN_STATUS = string.format("%d★ → %d★\n%s", pet and pet.star or 0, ops.maxStar, text)
                    _G.HTPS_UpdatePetAwakenBtnUI()
                end
                ops.syncNow(true)
                local target = ops.getPetById(targetPetId)
                if not target then finishMsg = "Không tìm thấy thú cưng!"; return end

                -- Phase 1: Upgrade Stars up to ops.maxStar (10).
                -- 0* slots strictly use target.setId (+ library); 5*/6*/9* fodder uses 3-tier pool (D..A -> S excess keeping 1 highest -> redundant 5* SS clones).
                while _G.HTPS_PET_AWAKEN_RUNNING and target and (target.star or 0) < ops.maxStar do
                    local nextSt = (target.star or 0) + 1
                    _G.HTPS_PET_AWAKEN_STATUS = string.format("%d/%d★", nextSt, ops.maxStar)
                    _G.HTPS_UpdatePetAwakenBtnUI()

                    local okStep, reasonMsg = ops.execStarStep(targetPetId)
                    target = ops.getPetById(targetPetId)
                    pcall(function()
                        local current = livePI.petPanelAwaken and livePI.petPanelAwaken.currentPet
                        if target and current and current.petId == targetPetId and not livePI.disposed then
                            livePI.petPanelAwaken:SetPetData(target)
                        end
                    end)
                    if not okStep then
                        finishMsg = string.format("Dừng ở %d★: %s", target and target.star or 0, reasonMsg or "Thiếu nguyên liệu")
                        break
                    end
                end

                target = ops.getPetById(targetPetId)
                pcall(function()
                    local eqHero = ops.pdi:GetPetEquipped(targetPetId)
                    if eqHero and eqHero > 0 and ops.gc and ops.gc.dataSender then
                        ops.gc.dataSender:HeroRequestInfo(eqHero)
                    end
                end)
                if not finishMsg and target then
                    if not _G.HTPS_PET_AWAKEN_RUNNING then
                        finishMsg = string.format("Đã dừng ở %d★", target.star or 0)
                    elseif (target.star or 0) >= ops.maxStar then
                        finishMsg = string.format("Đã thức tỉnh tối đa %d★!", target.star or 0)
                    else
                        finishMsg = string.format("Đã thức tỉnh tới %d★!", target.star or 0)
                    end
                end
            end)

            _G.HTPS_PET_AWAKEN_RUNNING = false
            _G.HTPS_PET_AWAKEN_STATUS = ""
            _G.HTPS_BONUS_SUPPRESS_UNTIL = UG.Time.realtimeSinceStartup + 0.5
            pcall(function() _G.HTPS_PetSync940(true) end)
            _G.HTPS_UpdatePetAwakenBtnUI()
            _G.HTPS_PET_AWAKEN_LOCK = false
            if not okAll and errAll then
                pcall(function() CS.Toast.ShowToast("Lỗi Auto Thức Tỉnh: " .. tostring(errAll)) end)
            elseif finishMsg and finishMsg ~= "" then
                pcall(function() CS.Toast.ShowToast(finishMsg) end)
            end
        end)
    end

    _G.HTPS_EnsurePetAwakenButtons = function()
        if not _G.HTPS_AUTO_ACTIVATED then return end
        pcall(function()
            local piGo = GO.Find("PetInventory(Clone)")
            if not piGo or not piGo.activeInHierarchy then return end
            local paTf = piGo.transform:Find("Content/Main/BoxInfo/TabContent/PanelAwaken")
            if not paTf or not paTf.gameObject.activeInHierarchy then return end

            local frmUp = paTf:Find("FrameUpgrade")
            local awBtn = frmUp and frmUp:Find("AwakenButton")
            if not awBtn then return end

            local upActive = frmUp.gameObject.activeSelf
            local rtAw = awBtn:GetComponent(typeof(UG.RectTransform))
            if rtAw and upActive then
                rtAw.anchoredPosition = UG.Vector2(-92, -160)
                rtAw.sizeDelta = UG.Vector2(166, 66)
            end

            local btnAuto = paTf:Find("BtnHTPSAutoPetAwaken")
            if not btnAuto then
                local clone = GO.Instantiate(awBtn.gameObject, paTf, false)
                clone.name = "BtnHTPSAutoPetAwaken"
                btnAuto = clone.transform
                local bComp = clone:GetComponent(typeof(UG.UI.Button))
                if bComp then
                    bComp.onClick = UG.UI.Button.ButtonClickedEvent()
                    bComp.onClick:AddListener(function()
                        _G.HTPS_ToggleAutoPetAwaken()
                    end)
                end
            end

            btnAuto.gameObject:SetActive(true)
            btnAuto:SetAsLastSibling()
            local rtAuto = btnAuto:GetComponent(typeof(UG.RectTransform))
            if rtAuto then
                rtAuto.anchorMin = UG.Vector2(0.5, 0.5)
                rtAuto.anchorMax = UG.Vector2(0.5, 0.5)
                rtAuto.pivot = UG.Vector2(0.5, 0.5)
                if upActive then
                    rtAuto.anchoredPosition = UG.Vector2(92, -160)
                    rtAuto.sizeDelta = UG.Vector2(174, 66)
                else
                    rtAuto.anchoredPosition = UG.Vector2(0, -160)
                    rtAuto.sizeDelta = UG.Vector2(198, 66)
                end
            end

            if _G.HTPS_BOUND_PET_AWAKEN_BTN ~= btnAuto then
                _G.HTPS_BOUND_PET_AWAKEN_BTN = btnAuto
            end
            _G.HTPS_UpdatePetAwakenBtnUI()
        end)
    end

    if not _G.HTPS_UI_WATCHER_STARTED then
        _G.HTPS_UI_WATCHER_STARTED = true
        CsCoroutine.start(function()
            coroutine.yield(UG.WaitForSecondsRealtime(0.25))
            while true do
                -- 2. ONLY INJECT AUTO BUTTONS IF ACTIVATED
                if _G.HTPS_AUTO_ACTIVATED then
                    _G.HTPS_RefreshModUI()
                end

                coroutine.yield(UG.WaitForSecondsRealtime(0.25))
            end
        end)
    end

    print("=== HTPS AUTO AGENT LOADED OK ===")
end

print('HTDC_REBUILD READY 20261115')
end
-- Extend the game's two fruit wheels after the paid feature module is loaded.
do
    local U = CS.UnityEngine
    local A = {panels = {}, installed = false, pending = nil, running = nil}
    _G.VinhFruitAuto = A
    _G.HTPS_FRUIT_WHEEL_RUNNING = false

    local function scope()
        local context = CS.GameContext.GetIntance()
        local server = context and context.m_ServerGame
        if not context or not server or context.m_UserId <= 0 then return end
        return tostring(context.m_UserId)..'/'..tostring(server.m_ServerId)
    end

    local function shown(panel)
        return panel and not panel.disposed and panel.goRoot
            and not panel.goRoot:Equals(nil) and panel.goRoot.activeInHierarchy
    end

    local function permitted()
        return _G.VinhLuaGate and _G.VinhLuaGate.allowed()
    end

    local function setText(label, text)
        if label and label.text ~= text then label.text = text end
    end

    local function updateButtons(panel)
        if not shown(panel) or not panel.vinhAutoButton then return end
        local run = A.running
        local active = run and run.panel == panel and _G.HTPS_FRUIT_WHEEL_RUNNING
        local label = active and ('Dừng · '..run.done..' lượt') or 'Tự quay'
        if active and A.pending and U.Time.realtimeSinceStartup-A.pending.at >= 8 then
            label = 'Chờ phản hồi · Dừng'
        end
        setText(panel.vinhAutoLabel, label)
        panel.vinhAutoButton.interactable = active or not A.pending and not run
        local locked = run and run.panel == panel or A.pending and A.pending.panel == panel
        if locked and not panel.vinhManualState and panel.btnRoll1 and panel.btnRoll10 then
            panel.vinhManualState = {panel.btnRoll1.interactable,panel.btnRoll10.interactable}
            panel.btnRoll1.interactable,panel.btnRoll10.interactable = false,false
        elseif not locked and panel.vinhManualState then
            panel.btnRoll1.interactable,panel.btnRoll10.interactable = panel.vinhManualState[1],panel.vinhManualState[2]
            panel.vinhManualState = nil
        end
        if panel.vinhSkipButton then
            panel.vinhSkipButton.interactable = not run and not A.pending
            local skip = panel.fruitWheel and panel.fruitWheel:isSkippingOn()
            setText(panel.vinhSkipLabel, (skip and '✓ ' or '□ ')..'Bỏ hoạt ảnh')
        end
    end

    local function summary(run, message)
        local lines = {message, 'Đã quay '..run.done..' lượt'}
        local keys = {}
        for key in pairs(run.rewards) do keys[#keys+1] = key end
        table.sort(keys)
        for _,key in ipairs(keys) do
            local item = run.rewards[key]
            lines[#lines+1] = item.name..' × '..item.amount
        end
        if run.other > 0 then lines[#lines+1] = 'Vật phẩm khác đã nhận × '..run.other end
        CS.PopupMessage.ShowUp(table.concat(lines, '\n'))
    end

    local function refresh(run)
        if not shown(run.panel) or scope() ~= run.scope then return end
        FFDataSender:instance():GetWheelStatus(run.panel.mode)
        local data = FFDataItem and FFDataItem._instance
        if data and data.ffRoot then data.ffRoot:OnTabRefresh(true) end
    end

    function A.stop(message)
        local run = A.running
        if not run then return end
        _G.HTPS_FRUIT_WHEEL_RUNNING = false
        A.running = nil
        if A.pending then A.pending.stopped = true end
        if A.pending and A.pending.scope ~= scope() then A.pending = nil end
        updateButtons(run.panel)
        if scope() == run.scope then
            if A.pending then
                CS.Toast.ShowToast('Đã dừng gửi lượt mới. Lượt vừa gửi còn chờ game xác nhận.')
            else
                refresh(run)
                summary(run, message or 'Đã dừng')
            end
        end
        print('VinhFruitAuto stop mode='..run.panel.mode..' confirmed='..run.done..' pending='..tostring(A.pending ~= nil))
    end

    local function reward(run, key, name, amount)
        local entry = run.rewards[key]
        if not entry then entry = {name = name, amount = 0}; run.rewards[key] = entry end
        entry.amount = entry.amount + amount
    end

    local function applyResult(panel, packet, updateData)
        local pending = A.pending
        if not pending or pending.panel ~= panel then return false end
        if pending.applied or pending.scope ~= scope() then return true end
        local received = packet and packet.aVector and tonumber(packet.aVector.Count)
        if not received or received < 2 or received > pending.count+1 then
            error('Fruit result count does not match the request')
        end
        -- Mark before applying data so a failed UI callback cannot apply it twice.
        pending.applied = true
        local run = pending.run
        for index = 1,packet.aVector.Count-1 do
            local row = packet.aVector[index].aLong
            local kind = tonumber(row[2])
            if kind == 1 or kind == 2 then
                local data = FFDataItem:instance():GetFruitById(row[4])
                if data then
                    if kind == 1 then
                        if updateData then
                            data.id,data.owned = row[3],row[5] == 1
                            data.current, data.star, data.level = row[6],row[7],row[8]
                            if FFDataItem:instance().ffRoot then FFDataItem:instance().ffRoot.hasUpgrade = true end
                        end
                        reward(run, 'fruit/'..data.fruitId, data.name or 'Trái ác quỷ', 1)
                    else
                        if updateData then data.id,data.current = row[3],row[5] end
                        reward(run, 'shard/'..data.fruitId, 'Mảnh '..(data.name or 'Trái ác quỷ'), tonumber(row[6]) or 0)
                    end
                end
            elseif kind == 3 then
                local bonus = CS.BonusModel.ParseBonusReceived(row:GetRange(3,row.Count-3),updateData)
                local items = bonus and bonus:ToListModelObject()
                if items then
                    for i = 0,items.Count-1 do run.other = run.other + (tonumber(items[i].m_Number) or 1) end
                end
            end
        end
        run.done = run.done + received-1
        if pending.batch then
            pending.batch.confirmed = pending.batch.confirmed + received-1
            pending.batch.receipts = pending.batch.receipts + 1
            A.pending = pending.batch
            return true
        end
        A.pending = nil
        run.nextAt = U.Time.realtimeSinceStartup + .04
        print('VinhFruitAuto confirmed mode='..panel.mode..' batch='..(received-1)..' total='..run.done)
        if pending.stopped or not _G.HTPS_FRUIT_WHEEL_RUNNING then
            refresh(run)
            if shown(panel) then summary(run, 'Đã nhận kết quả lượt cuối') end
        end
        return true
    end

    local function sendBatch(run, have, fee)
        local panel = run.panel
        local turns = math.floor(have/fee)
        local counts,specs = {},{}
        local action = panel.mode == 1 and FFDataSender.FRUIT_NORMAL_WHEEL_ROLL
            or FFDataSender.FRUIT_SPECIAL_WHEEL_ROLL
        if turns >= 10 then
            for i = 1,math.min(25,math.floor(turns/10)) do
                counts[i] = 10
                specs[i] = {id = action, vals = {10}}
            end
        else
            for i = 1,turns do
                counts[i] = 1
                specs[i] = {id = action, vals = {1}}
            end
        end
        if #counts == 0 then return end
        local pending = {run = run, panel = panel, scope = run.scope, at = U.Time.realtimeSinceStartup,
            confirmed = 0, receipts = 0}
        A.pending = pending
        print('VinhFruitAuto batch send mode='..panel.mode..' actions='..#counts..' perAction='..counts[1])
        local results,message = _G.HTPS_PetSendActs(action,specs)
        if A.pending ~= pending or scope() ~= run.scope then
            if A.pending == pending then A.pending = nil end
            if A.running == run then A.stop('Đã đổi tài khoản') end
            return
        end
        if not results then
            A.stop(message or 'Chưa nhận được kết quả đợt quay')
            return
        end
        local yieldAt = U.Time.realtimeSinceStartup + .004
        for _,response in ipairs(results) do
            if scope() ~= run.scope then
                A.pending = nil
                if A.running == run then A.stop('Đã đổi tài khoản') end
                return
            end
            if response.actionId == action and response.data then
                local count = counts[pending.receipts+1]
                if not count then
                    A.stop('Số phản hồi vượt đợt đã gửi. Kiểm tra lại kho.')
                    return
                end
                local packet = _G.HTPS_DeserializeProto(response.data,'pbdson.ListCommonVector,PbMethodLib')
                if not packet or not packet.aVector or packet.aVector.Count < 2 or packet.aVector.Count > count+1 then
                    A.stop('Phản hồi đợt quay chưa đầy đủ. Kiểm tra lại kho.')
                    return
                end
                local receipt = {run = run, panel = panel, scope = run.scope, count = count, batch = pending}
                A.pending = receipt
                -- Use the same cost and reward parsers as the game's wheel response.
                local ok = pcall(function()
                    CS.BonusModel.ParseBonusReceived(packet.aVector[0].aLong)
                    applyResult(panel,packet,true)
                end)
                if not ok then
                    A.pending = pending
                    A.stop('Chưa đọc đủ phần thưởng. Kiểm tra lại trong kho.')
                    return
                end
                if U.Time.realtimeSinceStartup >= yieldAt then
                    coroutine.yield(U.WaitForSecondsRealtime(0))
                    yieldAt = U.Time.realtimeSinceStartup + .004
                end
            end
        end
        print('VinhFruitAuto batch received mode='..panel.mode..' actions='..pending.receipts..'/'..#counts..' confirmed='..pending.confirmed)
        if shown(panel) then panel:reloadAmount() end
        if pending.receipts ~= #counts then
            A.stop(message or 'Đợt quay chưa trả đủ kết quả. Chưa gửi lại lượt cũ.')
            return
        end
        A.pending = nil
        run.nextAt = U.Time.realtimeSinceStartup + .04
        if pending.stopped or not _G.HTPS_FRUIT_WHEEL_RUNNING then
            refresh(run)
            if shown(panel) then summary(run,'Đã nhận kết quả đợt cuối') end
        elseif message then
            A.stop(message)
        end
    end

    local function busy()
        if _G.HTPS_AUTO and _G.HTPS_AUTO.running then return true end
        if _G.HTPS_CAMPAIGN_BUSY then return true end
        for name,value in pairs(_G) do
            if type(name) == 'string' and name ~= 'HTPS_FRUIT_WHEEL_RUNNING' and name ~= 'HTPS_CAMPAIGN_RUNNING'
                and name:match('^HTPS_.*_RUNNING$') and value == true then return true end
        end
    end

    function A.toggle(panel)
        if A.running then A.stop('Đã dừng'); return end
        if not permitted() then _G.VinhLuaGate.open(); return end
        if not shown(panel) or not scope() then return end
        if A.pending then CS.Toast.ShowToast('Lượt trước còn chờ xác nhận. Chưa gửi thêm lượt.'); return end
        if busy() then CS.Toast.ShowToast('Dừng auto đang chạy trước.'); return end
        local run = {panel = panel, scope = scope(), done = 0, other = 0, rewards = {}, nextAt = 0}
        A.running = run
        _G.HTPS_FRUIT_WHEEL_RUNNING = true
        CsCoroutine.start(function()
            while A.running == run and _G.HTPS_FRUIT_WHEEL_RUNNING do
                if not permitted() or scope() ~= run.scope or not shown(panel) then
                    A.stop('Đã rời vòng quay hoặc đổi tài khoản'); break
                end
                local now = U.Time.realtimeSinceStartup
                if A.pending then
                    local pending = A.pending
                    if pending.popup and shown(pending.popup) then
                        local close = pending.popup.btnBack
                        local character = U.GameObject.Find('FFPopupSummon(Clone)')
                        if character then
                            local node = character.transform:Find('Bgr')
                            local control = node and node:GetComponent(typeof(U.UI.Button))
                            if control and control.isActiveAndEnabled and control:IsInteractable() then control.onClick:Invoke() end
                        elseif close and close.gameObject.activeInHierarchy and close:IsInteractable() and not pending.closed then
                            pending.closed = true;close.onClick:Invoke()
                        end
                    end
                    if now-pending.at >= 15 and not pending.readSent then
                        pending.readSent = true
                        FFDataSender:instance():GetWheelStatus(panel.mode)
                        print('VinhFruitAuto read-only recheck mode='..panel.mode)
                    end
                    if now-pending.at >= 60 then A.stop('Game chưa trả kết quả lượt cuối'); break end
                elseif now >= run.nextAt then
                    local inventory = CS.PlayerInventory.GetInstance()
                    local fee = tonumber(panel.item_amount)
                    local key = tonumber(panel.item_key)
                    local have = key and inventory and tonumber(inventory:GetNumberItemConsumable(key))
                    if not have or not fee or fee < 1 then A.stop('Chưa đọc được vé và chi phí'); break end
                    local count = have >= fee*10 and 10 or have >= fee and 1 or 0
                    if count == 0 then A.stop('Đã hết vé quay'); break end
                    local network = NetworkController:instance()
                    if not network.requestInFlight then
                        local skip = panel.fruitWheel and panel.fruitWheel:isSkippingOn()
                        if skip and type(_G.HTPS_PetSendActs) == 'function' then
                            local ok = pcall(sendBatch,run,have,fee)
                            if not ok then A.stop('Chưa xử lý được đợt quay. Kiểm tra lại kho.'); break end
                        else
                            A.pending = {run = run, panel = panel, scope = run.scope, count = count, at = now}
                            local ok = pcall(function() FFDataSender:instance():WheelRoll(panel.mode,count) end)
                            if not ok then A.stop('Chưa gửi được lượt quay'); break end
                        end
                    end
                end
                updateButtons(panel)
                coroutine.yield(U.WaitForSecondsRealtime(.04))
            end
            if A.running == run then A.stop('Đã dừng') end
        end)
        updateButtons(panel)
    end

    local function cloneButton(panel, name, label, x)
        local source = panel.btnRoll10.gameObject
        local node = U.Object.Instantiate(source,source.transform.parent,false)
        node.name = name
        local rect = node:GetComponent(typeof(U.RectTransform))
        rect.anchorMin,rect.anchorMax,rect.pivot = U.Vector2(.5,0),U.Vector2(.5,0),U.Vector2(.5,.5)
        rect.anchoredPosition,rect.sizeDelta = U.Vector2(x,75),U.Vector2(220,36)
        rect.localScale = U.Vector3.one
        local icon = node.transform:Find('Icon')
        if icon then icon.gameObject:SetActive(false) end
        local labels = node:GetComponentsInChildren(typeof(U.UI.Text),true)
        local text
        for i = 0,labels.Length-1 do
            local candidate = labels[i]
            if candidate.gameObject.activeInHierarchy then text = candidate; break end
        end
        if text then
            text.text,text.fontSize,text.alignment = label,20,U.TextAnchor.MiddleCenter
            local localizer = text.gameObject:GetComponent(typeof(CS.I2.Loc.Localize))
            if localizer then U.Object.Destroy(localizer) end
            local checker = text.gameObject:GetComponent(typeof(CS.TextLocalizeChecker))
            if checker then U.Object.Destroy(checker) end
            local textRect = text:GetComponent(typeof(U.RectTransform))
            textRect.anchorMin,textRect.anchorMax = U.Vector2.zero,U.Vector2.one
            textRect.offsetMin,textRect.offsetMax = U.Vector2(6,3),U.Vector2(-6,-3)
        end
        local control = node:GetComponent(typeof(U.UI.Button))
        control.onClick = U.UI.Button.ButtonClickedEvent()
        node:SetActive(true)
        return control,text
    end

    local function ensure(panel)
        if not shown(panel) or not permitted() then return end
        if not panel.vinhAutoButton then
            panel.vinhAutoButton,panel.vinhAutoLabel = cloneButton(panel,'VinhFruitAuto','Tự quay',-116)
            panel.vinhAutoButton.onClick:AddListener(function() A.toggle(panel) end)
            panel.vinhSkipButton,panel.vinhSkipLabel = cloneButton(panel,'VinhFruitSkip','Bỏ hoạt ảnh',116)
            panel.vinhSkipButton.onClick:AddListener(function()
                local wheel = panel.fruitWheel
                if wheel and wheel.toggleSkip and not A.running and not A.pending then
                    wheel.toggleSkip.isOn = not wheel.toggleSkip.isOn
                    CS.UnityEngine.PlayerPrefs.SetInt('KEY_SKIP_FRUIT_WHEEL',wheel.toggleSkip.isOn and 1 or 0)
                    updateButtons(panel)
                end
            end)
        end
        updateButtons(panel)
    end

    local function install()
        if A.installed then return end
        if not FFPanelWheel or not FFPanelWheel.initUI or not FFPanelWheel.spinEffect then return end
        A.installed = true
        local init,spin,dispose = FFPanelWheel.initUI,FFPanelWheel.spinEffect,FFPanelWheel.dispose
        local showLoading,hideLoading = FFPanelWheel.showLoadingPanel,FFPanelWheel.hideLoadingPanel
        function FFPanelWheel:showLoadingPanel(...)
            if A.pending and A.pending.panel == self then return end
            return showLoading(self,...)
        end
        function FFPanelWheel:hideLoadingPanel(...)
            if A.pending and A.pending.panel == self then return end
            return hideLoading(self,...)
        end
        local createPopup = FFPopupShowBonusEffectFruit.new
        function FFPopupShowBonusEffectFruit:new(...)
            local popup = createPopup(self,...)
            local pending = A.pending
            if pending and pending.rendering and pending.scope == scope() then
                pending.popup = popup
                local setClose = popup.CloseFunc
                popup.CloseFunc = function(p,callback)
                    return setClose(p,function()
                        callback()
                        if A.pending == pending then
                            local ok = pcall(applyResult,pending.panel,pending.packet,false)
                            if not ok then A.stop('Chưa đọc đủ phần thưởng. Kiểm tra lại trong kho.') end
                        end
                    end)
                end
            end
            return popup
        end
        function FFPanelWheel:initUI(...)
            init(self,...)
            A.panels[self] = true
            ensure(self)
        end
        function FFPanelWheel:spinEffect(packet)
            local pending = A.pending
            if pending and pending.panel == self then
                local skip = self.fruitWheel and self.fruitWheel:isSkippingOn()
                if skip then
                    local ok = pcall(applyResult,self,packet,true)
                    if not ok then
                        A.stop('Chưa đọc đủ phần thưởng. Kiểm tra lại trong kho.')
                        print('VinhFruitAuto reward decode failed')
                    end
                    return
                end
                pending.rendering = true
                pending.packet = packet
            end
            return spin(self,packet)
        end
        function FFPanelWheel:dispose(...)
            if A.running and A.running.panel == self then A.stop('Đã rời vòng quay') end
            A.panels[self] = nil
            return dispose(self,...)
        end
        local data = FFDataItem and FFDataItem._instance
        local wheel = data and data.ffRoot and data.ffRoot.tabFruitWheel
        for _,key in ipairs({'wheelNormal','wheelSpecial'}) do
            local panel = wheel and wheel[key]
            if panel then A.panels[panel] = true end
        end
    end

    local original = _G.HTPS_EnsureSpecialEquipButtons
    _G.HTPS_EnsureSpecialEquipButtons = function(...)
        if original then original(...) end
        install()
        for panel in pairs(A.panels) do
            if panel.disposed or not panel.goRoot or panel.goRoot:Equals(nil) then A.panels[panel] = nil
            else ensure(panel) end
        end
    end
end

do
    local U = CS.UnityEngine
    local active
    local installed
    _G.HTPS_FRUIT_UPGRADE_RUNNING = false

    local function visible(object)
        return object and not object:Equals(nil) and object.activeInHierarchy
    end

    local function allowed()
        return _G.VinhLuaGate and _G.VinhLuaGate.allowed()
    end

    local function scope()
        local context = CS.GameContext.GetIntance()
        local server = context and context.m_ServerGame
        if server and context.m_UserId > 0 then
            return tostring(context.m_UserId)..'/'..tostring(server.m_ServerId)
        end
    end

    local function otherAutoRunning()
        local wheel = _G.VinhFruitAuto
        if wheel and wheel.pending then return true end
        if _G.HTPS_CAMPAIGN_BUSY or (_G.HTPS_AUTO and _G.HTPS_AUTO.running) then return true end
        for name,value in pairs(_G) do
            if type(name)=='string' and value==true and name~='HTPS_CAMPAIGN_RUNNING'
                and name:match('^HTPS_.*_RUNNING$') then return true end
        end
        return false
    end

    local function state(fruit,mode)
        if not fruit or not fruit.owned then return end
        local db = FFDbManager:instance()
        if mode == 1 then return tonumber(fruit.level),tonumber(db.maxUpgrade) end
        if mode == 2 then return tonumber(fruit.star),tonumber(db.maxStar) end
    end

    local function gameBusy()
        local network = NetworkController:instance()
        return network.requestInFlight or network.listPbSendingQueue:count()>0
    end

    local function checkCost(fruit,mode,nextValue)
        local db = FFDbManager:instance()
        local amounts = {}
        local function add(list)
            local items = CS.BonusModel.ParseBonusPreview(list):ToListModelObject()
            for i=0,items.Count-1 do
                local item = items[i]
                local key,needed = tonumber(item.m_ItemKey),tonumber(item.m_Number)
                assert(key and needed and needed>=0)
                amounts[key] = (amounts[key] or 0)+needed
            end
        end
        if mode == 1 then
            local fee = db:GetFeeUpgradeLevel(fruit.rank,nextValue)
            if not fee or tonumber(fee.level)~=nextValue or fee.item.Count+fee.gold.Count==0 then
                return 'Chưa đọc được chi phí cường hóa.'
            end
            add(fee.item)
            add(fee.gold)
        else
            local fee = db:GetFeeUpgradeStar(fruit.rank,nextValue)
            local sameShard = fee and tonumber(fee.sameShard)
            if not fee or tonumber(fee.star)~=nextValue or not sameShard or sameShard<0
                or (sameShard==0 and fee.item.Count==0) then return 'Chưa đọc được chi phí nâng sao.' end
            if sameShard>0 then
                local owned = tonumber(fruit.current)
                if not owned then return 'Chưa đọc được số mảnh.' end
                if owned<sameShard then return 'Thiếu '..(sameShard-owned)..' mảnh cùng loại.' end
            end
            add(fee.item)
        end
        local inventory = CS.PlayerInventory.GetInstance()
        for key,needed in pairs(amounts) do
            local have = tonumber(inventory:GetNumberItemConsumable(key))
            if not have then return 'Chưa đọc được nguyên liệu trong kho.' end
            if have<needed then return 'Thiếu nguyên liệu cho mốc tiếp theo.' end
        end
    end

    local function render(owner,batch)
        local controls = owner.vinhFruitUpgrade
        if not controls or not visible(owner.goRoot) then return end
        local run = active and active.owner==owner and active or nil
        local label = batch and 'Nâng tất cả' or 'Tự nâng'
        if run then
            label = 'Dừng · '..run.confirmed
            if run.stopped then label = 'Đã dừng' end
        end
        if controls.buttonText.text~=label then controls.buttonText.text=label end
        local canStart = not active and not controls.uncertain
        if not batch then
            local current,maximum = state(owner.fruitData,owner.mode)
            canStart = canStart and current and maximum and current<maximum
        end
        local enabled = (run and not run.stopped) or canStart or false
        if controls.button.interactable~=enabled then controls.button.interactable=enabled end
    end

    local function finish(run,message,uncertain)
        if active~=run then return end
        active = nil
        _G.HTPS_FRUIT_UPGRADE_RUNNING = false
        if visible(run.owner.goRoot) then
            for button,enabled in pairs(run.manual) do button.interactable=enabled end
            run.owner.vinhFruitUpgrade.uncertain = uncertain
            if run.batch and not uncertain and FFDataItem._instance==run.data and scope()==run.scope then
                run.data.currentFruit = run.previousFruit
                run.owner:loadCurrentFruit()
            end
            render(run.owner,run.batch)
        end
        if message and scope()==run.scope then CS.Toast.ShowToast(message) end
    end

    local function sendStep(run,fruit)
        local container = NetworkController:instance().loadingContainer
        local showLoading
        if type(container)=='table' and type(container.showLoadingPanel)=='function' then
            -- The network controller can still point at a wheel tab after returning to the list.
            -- Suppress only the overlay opened synchronously when this auto step is queued.
            showLoading = rawget(container,'showLoadingPanel')
            container.showLoadingPanel = function()end
        else
            container = nil
        end
        local ok,message = pcall(function()
            if run.batch then
                run.data.currentFruit = fruit
                run.data.blockUpgrade = true
                local sender = FFDataSender:instance()
                if run.mode==1 then sender:FruitLevelUp(fruit.fruitId) else sender:FruitStarUp(fruit.fruitId) end
            else
                run.owner.btnToDo.onClick:Invoke()
            end
        end)
        if container then container.showLoadingPanel = showLoading end
        if not ok then error(message) end
    end

    local function tick(run)
        local owner = run.owner
        local now = U.Time.realtimeSinceStartup
        if not allowed() or scope()~=run.scope then
            finish(run,nil,run.pending~=nil)
            return
        end
        local data = FFDataItem._instance
        if not visible(owner.goRoot) or data~=run.data or (run.batch and data.ffUpgrade)
            or (not run.batch and (data.ffUpgrade~=owner or owner.fruitData.fruitId~=run.fruitId or owner.mode~=run.mode)) then
            finish(run,nil,run.pending~=nil)
            return
        end
        if run.pending then
            local pending = run.pending
            local fruit = data:GetFruitById(pending.fruitId)
            local current = state(fruit,pending.mode)
            if current==pending.previous+1 then
                run.pending = nil
                run.confirmed = run.confirmed+1
                run.readyAt = now
                render(owner,run.batch)
            elseif now>=pending.deadline then
                finish(run,'Chưa xác nhận lượt nâng cuối. Mở lại bảng để kiểm tra.',true)
                return
            else
                return
            end
        end
        if run.stopped or not _G.HTPS_FRUIT_UPGRADE_RUNNING then
            finish(run,'Đã dừng. Hoàn thành '..run.confirmed..' bước nâng.');return
        end
        if gameBusy() then
            if now-run.readyAt>=15 then finish(run,'Game đang bận. Thử lại sau.');end
            return
        end
        while run.index<=#run.fruitIds do
            local fruitId = run.fruitIds[run.index]
            local fruit = data:GetFruitById(fruitId)
            local current,maximum = state(fruit,run.mode)
            local reason
            if current and maximum and current<maximum then
                reason = checkCost(fruit,run.mode,current+1)
                if not reason then
                    if not run.batch and (not visible(owner.btnToDo.gameObject) or data.currentFruit~=fruit) then
                        finish(run,'Bảng nâng đã đổi. Mở lại đúng trái.');return
                    end
                    run.pending = {fruitId=fruitId,mode=run.mode,previous=current,deadline=now+15}
                    sendStep(run,fruit)
                    return
                end
            end
            if not run.batch then
                finish(run,reason or (current and maximum and current>=maximum and 'Đã đạt tối đa.' or 'Chưa đọc được cấp hoặc sao.'))
                return
            end
            if run.mode==1 then run.mode=2 else run.mode=1;run.index=run.index+1 end
        end
        finish(run,'Đã nâng hết mức có thể. Hoàn thành '..run.confirmed..' bước nâng.')
    end

    local function toggle(owner,batch)
        if active then
            if active.owner==owner and not active.stopped then
                active.stopped = true
                print('VinhFruitUpgrade stop confirmed='..active.confirmed..' pending='..tostring(active.pending~=nil))
                if not active.pending then
                    finish(active,'Đã dừng tự nâng.')
                else
                    render(owner,batch)
                    CS.Toast.ShowToast('Đã dừng. Đang nhận kết quả lượt cuối.')
                end
            end
            return
        end
        local account = scope()
        if not allowed() or not visible(owner.goRoot) or not account or owner.vinhFruitUpgrade.uncertain then return end
        if otherAutoRunning() then CS.Toast.ShowToast('Dừng auto đang chạy trước.');return end
        local data = FFDataItem._instance
        if not data or (batch and data.ffUpgrade) or (not batch and data.ffUpgrade~=owner) or gameBusy() then
            CS.Toast.ShowToast('Game đang xử lý thao tác trước.');return
        end
        local run = {owner=owner,batch=batch,scope=account,data=data,index=1,confirmed=0,manual={},
                     readyAt=U.Time.realtimeSinceStartup,previousFruit=data.currentFruit,fruitIds={}}
        local function lock(button)
            run.manual[button] = button.interactable
            button.interactable = false
        end
        if batch then
            local list = data.fruitList
            for i=1,list:count() do
                local fruit = list:getAt(i)
                if fruit.owned then run.fruitIds[#run.fruitIds+1]=fruit.fruitId end
            end
            if #run.fruitIds==0 then CS.Toast.ShowToast('Chưa có trái ác quỷ để nâng.');return end
            run.mode = 1
            lock(owner.fruitInfo.btnUpgrade)
            lock(owner.fruitInfo.btnStar)
        else
            local current,maximum = state(owner.fruitData,owner.mode)
            if not current or not maximum or current>=maximum or not owner.btnToDo:IsInteractable() then return end
            run.mode,run.fruitId = owner.mode,owner.fruitData.fruitId
            run.fruitIds[1] = run.fruitId
            lock(owner.btnToDo)
        end
        active = run
        _G.HTPS_FRUIT_UPGRADE_RUNNING = true
        render(owner,batch)
        CsCoroutine.start(function()
            while active==run do
                local ok = pcall(tick,run)
                if not ok then finish(run,'Chưa xử lý được tự nâng. Kiểm tra lại bảng.',run.pending~=nil) end
                if active==run then coroutine.yield(U.WaitForSecondsRealtime(.05)) end
            end
        end)
    end

    local function place(go, original, x, width)
        local rect = go:GetComponent(typeof(U.RectTransform))
        rect.anchorMin,rect.anchorMax,rect.pivot = original.anchorMin,original.anchorMax,original.pivot
        rect.anchoredPosition = U.Vector2(x,original.anchoredPosition.y)
        rect.sizeDelta = U.Vector2(width,original.sizeDelta.y)
    end

    local function mount(owner,original,batch,x,width)
        local rect = original:GetComponent(typeof(U.RectTransform))
        local clone = U.Object.Instantiate(original,original.transform.parent,false)
        owner.vinhFruitUpgradeClone = clone
        clone.name = batch and 'VinhFruitUpgradeAll' or 'VinhFruitUpgradeAuto'
        place(clone,rect,x,width)
        local button = clone:GetComponent(typeof(U.UI.Button))
        local label = clone:GetComponentInChildren(typeof(U.UI.Text),true)
        local localizer = label.gameObject:GetComponent(typeof(CS.I2.Loc.Localize))
        if localizer then U.Object.Destroy(localizer) end
        local checker = label.gameObject:GetComponent(typeof(CS.TextLocalizeChecker))
        if checker then U.Object.Destroy(checker) end
        label.fontSize = math.min(24,label.fontSize)
        button.onClick = U.UI.Button.ButtonClickedEvent()
        button.onClick:AddListener(function()toggle(owner,batch)end)
        owner.vinhFruitUpgrade = {button=button,buttonText=label}
        render(owner,batch)
    end

    local function ensure(owner,batch)
        if owner.disposed or not visible(owner.goRoot) or not allowed() then return end
        if owner.vinhFruitUpgrade then render(owner,batch);return end
        if batch then
            local reference = owner.fruitInfo and owner.fruitInfo.btnReceive.gameObject
            if not visible(reference) then return end
            local rect = reference:GetComponent(typeof(U.RectTransform))
            local width = rect.rect.width
            if width<=0 then return end
            mount(owner,reference,true,rect.anchoredPosition.x-width-12,width)
            return
        end
        local current,maximum = state(owner.fruitData,owner.mode)
        local original = owner.btnToDo.gameObject
        if not current or not maximum or current>=maximum or not visible(original) then return end
        local rect = original:GetComponent(typeof(U.RectTransform))
        local parent = original.transform.parent
        local slot = math.min(190,(parent:GetComponent(typeof(U.RectTransform)).rect.width-32)/2)
        if slot<=8 then return end
        local x = rect.anchoredPosition.x
        mount(owner,original,false,x+slot/2,slot-8)
        place(original,rect,x-slot/2,slot-8)
    end

    local function attach(owner,batch)
        if owner.vinhFruitUpgradeUnavailable then return end
        local ok,message = pcall(ensure,owner,batch)
        if ok then return end
        owner.vinhFruitUpgradeUnavailable = true
        if owner.vinhFruitUpgradeClone then U.Object.Destroy(owner.vinhFruitUpgradeClone) end
        owner.vinhFruitUpgrade = nil
        print('VinhFruitUpgrade UI: '..tostring(message))
    end

    local original = _G.HTPS_EnsureSpecialEquipButtons
    _G.HTPS_EnsureSpecialEquipButtons = function(...)
        if original then original(...) end
        if not allowed() or not FFUpgrade or not FFDataItem then return end
        if installed~=FFUpgrade then
            local init = FFUpgrade.initUI
            if type(init)~='function' then return end
            installed = FFUpgrade
            function FFUpgrade:initUI(...)
                init(self,...)
                attach(self)
            end
        end
        local data = FFDataItem._instance
        if data and data.ffUpgrade then attach(data.ffUpgrade) end
        local list = data and data.ffRoot and data.ffRoot.tabFruitList
        if list then attach(list,true) end
    end
end

-- Individual Pet priority picker and batched enlightenment.
do
    local U,GO = CS.UnityEngine,CS.UnityEngine.GameObject
    local P = {query = '',page = 1,panels = {}}
    _G.VinhPetControls = P
    _G.HTPS_PET_ENLIGHT_RUNNING = false
    local quality = {'Thường','Ưu Tú','Nổi Bật','Trác Việt','Hoàn Mỹ'}
    local ranks = {'D','C','B','A','S','SS','SSS'}
    local function scope()
        local c = CS.GameContext.GetIntance()
        if c and c.m_ServerGame and c.m_UserId > 0 then
            return tostring(c.m_UserId)..'/'..tostring(c.m_ServerGame.m_ServerId)
        end
    end
    local function allowed() return _G.VinhLuaGate and _G.VinhLuaGate.allowed() end
    local function data() return PetDataItem and PetDataItem:instance() end
    local function shown(go) return go and not go:Equals(nil) and go.activeInHierarchy end
    local function trim(s) return tostring(s or ''):gsub('<[^>]+>','') end
    function P.fold(s)
        s = trim(s):gsub('[A-Z]',function(ch)return string.char(ch:byte()+32)end)
        local groups = {
            {'a','àáạảãâầấậẩẫăằắặẳẵÀÁẠẢÃÂẦẤẬẨẪĂẰẮẶẲẴ'},
            {'e','èéẹẻẽêềếệểễÈÉẸẺẼÊỀẾỆỂỄ'}, {'i','ìíịỉĩÌÍỊỈĨ'},
            {'o','òóọỏõôồốộổỗơờớợởỡÒÓỌỎÕÔỒỐỘỔỖƠỜỚỢỞỠ'},
            {'u','ùúụủũưừứựửữÙÚỤỦŨƯỪỨỰỬỮ'}, {'y','ỳýỵỷỹỲÝỴỶỸ'}, {'d','đĐ'}
        }
        for _,g in ipairs(groups) do
            for ch in g[2]:gmatch('[\1-\127\194-\244][\128-\191]*') do s = s:gsub(ch,g[1]) end
        end
        return s
    end
    function P.selectedId()
        local key = scope()
        if not key then return 0 end
        if P.selectedScope ~= key then
            P.selectedScope = key
            P.petId = tonumber(U.PlayerPrefs.GetString('VinhPetPriority/'..key,'0')) or 0
        end
        return P.petId or 0
    end
    function P.selectedPet()
        local id = P.selectedId()
        local d = data()
        return id > 0 and d and d:GetPetById(id) or nil
    end
    function P.select(option)
        if _G.HTPS_PET_SUMMON_RUNNING or _G.HTPS_PET_AWAKEN_RUNNING then return end
        _G.HTPS_SetPetTargetSetId(option.setId)
        P.selectedScope,P.petId = scope(),option.petId or 0
        if P.selectedScope then
            U.PlayerPrefs.SetString('VinhPetPriority/'..P.selectedScope,tostring(P.petId))
            U.PlayerPrefs.Save()
        end
        _G.HTPS_RefreshPetTargetButtonLabel()
        _G.HTPS_ClosePetTargetDropdown()
    end
    _G.HTPS_IsPreferredPet = function(p) return p and p.petId == P.selectedId() end
    function P.description(p)
        local base = p.basePet or {}
        local q = quality[math.min(5,math.max(1,tonumber(p.tierIntelligent) or 1))]
        return string.format('[%s] %s · %d★\n%s · Lv.%d · TT:%s · #%s',
            ranks[tonumber(base.rank) or 0] or '?',trim(base.name or ('Pet '..p.setId)),p.star or 0,
            q,p.level or 1,tostring(p.intelligent or '?'),tostring(p.petId))
    end
    local originalOptions = _G.HTPS_GetPetTargetOptions
    function P.options()
        local result = {{setId = 0,petId = 0,label = 'Tất cả SS · Tự chọn theo tiến trình'}}
        local ownSet = {}
        local d = data()
        for _,p in ipairs(d and d.petOwnedList and d.petOwnedList.listElement or {}) do
            local rank = p.basePet and tonumber(p.basePet.rank) or 0
            if rank == 5 or rank == 6 then
                ownSet[p.setId] = true
                result[#result+1] = {setId = p.setId,petId = p.petId,pet = p,label = P.description(p)}
            end
        end
        table.sort(result,function(a,b)
            if a.petId == 0 or b.petId == 0 then return a.petId == 0 and b.petId ~= 0 end
            if a.pet.basePet.rank ~= b.pet.basePet.rank then return a.pet.basePet.rank > b.pet.basePet.rank end
            if a.setId ~= b.setId then return a.setId < b.setId end
            if a.pet.star ~= b.pet.star then return a.pet.star > b.pet.star end
            if a.pet.tierIntelligent ~= b.pet.tierIntelligent then return a.pet.tierIntelligent > b.pet.tierIntelligent end
            return a.petId < b.petId
        end)
        for _,o in ipairs(originalOptions and originalOptions() or {}) do
            if o.setId > 0 and not ownSet[o.setId] then
                result[#result+1] = {setId = o.setId,petId = 0,label = trim(o.labelPlain)..' · Chọn theo loài'}
            end
        end
        return result
    end
    function P.filtered()
        local found,query = {},P.fold(P.query)
        for _,o in ipairs(P.options()) do
            if query == '' or P.fold(o.label):find(query,1,true) then found[#found+1] = o end
        end
        return found
    end
    local oldLabel = _G.HTPS_RefreshPetTargetButtonLabel
    _G.HTPS_RefreshPetTargetButtonLabel = function()
        if oldLabel then oldLabel() end
        local go = GO.Find('PetSummon(Clone)')
        local tf = go and go.transform:Find('Content/Main/BtnHTPSPetTargetDrop/Label')
        if not tf then return end
        tf.parent:GetComponent(typeof(U.RectTransform)).sizeDelta=U.Vector2(360,58)
        local p,id = P.selectedPet(),P.selectedId()
        if id > 0 then
            tf:GetComponent(typeof(U.UI.Text)).text = p and P.description(p) or 'Pet ưu tiên không còn trong kho · Chọn lại'
        end
    end
    local function node(parent,name,x,y,w,h)
        local go = GO(name);go.transform:SetParent(parent,false)
        local rt = go:AddComponent(typeof(U.RectTransform))
        rt.anchorMin,rt.anchorMax,rt.pivot = U.Vector2(.5,1),U.Vector2(.5,1),U.Vector2(.5,1)
        rt.anchoredPosition,rt.sizeDelta = U.Vector2(x,y),U.Vector2(w,h)
        return go
    end
    local function text(parent,name,value,font,size)
        local go = GO(name);go.transform:SetParent(parent,false)
        local rt = go:AddComponent(typeof(U.RectTransform))
        rt.anchorMin,rt.anchorMax = U.Vector2.zero,U.Vector2.one
        rt.offsetMin,rt.offsetMax = U.Vector2(10,3),U.Vector2(-10,-3)
        local label = go:AddComponent(typeof(U.UI.Text))
        label.font,label.fontSize,label.text,label.supportRichText = font,size,value,false
        label.alignment,label.color,label.raycastTarget = U.TextAnchor.MiddleLeft,U.Color(.98,.93,.81,1),false
        return label
    end
    local function button(parent,name,value,font,callback)
        local image = parent.gameObject:AddComponent(typeof(U.UI.Image))
        image.color = U.Color(.25,.17,.08,1)
        local label = text(parent,name,value,font,17)
        local control = parent.gameObject:AddComponent(typeof(U.UI.Button))
        control.targetGraphic = image;control.onClick:AddListener(callback)
        return control,label,image
    end
    function P.rebuild()
        local go = GO.Find('PetSummon(Clone)')
        local blocker = go and go.transform:Find('Content/BlockerHTPSPetTargetDrop')
        local inner = blocker and blocker:Find('BoxFrame/InnerBg')
        if not inner then return end
        local header = inner:Find('Header'):GetComponent(typeof(U.UI.Text))
        local font = header.font
        header.text = 'Chọn Pet ưu tiên nâng'
        local box = blocker:Find('BoxFrame'):GetComponent(typeof(U.RectTransform))
        box.sizeDelta,box.anchoredPosition = U.Vector2(540,430),U.Vector2(0,130)
        local viewport = inner:Find('Viewport')
        local vrt = viewport:GetComponent(typeof(U.RectTransform))
        vrt.offsetMin,vrt.offsetMax = U.Vector2(8,48),U.Vector2(-8,-92)
        local search = inner:Find('VinhPetSearch')
        if not search then
            local fieldGo = node(inner,'VinhPetSearch',0,-39,510,44)
            local image = fieldGo:AddComponent(typeof(U.UI.Image));image.color = U.Color(.98,.94,.81,1)
            local input = fieldGo:AddComponent(typeof(U.UI.InputField))
            input.targetGraphic = image
            input.textComponent = text(fieldGo.transform,'Value','',font,18)
            input.textComponent.color = U.Color(.2,.13,.06,1)
            local placeholder = text(fieldGo.transform,'Placeholder','Tìm tên, phẩm hoặc mã Pet…',font,17)
            placeholder.color = U.Color(.42,.33,.21,1);input.placeholder = placeholder
            input.characterLimit,input.text = 64,P.query
            input.onValueChanged:AddListener(function(value) P.query=value;P.page=1;P.rebuild() end)
            local prev = node(inner,'VinhPetPrev',-205,-384,110,36)
            button(prev.transform,'Text','‹ Trước',font,function()P.page=math.max(1,P.page-1);P.rebuild()end)
            local next = node(inner,'VinhPetNext',205,-384,110,36)
            button(next.transform,'Text','Sau ›',font,function()P.page=P.page+1;P.rebuild()end)
            local footer = node(inner,'VinhPetCount',0,-384,280,36)
            text(footer.transform,'Text','',font,16).alignment = U.TextAnchor.MiddleCenter
        end
        local list = viewport:Find('ListContent')
        for i=list.childCount-1,0,-1 do U.Object.DestroyImmediate(list:GetChild(i).gameObject) end
        local options = P.filtered()
        local pages = math.max(1,math.ceil(#options/30));P.page=math.min(P.page,pages)
        inner:Find('VinhPetCount/Text'):GetComponent(typeof(U.UI.Text)).text = string.format('%d Pet · %d/%d',#options,P.page,pages)
        inner:Find('VinhPetPrev'):GetComponent(typeof(U.UI.Button)).interactable = P.page>1
        inner:Find('VinhPetNext'):GetComponent(typeof(U.UI.Button)).interactable = P.page<pages
        local selected = P.selectedId()
        local setId = _G.HTPS_GetPetTargetSetId()
        for i=(P.page-1)*30+1,math.min(#options,P.page*30) do
            local option = options[i]
            local row = GO('PetChoice'..i);row.transform:SetParent(list,false)
            row:AddComponent(typeof(U.RectTransform))
            local layout = row:AddComponent(typeof(U.UI.LayoutElement));layout.minHeight,layout.preferredHeight=64,64
            local chosen = selected>0 and option.petId==selected or selected==0 and option.petId==0 and option.setId==setId
            local control,label,image = button(row.transform,'Text',(chosen and '✓ ' or '')..option.label,font,function()P.select(option)end)
            control.interactable = not _G.HTPS_PET_SUMMON_RUNNING and not _G.HTPS_PET_AWAKEN_RUNNING
            if chosen then image.color=U.Color(.94,.73,.25,1);label.color=U.Color(.2,.12,.03,1) end
        end
        if #options==0 then
            local row=node(list,'Empty',0,0,490,60);text(row.transform,'Text','Không tìm thấy. Thử tên ngắn hơn hoặc xóa bộ lọc.',font,18)
        end
        viewport:GetComponent(typeof(U.UI.ScrollRect)).verticalNormalizedPosition=1
    end
    _G.HTPS_RebuildPetTargetRows = P.rebuild
    local E = {running=nil,pending=nil}
    local initialBatchLimit,maxBatchLimit=5,20
    local levelCheckpoint=30
    P.enlight = E
    local function petUpgradeBusy()
        if not E.running and not E.pending then return false end
        CS.Toast.ShowToast('Hãy dừng và chờ đợt nâng Pet hiện tại hoàn tất.');return true
    end
    local oldSummonToggle = _G.HTPS_TogglePetFastSummon
    _G.HTPS_TogglePetFastSummon = function(...)
        if petUpgradeBusy() then return end
        if not _G.HTPS_PET_SUMMON_RUNNING and P.selectedId()>0 and not P.selectedPet() then
            CS.Toast.ShowToast('Pet ưu tiên không còn trong kho. Hãy chọn lại Pet.');return
        end
        return oldSummonToggle(...)
    end
    local oldAwakenToggle = _G.HTPS_ToggleAutoPetAwaken
    if oldAwakenToggle then
        _G.HTPS_ToggleAutoPetAwaken = function(...)
            if not petUpgradeBusy() then return oldAwakenToggle(...) end
        end
    end
    local function current(run)
        return scope()==run.scope and shown(run.panel.goRoot)
            and (run.level or shown(run.panel.panelEnlight.gameObject))
            and run.panel.currentPet and run.panel.currentPet.petId==run.petId
    end
    local function busy()
        if _G.HTPS_AUTO and _G.HTPS_AUTO.running or _G.HTPS_CAMPAIGN_BUSY then return true end
        for name,value in pairs(_G) do
            if type(name)=='string' and name:match('^HTPS_.*_RUNNING$') and value==true
                and name~='HTPS_PET_ENLIGHT_RUNNING' and name~='HTPS_CAMPAIGN_RUNNING' then return true end
        end
    end
    function E.update(panel)
        local label=panel.vinhLevelLabel or panel.vinhEnlightLabel
        if not label then return end
        local control=panel.vinhLevelButton or panel.vinhEnlightButton
        local manual=panel.upgradeBtn or panel.upBtn
        local run=E.running
        local active=run and run.panel==panel
        local caption=active and ('Dừng · '..run.attempts..' lần') or E.pending and 'Chờ kết quả…'
            or (panel.vinhLevelLabel and 'Nâng cấp nhanh' or 'Tự lĩnh ngộ')
        if label.text~=caption then label.text=caption end
        control.interactable = active or (not run and not E.pending)
        if panel.vinhLevelLabel then
            local p=panel.currentPet
            local visible=not not (active or p and p.level<p.maxLevel)
            if control.gameObject.activeSelf~=visible then control.gameObject:SetActive(visible) end
        end
        if run or E.pending then
            if panel.vinhManualUpgrade==nil then panel.vinhManualUpgrade=manual.interactable end
            manual.interactable=false
        elseif panel.vinhManualUpgrade~=nil then
            manual.interactable=panel.vinhManualUpgrade;panel.vinhManualUpgrade=nil
        end
    end
    local function complete(run,message)
        if run.notified or scope()~=run.scope then return end
        run.notified=true
        local p=data():GetPetById(run.petId)
        if run.level then
            CS.Toast.ShowToast(string.format('%s · %s Lv.%s/%s',message,run.name,p and p.level or '?',p and p.maxLevel or '?'))
            if run.attempts>0 and p then
                local hero=data():GetPetEquipped(run.petId)
                if hero and hero>0 then CS.GameContext.GetIntance().dataSender:HeroRequestInfo(hero) end
            end
            return
        end
        CS.PopupMessage.ShowUp(string.format('%s\n%s\n%d lần · Thành công %d · Thất bại %d\nLĩnh ngộ hiện tại: Lv.%s',
            message,run.name,run.attempts,run.success,run.failed,not run.unsynced and p and p.tier or '?'))
    end
    function E.stop(message)
        local run=E.running
        if not run then return end
        E.running=nil;_G.HTPS_PET_ENLIGHT_RUNNING=false
        run.stopMessage=message or 'Đã dừng'
        if not E.pending and run.level and run.sinceSync>0 and scope()==run.scope and allowed() then
            E.pending=run
        end
        if E.pending then CS.Toast.ShowToast('Đã dừng gửi đợt mới. Đang kiểm tra kết quả.')
        else complete(run,run.stopMessage) end
        E.update(run.panel)
        print('VinhPetEnlight stop confirmed='..run.attempts..' pending='..tostring(E.pending~=nil))
    end
    function E.plan(p,fee,have,rules,limit)
        if not fee or fee<=0 or not have then error('Missing enlightenment cost') end
        local maxLevel,maxFee=0,fee
        for _,r in ipairs(rules) do maxLevel=math.max(maxLevel,r.level);maxFee=math.max(maxFee,tonumber(r.stone) or fee) end
        if p.tier>=maxLevel then return 0 end
        return math.max(0,math.min(limit or initialBatchLimit,maxBatchLimit,math.floor(have/maxFee)))
    end
    function E.planLevels(p,gold,exp,rules,limit,fromLevel)
        local count=0
        local start=fromLevel or p.level
        local maxLevel=math.min(p.maxLevel,start+math.min(limit or initialBatchLimit,maxBatchLimit))
        for level=start+1,maxLevel do
            local rule=rules[level]
            if not rule then return count,'Thiếu dữ liệu phí nâng cấp' end
            if gold<rule.gold then return count,'Không đủ vàng' end
            if exp<rule.exp then return count,'Không đủ EXP Pet' end
            gold,exp=gold-rule.gold,exp-rule.exp
            count=count+1
        end
        return count,'Đã đạt trần cấp theo sao'
    end
    local function syncPet(run,snapshot)
        local httpCode
        if not snapshot and scope()==run.scope then
            local results,_,code=_G.HTPS_PetSendActs(940,{{id=940}})
            httpCode=code
            for _,reply in ipairs(results or {}) do
                if reply.actionId==940 and reply.data then snapshot=reply.data;break end
            end
        end
        local synced=scope()==run.scope and snapshot~=nil and _G.HTPS_PetApplySyncData(snapshot,true,true)
        run.unsynced=not synced
        if run.level then run.sinceSync=0 end
        local pet=synced and data():GetPetById(run.petId)
        if pet then
            if run.level and run.displayPet.setData then run.displayPet:setData(pet) end
            if current(run) then run.panel:SetPetData(pet) end
        end
        return pet,httpCode
    end
    local function adjustBatch(run,elapsed)
        if elapsed<=3.5 then
            run.batchLimit=math.min(run.batchLimit*2,maxBatchLimit)
        elseif elapsed>=7 then
            run.batchLimit=math.max(initialBatchLimit,math.floor(run.batchLimit/2))
        end
    end
    function E.batch(run,count)
        local action=run.level and 941 or 945
        local feature=run.level and 'VinhPetLevel' or 'VinhPetEnlight'
        local specs={}
        for i=1,count do specs[i]={id=action,vals={run.petId}} end
        local checkpoint=not run.level or run.sinceSync+count>=levelCheckpoint or run.levelCursor+count>=run.maxLevel
        if checkpoint then specs[#specs+1]={id=940} end
        E.pending=run
        local sentAt=U.Time.realtimeSinceStartup
        print(feature..' batch send actions='..count)
        local results,message,httpCode=_G.HTPS_PetSendActs(action,specs)
        local elapsed=U.Time.realtimeSinceStartup-sentAt
        if scope()~=run.scope then
            E.pending=nil;if E.running==run then E.stop('Đã đổi tài khoản') end;return false
        end
        local received,sync=0,nil
        local yieldAt=U.Time.realtimeSinceStartup+.004
        for _,r in ipairs(results or {}) do
            if scope()~=run.scope then
                E.pending=nil;if E.running==run then E.stop('Đã đổi tài khoản') end;return false
            end
            if r.actionId==action and r.data then
                local cv=_G.HTPS_DeserializeProto(r.data,'pbdson.CommonVector,PbMethodLib')
                local values=cv and cv.aLong
                if received>=count or not values or values.Count<1 then error('Unexpected Pet upgrade receipt') end
                if run.level then
                    CS.BonusModel.ParseBonusReceived(values)
                else
                    if values[0]~=0 and values[0]~=1 then error('Unexpected enlightenment result') end
                    CS.BonusModel.ParseBonusReceived(values:GetRange(1,values.Count-1))
                    if values[0]==1 then run.success=run.success+1 else run.failed=run.failed+1 end
                end
                received=received+1;run.attempts=run.attempts+1
                if U.Time.realtimeSinceStartup>=yieldAt then
                    coroutine.yield(U.WaitForSecondsRealtime(0));yieldAt=U.Time.realtimeSinceStartup+.004
                end
            elseif r.actionId==940 and r.data then sync=r.data end
        end
        if run.level then
            run.levelCursor=run.levelCursor+received
            run.sinceSync=run.sinceSync+received
            if not checkpoint and not sync and received==count and not message and E.running==run and current(run) then
                E.pending=nil
                adjustBatch(run,elapsed)
                print(string.format('%s batch received=%d/%d synced=deferred http=%s elapsed=%.2fs',
                    feature,received,count,tostring(httpCode),elapsed))
                return true
            end
        end
        local pet,statusCode=syncPet(run,sync)
        if scope()~=run.scope then E.pending=nil;if E.running==run then E.stop('Đã đổi tài khoản') end;return false end
        E.pending=nil
        print(string.format('%s batch received=%d/%d synced=%s http=%s syncHttp=%s elapsed=%.2fs',
            feature,received,count,tostring(not not pet),tostring(httpCode),tostring(statusCode),elapsed))
        if E.running~=run then complete(run,run.stopMessage or 'Đã dừng');return false end
        if pet and run.level and pet.level>=pet.maxLevel then
            E.stop('Đã đạt trần cấp theo sao');return false
        end
        if pet and not run.level then
            local maxed=true
            for _,rule in ipairs(data().petEnlightUpgrade.listElement) do
                if rule.level>pet.tier then maxed=false;break end
            end
            if maxed then E.stop('Đã đạt Lĩnh ngộ tối đa');return false end
        end
        if not pet or received~=count or message then
            if httpCode and httpCode>=400 then
                message='Máy chủ game trả HTTP '..httpCode..'. Hãy mở lại màn Pet để kiểm tra kết quả.'
            elseif not results and httpCode==0 then
                message='Máy chủ game chưa trả phản hồi. Hãy mở lại màn Pet để kiểm tra kết quả.'
            elseif not message then
                message='Chưa xác nhận đủ kết quả đợt vừa gửi. Hãy kiểm tra lại Pet.'
            end
            E.stop(message)
            return false
        end
        if run.level then
            if pet.level~=run.levelCursor then
                E.stop('Cấp Pet thực tế khác tiến độ dự kiến. Đã đồng bộ lại.');return false
            end
            run.maxLevel=pet.maxLevel
        end
        adjustBatch(run,elapsed)
        return true
    end
    function E.toggle(panel,level)
        if E.running then if E.running.panel==panel then E.stop('Đã dừng') end;return end
        if not allowed() then _G.VinhLuaGate.open();return end
        if E.pending then return end
        if busy() then CS.Toast.ShowToast('Dừng auto khác trước.');return end
        local pet=panel.currentPet
        if not pet or not scope() or not shown(panel.goRoot) or (not level and not shown(panel.panelEnlight.gameObject)) then return end
        local d=data()
        if d.m_ReceivedHeroUpLevelData==false then CS.Toast.ShowToast('Chờ thao tác Pet trước đó hoàn tất.');return end
        local run={panel=panel,scope=scope(),petId=pet.petId,name=trim(pet.basePet.name),attempts=0,success=0,failed=0,
            level=level,displayPet=pet,batchLimit=initialBatchLimit,levelCursor=pet.level,maxLevel=pet.maxLevel,sinceSync=0}
        local levelRules={}
        if level then for _,rule in ipairs(d.petLevelUpgrade.listElement) do levelRules[rule.level]=rule end end
        E.running=run;_G.HTPS_PET_ENLIGHT_RUNNING=true;E.update(panel)
        CsCoroutine.start(function()
            local ok=pcall(function()
                while E.running==run and _G.HTPS_PET_ENLIGHT_RUNNING do
                    if not allowed() or not current(run) then E.stop('Đã đổi Pet, rời màn hoặc hết quyền sử dụng');break end
                    local p=data():GetPetById(run.petId)
                    if not p then E.stop('Không còn Pet đã chọn');break end
                    local inventory=CS.PlayerInventory.GetInstance()
                    local count,reason
                    if level then
                        local gold=tonumber(CS.GameContext.GetIntance().m_Gold) or 0
                        local exp=tonumber(inventory:GetNumberItemConsumable(PetPanelInfo.PET_2_EXP_ITEM_KEY)) or 0
                        count,reason=E.planLevels(p,gold,exp,levelRules,run.batchLimit,run.levelCursor)
                    else
                        local item=panel.enlightGameItem.m_ItemConsumableUI.m_ItemConsumable
                        local have=tonumber(inventory:GetNumberItemConsumable(item.m_ItemKey))
                        count=E.plan(p,tonumber(item.m_Number),have,data().petEnlightUpgrade.listElement,run.batchLimit)
                        reason=panel.nextTierData and 'Đã hết nguyên liệu Lĩnh ngộ' or 'Đã đạt Lĩnh ngộ tối đa'
                    end
                    if count==0 then E.stop(reason);break end
                    if not NetworkController:instance().requestInFlight then if not E.batch(run,count) then break end end
                    E.update(panel);coroutine.yield(U.WaitForSecondsRealtime(.04))
                end
            end)
            if not ok then
                if run.level and E.pending==run then run.sinceSync=math.max(1,run.sinceSync) end
                E.pending=nil
                E.stop('Chưa đọc được kết quả nâng Pet. Kiểm tra lại trước khi chạy tiếp.')
            end
            if E.running==run then E.stop('Đã dừng') end
            if E.pending==run and run.level then
                local ok,pet=pcall(syncPet,run)
                E.pending=nil
                local message=run.stopMessage or 'Đã dừng'
                if not ok or not pet then message=message..' · Chưa đồng bộ được cấp Pet' end
                complete(run,message)
            end
            E.update(panel)
        end)
    end
    local function ensure(panel)
        if not shown(panel.goRoot) or not panel.upBtn or not allowed() then return end
        if not panel.vinhEnlightButton then
            local source=panel.upBtn.gameObject
            local clone=U.Object.Instantiate(source,source.transform.parent,false)
            clone.name='VinhAutoEnlight'
            local rt=clone:GetComponent(typeof(U.RectTransform));rt.anchoredPosition=U.Vector2(85,rt.anchoredPosition.y);rt.sizeDelta=U.Vector2(160,44)
            local original=source:GetComponent(typeof(U.RectTransform));original.anchoredPosition=U.Vector2(-85,original.anchoredPosition.y);original.sizeDelta=U.Vector2(160,44)
            local control=clone:GetComponent(typeof(U.UI.Button));control.onClick=U.UI.Button.ButtonClickedEvent()
            local label=clone:GetComponentInChildren(typeof(U.UI.Text),true)
            local loc=label.gameObject:GetComponent(typeof(CS.I2.Loc.Localize));if loc then U.Object.Destroy(loc) end
            local checker=label.gameObject:GetComponent(typeof(CS.TextLocalizeChecker));if checker then U.Object.Destroy(checker) end
            label.text,label.fontSize='Tự lĩnh ngộ',18
            control.onClick:AddListener(function()E.toggle(panel)end)
            clone:SetActive(true);panel.vinhEnlightButton,panel.vinhEnlightLabel=control,label
        end
        E.update(panel)
    end
    local function ensureLevel(panel)
        if not shown(panel.goRoot) or not panel.upgradeBtn or not allowed() then return end
        if not panel.vinhLevelButton then
            local font=panel.levelText.font
            local go=node(panel.goRoot.transform,'VinhQuickPetLevel',0,0,220,35)
            local rect=go:GetComponent(typeof(U.RectTransform))
            rect.anchorMin,rect.anchorMax,rect.pivot=U.Vector2(.5,0),U.Vector2(.5,0),U.Vector2(.5,0)
            rect.anchoredPosition=U.Vector2(0,4)
            local control,label,image=button(go.transform,'Label','Nâng cấp nhanh',font,function()E.toggle(panel,true)end)
            local sprite=_G.HTPS_FindNativeSprite and _G.HTPS_FindNativeSprite('button_yellow',true)
            if sprite then
                image.sprite,image.type,image.color=sprite,U.UI.Image.Type.Sliced,U.Color(1,1,1,1)
                label.color=U.Color(.36,.22,.07,1)
            end
            label.alignment,label.fontSize=U.TextAnchor.MiddleCenter,19
            panel.vinhLevelButton,panel.vinhLevelLabel=control,label
        end
        E.update(panel)
    end
    local oldEnsure=_G.HTPS_EnsureSpecialEquipButtons
    _G.HTPS_EnsureSpecialEquipButtons=function(...)
        if oldEnsure then oldEnsure(...) end
        if PetPanelFoster and not P.installed then
            P.installed=true
            local init,set=PetPanelFoster.initUI,PetPanelFoster.SetPetData
            function PetPanelFoster:initUI(...)init(self,...);P.panels[self]=true;ensure(self)end
            function PetPanelFoster:SetPetData(p,...)
                if E.running and E.running.panel==self and p.petId~=E.running.petId then E.stop('Đã đổi Pet') end
                set(self,p,...);P.panels[self]=true;ensure(self)
            end
        end
        local inv=_G.HTPS_GetLivePetInventory and _G.HTPS_GetLivePetInventory()
        if inv then
            if inv.petPanelFoster then P.panels[inv.petPanelFoster]=true end
            if inv.petPanelInfo then ensureLevel(inv.petPanelInfo) end
        end
        for panel in pairs(P.panels) do
            if panel.disposed or not panel.goRoot or panel.goRoot:Equals(nil) then P.panels[panel]=nil
            else ensure(panel) end
        end
        if E.running and (not _G.HTPS_PET_ENLIGHT_RUNNING or not current(E.running) or not allowed()) then E.stop('Đã dừng') end
    end
end

-- Share scene lookups within one UI refresh, then discard the snapshot.
do
    local U = CS.UnityEngine
    local findOne = _G.HTPS_FindObjectOfType
    local findMany = _G.HTPS_FindObjectsOfType
    local scan
    function _G.HTPS_FindObjectOfType(kind)
        if not scan then return findOne(kind) end
        if scan.one[kind] == nil then scan.one[kind] = findOne(kind) or false end
        return scan.one[kind] or nil
    end
    function _G.HTPS_FindObjectsOfType(kind)
        if not scan then return findMany(kind) end
        if not scan.many[kind] then scan.many[kind] = findMany(kind) end
        return scan.many[kind]
    end
    local function withScan(fn,...)
        local previous=scan
        scan=scan or {one={},many={},live={}}
        local ok,failure=pcall(fn,...)
        scan=previous
        if not ok then error(failure) end
    end
    local ensure = _G.HTPS_EnsureSpecialEquipButtons
    function _G.HTPS_EnsureSpecialEquipButtons(...) return withScan(ensure,...) end
    function _G.HTPS_GetModSprites()
        if not scan then return U.Resources.FindObjectsOfTypeAll(typeof(U.Sprite)) end
        if not scan.sprites then scan.sprites=U.Resources.FindObjectsOfTypeAll(typeof(U.Sprite)) end
        return scan.sprites
    end
    for _,name in ipairs({'HTPS_GetLivePetInventory','HTPS_GetLivePetSummon'}) do
        local read=_G[name]
        if read then
            _G[name]=function(...)
                if not scan then return read(...) end
                if scan.live[name]==nil then scan.live[name]=read(...) or false end
                return scan.live[name] or nil
            end
        end
    end
    local readers={'HTPS_EnsureHLBButtons','HTPS_EnsureSpecialEquipButtons','HTPS_EnsureSummonOrbButtons',
                   'HTPS_EnsureAlbumAutoButtons','HTPS_EnsureFurnitureButtons'}
    local errorAt={}
    function _G.HTPS_RefreshModUI()
        withScan(function()
            for _,name in ipairs(readers) do
                local fn=_G[name]
                if fn then
                    local ok=pcall(fn)
                    local time=U.Time.realtimeSinceStartup
                    if not ok and time>=(errorAt[name] or 0) then
                        errorAt[name]=time+30
                        print('Vinh UI waiting: '..name)
                    end
                end
            end
        end)
    end
    local clear = _G.HTPS_KillSummonPopups
    local nextClear = 0
    function _G.HTPS_KillSummonPopups(...)
        local time = U.Time.realtimeSinceStartup
        if time < nextClear then return end
        nextClear = time + .04
        return clear(...)
    end
end

end)
gate.state = ok and 'ready' or 'failed'
if not ok then
    gate.set(false)
    _G.HTPS_FEATURES_LOADED = false
    print('Vinh PC Lua initialization failed: '..tostring(message))
end
return gate.state

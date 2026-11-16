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
-- TÍNH NĂNG: Phó Bản Chiến Dịch (Action 316+318+349), Càn Quét Beli, Nguyên Liệu, Mảnh Hải Tặc
-- TRÍCH XUẤT TỪ NGUYENVINHMOD.DLL BẰNG REA ENGINE
-- =====================================================================

-- ==================== AUTO PHÓ BẢN CHIẾN DỊCH (POPUP EVENT RAID: BELI / NGUYÊN LIỆU / MẢNH HẢI TẶC) ====================
    _G.HTPS_EVENT_RAID_RUNNING = false

    _G.HTPS_UpdateEventRaidBtnUI = function(statusText)
        pcall(function()
            if _G.HTPS_BTN_RAID_ALL_TXT and not _G.HTPS_BTN_RAID_ALL_TXT:Equals(nil) then
                if _G.HTPS_EVENT_RAID_RUNNING then
                    _G.HTPS_BTN_RAID_ALL_TXT.text = statusText or "Đang Auto..."
                else
                    _G.HTPS_BTN_RAID_ALL_TXT.text = "Auto Cả 3 Phần"
                end
            end
            for rt = 0, 2 do
                local t = _G.HTPS_BTN_RAID_SUB_TXT and _G.HTPS_BTN_RAID_SUB_TXT[rt]
                if t and not t:Equals(nil) then
                    t.text = _G.HTPS_EVENT_RAID_RUNNING and "..." or "Auto"
                end
            end
        end)
    end

    _G.HTPS_RunAutoEventRaid = function(targetMode)
        if _G.HTPS_EVENT_RAID_RUNNING then
            CS.Toast.ShowToast("Đang xử lý Auto Chiến Dịch, vui lòng đợi 1 giây!")
            return
        end

        _G.HTPS_EVENT_RAID_RUNNING = true
        _G.HTPS_BONUS_SUPPRESS_UNTIL = 0
        if _G.HTPS_AUTO then _G.HTPS_AUTO.suppressPopup = true end
        _G.HTPS_UpdateEventRaidBtnUI("Đang càn quét...")

        CsCoroutine.start(function()
            local REF_FLAGS = 60
            local gc = CS.GameContext.GetIntance()
            local nc = CS.NetworkController.GetInstance()
            local inv = CS.PlayerInventory.GetInstance()

            -- Lấy 6 tướng mạnh nhất + Pet mạnh nhất
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

            if #heroes == 0 then
                _G.HTPS_EVENT_RAID_RUNNING = false
                _G.HTPS_UpdateEventRaidBtnUI()
                CS.Toast.ShowToast("Không tìm thấy tướng trong kho để đánh Chiến Dịch!")
                return
            end

            local raidTypes = {}
            if targetMode == "ALL" then
                raidTypes = { 0, 1, 2 }
            else
                raidTypes = { tonumber(targetMode) or 0 }
            end

            local RAID_NAMES = { [0] = "Beli", [1] = "Nguyên liệu", [2] = "Mảnh hải tặc" }

            -- Bước 1: Gửi Action 316 lấy trạng thái lượt & màn cao nhất đã mở khóa
            local reqStatus = CS.pbdson.RequestData()
            reqStatus.session = gc.m_Session
            for _, rt in ipairs(raidTypes) do
                local cv316 = CS.pbdson.CommonVector()
                cv316.aLong:Add(rt)
                local act316 = CS.pbdson.PbAction()
                act316.actionId = 316
                act316.data = _G.HTPS_SerializeProto(cv316)
                reqStatus.actions:Add(act316)
            end

            local raidStates = {}
            local dataSt, okSt = _G.HTPS_PutWebRequest(nc.m_UrlGameServer .. "/i/316/" .. tostring(gc.m_UserId), _G.HTPS_SerializeProto(reqStatus), 8)
            if okSt and dataSt then
                pcall(function()
                    local resp = _G.HTPS_DeserializeProto(dataSt, "pbdson.ResponseData,PbMethodLib")
                    if resp and resp.aAction then
                        local rtIdx = 1
                        for i = 0, resp.aAction.Count - 1 do
                            local a = resp.aAction[i]
                            if a.actionId == 316 and a.data then
                                local rt = raidTypes[rtIdx]
                                rtIdx = rtIdx + 1
                                if rt ~= nil then
                                    local lcv = _G.HTPS_DeserializeProto(a.data, "pbdson.ListCommonVector,PbMethodLib")
                                    if lcv and lcv.aVector and lcv.aVector.Count >= 2 then
                                        local v0 = lcv.aVector[0].aLong
                                        local buyLeft = tonumber(v0[0]) or 0
                                        local atkLeft = tonumber(v0[1]) or 0
                                        local price = tonumber(v0[3]) or 20
                                        local bestStage = 0
                                        local pLv = gc.m_PlayerLevel or 1
                                        for s = 1, lcv.aVector.Count - 1 do
                                            local vs = lcv.aVector[s].aLong
                                            local lvReq = (vs and vs.Count >= 2) and tonumber(vs[1]) or 999
                                            if lvReq <= pLv then
                                                bestStage = s - 1
                                            end
                                        end
                                        raidStates[rt] = {
                                            buyLeft = buyLeft,
                                            atkLeft = atkLeft,
                                            price = price,
                                            bestStage = bestStage,
                                        }
                                    end
                                end
                            end
                        end
                    end
                end)
            end

            -- Bước 2: Gộp mua tối đa lượt (Action 318) + đánh mở màn (Action 317) + càn quét toàn bộ (Action 349)
            local reqRun = CS.pbdson.RequestData()
            reqRun.session = gc.m_Session
            local availGem = gc.m_Gem or 0
            local summaryParts = {}
            local totalTurnsDone = 0

            for _, rt in ipairs(raidTypes) do
                local st = raidStates[rt]
                if st then
                    local canBuy = 0
                    if st.buyLeft > 0 and availGem >= st.price then
                        canBuy = math.min(st.buyLeft, math.floor(availGem / math.max(1, st.price)))
                    end
                    if canBuy > 0 then
                        local cv318 = CS.pbdson.CommonVector()
                        cv318.aLong:Add(rt)
                        cv318.aLong:Add(canBuy)
                        local act318 = CS.pbdson.PbAction()
                        act318.actionId = 318
                        act318.data = _G.HTPS_SerializeProto(cv318)
                        reqRun.actions:Add(act318)
                        availGem = availGem - (canBuy * st.price)
                        gc.m_Gem = availGem
                    end

                    local totalAtk = st.atkLeft + canBuy
                    if totalAtk > 0 then
                        -- Đánh 1 trận Action 317 ở màn cao nhất để đảm bảo đã mở khóa Càn Quét
                        local cv317 = CS.pbdson.CommonVector()
                        cv317.aLong:Add(rt)
                        cv317.aLong:Add(st.bestStage)
                        for s = 1, 6 do
                            cv317.aLong:Add(heroes[s] and heroes[s].m_HeroId or -1)
                        end
                        cv317.aLong:Add(bestPetId)
                        local act317 = CS.pbdson.PbAction()
                        act317.actionId = 317
                        act317.data = _G.HTPS_SerializeProto(cv317)
                        reqRun.actions:Add(act317)

                        -- Càn quét toàn bộ số lượt còn lại trong 1 gói Action 349
                        if totalAtk > 1 then
                            local cv349 = CS.pbdson.CommonVector()
                            cv349.aLong:Add(rt)
                            cv349.aLong:Add(st.bestStage)
                            cv349.aLong:Add(totalAtk - 1)
                            for s = 1, 6 do
                                cv349.aLong:Add(heroes[s] and heroes[s].m_HeroId or -1)
                            end
                            cv349.aLong:Add(bestPetId)
                            local act349 = CS.pbdson.PbAction()
                            act349.actionId = 349
                            act349.data = _G.HTPS_SerializeProto(cv349)
                            reqRun.actions:Add(act349)
                        end

                        totalTurnsDone = totalTurnsDone + totalAtk
                        table.insert(summaryParts, string.format("%s: %d lượt", RAID_NAMES[rt] or tostring(rt), totalAtk))
                    end
                end
            end

            if reqRun.actions.Count > 0 then
                _G.HTPS_BONUS_SUPPRESS_UNTIL = 0
                if _G.HTPS_AUTO then _G.HTPS_AUTO.suppressPopup = true end
                _G.HTPS_PutWebRequest(nc.m_UrlGameServer .. "/i/349/" .. tostring(gc.m_UserId), _G.HTPS_SerializeProto(reqRun), 10)
                _G.HTPS_KillSummonPopups()

                -- Đồng bộ lại túi đồ (Mảnh tướng / Beli / Nguyên liệu) từ Server mà không bật popup
                pcall(function()
                    gc.dataSender:ItemConsumableList()
                    if _G.HTPS_SyncServerEquipmentAndSafeGold then
                        _G.HTPS_SyncServerEquipmentAndSafeGold()
                    end
                    local plrc = CS.PopupListRaidChallenge.Instance
                    if plrc and not plrc:Equals(nil) and plrc.gameObject.activeInHierarchy then
                        plrc:LoadData(plrc.m_RaidType)
                        plrc:HideLoading()
                    end
                    local per = _G.HTPS_FindObjectOfType(typeof(CS.PopupEventRaid))
                    if per and not per:Equals(nil) then
                        per:HideLoading()
                    end
                end)

                CS.Toast.ShowToast("Đã tự mua lượt & càn quét xong Chiến Dịch (" .. table.concat(summaryParts, " | ") .. ")!")
            else
                CS.Toast.ShowToast("Đã hết sạch lượt đánh và lượt mua hôm nay!")
            end

            _G.HTPS_EVENT_RAID_RUNNING = false
            _G.HTPS_UpdateEventRaidBtnUI()
        end)
    end

    _G.HTPS_EnsureEventRaidButtons = function()
        pcall(function()
            local per = _G.HTPS_FindObjectOfType(typeof(CS.PopupEventRaid))
            if not per or per:Equals(nil) or not per.gameObject.activeInHierarchy then return end
            local bodyTf = per.transform:Find("PanelBody")
            if not bodyTf then return end

            if not _G.HTPS_BTN_RAID_SUB_TXT then _G.HTPS_BTN_RAID_SUB_TXT = {} end
            if not _G.HTPS_BOUND_RAID_BTNS then _G.HTPS_BOUND_RAID_BTNS = {} end

            local cards = {
                { name = "ImageGold", rt = 0 },
                { name = "ImageSpirit", rt = 1 },
                { name = "ImageHero", rt = 2 },
            }

            local sampleBtnEnter = nil
            for _, c in ipairs(cards) do
                local cardTf = bodyTf:Find(c.name)
                if cardTf then
                    local btnEnterTf = cardTf:Find("ButtonEnter")
                    if btnEnterTf then
                        sampleBtnEnter = btnEnterTf
                        local btnSubTf = cardTf:Find("BtnHTPSAutoRaid")
                        if not btnSubTf then
                            local origRt = btnEnterTf:GetComponent(typeof(UG.RectTransform))
                            origRt.anchoredPosition = UG.Vector2(-52.0, -198.0)
                            origRt.sizeDelta = UG.Vector2(98.0, 64.0)
                            local origTxt = btnEnterTf:GetComponentInChildren(typeof(UG.UI.Text), true)
                            if origTxt then origTxt.fontSize = 21 end

                            local cloneGo = GO.Instantiate(btnEnterTf.gameObject, cardTf, false)
                            cloneGo.name = "BtnHTPSAutoRaid"
                            cloneGo:SetActive(true)
                            local rt = cloneGo:GetComponent(typeof(UG.RectTransform))
                            rt.anchoredPosition = UG.Vector2(52.0, -198.0)
                            rt.sizeDelta = UG.Vector2(98.0, 64.0)

                            local img = cloneGo:GetComponent(typeof(UG.UI.Image))
                            if img then img.raycastTarget = true end

                            local txt = cloneGo:GetComponentInChildren(typeof(UG.UI.Text), true)
                            if txt then
                                local loc = txt.gameObject:GetComponent(typeof(CS.I2.Loc.Localize))
                                if loc then UG.Object.DestroyImmediate(loc) end
                                txt.raycastTarget = true
                                txt.alignment = UG.TextAnchor.MiddleCenter
                                txt.fontSize = 20
                                txt.text = "Auto"
                                _G.HTPS_BTN_RAID_SUB_TXT[c.rt] = txt
                            end
                            btnSubTf = cloneGo.transform
                        end

                        if btnSubTf and _G.HTPS_BOUND_RAID_BTNS[c.rt] ~= btnSubTf then
                            local bc = btnSubTf:GetComponent(typeof(UG.UI.Button))
                            if bc then
                                local modeVal = c.rt
                                bc.onClick = UG.UI.Button.ButtonClickedEvent()
                                bc.onClick:AddListener(function()
                                    _G.HTPS_RunAutoEventRaid(modeVal)
                                end)
                            end
                            _G.HTPS_BOUND_RAID_BTNS[c.rt] = btnSubTf
                        end
                    end
                end
            end

            -- Nút tổng [Auto Cả 3 Phần] trên góc trên PanelBody
            local btnAllTf = bodyTf:Find("BtnHTPSAutoRaidAll")
            if not btnAllTf and sampleBtnEnter then
                local cloneAll = GO.Instantiate(sampleBtnEnter.gameObject, bodyTf, false)
                cloneAll.name = "BtnHTPSAutoRaidAll"
                cloneAll:SetActive(true)
                local rt = cloneAll:GetComponent(typeof(UG.RectTransform))
                rt.anchoredPosition = UG.Vector2(-255.0, 226.0)
                rt.sizeDelta = UG.Vector2(210.0, 52.0)

                local img = cloneAll:GetComponent(typeof(UG.UI.Image))
                if img then img.raycastTarget = true end

                local txt = cloneAll:GetComponentInChildren(typeof(UG.UI.Text), true)
                if txt then
                    local loc = txt.gameObject:GetComponent(typeof(CS.I2.Loc.Localize))
                    if loc then UG.Object.DestroyImmediate(loc) end
                    txt.raycastTarget = true
                    txt.alignment = UG.TextAnchor.MiddleCenter
                    txt.fontSize = 19
                    txt.text = "Auto Cả 3 Phần"
                    _G.HTPS_BTN_RAID_ALL_TXT = txt
                end
                btnAllTf = cloneAll.transform
            end

            if btnAllTf and _G.HTPS_BOUND_RAID_ALL_BTN ~= btnAllTf then
                local bc = btnAllTf:GetComponent(typeof(UG.UI.Button))
                if bc then
                    bc.onClick = UG.UI.Button.ButtonClickedEvent()
                    bc.onClick:AddListener(function()
                        _G.HTPS_RunAutoEventRaid("ALL")
                    end)
                end
                _G.HTPS_BOUND_RAID_ALL_BTN = btnAllTf
            end
        end)
    end

    
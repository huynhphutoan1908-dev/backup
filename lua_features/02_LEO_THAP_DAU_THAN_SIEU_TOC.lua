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
-- TÍNH NĂNG: Tự Động Leo Tháp Đậu Thần Đơn & Đôi, Khóa Cờ Skip Battle Bỏ Qua Giao Tranh 3D
-- TRÍCH XUẤT TỪ NGUYENVINHMOD.DLL BẰNG REA ENGINE
-- =====================================================================

-- AUTO LEO THÁP ĐẬU THẦN SIÊU TỐC (CẢ ĐƠN & ĐÔI - CHỐNG LAG MẠNG)
    -- =================================================================
    _G.HTPS_TOWER_RUNNING = _G.HTPS_TOWER_RUNNING or false
    _G.HTPS_TOWER_FLOOR = _G.HTPS_TOWER_FLOOR or 0
    _G.HTPS_TOWER_MODE = _G.HTPS_TOWER_MODE or "CURRENT"
    _G.HTPS_TOWER_CUR_TAB = _G.HTPS_TOWER_CUR_TAB or 1

    _G.HTPS_StopAutoTower = function()
        _G.HTPS_TOWER_RUNNING = false
        return "STOPPED"
    end

    local function getTowerFormation(curScene, targetTabId)
        local lstSrv = nil
        local pf1Exist = GO.Find("PopupFormation(Clone)")
        local pf2Exist = GO.Find("PopupFormation2(Clone)")
        if pf1Exist then
            pf1Exist:SetActive(false)
            UG.Object.DestroyImmediate(pf1Exist)
        end
        if pf2Exist then
            pf2Exist:SetActive(false)
            UG.Object.DestroyImmediate(pf2Exist)
        end

        curScene:ButtonFightClick()

        if targetTabId == 1 then
            local pfGo = GO.Find("PopupFormation(Clone)")
            if pfGo then
                local pf = pfGo:GetComponent(typeof(CS.PopupFormation))
                local panelForm = pf:GetType():GetField("m_PanelFormation", REF_FLAGS):GetValue(pf)
                local hf = panelForm:GetHeroesFormation()
                if hf:CountNumberHero() > 0 then
                    lstSrv = hf:ToListServerHeroId1LineUp()
                end
                pfGo:SetActive(false)
                UG.Object.DestroyImmediate(pfGo)
            end
        else
            local pfGo = GO.Find("PopupFormation2(Clone)")
            if pfGo then
                local pf = pfGo:GetComponent(typeof(CS.PopupFormation2))
                local panelForm = pf:GetType():GetField("m_PanelFormation", REF_FLAGS):GetValue(pf)
                local hf = panelForm:GetHeroesFormation()
                if hf:CountNumberHero() > 0 then
                    lstSrv = hf:ToListServerHeroId2LineUp()
                end
                pfGo:SetActive(false)
                UG.Object.DestroyImmediate(pfGo)
            end
        end
        return lstSrv
    end

    _G.HTPS_StartAutoTower = function(mode)
        if _G.HTPS_TOWER_RUNNING then return "ALREADY_RUNNING" end
        local curScene = CS.GameContext.GetIntance().m_CurrentScene
        if not curScene or curScene:GetType().Name ~= "TowerNewScene" then
            return "NOT_IN_TOWER"
        end

        mode = mode or "CURRENT"
        _G.HTPS_TOWER_MODE = mode
        _G.HTPS_TOWER_RUNNING = true

        CsCoroutine.start(function()
            local st = curScene:GetType()
            local tabField = st:GetField("_currentTabBtnId", REF_FLAGS)
            local tdField = st:GetField("m_CurrentTowerData", REF_FLAGS)
            local tmField = st:GetField("m_TabManager", REF_FLAGS)
            local stagesField = st:GetField("m_ListTowerStages", REF_FLAGS)
            local skipField = typeof(CS.StaticData):GetField("m_SkipBattleTower", REF_FLAGS)
            local pbeType = typeof(CS.PopupBattleEnd)
            local winField = pbeType:GetField("m_GoFrameWin", REF_FLAGS)
            local enField = pbeType:GetField("m_EnableClose", REF_FLAGS)
            local ds = CS.GameContext.GetIntance().dataSender
            local db = CS.DbManager.GetInstance()

            local startTab = tabField:GetValue(curScene)
            local tabOrder = {}
            if mode == "BOTH" then
                if startTab == 1 then
                    tabOrder = {1, 2}
                else
                    tabOrder = {2, 1}
                end
            elseif mode == "SINGLE" or mode == "1" then
                tabOrder = {1}
            elseif mode == "DOUBLE" or mode == "2" then
                tabOrder = {2}
            else
                tabOrder = {startTab}
            end

            for _, targetTab in ipairs(tabOrder) do
                if not _G.HTPS_TOWER_RUNNING then break end
                local activeScene = CS.GameContext.GetIntance().m_CurrentScene
                if not activeScene or activeScene ~= curScene then
                    _G.HTPS_TOWER_RUNNING = false
                    break
                end

                local modeLabel = (targetTab == 1) and "Đơn" or "Đôi"
                local maxTowerFloor = (targetTab == 1) and db:CountTower1Level() or db:CountTower2Level()
                _G.HTPS_TOWER_CUR_TAB = targetTab

                -- Chuyển sang tab tương ứng nếu chưa ở tab đó (chờ tối đa 6s nếu mạng lag)
                local nowTab = tabField:GetValue(curScene)
                if nowTab ~= targetTab then
                    local tm = tmField:GetValue(curScene)
                    if tm then tm:OnTabClick(targetTab) end
                    local tSw = UG.Time.realtimeSinceStartup
                    while _G.HTPS_TOWER_RUNNING and (UG.Time.realtimeSinceStartup - tSw < 6.0) do
                        local tdChk = tdField:GetValue(curScene)
                        if tabField:GetValue(curScene) == targetTab and tdChk and tdChk.m_TypeTower == targetTab then
                            break
                        end
                        coroutine.yield(nil)
                    end
                    coroutine.yield(UG.WaitForSeconds(0.15))
                end

                -- Luôn bật cờ Skip Battle của Tower để KHÔNG BAO GIỜ vào màn hình đánh trận
                skipField:SetValue(nil, true)

                local tdInit = tdField:GetValue(curScene)
                if tdInit then
                    _G.HTPS_TOWER_FLOOR = tdInit.m_CurrentLevelId
                end

                local lstSrv = getTowerFormation(curScene, targetTab)
                if not lstSrv then
                    pcall(function()
                        CS.Toast.ShowToast("Chưa có đội hình Leo " .. modeLabel .. "! Hãy bấm Chiến đấu xếp đội 1 lần.")
                    end)
                else
                    local lagRetryCount = 0
                    while _G.HTPS_TOWER_RUNNING do
                        activeScene = CS.GameContext.GetIntance().m_CurrentScene
                        if not activeScene or activeScene ~= curScene then
                            _G.HTPS_TOWER_RUNNING = false
                            break
                        end

                        skipField:SetValue(nil, true)

                        local td = tdField:GetValue(curScene)
                        if not td then break end
                        local prevFloor = td.m_CurrentLevelId
                        local turnsLeft = td.m_NumberAtkLeft
                        _G.HTPS_TOWER_FLOOR = prevFloor

                        if turnsLeft <= 0 then
                            pcall(function()
                                CS.Toast.ShowToast("Đã dừng Leo " .. modeLabel .. " tại Tầng " .. tostring(prevFloor) .. " (Hết lượt)!")
                            end)
                            break
                        end

                        -- Kiểm tra giới hạn tầng thật sự từ DbManager
                        local lvInfo = (targetTab == 1) and db:GetTowerLevel(prevFloor) or db:GetTower2Level(prevFloor)
                        local lstStages = stagesField:GetValue(curScene)
                        local stage0Inactive = (lstStages ~= nil and lstStages.Count > 0 and not lstStages[0].gameObject.activeSelf)
                        if prevFloor > maxTowerFloor or lvInfo == nil or stage0Inactive then
                            pcall(function()
                                CS.Toast.ShowToast("Đã đạt giới hạn tối đa Leo " .. modeLabel .. " (Tầng " .. tostring(prevFloor) .. ")!")
                            end)
                            break
                        end

                        -- Xóa PopupBattleEnd cũ nếu còn sót
                        local oldPbe = _G.HTPS_FindObjectOfType(pbeType)
                        if oldPbe then
                            oldPbe.gameObject:SetActive(false)
                            UG.Object.DestroyImmediate(oldPbe.gameObject)
                        end

                        if targetTab == 1 then
                            ds:TowerBattle(lstSrv)
                        else
                            ds:Tower2Battle(lstSrv)
                        end

                        -- Đợi kết quả trận đấu (tối đa 10 giây để chống mạng lag)
                        local t0 = UG.Time.realtimeSinceStartup
                        local gotResult = false
                        local won = false
                        while _G.HTPS_TOWER_RUNNING and (UG.Time.realtimeSinceStartup - t0 < 10.0) do
                            skipField:SetValue(nil, true)
                            local pbe = _G.HTPS_FindObjectOfType(pbeType)
                            if pbe then
                                gotResult = true
                                local goWin = winField:GetValue(pbe)
                                won = (goWin ~= nil and goWin.activeSelf)
                                enField:SetValue(pbe, true)
                                pbe.gameObject:SetActive(false)
                                pbe:ButtonCloseClick()
                                break
                            end
                            coroutine.yield(nil)
                        end

                        if not gotResult then
                            -- Mạng lag chưa trả về kịp -> thử đồng bộ lại và đánh lại tối đa 3 lần
                            lagRetryCount = lagRetryCount + 1
                            if lagRetryCount <= 3 then
                                if targetTab == 1 then ds:TowerStatus() else ds:Tower2Status() end
                                coroutine.yield(UG.WaitForSeconds(1.0))
                            else
                                pcall(function()
                                    CS.Toast.ShowToast("Mạng chậm / Server không phản hồi tại Tầng " .. tostring(prevFloor) .. "!")
                                end)
                                break
                            end
                        else
                            lagRetryCount = 0

                            if not won then
                                pcall(function()
                                    CS.Toast.ShowToast("Đã dừng Leo " .. modeLabel .. " tại Tầng " .. tostring(prevFloor) .. " (Không qua ải)!")
                                end)
                                break
                            end

                            -- Nếu vừa thắng tầng cuối cùng của tháp -> hoàn thành!
                            if prevFloor >= maxTowerFloor then
                                pcall(function()
                                    CS.Toast.ShowToast("Đã phá đảo tối đa Leo " .. modeLabel .. " (Tầng " .. tostring(prevFloor) .. ")!")
                                end)
                                break
                            end

                            -- Đợi callback của ButtonCloseClick cập nhật tầng mới (chờ tới 6s, nếu lag tự gọi lại TowerStatus)
                            local t1 = UG.Time.realtimeSinceStartup
                            local nudgedStatus = false
                            local advanced = false
                            while _G.HTPS_TOWER_RUNNING and (UG.Time.realtimeSinceStartup - t1 < 6.0) do
                                local tdNow = tdField:GetValue(curScene)
                                if tdNow and tdNow.m_CurrentLevelId > prevFloor then
                                    advanced = true
                                    _G.HTPS_TOWER_FLOOR = tdNow.m_CurrentLevelId
                                    break
                                end
                                if not nudgedStatus and (UG.Time.realtimeSinceStartup - t1 > 1.8) then
                                    nudgedStatus = true
                                    if targetTab == 1 then ds:TowerStatus() else ds:Tower2Status() end
                                end
                                coroutine.yield(nil)
                            end

                            if not advanced then
                                -- Nếu gói TowerStatus vẫn về chậm do lag mạng nhưng trận trước đã thắng (won == true),
                                -- tự cộng thêm 1 tầng tạm thời để không bị dừng nhầm!
                                local tdFallback = tdField:GetValue(curScene)
                                if tdFallback and tdFallback.m_CurrentLevelId <= prevFloor then
                                    tdFallback.m_CurrentLevelId = prevFloor + 1
                                    _G.HTPS_TOWER_FLOOR = prevFloor + 1
                                end
                            end

                            coroutine.yield(nil)
                        end
                    end
                end
            end

            _G.HTPS_TOWER_RUNNING = false
        end)

        return "STARTED_TOWER|" .. tostring(mode)
    end

    _G.HTPS_EnsureTowerButtons = function()
        pcall(function()
            local curScene = CS.GameContext.GetIntance().m_CurrentScene
            if not curScene or curScene:GetType().Name ~= "TowerNewScene" then return end

            -- Luôn mở sẵn cờ bỏ qua trận đấu trong Tháp Đậu Thần
            typeof(CS.StaticData):GetField("m_SkipBattleTower", REF_FLAGS):SetValue(nil, true)

            local cvs = GO.Find("Canvas")
            local bf = cvs and cvs.transform:Find("ButtonFight")
            if not bf then return end

            local oldTurbo = cvs.transform:Find("BtnAutoTowerTurbo")
            if oldTurbo then GO.DestroyImmediate(oldTurbo.gameObject) end

            local st = curScene:GetType()
            local curTab = st:GetField("_currentTabBtnId", REF_FLAGS):GetValue(curScene)
            local curTabLabel = (curTab == 1) and "Đơn" or "Đôi"

            -- Nút 1: Auto Leo Đơn / Auto Leo Đôi (theo tab đang mở)
            local btnTf = cvs.transform:Find("BtnAutoTowerFast")
            if not btnTf then
                local cloneGo = GO.Instantiate(bf.gameObject, cvs.transform, false)
                cloneGo.name = "BtnAutoTowerFast"
                btnTf = cloneGo.transform
            end
            if _G.HTPS_BOUND_BTN_FAST ~= btnTf then
                local rt = btnTf:GetComponent(typeof(UG.RectTransform))
                rt.anchoredPosition = UG.Vector2(-215, 65)
                rt.sizeDelta = UG.Vector2(200, 68)
                local txt = btnTf:GetComponentInChildren(typeof(UG.UI.Text), true)
                if txt then
                    local loc = txt.gameObject:GetComponent(typeof(CS.I2.Loc.Localize))
                    if loc then UG.Object.DestroyImmediate(loc) end
                    txt.fontSize = 20
                end
                local bc = btnTf:GetComponent(typeof(UG.UI.Button))
                bc.onClick = UG.UI.Button.ButtonClickedEvent()
                bc.onClick:AddListener(function()
                    if _G.HTPS_TOWER_RUNNING then
                        _G.HTPS_StopAutoTower()
                    else
                        _G.HTPS_StartAutoTower("CURRENT")
                    end
                end)
                _G.HTPS_BOUND_BTN_FAST = btnTf
            end

            -- Nút 2: Auto Đơn + Đôi (tự động leo cả 2 tháp)
            local btnBothTf = cvs.transform:Find("BtnAutoTowerBoth")
            if not btnBothTf then
                local cloneGo = GO.Instantiate(bf.gameObject, cvs.transform, false)
                cloneGo.name = "BtnAutoTowerBoth"
                btnBothTf = cloneGo.transform
            end
            if _G.HTPS_BOUND_BTN_BOTH ~= btnBothTf then
                local rt = btnBothTf:GetComponent(typeof(UG.RectTransform))
                rt.anchoredPosition = UG.Vector2(-215, 140)
                rt.sizeDelta = UG.Vector2(200, 62)
                local txt = btnBothTf:GetComponentInChildren(typeof(UG.UI.Text), true)
                if txt then
                    local loc = txt.gameObject:GetComponent(typeof(CS.I2.Loc.Localize))
                    if loc then UG.Object.DestroyImmediate(loc) end
                    txt.fontSize = 19
                end
                local bc = btnBothTf:GetComponent(typeof(UG.UI.Button))
                bc.onClick = UG.UI.Button.ButtonClickedEvent()
                bc.onClick:AddListener(function()
                    if _G.HTPS_TOWER_RUNNING then
                        _G.HTPS_StopAutoTower()
                    else
                        _G.HTPS_StartAutoTower("BOTH")
                    end
                end)
                _G.HTPS_BOUND_BTN_BOTH = btnBothTf
            end

            if btnTf then
                local txt = btnTf:GetComponentInChildren(typeof(UG.UI.Text), true)
                if txt then
                    if _G.HTPS_TOWER_RUNNING and _G.HTPS_TOWER_MODE ~= "BOTH" then
                        local runLbl = (_G.HTPS_TOWER_CUR_TAB == 1) and "Đơn" or "Đôi"
                        txt.text = "Dừng " .. runLbl .. " (" .. tostring(_G.HTPS_TOWER_FLOOR) .. ")"
                    else
                        txt.text = "Auto Leo " .. curTabLabel
                    end
                end
            end

            if btnBothTf then
                local txt = btnBothTf:GetComponentInChildren(typeof(UG.UI.Text), true)
                if txt then
                    if _G.HTPS_TOWER_RUNNING and _G.HTPS_TOWER_MODE == "BOTH" then
                        local runLbl = (_G.HTPS_TOWER_CUR_TAB == 1) and "Đơn" or "Đôi"
                        txt.text = "Dừng " .. runLbl .. " (" .. tostring(_G.HTPS_TOWER_FLOOR) .. ")"
                    else
                        txt.text = "Auto Đơn + Đôi"
                    end
                end
            end
        end)
    end

    local origEnsureSpecial2 = _G.HTPS_EnsureSpecialEquipButtons
    _G.HTPS_EnsureSpecialEquipButtons = function()
        if origEnsureSpecial2 then origEnsureSpecial2() end
        if _G.HTPS_EnsureTowerButtons then _G.HTPS_EnsureTowerButtons() end
    end


    -- =====================================================================
    -- 5. SOI ĐỘI HÌNH NGƯỜI CHƠI KHÁC & TRA CỨU KHO / RƯƠNG QUÀ (IN-GAME)
    -- =====================================================================
    local FACTION_VN_MAP = {
        [1] = "Thông Minh (INT/Dark)",
        [2] = "Minh Mẫn (MND/Light)",
        [3] = "Sinh Khí (VIT/Shadow)",
        [4] = "Nhanh Nhẹn (AGI/Fortress)",
        [5] = "Chính Xác (DEX/Forest)",
        [6] = "Bền Bỉ (STR/Abyss)"
    }
    local FACTION_SHORT_MAP = {
        [1] = "Thông Minh",
        [2] = "Minh Mẫn",
        [3] = "Sinh Khí",
        [4] = "Nhanh Nhẹn",
        [5] = "Chính Xác",
        [6] = "Bền Bỉ"
    }

    local CLASS_VN_MAP = {
        [1] = "Kiếm Sĩ (Assassin)",
        [2] = "Chỉ Huy (Mage)",
        [3] = "Xạ Thủ (Ranger)",
        [4] = "Hỗ Trợ (Priest)",
        [5] = "Đấu Sĩ (Warrior)"
    }

    local CLASS_GEAR_MAP = {
        [1] = {
            setName = "Bộ Cao Bồi (6★ Nghề Kiếm Sĩ)",
            keys = {21, 42, 63, 84},
            stone = "Đá Cam 6★: [1100 Công, 18% Công, 44% Xuyên Thủ] hoặc [20% Chí mạng, 52% ST Chí mạng, 4% Công]",
            talents = "2 - 1 - 3 - 1 - 2 (E1:+10% Công | E2:Giảm ST CM | E3:50% Giải khống | E4:+20% Công, +10% Miễn khống | E5:Khiên bất tử 3 hit)",
            voidNote = "Nâng Max 12 điểm Ấn + 4 Kỹ năng đặc biệt (dùng nút [Auto Max Ấn])"
        },
        [2] = {
            setName = "Bộ Lông Vũ (6★ Nghề Chỉ Huy)",
            keys = {85, 89, 93, 97},
            stone = "Đá Cam 6★: [23% Máu, 100 Tốc độ] (đi trước khống chế) hoặc [1100 Công, 22% Máu, 30% ST Chuẩn]",
            talents = "3 - 3 - 3 - 3 - 3 (Full Tốc độ +130 Tốc & 30% Hồi 100 Nộ) hoặc 2 - 1 - 3 - 1 - 2 (Full Sát thương + Khiên bất tử)",
            voidNote = "Nâng Max 12 điểm Ấn + 4 Kỹ năng đặc biệt (dùng nút [Auto Max Ấn])"
        },
        [3] = {
            setName = "Bộ Vương Giả (6★ Nghề Xạ Thủ)",
            keys = {86, 90, 94, 98},
            stone = "Đá Cam 6★: [1100 Công, 18% Công, 44% Xuyên Thủ] hoặc [1100 Công, 22% Máu, 30% ST Chuẩn]",
            talents = "2 - 1 - 3 - 1 - 2 (E1:+10% Công | E2:Giảm ST CM | E3:50% Giải khống | E4:+20% Công, +10% Miễn khống | E5:Khiên bất tử 3 hit)",
            voidNote = "Nâng Max 12 điểm Ấn + 4 Kỹ năng đặc biệt (dùng nút [Auto Max Ấn])"
        },
        [4] = {
            setName = "Bộ Mãng Xà (6★ Nghề Hỗ Trợ)",
            keys = {87, 91, 95, 99},
            stone = "Đá Cam 6★: [23% Máu, 100 Tốc độ] (buff nộ sớm) hoặc [26% Máu, 25% Chặn] (trụ giao tranh)",
            talents = "3 - 3 - 3 - 3 - 2 (Ưu tiên +130 Tốc độ đi trước + Giải khống + Khiên bất tử 3 hit)",
            voidNote = "Nâng Max 12 điểm Ấn + 4 Kỹ năng đặc biệt (dùng nút [Auto Max Ấn])"
        },
        [5] = {
            setName = "Bộ Ngưu Vương (6★ Nghề Đấu Sĩ)",
            keys = {88, 92, 96, 100},
            stone = "Đá Cam 6★: [26% Máu, 25% Chặn] (Đỡ đòn) hoặc [1100 Công, 22% Máu, 30% ST Chuẩn] (Đấu sĩ ST)",
            talents = "1 - 1 - 1 - 2 - 2 (E1:+12% Máu | E2:Giảm ST CM | E3:Hồi 15% máu mất | E4:+20% Máu, +10% Giảm ST | E5:Khiên bất tử 3 hit)",
            voidNote = "Nâng Max 12 điểm Ấn + 4 Kỹ năng đặc biệt (dùng nút [Auto Max Ấn])"
        }
    }

    _G.HTPS_HAKI_PRESETS = {
        {
            name = "Chuẩn Sát Thương (2-1-3-1-2)",
            indices = {1, 0, 2, 0, 1}, -- 0-based: E1=Vũ Trang(+10% Công), E2=Quan Sát(Giảm ST CM), E3=Bá Vương(Giải khống), E4=Quan Sát(+20% Công,+10% MK), E5=Vũ Trang(Khiên 3 hit)
            desc = "E1(+10% Công) - E2(Giảm 15% ST CM) - E3(50% Giải khống) - E4(+20% Công, +10% Miễn khống) - E5(Khiên bất tử 3 hit)"
        },
        {
            name = "Chuẩn Tốc Độ & Nộ (3-3-3-3-3)",
            indices = {2, 2, 2, 2, 2}, -- 0-based: Full Bá Vương (+30 Tốc, +15% Hồi máu, Giải khống, +100 Tốc, 30% Hồi 100 Nộ)
            desc = "E1(+30 Tốc) - E2(+15% Nhận hồi máu) - E3(50% Giải khống) - E4(+100 Tốc) - E5(30% cơ hội hồi 100 Nộ)"
        },
        {
            name = "Chuẩn Chống Chịu (1-1-1-2-2)",
            indices = {0, 0, 0, 1, 1}, -- 0-based: E1(+12% Máu), E2(Giảm ST CM), E3(Hồi 15% máu mất), E4(+20% Máu, +10% Giảm ST), E5(Khiên 3 hit)
            desc = "E1(+12% Máu) - E2(Giảm 15% ST CM) - E3(Hồi 15% máu mất) - E4(+20% Máu, +10% Giảm ST) - E5(Khiên bất tử 3 hit)"
        }
    }
    _G.HTPS_PREVIEW_HAKI_CYCLE = _G.HTPS_PREVIEW_HAKI_CYCLE or {}

    local function enumToIntVal(val)
        if not val then return 0 end
        local s = tostring(val)
        local n = s:match(":%s*(%d+)")
        if n then return tonumber(n) end
        return tonumber(s) or 0
    end

    local function fmtStar(star)
        if not star then return "?★" end
        if star > 10 then
            return string.format("E%d (%d★)", star - 10, star)
        end
        return tostring(star) .. "★"
    end

    local function resolveHero5And10Key(heroKey)
        local db = CS.DbManager.GetInstance()
        local k5 = db:GetKeyHero5StarFromHero10Star(heroKey)
        if not k5 or k5 <= 0 then
            k5 = db:GetKeyHero5StarFromHero6789Star(heroKey)
        end
        if not k5 or k5 <= 0 then
            k5 = heroKey
        end
        local k10 = db:GetKeyHero10StarFromHero5Star(k5)
        if not k10 or k10 <= 0 then
            k10 = heroKey
        end
        return k5, k10
    end

    _G.HTPS_CheckArtifactObtainable = function(artKey)
        local inv = CS.PlayerInventory.GetInstance()
        local db = CS.DbManager.GetInstance()
        local parts = {}
        local lstArt = inv:GetType():GetField("m_LstItemArtifact", REF_FLAGS):GetValue(inv)
        local bagCnt = 0
        local maxBagStar = 1
        if lstArt then
            for i = 0, lstArt.Count - 1 do
                local a = lstArt[i]
                if a and a.m_ItemKey == artKey and a.m_Number > 0 then
                    bagCnt = bagCnt + a.m_Number
                    if a.m_Star and a.m_Star > maxBagStar then maxBagStar = a.m_Star end
                end
            end
        end
        if bagCnt > 0 then
            table.insert(parts, string.format("<color=#00FF7F>Kho Bảo Vật: có sẵn x%d (★%d)</color>", bagCnt, maxBagStar))
        end

        local lstCons = inv:GetType():GetField("m_LstItemConsumable", REF_FLAGS):GetValue(inv)
        if lstCons then
            for i = 0, lstCons.Count - 1 do
                local ic = lstCons[i]
                if ic and ic.m_Number > 0 and ic.m_BonusPreview then
                    local lstA = ic.m_BonusPreview:GetType():GetField("m_LstBonusArtifact", REF_FLAGS):GetValue(ic.m_BonusPreview)
                    if lstA and lstA.Count > 0 then
                        for j = 0, lstA.Count - 1 do
                            local ba = lstA[j]
                            if ba and ba.m_ArtifactKey == artKey then
                                table.insert(parts, string.format("<color=#FFD700>%s</color> (có <b>%d</b> rương) -> <color=#00FFFF><b>Ô #%d</b></color>",
                                    tostring(ic.m_ItemName), ic.m_Number, j + 1))
                            end
                        end
                    end
                    local lstC = ic.m_BonusPreview:GetType():GetField("m_LstBonusConsumable", REF_FLAGS):GetValue(ic.m_BonusPreview)
                    if lstC and lstC.Count > 0 then
                        for k = 0, lstC.Count - 1 do
                            local bc = lstC[k]
                            if bc and bc.m_ItemKey and bc.m_ItemKey > 0 then
                                local subIc = db:GetItemConsumable(bc.m_ItemKey)
                                if subIc and subIc.m_BonusPreview then
                                    local subLstA = subIc.m_BonusPreview:GetType():GetField("m_LstBonusArtifact", REF_FLAGS):GetValue(subIc.m_BonusPreview)
                                    if subLstA and subLstA.Count > 0 then
                                        for m = 0, subLstA.Count - 1 do
                                            local sba = subLstA[m]
                                            if sba and sba.m_ArtifactKey == artKey then
                                                table.insert(parts, string.format("<color=#FFD700>%s</color> (có <b>%d</b>) -> <color=#00FFFF><b>Ô #%d</b></color> [%s] -> <color=#00FF7F><b>Ô #%d</b></color>",
                                                    tostring(ic.m_ItemName), ic.m_Number, k + 1, tostring(subIc.m_ItemName), m + 1))
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end

        if #parts == 0 then
            return false, "<color=#FFA500>Chưa có trong Kho/Rương của bạn</color>"
        end
        return true, table.concat(parts, " | ")
    end

    _G.HTPS_FindArtifactLocations = function(artKey)
        local _, txt = _G.HTPS_CheckArtifactObtainable(artKey)
        return txt
    end

    _G.HTPS_CheckClassGearInBag = function(clsId)
        local inv = CS.PlayerInventory.GetInstance()
        local gInfo = CLASS_GEAR_MAP[clsId]
        if not gInfo then return "Bộ Hải Âu 6★" end
        local lstEq = inv:GetType():GetField("m_LstItemEquipment", REF_FLAGS):GetValue(inv)
        local haveClassPieces = 0
        local baseCounts = { [20] = 0, [41] = 0, [62] = 0, [83] = 0 }
        if lstEq then
            for i = 0, lstEq.Count - 1 do
                local eq = lstEq[i]
                if eq and eq.m_Number > 0 then
                    for _, ck in ipairs(gInfo.keys) do
                        if eq.m_ItemKey == ck then
                            haveClassPieces = haveClassPieces + eq.m_Number
                        end
                    end
                    if baseCounts[eq.m_ItemKey] ~= nil then
                        baseCounts[eq.m_ItemKey] = baseCounts[eq.m_ItemKey] + eq.m_Number
                    end
                end
            end
        end
        local minBaseSets = math.min(baseCounts[20], baseCounts[41], baseCounts[62], baseCounts[83])

        local eqChestParts = {}
        local lstSh = inv:GetType():GetField("m_LstItemShard", REF_FLAGS):GetValue(inv)
        if lstSh then
            for i = 0, lstSh.Count - 1 do
                local sh = lstSh[i]
                if sh and sh.m_Number > 0 and (sh.m_ItemKey == 600138 or tostring(sh.m_ItemName or ""):find("Trang Bị 6 Sao")) then
                    table.insert(eqChestParts, string.format("<color=#FFD700>%s</color> (có <b>%d</b> rương trong Túi Mảnh)", tostring(sh.m_ItemName), sh.m_Number))
                end
            end
        end
        local chestNote = (#eqChestParts > 0) and (" + " .. table.concat(eqChestParts, ", ")) or ""
        return string.format("Kho đang có <b>%d/4</b> món %s | Có sẵn <b>%d bộ Hải Âu 6★</b>%s -> Mở lấy Bộ Hải Âu 6★ rồi vào <b>Nhà Thợ Rèn</b> rèn lên %s!",
            haveClassPieces, gInfo.setName, minBaseSets, chestNote, gInfo.setName)
    end

    _G.HTPS_AnalyzeHeroInBag = function(hm)
        local db = CS.DbManager.GetInstance()
        local inv = CS.PlayerInventory.GetInstance()
        local heroKey = hm.m_HeroKey
        local k5, k10 = resolveHero5And10Key(heroKey)
        local refHm = db:GetHeroModelCopy(heroKey) or db:GetHeroModelCopy(k10) or db:GetHeroModelCopy(k5) or hm
        local hName = tostring(refHm.m_HeroName or hm.m_HeroName or ("Hero#" .. tostring(heroKey)))
        local facId = enumToIntVal(refHm.m_Faction)
        local clsId = enumToIntVal(refHm.m_Class)
        local facName = FACTION_VN_MAP[facId] or tostring(refHm.m_Faction)
        local clsName = CLASS_VN_MAP[clsId] or tostring(refHm.m_Class)

        local lstH = inv:GetType():GetField("m_LstHeroModel", REF_FLAGS):GetValue(inv)
        local ownedSummary = {}
        local totalCopies = 0
        local myEquippedNote = nil
        local myBestCopy = nil
        if lstH then
            local byStar = {}
            for i = 0, lstH.Count - 1 do
                local uh = lstH[i]
                if uh and not CS.HeroModel.IsPuppetHero(uh.m_HeroKey) then
                    local uk5, _ = resolveHero5And10Key(uh.m_HeroKey)
                    if uk5 == k5 or uh.m_HeroKey == heroKey or tostring(uh.m_HeroName) == hName then
                        totalCopies = totalCopies + 1
                        local st = uh.m_Star or 5
                        byStar[st] = (byStar[st] or 0) + 1
                        if not myBestCopy or (st > (myBestCopy.m_Star or 0)) then
                            myBestCopy = uh
                        end
                    end
                end
            end
            if myBestCopy then
                local st = myBestCopy.m_Star or 5
                local eqCnt = ((myBestCopy.m_WeaponKey > 0) and 1 or 0) + ((myBestCopy.m_ArmorKey > 0) and 1 or 0) + ((myBestCopy.m_ShoesKey > 0) and 1 or 0) + ((myBestCopy.m_AccessoryKey > 0) and 1 or 0)
                local artName = "Chưa đeo Bảo vật"
                if myBestCopy.m_ArtifactKey and myBestCopy.m_ArtifactKey > 0 then
                    local aObj = db:GetItemArtifact(myBestCopy.m_ArtifactKey, math.max(1, myBestCopy.m_ArtifactStar or 1)) or db:GetItemArtifact(myBestCopy.m_ArtifactKey, 1)
                    artName = aObj and (tostring(aObj.m_ItemName) .. " ★" .. tostring(myBestCopy.m_ArtifactStar)) or ("Artifact#" .. tostring(myBestCopy.m_ArtifactKey))
                end
                local es = myBestCopy:GetListIndexESkill()
                local esParts = {}
                if es then
                    for k = 0, es.Count - 1 do table.insert(esParts, tostring(es[k] + 1)) end
                end
                local hakiTxt = (#esParts > 0) and (" | Haki: " .. table.concat(esParts, "-")) or ""
                myEquippedNote = string.format("Bản %s trong Kho của bạn đang mặc %d/4 Trang bị | %s%s", fmtStar(st), eqCnt, artName, hakiTxt)
            end
            for st = 15, 5, -1 do
                if byStar[st] then
                    table.insert(ownedSummary, string.format("<color=#00FF7F>%d bản %s</color>", byStar[st], fmtStar(st)))
                end
            end
        end

        local lstS = inv:GetType():GetField("m_LstItemShard", REF_FLAGS):GetValue(inv)
        local shardCount = 0
        if lstS then
            for i = 0, lstS.Count - 1 do
                local s = lstS[i]
                if s and s.m_Number > 0 then
                    local sk = s.m_HeroKey
                    if sk == k5 or sk == k10 or sk == heroKey or tostring(s.m_ItemName) == ("Mảnh ghép " .. hName) then
                        shardCount = shardCount + s.m_Number
                    end
                end
            end
        end

        local lstCons = inv:GetType():GetField("m_LstItemConsumable", REF_FLAGS):GetValue(inv)
        local chestList = {}
        if lstCons then
            for i = 0, lstCons.Count - 1 do
                local ic = lstCons[i]
                if ic and ic.m_Number > 0 and ic.m_BonusPreview then
                    local lstBH = ic.m_BonusPreview:GetType():GetField("m_LstBonusHero", REF_FLAGS):GetValue(ic.m_BonusPreview)
                    if lstBH and lstBH.Count > 0 then
                        for j = 0, lstBH.Count - 1 do
                            local bh = lstBH[j]
                            if bh and (bh.m_HeroKey == k5 or bh.m_HeroKey == k10 or bh.m_HeroKey == heroKey) then
                                table.insert(chestList, string.format("<color=#FFD700>%s</color> (có <b>%d</b> rương) -> <color=#00FFFF><b>Ô #%d</b></color>",
                                    tostring(ic.m_ItemName), ic.m_Number, j + 1))
                            end
                        end
                    end
                    local lstBC = ic.m_BonusPreview:GetType():GetField("m_LstBonusConsumable", REF_FLAGS):GetValue(ic.m_BonusPreview)
                    if lstBC and lstBC.Count > 0 then
                        for k = 0, lstBC.Count - 1 do
                            local bc = lstBC[k]
                            if bc and bc.m_ItemKey and bc.m_ItemKey > 0 then
                                local subIc = db:GetItemConsumable(bc.m_ItemKey)
                                if subIc and subIc.m_BonusPreview then
                                    local subBH = subIc.m_BonusPreview:GetType():GetField("m_LstBonusHero", REF_FLAGS):GetValue(subIc.m_BonusPreview)
                                    if subBH and subBH.Count > 0 then
                                        for m = 0, subBH.Count - 1 do
                                            local sbh = subBH[m]
                                            if sbh and (sbh.m_HeroKey == k5 or sbh.m_HeroKey == k10 or sbh.m_HeroKey == heroKey) then
                                                table.insert(chestList, string.format("<color=#FFD700>%s</color> (có <b>%d</b>) -> <color=#00FFFF><b>Ô #%d</b></color> [%s] -> <color=#00FF7F><b>Ô #%d</b></color>",
                                                    tostring(ic.m_ItemName), ic.m_Number, k + 1, tostring(subIc.m_ItemName), m + 1))
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end

        return {
            refHm = refHm,
            name = hName,
            heroKey = heroKey,
            k5 = k5,
            k10 = k10,
            star = hm.m_Star or 15,
            level = hm.m_Level or 330,
            facId = facId,
            clsId = clsId,
            facName = facName,
            clsName = clsName,
            ownedStr = (#ownedSummary > 0) and table.concat(ownedSummary, ", ") or "<color=#FF6347>Chưa có trong Kho Tướng</color>",
            myEquippedNote = myEquippedNote,
            myBestCopy = myBestCopy,
            shardCount = shardCount,
            shardCopies = math.floor(shardCount / 50),
            chestList = chestList
        }
    end

    _G.HTPS_GetRecommendedArtifactsForHero = function(facId, clsId)
        local ssOffMap = { [3] = 0, [6] = 1, [4] = 2, [5] = 3, [1] = 4, [2] = 5 }
        local bdHtMap  = { [2] = 148, [1] = 149, [5] = 150, [4] = 151, [6] = 152, [3] = 153 }
        local ssOff = ssOffMap[facId] or 0
        local facShort = FACTION_SHORT_MAP[facId] or "Đúng Hệ"

        local artDieuSu = {
            key = 130 + ssOff,
            name = "Điểu Sư (SS - Kích hệ " .. facShort .. ")",
            stats = "25% Công, 70 Tốc độ, 20% Máu + Kích hệ " .. facShort .. ": 18% Chí mạng, 50% Miễn khống",
            bonus = { atkPct = 25, hpPct = 20, speed = 70, crit = 18, ci = 50 }
        }
        local artYasopp = {
            key = 136 + ssOff,
            name = "Áo Yasopp (SS - Kích hệ " .. facShort .. ")",
            stats = "45% Máu, 30% Giảm ST + Kích hệ " .. facShort .. ": 70% Chặn, 18% Máu",
            bonus = { hpPct = 63, rd = 30, block = 70 }
        }
        local artBdTT = {
            key = 142 + ssOff,
            name = "Bá Đao Truyền Thuyết (SS - Kích hệ " .. facShort .. ")",
            stats = "21% Công, 18% Chí mạng, 30% Miễn khống + Kích hệ " .. facShort .. ": 50% ST Chí mạng, 20% Công",
            bonus = { atkPct = 41, crit = 18, cd = 50, ci = 30 }
        }
        local artBdHT = {
            key = bdHtMap[facId] or 149,
            name = "Bá Đao Huyền Thoại (SS - Kích hệ " .. facShort .. ")",
            stats = "21% Công, 20% Máu, 70 Tốc độ + Kích hệ " .. facShort .. ": 50% ST Kỹ năng, 20% Công",
            bonus = { atkPct = 41, hpPct = 20, speed = 70, sd = 50 }
        }
        local artMogura = {
            key = 154 + ssOff,
            name = "Mogura (SS - Kích hệ " .. facShort .. ")",
            stats = "18% Máu, 14% Công, 50% ST Kỹ năng + Kích hệ " .. facShort .. ": 40% Phá giáp, 25% ST Thần thánh",
            bonus = { atkPct = 14, hpPct = 18, sd = 50, ab = 40, hd = 25 }
        }
        local artChopper = {
            key = 160 + ssOff,
            name = "Mũ Chopper (SS - Kích hệ " .. facShort .. ")",
            stats = "30% Giảm ST, 14% Máu, 30% Miễn khống + Kích hệ " .. facShort .. ": 25% Máu, 18% Công",
            bonus = { atkPct = 18, hpPct = 39, rd = 30, ci = 30 }
        }

        local artPhiThuy = {
            key = 111,
            name = "Vòng Phỉ Thúy (Đỏ Siêu VIP - Đa dụng)",
            stats = "21% Công, 30% Giảm ST, 25% Miễn khống (Dùng chung mọi hệ)",
            bonus = { atkPct = 21, rd = 30, ci = 25 }
        }
        local artDurandal = {
            key = 53,
            name = "Kiếm Durandal (Đỏ VIP - Nộ Turn 1)",
            stats = "+50 Nộ đầu trận, +50% ST Kỹ năng (Tung tuyệt kỹ ngay lượt 1)",
            bonus = { sd = 50 }
        }
        local artDoflamingo = {
            key = 115,
            name = "Áo Choàng Doflamingo (Đỏ Siêu VIP - Chống chịu)",
            stats = "18% Máu, 60% Chặn, 25% Miễn khống",
            bonus = { hpPct = 18, block = 60, ci = 25 }
        }
        local artBaDaoDo = {
            key = 68,
            name = "Bá Đao Râu Trắng (Đỏ VIP - Chí Mạng)",
            stats = "21% Công, 15% Chí mạng, 50% ST Chí mạng",
            bonus = { atkPct = 21, crit = 15, cd = 50 }
        }

        local candidates = {}
        if clsId == 4 then
            candidates = { artDieuSu, artChopper, artYasopp, artDurandal, artPhiThuy, artDoflamingo }
        elseif clsId == 5 then
            candidates = { artYasopp, artChopper, artDieuSu, artMogura, artDoflamingo, artPhiThuy }
        elseif clsId == 2 then
            candidates = { artDieuSu, artBdHT, artMogura, artBdTT, artDurandal, artPhiThuy }
        else
            candidates = { artBdTT, artDieuSu, artMogura, artBdHT, artPhiThuy, artBaDaoDo, artDurandal }
        end

        if facId == 2 then
            table.insert(candidates, {
                key = 119,
                name = "Tam Kiếm (Đỏ Siêu VIP - Kích hệ Minh Mẫn)",
                stats = "15% Công, 15% Máu + Kích hệ Minh Mẫn: 50% Phá giáp",
                bonus = { atkPct = 15, hpPct = 15, ab = 50 }
            })
            table.insert(candidates, {
                key = 117,
                name = "Vòng Ngọc Quý (Đỏ Siêu VIP - Kích hệ Minh Mẫn)",
                stats = "70 Tốc độ, 20% Máu + Kích hệ Minh Mẫn: 20% Giảm ST",
                bonus = { hpPct = 20, speed = 70, rd = 20 }
            })
        elseif facId == 1 then
            table.insert(candidates, {
                key = 114,
                name = "Rìu Đầu Lâu (Đỏ Siêu VIP - Kích hệ Thông Minh)",
                stats = "50% Chặn, 25% Máu + Kích hệ Thông Minh: 18% Công",
                bonus = { atkPct = 18, hpPct = 25, block = 50 }
            })
        end

        local obtainableRecs = {}
        local allRecs = {}
        for _, cand in ipairs(candidates) do
            local ok, whereTxt = _G.HTPS_CheckArtifactObtainable(cand.key)
            local item = {
                key = cand.key,
                name = cand.name,
                stats = cand.stats,
                where = whereTxt,
                obtainable = ok,
                bonus = cand.bonus
            }
            table.insert(allRecs, item)
            if ok and #obtainableRecs < 6 then
                table.insert(obtainableRecs, item)
            end
        end

        if #obtainableRecs > 0 then
            return obtainableRecs
        end
        return allRecs
    end

    _G.HTPS_ShowInspectorPopup = function(titleText, bodyText, optionalHeroModel)
        pcall(function()
            local oldHelp = GO.Find("PopupHelp(Clone)")
            if oldHelp then GO.DestroyImmediate(oldHelp) end

            CS.PopupHelp.showYourself(bodyText)
            local phGo = GO.Find("PopupHelp(Clone)")
            if not phGo then return end
            phGo.transform:SetAsLastSibling()

            local ph = phGo:GetComponent(typeof(CS.PopupHelp))
            if ph then
                local tTitle = ph:GetType():GetField("m_TextTitle", REF_FLAGS):GetValue(ph)
                if tTitle then
                    local loc = tTitle.gameObject:GetComponent(typeof(CS.I2.Loc.Localize))
                    if loc then UG.Object.DestroyImmediate(loc) end
                    tTitle.text = titleText
                end
                local tContent = ph:GetType():GetField("content_lb", REF_FLAGS):GetValue(ph)
                if tContent then
                    tContent.supportRichText = true
                    tContent.fontSize = 18
                    tContent.lineSpacing = 1.15
                end
            end

            if optionalHeroModel then
                local contentGo = ph and ph:GetType():GetField("m_GoContent", REF_FLAGS):GetValue(ph)
                if contentGo then
                    local ppiGo = GO.Find("PopupPlayerInfo(Clone)") or GO.Find("PopupPlayerInfo3(Clone)")
                    local tplBtn = nil
                    if ppiGo then
                        local c1 = ppiGo:GetComponent(typeof(CS.PopupPlayerInfo)) or ppiGo:GetComponent(typeof(CS.PopupPlayerInfo3))
                        if c1 then
                            tplBtn = c1:GetType():GetField("m_GoButton1", REF_FLAGS):GetValue(c1)
                        end
                    end
                    if tplBtn then
                        local cloneBtn = GO.Instantiate(tplBtn, contentGo.transform, false)
                        cloneBtn.name = "BtnHTPSViewSkillOrig"
                        cloneBtn:SetActive(true)
                        local rt = cloneBtn:GetComponent(typeof(UG.RectTransform))
                        rt.anchorMin = UG.Vector2(0.5, 0.5)
                        rt.anchorMax = UG.Vector2(0.5, 0.5)
                        rt.pivot = UG.Vector2(0.5, 0.5)
                        rt.anchoredPosition = UG.Vector2(0, -235)
                        rt.sizeDelta = UG.Vector2(250, 48)
                        local txt = cloneBtn:GetComponentInChildren(typeof(UG.UI.Text), true)
                        if txt then
                            local loc = txt.gameObject:GetComponent(typeof(CS.I2.Loc.Localize))
                            if loc then UG.Object.DestroyImmediate(loc) end
                            txt.fontSize = 17
                            txt.text = "Xem Bảng Kỹ Năng Tướng"
                        end
                        local bc = cloneBtn:GetComponent(typeof(UG.UI.Button))
                        bc.onClick = UG.UI.Button.ButtonClickedEvent()
                        bc.onClick:AddListener(function()
                            pcall(function()
                                CS.PopupHeroBriefInfo.ShowUp(optionalHeroModel)
                                local hbGo = GO.Find("PopupHeroBriefInfo(Clone)")
                                if hbGo then hbGo.transform:SetAsLastSibling() end
                            end)
                        end)
                    end
                end
            end
        end)
    end

    _G.HTPS_PREVIEW_META = _G.HTPS_PREVIEW_META or {}

    _G.HTPS_InspectHeroBuildAndBag = function(hm, slotIdx)
        pcall(function()
            if not hm or hm:IsModelNull() then return end
            local info = _G.HTPS_AnalyzeHeroInBag(hm)
            local gInfo = CLASS_GEAR_MAP[info.clsId] or CLASS_GEAR_MAP[1]
            local artRecs = _G.HTPS_GetRecommendedArtifactsForHero(info.facId, info.clsId)
            local db = CS.DbManager.GetInstance()
            local meta = _G.HTPS_PREVIEW_META[hm.m_HeroId]

            local lines = {}
            table.insert(lines, string.format("<size=21><b><color=#FFD700>[Vị trí #%s] %s — %s Lv.%d</color></b></size>",
                tostring(slotIdx or "?"), info.name, fmtStar(info.star), info.level))
            table.insert(lines, string.format("• <b>Hệ (Chính xác):</b> <color=#00FFFF>%s</color>   |   <b>Vai trò (Nghề):</b> <color=#00FF7F>%s</color>",
                info.facName, info.clsName))
            table.insert(lines, string.format("• <b>Mã Tướng:</b> 5★ Key = <b>%d</b> | 10★/E5 Key = <b>%d</b> (Cần tổng 9 bản 5★ để lên E5)",
                info.k5, info.k10))

            if meta and meta.hasServerGear then
                table.insert(lines, "")
                table.insert(lines, "<size=19><b><color=#FFA500>I. TRANG BỊ THẬT ĐANG MẶC TRÊN TƯỚNG NÀY:</color></b></size>")
                local eqNames = {}
                for _, ek in ipairs({hm.m_WeaponKey, hm.m_ArmorKey, hm.m_ShoesKey, hm.m_AccessoryKey}) do
                    if ek and ek > 0 then
                        local eqObj = db:GetItemEquipment(ek)
                        table.insert(eqNames, eqObj and tostring(eqObj.m_ItemName) or ("Equip#" .. tostring(ek)))
                    end
                end
                table.insert(lines, "• <b>Trang bị:</b> " .. ((#eqNames > 0) and table.concat(eqNames, ", ") or "Chưa mặc"))
                if hm.m_ArtifactKey and hm.m_ArtifactKey > 0 then
                    local aObj = db:GetItemArtifact(hm.m_ArtifactKey, math.max(1, hm.m_ArtifactStar or 1)) or db:GetItemArtifact(hm.m_ArtifactKey, 1)
                    table.insert(lines, "• <b>Bảo vật:</b> <color=#FFD700>" .. (aObj and tostring(aObj.m_ItemName) or tostring(hm.m_ArtifactKey)) .. " (★" .. tostring(hm.m_ArtifactStar) .. ")</color>")
                end
            end

            table.insert(lines, "")
            table.insert(lines, "<size=19><b><color=#00FF7F>I. KIỂM TRA TRONG KHO & RƯƠNG QUÀ CỦA BẠN:</color></b></size>")
            table.insert(lines, "• <b>Kho Tướng hiện có:</b> " .. info.ownedStr)
            if info.myEquippedNote then
                table.insert(lines, "  <i>(" .. info.myEquippedNote .. ")</i>")
            end
            if info.shardCount > 0 then
                table.insert(lines, string.format("• <b>Túi Mảnh ghép:</b> <color=#00FF7F><b>%d mảnh</b> (Ghép ngay được <b>%d bản 5★</b>!)</color>",
                    info.shardCount, info.shardCopies))
            else
                table.insert(lines, "• <b>Túi Mảnh ghép:</b> 0 mảnh")
            end
            if #info.chestList > 0 then
                table.insert(lines, "• <b>Nằm trong Rương Tự Chọn của bạn (Mở đúng Ô số sau):</b>")
                for _, cs in ipairs(info.chestList) do
                    table.insert(lines, "   + " .. cs)
                end
            else
                table.insert(lines, "• <b>Rương Tự Chọn:</b> <color=#FFA500>Không nằm trong rương SS L1/L2 (Kiếm qua Chiêu Mộ Hệ / Thay Thế Thùng Rượu / Mảnh Ghép)</color>")
            end

            table.insert(lines, "")
            table.insert(lines, "<size=19><b><color=#FFD700>II. BẢO VẬT, TRANG BỊ, ĐÁ HỘ MỆNH & HAKI CHUẨN CHÍNH XÁC:</color></b></size>")
            table.insert(lines, "• <b>1. Bộ Trang Bị 6★ Chuẩn Nghề (Kích hoạt đủ 4/4 món):</b> <color=#00FFFF><b>" .. gInfo.setName .. "</b></color>")
            table.insert(lines, "   + " .. _G.HTPS_CheckClassGearInBag(info.clsId))
            table.insert(lines, "• <b>2. Bảo Vật 6★ Kích Hệ Có Sẵn Trong Rương Của Bạn:</b>")
            for idx, ar in ipairs(artRecs) do
                table.insert(lines, string.format("   + <b>Phương án %d: <color=#FFD700>%s</color></b> (%s)", idx, ar.name, ar.stats))
                table.insert(lines, "      -> <b>Cách lấy ngay:</b> " .. ar.where)
            end
            table.insert(lines, "• <b>3. Đá Hộ Mệnh (Đá Cam 6★) Chuẩn:</b> <color=#00FFFF>" .. gInfo.stone .. "</color>")
            table.insert(lines, "• <b>4. Haki E1 -> E5 (Tab 4) Chuẩn:</b> <color=#00FF7F><b>" .. gInfo.talents .. "</b></color>")
            table.insert(lines, "   + <i>Chi tiết bảng Haki gốc: E1(1:+12% Máu | 2:+10% Công | 3:+30 Tốc) • E2(1:Giảm 15% ST CM | 2:Giảm 15% ST Đốt/Độc | 3:+15% Nhận hồi máu) • E3(1:Hồi 15% máu mất | 2:+3% Công/tướng sống | 3:50% Giải khống) • E4(1:+20% Công,+10% MK | 2:+20% Máu,+10% Giảm ST | 3:+100 Tốc) • E5(1:CM hồi 15% máu/Ko CM +100% ST | 2:Khiên bất tử 3 hit khi máu <50% | 3:30% hồi 100 Nộ)</i>")
            table.insert(lines, "• <b>5. Ấn & Nghề Hạm Đội:</b> " .. gInfo.voidNote .. " + Max 300 cấp Nghề <b>" .. info.clsName .. "</b>")

            local lstSk = info.refHm and info.refHm.m_ListSkillId
            if lstSk and lstSk.Count > 0 then
                table.insert(lines, "")
                table.insert(lines, "<size=19><b><color=#00FFFF>III. BỘ KỸ NĂNG CỦA TƯỚNG (Bấm nút dưới để xem chi tiết):</color></b></size>")
                for i = 0, lstSk.Count - 1 do
                    local sk = db:GetSkillModel(lstSk[i])
                    if sk then
                        local desc = tostring(sk.m_SkillDesc or ""):gsub("\n", " ")
                        table.insert(lines, string.format("• <b>Chiêu %d - <color=#FFD700>%s</color>:</b> %s",
                            i + 1, tostring(sk.m_SkillName), desc))
                    end
                end
            end

            _G.HTPS_ShowInspectorPopup("SOI TƯỚNG: BẢO VẬT • TRANG BỊ • ĐÁ • HAKI", table.concat(lines, "\n"), info.refHm)
        end)
    end

    _G.HTPS_InspectFullPlayerLineup = function(ppiComp, is3Team)
        pcall(function()
            if not ppiComp then return end
            local pt = ppiComp:GetType()
            local tName = pt:GetField("m_TextPlayername", REF_FLAGS):GetValue(ppiComp)
            local tId = pt:GetField("m_TextId", REF_FLAGS):GetValue(ppiComp)
            local tPow = pt:GetField("m_TextPower", REF_FLAGS):GetValue(ppiComp)
            local pName = (tName and tName.text ~= "") and tName.text or "Người chơi"
            local pId = (tId and tId.text ~= "") and tId.text or ""
            local pPow = (tPow and tPow.text ~= "") and tPow.text or ""

            local lineups = {}
            if is3Team then
                table.insert(lineups, { label = "ĐỘI HÌNH 1", hl = pt:GetField("m_HeroesLineup1", REF_FLAGS):GetValue(ppiComp) })
                table.insert(lineups, { label = "ĐỘI HÌNH 2", hl = pt:GetField("m_HeroesLineup2", REF_FLAGS):GetValue(ppiComp) })
                table.insert(lineups, { label = "ĐỘI HÌNH 3", hl = pt:GetField("m_HeroesLineup3", REF_FLAGS):GetValue(ppiComp) })
            else
                table.insert(lineups, { label = "ĐỘI HÌNH CHÍNH (6 VỊ TRÍ)", hl = pt:GetField("m_HeroesLineup", REF_FLAGS):GetValue(ppiComp) })
            end

            local lines = {}
            table.insert(lines, string.format("<size=20><b><color=#FFD700>NGƯỜI CHƠI: %s (%s) — Lực chiến: %s</color></b></size>", pName, pId, pPow))
            table.insert(lines, "<i><color=#00FFFF>💡 Mẹo: Bấm trực tiếp vào từng Avatar tướng để mở giao diện kiểm tra Trang Bị (4/4), Bảo Vật SS kích hệ, Đá Hộ Mệnh 6★ và bảng Haki E1->E5!</color></i>")

            for _, lu in ipairs(lineups) do
                if lu.hl then
                    table.insert(lines, "")
                    table.insert(lines, "<size=19><b><color=#00FF7F>=== " .. lu.label .. " ===</color></b></size>")
                    local lst = lu.hl:GetType():GetField("m_LstGoHeroHead", REF_FLAGS):GetValue(lu.hl)
                    local foundAny = false
                    if lst then
                        for i = 0, lst.Count - 1 do
                            local hgo = lst[i]
                            if hgo and hgo.activeSelf then
                                local hhc = hgo:GetComponent(typeof(CS.HeroHeadClickable))
                                local hm = hhc and hhc:GetType():GetField("m_HeroModel", REF_FLAGS):GetValue(hhc)
                                if hm and not hm:IsModelNull() and hm.m_HeroKey and hm.m_HeroKey > 0 then
                                    foundAny = true
                                    local info = _G.HTPS_AnalyzeHeroInBag(hm)
                                    local gInfo = CLASS_GEAR_MAP[info.clsId] or CLASS_GEAR_MAP[1]
                                    local artRecs = _G.HTPS_GetRecommendedArtifactsForHero(info.facId, info.clsId)
                                    local topArt = artRecs[1]
                                    local secArt = artRecs[2]

                                    table.insert(lines, string.format("<b><color=#FFD700>[Ô #%d] %s</color></b> (%s - Lv.%d) | Hệ: <color=#00FFFF>%s</color> | Nghề: <color=#00FF7F>%s</color>",
                                        i + 1, info.name, fmtStar(info.star), info.level, info.facName, info.clsName))
                                    local shardTxt = (info.shardCount > 0) and string.format("<color=#00FF7F>%d mảnh (%d bản 5★)</color>", info.shardCount, info.shardCopies) or "0 mảnh"
                                    table.insert(lines, string.format("   • <b>Kho của bạn:</b> %s | <b>Túi mảnh:</b> %s", info.ownedStr, shardTxt))
                                    if #info.chestList > 0 then
                                        table.insert(lines, "   • <b>Lấy Tướng ở Rương:</b> " .. table.concat(info.chestList, " ; "))
                                    else
                                        table.insert(lines, "   • <b>Lấy Tướng ở đâu:</b> Không có trong rương SS L1/L2 (Kiếm qua Chiêu mộ Hệ / Mảnh ghép)")
                                    end
                                    table.insert(lines, string.format("   • <b>Trang bị & Haki:</b> <color=#00FFFF>%s</color> | <b>Đá:</b> %s | <b>Haki:</b> <color=#00FF7F>%s</color>",
                                        gInfo.setName, gInfo.stone, gInfo.talents))
                                    if topArt then
                                        table.insert(lines, string.format("   • <b>Bảo vật #1 (Kích hệ):</b> <color=#FFD700>%s</color> -> %s", topArt.name, topArt.where))
                                    end
                                    if secArt then
                                        table.insert(lines, string.format("   • <b>Bảo vật #2 (Thay thế):</b> <color=#FFD700>%s</color> -> %s", secArt.name, secArt.where))
                                    end
                                end
                            end
                        end
                    end
                    if not foundAny then
                        table.insert(lines, "   <i>(Chưa tải xong đội hình hoặc đội hình đang ẩn)</i>")
                    end
                end
            end

            table.insert(lines, "")
            table.insert(lines, "<size=19><b><color=#FFD700>=== KHO RƯƠNG BẢO VẬT & TRANG BỊ THẬT TRONG TÚI CỦA BẠN ===</color></b></size>")
            local inv = CS.PlayerInventory.GetInstance()
            local db = CS.DbManager.GetInstance()
            local lstCons = inv:GetType():GetField("m_LstItemConsumable", REF_FLAGS):GetValue(inv)
            local anyChest = false
            if lstCons then
                for i = 0, lstCons.Count - 1 do
                    local ic = lstCons[i]
                    if ic and ic.m_Number > 0 and ic.m_BonusPreview then
                        local lstA = ic.m_BonusPreview:GetType():GetField("m_LstBonusArtifact", REF_FLAGS):GetValue(ic.m_BonusPreview)
                        local lstC = ic.m_BonusPreview:GetType():GetField("m_LstBonusConsumable", REF_FLAGS):GetValue(ic.m_BonusPreview)
                        if (lstA and lstA.Count > 0) or (lstC and lstC.Count > 0) then
                            anyChest = true
                            table.insert(lines, string.format("• <b><color=#00FF7F>%s</color> (Đang có sẵn: %d rương):</b>", tostring(ic.m_ItemName), ic.m_Number))
                            if lstC and lstC.Count > 0 then
                                local subNames = {}
                                for k = 0, lstC.Count - 1 do
                                    local bc = lstC[k]
                                    local subIc = bc and db:GetItemConsumable(bc.m_ItemKey)
                                    if subIc then
                                        table.insert(subNames, string.format("<b>Ô #%d:</b> %s", k + 1, tostring(subIc.m_ItemName)))
                                    end
                                end
                                if #subNames > 0 then
                                    table.insert(lines, "   + Chứa: " .. table.concat(subNames, " | "))
                                end
                            elseif lstA and lstA.Count > 0 then
                                table.insert(lines, string.format("   + Chứa %d Bảo vật Đỏ tự chọn (Vòng Phỉ Thúy Ô #61, Kiếm Durandal Ô #37, Áo Doflamingo Ô #65, Bá Đao Ô #51...)", lstA.Count))
                            end
                        end
                    end
                end
            end
            if not anyChest then
                table.insert(lines, "• <i>Hiện trong túi chưa có Rương Bảo Vật Tự Chọn.</i>")
            end

            _G.HTPS_ShowInspectorPopup("SOI ĐỘI HÌNH & ĐỐI CHIẾU RƯƠNG CỦA BẠN", table.concat(lines, "\n"), nil)
        end)
    end


    _G.HTPS_PREVIEW_ART_CYCLE = _G.HTPS_PREVIEW_ART_CYCLE or {}

    _G.HTPS_STONE_PRESETS = {
        {
            roleTag = "Công + Xuyên Thủ (Chuẩn Sát Thương/Roger)",
            stats = "1100 Công, 18% Công, 44% Xuyên Thủ",
            bonus = { atkPct = 18, ab = 44 }
        },
        {
            roleTag = "Chí Mạng + ST Chí Mạng (Chuẩn Sát Thủ)",
            stats = "20% Chí mạng, 52% Sát thương chí mạng, 4% Công",
            bonus = { atkPct = 4, crit = 20, cd = 52 }
        },
        {
            roleTag = "Công + Máu + ST Chuẩn (Đa Dụng Công-Thủ)",
            stats = "1100 Công, 22% Máu, 30% Sát thương chuẩn",
            bonus = { hpPct = 22, hd = 30 }
        },
        {
            roleTag = "Tốc Độ + Máu (Khống Chế / Hỗ Trợ Đi Trước)",
            stats = "23% Máu, 100 Tốc độ",
            bonus = { hpPct = 23, speed = 100 }
        },
        {
            roleTag = "Máu + Chặn (Đỡ Đòn / Đấu Sĩ Hàng Trước)",
            stats = "26% Máu, 25% Chặn",
            bonus = { hpPct = 26, block = 25 }
        },
        {
            roleTag = "Công + Chính Xác (Sát Thương Kỹ Năng)",
            stats = "1100 Công, 18% Công, 21% Chính xác",
            bonus = { atkPct = 18, prec = 21 }
        },
    }
    _G.HTPS_PREVIEW_STONE_CYCLE = _G.HTPS_PREVIEW_STONE_CYCLE or {}

    _G.HTPS_GetDefaultStonePresetIdx = function(curHm)
        local hName = tostring(curHm and curHm.m_HeroName or ""):lower()
        if hName:find("roger") or hName:find("hawk") or hName:find("mihawk") or hName:find("zoro") or hName:find("akainu") or hName:find("oden") then
            return 1
        end
        local clsId = enumToIntVal(curHm and curHm.m_Class)
        if clsId == 5 then
            return 5
        elseif clsId == 4 or clsId == 2 then
            return 4
        elseif clsId == 1 then
            return 2
        else
            return 3
        end
    end

    _G.HTPS_GetDefaultHakiPresetIdx = function(clsId)
        if clsId == 5 then
            return 3
        elseif clsId == 4 or clsId == 2 then
            return 2
        else
            return 1
        end
    end

    -- Tính toán lại chính xác toàn bộ chỉ số của tướng theo đúng Bộ Trang Bị + Bảo Vật + Đá Hộ Mệnh + Haki đang chọn
    _G.HTPS_RecalcPreviewHeroStats = function(hm)
        pcall(function()
            if not hm then return end
            local meta = _G.HTPS_PREVIEW_META[hm.m_HeroId]
            if not meta or meta.hasServerStats then return end

            local facId = enumToIntVal(hm.m_Faction)
            local clsId = enumToIntVal(hm.m_Class)
            local star = hm.m_Star or 15

            local baseAtk = meta.baseAtk or 92000
            local baseHp = meta.baseHp or 1850000
            local baseArm = meta.baseArm or 2600
            local baseSpd = meta.baseSpd or 1680

            local atkPct = 240 -- EpicEquip + GuildTech
            local hpPct = 240
            local spdFlat = (star >= 15) and 520 or 260
            local crit = 15
            local cd = 20
            local sd = 20
            local prec = 15
            local block = 15
            local ab = 0
            local ci = 10
            local rd = 10
            local hd = 0

            -- 1. Cộng chỉ số từ Bộ Trang Bị (Nghề 6★ vs Hải Âu 6★)
            if meta.gearMode == "class" then
                atkPct = atkPct + 27
                hpPct = hpPct + 26
                spdFlat = spdFlat + 20
                if clsId == 1 then crit = crit + 10; cd = cd + 10; sd = sd + 14
                elseif clsId == 2 then prec = prec + 10; sd = sd + 20
                elseif clsId == 3 then crit = crit + 5; ab = ab + 15; prec = prec + 10
                elseif clsId == 4 then hpPct = hpPct + 12; rd = rd + 10
                elseif clsId == 5 then block = block + 15; rd = rd + 10 end
            else
                atkPct = atkPct + 21
                hpPct = hpPct + 24
            end

            -- 2. Cộng chỉ số từ Bảo Vật đang đeo
            local artRecs = _G.HTPS_GetRecommendedArtifactsForHero(facId, clsId)
            local curArtIdx = _G.HTPS_PREVIEW_ART_CYCLE[hm.m_HeroId] or 1
            local chosenArt = artRecs[curArtIdx]
            if chosenArt and chosenArt.bonus then
                local b = chosenArt.bonus
                atkPct = atkPct + (b.atkPct or 0)
                hpPct = hpPct + (b.hpPct or 0)
                spdFlat = spdFlat + (b.speed or 0)
                crit = crit + (b.crit or 0)
                cd = cd + (b.cd or 0)
                sd = sd + (b.sd or 0)
                prec = prec + (b.prec or 0)
                block = block + (b.block or 0)
                ab = ab + (b.ab or 0)
                ci = ci + (b.ci or 0)
                rd = rd + (b.rd or 0)
                hd = hd + (b.hd or 0)
            end

            -- 3. Cộng chỉ số từ Đá Hộ Mệnh 6★ đang đeo
            local curStoneIdx = _G.HTPS_PREVIEW_STONE_CYCLE[hm.m_HeroId] or _G.HTPS_GetDefaultStonePresetIdx(hm)
            local stPreset = _G.HTPS_STONE_PRESETS[curStoneIdx]
            if stPreset and stPreset.bonus then
                local sb = stPreset.bonus
                atkPct = atkPct + (sb.atkPct or 0)
                hpPct = hpPct + (sb.hpPct or 0)
                spdFlat = spdFlat + (sb.speed or 0)
                crit = crit + (sb.crit or 0)
                cd = cd + (sb.cd or 0)
                prec = prec + (sb.prec or 0)
                block = block + (sb.block or 0)
                ab = ab + (sb.ab or 0)
                hd = hd + (sb.hd or 0)
            end

            -- 4. Cộng chỉ số từ Haki E1 -> E5 đang chọn
            local es = hm:GetListIndexESkill()
            if es and es.Count >= 4 then
                if es[0] == 0 then hpPct = hpPct + 12
                elseif es[0] == 1 then atkPct = atkPct + 10
                elseif es[0] == 2 then spdFlat = spdFlat + 30 end

                if es[3] == 0 then atkPct = atkPct + 20; ci = ci + 10
                elseif es[3] == 1 then hpPct = hpPct + 20; rd = rd + 10
                elseif es[3] == 2 then spdFlat = spdFlat + 100 end
            end

            local starScale = (star >= 15) and 1.85 or ((star >= 13) and 1.35 or ((star >= 10) and 1.0 or 0.55))
            hm.mp_Attack = math.floor((baseAtk * (1 + atkPct / 100) + 270000) * starScale)
            hm.mp_Hp = math.floor((baseHp * (1 + hpPct / 100) + 8100000) * starScale)
            hm.mp_Armor = math.floor(baseArm * 1.45)
            hm.mp_Speed = math.floor(baseSpd + spdFlat)
            hm.mp_PowerFromServer = math.floor(hm.mp_Attack * 2.2 + hm.mp_Hp * 0.1)

            hm.mp_Crit = crit
            hm.mp_CritDamage = cd
            hm.mp_SkillDamage = sd
            hm.mp_Precision = prec
            hm.mp_Block = block
            hm.mp_ArmorBreak = ab
            hm.mp_ControlImmune = ci
            hm.mp_ReduceDamage = math.min(70, rd)
            hm.mp_HolyDamage = hd
        end)
    end

    _G.HTPS_BuildPreviewHeroModel = function(origHm, slotIdx)
        local db = CS.DbManager.GetInstance()
        local heroKey = origHm.m_HeroKey
        local k5, k10 = resolveHero5And10Key(heroKey)
        local hm = db:GetHeroModelCopy(heroKey) or db:GetHeroModelCopy(k10) or db:GetHeroModelCopy(k5) or origHm:Clone()
        if hm.lstMaxPoint then
            pcall(function() hm:CalculateMaxHero(hm.lstMaxPoint) end)
        end

        local star = (origHm.m_Star and origHm.m_Star > 0) and origHm.m_Star or 15
        local level = (origHm.m_Level and origHm.m_Level > 0) and origHm.m_Level or 330
        hm.m_HeroId = -9900 - (slotIdx or 1)
        hm:SetStar(star)
        hm:SetTier(6)
        hm.m_Level = level
        hm.m_MaxLevel = math.max(level, hm:CalculateMaxLevelByStarAndTier())

        if origHm.m_EquipedSkinKey and origHm.m_EquipedSkinKey > 0 then
            hm.m_EquipedSkinKey = origHm.m_EquipedSkinKey
        end

        local facId = enumToIntVal(hm.m_Faction)
        local clsId = enumToIntVal(hm.m_Class)
        local gInfo = CLASS_GEAR_MAP[clsId] or CLASS_GEAR_MAP[1]
        local artRecs = _G.HTPS_GetRecommendedArtifactsForHero(facId, clsId)
        local defaultArt = artRecs[1]

        local hasServerGear = (origHm.m_WeaponKey and origHm.m_WeaponKey > 0) or (origHm.m_ArtifactKey and origHm.m_ArtifactKey > 0)
        local hasServerStats = (origHm.mp_Attack and origHm.mp_Attack > 150000)
        _G.HTPS_PREVIEW_META[hm.m_HeroId] = {
            hasServerGear = hasServerGear,
            hasServerStats = hasServerStats,
            gearMode = "class",
            baseAtk = math.max(hm.mp_Attack or 90000, 85000),
            baseHp = math.max(hm.mp_Hp or 1800000, 1600000),
            baseArm = math.max(hm.mp_Armor or 2500, 2400),
            baseSpd = math.max(hm.mp_Speed or 1650, 1620),
        }
        _G.HTPS_PREVIEW_ART_CYCLE[hm.m_HeroId] = 1
        _G.HTPS_PREVIEW_STONE_CYCLE[hm.m_HeroId] = _G.HTPS_GetDefaultStonePresetIdx(hm)
        _G.HTPS_PREVIEW_HAKI_CYCLE[hm.m_HeroId] = _G.HTPS_GetDefaultHakiPresetIdx(clsId)

        -- 1. Trang bị chuẩn 6 sao theo Nghề (hoặc giữ nguyên nếu có dữ liệu thật từ Server)
        if origHm.m_WeaponKey and origHm.m_WeaponKey > 0 then
            hm.m_WeaponKey = origHm.m_WeaponKey
            hm.m_ArmorKey = origHm.m_ArmorKey
            hm.m_ShoesKey = origHm.m_ShoesKey
            hm.m_AccessoryKey = origHm.m_AccessoryKey
        else
            for _, ek in ipairs(gInfo.keys) do
                local eqObj = db:GetItemEquipment(ek)
                if eqObj then
                    local eqTypeInt = enumToIntVal(eqObj.m_Type)
                    if eqTypeInt == 4 then hm.m_WeaponKey = ek
                    elseif eqTypeInt == 3 then hm.m_ArmorKey = ek
                    elseif eqTypeInt == 2 then hm.m_ShoesKey = ek
                    elseif eqTypeInt == 1 then hm.m_AccessoryKey = ek end
                end
            end
        end

        -- 2. Bảo vật 6★ Kích Hệ chuẩn trong Rương của bạn
        if origHm.m_ArtifactKey and origHm.m_ArtifactKey > 0 then
            hm.m_ArtifactKey = origHm.m_ArtifactKey
            hm.m_ArtifactStar = (origHm.m_ArtifactStar and origHm.m_ArtifactStar > 0) and origHm.m_ArtifactStar or 6
        else
            hm.m_ArtifactKey = defaultArt and defaultArt.key or 111
            hm.m_ArtifactStar = 6
        end

        -- 3. Đá Hộ Mệnh (Đá Cam 6★)
        hm.m_StoneId = (origHm.m_StoneId and origHm.m_StoneId > 0) and origHm.m_StoneId or 20

        -- 4. Haki E1 -> E5 (Gán đúng vào trường m_ListIndexESkillActive của C# HeroModel!)
        local origEs = origHm:GetListIndexESkill()
        local esList = CS.System.Collections.Generic.List(typeof(CS.System.Int32))()
        if origEs and origEs.Count > 0 then
            for i = 0, origEs.Count - 1 do
                esList:Add(origEs[i])
            end
        else
            local hakiPreset = _G.HTPS_HAKI_PRESETS[_G.HTPS_PREVIEW_HAKI_CYCLE[hm.m_HeroId]] or _G.HTPS_HAKI_PRESETS[1]
            local maxE = math.max(0, math.min(5, star - 10))
            for i = 1, 5 do
                if i <= maxE or star >= 15 then
                    esList:Add(hakiPreset.indices[i])
                end
            end
        end
        local fEs = hm:GetType():GetField("m_ListIndexESkillActive", REF_FLAGS)
        if fEs then
            fEs:SetValue(hm, esList)
        end

        -- 5. Trang bị đặc thù (Vai trò & Nhóm hạng Max 300 cấp - 15 sao)
        local ee = CS.EpicEquipment()
        ee.isLock = false
        ee.attackLevel = 300
        ee.attackTier = 15
        ee.attackNormal = 270000
        ee.attackPercent = 240
        ee.hpLevel = 300
        ee.hpTier = 15
        ee.hpNormal = 8100000
        ee.hpPercent = 240
        ee.maxLevelEnhance = 300
        ee.maxLeveUpgrade = 15
        hm.epicEquipment = ee

        if hasServerStats then
            hm.mp_Attack = origHm.mp_Attack
            hm.mp_Hp = origHm.mp_Hp
            hm.mp_Armor = origHm.mp_Armor
            hm.mp_Speed = origHm.mp_Speed
            hm.mp_PowerFromServer = origHm:GetPower()
        else
            _G.HTPS_RecalcPreviewHeroStats(hm)
        end

        return hm
    end

    _G.HTPS_PopulatePreviewStonePopup = function(phsiGo, curHm, slotIdx)
        pcall(function()
            if not phsiGo or not curHm then return end
            phsiGo.transform:SetAsLastSibling()
            local phsi = phsiGo:GetComponent(typeof(CS.PopupHeroStoneInfo))
            if not phsi then return end
            local curStoneIdx = _G.HTPS_PREVIEW_STONE_CYCLE[curHm.m_HeroId] or _G.HTPS_GetDefaultStonePresetIdx(curHm)
            _G.HTPS_PREVIEW_STONE_CYCLE[curHm.m_HeroId] = curStoneIdx
            local preset = _G.HTPS_STONE_PRESETS[curStoneIdx] or _G.HTPS_STONE_PRESETS[1]

            local tTitle = phsi:GetType():GetField("m_TextTitle", REF_FLAGS):GetValue(phsi)
            if tTitle then
                local loc = tTitle.gameObject:GetComponent(typeof(CS.I2.Loc.Localize))
                if loc then UG.Object.DestroyImmediate(loc) end
                local chk = tTitle.gameObject:GetComponent(typeof(CS.TextLocalizeChecker))
                if chk then UG.Object.DestroyImmediate(chk) end
                tTitle.text = "Đá Cam (6★ Max)"
            end

            local tInfo = phsi:GetType():GetField("m_TextInfo", REF_FLAGS):GetValue(phsi)
            if tInfo then
                local loc = tInfo.gameObject:GetComponent(typeof(CS.I2.Loc.Localize))
                if loc then UG.Object.DestroyImmediate(loc) end
                local chk = tInfo.gameObject:GetComponent(typeof(CS.TextLocalizeChecker))
                if chk then UG.Object.DestroyImmediate(chk) end
                tInfo.supportRichText = true
                tInfo.fontSize = 18
                tInfo.text = string.format("Đá hộ mệnh\n<color=#FFD700>[Chuẩn %d/%d: %s]</color>", curStoneIdx, #_G.HTPS_STONE_PRESETS, preset.roleTag)
            end

            local tDesc = phsi:GetType():GetField("m_TextDesc", REF_FLAGS):GetValue(phsi)
            if tDesc then
                local loc = tDesc.gameObject:GetComponent(typeof(CS.I2.Loc.Localize))
                if loc then UG.Object.DestroyImmediate(loc) end
                local chk = tDesc.gameObject:GetComponent(typeof(CS.TextLocalizeChecker))
                if chk then UG.Object.DestroyImmediate(chk) end
                tDesc.supportRichText = true
                tDesc.fontSize = 22
                tDesc.text = "<color=#12FE21><b>" .. preset.stats .. "</b></color>\n<size=16><color=#00FFFF>(Nâng cấp bằng Bụi Ma Thuật + Vàng tại Tab Trang Bị)</color></size>"
            end

            for _, fn in ipairs({"m_TextAction1", "m_TextAction2"}) do
                local tAct = phsi:GetType():GetField(fn, REF_FLAGS):GetValue(phsi)
                if tAct then
                    local loc = tAct.gameObject:GetComponent(typeof(CS.I2.Loc.Localize))
                    if loc then UG.Object.DestroyImmediate(loc) end
                    local chk = tAct.gameObject:GetComponent(typeof(CS.TextLocalizeChecker))
                    if chk then UG.Object.DestroyImmediate(chk) end
                    tAct.fontSize = 19
                end
            end

            phsi:SetAction(
                string.format("Đổi Đá (%d/%d)", curStoneIdx, #_G.HTPS_STONE_PRESETS),
                function()
                    local nxt = (curStoneIdx % #_G.HTPS_STONE_PRESETS) + 1
                    _G.HTPS_PREVIEW_STONE_CYCLE[curHm.m_HeroId] = nxt
                    _G.HTPS_RecalcPreviewHeroStats(curHm)
                    local phiGo = GO.Find("PanelHeroInfo(Clone)")
                    if phiGo then _G.HTPS_SyncPreviewHeroInfoUI(phiGo) end
                    CsCoroutine.start(function()
                        coroutine.yield(nil)
                        _G.HTPS_OpenPreviewStonePopup(curHm, nil, slotIdx)
                    end)
                end,
                "Xem Build",
                function()
                    CsCoroutine.start(function()
                        coroutine.yield(nil)
                        _G.HTPS_InspectHeroBuildAndBag(curHm, slotIdx)
                    end)
                end
            )
        end)
    end

    _G.HTPS_OpenPreviewStonePopup = function(curHm, stObj, slotIdx)
        pcall(function()
            if not curHm then return end
            while true do
                local oldS = GO.Find("PopupHeroStoneInfo(Clone)")
                if not oldS then break end
                GO.DestroyImmediate(oldS)
            end
            local db = CS.DbManager.GetInstance()
            local stoneModel = stObj or db:GetHeroStoneModelCopy((curHm.m_StoneId and curHm.m_StoneId > 0) and curHm.m_StoneId or 20)
            if not stoneModel then return end
            CS.PopupHeroStoneInfo.ShowUp(curHm.m_HeroId, stoneModel)
            local phsiGo = GO.Find("PopupHeroStoneInfo(Clone)")
            if phsiGo then
                _G.HTPS_PopulatePreviewStonePopup(phsiGo, curHm, slotIdx)
            end
            CsCoroutine.start(function()
                coroutine.yield(nil)
                local phsiGo2 = GO.Find("PopupHeroStoneInfo(Clone)")
                if phsiGo2 then
                    _G.HTPS_PopulatePreviewStonePopup(phsiGo2, curHm, slotIdx)
                end
            end)
        end)
    end

    _G.HTPS_OpenPreviewItemPopup = function(itemObj, curHm, extraNote, actionLabel, actionCb, action2Label, action2Cb)
        pcall(function()
            while true do
                local oldP = GO.Find("PopupItemInfo(Clone)")
                if not oldP then break end
                GO.DestroyImmediate(oldP)
            end
            while true do
                local oldS = GO.Find("PopupSelectArtifact(Clone)") or GO.Find("PopupSelectEquipment(Clone)")
                if not oldS then break end
                GO.DestroyImmediate(oldS)
            end
            CS.PopupItemInfo.ShowUp(itemObj, curHm.m_Faction, curHm.m_Class)

            local function formatPopup(piiGo)
                if not piiGo then return end
                piiGo.transform:SetAsLastSibling()
                local pii = piiGo:GetComponent(typeof(CS.PopupItemInfo))
                if not pii then return end

                local tDesc = pii:GetType():GetField("m_TextDesc", REF_FLAGS):GetValue(pii)
                if tDesc then
                    tDesc.supportRichText = true
                    local rawTxt = tostring(tDesc.text or "")
                    -- Bật sáng màu xanh lá (#12FE21) cho dòng Kích hoạt hạn chế Hệ / Vai trò
                    rawTxt = rawTxt:gsub('"#8a8282"', '"#12FE21"'):gsub("#8a8282", "#12FE21")
                    if extraNote and extraNote ~= "" and not rawTxt:find("%[Kho", 1) and not rawTxt:find("%[Có sẵn", 1) and not rawTxt:find("%[Phương án", 1) then
                        rawTxt = rawTxt .. "\n\n" .. extraNote
                    end
                    tDesc.text = rawTxt
                end

                -- Nếu là Trang bị (ItemEquipment): bật sáng đủ 3 dòng kích hoạt Bộ (4/4) màu xanh lá
                local tSet = pii:GetType():GetField("m_TextEquipmentSet", REF_FLAGS):GetValue(pii)
                local lstEff = pii:GetType():GetField("m_LstTextEquipmentSetEffect", REF_FLAGS):GetValue(pii)
                local grpSet = pii:GetType():GetField("m_GoGroupEquipmentSet", REF_FLAGS):GetValue(pii)
                if grpSet and grpSet.activeSelf and lstEff then
                    if tSet then
                        local locS = tSet.gameObject:GetComponent(typeof(CS.I2.Loc.Localize))
                        if locS then UG.Object.DestroyImmediate(locS) end
                        tSet.supportRichText = true
                        tSet.text = "<color=#FFD700>Trang bị theo bộ (4/4 - Đã kích hoạt đủ bộ)</color>"
                    end
                    local greenCol = UG.Color(0.07, 0.99, 0.13, 1)
                    for i = 0, lstEff.Count - 1 do
                        if lstEff[i] then
                            lstEff[i].color = greenCol
                        end
                    end
                end

                for _, fn in ipairs({"m_TextAction1", "m_TextAction2"}) do
                    local tAct = pii:GetType():GetField(fn, REF_FLAGS):GetValue(pii)
                    if tAct then
                        local loc = tAct.gameObject:GetComponent(typeof(CS.I2.Loc.Localize))
                        if loc then UG.Object.DestroyImmediate(loc) end
                        local chk = tAct.gameObject:GetComponent(typeof(CS.TextLocalizeChecker))
                        if chk then UG.Object.DestroyImmediate(chk) end
                        tAct.fontSize = 18
                    end
                end
                if actionLabel and actionCb then
                    pii:SetAction(actionLabel, actionCb, action2Label, action2Cb, false)
                else
                    pii:HideActions()
                end
            end

            local piiGo = GO.Find("PopupItemInfo(Clone)")
            if piiGo then formatPopup(piiGo) end
            CsCoroutine.start(function()
                coroutine.yield(nil)
                local piiGo2 = GO.Find("PopupItemInfo(Clone)")
                if piiGo2 then formatPopup(piiGo2) end
            end)
        end)
    end

    _G.HTPS_SyncPreviewHeroInfoUI = function(phiGo)
        pcall(function()
            if not phiGo or not phiGo.activeInHierarchy then return end
            local phi = phiGo:GetComponent(typeof(CS.PanelHeroInfo))
            if not phi then return end
            local curHm = phi:GetType():GetField("currentHeroModel", REF_FLAGS):GetValue(phi)
            if not curHm or not curHm.m_HeroId or curHm.m_HeroId >= 0 then return end

            local slotIdx = math.abs(curHm.m_HeroId) - 9900
            local db = CS.DbManager.GetInstance()
            local info = _G.HTPS_AnalyzeHeroInBag(curHm)
            local gInfo = CLASS_GEAR_MAP[info.clsId] or CLASS_GEAR_MAP[1]
            local artRecs = _G.HTPS_GetRecommendedArtifactsForHero(info.facId, info.clsId)

            for _, bname in ipairs({"ButtonNoLock", "ButtonLocked", "ButtonShare"}) do
                local btf = phiGo.transform:Find(bname)
                if btf and btf.gameObject.activeSelf then btf.gameObject:SetActive(false) end
            end

            local lstHm = phi:GetType():GetField("m_LstHeroModel", REF_FLAGS):GetValue(phi)
            if lstHm and lstHm.Count > 1 then
                local btnNext = phiGo.transform:Find("ButtonNext")
                local btnPrev = phiGo.transform:Find("ButtonPrev")
                if btnNext and not btnNext.gameObject.activeSelf then btnNext.gameObject:SetActive(true) end
                if btnPrev and not btnPrev.gameObject.activeSelf then btnPrev.gameObject:SetActive(true) end
            end

            local rightPart = phiGo.transform:Find("RightPart")
            if not rightPart then return end
            local fg = rightPart:Find("FieldGold")
            local fs = rightPart:Find("FieldSpirit")
            if fg and fg.gameObject.activeSelf then fg.gameObject:SetActive(false) end
            if fs and fs.gameObject.activeSelf then fs.gameObject:SetActive(false) end

            local boxInfo = rightPart:Find("BoxInfo")
            if not boxInfo then return end

            local tabsTf = boxInfo:Find("Tabs")
            if tabsTf then
                if not tabsTf.gameObject.activeSelf then tabsTf.gameObject:SetActive(true) end
                for _, tname in ipairs({"TabPoint", "TabEquipment", "TabEnable", "TabESkill", "TabSpecialEquip"}) do
                    local t = tabsTf:Find(tname)
                    if t and not t.gameObject.activeSelf then t.gameObject:SetActive(true) end
                end
            end

            local peqTf = boxInfo:Find("PanelEquipment")
            local ppTf = boxInfo:Find("PanelPoint")
            local pesTf = boxInfo:Find("PanelESkill")
            local tplGreen = peqTf and peqTf:Find("ButtonQuickEquip") and peqTf:Find("ButtonQuickEquip").gameObject
            local tplYellow = peqTf and peqTf:Find("ButtonUnEquip") and peqTf:Find("ButtonUnEquip").gameObject

            if tplGreen and tplYellow then
                local btnEqTf = rightPart:Find("BtnHTPSQuickTabEq")
                if not btnEqTf then
                    local c1 = GO.Instantiate(tplGreen, rightPart, false)
                    c1.name = "BtnHTPSQuickTabEq"
                    c1:SetActive(true)
                    btnEqTf = c1.transform
                    local rt1 = btnEqTf:GetComponent(typeof(UG.RectTransform))
                    rt1.anchoredPosition = UG.Vector2(95, 290)
                    rt1.sizeDelta = UG.Vector2(225, 48)
                    local ph1 = btnEqTf:Find("PointHandQuickEquip")
                    if ph1 then ph1.gameObject:SetActive(false) end
                    local txt1 = btnEqTf:GetComponentInChildren(typeof(UG.UI.Text), true)
                    if txt1 then
                        local loc = txt1.gameObject:GetComponent(typeof(CS.I2.Loc.Localize))
                        if loc then UG.Object.DestroyImmediate(loc) end
                        local chk = txt1.gameObject:GetComponent(typeof(CS.TextLocalizeChecker))
                        if chk then UG.Object.DestroyImmediate(chk) end
                        txt1.fontSize = 17
                    end
                    local bc1 = btnEqTf:GetComponent(typeof(UG.UI.Button))
                    bc1.onClick = UG.UI.Button.ButtonClickedEvent()
                    bc1.onClick:AddListener(function()
                        if peqTf and peqTf.gameObject.activeSelf then
                            local tPt = tabsTf and tabsTf:Find("TabPoint")
                            if tPt then tPt:GetComponent(typeof(CS.TabButton)):ButtonTabClick() end
                        else
                            local tEq = tabsTf and tabsTf:Find("TabEquipment")
                            if tEq then tEq:GetComponent(typeof(CS.TabButton)):ButtonTabClick() end
                        end
                    end)
                end
                local txt1 = btnEqTf:GetComponentInChildren(typeof(UG.UI.Text), true)
                if txt1 then
                    txt1.text = (peqTf and peqTf.gameObject.activeSelf) and "Xem Chỉ Số & Chiêu" or "Xem Trang Bị & Đồ"
                end

                local btnBagTf = rightPart:Find("BtnHTPSQuickBagInfo")
                if not btnBagTf then
                    local c2 = GO.Instantiate(tplYellow, rightPart, false)
                    c2.name = "BtnHTPSQuickBagInfo"
                    c2:SetActive(true)
                    btnBagTf = c2.transform
                    local rt2 = btnBagTf:GetComponent(typeof(UG.RectTransform))
                    rt2.anchoredPosition = UG.Vector2(335, 290)
                    rt2.sizeDelta = UG.Vector2(225, 48)
                    local txt2 = btnBagTf:GetComponentInChildren(typeof(UG.UI.Text), true)
                    if txt2 then
                        local loc = txt2.gameObject:GetComponent(typeof(CS.I2.Loc.Localize))
                        if loc then UG.Object.DestroyImmediate(loc) end
                        local chk = txt2.gameObject:GetComponent(typeof(CS.TextLocalizeChecker))
                        if chk then UG.Object.DestroyImmediate(chk) end
                        txt2.fontSize = 17
                        txt2.text = "Kho & Rương (Ô #)"
                    end
                    local bc2 = btnBagTf:GetComponent(typeof(UG.UI.Button))
                    bc2.onClick = UG.UI.Button.ButtonClickedEvent()
                    bc2.onClick:AddListener(function()
                        local latestHm = phi:GetType():GetField("currentHeroModel", REF_FLAGS):GetValue(phi)
                        local sIdx = latestHm and (math.abs(latestHm.m_HeroId) - 9900) or 1
                        _G.HTPS_InspectHeroBuildAndBag(latestHm or curHm, sIdx)
                    end)
                end
            end

            -- 1. Cập nhật Tab 1 (PanelPoint: Chỉ số + Hộp Kho & Rương)
            if ppTf and ppTf.gameObject.activeSelf then
                local pp = ppTf:GetComponent(typeof(CS.PanelHeroPoint))
                if pp then
                    local tAtk = pp:GetType():GetField("m_TextAttack", REF_FLAGS):GetValue(pp)
                    local tHp = pp:GetType():GetField("m_TextHp", REF_FLAGS):GetValue(pp)
                    local tArm = pp:GetType():GetField("m_TextArmor", REF_FLAGS):GetValue(pp)
                    local tSpd = pp:GetType():GetField("m_TextSpeed", REF_FLAGS):GetValue(pp)
                    local tPow = pp:GetType():GetField("m_TextPower", REF_FLAGS):GetValue(pp)
                    if tAtk then tAtk.text = tostring(curHm.mp_Attack) end
                    if tHp then tHp.text = tostring(curHm.mp_Hp) end
                    if tArm then tArm.text = tostring(curHm.mp_Armor) end
                    if tSpd then tSpd.text = tostring(curHm.mp_Speed) end
                    if tPow then tPow.text = tostring(curHm:GetPower()) end
                end
                local boxMaxGo = pp and pp:GetType():GetField("m_GoBoxMaxLevel", REF_FLAGS):GetValue(pp)
                if boxMaxGo then
                    boxMaxGo:SetActive(true)
                    local rtM = boxMaxGo:GetComponent(typeof(UG.RectTransform))
                    rtM.sizeDelta = UG.Vector2(430, 56)
                    local tMaxTf = boxMaxGo.transform:Find("TextMax")
                    if tMaxTf then
                        local rtT = tMaxTf:GetComponent(typeof(UG.RectTransform))
                        if rtT then rtT.sizeDelta = UG.Vector2(415, 52) end
                        local tMax = tMaxTf:GetComponent(typeof(UG.UI.Text))
                        if tMax then
                            local locM = tMax.gameObject:GetComponent(typeof(CS.I2.Loc.Localize))
                            if locM then UG.Object.DestroyImmediate(locM) end
                            local chkM = tMax.gameObject:GetComponent(typeof(CS.TextLocalizeChecker))
                            if chkM then UG.Object.DestroyImmediate(chkM) end
                            tMax.supportRichText = true
                            tMax.fontSize = 15
                            local chestShort = (#info.chestList > 0) and info.chestList[1] or "<color=#FFA500>Không nằm trong rương SS L1/L2 (Bấm xem)</color>"
                            local shardShort = (info.shardCount > 0) and string.format("%d (%d bản)", info.shardCount, info.shardCopies) or "0"
                            tMax.text = string.format("<b>Kho:</b> %s | <b>Mảnh:</b> <color=#00FF7F>%s</color>\n%s",
                                info.ownedStr, shardShort, chestShort)
                        end
                    end
                    local btnMax = boxMaxGo:GetComponent(typeof(UG.UI.Button))
                    if not btnMax then
                        btnMax = boxMaxGo:AddComponent(typeof(UG.UI.Button))
                    end
                    if _G.HTPS_BOUND_BOXMAX_BTN ~= btnMax then
                        btnMax.onClick = UG.UI.Button.ButtonClickedEvent()
                        btnMax.onClick:AddListener(function()
                            local latestHm = phi:GetType():GetField("currentHeroModel", REF_FLAGS):GetValue(phi)
                            local sIdx = latestHm and (math.abs(latestHm.m_HeroId) - 9900) or 1
                            _G.HTPS_InspectHeroBuildAndBag(latestHm or curHm, sIdx)
                        end)
                        _G.HTPS_BOUND_BOXMAX_BTN = btnMax
                    end
                end
            end

            -- 2. Cập nhật Tab 2 (PanelEquipment: 4 món Đồ 6★ + Bảo vật 6★ Kích Hệ + Đá Cam 6★)
            if peqTf and peqTf.gameObject.activeSelf then
                local pEq = peqTf:GetComponent(typeof(CS.PanelHeroEquipment))
                if pEq then
                    local eqSyncKey = string.format("%d_%d_%d_%d", curHm.m_HeroId, curHm.m_WeaponKey or 0, curHm.m_ArtifactKey or 0, curHm.m_StoneId or 0)
                    if _G.HTPS_BOUND_EQUI_MAP[peqTf] ~= eqSyncKey then
                        _G.HTPS_BOUND_EQUI_MAP[peqTf] = eqSyncKey

                        local lstSlots = pEq:GetType():GetField("m_LstSlotEquipment", REF_FLAGS):GetValue(pEq)
                        local keyByName = {
                            SlotWeapon = curHm.m_WeaponKey,
                            SlotArmor = curHm.m_ArmorKey,
                            SlotShoes = curHm.m_ShoesKey,
                            SlotAccessory = curHm.m_AccessoryKey,
                        }
                        if lstSlots then
                            for i = 0, lstSlots.Count - 1 do
                                local sl = lstSlots[i]
                                local k = keyByName[sl.gameObject.name]
                                if k and k > 0 then
                                    local eqObj = db:GetItemEquipmentCopy(k) or db:GetItemEquipment(k)
                                    if eqObj then
                                        eqObj.m_NumberUsed = 4
                                        eqObj.m_Number = 1
                                        sl:GetType():GetField("m_ItemEquipment", REF_FLAGS):SetValue(sl, eqObj)
                                        local goItem = sl:GetType():GetField("m_GoItemEquipment", REF_FLAGS):GetValue(sl)
                                        if goItem and not goItem.activeSelf then goItem:SetActive(true) end
                                        local eqUI = sl:GetType():GetField("m_EquipmentUI", REF_FLAGS):GetValue(sl)
                                        local openEqCb = function()
                                            local latestHm = phi:GetType():GetField("currentHeroModel", REF_FLAGS):GetValue(phi) or curHm
                                            local lInfo = _G.HTPS_AnalyzeHeroInBag(latestHm)
                                            local meta = _G.HTPS_PREVIEW_META[latestHm.m_HeroId] or { gearMode = "class" }
                                            local note = "<color=#00FF7F><b>[Kho & Rương Trang Bị của bạn]:</b></color>\n• " .. _G.HTPS_CheckClassGearInBag(lInfo.clsId)
                                            local toggleLabel = (meta.gearMode == "class") and "Đổi Bộ Hải Âu 6★" or "Đổi Bộ Nghề 6★"
                                            _G.HTPS_OpenPreviewItemPopup(eqObj, latestHm, note, toggleLabel, function()
                                                local lGi = CLASS_GEAR_MAP[lInfo.clsId] or CLASS_GEAR_MAP[1]
                                                if meta.gearMode == "class" then
                                                    meta.gearMode = "haiau"
                                                    latestHm.m_WeaponKey = 20
                                                    latestHm.m_ArmorKey = 41
                                                    latestHm.m_ShoesKey = 62
                                                    latestHm.m_AccessoryKey = 83
                                                else
                                                    meta.gearMode = "class"
                                                    for _, ek in ipairs(lGi.keys) do
                                                        local eo = db:GetItemEquipment(ek)
                                                        if eo then
                                                            local et = enumToIntVal(eo.m_Type)
                                                            if et == 4 then latestHm.m_WeaponKey = ek
                                                            elseif et == 3 then latestHm.m_ArmorKey = ek
                                                            elseif et == 2 then latestHm.m_ShoesKey = ek
                                                            elseif et == 1 then latestHm.m_AccessoryKey = ek end
                                                        end
                                                    end
                                                end
                                                _G.HTPS_PREVIEW_META[latestHm.m_HeroId] = meta
                                                _G.HTPS_RecalcPreviewHeroStats(latestHm)
                                                _G.HTPS_BOUND_EQUI_MAP[peqTf] = nil
                                                _G.HTPS_SyncPreviewHeroInfoUI(phiGo)
                                                local newEq = db:GetItemEquipmentCopy(latestHm.m_WeaponKey) or db:GetItemEquipment(latestHm.m_WeaponKey)
                                                if newEq then
                                                    newEq.m_NumberUsed = 4
                                                    newEq.m_Number = 1
                                                    _G.HTPS_OpenPreviewItemPopup(newEq, latestHm, note,
                                                        (meta.gearMode == "class") and "Đổi Bộ Hải Âu 6★" or "Đổi Bộ Nghề 6★",
                                                        function() _G.HTPS_InspectHeroBuildAndBag(latestHm, math.abs(latestHm.m_HeroId) - 9900) end,
                                                        "Xem Hướng Dẫn",
                                                        function() _G.HTPS_InspectHeroBuildAndBag(latestHm, math.abs(latestHm.m_HeroId) - 9900) end)
                                                end
                                            end, "Xem Hướng Dẫn", function()
                                                _G.HTPS_InspectHeroBuildAndBag(latestHm, math.abs(latestHm.m_HeroId) - 9900)
                                            end)
                                        end
                                        local btnSl = sl.gameObject:GetComponent(typeof(UG.UI.Button))
                                        if btnSl then
                                            btnSl.onClick = UG.UI.Button.ButtonClickedEvent()
                                            btnSl.onClick:AddListener(openEqCb)
                                        end
                                        if eqUI then
                                            eqUI:SetItemEquipment(eqObj, false)
                                            pcall(function() eqUI:SetClickCallback(openEqCb) end)
                                            local btnUI = eqUI.gameObject:GetComponent(typeof(UG.UI.Button))
                                            if btnUI then
                                                btnUI.onClick = UG.UI.Button.ButtonClickedEvent()
                                                btnUI.onClick:AddListener(openEqCb)
                                            end
                                        end
                                        local goNoti = sl:GetType():GetField("m_GoNotification", REF_FLAGS):GetValue(sl)
                                        if goNoti and goNoti.activeSelf then goNoti:SetActive(false) end
                                    end
                                end
                            end
                        end

                        -- Slot Bảo Vật
                        local slArt = pEq:GetType():GetField("m_SlotArtifact", REF_FLAGS):GetValue(pEq)
                        if slArt and curHm.m_ArtifactKey and curHm.m_ArtifactKey > 0 then
                            local artStar = math.max(1, curHm.m_ArtifactStar or 6)
                            local artObj = db:GetItemArtifact(curHm.m_ArtifactKey, artStar) or db:GetItemArtifact(curHm.m_ArtifactKey, 1)
                            if artObj then
                                artObj.m_Star = artStar
                                artObj.m_Number = 1
                                slArt:SetItemArtifact(curHm.m_HeroId, artObj)
                                local goNotiA = slArt:GetType():GetField("m_GoNotification", REF_FLAGS):GetValue(slArt)
                                if goNotiA and goNotiA.activeSelf then goNotiA:SetActive(false) end
                                local openArtCb = function()
                                    local latestHm = phi:GetType():GetField("currentHeroModel", REF_FLAGS):GetValue(phi) or curHm
                                    local lInfo = _G.HTPS_AnalyzeHeroInBag(latestHm)
                                    local recs = _G.HTPS_GetRecommendedArtifactsForHero(lInfo.facId, lInfo.clsId)
                                    local curIdx = _G.HTPS_PREVIEW_ART_CYCLE[latestHm.m_HeroId] or 1
                                    local whereStr = _G.HTPS_FindArtifactLocations(latestHm.m_ArtifactKey)
                                    local note = string.format("<color=#00FF7F><b>[Có sẵn trong Kho & Rương của bạn (%d/%d)]:</b></color>\n• %s", curIdx, #recs, whereStr)
                                    _G.HTPS_OpenPreviewItemPopup(artObj, latestHm, note, string.format("Đổi Bảo Vật (%d/%d)", curIdx, #recs), function()
                                        if #recs > 0 then
                                            local nxt = (curIdx % #recs) + 1
                                            _G.HTPS_PREVIEW_ART_CYCLE[latestHm.m_HeroId] = nxt
                                            local chosen = recs[nxt]
                                            latestHm.m_ArtifactKey = chosen.key
                                            latestHm.m_ArtifactStar = 6
                                            _G.HTPS_RecalcPreviewHeroStats(latestHm)
                                            _G.HTPS_BOUND_EQUI_MAP[peqTf] = nil
                                            local btnQE2 = peqTf:Find("ButtonQuickEquip")
                                            if btnQE2 then _G.HTPS_BOUND_EQUI_MAP[btnQE2:GetComponent(typeof(UG.UI.Button))] = nil end
                                            _G.HTPS_SyncPreviewHeroInfoUI(phiGo)
                                            local nxtObj = db:GetItemArtifact(chosen.key, 6) or db:GetItemArtifact(chosen.key, 1)
                                            if nxtObj then
                                                nxtObj.m_Star = 6
                                                nxtObj.m_Number = 1
                                                local nxtNote = string.format("<color=#FFD700><b>[Phương án %d/%d]: %s</b></color>\n• <color=#00FF7F><b>Lấy ở đâu:</b></color> %s",
                                                    nxt, #recs, chosen.stats, chosen.where)
                                                _G.HTPS_OpenPreviewItemPopup(nxtObj, latestHm, nxtNote, string.format("Đổi Bảo Vật (%d/%d)", nxt, #recs), function()
                                                    _G.HTPS_InspectHeroBuildAndBag(latestHm, math.abs(latestHm.m_HeroId) - 9900)
                                                end, "Xem Hướng Dẫn", function()
                                                    _G.HTPS_InspectHeroBuildAndBag(latestHm, math.abs(latestHm.m_HeroId) - 9900)
                                                end)
                                            end
                                        end
                                    end, "Xem Hướng Dẫn", function()
                                        _G.HTPS_InspectHeroBuildAndBag(latestHm, math.abs(latestHm.m_HeroId) - 9900)
                                    end)
                                end
                                local btnSlArt = slArt.gameObject:GetComponent(typeof(UG.UI.Button))
                                if btnSlArt then
                                    btnSlArt.onClick = UG.UI.Button.ButtonClickedEvent()
                                    btnSlArt.onClick:AddListener(openArtCb)
                                end
                                local artUI = slArt:GetType():GetField("m_ArtifactUI", REF_FLAGS):GetValue(slArt)
                                if artUI then
                                    pcall(function() artUI:SetClickCallback(openArtCb) end)
                                    local btnArt = artUI.gameObject:GetComponent(typeof(UG.UI.Button))
                                    if btnArt then
                                        btnArt.onClick = UG.UI.Button.ButtonClickedEvent()
                                        btnArt.onClick:AddListener(openArtCb)
                                    end
                                end
                            end
                        end

                        -- Slot Đá Hộ Mệnh (Đá Cam 6★)
                        local slStone = pEq:GetType():GetField("m_SlotStone", REF_FLAGS):GetValue(pEq)
                        if slStone and curHm.m_StoneId and curHm.m_StoneId > 0 then
                            local stObj = db:GetHeroStoneModelCopy(curHm.m_StoneId)
                            if stObj then
                                slStone:SetStone(curHm.m_HeroId, stObj)
                                local openStoneCb = function()
                                    local latestHm = phi:GetType():GetField("currentHeroModel", REF_FLAGS):GetValue(phi) or curHm
                                    _G.HTPS_OpenPreviewStonePopup(latestHm, stObj, math.abs(latestHm.m_HeroId) - 9900)
                                end
                                pcall(function() slStone:SetSlotClickCallback(openStoneCb) end)
                                local btnSlStone = slStone.gameObject:GetComponent(typeof(UG.UI.Button))
                                if btnSlStone then
                                    btnSlStone.onClick = UG.UI.Button.ButtonClickedEvent()
                                    btnSlStone.onClick:AddListener(openStoneCb)
                                end
                                local stUI = slStone:GetType():GetField("m_HeroStoneUI", REF_FLAGS):GetValue(slStone)
                                if stUI then
                                    pcall(function() stUI:SetClickCallback(openStoneCb) end)
                                    local btnSt = stUI.gameObject:GetComponent(typeof(UG.UI.Button))
                                    if btnSt then
                                        btnSt.onClick = UG.UI.Button.ButtonClickedEvent()
                                        btnSt.onClick:AddListener(openStoneCb)
                                    end
                                end
                            end
                        end
                    end

                    -- Nút [Đổi Bảo Vật Chuẩn] & [Mở Ở Rương Nào?] ở dưới đáy PanelEquipment
                    local btnQE = peqTf:Find("ButtonQuickEquip")
                    if btnQE then
                        local ph = btnQE:Find("PointHandQuickEquip")
                        if ph and ph.gameObject.activeSelf then ph.gameObject:SetActive(false) end
                        local tQE = btnQE:GetComponentInChildren(typeof(UG.UI.Text), true)
                        if tQE then
                            local loc = tQE.gameObject:GetComponent(typeof(CS.I2.Loc.Localize))
                            if loc then UG.Object.DestroyImmediate(loc) end
                            local chk = tQE.gameObject:GetComponent(typeof(CS.TextLocalizeChecker))
                            if chk then UG.Object.DestroyImmediate(chk) end
                            local curIdx = _G.HTPS_PREVIEW_ART_CYCLE[curHm.m_HeroId] or 1
                            tQE.fontSize = 17
                            tQE.text = string.format("Đổi Bảo Vật (%d/%d)", curIdx, #artRecs)
                        end
                        local bcQE = btnQE:GetComponent(typeof(UG.UI.Button))
                        if bcQE and _G.HTPS_BOUND_EQUI_MAP[bcQE] ~= curHm.m_HeroId then
                            bcQE.onClick = UG.UI.Button.ButtonClickedEvent()
                            bcQE.onClick:AddListener(function()
                                local latestHm = phi:GetType():GetField("currentHeroModel", REF_FLAGS):GetValue(phi) or curHm
                                local lInfo = _G.HTPS_AnalyzeHeroInBag(latestHm)
                                local recs = _G.HTPS_GetRecommendedArtifactsForHero(lInfo.facId, lInfo.clsId)
                                if #recs > 0 then
                                    local nxt = ((_G.HTPS_PREVIEW_ART_CYCLE[latestHm.m_HeroId] or 1) % #recs) + 1
                                    _G.HTPS_PREVIEW_ART_CYCLE[latestHm.m_HeroId] = nxt
                                    local chosen = recs[nxt]
                                    latestHm.m_ArtifactKey = chosen.key
                                    latestHm.m_ArtifactStar = 6
                                    _G.HTPS_RecalcPreviewHeroStats(latestHm)
                                    _G.HTPS_BOUND_EQUI_MAP[peqTf] = nil
                                    _G.HTPS_BOUND_EQUI_MAP[bcQE] = nil
                                    _G.HTPS_SyncPreviewHeroInfoUI(phiGo)
                                    local aObj = db:GetItemArtifact(chosen.key, 6) or db:GetItemArtifact(chosen.key, 1)
                                    if aObj then
                                        aObj.m_Star = 6
                                        aObj.m_Number = 1
                                        local note = string.format("<color=#FFD700><b>[Phương án %d/%d]: %s</b></color>\n• <color=#00FF7F><b>Lấy ở đâu:</b></color> %s",
                                            nxt, #recs, chosen.stats, chosen.where)
                                        _G.HTPS_OpenPreviewItemPopup(aObj, latestHm, note, "Xem Đầy Đủ Hướng Dẫn", function()
                                            _G.HTPS_InspectHeroBuildAndBag(latestHm, math.abs(latestHm.m_HeroId) - 9900)
                                        end)
                                    end
                                end
                            end)
                            _G.HTPS_BOUND_EQUI_MAP[bcQE] = curHm.m_HeroId
                        end
                    end

                    local btnUE = peqTf:Find("ButtonUnEquip")
                    if btnUE then
                        local tUE = btnUE:GetComponentInChildren(typeof(UG.UI.Text), true)
                        if tUE then
                            local loc = tUE.gameObject:GetComponent(typeof(CS.I2.Loc.Localize))
                            if loc then UG.Object.DestroyImmediate(loc) end
                            local chk = tUE.gameObject:GetComponent(typeof(CS.TextLocalizeChecker))
                            if chk then UG.Object.DestroyImmediate(chk) end
                            tUE.fontSize = 17
                            tUE.text = "Mở Ở Rương Nào?"
                        end
                        local bcUE = btnUE:GetComponent(typeof(UG.UI.Button))
                        if bcUE and _G.HTPS_BOUND_EQUI_MAP[bcUE] ~= curHm.m_HeroId then
                            bcUE.onClick = UG.UI.Button.ButtonClickedEvent()
                            bcUE.onClick:AddListener(function()
                                local latestHm = phi:GetType():GetField("currentHeroModel", REF_FLAGS):GetValue(phi) or curHm
                                _G.HTPS_InspectHeroBuildAndBag(latestHm, math.abs(latestHm.m_HeroId) - 9900)
                            end)
                            _G.HTPS_BOUND_EQUI_MAP[bcUE] = curHm.m_HeroId
                        end
                    end
                end
            else
                if peqTf then _G.HTPS_BOUND_EQUI_MAP[peqTf] = nil end
            end

            -- 2b. Cập nhật Tab 4 (PanelESkill: Bảng Haki E1 -> E5 & Nút Đổi Bộ Haki Chuẩn)
            if pesTf and pesTf.gameObject.activeSelf then
                local pEs = pesTf:GetComponent(typeof(CS.PanelHeroESkill))
                if pEs then
                    local hakiIdx = _G.HTPS_PREVIEW_HAKI_CYCLE[curHm.m_HeroId] or 1
                    local esSyncKey = string.format("%d_%d", curHm.m_HeroId, hakiIdx)
                    if _G.HTPS_BOUND_EQUI_MAP[pesTf] ~= esSyncKey then
                        _G.HTPS_BOUND_EQUI_MAP[pesTf] = esSyncKey
                        pEs:SetHeroModel(curHm)
                    end
                    local btnSw = pesTf:Find("ButtonSwitchSkill")
                    if btnSw then
                        btnSw.gameObject:SetActive(true)
                        local tSw = btnSw:GetComponentInChildren(typeof(UG.UI.Text), true)
                        if tSw then
                            local loc = tSw.gameObject:GetComponent(typeof(CS.I2.Loc.Localize))
                            if loc then UG.Object.DestroyImmediate(loc) end
                            local chk = tSw.gameObject:GetComponent(typeof(CS.TextLocalizeChecker))
                            if chk then UG.Object.DestroyImmediate(chk) end
                            local hp = _G.HTPS_HAKI_PRESETS[hakiIdx] or _G.HTPS_HAKI_PRESETS[1]
                            tSw.fontSize = 16
                            tSw.text = string.format("Đổi Haki (%d/3): %s", hakiIdx, hp.name)
                        end
                        local rtSw = btnSw:GetComponent(typeof(UG.RectTransform))
                        if rtSw then rtSw.sizeDelta = UG.Vector2(380, 48) end
                        local bcSw = btnSw:GetComponent(typeof(UG.UI.Button))
                        if bcSw and _G.HTPS_BOUND_EQUI_MAP[bcSw] ~= curHm.m_HeroId then
                            bcSw.onClick = UG.UI.Button.ButtonClickedEvent()
                            bcSw.onClick:AddListener(function()
                                local latestHm = phi:GetType():GetField("currentHeroModel", REF_FLAGS):GetValue(phi) or curHm
                                local curH = _G.HTPS_PREVIEW_HAKI_CYCLE[latestHm.m_HeroId] or 1
                                local nxtH = (curH % #_G.HTPS_HAKI_PRESETS) + 1
                                _G.HTPS_PREVIEW_HAKI_CYCLE[latestHm.m_HeroId] = nxtH
                                local preset = _G.HTPS_HAKI_PRESETS[nxtH]
                                local newEs = CS.System.Collections.Generic.List(typeof(CS.System.Int32))()
                                for _, v in ipairs(preset.indices) do newEs:Add(v) end
                                latestHm:GetType():GetField("m_ListIndexESkillActive", REF_FLAGS):SetValue(latestHm, newEs)
                                _G.HTPS_RecalcPreviewHeroStats(latestHm)
                                _G.HTPS_BOUND_EQUI_MAP[pesTf] = nil
                                pEs:SetHeroModel(latestHm)
                                _G.HTPS_SyncPreviewHeroInfoUI(phiGo)
                                pcall(function() CS.Toast.ShowMessage(string.format("<color=#00FF7F>[Haki %d/3]</color> %s", nxtH, preset.desc)) end)
                            end)
                            _G.HTPS_BOUND_EQUI_MAP[bcSw] = curHm.m_HeroId
                        end
                    end
                    -- Cho phép bấm chọn trực tiếp từng ô Haki trong PanelESkillDetail khi đang xem thử
                    local detailTf = pesTf:Find("PanelESkillDetail")
                    if detailTf and detailTf.gameObject.activeSelf then
                        local btnAct = detailTf:Find("Background/ButtonActivate") or detailTf:Find("ButtonActivate")
                        if btnAct then
                            local bcAct = btnAct:GetComponent(typeof(UG.UI.Button))
                            if bcAct and _G.HTPS_BOUND_EQUI_MAP[bcAct] ~= curHm.m_HeroId then
                                bcAct.onClick = UG.UI.Button.ButtonClickedEvent()
                                bcAct.onClick:AddListener(function()
                                    detailTf.gameObject:SetActive(false)
                                end)
                                _G.HTPS_BOUND_EQUI_MAP[bcAct] = curHm.m_HeroId
                            end
                        end
                    end
                end
            else
                if pesTf then _G.HTPS_BOUND_EQUI_MAP[pesTf] = nil end
            end

            -- Đồng bộ PopupHeroStoneInfo nếu đang mở khi soi tướng
            local phsiGo = GO.Find("PopupHeroStoneInfo(Clone)")
            if phsiGo and phsiGo.activeInHierarchy then
                local phsi = phsiGo:GetComponent(typeof(CS.PopupHeroStoneInfo))
                local tDesc = phsi and phsi:GetType():GetField("m_TextDesc", REF_FLAGS):GetValue(phsi)
                if tDesc and (tDesc.text == "" or tDesc.text == " ") then
                    _G.HTPS_PopulatePreviewStonePopup(phsiGo, curHm, slotIdx)
                end
            end

            -- 3. Cập nhật Tab 5 (PanelSpecialEquip: Vai trò & Nhóm hạng Max 300 cấp - 15 sao)
            local pseTf = boxInfo:Find("PanelSpecialEquip")
            if pseTf and pseTf.gameObject.activeSelf then
                local pSe = pseTf:GetComponent(typeof(CS.PanelSpecialEquip))
                if pSe and curHm.epicEquipment then
                    pSe:GetType():GetField("heroModel", REF_FLAGS):SetValue(pSe, curHm)
                    pSe:SetDataPanel(curHm)
                end
            end
        end)
    end

    _G.HTPS_BOUND_EQUI_MAP = _G.HTPS_BOUND_EQUI_MAP or setmetatable({}, { __mode = "k" })

    _G.HTPS_OpenPreviewHeroInfoUI = function(hl, selectedSlotIdx)
        pcall(function()
            if not hl then return end
            local lstGo = hl:GetType():GetField("m_LstGoHeroHead", REF_FLAGS):GetValue(hl)
            if not lstGo then return end

            local previewList = CS.System.Collections.Generic.List(typeof(CS.HeroModel))()
            local selectedPreviewHm = nil

            for i = 0, lstGo.Count - 1 do
                local hgo = lstGo[i]
                if hgo and hgo.activeSelf then
                    local hhc = hgo:GetComponent(typeof(CS.HeroHeadClickable))
                    local origHm = hhc and hhc:GetType():GetField("m_HeroModel", REF_FLAGS):GetValue(hhc)
                    if origHm and not origHm:IsModelNull() and origHm.m_HeroKey and origHm.m_HeroKey > 0 then
                        local pHm = _G.HTPS_BuildPreviewHeroModel(origHm, i + 1)
                        previewList:Add(pHm)
                        if (i + 1) == selectedSlotIdx or not selectedPreviewHm then
                            selectedPreviewHm = pHm
                        end
                    end
                end
            end

            if not selectedPreviewHm or previewList.Count == 0 then return end

            local oldPhi = GO.Find("PanelHeroInfo(Clone)")
            if oldPhi then GO.DestroyImmediate(oldPhi) end

            CS.PanelHeroInfo.ShowUp(selectedPreviewHm, previewList)
            local phiGo = GO.Find("PanelHeroInfo(Clone)")
            if phiGo then
                phiGo.transform:SetAsLastSibling()
                _G.HTPS_SyncPreviewHeroInfoUI(phiGo)
            end
        end)
    end

    local function bindLineupHeroClicks(hl)
        if not hl then return end
        local lst = hl:GetType():GetField("m_LstGoHeroHead", REF_FLAGS):GetValue(hl)
        if not lst then return end
        for i = 0, lst.Count - 1 do
            local hgo = lst[i]
            if hgo then
                local slotIdx = i + 1
                local hhc = hgo:GetComponent(typeof(CS.HeroHeadClickable))
                local btn = hgo:GetComponent(typeof(UG.UI.Button))
                if hhc and btn and _G.HTPS_BOUND_HHC_MAP[hgo] ~= btn then
                    btn.onClick = UG.UI.Button.ButtonClickedEvent()
                    btn.onClick:AddListener(function()
                        local hm = hhc:GetType():GetField("m_HeroModel", REF_FLAGS):GetValue(hhc)
                        if hm and not hm:IsModelNull() and hm.m_HeroKey and hm.m_HeroKey > 0 then
                            _G.HTPS_OpenPreviewHeroInfoUI(hl, slotIdx)
                        end
                    end)
                    _G.HTPS_BOUND_HHC_MAP[hgo] = btn
                end
            end
        end
    end

    _G.HTPS_BOUND_HHC_MAP = _G.HTPS_BOUND_HHC_MAP or setmetatable({}, { __mode = "k" })

    _G.HTPS_EnsurePlayerInfoButtons = function()
        pcall(function()
            -- 1. PopupPlayerInfo (Đội hình 1 đội: BXH, Đấu trường, Tháp, Bạn bè, Hạm đội, Chat)
            local ppiGo = GO.Find("PopupPlayerInfo(Clone)")
            if ppiGo and ppiGo.activeInHierarchy then
                local ppi = ppiGo:GetComponent(typeof(CS.PopupPlayerInfo))
                if ppi then
                    local hl = ppi:GetType():GetField("m_HeroesLineup", REF_FLAGS):GetValue(ppi)
                    bindLineupHeroClicks(hl)

                    local lineupTf = ppiGo.transform:Find("Content/Body/Lineup")
                    local tplBtn = ppi:GetType():GetField("m_GoButton1", REF_FLAGS):GetValue(ppi)
                    if lineupTf and tplBtn then
                        local btnTf = lineupTf:Find("BtnHTPSSoiDoiHinh")
                        if not btnTf then
                            local cloneGo = GO.Instantiate(tplBtn, lineupTf, false)
                            cloneGo.name = "BtnHTPSSoiDoiHinh"
                            cloneGo:SetActive(true)
                            btnTf = cloneGo.transform
                        end
                        if _G.HTPS_BOUND_PPI_BTN ~= btnTf then
                            local txtLineup = lineupTf:Find("TextLineup")
                            local rt = btnTf:GetComponent(typeof(UG.RectTransform))
                            if txtLineup then
                                local trt = txtLineup:GetComponent(typeof(UG.RectTransform))
                                rt.anchorMin = trt.anchorMin
                                rt.anchorMax = trt.anchorMax
                                rt.pivot = UG.Vector2(0.5, 0.5)
                                rt.anchoredPosition = UG.Vector2(trt.anchoredPosition.x + 260, trt.anchoredPosition.y)
                            else
                                rt.anchoredPosition = UG.Vector2(30, 50)
                            end
                            rt.sizeDelta = UG.Vector2(215, 44)
                            local txt = btnTf:GetComponentInChildren(typeof(UG.UI.Text), true)
                            if txt then
                                local loc = txt.gameObject:GetComponent(typeof(CS.I2.Loc.Localize))
                                if loc then UG.Object.DestroyImmediate(loc) end
                                txt.fontSize = 17
                                txt.text = "Soi Đội Hình & Kho"
                            end
                            local bc = btnTf:GetComponent(typeof(UG.UI.Button))
                            bc.onClick = UG.UI.Button.ButtonClickedEvent()
                            bc.onClick:AddListener(function()
                                _G.HTPS_InspectFullPlayerLineup(ppi, false)
                            end)
                            _G.HTPS_BOUND_PPI_BTN = btnTf
                        end
                    end
                end
            end

            -- 0. Đồng bộ giao diện Soi Tướng (PanelHeroInfo) nếu đang mở ở chế độ Preview
            local phiPreviewGo = GO.Find("PanelHeroInfo(Clone)")
            if phiPreviewGo and phiPreviewGo.activeInHierarchy then
                _G.HTPS_SyncPreviewHeroInfoUI(phiPreviewGo)
            end

            -- 2. PopupPlayerInfo3 (Đội hình 3 đội: Đấu trường Tam Hùng / Liên Server)
            local ppi3Go = GO.Find("PopupPlayerInfo3(Clone)")
            if ppi3Go and ppi3Go.activeInHierarchy then
                local ppi3 = ppi3Go:GetComponent(typeof(CS.PopupPlayerInfo3))
                if ppi3 then
                    local pt3 = ppi3:GetType()
                    bindLineupHeroClicks(pt3:GetField("m_HeroesLineup1", REF_FLAGS):GetValue(ppi3))
                    bindLineupHeroClicks(pt3:GetField("m_HeroesLineup2", REF_FLAGS):GetValue(ppi3))
                    bindLineupHeroClicks(pt3:GetField("m_HeroesLineup3", REF_FLAGS):GetValue(ppi3))

                    local contentGo = pt3:GetField("m_GoContent", REF_FLAGS):GetValue(ppi3)
                    local tplBtn = pt3:GetField("m_GoButton1", REF_FLAGS):GetValue(ppi3)
                    if contentGo and tplBtn then
                        local btnTf = contentGo.transform:Find("BtnHTPSSoiDoiHinh3")
                        if not btnTf then
                            local cloneGo = GO.Instantiate(tplBtn, contentGo.transform, false)
                            cloneGo.name = "BtnHTPSSoiDoiHinh3"
                            cloneGo:SetActive(true)
                            btnTf = cloneGo.transform
                        end
                        if _G.HTPS_BOUND_PPI3_BTN ~= btnTf then
                            local rt = btnTf:GetComponent(typeof(UG.RectTransform))
                            rt.anchorMin = UG.Vector2(0.5, 0.5)
                            rt.anchorMax = UG.Vector2(0.5, 0.5)
                            rt.pivot = UG.Vector2(0.5, 0.5)
                            rt.anchoredPosition = UG.Vector2(190, 195)
                            rt.sizeDelta = UG.Vector2(215, 44)
                            local txt = btnTf:GetComponentInChildren(typeof(UG.UI.Text), true)
                            if txt then
                                local loc = txt.gameObject:GetComponent(typeof(CS.I2.Loc.Localize))
                                if loc then UG.Object.DestroyImmediate(loc) end
                                txt.fontSize = 17
                                txt.text = "Soi Đội Hình & Kho"
                            end
                            local bc = btnTf:GetComponent(typeof(UG.UI.Button))
                            bc.onClick = UG.UI.Button.ButtonClickedEvent()
                            bc.onClick:AddListener(function()
                                _G.HTPS_InspectFullPlayerLineup(ppi3, true)
                            end)
                            _G.HTPS_BOUND_PPI3_BTN = btnTf
                        end
                    end
                end
            end
        end)
    end


    
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
-- TÍNH NĂNG: Luyện Tướng / Huyết Tế (AltarScene), Tự Mở Mảnh Tướng Rồi Huyết Tế Lập Tức Không Hiện Popup
-- TRÍCH XUẤT TỪ NGUYENVINHMOD.DLL BẰNG REA ENGINE
-- =====================================================================

-- ==================== AUTO LUYỆN TƯỚNG / HUYẾT TẾ (ALTAR SCENE - TỰ MỞ MẢNH THEO SAO & HỆ RỒI HUYẾT TẾ LUÔN, KHÔNG POPUP) ====================
    _G.HTPS_ALTAR_RUNNING = false
    _G.HTPS_ALTAR_STOP_REQ = false

    _G.HTPS_UpdateAltarBtnUI = function(statusText)
        pcall(function()
            if _G.HTPS_BTN_ALTAR_TXT and not _G.HTPS_BTN_ALTAR_TXT:Equals(nil) then
                if _G.HTPS_ALTAR_RUNNING then
                    _G.HTPS_BTN_ALTAR_TXT.text = statusText or "Dừng Luyện"
                else
                    _G.HTPS_BTN_ALTAR_TXT.text = "Auto Luyện Hết"
                end
            end
        end)
    end

    local ALTAR_HERO_FAC_MAP = {
        [6] = 1, -- ABYSS -> Bền Bỉ
        [5] = 2, -- FOREST -> Chính Xác
        [4] = 3, -- FORTRESS -> Nhanh Nhẹn
        [3] = 4, -- SHADOW -> Sinh Khí
        [1] = 5, -- DARK -> Minh Mẫn / Ám
        [2] = 6  -- LIGHT -> Thông Minh / Quang
    }

    local ALTAR_GENERIC_SHARD_FAC_MAP = {
        [1] = 4, -- Sinh Khí (10001, 20001, 30001)
        [2] = 1, -- Bền Bỉ (10002, 20002, 30002)
        [3] = 3, -- Nhanh Nhẹn (10003, 20003, 30003)
        [4] = 2, -- Chính Xác (10004, 20004, 30004)
        [5] = 6, -- Thông Minh / Quang (10005, 20005, 30005)
        [6] = 5  -- Minh Mẫn / Ám (10006, 20006, 30006)
    }

    local function getEnumInt(val)
        if not val then return 0 end
        local s = tostring(val)
        local n = s:match(":%s*(%d+)")
        if n then return tonumber(n) end
        return tonumber(s) or 0
    end

    local function getShardAltarFac(s, db)
        if not s then return 0 end
        if s.m_HeroKey and s.m_HeroKey > 0 then
            local hm = db and (db:GetHeroModel(s.m_HeroKey) or db:GetHeroModelCopy(s.m_HeroKey))
            if hm and hm.m_Faction then
                return ALTAR_HERO_FAC_MAP[getEnumInt(hm.m_Faction)] or 0
            end
        else
            local k = tonumber(s.m_ItemKey) or 0
            if k >= 10000 and k <= 39999 then
                local rem = k % 10000
                if rem == 0 then return 0 end
                return ALTAR_GENERIC_SHARD_FAC_MAP[rem] or 0
            end
        end
        return 0
    end

    local function collectMatchingShards(inv, db, fltStar, fltFac)
        local res = {}
        local lstShard = inv:GetType():GetField("m_LstItemShard", 60):GetValue(inv)
        if not lstShard then return res end
        for i = 0, lstShard.Count - 1 do
            local s = lstShard[i]
            if s and s.m_ShardType == 2 and s.m_RequireToMerge and s.m_RequireToMerge > 0 then
                local st = tonumber(s.m_Star) or 0
                local num = tonumber(s.m_Number) or 0
                local copies = math.floor(num / s.m_RequireToMerge)
                if copies > 0 and st >= 1 and st <= 5 then
                    -- Nếu không chọn Sao (fltStar <= 0), mặc định chỉ mở mảnh 1-4★ để bảo vệ mảnh 5★
                    local okStar = (fltStar > 0) and (st == fltStar) or (fltStar <= 0 and st <= 4)
                    if okStar then
                        local sFac = getShardAltarFac(s, db)
                        local okFac = (fltFac <= 0) or (sFac == fltFac)
                        if okFac then
                            local isGeneric = (not s.m_HeroKey) or (tonumber(s.m_HeroKey) <= 0) or (tonumber(s.m_ItemKey) >= 10000)
                            -- 1★ - 3★: Mở cả mảnh ngẫu nhiên lẫn mảnh tướng cụ thể
                            -- 4★ - 5★: CHỈ mở mảnh ngẫu nhiên / mảnh hệ (isGeneric), bảo vệ tuyệt đối mảnh tướng 4★-5★ cụ thể tích góp!
                            if st <= 3 or isGeneric then
                                local prio = isGeneric and 0 or 1
                                table.insert(res, {
                                    shard = s,
                                    itemKey = s.m_ItemKey,
                                    star = st,
                                    copies = copies,
                                    num = num,
                                    priority = prio
                                })
                            end
                        end
                    end
                end
            end
        end
        table.sort(res, function(a, b)
            if a.star ~= b.star then return a.star < b.star end
            if a.priority ~= b.priority then return a.priority < b.priority end
            return a.num > b.num
        end)
        return res
    end

    _G.HTPS_RunAutoAltar = function()
        if _G.HTPS_ALTAR_RUNNING then
            _G.HTPS_ALTAR_STOP_REQ = true
            _G.HTPS_ALTAR_RUNNING = false
            _G.HTPS_UpdateAltarBtnUI()
            CS.Toast.ShowToast("🛑 Đã dừng Auto Huyết Tế!")
            return
        end

        local als = _G.HTPS_FindObjectOfType(typeof(CS.AltarScene))
        if not als or als:Equals(nil) or not als.gameObject.activeInHierarchy then
            CS.Toast.ShowToast("Hãy mở màn hình Lò Luyện trước!")
            return
        end

        local REF_FLAGS = 60
        local gc = CS.GameContext.GetIntance()
        local t = als:GetType()
        local initStar = t:GetField("m_FilterByStar", REF_FLAGS):GetValue(als) or -9999
        local initFac = t:GetField("m_FilterByFaction", REF_FLAGS):GetValue(als) or -9999
        local playerLv = tonumber(gc.m_PlayerLevel) or 0

        if initStar <= 0 and initFac <= 0 then
            CS.Toast.ShowToast("⚠️ Hãy chọn Cấp Sao (1★ - 4★) hoặc Hệ cần mở mảnh trước khi bấm Auto!")
            return
        end

        if initStar == 5 and playerLv < 70 then
            CS.Toast.ShowToast("⚠️ Server yêu cầu đạt Cấp 70 mới được Huyết Tế tướng 5★ (Cấp hiện tại: " .. tostring(playerLv) .. ")! Hãy chọn 1★ - 4★.")
            return
        end

        _G.HTPS_ALTAR_STOP_REQ = false
        _G.HTPS_ALTAR_RUNNING = true
        _G.HTPS_BONUS_SUPPRESS_UNTIL = 0
        if _G.HTPS_AUTO then _G.HTPS_AUTO.suppressPopup = true end
        _G.HTPS_UpdateAltarBtnUI("Đang Mở & Luyện...")

        CsCoroutine.start(function()
            local nc = CS.NetworkController.GetInstance()
            local inv = CS.PlayerInventory.GetInstance()
            local db = CS.DbManager.GetInstance()

            pcall(function()
                local pm = _G.HTPS_FindObjectOfType(typeof(CS.PopupMessage))
                if pm then UG.Object.DestroyImmediate(pm.gameObject) end
            end)
            _G.HTPS_KillSummonPopups()

            local fltFac = t:GetField("m_FilterByFaction", REF_FLAGS):GetValue(als) or -9999
            local fltStar = t:GetField("m_FilterByStar", REF_FLAGS):GetValue(als) or -9999
            local slots = t:GetField("m_LstSlotHeroAltar", REF_FLAGS):GetValue(als)
            local lstFlt = t:GetField("m_LstPlayerHeroesFilter", REF_FLAGS):GetValue(als)

            local soulBefore = tonumber(gc.m_SoulStoneShard) or 0
            local totalSacrificed = 0
            local totalOpenedFromShards = 0
            local serverErrMsg = nil
            local bagFullWarn = false
            local autoBoughtSlots = 0
            local syncedRealHeroes = false

            -- CHỈ MỞ MẢNH TƯỚNG TRONG TÚI ĐỒ THEO SỐ SAO & HỆ ĐANG CHỌN RỒI HUYẾT TẾ NGAY TƯỚNG VỪA MỞ
            -- Tuyệt đối KHÔNG đụng vào các tướng đang có sẵn trong Kho Tướng của người chơi!
            while _G.HTPS_ALTAR_RUNNING and not _G.HTPS_ALTAR_STOP_REQ do
                if not als or als:Equals(nil) or not als.gameObject.activeInHierarchy then
                    break
                end

                fltFac = t:GetField("m_FilterByFaction", REF_FLAGS):GetValue(als) or -9999
                fltStar = t:GetField("m_FilterByStar", REF_FLAGS):GetValue(als) or -9999
                local maxAllowedStar = ((tonumber(gc.m_PlayerLevel) or 0) >= 70) and 5 or 4

                if fltStar == 5 and maxAllowedStar < 5 then
                    serverErrMsg = "Lên cấp 70 để huyết tế tướng 5 sao"
                    break
                end

                local shardQueue = collectMatchingShards(inv, db, fltStar, fltFac)
                if #shardQueue == 0 then
                    break
                end

                local req254 = CS.pbdson.RequestData()
                req254.session = gc.m_Session
                local actionsAdded = 0
                for _, item in ipairs(shardQueue) do
                    if actionsAdded >= 2 then break end
                    if item.star <= maxAllowedStar then
                        local askNum = math.min(item.copies, 50)
                        if askNum > 0 then
                            local cv254 = CS.pbdson.CommonVector()
                            cv254.aLong:Add(2)
                            cv254.aLong:Add(item.itemKey)
                            cv254.aLong:Add(askNum)
                            local act254 = CS.pbdson.PbAction()
                            act254.actionId = 254
                            act254.data = _G.HTPS_SerializeProto(cv254)
                            req254.actions:Add(act254)
                            actionsAdded = actionsAdded + 1
                        end
                    end
                end

                if actionsAdded == 0 then
                    break
                end

                _G.HTPS_BONUS_SUPPRESS_UNTIL = 0
                if _G.HTPS_AUTO then _G.HTPS_AUTO.suppressPopup = true end

                local d254, ok254 = _G.HTPS_PutWebRequest(
                    nc.m_UrlGameServer .. "/i/254/" .. tostring(gc.m_UserId),
                    _G.HTPS_SerializeProto(req254),
                    8
                )

                local newHeroIds = {}
                if ok254 and d254 then
                    pcall(function()
                        local r254 = _G.HTPS_DeserializeProto(d254, "pbdson.ResponseData,PbMethodLib")
                        if r254 and r254.aAction then
                            for i = 0, r254.aAction.Count - 1 do
                                local a = r254.aAction[i]
                                if a.actionId == 254 and a.data then
                                    local rcv = _G.HTPS_DeserializeProto(a.data, "pbdson.CommonVector,PbMethodLib")
                                    if rcv and rcv.aLong and rcv.aLong.Count > 0 then
                                        local idx = 0
                                        while idx < rcv.aLong.Count do
                                            local bType = tonumber(rcv.aLong[idx])
                                            if bType == 3 then
                                                idx = idx + 5
                                            elseif bType == 5 then
                                                local hid = tonumber(rcv.aLong[idx + 1])
                                                if hid and hid > 0 then
                                                    table.insert(newHeroIds, hid)
                                                end
                                                idx = idx + 3
                                            else
                                                break
                                            end
                                        end
                                        pcall(function()
                                            CS.BonusModel.ParseBonusReceived(rcv.aLong, true)
                                        end)
                                    end
                                end
                            end
                        end
                    end)
                end

                if #newHeroIds == 0 then
                    -- Đồng bộ lại số tướng thực tế trên Server (phòng trường hợp bấm Huyết Tế thường 5★ khi < Lv70 bị trừ ảo ở Client)
                    if not syncedRealHeroes then
                        syncedRealHeroes = true
                        pcall(function()
                            local req200 = CS.pbdson.RequestData()
                            req200.session = gc.m_Session
                            local act200 = CS.pbdson.PbAction()
                            act200.actionId = 200
                            req200.actions:Add(act200)
                            local d200, ok200 = _G.HTPS_PutWebRequest(nc.m_UrlGameServer .. "/i/200/" .. tostring(gc.m_UserId), _G.HTPS_SerializeProto(req200), 8)
                            if ok200 and d200 then
                                local r200 = _G.HTPS_DeserializeProto(d200, "pbdson.ResponseData,PbMethodLib")
                                local lhm = _G.HTPS_DeserializeProto(r200.aAction[0].data, "pbdson.PbListHero,PbMethodLib")
                                local newList = CS.System.Collections.Generic.List(typeof(CS.HeroModel))()
                                for i = 0, lhm.aHero.Count - 1 do
                                    local hm = CS.HeroModel()
                                    hm:ImportFromPbHero(lhm.aHero[i])
                                    newList:Add(hm)
                                end
                                inv:SetHeroModels(newList)
                            end
                        end)
                    end

                    -- Kho tướng đang 0 chỗ trống để chứa tạm tướng mở từ mảnh -> Tự động mua thêm ô chứa tướng (Action 234) nếu còn Kim Cương
                    if autoBoughtSlots < 30 and (tonumber(gc.m_Gem) or 0) >= 100000 then
                        local boughtAny = false
                        pcall(function()
                            local req234 = CS.pbdson.RequestData()
                            req234.session = gc.m_Session
                            for b = 1, 4 do
                                local act234 = CS.pbdson.PbAction()
                                act234.actionId = 234
                                req234.actions:Add(act234)
                            end
                            local d234, ok234 = _G.HTPS_PutWebRequest(
                                nc.m_UrlGameServer .. "/i/234/" .. tostring(gc.m_UserId),
                                _G.HTPS_SerializeProto(req234),
                                8
                            )
                            if ok234 and d234 then
                                local r234 = _G.HTPS_DeserializeProto(d234, "pbdson.ResponseData,PbMethodLib")
                                if r234 and r234.aAction then
                                    for i = 0, r234.aAction.Count - 1 do
                                        local a = r234.aAction[i]
                                        if a.actionId == 234 and a.data then
                                            boughtAny = true
                                            autoBoughtSlots = autoBoughtSlots + 5
                                            local rcv = _G.HTPS_DeserializeProto(a.data, "pbdson.CommonVector,PbMethodLib")
                                            if rcv and rcv.aLong and rcv.aLong.Count >= 2 then
                                                CS.MiscData.m_CostBuyHeroCapacity = tonumber(rcv.aLong[0]) or CS.MiscData.m_CostBuyHeroCapacity
                                                CS.MiscData.m_HeroCapacity = tonumber(rcv.aLong[1]) or CS.MiscData.m_HeroCapacity
                                            end
                                        end
                                    end
                                end
                            end
                        end)
                        if boughtAny then
                            coroutine.yield(nil)
                        else
                            bagFullWarn = true
                            break
                        end
                    else
                        bagFullWarn = true
                        break
                    end
                else
                    -- Huyết tế ngay lập tức CHỈ các tướng vừa mở ra từ mảnh (newHeroIds)
                    local cv209 = CS.pbdson.CommonVector()
                    local lstRemNew = CS.System.Collections.Generic.List(typeof(CS.System.Int32))()
                    for _, hid in ipairs(newHeroIds) do
                        cv209.aLong:Add(hid)
                        lstRemNew:Add(hid)
                    end

                    local req209 = CS.pbdson.RequestData()
                    req209.session = gc.m_Session
                    local act209 = CS.pbdson.PbAction()
                    act209.actionId = 209
                    act209.data = _G.HTPS_SerializeProto(cv209)
                    req209.actions:Add(act209)

                    _G.HTPS_BONUS_SUPPRESS_UNTIL = 0
                    if _G.HTPS_AUTO then _G.HTPS_AUTO.suppressPopup = true end

                    local d209, ok209 = _G.HTPS_PutWebRequest(
                        nc.m_UrlGameServer .. "/i/209/" .. tostring(gc.m_UserId),
                        _G.HTPS_SerializeProto(req209),
                        8
                    )

                    local step2SacrificedOk = false
                    if ok209 and d209 then
                        pcall(function()
                            local r209 = _G.HTPS_DeserializeProto(d209, "pbdson.ResponseData,PbMethodLib")
                            if r209 and r209.aAction then
                                for i = 0, r209.aAction.Count - 1 do
                                    local a = r209.aAction[i]
                                    if a.actionId == 209 and a.data then
                                        step2SacrificedOk = true
                                        local rcv = _G.HTPS_DeserializeProto(a.data, "pbdson.CommonVector,PbMethodLib")
                                        if rcv and rcv.aLong and rcv.aLong.Count > 0 then
                                            CS.BonusModel.ParseBonusReceived(rcv.aLong, true)
                                        end
                                    elseif a.actionId == 1 and a.data then
                                        local cvErr = _G.HTPS_DeserializeProto(a.data, "pbdson.CommonVector,PbMethodLib")
                                        if cvErr and cvErr.aString and cvErr.aString.Count > 0 then
                                            serverErrMsg = tostring(cvErr.aString[0])
                                        end
                                    end
                                end
                            end
                        end)
                    end

                    if step2SacrificedOk then
                        pcall(function()
                            inv:RemoveHeroModels(lstRemNew)
                            if als and not als:Equals(nil) then
                                als:UpdateDaDauXanh()
                                if slots and slots.Count > 0 and slots[0] then
                                    slots[0]:PlayBurnEffect()
                                end
                            end
                        end)

                        totalOpenedFromShards = totalOpenedFromShards + #newHeroIds
                        totalSacrificed = totalSacrificed + #newHeroIds
                        _G.HTPS_UpdateAltarBtnUI("Dừng (" .. tostring(totalSacrificed) .. ")")
                        _G.HTPS_KillSummonPopups()
                        coroutine.yield(nil)
                    else
                        break
                    end
                end
            end

            _G.HTPS_KillSummonPopups()
            pcall(function()
                if als and not als:Equals(nil) then
                    local txtNum = t:GetField("m_TextNumber", REF_FLAGS):GetValue(als)
                    local invHeroes = inv:GetType():GetField("m_LstHeroModel", REF_FLAGS):GetValue(inv)
                    if txtNum and lstFlt and invHeroes then
                        txtNum.text = tostring(lstFlt.Count) .. "/" .. tostring(invHeroes.Count)
                    end
                    als:UpdateDaDauXanh()
                end
            end)

            local starStr = (fltStar > 0) and (tostring(fltStar) .. "★") or "1-4★"
            local FAC_NAMES = { [1] = "Bền Bỉ", [2] = "Chính Xác", [3] = "Nhanh Nhẹn", [4] = "Sinh Khí", [5] = "Ám", [6] = "Quang" }
            local facStr = (fltFac > 0 and FAC_NAMES[fltFac]) and ("Hệ " .. FAC_NAMES[fltFac]) or "Tất cả Hệ"
            local soulGain = math.max(0, (tonumber(gc.m_SoulStoneShard) or 0) - soulBefore)

            if totalSacrificed > 0 then
                CS.Toast.ShowToast(string.format("🔥 Đã Mở & Luyện %d tướng từ mảnh [%s - %s] (+%d Đá Hồn)!",
                    totalSacrificed, starStr, facStr, soulGain))
            elseif serverErrMsg then
                CS.Toast.ShowToast("⚠️ " .. serverErrMsg)
            elseif bagFullWarn then
                CS.Toast.ShowToast("⚠️ Kho tướng trên Server đã đầy cứng (" .. tostring(CS.MiscData.m_HeroCapacity) .. " ô), hãy ghép bớt tướng 5★ hoặc mua thêm ô!")
            else
                CS.Toast.ShowToast(string.format("Không còn mảnh tướng (%s - %s) nào trong Túi Đồ để mở & luyện!", starStr, facStr))
            end

            _G.HTPS_ALTAR_RUNNING = false
            _G.HTPS_ALTAR_STOP_REQ = false
            _G.HTPS_UpdateAltarBtnUI()
        end)
    end

    _G.HTPS_EnsureAltarButtons = function()
        pcall(function()
            local als = _G.HTPS_FindObjectOfType(typeof(CS.AltarScene))
            if not als or als:Equals(nil) or not als.gameObject.activeInHierarchy then return end
            local REF_FLAGS = 60
            local t = als:GetType()
            local btnSmartGo = t:GetField("m_GoButtonQuickSelect", REF_FLAGS):GetValue(als)
            local btnAltarGo = t:GetField("m_GoButtonAltar", REF_FLAGS):GetValue(als)
            if not btnSmartGo or not btnAltarGo then return end
            local parentTf = btnAltarGo.transform.parent
            if not parentTf then return end

            local btnAutoTf = parentTf:Find("BtnHTPSAutoAltar")
            if not btnAutoTf then
                local smartRt = btnSmartGo:GetComponent(typeof(UG.RectTransform))
                smartRt.anchoredPosition = UG.Vector2(-134.0, -218.2)
                smartRt.sizeDelta = UG.Vector2(124.0, 62.0)
                local smartTxt = btnSmartGo:GetComponentInChildren(typeof(UG.UI.Text), true)
                if smartTxt then smartTxt.fontSize = 18 end

                local altarRt = btnAltarGo:GetComponent(typeof(UG.RectTransform))
                altarRt.anchoredPosition = UG.Vector2(0.0, -218.2)
                altarRt.sizeDelta = UG.Vector2(124.0, 62.0)
                local altarTxt = btnAltarGo:GetComponentInChildren(typeof(UG.UI.Text), true)
                if altarTxt then altarTxt.fontSize = 18 end

                local cloneGo = GO.Instantiate(btnAltarGo, parentTf, false)
                cloneGo.name = "BtnHTPSAutoAltar"
                cloneGo:SetActive(true)
                local rt = cloneGo:GetComponent(typeof(UG.RectTransform))
                rt.anchoredPosition = UG.Vector2(134.0, -218.2)
                rt.sizeDelta = UG.Vector2(136.0, 62.0)

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
                    txt.fontSize = 17
                    txt.text = "Auto Luyện Hết"
                    _G.HTPS_BTN_ALTAR_TXT = txt
                end
                btnAutoTf = cloneGo.transform
                _G.HTPS_UpdateAltarBtnUI()
            end

            if btnAutoTf and _G.HTPS_BOUND_ALTAR_BTN ~= btnAutoTf then
                local bc = btnAutoTf:GetComponent(typeof(UG.UI.Button))
                if bc then
                    bc.onClick = UG.UI.Button.ButtonClickedEvent()
                    bc.onClick:AddListener(function()
                        _G.HTPS_RunAutoAltar()
                    end)
                end
                _G.HTPS_BOUND_ALTAR_BTN = btnAutoTf
            end
        end)
    end

    
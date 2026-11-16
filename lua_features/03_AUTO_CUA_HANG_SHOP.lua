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
-- TÍNH NĂNG: Tự Động Mua Vật Phẩm Cửa Hàng Bằng Vàng/Kim Cương (Action 131/132)
-- TRÍCH XUẤT TỪ NGUYENVINHMOD.DLL BẰNG REA ENGINE
-- =====================================================================

-- ==================== AUTO KIỂM TRA & MUA CỬA HÀNG MỖI KHI VÀO GAME (Action 131 & 132) ====================
    _G.HTPS_SerializeProto = function(proto)
        local ms = CS.System.IO.MemoryStream()
        local serializer = CS.PbMethodSerializer()
        serializer:Serialize(ms, proto)
        return ms:ToArray()
    end

    _G.HTPS_DeserializeProto = function(bytes, typeName)
        local ms = CS.System.IO.MemoryStream(bytes)
        local serializer = CS.PbMethodSerializer()
        local typeToParse = CS.System.Type.GetType(typeName)
        return serializer:Deserialize(ms, nil, typeToParse)
    end

    _G.HTPS_AutoCheckAndBuyDailyShop = function(forceToastWhenEmpty)
        if _G.HTPS_SHOP_AUTO_CHECKING then return end
        local gc = CS.GameContext.GetIntance()
        local csNet = CS.NetworkController.GetInstance()
        if not gc or not gc.m_Session or gc.m_Session == "" or not csNet or not csNet.m_UrlGameServer or csNet.m_UrlGameServer == "" then
            return
        end
        _G.HTPS_SHOP_AUTO_CHECKING = true
        CsCoroutine.start(function()
            local ok, err = pcall(function()
                local urlServer = csNet.m_UrlGameServer
                local reqStatus = CS.pbdson.RequestData()
                reqStatus.session = gc.m_Session
                local act131 = CS.pbdson.PbAction()
                act131.actionId = 131
                reqStatus.actions:Add(act131)

                local www = CS.UnityEngine.Networking.UnityWebRequest.Put(urlServer, _G.HTPS_SerializeProto(reqStatus))
                www.timeout = 10
                coroutine.yield(www:SendWebRequest())
                local okShop1 = (not www.isNetworkError and not www.isHttpError)
                local dataShop1 = okShop1 and www.downloadHandler and www.downloadHandler.data or nil
                pcall(function() www:Dispose() end)
                if not okShop1 or not dataShop1 then
                    _G.HTPS_NEXT_SHOP_CHECK_TIME = os.time() + 30
                    return
                end
                local resp = _G.HTPS_DeserializeProto(dataShop1, "pbdson.ResponseData,PbMethodLib")
                if not resp or not resp.aAction then return end

                local toBuy = {}
                local levelShop = 1
                local timeCountDown = 3600

                for i = 0, resp.aAction.Count - 1 do
                    local pbAct = resp.aAction[i]
                    if pbAct.actionId == 131 and pbAct.data then
                        local lstCv = _G.HTPS_DeserializeProto(pbAct.data, "pbdson.ListCommonVector,PbMethodLib")
                        if lstCv and lstCv.aVector and lstCv.aVector.Count >= 4 then
                            local cv1 = lstCv.aVector[0]
                            local cv3 = lstCv.aVector[2]
                            local cv4 = lstCv.aVector[3]
                            levelShop = cv1.aLong[0]
                            timeCountDown = tonumber(cv1.aLong[1]) or 3600
                            for k = 0, cv3.aLong.Count - 1 do
                                local limit = tonumber(cv3.aLong[k]) or 0
                                local itemIdx = tonumber(cv4.aLong[k]) or 0
                                if limit > 0 and itemIdx > 0 then
                                    table.insert(toBuy, { index = itemIdx, level = levelShop, limit = limit })
                                end
                            end
                        end
                    end
                end

                _G.HTPS_NEXT_SHOP_CHECK_TIME = os.time() + math.max(60, timeCountDown) + 3

                if #toBuy > 0 then
                    local reqBuy = CS.pbdson.RequestData()
                    reqBuy.session = gc.m_Session
                    for _, item in ipairs(toBuy) do
                        local cv = CS.pbdson.CommonVector()
                        cv.aLong:Add(item.index)
                        cv.aLong:Add(item.level)
                        cv.aLong:Add(item.limit)
                        local act132 = CS.pbdson.PbAction()
                        act132.actionId = 132
                        act132.data = _G.HTPS_SerializeProto(cv)
                        reqBuy.actions:Add(act132)
                    end

                    local wwwBuy = CS.UnityEngine.Networking.UnityWebRequest.Put(urlServer, _G.HTPS_SerializeProto(reqBuy))
                    wwwBuy.timeout = 10
                    coroutine.yield(wwwBuy:SendWebRequest())
                    pcall(function() wwwBuy:Dispose() end)

                    CS.Toast.ShowToast(string.format("[Auto Cửa Hàng] Đã tự động mua %d/12 món hôm nay!", #toBuy))

                    local psGo = GO.Find("PopupShopNew(Clone)")
                    if psGo and psGo.activeInHierarchy and DataSender and DataSender.instance then
                        DataSender:instance():GetShopNewStatus()
                    end
                elseif forceToastWhenEmpty then
                    local h = math.floor(timeCountDown / 3600)
                    local m = math.floor((timeCountDown % 3600) / 60)
                    CS.Toast.ShowToast(string.format("Đã mua hết 12 món hôm nay! (Tự mua tiếp sau %dh%02dp)", h, m))
                end
            end)
            _G.HTPS_SHOP_AUTO_CHECKING = false
        end)
    end

    _G.HTPS_EnsureShopNewButtons = function()
        if _G.HTPS_EnsureShopExchangeButtons then
            _G.HTPS_EnsureShopExchangeButtons()
        end
        if _G.HTPS_EnsurePopupShopAutoButtons then
            _G.HTPS_EnsurePopupShopAutoButtons()
        end
        pcall(function()
            -- 1. Tự động kiểm tra & mua ngầm ngay khi vào game (hoặc khi qua 00:00 đêm)
            local now = os.time()
            if not _G.HTPS_NEXT_SHOP_CHECK_TIME or now >= _G.HTPS_NEXT_SHOP_CHECK_TIME then
                local sceneName = UG.SceneManagement.SceneManager.GetActiveScene().name
                if sceneName == "Home2Scene" or sceneName == "LuaScene" then
                    _G.HTPS_AutoCheckAndBuyDailyShop(false)
                end
            end

            -- 2. Nếu mở PopupShopNew(Clone), gắn nút [Mua Hết 12 Món] & tự kiểm tra nếu còn món chưa mua
            local psGo = GO.Find("PopupShopNew(Clone)")
            if not psGo or not psGo.activeInHierarchy then return end

            local contentTf = psGo.transform:Find("Content/ScrollView/Viewport/Content")
            if contentTf then
                for i = 0, contentTf.childCount - 1 do
                    local cellTf = contentTf:GetChild(i)
                    if cellTf.gameObject.activeSelf then
                        local cps = cellTf:GetComponent("CellPopupShop")
                        local parentItem = cps and cps._parentItem
                        if parentItem then
                            for k = 0, parentItem.transform.childCount - 1 do
                                local itGo = parentItem.transform:GetChild(k).gameObject
                                if itGo.activeSelf then
                                    local si = itGo:GetComponent("ShopItem")
                                    local info = si and LuaUtils.getObjectMemberValue(si, "m_ShopItemInfo")
                                    if info and info.m_MaxCanBuy and info.m_MaxCanBuy > 0 then
                                        _G.HTPS_AutoCheckAndBuyDailyShop(false)
                                        break
                                    end
                                end
                            end
                        end
                    end
                end
            end

            local grpAsset = psGo.transform:Find("Content/GroupAsset")
            if not grpAsset then return end
            local btnTf = grpAsset:Find("BtnHTPSBuyAllShopNew")
            if not btnTf then
                local tplBtnGo = nil
                if contentTf and contentTf.childCount > 0 then
                    local cps = contentTf:GetChild(0):GetComponent("CellPopupShop")
                    if cps and cps._parentItem and cps._parentItem.transform.childCount > 0 then
                        local si = cps._parentItem.transform:GetChild(0):GetComponent("ShopItem")
                        if si and si.m_GoPrice then tplBtnGo = si.m_GoPrice.gameObject end
                    end
                end
                if tplBtnGo then
                    local cloneGo = GO.Instantiate(tplBtnGo, grpAsset, false)
                    cloneGo.name = "BtnHTPSBuyAllShopNew"
                    cloneGo:SetActive(true)
                    local iconTf = cloneGo.transform:Find("IconPrice")
                    if iconTf then iconTf.gameObject:SetActive(false) end
                    local rt = cloneGo:GetComponent(typeof(UG.RectTransform))
                    rt.anchorMin = UG.Vector2(0.5, 0.5)
                    rt.anchorMax = UG.Vector2(0.5, 0.5)
                    rt.pivot = UG.Vector2(0.5, 0.5)
                    rt.anchoredPosition = UG.Vector2(175, 0)
                    rt.sizeDelta = UG.Vector2(195, 46)
                    local txt = cloneGo:GetComponentInChildren(typeof(UG.UI.Text), true)
                    if txt then
                        local trt = txt.gameObject:GetComponent(typeof(UG.RectTransform))
                        trt.anchoredPosition = UG.Vector2(0, 0)
                        trt.sizeDelta = UG.Vector2(185, 42)
                        txt.alignment = UG.TextAnchor.MiddleCenter
                        txt.fontSize = 17
                        txt.text = "Auto Mua (Đang Bật)"
                    end
                    btnTf = cloneGo.transform
                end
            end
            if btnTf and _G.HTPS_BOUND_SHOPNEW_BTN ~= btnTf then
                local bc = btnTf:GetComponent(typeof(UG.UI.Button))
                if bc then
                    bc.onClick = UG.UI.Button.ButtonClickedEvent()
                    bc.onClick:AddListener(function()
                        _G.HTPS_AutoCheckAndBuyDailyShop(true)
                    end)
                end
                _G.HTPS_BOUND_SHOPNEW_BTN = btnTf
            end
        end)
    end

    -- ==================== ĐỔI NHIỀU (x10, x100) & ĐỔI HẾT TRONG MỌI CỬA HÀNG (POPUPSHOP / ACTION 121) ====================
    _G.HTPS_SHOP_BATCH_RUNNING = false
    _G.HTPS_SHOP_BATCH_STOP = false

    _G.HTPS_RunShopBatchBuy = function(pm, info, targetCount)
        if _G.HTPS_SHOP_BATCH_RUNNING then
            _G.HTPS_SHOP_BATCH_STOP = true
            return
        end
        if not info then return end

        local REF_FLAGS = 60
        local gc = CS.GameContext.GetIntance()
        local nc = CS.NetworkController.GetInstance()
        if not gc or not nc then return end

        local shopId = tonumber(info.m_ShopId) or 0
        local itemId = tonumber(info.m_ShopItemId) or 0
        local obj = info.m_ObjModel
        local costObj = info.m_ItemConsumeCost
        local itemName = tostring((obj and (obj.m_ItemName or obj.m_HeroName)) or ("Vật phẩm #" .. tostring(itemId)))
        local perBuyNum = (obj and tonumber(obj.m_Number)) or 1
        local costNum = (costObj and tonumber(costObj.m_Number)) or 1
        local haveNum = (costObj and tonumber(CS.BonusModel.GetNumberItemInInventory(costObj))) or 0
        local maxAfford = (costNum > 0) and math.floor(haveNum / costNum) or 0

        if maxAfford <= 0 then
            CS.Toast.ShowToast("⚠️ Không đủ nguyên liệu để đổi " .. itemName .. "!")
            return
        end

        local totalToBuy = math.min(tonumber(targetCount) or 1, maxAfford)
        if totalToBuy <= 0 then return end

        _G.HTPS_SHOP_BATCH_RUNNING = true
        _G.HTPS_SHOP_BATCH_STOP = false
        _G.HTPS_BONUS_SUPPRESS_UNTIL = 0
        if _G.HTPS_AUTO then _G.HTPS_AUTO.suppressPopup = true end

        CsCoroutine.start(function()
            local bought = 0
            local txtMsg = nil
            pcall(function()
                if pm and not pm:Equals(nil) then
                    txtMsg = pm:GetType():GetField("m_TextMessage", REF_FLAGS):GetValue(pm)
                    if txtMsg then txtMsg.supportRichText = true end
                end
            end)

            while bought < totalToBuy and not _G.HTPS_SHOP_BATCH_STOP do
                if not pm or pm:Equals(nil) or not pm.gameObject.activeInHierarchy then
                    break
                end

                local curHave = (costObj and tonumber(CS.BonusModel.GetNumberItemInInventory(costObj))) or 0
                local canStillAfford = (costNum > 0) and math.floor(curHave / costNum) or 0
                if canStillAfford <= 0 then
                    break
                end

                local remain = math.min(totalToBuy - bought, canStillAfford)
                local batch = math.min(5, remain)
                if batch <= 0 then break end

                if txtMsg and not txtMsg:Equals(nil) then
                    txtMsg.text = string.format("Đang tự động đổi <color=#FFD700>%s</color>: <color=#00FF7F>%d / %d</color> lần...\n(Bấm [Không] hoặc bất kỳ nút Đổi nào để dừng)",
                        itemName, bought, totalToBuy)
                end

                local req = CS.pbdson.RequestData()
                req.session = gc.m_Session
                for b = 1, batch do
                    local cv = CS.pbdson.CommonVector()
                    cv.aLong:Add(shopId)
                    cv.aLong:Add(itemId)
                    cv.aLong:Add(1)
                    local act = CS.pbdson.PbAction()
                    act.actionId = 121
                    act.data = _G.HTPS_SerializeProto(cv)
                    req.actions:Add(act)
                end

                _G.HTPS_BONUS_SUPPRESS_UNTIL = 0
                if _G.HTPS_AUTO then _G.HTPS_AUTO.suppressPopup = true end

                local d, ok = _G.HTPS_PutWebRequest(
                    nc.m_UrlGameServer .. "/i/121/" .. tostring(gc.m_UserId),
                    _G.HTPS_SerializeProto(req),
                    8
                )

                local gotInBatch = 0
                local serverErr = nil
                if ok and d then
                    pcall(function()
                        local resp = _G.HTPS_DeserializeProto(d, "pbdson.ResponseData,PbMethodLib")
                        if resp and resp.aAction then
                            for i = 0, resp.aAction.Count - 1 do
                                local a = resp.aAction[i]
                                if a.actionId == 121 and a.data then
                                    local rcv = _G.HTPS_DeserializeProto(a.data, "pbdson.CommonVector,PbMethodLib")
                                    if rcv and rcv.aLong and rcv.aLong.Count > 0 then
                                        CS.BonusModel.ParseBonusReceived(rcv.aLong, true)
                                        gotInBatch = gotInBatch + 1
                                        bought = bought + 1
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
                if gotInBatch < batch or serverErr then
                    break
                end
                coroutine.yield(nil)
            end

            _G.HTPS_SHOP_BATCH_RUNNING = false
            _G.HTPS_SHOP_BATCH_STOP = false
            _G.HTPS_KillSummonPopups()

            pcall(function()
                local ps = _G.HTPS_FindObjectOfType(typeof(CS.PopupShop))
                if ps and not ps:Equals(nil) then
                    ps:ShowPlayerAsset()
                    if bought < totalToBuy then
                        local cache = ps:GetType():GetField("_cacheShopData", REF_FLAGS):GetValue(ps)
                        if cache and cache:ContainsKey(shopId) then
                            cache:Remove(shopId)
                        end
                        gc.dataSender:ShopRequestData(shopId)
                    end
                end
            end)

            pcall(function()
                if pm and not pm:Equals(nil) and pm.gameObject then
                    UG.Object.Destroy(pm.gameObject)
                end
            end)

            if bought > 0 then
                CS.Toast.ShowToast(string.format("🛒 Đã đổi thành công %d lần %s (Tổng +%d)!", bought, itemName, bought * perBuyNum))
            else
                CS.Toast.ShowToast("⚠️ Vật phẩm đã hết lượt đổi hoặc không đủ nguyên liệu!")
            end
        end)
    end

    _G.HTPS_EnsureShopExchangeButtons = function()
        pcall(function()
            local pm = _G.HTPS_FindObjectOfType(typeof(CS.PopupMessage))
            if not pm or pm:Equals(nil) or not pm.gameObject.activeInHierarchy then return end

            local REF_FLAGS = 60
            local pmt = pm:GetType()
            local cb = pmt:GetField("m_Action1Cb", REF_FLAGS):GetValue(pm)
            if not cb or not cb.Target or cb.Target:GetType() ~= typeof(CS.ShopItem) then
                return
            end

            local si = cb.Target
            local info = si:GetType():GetField("m_ShopItemInfo", REF_FLAGS):GetValue(si)
            if not info then return end

            local b1Go = pmt:GetField("m_ButtonAction1", REF_FLAGS):GetValue(pm)
            local b2Go = pmt:GetField("m_ButtonAction2", REF_FLAGS):GetValue(pm)
            local txtMsg = pmt:GetField("m_TextMessage", REF_FLAGS):GetValue(pm)
            if not b1Go or not b2Go then return end

            local gbTf = b1Go.transform.parent
            if not gbTf then return end

            if _G.HTPS_BOUND_SHOP_PM ~= pm then
                _G.HTPS_BOUND_SHOP_PM = pm

                local obj = info.m_ObjModel
                local costObj = info.m_ItemConsumeCost
                local itemName = tostring((obj and (obj.m_ItemName or obj.m_HeroName)) or "Vật phẩm")
                local perBuyNum = (obj and tonumber(obj.m_Number)) or 1
                local costNum = (costObj and tonumber(costObj.m_Number)) or 1
                local haveNum = (costObj and tonumber(CS.BonusModel.GetNumberItemInInventory(costObj))) or 0
                local maxAfford = (costNum > 0) and math.floor(haveNum / costNum) or 0

                if txtMsg then
                    local locMsg = txtMsg.gameObject:GetComponent(typeof(CS.I2.Loc.Localize))
                    if locMsg then UG.Object.DestroyImmediate(locMsg) end
                    txtMsg.supportRichText = true
                    local numStr = (perBuyNum > 1) and (" x" .. tostring(perBuyNum)) or ""
                    txtMsg.text = string.format("Bạn muốn đổi <color=#FFD700>%s%s</color>?\n(Hiện đủ nguyên liệu đổi tối đa: <color=#00FF7F>%d lần</color>)",
                        itemName, numStr, maxAfford)
                end

                local function styleBtn(btnGo, xPos, labelText)
                    local rt = btnGo:GetComponent(typeof(UG.RectTransform))
                    if rt then
                        rt.anchorMin = UG.Vector2(0.0, 1.0)
                        rt.anchorMax = UG.Vector2(0.0, 1.0)
                        rt.pivot = UG.Vector2(0.5, 0.5)
                        rt.anchoredPosition = UG.Vector2(xPos, -30.0)
                        rt.sizeDelta = UG.Vector2(112.0, 56.0)
                    end
                    local txt = btnGo:GetComponentInChildren(typeof(UG.UI.Text), true)
                    if txt then
                        local loc = txt.gameObject:GetComponent(typeof(CS.I2.Loc.Localize))
                        if loc then UG.Object.DestroyImmediate(loc) end
                        txt.fontSize = 18
                        txt.alignment = UG.TextAnchor.MiddleCenter
                        txt.text = labelText
                    end
                end

                local old100 = gbTf:Find("BtnHTPSShopBuy100")
                if old100 then old100.gameObject:SetActive(false) end

                styleBtn(b2Go, -3.0, "Không")
                styleBtn(b1Go, 119.0, "Đổi x1")

                local function makeExtraBtn(name, xPos, labelText, countVal)
                    local existing = gbTf:Find(name)
                    local cloneGo = existing and existing.gameObject or GO.Instantiate(b1Go, gbTf, false)
                    cloneGo.name = name
                    cloneGo:SetActive(true)
                    styleBtn(cloneGo, xPos, labelText)
                    local bc = cloneGo:GetComponent(typeof(UG.UI.Button))
                    if bc then
                        bc.onClick = UG.UI.Button.ButtonClickedEvent()
                        bc.onClick:AddListener(function()
                            _G.HTPS_RunShopBatchBuy(pm, info, countVal)
                        end)
                    end
                end

                makeExtraBtn("BtnHTPSShopBuy10", 241.0, "Đổi x10", 10)
                makeExtraBtn("BtnHTPSShopBuyAll", 363.0, "Đổi Hết", 999999)
            end
        end)
    end


    
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
-- TÍNH NĂNG: Tự Động Xoay Vòng Quay Đồ & Bụi Ma Thuật, Bỏ Hoạt Cảnh, Gộp 160 Lượt/Gói Mạng
-- TRÍCH XUẤT TỪ NGUYENVINHMOD.DLL BẰNG REA ENGINE
-- =====================================================================

-- ==================== AUTO VÒNG QUAY (TỰ MUA VÉ + TỰ RESET) & AUTO GHÉP TRANG BỊ LÊN DẦN 6★ ====================
    _G.HTPS_SyncServerEquipmentAndSafeGold = function()
        -- Đã gỡ bỏ hoàn toàn cơ chế xả Vàng bằng Action 235 (Tẩy Đá) vì Server hỗ trợ Vàng 64-bit trực tiếp,
        -- và Action 235 làm hao hụt Bụi Ma Thuật ngoài ý muốn!
    end

    _G.HTPS_FormatMarketNum = function(n)
        n = tonumber(n) or 0
        if n >= 1000000 and (n % 1000000 == 0) then
            return string.format("%dM", math.floor(n / 1000000))
        elseif n >= 1000000 then
            return string.format("%.1fM", n / 1000000)
        elseif n >= 10000 and (n % 1000 == 0) then
            return string.format("%dK", math.floor(n / 1000))
        end
        return tostring(math.floor(n))
    end

    _G.HTPS_GetMarketItemIdentity = function(info)
        if not info then return "UNKNOWN", "Vật phẩm", 1 end
        local obj = info.m_ObjModel
        local typeName = "Item"
        local itemKey = nil
        local itemName = nil
        local qty = 1
        if obj then
            pcall(function() typeName = tostring(obj:GetType().Name) end)
            pcall(function() itemKey = obj.m_ItemKey end)
            if itemKey == nil then
                pcall(function() itemKey = obj.m_HeroKey end)
            end
            pcall(function() itemName = obj.m_ItemName end)
            if not itemName or itemName == "" then
                pcall(function() itemName = obj.m_HeroName end)
            end
            if not itemName or itemName == "" then
                pcall(function() itemName = obj.m_Name end)
            end
            pcall(function() qty = tonumber(obj.m_Number) or 1 end)
        end
        if not itemName or itemName == "" then
            local sid = 0
            pcall(function() sid = tonumber(info.m_ShopItemId) or 0 end)
            itemName = "Vật phẩm #" .. tostring(sid)
        end
        local uid = typeName .. "_" .. tostring(itemKey ~= nil and itemKey or itemName)
        return uid, tostring(itemName), (tonumber(qty) or 1)
    end

    _G.HTPS_GetMarketOptions = function(ps)
        local opts = {}
        local groupMap = {}
        local groupOrder = {}
        pcall(function()
            if not ps or ps:Equals(nil) then return end
            local lst = ps:GetType():GetField("m_LstShopItemData", 60):GetValue(ps)
            if lst and lst.Count > 0 then
                for i = 0, lst.Count - 1 do
                    local info = lst[i]
                    if info then
                        local slotId = tonumber(info.m_ShopItemId) or i
                        local itemUid, itemName, qty = _G.HTPS_GetMarketItemIdentity(info)
                        local cost = info.m_ItemConsumeCost
                        local costAmt = (cost and tonumber(cost.m_Number)) or 0
                        local costKey = (cost and tonumber(cost.m_ItemKey)) or 1000
                        local grp = groupMap[itemUid]
                        if not grp then
                            grp = {
                                itemUid = itemUid,
                                itemName = itemName,
                                totalQty = 0,
                                costKC = 0,
                                costGold = 0,
                                costOther = 0,
                                slots = {}
                            }
                            groupMap[itemUid] = grp
                            table.insert(groupOrder, grp)
                        end
                        grp.totalQty = grp.totalQty + qty
                        if costKey == 1000 then
                            grp.costKC = grp.costKC + costAmt
                        elseif costKey == 1001 then
                            grp.costGold = grp.costGold + costAmt
                        else
                            grp.costOther = grp.costOther + costAmt
                        end
                        table.insert(grp.slots, {
                            slotId = slotId,
                            qty = qty,
                            costAmt = costAmt,
                            costKey = costKey
                        })
                    end
                end
            end
        end)
        for _, grp in ipairs(groupOrder) do
            local costParts = {}
            if grp.costKC > 0 then table.insert(costParts, _G.HTPS_FormatMarketNum(grp.costKC) .. " KC") end
            if grp.costGold > 0 then table.insert(costParts, _G.HTPS_FormatMarketNum(grp.costGold) .. " Vàng") end
            if grp.costOther > 0 then table.insert(costParts, _G.HTPS_FormatMarketNum(grp.costOther) .. " Xu") end
            local costStr = (#costParts > 0) and table.concat(costParts, " + ") or "Miễn phí"
            local slotCnt = #grp.slots
            local label, shortLabel
            if slotCnt > 1 then
                label = string.format("%s (+%s / %d ô - %s)", grp.itemName, _G.HTPS_FormatMarketNum(grp.totalQty), slotCnt, costStr)
                shortLabel = string.format("%s (+%s / %d ô)", grp.itemName, _G.HTPS_FormatMarketNum(grp.totalQty), slotCnt)
            else
                label = string.format("%s (+%s - %s)", grp.itemName, _G.HTPS_FormatMarketNum(grp.totalQty), costStr)
                shortLabel = string.format("%s (+%s - %s)", grp.itemName, _G.HTPS_FormatMarketNum(grp.totalQty), costStr)
            end
            table.insert(opts, {
                itemUid = grp.itemUid,
                label = label,
                shortLabel = shortLabel,
                itemName = grp.itemName,
                totalQty = grp.totalQty,
                slotCnt = slotCnt,
                slots = grp.slots
            })
        end
        if #opts > 0 then
            table.insert(opts, {
                itemUid = "__ALL__",
                label = "[Tất cả] Mua hết món Chợ Đen",
                shortLabel = "Tất cả món Chợ Đen",
                itemName = "Tất cả món Chợ Đen",
                totalQty = 1,
                slotCnt = 0,
                slots = {}
            })
        end
        return opts
    end

    _G.HTPS_NATIVE_SPRITE_CACHE = _G.HTPS_NATIVE_SPRITE_CACHE or {}
    _G.HTPS_FindNativeSprite = function(spName, requireSliced)
        if not spName or spName == "" then return nil end
        local cacheKey = spName .. (requireSliced and "_sliced" or "_any")
        local cached = _G.HTPS_NATIVE_SPRITE_CACHE[cacheKey]
        if cached and not cached:Equals(nil) then
            return cached
        end
        local ok, allSp = pcall(_G.HTPS_GetModSprites)
        if ok and allSp then
            local fallback = nil
            for i = 0, allSp.Length - 1 do
                local sp = allSp[i]
                if sp and not sp:Equals(nil) and sp.name == spName then
                    local b = sp.border
                    local hasBorder = (b.x + b.y + b.z + b.w) > 0
                    if hasBorder then
                        _G.HTPS_NATIVE_SPRITE_CACHE[cacheKey] = sp
                        return sp
                    elseif not fallback and not requireSliced then
                        fallback = sp
                    end
                end
            end
            if fallback then
                _G.HTPS_NATIVE_SPRITE_CACHE[cacheKey] = fallback
                return fallback
            end
        end
        return nil
    end

    _G.HTPS_FormatExactInt = function(n)
        local s = tostring(math.floor(tonumber(n) or 0))
        local k
        while true do
            s, k = s:gsub("^(-?%d+)(%d%d%d)", "%1,%2")
            if k == 0 then break end
        end
        return s
    end

    _G.HTPS_SHOP_COUNTER_DATA = _G.HTPS_SHOP_COUNTER_DATA or {}

    _G.HTPS_GetShopCounterKey = function(shopId, selUid)
        shopId = tonumber(shopId) or 2
        if shopId == 1 then
            local u = tostring(selUid or _G.HTPS_MARKET_SELECTED_UID or "")
            return "1_" .. ((u ~= "") and u or "__DEFAULT__")
        elseif shopId == 3 then
            return "3_stone"
        end
        return "shop_" .. tostring(shopId)
    end

    _G.HTPS_AddShopCounter = function(shopId, selUid, itemName, addQty, addBuys, addResets)
        local key = _G.HTPS_GetShopCounterKey(shopId, selUid)
        local rec = _G.HTPS_SHOP_COUNTER_DATA[key]
        if not rec then
            rec = { qty = 0, buys = 0, resets = 0, name = itemName or "Vật phẩm" }
            _G.HTPS_SHOP_COUNTER_DATA[key] = rec
        end
        if itemName and itemName ~= "" then rec.name = itemName end
        rec.qty = (rec.qty or 0) + (tonumber(addQty) or 0)
        rec.buys = (rec.buys or 0) + (tonumber(addBuys) or 0)
        rec.resets = (rec.resets or 0) + (tonumber(addResets) or 0)
        return rec
    end

    _G.HTPS_UpdateAutoShopButtonStyle = function(ps)
        pcall(function()
            ps = ps or _G.HTPS_FindObjectOfType(typeof(CS.PopupShop))
            local sid = (ps and not ps:Equals(nil)) and (tonumber(ps:GetType():GetField("m_ShopId", 60):GetValue(ps)) or 2) or 2
            local btnTf = _G.HTPS_BTN_SHOP_AUTO_NEW_TF
            local spYellow = _G.HTPS_FindNativeSprite("button_yellow", true) or _G.HTPS_FindNativeSprite("button_green", true)
            if btnTf and not btnTf:Equals(nil) then
                local img = btnTf:GetComponent(typeof(UG.UI.Image))
                if img and spYellow then
                    img.sprite = spYellow
                    img.type = UG.UI.Image.Type.Sliced
                end
                if _G.HTPS_SHOP_AUTO_RESET_RUNNING then
                    if img then
                        img.color = spYellow and UG.Color(1.0, 0.48, 0.46, 1.0) or UG.Color(0.76, 0.15, 0.15, 0.98)
                    end
                else
                    if img then
                        img.color = spYellow and UG.Color(1.0, 1.0, 1.0, 1.0) or UG.Color(0.88, 0.68, 0.18, 0.98)
                    end
                end
            end
            local txt = _G.HTPS_BTN_SHOP_AUTO_RESET_TXT
            if txt and not txt:Equals(nil) then
                local tOut = txt.gameObject:GetComponent(typeof(UG.UI.Outline))
                if _G.HTPS_SHOP_AUTO_RESET_RUNNING then
                    txt.text = "Dừng Auto Mua"
                    txt.color = UG.Color(1.0, 0.98, 0.95, 1.0)
                    if tOut then tOut.enabled = true end
                else
                    txt.text = (sid == 1) and "Auto Mua Chợ Đen" or "Auto Mua + Reset"
                    txt.color = spYellow and UG.Color(0.510, 0.318, 0.165, 1.0) or UG.Color(1.0, 0.98, 0.90, 1.0)
                    if tOut then tOut.enabled = false end
                end
            end
        end)
    end

    _G.HTPS_RefreshShopCounterUI = function(ps)
        pcall(function()
            ps = ps or _G.HTPS_FindObjectOfType(typeof(CS.PopupShop))
            if not ps or ps:Equals(nil) then return end
            local btnRef = ps:GetType():GetField("m_ButtonRefresh", 60):GetValue(ps)
            if not btnRef or not btnRef.transform.parent then return end
            local cntPanel = btnRef.transform.parent:Find("PanelHTPSMarketCounter")
            if not cntPanel then return end
            local t1Tf = cntPanel:Find("TxtLine1")
            local t2Tf = cntPanel:Find("TxtLine2")
            local t1 = t1Tf and t1Tf:GetComponent(typeof(UG.UI.Text)) or nil
            local t2 = t2Tf and t2Tf:GetComponent(typeof(UG.UI.Text)) or nil
            if not t1 or not t2 then return end

            local sid = tonumber(ps:GetType():GetField("m_ShopId", 60):GetValue(ps)) or 2
            local selUid = tostring(_G.HTPS_MARKET_SELECTED_UID or "")
            local itemName = "Vật phẩm"
            if sid == 1 then
                local opts = _G.HTPS_GetMarketOptions(ps)
                local matched = nil
                for _, o in ipairs(opts) do
                    if o.itemUid == selUid then matched = o; break end
                end
                if not matched and #opts > 0 then
                    matched = opts[1]
                    selUid = matched.itemUid
                    _G.HTPS_MARKET_SELECTED_UID = selUid
                end
                if matched then itemName = matched.itemName end
            elseif sid == 3 then
                itemName = "Đá nâng đồ"
            end

            local key = _G.HTPS_GetShopCounterKey(sid, selUid)
            local rec = _G.HTPS_SHOP_COUNTER_DATA[key] or { qty = 0, buys = 0, resets = 0, name = itemName }

            if sid == 1 then
                if selUid == "__ALL__" then
                    t1.text = string.format("Đã mua: %s ô (Tất cả)", _G.HTPS_FormatExactInt(rec.buys))
                    t2.text = string.format("Làm mới: %s lần (Chạm xóa)", _G.HTPS_FormatExactInt(rec.resets))
                else
                    t1.text = string.format("+%s %s", _G.HTPS_FormatExactInt(rec.qty), itemName)
                    t2.text = string.format("Làm mới: %s | %s ô (Chạm xóa)", _G.HTPS_FormatExactInt(rec.resets), _G.HTPS_FormatExactInt(rec.buys))
                end
            elseif sid == 3 then
                t1.text = string.format("+%s Đá nâng đồ", _G.HTPS_FormatExactInt(rec.qty))
                t2.text = string.format("Làm mới: %s lần (Chạm xóa)", _G.HTPS_FormatExactInt(rec.resets))
            else
                t1.text = string.format("Đã mua: %s món", _G.HTPS_FormatExactInt(rec.buys))
                t2.text = string.format("Làm mới: %s lần (Chạm xóa)", _G.HTPS_FormatExactInt(rec.resets))
            end
        end)
    end

    _G.HTPS_ManualRefreshMarketOnce = function()
        if _G.HTPS_SHOP_AUTO_RESET_RUNNING then
            if CS.Toast then CS.Toast.ShowToast("⚠️ Đang chạy Auto Mua, hãy bấm [⏹ DỪNG AUTO MUA] trước!") end
            return
        end
        if _G.HTPS_MARKET_MANUAL_REFRESH_BUSY then return end

        local ps = _G.HTPS_FindObjectOfType(typeof(CS.PopupShop))
        if not ps or ps:Equals(nil) or not ps.gameObject.activeInHierarchy then return end
        local gc = CS.GameContext.GetIntance()
        local csNet = CS.NetworkController.GetInstance()
        local urlServer = csNet and csNet.m_UrlGameServer or ""
        if not gc or not csNet or urlServer == "" then return end

        if (tonumber(gc.m_Gem) or 0) < 50 then
            if CS.Toast then CS.Toast.ShowToast("⚠️ Không đủ 50 Kim Cương để làm mới Chợ Đen!") end
            return
        end

        _G.HTPS_MARKET_MANUAL_REFRESH_BUSY = true
        CsCoroutine.start(function()
            pcall(function()
                local req = CS.pbdson.RequestData()
                req.session = gc.m_Session

                local cv122 = CS.pbdson.CommonVector()
                cv122.aLong:Add(1)
                cv122.aLong:Add(0)
                local a122 = CS.pbdson.PbAction()
                a122.actionId = 122
                a122.data = _G.HTPS_SerializeProto(cv122)
                req.actions:Add(a122)

                local cv128 = CS.pbdson.CommonVector()
                cv128.aLong:Add(1)
                local a128 = CS.pbdson.PbAction()
                a128.actionId = 128
                a128.data = _G.HTPS_SerializeProto(cv128)
                req.actions:Add(a128)

                local d = _G.HTPS_PutWebRequest(urlServer .. "/i/122/" .. tostring(gc.m_UserId), _G.HTPS_SerializeProto(req), 8)
                local errStr = nil
                if d then
                    local r = _G.HTPS_DeserializeProto(d, "pbdson.ResponseData,PbMethodLib")
                    if r and r.aAction then
                        for i = 0, r.aAction.Count - 1 do
                            local act = r.aAction[i]
                            if act.actionId == 122 and act.data then
                                local cv = _G.HTPS_DeserializeProto(act.data, "pbdson.CommonVector,PbMethodLib")
                                if cv and cv.aLong then
                                    CS.BonusModel.ParseBonusReceived(cv.aLong)
                                end
                            elseif act.actionId == 128 and act.data then
                                pcall(function() csNet:ProcessPackageEvent(128, act.data) end)
                            elseif act.actionId == 1 and act.data then
                                local cv = _G.HTPS_DeserializeProto(act.data, "pbdson.CommonVector,PbMethodLib")
                                if cv and cv.aString and cv.aString.Count > 0 then
                                    errStr = tostring(cv.aString[0])
                                end
                            end
                        end
                    end
                else
                    errStr = "Lỗi kết nối máy chủ!"
                end

                pcall(function()
                    if ps and not ps:Equals(nil) then ps:ShowPlayerAsset() end
                end)
                if CS.Toast then
                    if errStr then
                        CS.Toast.ShowToast("⚠️ " .. errStr)
                    else
                        CS.Toast.ShowToast("🔄 Đã làm mới Chợ Đen (-50 KC)!")
                    end
                end
            end)
            _G.HTPS_MARKET_MANUAL_REFRESH_BUSY = false
        end)
    end

    if _G.HTPS_MARKET_SELECTED_UID == nil then
        pcall(function()
            _G.HTPS_MARKET_SELECTED_UID = UG.PlayerPrefs.GetString("HTPS_MARKET_ITEM_UID", "")
        end)
        if _G.HTPS_MARKET_SELECTED_UID == nil then _G.HTPS_MARKET_SELECTED_UID = "" end
    end

    _G.HTPS_ToggleAutoShopBuyAndReset = function()
        if not _G.HTPS_AUTO_ACTIVATED then
            if CS.Toast then CS.Toast.ShowToast("⚠️ Vui lòng kích hoạt bản quyền VIP để dùng tính năng này!") end
            if _G.HTPS_ShowActivationDialog then _G.HTPS_ShowActivationDialog(true) end
            return
        end

        if _G.HTPS_SHOP_AUTO_RESET_RUNNING then
            _G.HTPS_SHOP_AUTO_RESET_RUNNING = false
            local psNow = _G.HTPS_FindObjectOfType(typeof(CS.PopupShop))
            _G.HTPS_UpdateAutoShopButtonStyle(psNow)
            _G.HTPS_RefreshShopCounterUI(psNow)
            return
        end

        local ps = _G.HTPS_FindObjectOfType(typeof(CS.PopupShop))
        if not ps or ps:Equals(nil) or not ps.gameObject.activeInHierarchy then
            return
        end

        -- Tự đóng bảng chọn Dropdown nếu đang mở khi bấm Auto Mua
        pcall(function()
            local btnRef = ps:GetType():GetField("m_ButtonRefresh", 60):GetValue(ps)
            if btnRef and btnRef.transform.parent then
                local blk = btnRef.transform.parent:Find("BlockerHTPSMarketDrop")
                if blk and blk.gameObject.activeSelf then blk.gameObject:SetActive(false) end
            end
        end)

        pcall(function() xlua.private_accessible(CS.PopupShop) end)
        _G.HTPS_SHOP_AUTO_RESET_RUNNING = true
        _G.HTPS_BONUS_SUPPRESS_UNTIL = 0
        if _G.HTPS_AUTO then _G.HTPS_AUTO.suppressPopup = true end
        _G.HTPS_UpdateAutoShopButtonStyle(ps)
        _G.HTPS_RefreshShopCounterUI(ps)

        CsCoroutine.start(function()
            local REF_FLAGS = 60
            local gc = CS.GameContext.GetIntance()
            local inv = CS.PlayerInventory.GetInstance()
            local csNet = CS.NetworkController.GetInstance()
            local urlServer = csNet and csNet.m_UrlGameServer or ""
            local totalBought = 0
            local totalReset = 0
            local totalMarketQty = 0
            local stopReason = ""
            local curShopId = 2
            local marketTargetName = "Vật phẩm"

            local okLoop, errLoop = pcall(function()
                if not gc or not inv or not csNet or urlServer == "" then return end
                curShopId = tonumber(ps:GetType():GetField("m_ShopId", REF_FLAGS):GetValue(ps)) or 2

                -- Đảm bảo đồng bộ dữ liệu trang hiện tại của Shop từ Server trước khi mua
                local reqInit = CS.pbdson.RequestData()
                reqInit.session = gc.m_Session
                local cvInit = CS.pbdson.CommonVector()
                cvInit.aLong:Add(curShopId)
                local aInit = CS.pbdson.PbAction()
                aInit.actionId = 128
                aInit.data = _G.HTPS_SerializeProto(cvInit)
                reqInit.actions:Add(aInit)
                local dInit = _G.HTPS_PutWebRequest(urlServer .. "/i/128/" .. tostring(gc.m_UserId), _G.HTPS_SerializeProto(reqInit), 8)
                if dInit then
                    local rInit = _G.HTPS_DeserializeProto(dInit, "pbdson.ResponseData,PbMethodLib")
                    if rInit and rInit.aAction then
                        for i = 0, rInit.aAction.Count - 1 do
                            local act = rInit.aAction[i]
                            if act.actionId == 128 and act.data then
                                pcall(function() csNet:ProcessPackageEvent(128, act.data) end)
                            end
                        end
                    end
                end
                coroutine.yield(nil)

                while _G.HTPS_SHOP_AUTO_RESET_RUNNING do
                    _G.HTPS_BONUS_SUPPRESS_UNTIL = 0
                    if _G.HTPS_AUTO then _G.HTPS_AUTO.suppressPopup = true end
                    _G.HTPS_KillSummonPopups()

                    ps = _G.HTPS_FindObjectOfType(typeof(CS.PopupShop))
                    if not ps or ps:Equals(nil) or not ps.gameObject.activeInHierarchy then
                        _G.HTPS_SHOP_AUTO_RESET_RUNNING = false
                        break
                    end
                    local nowShopId = tonumber(ps:GetType():GetField("m_ShopId", REF_FLAGS):GetValue(ps)) or curShopId
                    if nowShopId ~= curShopId then
                        _G.HTPS_SHOP_AUTO_RESET_RUNNING = false
                        break
                    end

                    local selMarketUid = tostring(_G.HTPS_MARKET_SELECTED_UID or "")

                    -- Chế độ Siêu Tốc Vô Hạn Lượt cho Chợ Đen (ShopId = 1) theo Vật Phẩm (Gom TẤT CẢ các ô trùng vật phẩm):
                    -- Mua đồng thời toàn bộ các ô chứa vật phẩm đã chọn trên mỗi trang rồi mới Reset 50 KC để không lãng phí lượt Reset!
                    if curShopId == 1 and selMarketUid ~= "__ALL__" then
                        local lstItems = ps:GetType():GetField("m_LstShopItemData", REF_FLAGS):GetValue(ps)
                        local matchingSlots = {}
                        local fallbackUid = nil
                        if lstItems and lstItems.Count > 0 then
                            if selMarketUid == "" then
                                fallbackUid = select(1, _G.HTPS_GetMarketItemIdentity(lstItems[0]))
                                selMarketUid = fallbackUid
                                _G.HTPS_MARKET_SELECTED_UID = selMarketUid
                            end
                            for pass = 1, 2 do
                                matchingSlots = {}
                                for i = 0, lstItems.Count - 1 do
                                    local inf = lstItems[i]
                                    if inf then
                                        local uid, iName, qty = _G.HTPS_GetMarketItemIdentity(inf)
                                        if uid == selMarketUid then
                                            marketTargetName = iName
                                            local costObj = inf.m_ItemConsumeCost
                                            local costAmt = (costObj and tonumber(costObj.m_Number)) or 0
                                            local costType = (costObj and tonumber(costObj.m_ItemType)) or 3
                                            local costKey = (costObj and tonumber(costObj.m_ItemKey)) or 1000
                                            local curKey = (costKey == 1000 and "GEM") or (costKey == 1001 and "GOLD") or (tostring(costType) .. "_" .. tostring(costKey))
                                            table.insert(matchingSlots, {
                                                slotId = tonumber(inf.m_ShopItemId) or i,
                                                qty = qty,
                                                costObj = costObj,
                                                costAmt = costAmt,
                                                costKey = costKey,
                                                curKey = curKey,
                                                canBuyNow = (tonumber(inf.m_MaxCanBuy) or 0) > 0
                                            })
                                        end
                                    end
                                end
                                if #matchingSlots > 0 then break end
                                selMarketUid = select(1, _G.HTPS_GetMarketItemIdentity(lstItems[0]))
                                _G.HTPS_MARKET_SELECTED_UID = selMarketUid
                            end
                        end

                        if #matchingSlots == 0 then
                            stopReason = "Chưa tải được danh sách vật phẩm Chợ Đen!"
                            _G.HTPS_SHOP_AUTO_RESET_RUNNING = false
                            break
                        end

                        local avail = {
                            GEM = tonumber(gc.m_Gem) or 0,
                            GOLD = tonumber(gc.m_Gold) or 0
                        }
                        for _, s in ipairs(matchingSlots) do
                            if avail[s.curKey] == nil then
                                avail[s.curKey] = (s.costObj and tonumber(CS.BonusModel.GetNumberItemInInventory(s.costObj))) or 0
                            end
                        end

                        local req = CS.pbdson.RequestData()
                        req.session = gc.m_Session
                        local sentBuyQtys = {}

                        -- Bước A: Mua hết các ô của vật phẩm này đang còn lượt trên trang hiện tại (không tốn KC Reset)
                        for _, s in ipairs(matchingSlots) do
                            if s.canBuyNow and (avail[s.curKey] or 0) >= s.costAmt then
                                avail[s.curKey] = (avail[s.curKey] or 0) - s.costAmt
                                local cvFirst = CS.pbdson.CommonVector()
                                cvFirst.aLong:Add(1)
                                cvFirst.aLong:Add(s.slotId)
                                cvFirst.aLong:Add(1)
                                local aFirst = CS.pbdson.PbAction()
                                aFirst.actionId = 121
                                aFirst.data = _G.HTPS_SerializeProto(cvFirst)
                                req.actions:Add(aFirst)
                                table.insert(sentBuyQtys, s.qty)
                            end
                        end

                        -- Chi phí cho 1 chu kỳ (Reset 50 KC + Mua ĐỦ tất cả các ô chứa vật phẩm đã chọn)
                        local cycleNeed = { GEM = 50 }
                        for _, s in ipairs(matchingSlots) do
                            cycleNeed[s.curKey] = (cycleNeed[s.curKey] or 0) + s.costAmt
                        end

                        -- Bước B: Gộp tối đa 35 chu kỳ (Reset + Mua toàn bộ các ô khớp vật phẩm) trong 1 gói HTTP
                        local maxCycles = math.max(1, math.floor(70 / math.max(1, #matchingSlots)))
                        for b = 1, maxCycles do
                            local canCycle = true
                            for k, needAmt in pairs(cycleNeed) do
                                if (avail[k] or 0) < needAmt then
                                    canCycle = false
                                    break
                                end
                            end
                            if not canCycle then break end

                            for k, needAmt in pairs(cycleNeed) do
                                avail[k] = (avail[k] or 0) - needAmt
                            end

                            local cv122 = CS.pbdson.CommonVector()
                            cv122.aLong:Add(1)
                            cv122.aLong:Add(0)
                            local a122 = CS.pbdson.PbAction()
                            a122.actionId = 122
                            a122.data = _G.HTPS_SerializeProto(cv122)
                            req.actions:Add(a122)

                            for _, s in ipairs(matchingSlots) do
                                local cv121 = CS.pbdson.CommonVector()
                                cv121.aLong:Add(1)
                                cv121.aLong:Add(s.slotId)
                                cv121.aLong:Add(1)
                                local a121 = CS.pbdson.PbAction()
                                a121.actionId = 121
                                a121.data = _G.HTPS_SerializeProto(cv121)
                                req.actions:Add(a121)
                                table.insert(sentBuyQtys, s.qty)
                            end
                        end

                        if #sentBuyQtys == 0 then
                            if (avail.GEM or 0) < (cycleNeed.GEM or 50) then
                                stopReason = "Không đủ Kim Cương để Reset & Mua tiếp!"
                            elseif (cycleNeed.GOLD or 0) > 0 and (avail.GOLD or 0) < cycleNeed.GOLD then
                                stopReason = "Không đủ Vàng để mua đủ các ô vật phẩm này!"
                            else
                                stopReason = "Không đủ nguyên liệu để mua tiếp!"
                            end
                            _G.HTPS_SHOP_AUTO_RESET_RUNNING = false
                            break
                        end

                        local cv128 = CS.pbdson.CommonVector()
                        cv128.aLong:Add(1)
                        local a128 = CS.pbdson.PbAction()
                        a128.actionId = 128
                        a128.data = _G.HTPS_SerializeProto(cv128)
                        req.actions:Add(a128)

                        local d = _G.HTPS_PutWebRequest(urlServer .. "/i/121/" .. tostring(gc.m_UserId), _G.HTPS_SerializeProto(req), 12)
                        local serverErr = nil
                        local boughtInReq = 0
                        if d then
                            local r = _G.HTPS_DeserializeProto(d, "pbdson.ResponseData,PbMethodLib")
                            if r and r.aAction then
                                local last128 = nil
                                for i = 0, r.aAction.Count - 1 do
                                    local act = r.aAction[i]
                                    if (act.actionId == 121 or act.actionId == 122) and act.data then
                                        local cv = _G.HTPS_DeserializeProto(act.data, "pbdson.CommonVector,PbMethodLib")
                                        if cv and cv.aLong then
                                            CS.BonusModel.ParseBonusReceived(cv.aLong)
                                            if act.actionId == 121 then
                                                boughtInReq = boughtInReq + 1
                                                local qAdd = sentBuyQtys[boughtInReq] or 1
                                                totalBought = totalBought + 1
                                                totalMarketQty = totalMarketQty + qAdd
                                                _G.HTPS_AddShopCounter(1, selMarketUid, marketTargetName, qAdd, 1, 0)
                                            elseif act.actionId == 122 then
                                                totalReset = totalReset + 1
                                                _G.HTPS_AddShopCounter(1, selMarketUid, marketTargetName, 0, 0, 1)
                                            end
                                        end
                                    elseif act.actionId == 128 and act.data then
                                        last128 = act.data
                                    elseif act.actionId == 1 and act.data then
                                        local cv = _G.HTPS_DeserializeProto(act.data, "pbdson.CommonVector,PbMethodLib")
                                        if cv and cv.aString and cv.aString.Count > 0 then
                                            serverErr = tostring(cv.aString[0])
                                        end
                                    end
                                end
                                if last128 then
                                    pcall(function() csNet:ProcessPackageEvent(128, last128) end)
                                end
                            end
                        else
                            serverErr = "Lỗi kết nối máy chủ!"
                        end

                        pcall(function()
                            if ps and not ps:Equals(nil) then
                                ps:ShowPlayerAsset()
                            end
                        end)
                        _G.HTPS_RefreshShopCounterUI(ps)
                        _G.HTPS_UpdateAutoShopButtonStyle(ps)

                        if boughtInReq == 0 and serverErr then
                            stopReason = serverErr
                            _G.HTPS_SHOP_AUTO_RESET_RUNNING = false
                            break
                        end

                        coroutine.yield(nil)

                    -- Chế độ Siêu Tốc riêng cho Shop Huyết Tế (ShopId = 3):
                    -- Chỉ mua Đá nâng đồ (slotId = 3, 500 Đá / 120 Hồn hải tặc), gộp 60 lần Mua+Reset mỗi gói HTTP,
                    -- và tự động mở + huyết tế mảnh phôi trong túi khi thiếu Hồn hải tặc!
                    elseif curShopId == 3 then
                        local haveSoul = tonumber(inv:GetNumberItemConsumable(7)) or 0
                        local newHeroIds = {}
                        local gainedSoul = 0
                        if haveSoul < 7200 and (tonumber(gc.m_PlayerLevel) or 0) >= 70 then
                            local lstShard = inv:GetType():GetField("m_LstItemShard", REF_FLAGS):GetValue(inv)
                            local lstH = inv:GetType():GetField("m_LstHeroModel", REF_FLAGS):GetValue(inv)
                            local freeSlots = math.max(50, 1340 - ((lstH and lstH.Count) or 900))
                            local bestShard = nil
                            local bestPrio = 999
                            if lstShard then
                                for i = 0, lstShard.Count - 1 do
                                    local s = lstShard[i]
                                    if s and s.m_ShardType == 2 and s.m_RequireToMerge and s.m_RequireToMerge > 0 then
                                        local st = tonumber(s.m_Star) or 0
                                        local num = tonumber(s.m_Number) or 0
                                        local copies = math.floor(num / s.m_RequireToMerge)
                                        local k = tonumber(s.m_ItemKey) or 0
                                        local isGeneric = (not s.m_HeroKey) or (tonumber(s.m_HeroKey) <= 0) or (k >= 10000)
                                        if copies >= 10 and ((st == 5 and isGeneric) or (st == 4 and isGeneric) or (st >= 1 and st <= 3)) then
                                            local prio = (st == 5 and 1) or (st == 4 and 2) or (4 - st + 2)
                                            if prio < bestPrio or (prio == bestPrio and bestShard and copies > bestShard.copies) then
                                                bestPrio = prio
                                                bestShard = { shard = s, key = k, star = st, copies = copies }
                                            end
                                        end
                                    end
                                end
                            end
                            if bestShard then
                                local openCnt = math.min(bestShard.copies, freeSlots, 280)
                                if openCnt > 0 then
                                    local req254 = CS.pbdson.RequestData()
                                    req254.session = gc.m_Session
                                    local cv254 = CS.pbdson.CommonVector()
                                    cv254.aLong:Add(2)
                                    cv254.aLong:Add(bestShard.key)
                                    cv254.aLong:Add(openCnt)
                                    local a254 = CS.pbdson.PbAction()
                                    a254.actionId = 254
                                    a254.data = _G.HTPS_SerializeProto(cv254)
                                    req254.actions:Add(a254)
                                    local d254 = _G.HTPS_PutWebRequest(urlServer .. "/i/254/" .. tostring(gc.m_UserId), _G.HTPS_SerializeProto(req254), 10)
                                    if d254 then
                                        local r254 = _G.HTPS_DeserializeProto(d254, "pbdson.ResponseData,PbMethodLib")
                                        if r254 and r254.aAction and r254.aAction.Count > 0 then
                                            local act = r254.aAction[0]
                                            if act.actionId == 254 and act.data then
                                                local cvRes = _G.HTPS_DeserializeProto(act.data, "pbdson.CommonVector,PbMethodLib")
                                                if cvRes and cvRes.aLong and cvRes.aLong.Count >= 5 then
                                                    bestShard.shard.m_Number = tonumber(cvRes.aLong[3]) or bestShard.shard.m_Number
                                                    local j = 5
                                                    while j <= cvRes.aLong.Count - 3 do
                                                        if tonumber(cvRes.aLong[j]) == 5 then
                                                            table.insert(newHeroIds, cvRes.aLong[j + 1])
                                                            j = j + 3
                                                        else
                                                            j = j + 1
                                                        end
                                                    end
                                                    local soulPerHero = (bestShard.star == 5 and 25) or (bestShard.star == 4 and 10) or (bestShard.star == 3 and 5) or 2
                                                    gainedSoul = #newHeroIds * soulPerHero
                                                end
                                            end
                                        end
                                    end
                                end
                            end
                        end

                        local availSoul = haveSoul + gainedSoul
                        local availGem = tonumber(gc.m_Gem) or 0
                        local batchPairs = math.min(60, math.floor(availSoul / 120), math.floor(availGem / 30))
                        if batchPairs <= 0 and #newHeroIds == 0 then
                            stopReason = (availGem < 30) and "Không đủ Kim Cương để Reset Shop!" or "Không đủ Hồn hải tặc / Mảnh phôi để đổi thêm!"
                            _G.HTPS_SHOP_AUTO_RESET_RUNNING = false
                            break
                        end

                        local req = CS.pbdson.RequestData()
                        req.session = gc.m_Session
                        if #newHeroIds > 0 then
                            local cv209 = CS.pbdson.CommonVector()
                            for _, hid in ipairs(newHeroIds) do cv209.aLong:Add(hid) end
                            local a209 = CS.pbdson.PbAction()
                            a209.actionId = 209
                            a209.data = _G.HTPS_SerializeProto(cv209)
                            req.actions:Add(a209)
                        end
                        for b = 1, batchPairs do
                            local cv122 = CS.pbdson.CommonVector()
                            cv122.aLong:Add(3)
                            cv122.aLong:Add(0)
                            local a122 = CS.pbdson.PbAction()
                            a122.actionId = 122
                            a122.data = _G.HTPS_SerializeProto(cv122)
                            req.actions:Add(a122)

                            local cv121 = CS.pbdson.CommonVector()
                            cv121.aLong:Add(3)
                            cv121.aLong:Add(3)
                            cv121.aLong:Add(1)
                            local a121 = CS.pbdson.PbAction()
                            a121.actionId = 121
                            a121.data = _G.HTPS_SerializeProto(cv121)
                            req.actions:Add(a121)
                        end
                        local cv128 = CS.pbdson.CommonVector()
                        cv128.aLong:Add(3)
                        local a128 = CS.pbdson.PbAction()
                        a128.actionId = 128
                        a128.data = _G.HTPS_SerializeProto(cv128)
                        req.actions:Add(a128)

                        local mainAct = (#newHeroIds > 0) and 209 or 121
                        local d = _G.HTPS_PutWebRequest(urlServer .. "/i/" .. tostring(mainAct) .. "/" .. tostring(gc.m_UserId), _G.HTPS_SerializeProto(req), 12)
                        local serverErr = nil
                        if d then
                            local r = _G.HTPS_DeserializeProto(d, "pbdson.ResponseData,PbMethodLib")
                            if r and r.aAction then
                                for i = 0, r.aAction.Count - 1 do
                                    local act = r.aAction[i]
                                    if (act.actionId == 209 or act.actionId == 121 or act.actionId == 122) and act.data then
                                        local cv = _G.HTPS_DeserializeProto(act.data, "pbdson.CommonVector,PbMethodLib")
                                        if cv and cv.aLong then
                                            CS.BonusModel.ParseBonusReceived(cv.aLong)
                                            if act.actionId == 121 then
                                                totalBought = totalBought + 1
                                                _G.HTPS_AddShopCounter(3, nil, "Đá nâng đồ", 500, 1, 0)
                                            end
                                            if act.actionId == 122 then
                                                totalReset = totalReset + 1
                                                _G.HTPS_AddShopCounter(3, nil, "Đá nâng đồ", 0, 0, 1)
                                            end
                                        end
                                    elseif act.actionId == 128 and act.data then
                                        pcall(function() csNet:ProcessPackageEvent(128, act.data) end)
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

                        pcall(function()
                            if ps and not ps:Equals(nil) then
                                ps:ShowPlayerAsset()
                            end
                        end)
                        _G.HTPS_RefreshShopCounterUI(ps)
                        _G.HTPS_UpdateAutoShopButtonStyle(ps)

                        if serverErr then
                            stopReason = serverErr
                            _G.HTPS_SHOP_AUTO_RESET_RUNNING = false
                            break
                        end

                        coroutine.yield(nil)
                    else

                    local lstItems = ps:GetType():GetField("m_LstShopItemData", REF_FLAGS):GetValue(ps)
                    local cands = {}
                    local minCostOnPage = nil
                    if lstItems then
                        for i = 0, lstItems.Count - 1 do
                            local info = lstItems[i]
                            if info and (tonumber(info.m_MaxCanBuy) or 0) > 0 then
                                local costObj = info.m_ItemConsumeCost
                                local costAmt = (costObj and tonumber(costObj.m_Number)) or 0
                                local cType = (costObj and tonumber(costObj.m_ItemType)) or 0
                                local cKey = (costObj and tonumber(costObj.m_ItemKey)) or 0
                                if not minCostOnPage or costAmt < minCostOnPage then
                                    minCostOnPage = costAmt
                                end
                                table.insert(cands, {
                                    slotId = tonumber(info.m_ShopItemId) or i,
                                    costObj = costObj,
                                    costAmt = costAmt,
                                    cKey = cKey,
                                    curKey = tostring(cType) .. "_" .. tostring(cKey),
                                    order = i
                                })
                            end
                        end
                    end

                    -- Ưu tiên mua từ món rẻ đến đắt để vét sạch nguyên liệu ở trang cuối cùng
                    table.sort(cands, function(a, b)
                        if a.costAmt ~= b.costAmt then return a.costAmt < b.costAmt end
                        return a.order < b.order
                    end)

                    local spentByCur = {}
                    local kcSpentOnPage = 0
                    local toBuySlots = {}
                    local skippedUnaffordable = 0
                    for _, c in ipairs(cands) do
                        local haveNow = ((c.costObj and tonumber(CS.BonusModel.GetNumberItemInInventory(c.costObj))) or 0) - (spentByCur[c.curKey] or 0)
                        if haveNow >= c.costAmt then
                            table.insert(toBuySlots, c.slotId)
                            spentByCur[c.curKey] = (spentByCur[c.curKey] or 0) + c.costAmt
                            if c.cKey == 1000 then
                                kcSpentOnPage = kcSpentOnPage + c.costAmt
                            end
                        else
                            skippedUnaffordable = skippedUnaffordable + 1
                        end
                    end
                    table.sort(toBuySlots)

                    -- Nếu có món trên trang nhưng không đủ nguyên liệu mua bất kỳ món nào -> dừng ngay
                    if #toBuySlots == 0 and skippedUnaffordable > 0 then
                        stopReason = "Không đủ nguyên liệu để mua thêm!"
                        _G.HTPS_SHOP_AUTO_RESET_RUNNING = false
                        break
                    end

                    -- Kiểm tra có đủ điều kiện Reset sang trang mới sau khi mua xong trang này không
                    local fFree = ps:GetType():GetField("m_IsFreeToRefresh", REF_FLAGS)
                    local isFree = (fFree and fFree:GetValue(ps) == true) or false
                    local txtCostRef = ps:GetType():GetField("m_TextCostRefresh", REF_FLAGS):GetValue(ps)
                    local refreshCost = isFree and 0 or ((curShopId == 1) and 50 or (tonumber(txtCostRef and txtCostRef.text) or 50))
                    local remGemAfterPage = (tonumber(gc.m_Gem) or 0) - kcSpentOnPage
                    local canAffordRefresh = isFree or (remGemAfterPage >= refreshCost)

                    -- Nếu đã cạn nguyên liệu ngay trên trang này (skippedUnaffordable > 0), chỉ mua nốt các món đủ tiền và KHÔNG tốn KC Reset thêm
                    local doRefresh = canAffordRefresh and (skippedUnaffordable == 0)
                    if curShopId == 2 then
                        local remLuck = (inv:GetNumberItemConsumable(22) or 0) - (spentByCur["3_22"] or 0)
                        if remLuck < 500 then
                            doRefresh = false
                        end
                    end

                    if #toBuySlots == 0 and not doRefresh then
                        stopReason = (not canAffordRefresh) and "Không đủ Kim Cương để Reset Shop!" or "Không đủ nguyên liệu để mua thêm!"
                        _G.HTPS_SHOP_AUTO_RESET_RUNNING = false
                        break
                    end

                    local req = CS.pbdson.RequestData()
                    req.session = gc.m_Session
                    for _, slotId in ipairs(toBuySlots) do
                        local cv121 = CS.pbdson.CommonVector()
                        cv121.aLong:Add(curShopId)
                        cv121.aLong:Add(slotId)
                        cv121.aLong:Add(1)
                        local a121 = CS.pbdson.PbAction()
                        a121.actionId = 121
                        a121.data = _G.HTPS_SerializeProto(cv121)
                        req.actions:Add(a121)
                    end

                    if doRefresh then
                        local cv122 = CS.pbdson.CommonVector()
                        cv122.aLong:Add(curShopId)
                        cv122.aLong:Add(isFree and 1 or 0)
                        local a122 = CS.pbdson.PbAction()
                        a122.actionId = 122
                        a122.data = _G.HTPS_SerializeProto(cv122)
                        req.actions:Add(a122)
                    end

                    local cv128 = CS.pbdson.CommonVector()
                    cv128.aLong:Add(curShopId)
                    local a128 = CS.pbdson.PbAction()
                    a128.actionId = 128
                    a128.data = _G.HTPS_SerializeProto(cv128)
                    req.actions:Add(a128)

                    local mainActId = (#toBuySlots > 0) and 121 or 122
                    local d = _G.HTPS_PutWebRequest(urlServer .. "/i/" .. tostring(mainActId) .. "/" .. tostring(gc.m_UserId), _G.HTPS_SerializeProto(req), 8)
                    local boughtInStep = 0
                    local serverErr = nil
                    if d then
                        local r = _G.HTPS_DeserializeProto(d, "pbdson.ResponseData,PbMethodLib")
                        if r and r.aAction then
                            for i = 0, r.aAction.Count - 1 do
                                local act = r.aAction[i]
                                if act.actionId == 121 and act.data then
                                    local cv = _G.HTPS_DeserializeProto(act.data, "pbdson.CommonVector,PbMethodLib")
                                    if cv and cv.aLong then
                                        CS.BonusModel.ParseBonusReceived(cv.aLong)
                                        boughtInStep = boughtInStep + 1
                                        totalBought = totalBought + 1
                                        _G.HTPS_AddShopCounter(curShopId, (curShopId == 1) and "__ALL__" or nil, "Tất cả món", 1, 1, 0)
                                    end
                                elseif act.actionId == 122 and act.data then
                                    local cv = _G.HTPS_DeserializeProto(act.data, "pbdson.CommonVector,PbMethodLib")
                                    if cv and cv.aLong then
                                        CS.BonusModel.ParseBonusReceived(cv.aLong)
                                        totalReset = totalReset + 1
                                        _G.HTPS_AddShopCounter(curShopId, (curShopId == 1) and "__ALL__" or nil, "Tất cả món", 0, 0, 1)
                                    end
                                elseif act.actionId == 128 and act.data then
                                    pcall(function() csNet:ProcessPackageEvent(128, act.data) end)
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

                    pcall(function()
                        if ps and not ps:Equals(nil) then
                            ps:ShowPlayerAsset()
                        end
                    end)
                    _G.HTPS_RefreshShopCounterUI(ps)
                    _G.HTPS_UpdateAutoShopButtonStyle(ps)

                    if serverErr then
                        stopReason = serverErr
                        _G.HTPS_SHOP_AUTO_RESET_RUNNING = false
                        break
                    end

                    if not doRefresh then
                        stopReason = (not canAffordRefresh) and "Đã hết Kim Cương để Reset thêm!" or "Đã mua hết nguyên liệu hiện có!"
                        _G.HTPS_SHOP_AUTO_RESET_RUNNING = false
                        break
                    end

                    coroutine.yield(nil)
                    end
                end
            end)

            _G.HTPS_SHOP_AUTO_RESET_RUNNING = false
            _G.HTPS_KillSummonPopups()
            local psEnd = _G.HTPS_FindObjectOfType(typeof(CS.PopupShop))
            _G.HTPS_UpdateAutoShopButtonStyle(psEnd)
            _G.HTPS_RefreshShopCounterUI(psEnd)
            if not okLoop then
                CS.Toast.ShowToast("⚠️ Lỗi Auto Shop: " .. tostring(errLoop))
            else
                local extra = (stopReason ~= "") and (" - " .. stopReason) or ""
                if curShopId == 1 and tostring(_G.HTPS_MARKET_SELECTED_UID or "") ~= "__ALL__" then
                    CS.Toast.ShowToast(string.format("⏹ Đã dừng Auto Chợ Đen: +%s %s (%d ô, Reset %d lần)%s",
                        _G.HTPS_FormatExactInt(totalMarketQty), marketTargetName, totalBought, totalReset, extra))
                elseif curShopId == 3 then
                    CS.Toast.ShowToast(string.format("💎 Shop Huyết Tế: Đã nhận +%s Đá nâng đồ (%d lần mua)%s", _G.HTPS_FormatExactInt(totalBought * 500), totalBought, extra))
                else
                    CS.Toast.ShowToast(string.format("🛒 Auto Shop: Đã mua %d món (Reset %d lần)%s", totalBought, totalReset, extra))
                end
            end
        end)
    end

    _G.HTPS_AutoBuyLuckyShopOnce = function(showToast)
        _G.HTPS_ToggleAutoShopBuyAndReset()
    end

    _G.HTPS_EnsurePopupShopAutoButtons = function()
        pcall(function()
            local ps = _G.HTPS_FindObjectOfType(typeof(CS.PopupShop))
            if not ps or ps:Equals(nil) or not ps.gameObject.activeInHierarchy then
                if _G.HTPS_SHOP_AUTO_RESET_RUNNING then
                    _G.HTPS_SHOP_AUTO_RESET_RUNNING = false
                end
                return
            end
            local REF_FLAGS = 60
            local btnRef = ps:GetType():GetField("m_ButtonRefresh", REF_FLAGS):GetValue(ps)
            if not btnRef or not btnRef.transform.parent then return end
            local parentTf = btnRef.transform.parent
            local curShopId = tonumber(ps:GetType():GetField("m_ShopId", REF_FLAGS):GetValue(ps)) or 2

            local refTxtComp = btnRef:GetComponentInChildren(typeof(UG.UI.Text), true)
            local gameFont = (refTxtComp and refTxtComp.font) or UG.Resources.GetBuiltinResource(typeof(UG.Font), "Arial.ttf")

            -- Lấy trực tiếp các Sprite khung nút gốc của game trên PopupShop (kèm fallback FindNativeSprite)
            local refBtnImg = btnRef:GetComponent(typeof(UG.UI.Image))
            local spBtnGreen = (refBtnImg and refBtnImg.sprite and not refBtnImg.sprite:Equals(nil)) and refBtnImg.sprite or _G.HTPS_FindNativeSprite("button_green", true)
            local spBtnYellow = _G.HTPS_FindNativeSprite("button_yellow", true) or spBtnGreen
            local spBoxField = _G.HTPS_FindNativeSprite("box_field_1", true) or _G.HTPS_FindNativeSprite("box_text_1", true)
            local spBoxText = _G.HTPS_FindNativeSprite("box_text_1", true) or spBoxField

            local bgrTf = parentTf:Find("bgr")
            local bgrImg = bgrTf and bgrTf:GetComponent(typeof(UG.UI.Image)) or nil
            local spPopupScroll = (bgrImg and bgrImg.sprite and not bgrImg.sprite:Equals(nil)) and bgrImg.sprite or _G.HTPS_FindNativeSprite("popup_notitle_2", true)

            local icTf = parentTf:Find("ItemContainer")
            local icImg = icTf and icTf:GetComponent(typeof(UG.UI.Image)) or nil
            local spInnerShelf = (icImg and icImg.sprite and not icImg.sprite:Equals(nil)) and icImg.sprite or _G.HTPS_FindNativeSprite("round_rect_5", true)

            local refGemTf = btnRef.transform:Find("IconCost")
            local refGemImg = refGemTf and refGemTf:GetComponent(typeof(UG.UI.Image)) or nil
            local spIconGem = (refGemImg and refGemImg.sprite and not refGemImg.sprite:Equals(nil)) and refGemImg.sprite or _G.HTPS_FindNativeSprite("icon_gem", false)
            local spTickGreen = _G.HTPS_FindNativeSprite("tick_green", false)

            -- Xóa triệt để nút cũ từng clone từ ButtonRefresh & nâng cấp các khung cũ chưa dùng SkinV2 gốc
            for _, oldName in ipairs({"BtnHTPSAutoShopBuyReset"}) do
                local oldTf = parentTf:Find(oldName)
                if oldTf then UG.Object.DestroyImmediate(oldTf.gameObject) end
            end
            for _, upgName in ipairs({"PanelHTPSMarketCounter", "BtnHTPSAutoShopNew", "BtnHTPSMarketRefreshOnce", "BtnHTPSMarketDropdown", "BlockerHTPSMarketDrop"}) do
                local exTf = parentTf:Find(upgName)
                if exTf and not exTf:Find("SkinV3") then
                    UG.Object.DestroyImmediate(exTf.gameObject)
                end
            end

            local function addSkinMarker(go)
                local mk = GO("SkinV3")
                mk.transform:SetParent(go.transform, false)
                mk:SetActive(false)
            end

            local showAutoControls = (curShopId == 1) or btnRef.activeSelf or (_G.HTPS_SHOP_AUTO_RESET_RUNNING == true)

            -- 1. Bảng Bộ Đếm Trực Tiếp (PanelHTPSMarketCounter) - Khung gỗ sẫm viền vàng gốc (round_rect_5 + box_field_1)
            local cntPanelTf = parentTf:Find("PanelHTPSMarketCounter")
            if not cntPanelTf then
                local cntGo = GO("PanelHTPSMarketCounter")
                cntGo.transform:SetParent(parentTf, false)
                addSkinMarker(cntGo)
                local crt = cntGo:AddComponent(typeof(UG.RectTransform))
                crt.anchorMin = UG.Vector2(1.0, 0.5)
                crt.anchorMax = UG.Vector2(1.0, 0.5)
                crt.pivot = UG.Vector2(0.5, 0.5)
                crt.anchoredPosition = UG.Vector2(-952.0, -114.0)
                crt.sizeDelta = UG.Vector2(260.0, 56.0)

                local cimg = cntGo:AddComponent(typeof(UG.UI.Image))
                if spInnerShelf then
                    cimg.sprite = spInnerShelf
                    cimg.type = UG.UI.Image.Type.Sliced
                    cimg.color = UG.Color(0.34, 0.23, 0.14, 0.94)
                else
                    cimg.color = UG.Color(0.18, 0.12, 0.07, 0.94)
                end

                if spBoxField then
                    local frmGo = GO("FrameGold")
                    frmGo.transform:SetParent(cntGo.transform, false)
                    local frt = frmGo:AddComponent(typeof(UG.RectTransform))
                    frt.anchorMin = UG.Vector2(0, 0)
                    frt.anchorMax = UG.Vector2(1, 1)
                    frt.offsetMin = UG.Vector2(0, 0)
                    frt.offsetMax = UG.Vector2(0, 0)
                    local fimg = frmGo:AddComponent(typeof(UG.UI.Image))
                    fimg.sprite = spBoxField
                    fimg.type = UG.UI.Image.Type.Sliced
                    fimg.color = UG.Color(1.0, 1.0, 1.0, 1.0)
                    fimg.raycastTarget = false
                end

                local cbtn = cntGo:AddComponent(typeof(UG.UI.Button))
                cbtn.targetGraphic = cimg

                local l1Go = GO("TxtLine1")
                l1Go.transform:SetParent(cntGo.transform, false)
                local r1 = l1Go:AddComponent(typeof(UG.RectTransform))
                r1.anchorMin = UG.Vector2(0, 0.46)
                r1.anchorMax = UG.Vector2(1, 1)
                r1.offsetMin = UG.Vector2(12, 0)
                r1.offsetMax = UG.Vector2(-12, -4)
                local t1 = l1Go:AddComponent(typeof(UG.UI.Text))
                t1.font = gameFont
                t1.fontSize = 15
                t1.fontStyle = UG.FontStyle.Normal
                t1.alignment = UG.TextAnchor.MiddleCenter
                t1.resizeTextForBestFit = true
                t1.resizeTextMinSize = 10
                t1.resizeTextMaxSize = 15
                t1.color = UG.Color(1.0, 0.90, 0.42, 1.0)
                t1.text = "+0 Vật phẩm"
                local o1 = l1Go:AddComponent(typeof(UG.UI.Outline))
                o1.effectColor = UG.Color(0.18, 0.10, 0.05, 1.0)
                o1.effectDistance = UG.Vector2(1.0, -1.0)

                local l2Go = GO("TxtLine2")
                l2Go.transform:SetParent(cntGo.transform, false)
                local r2 = l2Go:AddComponent(typeof(UG.RectTransform))
                r2.anchorMin = UG.Vector2(0, 0)
                r2.anchorMax = UG.Vector2(1, 0.48)
                r2.offsetMin = UG.Vector2(12, 4)
                r2.offsetMax = UG.Vector2(-12, 0)
                local t2 = l2Go:AddComponent(typeof(UG.UI.Text))
                t2.font = gameFont
                t2.fontSize = 12
                t2.fontStyle = UG.FontStyle.Normal
                t2.alignment = UG.TextAnchor.MiddleCenter
                t2.resizeTextForBestFit = true
                t2.resizeTextMinSize = 9
                t2.resizeTextMaxSize = 12
                t2.color = UG.Color(0.93, 0.89, 0.80, 1.0)
                t2.text = "Làm mới: 0 | 0 ô (Chạm xóa)"
                local o2 = l2Go:AddComponent(typeof(UG.UI.Outline))
                o2.effectColor = UG.Color(0.18, 0.10, 0.05, 1.0)
                o2.effectDistance = UG.Vector2(1.0, -1.0)

                cntPanelTf = cntGo.transform
            end

            if cntPanelTf then
                if cntPanelTf.gameObject.activeSelf ~= showAutoControls then
                    cntPanelTf.gameObject:SetActive(showAutoControls)
                end
                local crt = cntPanelTf:GetComponent(typeof(UG.RectTransform))
                if crt then
                    if curShopId == 1 then
                        crt.anchoredPosition = UG.Vector2(-952.0, -114.0)
                        crt.sizeDelta = UG.Vector2(260.0, 56.0)
                    else
                        crt.anchoredPosition = UG.Vector2(-953.9, -90.0)
                        crt.sizeDelta = UG.Vector2(240.0, 54.0)
                    end
                end
                if _G.HTPS_BOUND_SHOP_COUNTER_BTN ~= cntPanelTf then
                    local cbtn = cntPanelTf:GetComponent(typeof(UG.UI.Button))
                    if cbtn then
                        cbtn.onClick:RemoveAllListeners()
                        cbtn.onClick:AddListener(function()
                            local psNow = _G.HTPS_FindObjectOfType(typeof(CS.PopupShop))
                            local sidNow = (psNow and not psNow:Equals(nil)) and (tonumber(psNow:GetType():GetField("m_ShopId", 60):GetValue(psNow)) or 1) or 1
                            local key = _G.HTPS_GetShopCounterKey(sidNow, _G.HTPS_MARKET_SELECTED_UID)
                            _G.HTPS_SHOP_COUNTER_DATA[key] = { qty = 0, buys = 0, resets = 0 }
                            _G.HTPS_RefreshShopCounterUI(psNow)
                            if CS.Toast then CS.Toast.ShowToast("Đã đặt lại bộ đếm về 0!") end
                        end)
                    end
                    _G.HTPS_BOUND_SHOP_COUNTER_BTN = cntPanelTf
                end
            end

            -- 2. Nút Auto Mua / Dừng ĐỘC LẬP 100% (BtnHTPSAutoShopNew) - Khung nút vàng 3D gốc (button_yellow)
            local btnAutoTf = parentTf:Find("BtnHTPSAutoShopNew")
            if not btnAutoTf then
                local autoGo = GO("BtnHTPSAutoShopNew")
                autoGo.transform:SetParent(parentTf, false)
                addSkinMarker(autoGo)
                local art = autoGo:AddComponent(typeof(UG.RectTransform))
                art.anchorMin = UG.Vector2(1.0, 0.5)
                art.anchorMax = UG.Vector2(1.0, 0.5)
                art.pivot = UG.Vector2(0.5, 0.5)
                art.anchoredPosition = UG.Vector2(-952.0, -176.0)
                art.sizeDelta = UG.Vector2(252.0, 58.0)

                local aimg = autoGo:AddComponent(typeof(UG.UI.Image))
                if spBtnYellow then
                    aimg.sprite = spBtnYellow
                    aimg.type = UG.UI.Image.Type.Sliced
                    aimg.color = UG.Color(1.0, 1.0, 1.0, 1.0)
                else
                    aimg.color = UG.Color(0.88, 0.68, 0.18, 0.98)
                end

                local abc = autoGo:AddComponent(typeof(UG.UI.Button))
                abc.targetGraphic = aimg

                local atxtGo = GO("Label")
                atxtGo.transform:SetParent(autoGo.transform, false)
                local atrt = atxtGo:AddComponent(typeof(UG.RectTransform))
                atrt.anchorMin = UG.Vector2(0, 0)
                atrt.anchorMax = UG.Vector2(1, 1)
                atrt.offsetMin = UG.Vector2(14, 6)
                atrt.offsetMax = UG.Vector2(-14, -3)
                local atxt = atxtGo:AddComponent(typeof(UG.UI.Text))
                atxt.font = gameFont
                atxt.fontSize = 20
                atxt.fontStyle = UG.FontStyle.Normal
                atxt.alignment = UG.TextAnchor.MiddleCenter
                atxt.resizeTextForBestFit = true
                atxt.resizeTextMinSize = 13
                atxt.resizeTextMaxSize = 20
                atxt.color = UG.Color(0.510, 0.318, 0.165, 1.0)
                atxt.text = "Auto Mua Chợ Đen"

                local aout = atxtGo:AddComponent(typeof(UG.UI.Outline))
                aout.effectColor = UG.Color(0.32, 0.06, 0.05, 1.0)
                aout.effectDistance = UG.Vector2(1.2, -1.2)
                aout.enabled = false

                _G.HTPS_BTN_SHOP_AUTO_RESET_TXT = atxt
                btnAutoTf = autoGo.transform
            end

            if btnAutoTf then
                _G.HTPS_BTN_SHOP_AUTO_NEW_TF = btnAutoTf
                if btnAutoTf.gameObject.activeSelf ~= showAutoControls then
                    btnAutoTf.gameObject:SetActive(showAutoControls)
                end
                local rtAuto = btnAutoTf:GetComponent(typeof(UG.RectTransform))
                if rtAuto then
                    if curShopId == 1 then
                        rtAuto.anchoredPosition = UG.Vector2(-952.0, -176.0)
                        rtAuto.sizeDelta = UG.Vector2(252.0, 58.0)
                    else
                        rtAuto.anchoredPosition = UG.Vector2(-953.9, -152.0)
                        rtAuto.sizeDelta = UG.Vector2(240.0, 58.0)
                    end
                end
                local atxt = btnAutoTf:Find("Label") and btnAutoTf:Find("Label"):GetComponent(typeof(UG.UI.Text)) or nil
                if atxt then _G.HTPS_BTN_SHOP_AUTO_RESET_TXT = atxt end
                _G.HTPS_UpdateAutoShopButtonStyle(ps)

                if _G.HTPS_BOUND_SHOP_AUTO_RESET_BTN ~= btnAutoTf then
                    local bc = btnAutoTf:GetComponent(typeof(UG.UI.Button))
                    if bc then
                        bc.onClick:RemoveAllListeners()
                        bc.onClick:AddListener(function()
                            _G.HTPS_ToggleAutoShopBuyAndReset()
                        end)
                    end
                    _G.HTPS_BOUND_SHOP_AUTO_RESET_BTN = btnAutoTf
                end
            end

            -- 3. Nút Làm Mới 1 Lần RIÊNG cho Chợ Đen (BtnHTPSMarketRefreshOnce - chuẩn khung xanh + icon KC gốc) & Dropdown
            local btnManualRefTf = parentTf:Find("BtnHTPSMarketRefreshOnce")
            local btnDropTf = parentTf:Find("BtnHTPSMarketDropdown")
            local blkDropTf = parentTf:Find("BlockerHTPSMarketDrop")

            if curShopId ~= 1 then
                if btnManualRefTf and btnManualRefTf.gameObject.activeSelf then btnManualRefTf.gameObject:SetActive(false) end
                if btnDropTf and btnDropTf.gameObject.activeSelf then btnDropTf.gameObject:SetActive(false) end
                if blkDropTf and blkDropTf.gameObject.activeSelf then blkDropTf.gameObject:SetActive(false) end
                _G.HTPS_RefreshShopCounterUI(ps)
                return
            end

            if not btnManualRefTf then
                local mGo = GO("BtnHTPSMarketRefreshOnce")
                mGo.transform:SetParent(parentTf, false)
                addSkinMarker(mGo)
                local mrt = mGo:AddComponent(typeof(UG.RectTransform))
                mrt.anchorMin = UG.Vector2(1.0, 0.5)
                mrt.anchorMax = UG.Vector2(1.0, 0.5)
                mrt.pivot = UG.Vector2(0.5, 0.5)
                mrt.anchoredPosition = UG.Vector2(-952.0, -238.0)
                mrt.sizeDelta = UG.Vector2(252.0, 58.0)

                local mimg = mGo:AddComponent(typeof(UG.UI.Image))
                if spBtnGreen then
                    mimg.sprite = spBtnGreen
                    mimg.type = UG.UI.Image.Type.Sliced
                    mimg.color = UG.Color(1.0, 1.0, 1.0, 1.0)
                else
                    mimg.color = UG.Color(0.18, 0.62, 0.28, 0.98)
                end

                local mbc = mGo:AddComponent(typeof(UG.UI.Button))
                mbc.targetGraphic = mimg

                if spIconGem then
                    local icGo = GO("IconCost")
                    icGo.transform:SetParent(mGo.transform, false)
                    local icRt = icGo:AddComponent(typeof(UG.RectTransform))
                    icRt.anchorMin = UG.Vector2(0.5, 0.5)
                    icRt.anchorMax = UG.Vector2(0.5, 0.5)
                    icRt.pivot = UG.Vector2(0.5, 0.5)
                    icRt.anchoredPosition = UG.Vector2(-74.0, 2.0)
                    icRt.sizeDelta = UG.Vector2(42.0, 42.0)
                    local icIm = icGo:AddComponent(typeof(UG.UI.Image))
                    icIm.sprite = spIconGem
                    icIm.type = UG.UI.Image.Type.Simple
                    icIm.color = UG.Color(1.0, 1.0, 1.0, 1.0)

                    local tcGo = GO("TextCost")
                    tcGo.transform:SetParent(icGo.transform, false)
                    local tcRt = tcGo:AddComponent(typeof(UG.RectTransform))
                    tcRt.anchorMin = UG.Vector2(0.5, 0.5)
                    tcRt.anchorMax = UG.Vector2(0.5, 0.5)
                    tcRt.pivot = UG.Vector2(0.5, 0.5)
                    tcRt.anchoredPosition = UG.Vector2(1.0, -8.0)
                    tcRt.sizeDelta = UG.Vector2(70.0, 28.0)
                    local tcTxt = tcGo:AddComponent(typeof(UG.UI.Text))
                    tcTxt.font = gameFont
                    tcTxt.fontSize = 19
                    tcTxt.fontStyle = UG.FontStyle.Normal
                    tcTxt.alignment = UG.TextAnchor.MiddleCenter
                    tcTxt.color = UG.Color(1.0, 1.0, 1.0, 1.0)
                    tcTxt.text = "50"
                    local tcOut = tcGo:AddComponent(typeof(UG.UI.Outline))
                    tcOut.effectColor = UG.Color(0.0, 0.0, 0.0, 1.0)
                    tcOut.effectDistance = UG.Vector2(1.1, -1.1)
                end

                local mlblGo = GO("Label")
                mlblGo.transform:SetParent(mGo.transform, false)
                local mlrt = mlblGo:AddComponent(typeof(UG.RectTransform))
                mlrt.anchorMin = UG.Vector2(0, 0)
                mlrt.anchorMax = UG.Vector2(1, 1)
                mlrt.offsetMin = UG.Vector2(spIconGem and 64 or 14, 6)
                mlrt.offsetMax = UG.Vector2(-14, -3)
                local mtxt = mlblGo:AddComponent(typeof(UG.UI.Text))
                mtxt.font = gameFont
                mtxt.fontSize = 22
                mtxt.fontStyle = UG.FontStyle.Normal
                mtxt.alignment = UG.TextAnchor.MiddleCenter
                mtxt.resizeTextForBestFit = true
                mtxt.resizeTextMinSize = 14
                mtxt.resizeTextMaxSize = 23
                mtxt.color = spBtnGreen and UG.Color(0.122, 0.408, 0.157, 1.0) or UG.Color(0.95, 0.98, 1.0, 1.0)
                mtxt.text = spIconGem and "Làm mới" or "Làm mới (50 KC)"

                btnManualRefTf = mGo.transform
            end

            if btnManualRefTf then
                if not btnManualRefTf.gameObject.activeSelf then
                    btnManualRefTf.gameObject:SetActive(true)
                end
                if _G.HTPS_BOUND_MARKET_MANUAL_REF_BTN ~= btnManualRefTf then
                    local mbc = btnManualRefTf:GetComponent(typeof(UG.UI.Button))
                    if mbc then
                        mbc.onClick:RemoveAllListeners()
                        mbc.onClick:AddListener(function()
                            _G.HTPS_ManualRefreshMarketOnce()
                        end)
                    end
                    _G.HTPS_BOUND_MARKET_MANUAL_REF_BTN = btnManualRefTf
                end
            end

            -- 4. Khung chọn vật phẩm (BtnHTPSMarketDropdown) - Khung thanh chọn gốc (box_text_1)
            if not btnDropTf then
                local dropGo = GO("BtnHTPSMarketDropdown")
                dropGo.transform:SetParent(parentTf, false)
                addSkinMarker(dropGo)
                local rt = dropGo:AddComponent(typeof(UG.RectTransform))
                rt.anchorMin = UG.Vector2(1.0, 0.5)
                rt.anchorMax = UG.Vector2(1.0, 0.5)
                rt.pivot = UG.Vector2(0.5, 0.5)
                rt.anchoredPosition = UG.Vector2(-952.0, -56.0)
                rt.sizeDelta = UG.Vector2(260.0, 50.0)

                local img = dropGo:AddComponent(typeof(UG.UI.Image))
                if spBoxText then
                    img.sprite = spBoxText
                    img.type = UG.UI.Image.Type.Sliced
                    img.color = UG.Color(1.0, 1.0, 1.0, 1.0)
                else
                    img.color = UG.Color(0.22, 0.15, 0.09, 0.96)
                end

                local bc = dropGo:AddComponent(typeof(UG.UI.Button))
                bc.targetGraphic = img

                local lblGo = GO("Label")
                lblGo.transform:SetParent(dropGo.transform, false)
                local lrt = lblGo:AddComponent(typeof(UG.RectTransform))
                lrt.anchorMin = UG.Vector2(0, 0)
                lrt.anchorMax = UG.Vector2(1, 1)
                lrt.offsetMin = UG.Vector2(16, 4)
                lrt.offsetMax = UG.Vector2(-32, -4)
                local ltxt = lblGo:AddComponent(typeof(UG.UI.Text))
                ltxt.font = gameFont
                ltxt.fontSize = 15
                ltxt.fontStyle = UG.FontStyle.Normal
                ltxt.alignment = UG.TextAnchor.MiddleCenter
                ltxt.resizeTextForBestFit = true
                ltxt.resizeTextMinSize = 11
                ltxt.resizeTextMaxSize = 16
                ltxt.color = UG.Color(0.98, 0.92, 0.74, 1.0)
                ltxt.text = "Chọn vật phẩm..."
                local lout = lblGo:AddComponent(typeof(UG.UI.Outline))
                lout.effectColor = UG.Color(0.20, 0.14, 0.10, 1.0)
                lout.effectDistance = UG.Vector2(1.0, -1.0)

                local arrGo = GO("Arrow")
                arrGo.transform:SetParent(dropGo.transform, false)
                local arrRt = arrGo:AddComponent(typeof(UG.RectTransform))
                arrRt.anchorMin = UG.Vector2(1, 0)
                arrRt.anchorMax = UG.Vector2(1, 1)
                arrRt.pivot = UG.Vector2(1, 0.5)
                arrRt.anchoredPosition = UG.Vector2(-10, 0)
                arrRt.sizeDelta = UG.Vector2(22, 0)
                local arrTxt = arrGo:AddComponent(typeof(UG.UI.Text))
                arrTxt.font = gameFont
                arrTxt.fontSize = 15
                arrTxt.alignment = UG.TextAnchor.MiddleCenter
                arrTxt.color = UG.Color(1.0, 0.85, 0.35, 1.0)
                arrTxt.text = "▼"
                local arrOut = arrGo:AddComponent(typeof(UG.UI.Outline))
                arrOut.effectColor = UG.Color(0.20, 0.14, 0.10, 1.0)
                arrOut.effectDistance = UG.Vector2(1.0, -1.0)

                btnDropTf = dropGo.transform
            else
                local drt = btnDropTf:GetComponent(typeof(UG.RectTransform))
                if drt then
                    drt.anchoredPosition = UG.Vector2(-952.0, -56.0)
                    drt.sizeDelta = UG.Vector2(260.0, 50.0)
                end
            end

            -- 5. Bảng xổ xuống chọn vật phẩm (BlockerHTPSMarketDrop) - Khung giấy cuộn viền vàng gốc (popup_notitle_2 + round_rect_5)
            if not blkDropTf then
                local blkGo = GO("BlockerHTPSMarketDrop")
                blkGo.transform:SetParent(parentTf, false)
                addSkinMarker(blkGo)
                local brt = blkGo:AddComponent(typeof(UG.RectTransform))
                brt.anchorMin = UG.Vector2(0, 0)
                brt.anchorMax = UG.Vector2(1, 1)
                brt.offsetMin = UG.Vector2(-300, -300)
                brt.offsetMax = UG.Vector2(300, 300)
                local bimg = blkGo:AddComponent(typeof(UG.UI.Image))
                bimg.color = UG.Color(0, 0, 0, 0.30)
                local bbtn = blkGo:AddComponent(typeof(UG.UI.Button))
                bbtn.onClick:AddListener(function()
                    blkGo:SetActive(false)
                end)

                local boxGo = GO("BoxList")
                boxGo.transform:SetParent(blkGo.transform, false)
                local xrt = boxGo:AddComponent(typeof(UG.RectTransform))
                xrt.anchorMin = UG.Vector2(1.0, 0.5)
                xrt.anchorMax = UG.Vector2(1.0, 0.5)
                xrt.pivot = UG.Vector2(0.5, 0.5)
                xrt.anchoredPosition = UG.Vector2(-902.0, 58.0)
                xrt.sizeDelta = UG.Vector2(352.0, 386.0)
                local ximg = boxGo:AddComponent(typeof(UG.UI.Image))
                if spPopupScroll then
                    ximg.sprite = spPopupScroll
                    ximg.type = UG.UI.Image.Type.Sliced
                    ximg.color = UG.Color(1.0, 1.0, 1.0, 1.0)
                else
                    ximg.color = UG.Color(0.84, 0.76, 0.58, 0.98)
                end
                -- Chặn click xuyên qua BoxList xuống Blocker
                local xbtn = boxGo:AddComponent(typeof(UG.UI.Button))
                xbtn.transition = UG.UI.Selectable.Transition.None

                local hdrGo = GO("Header")
                hdrGo.transform:SetParent(boxGo.transform, false)
                local hrt = hdrGo:AddComponent(typeof(UG.RectTransform))
                hrt.anchorMin = UG.Vector2(0, 1)
                hrt.anchorMax = UG.Vector2(1, 1)
                hrt.pivot = UG.Vector2(0.5, 1)
                hrt.anchoredPosition = UG.Vector2(0, -10)
                hrt.sizeDelta = UG.Vector2(-32, 30)
                local htxt = hdrGo:AddComponent(typeof(UG.UI.Text))
                htxt.font = gameFont
                htxt.fontSize = 18
                htxt.fontStyle = UG.FontStyle.Normal
                htxt.alignment = UG.TextAnchor.MiddleCenter
                htxt.color = UG.Color(0.376, 0.243, 0.110, 1.0)
                htxt.text = "Chọn Vật Phẩm Chợ Đen"
                local hout = hdrGo:AddComponent(typeof(UG.UI.Outline))
                hout.effectColor = UG.Color(0.996, 0.843, 0.541, 1.0)
                hout.effectDistance = UG.Vector2(1.0, -1.0)

                local vpGo = GO("Viewport")
                vpGo.transform:SetParent(boxGo.transform, false)
                local vprt = vpGo:AddComponent(typeof(UG.RectTransform))
                vprt.anchorMin = UG.Vector2(0, 0)
                vprt.anchorMax = UG.Vector2(1, 1)
                vprt.offsetMin = UG.Vector2(16, 16)
                vprt.offsetMax = UG.Vector2(-16, -44)
                local vpimg = vpGo:AddComponent(typeof(UG.UI.Image))
                if spInnerShelf then
                    vpimg.sprite = spInnerShelf
                    vpimg.type = UG.UI.Image.Type.Sliced
                    vpimg.color = UG.Color(1.0, 1.0, 1.0, 1.0)
                else
                    vpimg.color = UG.Color(0.38, 0.28, 0.19, 0.96)
                end
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
                vlg.spacing = 5
                vlg.padding = UG.RectOffset(8, 8, 8, 8)

                local csf = cntGo:AddComponent(typeof(UG.UI.ContentSizeFitter))
                csf.verticalFit = UG.UI.ContentSizeFitter.FitMode.PreferredSize

                local sr = vpGo:AddComponent(typeof(UG.UI.ScrollRect))
                sr.content = crt
                sr.viewport = vprt
                sr.horizontal = false
                sr.vertical = true
                sr.movementType = UG.UI.ScrollRect.MovementType.Clamped
                sr.scrollSensitivity = 25

                blkGo:SetActive(false)
                blkDropTf = blkGo.transform
            end

            if not btnDropTf.gameObject.activeSelf then
                btnDropTf.gameObject:SetActive(true)
            end

            local opts = _G.HTPS_GetMarketOptions(ps)
            local lblDropTxt = btnDropTf:Find("Label") and btnDropTf:Find("Label"):GetComponent(typeof(UG.UI.Text)) or nil

            local sigParts = {}
            for _, o in ipairs(opts) do
                table.insert(sigParts, tostring(o.itemUid) .. ":" .. tostring(o.label))
            end
            local optsSig = table.concat(sigParts, "|")

            local function refreshMarketDropSelectionUI()
                local curSel = tostring(_G.HTPS_MARKET_SELECTED_UID or "")
                local matchedOpt = nil
                for _, o in ipairs(opts) do
                    if o.itemUid == curSel then
                        matchedOpt = o
                        break
                    end
                end
                if not matchedOpt and #opts > 0 then
                    matchedOpt = opts[1]
                    _G.HTPS_MARKET_SELECTED_UID = matchedOpt.itemUid
                end
                if lblDropTxt and matchedOpt then
                    lblDropTxt.text = matchedOpt.shortLabel
                end
                local cntTf = blkDropTf and blkDropTf:Find("BoxList/Viewport/ListContent") or nil
                if cntTf then
                    for i = 0, cntTf.childCount - 1 do
                        local rTf = cntTf:GetChild(i)
                        local rowIdx = tonumber(rTf.name:match("^RowIdx_(%d+)$"))
                        local rowUid = (rowIdx and _G.HTPS_MARKET_ROW_UID_MAP and _G.HTPS_MARKET_ROW_UID_MAP[rowIdx]) or nil
                        local isSel = (matchedOpt ~= nil and rowUid == matchedOpt.itemUid)
                        local rImg = rTf:GetComponent(typeof(UG.UI.Image))
                        if rImg then
                            if isSel and spBtnYellow then
                                rImg.sprite = spBtnYellow
                                rImg.type = UG.UI.Image.Type.Sliced
                                rImg.color = UG.Color(1.0, 1.0, 1.0, 1.0)
                            elseif spBoxField then
                                rImg.sprite = spBoxField
                                rImg.type = UG.UI.Image.Type.Sliced
                                rImg.color = UG.Color(1.0, 1.0, 1.0, 0.96)
                            else
                                rImg.color = isSel and UG.Color(0.88, 0.68, 0.18, 0.98) or UG.Color(0.24, 0.17, 0.11, 0.94)
                            end
                        end
                        local tickTf = rTf:Find("Tick")
                        if tickTf then
                            tickTf.gameObject:SetActive(isSel and spTickGreen ~= nil)
                        end
                        local txtTf = rTf:Find("Text")
                        if txtTf then
                            local trt = txtTf:GetComponent(typeof(UG.RectTransform))
                            if trt then
                                trt.offsetMin = UG.Vector2((isSel and spTickGreen ~= nil) and 36 or 14, 4)
                                trt.offsetMax = UG.Vector2(-12, -3)
                            end
                            local rTxt = txtTf:GetComponent(typeof(UG.UI.Text))
                            local rOut = txtTf:GetComponent(typeof(UG.UI.Outline))
                            if rTxt then
                                rTxt.color = isSel and UG.Color(0.45, 0.26, 0.11, 1.0) or UG.Color(0.95, 0.91, 0.82, 1.0)
                            end
                            if rOut then
                                rOut.enabled = not isSel
                            end
                        end
                    end
                end
            end

            -- Nạp danh sách các dòng vật phẩm (đã gộp các ô trùng) vào ListContent bằng khung gỗ/vàng gốc
            local listCntTf = blkDropTf:Find("BoxList/Viewport/ListContent")
            if listCntTf and #opts > 0 and (listCntTf.childCount ~= #opts or _G.HTPS_MARKET_LAST_SIG ~= optsSig) then
                for i = listCntTf.childCount - 1, 0, -1 do
                    UG.Object.DestroyImmediate(listCntTf:GetChild(i).gameObject)
                end
                _G.HTPS_MARKET_ROW_UID_MAP = {}
                for idx, opt in ipairs(opts) do
                    _G.HTPS_MARKET_ROW_UID_MAP[idx] = opt.itemUid
                    local rowGo = GO("RowIdx_" .. tostring(idx))
                    rowGo.transform:SetParent(listCntTf, false)
                    rowGo:AddComponent(typeof(UG.RectTransform))
                    local le = rowGo:AddComponent(typeof(UG.UI.LayoutElement))
                    le.minHeight = 42
                    le.preferredHeight = 42
                    local rImg = rowGo:AddComponent(typeof(UG.UI.Image))
                    if spBoxField then
                        rImg.sprite = spBoxField
                        rImg.type = UG.UI.Image.Type.Sliced
                        rImg.color = UG.Color(1.0, 1.0, 1.0, 0.96)
                    else
                        rImg.color = UG.Color(0.24, 0.17, 0.11, 0.94)
                    end
                    local rBtn = rowGo:AddComponent(typeof(UG.UI.Button))
                    rBtn.targetGraphic = rImg

                    if spTickGreen then
                        local tkGo = GO("Tick")
                        tkGo.transform:SetParent(rowGo.transform, false)
                        local tkRt = tkGo:AddComponent(typeof(UG.RectTransform))
                        tkRt.anchorMin = UG.Vector2(0, 0.5)
                        tkRt.anchorMax = UG.Vector2(0, 0.5)
                        tkRt.pivot = UG.Vector2(0, 0.5)
                        tkRt.anchoredPosition = UG.Vector2(8, 1)
                        tkRt.sizeDelta = UG.Vector2(24, 22)
                        local tkIm = tkGo:AddComponent(typeof(UG.UI.Image))
                        tkIm.sprite = spTickGreen
                        tkIm.type = UG.UI.Image.Type.Simple
                        tkIm.color = UG.Color(1.0, 1.0, 1.0, 1.0)
                        tkGo:SetActive(false)
                    end

                    local rtGo = GO("Text")
                    rtGo.transform:SetParent(rowGo.transform, false)
                    local rtrt = rtGo:AddComponent(typeof(UG.RectTransform))
                    rtrt.anchorMin = UG.Vector2(0, 0)
                    rtrt.anchorMax = UG.Vector2(1, 1)
                    rtrt.offsetMin = UG.Vector2(14, 4)
                    rtrt.offsetMax = UG.Vector2(-12, -3)
                    local rTxt = rtGo:AddComponent(typeof(UG.UI.Text))
                    rTxt.font = gameFont
                    rTxt.fontSize = 15
                    rTxt.fontStyle = UG.FontStyle.Normal
                    rTxt.alignment = UG.TextAnchor.MiddleLeft
                    rTxt.resizeTextForBestFit = true
                    rTxt.resizeTextMinSize = 11
                    rTxt.resizeTextMaxSize = 16
                    rTxt.text = opt.label
                    local rOut = rtGo:AddComponent(typeof(UG.UI.Outline))
                    rOut.effectColor = UG.Color(0.18, 0.10, 0.05, 1.0)
                    rOut.effectDistance = UG.Vector2(1.0, -1.0)

                    local chosenUid = opt.itemUid
                    rBtn.onClick:AddListener(function()
                        _G.HTPS_MARKET_SELECTED_UID = chosenUid
                        pcall(function() UG.PlayerPrefs.SetString("HTPS_MARKET_ITEM_UID", chosenUid) end)
                        refreshMarketDropSelectionUI()
                        _G.HTPS_RefreshShopCounterUI(ps)
                        if blkDropTf then blkDropTf.gameObject:SetActive(false) end
                    end)
                end
                _G.HTPS_MARKET_LAST_SIG = optsSig
            end

            refreshMarketDropSelectionUI()
            _G.HTPS_RefreshShopCounterUI(ps)

            if _G.HTPS_BOUND_MARKET_DROP_BTN ~= btnDropTf then
                local dbc = btnDropTf:GetComponent(typeof(UG.UI.Button))
                if dbc then
                    dbc.onClick:RemoveAllListeners()
                    dbc.onClick:AddListener(function()
                        if blkDropTf then
                            local nextState = not blkDropTf.gameObject.activeSelf
                            if nextState then
                                blkDropTf:SetAsLastSibling()
                                refreshMarketDropSelectionUI()
                            end
                            blkDropTf.gameObject:SetActive(nextState)
                        end
                    end)
                end
                _G.HTPS_BOUND_MARKET_DROP_BTN = btnDropTf
            end
        end)
    end

    _G.HTPS_ToggleAutoLuckySpin = function()
        if _G.HTPS_LUCKY_SPIN_RUNNING then
            _G.HTPS_LUCKY_SPIN_RUNNING = false
            _G.HTPS_BONUS_SUPPRESS_UNTIL = 0
            if _G.HTPS_AUTO then _G.HTPS_AUTO.suppressPopup = true end
            if _G.HTPS_BTN_LUCKY_SPIN_TXT and not _G.HTPS_BTN_LUCKY_SPIN_TXT:Equals(nil) then
                _G.HTPS_BTN_LUCKY_SPIN_TXT.text = "Auto Quay Đồ"
            end
            _G.HTPS_KillSummonPopups()
            return
        end
        if _G.HTPS_LUCKY_DUST_RUNNING then
            _G.HTPS_LUCKY_DUST_RUNNING = false
            if _G.HTPS_BTN_LUCKY_DUST_TXT and not _G.HTPS_BTN_LUCKY_DUST_TXT:Equals(nil) then
                _G.HTPS_BTN_LUCKY_DUST_TXT.text = "Auto Quay Bụi"
            end
        end
        _G.HTPS_LUCKY_SPIN_RUNNING = true
        _G.HTPS_BONUS_SUPPRESS_UNTIL = 0
        if _G.HTPS_AUTO then _G.HTPS_AUTO.suppressPopup = true end
        if _G.HTPS_BTN_LUCKY_SPIN_TXT and not _G.HTPS_BTN_LUCKY_SPIN_TXT:Equals(nil) then
            _G.HTPS_BTN_LUCKY_SPIN_TXT.text = "Đang Quay... [Dừng]"
        end
        CS.Toast.ShowToast("🚀 Bắt đầu Auto Quay Vòng Quay Siêu Tốc (Gộp đa bàn xoay + Tự Reset)!")

        CsCoroutine.start(function()
            local REF_FLAGS = 60
            local gc = CS.GameContext.GetIntance()
            local inv = CS.PlayerInventory.GetInstance()
            local csNet = CS.NetworkController.GetInstance()
            local urlServer = csNet and csNet.m_UrlGameServer or ""
            local totalSpins10 = 0
            local totalEquipWon = 0
            local equipAvail = 2
            local firstBatchNeedsReset = false

            local function countTotalEquips()
                local total = 0
                pcall(function()
                    local lstEq = inv:GetType():GetField("m_LstItemEquipment", REF_FLAGS):GetValue(inv)
                    if lstEq then
                        for i = 0, lstEq.Count - 1 do
                            local eq = lstEq[i]
                            if eq then
                                total = total + (tonumber(eq.m_Number) or 0)
                            end
                        end
                    end
                end)
                return total
            end

            local function syncWheelStatus()
                if not urlServer or urlServer == "" then return end
                local req319 = CS.pbdson.RequestData()
                req319.session = gc.m_Session
                local a319 = CS.pbdson.PbAction()
                a319.actionId = 319
                req319.actions:Add(a319)
                local d319 = _G.HTPS_PutWebRequest(urlServer .. "/i/319/" .. tostring(gc.m_UserId), _G.HTPS_SerializeProto(req319), 8)
                if d319 then
                    local r = _G.HTPS_DeserializeProto(d319, "pbdson.ResponseData,PbMethodLib")
                    if r and r.aAction then
                        for i = 0, r.aAction.Count - 1 do
                            local act = r.aAction[i]
                            if act.actionId == 319 and act.data then
                                local lcv = _G.HTPS_DeserializeProto(act.data, "pbdson.ListCommonVector,PbMethodLib")
                                if lcv and lcv.aVector and lcv.aVector.Count >= 3 then
                                    local v2 = lcv.aVector[2]
                                    if v2 and v2.aLong and v2.aLong.Count >= 6 then
                                        equipAvail = (tonumber(v2.aLong[4]) or 0) + (tonumber(v2.aLong[5]) or 0)
                                    end
                                end
                                pcall(function() csNet:ProcessPackageEvent(319, act.data) end)
                            end
                        end
                    end
                end
            end

            pcall(function() _G.HTPS_SyncServerEquipmentAndSafeGold() end)
            pcall(syncWheelStatus)
            if equipAvail < 2 then
                firstBatchNeedsReset = true
            end

            while _G.HTPS_LUCKY_SPIN_RUNNING do
                _G.HTPS_BONUS_SUPPRESS_UNTIL = 0
                if _G.HTPS_AUTO then _G.HTPS_AUTO.suppressPopup = true end
                _G.HTPS_KillSummonPopups()
                local ls = _G.HTPS_FindObjectOfType(typeof(CS.LuckySpinScene))
                if not ls or not ls.gameObject.activeInHierarchy then
                    _G.HTPS_LUCKY_SPIN_RUNNING = false
                    break
                end

                -- 1. Ẩn/xóa PopupShowBonus nếu hiện ra chắn màn hình & mở khóa bàn xoay
                pcall(function()
                    local allPops = _G.HTPS_FindObjectsOfType(typeof(CS.BasePopup))
                    for i = 0, allPops.Length - 1 do
                        local p = allPops[i]
                        if p and p.gameObject.name:find("PopupShowBonus") then
                            UG.Object.DestroyImmediate(p.gameObject)
                        end
                    end
                    ls:GetType():GetField("m_SpinDiskActive", REF_FLAGS):SetValue(ls, true)
                    local sd = ls:GetType():GetField("m_SpinDisk", REF_FLAGS):GetValue(ls)
                    if sd and sd.m_Transform then
                        sd.m_Transform:Rotate(0, 0, -165)
                    end
                end)

                local curChips = inv:GetNumberItemConsumable(10)
                if not curChips or curChips < 0 then curChips = gc.m_Chip or 0 end
                local curGem = tonumber(gc.m_Gem) or 0
                local extraResetGem = firstBatchNeedsReset and 50 or 0

                -- Mỗi bàn xoay cần 32 vé (1,600 KC) + 50 KC Reset = 1,650 KC; gộp tối đa 4 bàn xoay (160 lượt quay) trong 1 gói HTTP!
                local availGemEquiv = math.max(0, (curGem - extraResetGem) + (curChips * 50))
                local wheelsToRun = math.min(4, math.floor(availGemEquiv / 1650))

                if wheelsToRun >= 1 then
                    local totalChipsNeeded = wheelsToRun * 32
                    local needBuyChips = math.max(0, totalChipsNeeded - curChips)

                    local req = CS.pbdson.RequestData()
                    req.session = gc.m_Session

                    if firstBatchNeedsReset then
                        local a320Init = CS.pbdson.PbAction()
                        a320Init.actionId = 320
                        req.actions:Add(a320Init)
                        firstBatchNeedsReset = false
                    end

                    if needBuyChips > 0 then
                        local cv323 = CS.pbdson.CommonVector()
                        cv323.aLong:Add(needBuyChips)
                        local a323 = CS.pbdson.PbAction()
                        a323.actionId = 323
                        a323.data = _G.HTPS_SerializeProto(cv323)
                        req.actions:Add(a323)
                    end

                    for w = 1, wheelsToRun do
                        for s = 1, 4 do
                            local cv321 = CS.pbdson.CommonVector()
                            cv321.aLong:Add(10)
                            local a321 = CS.pbdson.PbAction()
                            a321.actionId = 321
                            a321.data = _G.HTPS_SerializeProto(cv321)
                            req.actions:Add(a321)
                        end
                        local a320 = CS.pbdson.PbAction()
                        a320.actionId = 320
                        req.actions:Add(a320)
                    end

                    local beforeEq = countTotalEquips()
                    local d = _G.HTPS_PutWebRequest(urlServer .. "/i/321/" .. tostring(gc.m_UserId), _G.HTPS_SerializeProto(req), 10)
                    if d then
                        local r = _G.HTPS_DeserializeProto(d, "pbdson.ResponseData,PbMethodLib")
                        if r and r.aAction then
                            local last320Data = nil
                            local last319Data = nil
                            for i = 0, r.aAction.Count - 1 do
                                local act = r.aAction[i]
                                if act.actionId == 323 and act.data then
                                    local cv = _G.HTPS_DeserializeProto(act.data, "pbdson.CommonVector,PbMethodLib")
                                    if cv and cv.aLong then
                                        CS.BonusModel.ParseBonusReceived(cv.aLong)
                                    end
                                elseif act.actionId == 321 and act.data then
                                    local lcv = _G.HTPS_DeserializeProto(act.data, "pbdson.ListCommonVector,PbMethodLib")
                                    if lcv and lcv.aVector and lcv.aVector.Count >= 1 then
                                        local v0 = lcv.aVector[0]
                                        if v0 and v0.aLong and v0.aLong.Count > 1 then
                                            local bonusLongs = CS.System.Collections.Generic.List(typeof(CS.System.Int64))()
                                            for j = 1, v0.aLong.Count - 1 do
                                                bonusLongs:Add(v0.aLong[j])
                                            end
                                            CS.BonusModel.ParseBonusReceived(bonusLongs)
                                        end
                                        if lcv.aVector.Count >= 2 then
                                            local v1 = lcv.aVector[1]
                                            if v1 and v1.aLong and v1.aLong.Count > 0 then
                                                CS.BonusModel.ParseBonusReceived(v1.aLong)
                                            end
                                        end
                                        totalSpins10 = totalSpins10 + 1
                                    end
                                elseif act.actionId == 320 and act.data then
                                    local cv = _G.HTPS_DeserializeProto(act.data, "pbdson.CommonVector,PbMethodLib")
                                    if cv and cv.aLong and cv.aLong.Count > 0 then
                                        gc.m_Gem = tonumber(cv.aLong[0]) or gc.m_Gem
                                    end
                                    last320Data = act.data
                                elseif act.actionId == 319 and act.data then
                                    last319Data = act.data
                                end
                            end
                            if last320Data then
                                pcall(function() csNet:ProcessPackageEvent(320, last320Data) end)
                            end
                            if last319Data then
                                pcall(function() csNet:ProcessPackageEvent(319, last319Data) end)
                            end
                        end
                    end
                    local afterEq = countTotalEquips()
                    if afterEq > beforeEq then
                        totalEquipWon = totalEquipWon + (afterEq - beforeEq)
                    end
                else
                    -- Fallback khi Kim Cương còn ít (< 1,650 KC): quay nốt từng lượt x10
                    local needChipsOne = math.max(0, 8 - curChips)
                    if curGem < (needChipsOne * 50) then
                        CS.Toast.ShowToast("Không đủ Kim Cương để mua thêm Vé Vòng Quay!")
                        _G.HTPS_LUCKY_SPIN_RUNNING = false
                        break
                    end
                    local reqOne = CS.pbdson.RequestData()
                    reqOne.session = gc.m_Session
                    if needChipsOne > 0 then
                        local cv323 = CS.pbdson.CommonVector()
                        cv323.aLong:Add(needChipsOne)
                        local a323 = CS.pbdson.PbAction()
                        a323.actionId = 323
                        a323.data = _G.HTPS_SerializeProto(cv323)
                        reqOne.actions:Add(a323)
                    end
                    local cv321 = CS.pbdson.CommonVector()
                    cv321.aLong:Add(10)
                    local a321 = CS.pbdson.PbAction()
                    a321.actionId = 321
                    a321.data = _G.HTPS_SerializeProto(cv321)
                    reqOne.actions:Add(a321)

                    local beforeEq = countTotalEquips()
                    local dOne = _G.HTPS_PutWebRequest(urlServer .. "/i/321/" .. tostring(gc.m_UserId), _G.HTPS_SerializeProto(reqOne), 8)
                    if dOne then
                        local rOne = _G.HTPS_DeserializeProto(dOne, "pbdson.ResponseData,PbMethodLib")
                        if rOne and rOne.aAction then
                            for i = 0, rOne.aAction.Count - 1 do
                                local act = rOne.aAction[i]
                                if act.actionId == 323 and act.data then
                                    local cv = _G.HTPS_DeserializeProto(act.data, "pbdson.CommonVector,PbMethodLib")
                                    if cv and cv.aLong then CS.BonusModel.ParseBonusReceived(cv.aLong) end
                                elseif act.actionId == 321 and act.data then
                                    local lcv = _G.HTPS_DeserializeProto(act.data, "pbdson.ListCommonVector,PbMethodLib")
                                    if lcv and lcv.aVector and lcv.aVector.Count >= 1 then
                                        local v0 = lcv.aVector[0]
                                        if v0 and v0.aLong and v0.aLong.Count > 1 then
                                            local bonusLongs = CS.System.Collections.Generic.List(typeof(CS.System.Int64))()
                                            for j = 1, v0.aLong.Count - 1 do bonusLongs:Add(v0.aLong[j]) end
                                            CS.BonusModel.ParseBonusReceived(bonusLongs)
                                        end
                                        if lcv.aVector.Count >= 2 then
                                            local v1 = lcv.aVector[1]
                                            if v1 and v1.aLong and v1.aLong.Count > 0 then
                                                CS.BonusModel.ParseBonusReceived(v1.aLong)
                                            end
                                        end
                                        totalSpins10 = totalSpins10 + 1
                                    end
                                elseif act.actionId == 1 then
                                    _G.HTPS_LUCKY_SPIN_RUNNING = false
                                end
                            end
                        end
                    end
                    local afterEq = countTotalEquips()
                    if afterEq > beforeEq then
                        totalEquipWon = totalEquipWon + (afterEq - beforeEq)
                    end
                end

                if _G.HTPS_BTN_LUCKY_SPIN_TXT and _G.HTPS_LUCKY_SPIN_RUNNING then
                    _G.HTPS_BTN_LUCKY_SPIN_TXT.text = string.format("Đang Quay (%d)... [Dừng]", totalSpins10 * 10)
                end

                -- Bảo vệ tràn Vàng 32-bit định kỳ khi quay nhiều
                if (gc.m_Gold % 4294967296) >= 2050000000 then
                    pcall(function() _G.HTPS_SyncServerEquipmentAndSafeGold() end)
                end

                coroutine.yield(nil)
            end

            -- Khi dừng Auto Quay, đồng bộ lại trạng thái bàn xoay & kho trang bị từ Server để qua Lò Rèn ghép ngay
            pcall(syncWheelStatus)
            pcall(function() _G.HTPS_SyncServerEquipmentAndSafeGold() end)
            if _G.HTPS_BTN_LUCKY_SPIN_TXT and not _G.HTPS_BTN_LUCKY_SPIN_TXT:Equals(nil) then
                _G.HTPS_BTN_LUCKY_SPIN_TXT.text = "Auto Quay Đồ"
            end
            CS.Toast.ShowToast(string.format("Đã dừng Auto Vòng Quay! (Quay %d lượt, nhận +%d trang bị)", totalSpins10 * 10, totalEquipWon))
        end)
    end

    _G.HTPS_ToggleAutoLuckyDust = function()
        if not _G.HTPS_AUTO_ACTIVATED then
            if CS.Toast then CS.Toast.ShowToast("⚠️ Vui lòng kích hoạt bản quyền VIP để dùng tính năng này!") end
            if _G.HTPS_ShowActivationDialog then _G.HTPS_ShowActivationDialog(true) end
            return
        end

        if _G.HTPS_LUCKY_DUST_RUNNING then
            _G.HTPS_LUCKY_DUST_RUNNING = false
            _G.HTPS_BONUS_SUPPRESS_UNTIL = 0
            if _G.HTPS_AUTO then _G.HTPS_AUTO.suppressPopup = true end
            if _G.HTPS_BTN_LUCKY_DUST_TXT and not _G.HTPS_BTN_LUCKY_DUST_TXT:Equals(nil) then
                _G.HTPS_BTN_LUCKY_DUST_TXT.text = "Auto Quay Bụi"
            end
            _G.HTPS_KillSummonPopups()
            return
        end

        if _G.HTPS_LUCKY_SPIN_RUNNING then
            _G.HTPS_LUCKY_SPIN_RUNNING = false
            if _G.HTPS_BTN_LUCKY_SPIN_TXT and not _G.HTPS_BTN_LUCKY_SPIN_TXT:Equals(nil) then
                _G.HTPS_BTN_LUCKY_SPIN_TXT.text = "Auto Quay Đồ"
            end
        end

        _G.HTPS_LUCKY_DUST_RUNNING = true
        _G.HTPS_BONUS_SUPPRESS_UNTIL = 0
        if _G.HTPS_AUTO then _G.HTPS_AUTO.suppressPopup = true end
        if _G.HTPS_BTN_LUCKY_DUST_TXT and not _G.HTPS_BTN_LUCKY_DUST_TXT:Equals(nil) then
            _G.HTPS_BTN_LUCKY_DUST_TXT.text = "Đang Săn... [Dừng]"
        end
        CS.Toast.ShowToast("🔮 Bắt đầu Auto Quay Bụi Ma Thuật Siêu Tốc (Tự săn bàn Max Bụi + Gộp x160 lượt)!")

        CsCoroutine.start(function()
            local REF_FLAGS = 60
            local gc = CS.GameContext.GetIntance()
            local inv = CS.PlayerInventory.GetInstance()
            local csNet = CS.NetworkController.GetInstance()
            local urlServer = csNet and csNet.m_UrlGameServer or ""
            local totalSpins10 = 0
            local totalDustWon = 0
            local curDustTier = 0

            -- QUAN TRỌNG: Dùng ParseBonusPreview (chỉ đọc preview bàn xoay, TUYỆT ĐỐI KHÔNG dùng ParseBonusReceived trên gói 319 vì sẽ ghi đè nhầm m_Gem & Bụi trong RAM!)
            local function parseWheelDustTier(actData)
                local maxTier = 0
                if not actData then return 0 end
                pcall(function()
                    local lcv = _G.HTPS_DeserializeProto(actData, "pbdson.ListCommonVector,PbMethodLib")
                    if lcv and lcv.aVector and lcv.aVector.Count >= 2 then
                        local v1 = lcv.aVector[1]
                        local v2 = (lcv.aVector.Count >= 3) and lcv.aVector[2] or nil
                        if v1 and v1.aLong and v1.aLong.Count > 0 then
                            local listLongs = CS.System.Collections.Generic.List(typeof(CS.System.Int64))()
                            for j = 0, v1.aLong.Count - 1 do listLongs:Add(v1.aLong[j]) end
                            local bm = CS.BonusModel.ParseBonusPreview(listLongs)
                            if bm and bm.m_LstBonusConsumable then
                                for k = 0, bm.m_LstBonusConsumable.Count - 1 do
                                    local c = bm.m_LstBonusConsumable[k]
                                    if c and c.m_ItemKey == 3 then
                                        local idx = tonumber(c.m_IndexReward) or -1
                                        local avail = 1
                                        if v2 and v2.aLong and idx >= 0 and idx < v2.aLong.Count then
                                            avail = tonumber(v2.aLong[idx]) or 1
                                        end
                                        if avail > 0 then
                                            local amt = tonumber(c.m_NumberAdd) or 0
                                            if amt <= 0 then amt = 1 end
                                            if amt > maxTier then maxTier = amt end
                                        end
                                    end
                                end
                            end
                        end
                    end
                end)
                return maxTier
            end

            local function syncWheelDustStatus()
                if not urlServer or urlServer == "" then return 0 end
                local req319 = CS.pbdson.RequestData()
                req319.session = gc.m_Session
                local a319 = CS.pbdson.PbAction()
                a319.actionId = 319
                req319.actions:Add(a319)
                local d319 = _G.HTPS_PutWebRequest(urlServer .. "/i/319/" .. tostring(gc.m_UserId), _G.HTPS_SerializeProto(req319), 8)
                if d319 then
                    local r = _G.HTPS_DeserializeProto(d319, "pbdson.ResponseData,PbMethodLib")
                    if r and r.aAction then
                        local last319 = nil
                        for i = 0, r.aAction.Count - 1 do
                            local act = r.aAction[i]
                            if act.actionId == 319 and act.data then
                                curDustTier = parseWheelDustTier(act.data)
                                last319 = act.data
                            end
                        end
                        if last319 then
                            pcall(function() csNet:ProcessPackageEvent(319, last319) end)
                        end
                    end
                end
                return curDustTier
            end

            -- KHÔNG gọi HTPS_SyncServerEquipmentAndSafeGold trong Auto Quay Bụi vì hàm xả vàng (action 235) sẽ tiêu tốn Bụi Ma Thuật!
            pcall(syncWheelDustStatus)

            while _G.HTPS_LUCKY_DUST_RUNNING do
                _G.HTPS_BONUS_SUPPRESS_UNTIL = 0
                if _G.HTPS_AUTO then _G.HTPS_AUTO.suppressPopup = true end
                _G.HTPS_KillSummonPopups()
                local ls = _G.HTPS_FindObjectOfType(typeof(CS.LuckySpinScene))
                if not ls or ls:Equals(nil) or not ls.gameObject.activeInHierarchy then
                    _G.HTPS_LUCKY_DUST_RUNNING = false
                    break
                end

                pcall(function()
                    local allPops = _G.HTPS_FindObjectsOfType(typeof(CS.BasePopup))
                    for i = 0, allPops.Length - 1 do
                        local p = allPops[i]
                        if p and p.gameObject.name:find("PopupShowBonus") then
                            UG.Object.DestroyImmediate(p.gameObject)
                        end
                    end
                    ls:GetType():GetField("m_SpinDiskActive", REF_FLAGS):SetValue(ls, true)
                    local sd = ls:GetType():GetField("m_SpinDisk", REF_FLAGS):GetValue(ls)
                    if sd and sd.m_Transform then
                        sd.m_Transform:Rotate(0, 0, -165)
                    end
                end)

                -- 1. Nếu bàn chưa có Bụi (hoặc chưa đạt mốc 40 Bụi khi dư dả KC), tự động Reset (320) tìm bàn ngon nhất!
                -- Khi đã tìm được bàn có Bụi ngon, Bụi Ma Thuật trên Vòng Quay Thường KHÔNG BAO GIỜ CẠN (v2 luôn = 1), nên giữ nguyên bàn đó để gộp x160 lượt siêu tốc!
                local resetTries = 0
                local lastReset320 = nil
                local lastReset319 = nil
                while _G.HTPS_LUCKY_DUST_RUNNING do
                    local curGem = tonumber(gc.m_Gem) or 0
                    local wantMoreReset = false
                    if curDustTier <= 0 then
                        wantMoreReset = (resetTries < 25)
                    elseif curDustTier < 40 and curGem >= 2500 and resetTries < 12 then
                        wantMoreReset = true
                    end
                    if not wantMoreReset then break end

                    if curGem < 50 then
                        if curDustTier <= 0 then
                            CS.Toast.ShowToast("⚠️ Không đủ 50 Kim Cương để Reset tìm Bụi Ma Thuật!")
                            _G.HTPS_LUCKY_DUST_RUNNING = false
                        end
                        break
                    end

                    local reqRes = CS.pbdson.RequestData()
                    reqRes.session = gc.m_Session
                    local a320 = CS.pbdson.PbAction()
                    a320.actionId = 320
                    reqRes.actions:Add(a320)

                    local dRes = _G.HTPS_PutWebRequest(urlServer .. "/i/320/" .. tostring(gc.m_UserId), _G.HTPS_SerializeProto(reqRes), 8)
                    if dRes then
                        local r = _G.HTPS_DeserializeProto(dRes, "pbdson.ResponseData,PbMethodLib")
                        if r and r.aAction then
                            for i = 0, r.aAction.Count - 1 do
                                local act = r.aAction[i]
                                if act.actionId == 320 and act.data then
                                    local cv = _G.HTPS_DeserializeProto(act.data, "pbdson.CommonVector,PbMethodLib")
                                    if cv and cv.aLong and cv.aLong.Count > 0 then
                                        gc.m_Gem = tonumber(cv.aLong[0]) or gc.m_Gem
                                    end
                                    lastReset320 = act.data
                                elseif act.actionId == 319 and act.data then
                                    curDustTier = parseWheelDustTier(act.data)
                                    lastReset319 = act.data
                                end
                            end
                        end
                    end
                    resetTries = resetTries + 1
                    coroutine.yield(UG.WaitForSeconds(0.03))
                end

                if lastReset320 then pcall(function() csNet:ProcessPackageEvent(320, lastReset320) end) end
                if lastReset319 then pcall(function() csNet:ProcessPackageEvent(319, lastReset319) end) end

                if not _G.HTPS_LUCKY_DUST_RUNNING then break end

                -- 2. Gộp tối đa 16 lượt x10 (160 vòng quay / 1 gói HTTP) trên bàn có Bụi, y hệt tốc độ Auto Quay Đồ!
                if curDustTier > 0 then
                    local curChips = inv:GetNumberItemConsumable(10)
                    if not curChips or curChips < 0 then curChips = gc.m_Chip or 0 end
                    local curGem = tonumber(gc.m_Gem) or 0

                    local maxSpins10 = math.floor((curChips + math.floor(curGem / 50)) / 8)
                    if maxSpins10 < 1 then
                        CS.Toast.ShowToast("⚠️ Không đủ Kim Cương / Vé Vòng Quay để quay tiếp!")
                        _G.HTPS_LUCKY_DUST_RUNNING = false
                        break
                    end

                    local spinsToRun = math.min(16, maxSpins10)
                    local needBuyChips = math.max(0, (spinsToRun * 8) - curChips)

                    local reqSpin = CS.pbdson.RequestData()
                    reqSpin.session = gc.m_Session

                    if needBuyChips > 0 then
                        local cv323 = CS.pbdson.CommonVector()
                        cv323.aLong:Add(needBuyChips)
                        local a323 = CS.pbdson.PbAction()
                        a323.actionId = 323
                        a323.data = _G.HTPS_SerializeProto(cv323)
                        reqSpin.actions:Add(a323)
                    end

                    for s = 1, spinsToRun do
                        local cv321 = CS.pbdson.CommonVector()
                        cv321.aLong:Add(10)
                        local a321 = CS.pbdson.PbAction()
                        a321.actionId = 321
                        a321.data = _G.HTPS_SerializeProto(cv321)
                        reqSpin.actions:Add(a321)
                    end

                    -- Gửi kèm 1 gói 319 cuối batch để kiểm tra nếu vòng quay tự làm mới theo giờ
                    local a319Check = CS.pbdson.PbAction()
                    a319Check.actionId = 319
                    reqSpin.actions:Add(a319Check)

                    local prevDust = inv:GetNumberItemConsumable(3) or 0
                    local dSpin = _G.HTPS_PutWebRequest(urlServer .. "/i/321/" .. tostring(gc.m_UserId), _G.HTPS_SerializeProto(reqSpin), 10)
                    if dSpin then
                        local r = _G.HTPS_DeserializeProto(dSpin, "pbdson.ResponseData,PbMethodLib")
                        if r and r.aAction then
                            local spinsInBatch = 0
                            local serverErr = nil
                            local lastSpin319 = nil
                            for i = 0, r.aAction.Count - 1 do
                                local act = r.aAction[i]
                                if act.actionId == 323 and act.data then
                                    local cv = _G.HTPS_DeserializeProto(act.data, "pbdson.CommonVector,PbMethodLib")
                                    if cv and cv.aLong then CS.BonusModel.ParseBonusReceived(cv.aLong) end
                                elseif act.actionId == 321 and act.data then
                                    local lcv = _G.HTPS_DeserializeProto(act.data, "pbdson.ListCommonVector,PbMethodLib")
                                    if lcv and lcv.aVector and lcv.aVector.Count >= 1 then
                                        local v0 = lcv.aVector[0]
                                        if v0 and v0.aLong and v0.aLong.Count > 1 then
                                            local bonusLongs = CS.System.Collections.Generic.List(typeof(CS.System.Int64))()
                                            for j = 1, v0.aLong.Count - 1 do bonusLongs:Add(v0.aLong[j]) end
                                            CS.BonusModel.ParseBonusReceived(bonusLongs)
                                        end
                                        if lcv.aVector.Count >= 2 then
                                            local v1 = lcv.aVector[1]
                                            if v1 and v1.aLong and v1.aLong.Count > 0 then
                                                CS.BonusModel.ParseBonusReceived(v1.aLong)
                                            end
                                        end
                                        totalSpins10 = totalSpins10 + 1
                                        spinsInBatch = spinsInBatch + 1
                                    end
                                elseif act.actionId == 319 and act.data then
                                    curDustTier = parseWheelDustTier(act.data)
                                    lastSpin319 = act.data
                                elseif act.actionId == 1 and act.data then
                                    local cv = _G.HTPS_DeserializeProto(act.data, "pbdson.CommonVector,PbMethodLib")
                                    if cv and cv.aString and cv.aString.Count > 0 then
                                        serverErr = tostring(cv.aString[0])
                                    end
                                end
                            end
                            if lastSpin319 then
                                pcall(function() csNet:ProcessPackageEvent(319, lastSpin319) end)
                            end
                            if spinsInBatch == 0 and serverErr then
                                CS.Toast.ShowToast("⚠️ " .. serverErr)
                                _G.HTPS_LUCKY_DUST_RUNNING = false
                                break
                            end
                        end
                    end

                    local nowDust = inv:GetNumberItemConsumable(3) or 0
                    if nowDust > prevDust then
                        totalDustWon = totalDustWon + (nowDust - prevDust)
                    end
                end

                if _G.HTPS_BTN_LUCKY_DUST_TXT and not _G.HTPS_BTN_LUCKY_DUST_TXT:Equals(nil) and _G.HTPS_LUCKY_DUST_RUNNING then
                    _G.HTPS_BTN_LUCKY_DUST_TXT.text = string.format("Đang Quay (+%d Bụi) [Dừng]", totalDustWon)
                end

                coroutine.yield(nil)
            end

            _G.HTPS_LUCKY_DUST_RUNNING = false
            _G.HTPS_KillSummonPopups()
            pcall(syncWheelDustStatus)
            if _G.HTPS_BTN_LUCKY_DUST_TXT and not _G.HTPS_BTN_LUCKY_DUST_TXT:Equals(nil) then
                _G.HTPS_BTN_LUCKY_DUST_TXT.text = "Auto Quay Bụi"
            end
            CS.Toast.ShowToast(string.format("Đã dừng Auto Quay Bụi! (Quay %d lượt, nhận +%d Bụi Ma Thuật)", totalSpins10 * 10, totalDustWon))
        end)
    end

    _G.HTPS_EnsureLuckySpinButtons = function()
        pcall(function()
            local ls = _G.HTPS_FindObjectOfType(typeof(CS.LuckySpinScene))
            if not ls or not ls.gameObject.activeInHierarchy then return end
            local REF_FLAGS = 60
            local btnRef = ls:GetType():GetField("m_GoButtonRefresh", REF_FLAGS):GetValue(ls)
            if not btnRef then return end
            local parentTf = btnRef.transform.parent
            if not parentTf then return end

            -- Ẩn nút Mua + Reset Shop cũ ở ngoài màn Vòng Quay (đã chuyển vào bên trong PopupShop)
            local oldShopBtn = parentTf:Find("BtnHTPSAutoLuckyShop")
            if oldShopBtn and oldShopBtn.gameObject.activeSelf then
                oldShopBtn.gameObject:SetActive(false)
            end

            -- Nút 1: [Auto Quay Đồ]
            local btnAutoTf = parentTf:Find("BtnHTPSAutoLuckySpin")
            if not btnAutoTf then
                local cloneGo = GO.Instantiate(btnRef, parentTf, false)
                cloneGo.name = "BtnHTPSAutoLuckySpin"
                cloneGo:SetActive(true)
                local iconGem = cloneGo.transform:Find("IconGemRefresh")
                if iconGem then iconGem.gameObject:SetActive(false) end
                local txtGem = cloneGo.transform:Find("TextGemRefresh")
                if txtGem then txtGem.gameObject:SetActive(false) end
                local rt = cloneGo:GetComponent(typeof(UG.RectTransform))
                rt.anchoredPosition = UG.Vector2(-122.2, 112.0)
                rt.sizeDelta = UG.Vector2(215.0, 54.0)
                local txts = cloneGo:GetComponentsInChildren(typeof(UG.UI.Text), true)
                for i = 0, txts.Length - 1 do
                    local t = txts[i]
                    if t.gameObject.name ~= "TextGemRefresh" then
                        local loc = t.gameObject:GetComponent(typeof(CS.I2.Loc.Localize))
                        if loc then UG.Object.DestroyImmediate(loc) end
                        local trt = t.gameObject:GetComponent(typeof(UG.RectTransform))
                        trt.anchoredPosition = UG.Vector2(0, 0)
                        trt.sizeDelta = UG.Vector2(205, 48)
                        t.alignment = UG.TextAnchor.MiddleCenter
                        t.fontSize = 18
                        t.resizeTextForBestFit = true
                        t.resizeTextMinSize = 12
                        t.resizeTextMaxSize = 18
                        t.text = _G.HTPS_LUCKY_SPIN_RUNNING and "Đang Quay... [Dừng]" or "Auto Quay Đồ"
                        _G.HTPS_BTN_LUCKY_SPIN_TXT = t
                        break
                    end
                end
                btnAutoTf = cloneGo.transform
            end

            if btnAutoTf then
                if _G.HTPS_BTN_LUCKY_SPIN_TXT and not _G.HTPS_BTN_LUCKY_SPIN_TXT:Equals(nil) and not _G.HTPS_LUCKY_SPIN_RUNNING then
                    _G.HTPS_BTN_LUCKY_SPIN_TXT.text = "Auto Quay Đồ"
                end
                if _G.HTPS_BOUND_LUCKY_SPIN_BTN ~= btnAutoTf then
                    local bc = btnAutoTf:GetComponent(typeof(UG.UI.Button))
                    if bc then
                        bc.onClick:RemoveAllListeners()
                        bc.onClick:AddListener(function()
                            _G.HTPS_ToggleAutoLuckySpin()
                        end)
                    end
                    _G.HTPS_BOUND_LUCKY_SPIN_BTN = btnAutoTf
                end
            end

            -- Nút 2: [Auto Quay Bụi] (vị trí y=172)
            local btnDustTf = parentTf:Find("BtnHTPSAutoLuckyDust")
            if not btnDustTf then
                local cloneGo = GO.Instantiate(btnRef, parentTf, false)
                cloneGo.name = "BtnHTPSAutoLuckyDust"
                cloneGo:SetActive(true)
                local iconGem = cloneGo.transform:Find("IconGemRefresh")
                if iconGem then iconGem.gameObject:SetActive(false) end
                local txtGem = cloneGo.transform:Find("TextGemRefresh")
                if txtGem then txtGem.gameObject:SetActive(false) end
                local rt = cloneGo:GetComponent(typeof(UG.RectTransform))
                rt.anchoredPosition = UG.Vector2(-122.2, 172.0)
                rt.sizeDelta = UG.Vector2(215.0, 54.0)
                local txts = cloneGo:GetComponentsInChildren(typeof(UG.UI.Text), true)
                for i = 0, txts.Length - 1 do
                    local t = txts[i]
                    if t.gameObject.name ~= "TextGemRefresh" then
                        local loc = t.gameObject:GetComponent(typeof(CS.I2.Loc.Localize))
                        if loc then UG.Object.DestroyImmediate(loc) end
                        local trt = t.gameObject:GetComponent(typeof(UG.RectTransform))
                        trt.anchoredPosition = UG.Vector2(0, 0)
                        trt.sizeDelta = UG.Vector2(205, 48)
                        t.alignment = UG.TextAnchor.MiddleCenter
                        t.fontSize = 18
                        t.resizeTextForBestFit = true
                        t.resizeTextMinSize = 12
                        t.resizeTextMaxSize = 18
                        t.text = _G.HTPS_LUCKY_DUST_RUNNING and "Đang Săn... [Dừng]" or "Auto Quay Bụi"
                        _G.HTPS_BTN_LUCKY_DUST_TXT = t
                        break
                    end
                end
                btnDustTf = cloneGo.transform
            end

            if btnDustTf then
                if _G.HTPS_BTN_LUCKY_DUST_TXT and not _G.HTPS_BTN_LUCKY_DUST_TXT:Equals(nil) and not _G.HTPS_LUCKY_DUST_RUNNING then
                    _G.HTPS_BTN_LUCKY_DUST_TXT.text = "Auto Quay Bụi"
                end
                if _G.HTPS_BOUND_LUCKY_DUST_BTN ~= btnDustTf then
                    local bc = btnDustTf:GetComponent(typeof(UG.UI.Button))
                    if bc then
                        bc.onClick:RemoveAllListeners()
                        bc.onClick:AddListener(function()
                            _G.HTPS_ToggleAutoLuckyDust()
                        end)
                    end
                    _G.HTPS_BOUND_LUCKY_DUST_BTN = btnDustTf
                end
            end
        end)
        if _G.HTPS_EnsureSuperLuckySpinButtons then
            pcall(_G.HTPS_EnsureSuperLuckySpinButtons)
        end
    end

    _G.HTPS_ToggleAutoSuperLuckySpin = function()
        if _G.HTPS_SUPER_LUCKY_YR_RUNNING then
            _G.HTPS_SUPER_LUCKY_YR_RUNNING = false
            if _G.HTPS_BTN_SUPER_LUCKY_YR_TXT and not _G.HTPS_BTN_SUPER_LUCKY_YR_TXT:Equals(nil) then
                _G.HTPS_BTN_SUPER_LUCKY_YR_TXT.text = "Auto Mảnh Vàng"
            end
        end
        if _G.HTPS_SUPER_LUCKY_SPIN_RUNNING then
            _G.HTPS_SUPER_LUCKY_SPIN_RUNNING = false
            _G.HTPS_BONUS_SUPPRESS_UNTIL = 0
            if _G.HTPS_AUTO then _G.HTPS_AUTO.suppressPopup = true end
            if _G.HTPS_BTN_SUPER_LUCKY_SPIN_TXT and not _G.HTPS_BTN_SUPER_LUCKY_SPIN_TXT:Equals(nil) then
                _G.HTPS_BTN_SUPER_LUCKY_SPIN_TXT.text = "Auto Mảnh Đỏ"
            end
            _G.HTPS_KillSummonPopups()
            return
        end

        _G.HTPS_SUPER_LUCKY_SPIN_RUNNING = true
        _G.HTPS_BONUS_SUPPRESS_UNTIL = 0
        if _G.HTPS_AUTO then _G.HTPS_AUTO.suppressPopup = true end
        if _G.HTPS_BTN_SUPER_LUCKY_SPIN_TXT and not _G.HTPS_BTN_SUPER_LUCKY_SPIN_TXT:Equals(nil) then
            _G.HTPS_BTN_SUPER_LUCKY_SPIN_TXT.text = "(+0 Mảnh) [Dừng]"
        end
        CS.Toast.ShowToast("🎯 Bắt đầu Auto Vòng Quay Siêu Cấp (Tự nạp Xu + Săn Mảnh Bảo Vật Đỏ + Tự Reset)!")

        CsCoroutine.start(function()
            local REF_FLAGS = 60
            local gc = CS.GameContext.GetIntance()
            local inv = CS.PlayerInventory.GetInstance()
            local csNet = CS.NetworkController.GetInstance()
            local urlServer = csNet and csNet.m_UrlGameServer or ""
            local totalSpins10 = 0
            local totalReset = 0
            local totalRedWon = 0
            local redAvail = 1

            local function countRedShards()
                local total = 0
                pcall(function()
                    local lstS = inv:GetType():GetField("m_LstItemShard", REF_FLAGS):GetValue(inv)
                    if lstS then
                        for i = 0, lstS.Count - 1 do
                            local s = lstS[i]
                            if s and s.m_ShardType == 3 and (tonumber(s.m_ItemKey) == 1 or tonumber(s.m_ItemKey) == 6) then
                                total = total + (tonumber(s.m_Number) or 0)
                            end
                        end
                    end
                end)
                return total
            end

            local function syncSuperWheelStatus()
                if not urlServer or urlServer == "" then return end
                local req344 = CS.pbdson.RequestData()
                req344.session = gc.m_Session
                local a344 = CS.pbdson.PbAction()
                a344.actionId = 344
                req344.actions:Add(a344)
                local d344 = _G.HTPS_PutWebRequest(urlServer .. "/i/344/" .. tostring(gc.m_UserId), _G.HTPS_SerializeProto(req344), 8)
                if d344 then
                    local r = _G.HTPS_DeserializeProto(d344, "pbdson.ResponseData,PbMethodLib")
                    if r and r.aAction then
                        for i = 0, r.aAction.Count - 1 do
                            local act = r.aAction[i]
                            if act.actionId == 344 and act.data then
                                local lcv = _G.HTPS_DeserializeProto(act.data, "pbdson.ListCommonVector,PbMethodLib")
                                if lcv and lcv.aVector and lcv.aVector.Count >= 3 then
                                    local v2 = lcv.aVector[2]
                                    if v2 and v2.aLong and v2.aLong.Count >= 1 then
                                        redAvail = tonumber(v2.aLong[0]) or 0
                                    end
                                end
                                pcall(function() csNet:ProcessPackageEvent(344, act.data) end)
                            end
                        end
                    end
                end
            end

            pcall(function() _G.HTPS_SyncServerEquipmentAndSafeGold() end)
            pcall(syncSuperWheelStatus)

            while _G.HTPS_SUPER_LUCKY_SPIN_RUNNING do
                _G.HTPS_BONUS_SUPPRESS_UNTIL = 0
                if _G.HTPS_AUTO then _G.HTPS_AUTO.suppressPopup = true end
                _G.HTPS_KillSummonPopups()

                local sls = _G.HTPS_FindObjectOfType(typeof(CS.SuperLuckySpinScene))
                if not sls or sls:Equals(nil) or not sls.gameObject.activeInHierarchy then
                    _G.HTPS_SUPER_LUCKY_SPIN_RUNNING = false
                    break
                end

                pcall(function()
                    local allPops = _G.HTPS_FindObjectsOfType(typeof(CS.BasePopup))
                    for i = 0, allPops.Length - 1 do
                        local p = allPops[i]
                        if p and p.gameObject.name:find("PopupShowBonus") then
                            UG.Object.DestroyImmediate(p.gameObject)
                        end
                    end
                    sls:GetType():GetField("m_SpinDiskActive", REF_FLAGS):SetValue(sls, true)
                    local sd = sls:GetType():GetField("m_SpinDisk", REF_FLAGS):GetValue(sls)
                    if sd and sd.m_Transform then
                        sd.m_Transform:Rotate(0, 0, -165)
                    end
                end)

                pcall(function() CS.UnityEngine.Debug.unityLogger.logEnabled = false end)
                local curChips = tonumber(inv:GetNumberItemConsumable(13)) or 0
                local curGem = tonumber(gc.m_Gem) or 0

                -- G?p 3 b?n xoay si?u c?p trong 1 g?i HTTP: m?i b?n 6 l?n x10 (60 Xu) + 1 l?n Reset (100 KC) = 180 Xu / g?i!
                local targetChips = 180
                local buyPairs = 0
                if curChips < targetChips then
                    local needChips = targetChips - curChips
                    buyPairs = math.min(90, math.ceil(needChips / 2), math.floor(math.max(0, curGem - 400) / 550))
                end

                local availChipsAfterBuy = curChips + (buyPairs * 2)
                if availChipsAfterBuy < 10 then
                    CS.Toast.ShowToast("Không đủ Kim Cương / Xu Quay Siêu Cấp để quay tiếp!")
                    _G.HTPS_SUPER_LUCKY_SPIN_RUNNING = false
                    break
                end

                local req = CS.pbdson.RequestData()
                req.session = gc.m_Session

                for b = 1, buyPairs do
                    local cv122 = CS.pbdson.CommonVector()
                    cv122.aLong:Add(1)
                    cv122.aLong:Add(0)
                    local a122 = CS.pbdson.PbAction()
                    a122.actionId = 122
                    a122.data = _G.HTPS_SerializeProto(cv122)
                    req.actions:Add(a122)

                    local cv121 = CS.pbdson.CommonVector()
                    cv121.aLong:Add(1)
                    cv121.aLong:Add(3)
                    cv121.aLong:Add(1)
                    local a121 = CS.pbdson.PbAction()
                    a121.actionId = 121
                    a121.data = _G.HTPS_SerializeProto(cv121)
                    req.actions:Add(a121)
                end

                if redAvail <= 0 then
                    local a324Init = CS.pbdson.PbAction()
                    a324Init.actionId = 324
                    req.actions:Add(a324Init)
                    totalReset = totalReset + 1
                end

                local totalSpins10InReq = math.min(18, math.floor(availChipsAfterBuy / 10))
                local spinsDone = 0
                while spinsDone < totalSpins10InReq do
                    local wheelSpins = math.min(6, totalSpins10InReq - spinsDone)
                    for s = 1, wheelSpins do
                        local cv325 = CS.pbdson.CommonVector()
                        cv325.aLong:Add(10)
                        local a325 = CS.pbdson.PbAction()
                        a325.actionId = 325
                        a325.data = _G.HTPS_SerializeProto(cv325)
                        req.actions:Add(a325)
                    end
                    spinsDone = spinsDone + wheelSpins
                    if spinsDone < totalSpins10InReq then
                        local a324 = CS.pbdson.PbAction()
                        a324.actionId = 324
                        req.actions:Add(a324)
                        totalReset = totalReset + 1
                    end
                end

                local a344 = CS.pbdson.PbAction()
                a344.actionId = 344
                req.actions:Add(a344)

                local beforeRed = countRedShards()
                local d = _G.HTPS_PutWebRequest(urlServer .. "/i/325/" .. tostring(gc.m_UserId), _G.HTPS_SerializeProto(req), 10)
                if d then
                    local r = _G.HTPS_DeserializeProto(d, "pbdson.ResponseData,PbMethodLib")
                    if r and r.aAction then
                        local last344Data = nil
                        for i = 0, r.aAction.Count - 1 do
                            local act = r.aAction[i]
                            if (act.actionId == 121 or act.actionId == 122) and act.data then
                                local cv = _G.HTPS_DeserializeProto(act.data, "pbdson.CommonVector,PbMethodLib")
                                if cv and cv.aLong then
                                    CS.BonusModel.ParseBonusReceived(cv.aLong)
                                end
                            elseif act.actionId == 324 and act.data then
                                local cv = _G.HTPS_DeserializeProto(act.data, "pbdson.CommonVector,PbMethodLib")
                                if cv and cv.aLong and cv.aLong.Count > 0 then
                                    gc.m_Gem = tonumber(cv.aLong[0]) or gc.m_Gem
                                end
                            elseif act.actionId == 325 and act.data then
                                local lcv = _G.HTPS_DeserializeProto(act.data, "pbdson.ListCommonVector,PbMethodLib")
                                if lcv and lcv.aVector and lcv.aVector.Count >= 1 then
                                    local v0 = lcv.aVector[0]
                                    if v0 and v0.aLong and v0.aLong.Count > 1 then
                                        local bonusLongs = CS.System.Collections.Generic.List(typeof(CS.System.Int64))()
                                        for j = 1, v0.aLong.Count - 1 do
                                            bonusLongs:Add(v0.aLong[j])
                                        end
                                        CS.BonusModel.ParseBonusReceived(bonusLongs)
                                    end
                                    if lcv.aVector.Count >= 2 then
                                        local v1 = lcv.aVector[1]
                                        if v1 and v1.aLong and v1.aLong.Count > 0 then
                                            CS.BonusModel.ParseBonusReceived(v1.aLong)
                                        end
                                    end
                                    totalSpins10 = totalSpins10 + 1
                                end
                            elseif act.actionId == 344 and act.data then
                                local lcv = _G.HTPS_DeserializeProto(act.data, "pbdson.ListCommonVector,PbMethodLib")
                                if lcv and lcv.aVector and lcv.aVector.Count >= 3 then
                                    local v2 = lcv.aVector[2]
                                    if v2 and v2.aLong and v2.aLong.Count >= 1 then
                                        redAvail = tonumber(v2.aLong[0]) or 0
                                    end
                                end
                                last344Data = act.data
                            end
                        end
                        if last344Data then
                            pcall(function() csNet:ProcessPackageEvent(344, last344Data) end)
                        end
                    end
                end

                local afterRed = countRedShards()
                if afterRed > beforeRed then
                    totalRedWon = totalRedWon + (afterRed - beforeRed)
                end

                if _G.HTPS_BTN_SUPER_LUCKY_SPIN_TXT and not _G.HTPS_BTN_SUPER_LUCKY_SPIN_TXT:Equals(nil) and _G.HTPS_SUPER_LUCKY_SPIN_RUNNING then
                    _G.HTPS_BTN_SUPER_LUCKY_SPIN_TXT.text = string.format("(+%d Mảnh) [Dừng]", totalRedWon)
                end

                if (gc.m_Gold % 4294967296) >= 2050000000 then
                    pcall(function() _G.HTPS_SyncServerEquipmentAndSafeGold() end)
                end

                coroutine.yield(nil)
            end

            pcall(syncSuperWheelStatus)
            pcall(function() _G.HTPS_SyncServerEquipmentAndSafeGold() end)
            if _G.HTPS_BTN_SUPER_LUCKY_SPIN_TXT and not _G.HTPS_BTN_SUPER_LUCKY_SPIN_TXT:Equals(nil) then
                _G.HTPS_BTN_SUPER_LUCKY_SPIN_TXT.text = "Auto Mảnh Đỏ"
            end
            CS.Toast.ShowToast(string.format("Đã dừng Auto Quay Siêu Cấp! (Quay %d lượt, Reset %d lần, nhận +%d Mảnh Đỏ)", totalSpins10 * 10, totalReset, totalRedWon))
        end)
    end

    _G.HTPS_ToggleAutoSuperLuckyYellowRed = function()
        if _G.HTPS_SUPER_LUCKY_SPIN_RUNNING then
            _G.HTPS_SUPER_LUCKY_SPIN_RUNNING = false
            if _G.HTPS_BTN_SUPER_LUCKY_SPIN_TXT and not _G.HTPS_BTN_SUPER_LUCKY_SPIN_TXT:Equals(nil) then
                _G.HTPS_BTN_SUPER_LUCKY_SPIN_TXT.text = "Auto Mảnh Đỏ"
            end
        end
        if _G.HTPS_SUPER_LUCKY_YR_RUNNING then
            _G.HTPS_SUPER_LUCKY_YR_RUNNING = false
            _G.HTPS_BONUS_SUPPRESS_UNTIL = 0
            if _G.HTPS_AUTO then _G.HTPS_AUTO.suppressPopup = true end
            if _G.HTPS_BTN_SUPER_LUCKY_YR_TXT and not _G.HTPS_BTN_SUPER_LUCKY_YR_TXT:Equals(nil) then
                _G.HTPS_BTN_SUPER_LUCKY_YR_TXT.text = "Auto Mảnh Vàng"
            end
            _G.HTPS_KillSummonPopups()
            return
        end

        _G.HTPS_SUPER_LUCKY_YR_RUNNING = true
        _G.HTPS_BONUS_SUPPRESS_UNTIL = 0
        if _G.HTPS_AUTO then _G.HTPS_AUTO.suppressPopup = true end
        if _G.HTPS_BTN_SUPER_LUCKY_YR_TXT and not _G.HTPS_BTN_SUPER_LUCKY_YR_TXT:Equals(nil) then
            _G.HTPS_BTN_SUPER_LUCKY_YR_TXT.text = "(+0 Mảnh) [Dừng]"
        end
        CS.Toast.ShowToast("🎯 Bắt đầu Auto Săn Mảnh Vàng & Đỏ (Tiết kiệm Xu + Tự Reset mỗi bàn)!")

        CsCoroutine.start(function()
            local REF_FLAGS = 60
            local gc = CS.GameContext.GetIntance()
            local inv = CS.PlayerInventory.GetInstance()
            local csNet = CS.NetworkController.GetInstance()
            local urlServer = csNet and csNet.m_UrlGameServer or ""
            local totalSpins10 = 0
            local totalReset = 0
            local totalYellowWon = 0
            local totalRedWon = 0
            local yellowAvail = 1
            local redAvail = 1

            local function countYellowAndRedShards()
                local yTotal, rTotal = 0, 0
                pcall(function()
                    local lstS = inv:GetType():GetField("m_LstItemShard", REF_FLAGS):GetValue(inv)
                    if lstS then
                        for i = 0, lstS.Count - 1 do
                            local s = lstS[i]
                            if s and s.m_ShardType == 3 then
                                local k = tonumber(s.m_ItemKey) or 0
                                local n = tonumber(s.m_Number) or 0
                                if k == 2 or k == 3 then yTotal = yTotal + n
                                elseif k == 1 or k == 6 then rTotal = rTotal + n end
                            end
                        end
                    end
                end)
                return yTotal, rTotal
            end

            local function syncSuperWheelStatus()
                if not urlServer or urlServer == "" then return end
                local req344 = CS.pbdson.RequestData()
                req344.session = gc.m_Session
                local a344 = CS.pbdson.PbAction()
                a344.actionId = 344
                req344.actions:Add(a344)
                local d344 = _G.HTPS_PutWebRequest(urlServer .. "/i/344/" .. tostring(gc.m_UserId), _G.HTPS_SerializeProto(req344), 8)
                if d344 then
                    local r = _G.HTPS_DeserializeProto(d344, "pbdson.ResponseData,PbMethodLib")
                    if r and r.aAction then
                        for i = 0, r.aAction.Count - 1 do
                            local act = r.aAction[i]
                            if act.actionId == 344 and act.data then
                                local lcv = _G.HTPS_DeserializeProto(act.data, "pbdson.ListCommonVector,PbMethodLib")
                                if lcv and lcv.aVector and lcv.aVector.Count >= 3 then
                                    local v2 = lcv.aVector[2]
                                    if v2 and v2.aLong then
                                        if v2.aLong.Count >= 1 then redAvail = tonumber(v2.aLong[0]) or 0 end
                                        if v2.aLong.Count >= 4 then yellowAvail = tonumber(v2.aLong[3]) or 0 end
                                    end
                                end
                                pcall(function() csNet:ProcessPackageEvent(344, act.data) end)
                            end
                        end
                    end
                end
            end

            pcall(function() _G.HTPS_SyncServerEquipmentAndSafeGold() end)
            pcall(syncSuperWheelStatus)

            while _G.HTPS_SUPER_LUCKY_YR_RUNNING do
                _G.HTPS_BONUS_SUPPRESS_UNTIL = 0
                if _G.HTPS_AUTO then _G.HTPS_AUTO.suppressPopup = true end
                _G.HTPS_KillSummonPopups()

                local sls = _G.HTPS_FindObjectOfType(typeof(CS.SuperLuckySpinScene))
                if not sls or sls:Equals(nil) or not sls.gameObject.activeInHierarchy then
                    _G.HTPS_SUPER_LUCKY_YR_RUNNING = false
                    break
                end

                pcall(function()
                    local allPops = _G.HTPS_FindObjectsOfType(typeof(CS.BasePopup))
                    for i = 0, allPops.Length - 1 do
                        local p = allPops[i]
                        if p and p.gameObject.name:find("PopupShowBonus") then
                            UG.Object.DestroyImmediate(p.gameObject)
                        end
                    end
                    sls:GetType():GetField("m_SpinDiskActive", REF_FLAGS):SetValue(sls, true)
                    local sd = sls:GetType():GetField("m_SpinDisk", REF_FLAGS):GetValue(sls)
                    if sd and sd.m_Transform then
                        sd.m_Transform:Rotate(0, 0, -165)
                    end
                end)

                pcall(function() CS.UnityEngine.Debug.unityLogger.logEnabled = false end)
                local curChips = tonumber(inv:GetNumberItemConsumable(13)) or 0
                local curGem = tonumber(gc.m_Gem) or 0

                local targetChips = 80
                local buyPairs = 0
                if curChips < targetChips then
                    local needChips = targetChips - curChips
                    buyPairs = math.min(40, math.ceil(needChips / 2), math.floor(math.max(0, curGem - 1000) / 550))
                end

                local availChipsAfterBuy = curChips + (buyPairs * 2)
                if availChipsAfterBuy < 10 then
                    CS.Toast.ShowToast("Không đủ Kim Cương / Xu Quay Siêu Cấp để quay tiếp!")
                    _G.HTPS_SUPER_LUCKY_YR_RUNNING = false
                    break
                end

                local req = CS.pbdson.RequestData()
                req.session = gc.m_Session

                for b = 1, buyPairs do
                    local cv122 = CS.pbdson.CommonVector()
                    cv122.aLong:Add(1); cv122.aLong:Add(0)
                    local a122 = CS.pbdson.PbAction()
                    a122.actionId = 122; a122.data = _G.HTPS_SerializeProto(cv122)
                    req.actions:Add(a122)

                    local cv121 = CS.pbdson.CommonVector()
                    cv121.aLong:Add(1); cv121.aLong:Add(3); cv121.aLong:Add(1)
                    local a121 = CS.pbdson.PbAction()
                    a121.actionId = 121; a121.data = _G.HTPS_SerializeProto(cv121)
                    req.actions:Add(a121)
                end

                if yellowAvail <= 0 then
                    local a324Init = CS.pbdson.PbAction()
                    a324Init.actionId = 324
                    req.actions:Add(a324Init)
                    totalReset = totalReset + 1
                end

                local totalSpins10InReq = math.min(8, math.floor(availChipsAfterBuy / 10))
                for s = 1, totalSpins10InReq do
                    local cv325 = CS.pbdson.CommonVector()
                    cv325.aLong:Add(10)
                    local a325 = CS.pbdson.PbAction()
                    a325.actionId = 325
                    a325.data = _G.HTPS_SerializeProto(cv325)
                    req.actions:Add(a325)

                    if s < totalSpins10InReq then
                        local a324 = CS.pbdson.PbAction()
                        a324.actionId = 324
                        req.actions:Add(a324)
                        totalReset = totalReset + 1
                    end
                end

                local a344 = CS.pbdson.PbAction()
                a344.actionId = 344
                req.actions:Add(a344)

                local beforeY, beforeR = countYellowAndRedShards()
                local d = _G.HTPS_PutWebRequest(urlServer .. "/i/325/" .. tostring(gc.m_UserId), _G.HTPS_SerializeProto(req), 10)
                if d then
                    local r = _G.HTPS_DeserializeProto(d, "pbdson.ResponseData,PbMethodLib")
                    if r and r.aAction then
                        local last344Data = nil
                        for i = 0, r.aAction.Count - 1 do
                            local act = r.aAction[i]
                            if (act.actionId == 121 or act.actionId == 122) and act.data then
                                local cv = _G.HTPS_DeserializeProto(act.data, "pbdson.CommonVector,PbMethodLib")
                                if cv and cv.aLong then CS.BonusModel.ParseBonusReceived(cv.aLong) end
                            elseif act.actionId == 324 and act.data then
                                local cv = _G.HTPS_DeserializeProto(act.data, "pbdson.CommonVector,PbMethodLib")
                                if cv and cv.aLong and cv.aLong.Count > 0 then
                                    gc.m_Gem = tonumber(cv.aLong[0]) or gc.m_Gem
                                end
                            elseif act.actionId == 325 and act.data then
                                local lcv = _G.HTPS_DeserializeProto(act.data, "pbdson.ListCommonVector,PbMethodLib")
                                if lcv and lcv.aVector and lcv.aVector.Count >= 1 then
                                    local v0 = lcv.aVector[0]
                                    if v0 and v0.aLong and v0.aLong.Count > 1 then
                                        local bonusLongs = CS.System.Collections.Generic.List(typeof(CS.System.Int64))()
                                        for j = 1, v0.aLong.Count - 1 do bonusLongs:Add(v0.aLong[j]) end
                                        CS.BonusModel.ParseBonusReceived(bonusLongs)
                                    end
                                    if lcv.aVector.Count >= 2 then
                                        local v1 = lcv.aVector[1]
                                        if v1 and v1.aLong and v1.aLong.Count > 0 then
                                            CS.BonusModel.ParseBonusReceived(v1.aLong)
                                        end
                                    end
                                    totalSpins10 = totalSpins10 + 1
                                end
                            elseif act.actionId == 344 and act.data then
                                local lcv = _G.HTPS_DeserializeProto(act.data, "pbdson.ListCommonVector,PbMethodLib")
                                if lcv and lcv.aVector and lcv.aVector.Count >= 3 then
                                    local v2 = lcv.aVector[2]
                                    if v2 and v2.aLong then
                                        if v2.aLong.Count >= 1 then redAvail = tonumber(v2.aLong[0]) or 0 end
                                        if v2.aLong.Count >= 4 then yellowAvail = tonumber(v2.aLong[3]) or 0 end
                                    end
                                end
                                last344Data = act.data
                            end
                        end
                        if last344Data then
                            pcall(function() csNet:ProcessPackageEvent(344, last344Data) end)
                        end
                    end
                end

                local afterY, afterR = countYellowAndRedShards()
                if afterY > beforeY then totalYellowWon = totalYellowWon + (afterY - beforeY) end
                if afterR > beforeR then totalRedWon = totalRedWon + (afterR - beforeR) end

                if _G.HTPS_BTN_SUPER_LUCKY_YR_TXT and not _G.HTPS_BTN_SUPER_LUCKY_YR_TXT:Equals(nil) and _G.HTPS_SUPER_LUCKY_YR_RUNNING then
                    _G.HTPS_BTN_SUPER_LUCKY_YR_TXT.text = string.format("(+%d Mảnh) [Dừng]", totalYellowWon)
                end

                if (gc.m_Gold % 4294967296) >= 2050000000 then
                    pcall(function() _G.HTPS_SyncServerEquipmentAndSafeGold() end)
                end

                coroutine.yield(nil)
            end

            pcall(syncSuperWheelStatus)
            pcall(function() _G.HTPS_SyncServerEquipmentAndSafeGold() end)
            if _G.HTPS_BTN_SUPER_LUCKY_YR_TXT and not _G.HTPS_BTN_SUPER_LUCKY_YR_TXT:Equals(nil) then
                _G.HTPS_BTN_SUPER_LUCKY_YR_TXT.text = "Auto Mảnh Vàng"
            end
            CS.Toast.ShowToast(string.format("Đã dừng Auto Mảnh Vàng! (Quay %d lượt, Reset %d lần, nhận +%d Mảnh Vàng)", totalSpins10 * 10, totalReset, totalYellowWon))
        end)
    end

    _G.HTPS_EnsureSuperLuckySpinButtons = function()
        pcall(function()
            local sls = _G.HTPS_FindObjectOfType(typeof(CS.SuperLuckySpinScene))
            if not sls or sls:Equals(nil) or not sls.gameObject.activeInHierarchy then return end
            local REF_FLAGS = 60
            local btnRef = sls:GetType():GetField("m_GoButtonRefresh", REF_FLAGS):GetValue(sls)
            if not btnRef then return end
            local parentTf = btnRef.transform.parent
            if not parentTf then return end

            local btnAutoTf = parentTf:Find("BtnHTPSAutoSuperLuckySpin")
            if not btnAutoTf then
                local cloneGo = GO.Instantiate(btnRef, parentTf, false)
                cloneGo.name = "BtnHTPSAutoSuperLuckySpin"
                cloneGo:SetActive(true)
                local iconGem = cloneGo.transform:Find("IconGem") or cloneGo.transform:Find("IconGemRefresh")
                if iconGem then iconGem.gameObject:SetActive(false) end
                local txtGem = cloneGo.transform:Find("TextGemRefresh")
                if txtGem then txtGem.gameObject:SetActive(false) end
                local rt = cloneGo:GetComponent(typeof(UG.RectTransform))
                rt.anchoredPosition = UG.Vector2(-118.0, 114.0)
                rt.sizeDelta = UG.Vector2(215.0, 54.0)
                local txts = cloneGo:GetComponentsInChildren(typeof(UG.UI.Text), true)
                for i = 0, txts.Length - 1 do
                    local t = txts[i]
                    if t.gameObject.name ~= "TextGemRefresh" then
                        local loc = t.gameObject:GetComponent(typeof(CS.I2.Loc.Localize))
                        if loc then UG.Object.DestroyImmediate(loc) end
                        local trt = t.gameObject:GetComponent(typeof(UG.RectTransform))
                        trt.anchoredPosition = UG.Vector2(0, 0)
                        trt.sizeDelta = UG.Vector2(205, 48)
                        t.alignment = UG.TextAnchor.MiddleCenter
                        t.fontSize = 18
                        t.text = _G.HTPS_SUPER_LUCKY_SPIN_RUNNING and "(+0 Mảnh) [Dừng]" or "Auto Mảnh Đỏ"
                        _G.HTPS_BTN_SUPER_LUCKY_SPIN_TXT = t
                        break
                    end
                end
                btnAutoTf = cloneGo.transform
            end

            if btnAutoTf then
                if _G.HTPS_BTN_SUPER_LUCKY_SPIN_TXT and not _G.HTPS_BTN_SUPER_LUCKY_SPIN_TXT:Equals(nil) and not _G.HTPS_SUPER_LUCKY_SPIN_RUNNING then
                    _G.HTPS_BTN_SUPER_LUCKY_SPIN_TXT.text = "Auto Mảnh Đỏ"
                end
                if _G.HTPS_BOUND_SUPER_LUCKY_SPIN_BTN ~= btnAutoTf then
                    local bc = btnAutoTf:GetComponent(typeof(UG.UI.Button))
                    if bc then
                        bc.onClick = UG.UI.Button.ButtonClickedEvent()
                        bc.onClick:AddListener(function()
                            _G.HTPS_ToggleAutoSuperLuckySpin()
                        end)
                    end
                    _G.HTPS_BOUND_SUPER_LUCKY_SPIN_BTN = btnAutoTf
                end
            end

            local btnYrTf = parentTf:Find("BtnHTPSAutoSuperLuckyYellowRed")
            if not btnYrTf then
                local cloneGo = GO.Instantiate(btnRef, parentTf, false)
                cloneGo.name = "BtnHTPSAutoSuperLuckyYellowRed"
                cloneGo:SetActive(true)
                local iconGem = cloneGo.transform:Find("IconGem") or cloneGo.transform:Find("IconGemRefresh")
                if iconGem then iconGem.gameObject:SetActive(false) end
                local txtGem = cloneGo.transform:Find("TextGemRefresh")
                if txtGem then txtGem.gameObject:SetActive(false) end
                local rt = cloneGo:GetComponent(typeof(UG.RectTransform))
                rt.anchoredPosition = UG.Vector2(-118.0, 174.0)
                rt.sizeDelta = UG.Vector2(215.0, 54.0)
                local txts = cloneGo:GetComponentsInChildren(typeof(UG.UI.Text), true)
                for i = 0, txts.Length - 1 do
                    local t = txts[i]
                    if t.gameObject.name ~= "TextGemRefresh" then
                        local loc = t.gameObject:GetComponent(typeof(CS.I2.Loc.Localize))
                        if loc then UG.Object.DestroyImmediate(loc) end
                        local trt = t.gameObject:GetComponent(typeof(UG.RectTransform))
                        trt.anchoredPosition = UG.Vector2(0, 0)
                        trt.sizeDelta = UG.Vector2(205, 48)
                        t.alignment = UG.TextAnchor.MiddleCenter
                        t.fontSize = 18
                        t.text = _G.HTPS_SUPER_LUCKY_YR_RUNNING and "(+0 Mảnh) [Dừng]" or "Auto Mảnh Vàng"
                        _G.HTPS_BTN_SUPER_LUCKY_YR_TXT = t
                        break
                    end
                end
                btnYrTf = cloneGo.transform
            end

            if btnYrTf then
                if _G.HTPS_BTN_SUPER_LUCKY_YR_TXT and not _G.HTPS_BTN_SUPER_LUCKY_YR_TXT:Equals(nil) and not _G.HTPS_SUPER_LUCKY_YR_RUNNING then
                    _G.HTPS_BTN_SUPER_LUCKY_YR_TXT.text = "Auto Mảnh Vàng"
                end
                if _G.HTPS_BOUND_SUPER_LUCKY_YR_BTN ~= btnYrTf then
                    local bc = btnYrTf:GetComponent(typeof(UG.UI.Button))
                    if bc then
                        bc.onClick = UG.UI.Button.ButtonClickedEvent()
                        bc.onClick:AddListener(function()
                            _G.HTPS_ToggleAutoSuperLuckyYellowRed()
                        end)
                    end
                    _G.HTPS_BOUND_SUPER_LUCKY_YR_BTN = btnYrTf
                end
            end
        end)
    end

    
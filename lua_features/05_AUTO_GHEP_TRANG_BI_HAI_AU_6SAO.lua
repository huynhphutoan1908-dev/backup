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
-- TÍNH NĂNG: Tự Động Ghép Trang Bị Trắng/Xanh/Tím Lên Bộ Hải Âu 6 Sao (Action 252, Gộp 1.000 Món/Lệnh)
-- TRÍCH XUẤT TỪ NGUYENVINHMOD.DLL BẰNG REA ENGINE
-- =====================================================================

-- ==================== AUTO GHÉP TRANG BỊ LÊN DẦN TỚI BỘ HẢI ÂU 6★ (ForgeScene) ====================
    _G.HTPS_ToggleAutoForgeAll = function()
        if _G.HTPS_FORGE_RUNNING then
            _G.HTPS_FORGE_RUNNING = false
            if _G.HTPS_BTN_FORGE_TXT and not _G.HTPS_BTN_FORGE_TXT:Equals(nil) then
                _G.HTPS_BTN_FORGE_TXT.text = "Auto Ghép Lên 6★"
            end
            CS.Toast.ShowToast("Đã dừng Auto Ghép Trang Bị!")
            return
        end
        _G.HTPS_FORGE_RUNNING = true
        _G.HTPS_BONUS_SUPPRESS_UNTIL = 0
        if _G.HTPS_AUTO then _G.HTPS_AUTO.suppressPopup = true end
        if _G.HTPS_BTN_FORGE_TXT and not _G.HTPS_BTN_FORGE_TXT:Equals(nil) then
            _G.HTPS_BTN_FORGE_TXT.text = "Đang Ghép... [Dừng]"
        end
        CS.Toast.ShowToast("🔨 Đang ghép toàn bộ trang bị lên thẳng 6★ Hải Âu (Không hiện Popup)...")

        CsCoroutine.start(function()
            local REF_FLAGS = 60
            local totalForged = 0
            local stepsForged = 0
            local stopErr = nil

            local ok, err = pcall(function()
                _G.HTPS_SyncServerEquipmentAndSafeGold()

                local gc = CS.GameContext.GetIntance()
                local csNet = CS.NetworkController.GetInstance()
                local inv = CS.PlayerInventory.GetInstance()
                local db = CS.DbManager.GetInstance()
                if not gc or not csNet or not inv or not db then return end
                local urlServer = csNet.m_UrlGameServer
                if not urlServer or urlServer == "" then return end

                local fs = _G.HTPS_FindObjectOfType(typeof(CS.ForgeScene))
                if not fs or fs:Equals(nil) then return end
                local curTabField = fs:GetType():GetField("m_CurrentButtonTab", REF_FLAGS)
                local dbLst = db:GetType():GetField("m_ListItemEquipment", REF_FLAGS):GetValue(db)
                local eqMap = {}
                for i = 0, dbLst.Count - 1 do
                    local e = dbLst[i]
                    eqMap[e.m_ItemKey] = e
                end

                local function syncDbEquipmentCounts()
                    pcall(function()
                        for i = 0, dbLst.Count - 1 do
                            local e = dbLst[i]
                            if e then
                                e.m_Number = inv:CountItemEquipment(e.m_ItemKey)
                            end
                        end
                    end)
                end

                local branches = {
                    [1] = {4, 5, 6, 7, 8, 9, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20},
                    [2] = {25, 26, 27, 28, 29, 30, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41},
                    [3] = {46, 47, 48, 49, 50, 51, 53, 54, 55, 56, 57, 58, 59, 60, 61, 62},
                    [4] = {67, 68, 69, 70, 71, 72, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83},
                }

                local startTab = curTabField:GetValue(fs)
                if not startTab or startTab < 1 or startTab > 4 then startTab = 1 end
                local tabOrder = { startTab }
                for t = 1, 4 do
                    if t ~= startTab then table.insert(tabOrder, t) end
                end

                for _, tabId in ipairs(tabOrder) do
                    if not _G.HTPS_FORGE_RUNNING or stopErr then break end
                    local chain = branches[tabId]
                    local switchedTab = false

                    -- Lặp vét sạch toàn bộ các bậc trong nhánh (mỗi lệnh Action 252 tối đa 100 món, đóng gói tối đa 10 lệnh = 1.000 món/request)
                    local passGuard = 0
                    while _G.HTPS_FORGE_RUNNING and not stopErr and passGuard < 5 do
                        passGuard = passGuard + 1
                        local forgedInPass = 0

                        for _, outKey in ipairs(chain) do
                            if not _G.HTPS_FORGE_RUNNING or stopErr then break end
                            local outEq = eqMap[outKey]
                            if outEq and outEq.m_MaterialItemKey > 0 then
                                local matKey = outEq.m_MaterialItemKey
                                local matNum = outEq.m_MaterialNumber > 0 and outEq.m_MaterialNumber or 3
                                local costPerItem = tonumber(outEq.m_CostForge) or 0

                                local chunkGuard = 0
                                while _G.HTPS_FORGE_RUNNING and not stopErr and chunkGuard < 50 do
                                    chunkGuard = chunkGuard + 1
                                    local have = inv:CountItemEquipment(matKey)
                                    local numForge = math.floor(have / matNum)
                                    if numForge <= 0 then break end

                                    if (gc.m_Gold % 4294967296) >= 2050000000 then
                                        pcall(function() _G.HTPS_SyncServerEquipmentAndSafeGold() end)
                                    end

                                    if costPerItem > 0 then
                                        local maxByGold = math.floor(math.max(0, tonumber(gc.m_Gold) or 0) / costPerItem)
                                        if maxByGold <= 0 then
                                            stopErr = "Không đủ Vàng để ghép tiếp!"
                                            break
                                        end
                                        numForge = math.min(numForge, maxByGold)
                                    end

                                    if not switchedTab and fs and not fs:Equals(nil) and fs.gameObject.activeInHierarchy then
                                        pcall(function() fs:OnTabActive(tabId, tabId) end)
                                        switchedTab = true
                                    end

                                    if _G.HTPS_BTN_FORGE_TXT and not _G.HTPS_BTN_FORGE_TXT:Equals(nil) then
                                        _G.HTPS_BTN_FORGE_TXT.text = string.format("Ghép +%d %s [Dừng]", numForge, tostring(outEq.m_ItemName))
                                    end

                                    local req = CS.pbdson.RequestData()
                                    req.session = gc.m_Session
                                    local rem = math.min(numForge, 1000)
                                    while rem > 0 do
                                        local chunk = math.min(100, rem)
                                        local cv = CS.pbdson.CommonVector()
                                        cv.aLong:Add(outKey)
                                        cv.aLong:Add(chunk)
                                        local a252 = CS.pbdson.PbAction()
                                        a252.actionId = 252
                                        a252.data = _G.HTPS_SerializeProto(cv)
                                        req.actions:Add(a252)
                                        rem = rem - chunk
                                    end

                                    _G.HTPS_BONUS_SUPPRESS_UNTIL = 0
                                    if _G.HTPS_AUTO then _G.HTPS_AUTO.suppressPopup = true end
                                    _G.HTPS_KillSummonPopups()

                                    local d = _G.HTPS_PutWebRequest(urlServer .. "/i/252/" .. tostring(gc.m_UserId), _G.HTPS_SerializeProto(req), 10)
                                    local gotInReq = 0
                                    if d then
                                        local r = _G.HTPS_DeserializeProto(d, "pbdson.ResponseData,PbMethodLib")
                                        if r and r.aAction then
                                            for i = 0, r.aAction.Count - 1 do
                                                local act = r.aAction[i]
                                                if act.actionId == 252 and act.data then
                                                    local cvR = _G.HTPS_DeserializeProto(act.data, "pbdson.CommonVector,PbMethodLib")
                                                    if cvR and cvR.aLong then
                                                        CS.BonusModel.ParseBonusReceived(cvR.aLong)
                                                        local forgedAmt = (cvR.aLong.Count >= 8) and (tonumber(cvR.aLong[7]) or 0) or 1
                                                        gotInReq = gotInReq + forgedAmt
                                                        forgedInPass = forgedInPass + forgedAmt
                                                        totalForged = totalForged + forgedAmt
                                                    end
                                                elseif act.actionId == 1 and act.data then
                                                    local cvE = _G.HTPS_DeserializeProto(act.data, "pbdson.CommonVector,PbMethodLib")
                                                    if cvE and cvE.aString and cvE.aString.Count > 0 then
                                                        stopErr = tostring(cvE.aString[0])
                                                    end
                                                end
                                            end
                                        end
                                    else
                                        stopErr = "Lỗi kết nối máy chủ khi rèn!"
                                    end

                                    if gotInReq > 0 then
                                        stepsForged = stepsForged + 1
                                    end
                                    _G.HTPS_KillSummonPopups()
                                    coroutine.yield(nil)

                                    if gotInReq <= 0 or stopErr then
                                        break
                                    end
                                end
                            end
                        end

                        if forgedInPass <= 0 then
                            break
                        end
                    end

                    if switchedTab and fs and not fs:Equals(nil) and fs.gameObject.activeInHierarchy then
                        syncDbEquipmentCounts()
                        pcall(function() fs:OnTabActive(tabId, tabId) end)
                    end
                end

                syncDbEquipmentCounts()
                if fs and not fs:Equals(nil) and fs.gameObject.activeInHierarchy then
                    pcall(function() fs:OnTabActive(startTab, startTab) end)
                end
            end)

            _G.HTPS_FORGE_RUNNING = false
            _G.HTPS_BONUS_SUPPRESS_UNTIL = 0
            if _G.HTPS_AUTO then _G.HTPS_AUTO.suppressPopup = true end
            _G.HTPS_KillSummonPopups()
            if _G.HTPS_BTN_FORGE_TXT and not _G.HTPS_BTN_FORGE_TXT:Equals(nil) then
                _G.HTPS_BTN_FORGE_TXT.text = "Auto Ghép Lên 6★"
            end
            if not ok then
                CS.Toast.ShowToast("⚠️ Lỗi Auto Ghép: " .. tostring(err))
            elseif totalForged > 0 then
                local extra = stopErr and (" (" .. stopErr .. ")") or ""
                CS.Toast.ShowToast(string.format("✅ Đã ghép hoàn tất %d trang bị (%d đợt) lên thẳng 6★ Hải Âu!%s", totalForged, stepsForged, extra))
            elseif stopErr then
                CS.Toast.ShowToast("⚠️ Auto Ghép: " .. tostring(stopErr))
            else
                CS.Toast.ShowToast("Hiện chưa có bậc trang bị nào đủ 3 phôi để ghép lên tiếp!")
            end
        end)
    end

    _G.HTPS_EnsureForgeButtons = function()
        pcall(function()
            local fs = _G.HTPS_FindObjectOfType(typeof(CS.ForgeScene))
            if not fs or not fs.gameObject.activeInHierarchy then return end
            local REF_FLAGS = 60
            local btnForgeGo = fs:GetType():GetField("m_GoButtonForge", REF_FLAGS):GetValue(fs)
            if not btnForgeGo then return end
            local bfTf = btnForgeGo.transform.parent
            if not bfTf then return end

            local btnAutoTf = bfTf:Find("BtnHTPSAutoForgeAll")
            if not btnAutoTf then
                -- Dịch nút Rèn gốc sang trái và đặt nút [Auto Ghép Lên 6★] bên phải
                local origRt = btnForgeGo:GetComponent(typeof(UG.RectTransform))
                origRt.anchoredPosition = UG.Vector2(-115.0, -175.4)
                origRt.sizeDelta = UG.Vector2(165.0, 58.0)

                local cloneGo = GO.Instantiate(btnForgeGo, bfTf, false)
                cloneGo.name = "BtnHTPSAutoForgeAll"
                cloneGo:SetActive(true)
                local rt = cloneGo:GetComponent(typeof(UG.RectTransform))
                rt.anchoredPosition = UG.Vector2(105.0, -175.4)
                rt.sizeDelta = UG.Vector2(215.0, 58.0)

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
                    txt.text = _G.HTPS_FORGE_RUNNING and "Đang Ghép... [Dừng]" or "Auto Ghép Lên 6★"
                    _G.HTPS_BTN_FORGE_TXT = txt
                end
                btnAutoTf = cloneGo.transform
            end

            if btnAutoTf and _G.HTPS_BOUND_FORGE_BTN ~= btnAutoTf then
                local bc = btnAutoTf:GetComponent(typeof(UG.UI.Button))
                if bc then
                    bc.onClick = UG.UI.Button.ButtonClickedEvent()
                    bc.onClick:AddListener(function()
                        _G.HTPS_ToggleAutoForgeAll()
                    end)
                end
                _G.HTPS_BOUND_FORGE_BTN = btnAutoTf
            end
        end)
    end


    -- =================================================================
    -- AUTO ĐẤU TRƯỜNG THÔNG MINH (CHẤM ĐIỂM TỈ LỆ THẮNG, TỰ NÉ ĐỘI MẠNH, TỰ GẮN PET, THỐNG KÊ THẮNG/THUA)
    -- =================================================================
    _G.HTPS_ARENA_RUNNING = _G.HTPS_ARENA_RUNNING or false
    
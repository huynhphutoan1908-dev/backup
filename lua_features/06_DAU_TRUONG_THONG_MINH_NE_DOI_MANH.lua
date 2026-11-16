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
-- TÍNH NĂNG: Tự Động Đánh Đấu Trường (Action 334+333), Chấm Điểm Né Đội Mạnh, Tự Gán Pet Mạnh Nhất
-- TRÍCH XUẤT TỪ NGUYENVINHMOD.DLL BẰNG REA ENGINE
-- =====================================================================

-- ==================== AUTO ĐÁNH ĐẤU TRƯỜNG THÔNG MINH (CHỌN TỈ LỆ THẮNG CAO + TỰ RESET + KHÔNG VÀO TRẬN) ====================
    _G.HTPS_ARENA_RUNNING = false
    _G.HTPS_ARENA_MAXED_RIVALS = _G.HTPS_ARENA_MAXED_RIVALS or {}
    _G.HTPS_ARENA_LOSE_RIVALS = _G.HTPS_ARENA_LOSE_RIVALS or {}
    _G.HTPS_ARENA_STATS = _G.HTPS_ARENA_STATS or { win = 0, lose = 0, pointDiff = 0, resetCount = 0 }

    _G.HTPS_PutWebRequest = function(url, payloadBytes, timeoutSec)
        local www = CS.UnityEngine.Networking.UnityWebRequest.Put(url, payloadBytes)
        www.timeout = timeoutSec or 8
        coroutine.yield(www:SendWebRequest())
        local data = nil
        local okNet = (not www.isNetworkError and not www.isHttpError)
        if okNet and www.downloadHandler and www.downloadHandler.data then
            data = www.downloadHandler.data
        end
        local responseCode = tonumber(www.responseCode) or 0
        pcall(function() www:Dispose() end)
        return data, okNet, responseCode
    end

    _G.HTPS_UpdateArenaStatsUI = function(extraNote)
        pcall(function()
            local st = _G.HTPS_ARENA_STATS or { win = 0, lose = 0, pointDiff = 0, resetCount = 0 }
            local total = st.win + st.lose
            local rate = total > 0 and math.floor((st.win * 100) / total) or 0
            local sign = st.pointDiff >= 0 and "+" or ""

            if _G.HTPS_BTN_ARENA_TXT and not _G.HTPS_BTN_ARENA_TXT:Equals(nil) then
                if _G.HTPS_ARENA_RUNNING then
                    _G.HTPS_BTN_ARENA_TXT.text = string.format("Đang Đánh [Dừng]\n<size=13>%dT - %dB (%d%%)</size>", st.win, st.lose, rate)
                else
                    _G.HTPS_BTN_ARENA_TXT.text = "Auto Đấu Trường"
                end
            end

            if _G.HTPS_TXT_ARENA_STATS and not _G.HTPS_TXT_ARENA_STATS:Equals(nil) then
                local baseStr = string.format("Thắng: <color=#00FF66>%d</color> | Thua: <color=#FF5555>%d</color> (%d%%) | Điểm: <color=#FFE066>%s%d</color>", st.win, st.lose, rate, sign, st.pointDiff)
                if extraNote and extraNote ~= "" then
                    baseStr = baseStr .. "\n<size=13><color=#AADDFF>" .. extraNote .. "</color></size>"
                end
                _G.HTPS_TXT_ARENA_STATS.text = baseStr
            end
        end)
    end

    _G.HTPS_StopAutoArena = function()
        _G.HTPS_ARENA_RUNNING = false
        _G.HTPS_UpdateArenaStatsUI("Đã dừng Auto")
        return "STOPPED"
    end

    _G.HTPS_ToggleAutoArena = function()
        if _G.HTPS_ARENA_RUNNING then
            _G.HTPS_ARENA_RUNNING = false
            local st = _G.HTPS_ARENA_STATS or { win = 0, lose = 0, pointDiff = 0 }
            _G.HTPS_UpdateArenaStatsUI("Đã dừng Auto")
            CS.Toast.ShowToast(string.format("Đã dừng Auto Đấu Trường! (Thắng: %d | Thua: %d | Điểm: %+d)", st.win, st.lose, st.pointDiff))
            return
        end

        local cc = CS.CrystalCrownScene.Instance
        if not cc or not cc.gameObject.activeInHierarchy then
            CS.Toast.ShowToast("Hãy mở màn hình Đấu Trường trước!")
            return
        end

        _G.HTPS_ARENA_RUNNING = true
        _G.HTPS_ARENA_LOSE_RIVALS = {}
        _G.HTPS_ARENA_STATS = { win = 0, lose = 0, pointDiff = 0, resetCount = 0 }
        _G.HTPS_BONUS_SUPPRESS_UNTIL = 0
        if _G.HTPS_AUTO then _G.HTPS_AUTO.suppressPopup = true end
        _G.HTPS_UpdateArenaStatsUI("Đang tối ưu E-Skill, gắn Pet & lọc đối thủ...")
        CS.Toast.ShowToast("Bắt đầu Auto Đấu Trường Thông Minh (Tự bật E-Skill + Gắn Pet + Lọc Tỉ Lệ Thắng Cao)!")

        CsCoroutine.start(function()
            local REF_FLAGS = 60
            local gc = CS.GameContext.GetIntance()
            local nc = CS.NetworkController.GetInstance()
            local inv = CS.PlayerInventory.GetInstance()
            local startPoint = nil
            local myPower = 17000000
            local myLv350Count = 0

            pcall(function()
                myPower = cc:GetType():GetField("m_PlayerPower", REF_FLAGS):GetValue(cc) or 17000000
                local pi = cc:GetType():GetField("m_PanelInfo", REF_FLAGS):GetValue(cc)
                if pi then
                    local txtPoint = pi:GetType():GetField("m_TextPoint", REF_FLAGS):GetValue(pi)
                    if txtPoint then startPoint = tonumber(txtPoint.text) end
                end
            end)

            -- Đóng các popup chọn đối thủ / đội hình nếu đang mở
            pcall(function()
                local par = _G.HTPS_FindObjectOfType(typeof(CS.PopupArenaRival))
                if par then UG.Object.DestroyImmediate(par.gameObject) end
                local pfGo = GO.Find("PopupFormation(Clone)")
                if pfGo then UG.Object.DestroyImmediate(pfGo) end
            end)

            -- Lấy đội hình chiến đấu + Tự động gắn Pet mạnh nhất + Tự động bật đủ 5 kỹ năng E1-E5 nếu tướng 15 sao đang quên bật
            local lstHero = nil
            local bestPetId = -1
            pcall(function()
                local lstP = inv:GetType():GetField("m_LstPetModel", REF_FLAGS):GetValue(inv)
                local maxPetLv = -1
                if lstP then
                    for i = 0, lstP.Count - 1 do
                        local pm = lstP[i]
                        if pm and pm.m_Level and pm.m_Level > maxPetLv then
                            maxPetLv = pm.m_Level
                            bestPetId = pm.m_PetId
                        end
                    end
                end
                local df = cc:GetType():GetField("m_DefensiveFormation", REF_FLAGS):GetValue(cc)
                if df and df:CountNumberHero() > 0 then
                    lstHero = df:ToListServerHeroId1LineUp()
                    local defaultESkill = { 2, 2, 1, 2, 2 }
                    for i = 0, lstHero.Count - 1 do
                        local hid = lstHero[i]
                        if hid and hid > 0 and i < 6 then
                            local hm = inv:GetHeroModelById(hid)
                            if hm then
                                if hm.m_Level and hm.m_Level >= 350 then
                                    myLv350Count = myLv350Count + 1
                                end
                                if hm.m_Star and hm.m_Star >= 15 then
                                    local es = hm:GetType():GetField("m_ListIndexESkillActive", REF_FLAGS):GetValue(hm)
                                    if es then
                                        for g = 0, es.Count - 1 do
                                            if es[g] == 0 then
                                                local pick = defaultESkill[g + 1] or 1
                                                gc.dataSender:HeroPickESkill(hid, g, pick)
                                                es[g] = pick
                                                if cc then cc:HideLoading() end
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end)

            if not lstHero or lstHero.Count == 0 then
                _G.HTPS_ARENA_RUNNING = false
                _G.HTPS_UpdateArenaStatsUI("Chưa xếp đội hình")
                CS.Toast.ShowToast("Chưa có đội hình! Hãy bấm Phòng Thủ hoặc Chiến Đấu xếp đội 1 lần.")
                return
            end

            -- Hàm phân tích đội hình đối thủ để tính Điểm Nguy Hiểm Thực Tế & Tỉ Lệ Thắng Dự Kiến (%)
            local STALL_HEROES = { [524] = true, [539] = true, [551] = true, [557] = true, [647] = true }
            local META_BURST = { [611] = true, [629] = true, [638] = true, [608] = true, [542] = true }
            local myEffectiveScore = myPower + (myLv350Count * 3000000)

            local function evaluateRival(r)
                if not r or not r.m_UserId or r.m_UserId <= 0 then
                    return 999999999, 0, 0
                end
                local rPower = r.m_Power or 0
                local r350 = 0
                local r330 = 0
                local rStall = 0
                local rBurst = 0
                if r.m_ListHeroModel then
                    for h = 0, r.m_ListHeroModel.Count - 1 do
                        local hm = r.m_ListHeroModel[h]
                        if hm then
                            local lv = hm.m_Level or 1
                            local hk = hm.m_HeroKey or 0
                            if lv >= 350 then
                                r350 = r350 + 1
                            elseif lv >= 330 then
                                r330 = r330 + 1
                            end
                            if STALL_HEROES[hk] then rStall = rStall + 1 end
                            if META_BURST[hk] then rBurst = rBurst + 1 end
                        end
                    end
                end
                -- Chống bẫy Lực Chiến ảo (khi đối thủ nâng tướng lên lv350 sau khi lưu đội hình phòng thủ)
                local minRealPower = (r350 * 3100000) + (r330 * 2050000)
                local effBasePower = math.max(rPower, minRealPower)
                local dangerScore = effBasePower + (r350 * 2600000) + (rStall * 650000) + (rBurst * 450000)
                if r350 >= 2 and rStall >= 2 then
                    dangerScore = dangerScore + 1800000
                end
                local ratio = myEffectiveScore / math.max(1, dangerScore)
                local winProb = math.floor(math.min(99, math.max(15, (ratio - 0.52) * 135)))
                return dangerScore, winProb, r350
            end

            local currentRivals = {}
            local consecutiveEmptyResets = 0

            local function fetchNewRivalsFromServer()
                local listOut = {}
                local req333 = CS.pbdson.RequestData()
                req333.session = gc.m_Session
                local act333 = CS.pbdson.PbAction()
                act333.actionId = 333
                req333.actions:Add(act333)
                local data333, okNet = _G.HTPS_PutWebRequest(nc.m_UrlGameServer .. "/i/333/" .. tostring(gc.m_UserId), _G.HTPS_SerializeProto(req333), 8)
                if okNet and data333 then
                    pcall(function()
                        local resp333 = _G.HTPS_DeserializeProto(data333, "pbdson.ResponseData,PbMethodLib")
                        if resp333 and resp333.aAction then
                            for i = 0, resp333.aAction.Count - 1 do
                                local a = resp333.aAction[i]
                                if a.actionId == 333 and a.data then
                                    local pbLst = _G.HTPS_DeserializeProto(a.data, "pbdson.PbListUser,PbMethodLib")
                                    if pbLst and pbLst.aUser then
                                        for u = 0, pbLst.aUser.Count - 1 do
                                            local ap = CS.ArenaPlayer()
                                            ap:ImportFromPbUser(pbLst.aUser[u])
                                            if not _G.HTPS_ARENA_MAXED_RIVALS[ap.m_UserId] then
                                                table.insert(listOut, ap)
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end)
                end
                _G.HTPS_ARENA_STATS.resetCount = (_G.HTPS_ARENA_STATS.resetCount or 0) + 1
                return listOut
            end

            while _G.HTPS_ARENA_RUNNING do
                cc = CS.CrystalCrownScene.Instance
                if not cc or not cc.gameObject.activeInHierarchy then
                    _G.HTPS_ARENA_RUNNING = false
                    break
                end

                _G.HTPS_BONUS_SUPPRESS_UNTIL = 0
                if _G.HTPS_AUTO then _G.HTPS_AUTO.suppressPopup = true end
                _G.HTPS_KillSummonPopups()

                pcall(function()
                    local par = _G.HTPS_FindObjectOfType(typeof(CS.PopupArenaRival))
                    if par then UG.Object.DestroyImmediate(par.gameObject) end
                end)

                local ticketCost = 1
                pcall(function()
                    ticketCost = cc:GetType():GetField("m_TicketPerBattle", REF_FLAGS):GetValue(cc)
                    if not ticketCost or ticketCost < 1 then ticketCost = 1 end
                end)

                if gc.m_ArenaTicket < ticketCost then
                    if gc.m_Gem >= 200 then
                        gc.dataSender:CrystalBuyTicket(10)
                        cc:HideLoading()
                        gc.m_ArenaTicket = gc.m_ArenaTicket + 10
                        coroutine.yield(UG.WaitForSeconds(0.25))
                    else
                        CS.Toast.ShowToast("Đã hết Vé Đấu Trường!")
                        _G.HTPS_ARENA_RUNNING = false
                        break
                    end
                end

                local validRivals = {}
                for _, r in ipairs(currentRivals) do
                    if r and r.m_UserId and r.m_UserId > 0 and not _G.HTPS_ARENA_MAXED_RIVALS[r.m_UserId] then
                        table.insert(validRivals, r)
                    end
                end
                currentRivals = validRivals

                if #currentRivals == 0 then
                    _G.HTPS_UpdateArenaStatsUI("Đang Reset tìm danh sách đối thủ mới...")
                    currentRivals = fetchNewRivalsFromServer()
                    if #currentRivals == 0 then
                        consecutiveEmptyResets = consecutiveEmptyResets + 1
                        if consecutiveEmptyResets >= 5 then
                            CS.Toast.ShowToast("Tất cả đối thủ ở mốc điểm hiện tại đều đã chạm giới hạn 3 lần/ngày!")
                            _G.HTPS_UpdateArenaStatsUI("Các đối thủ ở mốc điểm này đã hết lượt đánh hôm nay (3/3)!")
                            _G.HTPS_ARENA_RUNNING = false
                            break
                        end
                        coroutine.yield(UG.WaitForSeconds(0.15))
                    else
                        consecutiveEmptyResets = 0
                    end
                end

                if #currentRivals > 0 then
                    -- Bước 1: Ưu tiên chọn đối thủ CHƯA THUA LẦN NÀO và có Tỉ Lệ Thắng Cao Nhất (Điểm Nguy Hiểm thấp nhất)
                    local bestRival = nil
                    local bestIdx = nil
                    local bestDanger = nil
                    local bestWinProb = 0

                    for idx, r in ipairs(currentRivals) do
                        if r and r.m_UserId and r.m_UserId > 0 and not _G.HTPS_ARENA_MAXED_RIVALS[r.m_UserId] and not _G.HTPS_ARENA_LOSE_RIVALS[r.m_UserId] then
                            local danger, winProb, r350 = evaluateRival(r)
                            local isTooStrong = (r.m_Power > myPower * 1.03) or (r350 >= myLv350Count + 3) or (winProb < 58)
                            if not isTooStrong then
                                if not bestDanger or danger < bestDanger then
                                    bestDanger = danger
                                    bestRival = r
                                    bestIdx = idx
                                    bestWinProb = winProb
                                end
                            end
                        end
                    end

                    -- Bước 2: Nếu cả 3 đối thủ đều hơi cứng hoặc đã thua -> Thử Reset tối đa 2 lần xem Server có đổi đối thủ mềm hơn không
                    if not bestRival then
                        local prevIds = {}
                        for _, r in ipairs(currentRivals) do
                            if r and r.m_UserId then prevIds[r.m_UserId] = true end
                        end
                        for rst = 1, 2 do
                            _G.HTPS_UpdateArenaStatsUI(string.format("Đối thủ rủi ro cao -> Đang Reset tìm đối thủ mềm hơn (Lần %d)...", rst))
                            local refreshed = fetchNewRivalsFromServer()
                            local sameList = true
                            for idx, r in ipairs(refreshed) do
                                if r and r.m_UserId and r.m_UserId > 0 then
                                    if not prevIds[r.m_UserId] then sameList = false end
                                    if not _G.HTPS_ARENA_MAXED_RIVALS[r.m_UserId] and not _G.HTPS_ARENA_LOSE_RIVALS[r.m_UserId] then
                                        local danger, winProb, r350 = evaluateRival(r)
                                        local isTooStrong = (r.m_Power > myPower * 1.03) or (r350 >= myLv350Count + 3) or (winProb < 58)
                                        if not isTooStrong then
                                            if not bestDanger or danger < bestDanger then
                                                bestDanger = danger
                                                bestRival = r
                                                bestIdx = idx
                                                bestWinProb = winProb
                                            end
                                        end
                                    end
                                end
                            end
                            if #refreshed > 0 then
                                currentRivals = refreshed
                            end
                            if bestRival or sameList then
                                break
                            end
                        end
                    end

                    -- Bước 3A: Nếu Reset vẫn không ra đối thủ tỉ lệ thắng >= 58%, ưu tiên chọn đối thủ CHƯA THUA để đánh 1 trận đổi mốc điểm
                    local isBreakoutMatch = false
                    if not bestRival then
                        for idx, r in ipairs(currentRivals) do
                            if r and r.m_UserId and r.m_UserId > 0 and not _G.HTPS_ARENA_MAXED_RIVALS[r.m_UserId] and not _G.HTPS_ARENA_LOSE_RIVALS[r.m_UserId] then
                                local danger, winProb = evaluateRival(r)
                                if not bestDanger or danger < bestDanger then
                                    bestDanger = danger
                                    bestRival = r
                                    bestIdx = idx
                                    bestWinProb = winProb
                                    isBreakoutMatch = true
                                end
                            end
                        end
                    end

                    -- Bước 3B: Nếu cả 3 đối thủ ở mốc điểm này đều từng thắng mình (Reset không đổi được danh sách),
                    -- BẮT BUỘC đánh 1 trận với người mềm nhất trong 3 người để đổi mốc điểm (giúp Server làm mới hoàn toàn 3 đối thủ khác!)
                    if not bestRival then
                        for idx, r in ipairs(currentRivals) do
                            if r and r.m_UserId and r.m_UserId > 0 and not _G.HTPS_ARENA_MAXED_RIVALS[r.m_UserId] then
                                local danger, winProb = evaluateRival(r)
                                if not bestDanger or danger < bestDanger then
                                    bestDanger = danger
                                    bestRival = r
                                    bestIdx = idx
                                    bestWinProb = winProb
                                    isBreakoutMatch = true
                                end
                            end
                        end
                    end

                    if not bestRival then
                        CS.Toast.ShowToast("Cả 3 đối thủ ở mốc điểm này đều đã chạm giới hạn 3/3 lượt hôm nay!")
                        _G.HTPS_UpdateArenaStatsUI("Đã dừng: 3 đối thủ ở mốc điểm này đã hết 3/3 lượt đánh hôm nay")
                        _G.HTPS_ARENA_RUNNING = false
                        break
                    else
                        if isBreakoutMatch then
                            _G.HTPS_UpdateArenaStatsUI(string.format("Đánh 1 trận đổi mốc điểm để Reset DS: %s (LC:%.1fM)...", tostring(bestRival.m_Playername), (bestRival.m_Power or 0) / 1000000.0))
                        end
                        -- Gửi gói gộp: Action 334 (Đánh đối thủ kèm Pet mạnh nhất) + Action 333 (Tìm danh sách mới)
                        local cv = CS.pbdson.CommonVector()
                        cv.aLong:Add(bestRival.m_UserId)
                        for i = 0, lstHero.Count - 1 do
                            local hid = lstHero[i]
                            if i == 6 and hid <= 0 and bestPetId > 0 then
                                hid = bestPetId
                            end
                            if hid == 0 then hid = -1 end
                            cv.aLong:Add(hid)
                        end
                        local act334 = CS.pbdson.PbAction()
                        act334.actionId = 334
                        act334.data = _G.HTPS_SerializeProto(cv)

                        local actNext333 = CS.pbdson.PbAction()
                        actNext333.actionId = 333

                        local req = CS.pbdson.RequestData()
                        req.session = gc.m_Session
                        req.actions:Add(act334)
                        req.actions:Add(actNext333)

                        local data334, okNet = _G.HTPS_PutWebRequest(nc.m_UrlGameServer .. "/i/334/" .. tostring(gc.m_UserId), _G.HTPS_SerializeProto(req), 8)
                        local gotBattle334 = false
                        local gotLimitErr = false
                        local nextRivals = {}

                        if okNet and data334 then
                            pcall(function()
                                local resp = _G.HTPS_DeserializeProto(data334, "pbdson.ResponseData,PbMethodLib")
                                if resp and resp.aAction then
                                    for i = 0, resp.aAction.Count - 1 do
                                        local a = resp.aAction[i]
                                        if a.actionId == 334 and a.data then
                                            gotBattle334 = true
                                            local pbRes = _G.HTPS_DeserializeProto(a.data, "pbdson.PbListBattleResult,PbMethodLib")
                                            if pbRes then
                                                local lbd = CS.ListBattleData.Parse(pbRes, true)
                                                local isWin = (lbd.m_Team1Score > lbd.m_Team2Score)
                                                if isWin then
                                                    _G.HTPS_ARENA_STATS.win = _G.HTPS_ARENA_STATS.win + 1
                                                else
                                                    _G.HTPS_ARENA_STATS.lose = _G.HTPS_ARENA_STATS.lose + 1
                                                    -- Khóa ngay đối thủ vừa thắng mình vào danh sách Né, KHÔNG đánh lại người này lần 2!
                                                    _G.HTPS_ARENA_LOSE_RIVALS[bestRival.m_UserId] = true
                                                end
                                                gc.m_ArenaTicket = math.max(0, gc.m_ArenaTicket - ticketCost)

                                                local newPt = nil
                                                local ptAdd = 0
                                                if pbRes.info and pbRes.info.aLong and pbRes.info.aLong.Count >= 2 then
                                                    newPt = pbRes.info.aLong[0]
                                                    ptAdd = pbRes.info.aLong[1]
                                                elseif lbd.m_ArenaPointResult then
                                                    newPt = lbd.m_ArenaPointResult.m_MyArenaPoint
                                                    ptAdd = lbd.m_ArenaPointResult.m_MyAreaPointAdd or 0
                                                end

                                                local pi = cc:GetType():GetField("m_PanelInfo", REF_FLAGS):GetValue(cc)
                                                if pi then
                                                    local txtTicket = pi:GetType():GetField("m_TextTicket", REF_FLAGS):GetValue(pi)
                                                    if txtTicket then txtTicket.text = tostring(gc.m_ArenaTicket) end
                                                    if newPt then
                                                        if not startPoint then
                                                            startPoint = newPt - ptAdd
                                                        end
                                                        _G.HTPS_ARENA_STATS.pointDiff = newPt - startPoint
                                                        local txtPoint = pi:GetType():GetField("m_TextPoint", REF_FLAGS):GetValue(pi)
                                                        if txtPoint then
                                                            txtPoint.text = tostring(newPt)
                                                        end
                                                    end
                                                end

                                                local resTag = isWin and "Thắng" or "Né ngay"
                                                _G.HTPS_UpdateArenaStatsUI(string.format("%s: %s (LC:%.1fM | Tỉ lệ:%d%%)", resTag, tostring(bestRival.m_Playername), (bestRival.m_Power or 0) / 1000000.0, bestWinProb))
                                            end
                                        elseif a.actionId == 1 then
                                            gotLimitErr = true
                                        elseif a.actionId == 333 and a.data then
                                            local pbLst = _G.HTPS_DeserializeProto(a.data, "pbdson.PbListUser,PbMethodLib")
                                            if pbLst and pbLst.aUser then
                                                for u = 0, pbLst.aUser.Count - 1 do
                                                    local ap = CS.ArenaPlayer()
                                                    ap:ImportFromPbUser(pbLst.aUser[u])
                                                    table.insert(nextRivals, ap)
                                                end
                                            end
                                        end
                                    end
                                end
                            end)
                        end

                        if not gotBattle334 then
                            if gotLimitErr or okNet then
                                _G.HTPS_ARENA_MAXED_RIVALS[bestRival.m_UserId] = true
                            end
                            if bestIdx then
                                table.remove(currentRivals, bestIdx)
                            end
                            _G.HTPS_UpdateArenaStatsUI(string.format("Đổi mục tiêu (Quá 3 lượt: %s)...", tostring(bestRival.m_Playername)))
                            if #currentRivals == 0 and #nextRivals > 0 then
                                for _, nr in ipairs(nextRivals) do
                                    if not _G.HTPS_ARENA_MAXED_RIVALS[nr.m_UserId] then
                                        table.insert(currentRivals, nr)
                                    end
                                end
                            end
                        else
                            consecutiveEmptyResets = 0
                            currentRivals = {}
                            for _, nr in ipairs(nextRivals) do
                                if not _G.HTPS_ARENA_MAXED_RIVALS[nr.m_UserId] then
                                    table.insert(currentRivals, nr)
                                end
                            end
                        end

                        local totalBattles = _G.HTPS_ARENA_STATS.win + _G.HTPS_ARENA_STATS.lose
                        if totalBattles > 0 and totalBattles % 5 == 0 then
                            pcall(function()
                                gc.dataSender:CrystalStatus()
                                gc.dataSender:CrystalTopPlayer()
                                cc:HideLoading()
                            end)
                            if (gc.m_Gold % 4294967296) >= 2050000000 then
                                pcall(function() _G.HTPS_SyncServerEquipmentAndSafeGold() end)
                            end
                        end

                        coroutine.yield(UG.WaitForSeconds(0.06))
                    end
                end
            end

            _G.HTPS_ARENA_RUNNING = false
            pcall(function()
                gc.dataSender:CrystalStatus()
                gc.dataSender:CrystalTopPlayer()
                if cc then cc:HideLoading() end
                if (gc.m_Gold % 4294967296) >= 2050000000 then
                    _G.HTPS_SyncServerEquipmentAndSafeGold()
                end
            end)
        end)
    end

    _G.HTPS_EnsureArenaButtons = function()
        pcall(function()
            local cc = CS.CrystalCrownScene.Instance
            if not cc or not cc.gameObject.activeInHierarchy then return end
            local REF_FLAGS = 60
            local pi = cc:GetType():GetField("m_PanelInfo", REF_FLAGS):GetValue(cc)
            if not pi then return end
            local boxTf = pi.transform
            local btnBattleTf = boxTf:Find("ButtonBattle")
            if not btnBattleTf then return end

            local btnAutoTf = boxTf:Find("BtnHTPSAutoArena")
            if not btnAutoTf then
                local origRt = btnBattleTf:GetComponent(typeof(UG.RectTransform))
                origRt.anchoredPosition = UG.Vector2(-86.0, -68.2)
                origRt.sizeDelta = UG.Vector2(150.0, 56.0)

                local cloneGo = GO.Instantiate(btnBattleTf.gameObject, boxTf, false)
                cloneGo.name = "BtnHTPSAutoArena"
                cloneGo:SetActive(true)
                local rt = cloneGo:GetComponent(typeof(UG.RectTransform))
                rt.anchoredPosition = UG.Vector2(82.0, -68.2)
                rt.sizeDelta = UG.Vector2(176.0, 56.0)

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
                    _G.HTPS_BTN_ARENA_TXT = txt
                end
                btnAutoTf = cloneGo.transform
                _G.HTPS_UpdateArenaStatsUI()
            end

            local statsTf = boxTf:Find("TxtHTPSArenaStats")
            if not statsTf then
                local refTxt = pi:GetType():GetField("m_TextPoint", REF_FLAGS):GetValue(pi)
                if refTxt then
                    local stGo = GO.Instantiate(refTxt.gameObject, boxTf, false)
                    stGo.name = "TxtHTPSArenaStats"
                    stGo:SetActive(true)
                    local loc = stGo:GetComponent(typeof(CS.I2.Loc.Localize))
                    if loc then UG.Object.DestroyImmediate(loc) end
                    local srt = stGo:GetComponent(typeof(UG.RectTransform))
                    srt.anchorMin = UG.Vector2(0.5, 0.5)
                    srt.anchorMax = UG.Vector2(0.5, 0.5)
                    srt.anchoredPosition = UG.Vector2(0.0, -118.0)
                    srt.sizeDelta = UG.Vector2(345.0, 42.0)
                    local stTxt = stGo:GetComponent(typeof(UG.UI.Text))
                    if stTxt then
                        stTxt.raycastTarget = false
                        stTxt.supportRichText = true
                        stTxt.alignment = UG.TextAnchor.MiddleCenter
                        stTxt.fontSize = 15
                        stTxt.color = UG.Color(1, 1, 1, 1)
                        _G.HTPS_TXT_ARENA_STATS = stTxt
                    end
                    _G.HTPS_UpdateArenaStatsUI()
                end
            end

            if btnAutoTf and _G.HTPS_BOUND_ARENA_BTN ~= btnAutoTf then
                local bc = btnAutoTf:GetComponent(typeof(UG.UI.Button))
                if bc then
                    bc.onClick = UG.UI.Button.ButtonClickedEvent()
                    bc.onClick:AddListener(function()
                        _G.HTPS_ToggleAutoArena()
                    end)
                end
                _G.HTPS_BOUND_ARENA_BTN = btnAutoTf
            end
        end)
    end

    
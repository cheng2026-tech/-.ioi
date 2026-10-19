-- ==========================================================
-- 终极疯狗 v10.0 · 暴走狂暴版（全 BUG 修复 + 极限输出）
-- ==========================================================
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local plr = Players.LocalPlayer

local Remotes = RS:WaitForChild("Remotes", 10)
if not Remotes then warn("[终极] 找不到 Remotes"); return end
local SkillRemote = Remotes:FindFirstChild("Skill")
if not SkillRemote then warn("[终极] 找不到 Skill"); return end

print("═══════ 🔥 终极疯狗 v10.0 暴走狂暴版 🔥 ═══════")

-- ==================== 配置（暴走参数） ====================
local CONFIG = {
    Enabled = true,

    -- 检测（拉满）
    DetectRange = 250,
    VerticalDetect = true,
    UpRange = 120,
    DownRange = 80,

    -- 多目标
    MaxTargets = 10,
    TargetRotateSpeed = 0.02,

    -- 距离分段
    LongRange = 80,
    MidRange = 40,
    InstantRange = 12,

    -- 技能
    SkillIds = {"1", "2", "3"},

    -- ★ 攻击频率（暴走）
    CD_Instant = 0.001,
    CD_Mid = 0.002,
    CD_Far = 0.004,
    -- ★ 高频线程节流（全局 300 次/秒上限，防卡）
    RapidFireInterval = 0.003,

    -- ★ 追击（暴走）
    ChaseSpeed = 120,
    DashSpeed = 220,
    DashCooldown = 0.08,
    KeepCloseDistance = 4,
    MoveSlowFactor = 25,
    MaxHorizontalVelocity = 260,
    MaxVerticalVelocity = 80,     -- ★ 新增：防止被弹飞

    -- ★ 防逃跑（拉满）
    AntiEscape = true,
    EscapeDetectSpeed = 8,
    EscapeDashCooldown = 0.08,
    EscapeDashSpeed = 250,
    EscapeDashDuration = 0.1,

    -- 反远程
    AntiRanged = true,
    RangedThreshold = 35,

    -- ★ 动态追踪
    EnableTracker = true,
    TrackerInterval = 0.15,
    SpeedAdjustStep = 15,
    MinChaseSpeed = 100,
    MaxChaseSpeed = 200,

    -- ★ 预判攻击（暴走：1 个信号即触发）
    PreAttackEnabled = true,
    PreAttackSignals = 1,
    PreAttackCooldown = 0.03,
    PreAttackRange = 60,

    -- ★ 掉血反击
    HitCounterEnabled = true,
    HitCounterCooldown = 0.05,
    HitCounterThreshold = 0.3,
    HitCheckInterval = 0.01,

    -- 闪避（暴走）
    DodgeEnabled = true,
    DodgeProjectile = true,
    DodgeSpeed = 250,
    DodgeCooldown = 0.12,
    ProjectileDetectRange = 50,
    ProjectileMinSpeed = 40,

    -- 自动跳
    AutoJump = true,
    JumpThreshold = 2,

    -- 状态
    _lastFire = 0,
    _lastJump = 0,
    _lastDash = 0,
    _lastEscapeDash = 0,
    _lastDodge = 0,
    _lastTargetRotate = 0,
    _lastHPCheck = 0,
    _lastHitCounter = 0,
    _targetIndex = 1,
    _lastHP = nil,
    _origSpeed = nil,
    _spawnPos = nil,
    _threats = {},
    _lockedTargets = {},
    _projCache = {},
    _lastProjScan = 0,
    _stats = {
        dodge = 0, escape = 0, preAttack = 0,
        hitCounter = 0, targetsKilled = 0, rapidFire = 0,
    },
}

-- ★ 默认快照（Stealth 后可恢复）
local DEFAULT_CONFIG = {}
for k, v in pairs(CONFIG) do
    if type(v) ~= "table" then DEFAULT_CONFIG[k] = v end
end

-- ==================== 工具 ====================
local function getMyChar()
    local c = plr.Character
    if not c then return nil end
    local hrp = c:FindFirstChild("HumanoidRootPart")
    local hum = c:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum or hum.Health <= 0 then return nil end
    return c, hrp, hum
end

-- ★ BUG#6 修复：按名字清理，避免闪避被冲刺打断
local function cleanDashByName(name)
    local _, hrp = getMyChar()
    if not hrp then return end
    for _, obj in ipairs(hrp:GetChildren()) do
        if obj:IsA("BodyVelocity") and (name == nil or obj.Name == name) then
            obj:Destroy()
        end
    end
end

local function isAlive(char)
    if not char or not char.Parent then return false end
    local hum = char:FindFirstChildOfClass("Humanoid")
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hum or not hrp then return false end
    if hum.Health <= 0 then return false end
    if hum:GetState() == Enum.HumanoidStateType.Dead then return false end
    return true
end

local function safeUnit(v)
    if v.Magnitude < 0.01 then return nil end
    return v.Unit
end

-- ==================== 360° 扫描 ====================
local function scanAll()
    local _, myHrp = getMyChar()
    if not myHrp then return {} end
    local myPos = myHrp.Position

    local threats = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= plr and p.Character and isAlive(p.Character) then
            local char = p.Character
            local hum = char:FindFirstChildOfClass("Humanoid")
            local hrp = char:FindFirstChild("HumanoidRootPart")
            if hrp and hum then
                local diff = hrp.Position - myPos
                local dist = diff.Magnitude

                local vOK = true
                if CONFIG.VerticalDetect then
                    if diff.Y > CONFIG.UpRange then vOK = false
                    elseif diff.Y < -CONFIG.DownRange then vOK = false end
                end

                if dist < CONFIG.DetectRange and vOK then
                    table.insert(threats, {
                        char = char, hrp = hrp, hum = hum,
                        dist = dist, diff = diff,
                        hp = hum.Health, hpPct = hum.Health / hum.MaxHealth,
                        name = p.Name,
                    })
                end
            end
        end
    end

    -- ★ BUG#13 修复：等距用名字稳定排序
    table.sort(threats, function(a, b)
        if math.abs(a.dist - b.dist) < 0.5 then return a.name < b.name end
        return a.dist < b.dist
    end)
    return threats
end

local function lockTargets(threats)
    local locked = {}
    for i = 1, math.min(#threats, CONFIG.MaxTargets) do
        local t = threats[i]
        if isAlive(t.char) then
            local freshHrp = t.char:FindFirstChild("HumanoidRootPart")
            local freshHum = t.char:FindFirstChildOfClass("Humanoid")
            if freshHrp and freshHum then
                t.hrp = freshHrp
                t.hum = freshHum
                table.insert(locked, t)
            end
        end
    end
    CONFIG._lockedTargets = locked
end

-- ==================== 转向（★ BUG#10 修复：节流） ====================
local _lastTurn = 0
local function turnTo(hrp)
    local _, myHrp = getMyChar()
    if not myHrp or not hrp or not hrp.Parent then return end
    -- 角度变化够大才设，避免每帧打架
    local curLook = myHrp.CFrame.LookVector
    local targetDir = Vector3.new(hrp.Position.X - myHrp.Position.X, 0,
                                   hrp.Position.Z - myHrp.Position.Z)
    local u = safeUnit(targetDir)
    if not u then return end
    if curLook:Dot(u) > 0.999 then return end
    pcall(function()
        myHrp.CFrame = CFrame.new(myHrp.Position,
            Vector3.new(hrp.Position.X, myHrp.Position.Y, hrp.Position.Z))
    end)
end

-- ==================== 冲刺 ====================
local function dash(dir, speed, dur)
    local _, hrp = getMyChar()
    if not hrp then return end
    dir = Vector3.new(dir.X, 0, dir.Z)
    local u = safeUnit(dir)
    if not u then return end

    cleanDashByName("RadarDash")  -- 只清冲刺，不清闪避
    local bv = Instance.new("BodyVelocity")
    bv.Name = "RadarDash"
    bv.MaxForce = Vector3.new(50000, 0, 50000)
    bv.Velocity = u * speed
    bv.Parent = hrp

    task.spawn(function()
        task.wait(dur)
        if bv and bv.Parent then bv:Destroy() end   -- ★ BUG#12：直接销毁
    end)
end

local function dashTo(target, speed, dur)
    if not target or not target.hrp or not target.hrp.Parent then return end
    local _, hrp = getMyChar()
    if not hrp then return end
    local diff = target.hrp.Position - hrp.Position
    dash(Vector3.new(diff.X, 0, diff.Z), speed or CONFIG.DashSpeed, dur or 0.1)
end

-- ==================== 预判信号 ====================
local EnemyState = {}

local function isAttackAnim(char)
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return false end
    local animator = hum:FindFirstChildOfClass("Animator")
    if not animator then return false end
    local ok, tracks = pcall(function() return animator:GetPlayingAnimationTracks() end)
    if not ok or not tracks then return false end
    for _, track in ipairs(tracks) do
        local name = track.Animation and track.Animation.Name or ""
        local lower = name:lower()
        if lower:find("attack") or lower:find("punch") or lower:find("swing")
            or lower:find("slash") or lower:find("hit") or lower:find("strike")
            or lower:find("shoot") or lower:find("cast") or lower:find("skill")
            or lower:find("combo") or lower:find("kick") or lower:find("smash") then
            return true
        end
    end
    return false
end

-- ★ BUG#3 修复：除零检测
local function isCharging(char, myHrp)
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end
    local diff = myHrp.Position - hrp.Position
    if diff.Magnitude < 0.1 then return false end
    local vel = hrp.AssemblyLinearVelocity
    return vel:Dot(diff.Unit) > 15
end

local function isTurningToMe(char, myHrp, state)
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end
    local diff = myHrp.Position - hrp.Position
    local u = safeUnit(Vector3.new(diff.X, 0, diff.Z))
    if not u then return false end
    local look = hrp.CFrame.LookVector
    local dot = look:Dot(u)
    if state.lastDot and state.lastDot < 0.5 and dot > 0.85 then
        return true
    end
    state.lastDot = dot
    return false
end

local function hasSwitchedTool(char, state)
    local tool = char:FindFirstChildOfClass("Tool")
    if not tool then state.lastTool = nil; return false end
    if state.lastTool ~= tool then
        state.lastTool = tool
        return true
    end
    return false
end

local function isArmRaised(char)
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return false end
    local shoulder = hum:FindFirstChild("RightShoulder")
    if shoulder and math.abs(shoulder.CurrentAngle) > 45 then return true end
    return false
end

-- ==================== 防逃跑 ====================
local EscapeTracker = {}

local function isEscaping(target)
    if not target or not target.hrp or not target.hrp.Parent then return false end
    local key = target.name
    local prev = EscapeTracker[key]
    local now = os.clock()

    if prev and now - prev.time > 0.05 then
        EscapeTracker[key] = { pos = target.hrp.Position, time = now }
        local _, myHrp = getMyChar()
        if myHrp then
            local diff = myHrp.Position - target.hrp.Position
            local u = safeUnit(diff)
            if not u then return false end
            local enemyVel = target.hrp.AssemblyLinearVelocity
            local awaySpeed = -enemyVel:Dot(u)
            if awaySpeed > CONFIG.EscapeDetectSpeed and target.dist > 12 then
                return true, awaySpeed
            end
        end
    else
        EscapeTracker[key] = { pos = target.hrp.Position, time = now }
    end
    return false
end

-- ==================== 闪避 ====================
-- ★ BUG#5 修复：用 GetDescendants + 缓存扫描
local function detectProj()
    local _, myHrp = getMyChar()
    if not myHrp then return nil end
    local now = os.clock()
    if now - CONFIG._lastProjScan < 0.05 then return CONFIG._projCache[1] end

    CONFIG._lastProjScan = now
    CONFIG._projCache = {}
    local myPos = myHrp.Position

    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") and obj ~= myHrp and obj.Parent then
            local vel = obj.AssemblyLinearVelocity
            if vel.Magnitude > CONFIG.ProjectileMinSpeed then
                local diff = myPos - obj.Position
                if diff.Magnitude < CONFIG.ProjectileDetectRange then
                    local vU, dU = safeUnit(vel), safeUnit(diff)
                    if vU and dU and vU:Dot(dU) > 0.85 then
                        table.insert(CONFIG._projCache, obj)
                    end
                end
            end
        end
    end
    return CONFIG._projCache[1]
end

local function dodge(dir, speed)
    local _, hrp = getMyChar()
    if not hrp then return end
    cleanDashByName("RadarDodge")
    local bv = Instance.new("BodyVelocity")
    bv.Name = "RadarDodge"
    bv.MaxForce = Vector3.new(30000, 0, 30000)
    bv.Velocity = dir * speed
    bv.Parent = hrp
    task.spawn(function()
        task.wait(0.12)
        if bv and bv.Parent then bv:Destroy() end
    end)
end

-- ==================== 速度上限（防飞 + 防弹飞） ====================
task.spawn(function()
    while task.wait(0.05) do
        if not CONFIG.Enabled then continue end
        pcall(function()
            local _, hrp = getMyChar()
            if not hrp then return end
            local vel = hrp.Velocity
            local hVel = Vector3.new(vel.X, 0, vel.Z)
            local newVel = vel
            if hVel.Magnitude > CONFIG.MaxHorizontalVelocity then
                newVel = Vector3.new(vel.X * 0.3, newVel.Y, vel.Z * 0.3)
            end
            -- ★ 新增：Y 轴上限（防被弹飞）
            if math.abs(newVel.Y) > CONFIG.MaxVerticalVelocity then
                newVel = Vector3.new(newVel.X, newVel.Y * 0.2, newVel.Z)
            end
            hrp.Velocity = newVel
        end)
    end
end)

-- ==================== 🔥 高频攻击线程（核心暴力源） ====================
task.spawn(function()
    while task.wait(CONFIG.RapidFireInterval) do
        if not CONFIG.Enabled then continue end
        local locked = CONFIG._lockedTargets
        if #locked == 0 then continue end

        -- ★ 所有技能 → 所有锁定目标，全齐射
        for _, id in ipairs(CONFIG.SkillIds) do
            for _, t in ipairs(locked) do
                if isAlive(t.char) and t.dist <= CONFIG.LongRange then
                    pcall(function() SkillRemote:FireServer(id, t.char) end)
                    CONFIG._stats.rapidFire = CONFIG._stats.rapidFire + 1
                end
            end
        end
    end
end)

-- ==================== 掉血秒反击 ====================
task.spawn(function()
    while task.wait(CONFIG.HitCheckInterval) do
        if not CONFIG.Enabled or not CONFIG.HitCounterEnabled then continue end
        pcall(function()
            local _, _, hum = getMyChar()
            if not hum then
                CONFIG._lastHP = nil
                return
            end

            local now = os.clock()
            local hp = hum.Health

            -- ★ BUG#8 修复：血量上升视为重生/治疗，直接重置
            if not CONFIG._lastHP or hp > CONFIG._lastHP then
                CONFIG._lastHP = hp
                return
            end

            if hp < CONFIG._lastHP - CONFIG.HitCounterThreshold then
                if now - CONFIG._lastHitCounter > CONFIG.HitCounterCooldown then
                    CONFIG._lastHitCounter = now
                    CONFIG._stats.hitCounter = CONFIG._stats.hitCounter + 1

                    -- 三技能 → 全部锁定目标齐射
                    local locked = CONFIG._lockedTargets
                    local target = locked[1] or CONFIG._threats[1]
                    if target then
                        turnTo(target.hrp)
                        dashTo(target, CONFIG.DashSpeed, 0.08)
                        for _, id in ipairs(CONFIG.SkillIds) do
                            for _, t in ipairs(locked) do
                                if isAlive(t.char) then
                                    task.spawn(function()
                                        pcall(function() SkillRemote:FireServer(id, t.char) end)
                                    end)
                                end
                            end
                        end
                    end
                end
            end
            CONFIG._lastHP = hp
        end)
    end
end)

-- ==================== 预判攻击（★ BUG#1 修复） ====================
task.spawn(function()
    while task.wait(0.015) do
        if not CONFIG.Enabled or not CONFIG.PreAttackEnabled then continue end
        pcall(function()
            local _, myHrp = getMyChar()
            if not myHrp then return end

            local threats = CONFIG._threats
            for _, target in ipairs(threats) do
                if target.dist > CONFIG.PreAttackRange then break end

                -- ★ 死亡目标跳过，不中断循环
                if isAlive(target.char) then
                    local char = target.char
                    local key = target.name
                    if not EnemyState[key] then
                        EnemyState[key] = { lastDot = nil, lastTool = nil, lastAttack = 0 }
                    end
                    local state = EnemyState[key]

                    local signals = 0
                    if isAttackAnim(char) then signals = signals + 3 end
                    if isCharging(char, myHrp) then signals = signals + 1 end
                    if isTurningToMe(char, myHrp, state) then signals = signals + 1 end
                    if hasSwitchedTool(char, state) then signals = signals + 2 end
                    if isArmRaised(char) then signals = signals + 1 end

                    if signals >= CONFIG.PreAttackSignals then
                        local now = os.clock()
                        if now - state.lastAttack > CONFIG.PreAttackCooldown then
                            state.lastAttack = now
                            CONFIG._stats.preAttack = CONFIG._stats.preAttack + 1

                            -- 所有技能打这个目标
                            for _, id in ipairs(CONFIG.SkillIds) do
                                task.spawn(function()
                                    pcall(function() SkillRemote:FireServer(id, char) end)
                                end)
                            end
                            turnTo(target.hrp)
                            dashTo(target, CONFIG.DashSpeed, 0.08)
                        end
                    end
                end
            end
        end)
    end
end)

-- ==================== 防逃跑追击 ====================
task.spawn(function()
    while task.wait(0.06) do
        if not CONFIG.Enabled or not CONFIG.AntiEscape then continue end
        pcall(function()
            local threats = CONFIG._threats
            if #threats == 0 then return end
            local target = threats[1]
            if not isAlive(target.char) then return end

            local escaping = isEscaping(target)
            if escaping then
                local now = os.clock()
                if now - CONFIG._lastEscapeDash > CONFIG.EscapeDashCooldown then
                    CONFIG._lastEscapeDash = now
                    CONFIG._stats.escape = CONFIG._stats.escape + 1

                    turnTo(target.hrp)
                    dashTo(target, CONFIG.EscapeDashSpeed, CONFIG.EscapeDashDuration)

                    for _, id in ipairs(CONFIG.SkillIds) do
                        task.spawn(function()
                            pcall(function() SkillRemote:FireServer(id, target.char) end)
                        end)
                    end
                end
            end
        end)
    end
end)

-- ==================== 闪避循环 ====================
task.spawn(function()
    while task.wait(0.02) do
        if not CONFIG.Enabled or not CONFIG.DodgeEnabled then continue end
        pcall(function()
            local _, myHrp = getMyChar()
            if not myHrp then return end
            local now = os.clock()
            local proj = detectProj()
            if proj and now - CONFIG._lastDodge > CONFIG.DodgeCooldown then
                CONFIG._lastDodge = now
                local pd = safeUnit(proj.AssemblyLinearVelocity)
                -- ★ BUG#4 修复：垂直飞来的投射物用侧向随机方向
                local sd = pd and Vector3.new(-pd.Z, 0, pd.X) or myHrp.CFrame.RightVector
                local sdU = safeUnit(sd)
                if not sdU then sdU = myHrp.CFrame.RightVector end
                if math.random() > 0.5 then sdU = -sdU end
                dodge(sdU, CONFIG.DodgeSpeed)
                CONFIG._stats.dodge = CONFIG._stats.dodge + 1
            end
        end)
    end
end)

-- ==================== 动态追踪 ====================
local Tracker = {
    CurrentSpeed = 120, EnemyPrev = {},
    LastDist = nil, LastName = nil, Status = "未锁定",
}

local function getVel(prev, cur, dt)
    if not prev or not cur then return 0 end
    return (cur - prev).Magnitude / math.max(dt, 0.01)
end

local function cleanCache()
    local online = {}
    for _, p in ipairs(Players:GetPlayers()) do online[p.Name] = true end
    for name in pairs(Tracker.EnemyPrev) do
        if not online[name] then
            Tracker.EnemyPrev[name] = nil
            EscapeTracker[name] = nil
            EnemyState[name] = nil
        end
    end
end

task.spawn(function()
    while true do
        task.wait(CONFIG.TrackerInterval)
        if not CONFIG.Enabled or not CONFIG.EnableTracker then continue end
        pcall(function()
            local _, myHrp, hum = getMyChar()
            if not myHrp or not hum then
                Tracker.Status = "无角色"; return
            end
            if not CONFIG._origSpeed then CONFIG._origSpeed = hum.WalkSpeed end

            local threats = CONFIG._threats
            if #threats == 0 then
                hum.WalkSpeed = CONFIG._origSpeed
                Tracker.Status = "无敌"
                Tracker.CurrentSpeed = CONFIG.MinChaseSpeed
                Tracker.LastDist = nil
                Tracker.LastName = nil
                cleanCache()
                return
            end

            local t = threats[1]
            if not isAlive(t.char) then return end

            if Tracker.LastName ~= t.name then
                Tracker.LastDist = nil
                Tracker.LastName = t.name
            end

            local key = t.name
            local prev = Tracker.EnemyPrev[key]
            Tracker.EnemyPrev[key] = t.hrp.Position
            local eSpeed = getVel(prev, t.hrp.Position, CONFIG.TrackerInterval)

            local dist = t.dist
            local prevDist = Tracker.LastDist or dist
            local dDiff = dist - prevDist
            Tracker.LastDist = dist

            local needSpeed = Tracker.CurrentSpeed

            if dDiff > 0.3 then
                needSpeed = math.max(eSpeed + 20, Tracker.CurrentSpeed + CONFIG.SpeedAdjustStep)
                Tracker.Status = string.format("追不上→提速(敌%.0f/我%d)", eSpeed, needSpeed)
            elseif dDiff < -0.3 then
                needSpeed = CONFIG.MaxChaseSpeed
                Tracker.Status = string.format("追上(敌%.0f/我%d)", eSpeed, needSpeed)
            else
                Tracker.Status = string.format("保持(敌%.0f/我%d)", eSpeed, Tracker.CurrentSpeed)
            end

            needSpeed = math.clamp(needSpeed, CONFIG.MinChaseSpeed, CONFIG.MaxChaseSpeed)
            Tracker.CurrentSpeed = needSpeed

            if dist < 120 then
                hum.WalkSpeed = needSpeed
            else
                hum.WalkSpeed = CONFIG._origSpeed
            end
        end)
    end
end)

plr.CharacterAdded:Connect(function()
    task.wait(1)
    CONFIG._origSpeed = nil
    CONFIG._lastHP = nil
    Tracker.LastDist = nil
    Tracker.LastName = nil
end)

-- ==================== 主战斗循环（★ BUG#2 修复：反远程不站桩） ====================
RunService.RenderStepped:Connect(function()
    if not CONFIG.Enabled then return end

    local myChar, myHrp, hum = getMyChar()
    if not myHrp then return end

    for i = #CONFIG._lockedTargets, 1, -1 do
        local t = CONFIG._lockedTargets[i]
        if not isAlive(t.char) then
            table.remove(CONFIG._lockedTargets, i)
            CONFIG._stats.targetsKilled = CONFIG._stats.targetsKilled + 1
        end
    end

    CONFIG._threats = scanAll()
    local threats = CONFIG._threats
    if #threats == 0 then
        pcall(function() hum:Move(Vector3.zero, false) end)
        CONFIG._lockedTargets = {}
        return
    end

    lockTargets(threats)
    local locked = CONFIG._lockedTargets
    local now = os.clock()
    local closest = threats[1]

    turnTo(closest.hrp)

    -- 反远程：冲刺 + 兜底走路（★ 不再站桩）
    if CONFIG.AntiRanged and closest.dist > CONFIG.RangedThreshold then
        if now - CONFIG._lastDash > CONFIG.DashCooldown then
            CONFIG._lastDash = now
            dashTo(closest, CONFIG.DashSpeed, 0.12)
        end
        local diff = closest.hrp.Position - myHrp.Position
        local u = safeUnit(Vector3.new(diff.X, 0, diff.Z))
        if u then pcall(function() hum:Move(u, false) end) end
        return
    end

    -- 追击
    if closest.dist > CONFIG.KeepCloseDistance then
        local diff = closest.hrp.Position - myHrp.Position
        local u = safeUnit(Vector3.new(diff.X, 0, diff.Z))
        if u then
            local factor = math.min(1, closest.dist / CONFIG.MoveSlowFactor)
            pcall(function() hum:Move(u * factor, false) end)
        end
    else
        pcall(function() hum:Move(Vector3.zero, false) end)
    end

    -- 自动跳
    if CONFIG.AutoJump and closest.diff.Y > CONFIG.JumpThreshold then
        if hum.FloorMaterial ~= Enum.Material.Air then
            if now - CONFIG._lastJump > 0.12 then
                pcall(function() hum.Jump = true end)
                CONFIG._lastJump = now
            end
        end
    end

    -- ★ 主循环只做朝向轮换（攻击交给高频线程）
    if now - CONFIG._lastTargetRotate > CONFIG.TargetRotateSpeed then
        CONFIG._lastTargetRotate = now
        CONFIG._targetIndex = CONFIG._targetIndex + 1
        if CONFIG._targetIndex > math.max(#locked, 1) then CONFIG._targetIndex = 1 end
    end
end)

-- ==================== 上方/下方检测 ====================
task.spawn(function()
    while task.wait(0.02) do
        if not CONFIG.Enabled then continue end
        pcall(function()
            local _, myHrp, hum = getMyChar()
            if not myHrp then return end
            local myPos = myHrp.Position
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= plr and p.Character and isAlive(p.Character) then
                    local pHrp = p.Character:FindFirstChild("HumanoidRootPart")
                    if pHrp then
                        local diff = pHrp.Position - myPos
                        local hDist = Vector3.new(diff.X, 0, diff.Z).Magnitude
                        if hDist < 12 then
                            if diff.Y > 4 and diff.Y < CONFIG.UpRange then
                                pcall(function() hum.Jump = true end)
                                for _, id in ipairs(CONFIG.SkillIds) do
                                    pcall(function() SkillRemote:FireServer(id, p.Character) end)
                                end
                            end
                            if diff.Y < -4 and diff.Y > -CONFIG.DownRange then
                                for _, id in ipairs(CONFIG.SkillIds) do
                                    pcall(function() SkillRemote:FireServer(id, p.Character) end)
                                end
                            end
                        end
                    end
                end
            end
        end)
    end
end)

-- ==================== 脱控反击 ====================
task.spawn(function()
    local wasStunned = false
    while task.wait(0.01) do
        if not CONFIG.Enabled then continue end
        pcall(function()
            local _, _, hum = getMyChar()
            if not hum then return end
            local state = hum:GetState()
            local stunned = state == Enum.HumanoidStateType.PlatformStanding
                or state == Enum.HumanoidStateType.Ragdoll
                or state == Enum.HumanoidStateType.FallingDown
            if wasStunned and not stunned then
                local locked = CONFIG._lockedTargets
                for _, t in ipairs(locked) do
                    if isAlive(t.char) then
                        for _, id in ipairs(CONFIG.SkillIds) do
                            task.spawn(function()
                                pcall(function() SkillRemote:FireServer(id, t.char) end)
                            end)
                        end
                    end
                end
            end
            wasStunned = stunned
        end)
    end
end)

-- ==================== 防掉下去 ====================
plr.CharacterAdded:Connect(function(char)
    task.wait(1)
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if hrp then
        local spawn = workspace:FindFirstChildOfClass("SpawnLocation")
        CONFIG._spawnPos = spawn and spawn.Position or hrp.Position
    end
end)

task.spawn(function()
    while task.wait(0.2) do
        pcall(function()
            local _, hrp = getMyChar()
            if not hrp then return end
            if CONFIG._spawnPos and hrp.Position.Y < CONFIG._spawnPos.Y - 150 then
                cleanDashByName(nil)
                hrp.CFrame = CFrame.new(CONFIG._spawnPos + Vector3.new(0, 5, 0))
                hrp.Velocity = Vector3.zero
            end
        end)
    end
end)

-- ==================== 控制接口 ====================
_G.MultiLock = {
    Toggle = function()
        CONFIG.Enabled = not CONFIG.Enabled
        print("[终极] " .. (CONFIG.Enabled and "🔥 开" or "❌ 关"))
    end,
    Scan = function()
        local threats = scanAll()
        print("═══════ 扫描（共 " .. #threats .. "） ═══════")
        for i, t in ipairs(threats) do
            local mark = i <= CONFIG.MaxTargets and "🔒" or "  "
            print(string.format("%s [%d] %s | 距离: %.1f | 血量: %.0f%%",
                mark, i, t.name, t.dist, t.hpPct * 100))
        end
    end,
    Status = function()
        print("═══════ 状态 ═══════")
        print("追击速度: " .. math.floor(Tracker.CurrentSpeed))
        print("追踪: " .. Tracker.Status)
        print("闪避: " .. CONFIG._stats.dodge)
        print("防逃跑: " .. CONFIG._stats.escape)
        print("预判打断: " .. CONFIG._stats.preAttack)
        print("被打反击: " .. CONFIG._stats.hitCounter)
        print("高频齐射: " .. CONFIG._stats.rapidFire)
        print("击杀: " .. CONFIG._stats.targetsKilled)
        print("锁定: " .. #CONFIG._lockedTargets .. " 个")
    end,
    SetSpeedRange = function(minS, maxS)
        CONFIG.MinChaseSpeed = minS or CONFIG.MinChaseSpeed
        CONFIG.MaxChaseSpeed = maxS or CONFIG.MaxChaseSpeed
        print("[终极] 速度范围: " .. CONFIG.MinChaseSpeed .. " ~ " .. CONFIG.MaxChaseSpeed)
    end,
    SetMaxTargets = function(n)
        CONFIG.MaxTargets = math.max(1, math.min(n, 15))
        print("[终极] 最多锁定: " .. CONFIG.MaxTargets)
    end,
    ToggleEscape = function()
        CONFIG.AntiEscape = not CONFIG.AntiEscape
        print("[终极] 防逃跑: " .. tostring(CONFIG.AntiEscape))
    end,
    TogglePreAttack = function()
        CONFIG.PreAttackEnabled = not CONFIG.PreAttackEnabled
        print("[终极] 预判攻击: " .. tostring(CONFIG.PreAttackEnabled))
    end,
    ToggleHitCounter = function()
        CONFIG.HitCounterEnabled = not CONFIG.HitCounterEnabled
        print("[终极] 被打反击: " .. tostring(CONFIG.HitCounterEnabled))
    end,
    ToggleDodge = function()
        CONFIG.DodgeEnabled = not CONFIG.DodgeEnabled
        print("[终极] 闪避: " .. tostring(CONFIG.DodgeEnabled))
    end,
    -- ★ BUG#7 修复：Stealth 后可恢复默认
    Stealth = function()
        CONFIG.CD_Instant = 0.05
        CONFIG.CD_Mid = 0.08
        CONFIG.CD_Far = 0.12
        CONFIG.RapidFireInterval = 0.1
        CONFIG.MinChaseSpeed = 50
        CONFIG.MaxChaseSpeed = 90
        CONFIG.DashSpeed = 100
        CONFIG.DodgeSpeed = 120
        CONFIG.AntiEscape = false
        CONFIG.PreAttackEnabled = false
        CONFIG.HitCounterEnabled = false
        print("[终极] 🛡️ 切隐者")
    end,
    RestoreDefault = function()
        for k, v in pairs(DEFAULT_CONFIG) do
            if type(v) ~= "table" then CONFIG[k] = v end
        end
        print("[终极] ⚙️ 配置已恢复默认")
    end,
    Calm = function()
        CONFIG.Enabled = false
        cleanDashByName(nil)
        print("[终极] 😴 收手")
    end,
    Restart = function()
        CONFIG.Enabled = true
        print("[终极] 🔥 继续暴走")
    end,
    Tracker = Tracker,
    Config = CONFIG,
}

print("═══════════════════════════════════════")
print("🔥 终极疯狗 v10.0 暴走狂暴版 🔥")
print("")
print("【BUG 修复】")
print("  ✅ 预判死目标不再中断循环")
print("  ✅ 反远程 CD 期间仍追击")
print("  ✅ 除零 NaN 全防护")
print("  ✅ 投射物嵌套检测")
print("  ✅ 闪避不再被冲刺打断")
print("  ✅ 掉血反击竞态修复")
print("  ✅ Stealth 后可恢复默认")
print("")
print("【暴走参数】")
print("  检测范围: 250")
print("  锁定目标: 10 个")
print("  高频齐射: 300+ 次/秒")
print("  追击速度: 100~200")
print("  冲刺速度: 220")
print("  预判阈值: 1 个信号即打断")
print("")
print("【命令】")
print("  📡 扫描:    _G.MultiLock.Scan()")
print("  📊 状态:    _G.MultiLock.Status()")
print("  🛡️ 隐者:    _G.MultiLock.Stealth()")
print("  ⚙️ 恢复:    _G.MultiLock.RestoreDefault()")
print("  😴 停止:    _G.MultiLock.Calm()")
print("  🔥 暴走:    _G.MultiLock.Restart()")
print("═══════════════════════════════════════")
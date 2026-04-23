local Players          = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService       = game:GetService("RunService")

local player   = Players.LocalPlayer
local lbSearch = workspace:WaitForChild("OthersSpecialEvents"):WaitForChild("LBSearch")

-- ── Config ────────────────────────────────────────────────────────────────────
local COLLECT_DELAY = 0.3
local CHEST_DELAY   = 5
local LOOP_DELAY    = 5

-- ── State ─────────────────────────────────────────────────────────────────────
local active        = true
local running       = false
local flyEnabled    = false
local noclipEnabled = false
local flySpeed      = 1
local walkSpeed     = 16
local jumpPower     = 50
local minimized     = false

local function getHumanoid()
    local char = player.Character
    if char then return char:FindFirstChildOfClass("Humanoid") end
end

do
    local hum = getHumanoid()
    if hum then
        walkSpeed = hum.WalkSpeed
        jumpPower = hum.JumpPower
    end
end

-- ── Noclip ────────────────────────────────────────────────────────────────────
local noclipConn
local function enableNoclip()
    noclipConn = RunService.Stepped:Connect(function()
        local char = player.Character
        if not char then return end
        for _, v in ipairs(char:GetDescendants()) do
            if v:IsA("BasePart") then v.CanCollide = false end
        end
    end)
end
local function disableNoclip()
    if noclipConn then noclipConn:Disconnect() noclipConn = nil end
    local char = player.Character
    if not char then return end
    for _, v in ipairs(char:GetDescendants()) do
        if v:IsA("BasePart") then v.CanCollide = true end
    end
end

-- ── Fly ───────────────────────────────────────────────────────────────────────
local flyConn
local bodyVel, bodyGyro

local function enableFly()
    local char = player.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum then return end
    hum.PlatformStand = true
    bodyVel          = Instance.new("BodyVelocity")
    bodyVel.Velocity = Vector3.zero
    bodyVel.MaxForce = Vector3.new(1e9, 1e9, 1e9)
    bodyVel.Parent   = hrp
    bodyGyro             = Instance.new("BodyGyro")
    bodyGyro.MaxTorque   = Vector3.new(1e9, 1e9, 1e9)
    bodyGyro.P           = 1e4
    bodyGyro.CFrame      = hrp.CFrame
    bodyGyro.Parent      = hrp
    flyConn = RunService.Heartbeat:Connect(function()
        if not flyEnabled then return end
        local cam = workspace.CurrentCamera
        local dir = Vector3.zero
        if UserInputService:IsKeyDown(Enum.KeyCode.W)         then dir += cam.CFrame.LookVector  end
        if UserInputService:IsKeyDown(Enum.KeyCode.S)         then dir -= cam.CFrame.LookVector  end
        if UserInputService:IsKeyDown(Enum.KeyCode.A)         then dir -= cam.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D)         then dir += cam.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space)     then dir += Vector3.new(0,1,0)     end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then dir -= Vector3.new(0,1,0)     end
        if dir.Magnitude > 0 then dir = dir.Unit end
        bodyVel.Velocity = dir * flySpeed
        bodyGyro.CFrame  = cam.CFrame
    end)
end

local function disableFly()
    flyEnabled = false
    if flyConn  then flyConn:Disconnect()  flyConn  = nil end
    if bodyVel  then bodyVel:Destroy()     bodyVel  = nil end
    if bodyGyro then bodyGyro:Destroy()    bodyGyro = nil end
    local hum = getHumanoid()
    if hum then hum.PlatformStand = false end
end

player.CharacterAdded:Connect(function(char)
    task.wait(1)
    local hum = char:WaitForChild("Humanoid")
    hum.WalkSpeed = walkSpeed
    hum.JumpPower = jumpPower
    if noclipEnabled then enableNoclip() end
    if flyEnabled    then enableFly()    end
end)

-- ── GUI ───────────────────────────────────────────────────────────────────────
local W, H = 220, 385

local screenGui = Instance.new("ScreenGui")
screenGui.Name           = "LBCollector"
screenGui.ResetOnSpawn   = false
screenGui.IgnoreGuiInset = true
screenGui.Parent         = player.PlayerGui

local frame = Instance.new("Frame")
frame.Size             = UDim2.new(0, W, 0, H)
frame.Position         = UDim2.new(0.5, -W/2, 0.5, -H/2)
frame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
frame.BorderSizePixel  = 0
frame.Active           = true
frame.Parent           = screenGui
Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)

local titleBar = Instance.new("Frame")
titleBar.Size             = UDim2.new(1, 0, 0, 28)
titleBar.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
titleBar.BorderSizePixel  = 0
titleBar.Parent           = frame
Instance.new("UICorner", titleBar).CornerRadius = UDim.new(0, 8)

local titlePatch = Instance.new("Frame")
titlePatch.Size             = UDim2.new(1, 0, 0, 8)
titlePatch.Position         = UDim2.new(0, 0, 1, -8)
titlePatch.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
titlePatch.BorderSizePixel  = 0
titlePatch.Parent           = titleBar

local titleLabel = Instance.new("TextLabel")
titleLabel.Size                   = UDim2.new(1, -60, 1, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text                   = "LB Collector"
titleLabel.TextColor3             = Color3.fromRGB(220, 220, 220)
titleLabel.TextSize               = 13
titleLabel.Font                   = Enum.Font.GothamBold
titleLabel.Parent                 = titleBar

-- Close button
local closeBtn = Instance.new("TextButton")
closeBtn.Size                   = UDim2.new(0, 28, 0, 28)
closeBtn.Position               = UDim2.new(1, -28, 0, 0)
closeBtn.BackgroundColor3       = Color3.fromRGB(200, 50, 50)
closeBtn.BorderSizePixel        = 0
closeBtn.Text                   = "X"
closeBtn.TextColor3             = Color3.fromRGB(255, 255, 255)
closeBtn.TextSize               = 12
closeBtn.Font                   = Enum.Font.GothamBold
closeBtn.Parent                 = titleBar
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 6)
closeBtn.MouseEnter:Connect(function() closeBtn.BackgroundColor3 = Color3.fromRGB(255, 60, 60) end)
closeBtn.MouseLeave:Connect(function() closeBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50) end)
closeBtn.MouseButton1Click:Connect(function()
    active  = false
    running = false
    disableFly()
    disableNoclip()
    -- Remove all ESP from every part before destroying
    for _, spawnFolder in ipairs(lbSearch:GetChildren()) do
        for _, child in ipairs(spawnFolder:GetDescendants()) do
            if child:IsA("BasePart") then
                local bb = child:FindFirstChild("_LBEsp")
                if bb then bb:Destroy() end
                local hl = child:FindFirstChild("_LBHighlight")
                if hl then hl:Destroy() end
            end
        end
    end
    screenGui:Destroy()
end)

-- Minimize button
local minBtn = Instance.new("TextButton")
minBtn.Size                   = UDim2.new(0, 28, 0, 28)
minBtn.Position               = UDim2.new(1, -58, 0, 0)
minBtn.BackgroundColor3       = Color3.fromRGB(60, 60, 60)
minBtn.BorderSizePixel        = 0
minBtn.Text                   = "-"
minBtn.TextColor3             = Color3.fromRGB(255, 255, 255)
minBtn.TextSize               = 16
minBtn.Font                   = Enum.Font.GothamBold
minBtn.Parent                 = titleBar
Instance.new("UICorner", minBtn).CornerRadius = UDim.new(0, 6)
minBtn.MouseEnter:Connect(function() minBtn.BackgroundColor3 = Color3.fromRGB(90, 90, 90) end)
minBtn.MouseLeave:Connect(function() minBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60) end)

local contentFrames = {}
local function trackContent(f) table.insert(contentFrames, f) end

minBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    minBtn.Text = minimized and "+" or "-"
    frame.Size  = minimized and UDim2.new(0, W, 0, 28) or UDim2.new(0, W, 0, H)
    for _, f in ipairs(contentFrames) do f.Visible = not minimized end
end)

local statusLabel = Instance.new("TextLabel")
statusLabel.Size                   = UDim2.new(1, -12, 0, 20)
statusLabel.Position               = UDim2.new(0, 6, 0, 34)
statusLabel.BackgroundTransparency = 1
statusLabel.Text                   = "Status: Idle"
statusLabel.TextColor3             = Color3.fromRGB(160, 160, 160)
statusLabel.TextSize               = 12
statusLabel.Font                   = Enum.Font.Gotham
statusLabel.TextXAlignment         = Enum.TextXAlignment.Left
statusLabel.Parent                 = frame
trackContent(statusLabel)

local startBtn = Instance.new("TextButton")
startBtn.Size             = UDim2.new(1, -12, 0, 26)
startBtn.Position         = UDim2.new(0, 6, 0, 58)
startBtn.BackgroundColor3 = Color3.fromRGB(50, 168, 82)
startBtn.BorderSizePixel  = 0
startBtn.Text             = "Start"
startBtn.TextColor3       = Color3.fromRGB(255, 255, 255)
startBtn.TextSize         = 13
startBtn.Font             = Enum.Font.GothamBold
startBtn.Parent           = frame
Instance.new("UICorner", startBtn).CornerRadius = UDim.new(0, 6)
trackContent(startBtn)
startBtn.MouseButton1Click:Connect(function()
    running = not running
    if running then
        startBtn.Text             = "Stop"
        startBtn.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
    else
        startBtn.Text             = "Start"
        startBtn.BackgroundColor3 = Color3.fromRGB(50, 168, 82)
        statusLabel.Text          = "Status: Idle"
        statusLabel.TextColor3    = Color3.fromRGB(160, 160, 160)
    end
end)

-- ── Toggle factory ────────────────────────────────────────────────────────────
local function makeToggle(yPos, labelText, callback)
    local row = Instance.new("Frame")
    row.Size             = UDim2.new(1, -12, 0, 26)
    row.Position         = UDim2.new(0, 6, 0, yPos)
    row.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    row.BorderSizePixel  = 0
    row.Parent           = frame
    Instance.new("UICorner", row).CornerRadius = UDim.new(0, 6)
    trackContent(row)

    local dot = Instance.new("Frame")
    dot.Size             = UDim2.new(0, 10, 0, 10)
    dot.Position         = UDim2.new(0, 9, 0.5, -5)
    dot.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
    dot.BorderSizePixel  = 0
    dot.Parent           = row
    Instance.new("UICorner", dot).CornerRadius = UDim.new(1, 0)

    local lbl = Instance.new("TextLabel")
    lbl.Size                   = UDim2.new(1, -30, 1, 0)
    lbl.Position               = UDim2.new(0, 28, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text                   = labelText
    lbl.TextColor3             = Color3.fromRGB(160, 160, 160)
    lbl.TextSize               = 12
    lbl.Font                   = Enum.Font.Gotham
    lbl.TextXAlignment         = Enum.TextXAlignment.Left
    lbl.Parent                 = row

    local btn = Instance.new("TextButton")
    btn.Size                   = UDim2.new(1, 0, 1, 0)
    btn.BackgroundTransparency = 1
    btn.Text                   = ""
    btn.Parent                 = row

    local activeState = false
    btn.MouseButton1Click:Connect(function()
        activeState = not activeState
        dot.BackgroundColor3 = activeState and Color3.fromRGB(50, 168, 82) or Color3.fromRGB(100, 100, 100)
        lbl.TextColor3       = activeState and Color3.fromRGB(220, 220, 220) or Color3.fromRGB(160, 160, 160)
        if callback then callback(activeState) end
    end)
    return function() return activeState end
end

local getEspEnabled = makeToggle(88, "Item ESP")

-- ── Divider ───────────────────────────────────────────────────────────────────
local div = Instance.new("Frame")
div.Size             = UDim2.new(1, -12, 0, 1)
div.Position         = UDim2.new(0, 6, 0, 120)
div.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
div.BorderSizePixel  = 0
div.Parent           = frame
trackContent(div)

local secLbl = Instance.new("TextLabel")
secLbl.Size                   = UDim2.new(1, -12, 0, 14)
secLbl.Position               = UDim2.new(0, 6, 0, 124)
secLbl.BackgroundTransparency = 1
secLbl.Text                   = "MOVEMENT"
secLbl.TextColor3             = Color3.fromRGB(90, 90, 90)
secLbl.TextSize               = 10
secLbl.Font                   = Enum.Font.GothamBold
secLbl.TextXAlignment         = Enum.TextXAlignment.Left
secLbl.Parent                 = frame
trackContent(secLbl)

makeToggle(142, "Noclip", function(act)
    noclipEnabled = act
    if act then enableNoclip() else disableNoclip() end
end)

makeToggle(172, "Fly  (WASD + Space/Shift)", function(act)
    flyEnabled = act
    if act then enableFly() else disableFly() end
end)

-- ── Slider factory ────────────────────────────────────────────────────────────
local slidingCallback = nil

local function makeSlider(yPos, labelText, minVal, maxVal, defaultVal, resetVal, onChange)
    local row = Instance.new("Frame")
    row.Size             = UDim2.new(1, -12, 0, 26)
    row.Position         = UDim2.new(0, 6, 0, yPos)
    row.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    row.BorderSizePixel  = 0
    row.Parent           = frame
    Instance.new("UICorner", row).CornerRadius = UDim.new(0, 6)
    trackContent(row)

    local lbl = Instance.new("TextLabel")
    lbl.Size                   = UDim2.new(0, 62, 1, 0)
    lbl.Position               = UDim2.new(0, 8, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text                   = labelText
    lbl.TextColor3             = Color3.fromRGB(160, 160, 160)
    lbl.TextSize               = 11
    lbl.Font                   = Enum.Font.Gotham
    lbl.TextXAlignment         = Enum.TextXAlignment.Left
    lbl.Parent                 = row

    local track = Instance.new("TextButton")
    track.Size             = UDim2.new(0, 76, 0, 6)
    track.Position         = UDim2.new(0, 73, 0.5, -3)
    track.BackgroundColor3 = Color3.fromRGB(55, 55, 55)
    track.BorderSizePixel  = 0
    track.Text             = ""
    track.AutoButtonColor  = false
    track.Parent           = row
    Instance.new("UICorner", track).CornerRadius = UDim.new(1, 0)

    local fill = Instance.new("Frame")
    fill.BackgroundColor3 = Color3.fromRGB(50, 168, 82)
    fill.BorderSizePixel  = 0
    fill.Size             = UDim2.new((defaultVal - minVal) / (maxVal - minVal), 0, 1, 0)
    fill.Parent           = track
    Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)

    local thumb = Instance.new("Frame")
    thumb.Size             = UDim2.new(0, 12, 0, 12)
    thumb.AnchorPoint      = Vector2.new(0.5, 0.5)
    thumb.Position         = UDim2.new((defaultVal - minVal) / (maxVal - minVal), 0, 0.5, 0)
    thumb.BackgroundColor3 = Color3.fromRGB(220, 220, 220)
    thumb.BorderSizePixel  = 0
    thumb.ZIndex           = 3
    thumb.Parent           = track
    Instance.new("UICorner", thumb).CornerRadius = UDim.new(1, 0)

    local valLbl = Instance.new("TextLabel")
    valLbl.Size                   = UDim2.new(0, 30, 1, 0)
    valLbl.Position               = UDim2.new(0, 153, 0, 0)
    valLbl.BackgroundTransparency = 1
    valLbl.Text                   = tostring(math.floor(defaultVal))
    valLbl.TextColor3             = Color3.fromRGB(200, 200, 200)
    valLbl.TextSize               = 11
    valLbl.Font                   = Enum.Font.GothamBold
    valLbl.Parent                 = row

    local resetBtn = Instance.new("TextButton")
    resetBtn.Size             = UDim2.new(0, 22, 0, 18)
    resetBtn.Position         = UDim2.new(1, -26, 0.5, -9)
    resetBtn.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
    resetBtn.BorderSizePixel  = 0
    resetBtn.Text             = "R"
    resetBtn.TextColor3       = Color3.fromRGB(255, 160, 60)
    resetBtn.TextSize         = 11
    resetBtn.Font             = Enum.Font.GothamBold
    resetBtn.Parent           = row
    Instance.new("UICorner", resetBtn).CornerRadius = UDim.new(0, 4)
    resetBtn.MouseEnter:Connect(function() resetBtn.BackgroundColor3 = Color3.fromRGB(100,100,100) end)
    resetBtn.MouseLeave:Connect(function() resetBtn.BackgroundColor3 = Color3.fromRGB(70,70,70)   end)

    local function setValue(val)
        val = math.clamp(math.floor(val + 0.5), minVal, maxVal)
        local t = (val - minVal) / (maxVal - minVal)
        fill.Size      = UDim2.new(t, 0, 1, 0)
        thumb.Position = UDim2.new(t, 0, 0.5, 0)
        valLbl.Text    = tostring(val)
        if onChange then onChange(val) end
    end

    local function inputToVal(inputX)
        local rel = (inputX - track.AbsolutePosition.X) / track.AbsoluteSize.X
        return minVal + (maxVal - minVal) * math.clamp(rel, 0, 1)
    end

    track.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            slidingCallback = function(x) setValue(inputToVal(x)) end
            slidingCallback(input.Position.X)
        end
    end)
    resetBtn.MouseButton1Click:Connect(function() setValue(resetVal) end)
    setValue(defaultVal)
end

local initialWalkSpeed = walkSpeed
local initialJumpPower = jumpPower

makeSlider(202, "Fly spd",  1,  400,              1,               1, function(v) flySpeed = v end)
makeSlider(232, "Walk spd", 1, 1000, initialWalkSpeed, initialWalkSpeed, function(v)
    walkSpeed = v
    local hum = getHumanoid()
    if hum then hum.WalkSpeed = v end
end)
makeSlider(262, "Jump pwr", 1, 1000, initialJumpPower, initialJumpPower, function(v)
    jumpPower = v
    local hum = getHumanoid()
    if hum then hum.JumpPower = v end
end)

-- ── Dragging ──────────────────────────────────────────────────────────────────
local dragging, dragStart, startPos

frame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging  = true
        dragStart = input.Position
        startPos  = frame.Position
    end
end)
frame.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = false
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if input.UserInputType ~= Enum.UserInputType.MouseMovement then return end
    if slidingCallback then
        slidingCallback(input.Position.X)
    elseif dragging then
        local delta = input.Position - dragStart
        frame.Position = UDim2.new(
            startPos.X.Scale, startPos.X.Offset + delta.X,
            startPos.Y.Scale, startPos.Y.Offset + delta.Y
        )
    end
end)
UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        slidingCallback = nil
    end
end)

-- ── Status animation ──────────────────────────────────────────────────────────
local dots   = {"Searching..", "Searching..."}
local dotIdx = 1
task.spawn(function()
    while active do
        if running then
            statusLabel.Text       = dots[dotIdx]
            statusLabel.TextColor3 = Color3.fromRGB(80, 200, 120)
            dotIdx = (dotIdx % #dots) + 1
        end
        task.wait(0.6)
    end
end)

-- ── ESP ───────────────────────────────────────────────────────────────────────
local function addEsp(part, label, color)
    if not part or not part:IsA("BasePart") then return end
    if part:FindFirstChild("_LBEsp") then return end
    local bb = Instance.new("BillboardGui")
    bb.Name        = "_LBEsp"
    bb.Size        = UDim2.new(0, 80, 0, 20)
    bb.StudsOffset = Vector3.new(0, 4, 0)
    bb.AlwaysOnTop = true
    bb.Parent      = part
    local txt = Instance.new("TextLabel")
    txt.Size                   = UDim2.new(1, 0, 1, 0)
    txt.BackgroundTransparency = 1
    txt.Text                   = label
    txt.TextColor3             = color
    txt.TextSize               = 12
    txt.Font                   = Enum.Font.GothamBold
    txt.Parent                 = bb
    local hl = Instance.new("SelectionBox")
    hl.Name                = "_LBHighlight"
    hl.Adornee             = part
    hl.Color3              = color
    hl.LineThickness       = 0.05
    hl.SurfaceTransparency = 0.8
    hl.SurfaceColor3       = color
    hl.Parent              = part
end

local function removeEsp(part)
    if not part then return end
    local bb = part:FindFirstChild("_LBEsp")
    if bb then bb:Destroy() end
    local hl = part:FindFirstChild("_LBHighlight")
    if hl then hl:Destroy() end
end

local function findBottlePart(folder, name)
    local direct = folder:FindFirstChild(name)
    if direct and direct:IsA("BasePart") then return direct end
    if direct then
        local part = direct:FindFirstChildWhichIsA("BasePart", true)
        if part then return part end
    end
    for _, v in ipairs(folder:GetDescendants()) do
        if v.Name == name and v:IsA("BasePart") then return v end
    end
    return nil
end

task.spawn(function()
    while active do
        for _, spawnFolder in ipairs(lbSearch:GetChildren()) do
            if spawnFolder:IsA("Script") or spawnFolder:IsA("LocalScript") then continue end
            local lbPart = findBottlePart(spawnFolder, "LBbottleSpawn")
            if lbPart then
                if getEspEnabled() then addEsp(lbPart, "LB Bottle", Color3.fromRGB(100,180,255))
                else removeEsp(lbPart) end
            end
            local xlPart = findBottlePart(spawnFolder, "XLLbottleSpawn")
                        or findBottlePart(spawnFolder, "XLbottleSpawn")
                        or findBottlePart(spawnFolder, "XLBottleSpawn")
            if xlPart then
                if getEspEnabled() then addEsp(xlPart, "XL Bottle", Color3.fromRGB(100,255,150))
                else removeEsp(xlPart) end
            end
            local ch = spawnFolder:FindFirstChild("LBChest")
            if ch then
                local main = ch:FindFirstChild("Main")
                if main and not main:IsA("BasePart") then
                    main = main:FindFirstChildWhichIsA("BasePart", true)
                end
                if not main then main = ch:FindFirstChildWhichIsA("BasePart", true) end
                if main and main:IsA("BasePart") then
                    if getEspEnabled() then addEsp(main, "Chest", Color3.fromRGB(255,210,80))
                    else removeEsp(main) end
                end
            end
        end
        task.wait(2)
    end
end)

-- ── Collector ─────────────────────────────────────────────────────────────────
local function findPrompt(obj)
    if not obj then return nil end
    local p = obj:FindFirstChildOfClass("ProximityPrompt")
    if p then return p end
    for _, v in ipairs(obj:GetDescendants()) do
        if v:IsA("ProximityPrompt") then return v end
    end
    return nil
end

local function teleportTo(cf)
    local char = player.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if hrp then hrp.CFrame = cf + Vector3.new(0, 3, 0) end
end

local function getOriginCF()
    local char = player.Character
    if not char then return nil end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if hrp then return hrp.CFrame end
end

local function collectAll()
    local origin = getOriginCF()
    for _, spawnFolder in ipairs(lbSearch:GetChildren()) do
        if not running or not active then return end
        if spawnFolder:IsA("Script") or spawnFolder:IsA("LocalScript") then continue end

        local lb = spawnFolder:FindFirstChild("LBbottleSpawn")
        if lb then
            local prompt = findPrompt(lb)
            if prompt then
                local part = lb:IsA("BasePart") and lb or lb:FindFirstChildWhichIsA("BasePart") or lb
                teleportTo(part.CFrame) task.wait(0.05)
                prompt.MaxActivationDistance = math.huge
                fireproximityprompt(prompt) task.wait(COLLECT_DELAY)
            end
        end

        local xll = spawnFolder:FindFirstChild("XLLbottleSpawn")
                 or spawnFolder:FindFirstChild("XLbottleSpawn")
                 or spawnFolder:FindFirstChild("XLBottleSpawn")
        if xll then
            local part = xll:IsA("BasePart") and xll or xll:FindFirstChildWhichIsA("BasePart") or xll
            if part then
                teleportTo(part.CFrame)
                -- Prompt may be added dynamically by server script - wait up to 1s for it
                local prompt = nil
                for _ = 1, 10 do
                    task.wait(0.1)
                    prompt = findPrompt(xll)
                    if prompt then break end
                end
                if prompt then
                    prompt.MaxActivationDistance = math.huge
                    fireproximityprompt(prompt)
                    task.wait(COLLECT_DELAY)
                else
                    task.wait(COLLECT_DELAY)
                end
            end
        end

        local chest = spawnFolder:FindFirstChild("LBChest")
        if chest then
            local prompt = findPrompt(chest)
            if prompt then
                local main = chest:FindFirstChild("Main") or chest:FindFirstChildWhichIsA("BasePart") or chest
                local mainPart = main:IsA("BasePart") and main or main:FindFirstChildWhichIsA("BasePart") or main
                teleportTo(mainPart.CFrame) task.wait(0.05)
                prompt.MaxActivationDistance = math.huge
                fireproximityprompt(prompt) task.wait(0.5)
                for _, item in ipairs(chest:GetDescendants()) do
                    if item:IsA("ProximityPrompt") and item ~= prompt then
                        item.MaxActivationDistance = math.huge
                        fireproximityprompt(item) task.wait(0.2)
                    end
                end
                task.wait(CHEST_DELAY)
            end
        end
    end
    -- Return to origin after collecting everything
    if origin and running and active then
        teleportTo(origin)
    end
end


-- ── Hitbox ────────────────────────────────────────────────────────────────────
local div2 = Instance.new("Frame")
div2.Size             = UDim2.new(1, -12, 0, 1)
div2.Position         = UDim2.new(0, 6, 0, 295)
div2.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
div2.BorderSizePixel  = 0
div2.Parent           = frame
trackContent(div2)

local hbSecLbl = Instance.new("TextLabel")
hbSecLbl.Size                   = UDim2.new(1, -12, 0, 14)
hbSecLbl.Position               = UDim2.new(0, 6, 0, 299)
hbSecLbl.BackgroundTransparency = 1
hbSecLbl.Text                   = "HITBOX"
hbSecLbl.TextColor3             = Color3.fromRGB(90, 90, 90)
hbSecLbl.TextSize               = 10
hbSecLbl.Font                   = Enum.Font.GothamBold
hbSecLbl.TextXAlignment         = Enum.TextXAlignment.Left
hbSecLbl.Parent                 = frame
trackContent(hbSecLbl)

-- Tool dropdown
local selectedTool = nil

local dropRow = Instance.new("Frame")
dropRow.Size             = UDim2.new(1, -12, 0, 26)
dropRow.Position         = UDim2.new(0, 6, 0, 317)
dropRow.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
dropRow.BorderSizePixel  = 0
dropRow.Parent           = frame
Instance.new("UICorner", dropRow).CornerRadius = UDim.new(0, 6)
trackContent(dropRow)

local dropBtn = Instance.new("TextButton")
dropBtn.Size                   = UDim2.new(1, 0, 1, 0)
dropBtn.BackgroundTransparency = 1
dropBtn.Text                   = "Select Tool  v"
dropBtn.TextColor3             = Color3.fromRGB(160, 160, 160)
dropBtn.TextSize               = 11
dropBtn.Font                   = Enum.Font.Gotham
dropBtn.Parent                 = dropRow

-- Dropdown popup (opens upward, high ZIndex)
local dropList = Instance.new("Frame")
dropList.Size             = UDim2.new(1, -12, 0, 0)
dropList.Position         = UDim2.new(0, 6, 0, 317)
dropList.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
dropList.BorderSizePixel  = 0
dropList.ZIndex           = 20
dropList.Visible          = false
dropList.ClipsDescendants = true
dropList.Parent           = frame
Instance.new("UICorner", dropList).CornerRadius = UDim.new(0, 6)

local dropScroll = Instance.new("ScrollingFrame")
dropScroll.Size                   = UDim2.new(1, 0, 1, 0)
dropScroll.BackgroundTransparency = 1
dropScroll.BorderSizePixel        = 0
dropScroll.ScrollBarThickness     = 4
dropScroll.ZIndex                 = 20
dropScroll.Parent                 = dropList
local dropLayout = Instance.new("UIListLayout")
dropLayout.Padding   = UDim.new(0, 2)
dropLayout.SortOrder = Enum.SortOrder.LayoutOrder
dropLayout.Parent    = dropScroll
local dropPad = Instance.new("UIPadding")
dropPad.PaddingLeft = UDim.new(0, 4)
dropPad.Parent      = dropScroll

local function refreshDropdown()
    for _, ch in ipairs(dropScroll:GetChildren()) do
        if ch:IsA("TextButton") then ch:Destroy() end
    end
    local tools = {}
    for _, t in ipairs(player.Backpack:GetChildren()) do
        if t:IsA("Tool") then table.insert(tools, t) end
    end
    local char = player.Character
    if char then
        for _, t in ipairs(char:GetChildren()) do
            if t:IsA("Tool") then table.insert(tools, t) end
        end
    end
    if #tools == 0 then
        local none = Instance.new("TextButton")
        none.Size                   = UDim2.new(1, -4, 0, 24)
        none.BackgroundTransparency = 1
        none.Text                   = "No tools found"
        none.TextColor3             = Color3.fromRGB(100, 100, 100)
        none.TextSize               = 11
        none.Font                   = Enum.Font.Gotham
        none.ZIndex                 = 20
        none.Parent                 = dropScroll
    end
    for _, tool in ipairs(tools) do
        local entry = Instance.new("TextButton")
        entry.Size             = UDim2.new(1, -4, 0, 24)
        entry.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
        entry.BorderSizePixel  = 0
        entry.Text             = tool.Name
        entry.TextColor3       = Color3.fromRGB(200, 200, 200)
        entry.TextSize         = 11
        entry.Font             = Enum.Font.Gotham
        entry.ZIndex           = 20
        entry.Parent           = dropScroll
        Instance.new("UICorner", entry).CornerRadius = UDim.new(0, 4)
        entry.MouseEnter:Connect(function() entry.BackgroundColor3 = Color3.fromRGB(60,60,60) end)
        entry.MouseLeave:Connect(function() entry.BackgroundColor3 = Color3.fromRGB(45,45,45) end)
        entry.MouseButton1Click:Connect(function()
            selectedTool     = tool
            dropBtn.Text     = tool.Name .. "  v"
            dropList.Visible = false
        end)
    end
    local count = math.max(1, #tools)
    local listH = math.min(count * 26, 104)
    dropList.Position     = UDim2.new(0, 6, 0, 317 - listH - 2)
    dropList.Size         = UDim2.new(1, -12, 0, listH)
    dropScroll.CanvasSize = UDim2.new(0, 0, 0, count * 26)
end

dropBtn.MouseButton1Click:Connect(function()
    if dropList.Visible then
        dropList.Visible = false
    else
        refreshDropdown()
        dropList.Visible = true
    end
end)

-- Hitbox toggle + size slider
local hitboxEnabled   = false
local hitboxSize      = 1.0
local hitboxOrigSizes = {}

local hbRow = Instance.new("Frame")
hbRow.Size             = UDim2.new(1, -12, 0, 26)
hbRow.Position         = UDim2.new(0, 6, 0, 347)
hbRow.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
hbRow.BorderSizePixel  = 0
hbRow.Parent           = frame
Instance.new("UICorner", hbRow).CornerRadius = UDim.new(0, 6)
trackContent(hbRow)

local hbDot = Instance.new("Frame")
hbDot.Size             = UDim2.new(0, 10, 0, 10)
hbDot.Position         = UDim2.new(0, 8, 0.5, -5)
hbDot.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
hbDot.BorderSizePixel  = 0
hbDot.Parent           = hbRow
Instance.new("UICorner", hbDot).CornerRadius = UDim.new(1, 0)

local hbLbl = Instance.new("TextLabel")
hbLbl.Size                   = UDim2.new(0, 42, 1, 0)
hbLbl.Position               = UDim2.new(0, 22, 0, 0)
hbLbl.BackgroundTransparency = 1
hbLbl.Text                   = "Hitbox"
hbLbl.TextColor3             = Color3.fromRGB(160, 160, 160)
hbLbl.TextSize               = 11
hbLbl.Font                   = Enum.Font.Gotham
hbLbl.TextXAlignment         = Enum.TextXAlignment.Left
hbLbl.Parent                 = hbRow

local hbTrack = Instance.new("TextButton")
hbTrack.Size             = UDim2.new(0, 60, 0, 6)
hbTrack.Position         = UDim2.new(0, 68, 0.5, -3)
hbTrack.BackgroundColor3 = Color3.fromRGB(55, 55, 55)
hbTrack.BorderSizePixel  = 0
hbTrack.Text             = ""
hbTrack.AutoButtonColor  = false
hbTrack.Parent           = hbRow
Instance.new("UICorner", hbTrack).CornerRadius = UDim.new(1, 0)

local hbFill = Instance.new("Frame")
hbFill.BackgroundColor3 = Color3.fromRGB(50, 168, 82)
hbFill.BorderSizePixel  = 0
hbFill.Size             = UDim2.new(0, 0, 1, 0)
hbFill.Parent           = hbTrack
Instance.new("UICorner", hbFill).CornerRadius = UDim.new(1, 0)

local hbThumb = Instance.new("Frame")
hbThumb.Size             = UDim2.new(0, 12, 0, 12)
hbThumb.AnchorPoint      = Vector2.new(0.5, 0.5)
hbThumb.Position         = UDim2.new(0, 0, 0.5, 0)
hbThumb.BackgroundColor3 = Color3.fromRGB(220, 220, 220)
hbThumb.BorderSizePixel  = 0
hbThumb.ZIndex           = 3
hbThumb.Parent           = hbTrack
Instance.new("UICorner", hbThumb).CornerRadius = UDim.new(1, 0)

local hbValLbl = Instance.new("TextLabel")
hbValLbl.Size                   = UDim2.new(0, 28, 1, 0)
hbValLbl.Position               = UDim2.new(0, 132, 0, 0)
hbValLbl.BackgroundTransparency = 1
hbValLbl.Text                   = "1x"
hbValLbl.TextColor3             = Color3.fromRGB(200, 200, 200)
hbValLbl.TextSize               = 11
hbValLbl.Font                   = Enum.Font.GothamBold
hbValLbl.Parent                 = hbRow

local hbResetBtn = Instance.new("TextButton")
hbResetBtn.Size             = UDim2.new(0, 22, 0, 18)
hbResetBtn.Position         = UDim2.new(1, -26, 0.5, -9)
hbResetBtn.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
hbResetBtn.BorderSizePixel  = 0
hbResetBtn.Text             = "R"
hbResetBtn.TextColor3       = Color3.fromRGB(255, 160, 60)
hbResetBtn.TextSize         = 11
hbResetBtn.Font             = Enum.Font.GothamBold
hbResetBtn.Parent           = hbRow
Instance.new("UICorner", hbResetBtn).CornerRadius = UDim.new(0, 4)
hbResetBtn.MouseEnter:Connect(function() hbResetBtn.BackgroundColor3 = Color3.fromRGB(100,100,100) end)
hbResetBtn.MouseLeave:Connect(function() hbResetBtn.BackgroundColor3 = Color3.fromRGB(70,70,70) end)

local HB_MIN, HB_MAX = 0.5, 10.0

local function setHbValue(val)
    val = math.clamp(math.floor(val * 10 + 0.5) / 10, HB_MIN, HB_MAX)
    hitboxSize = val
    local t = (val - HB_MIN) / (HB_MAX - HB_MIN)
    hbFill.Size      = UDim2.new(t, 0, 1, 0)
    hbThumb.Position = UDim2.new(t, 0, 0.5, 0)
    hbValLbl.Text    = val .. "x"
end

hbTrack.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        slidingCallback = function(x)
            local rel = (x - hbTrack.AbsolutePosition.X) / hbTrack.AbsoluteSize.X
            setHbValue(HB_MIN + (HB_MAX - HB_MIN) * math.clamp(rel, 0, 1))
        end
        slidingCallback(input.Position.X)
    end
end)
hbResetBtn.MouseButton1Click:Connect(function() setHbValue(1.0) end)
setHbValue(1.0)

local function restoreHitbox()
    for part, origSize in pairs(hitboxOrigSizes) do
        pcall(function()
            if part and part.Parent then part.Size = origSize end
        end)
    end
    hitboxOrigSizes = {}
end

local function applyHitbox()
    if not selectedTool then return end
    local char = player.Character
    local src = (char and char:FindFirstChild(selectedTool.Name))
             or player.Backpack:FindFirstChild(selectedTool.Name)
    if not src then return end
    for _, part in ipairs(src:GetDescendants()) do
        if part:IsA("BasePart") then
            if not hitboxOrigSizes[part] then hitboxOrigSizes[part] = part.Size end
            part.Size = hitboxOrigSizes[part] * hitboxSize
        end
    end
    local handle = src:FindFirstChild("Handle")
    if handle and handle:IsA("BasePart") then
        if not hitboxOrigSizes[handle] then hitboxOrigSizes[handle] = handle.Size end
        handle.Size = hitboxOrigSizes[handle] * hitboxSize
    end
end

local hbToggleBtn = Instance.new("TextButton")
hbToggleBtn.Size                   = UDim2.new(0, 64, 1, 0)
hbToggleBtn.BackgroundTransparency = 1
hbToggleBtn.Text                   = ""
hbToggleBtn.Parent                 = hbRow
hbToggleBtn.MouseButton1Click:Connect(function()
    hitboxEnabled = not hitboxEnabled
    hbDot.BackgroundColor3 = hitboxEnabled and Color3.fromRGB(50,168,82) or Color3.fromRGB(100,100,100)
    hbLbl.TextColor3       = hitboxEnabled and Color3.fromRGB(220,220,220) or Color3.fromRGB(160,160,160)
    if not hitboxEnabled then restoreHitbox() end
end)

task.spawn(function()
    while active do
        if hitboxEnabled then applyHitbox() end
        task.wait(0.1)
    end
    restoreHitbox()
end)
-- ── Main loop ─────────────────────────────────────────────────────────────────
while active do
    if running then
        collectAll()
        if running and active then task.wait(LOOP_DELAY) end
    else
        task.wait(0.1)
    end
end


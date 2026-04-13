local Players          = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService       = game:GetService("RunService")

local player     = Players.LocalPlayer
local activeEggs = workspace:WaitForChild("EasterEggHuntRuntime"):WaitForChild("ActiveEggs")

local COLLECT_DELAY = 0.1
local LOOP_DELAY    = 1

local running          = false
local flyEnabled       = false
local noclipEnabled    = false
local flySpeed         = 1
local walkSpeed        = 16
local jumpPower        = 50
local collectedIds     = {}
local espEnabled       = false
local expSpeedEnabled  = false
local expFogEnabled    = false
local autoFishEnabled  = false
local autoSurfaceEnabled = false
local SURFACE_HP_PCT    = 0.50  -- surface when HP drops below 50%
local EXPEDITION_BACK   = Vector3.new(-60108.7, 2384, 33.5)  -- hole layer exit (exact)
local EXP_SPEED        = 80
local IN_EXPEDITION    = false
local lastFogClear     = 0

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
    local hrp  = char:FindFirstChild("HumanoidRootPart")
    local hum  = char:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum then return end
    hum.PlatformStand = true
    bodyVel          = Instance.new("BodyVelocity")
    bodyVel.Velocity = Vector3.zero
    bodyVel.MaxForce = Vector3.new(1e9, 1e9, 1e9)
    bodyVel.Parent   = hrp
    bodyGyro           = Instance.new("BodyGyro")
    bodyGyro.MaxTorque = Vector3.new(1e9, 1e9, 1e9)
    bodyGyro.P         = 1e4
    bodyGyro.CFrame    = hrp.CFrame
    bodyGyro.Parent    = hrp
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

-- ── Expedition helpers ────────────────────────────────────────────────────────
local function isInExpedition()
    local char = player.Character
    if not char then return false end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end
    -- Expedition zone is at around X=-60108, normal world is around X=-265
    return hrp.Position.X < -1000
end

local fogConnections = {}

local function hookFogObject(obj)
    if obj:IsA("DepthOfFieldEffect") or obj:IsA("BlurEffect") then
        obj.Enabled = false
        local conn = obj:GetPropertyChangedSignal("Enabled"):Connect(function()
            if expFogEnabled and obj.Enabled then
                obj.Enabled = false
            end
        end)
        table.insert(fogConnections, conn)
    end
end

local function clearFog()
    -- Disconnect old hooks
    for _, c in ipairs(fogConnections) do pcall(function() c:Disconnect() end) end
    fogConnections = {}

    -- Hook all existing effects
    for _, obj in ipairs(game:GetService("Lighting"):GetDescendants()) do
        hookFogObject(obj)
    end

    -- Hook new effects as they get added
    local conn = game:GetService("Lighting").DescendantAdded:Connect(function(obj)
        if expFogEnabled then hookFogObject(obj) end
    end)
    table.insert(fogConnections, conn)

    -- Clear atmosphere and fog distance
    local atmo = workspace:FindFirstChildOfClass("Atmosphere")
    if atmo then
        atmo.Density = 0
        atmo.Haze    = 0
        atmo.Glare   = 0
    end
    game:GetService("Lighting").FogEnd   = 100000
    game:GetService("Lighting").FogStart = 100000
end

local function restoreFog()
    for _, c in ipairs(fogConnections) do pcall(function() c:Disconnect() end) end
    fogConnections = {}
    for _, obj in ipairs(game:GetService("Lighting"):GetDescendants()) do
        if obj:IsA("DepthOfFieldEffect") or obj:IsA("BlurEffect") then
            obj.Enabled = true
        end
    end
    game:GetService("Lighting").FogEnd   = 1000
    game:GetService("Lighting").FogStart = 0
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
local W, H = 220, 500

local screenGui = Instance.new("ScreenGui")
screenGui.Name           = "EggCollector"
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
titleLabel.Size                   = UDim2.new(1, -36, 1, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text                   = "Fish Pond"
titleLabel.TextColor3             = Color3.fromRGB(220, 220, 220)
titleLabel.TextSize               = 13
titleLabel.Font                   = Enum.Font.GothamBold
titleLabel.Parent                 = titleBar

local closeBg = Instance.new("Frame")
closeBg.Size             = UDim2.new(0, 22, 0, 20)
closeBg.Position         = UDim2.new(1, -25, 0.5, -10)
closeBg.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
closeBg.BorderSizePixel  = 0
closeBg.Parent           = titleBar
Instance.new("UICorner", closeBg).CornerRadius = UDim.new(0, 4)

local closeBtn = Instance.new("TextButton")
closeBtn.Size                   = UDim2.new(1, 0, 1, 0)
closeBtn.BackgroundTransparency = 1
closeBtn.Text                   = "X"
closeBtn.TextColor3             = Color3.fromRGB(255, 255, 255)
closeBtn.TextSize               = 12
closeBtn.Font                   = Enum.Font.GothamBold
closeBtn.Parent                 = closeBg

closeBg.MouseEnter:Connect(function() closeBg.BackgroundColor3 = Color3.fromRGB(255, 60, 60) end)
closeBg.MouseLeave:Connect(function() closeBg.BackgroundColor3 = Color3.fromRGB(200, 50, 50) end)
closeBtn.MouseButton1Click:Connect(function()
    running = false
    disableFly()
    disableNoclip()
    if expFogEnabled then restoreFog() end
    screenGui:Destroy()
end)

local statusLabel = Instance.new("TextLabel")
statusLabel.Size                   = UDim2.new(1, -12, 0, 20)
statusLabel.Position               = UDim2.new(0, 6, 0, 32)
statusLabel.BackgroundTransparency = 1
statusLabel.Text                   = "Status: Idle"
statusLabel.TextColor3             = Color3.fromRGB(160, 160, 160)
statusLabel.TextSize               = 12
statusLabel.Font                   = Enum.Font.Gotham
statusLabel.TextXAlignment         = Enum.TextXAlignment.Left
statusLabel.Parent                 = frame

local countLabel = Instance.new("TextLabel")
countLabel.Size                   = UDim2.new(1, -12, 0, 20)
countLabel.Position               = UDim2.new(0, 6, 0, 32)
countLabel.BackgroundTransparency = 1
countLabel.Text                   = ""
countLabel.TextColor3             = Color3.fromRGB(255, 210, 80)
countLabel.TextSize               = 12
countLabel.Font                   = Enum.Font.GothamBold
countLabel.TextXAlignment         = Enum.TextXAlignment.Right
countLabel.Parent                 = frame

local startBtn = Instance.new("TextButton")
startBtn.Size             = UDim2.new(1, -12, 0, 26)
startBtn.Position         = UDim2.new(0, 6, 0, 55)
startBtn.BackgroundColor3 = Color3.fromRGB(50, 168, 82)
startBtn.BorderSizePixel  = 0
startBtn.Text             = "Start Egg Collector"
startBtn.TextColor3       = Color3.fromRGB(255, 255, 255)
startBtn.TextSize         = 13
startBtn.Font             = Enum.Font.GothamBold
startBtn.Parent           = frame
Instance.new("UICorner", startBtn).CornerRadius = UDim.new(0, 6)

startBtn.MouseButton1Click:Connect(function()
    running = not running
    if running then
        startBtn.Text             = "Stop Egg Collector"
        startBtn.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
    else
        startBtn.Text             = "Start Egg Collector"
        startBtn.BackgroundColor3 = Color3.fromRGB(50, 168, 82)
        statusLabel.Text          = "Status: Idle"
        statusLabel.TextColor3    = Color3.fromRGB(160, 160, 160)
        countLabel.Text           = ""
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

    local active = false
    btn.MouseButton1Click:Connect(function()
        active = not active
        dot.BackgroundColor3 = active and Color3.fromRGB(50, 168, 82) or Color3.fromRGB(100, 100, 100)
        lbl.TextColor3       = active and Color3.fromRGB(220, 220, 220) or Color3.fromRGB(160, 160, 160)
        if callback then callback(active) end
    end)

    return function() return active end
end

local espFolder = Instance.new("Folder")
espFolder.Name   = "EggESP"
espFolder.Parent = player.PlayerGui

local div1 = Instance.new("Frame")
div1.Size             = UDim2.new(1, -12, 0, 1)
div1.Position         = UDim2.new(0, 6, 0, 85)
div1.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
div1.BorderSizePixel  = 0
div1.Parent           = frame

makeToggle(88, "Egg ESP", function(active)
    espEnabled = active
    if not active then
        espFolder:ClearAllChildren()
        countLabel.Text = ""
    end
end)

makeToggle(118, "Noclip", function(active)
    noclipEnabled = active
    if active then enableNoclip() else disableNoclip() end
end)

makeToggle(148, "Fly  (WASD + Space/Shift)", function(active)
    flyEnabled = active
    if active then enableFly() else disableFly() end
end)

-- ── Divider: Movement ─────────────────────────────────────────────────────────
local div2 = Instance.new("Frame")
div2.Size             = UDim2.new(1, -12, 0, 1)
div2.Position         = UDim2.new(0, 6, 0, 178)
div2.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
div2.BorderSizePixel  = 0
div2.Parent           = frame

local secLbl = Instance.new("TextLabel")
secLbl.Size                   = UDim2.new(1, -12, 0, 14)
secLbl.Position               = UDim2.new(0, 6, 0, 182)
secLbl.BackgroundTransparency = 1
secLbl.Text                   = "MOVEMENT"
secLbl.TextColor3             = Color3.fromRGB(90, 90, 90)
secLbl.TextSize               = 10
secLbl.Font                   = Enum.Font.GothamBold
secLbl.TextXAlignment         = Enum.TextXAlignment.Left
secLbl.Parent                 = frame

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

    local resetBg = Instance.new("Frame")
    resetBg.Size             = UDim2.new(0, 22, 0, 18)
    resetBg.Position         = UDim2.new(1, -26, 0.5, -9)
    resetBg.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
    resetBg.BorderSizePixel  = 0
    resetBg.Parent           = row
    Instance.new("UICorner", resetBg).CornerRadius = UDim.new(0, 4)

    local resetBtn = Instance.new("TextButton")
    resetBtn.Size                   = UDim2.new(1, 0, 1, 0)
    resetBtn.BackgroundTransparency = 1
    resetBtn.Text                   = "R"
    resetBtn.TextColor3             = Color3.fromRGB(255, 160, 60)
    resetBtn.TextSize               = 11
    resetBtn.Font                   = Enum.Font.GothamBold
    resetBtn.Parent                 = resetBg

    resetBg.MouseEnter:Connect(function() resetBg.BackgroundColor3 = Color3.fromRGB(100, 100, 100) end)
    resetBg.MouseLeave:Connect(function() resetBg.BackgroundColor3 = Color3.fromRGB(70, 70, 70)   end)

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

makeSlider(198, "Fly spd",  1,   20,              1,               1, function(v) flySpeed = v end)
makeSlider(228, "Walk spd", 1, 1000, initialWalkSpeed, initialWalkSpeed, function(v)
    walkSpeed = v
    local hum = getHumanoid()
    if hum then hum.WalkSpeed = v end
end)
makeSlider(258, "Jump pwr", 1, 1000, initialJumpPower, initialJumpPower, function(v)
    jumpPower = v
    local hum = getHumanoid()
    if hum then hum.JumpPower = v end
end)

-- ── Divider: Expedition ───────────────────────────────────────────────────────
local div3 = Instance.new("Frame")
div3.Size             = UDim2.new(1, -12, 0, 1)
div3.Position         = UDim2.new(0, 6, 0, 288)
div3.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
div3.BorderSizePixel  = 0
div3.Parent           = frame

local expLbl = Instance.new("TextLabel")
expLbl.Size                   = UDim2.new(1, -12, 0, 14)
expLbl.Position               = UDim2.new(0, 6, 0, 292)
expLbl.BackgroundTransparency = 1
expLbl.Text                   = "EXPEDITION"
expLbl.TextColor3             = Color3.fromRGB(90, 90, 90)
expLbl.TextSize               = 10
expLbl.Font                   = Enum.Font.GothamBold
expLbl.TextXAlignment         = Enum.TextXAlignment.Left
expLbl.Parent                 = frame

makeToggle(310, "Speed Boost (auto on dive)", function(active)
    expSpeedEnabled = active
    if not active then
        local hum = getHumanoid()
        if hum and IN_EXPEDITION then
            hum.WalkSpeed = walkSpeed
        end
    end
end)

makeToggle(340, "Clear Fog (auto on dive)", function(active)
    expFogEnabled = active
    if active and IN_EXPEDITION then
        clearFog()
    elseif not active then
        restoreFog()
    end
end)

makeToggle(370, "Auto Fish / Harpoon", function(active)
    autoFishEnabled = active
end)

-- Surface now button
local surfBtnBg = Instance.new("Frame")
surfBtnBg.Size             = UDim2.new(1, -12, 0, 26)
surfBtnBg.Position         = UDim2.new(0, 6, 0, 400)
surfBtnBg.BackgroundColor3 = Color3.fromRGB(40, 100, 180)
surfBtnBg.BorderSizePixel  = 0
surfBtnBg.Parent           = frame
Instance.new("UICorner", surfBtnBg).CornerRadius = UDim.new(0, 6)

local surfBtn = Instance.new("TextButton")
surfBtn.Size                   = UDim2.new(1, 0, 1, 0)
surfBtn.BackgroundTransparency = 1
surfBtn.Text                   = "Surface Now"
surfBtn.TextColor3             = Color3.fromRGB(255, 255, 255)
surfBtn.TextSize               = 12
surfBtn.Font                   = Enum.Font.GothamBold
surfBtn.Parent                 = surfBtnBg

surfBtnBg.MouseEnter:Connect(function() surfBtnBg.BackgroundColor3 = Color3.fromRGB(60, 130, 220) end)
surfBtnBg.MouseLeave:Connect(function() surfBtnBg.BackgroundColor3 = Color3.fromRGB(40, 100, 180) end)
surfBtn.MouseButton1Click:Connect(function()
    local char = player.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if hrp then hrp.CFrame = CFrame.new(EXPEDITION_BACK + Vector3.new(0, 4, 0)) end
end)

makeToggle(430, "Auto Surface at 30% HP", function(active)
    autoSurfaceEnabled = active
end)

makeSlider(460, "Exp spd", 1, 500, 80, 80, function(v)
    EXP_SPEED = v
    local hum = getHumanoid()
    if hum and IN_EXPEDITION and expSpeedEnabled then
        hum.WalkSpeed = v
    end
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
    while true do
        if running then
            statusLabel.Text       = dots[dotIdx]
            statusLabel.TextColor3 = Color3.fromRGB(80, 200, 120)
            dotIdx = (dotIdx % #dots) + 1
        end
        task.wait(0.6)
    end
end)

-- ── ESP ───────────────────────────────────────────────────────────────────────
local function updateEsp()
    espFolder:ClearAllChildren()
    if not espEnabled then return end

    local count = 0
    for _, egg in ipairs(activeEggs:GetChildren()) do
        count += 1
        local hitbox = egg:FindFirstChild("Hitbox")
        if not hitbox then continue end
        local main = hitbox:FindFirstChildWhichIsA("BasePart")
        if not main then continue end

        local isCollected = collectedIds[egg.Name]
        local color = isCollected
            and Color3.fromRGB(80, 80, 80)
            or  Color3.fromRGB(255, 210, 80)

        local hl = Instance.new("Highlight")
        hl.Adornee             = main
        hl.FillColor           = color
        hl.OutlineColor        = color
        hl.FillTransparency    = 0.5
        hl.OutlineTransparency = 0
        hl.Parent              = espFolder

        local bb = Instance.new("BillboardGui")
        bb.Adornee     = main
        bb.Size        = UDim2.new(0, 80, 0, 20)
        bb.StudsOffset = Vector3.new(0, 4, 0)
        bb.AlwaysOnTop = true
        bb.Parent      = espFolder

        local txt = Instance.new("TextLabel")
        txt.Size                   = UDim2.new(1, 0, 1, 0)
        txt.BackgroundTransparency = 1
        txt.Text                   = egg.Name
        txt.TextColor3             = color
        txt.TextSize               = 12
        txt.Font                   = Enum.Font.GothamBold
        txt.Parent                 = bb
    end

    countLabel.Text = count .. " egg" .. (count == 1 and "" or "s") .. " on map"
end

task.spawn(function()
    while true do
        updateEsp()
        task.wait(0.5)
    end
end)

-- ── Expedition movement boost ───────────────────────────────────────────────
local expBodyVel = nil

local function enableExpSpeed()
    local char = player.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    if expBodyVel then expBodyVel:Destroy() end
    expBodyVel          = Instance.new("BodyVelocity")
    expBodyVel.Velocity = Vector3.zero
    expBodyVel.MaxForce = Vector3.new(1e5, 1e5, 1e5)
    expBodyVel.Parent   = hrp
end

local function disableExpSpeed()
    if expBodyVel then
        expBodyVel:Destroy()
        expBodyVel = nil
    end
end

-- ── Expedition watcher ────────────────────────────────────────────────────────
RunService.Heartbeat:Connect(function()
    local inExp = isInExpedition()

    if inExp and not IN_EXPEDITION then
        IN_EXPEDITION = true
        if expSpeedEnabled then enableExpSpeed() end
        if expFogEnabled   then clearFog()       end

    elseif not inExp and IN_EXPEDITION then
        IN_EXPEDITION = false
        disableExpSpeed()
        if expFogEnabled then restoreFog() end
    end

    -- Auto surface on low HP
    if IN_EXPEDITION and autoSurfaceEnabled then
        local char = player.Character
        local hum  = char and char:FindFirstChildOfClass("Humanoid")
        if hum and hum.MaxHealth > 0 and (hum.Health / hum.MaxHealth) <= SURFACE_HP_PCT then
            local hrp = char:FindFirstChild("HumanoidRootPart")
            if hrp then
                hrp.CFrame = CFrame.new(EXPEDITION_BACK + Vector3.new(0, 4, 0))
            end
        end
    end

    -- Update expedition speed boost direction
    if IN_EXPEDITION and expSpeedEnabled and expBodyVel and expBodyVel.Parent then
        local cam = workspace.CurrentCamera
        local dir = Vector3.zero
        if UserInputService:IsKeyDown(Enum.KeyCode.W)         then dir += cam.CFrame.LookVector  end
        if UserInputService:IsKeyDown(Enum.KeyCode.S)         then dir -= cam.CFrame.LookVector  end
        if UserInputService:IsKeyDown(Enum.KeyCode.A)         then dir -= cam.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D)         then dir += cam.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space)     then dir += Vector3.new(0,1,0)     end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then dir -= Vector3.new(0,1,0)     end
        if dir.Magnitude > 0 then dir = dir.Unit end
        expBodyVel.Velocity = dir * EXP_SPEED
    elseif expBodyVel and expBodyVel.Parent then
        expBodyVel.Velocity = Vector3.zero
    end

    -- fog is handled by hooks, no polling needed
end)

-- Clean up exp speed on character respawn
player.CharacterAdded:Connect(function()
    expBodyVel = nil
    if IN_EXPEDITION and expSpeedEnabled then
        task.wait(1)
        enableExpSpeed()
    end
end)

-- ── Trade detection ───────────────────────────────────────────────────────────
local function onTradeDetected()
    collectedIds = {}
end

local function onItemAdded(item)
    if item.Name:lower():find("easter") or item.Name:lower():find("bucket") then
        onTradeDetected()
    end
end

player.Backpack.ChildAdded:Connect(onItemAdded)
player.ChildAdded:Connect(onItemAdded)

activeEggs.ChildRemoved:Connect(function()
    task.wait(0.5)
    if #activeEggs:GetChildren() == 0 then
        onTradeDetected()
    end
end)

-- ── Teleport & collector ──────────────────────────────────────────────────────
local function teleportTo(cf)
    local char = player.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if hrp then hrp.CFrame = cf + Vector3.new(0, 4, 0) end
end

local function collectAll()
    local eggs = activeEggs:GetChildren()
    for _, egg in ipairs(eggs) do
        if not running then return end
        if collectedIds[egg.Name] then continue end

        local hitbox = egg:FindFirstChild("Hitbox")
        if not hitbox then continue end

        local prompt = hitbox:FindFirstChild("CollectPrompt")
        if not prompt then continue end

        prompt.MaxActivationDistance = math.huge
        teleportTo(hitbox.CFrame)
        task.wait(0.1)
        fireproximityprompt(prompt)
        task.wait(COLLECT_DELAY)

        if egg.Parent ~= nil then
            collectedIds[egg.Name] = true
        end
    end
end


-- ── Auto Fish / Harpoon ───────────────────────────────────────────────────────
-- Watches HitTheZoneCircleUI > Holder > Main > Arrow and Target
-- When Arrow.Rotation is within Target arc, fires mouse1click()

local function getMinigameElements()
    local pg = player.PlayerGui
    local gui = pg:FindFirstChild("HitTheZoneCircleUI")
    if not gui then return nil end
    local holder = gui:FindFirstChild("Holder")
    if not holder then return nil end
    local main = holder:FindFirstChild("Main")
    if not main then return nil end
    return main:FindFirstChild("Arrow"), main:FindFirstChild("Target"), holder
end

-- Normalize angle to 0-360
local function normAngle(a)
    return ((a % 360) + 360) % 360
end

-- Check if angle is within an arc centered at targetRot with given width
local function inArc(arrowRot, targetRot, arcWidth)
    local diff = normAngle(arrowRot - targetRot + 180) - 180
    return math.abs(diff) <= arcWidth / 2
end

local lastClick    = 0
local lastArrowRot = nil
local wasInZone    = false

-- ARC_HALF: half the blue zone width in degrees
local ARC_HALF = 35

-- CLICK_OFFSET: how many degrees before the zone edge to fire the click
-- Compensates for the small delay between detection and mouse1click() executing
-- Positive = click earlier (before entry), negative = click later (inside zone)
local CLICK_OFFSET = -4

RunService.Heartbeat:Connect(function()
    if not autoFishEnabled then return end
    local arrow, target, holder = getMinigameElements()
    if not arrow or not target or not holder then return end
    if not holder.Visible then
        lastArrowRot = nil
        wasInZone    = false
        return
    end

    local arrowRot  = arrow.Rotation
    local targetRot = target.Rotation

    -- Detect entry into zone using leading edge
    -- Figure out spin direction
    local spinDir = 0
    if lastArrowRot then
        local delta = normAngle(arrowRot - lastArrowRot + 180) - 180
        if delta > 0 then spinDir = 1 elseif delta < 0 then spinDir = -1 end
    end
    lastArrowRot = arrowRot

    -- Apply offset in the direction of spin so we click slightly ahead of entry
    local adjustedArrow = arrowRot + (spinDir * CLICK_OFFSET)
    local diff = normAngle(adjustedArrow - targetRot + 180) - 180
    local inZone = math.abs(diff) <= ARC_HALF

    -- Click on the moment we enter the zone (transition from outside to inside)
    if inZone and not wasInZone then
        local now = tick()
        if (now - lastClick) > 0.2 then
            lastClick = now
            mouse1click()
            wasInZone = false  -- reset immediately so next spawn is detected right away
        end
    else
        wasInZone = inZone
    end
end)
-- ── Main loop ─────────────────────────────────────────────────────────────────
while true do
    if running then
        collectAll()
        if running then task.wait(LOOP_DELAY) end
    else
        task.wait(0.1)
    end
end






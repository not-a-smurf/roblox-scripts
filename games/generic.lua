local Players          = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService       = game:GetService("RunService")

local player = Players.LocalPlayer

local running       = false
local flyEnabled    = false
local noclipEnabled = false
local flySpeed      = 1
local walkSpeed     = 16
local jumpPower     = 50

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

player.CharacterAdded:Connect(function(char)
    task.wait(1)
    local hum = char:WaitForChild("Humanoid")
    hum.WalkSpeed = walkSpeed
    hum.JumpPower = jumpPower
    if noclipEnabled then enableNoclip() end
    if flyEnabled    then enableFly()    end
end)

-- ── GUI ───────────────────────────────────────────────────────────────────────
local W, H = 220, 235

local screenGui = Instance.new("ScreenGui")
screenGui.Name           = "Generic"
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
titleLabel.Text                   = "Generic — PlaceId: " .. game.PlaceId
titleLabel.TextColor3             = Color3.fromRGB(180, 180, 180)
titleLabel.TextSize               = 11
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
closeBtn.Text                   = "✕"
closeBtn.TextColor3             = Color3.fromRGB(255, 255, 255)
closeBtn.TextSize               = 12
closeBtn.Font                   = Enum.Font.GothamBold
closeBtn.Parent                 = closeBg

closeBg.MouseEnter:Connect(function() closeBg.BackgroundColor3 = Color3.fromRGB(255, 60, 60) end)
closeBg.MouseLeave:Connect(function() closeBg.BackgroundColor3 = Color3.fromRGB(200, 50, 50) end)
closeBtn.MouseButton1Click:Connect(function()
    disableFly()
    disableNoclip()
    screenGui:Destroy()
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

makeToggle(32, "Noclip", function(active)
    noclipEnabled = active
    if active then enableNoclip() else disableNoclip() end
end)

makeToggle(62, "Fly  (WASD + Space/Shift)", function(active)
    flyEnabled = active
    if active then enableFly() else disableFly() end
end)

local div = Instance.new("Frame")
div.Size             = UDim2.new(1, -12, 0, 1)
div.Position         = UDim2.new(0, 6, 0, 92)
div.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
div.BorderSizePixel  = 0
div.Parent           = frame

local secLbl = Instance.new("TextLabel")
secLbl.Size                   = UDim2.new(1, -12, 0, 14)
secLbl.Position               = UDim2.new(0, 6, 0, 96)
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

makeSlider(112, "Fly spd",  1,   20,              1,               1, function(v) flySpeed = v end)
makeSlider(142, "Walk spd", 1, 1000, initialWalkSpeed, initialWalkSpeed, function(v)
    walkSpeed = v
    local hum = getHumanoid()
    if hum then hum.WalkSpeed = v end
end)
makeSlider(172, "Jump pwr", 1, 1000, initialJumpPower, initialJumpPower, function(v)
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

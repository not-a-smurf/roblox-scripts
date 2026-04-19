-- Peroxide ESP sender

local Players     = game:GetService("Players")
local RunService  = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera
local PORT   = 7842
local URL    = "http://127.0.0.1:" .. PORT
local SEND_RATE = 0.01  -- 100 times per second

-- Kill any previous instance
if _G.PeroxideESP_Stop then
    _G.PeroxideESP_Stop()
end
local alive = true
local connections = {}
local cached = {}

local function track(conn)
    table.insert(connections, conn)
    return conn
end

_G.PeroxideESP_Stop = function()
    alive = false
    for _, c in ipairs(connections) do
        pcall(function() c:Disconnect() end)
    end
    connections = {}
    cached = {}
end

local function sendData(body)
    pcall(function()
        http_request({
            Url     = URL,
            Method  = "POST",
            Headers = { ["Content-Type"] = "application/json" },
            Body    = body
        })
    end)
end

-- Helpers
local function getNPCType(model)
    local name = model.Name:lower()
    if name:find("vastolorde") or name:find("vastocar") or name:find("vastohollow") then
        return "vasto"
    elseif name:find("adjuchas") then
        return "adjuchas"
    elseif name:find("normalhallow") or name:find("normalhollow") then
        return "hollow"
    end
    return "hollow"
end

local function isVastoLorde(model)
    local name = model.Name:lower()
    return name:find("vastolorde") or name:find("vastocar") or name:find("vastohollow")
end

local function isEggNPC(model)
    local head = model:FindFirstChild("Head")
    if not head then return false end
    for _, v in ipairs(head:GetDescendants()) do
        if v.Name:lower():find("egg") then return true end
    end
    return false
end

local function getEggName(model)
    local head = model:FindFirstChild("Head")
    if not head then return "Egg Hollow" end
    for _, v in ipairs(head:GetDescendants()) do
        if v.Name:lower():find("egg") then return v.Name end
    end
    return "Egg Hollow"
end

local function getQuestName(model)
    -- Try GetAttribute first
    local fn, cl = "", ""
    pcall(function() fn = model:GetAttribute("First_Name") or "" end)
    pcall(function() cl = model:GetAttribute("Clan") or "" end)

    -- Fallback: check Stats folder for StringValue/StringValue children
    if fn == "" then
        local stats = model:FindFirstChild("Stats")
        if stats then
            local fnVal = stats:FindFirstChild("First_Name")
            local clVal = stats:FindFirstChild("Clan")
            if fnVal and fnVal.Value then fn = tostring(fnVal.Value) end
            if clVal and clVal.Value then cl = tostring(clVal.Value) end
        end
    end

    local qn = (fn .. " " .. cl):gsub("^%s+", ""):gsub("%s+$", "")
    return qn ~= "" and qn or model.Name
end

local function getItemName(itemDrop)
    local handle = itemDrop:FindFirstChild("Handle")
    if not handle then return "Item Drop" end
    local bb = handle:FindFirstChildOfClass("BillboardGui")
    if bb then
        local lbl = bb:FindFirstChildOfClass("TextLabel")
        if lbl and lbl.Text ~= "" then return lbl.Text end
    end
    return "Item Drop"
end

local function getMoneyAmount(moneyPart)
    if not moneyPart or not moneyPart.Parent then return "Yen ?" end
    local bb = moneyPart:FindFirstChildOfClass("BillboardGui")
    if bb then
        local lbl = bb:FindFirstChildOfClass("TextLabel")
        if lbl and lbl.Text ~= "" then return "Yen " .. lbl.Text end
    end
    return "Yen ?"
end

-- Cache management
local function addEntry(entry)
    if not alive then return end
    for _, e in ipairs(cached) do
        if e.part == entry.part then return end
    end
    table.insert(cached, entry)
end

local function removeByPart(part)
    for i = #cached, 1, -1 do
        if cached[i].part == part then
            table.remove(cached, i)
        end
    end
end

-- Watch NPCs
local charsFolder = workspace:WaitForChild("Live", 10)

local function tryAddNPC(model)
    if not alive then return end
    local isPlayer = false
    for _, p in ipairs(Players:GetPlayers()) do
        if p.Character == model then isPlayer = true break end
    end
    if isPlayer then return end

    local hrp = model:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local hasEgg = isEggNPC(model)
    local isVasto = isVastoLorde(model)

    if not hasEgg and not isVasto then return end

    local npcType = getNPCType(model)
    local espType = "npc_hollow"
    if npcType == "adjuchas" then
        espType = "npc_adjuchas"
    elseif npcType == "vasto" then
        espType = "npc_vasto"
    end

    local displayName = isVasto and "Vasto Lorde" or getEggName(model)
    local questName   = isVasto and getQuestName(model) or ""

    addEntry({
        type      = espType,
        name      = displayName,
        modelName = questName,
        part      = hrp,
        hum       = model:FindFirstChildOfClass("Humanoid"),
    })
    track(model.AncestryChanged:Connect(function(_, parent)
        if not parent then removeByPart(hrp) end
    end))
end

local function watchNPC(model)
    if not alive then return end
    if not model:IsA("Model") then return end
    task.wait(0.3)
    if not alive then return end
    if not model:FindFirstChildOfClass("Humanoid") then return end
    tryAddNPC(model)
    local head = model:FindFirstChild("Head")
    if head then
        track(head.ChildAdded:Connect(function()
            task.wait(0.05)
            tryAddNPC(model)
        end))
    end
end

if charsFolder then
    for _, obj in ipairs(charsFolder:GetChildren()) do
        task.spawn(watchNPC, obj)
    end
    track(charsFolder.ChildAdded:Connect(function(obj)
        task.spawn(watchNPC, obj)
    end))
end

-- Watch Effects
local effectsFolder = workspace:WaitForChild("Effects", 10)

local function watchEffect(obj)
    if not alive then return end
    if obj:IsA("BasePart") and obj.Name:lower() == "egg" then
        addEntry({ type = "map_egg", name = "Map Egg", part = obj, hum = nil })
        track(obj.AncestryChanged:Connect(function(_, p)
            if not p then removeByPart(obj) end
        end))
    elseif obj.Name == "ItemDrop" and obj:IsA("Model") then
        task.wait(0.1)
        if not alive then return end
        local handle = obj:FindFirstChild("Handle")
        if handle and handle:IsA("BasePart") then
            addEntry({ type = "item_drop", name = getItemName(obj), part = handle, hum = nil })
            track(obj.AncestryChanged:Connect(function(_, p)
                if not p then removeByPart(handle) end
            end))
        end
    elseif obj.Name == "Money" and obj:IsA("BasePart") then
        addEntry({ type = "money", name = getMoneyAmount(obj), part = obj, hum = nil })
        track(obj.AncestryChanged:Connect(function(_, p)
            if not p then removeByPart(obj) end
        end))
    end
end

if effectsFolder then
    for _, obj in ipairs(effectsFolder:GetDescendants()) do
        task.spawn(watchEffect, obj)
    end
    track(effectsFolder.DescendantAdded:Connect(function(obj)
        task.spawn(watchEffect, obj)
    end))
end

-- Watch Storm Delve objects
local chestsFolder  = workspace:FindFirstChild("Chests")
local orbsFolder    = workspace:FindFirstChild("Orbs")
local rewardBoxes   = workspace  -- RewardBoxes are direct children of workspace

local function watchChest(obj)
    if not alive then return end
    if not obj.Name:find("Chest_") then return end
    if not obj:IsA("Model") then return end
    local primary = obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")
    if not primary then return end
    addEntry({ type = "storm_chest", name = "Chest", part = primary, hum = nil, modelName = "" })
    track(obj.AncestryChanged:Connect(function(_, p)
        if not p then removeByPart(primary) end
    end))
end

local function watchOrb(obj)
    if not alive then return end
    if not obj:IsA("BasePart") and not obj:IsA("Model") then return end
    local primary = obj:IsA("BasePart") and obj or (obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart"))
    if not primary then return end
    addEntry({ type = "storm_orb", name = "Orb", part = primary, hum = nil, modelName = "" })
    track(obj.AncestryChanged:Connect(function(_, p)
        if not p then removeByPart(primary) end
    end))
end

local function watchRewardBox(obj)
    if not alive then return end
    if not obj.Name:find("RewardBox_") then return end
    if not obj:IsA("Model") then return end
    local primary = obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")
    if not primary then return end
    addEntry({ type = "storm_reward", name = "Reward Box", part = primary, hum = nil, modelName = "" })
    track(obj.AncestryChanged:Connect(function(_, p)
        if not p then removeByPart(primary) end
    end))
end

-- Seed existing and watch for new storm objects
task.spawn(function()
    task.wait(2)  -- wait for workspace to populate
    if not alive then return end

    chestsFolder = workspace:FindFirstChild("Chests")
    orbsFolder   = workspace:FindFirstChild("Orbs")

    if chestsFolder then
        for _, obj in ipairs(chestsFolder:GetChildren()) do task.spawn(watchChest, obj) end
        track(chestsFolder.ChildAdded:Connect(function(obj) task.spawn(watchChest, obj) end))
    end

    if orbsFolder then
        for _, obj in ipairs(orbsFolder:GetChildren()) do task.spawn(watchOrb, obj) end
        track(orbsFolder.ChildAdded:Connect(function(obj) task.spawn(watchOrb, obj) end))
    end

    -- Watch workspace direct children for RewardBoxes
    for _, obj in ipairs(workspace:GetChildren()) do
        if obj.Name:find("RewardBox_") then task.spawn(watchRewardBox, obj) end
    end
    track(workspace.ChildAdded:Connect(function(obj)
        if obj.Name:find("RewardBox_") then task.spawn(watchRewardBox, obj) end
        -- Also watch if Chests/Orbs folders appear late
        if obj.Name == "Chests" then
            for _, c2 in ipairs(obj:GetChildren()) do task.spawn(watchChest, c2) end
            track(obj.ChildAdded:Connect(function(c2) task.spawn(watchChest, c2) end))
        end
        if obj.Name == "Orbs" then
            for _, o2 in ipairs(obj:GetChildren()) do task.spawn(watchOrb, o2) end
            track(obj.ChildAdded:Connect(function(o2) task.spawn(watchOrb, o2) end))
        end
    end))
end)

-- Send loop
local lastSend = 0
track(RunService.Heartbeat:Connect(function()
    if not alive then return end
    local now = tick()
    if (now - lastSend) < SEND_RATE then return end
    lastSend = now

    local char  = player.Character
    if not char then return end
    local myHrp = char:FindFirstChild("HumanoidRootPart")
    if not myHrp then return end

    local npcs = {}

    for i = #cached, 1, -1 do
        local entry = cached[i]
        local part  = entry.part
        if not part or not part.Parent then
            table.remove(cached, i)
            continue
        end

        local sp, vis = camera:WorldToViewportPoint(part.Position)
        local vp = camera.ViewportSize
        local onScreen = vis
            and sp.X > -100 and sp.X < vp.X + 100
            and sp.Y > -100 and sp.Y < vp.Y + 100

        if onScreen then
            local dist = (part.Position - myHrp.Position).Magnitude
            local hp, maxhp = -1, -1
            if entry.hum and entry.hum.Parent then
                hp    = math.floor(entry.hum.Health)
                maxhp = math.floor(entry.hum.MaxHealth)
            end
            local name = entry.name
            if entry.type == "money" then
                name = getMoneyAmount(part)
            end
            table.insert(npcs, {
                type      = entry.type,
                name      = name,
                modelName = entry.modelName or "",
                sx        = math.floor(sp.X),
                sy        = math.floor(sp.Y),
                dist      = math.floor(dist),
                visible   = vis,
                hp        = hp,
                maxhp     = maxhp,
            })
        end
    end

    sendData(HttpService:JSONEncode({ npcs = npcs }))
end))

--// ===== Services =====
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

--// ===== UI (Simple, No Web) =====
local gui = Instance.new("ScreenGui")
gui.Name = "AbyssESPUI"
pcall(function() gui.Parent = game.CoreGui end)

local frame = Instance.new("Frame", gui)
frame.Size = UDim2.new(0, 220, 0, 210)
frame.Position = UDim2.new(0, 20, 0, 120)
frame.BackgroundColor3 = Color3.fromRGB(25,25,25)
frame.BorderSizePixel = 0
frame.Active = true
frame.Draggable = true

local corner = Instance.new("UICorner", frame)
corner.CornerRadius = UDim.new(0, 12)

local title = Instance.new("TextLabel", frame)
title.Size = UDim2.new(1, 0, 0, 30)
title.BackgroundTransparency = 1
title.Text = "Abyss ESP"
title.TextColor3 = Color3.fromRGB(255,255,255)
title.Font = Enum.Font.SourceSansBold
title.TextSize = 18

local function makeButton(text, y)
    local btn = Instance.new("TextButton", frame)
    btn.Size = UDim2.new(1, -20, 0, 35)
    btn.Position = UDim2.new(0, 10, 0, y)
    btn.BackgroundColor3 = Color3.fromRGB(40,40,40)
    btn.TextColor3 = Color3.fromRGB(255,255,255)
    btn.Font = Enum.Font.SourceSansBold
    btn.TextSize = 16
    btn.Text = text
    local c = Instance.new("UICorner", btn)
    c.CornerRadius = UDim.new(0, 8)
    return btn
end

local chestBtn = makeButton("Chest ESP : OFF", 40)
local duckBtn  = makeButton("Duck ESP : OFF", 80)
local miniBtn  = makeButton("Minimize UI", 120)

-- ปุ่มเล็กมุมจอ
local toggleGui = Instance.new("ScreenGui")
toggleGui.Name = "AbyssToggleGui"
pcall(function() toggleGui.Parent = game.CoreGui end)

local toggleBtn = Instance.new("TextButton", toggleGui)
toggleBtn.Size = UDim2.new(0, 50, 0, 50)
toggleBtn.Position = UDim2.new(0, 10, 1, -60)
toggleBtn.Text = "A"
toggleBtn.BackgroundColor3 = Color3.fromRGB(20,20,20)
toggleBtn.TextColor3 = Color3.fromRGB(255,0,0)
toggleBtn.TextScaled = true
toggleBtn.BorderSizePixel = 0
toggleBtn.Visible = false
local tc = Instance.new("UICorner", toggleBtn)
tc.CornerRadius = UDim.new(0, 12)

--// ===== States =====
local ChestESPEnabled = false
local DuckESPEnabled = false

--// ===== Paths =====
local chestsRoot = workspace:WaitForChild("Game"):WaitForChild("Chests")
local ducksRoot = workspace:WaitForChild("Game"):WaitForChild("QuestItems"):WaitForChild("SecretRoom"):WaitForChild("Ducks")

--// ===== Data =====
local trackedChests = {}
local trackedDucks = {}

local tierColors = {
    ["Tier 1"] = Color3.fromRGB(0,255,0),
    ["Tier 2"] = Color3.fromRGB(0,150,255),
    ["Tier 3"] = Color3.fromRGB(255,0,0),
}

local DUCK_COLOR = Color3.fromRGB(255,255,0)

--// ===== Helpers =====
local function hasRewardPart(chestModel)
    for _, v in ipairs(chestModel:GetDescendants()) do
        if v:IsA("MeshPart") and v.Name == "RewardPart" then
            return true
        end
    end
    return false
end

local function shouldHideDuck(duck)
    local cube = duck:FindFirstChild("Cube.008", true)
    if cube and cube:IsA("BasePart") and cube.Transparency == 1 then
        return true
    end
    return false
end

--// ===== Remove =====
local function removeChestESP(model)
    if model:FindFirstChild("ChestHighlight") then model.ChestHighlight:Destroy() end
    if model:FindFirstChild("ChestTierESP") then model.ChestTierESP:Destroy() end
end

local function removeDuckESP(model)
    if model:FindFirstChild("DuckHighlight") then model.DuckHighlight:Destroy() end
    if model:FindFirstChild("DuckESP") then model.DuckESP:Destroy() end
end

--// ===== Add Chest =====
local function addChestESP(chestModel, tierFolder)
    if not ChestESPEnabled then return end
    if chestModel:FindFirstChild("ChestHighlight") then return end

    local color = tierColors[tierFolder.Name] or Color3.new(1,1,1)

    local h = Instance.new("Highlight")
    h.Name = "ChestHighlight"
    h.Adornee = chestModel
    h.FillTransparency = 1
    h.OutlineTransparency = 0
    h.OutlineColor = color
    h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    h.Parent = chestModel

    local adorneePart = chestModel.PrimaryPart or chestModel:FindFirstChildWhichIsA("BasePart")
    if not adorneePart then return end

    local billboard = Instance.new("BillboardGui")
    billboard.Name = "ChestTierESP"
    billboard.Adornee = adorneePart
    billboard.AlwaysOnTop = true
    billboard.StudsOffset = Vector3.new(0, 2.2, 0)
    billboard.Size = UDim2.new(0, 80, 0, 30)

    local text = Instance.new("TextLabel", billboard)
    text.Size = UDim2.new(1,0,1,0)
    text.BackgroundTransparency = 1
    text.Text = tierFolder.Name
    text.TextScaled = true
    text.Font = Enum.Font.SourceSansBold
    text.TextColor3 = color
    text.TextStrokeTransparency = 0.2

    billboard.Parent = chestModel
    table.insert(trackedChests, {billboard = billboard, adornee = adorneePart, model = chestModel})
end

local function scanChests()
    for _, tierFolder in ipairs(chestsRoot:GetChildren()) do
        if tierFolder:IsA("Folder") or tierFolder:IsA("Model") then
            for _, v in ipairs(tierFolder:GetDescendants()) do
                if v:IsA("Model") and v.Name == "Chest" and hasRewardPart(v) then
                    addChestESP(v, tierFolder)
                end
            end
        end
    end
end

--// ===== Add Duck =====
local function addDuckESP(duck)
    if not DuckESPEnabled then return end
    if duck:FindFirstChild("DuckHighlight") then return end
    if shouldHideDuck(duck) then return end

    local h = Instance.new("Highlight")
    h.Name = "DuckHighlight"
    h.Adornee = duck
    h.FillTransparency = 1
    h.OutlineTransparency = 0
    h.OutlineColor = DUCK_COLOR
    h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    h.Parent = duck

    local adorneePart = duck.PrimaryPart or duck:FindFirstChildWhichIsA("BasePart")
    if not adorneePart then return end

    local billboard = Instance.new("BillboardGui")
    billboard.Name = "DuckESP"
    billboard.Adornee = adorneePart
    billboard.AlwaysOnTop = true
    billboard.StudsOffset = Vector3.new(0, 2.2, 0)
    billboard.Size = UDim2.new(0, 80, 0, 30)

    local text = Instance.new("TextLabel", billboard)
    text.Size = UDim2.new(1,0,1,0)
    text.BackgroundTransparency = 1
    text.Text = duck.Name
    text.TextScaled = true
    text.Font = Enum.Font.SourceSansBold
    text.TextColor3 = DUCK_COLOR
    text.TextStrokeTransparency = 0.2

    billboard.Parent = duck
    table.insert(trackedDucks, {billboard = billboard, adornee = adorneePart, model = duck})
end

local function scanDucks()
    for _, v in ipairs(ducksRoot:GetChildren()) do
        if (v:IsA("Model") or v:IsA("BasePart")) and string.find(string.lower(v.Name), "duck") then
            addDuckESP(v)
        end
    end
end

--// ===== Buttons =====
chestBtn.MouseButton1Click:Connect(function()
    ChestESPEnabled = not ChestESPEnabled
    chestBtn.Text = "Chest ESP : " .. (ChestESPEnabled and "ON" or "OFF")

    if ChestESPEnabled then
        scanChests()
    else
        for _, tier in ipairs(chestsRoot:GetChildren()) do
            for _, v in ipairs(tier:GetDescendants()) do
                if v:IsA("Model") and v.Name == "Chest" then
                    removeChestESP(v)
                end
            end
        end
        trackedChests = {}
    end
end)

duckBtn.MouseButton1Click:Connect(function()
    DuckESPEnabled = not DuckESPEnabled
    duckBtn.Text = "Duck ESP : " .. (DuckESPEnabled and "ON" or "OFF")

    if DuckESPEnabled then
        scanDucks()
    else
        for _, v in ipairs(ducksRoot:GetChildren()) do
            removeDuckESP(v)
        end
        trackedDucks = {}
    end
end)

-- ปุ่มพับ UI
miniBtn.MouseButton1Click:Connect(function()
    gui.Enabled = false
    toggleBtn.Visible = true
end)

-- ปุ่มเล็กเปิดกลับ
toggleBtn.MouseButton1Click:Connect(function()
    gui.Enabled = true
    toggleBtn.Visible = false
end)

--// ===== Realtime Update =====
RunService.RenderStepped:Connect(function()
    -- Ducks
    for i = #trackedDucks, 1, -1 do
        local item = trackedDucks[i]
        if not DuckESPEnabled or not item.model or not item.model.Parent or shouldHideDuck(item.model) then
            if item.model then removeDuckESP(item.model) end
            table.remove(trackedDucks, i)
        else
            local dist = (Camera.CFrame.Position - item.adornee.Position).Magnitude
            local size = math.clamp(2000 / dist, 20, 80)
            item.billboard.Size = UDim2.new(0, size, 0, size * 0.4)
        end
    end

    -- Chests
    for i = #trackedChests, 1, -1 do
        local item = trackedChests[i]
        if not ChestESPEnabled or not item.model or not item.model.Parent then
            if item.model then removeChestESP(item.model) end
            table.remove(trackedChests, i)
        else
            local dist = (Camera.CFrame.Position - item.adornee.Position).Magnitude
            local size = math.clamp(2000 / dist, 20, 80)
            item.billboard.Size = UDim2.new(0, size, 0, size * 0.4)
        end
    end
end)

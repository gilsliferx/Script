local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local Camera = workspace.CurrentCamera
local Player = Players.LocalPlayer

-- ====== UI Toggle ======
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ESP_UI"
ScreenGui.Parent = Player:WaitForChild("PlayerGui")

local ToggleBtn = Instance.new("TextButton")
ToggleBtn.Size = UDim2.new(0, 140, 0, 40)
ToggleBtn.Position = UDim2.new(0, 20, 0, 100)
ToggleBtn.Text = "ESP: ON"
ToggleBtn.BackgroundColor3 = Color3.fromRGB(40,40,40)
ToggleBtn.TextColor3 = Color3.fromRGB(255,255,255)
ToggleBtn.Parent = ScreenGui

local espEnabled = true
ToggleBtn.MouseButton1Click:Connect(function()
    espEnabled = not espEnabled
    ToggleBtn.Text = espEnabled and "ESP: ON" or "ESP: OFF"
end)

-- ====== Roots ======
local ducksRoot = workspace:WaitForChild("Game")
    :WaitForChild("QuestItems")
    :WaitForChild("SecretRoom")
    :WaitForChild("Ducks")

local chestsRoot = workspace:WaitForChild("Game"):WaitForChild("Chests")

-- ====== Colors ======
local DUCK_COLOR = Color3.fromRGB(255, 255, 0)
local tierColors = {
    ["Tier 1"] = Color3.fromRGB(0, 255, 0),
    ["Tier 2"] = Color3.fromRGB(0, 150, 255),
    ["Tier 3"] = Color3.fromRGB(255, 0, 0),
}

-- ====== Tracked ======
local tracked = {}

-- ====== Utils ======
local function getAdorneePart(obj)
    if obj:IsA("Model") then
        return obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")
    elseif obj:IsA("BasePart") then
        return obj
    end
end

local function findRewardPart(chestModel)
    if not chestModel or not chestModel:IsA("Model") then return nil end
    for _, v in ipairs(chestModel:GetDescendants()) do
        if v:IsA("MeshPart") and v.Name == "RewardPart" then
            return v
        end
    end
    return nil
end

-- ====== Duck ESP ======
local function addDuckESP(duck)
    if duck:FindFirstChild("DuckHighlight") then return end

    local h = Instance.new("Highlight")
    h.Name = "DuckHighlight"
    h.Adornee = duck
    h.FillTransparency = 1
    h.OutlineTransparency = 0
    h.OutlineColor = DUCK_COLOR
    h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    h.Parent = duck

    local adorneePart = getAdorneePart(duck)
    if not adorneePart then return end

    local billboard = Instance.new("BillboardGui")
    billboard.Name = "DuckESP"
    billboard.Adornee = adorneePart
    billboard.AlwaysOnTop = true
    billboard.StudsOffset = Vector3.new(0, 2.2, 0)
    billboard.Size = UDim2.new(0, 80, 0, 30)

    local text = Instance.new("TextLabel")
    text.Parent = billboard
    text.Size = UDim2.new(1, 0, 1, 0)
    text.BackgroundTransparency = 1
    text.Text = duck.Name
    text.TextScaled = true
    text.Font = Enum.Font.SourceSansBold
    text.TextColor3 = DUCK_COLOR
    text.TextStrokeTransparency = 0.2

    billboard.Parent = duck
    table.insert(tracked, {billboard = billboard, adornee = adorneePart, highlight = h, type = "duck", model = duck})
end

local function scanDucks()
    for _, v in ipairs(ducksRoot:GetChildren()) do
        if (v:IsA("Model") or v:IsA("BasePart")) and string.find(string.lower(v.Name), "duck") then
            addDuckESP(v)
        end
    end
end

ducksRoot.ChildAdded:Connect(function(v)
    if (v:IsA("Model") or v:IsA("BasePart")) and string.find(string.lower(v.Name), "duck") then
        addDuckESP(v)
    end
end)

-- ====== Chest ESP ======
local function addChestESP(chestModel, tierFolder)
    if chestModel:FindFirstChild("ChestHighlight") then return end

    local color = tierColors[tierFolder.Name] or Color3.fromRGB(255,255,255)

    local h = Instance.new("Highlight")
    h.Name = "ChestHighlight"
    h.Adornee = chestModel
    h.FillTransparency = 1
    h.OutlineTransparency = 0
    h.OutlineColor = color
    h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    h.Parent = chestModel

    local adorneePart = getAdorneePart(chestModel)
    if not adorneePart then return end

    local billboard = Instance.new("BillboardGui")
    billboard.Name = "ChestTierESP"
    billboard.Adornee = adorneePart
    billboard.AlwaysOnTop = true
    billboard.StudsOffset = Vector3.new(0, 2.2, 0)
    billboard.Size = UDim2.new(0, 80, 0, 30)

    local text = Instance.new("TextLabel")
    text.Parent = billboard
    text.Size = UDim2.new(1, 0, 1, 0)
    text.BackgroundTransparency = 1
    text.Text = tierFolder.Name
    text.TextScaled = true
    text.Font = Enum.Font.SourceSansBold
    text.TextColor3 = color
    text.TextStrokeTransparency = 0.2

    billboard.Parent = chestModel
    table.insert(tracked, {billboard = billboard, adornee = adorneePart, highlight = h, type = "chest", model = chestModel})
end

local function scanTier(tierFolder)
    for _, v in ipairs(tierFolder:GetDescendants()) do
        if v.Name == "Chest" and v:IsA("Model") then
            -- ต้องมี RewardPart ตอนเริ่ม
            if findRewardPart(v) then
                addChestESP(v, tierFolder)
            end
        end
    end

    tierFolder.DescendantAdded:Connect(function(v)
        if v.Name == "Chest" and v:IsA("Model") then
            if findRewardPart(v) then
                addChestESP(v, tierFolder)
            end
        end
    end)
end

for _, tierFolder in ipairs(chestsRoot:GetChildren()) do
    if tierFolder:IsA("Folder") or tierFolder:IsA("Model") then
        scanTier(tierFolder)
    end
end

chestsRoot.ChildAdded:Connect(function(tierFolder)
    if tierFolder:IsA("Folder") or tierFolder:IsA("Model") then
        scanTier(tierFolder)
    end
end)

-- ====== First Scan ======
scanDucks()

-- ====== RenderStepped (Realtime Update) ======
RunService.RenderStepped:Connect(function()
    for i = #tracked, 1, -1 do
        local item = tracked[i]
        if not item.billboard or not item.billboard.Parent or not item.adornee or not item.adornee.Parent then
            table.remove(tracked, i)
        else
            -- Toggle ESP
            item.billboard.Enabled = espEnabled
            if item.highlight then
                item.highlight.Enabled = espEnabled
            end

            -- ===== Duck: ซ่อนถ้า Cube.008 โปร่งใส =====
            if item.type == "duck" and item.model and item.model:IsA("Model") then
                local cube = item.model:FindFirstChild("Cube.008", true)
                if cube and cube:IsA("BasePart") and cube.Transparency >= 1 then
                    item.billboard.Enabled = false
                    if item.highlight then item.highlight.Enabled = false end
                end
            end

            -- ===== Chest: ซ่อนถ้า RewardPart หายหรือโปร่งใส (เปิดแล้ว) =====
            if item.type == "chest" and item.model and item.model:IsA("Model") then
                local reward = findRewardPart(item.model)
                if (not reward) or reward.Transparency >= 1 then
                    item.billboard.Enabled = false
                    if item.highlight then item.highlight.Enabled = false end
                end
            end

            -- ===== ปรับขนาดตามระยะ =====
            if item.billboard.Enabled then
                local dist = (Camera.CFrame.Position - item.adornee.Position).Magnitude
                local size = math.clamp(2000 / dist, 20, 80)
                item.billboard.Size = UDim2.new(0, size, 0, size * 0.4)
            end
        end
    end
end)

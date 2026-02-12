--// Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer

--// Remotes
local HakiRemote = ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("HakiRemote")
local RequestHit = ReplicatedStorage:WaitForChild("CombatSystem"):WaitForChild("Remotes"):WaitForChild("RequestHit")

--// State
local autoHaki = false
local autoFarm = false
local targetKeyword = "curse"

--// Settings
local attackDelay = 0.05
local farmDistance = 6

--// Utils
local function getCharacter()
    return player.Character or player.CharacterAdded:Wait()
end

local function getRoot(char)
    return char:WaitForChild("HumanoidRootPart")
end

local function isAlive(model)
    local hum = model:FindFirstChildOfClass("Humanoid")
    return hum and hum.Health > 0
end

-- หา NPC ตาม keyword (curse, bandit, etc.)
local function getTargets()
    local list = {}
    local npcs = workspace:FindFirstChild("NPCs")
    if not npcs then return list end

    for _, obj in ipairs(npcs:GetDescendants()) do
        if obj:IsA("Model") then
            if string.find(string.lower(obj.Name), string.lower(targetKeyword)) then
                local hrp = obj:FindFirstChild("HumanoidRootPart")
                local hum = obj:FindFirstChildOfClass("Humanoid")
                if hrp and hum and hum.Health > 0 then
                    table.insert(list, obj)
                end
            end
        end
    end

    return list
end

-- ล็อกหน้ามองมอน (ก้ม/เงยจริง)
local function faceTarget(root, targetRoot)
    if root and targetRoot then
        local pos = root.Position
        local tpos = targetRoot.Position
        root.CFrame = CFrame.lookAt(pos, tpos)
    end
end

--// Actions
local function useHaki()
    pcall(function()
        HakiRemote:FireServer("Toggle")
    end)
end

-- เปิด Haki ตอนเกิดใหม่
player.CharacterAdded:Connect(function()
    if autoHaki then
        task.wait(2)
        useHaki()
    end
end)

--// Auto Farm Loop
task.spawn(function()
    while true do
        if autoFarm then
            local char = getCharacter()
            local root = getRoot(char)

            local targets = getTargets()
            for _, npc in ipairs(targets) do
                if not autoFarm then break end
                if npc and npc.Parent and isAlive(npc) then
                    local npcRoot = npc:FindFirstChild("HumanoidRootPart")
                    if npcRoot then
                        while autoFarm and npc.Parent and isAlive(npc) do
                            -- คำนวณตำแหน่งยืนห่างจากมอน
                            local dir = (root.Position - npcRoot.Position)
                            if dir.Magnitude < 0.1 then
                                dir = Vector3.new(0, 0, 1)
                            end
                            dir = dir.Unit

                            local pos = npcRoot.Position + dir * farmDistance + Vector3.new(0, 2, 0)
                            char:PivotTo(CFrame.new(pos))
                            faceTarget(root, npcRoot)

                            pcall(function()
                                RequestHit:FireServer()
                            end)

                            task.wait(attackDelay)
                        end
                    end
                end
            end
        end
        task.wait(0.3)
    end
end)

--// ================= UI =================

pcall(function()
    CoreGui:FindFirstChild("GilsliferUI"):Destroy()
end)

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "GilsliferUI"
ScreenGui.Parent = CoreGui

local Main = Instance.new("Frame")
Main.Size = UDim2.new(0, 240, 0, 280)
Main.Position = UDim2.new(0.5, -120, 0.5, -140)
Main.BackgroundColor3 = Color3.fromRGB(28, 28, 28)
Main.BorderSizePixel = 0
Main.Parent = ScreenGui
Main.Active = true
Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 10)

-- Title
local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 32)
Title.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
Title.BorderSizePixel = 0
Title.Text = "Gilslifer"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextSize = 15
Title.Font = Enum.Font.SourceSansBold
Title.Parent = Main

-- Minimize
local MinBtn = Instance.new("TextButton")
MinBtn.Size = UDim2.new(0, 26, 0, 20)
MinBtn.Position = UDim2.new(1, -30, 0, 6)
MinBtn.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
MinBtn.Text = "-"
MinBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
MinBtn.TextSize = 16
MinBtn.Font = Enum.Font.SourceSansBold
MinBtn.Parent = Main
Instance.new("UICorner", MinBtn).CornerRadius = UDim.new(0, 6)

-- Content
local Content = Instance.new("Frame")
Content.Size = UDim2.new(1, 0, 1, -32)
Content.Position = UDim2.new(0, 0, 0, 32)
Content.BackgroundTransparency = 1
Content.Parent = Main

local function makeBtn(text, y)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(0, 200, 0, 34)
    b.Position = UDim2.new(0.5, -100, 0, y)
    b.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
    b.Text = text
    b.TextColor3 = Color3.fromRGB(255, 255, 255)
    b.TextSize = 14
    b.Font = Enum.Font.SourceSansBold
    b.Parent = Content
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 8)
    return b
end

-- Input เลือกมอน
local Input = Instance.new("TextBox")
Input.Size = UDim2.new(0, 200, 0, 32)
Input.Position = UDim2.new(0.5, -100, 0, 12)
Input.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
Input.Text = targetKeyword
Input.PlaceholderText = "พิมพ์ชื่อมอน เช่น curse / bandit"
Input.TextColor3 = Color3.fromRGB(255,255,255)
Input.TextSize = 14
Input.Font = Enum.Font.SourceSans
Input.Parent = Content
Instance.new("UICorner", Input).CornerRadius = UDim.new(0, 8)

Input.FocusLost:Connect(function()
    if Input.Text ~= "" then
        targetKeyword = Input.Text
    end
end)

local HakiBtn  = makeBtn("Auto Haki: OFF", 56)
local FarmBtn  = makeBtn("Auto Farm: OFF", 100)

-- Distance label
local DistLabel = Instance.new("TextLabel")
DistLabel.Size = UDim2.new(0, 200, 0, 24)
DistLabel.Position = UDim2.new(0.5, -100, 0, 144)
DistLabel.BackgroundTransparency = 1
DistLabel.Text = "Distance: " .. farmDistance
DistLabel.TextColor3 = Color3.fromRGB(255,255,255)
DistLabel.TextSize = 14
DistLabel.Font = Enum.Font.SourceSansBold
DistLabel.Parent = Content

local MinusBtn = Instance.new("TextButton")
MinusBtn.Size = UDim2.new(0, 40, 0, 28)
MinusBtn.Position = UDim2.new(0.5, -100, 0, 172)
MinusBtn.BackgroundColor3 = Color3.fromRGB(70,70,70)
MinusBtn.Text = "-"
MinusBtn.TextColor3 = Color3.fromRGB(255,255,255)
MinusBtn.TextSize = 18
MinusBtn.Font = Enum.Font.SourceSansBold
MinusBtn.Parent = Content
Instance.new("UICorner", MinusBtn).CornerRadius = UDim.new(0,6)

local PlusBtn = Instance.new("TextButton")
PlusBtn.Size = UDim2.new(0, 40, 0, 28)
PlusBtn.Position = UDim2.new(0.5, 60, 0, 172)
PlusBtn.BackgroundColor3 = Color3.fromRGB(70,70,70)
PlusBtn.Text = "+"
PlusBtn.TextColor3 = Color3.fromRGB(255,255,255)
PlusBtn.TextSize = 18
PlusBtn.Font = Enum.Font.SourceSansBold
PlusBtn.Parent = Content
Instance.new("UICorner", PlusBtn).CornerRadius = UDim.new(0,6)

local function updateDistLabel()
    DistLabel.Text = "Distance: " .. farmDistance
end

MinusBtn.MouseButton1Click:Connect(function()
    farmDistance = math.max(2, farmDistance - 1)
    updateDistLabel()
end)

PlusBtn.MouseButton1Click:Connect(function()
    farmDistance = math.min(30, farmDistance + 1)
    updateDistLabel()
end)

-- Buttons logic
HakiBtn.MouseButton1Click:Connect(function()
    autoHaki = not autoHaki
    if autoHaki then
        HakiBtn.Text = "Auto Haki: ON"
        HakiBtn.BackgroundColor3 = Color3.fromRGB(0, 120, 0)
        useHaki()
    else
        HakiBtn.Text = "Auto Haki: OFF"
        HakiBtn.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
    end
end)

FarmBtn.MouseButton1Click:Connect(function()
    autoFarm = not autoFarm
    if autoFarm then
        FarmBtn.Text = "Auto Farm: ON"
        FarmBtn.BackgroundColor3 = Color3.fromRGB(0, 80, 120)
    else
        FarmBtn.Text = "Auto Farm: OFF"
        FarmBtn.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
    end
end)

-- Minimize
local minimized = false
local normalSize = Main.Size

MinBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    if minimized then
        Content.Visible = false
        Main.Size = UDim2.new(normalSize.X.Scale, normalSize.X.Offset, 0, 32)
        MinBtn.Text = "+"
    else
        Content.Visible = true
        Main.Size = normalSize
        MinBtn.Text = "-"
    end
end)

-- Drag UI (เมาส์ + ทัช)
local dragging = false
local dragStart
local startPos

Title.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = Main.Position

        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        Main.Position = UDim2.new(
            startPos.X.Scale,
            startPos.X.Offset + delta.X,
            startPos.Y.Scale,
            startPos.Y.Offset + delta.Y
        )
    end
end)

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
local autoCurse = false

--// Settings
local attackDelay = 0.05      -- ความเร็วตี (ใช้ใน Auto Curse)
local attackHeight = 6        -- ความสูงเหนือหัวมอน (ปรับได้จาก UI)

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

local function getAllCurses()
    local list = {}
    local npcsFolder = workspace:FindFirstChild("NPCs")
    if not npcsFolder then return list end

    for _, npc in ipairs(npcsFolder:GetChildren()) do
        if npc:IsA("Model") and npc.Name:lower():find("curse") then
            if isAlive(npc) then
                table.insert(list, npc)
            end
        end
    end
    return list
end

-- ฟังก์ชันล็อคหน้าเข้าหาเป้าหมาย
local function faceTarget(root, targetRoot)
    if root and targetRoot then
        local pos = root.Position
        local tpos = targetRoot.Position
        root.CFrame = CFrame.new(pos, Vector3.new(tpos.X, pos.Y, tpos.Z))
    end
end

--// Actions
local function useHaki()
    pcall(function()
        HakiRemote:FireServer("Toggle")
    end)
end

-- เปิด Haki ตอนเกิดใหม่ (ถ้าเปิด Auto Haki)
player.CharacterAdded:Connect(function()
    if autoHaki then
        task.wait(2)
        useHaki()
    end
end)

-- Auto Curse loop (ฟาร์มจากบนหัว + ล็อคหน้า)
task.spawn(function()
    while true do
        if autoCurse then
            local char = getCharacter()
            local root = getRoot(char)

            local curses = getAllCurses()
            for _, npc in ipairs(curses) do
                if not autoCurse then break end
                if npc and npc.Parent and isAlive(npc) then
                    local npcRoot = npc:FindFirstChild("HumanoidRootPart") or npc:FindFirstChild("RootPart")
                    if npcRoot then
                        -- วาร์ปไปอยู่เหนือหัวมอน
                        root.CFrame = npcRoot.CFrame * CFrame.new(0, attackHeight, 0)
                        faceTarget(root, npcRoot)

                        -- ตีจนกว่าจะตาย
                        while autoCurse and npc.Parent and isAlive(npc) do
                            root.CFrame = npcRoot.CFrame * CFrame.new(0, attackHeight, 0)
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

--// UI
pcall(function()
    CoreGui:FindFirstChild("GilsliferUI"):Destroy()
end)

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "GilsliferUI"
ScreenGui.Parent = CoreGui

local Main = Instance.new("Frame")
Main.Size = UDim2.new(0, 220, 0, 230)
Main.Position = UDim2.new(0.5, -110, 0.5, -115)
Main.BackgroundColor3 = Color3.fromRGB(28, 28, 28)
Main.BorderSizePixel = 0
Main.Parent = ScreenGui
Main.Active = true

Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 10)

-- Title bar
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

-- Button factory
local function makeBtn(text, y)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(0, 180, 0, 34)
    b.Position = UDim2.new(0.5, -90, 0, y)
    b.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
    b.Text = text
    b.TextColor3 = Color3.fromRGB(255, 255, 255)
    b.TextSize = 14
    b.Font = Enum.Font.SourceSansBold
    b.Parent = Content
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 8)
    return b
end

local HakiBtn  = makeBtn("Auto Haki: OFF", 12)
local CurseBtn = makeBtn("Auto Curse: OFF", 56)

-- Height label
local DistLabel = Instance.new("TextLabel")
DistLabel.Size = UDim2.new(0, 180, 0, 24)
DistLabel.Position = UDim2.new(0.5, -90, 0, 100)
DistLabel.BackgroundTransparency = 1
DistLabel.Text = "Height: " .. attackHeight
DistLabel.TextColor3 = Color3.fromRGB(255,255,255)
DistLabel.TextSize = 14
DistLabel.Font = Enum.Font.SourceSansBold
DistLabel.Parent = Content

-- Minus button
local MinusBtn = Instance.new("TextButton")
MinusBtn.Size = UDim2.new(0, 40, 0, 28)
MinusBtn.Position = UDim2.new(0.5, -90, 0, 130)
MinusBtn.BackgroundColor3 = Color3.fromRGB(70,70,70)
MinusBtn.Text = "-"
MinusBtn.TextColor3 = Color3.fromRGB(255,255,255)
MinusBtn.TextSize = 18
MinusBtn.Font = Enum.Font.SourceSansBold
MinusBtn.Parent = Content
Instance.new("UICorner", MinusBtn).CornerRadius = UDim.new(0,6)

-- Plus button
local PlusBtn = Instance.new("TextButton")
PlusBtn.Size = UDim2.new(0, 40, 0, 28)
PlusBtn.Position = UDim2.new(0.5, 50, 0, 130)
PlusBtn.BackgroundColor3 = Color3.fromRGB(70,70,70)
PlusBtn.Text = "+"
PlusBtn.TextColor3 = Color3.fromRGB(255,255,255)
PlusBtn.TextSize = 18
PlusBtn.Font = Enum.Font.SourceSansBold
PlusBtn.Parent = Content
Instance.new("UICorner", PlusBtn).CornerRadius = UDim.new(0,6)

local function updateDistLabel()
    DistLabel.Text = "Height: " .. attackHeight
end

MinusBtn.MouseButton1Click:Connect(function()
    attackHeight = math.max(2, attackHeight - 1)
    updateDistLabel()
end)

PlusBtn.MouseButton1Click:Connect(function()
    attackHeight = math.min(20, attackHeight + 1)
    updateDistLabel()
end)

-- Button logic
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

CurseBtn.MouseButton1Click:Connect(function()
    autoCurse = not autoCurse
    if autoCurse then
        CurseBtn.Text = "Auto Curse: ON"
        CurseBtn.BackgroundColor3 = Color3.fromRGB(0, 80, 120)
    else
        CurseBtn.Text = "Auto Curse: OFF"
        CurseBtn.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
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

-- Drag (เมาส์ + ทัช)
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

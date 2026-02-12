--// Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")
local VirtualInputManager = game:GetService("VirtualInputManager")

local player = Players.LocalPlayer

--// Remotes
local HakiRemote = ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("HakiRemote")
local RequestHit = ReplicatedStorage:WaitForChild("CombatSystem"):WaitForChild("Remotes"):WaitForChild("RequestHit")

--// State
local autoHaki = false
local autoFarm = false
local autoSkill = false
local targetKeyword = "curse"
local currentTarget = nil

-- Skill toggles
local skillEnabled = { Z = true, X = true, C = true, V = true }
local skillKeys = {
    Z = Enum.KeyCode.Z,
    X = Enum.KeyCode.X,
    C = Enum.KeyCode.C,
    V = Enum.KeyCode.V
}

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

-- หาเป้าหมายตาม keyword
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

-- หันหน้าเข้าหามอนแบบไม่ก้ม/เงย
local function faceTargetFlat(root, targetRoot)
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

local function pressKey(key)
    VirtualInputManager:SendKeyEvent(true, key, false, game)
    task.wait(0.05)
    VirtualInputManager:SendKeyEvent(false, key, false, game)
end

-- Auto Skill Loop
task.spawn(function()
    while true do
        if autoSkill then
            for name, key in pairs(skillKeys) do
                if skillEnabled[name] then
                    pressKey(key)
                    task.wait(0.15)
                end
            end
        end
        task.wait(0.3)
    end
end)

-- Respawn
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

            local targets = {}
            if currentTarget and currentTarget.Parent and isAlive(currentTarget) then
                table.insert(targets, currentTarget)
            else
                currentTarget = nil
                targets = getTargets()
            end

            for _, npc in ipairs(targets) do
                if not autoFarm then break end
                if npc and npc.Parent and isAlive(npc) then
                    local npcRoot = npc:FindFirstChild("HumanoidRootPart")
                    if npcRoot then
                        currentTarget = npc

                        while autoFarm and npc.Parent and isAlive(npc) do
                            local targetPos = npcRoot.Position
                            local backDir = -npcRoot.CFrame.LookVector
                            local pos = targetPos + backDir * farmDistance + Vector3.new(0, 2, 0)

                            char:PivotTo(CFrame.new(pos))
                            faceTargetFlat(root, npcRoot)

                            pcall(function()
                                RequestHit:FireServer()
                            end)

                            task.wait(attackDelay)
                        end

                        if not isAlive(npc) then
                            currentTarget = nil
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

local ScreenGui = Instance.new("ScreenGui", CoreGui)
ScreenGui.Name = "GilsliferUI"

-- Main
local Main = Instance.new("Frame", ScreenGui)
Main.Size = UDim2.new(0, 520, 0, 210)
Main.Position = UDim2.new(0.5, -260, 0.5, -105)
Main.BackgroundColor3 = Color3.fromRGB(28,28,28)
Main.BorderSizePixel = 0
Main.Active = true
Instance.new("UICorner", Main).CornerRadius = UDim.new(0,10)

-- Title
local Title = Instance.new("TextLabel", Main)
Title.Size = UDim2.new(1, -40, 0, 32)
Title.Position = UDim2.new(0, 10, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "Gilslifer Hub"
Title.TextColor3 = Color3.new(1,1,1)
Title.Font = Enum.Font.SourceSansBold
Title.TextSize = 16
Title.TextXAlignment = Enum.TextXAlignment.Left

-- Hide Button
local HideBtn = Instance.new("TextButton", Main)
HideBtn.Size = UDim2.new(0, 26, 0, 20)
HideBtn.Position = UDim2.new(1, -32, 0, 6)
HideBtn.Text = "–"
HideBtn.BackgroundColor3 = Color3.fromRGB(70,70,70)
HideBtn.TextColor3 = Color3.new(1,1,1)
HideBtn.Font = Enum.Font.SourceSansBold
HideBtn.TextSize = 18
Instance.new("UICorner", HideBtn).CornerRadius = UDim.new(0,6)

-- Small Open Button
local OpenBtn = Instance.new("TextButton", ScreenGui)
OpenBtn.Size = UDim2.new(0, 40, 0, 40)
OpenBtn.Position = UDim2.new(0, 5, 0.5, -20)
OpenBtn.Text = "≡"
OpenBtn.Visible = false
OpenBtn.BackgroundColor3 = Color3.fromRGB(40,40,40)
OpenBtn.TextColor3 = Color3.new(1,1,1)
OpenBtn.Font = Enum.Font.SourceSansBold
OpenBtn.TextSize = 22
Instance.new("UICorner", OpenBtn).CornerRadius = UDim.new(0,10)

-- Content
local Content = Instance.new("Frame", Main)
Content.Size = UDim2.new(1, -20, 1, -42)
Content.Position = UDim2.new(0, 10, 0, 36)
Content.BackgroundTransparency = 1

-- Input
local Input = Instance.new("TextBox", Content)
Input.Size = UDim2.new(0, 200, 0, 32)
Input.Position = UDim2.new(0, 0, 0, 0)
Input.Text = targetKeyword
Input.PlaceholderText = "ชื่อมอน เช่น curse / bandit"
Input.BackgroundColor3 = Color3.fromRGB(60,60,60)
Input.TextColor3 = Color3.new(1,1,1)
Input.Font = Enum.Font.SourceSans
Input.TextSize = 14
Instance.new("UICorner", Input).CornerRadius = UDim.new(0,8)

Input.FocusLost:Connect(function()
    if Input.Text ~= "" then
        targetKeyword = Input.Text
    end
end)

local function makeBtn(txt, x, y, w)
    local b = Instance.new("TextButton", Content)
    b.Size = UDim2.new(0, w, 0, 36)
    b.Position = UDim2.new(0, x, 0, y)
    b.Text = txt
    b.BackgroundColor3 = Color3.fromRGB(70,70,70)
    b.TextColor3 = Color3.new(1,1,1)
    b.Font = Enum.Font.SourceSansBold
    b.TextSize = 14
    Instance.new("UICorner", b).CornerRadius = UDim.new(0,8)
    return b
end

-- Left
local HakiBtn  = makeBtn("Auto Haki: OFF", 0, 42, 200)
local FarmBtn  = makeBtn("Auto Farm: OFF", 0, 84, 200)
local SkillBtn = makeBtn("Auto Skill: OFF", 0, 126, 200)

-- Right
local DistLabel = Instance.new("TextLabel", Content)
DistLabel.Size = UDim2.new(0, 200, 0, 24)
DistLabel.Position = UDim2.new(0, 230, 0, 0)
DistLabel.BackgroundTransparency = 1
DistLabel.Text = "Distance: "..farmDistance
DistLabel.TextColor3 = Color3.new(1,1,1)
DistLabel.Font = Enum.Font.SourceSans
DistLabel.TextSize = 14

local MinusBtn = makeBtn("-", 230, 28, 90)
local PlusBtn  = makeBtn("+", 340, 28, 90)

MinusBtn.MouseButton1Click:Connect(function()
    farmDistance = math.max(1, farmDistance - 1)
    DistLabel.Text = "Distance: "..farmDistance
end)

PlusBtn.MouseButton1Click:Connect(function()
    farmDistance = math.min(30, farmDistance + 1)
    DistLabel.Text = "Distance: "..farmDistance
end)

-- Skill toggles
local function makeToggleSkill(name, x, y)
    local b = makeBtn(name..": ON", x, y, 90)
    b.BackgroundColor3 = Color3.fromRGB(0,120,0)
    b.MouseButton1Click:Connect(function()
        skillEnabled[name] = not skillEnabled[name]
        if skillEnabled[name] then
            b.Text = name..": ON"
            b.BackgroundColor3 = Color3.fromRGB(0,120,0)
        else
            b.Text = name..": OFF"
            b.BackgroundColor3 = Color3.fromRGB(120,0,0)
        end
    end)
end

makeToggleSkill("Z", 230, 76)
makeToggleSkill("X", 340, 76)
makeToggleSkill("C", 230, 120)
makeToggleSkill("V", 340, 120)

-- Buttons logic
HakiBtn.MouseButton1Click:Connect(function()
    autoHaki = not autoHaki
    if autoHaki then
        HakiBtn.Text = "Auto Haki: ON"
        HakiBtn.BackgroundColor3 = Color3.fromRGB(0,120,0)
        useHaki()
    else
        HakiBtn.Text = "Auto Haki: OFF"
        HakiBtn.BackgroundColor3 = Color3.fromRGB(70,70,70)
    end
end)

FarmBtn.MouseButton1Click:Connect(function()
    autoFarm = not autoFarm
    if autoFarm then
        FarmBtn.Text = "Auto Farm: ON"
        FarmBtn.BackgroundColor3 = Color3.fromRGB(0,80,120)
    else
        FarmBtn.Text = "Auto Farm: OFF"
        FarmBtn.BackgroundColor3 = Color3.fromRGB(70,70,70)
        currentTarget = nil
    end
end)

SkillBtn.MouseButton1Click:Connect(function()
    autoSkill = not autoSkill
    if autoSkill then
        SkillBtn.Text = "Auto Skill: ON"
        SkillBtn.BackgroundColor3 = Color3.fromRGB(120,80,0)
    else
        SkillBtn.Text = "Auto Skill: OFF"
        SkillBtn.BackgroundColor3 = Color3.fromRGB(70,70,70)
    end
end)

-- Hide / Show
HideBtn.MouseButton1Click:Connect(function()
    Main.Visible = false
    OpenBtn.Visible = true
end)

OpenBtn.MouseButton1Click:Connect(function()
    Main.Visible = true
    OpenBtn.Visible = false
end)

-- Drag
local dragging = false
local dragStart, startPos

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

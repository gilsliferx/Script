--// Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local VirtualUser = game:GetService("VirtualUser")

local player = Players.LocalPlayer

--// ================= Anti AFK =================
player.Idled:Connect(function()
    VirtualUser:Button2Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
    task.wait(1)
    VirtualUser:Button2Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
end)

--// Remotes
local RequestHit = ReplicatedStorage:WaitForChild("CombatSystem"):WaitForChild("Remotes"):WaitForChild("RequestHit")

--// State
local autoFarm = false
local autoSkill = false
local farmDistance = 6
local attackDelay = 0.05

-- Skill
local skillEnabled = { Z=true, X=true, C=true, V=true }
local skillKeys = {
    Z = Enum.KeyCode.Z,
    X = Enum.KeyCode.X,
    C = Enum.KeyCode.C,
    V = Enum.KeyCode.V
}

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

-- Blacklist (ไม่ตีตัวพวกนี้)
local blacklist = {
    ["TrainingDummy"] = true
}

-- ฟาร์มทุกมอน ยกเว้น blacklist
local function getTargets()
    local list = {}
    local npcs = workspace:FindFirstChild("NPCs")
    if not npcs then return list end

    for _, obj in ipairs(npcs:GetChildren()) do
        if obj:IsA("Model") and not blacklist[obj.Name] then
            local hrp = obj:FindFirstChild("HumanoidRootPart")
            local hum = obj:FindFirstChildOfClass("Humanoid")
            if hrp and hum and hum.Health > 0 then
                table.insert(list, obj)
            end
        end
    end
    return list
end

local function faceTargetFlat(root, targetRoot)
    local pos = root.Position
    local tpos = targetRoot.Position
    root.CFrame = CFrame.new(pos, Vector3.new(tpos.X, pos.Y, tpos.Z))
end

local function pressKey(key)
    VirtualInputManager:SendKeyEvent(true, key, false, game)
    task.wait(0.05)
    VirtualInputManager:SendKeyEvent(false, key, false, game)
end

--// Auto Skill
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

--// Auto Farm
task.spawn(function()
    while true do
        if autoFarm then
            local char = getCharacter()
            local root = getRoot(char)

            local targets = getTargets()
            for _, npc in ipairs(targets) do
                if not autoFarm then break end
                local npcRoot = npc:FindFirstChild("HumanoidRootPart")
                if npcRoot and isAlive(npc) then
                    while autoFarm and npc.Parent and isAlive(npc) do
                        local backDir = -npcRoot.CFrame.LookVector
                        local pos = npcRoot.Position + backDir * farmDistance + Vector3.new(0,2,0)

                        char:PivotTo(CFrame.new(pos))
                        faceTargetFlat(root, npcRoot)

                        pcall(function()
                            RequestHit:FireServer()
                        end)

                        task.wait(attackDelay)
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

local Main = Instance.new("Frame", ScreenGui)
Main.Size = UDim2.new(0, 520, 0, 200)
Main.Position = UDim2.new(0.5, -260, 0.5, -100)
Main.BackgroundColor3 = Color3.fromRGB(28,28,28)
Main.Active = true
Instance.new("UICorner", Main).CornerRadius = UDim.new(0,10)

local Title = Instance.new("TextLabel", Main)
Title.Size = UDim2.new(1, -40, 0, 32)
Title.Position = UDim2.new(0, 10, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "Gilslifer"
Title.TextColor3 = Color3.new(1,1,1)
Title.Font = Enum.Font.SourceSansBold
Title.TextSize = 16
Title.TextXAlignment = Enum.TextXAlignment.Left

local HideBtn = Instance.new("TextButton", Main)
HideBtn.Size = UDim2.new(0, 26, 0, 20)
HideBtn.Position = UDim2.new(1, -32, 0, 6)
HideBtn.Text = "–"
HideBtn.BackgroundColor3 = Color3.fromRGB(70,70,70)
HideBtn.TextColor3 = Color3.new(1,1,1)
Instance.new("UICorner", HideBtn)

local OpenBtn = Instance.new("TextButton", ScreenGui)
OpenBtn.Size = UDim2.new(0, 40, 0, 40)
OpenBtn.Position = UDim2.new(0, 5, 0.5, -20)
OpenBtn.Text = "≡"
OpenBtn.Visible = false
OpenBtn.BackgroundColor3 = Color3.fromRGB(40,40,40)
OpenBtn.TextColor3 = Color3.new(1,1,1)
Instance.new("UICorner", OpenBtn)

local Content = Instance.new("Frame", Main)
Content.Size = UDim2.new(1, -20, 1, -42)
Content.Position = UDim2.new(0, 10, 0, 36)
Content.BackgroundTransparency = 1

local function makeBtn(txt, x, y, w)
    local b = Instance.new("TextButton", Content)
    b.Size = UDim2.new(0, w, 0, 36)
    b.Position = UDim2.new(0, x, 0, y)
    b.Text = txt
    b.BackgroundColor3 = Color3.fromRGB(70,70,70)
    b.TextColor3 = Color3.new(1,1,1)
    b.Font = Enum.Font.SourceSansBold
    b.TextSize = 14
    Instance.new("UICorner", b)
    return b
end

local FarmBtn  = makeBtn("Auto Farm: OFF", 0, 50, 200)
local SkillBtn = makeBtn("Auto Skill: OFF", 0, 100, 200)

FarmBtn.MouseButton1Click:Connect(function()
    autoFarm = not autoFarm
    FarmBtn.Text = autoFarm and "Auto Farm: ON" or "Auto Farm: OFF"
    FarmBtn.BackgroundColor3 = autoFarm and Color3.fromRGB(0,80,120) or Color3.fromRGB(70,70,70)
end)

SkillBtn.MouseButton1Click:Connect(function()
    autoSkill = not autoSkill
    SkillBtn.Text = autoSkill and "Auto Skill: ON" or "Auto Skill: OFF"
    SkillBtn.BackgroundColor3 = autoSkill and Color3.fromRGB(120,80,0) or Color3.fromRGB(70,70,70)
end)

local DistLabel = Instance.new("TextLabel", Content)
DistLabel.Size = UDim2.new(0, 200, 0, 24)
DistLabel.Position = UDim2.new(0, 240, 0, 0)
DistLabel.BackgroundTransparency = 1
DistLabel.Text = "Distance: "..farmDistance
DistLabel.TextColor3 = Color3.new(1,1,1)

local MinusBtn = makeBtn("-", 240, 28, 90)
local PlusBtn  = makeBtn("+", 350, 28, 90)

MinusBtn.MouseButton1Click:Connect(function()
    farmDistance = math.max(1, farmDistance - 1)
    DistLabel.Text = "Distance: "..farmDistance
end)

PlusBtn.MouseButton1Click:Connect(function()
    farmDistance = math.min(30, farmDistance + 1)
    DistLabel.Text = "Distance: "..farmDistance
end)

local function toggleSkill(name, x, y)
    local b = makeBtn(name.." ✓", x, y, 90)
    b.BackgroundColor3 = Color3.fromRGB(0,120,0)
    b.MouseButton1Click:Connect(function()
        skillEnabled[name] = not skillEnabled[name]
        b.Text = name..(skillEnabled[name] and " ✓" or " ✗")
        b.BackgroundColor3 = skillEnabled[name] and Color3.fromRGB(0,120,0) or Color3.fromRGB(120,0,0)
    end)
end

toggleSkill("Z", 240, 70)
toggleSkill("X", 350, 70)
toggleSkill("C", 240, 120)
toggleSkill("V", 350, 120)

HideBtn.MouseButton1Click:Connect(function()
    Main.Visible = false
    OpenBtn.Visible = true
end)

OpenBtn.MouseButton1Click:Connect(function()
    Main.Visible = true
    OpenBtn.Visible = false
end)

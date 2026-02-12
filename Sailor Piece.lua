-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")
local player = Players.LocalPlayer

-- Remotes
local HakiRemote = ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("HakiRemote")
local RequestHit = ReplicatedStorage:WaitForChild("CombatSystem"):WaitForChild("Remotes"):WaitForChild("RequestHit")

-- State
local autoHaki = false
local autoCurse = false

-- Settings
local attackDelay = 0.05
local attackHeight = 6

-- Utility Functions
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
        if npc:IsA("Model") and npc.Name:lower():find("curse") and isAlive(npc) then
            table.insert(list, npc)
        end
    end
    return list
end

local function faceTarget(root, targetRoot)
    if root and targetRoot then
        local pos = root.Position
        local tpos = targetRoot.Position
        root.CFrame = CFrame.new(pos, Vector3.new(tpos.X, pos.Y, tpos.Z))
    end
end

-- Actions
local function useHaki()
    pcall(function()
        HakiRemote:FireServer("Toggle")
    end)
end

-- Keep Haki On When Character Respawns
player.CharacterAdded:Connect(function()
    if autoHaki then
        task.wait(2)
        useHaki()
    end
end)

-- Auto Curse Loop
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
                        root.CFrame = npcRoot.CFrame * CFrame.new(0, attackHeight, 0)
                        faceTarget(root, npcRoot)
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

-- UI
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

-- Title
local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 32)
Title.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
Title.Text = "Gilslifer"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.Font = Enum.Font.SourceSansBold
Title.TextSize = 15
Title.Parent = Main

-- Buttons
local function makeBtn(text, y)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 180, 0, 34)
    btn.Position = UDim2.new(0.5, -90, 0, y)
    btn.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.TextSize = 14
    btn.Font = Enum.Font.SourceSansBold
    btn.Parent = Main
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
    return btn
end

local HakiBtn = makeBtn("Auto Haki: OFF", 50)
local CurseBtn = makeBtn("Auto Curse: OFF", 100)

-- Button Logic
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

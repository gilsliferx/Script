local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/xHeptc/Kavo-UI-Library/main/source.lua"))()

local Window = Library.CreateLib("Somtam", "Midnight")

local Tab = Window:NewTab("Auto")

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer

local Section = Tab:NewSection("Teepormeng")

Section:NewToggle("Cut", "ToggleInfo", function(state)
    if state then
        while wait() do
            game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("AxeSwing"):FireServer()
        end
        print("Toggle On")
    else
        print("Toggle Off")
    end
end)

local OrbToggle = false
local OrbConnection

Section:NewToggle("Auto Coin", "ToggleInfo", function(state)
    OrbToggle = state

        if state then
            OrbConnection = RunService.Heartbeat:Connect(function()
                if not OrbToggle then return end

                local character = player.Character
                local hrp = character and character:FindFirstChild("HumanoidRootPart")
                if not hrp then return end

                for _, orb in pairs(workspace:WaitForChild("Orbs"):GetChildren()) do
                    if orb:IsA("BasePart") then
                        orb.CFrame = hrp.CFrame
                    end
                end

                task.wait(0.01)
            end)
        else
            if OrbConnection then
                OrbConnection:Disconnect()
                OrbConnection = nil
            end
        endint("Toggle Off")
    end
end)
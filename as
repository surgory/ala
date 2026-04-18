--// ====================== FAZE.CC - FINAL WORKING SCRIPT ======================
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

--// ====================== INTRO (BLACK & WHITE) ======================
local IntroGui = Instance.new("ScreenGui")
IntroGui.Name = "FazeCC_Intro"
IntroGui.ResetOnSpawn = false
IntroGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
IntroGui.IgnoreGuiInset = true

local Blur = Instance.new("BlurEffect")
Blur.Size = 0
Blur.Name = "IntroBlur"
Blur.Parent = game:GetService("Lighting")

local Overlay = Instance.new("Frame")
Overlay.Size = UDim2.new(1, 0, 1, 0)
Overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
Overlay.BackgroundTransparency = 1
Overlay.BorderSizePixel = 0
Overlay.ZIndex = 9
Overlay.Parent = IntroGui

local Logo = Instance.new("ImageLabel")
Logo.Size = UDim2.new(0, 250, 0, 250)
Logo.Position = UDim2.new(0.5, -125, 0.5, -125)
Logo.BackgroundTransparency = 1
Logo.Image = "rbxassetid://122568853954666"
Logo.ImageTransparency = 1
Logo.ZIndex = 10
Logo.Parent = IntroGui

local BrandText = Instance.new("TextLabel")
BrandText.Size = UDim2.new(1, 0, 0, 30)
BrandText.Position = UDim2.new(0, 0, 0.5, 140)
BrandText.BackgroundTransparency = 1
BrandText.Text = "FAZE.CC"
BrandText.TextColor3 = Color3.fromRGB(255, 255, 255)
BrandText.TextTransparency = 1
BrandText.TextSize = 20
BrandText.Font = Enum.Font.GothamBlack
BrandText.ZIndex = 10
BrandText.Parent = IntroGui

pcall(function() if syn and syn.protect_gui then syn.protect_gui(IntroGui) end end)
pcall(function() if gethui then IntroGui.Parent = gethui() else IntroGui.Parent = game:GetService("CoreGui") end end)

local blurIn = TweenService:Create(Blur, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = 20})
blurIn:Play()
local overlayIn = TweenService:Create(Overlay, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = 0.5})
overlayIn:Play()
task.wait(0.15)
local logoIn = TweenService:Create(Logo, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {ImageTransparency = 0})
logoIn:Play()
local textIn = TweenService:Create(BrandText, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {TextTransparency = 0})
textIn:Play()
task.wait(3)
local blurOut = TweenService:Create(Blur, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Size = 0})
blurOut:Play()
local overlayOut = TweenService:Create(Overlay, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {BackgroundTransparency = 1})
overlayOut:Play()
local logoOut = TweenService:Create(Logo, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {ImageTransparency = 1})
logoOut:Play()
local textOut = TweenService:Create(BrandText, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {TextTransparency = 1})
textOut:Play()
task.wait(0.2)
Blur:Destroy()
IntroGui:Destroy()

--// ====================== SETTINGS ======================
local Settings = {
    SilentAim = true,
    Triggerbot = false,
    Camlock = false,
    ESPNames = true,
    RapidFire = false,
    BulletMod = false,
    SpeedWalk = false,
    
    FOV = 350,
    TriggerFOV = 100,
    AimPart = "Head",
    CamlockSmoothness = 0.15,
    FireRate = 0.05,
    BulletSpeed = 9999,
    SpeedValue = 200,
    
    ESPOffsetY = -3.5,
    ESPTextSize = 11,
    ESPMaxDistance = 500,
    ESPNormalColor = Color3.fromRGB(255, 255, 255),
    ESPTargetColor = Color3.fromRGB(255, 50, 50),
}

--// ====================== VARIABLES ======================
local Connections = {}
local CamlockTarget = nil
local TargetedPlayer = nil
local ESPCache = {}
local lastFire = 0
local SpeedConnection = nil
local MainRemote = ReplicatedStorage:FindFirstChild("Remotes") and ReplicatedStorage.Remotes:FindFirstChild("MainRemoteEvent")

--// ====================== STATUS GUI ======================
local StatusGui = Instance.new("ScreenGui")
StatusGui.Name = "FazeCC_Status"
StatusGui.ResetOnSpawn = false
StatusGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
pcall(function() if gethui then StatusGui.Parent = gethui() else StatusGui.Parent = game:GetService("CoreGui") end end)

local StatusText = Instance.new("TextLabel")
StatusText.Size = UDim2.new(1, 0, 0, 120)
StatusText.Position = UDim2.new(0, 0, 0.65, -60)
StatusText.BackgroundTransparency = 1
StatusText.Text = ""
StatusText.TextSize = 12
StatusText.Font = Enum.Font.GothamBold
StatusText.TextStrokeTransparency = 0.7
StatusText.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
StatusText.RichText = true
StatusText.Parent = StatusGui

--// ====================== ESP GUI ======================
local ESPGui = Instance.new("ScreenGui")
ESPGui.Name = "FazeCC_ESP"
ESPGui.ResetOnSpawn = false
pcall(function() if gethui then ESPGui.Parent = gethui() else ESPGui.Parent = game:GetService("CoreGui") end end)

--// ====================== UTILITY FUNCTIONS ======================
local function IsAlive(plr)
    if not plr or not plr.Character then return false end
    local humanoid = plr.Character:FindFirstChild("Humanoid")
    return humanoid and humanoid.Health > 0
end

local function GetTargetPart(character)
    if Settings.AimPart == "Head" then
        return character:FindFirstChild("Head") or character:FindFirstChild("HumanoidRootPart")
    end
    return character:FindFirstChild("HumanoidRootPart")
end

local function GetClosestPlayerToCursor(fov)
    local closest = nil
    local closestDist = fov or Settings.FOV
    local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and IsAlive(player) then
            local targetPart = GetTargetPart(player.Character)
            if targetPart then
                local screenPos, onScreen = Camera:WorldToViewportPoint(targetPart.Position)
                if onScreen then
                    local dist = (Vector2.new(screenPos.X, screenPos.Y) - center).Magnitude
                    if dist < closestDist then
                        closestDist = dist
                        closest = player
                    end
                end
            end
        end
    end
    return closest
end

local function GetPlayerUnderCursor()
    local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    local closest = nil
    local closestDist = 100
    
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and IsAlive(player) then
            local targetPart = GetTargetPart(player.Character)
            if targetPart then
                local screenPos, onScreen = Camera:WorldToViewportPoint(targetPart.Position)
                if onScreen then
                    local dist = (Vector2.new(screenPos.X, screenPos.Y) - center).Magnitude
                    if dist < closestDist then
                        closestDist = dist
                        closest = player
                    end
                end
            end
        end
    end
    return closest
end

--// ====================== STATUS UPDATE ======================
function UpdateStatus()
    local lines = {"<font color='#AAAAAA'>FAZE.CC</font>", ""}
    if Settings.SilentAim then table.insert(lines, "<font color='#FF5050'>Silent Aim</font>") end
    if Settings.Triggerbot then table.insert(lines, "<font color='#FF5050'>Triggerbot</font>") end
    if Settings.Camlock then table.insert(lines, "<font color='#FF5050'>Camlock</font>") end
    if Settings.RapidFire then table.insert(lines, "<font color='#FF5050'>Rapid Fire</font>") end
    if Settings.BulletMod then table.insert(lines, "<font color='#FF5050'>Bullet Mod</font>") end
    if Settings.ESPNames then table.insert(lines, "<font color='#FF5050'>ESP Names</font>") end
    if Settings.SpeedWalk then table.insert(lines, "<font color='#FF5050'>Speed Walk (" .. Settings.SpeedValue .. ")</font>") end
    if TargetedPlayer then
        table.insert(lines, "")
        table.insert(lines, "<font color='#FF5050'>Target: " .. TargetedPlayer.Name .. "</font>")
    end
    StatusText.Text = table.concat(lines, "\n")
end

--// ====================== ESP FUNCTIONS ======================
local function ClearESP()
    for _, billboard in pairs(ESPCache) do
        pcall(function() billboard:Destroy() end)
    end
    ESPCache = {}
end

local function UpdateESPColors()
    for player, billboard in pairs(ESPCache) do
        pcall(function()
            local label = billboard:FindFirstChild("TextLabel")
            if label then
                label.TextColor3 = (player == TargetedPlayer) and Settings.ESPTargetColor or Settings.ESPNormalColor
            end
        end)
    end
end

local function CreateESP(player)
    if not player.Character then return end
    local hrp = player.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    
    local billboard = Instance.new("BillboardGui")
    billboard.Size = UDim2.new(0, 100, 0, 20)
    billboard.StudsOffset = Vector3.new(0, Settings.ESPOffsetY, 0)
    billboard.AlwaysOnTop = true
    billboard.MaxDistance = Settings.ESPMaxDistance
    billboard.Parent = hrp
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = player.Name
    label.TextColor3 = (player == TargetedPlayer) and Settings.ESPTargetColor or Settings.ESPNormalColor
    label.TextSize = Settings.ESPTextSize
    label.Font = Enum.Font.GothamBold
    label.TextStrokeTransparency = 0.5
    label.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    label.Parent = billboard
    
    ESPCache[player] = billboard
end

local function UpdateESP()
    if not Settings.ESPNames then
        ClearESP()
        return
    end
    
    for player, billboard in pairs(ESPCache) do
        if not player.Parent or not IsAlive(player) then
            pcall(function() billboard:Destroy() end)
            ESPCache[player] = nil
        end
    end
    
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and IsAlive(player) and not ESPCache[player] then
            CreateESP(player)
        end
    end
end

--// ====================== SPEED WALK ======================
local function ApplySpeed()
    local character = LocalPlayer.Character
    if not character then return end
    local humanoid = character:FindFirstChild("Humanoid")
    if humanoid then
        humanoid.WalkSpeed = Settings.SpeedWalk and Settings.SpeedValue or 16
    end
end

local function ToggleSpeedWalk()
    if Settings.SpeedWalk then
        ApplySpeed()
        if SpeedConnection then SpeedConnection:Disconnect() end
        SpeedConnection = RunService.Heartbeat:Connect(ApplySpeed)
    else
        if SpeedConnection then SpeedConnection:Disconnect(); SpeedConnection = nil end
        ApplySpeed()
    end
end

--// ====================== METATABLE HOOKS ======================
local mt = getrawmetatable(game)
local oldIndex = mt.__index
local oldNamecall = mt.__namecall
setreadonly(mt, false)

-- Silent Aim (The Core Feature)
mt.__index = function(self, key)
    if key == "Hit" and Settings.SilentAim and UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
        local closest = GetClosestPlayerToCursor()
        if closest and closest.Character then
            local targetPart = GetTargetPart(closest.Character)
            if targetPart then
                return targetPart.CFrame
            end
        end
    end
    return oldIndex(self, key)
end

-- Bullet Mod (Remote Hook)
mt.__namecall = newcclosure(function(self, ...)
    local args = {...}
    local method = getnamecallmethod()
    
    if Settings.BulletMod and method == "FireServer" then
        if self == MainRemote or self.Name == "MainRemoteEvent" then
            if #args >= 3 and args[1] == "ShootGun" then
                for i, arg in ipairs(args) do
                    if typeof(arg) == "Vector3" and arg.Magnitude > 0 then
                        args[i] = arg.Unit * Settings.BulletSpeed
                    end
                end
            end
        end
    end
    
    return oldNamecall(self, unpack(args))
end)

setreadonly(mt, true)

--// ====================== COMBAT LOOPS ======================
local function TriggerbotCheck()
    if not Settings.Triggerbot then return end
    if GetClosestPlayerToCursor(Settings.TriggerFOV) then
        local character = LocalPlayer.Character
        if character then
            local tool = character:FindFirstChildOfClass("Tool")
            if tool then pcall(function() tool:Activate() end) end
        end
    end
end

local function RapidFireCheck()
    if not Settings.RapidFire then return end
    if not UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then return end
    
    local now = tick()
    if now - lastFire < Settings.FireRate then return end
    
    local character = LocalPlayer.Character
    if character then
        local tool = character:FindFirstChildOfClass("Tool")
        if tool then pcall(function() tool:Activate() end); lastFire = now end
    end
end

local function CamlockUpdate()
    if not Settings.Camlock then return end
    if not CamlockTarget or not IsAlive(CamlockTarget) then
        CamlockTarget = GetClosestPlayerToCursor()
    end
    if CamlockTarget and CamlockTarget.Character then
        local targetPart = GetTargetPart(CamlockTarget.Character)
        if targetPart then
            Camera.CFrame = Camera.CFrame:Lerp(CFrame.new(Camera.CFrame.Position, targetPart.Position), Settings.CamlockSmoothness)
        end
    end
end

--// ====================== MAIN LOOP ======================
local mainLoop = RunService.Heartbeat:Connect(function()
    UpdateESP()
    CamlockUpdate()
    TriggerbotCheck()
    RapidFireCheck()
end)
table.insert(Connections, mainLoop)

--// ====================== TRIGGER FOV CIRCLE ======================
local triggerFOVCircle = Instance.new("Frame")
triggerFOVCircle.Size = UDim2.new(0, Settings.TriggerFOV * 2, 0, Settings.TriggerFOV * 2)
triggerFOVCircle.BackgroundTransparency = 0.9
triggerFOVCircle.BorderSizePixel = 1
triggerFOVCircle.BorderColor3 = Color3.fromRGB(255, 50, 50)
triggerFOVCircle.Visible = false
triggerFOVCircle.Parent = game:GetService("CoreGui")
Instance.new("UICorner", triggerFOVCircle).CornerRadius = UDim.new(1, 0)

local circleUpdate = RunService.RenderStepped:Connect(function()
    if Settings.Triggerbot then
        triggerFOVCircle.Position = UDim2.new(0, Mouse.X - Settings.TriggerFOV, 0, Mouse.Y - Settings.TriggerFOV)
    end
end)
table.insert(Connections, circleUpdate)

--// ====================== CHARACTER ADDED ======================
LocalPlayer.CharacterAdded:Connect(function(char)
    task.wait(0.1)
    if Settings.SpeedWalk then ApplySpeed() end
    UpdateESP()
end)

--// ====================== NOTIFICATIONS ======================
local function ShowNotification(text, color)
    local notif = Instance.new("TextLabel")
    notif.Size = UDim2.new(1, 0, 0, 25)
    notif.Position = UDim2.new(0, 0, 0.8, 0)
    notif.BackgroundTransparency = 1
    notif.Text = text
    notif.TextColor3 = color or Color3.fromRGB(255, 255, 255)
    notif.TextSize = 13
    notif.Font = Enum.Font.GothamBold
    notif.TextStrokeTransparency = 0.7
    notif.TextTransparency = 1
    notif.Parent = game:GetService("CoreGui")
    task.delay(1.2, function() pcall(function() notif:Destroy() end) end)
end

--// ====================== UNLOAD ======================
local function UnloadScript()
    Settings.SpeedWalk = false
    ToggleSpeedWalk()
    Settings.ESPNames = false
    ClearESP()
    
    pcall(function() triggerFOVCircle:Destroy() end)
    pcall(function() StatusGui:Destroy() end)
    pcall(function() ESPGui:Destroy() end)
    
    for _, conn in ipairs(Connections) do
        pcall(function() conn:Disconnect() end)
    end
    
    pcall(function()
        setreadonly(mt, false)
        mt.__index = oldIndex
        mt.__namecall = oldNamecall
        setreadonly(mt, true)
    end)
    
    if LocalPlayer.Character then
        local humanoid = LocalPlayer.Character:FindFirstChild("Humanoid")
        if humanoid then humanoid.WalkSpeed = 16 end
    end
    
    print("FAZE.CC - Unloaded")
end

--// ====================== INPUT HANDLING ======================
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    if input.KeyCode == Enum.KeyCode.Insert then
        Settings.SilentAim = not Settings.SilentAim
        UpdateStatus()
        ShowNotification("Silent Aim: " .. (Settings.SilentAim and "ON" or "OFF"), Color3.fromRGB(255, 50, 50))
    elseif input.KeyCode == Enum.KeyCode.E then
        Settings.Triggerbot = not Settings.Triggerbot
        triggerFOVCircle.Visible = Settings.Triggerbot
        UpdateStatus()
        ShowNotification("Triggerbot: " .. (Settings.Triggerbot and "ON" or "OFF"), Color3.fromRGB(255, 50, 50))
    elseif input.KeyCode == Enum.KeyCode.C then
        Settings.Camlock = not Settings.Camlock
        if Settings.Camlock then CamlockTarget = GetClosestPlayerToCursor() else CamlockTarget = nil end
        UpdateStatus()
        ShowNotification("Camlock: " .. (Settings.Camlock and "ON" or "OFF"), Color3.fromRGB(255, 50, 50))
    elseif input.KeyCode == Enum.KeyCode.V then
        Settings.ESPNames = not Settings.ESPNames
        UpdateESP()
        UpdateStatus()
        ShowNotification("ESP Names: " .. (Settings.ESPNames and "ON" or "OFF"), Color3.fromRGB(255, 50, 50))
    elseif input.KeyCode == Enum.KeyCode.K then
        Settings.RapidFire = not Settings.RapidFire
        UpdateStatus()
        ShowNotification("Rapid Fire: " .. (Settings.RapidFire and "ON" or "OFF"), Color3.fromRGB(255, 50, 50))
    elseif input.KeyCode == Enum.KeyCode.B then
        Settings.BulletMod = not Settings.BulletMod
        UpdateStatus()
        ShowNotification("Bullet Mod: " .. (Settings.BulletMod and "ON" or "OFF"), Color3.fromRGB(255, 50, 50))
    elseif input.KeyCode == Enum.KeyCode.G then
        Settings.SpeedWalk = not Settings.SpeedWalk
        ToggleSpeedWalk()
        UpdateStatus()
        ShowNotification("Speed Walk: " .. (Settings.SpeedWalk and "ON" or "OFF"), Color3.fromRGB(255, 50, 50))
    elseif input.KeyCode == Enum.KeyCode.T then
        if Settings.ESPNames then
            local target = GetPlayerUnderCursor()
            if target then
                TargetedPlayer = target
                UpdateESPColors()
                UpdateStatus()
                ShowNotification("Target: " .. target.Name, Color3.fromRGB(255, 50, 50))
            end
        end
    elseif input.KeyCode == Enum.KeyCode.Y then
        TargetedPlayer = nil
        UpdateESPColors()
        UpdateStatus()
        ShowNotification("Target Cleared", Color3.fromRGB(150, 150, 150))
    elseif input.KeyCode == Enum.KeyCode.End then
        ShowNotification("FAZE.CC - Unloading...", Color3.fromRGB(255, 150, 0))
        task.wait(0.3)
        UnloadScript()
    end
    
    if Settings.SpeedWalk then
        if input.KeyCode == Enum.KeyCode.Up then
            Settings.SpeedValue = Settings.SpeedValue + 50
            ApplySpeed()
            UpdateStatus()
            ShowNotification("Speed: " .. Settings.SpeedValue, Color3.fromRGB(50, 255, 50))
        elseif input.KeyCode == Enum.KeyCode.Down then
            Settings.SpeedValue = math.max(Settings.SpeedValue - 50, 50)
            ApplySpeed()
            UpdateStatus()
            ShowNotification("Speed: " .. Settings.SpeedValue, Color3.fromRGB(255, 150, 50))
        end
    end
end)

--// ====================== INIT ======================
UpdateStatus()
UpdateESP()
ShowNotification("FAZE.CC Loaded!", Color3.fromRGB(255, 50, 50))

print("========================================")
print("FAZE.CC - FINAL WORKING SCRIPT LOADED")
print("INSERT - Silent Aim | E - Triggerbot")
print("C - Camlock | V - ESP Names")
print("K - Rapid Fire | B - Bullet Mod")
print("G - Speed Walk | T/Y - Target")
print("END - Unload")
print("========================================")

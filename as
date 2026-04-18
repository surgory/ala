--// ====================== faze.cc - COMPLETE SCRIPT ======================
local cfg = shared.faze

-- Services
local players = game:GetService("Players")
local uis = game:GetService("UserInputService")
local runservice = game:GetService("RunService")
local workspace = game:GetService("Workspace")
local camera = workspace.CurrentCamera
local localplayer = players.LocalPlayer
local mouse = localplayer:GetMouse()
local replicated = game:GetService("ReplicatedStorage")

-- Variables
local targeted_player = nil
local silent_aim_active = false
local triggerbot_active = false
local camlock_active = false
local speed_active = false
local esp_active = true
local rapid_active = false
local firing = false
local last_shot = 0
local last_rapid = 0
local esp_cache = {}
local main_remote = replicated:FindFirstChild("Remotes") and replicated.Remotes:FindFirstChild("MainRemoteEvent")

-- Status GUI
local gui = Instance.new("ScreenGui")
gui.Name = "faze_cc"
gui.Parent = game:GetService("CoreGui")

local status = Instance.new("TextLabel")
status.Size = UDim2.new(0, 200, 0, 120)
status.Position = UDim2.new(0, 10, 0, 10)
status.BackgroundTransparency = 1
status.Text = "faze.cc\nSilent: ON\nTrigger: OFF\nCamlock: OFF\nSpeed: OFF\nESP: ON\nTarget: NONE"
status.TextColor3 = Color3.fromRGB(180, 50, 255)
status.TextSize = 12
status.Font = Enum.Font.FredokaOne
status.TextStrokeTransparency = 0.7
status.TextXAlignment = Enum.TextXAlignment.Left
status.RichText = true
status.Parent = gui

-- Update status display
local function update_status()
    local silent_status = cfg['Silent Aim']['Enabled'] and "<font color='#50FF50'>ON</font>" or "<font color='#FF5050'>OFF</font>"
    local trigger_status = cfg['Trigger Bot']['Enabled'] and "<font color='#50FF50'>ON</font>" or "<font color='#FF5050'>OFF</font>"
    local camlock_status = cfg['Camlock']['Enabled'] and "<font color='#50FF50'>ON</font>" or "<font color='#FF5050'>OFF</font>"
    local speed_status = cfg['Local Player']['Speed']['Enabled'] and "<font color='#50FF50'>ON</font>" or "<font color='#FF5050'>OFF</font>"
    local esp_status = cfg['ESP']['Enabled'] and "<font color='#50FF50'>ON</font>" or "<font color='#FF5050'>OFF</font>"
    local target_status = targeted_player and targeted_player.Name or "NONE"
    
    status.Text = string.format("faze.cc\nSilent: %s\nTrigger: %s\nCamlock: %s\nSpeed: %s\nESP: %s\nTarget: %s",
        silent_status, trigger_status, camlock_status, speed_status, esp_status, target_status)
end

-- Utility functions
local function is_alive(plr)
    if not plr or not plr.Character then return false end
    local hum = plr.Character:FindFirstChild("Humanoid")
    return hum and hum.Health > 0
end

local function check_knocked(plr)
    if not cfg['Checks']['For Features']['Knocked'] then return false end
    if not plr or not plr.Character then return false end
    local be = plr.Character:FindFirstChild("BodyEffects")
    if be then
        local ko = be:FindFirstChild("K.O")
        if ko and ko.Value then return true end
        local knocked = be:FindFirstChild("Knocked")
        if knocked and knocked.Value then return true end
    end
    return false
end

local function check_forcefield(plr)
    if not cfg['Checks']['For Features']['Forcefield'] then return false end
    return plr and plr.Character and plr.Character:FindFirstChildOfClass("ForceField") ~= nil
end

local function check_wall(target_part, target_char)
    if not cfg['Checks']['For Features']['Wall Check'] then return true end
    if not target_part then return false end
    
    local origin = camera.CFrame.Position
    local dir = (target_part.Position - origin).Unit
    local dist = (target_part.Position - origin).Magnitude
    
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Blacklist
    params.FilterDescendantsInstances = {localplayer.Character, target_char}
    
    local hit = workspace:Raycast(origin, dir * dist, params)
    return hit == nil
end

local function is_valid_target(plr)
    if not plr or plr == localplayer then return false end
    if not is_alive(plr) then return false end
    if check_knocked(plr) then return false end
    if check_forcefield(plr) then return false end
    return true
end

local function get_target_part(character, hit_part)
    if hit_part == "Head" then
        return character:FindFirstChild("Head") or character:FindFirstChild("HumanoidRootPart")
    elseif hit_part == "Closest Part" then
        local closest, best = nil, math.huge
        local parts = {"Head", "UpperTorso", "LowerTorso", "HumanoidRootPart"}
        local mpos = uis:GetMouseLocation()
        for _, name in ipairs(parts) do
            local p = character:FindFirstChild(name)
            if p then
                local pos, onscreen = camera:WorldToViewportPoint(p.Position)
                if onscreen then
                    local dist = (Vector2.new(pos.X, pos.Y) - mpos).Magnitude
                    if dist < best then best = dist; closest = p end
                end
            end
        end
        return closest
    end
    return character:FindFirstChild("HumanoidRootPart")
end

-- Target selection
local function get_closest_player_to_crosshair()
    local mpos = uis:GetMouseLocation()
    local closest, best = nil, 100
    
    for _, plr in ipairs(players:GetPlayers()) do
        if is_valid_target(plr) then
            local part = plr.Character:FindFirstChild("Head") or plr.Character:FindFirstChild("HumanoidRootPart")
            if part then
                local pos, onscreen = camera:WorldToViewportPoint(part.Position)
                if onscreen then
                    local dist = (Vector2.new(pos.X, pos.Y) - mpos).Magnitude
                    if dist < best then best = dist; closest = plr end
                end
            end
        end
    end
    return closest
end

-- Silent Aim
local mt = getrawmetatable(game)
local old_index = mt.__index
setreadonly(mt, false)

mt.__index = function(self, key)
    if key == "Hit" and cfg['Silent Aim']['Enabled'] then
        if targeted_player and is_valid_target(targeted_player) then
            local part = get_target_part(targeted_player.Character, cfg['Silent Aim']['Settings']['Hit Part'])
            if part and check_wall(part, targeted_player.Character) then
                return part.CFrame
            end
        end
    end
    return old_index(self, key)
end
setreadonly(mt, true)

-- Zero Spread (Sniper DB)
local old_random = math.random
math.random = function(...)
    if cfg['Gun Modifications']['Custom Spread']['Enabled'] then
        local char = localplayer.Character
        if char then
            local tool = char:FindFirstChildOfClass("Tool")
            if tool and cfg['Gun Modifications']['Custom Spread'][tool.Name] then
                return old_random(...) * cfg['Gun Modifications']['Custom Spread'][tool.Name]
            end
        end
    end
    return old_random(...)
end

-- Weapon firing
local function fire_weapon()
    local char = localplayer.Character
    if not char then return end
    local tool = char:FindFirstChildOfClass("Tool")
    if tool and tool.Name ~= "[Knife]" then
        pcall(function() tool:Activate() end)
    end
end

-- Triggerbot
local function triggerbot_check()
    if not cfg['Trigger Bot']['Enabled'] then return end
    if not targeted_player or not is_valid_target(targeted_player) then return end
    
    local now = tick()
    if now - last_shot < cfg['Trigger Bot']['Interval'] then return end
    
    local part = get_target_part(targeted_player.Character, "Head")
    if not part then return end
    
    local pos, onscreen = camera:WorldToViewportPoint(part.Position)
    if not onscreen then return end
    
    local center = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y / 2)
    local dist = (Vector2.new(pos.X, pos.Y) - center).Magnitude
    if dist > 120 then return end
    
    if not check_wall(part, targeted_player.Character) then return end
    
    fire_weapon()
    last_shot = now
end

-- Camlock
local function camlock_update()
    if not cfg['Camlock']['Enabled'] then return end
    if not targeted_player or not is_valid_target(targeted_player) then return end
    
    local part = get_target_part(targeted_player.Character, cfg['Camlock']['Settings']['Part'])
    if not part then return end
    
    local smooth = cfg['Camlock']['Settings']['Smoothing']
    local target_cf = CFrame.new(camera.CFrame.Position, part.Position)
    local alpha = math.min(1 / smooth.X, 1)
    camera.CFrame = camera.CFrame:Lerp(target_cf, alpha)
end

-- Speed
local function apply_speed()
    if not cfg['Local Player']['Speed']['Enabled'] then return end
    local hum = localplayer.Character and localplayer.Character:FindFirstChild("Humanoid")
    if hum then
        hum.WalkSpeed = 16 * cfg['Local Player']['Speed']['Multipliers']['Normal']
    end
end

-- ESP
local esp_gui = Instance.new("ScreenGui")
esp_gui.Name = "faze_esp"
esp_gui.Parent = game:GetService("CoreGui")

local function update_esp()
    if not cfg['ESP']['Enabled'] then
        for _, bill in pairs(esp_cache) do bill:Destroy() end
        esp_cache = {}
        return
    end
    
    for _, plr in ipairs(players:GetPlayers()) do
        if plr ~= localplayer and is_alive(plr) then
            if not esp_cache[plr] then
                local hrp = plr.Character:FindFirstChild("HumanoidRootPart")
                if hrp then
                    local bill = Instance.new("BillboardGui")
                    bill.Size = UDim2.new(0, 100, 0, 26)
                    bill.StudsOffset = Vector3.new(0, -3.5, 0)
                    bill.AlwaysOnTop = true
                    bill.MaxDistance = 500
                    
                    local display = Instance.new("TextLabel")
                    display.Name = "Display"
                    display.Size = UDim2.new(1, 0, 0.5, 0)
                    display.BackgroundTransparency = 1
                    display.Text = plr.DisplayName
                    display.TextColor3 = cfg['ESP']['Settings']['Names']['Color']
                    display.TextSize = 11
                    display.Font = Enum.Font.FredokaOne
                    display.TextStrokeTransparency = 0.5
                    display.Parent = bill
                    
                    local username = Instance.new("TextLabel")
                    username.Name = "Username"
                    username.Size = UDim2.new(1, 0, 0.5, 0)
                    username.Position = UDim2.new(0, 0, 0.5, -2)
                    username.BackgroundTransparency = 1
                    username.Text = "@" .. plr.Name
                    username.TextColor3 = cfg['ESP']['Settings']['Names']['Color']
                    username.TextSize = 10
                    username.Font = Enum.Font.FredokaOne
                    username.TextStrokeTransparency = 0.6
                    username.TextTransparency = 0.3
                    username.Parent = bill
                    
                    bill.Parent = hrp
                    esp_cache[plr] = {bill = bill, display = display, username = username}
                end
            end
            
            -- Update colors for target
            if esp_cache[plr] then
                local color = (plr == targeted_player) and cfg['ESP']['Settings']['Names']['Target Color'] or cfg['ESP']['Settings']['Names']['Color']
                esp_cache[plr].display.TextColor3 = color
                esp_cache[plr].username.TextColor3 = color
            end
        else
            if esp_cache[plr] then
                esp_cache[plr].bill:Destroy()
                esp_cache[plr] = nil
            end
        end
    end
end

-- Rapid Fire
uis.InputBegan:Connect(function(input, processed)
    if processed then return end
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        firing = true
        task.spawn(function()
            while firing and cfg['Rapid Fire']['Enabled'] do
                fire_weapon()
                runservice.RenderStepped:Wait()
            end
        end)
    end
end)

uis.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        firing = false
    end
end)

-- Keybinds
local keybinds = cfg['Miscellaneous']['Keybinds']
uis.InputBegan:Connect(function(input, processed)
    if processed then return end
    
    local key = input.KeyCode
    
    if key == Enum.KeyCode[keybinds['Selection']] then
        targeted_player = get_closest_player_to_crosshair()
        update_status()
        update_esp()
    end
    
    if key == Enum.KeyCode[keybinds['Silent Aim']] then
        cfg['Silent Aim']['Enabled'] = not cfg['Silent Aim']['Enabled']
        update_status()
    end
    
    if key == Enum.KeyCode[keybinds['Trigger Bot']] then
        cfg['Trigger Bot']['Enabled'] = not cfg['Trigger Bot']['Enabled']
        update_status()
    end
    
    if key == Enum.KeyCode[keybinds['Camlock']] then
        cfg['Camlock']['Enabled'] = not cfg['Camlock']['Enabled']
        update_status()
    end
    
    if key == Enum.KeyCode[keybinds['Speed']] then
        cfg['Local Player']['Speed']['Enabled'] = not cfg['Local Player']['Speed']['Enabled']
        apply_speed()
        update_status()
    end
    
    if key == Enum.KeyCode[keybinds['ESP']] then
        cfg['ESP']['Enabled'] = not cfg['ESP']['Enabled']
        update_esp()
        update_status()
    end
    
    if key == Enum.KeyCode.Y then
        targeted_player = nil
        update_status()
        update_esp()
    end
    
    if key == Enum.KeyCode.End then
        -- Unload
        cfg['Silent Aim']['Enabled'] = false
        cfg['Trigger Bot']['Enabled'] = false
        cfg['Camlock']['Enabled'] = false
        cfg['Local Player']['Speed']['Enabled'] = false
        cfg['ESP']['Enabled'] = false
        update_esp()
        setreadonly(mt, false)
        mt.__index = old_index
        setreadonly(mt, true)
        math.random = old_random
        gui:Destroy()
        esp_gui:Destroy()
        print("faze.cc - Unloaded")
    end
end)

-- Character handling
localplayer.CharacterAdded:Connect(function(char)
    apply_speed()
    update_esp()
end)

-- Loops
runservice.RenderStepped:Connect(function()
    triggerbot_check()
    camlock_update()
end)

runservice.Heartbeat:Connect(function()
    update_esp()
end)

-- Initial
apply_speed()
update_esp()
update_status()

print("========================================")
print("faze.cc - Loaded")
print("C - Target | Y - Clear")
print("V - Triggerbot | X - Camlock")
print("G - Speed | B - ESP")
print("END - Unload")
print("========================================")

getgenv().RAYFIELD_SECURE = true
local Rayfield = loadstring(game:HttpGet("https://sirius.menu/gen2"))()

-- Services
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Camera = Workspace.CurrentCamera

local LocalPlayer = Players.LocalPlayer

-- Net / Remotes Setup
local NetModule = ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Net")
local Net = require(NetModule)
local SkillCheckRemote = Net:Event("SkillCheck")

-- ============================================================
-- STATE VARIABLES & OBJECT TABLES
-- ============================================================
local InfiniteStaminaEnabled = false
local EspEnabled = false
local NoSpreadEnabled = false
local AntiRagdollEnabled = false
local AutoSkillCheckEnabled = false
local AutoHopiumEnabled = false

-- New Features
local InfiniteAmmoEnabled = false
local AmmoBagESPEnabled = false
local BonBonESPEnabled = false

-- Rainbow / Chams Variables
local RainbowEnabled = false
local RainbowSpeed = 5
local rainbowHue = 0

-- Aimbot Variables
local AimbotEnabled = false
local AimbotVisibleCheck = false
local AimbotFOV = 150
local AimbotSmoothness = 5

-- Aimbot Keybind Variables
local AimbotMode = "Hold" -- "Hold" or "Toggle"
local AimbotKeyHeld = false
local AimbotToggleState = false
local LastKeyState = false

-- Shared Radar/Aimbot Folders Logic
local FoldersToScan = {
    { Name = "NPCs", PlayersOnly = false }       -- Tracks Dogs
}

-- Drawing Tables
local FOVCircle = Drawing.new("Circle")
FOVCircle.Thickness = 1
FOVCircle.Color = Color3.fromRGB(255, 255, 255)
FOVCircle.Filled = false
FOVCircle.Transparency = 0.5
FOVCircle.Visible = false

local ActiveMarks = {}
local AmmoMarks = {}
local BonBonMarks = {}

-- ============================================================
-- RAYFIELD UI
-- ============================================================
local Window = Rayfield:CreateWindow({
    name = "Dogs Cheat",
    subtitle = "Small Menu",
    sidebarLayout = true, 
})

-- 1. AIM TAB
local AimTab = Window:CreateTab({
    name = "Aim",
    icon = "crosshair",
})

AimTab:CreateToggle({
    name = "Dog Aimbot",
    currentValue = false,
    flag = "DogAimbot",
    callback = function(value)
        AimbotEnabled = value
    end,
})

AimTab:CreateKeybind({
    name = "Aim Keybind",
    currentKeybind = "MouseButton2", -- Default to RMB
    holdToInteract = true,
    flag = "AimbotKeybind",
    callback = function(isHeld)
        AimbotKeyHeld = isHeld
        -- Handle toggle logic carefully so it doesn't flicker
        if AimbotMode == "Toggle" and isHeld and not LastKeyState then
            AimbotToggleState = not AimbotToggleState
        end
        LastKeyState = isHeld
    end,
})

AimTab:CreateDropdown({
    name = "Aim Mode",
    options = {"Hold", "Toggle"},
    currentOption = {"Hold"},
    multipleOptions = false,
    flag = "AimModeSelect",
    callback = function(options)
        AimbotMode = options[1]
    end,
})

AimTab:CreateToggle({
    name = "Visible Check",
    currentValue = false,
    flag = "VisibleCheck",
    callback = function(value)
        AimbotVisibleCheck = value
    end,
})

AimTab:CreateSlider({
    name = "FOV Size",
    range = {30, 800},
    increment = 10,
    suffix = "px",
    currentValue = 150,
    flag = "AimbotFOV",
    callback = function(value)
        AimbotFOV = value
    end,
})

AimTab:CreateSlider({
    name = "Smoothness",
    range = {1, 20},
    increment = 1,
    suffix = "x",
    currentValue = 5,
    flag = "AimbotSmoothness",
    callback = function(value)
        AimbotSmoothness = value
    end,
})

-- 2. COMBAT TAB
local CombatTab = Window:CreateTab({
    name = "Combat",
    icon = "crosshair",
})

CombatTab:CreateToggle({
    name = "No Spread",
    currentValue = false,
    flag = "NoSpread",
    callback = function(value)
        NoSpreadEnabled = value
    end,
})

CombatTab:CreateToggle({
    name = "Infinite Ammo",
    currentValue = false,
    flag = "InfiniteAmmo",
    callback = function(value)
        InfiniteAmmoEnabled = value
    end,
})

-- 3. PLAYER TAB
local PlayerTab = Window:CreateTab({
    name = "Player",
    icon = "user",
})

PlayerTab:CreateToggle({
    name = "Infinite Stamina",
    currentValue = false,
    flag = "InfiniteStamina",
    callback = function(value)
        InfiniteStaminaEnabled = value
        if value then
            local char = LocalPlayer.Character
            if char then char:SetAttribute("Epicsauce", Workspace:GetServerTimeNow() + 999999) end
        elseif LocalPlayer.Character then
            LocalPlayer.Character:SetAttribute("Epicsauce", nil)
        end
    end,
})

PlayerTab:CreateToggle({
    name = "Anti-Ragdoll",
    currentValue = false,
    flag = "AntiRagdoll",
    callback = function(value)
        AntiRagdollEnabled = value
        if value then
            applyAntiRagdoll(LocalPlayer.Character)
        end
    end,
})

PlayerTab:CreateToggle({
    name = "Auto Skill Check",
    currentValue = false,
    flag = "AutoSkill",
    callback = function(value)
        AutoSkillCheckEnabled = value
    end,
})

PlayerTab:CreateToggle({
    name = "Auto Hopium",
    currentValue = false,
    flag = "AutoHopium",
    callback = function(value)
        AutoHopiumEnabled = value
    end,
})

-- 4. VISUALS TAB
local VisualsTab = Window:CreateTab({
    name = "Visuals",
    icon = "eye",
})

VisualsTab:CreateToggle({
    name = "Radar ESP",
    currentValue = false,
    flag = "RadarESP",
    callback = function(value)
        EspEnabled = value
        if not value then clearESP() end
    end,
})

VisualsTab:CreateToggle({
    name = "Ammo Bag ESP",
    currentValue = false,
    flag = "AmmoBagESP",
    callback = function(value)
        AmmoBagESPEnabled = value
        if not value then clearAmmoESP() end
    end,
})

VisualsTab:CreateSection("Chams / Rainbow")
VisualsTab:CreateToggle({
    name = "Rainbow Mode",
    currentValue = false,
    flag = "RainbowMode",
    callback = function(value)
        RainbowEnabled = value
        if not value then
            if FOVCircle then FOVCircle.Color = Color3.fromRGB(255, 255, 255) end
        end
    end,
})

VisualsTab:CreateSlider({
    name = "Rainbow Speed",
    range = {1, 20},
    increment = 1,
    suffix = "x",
    currentValue = 5,
    flag = "RainbowSpeed",
    callback = function(value)
        RainbowSpeed = value
    end,
})

VisualsTab:CreateSection("Halloween Event")
VisualsTab:CreateToggle({
    name = "🎃 Bon Bon ESP",
    currentValue = false,
    flag = "BonBonESP",
    callback = function(value)
        BonBonESPEnabled = value
        if not value then clearBonBonESP() end
    end,
})

VisualsTab:CreateButton({
    name = "Teleport to Bon Bon",
    callback = function()
        local bonBon = getBonBon()
        local char = LocalPlayer.Character
        if bonBon and char and char:FindFirstChild("HumanoidRootPart") then
            local pos
            if bonBon:IsA("BasePart") then
                pos = bonBon.Position
            else
                local primary = bonBon.PrimaryPart or bonBon:FindFirstChild("HumanoidRootPart") or bonBon:FindFirstChildWhichIsA("BasePart")
                if primary then pos = primary.Position end
            end
            
            if pos then
                char.HumanoidRootPart.CFrame = CFrame.new(pos + Vector3.new(0, 5, 0))
            end
        end
    end,
})

-- 5. SETTINGS TAB
local SettingsTab = Window:CreateTab({
    name = "Settings",
    icon = "settings",
})

SettingsTab:CreateSection("UI Theme")
SettingsTab:CreateDropdown({
    name = "Theme",
    options = {"Default", "AmberGlow", "Amethyst", "Bloom", "DarkBlue", "Green", "Light", "Ocean", "Serenity"},
    currentOption = {"Default"},
    multipleOptions = false,
    flag = "ThemeSelect",
    callback = function(options)
        Window:ModifyTheme(options[1])
    end,
})

-- ============================================================
-- LOGIC: INFINITE AMMO
-- ============================================================
task.spawn(function()
    while true do
        if InfiniteAmmoEnabled then
            local character = LocalPlayer.Character
            if character then
                character:SetAttribute("Ammo", 999)
                character:SetAttribute("Clip", 999)
                character:SetAttribute("Reserve", 999)
                character:SetAttribute("CurrentAmmo", 999)

                local tool = character:FindFirstChildOfClass("Tool")
                if tool then
                    tool:SetAttribute("Ammo", 999)
                    tool:SetAttribute("Clip", 999)
                    tool:SetAttribute("Reserve", 999)
                    tool:SetAttribute("CurrentAmmo", 999)
                    
                    for _, child in ipairs(tool:GetDescendants()) do
                        if child:IsA("IntValue") and (string.find(child.Name:lower(), "ammo") or string.find(child.Name:lower(), "clip")) then
                            child.Value = 999
                        end
                    end
                end
            end
        end
        task.wait(0.1)
    end
end)

-- ============================================================
-- LOGIC: BON BON ESP & FINDER
-- ============================================================
function clearBonBonESP()
    for obj, data in pairs(BonBonMarks) do
        if data.highlight and data.highlight.Parent then data.highlight:Destroy() end
        if data.text then data.text:Remove() end
    end
    table.clear(BonBonMarks)
end

function getBonBon()
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("BasePart") or obj:IsA("Model") then
            local name = obj.Name:lower():gsub("%s+", "")
            if string.find(name, "bonbon") or string.find(name, "bon") then
                local parentModel = obj:FindFirstAncestorOfClass("Model")
                if not (parentModel and parentModel:FindFirstChildOfClass("Humanoid")) then
                    return obj
                end
            end
        end
    end
    return nil
end

local function updateBonBonESP()
    if not BonBonESPEnabled then return end
    local CurrentTargets = {}

    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("BasePart") or obj:IsA("Model") then
            local name = obj.Name:lower():gsub("%s+", "")
            if string.find(name, "bonbon") or string.find(name, "bon") then
                local parentModel = obj:FindFirstAncestorOfClass("Model")
                if not (parentModel and parentModel:FindFirstChildOfClass("Humanoid")) then
                    CurrentTargets[obj] = true
                    
                    local data = BonBonMarks[obj]
                    if not data or not data.highlight or not data.highlight.Parent then
                        local highlight = Instance.new("Highlight")
                        highlight.Name = "BonBonMark"
                        highlight.FillColor = Color3.fromRGB(255, 100, 0)
                        highlight.OutlineColor = Color3.fromRGB(0, 0, 0)
                        highlight.FillTransparency = 0.2
                        highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                        highlight.Adornee = obj
                        highlight.Parent = obj
                        
                        local text = Drawing.new("Text")
                        text.Text = "Bon Bon"
                        text.Color = Color3.fromRGB(255, 100, 0)
                        text.Size = 16
                        text.Center = true
                        text.Outline = true
                        text.OutlineColor = Color3.fromRGB(0, 0, 0)
                        text.Font = 2
                        text.Visible = false
                        
                        BonBonMarks[obj] = { highlight = highlight, text = text }
                    end
                    
                    if not RainbowEnabled then
                        BonBonMarks[obj].highlight.FillColor = Color3.fromRGB(255, 100, 0)
                        BonBonMarks[obj].text.Color = Color3.fromRGB(255, 100, 0)
                    end
                end
            end
        end
    end

    for obj, data in pairs(BonBonMarks) do
        if not CurrentTargets[obj] then
            if data.highlight then data.highlight:Destroy() end
            if data.text then data.text:Remove() end
            BonBonMarks[obj] = nil
        end
    end
end

RunService.RenderStepped:Connect(function()
    if not BonBonESPEnabled then return end
    for obj, data in pairs(BonBonMarks) do
        if data.text and data.highlight and data.highlight.Parent then
            local pos
            if obj:IsA("BasePart") then
                pos = obj.Position
            elseif obj:IsA("Model") then
                local primary = obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")
                if primary then pos = primary.Position end
            end
            
            if pos then
                local screenPos, onScreen = Camera:WorldToViewportPoint(pos)
                if onScreen then
                    data.text.Position = Vector2.new(screenPos.X, screenPos.Y - 30)
                    data.text.Visible = true
                else
                    data.text.Visible = false
                end
            else
                data.text.Visible = false
            end
        end
    end
end)

task.spawn(function()
    while true do
        if BonBonESPEnabled then pcall(updateBonBonESP) end
        task.wait(0.5)
    end
end)

-- ============================================================
-- LOGIC: AMMO BAG ESP
-- ============================================================
function clearAmmoESP()
    for part, data in pairs(AmmoMarks) do
        if data.highlight and data.highlight.Parent then data.highlight:Destroy() end
        if data.text then data.text:Remove() end
    end
    table.clear(AmmoMarks)
end

local function updateAmmoESP()
    if not AmmoBagESPEnabled then return end
    local CurrentTargets = {}

    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("BasePart") or obj:IsA("Model") then
            local name = obj.Name:lower()
            if string.find(name, "ammo") or string.find(name, "bag") or string.find(name, "resupply") then
                local parentModel = obj:FindFirstAncestorOfClass("Model")
                if not (parentModel and parentModel:FindFirstChildOfClass("Humanoid")) then
                    CurrentTargets[obj] = true
                    
                    local data = AmmoMarks[obj]
                    if not data or not data.highlight or not data.highlight.Parent then
                        local highlight = Instance.new("Highlight")
                        highlight.Name = "AmmoMark"
                        highlight.FillColor = Color3.fromRGB(255, 170, 0)
                        highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
                        highlight.FillTransparency = 0.3
                        highlight.OutlineTransparency = 0
                        highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                        highlight.Adornee = obj
                        highlight.Parent = obj
                        
                        local text = Drawing.new("Text")
                        text.Text = "Ammo Bag"
                        text.Color = Color3.fromRGB(255, 255, 255)
                        text.Size = 16
                        text.Center = true
                        text.Outline = true
                        text.OutlineColor = Color3.fromRGB(0, 0, 0)
                        text.Font = 2
                        text.Visible = false
                        
                        AmmoMarks[obj] = { highlight = highlight, text = text }
                    end

                    if not RainbowEnabled then
                        AmmoMarks[obj].highlight.FillColor = Color3.fromRGB(255, 170, 0)
                        AmmoMarks[obj].text.Color = Color3.fromRGB(255, 255, 255)
                    end
                end
            end
        end
    end

    for obj, data in pairs(AmmoMarks) do
        if not CurrentTargets[obj] then
            if data.highlight then data.highlight:Destroy() end
            if data.text then data.text:Remove() end
            AmmoMarks[obj] = nil
        end
    end
end

RunService.RenderStepped:Connect(function()
    if not AmmoBagESPEnabled then return end
    for obj, data in pairs(AmmoMarks) do
        if data.text and data.highlight and data.highlight.Parent then
            local pos
            if obj:IsA("BasePart") then
                pos = obj.Position
            elseif obj:IsA("Model") then
                local primary = obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")
                if primary then pos = primary.Position end
            end
            
            if pos then
                local screenPos, onScreen = Camera:WorldToViewportPoint(pos)
                if onScreen then
                    data.text.Position = Vector2.new(screenPos.X, screenPos.Y - 25)
                    data.text.Visible = true
                else
                    data.text.Visible = false
                end
            else
                data.text.Visible = false
            end
        end
    end
end)

task.spawn(function()
    while true do
        if AmmoBagESPEnabled then pcall(updateAmmoESP) end
        task.wait(0.5)
    end
end)

-- ============================================================
-- AIMBOT LOGIC
-- ============================================================
local function getTargetPart(model)
    return model:FindFirstChild("Head")
        or model:FindFirstChild("Torso")
        or model:FindFirstChild("UpperTorso")
        or model:FindFirstChild("HumanoidRootPart")
        or model.PrimaryPart
end

local function getClosestTarget()
    local closestPart = nil
    local shortestDist = AimbotFOV
    local center = Camera.ViewportSize / 2
    local LocalChar = LocalPlayer.Character

    for _, folderData in ipairs(FoldersToScan) do
        local folder = Workspace:FindFirstChild(folderData.Name)
        if folder then
            for _, model in ipairs(folder:GetChildren()) do
                local humanoid = model:IsA("Model") and model:FindFirstChildOfClass("Humanoid")
                if humanoid and humanoid.Health > 0 and model ~= LocalChar then
                    local isPlayer = Players:GetPlayerFromCharacter(model)
                    
                    if not folderData.PlayersOnly or isPlayer then
                        local targetPart = getTargetPart(model)
                        if targetPart then
                            local screenPos, onScreen = Camera:WorldToViewportPoint(targetPart.Position)
                            if onScreen then
                                local dist = (Vector2.new(screenPos.X, screenPos.Y) - center).Magnitude
                                if dist < shortestDist then
                                    if AimbotVisibleCheck then
                                        local rayParams = RaycastParams.new()
                                        rayParams.FilterType = Enum.RaycastFilterType.Exclude
                                        rayParams.FilterDescendantsInstances = { LocalChar, folder }
                                        local rayOrigin = Camera.CFrame.Position
                                        local rayDir = targetPart.Position - rayOrigin
                                        local rayResult = Workspace:Raycast(rayOrigin, rayDir, rayParams)
                                        
                                        if not rayResult then
                                            shortestDist = dist
                                            closestPart = targetPart
                                        end
                                    else
                                        shortestDist = dist
                                        closestPart = targetPart
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    return closestPart
end

RunService.RenderStepped:Connect(function()
    -- Handle FOV Circle Display
    if AimbotEnabled then
        FOVCircle.Visible = true
        FOVCircle.Position = Camera.ViewportSize / 2
        FOVCircle.Radius = AimbotFOV
    else
        FOVCircle.Visible = false
    end

    -- Handle Keybind State Logic
    local isAimbotActive = false
    if AimbotMode == "Hold" then
        isAimbotActive = AimbotKeyHeld
    else
        isAimbotActive = AimbotToggleState
    end

    -- Check if Aimbot is Enabled AND the keybind mode is currently active
    if not AimbotEnabled or not isAimbotActive then return end
    if UserInputService.MouseBehavior == Enum.MouseBehavior.Default then return end

    local targetPart = getClosestTarget()
    if targetPart then
        local screenPos, onScreen = Camera:WorldToViewportPoint(targetPart.Position)
        if onScreen then
            local center = Camera.ViewportSize / 2
            local deltaX = screenPos.X - center.X
            local deltaY = screenPos.Y - center.Y
            local factor = 1 / AimbotSmoothness
            mousemoverel(deltaX * factor, deltaY * factor)
        end
    end
end)

-- ============================================================
-- LOGIC: NO SPREAD
-- ============================================================
task.spawn(function()
    while true do
        local character = LocalPlayer.Character
        if character and NoSpreadEnabled then
            local tool = character:FindFirstChildOfClass("Tool")
            if tool then
                tool:SetAttribute("Spread", 0)
            end
        end
        task.wait(0.05)
    end
end)

-- ============================================================
-- LOGIC: AUTO SKILL CHECK
-- ============================================================
RunService.RenderStepped:Connect(function()
    if not AutoSkillCheckEnabled then return end
    local char = LocalPlayer.Character
    if not char or char:GetAttribute("Dragged") ~= true then return end

    local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
    if not playerGui then return end

    local skillGui = playerGui:FindFirstChild("SkillCheck")
    if skillGui and skillGui.Enabled then
        local track = skillGui:FindFirstChild("Track", true)
        local zone = track and track:FindFirstChild("Zone", true)
        local pointer = track and track:FindFirstChild("Pointer", true)

        if zone and pointer then
            local pX = pointer.Position.X.Scale
            local zX = zone.Position.X.Scale
            local zWidth = zone.Size.X.Scale
            if pX >= zX and pX <= (zX + zWidth) then
                SkillCheckRemote:FireServer()
                task.wait(0.2)
            end
        end
    end
end)

-- ============================================================
-- LOGIC: AUTO HOPIUM
-- ============================================================
task.spawn(function()
    while true do
        local shouldFire = false
        if AutoHopiumEnabled then
            shouldFire = UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)
        end

        if shouldFire then
            local char = LocalPlayer.Character
            if char then
                for _, child in ipairs(char:GetChildren()) do
                    if child:IsA("Tool") and child.Name:lower():gsub("%s+", "") == "hopium" then
                        for _ = 1, 5 do
                            pcall(function() child:Activate() end)
                        end
                    end
                end
            end
            RunService.Heartbeat:Wait()
        else
            task.wait(0.05)
        end
    end
end)

-- ============================================================
-- LOGIC: INFINITE STAMINA
-- ============================================================
task.spawn(function()
    while true do
        if InfiniteStaminaEnabled then
            local char = LocalPlayer.Character
            if char then
                char:SetAttribute("Epicsauce", Workspace:GetServerTimeNow() + 999999)
            end
        end

        for _, effect in ipairs(Lighting:GetChildren()) do
            if effect:IsA("ColorCorrectionEffect") then
                effect.Enabled = false
            end
        end
        local heartbeatSound = game:GetService("SoundService"):FindFirstChild("Heartbeat")
        if heartbeatSound then heartbeatSound:Destroy() end

        task.wait(0.1)
    end
end)

-- ============================================================
-- LOGIC: ANTI-RAGDOLL
-- ============================================================
local function fixJointsAndState(character)
    if not character then return end
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end

    humanoid.PlatformStand = false
    humanoid.AutoRotate = true
    humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)
    humanoid:SetStateEnabled(Enum.HumanoidStateType.GettingUp, true)
    humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)

    if humanoid.UseJumpPower then
        humanoid.JumpPower = 50
    else
        humanoid.JumpHeight = 7.2
    end

    for _, desc in ipairs(character:GetDescendants()) do
        if desc:IsA("BallSocketConstraint") or desc:IsA("HingeConstraint") or desc:IsA("RopeConstraint") or desc:IsA("NoCollisionConstraint") then
            desc:Destroy()
        elseif desc:IsA("Motor6D") then
            desc.Enabled = true
        end
    end

    local animateScript = character:FindFirstChild("Animate")
    if animateScript then
        if animateScript.Disabled then
            animateScript.Disabled = false
        else
            animateScript.Disabled = true
            task.wait()
            animateScript.Disabled = false
        end
    end
end

function applyAntiRagdoll(character)
    if not character then return end
    character:SetAttribute("Ragdolled", false)
    character:SetAttribute("Shocked", nil)
    fixJointsAndState(character)

    character:GetAttributeChangedSignal("Ragdolled"):Connect(function()
        if AntiRagdollEnabled then
            task.wait()
            character:SetAttribute("Ragdolled", false)
            fixJointsAndState(character)
        end
    end)
    character:GetAttributeChangedSignal("Shocked"):Connect(function()
        if AntiRagdollEnabled then
            character:SetAttribute("Shocked", nil)
        end
    end)
end

LocalPlayer.CharacterAdded:Connect(function(char)
    if InfiniteStaminaEnabled then
        task.wait(0.5)
        char:SetAttribute("Epicsauce", Workspace:GetServerTimeNow() + 999999)
    end
    if AntiRagdollEnabled then
        task.wait(0.5)
        applyAntiRagdoll(char)
    end
end)

-- ============================================================
-- LOGIC: RADAR ESP
-- ============================================================
local ESPColors = {
    { Name = "Characters", Color = Color3.fromRGB(70, 140, 255), PlayersOnly = true },
    { Name = "NPCs", Color = Color3.fromRGB(255, 55, 55), Named = { Cremator = Color3.fromRGB(0, 0, 0) } }
}

function clearESP()
    for model, data in pairs(ActiveMarks) do
        if data.highlight and data.highlight.Parent then data.highlight:Destroy() end
        if data.healthBar then data.healthBar:Remove() end
        if data.hpText then data.hpText:Remove() end
    end
    table.clear(ActiveMarks)
end

local function updateESP()
    if not EspEnabled then return end
    local LocalChar = LocalPlayer.Character
    local CurrentTargets = {}

    for _, folderData in ipairs(ESPColors) do
        local folder = Workspace:FindFirstChild(folderData.Name)
        if folder then
            for _, model in ipairs(folder:GetChildren()) do
                local humanoid = model:IsA("Model") and model:FindFirstChildOfClass("Humanoid")
                if humanoid and humanoid.Health > 0 and model ~= LocalChar then
                    local isPlayer = Players:GetPlayerFromCharacter(model)
                    if not folderData.PlayersOnly or isPlayer then
                        CurrentTargets[model] = true
                        local data = ActiveMarks[model]
                        
                        if not data or not data.highlight or not data.highlight.Parent then
                            local highlight = Instance.new("Highlight")
                            highlight.Name = "RadarMark"
                            highlight.FillTransparency = 0.5
                            highlight.OutlineTransparency = 1
                            highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                            highlight.Adornee = model
                            highlight.Parent = model
                            
                            local healthBar = Drawing.new("Line")
                            healthBar.Thickness = 2
                            healthBar.Transparency = 1
                            healthBar.Visible = false
                            
                            local hpText = Drawing.new("Text")
                            hpText.Size = 14
                            hpText.Center = true
                            hpText.Outline = true
                            hpText.OutlineColor = Color3.fromRGB(0, 0, 0)
                            hpText.Font = 2
                            hpText.Visible = false
                            
                            ActiveMarks[model] = { highlight = highlight, healthBar = healthBar, hpText = hpText }
                            data = ActiveMarks[model]
                        end
                        
                        if not RainbowEnabled then
                            local customColor = folderData.Named and folderData.Named[model.Name]
                            data.highlight.FillColor = customColor or folderData.Color
                        end
                    end
                end
            end
        end
    end

    for model, data in pairs(ActiveMarks) do
        if not CurrentTargets[model] then
            if data.highlight then data.highlight:Destroy() end
            if data.healthBar then data.healthBar:Remove() end
            if data.hpText then data.hpText:Remove() end
            ActiveMarks[model] = nil
        end
    end
end

RunService.RenderStepped:Connect(function()
    if not EspEnabled then return end
    for model, data in pairs(ActiveMarks) do
        local humanoid = model:FindFirstChildOfClass("Humanoid")
        local head = model:FindFirstChild("Head") or model:FindFirstChild("Torso") or model:FindFirstChild("HumanoidRootPart") or model.PrimaryPart
        
        if humanoid and humanoid.Health > 0 and head then
            local screenPos, onScreen = Camera:WorldToViewportPoint(head.Position + Vector3.new(0, 1.5, 0))
            if onScreen then
                local hpPercent = humanoid.Health / humanoid.MaxHealth
                
                local color = Color3.fromRGB(255 - (255 * hpPercent), 255 * hpPercent, 0)
                
                local barHeight = 30
                local barX = screenPos.X - 30
                local barY = screenPos.Y - barHeight
                
                data.healthBar.From = Vector2.new(barX, barY)
                data.healthBar.To = Vector2.new(barX, barY + barHeight)
                data.healthBar.Color = color
                data.healthBar.Visible = true
                
                data.hpText.Position = Vector2.new(barX - 12, barY + (barHeight / 2) - 7)
                data.hpText.Text = tostring(math.floor(humanoid.Health))
                data.hpText.Color = color
                data.hpText.Visible = true
            else
                data.healthBar.Visible = false
                data.hpText.Visible = false
            end
        else
            data.healthBar.Visible = false
            data.hpText.Visible = false
        end
    end
end)

task.spawn(function()
    while true do
        if EspEnabled then pcall(updateESP) end
        task.wait(0.4)
    end
end)

-- ============================================================
-- LOGIC: RAINBOW CHAMS LOOP
-- ============================================================
RunService.Heartbeat:Connect(function(dt)
    if not RainbowEnabled then return end
    
    rainbowHue = (rainbowHue + dt * (RainbowSpeed / 10)) % 1
    local rainbowColor = Color3.fromHSV(rainbowHue, 1, 1)

    -- Update FOV Circle
    if FOVCircle and AimbotEnabled then
        FOVCircle.Color = rainbowColor
    end

    -- Update Radar ESP
    for model, data in pairs(ActiveMarks) do
        if data.highlight then
            data.highlight.FillColor = rainbowColor
        end
    end

    -- Update Bon Bon ESP
    for obj, data in pairs(BonBonMarks) do
        if data.highlight then data.highlight.FillColor = rainbowColor end
        if data.text then data.text.Color = rainbowColor end
    end

    -- Update Ammo Bag ESP
    for obj, data in pairs(AmmoMarks) do
        if data.highlight then data.highlight.FillColor = rainbowColor end
        if data.text then data.text.Color = rainbowColor end
    end
end)

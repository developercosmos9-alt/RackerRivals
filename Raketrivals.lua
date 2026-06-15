local splib = loadstring(game:HttpGet("https://raw.githubusercontent.com/as6cd0/SP_Hub/refs/heads/main/splibv2"))()

-- Check if player is in Racket Rivals
local isRacketRivals = true
pcall(function()
    local gameName = game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name or ""
    if gameName:lower():find("racket rivals") or gameName:lower():find("racquet rivals") then
        isRacketRivals = true
    else
        -- Check if it's a different well-known game
        isRacketRivals = true -- Allow by default, warn if it's obviously not Racket Rivals
    end
end)

if not isRacketRivals then
    print("You arent in racket Rivals!!")
    return
end

-- Setup infinite jump
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local InfiniteJumpEnabled = false

local function getPlayer()
    return Players.LocalPlayer or Players:GetPlayers()[1]
end

local function getCharacter()
    local player = getPlayer()
    return player and player.Character or player.CharacterAdded:Wait()
end

local NoclipEnabled = false
local noclipConnection
local noclipHeartbeat
local RunService = game:GetService("RunService")

local function enableNoclip()
    local char = getCharacter()
    if not char then return end

    for _, part in pairs(char:GetDescendants()) do
        if part:IsA("BasePart") then
            part.CanCollide = false
        end
    end
end

local function disableNoclip()
    local char = getCharacter()
    if not char then return end

    for _, part in pairs(char:GetDescendants()) do
        if part:IsA("BasePart") then
            part.CanCollide = true
        end
    end
end

local function setupNoclipListener()
    local char = getCharacter()
    if not char then return end

    if noclipConnection then
        noclipConnection:Disconnect()
    end

    noclipConnection = char.DescendantAdded:Connect(function(part)
        if NoclipEnabled and part:IsA("BasePart") then
            part.CanCollide = false
        end
    end)
end

local function startNoclip()
    if noclipHeartbeat then
        noclipHeartbeat:Disconnect()
    end

    noclipHeartbeat = RunService.Heartbeat:Connect(function()
        if not NoclipEnabled then
            return
        end

        local char = getCharacter()
        if not char then return end

        for _, part in pairs(char:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = false
            end
        end
    end)

    setupNoclipListener()
end

startNoclip()

local EspEnabled = false
local SkeletonEnabled = false
local EspMaxDistance = 1000
local WalkSpeed = 16
local WalkSpeedEnabled = false
local AutoParryEnabled = false
local ParryRadius = 60
local parryDebounce = false
local espObjects = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualUser = game:GetService("VirtualUser")

local ballKeywords = {"ball", "racket", "projectile", "sphere", "tennis", "shot", "orb", "disc", "disk", "puck", "bullet", "missile", "shuttle", "shuttlecock", "birdie", "cork", "feather"}

local function applyWalkSpeed()
    local player = getPlayer()
    if not player or not player.Character then return end
    local hum = player.Character:FindFirstChildOfClass("Humanoid")
    if hum then
        if WalkSpeedEnabled then
            hum.WalkSpeed = WalkSpeed or 16
        else
            hum.WalkSpeed = 16
        end
    end
end

local function isBallPart(part)
    if not part or not part:IsA("BasePart") then
        return false
    end
    local lowerName = part.Name:lower()
    for _, keyword in ipairs(ballKeywords) do
        if lowerName:find(keyword) then
            return true
        end
    end
    if part.Shape == Enum.PartType.Ball then
        return true
    end
    local size = part.Size
    if math.abs(size.X - size.Y) < 0.1 and math.abs(size.Y - size.Z) < 0.1 and size.X < 5 then
        return true
    end
    return false
end

local function GetActiveBall()
    local player = getPlayer()
    local root = player and player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    local bestBall
    local bestDistance = ParryRadius * 2

    for _, descendant in ipairs(workspace:GetDescendants()) do
        if descendant:IsA("BasePart") and isBallPart(descendant) then
            local distance = root and root.Position and (descendant.Position - root.Position).Magnitude or 0
            if not root or distance < bestDistance then
                bestBall = descendant
                bestDistance = distance
            end
        end
    end
    return bestBall
end

local function FireParryRemote(ball)
    local remoteNames = {"Parry", "ParryAttempt", "Hit", "Swing", "SwingRacket", "HitBall", "Attack", "Deflect"}
    local fired = false
    local args = {nil, ball, ball and ball.Name, ball and ball.Position}

    for _, name in ipairs(remoteNames) do
        for _, remote in ipairs({ReplicatedStorage:FindFirstChild(name, true)}) do
            if remote then
                for _, arg in ipairs(args) do
                    if remote:IsA("RemoteEvent") or remote:IsA("UnreliableRemoteEvent") then
                        pcall(function()
                            if arg == nil then
                                remote:FireServer()
                            else
                                remote:FireServer(arg)
                            end
                        end)
                    elseif remote:IsA("RemoteFunction") then
                        pcall(function()
                            if arg == nil then
                                remote:InvokeServer()
                            else
                                remote:InvokeServer(arg)
                            end
                        end)
                    end
                    if remote and (remote:IsA("RemoteEvent") or remote:IsA("RemoteFunction") or remote:IsA("UnreliableRemoteEvent")) then
                        fired = true
                        break
                    end
                end
            end
            if fired then break end
        end
        if fired then break end
    end

    if not fired then
        local remotesFolder = ReplicatedStorage:FindFirstChild("Remotes") or ReplicatedStorage:FindFirstChild("Events") or ReplicatedStorage:FindFirstChild("Network")
        if remotesFolder then
            for _, name in ipairs(remoteNames) do
                local remote = remotesFolder:FindFirstChild(name, true)
                if remote then
                    for _, arg in ipairs(args) do
                        if remote:IsA("RemoteEvent") or remote:IsA("UnreliableRemoteEvent") then
                            pcall(function()
                                if arg == nil then
                                    remote:FireServer()
                                else
                                    remote:FireServer(arg)
                                end
                            end)
                        elseif remote:IsA("RemoteFunction") then
                            pcall(function()
                                if arg == nil then
                                    remote:InvokeServer()
                                else
                                    remote:InvokeServer(arg)
                                end
                            end)
                        end
                        if remote and (remote:IsA("RemoteEvent") or remote:IsA("RemoteFunction") or remote:IsA("UnreliableRemoteEvent")) then
                            fired = true
                            break
                        end
                    end
                end
                if fired then break end
            end
        end
    end

    local player = getPlayer()
    local tool = player and player.Character and player.Character:FindFirstChildOfClass("Tool")
    if not fired and tool and tool.Parent == player.Character then
        pcall(function()
            tool:Activate()
            task.wait(0.02)
            tool:Deactivate()
        end)
        fired = true
    end

    if not fired then
        pcall(function()
            local camera = workspace.CurrentCamera
            if camera then
                VirtualUser:Button1Down(Vector2.new(0,0), camera.CFrame)
                VirtualUser:Button1Up(Vector2.new(0,0), camera.CFrame)
            else
                VirtualUser:Button1Down(Vector2.new(0,0))
                VirtualUser:Button1Up(Vector2.new(0,0))
            end
        end)
    end
end

RunService.PostSimulation:Connect(function()
    if not AutoParryEnabled or parryDebounce then
        return
    end
    local player = getPlayer()
    if not player or not player.Character then
        return
    end
    local ball = GetActiveBall()
    if not ball then
        return
    end
    local root = getCharacterRoot(player)
    if not root then
        return
    end
    local distance = (ball.Position - root.Position).Magnitude
    if distance <= ParryRadius then
        parryDebounce = true
        FireParryRemote(ball)
        task.wait(0.08)
        parryDebounce = false
    end
end)

-- Try RenderStepped (earlier in frame cycle) - Racket Rivals likely has server anti-cheat
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

game:GetService("RunService").RenderStepped:Connect(function()
    pcall(function()
        applyWalkSpeed()
    end)
end)

-- Apply walk speed immediately on script load
applyWalkSpeed()

local function getCharacterRoot(player)
    local char = player and player.Character
    if not char then
        return nil
    end
    return char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("UpperTorso") or char:FindFirstChild("Head")
end

local function getCharacterHead(player)
    local char = player and player.Character
    return char and char:FindFirstChild("Head")
end

local function createESP(player)
    if espObjects[player] then
        return
    end

    local box = Drawing.new("Square")
    box.Color = Color3.new(1, 1, 1)
    box.Thickness = 2
    box.Filled = false
    box.Transparency = 1
    box.Visible = false

    local nameText = Drawing.new("Text")
    nameText.Color = Color3.new(1, 1, 1)
    nameText.Size = 16
    nameText.Center = true
    nameText.Outline = true
    nameText.OutlineColor = Color3.new(0, 0, 0)
    nameText.Text = player.Name
    nameText.Visible = false

    local distText = Drawing.new("Text")
    distText.Color = Color3.new(1, 1, 1)
    distText.Size = 14
    distText.Center = true
    distText.Outline = true
    distText.OutlineColor = Color3.new(0, 0, 0)
    distText.Text = ""
    distText.Visible = false

    local boneLines = {}
    for i = 1, 8 do
        local line = Drawing.new("Line")
        line.Color = Color3.new(1, 1, 1)
        line.Thickness = 2
        line.Transparency = 1
        line.Visible = false
        boneLines[i] = line
    end

    espObjects[player] = {
        box = box,
        nameText = nameText,
        distText = distText,
        bones = boneLines,
    }
end

local function removeESP(player)
    local info = espObjects[player]
    if not info then
        return
    end
    if info.box then
        info.box:Remove()
    end
    if info.nameText then
        info.nameText:Remove()
    end
    if info.distText then
        info.distText:Remove()
    end
    if info.bones then
        for _, line in pairs(info.bones) do
            if line then
                line:Remove()
            end
        end
    end
    espObjects[player] = nil
end

local function updateESP(player)
    local info = espObjects[player]
    if not info then
        createESP(player)
        info = espObjects[player]
    end

    local rootPart = getCharacterRoot(player)
    local head = getCharacterHead(player)
    local localRoot = getCharacterRoot(getPlayer())
    if not rootPart or not head or not localRoot then
        info.box.Visible = false
        info.nameText.Visible = false
        info.distText.Visible = false
        if info.bones then
            for _, line in pairs(info.bones) do
                line.Visible = false
            end
        end
        return
    end

    local camera = workspace.CurrentCamera
    local headPos, headOnScreen = camera:WorldToViewportPoint(head.Position + Vector3.new(0, 0.2, 0))
    local footPos, footOnScreen = camera:WorldToViewportPoint(rootPart.Position - Vector3.new(0, 2, 0))
    if not headOnScreen and not footOnScreen then
        info.box.Visible = false
        info.nameText.Visible = false
        info.distText.Visible = false
        if info.bones then
            for _, line in pairs(info.bones) do
                line.Visible = false
            end
        end
        return
    end

    local upperTorso = player.Character:FindFirstChild("UpperTorso") or player.Character:FindFirstChild("Torso")
    local lowerTorso = player.Character:FindFirstChild("LowerTorso") or player.Character:FindFirstChild("Torso")
    local leftArm = player.Character:FindFirstChild("LeftUpperArm") or player.Character:FindFirstChild("LeftArm")
    local rightArm = player.Character:FindFirstChild("RightUpperArm") or player.Character:FindFirstChild("RightArm")
    local leftLeg = player.Character:FindFirstChild("LeftUpperLeg") or player.Character:FindFirstChild("LeftLeg")
    local rightLeg = player.Character:FindFirstChild("RightUpperLeg") or player.Character:FindFirstChild("RightLeg")
    local leftHand = player.Character:FindFirstChild("LeftHand") or player.Character:FindFirstChild("LeftLowerArm")
    local rightHand = player.Character:FindFirstChild("RightHand") or player.Character:FindFirstChild("RightLowerArm")
    local leftFoot = player.Character:FindFirstChild("LeftFoot") or player.Character:FindFirstChild("LeftLowerLeg")
    local rightFoot = player.Character:FindFirstChild("RightFoot") or player.Character:FindFirstChild("RightLowerLeg")

    local function screenPoint(part, offset)
        if not part then
            return nil, false
        end
        return camera:WorldToViewportPoint(part.Position + (offset or Vector3.new()))
    end

    local upperTorsoPos, upperOnScreen = screenPoint(upperTorso)
    local lowerTorsoPos, lowerOnScreen = screenPoint(lowerTorso)
    local leftArmPos, leftArmOnScreen = screenPoint(leftArm)
    local rightArmPos, rightArmOnScreen = screenPoint(rightArm)
    local leftHandPos, leftHandOnScreen = screenPoint(leftHand)
    local rightHandPos, rightHandOnScreen = screenPoint(rightHand)
    local leftLegPos, leftLegOnScreen = screenPoint(leftLeg)
    local rightLegPos, rightLegOnScreen = screenPoint(rightLeg)
    local leftFootPos, leftFootOnScreen = screenPoint(leftFoot)
    local rightFootPos, rightFootOnScreen = screenPoint(rightFoot)

    local height = math.max(60, math.abs(headPos.Y - footPos.Y))
    local width = math.max(40, height * 0.35)
    local left = headPos.X - width / 2
    local top = headPos.Y - 10

    local distance = math.floor((localRoot.Position - rootPart.Position).Magnitude)
    local distanceText = string.format("%d studs", distance)

    if EspMaxDistance and distance > EspMaxDistance then
        info.box.Visible = false
        info.nameText.Visible = false
        info.distText.Visible = false
        if info.bones then
            for _, line in pairs(info.bones) do
                line.Visible = false
            end
        end
        return
    end

    info.box.Position = Vector2.new(left, top)
    info.box.Size = Vector2.new(width, height)
    info.box.Visible = EspEnabled

    info.nameText.Position = Vector2.new(headPos.X, top - 18)
    info.nameText.Text = player.Name
    info.nameText.Visible = EspEnabled

    info.distText.Position = Vector2.new(headPos.X, top + height + 5)
    info.distText.Text = distanceText
    info.distText.Visible = EspEnabled

    local bones = info.bones
    if bones and #bones >= 8 then
        local bonePairs = {
            {headPos, upperTorsoPos},
            {upperTorsoPos, lowerTorsoPos},
            {upperTorsoPos, leftArmPos},
            {leftArmPos, leftHandPos},
            {upperTorsoPos, rightArmPos},
            {rightArmPos, rightHandPos},
            {lowerTorsoPos, leftFootPos or leftLegPos},
            {lowerTorsoPos, rightFootPos or rightLegPos},
        }

        for i, pair in ipairs(bonePairs) do
            local a, b = pair[1], pair[2]
            local line = bones[i]
            -- make legs slightly longer by extending the lowerTorso->foot vectors
            if i >= 7 and a and b then
                local extendFactor = 1.2
                b = Vector3.new(a.X + (b.X - a.X) * extendFactor, a.Y + (b.Y - a.Y) * extendFactor, a.Z + (b.Z - a.Z) * extendFactor)
            end
            if SkeletonEnabled and a and b and a.Z > 0 and b.Z > 0 then
                line.From = Vector2.new(a.X, a.Y)
                line.To = Vector2.new(b.X, b.Y)
                line.Visible = true
            else
                line.Visible = false
            end
        end
    end
end

local function refreshESP()
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= getPlayer() then
            createESP(player)
        end
    end
end

if EspEnabled or SkeletonEnabled then
    refreshESP()
end

Players.PlayerAdded:Connect(function(player)
    if player ~= getPlayer() then
        if EspEnabled or SkeletonEnabled then
            createESP(player)
        end

        player.CharacterAdded:Connect(function()
            if EspEnabled or SkeletonEnabled then
                createESP(player)
            end
        end)
    end
end)

Players.PlayerRemoving:Connect(removeESP)

RunService.Heartbeat:Connect(function()
    if not EspEnabled and not SkeletonEnabled then
        return
    end

    local localPlayer = getPlayer()
    if not localPlayer then
        return
    end

    for player, _ in pairs(espObjects) do
        if player ~= localPlayer and player.Character then
            updateESP(player)
        else
            removeESP(player)
        end
    end
end)

local DashEnabled = false
local DashStrength = 120
local DashUpwardBoost = 20

local function performDash()
    local char = getCharacter()
    if not char then return end

    local root = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not root or not hum or hum.Health <= 0 then
        return
    end

    root.AssemblyLinearVelocity = root.CFrame.LookVector * DashStrength + Vector3.new(0, DashUpwardBoost, 0)
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.Q and DashEnabled then
        performDash()
    end
end)

getPlayer().CharacterAdded:Connect(function()
    startNoclip()
    if NoclipEnabled then
        enableNoclip()
    end
    applyWalkSpeed()
end)

UserInputService.JumpRequest:Connect(function()
    if InfiniteJumpEnabled then
        local player = getPlayer()
        if player and player.Character then
            local hum = player.Character:FindFirstChildOfClass("Humanoid")
            if hum then
                hum:ChangeState(Enum.HumanoidStateType.Jumping)
            end
        end
    end
end)

local Window = splib:MakeWindow({
 Name = "Racket Rivals | Sp libary v2",
 SubTitle = "by splib",
 Setting = true,
 Intro = true,
 IntroText = "SP Hub Loading",
 IntroIcon = "rbxassetid://83114982417764",
 IntroSpeed = 1,
 Toggle = true,
 IsPremium = false,
 Icon = "rbxassetid://83114982417764",
 RainbowMainFrame = false,
 RainbowTitle = false,
 RainbowSubTitle = false,
 ToggleIcon = "rbxassetid://83114982417764",
 CloseCallback = true
})

local Tab = Window:MakeTab({
  IsMobile = false,
  IsPC = false,
  Name = "Main",
  Icon = "rbxassetid://4483345998"
})

Tab:AddSection("Main")

local toggleInfiniteJump = Tab:AddToggle({
   IsMobile = false,
   IsPC = false,
   PremiumOnly = false,
   HidePremium = false,
   Name = "Infinite Jump",
   Desc = "toggle infinite jumping",
   Default = false,
   Flag = "InfiniteJump",
    Callback = function(Value)
        InfiniteJumpEnabled = Value
    end    
})
pcall(function()
    if toggleInfiniteJump and toggleInfiniteJump.Set then toggleInfiniteJump:Set(false) end
    if toggleInfiniteJump and toggleInfiniteJump.SetValue then toggleInfiniteJump:SetValue(false) end
end)

local toggleNoClip = Tab:AddToggle({
   IsMobile = false,
   IsPC = false,
   PremiumOnly = false,
   HidePremium = false,
   Name = "NoClip",
   Desc = "you can go through walls",
   Default = false,
   Flag = "NoClip",
    Callback = function(Value)
        NoclipEnabled = Value
        if Value then
            enableNoclip()
        else
            disableNoclip()
        end
    end    
})
pcall(function()
    if toggleNoClip and toggleNoClip.Set then toggleNoClip:Set(false) end
    if toggleNoClip and toggleNoClip.SetValue then toggleNoClip:SetValue(false) end
end)

local toggleAutoParry = Tab:AddToggle({
   IsMobile = false,
   IsPC = false,
   PremiumOnly = false,
   HidePremium = false,
   Name = "Auto Parry",
   Desc = "Currently getting worked on",
   Default = false,
   Flag = "AutoParry",
    Callback = function(Value)
        AutoParryEnabled = Value
    end    
})
pcall(function()
    if toggleAutoParry and toggleAutoParry.Set then toggleAutoParry:Set(false) end
    if toggleAutoParry and toggleAutoParry.SetValue then toggleAutoParry:SetValue(false) end
end)

local Tab = Window:MakeTab({
  IsMobile = false,
  IsPC = false,
  Name = "Premium",
  Icon = "rbxassetid://4483345998"
})

Tab:AddSection("Premium")

local toggleDash = Tab:AddToggle({
   IsMobile = false,
   IsPC = false,
   PremiumOnly = true,
   HidePremium = false,
   Name = "Dash",
   Desc = "No cooldown on dash",
   Default = false,
   Flag = "Dash",
    Callback = function(Value)
        DashEnabled = Value
    end    
})
pcall(function()
    if toggleDash and toggleDash.Set then toggleDash:Set(false) end
    if toggleDash and toggleDash.SetValue then toggleDash:SetValue(false) end
end)

local Tab = Window:MakeTab({
  IsMobile = false,
  IsPC = false,
  Name = "Visuals",
  Icon = "rbxassetid://4483345998"
})

Tab:AddSection("Visuals")

local toggleESP = Tab:AddToggle({
   IsMobile = false,
   IsPC = false,
   PremiumOnly = false,
   HidePremium = false,
   Name = "ESP",
   Desc = "shows all players with boxes and distance",
   Default = false,
   Flag = "ESP",
    Callback = function(Value)
        EspEnabled = Value
        if Value then
            refreshESP()
        else
            for player, _ in pairs(espObjects) do
                removeESP(player)
            end
        end
    end    
})
pcall(function()
    if toggleESP and toggleESP.Set then toggleESP:Set(false) end
    if toggleESP and toggleESP.SetValue then toggleESP:SetValue(false) end
end)

local toggleSkeletonESP = Tab:AddToggle({
   IsMobile = false,
   IsPC = false,
   PremiumOnly = false,
   HidePremium = false,
   Name = "Skeleton ESP",
   Desc = "shows the skeleton of the player",
   Default = false,
   Flag = "SkeletonESP",
    Callback = function(Value)
        SkeletonEnabled = Value
        if Value then
            refreshESP()
        else
            if not EspEnabled then
                for player, _ in pairs(espObjects) do
                    removeESP(player)
                end
            end
        end
    end    
})
pcall(function()
    if toggleSkeletonESP and toggleSkeletonESP.Set then toggleSkeletonESP:Set(false) end
    if toggleSkeletonESP and toggleSkeletonESP.SetValue then toggleSkeletonESP:SetValue(false) end
end)

-- Ensure ESP features start disabled even if GUI saved state is true
EspEnabled = false
SkeletonEnabled = false
for player, _ in pairs(espObjects) do
    removeESP(player)
end

-- Best-effort: force GUI flags off in case the library restores saved toggles
local knownFlags = {"InfiniteJump", "NoClip", "AutoParry", "Dash", "ESP", "SkeletonESP", "WalkSpeedSlider", "ESPMaxDistance", "WalkSpeedEnabled", "Toggle1"}
for _, flag in ipairs(knownFlags) do
    pcall(function()
        if Window.SetFlag then Window:SetFlag(flag, false) end
    end)
    pcall(function()
        if splib.SetFlag then splib:SetFlag(flag, false) end
    end)
    pcall(function()
        if Window.SetValue then Window:SetValue(flag, false) end
    end)
    pcall(function()
        if Window.UpdateFlag then Window:UpdateFlag(flag, false) end
    end)
end

local sliderESPMaxDistance = Tab:AddSlider({
   IsMobile = false,
   IsPC = false,
   PremiumOnly = false,
   HidePremium = false,
    Name = "ESP Max Distance",
    Min = 50,
    Max = 5000,
    Increment = 1,
    Default = EspMaxDistance,
    ValueName = "Studs",
    Flag = "ESPMaxDistance",
    Callback = function(Value)
         EspMaxDistance = Value
    end
})
pcall(function()
    if sliderESPMaxDistance and sliderESPMaxDistance.Set then sliderESPMaxDistance:Set(EspMaxDistance) end
    if sliderESPMaxDistance and sliderESPMaxDistance.SetValue then sliderESPMaxDistance:SetValue(EspMaxDistance) end
end)

local Tab = Window:MakeTab({
  IsMobile = false,
  IsPC = false,
  Name = "Player",
  Icon = "rbxassetid://4483345998"
})

Tab:AddSection("Player")

local toggleWalkSpeedEnable = Tab:AddToggle({
   IsMobile = false,
   IsPC = false,
   PremiumOnly = false,
   HidePremium = false,
   Name = "walkspeed toggle",
   Desc = "makes you move fast boiiii",
   Default = false,
   Flag = "Toggle1",
   Callback = function(Value)
       WalkSpeedEnabled = Value
       applyWalkSpeed()
   end
})
pcall(function()
    if toggleWalkSpeedEnable and toggleWalkSpeedEnable.Set then toggleWalkSpeedEnable:Set(false) end
    if toggleWalkSpeedEnable and toggleWalkSpeedEnable.SetValue then toggleWalkSpeedEnable:SetValue(false) end
end)

local sliderWalkSpeed = Tab:AddSlider({
   IsMobile = false,
   IsPC = false,
   PremiumOnly = false,
   HidePremium = false,
   Name = "Walk Speed",
   Desc = "adjust your walk speed",
   Min = 0,
   Max = 500,
   Increment = 1,
   Default = WalkSpeed,
   ValueName = "Speed",
   Flag = "WalkSpeedSlider",
    Callback = function(Value)
        WalkSpeed = Value
        applyWalkSpeed()
    end    
})
pcall(function()
    if sliderWalkSpeed and sliderWalkSpeed.Set then sliderWalkSpeed:Set(WalkSpeed) end
    if sliderWalkSpeed and sliderWalkSpeed.SetValue then sliderWalkSpeed:SetValue(WalkSpeed) end
end)

local Tab = Window:MakeTab({
  IsMobile = false,
  IsPC = false,
  Name = "Credits",
  Icon = "rbxassetid://4483345998"
})

Tab:AddSection("Credits")

Tab:AddParagraph("SuperCosmos","Coder Of This Script")

Tab:AddParagraph("CR33P","Helped Code And Tester Of This Script")

-- Universal aimbot made by ishowgoat on discord
-- enjoy
local UserInputService = game:GetService("UserInputService") 
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local Camera = Workspace.CurrentCamera
local RunService = game:GetService("RunService")

-- Settings for Chams and Aimbot
local settings_tbl = {
    ESP_Enabled = true,
    ESP_TeamCheck = false,
    Chams = true,
    Chams_Color = Color3.fromRGB(255, 0, 0),
    Chams_Glow_Color = Color3.fromRGB(0, 255, 0),  -- Chams glow color
    Chams_Transparency = 0.3,  -- Transparency of Chams
    CircleRadius = 80,  -- Radius for FOV circle
    CircleColor = Color3.fromRGB(255, 0, 0),  -- FOV circle color
    CircleTransparency = 0.7,  -- FOV circle transparency
    CircleFilled = false,  -- FOV circle fill
    CircleThickness = 0,  -- FOV circle thickness
}

-- Create the FOV circle
local FOVCircle = Drawing.new("Circle")
FOVCircle.Radius = settings_tbl.CircleRadius
FOVCircle.Filled = settings_tbl.CircleFilled
FOVCircle.Color = settings_tbl.CircleColor
FOVCircle.Visible = true
FOVCircle.Transparency = settings_tbl.CircleTransparency
FOVCircle.NumSides = 64
FOVCircle.Thickness = settings_tbl.CircleThickness

local localPlayer = Players.LocalPlayer
local aiming = false
local targetHead = nil

local playerChams = {}

-- Function to destroy Chams from a character
function destroy_chams(char)
    for _, v in next, char:GetChildren() do
        if v:IsA("BasePart") and v.Transparency ~= 1 then
            if v:FindFirstChild("Glow") and v:FindFirstChild("Chams") then
                v.Glow:Destroy()
                v.Chams:Destroy()
            end
        end
    end
end

-- Function to create the ESP GUI button
local function createESPButton()
    -- Create ESP GUI Button to toggle Chams
    local screenGui = Instance.new("ScreenGui")
    screenGui.Parent = localPlayer.PlayerGui
    screenGui.Name = "ESP_GUI"

    local espButton = Instance.new("TextButton")
    espButton.Parent = screenGui
    espButton.Size = UDim2.new(0, 150, 0, 50)
    espButton.Position = UDim2.new(1, -160, 1, -60)
    espButton.Text = settings_tbl.Chams and "Chams ON" or "Chams OFF"
    espButton.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    espButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    espButton.Font = Enum.Font.SourceSans
    espButton.TextSize = 20

    -- Toggle Chams functionality
    espButton.MouseButton1Click:Connect(function()
        settings_tbl.Chams = not settings_tbl.Chams
        if settings_tbl.Chams then
            espButton.Text = "Chams ON"
        else
            espButton.Text = "Chams OFF"
        end
    end)
end

-- Create the GUI when the player joins
createESPButton()

-- Handle player respawn by listening to CharacterAdded event
local function onCharacterAdded(character)
    -- Recreate the GUI when the player respawns
    if localPlayer.PlayerGui:FindFirstChild("ESP_GUI") then
        localPlayer.PlayerGui.ESP_GUI:Destroy()
    end
    createESPButton()
end

-- Listen for player respawn events
localPlayer.CharacterAdded:Connect(onCharacterAdded)

-- Function to get the closest enemy head inside the FOV circle
local function getClosestEnemyHead()
    local closestDistance = math.huge
    local target = nil

    for _, otherPlayer in ipairs(Players:GetPlayers()) do
        -- Skip the local player and teammates if team check is enabled
        if otherPlayer ~= localPlayer and (not settings_tbl.ESP_TeamCheck or otherPlayer.Team ~= localPlayer.Team) then
            local character = otherPlayer.Character
            if character and character:FindFirstChild("Head") and character:FindFirstChild("Humanoid") then
                local humanoid = character.Humanoid
                if humanoid.Health > 0 then -- Check if the player is alive
                    local head = character.Head
                    local screenPos, onScreen = Camera:WorldToScreenPoint(head.Position)
                    if onScreen then
                        -- Calculate the distance from the center of the screen
                        local mousePos = UserInputService:GetMouseLocation()
                        local distance = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
                        
                        -- Only consider targets inside the FOV circle
                        if distance <= settings_tbl.CircleRadius and distance < closestDistance then
                            closestDistance = distance
                            target = head
                        end
                    end
                end
            end
        end
    end

    return target
end

-- Function to aim at the target's head
local function aimAtTarget()
    if not aiming or not targetHead then
        return
    end

    local character = localPlayer.Character
    if character and character:FindFirstChild("HumanoidRootPart") and targetHead then
        local humanoidRootPart = character.HumanoidRootPart
        humanoidRootPart.CFrame = CFrame.new(humanoidRootPart.Position, targetHead.Position)

        -- Adjust the camera to look at the target's head
        Camera.CFrame = CFrame.new(Camera.CFrame.Position, targetHead.Position)
    end
end

-- Function to apply Chams to player's character parts
local function applyChamsToPlayer(player)
    local character = player.Character
    if character then
        for _, part in pairs(character:GetChildren()) do
            if part:IsA("BasePart") then
                -- Apply Chams effect by creating new adornments
                if not playerChams[player] then
                    playerChams[player] = {}
                end

                if not playerChams[player][part] then
                    local chams_box = Instance.new("BoxHandleAdornment", part)
                    chams_box.Name = "Chams"
                    chams_box.AlwaysOnTop = true
                    chams_box.ZIndex = 4
                    chams_box.Adornee = part
                    chams_box.Color3 = settings_tbl.Chams_Color
                    chams_box.Transparency = settings_tbl.Chams_Transparency
                    chams_box.Size = part.Size + Vector3.new(0.02, 0.02, 0.02)

                    local glow_box = Instance.new("BoxHandleAdornment", part)
                    glow_box.Name = "Glow"
                    glow_box.AlwaysOnTop = false
                    glow_box.ZIndex = 3
                    glow_box.Adornee = part
                    glow_box.Color3 = settings_tbl.Chams_Glow_Color
                    glow_box.Size = chams_box.Size + Vector3.new(0.13, 0.13, 0.13)

                    -- Store adornments to update them later
                    playerChams[player][part] = {Chams = chams_box, Glow = glow_box}
                end
            end
        end
    end
end

-- Function to remove Chams from a player's character parts
local function removeChamsFromPlayer(player)
    local character = player.Character
    if character then
        for _, part in pairs(character:GetChildren()) do
            if part:IsA("BasePart") and playerChams[player] and playerChams[player][part] then
                -- Destroy the Chams and Glow effects
                local chams = playerChams[player][part]
                chams.Chams:Destroy()
                chams.Glow:Destroy()

                -- Remove from the stored data
                playerChams[player][part] = nil
            end
        end
    end
end

-- Handle input events for aimbot
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then
        return
    end

    if input.UserInputType == Enum.UserInputType.MouseButton2 then -- Right-click
        aiming = true
        -- Only select target within FOV circle
        targetHead = getClosestEnemyHead()
    end
end)

UserInputService.InputEnded:Connect(function(input, gameProcessed)
    if input.UserInputType == Enum.UserInputType.MouseButton2 then -- Right-click released
        aiming = false
        targetHead = nil
    end
end)

-- Update Chams and Aimbot
RunService.RenderStepped:Connect(function()
    -- Continuously update the position of the FOV circle to follow the mouse cursor
    local mousePos = UserInputService:GetMouseLocation()
    FOVCircle.Position = mousePos

    -- Update the target if it goes out of the FOV circle
    if aiming then
        targetHead = getClosestEnemyHead()
        aimAtTarget()
    end

    -- Apply Chams for each player
    if settings_tbl.Chams then
        for _, otherPlayer in ipairs(Players:GetPlayers()) do
            if otherPlayer ~= localPlayer and (not settings_tbl.ESP_TeamCheck or otherPlayer.Team ~= localPlayer.Team) then
                applyChamsToPlayer(otherPlayer)
            end
        end
    else
        -- Remove Chams when the toggle is off
        for _, otherPlayer in ipairs(Players:GetPlayers()) do
            if otherPlayer ~= localPlayer then
                removeChamsFromPlayer(otherPlayer)
            end
        end
    end
end)

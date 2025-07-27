
-- example script by https://github.com/mstudio45/LinoriaLib/blob/main/Example.lua and modified by deivid

local repo = "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/"
local Library = loadstring(game:HttpGet(repo .. "Library.lua"))()
local ThemeManager = loadstring(game:HttpGet(repo .. "addons/ThemeManager.lua"))()
local SaveManager = loadstring(game:HttpGet(repo .. "addons/SaveManager.lua"))()

local Options = Library.Options
local Toggles = Library.Toggles

Library.ForceCheckbox = false
Library.ShowToggleFrameInKeybinds = true

local Window = Library:CreateWindow({
	Title = "AcidHub",
	Footer = "Michael's Zombies",
	NotifySide = "Right",
	ShowCustomCursor = true,
})

local Tabs = {
	Main = Window:AddTab("Main", "user"),
	["UI Settings"] = Window:AddTab("UI Settings", "settings"),
}

local AutoFarmGroupBox = Tabs.Main:AddLeftGroupbox("Auto Farm")

-- Boolean to track the toggle state
local teleporting = false

local function TeleportAboveHighestAndClosestZombieRepeatedly()
    while teleporting do
        local zombiesFound = false  -- Flag to check if any zombies are found
        local closestZombie = nil
        local closestDistance = math.huge  -- Set a very high initial distance value
        local highestZombie = nil
        local highestZ = -math.huge  -- Set an initial low Z value to ensure we find the highest one

        -- Loop through all the models in workspace.Ignore.Zombies
        for _, zombie in pairs(workspace.Ignore.Zombies:GetChildren()) do
            -- Ensure the model is a valid zombie (model has HumanoidRootPart)
            if zombie:IsA("Model") and zombie:FindFirstChild("HumanoidRootPart") then
                -- Calculate distance from the player to the zombie
                local player = game.Players.LocalPlayer
                if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                    local distance = (zombie.HumanoidRootPart.Position - player.Character.HumanoidRootPart.Position).Magnitude
                    local zombieHeight = zombie.HumanoidRootPart.Position.Y
                    
                    -- Find the closest zombie
                    if distance < closestDistance then
                        closestZombie = zombie
                        closestDistance = distance
                    end
                    
                    -- Find the highest zombie from the closest ones
                    if zombieHeight > highestZ then
                        highestZombie = zombie
                        highestZ = zombieHeight
                    end
                end
            end
        end

        -- If a valid highest and closest zombie is found, teleport to it
        if highestZombie then
            local player = game.Players.LocalPlayer
            if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                -- Teleport the player to 5 studs above the highest and closest zombie
                player.Character.HumanoidRootPart.CFrame = CFrame.new(highestZombie.HumanoidRootPart.Position + Vector3.new(0, 5, 0))
                zombiesFound = true
            end
        end

        -- If no zombies were found, teleport to MysteryBox
        if not zombiesFound then
            local mysteryBox = workspace._MapComponents:FindFirstChild("MysteryBox")
            if mysteryBox and mysteryBox:FindFirstChild("HumanoidRootPart") then
                local player = game.Players.LocalPlayer
                if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                    -- Teleport directly above the MysteryBox without tweening
                    player.Character.HumanoidRootPart.CFrame = CFrame.new(mysteryBox.HumanoidRootPart.Position + Vector3.new(0, 5, 0))
                end
            end
        end

        task.wait() 
    end
end

-- Add the teleport toggle
AutoFarmGroupBox:AddToggle("TeleportAboveHighestAndClosestZombieRepeatedly", {
    Text = "Teleport Above Zombies",
    Tooltip = "No Zombies = Mystery Box",
    Default = false,
    Callback = function(Value)
        if Value then
            -- Start teleporting repeatedly when the toggle is enabled
            teleporting = true
            spawn(TeleportAboveHighestAndClosestZombieRepeatedly)  -- Run the function in a separate thread to avoid freezing
        else
            -- Stop the teleportation when the toggle is disabled
            teleporting = false

            -- Teleport to the MysteryBox once when the toggle is disabled
            local mysteryBox = workspace._MapComponents:FindFirstChild("MysteryBox")
            if mysteryBox and mysteryBox:FindFirstChild("HumanoidRootPart") then
                local player = game.Players.LocalPlayer
                if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                    player.Character.HumanoidRootPart.CFrame = CFrame.new(mysteryBox.HumanoidRootPart.Position + Vector3.new(0, 5, 0))
                end
            end
        end
    end
})






local isFiring = false  -- To track whether the KnifeHitbox events are being fired
-- Function to fire the event for all zombies in the workspace
local function FireZombieKillAura()
    -- Fire events in parallel for each zombie to make it faster
    while isFiring do
        local Event = game:GetService("ReplicatedStorage").Framework.Remotes.KnifeHitbox

        -- Get all zombies at once
        local zombies = workspace.Ignore.Zombies:GetChildren()

        -- Iterate over zombies
        for _, zombie in ipairs(zombies) do
            -- Only fire if the object is a valid zombie
            if zombie and zombie:IsA("Model") and zombie:FindFirstChild("Humanoid") then
                task.spawn(function()
                    -- Fire the event for this zombie in a separate thread
                    Event:FireServer(zombie)
                end)
            end
        end
        task.wait(0.1)
    end
end


AutoFarmGroupBox:AddToggle("ZombieKillAura", {
	Text = "Zombie Kill Aura",
	Tooltip = "Kills Nearby Zombies",
	Default = false,
	Callback = function(Value)
		if Value then
			isFiring = true
			FireZombieKillAura()
		else
			isFiring = false
		end
	end
})



-- Initialize variables
-- Initialize variables
local delayTime = 0.2  -- Set the delay time between repairs (in seconds)
local isFiring = false  -- To control whether the repairs should keep firing

-- Function to auto-repair all barriers with the given object and delay
local function AutoRepairBarriers(delay)
    while isFiring do
        -- Loop through all barriers in _Barriers
        for _, barrier in pairs(workspace._Barriers:GetChildren()) do
            if barrier and barrier:FindFirstChild("FixBarrier") then
                local Event = game:GetService("Players").LocalPlayer.Character.Remotes.Interact
                -- Fire the event to repair the barrier
                Event:FireServer({ barrier.FixBarrier })
            end
        end
        
        -- Wait for the specified delay time before firing again
        task.wait(delay)
    end
end

-- Add a toggle for Auto Repair Barriers to the UI
AutoFarmGroupBox:AddToggle("AutoRepairBarriers", {
    Text = "Auto Repair Barriers",  -- Label for the toggle
    Tooltip = "Repairs All Barriers",  -- Tooltip when hovering over the toggle
    Default = false,  -- Default value for the toggle (off)
    Callback = function(Value)
        if Value then
            -- Start auto-repairing barriers when the toggle is enabled
            isFiring = true
            AutoRepairBarriers(delayTime)  -- Start the repair function with specified delay
        else
            -- Stop auto-repairing barriers when the toggle is disabled
            isFiring = false
        end
    end
})

local WeaponGroupBox = Tabs.Main:AddLeftGroupbox("Weapon")

-- Flag to control AutoReload toggle state
local autoReloading = false

-- Function to fire the reload remote
local function AutoReload()
    -- Get the event
    local Event = game:GetService("Players").LocalPlayer.Character.Remotes.Reload

    -- Fire the reload remote
    Event:FireServer()
end

-- Add a toggle to enable/disable AutoReload
WeaponGroupBox:AddToggle("AutoReload", {
    Text = "Auto Reload",  -- Label for the toggle
    Tooltip = "Automatically reloads when enabled",  -- Tooltip when hovering over the toggle
    Default = false,  -- Default value for the toggle (off)
    Callback = function(Value)
        autoReloading = Value  -- Set the flag based on toggle state

        -- Start or stop AutoReload based on the toggle value
        if autoReloading then
            -- Run AutoReload continuously while the toggle is enabled
            while autoReloading do
                AutoReload()
                task.wait()  -- Wait 1 second between reloads (adjust the delay as needed)
            end
        end
    end
})








local PlayerGroupBox = Tabs.Main:AddRightGroupbox("Player")

-- Flag to control the auto-touch fire toggle state
local autoTouchFiring = false

-- Function to continuously fire touch interest on all parts in _Powerups
local function GrabAllPowerups()
    while autoTouchFiring do
        -- Loop through all objects in workspace.Ignore._Powerups
        for _, v in pairs(workspace.Ignore._Powerups:GetChildren()) do
            -- Fire the touch interest for each part
            firetouchinterest(game.Players.LocalPlayer.Character.HumanoidRootPart, v, 0)
        end
        task.wait(0.1)  -- Adjust the delay if needed (this controls how often it fires)
    end
end

-- Add a toggle to enable/disable GrabAllPowerups
PlayerGroupBox:AddToggle("GrabAllPowerups", {
    Text = "Grab All Powerups",  -- Label for the toggle
    Tooltip = "Grabs All Dropped Powerups",  -- Tooltip when hovering over the toggle
    Default = false,  -- Default value for the toggle (off)
    Callback = function(Value)
        autoTouchFiring = Value  -- Set the flag based on toggle state

        if autoTouchFiring then
            -- Start the auto-fire loop when the toggle is enabled
            spawn(GrabAllPowerups)
        end
    end
})




-- 🧭 UI Settings & Buttons

local ToggleIcon = Instance.new("ImageButton")
ToggleIcon.Name = "ToggleIcon"
ToggleIcon.Size = UDim2.fromOffset(100, 100)
ToggleIcon.Position = UDim2.fromOffset(10, 10)
ToggleIcon.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
ToggleIcon.Image = "rbxassetid://75346641319200"
ToggleIcon.ImageColor3 = Color3.fromRGB(255, 255, 255)
ToggleIcon.Parent = Library.ScreenGui
ToggleIcon.ZIndex = 100

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(1, 0)
UICorner.Parent = ToggleIcon

local dragging, dragStart, startPos
ToggleIcon.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		dragging = true
		dragStart = input.Position
		startPos = ToggleIcon.Position
		input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then
				dragging = false
			end
		end)
	end
end)

ToggleIcon.InputChanged:Connect(function(input)
	if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
		local delta = input.Position - dragStart
		ToggleIcon.Position = UDim2.new(
			startPos.X.Scale,
			startPos.X.Offset + delta.X,
			startPos.Y.Scale,
			startPos.Y.Offset + delta.Y
		)
	end
end)

local MenuGroup = Tabs["UI Settings"]:AddLeftGroupbox("Menu")

MenuGroup:AddToggle("KeybindMenuOpen", {
	Default = Library.KeybindFrame.Visible,
	Text = "Open Keybind Menu",
	Callback = function(value)
		Library.KeybindFrame.Visible = value
	end,
})

MenuGroup:AddToggle("ShowToggleIcon", {
	Default = true,
	Text = "Show AcidHub Icon",
	Callback = function(value)
		ToggleIcon.Visible = value
	end,
})

MenuGroup:AddToggle("ShowCustomCursor", {
	Text = "Custom Cursor",
	Default = true,
	Callback = function(Value)
		Library.ShowCustomCursor = Value
	end,
})

MenuGroup:AddDropdown("NotificationSide", {
	Values = { "Left", "Right" },
	Default = "Right",
	Text = "Notification Side",
	Callback = function(Value)
		Library:SetNotifySide(Value)
	end,
})

MenuGroup:AddDropdown("DPIDropdown", {
	Values = { "50%", "75%", "100%", "125%", "150%", "175%", "200%" },
	Default = "100%",
	Text = "DPI Scale",
	Callback = function(Value)
		Value = Value:gsub("%%", "")
		local DPI = tonumber(Value)
		Library:SetDPIScale(DPI)
	end,
})

MenuGroup:AddDivider()

MenuGroup:AddLabel("Menu bind")
	:AddKeyPicker("MenuKeybind", { Default = "RightShift", NoUI = true, Text = "Menu keybind" })

MenuGroup:AddButton("Unload", function()
	Library:Unload()
end)

Library.ToggleKeybind = Options.MenuKeybind

-- Addons
ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)

SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({ "MenuKeybind" })
ThemeManager:SetFolder("AcidHub")
SaveManager:SetFolder("AcidHub/game")
SaveManager:SetSubFolder("Shh")

SaveManager:BuildConfigSection(Tabs["UI Settings"])
ThemeManager:ApplyToTab(Tabs["UI Settings"])
SaveManager:LoadAutoloadConfig()

ToggleIcon.MouseButton1Click:Connect(function()
	Library:Toggle()
end)

Library:OnUnload(function()
	ToggleIcon:Destroy()
	if Library.ShowCustomCursor then
		game:GetService("UserInputService").MouseIconEnabled = true
	end
	print("[Debug] Library unloaded.")
end)

Library:GiveSignal(Library.ToggleKeybind:OnChanged(function()
	ToggleIcon.Visible = not Library.Toggled
end))

-- Anti AFK
for _, v in ipairs(getconnections(client.Idled)) do
    v:Disable()
end
Library:Notify("Anti-Afk is enabled", 3)


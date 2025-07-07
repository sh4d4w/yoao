-- Project Meow GUI setup
local VLib = loadstring(game:HttpGet("https://gitlab.com/L1ZOT/test-project/-/raw/main/PJM-GUI"))()
local Win = VLib:Window("Cute Test", "Mining Tech Alpha")
local Autofarm = Win:Tab("Autofarm")

-- Services
local Player = game.Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")

-- Chunks folder reference
local ChunksFolder = Workspace:WaitForChild("PEFBEERQ"):WaitForChild("Chunks")

-- Remote reference (1-10 randomizer)
local MineBlockFolder = ReplicatedStorage:WaitForChild("VVHHVZVQ"):WaitForChild("RVRGFFRG"):WaitForChild("MineBlock")
local function getRandomRemote()
    local remotes = MineBlockFolder:GetChildren()
    return remotes[math.random(1, #remotes)]
end

-- Autofarm UI setup for Blox Aura
Autofarm:Toggle("Blox Aura", false, function(t)
    BloxAura = t
end)

Autofarm:Slider("Chunk Refreshing Speed", 0, 10, 10, function(t)
    getgenv().Chunk_Refresh = t
end)

Autofarm:Slider("Aura Range", 1, 20, 15, function(t)
    getgenv().AuraDistance = t
end)

-- Debugger toggle
local DebugEnabled = false
Autofarm:Toggle("Enable Debug Logs", false, function(t)
    DebugEnabled = t
end)

-- Mining flag toggle
local MineFlag = false
Autofarm:Toggle("Use true Flag", false, function(t)
    MineFlag = t
end)

-- Helper: 6-direction vectors only
local Directions = {
    Vector3.new(1, 0, 0), Vector3.new(-1, 0, 0),
    Vector3.new(0, 1, 0), Vector3.new(0, -1, 0),
    Vector3.new(0, 0, 1), Vector3.new(0, 0, -1)
}

-- Teleport tweening
local TweenInfoFast = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local function teleportTo(position)
    local hrp = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local tween = TweenService:Create(hrp, TweenInfoFast, {CFrame = CFrame.new(position)})
    tween:Play()
end

-- Continuous teleporting loop
spawn(function()
    while task.wait(0.1) do
        if BloxAura and Player.Character then
            local hrp = Player.Character:FindFirstChild("HumanoidRootPart")
            if not hrp then continue end

            local closestBlock, closestPos, minDist = nil, nil, math.huge
            for _, folder in pairs(ChunksFolder:GetChildren()) do
                for _, block in pairs(folder:GetChildren()) do
                    if block:IsA("MeshPart") or block:IsA("Model") then
                        local pos = block:IsA("Model") and block:GetPivot().Position or block.Position
                        local dist = (pos - hrp.Position).Magnitude
                        if dist < minDist then
                            closestBlock = block
                            closestPos = pos
                            minDist = dist
                        end
                    end
                end
            end

            if closestBlock and closestPos then
                teleportTo(closestPos + Vector3.new(0, 5, 0))
            end
        end
    end
end)

-- Blox Aura mining loop
spawn(function()
    while task.wait(0.1) do
        if BloxAura then
            pcall(function()
                local hrp = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
                if not hrp then return end

                for _, chunkFolder in pairs(ChunksFolder:GetChildren()) do
                    for _, block in pairs(chunkFolder:GetChildren()) do
                        if block:IsA("MeshPart") or block:IsA("Model") then
                            local blockPos = block:IsA("Model") and block:GetPivot().Position or block.Position
                            local distance = (blockPos - hrp.Position).Magnitude

                            if distance <= (getgenv().AuraDistance or 15) then
                                local scaled = Vector3.new(
                                    math.floor(blockPos.X / 6 + 0.5),
                                    math.floor(blockPos.Y / 6 + 0.5),
                                    math.floor(blockPos.Z / 6 + 0.5)
                                )

                                if DebugEnabled then
                                    print("🧱 Trying block:", block:GetFullName(), "at", scaled, "| Distance:", math.floor(distance * 100) / 100)
                                end

                                for _, dir in ipairs(Directions) do
                                    local success, err = pcall(function()
                                        getRandomRemote():FireServer(scaled, dir, MineFlag)
                                    end)

                                    if DebugEnabled then
                                        print((success and "✅" or "❌") .. " Fired with:", scaled.X, scaled.Y, scaled.Z, dir, MineFlag)
                                    end
                                    task.wait(0.05)
                                end
                            end
                        end
                    end
                end
            end)
        end
    end
end)

Autofarm:line()

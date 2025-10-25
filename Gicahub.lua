-- 🌌 Gica Hub v5 Mobile Auto-Pet-Hopper – KRNL Ready
-- Password/Key: "GicaHub"
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local LP = Players.LocalPlayer or Players.PlayerAdded:Wait()

-- =======================
-- Config
-- =======================
local Svt = {
    SelectedPet = "Los Combinasion",
    FinderActive = false
}

-- =======================
-- Simulierte Server & Pets (API-Simulation)
-- =======================
local servers = {
    {id="server1", pets={"Los Combinasion","GoldenDragon"}},
    {id="server2", pets={"FluffyCat","RainbowDog"}},
    {id="server3", pets={"MysticFox","Los Combinasion"}},
    {id="server4", pets={"MysticRabbit","ShadowWolf"}}
}

local function findPetServer(pet)
    for _,server in pairs(servers) do
        for _,p in pairs(server.pets) do
            if p:lower() == pet:lower() then
                return server.id
            end
        end
    end
    return nil
end

-- =======================
-- Auto-Pet-Finder / Server-Hop
-- =======================
local function startFinder()
    if Svt.FinderActive then return end
    Svt.FinderActive = true
    print("✅ Auto-Finder gestartet für Pet:", Svt.SelectedPet)

    spawn(function()
        while Svt.FinderActive do
            local serverId = findPetServer(Svt.SelectedPet)
            if serverId then
                print("✅ Pet gefunden auf Server:", serverId)
                -- Teleport nur simuliert (KRNL kann hier echt hoppen)
                pcall(function()
                    game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId, serverId, LP)
                end)
                return
            else
                print("🔁 Kein Server gefunden, retry...")
            end
            wait(1)
        end
    end)
end

local function stopFinder()
    Svt.FinderActive = false
    print("🛑 Auto-Finder gestoppt")
end

-- =======================
-- Key GUI
-- =======================
local function createKeyUI()
    local parent = LP:FindFirstChild("PlayerGui") or game:GetService("CoreGui")
    pcall(function() parent:FindFirstChild("GicaKeyUI"):Destroy() end)

    local screen = Instance.new("ScreenGui")
    screen.Name = "GicaKeyUI"
    screen.Parent = parent

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0,250,0,120)
    frame.Position = UDim2.new(0.5,-125,0.5,-60)
    frame.BackgroundColor3 = Color3.fromRGB(28,6,40)
    frame.BackgroundTransparency = 0.3
    frame.Parent = screen
    frame.Active = true
    frame.Draggable = true

    local text = Instance.new("TextLabel")
    text.Size = UDim2.new(1,0,0,30)
    text.Position = UDim2.new(0,0,0,10)
    text.BackgroundTransparency = 1
    text.Text = "Enter Key:"
    text.TextColor3 = Color3.fromRGB(255,255,255)
    text.Font = Enum.Font.GothamBold
    text.TextSize = 18
    text.Parent = frame

    local box = Instance.new("TextBox")
    box.Size = UDim2.new(1,-20,0,30)
    box.Position = UDim2.new(0,10,0,50)
    box.Text = ""
    box.BackgroundColor3 = Color3.fromRGB(50,0,100)
    box.TextColor3 = Color3.fromRGB(255,255,255)
    box.Font = Enum.Font.GothamBold
    box.TextSize = 16
    box.ClearTextOnFocus = false
    box.Parent = frame

    local button = Instance.new("TextButton")
    button.Size = UDim2.new(1,-20,0,30)
    button.Position = UDim2.new(0,10,0,90)
    button.Text = "Submit"
    button.BackgroundColor3 = Color3.fromRGB(100,0,150)
    button.TextColor3 = Color3.fromRGB(255,255,255)
    button.Font = Enum.Font.GothamBold
    button.TextSize = 16
    button.Parent = frame

    button.MouseButton1Click:Connect(function()
        if box.Text == "GicaHub" then
            print("✅ Key korrekt")
            screen:Destroy()
            createMainUI()
        else
            print("❌ Falscher Key! Neustart erforderlich")
            frame.BackgroundColor3 = Color3.fromRGB(0,0,0)
            frame.Size = UDim2.new(1,0,1,0)
            box:Destroy()
            button:Destroy()
            text.Text = "Restart Roblox!"
        end
    end)
end

-- =======================
-- Main GUI
-- =======================
function createMainUI()
    local parent = LP:FindFirstChild("PlayerGui") or game:GetService("CoreGui")
    pcall(function() parent:FindFirstChild("GicaHubUI"):Destroy() end)

    local screen = Instance.new("ScreenGui")
    screen.Name = "GicaHubUI"
    screen.Parent = parent

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0,320,0,250)
    frame.Position = UDim2.new(0.5,-160,0.5,-125)
    frame.BackgroundColor3 = Color3.fromRGB(28,6,40)
    frame.BackgroundTransparency = 0.3
    frame.Parent = screen
    frame.Active = true
    frame.Draggable = true

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1,-20,0,28)
    title.Position = UDim2.new(0,10,0,10)
    title.BackgroundTransparency = 1
    title.Text = "Gica Hub Pet-Hopper"
    title.TextColor3 = Color3.fromRGB(255,255,255)
    title.Font = Enum.Font.GothamBold
    title.TextSize = 18
    title.Parent = frame

    -- Pet Dropdown (nur Los Combinasion)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1,-20,0,28)
    btn.Position = UDim2.new(0,10,0,50)
    btn.Text = "Los Combinasion"
    btn.BackgroundColor3 = Color3.fromRGB(80,0,150)
    btn.TextColor3 = Color3.fromRGB(255,255,255)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 16
    btn.Parent = frame

    btn.MouseButton1Click:Connect(function()
        Svt.SelectedPet = "Los Combinasion"
        print("✅ Pet ausgewählt:", Svt.SelectedPet)
    end)

    -- Start Button
    local startBtn = Instance.new("TextButton")
    startBtn.Size = UDim2.new(1,-20,0,32)
    startBtn.Position = UDim2.new(0,10,0,90)
    startBtn.Text = "Start Finder"
    startBtn.BackgroundColor3 = Color3.fromRGB(0,150,80)
    startBtn.TextColor3 = Color3.fromRGB(255,255,255)
    startBtn.Font = Enum.Font.GothamBold
    startBtn.TextSize = 16
    startBtn.Parent = frame
    startBtn.MouseButton1Click:Connect(startFinder)

    -- Stop Button
    local stopBtn = Instance.new("TextButton")
    stopBtn.Size = UDim2.new(1,-20,0,32)
    stopBtn.Position = UDim2.new(0,10,0,130)
    stopBtn.Text = "Stop Finder"
    stopBtn.BackgroundColor3 = Color3.fromRGB(150,0,0)
    stopBtn.TextColor3 = Color3.fromRGB(255,255,255)
    stopBtn.Font = Enum.Font.GothamBold
    stopBtn.TextSize = 16
    stopBtn.Parent = frame
    stopBtn.MouseButton1Click:Connect(stopFinder)
end

-- =======================
-- Auto Start
-- =======================
createKeyUI()
print("✅ Gica Hub v5 Mobile ready. Script completed.")

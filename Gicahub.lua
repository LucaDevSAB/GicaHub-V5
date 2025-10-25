-- 🌌 Gica Hub v6 – Auto-Pet Finder für "Los Combinasion" (KRNL)
-- Hinweis: Benötigt HttpService & TeleportService (KRNL / Executor mit HTTP erlaubt)

local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

local LP = Players.LocalPlayer or Players.PlayerAdded:Wait()

-- =======================
-- Konfiguration
-- =======================
local Svt = {
    SelectedPet = "Los Combinasion", -- fixiertes Pet
    FinderActive = false,
    ApiUrl = "http://192.168.2.108:3000/checkPet?pet=Los%20Combinasion"
}

-- =======================
-- Hilfsfunktion: Prüft per API, ob Pet verfügbar ist
-- =======================
local function isPetAvailable()
    local success, response = pcall(function()
        return HttpService:GetAsync(Svt.ApiUrl)
    end)
    if not success then
        warn("❌ Fehler beim Abrufen API:", response)
        return false, nil
    end

    local data
    local ok, err = pcall(function() data = HttpService:JSONDecode(response) end)
    if not ok then
        warn("❌ Fehler beim JSON-Parsing:", err)
        return false, nil
    end

    return data.found == true, data.server
end

-- =======================
-- Auto-Finder / Server-Hop
-- =======================
local function startFinder()
    if Svt.FinderActive then return end
    Svt.FinderActive = true
    print("✅ Auto-Finder gestartet für Pet:", Svt.SelectedPet)

    spawn(function()
        while Svt.FinderActive do
            local available, serverId = isPetAvailable()
            if available and serverId then
                print("✅ Pet gefunden auf:", serverId)
                local success, err = pcall(function()
                    TeleportService:TeleportToPlaceInstance(game.PlaceId, serverId, LP)
                end)
                if not success then
                    warn("❌ Fehler beim Hoppen:", err)
                end
                return -- Teleport beendet das Script
            else
                print("🔁 Kein Treffer – Suche läuft weiter...")
            end
            wait(1) -- kurze Pause zwischen API-Checks
        end
    end)
end

local function stopFinder()
    Svt.FinderActive = false
    print("⏹️ Auto-Finder gestoppt")
end

-- =======================
-- GUI
-- =======================
local function createUI()
    local parent = LP:FindFirstChild("PlayerGui") or game:GetService("CoreGui")
    pcall(function() parent:FindFirstChild("GicaHubUI"):Destroy() end)

    local screen = Instance.new("ScreenGui")
    screen.Name = "GicaHubUI"
    screen.Parent = parent

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0,300,0,180)
    frame.Position = UDim2.new(0.5,-150,0.5,-90)
    frame.BackgroundColor3 = Color3.fromRGB(60,0,120)
    frame.BackgroundTransparency = 0.2
    frame.ClipsDescendants = true
    frame.Parent = screen
    frame.Active = true
    frame.Draggable = true

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1,-20,0,30)
    title.Position = UDim2.new(0,10,0,10)
    title.BackgroundTransparency = 1
    title.Text = "Gica Hub Auto-Pet Finder"
    title.TextColor3 = Color3.fromRGB(255,255,255)
    title.Font = Enum.Font.GothamBold
    title.TextSize = 18
    title.Parent = frame

    -- Start Button
    local startBtn = Instance.new("TextButton")
    startBtn.Size = UDim2.new(0.45,0,0,28)
    startBtn.Position = UDim2.new(0.05,0,0,60)
    startBtn.Text = "Start Finder"
    startBtn.BackgroundColor3 = Color3.fromRGB(0,200,120)
    startBtn.TextColor3 = Color3.fromRGB(255,255,255)
    startBtn.Font = Enum.Font.GothamBold
    startBtn.TextSize = 16
    startBtn.Parent = frame
    startBtn.MouseButton1Click:Connect(startFinder)

    -- Stop Button
    local stopBtn = Instance.new("TextButton")
    stopBtn.Size = UDim2.new(0.45,0,0,28)
    stopBtn.Position = UDim2.new(0.5,0,0,60)
    stopBtn.Text = "Stop Finder"
    stopBtn.BackgroundColor3 = Color3.fromRGB(200,0,0)
    stopBtn.TextColor3 = Color3.fromRGB(255,255,255)
    stopBtn.Font = Enum.Font.GothamBold
    stopBtn.TextSize = 16
    stopBtn.Parent = frame
    stopBtn.MouseButton1Click:Connect(stopFinder)
end

-- =======================
-- Start GUI
-- =======================
createUI()

print("✅ Gica Hub Auto-Pet Finder ready. Script complete")

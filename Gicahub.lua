-- 🌌 Gica Auto-Pet Finder – Cloud API + UI
-- Ziel-Pet: Los Combinasion
-- API: https://los-combi-api.vercel.app/api/checkPet?pet=Los%20Combinasion

local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LP = Players.LocalPlayer

local API_URL = "https://los-combi-api.vercel.app/api/checkPet?pet=Los%20Combinasion"
local FinderActive = false
local PetName = "Los Combinasion"

-- =======================
-- UI erstellen
-- =======================
local function createUI()
    local parent = LP:FindFirstChild("PlayerGui") or game:GetService("CoreGui")
    pcall(function() parent:FindFirstChild("GicaHubUI"):Destroy() end)

    local screen = Instance.new("ScreenGui")
    screen.Name = "GicaHubUI"
    screen.Parent = parent

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 280, 0, 150)
    frame.Position = UDim2.new(0.5, -140, 0.5, -75)
    frame.BackgroundColor3 = Color3.fromRGB(50, 0, 100)
    frame.BackgroundTransparency = 0.2
    frame.BorderSizePixel = 0
    frame.Parent = screen
    frame.Active = true
    frame.Draggable = true

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 28)
    title.Position = UDim2.new(0,0,0,0)
    title.BackgroundTransparency = 1
    title.Text = "Gica Auto-Pet Finder"
    title.TextColor3 = Color3.fromRGB(255,255,255)
    title.Font = Enum.Font.GothamBold
    title.TextSize = 18
    title.Parent = frame

    local statusLabel = Instance.new("TextLabel")
    statusLabel.Size = UDim2.new(1, -20, 0, 24)
    statusLabel.Position = UDim2.new(0,10,0,40)
    statusLabel.BackgroundTransparency = 1
    statusLabel.Text = "Status: Idle"
    statusLabel.TextColor3 = Color3.fromRGB(255,255,255)
    statusLabel.Font = Enum.Font.Gotham
    statusLabel.TextSize = 16
    statusLabel.Parent = frame

    local startBtn = Instance.new("TextButton")
    startBtn.Size = UDim2.new(0.4, 0, 0, 32)
    startBtn.Position = UDim2.new(0.05,0,0,80)
    startBtn.BackgroundColor3 = Color3.fromRGB(120,0,200)
    startBtn.TextColor3 = Color3.fromRGB(255,255,255)
    startBtn.Font = Enum.Font.GothamBold
    startBtn.TextSize = 16
    startBtn.Text = "Start Finder"
    startBtn.Parent = frame

    local stopBtn = Instance.new("TextButton")
    stopBtn.Size = UDim2.new(0.4, 0, 0, 32)
    stopBtn.Position = UDim2.new(0.55,0,0,80)
    stopBtn.BackgroundColor3 = Color3.fromRGB(200,0,120)
    stopBtn.TextColor3 = Color3.fromRGB(255,255,255)
    stopBtn.Font = Enum.Font.GothamBold
    stopBtn.TextSize = 16
    stopBtn.Text = "Stop Finder"
    stopBtn.Parent = frame

    -- =======================
    -- Finder-Funktion
    -- =======================
    local function checkPet()
        local success, response = pcall(function()
            return HttpService:GetAsync(API_URL)
        end)

        if not success then
            warn("⚠️ API Fehler: ", response)
            statusLabel.Text = "Status: API Error"
            return false
        end

        local data
        success, data = pcall(function() return HttpService:JSONDecode(response) end)
        if not success or not data then
            warn("⚠️ API Antwort Fehler")
            statusLabel.Text = "Status: JSON Error"
            return false
        end

        if data.found then
            print("✅ Pet gefunden auf:", data.server)
            statusLabel.Text = "Status: Gefunden auf "..data.server
            TeleportService:TeleportToPlaceInstance(game.PlaceId, data.server, LP)
            return true
        else
            statusLabel.Text = "Status: Suche läuft..."
        end
        return false
    end

    -- =======================
    -- Start/Stop Buttons
    -- =======================
    local FinderLoop
    startBtn.MouseButton1Click:Connect(function()
        if FinderActive then return end
        FinderActive = true
        statusLabel.Text = "Status: Suche gestartet"
        FinderLoop = RunService.Heartbeat:Connect(function()
            if FinderActive then
                checkPet()
            end
        end)
    end)

    stopBtn.MouseButton1Click:Connect(function()
        if FinderLoop then FinderLoop:Disconnect() end
        FinderActive = false
        statusLabel.Text = "Status: Gestoppt"
        print("🛑 Auto-Pet Finder gestoppt")
    end)
end

-- UI erstellen
createUI()
print("✅ Gica Auto-Pet Finder UI geladen. Script completed.")

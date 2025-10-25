-- 🌌 Gica Hub v5 – KRNL Auto-Pet-Finder fix
-- Passwort/Key: "Luca123", UI sofort sichtbar, bewegbar, Start/Stop Buttons, API-Integration

local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local LP = Players.LocalPlayer or Players.PlayerAdded:Wait()

-- =======================
-- Config
-- =======================
local Config = {
    Key = "Luca123",
    SelectedPet = "Los Combinasion",
    FinderActive = false
}

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
    frame.Size = UDim2.new(0,300,0,220)
    frame.Position = UDim2.new(0.5,-150,0.5,-110)
    frame.BackgroundColor3 = Color3.fromRGB(50,0,100)
    frame.BackgroundTransparency = 0.3
    frame.ClipsDescendants = true
    frame.Active = true
    frame.Draggable = true
    frame.Parent = screen

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1,0,0,28)
    title.Position = UDim2.new(0,0,0,0)
    title.BackgroundTransparency = 1
    title.Text = "Gica Hub Pet-Finder"
    title.TextColor3 = Color3.fromRGB(255,255,255)
    title.Font = Enum.Font.GothamBold
    title.TextSize = 18
    title.Parent = frame

    -- Pet Auswahl Dropdown (nur Los Combinasion fixiert)
    local petLabel = Instance.new("TextLabel")
    petLabel.Size = UDim2.new(1,-20,0,28)
    petLabel.Position = UDim2.new(0,10,0,40)
    petLabel.BackgroundColor3 = Color3.fromRGB(80,0,150)
    petLabel.TextColor3 = Color3.fromRGB(255,255,255)
    petLabel.Text = "Pet: "..Config.SelectedPet
    petLabel.Font = Enum.Font.GothamBold
    petLabel.TextSize = 16
    petLabel.Parent = frame

    -- Start Button
    local startBtn = Instance.new("TextButton")
    startBtn.Size = UDim2.new(1,-20,0,32)
    startBtn.Position = UDim2.new(0,10,0,80)
    startBtn.Text = "Start Finder"
    startBtn.BackgroundColor3 = Color3.fromRGB(0,150,80)
    startBtn.TextColor3 = Color3.fromRGB(255,255,255)
    startBtn.Font = Enum.Font.GothamBold
    startBtn.TextSize = 16
    startBtn.Parent = frame

    -- Stop Button
    local stopBtn = Instance.new("TextButton")
    stopBtn.Size = UDim2.new(1,-20,0,32)
    stopBtn.Position = UDim2.new(0,10,0,120)
    stopBtn.Text = "Stop Finder"
    stopBtn.BackgroundColor3 = Color3.fromRGB(150,0,0)
    stopBtn.TextColor3 = Color3.fromRGB(255,255,255)
    stopBtn.Font = Enum.Font.GothamBold
    stopBtn.TextSize = 16
    stopBtn.Parent = frame

    return startBtn, stopBtn
end

-- =======================
-- Auto-Pet Finder (Cloud API)
-- =======================
local function startFinder()
    if Config.FinderActive then return end
    Config.FinderActive = true
    print("✅ Finder gestartet für Pet:", Config.SelectedPet)

    spawn(function()
        while Config.FinderActive do
            local success, response = pcall(function()
                return HttpService:GetAsync("https://petfinder-api-v3.vercel.app/api/checkPet?pet="..Config.SelectedPet.."&key=Luca123")
            end)
            if success then
                local data = HttpService:JSONDecode(response)
                if data.found then
                    print("✅ Pet gefunden auf Server:", data.server)
                    Config.FinderActive = false
                    break
                else
                    print("🔁 Kein Pet gefunden, suche weiter...")
                end
            else
                warn("❌ Fehler beim Abrufen der API:", response)
            end
            wait(1)
        end
    end)
end

-- Stop Finder
local function stopFinder()
    Config.FinderActive = false
    print("⏹️ Finder gestoppt")
end

-- =======================
-- Key Eingabe
-- =======================
local function keyCheck()
    local key = Config.Key -- Kann erweitert werden für InputBox, jetzt fix
    if key ~= "Luca123" then
        -- Vollbild Schwarz bei falschem Key
        local blackScreen = Instance.new("ScreenGui")
        blackScreen.Name = "WrongKey"
        blackScreen.Parent = LP:FindFirstChild("PlayerGui") or game:GetService("CoreGui")
        local frame = Instance.new("Frame")
        frame.Size = UDim2.new(1,0,1,0)
        frame.BackgroundColor3 = Color3.new(0,0,0)
        frame.Parent = blackScreen
        return false
    end
    return true
end

-- =======================
-- Initialisierung
-- =======================
if keyCheck() then
    local startBtn, stopBtn = createUI()
    startBtn.MouseButton1Click:Connect(startFinder)
    stopBtn.MouseButton1Click:Connect(stopFinder)
end

print("✅ Gica Hub Pet-Finder ready. Script completed.")

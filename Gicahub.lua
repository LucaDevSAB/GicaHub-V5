-- 🌌 Gica Hub v13 Mobile Auto-Pet-Hopper (KRNL)
-- Script completed am Ende

local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local LP = Players.LocalPlayer or Players.PlayerAdded:Wait()

-- =======================
-- API Konfiguration
-- =======================
local API_IP = "192.168.2.108" -- DEINE WLAN-IP
local API_URL = "http://"..API_IP..":3000/checkPet?pet="

-- =======================
-- Verfügbare Pets
-- =======================
local availablePets = {
    "Los Combinasion",
    "GoldenDragon",
    "FluffyCat",
    "RainbowDog",
    "MysticFox",
    "MysticRabbit",
    "ShadowWolf",
    "FireTiger",
    "IcePenguin",
    "CyberFox"
}

-- =======================
-- Settings
-- =======================
local Svt = {
    SelectedPet = availablePets[1],
    FinderActive = false,
    Dragging = false,
    DragOffset = Vector2.new()
}

-- =======================
-- Log Funktion
-- =======================
local logLabel
local function addLog(msg)
    if logLabel then
        logLabel.Text = logLabel.Text.."\n"..msg
    end
    print(msg)
end

-- =======================
-- API Auto-Hop
-- =======================
local function getServerWithPet(petName)
    local success, response = pcall(function()
        return HttpService:GetAsync(API_URL..HttpService:UrlEncode(petName))
    end)
    if success then
        local data = HttpService:JSONDecode(response)
        if data and data.available and data.serverId then
            return data.serverId
        end
    end
    return nil
end

-- =======================
-- Finder Funktionen
-- =======================
local function startFinder()
    if Svt.FinderActive then return end
    Svt.FinderActive = true
    addLog("✅ Auto-Finder gestartet für Pet: "..Svt.SelectedPet)

    spawn(function()
        while Svt.FinderActive do
            local serverId = getServerWithPet(Svt.SelectedPet)
            if serverId then
                addLog("✅ Pet auf Server gefunden! ServerID: "..serverId)
                local success, err = pcall(function()
                    TeleportService:TeleportToPlaceInstance(game.PlaceId, serverId, LP)
                end)
                if not success then
                    addLog("❌ Fehler beim Hoppen: "..tostring(err))
                end
                Svt.FinderActive = false
                break
            else
                addLog("⚠️ Pet aktuell auf keinem Server verfügbar. Suche...")
            end
            RunService.Heartbeat:Wait()
        end
    end)
end

local function stopFinder()
    Svt.FinderActive = false
    addLog("🛑 Auto-Finder gestoppt")
end

-- =======================
-- GUI Funktionen
-- =======================
local function createUI()
    local parent = LP:FindFirstChild("PlayerGui") or game:GetService("CoreGui")
    pcall(function() parent:FindFirstChild("GicaHubUI"):Destroy() end)

    local screen = Instance.new("ScreenGui", parent)
    screen.Name = "GicaHubUI"

    local frame = Instance.new("Frame", screen)
    frame.Size = UDim2.new(0, 350, 0, 420)
    frame.Position = UDim2.new(0.5, -175, 0.5, -210)
    frame.BackgroundColor3 = Color3.fromRGB(60, 0, 120)
    frame.BackgroundTransparency = 0.2
    frame.AnchorPoint = Vector2.new(0.5,0.5)
    frame.Active = true

    -- Smooth bewegbar per Touch
    frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            Svt.Dragging = true
            Svt.DragOffset = input.Position - Vector2.new(frame.Position.X.Offset, frame.Position.Y.Offset)
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    Svt.Dragging = false
                end
            end)
        end
    end)
    RunService.RenderStepped:Connect(function()
        if Svt.Dragging then
            local mousePos = UserInputService:GetMouseLocation()
            local targetPos = UDim2.new(0, mousePos.X - Svt.DragOffset.X, 0, mousePos.Y - Svt.DragOffset.Y)
            frame.Position = frame.Position:Lerp(targetPos, 0.2)
        end
    end)

    -- Titel
    local title = Instance.new("TextLabel", frame)
    title.Size = UDim2.new(1, -20, 0, 30)
    title.Position = UDim2.new(0, 10, 0, 10)
    title.BackgroundTransparency = 1
    title.Text = "Gica Hub Pet-Hopper"
    title.TextColor3 = Color3.fromRGB(255,255,255)
    title.Font = Enum.Font.GothamBold
    title.TextSize = 20

    -- Pet Dropdown
    local petFrame = Instance.new("ScrollingFrame", frame)
    petFrame.Size = UDim2.new(1, -20, 0, 180)
    petFrame.Position = UDim2.new(0,10,0,50)
    petFrame.BackgroundTransparency = 0.3
    petFrame.CanvasSize = UDim2.new(0,0,#availablePets*40)
    petFrame.ScrollBarThickness = 8

    local yPos = 0
    for i, petName in ipairs(availablePets) do
        local btn = Instance.new("TextButton", petFrame)
        btn.Size = UDim2.new(1, -10, 0, 35)
        btn.Position = UDim2.new(0,5,0,yPos)
        btn.Text = petName
        btn.BackgroundColor3 = Color3.fromRGB(180,0,220)
        btn.TextColor3 = Color3.fromRGB(255,255,255)
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 16

        btn.MouseButton1Click:Connect(function()
            Svt.SelectedPet = petName
            addLog("✅ Pet ausgewählt: "..Svt.SelectedPet)
        end)

        yPos = yPos + 40
    end
    petFrame.CanvasSize = UDim2.new(0,0,yPos)

    -- Start Button
    local startBtn = Instance.new("TextButton", frame)
    startBtn.Size = UDim2.new(1, -20, 0, 35)
    startBtn.Position = UDim2.new(0, 10, 0, 250)
    startBtn.Text = "Start Finder"
    startBtn.BackgroundColor3 = Color3.fromRGB(0,150,255)
    startBtn.TextColor3 = Color3.fromRGB(255,255,255)
    startBtn.Font = Enum.Font.GothamBold
    startBtn.TextSize = 18
    startBtn.MouseButton1Click:Connect(startFinder)

    -- Stop Button
    local stopBtn = Instance.new("TextButton", frame)
    stopBtn.Size = UDim2.new(1, -20, 0, 35)
    stopBtn.Position = UDim2.new(0, 10, 0, 300)
    stopBtn.Text = "Stop Finder"
    stopBtn.BackgroundColor3 = Color3.fromRGB(200,0,0)
    stopBtn.TextColor3 = Color3.fromRGB(255,255,255)
    stopBtn.Font = Enum.Font.GothamBold
    stopBtn.TextSize = 18
    stopBtn.MouseButton1Click:Connect(stopFinder)

    -- Log
    logLabel = Instance.new("TextLabel", frame)
    logLabel.Size = UDim2.new(1, -20, 0, 80)
    logLabel.Position = UDim2.new(0, 10, 0, 350)
    logLabel.BackgroundTransparency = 0.3
    logLabel.TextColor3 = Color3.fromRGB(255,255,255)
    logLabel.Font = Enum.Font.Gotham
    logLabel.TextSize = 14
    logLabel.TextWrapped = true
    logLabel.TextYAlignment = Enum.TextYAlignment.Top
end

-- =======================
-- Key GUI
-- =======================
local function showKeyGUI()
    local parent = LP:FindFirstChild("PlayerGui") or game:GetService("CoreGui")
    local keyGui = Instance.new("ScreenGui", parent)
    keyGui.Name = "KeyGUI"

    local frame = Instance.new("Frame", keyGui)
    frame.Size = UDim2.new(0, 300, 0, 150)
    frame.Position = UDim2.new(0.5, -150, 0.5, -75)
    frame.BackgroundColor3 = Color3.fromRGB(50, 0, 100)
    frame.BackgroundTransparency = 0.2

    local textbox = Instance.new("TextBox", frame)
    textbox.Size = UDim2.new(1, -20, 0, 50)
    textbox.Position = UDim2.new(0, 10, 0, 40)
    textbox.PlaceholderText = "Enter Key"
    textbox.Text = ""
    textbox.Font = Enum.Font.GothamBold
    textbox.TextSize = 20
    textbox.TextColor3 = Color3.fromRGB(255,255,255)
    textbox.BackgroundColor3 = Color3.fromRGB(80,0,120)

    local submitBtn = Instance.new("TextButton", frame)
    submitBtn.Size = UDim2.new(1, -20, 0, 40)
    submitBtn.Position = UDim2.new(0, 10, 0, 100)
    submitBtn.Text = "Submit"
    submitBtn.BackgroundColor3 = Color3.fromRGB(0,150,255)
    submitBtn.TextColor3 = Color3.fromRGB(255,255,255)
    submitBtn.Font = Enum.Font.GothamBold
    submitBtn.TextSize = 18

    submitBtn.MouseButton1Click:Connect(function()
        if textbox.Text == "GicaHub" then
            keyGui:Destroy()
            createUI()
        else
            -- Schwarzer Bildschirm erzwingen
            local blackGui = Instance.new("ScreenGui", parent)
            local blackFrame = Instance.new("Frame", blackGui)
            blackFrame.Size = UDim2.new(1,0,1,0)
            blackFrame.BackgroundColor3 = Color3.new(0,0,0)
        end
    end)
end

-- =======================
-- Start Script
-- =======================
showKeyGUI()

print("✅ Gica Hub v13 Mobile Auto-Pet-Hopper ready. Script completed.")

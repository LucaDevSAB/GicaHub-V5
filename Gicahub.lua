-- 🌌 Gica Hub v5 Mobile Auto-Pet-Hopper (Key + Fancy UI + Start/Stop Finder + Cooldown)
-- KRNL-kompatibel

local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

local LP = Players.LocalPlayer or Players.PlayerAdded:Wait()

-- =======================
-- Alle verfügbaren Pets
-- =======================
local availablePets = {
    "Noobini Pizzanini","Lirili Larila","Tim Cheese","FluriFlura","Talpa Di Fero","Svinina Bombardino","Pipi Kiwi",
    "Trippi Troppi","Gangster Footera","Bandito Bobritto","Boneca Ambalabu","Cacto Hipopotamo","Ta Ta Ta Ta Sahur",
    "Tric Trac Baraboom","Cappuccino Assassino","Brr Brr Patapim","Trulimero Trulicina","Bambini Crostini",
    "Bananita Dolphinita","Perochello Lemonchello","Brri Brri Bicus Dicus Bombicus","Burbaloni Loliloli",
    "Lionel Cactuseli","Blueberrini Octopusini","Strawberelli Flamingelli","Bombardiro Crocodilo",
    "Gorillo Watermelondrillo","Gattatino Nyanino","La Grande Combinasion","Nuclearo Dinossauro","Garama and Madundung"
}

local Svt = {
    SelectedPet = availablePets[1],
    FinderActive = false
}

local GUI = {}

-- =======================
-- Log-Funktion
-- =======================
local function log(text, type)
    print(text)
    if not GUI.logBox then return end
    local color = Color3.fromRGB(255,255,255)
    if type == "success" then color = Color3.fromRGB(0,255,0)
    elseif type == "warn" then color = Color3.fromRGB(255,255,0)
    elseif type == "error" then color = Color3.fromRGB(255,0,0) end

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1,0,0,20)
    lbl.Position = UDim2.new(0,0,0,GUI.logBox.CanvasSize.Y.Offset)
    lbl.BackgroundTransparency = 1
    lbl.TextColor3 = color
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 14
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Text = text
    lbl.Parent = GUI.logBox

    GUI.logBox.CanvasSize = UDim2.new(0,0,0,GUI.logBox.CanvasSize.Y.Offset + 22)
    GUI.logBox.CanvasPosition = Vector2.new(0, GUI.logBox.CanvasSize.Y.Offset)
end

-- =======================
-- Prüft Base nach Pet
-- =======================
local function baseHasPet(petName)
    for _, base in pairs(Workspace:GetChildren()) do
        if base:IsA("Model") or base:IsA("Folder") then
            for _, obj in pairs(base:GetDescendants()) do
                if (obj:IsA("StringValue") or obj:IsA("ObjectValue") or obj:IsA("IntValue") or obj:IsA("NumberValue")) then
                    local ok, val = pcall(function() return tostring(obj.Value) end)
                    if ok and val:lower():match(petName:lower()) then return true, base.Name end
                elseif obj:IsA("MeshPart") or obj:IsA("Part") then
                    if obj.Name:lower():match(petName:lower()) then return true, base.Name end
                end
            end
        end
    end
    return false, nil
end

-- =======================
-- Auto-Finder
-- =======================
local function startFinder()
    if Svt.FinderActive then return end
    Svt.FinderActive = true
    log("✅ Auto-Finder gestartet für Pet: "..Svt.SelectedPet,"success")
    spawn(function()
        while Svt.FinderActive do
            local found, baseName = baseHasPet(Svt.SelectedPet)
            if found then
                log("✅ Pet gefunden im Server in Base: "..baseName,"success")
                Svt.FinderActive = false
                break
            else
                log("⏳ Pet nicht gefunden, hoppe zu anderem Server...","warn")
                pcall(function()
                    TeleportService:Teleport(game.PlaceId, LP)
                end)
            end
            wait(2) -- 2 Sekunden Cooldown nach jedem Server-Check
        end
    end)
end

local function stopFinder()
    if Svt.FinderActive then
        Svt.FinderActive = false
        log("🛑 Auto-Finder gestoppt","warn")
    end
end

-- =======================
-- Haupt-UI mit Start/Stop Finder
-- =======================
local function createUI()
    local parent = LP:FindFirstChild("PlayerGui") or game:GetService("CoreGui")
    pcall(function() parent:FindFirstChild("GicaHubUI"):Destroy() end)

    local screen = Instance.new("ScreenGui")
    screen.Name = "GicaHubUI"
    screen.Parent = parent

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0,320,0,480)
    frame.Position = UDim2.new(0.5,-160,0.5,-240)
    frame.BackgroundColor3 = Color3.fromRGB(50,0,80)
    frame.BackgroundTransparency = 0.2
    frame.BorderSizePixel = 0
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0,20)
    corner.Parent = frame
    frame.Parent = screen

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1,-20,0,28)
    title.Position = UDim2.new(0,10,0,10)
    title.BackgroundTransparency = 1
    title.Text = "Gica Hub Pet-Hopper"
    title.TextColor3 = Color3.fromRGB(255,200,255)
    title.Font = Enum.Font.GothamBold
    title.TextSize = 18
    title.Parent = frame

    -- Dropdown für Pets
    local scrollFrame = Instance.new("ScrollingFrame")
    scrollFrame.Size = UDim2.new(1,-20,0,160)
    scrollFrame.Position = UDim2.new(0,10,0,50)
    scrollFrame.CanvasSize = UDim2.new(0,0,0,#availablePets*35)
    scrollFrame.ScrollBarThickness = 8
    scrollFrame.BackgroundTransparency = 0.3
    scrollFrame.BackgroundColor3 = Color3.fromRGB(100,0,150)
    scrollFrame.BorderSizePixel = 0
    scrollFrame.Parent = frame

    local uiListLayout = Instance.new("UIListLayout")
    uiListLayout.Parent = scrollFrame
    uiListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    uiListLayout.Padding = UDim.new(0,5)

    for i, petName in ipairs(availablePets) do
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1,0,0,28)
        btn.Text = petName
        btn.BackgroundColor3 = Color3.fromRGB(120,0,180)
        btn.TextColor3 = Color3.fromRGB(255,255,255)
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 16
        btn.AutoButtonColor = true
        btn.Parent = scrollFrame
        local btnCorner = Instance.new("UICorner")
        btnCorner.CornerRadius = UDim.new(0,12)
        btnCorner.Parent = btn

        btn.MouseButton1Click:Connect(function()
            Svt.SelectedPet = petName
            log("✅ Pet ausgewählt: "..Svt.SelectedPet,"success")
        end)
    end

    -- Start Finder Button
    local startBtn = Instance.new("TextButton")
    startBtn.Size = UDim2.new(1,-20,0,32)
    startBtn.Position = UDim2.new(0,10,0,220)
    startBtn.Text = "Start Auto-Finder"
    startBtn.BackgroundColor3 = Color3.fromRGB(0,150,255)
    startBtn.TextColor3 = Color3.fromRGB(255,255,255)
    local startCorner = Instance.new("UICorner")
    startCorner.CornerRadius = UDim.new(0,12)
    startCorner.Parent = startBtn
    startBtn.Parent = frame
    startBtn.MouseButton1Click:Connect(startFinder)

    -- Stop Finder Button
    local stopBtn = Instance.new("TextButton")
    stopBtn.Size = UDim2.new(1,-20,0,32)
    stopBtn.Position = UDim2.new(0,10,0,260)
    stopBtn.Text = "Stop Auto-Finder"
    stopBtn.BackgroundColor3 = Color3.fromRGB(255,0,0)
    stopBtn.TextColor3 = Color3.fromRGB(255,255,255)
    local stopCorner = Instance.new("UICorner")
    stopCorner.CornerRadius = UDim.new(0,12)
    stopCorner.Parent = stopBtn
    stopBtn.Parent = frame
    stopBtn.MouseButton1Click:Connect(stopFinder)

    -- LogBox
    local logBox = Instance.new("ScrollingFrame")
    logBox.Size = UDim2.new(1,-20,0,180)
    logBox.Position = UDim2.new(0,10,0,300)
    logBox.CanvasSize = UDim2.new(0,0,0,0)
    logBox.ScrollBarThickness = 8
    logBox.BackgroundColor3 = Color3.fromRGB(60,0,100)
    logBox.BackgroundTransparency = 0.2
    logBox.BorderSizePixel = 0
    local logCorner = Instance.new("UICorner")
    logCorner.CornerRadius = UDim.new(0,16)
    logCorner.Parent = logBox
    logBox.Parent = frame

    GUI.logBox = logBox
end

-- =======================
-- Script starten
-- =======================
createUI()

-- Script completed

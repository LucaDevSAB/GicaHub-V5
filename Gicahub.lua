-- 🌌 Gica Hub v8 Mobile Auto-Pet-Hopper (KRNL, lokale API, Auto-Hop)
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
local API_URL = "http://192.168.179.68:3000/checkPet?pet=" -- trage hier deine lokale IP ein

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
    DragOffset = Vector3.new()
}

-- =======================
-- API Auto-Hop
-- =======================
local function getServerWithPet(petName)
    local success, response = pcall(function()
        return HttpService:GetAsync(API_URL..HttpService:UrlEncode(petName))
    end)
    if success then
        local data = HttpService:JSONDecode(response)
        if type(data) == "table" then
            for _, server in ipairs(data) do
                if server.available and server.serverId then
                    return server.serverId
                end
            end
        elseif data.available and data.serverId then
            return data.serverId
        end
    end
    return nil
end

-- =======================
-- Base Check
-- =======================
local function baseHasPet(petName)
    for _, base in pairs(Workspace:GetChildren()) do
        if base:IsA("Model") or base:IsA("Folder") then
            for _, obj in pairs(base:GetDescendants()) do
                if obj:IsA("StringValue") or obj:IsA("ObjectValue") or obj:IsA("IntValue") or obj:IsA("NumberValue") then
                    local ok,val = pcall(function() return tostring(obj.Value) end)
                    if ok and val:lower():match(petName:lower()) then
                        return true
                    end
                elseif obj:IsA("Part") or obj:IsA("MeshPart") then
                    if obj.Name:lower():match(petName:lower()) then
                        return true
                    end
                end
            end
        end
    end
    return false
end

-- =======================
-- Finder Funktionen
-- =======================
local function startFinder()
    if Svt.FinderActive then return end
    Svt.FinderActive = true
    print("✅ Auto-Finder gestartet für Pet:", Svt.SelectedPet)

    spawn(function()
        while Svt.FinderActive do
            local serverId = getServerWithPet(Svt.SelectedPet)
            if serverId then
                print("✅ Pet auf Server gefunden! ServerID:", serverId)
                -- Auto-Hop
                local success, err = pcall(function()
                    TeleportService:TeleportToPlaceInstance(game.PlaceId, serverId, LP)
                end)
                if not success then
                    warn("❌ Fehler beim Hoppen:", err)
                end
                Svt.FinderActive = false
                break
            else
                print("⚠️ Pet aktuell auf keinem Server verfügbar. Warte 2 Sekunden...")
            end
            wait(2)
        end
    end)
end

local function stopFinder()
    Svt.FinderActive = false
    print("🛑 Auto-Finder gestoppt")
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
    frame.Size = UDim2.new(0, 320, 0, 300)
    frame.Position = UDim2.new(0.5, -160, 0.5, -150)
    frame.BackgroundColor3 = Color3.fromRGB(50, 0, 100)
    frame.BackgroundTransparency = 0.2
    frame.AnchorPoint = Vector2.new(0.5, 0.5)
    frame.Active = true
    frame.Selectable = true

    -- Movable UI
    frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            Svt.Dragging = true
            Svt.DragOffset = input.Position - frame.Position
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
            frame.Position = UDim2.new(0, mousePos.X - Svt.DragOffset.X, 0, mousePos.Y - Svt.DragOffset.Y)
        end
    end)

    -- Titel
    local title = Instance.new("TextLabel", frame)
    title.Size = UDim2.new(1, -20, 0, 30)
    title.Position = UDim2.new(0, 10, 0, 10)
    title.BackgroundTransparency = 1
    title.Text = "Gica Hub Pet-Hopper"
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.Font = Enum.Font.GothamBold
    title.TextSize = 18

    -- Dropdown für Pets
    local yPos = 50
    for i, petName in ipairs(availablePets) do
        local btn = Instance.new("TextButton", frame)
        btn.Size = UDim2.new(1, -20, 0, 28)
        btn.Position = UDim2.new(0, 10, 0, yPos)
        btn.Text = petName
        btn.BackgroundColor3 = Color3.fromRGB(120, 0, 200)
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 16

        -- Puls-Effekt
        spawn(function()
            while btn.Parent do
                for i=0,1,0.05 do
                    btn.BackgroundTransparency = 0.2 + 0.3 * i
                    wait(0.03)
                end
                for i=1,0,-0.05 do
                    btn.BackgroundTransparency = 0.2 + 0.3 * i
                    wait(0.03)
                end
            end
        end)

        btn.MouseButton1Click:Connect(function()
            Svt.SelectedPet = petName
            print("✅ Pet ausgewählt:", Svt.SelectedPet)
        end)

        yPos = yPos + 35
    end

    -- Start Button
    local startBtn = Instance.new("TextButton", frame)
    startBtn.Size = UDim2.new(1, -20, 0, 32)
    startBtn.Position = UDim2.new(0, 10, 0, yPos)
    startBtn.Text = "Start Finder"
    startBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
    startBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    startBtn.Font = Enum.Font.GothamBold
    startBtn.TextSize = 16
    startBtn.MouseButton1Click:Connect(startFinder)
    yPos = yPos + 40

    -- Stop Button
    local stopBtn = Instance.new("TextButton", frame)
    stopBtn.Size = UDim2.new(1, -20, 0, 32)
    stopBtn.Position = UDim2.new(0, 10, 0, yPos)
    stopBtn.Text = "Stop Finder"
    stopBtn.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
    stopBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    stopBtn.Font = Enum.Font.GothamBold
    stopBtn.TextSize = 16
    stopBtn.MouseButton1Click:Connect(stopFinder)
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
    textbox.PlaceholderText = "Enter Key"
    textbox.Size = UDim2.new(0.8, 0, 0, 30)
    textbox.Position = UDim2.new(0.1, 0, 0.3, 0)

    local button = Instance.new("TextButton", frame)
    button.Text = "Submit"
    button.Size = UDim2.new(0.5, 0, 0, 30)
    button.Position = UDim2.new(0.25, 0, 0.7, 0)

    button.MouseButton1Click:Connect(function()
        if textbox.Text == "GicaHub" then
            keyGui:Destroy()
            createUI()
        else
            for _,v in pairs(parent:GetChildren()) do v:Destroy() end
            local blackGui = Instance.new("ScreenGui", parent)
            local bframe = Instance.new("Frame", blackGui)
            bframe.Size = UDim2.new(1,0,1,0)
            bframe.BackgroundColor3 = Color3.new(0,0,0)
        end
    end)
end

-- =======================
-- Start
-- =======================
showKeyGUI()

print("✅ Gica Hub v8 Mobile Auto-Pet-Hopper ready. Script completed.")

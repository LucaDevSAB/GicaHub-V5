-- 🌌 Gica Hub v6 – KRNL Auto-Pet-Hopper (API-basiert)

-- Services
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local LP = Players.LocalPlayer or Players.PlayerAdded:Wait()

-- =======================
-- Konfiguration
-- =======================
local Svt = {
    SelectedPet = "Los Combinasion",
    FinderActive = false,
    API_URL = "http://192.168.2.108:3000/checkPet?pet=Los%20Combinasion", -- Deine Termux API IP
}

-- =======================
-- Hilfsfunktion: prüft Base nach Pet
-- =======================
local function baseHasPet(petName)
    for _, base in pairs(Workspace:GetChildren()) do
        if base:IsA("Model") or base:IsA("Folder") then
            for _, obj in pairs(base:GetDescendants()) do
                if (obj:IsA("StringValue") or obj:IsA("ObjectValue") or obj:IsA("IntValue") or obj:IsA("NumberValue")) then
                    local ok, val = pcall(function() return tostring(obj.Value) end)
                    if ok and val:lower():match(petName:lower()) then
                        return true, base.Name
                    end
                elseif obj:IsA("MeshPart") or obj:IsA("Part") then
                    if obj.Name:lower():match(petName:lower()) then
                        return true, base.Name
                    end
                end
            end
        end
    end
    return false, nil
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
            -- 1️⃣ Erst lokale Base prüfen
            local found, baseName = baseHasPet(Svt.SelectedPet)
            if found then
                print("✅ Pet bereits im aktuellen Server in Base:", baseName)
                Svt.FinderActive = false
                return
            end

            -- 2️⃣ API abfragen
            local success, response = pcall(function()
                return HttpService:GetAsync(Svt.API_URL)
            end)

            if success then
                local data = HttpService:JSONDecode(response)
                if data.found then
                    print("✅ Pet gefunden auf Server:", data.server)
                    -- Teleport auf gefundenen Server
                    local hopSuccess, hopErr = pcall(function()
                        TeleportService:TeleportToPlaceInstance(game.PlaceId, data.server, LP)
                    end)
                    if not hopSuccess then
                        warn("❌ Fehler beim Hoppen:", hopErr)
                    end
                    return -- Teleport beendet Script
                else
                    print("🔁 Kein Treffer – Suche läuft weiter...")
                end
            else
                warn("❌ API konnte nicht erreicht werden:", response)
            end

            wait(1) -- Kurzer Cooldown, sonst zu viele Requests
        end
    end)
end

local function stopFinder()
    Svt.FinderActive = false
    print("🛑 Auto-Finder gestoppt")
end

-- =======================
-- GUI für Pet-Auswahl + Start/Stop
-- =======================
local function createUI()
    local parent = LP:FindFirstChild("PlayerGui") or game:GetService("CoreGui")
    pcall(function() parent:FindFirstChild("GicaHubUI"):Destroy() end)

    local screen = Instance.new("ScreenGui")
    screen.Name = "GicaHubUI"
    screen.Parent = parent

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 280, 0, 180)
    frame.Position = UDim2.new(0.5, -140, 0.5, -90)
    frame.BackgroundColor3 = Color3.fromRGB(60, 0, 100)
    frame.BackgroundTransparency = 0.3
    frame.BorderSizePixel = 0
    frame.Parent = screen

    -- Mach Frame per Touch bewegbar
    local uis = game:GetService("UserInputService")
    local dragging, dragInput, dragStart, startPos
    frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    frame.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement then
            dragInput = input
        end
    end)
    RunService.RenderStepped:Connect(function()
        if dragging and dragInput then
            local delta = dragInput.Position - dragStart
            frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)

    -- Start Button
    local startBtn = Instance.new("TextButton")
    startBtn.Size = UDim2.new(0, 120, 0, 32)
    startBtn.Position = UDim2.new(0, 20, 0, 50)
    startBtn.Text = "Start Finder"
    startBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 80)
    startBtn.TextColor3 = Color3.fromRGB(255,255,255)
    startBtn.Parent = frame
    startBtn.MouseButton1Click:Connect(startFinder)

    -- Stop Button
    local stopBtn = Instance.new("TextButton")
    stopBtn.Size = UDim2.new(0, 120, 0, 32)
    stopBtn.Position = UDim2.new(0, 140, 0, 50)
    stopBtn.Text = "Stop Finder"
    stopBtn.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
    stopBtn.TextColor3 = Color3.fromRGB(255,255,255)
    stopBtn.Parent = frame
    stopBtn.MouseButton1Click:Connect(stopFinder)
end

-- =======================
-- Starte GUI
-- =======================
createUI()

print("✅ Gica Hub v6 ready. Script completed.")

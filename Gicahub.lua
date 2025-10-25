-- 🌌 Gica Hub v5 Mobile Auto-Pet-Hopper robust
-- KRNL-kompatibel

local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local Workspace = game:GetService("Workspace")

local LP = Players.LocalPlayer or Players.PlayerAdded:Wait()

-- =======================
-- Pet-Auswahl
-- =======================
local availablePets = {
    "Los Combinasion", "GoldenDragon", "FluffyCat", "RainbowDog", "MysticFox"
}
local Svt = {
    SelectedPet = availablePets[1],
    FinderActive = false,
    minPlayers = 4
}

-- =======================
-- Prüft Base nach Pet
-- =======================
local function baseHasPet(petName)
    for _, base in pairs(Workspace:GetChildren()) do
        if base:IsA("Model") or base:IsA("Folder") then
            for _, obj in pairs(base:GetDescendants()) do
                local ok, val = pcall(function() return tostring(obj.Value) end)
                if ok and val and val:lower():match(petName:lower()) then
                    return true, base.Name
                elseif obj:IsA("Part") or obj:IsA("MeshPart") then
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

    local PlaceId = game.PlaceId
    local serversChecked = {}
    local pageCursor = ""

    spawn(function()
        while Svt.FinderActive do
            local url = "https://games.roblox.com/v1/games/"..PlaceId.."/servers/Public?sortOrder=Asc&limit=100"
            if pageCursor ~= "" then url = url.."&cursor="..pageCursor end

            local success, response = pcall(function() return HttpService:GetAsync(url) end)
            if not success then
                warn("❌ Fehler beim Abrufen Serverliste:", response)
                wait(2)
                continue
            end

            local data
            local ok, jsonErr = pcall(function() data = HttpService:JSONDecode(response) end)
            if not ok then
                warn("❌ JSON-Parsing Fehler:", jsonErr)
                wait(2)
                continue
            end

            pageCursor = data.nextPageCursor or ""

            if not data.data or #data.data == 0 then
                print("⚠️ Keine Server auf dieser Seite")
                wait(2)
                continue
            end

            table.sort(data.data, function(a,b) return (a.playing or 0) > (b.playing or 0) end)

            for _, server in pairs(data.data) do
                local sid = server.id
                if not serversChecked[sid] and (server.playing or 0) >= Svt.minPlayers then
                    serversChecked[sid] = true
                    print(("[Finder] Prüfe ServerID: %s (Spieler: %d)"):format(sid, server.playing or 0))

                    local found, baseName = baseHasPet(Svt.SelectedPet)
                    if found then
                        print("✅ Pet bereits im aktuellen Server:", baseName)
                        Svt.FinderActive = false
                        return
                    end

                    local hopSuccess, hopErr = pcall(function()
                        TeleportService:TeleportToPlaceInstance(PlaceId, sid, LP)
                    end)

                    if not hopSuccess then
                        warn("❌ Fehler beim Hoppen (evtl. Server blockiert):", hopErr)
                        -- Weiter zum nächsten Server
                    else
                        return -- Teleport erfolgreich, Script stoppt hier
                    end
                end
            end

            if pageCursor == "" then
                print("⚠️ Keine weiteren Server verfügbar, retry...")
                pageCursor = ""
            end
            wait(1)
        end
    end)
end

-- =======================
-- Start / Stop Buttons & UI
-- =======================
local function createUI()
    local parent = LP:FindFirstChild("PlayerGui") or game:GetService("CoreGui")
    pcall(function() parent:FindFirstChild("GicaHubUI"):Destroy() end)

    local screen = Instance.new("ScreenGui")
    screen.Name = "GicaHubUI"
    screen.Parent = parent

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0,320,0,250)
    frame.Position = UDim2.new(0.5,-160,0.5,-125)
    frame.BackgroundColor3 = Color3.fromRGB(28,6,40)
    frame.Parent = screen
    frame.Active = true
    frame.Draggable = true -- Smooth bewegen per Touch

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1,-20,0,28)
    title.Position = UDim2.new(0,10,0,10)
    title.BackgroundTransparency = 1
    title.Text = "Gica Hub Pet-Hopper"
    title.TextColor3 = Color3.fromRGB(255,255,255)
    title.Font = Enum.Font.GothamBold
    title.TextSize = 18
    title.Parent = frame

    -- Dropdown-artige Auswahl
    local yPos = 50
    for i, petName in ipairs(availablePets) do
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1,-20,0,28)
        btn.Position = UDim2.new(0,10,0,yPos)
        btn.Text = petName
        btn.BackgroundColor3 = Color3.fromRGB(80,0,150)
        btn.TextColor3 = Color3.fromRGB(255,255,255)
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 16
        btn.Parent = frame

        btn.MouseButton1Click:Connect(function()
            Svt.SelectedPet = petName
            print("✅ Pet ausgewählt:", Svt.SelectedPet)
        end)

        yPos = yPos + 35
    end

    -- Start Button
    local startBtn = Instance.new("TextButton")
    startBtn.Size = UDim2.new(1,-20,0,32)
    startBtn.Position = UDim2.new(0,10,0,yPos)
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
    stopBtn.Position = UDim2.new(0,10,0,yPos+40)
    stopBtn.Text = "Stop Finder"
    stopBtn.BackgroundColor3 = Color3.fromRGB(150,0,0)
    stopBtn.TextColor3 = Color3.fromRGB(255,255,255)
    stopBtn.Font = Enum.Font.GothamBold
    stopBtn.TextSize = 16
    stopBtn.Parent = frame
    stopBtn.MouseButton1Click:Connect(function()
        Svt.FinderActive = false
        print("🛑 Finder gestoppt")
    end)
end

-- =======================
-- Start UI
-- =======================
createUI()

print("✅ Gica Hub v5 Auto-Pet-Finder ready. Script completed.")

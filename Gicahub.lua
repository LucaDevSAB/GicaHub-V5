-- 🌌 Gica Hub v5 Mobile Auto-Pet-Hopper mit Pet-Auswahl (scrollbare Dropdown)
-- KRNL-kompatibel, startet automatisch beim Join

local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local Workspace = game:GetService("Workspace")

local LP = Players.LocalPlayer or Players.PlayerAdded:Wait()

-- =======================
-- Alle verfügbaren Steal-a-Brainrot Pets
-- =======================
local availablePets = {
    "Noobini Pizzanini",
    "Lirili Larila",
    "Tim Cheese",
    "FluriFlura",
    "Talpa Di Fero",
    "Svinina Bombardino",
    "Pipi Kiwi",
    "Trippi Troppi",
    "Gangster Footera",
    "Bandito Bobritto",
    "Boneca Ambalabu",
    "Cacto Hipopotamo",
    "Ta Ta Ta Ta Sahur",
    "Tric Trac Baraboom",
    "Cappuccino Assassino",
    "Brr Brr Patapim",
    "Trulimero Trulicina",
    "Bambini Crostini",
    "Bananita Dolphinita",
    "Perochello Lemonchello",
    "Brri Brri Bicus Dicus Bombicus",
    "Burbaloni Loliloli",
    "Lionel Cactuseli",
    "Blueberrini Octopusini",
    "Strawberelli Flamingelli",
    "Bombardiro Crocodilo",
    "Gorillo Watermelondrillo",
    "Gattatino Nyanino",
    "La Grande Combinasion",
    "Nuclearo Dinossauro",
    "Garama and Madundung",
}

-- =======================
-- Konfiguration
-- =======================
local Svt = {
    SelectedPet = availablePets[1],
    FinderActive = false,
    minPlayers = 4,
    maxAttempts = 200
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

    local found, baseName = baseHasPet(Svt.SelectedPet)
    if found then
        print("✅ Pet bereits im aktuellen Server in Base:", baseName)
        Svt.FinderActive = false
        return
    end

    local PlaceId = game.PlaceId
    local serversChecked = {}
    local pageCursor = ""
    local attempts = 0

    spawn(function()
        while Svt.FinderActive and attempts < Svt.maxAttempts do
            local url = "https://games.roblox.com/v1/games/"..PlaceId.."/servers/Public?sortOrder=Asc&limit=100"
            if pageCursor ~= "" then url = url.."&cursor="..pageCursor end

            local success, response = pcall(function() return HttpService:GetAsync(url) end)
            if not success then
                warn("❌ Fehler beim Abrufen Serverliste:", response)
                wait(5)
                continue
            end

            local data
            local ok,jsonErr = pcall(function() data = HttpService:JSONDecode(response) end)
            if not ok then
                warn("❌ Fehler beim JSON-Parsing:", jsonErr)
                wait(5)
                continue
            end

            pageCursor = data.nextPageCursor or ""

            if not data.data or #data.data == 0 then
                print("⚠️ Keine Server in dieser Seite verfügbar")
                wait(5)
                continue
            end

            table.sort(data.data, function(a,b) return (a.playing or 0) > (b.playing or 0) end)

            for _, server in pairs(data.data) do
                local sid = server.id
                if not serversChecked[sid] and (server.playing or 0) >= Svt.minPlayers then
                    serversChecked[sid] = true
                    attempts = attempts + 1
                    print(("[Finder] Versuch %d/%d → ServerID: %s (Spieler: %d)"):format(attempts, Svt.maxAttempts, sid, server.playing or 0))

                    local hopSuccess, hopErr = pcall(function()
                        TeleportService:TeleportToPlaceInstance(PlaceId, sid, LP)
                    end)
                    if not hopSuccess then
                        warn("❌ Fehler beim Hoppen:", hopErr)
                    end

                    return
                end
            end

            if pageCursor == "" then
                print("⚠️ Keine weiteren Server verfügbar, retry in 5 Sekunden...")
                wait(5)
                pageCursor = ""
            end

            wait(1)
        end

        if attempts >= Svt.maxAttempts then
            print("⚠️ Max Attempts erreicht, Finder stoppt")
            Svt.FinderActive = false
        end
    end)
end

-- =======================
-- GUI für Pet-Auswahl (scrollbar)
-- =======================
local function createUI()
    local parent = LP:FindFirstChild("PlayerGui") or game:GetService("CoreGui")
    pcall(function() parent:FindFirstChild("GicaHubUI"):Destroy() end)

    local screen = Instance.new("ScreenGui")
    screen.Name = "GicaHubUI"
    screen.Parent = parent

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0,340,0,500)
    frame.Position = UDim2.new(0.5,-170,0.5,-250)
    frame.BackgroundColor3 = Color3.fromRGB(28,6,40)
    frame.Parent = screen

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1,-20,0,28)
    title.Position = UDim2.new(0,10,0,10)
    title.BackgroundTransparency = 1
    title.Text = "Gica Hub Pet-Hopper"
    title.TextColor3 = Color3.fromRGB(255,255,255)
    title.Font = Enum.Font.GothamBold
    title.TextSize = 18
    title.Parent = frame

    -- ScrollFrame für alle Pets
    local scrollFrame = Instance.new("ScrollingFrame")
    scrollFrame.Size = UDim2.new(1,-20,1,-80)
    scrollFrame.Position = UDim2.new(0,10,0,50)
    scrollFrame.CanvasSize = UDim2.new(0,0,0,#availablePets*35)
    scrollFrame.ScrollBarThickness = 8
    scrollFrame.BackgroundTransparency = 1
    scrollFrame.Parent = frame

    local uiListLayout = Instance.new("UIListLayout")
    uiListLayout.Parent = scrollFrame
    uiListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    uiListLayout.Padding = UDim.new(0,5)

    for i, petName in ipairs(availablePets) do
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1,0,0,28)
        btn.Text = petName
        btn.BackgroundColor3 = Color3.fromRGB(80,0,150)
        btn.TextColor3 = Color3.fromRGB(255,255,255)
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 16
        btn.Parent = scrollFrame

        btn.MouseButton1Click:Connect(function()
            Svt.SelectedPet = petName
            print("✅ Pet ausgewählt:", Svt.SelectedPet)
        end)
    end

    -- Start Button
    local finderBtn = Instance.new("TextButton")
    finderBtn.Size = UDim2.new(1,-20,0,32)
    finderBtn.Position = UDim2.new(0,10,1,-40)
    finderBtn.AnchorPoint = Vector2.new(0,0)
    finderBtn.Text = "Start Auto-Finder"
    finderBtn.BackgroundColor3 = Color3.fromRGB(0,150,80)
    finderBtn.TextColor3 = Color3.fromRGB(255,255,255)
    finderBtn.Font = Enum.Font.GothamBold
    finderBtn.TextSize = 16
    finderBtn.Parent = frame

    finderBtn.MouseButton1Click:Connect(startFinder)
end

-- =======================
-- Auto-Start beim Join
-- =======================
Players.PlayerAdded:Connect(function(player)
    if player == LP then
        wait(2)
        spawn(startFinder)
    end
end)

-- Start GUI & initial Finder Check
createUI()
spawn(startFinder)

print("✅ Gica Hub v5 Mobile Auto-Pet-Hopper ready. Script completed.")

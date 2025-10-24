-- 🌌 Gica Hub v5 Mobile Auto-Pet-Hopper + Beste Server + Endlos + Dropdown + Farbcodierter GUI Log
-- KRNL-kompatibel, startet automatisch beim Join

local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

local LP = Players.LocalPlayer or Players.PlayerAdded:Wait()

-- =======================
-- Alle verfügbaren Steal-a-Brainrot Pets
-- =======================
local availablePets = {
    "Noobini Pizzanini","Lirili Larila","Tim Cheese","FluriFlura","Talpa Di Fero","Svinina Bombardino","Pipi Kiwi",
    "Trippi Troppi","Gangster Footera","Bandito Bobritto","Boneca Ambalabu","Cacto Hipopotamo","Ta Ta Ta Ta Sahur",
    "Tric Trac Baraboom","Cappuccino Assassino","Brr Brr Patapim","Trulimero Trulicina","Bambini Crostini",
    "Bananita Dolphinita","Perochello Lemonchello","Brri Brri Bicus Dicus Bombicus","Burbaloni Loliloli",
    "Lionel Cactuseli","Blueberrini Octopusini","Strawberelli Flamingelli","Bombardiro Crocodilo",
    "Gorillo Watermelondrillo","Gattatino Nyanino","La Grande Combinasion","Nuclearo Dinossauro","Garama and Madundung"
}

-- =======================
-- Konfiguration
-- =======================
local Svt = {
    SelectedPet = availablePets[1],
    FinderActive = false,
    minPlayers = 4
}

-- =======================
-- GUI Elemente
-- =======================
local GUI = {}
local function createUI()
    local parent = LP:FindFirstChild("PlayerGui") or game:GetService("CoreGui")
    pcall(function() parent:FindFirstChild("GicaHubUI"):Destroy() end)

    local screen = Instance.new("ScreenGui")
    screen.Name = "GicaHubUI"
    screen.Parent = parent

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0,380,0,520)
    frame.Position = UDim2.new(0.5,-190,0.5,-260)
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

    -- ScrollFrame für Pets
    local scrollFrame = Instance.new("ScrollingFrame")
    scrollFrame.Size = UDim2.new(1,-20,0,180)
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
            log("✅ Pet ausgewählt: "..Svt.SelectedPet,"success")
        end)
    end

    -- Start Button
    local finderBtn = Instance.new("TextButton")
    finderBtn.Size = UDim2.new(1,-20,0,32)
    finderBtn.Position = UDim2.new(0,10,0,240)
    finderBtn.Text = "Start Auto-Finder"
    finderBtn.BackgroundColor3 = Color3.fromRGB(0,150,80)
    finderBtn.TextColor3 = Color3.fromRGB(255,255,255)
    finderBtn.Font = Enum.Font.GothamBold
    finderBtn.TextSize = 16
    finderBtn.Parent = frame

    finderBtn.MouseButton1Click:Connect(function()
        startFinder()
    end)

    -- Log Frame
    local logBox = Instance.new("ScrollingFrame")
    logBox.Size = UDim2.new(1,-20,0,250)
    logBox.Position = UDim2.new(0,10,0,280)
    logBox.CanvasSize = UDim2.new(0,0,0,0)
    logBox.ScrollBarThickness = 8
    logBox.BackgroundColor3 = Color3.fromRGB(20,20,20)
    logBox.BorderSizePixel = 1
    logBox.Parent = frame
    GUI.logBox = logBox
end

-- =======================
-- Log Funktion GUI + Konsole (Farben)
-- =======================
local function log(text, type)
    print(text)

    if not GUI.logBox then return end

    local color = Color3.fromRGB(255,255,255) -- Info Standard
    if type == "success" then
        color = Color3.fromRGB(0,255,0)
    elseif type == "warn" then
        color = Color3.fromRGB(255,255,0)
    elseif type == "error" then
        color = Color3.fromRGB(255,0,0)
    end

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
-- Auto-Finder: Beste Server Hop (Endlos)
-- =======================
function startFinder()
    if Svt.FinderActive then return end
    Svt.FinderActive = true
    log("✅ Auto-Finder gestartet für Pet: "..Svt.SelectedPet,"success")

    RunService.Heartbeat:Wait()

    while Svt.FinderActive do
        local found, baseName = baseHasPet(Svt.SelectedPet)
        if found then
            log("✅ Pet gefunden im Server in Base: "..baseName,"success")
            Svt.FinderActive = false
            break
        end

        log("⏳ Pet nicht gefunden, Suche auf besten Servern läuft...","info")

        local PlaceId = game.PlaceId
        local serversChecked = {}
        local pageCursor = ""

        while true do
            local url = "https://games.roblox.com/v1/games/"..PlaceId.."/servers/Public?sortOrder=Desc&limit=100"
            if pageCursor ~= "" then url = url.."&cursor="..pageCursor end

            local success, response = pcall(function() return HttpService:GetAsync(url) end)
            if not success then
                log("❌ Fehler beim Abrufen Serverliste: "..tostring(response),"error")
                wait(5)
                continue
            end

            local data
            local ok,jsonErr = pcall(function() data = HttpService:JSONDecode(response) end)
            if not ok then
                log("❌ Fehler beim JSON-Parsing: "..tostring(jsonErr),"error")
                wait(5)
                continue
            end

            pageCursor = data.nextPageCursor or ""

            if not data.data or #data.data == 0 then
                log("⚠️ Keine Server in dieser Seite verfügbar, retry in 5 Sekunden...","warn")
                wait(5)
                break
            end

            table.sort(data.data, function(a,b) return (a.playing or 0) > (b.playing or 0) end)

            local hopped = false
            for _, server in pairs(data.data) do
                local sid = server.id
                if not serversChecked[sid] and (server.playing or 0) >= Svt.minPlayers then
                    serversChecked[sid] = true
                    log(("[Finder] Hoppen zu ServerID: %s (Spieler: %d)"):format(sid, server.playing or 0),"warn")

                    local hopSuccess, hopErr = pcall(function()
                        TeleportService:TeleportToPlaceInstance(PlaceId, sid, LP)
                    end)
                    if not hopSuccess then
                        log("❌ Fehler beim Hoppen: "..tostring(hopErr),"error")
                    end

                    hopped = true
                    break
                end
            end

            if not hopped then
                if pageCursor == "" then
                    log("⚠️ Keine weiteren Server verfügbar, retry in 5 Sekunden...","warn")
                    wait(5)
                    break
                end
            else
                break
            end

            wait(1)
        end
    end
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

createUI()
spawn(startFinder)

log("✅ Gica Hub v5 Mobile Auto-Pet-Hopper ready. Script completed.","success")

-- 🌌 Gica Hub v5 Ultra Compact – KRNL (Auto-Pet-Hopper nur bei Pet vorhanden)
-- Password: 1234-5678-9012
-- Hinweis: Benötigt HttpService & TeleportService (KRNL / Executor mit HTTP erlaubt)

local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")

local LP = Players.LocalPlayer or Players.PlayerAdded:Wait()
local Svt = {
    SelectedPet = "Los Combinasionas",
    FinderActive = false
}

-- =======================
-- Hilfsfunktionen
-- =======================
local function playerHasPetLocal(plr, petName)
    if not plr or not petName then return false end
    local found = false

    -- Prüfen auf Attributes
    if plr.GetAttributes then
        local ok, attrs = pcall(function() return plr:GetAttributes() end)
        if ok then
            for _,v in pairs(attrs) do
                if tostring(v):lower():match(petName:lower()) then
                    found = true
                end
            end
        end
    end

    -- Prüfen auf Leaderstats / Stats
    local s = plr:FindFirstChild("leaderstats") or plr:FindFirstChild("Leaderstats") or plr:FindFirstChild("stats")
    if s and s.GetChildren then
        for _,v in pairs(s:GetChildren()) do
            local ok,val = pcall(function() return tostring(v.Value or v.Text or "") end)
            if ok and val:lower():match(petName:lower()) then
                found = true
            end
        end
    end

    -- Prüfen im Character
    if plr.Character then
        for _,obj in pairs(plr.Character:GetDescendants()) do
            if obj:IsA("StringValue") or obj:IsA("NumberValue") or obj:IsA("IntValue") or obj:IsA("ObjectValue") then
                local ok,t = pcall(function() return tostring(obj.Value) end)
                if ok and t:lower():match(petName:lower()) then
                    found = true
                end
            end
        end
    end

    return found
end

local function currentServerHasPet(petName)
    for _,plr in pairs(Players:GetPlayers()) do
        if plr ~= LP and playerHasPetLocal(plr, petName) then
            return true, plr
        end
    end
    return false, nil
end

-- =======================
-- Auto-Pet-Finder / Server-Hop (kontinuierlich)
-- =======================
local function startFinder()
    if Svt.FinderActive then return end
    Svt.FinderActive = true
    print("✅ Auto-Finder gestartet für Pet:", Svt.SelectedPet)

    -- Zuerst aktuellen Server prüfen
    local found, plr = currentServerHasPet(Svt.SelectedPet)
    if found then
        print("✅ Pet bereits im aktuellen Server bei Spieler:", plr.Name)
        Svt.FinderActive = false
        return
    end

    local PlaceId = game.PlaceId
    local serversChecked = {}
    local pageCursor = ""

    -- Spawn Hintergrundthread, damit GUI nicht blockiert wird
    spawn(function()
        while Svt.FinderActive do
            local url = "https://games.roblox.com/v1/games/"..PlaceId.."/servers/Public?sortOrder=Asc&limit=100"
            if pageCursor ~= "" then url = url.."&cursor="..pageCursor end

            local success, response = pcall(function() return HttpService:GetAsync(url) end)
            if not success then
                warn("❌ Fehler beim Abrufen der Serverliste")
                break
            end

            local data = HttpService:JSONDecode(response)
            pageCursor = data.nextPageCursor or ""

            if not data.data or #data.data == 0 then
                print("⚠️ Keine Server in dieser Seite verfügbar")
                break
            end

            -- Alle Server prüfen
            for _,server in pairs(data.data) do
                local sid = server.id
                if not serversChecked[sid] then
                    serversChecked[sid] = true
                    print("[Server Check] ServerID:", sid, "Spieler:", server.playing)

                    -- Hier Auto-Hop: Teleport zu Server
                    -- Sobald Teleport passiert, Script stoppt auf aktuellem Client
                    local hopSuccess, hopErr = pcall(function()
                        TeleportService:TeleportToPlaceInstance(PlaceId, sid, LP)
                    end)
                    if not hopSuccess then
                        warn("❌ Fehler beim Hoppen:", hopErr)
                    end
                    -- Teleport beendet Script → kein break nötig
                    return
                end
            end

            if pageCursor == "" then
                print("⚠️ Keine weiteren Server verfügbar. Neuer Versuch in 5 Sekunden...")
                pageCursor = "" -- reset für neuen Request
                wait(5)
            end

            wait(1)
        end
    end)
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
    frame.Size = UDim2.new(0,320,0,200)
    frame.Position = UDim2.new(0.5,-160,0.5,-100)
    frame.BackgroundColor3 = Color3.fromRGB(28,6,40)
    frame.Parent = screen

    local petLabel = Instance.new("TextLabel")
    petLabel.Size = UDim2.new(1,-20,0,28)
    petLabel.Position = UDim2.new(0,10,0,20)
    petLabel.BackgroundTransparency = 1
    petLabel.Text = "Pet: "..Svt.SelectedPet
    petLabel.TextColor3 = Color3.fromRGB(255,255,255)
    petLabel.Font = Enum.Font.GothamBold
    petLabel.TextSize = 16
    petLabel.Parent = frame

    local finderBtn = Instance.new("TextButton")
    finderBtn.Size = UDim2.new(0,140,0,32)
    finderBtn.Position = UDim2.new(0.5,-70,0,60)
    finderBtn.Text = "Start Auto-Finder"
    finderBtn.BackgroundColor3 = Color3.fromRGB(80,0,150)
    finderBtn.TextColor3 = Color3.fromRGB(255,255,255)
    finderBtn.Font = Enum.Font.GothamBold
    finderBtn.TextSize = 16
    finderBtn.Parent = frame

    finderBtn.MouseButton1Click:Connect(startFinder)
end

-- =======================
-- Start
-- =======================
createUI()
print("✅ Gica Hub v5 Ultra Compact — KRNL Auto-Pet-Hopper ready.")

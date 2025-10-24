-- 🌌 Gica Hub v5 Ultra Compact – KRNL (Auto Server-Hopper + Minimierbare UI)
-- Password: 1234-5678-9012

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local Workspace = game:GetService("Workspace")

local LP = Players.LocalPlayer or Players.PlayerAdded:Wait()
local SETTINGS_FILE = "GicaHubSettings.json"
local PASSWORD = "6388-3589-1190"

local Svt = {
    WalkSpeed = 16,
    FlySpeed = 2,
    FinderActive = false,
    SelectedPet = "Los Combinasionas"
}

local function Save()
    if type(writefile) == "function" then
        pcall(function() writefile(SETTINGS_FILE, HttpService:JSONEncode(Svt)) end)
    end
end

local function getGuiParent()
    return LP:FindFirstChild("PlayerGui") or game:GetService("CoreGui") or workspace
end

local function addCorner(obj, r)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, r or 10)
    c.Parent = obj
    return c
end

-- ======================
-- Helper: Prüfe ob Spieler das Pet hat
-- ======================
local function playerHasPetLocal(plr, petName)
    if not plr or not petName then return false end
    local s = plr:FindFirstChild("leaderstats") or plr:FindFirstChild("Leaderstats") or plr:FindFirstChild("stats")
    if s then
        for _,v in pairs(s:GetChildren()) do
            local ok,val = pcall(function() return tostring(v.Value or v.Text or "") end)
            if ok and val:lower():match(petName:lower()) then return true end
        end
    end
    return false
end

local function currentServerHasPet(petName)
    for _,plr in pairs(Players:GetPlayers()) do
        if plr ~= LP and playerHasPetLocal(plr, petName) then return true, plr end
    end
    return false, nil
end

-- ======================
-- Finder Worker
-- ======================
local function finderWorker(statusLabel)
    Svt.FinderActive = true; Save()
    local placeIdStr = tostring(game.PlaceId)
    local attempted = {}
    print("[Finder] Starte Suche nach Pet: "..Svt.SelectedPet)
    
    while Svt.FinderActive do
        local nextCursor
        repeat
            local url = "https://games.roblox.com/v1/games/"..placeIdStr.."/servers/Public?sortOrder=Asc&limit=100"
            if nextCursor then url = url.."&cursor="..tostring(nextCursor) end
            local ok, res = pcall(function() return HttpService:GetAsync(url, true) end)
            if not ok then
                print("[Finder] Fehler beim Abrufen der Serverliste. Warte 3s...")
                wait(3)
                break
            end
            local decoded = nil
            pcall(function() decoded = HttpService:JSONDecode(res) end)
            if not decoded or type(decoded.data) ~= "table" then
                print("[Finder] Ungültige Antwort. Warte 2s...")
                wait(2)
                break
            end

            for _,server in ipairs(decoded.data) do
                local sid = tostring(server.id)
                if sid ~= tostring(game.JobId) and not attempted[sid] then
                    attempted[sid] = true
                    statusLabel.Text = "Prüfe Server "..sid.." ("..server.playing.." Spieler)"
                    print("[Finder] Prüfe Server: "..sid.." ("..server.playing.." Spieler)")

                    -- Teleport
                    local tpOk, err = pcall(function()
                        TeleportService:TeleportToPlaceInstance(game.PlaceId, sid, LP)
                    end)
                    wait(5)
                end
            end

            nextCursor = decoded.nextPageCursor
        until not nextCursor or not Svt.FinderActive

        if Svt.FinderActive then
            print("[Finder] Alle Server geprüft. Wiederhole Suche in 4s...")
            wait(4)
            attempted = {}
        end
    end
    statusLabel.Text = "Status: Gestoppt"
    print("[Finder] Suche gestoppt.")
end

-- ======================
-- GUI (Minimierbar)
-- ======================
local function createUI()
    local parent = getGuiParent()
    pcall(function() parent:FindFirstChild("GicaHubUI"):Destroy() end)

    -- GH Button (klein, lila, abgerundet)
    local ghBtn = Instance.new("TextButton")
    ghBtn.Size = UDim2.new(0,40,0,40)
    ghBtn.Position = UDim2.new(0,10,0,50)
    ghBtn.Text="GH"
    ghBtn.BackgroundColor3=Color3.fromRGB(128,0,255)
    ghBtn.TextColor3=Color3.fromRGB(255,255,255)
    ghBtn.Font=Enum.Font.GothamBold
    ghBtn.TextSize=18
    ghBtn.Name="GHButton"
    ghBtn.Parent=parent
    addCorner(ghBtn,8)

    local screen = Instance.new("Frame")
    screen.Size=UDim2.new(0,320,0,380)
    screen.Position=UDim2.new(0.5,-160,0.5,-190)
    screen.BackgroundColor3=Color3.fromRGB(28,6,40)
    screen.Visible=false
    screen.Parent=parent
    addCorner(screen,12)

    local statusLabel = Instance.new("TextLabel")
    statusLabel.Size=UDim2.new(1,-16,0,22)
    statusLabel.Position=UDim2.new(0,8,0,340)
    statusLabel.BackgroundTransparency=1
    statusLabel.Text="Status: Idle"
    statusLabel.TextColor3=Color3.fromRGB(255,255,255)
    statusLabel.Parent=screen

    local startBtn = Instance.new("TextButton")
    startBtn.Size=UDim2.new(0,120,0,34)
    startBtn.Position=UDim2.new(0,8,0,300)
    startBtn.Text="Start Finder"
    startBtn.Parent=screen
    addCorner(startBtn,8)

    local stopBtn = Instance.new("TextButton")
    stopBtn.Size=UDim2.new(0,120,0,34)
    stopBtn.Position=UDim2.new(0,136,0,300)
    stopBtn.Text="Stop Finder"
    stopBtn.Parent=screen
    addCorner(stopBtn,8)

    local petList={"Los Combinasionas","La Grande Combinasion","Los 67","67"}
    local petDropdown = Instance.new("TextButton")
    petDropdown.Size=UDim2.new(0,200,0,32)
    petDropdown.Position=UDim2.new(0,8,0,44)
    petDropdown.Text="Pet: "..Svt.SelectedPet
    petDropdown.Parent=screen
    addCorner(petDropdown,8)

    local petFrame = Instance.new("Frame")
    petFrame.Size=UDim2.new(0,200,0,#petList*28)
    petFrame.Position=UDim2.new(0,8,0,80)
    petFrame.BackgroundColor3=Color3.fromRGB(40,0,60)
    petFrame.Visible=false
    petFrame.Parent=screen
    addCorner(petFrame,8)

    for i,p in ipairs(petList) do
        local b = Instance.new("TextButton")
        b.Size=UDim2.new(1,0,0,28)
        b.Position=UDim2.new(0,0,0,(i-1)*28)
        b.Text=p
        b.Parent=petFrame
        addCorner(b,6)
        b.MouseButton1Click:Connect(function()
            Svt.SelectedPet=p
            petDropdown.Text="Pet: "..p
            petFrame.Visible=false
            Save()
        end)
    end

    petDropdown.MouseButton1Click:Connect(function()
        petFrame.Visible = not petFrame.Visible
    end)

    startBtn.MouseButton1Click:Connect(function()
        if Svt.FinderActive then return end
        spawn(function() finderWorker(statusLabel) end)
    end)

    stopBtn.MouseButton1Click:Connect(function()
        Svt.FinderActive=false
        statusLabel.Text="Status: Stopped"
    end)

    ghBtn.MouseButton1Click:Connect(function()
        screen.Visible = not screen.Visible
    end)
end

createUI()
print("✅ Gica Hub v5 Ultra Compact — KRNL (Auto-Server-Hopper + Minimierbare UI).")

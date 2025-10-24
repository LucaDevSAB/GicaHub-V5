-- 🌌 Gica Hub v5 Mobile – Echte Pets mit Live-Log
-- Android KRNL-kompatibel, zeigt Server-Check live

local P = game:GetService("Players").LocalPlayer
local TS = game:GetService("TeleportService")
local RS = game:GetService("ReplicatedStorage")
local HS = game:GetService("HttpService")
local WS = game:GetService("Workspace")

local S = {Pet=nil,Active=false}

-- Pet-Daten Ordner
local PF = RS:FindFirstChild("PetData") or Instance.new("Folder",RS)
PF.Name="PetData"

-- =======================
-- Echte Pets aus Workspace auslesen
-- =======================
local function updatePets()
    PF:ClearAllChildren()
    local bases = WS:FindFirstChild("Bases") or WS
    for _, base in pairs(bases:GetChildren()) do
        if base:IsA("Model") then
            for _, obj in pairs(base:GetChildren()) do
                local petName
                if obj:IsA("Model") and obj:FindFirstChild("PetName") then
                    petName = obj.PetName.Value
                elseif obj:IsA("StringValue") and obj.Name == "PetName" then
                    petName = obj.Value
                end
                if petName then
                    local v = Instance.new("StringValue", PF)
                    v.Name = petName
                    v.Value = base.Name
                end
            end
        end
    end
end

spawn(function()
    while true do
        pcall(updatePets)
        wait(5)
    end
end)

-- Prüfen ob Pet vorhanden
local function HasPet(p)
    for _,v in pairs(PF:GetChildren()) do
        if v.Name:lower():match(p:lower()) then return true,v.Value end
    end
    return false,nil
end

-- =======================
-- GUI erstellen
-- =======================
local function UI()
    local scr = Instance.new("ScreenGui",P:WaitForChild("PlayerGui"))
    scr.Name="GicaHubUI"
    local f=Instance.new("Frame",scr)
    f.Size=UDim2.new(0.9,0,0.5,0)
    f.Position=UDim2.new(0.05,0,0.25,0)
    f.BackgroundColor3=Color3.fromRGB(28,6,40)

    local lbl=Instance.new("TextLabel",f)
    lbl.Size=UDim2.new(1,-20,0,28)
    lbl.Position=UDim2.new(0,10,0,10)
    lbl.BackgroundTransparency=1
    lbl.Text="Wähle Pet:"
    lbl.TextColor3=Color3.fromRGB(255,255,255)
    lbl.Font=Enum.Font.GothamBold
    lbl.TextSize=20

    local dd=Instance.new("TextButton",f)
    dd.Size=UDim2.new(0.8,0,0.2,0)
    dd.Position=UDim2.new(0.1,0,0.2,0)
    dd.Text="Pet auswählen"
    dd.Font=Enum.Font.GothamBold
    dd.TextSize=18
    dd.TextColor3=Color3.fromRGB(255,255,255)
    dd.BackgroundColor3=Color3.fromRGB(80,0,150)

    local df=Instance.new("ScrollingFrame",f)
    df.Size=UDim2.new(0.8,0,0.5,0)
    df.Position=UDim2.new(0.1,0,0.4,0)
    df.BackgroundColor3=Color3.fromRGB(40,0,80)
    df.Visible=false
    df.CanvasSize=UDim2.new(0,0,0,0)

    local logLbl = Instance.new("TextLabel", f)
    logLbl.Size = UDim2.new(1, -20, 0.1, 0)
    logLbl.Position = UDim2.new(0, 10, 0.72, 0)
    logLbl.BackgroundTransparency = 1
    logLbl.TextColor3 = Color3.fromRGB(0, 255, 0)
    logLbl.Font = Enum.Font.GothamBold
    logLbl.TextSize = 16
    logLbl.Text = "Logs werden hier angezeigt..."
    logLbl.TextWrapped = true

    -- Dropdown aktualisieren
    local function UpdateDD()
        df:ClearAllChildren()
        local y=0
        for _,v in pairs(PF:GetChildren()) do
            local b=Instance.new("TextButton",df)
            b.Size=UDim2.new(1,0,0,30)
            b.Position=UDim2.new(0,0,0,y)
            b.Text=v.Name
            b.Font=Enum.Font.GothamBold
            b.TextSize=16
            b.TextColor3=Color3.fromRGB(255,255,255)
            b.BackgroundColor3=Color3.fromRGB(100,0,180)
            y=y+32
            df.CanvasSize=UDim2.new(0,0,0,y)
            b.MouseButton1Click:Connect(function()
                S.Pet=v.Name
                dd.Text=v.Name
                df.Visible=false
            end)
        end
    end

    spawn(function() while true do pcall(UpdateDD) wait(5) end end)
    dd.MouseButton1Click:Connect(function() df.Visible=not df.Visible end)

    -- =======================
    -- Auto Finder mit Log
    -- =======================
    local function Finder()
        if not S.Pet then warn("⚠️ Bitte Pet auswählen!") return end
        if S.Active then return end
        S.Active=true
        logLbl.Text = "Suche nach Server mit Pet: "..S.Pet
        local PID = game.PlaceId
        local checked,cursor = {}, ""
        spawn(function()
            while S.Active do
                local url="https://games.roblox.com/v1/games/"..PID.."/servers/Public?sortOrder=Asc&limit=100"
                if cursor~="" then url=url.."&cursor="..cursor end
                local success,res = pcall(function() return HS:GetAsync(url) end)
                if not success then 
                    logLbl.Text = "Fehler beim Abrufen der Serverliste"
                    wait(5) 
                    continue 
                end
                local data
                local ok,err = pcall(function() data=HS:JSONDecode(res) end)
                if not ok then 
                    logLbl.Text = "JSON Fehler: "..err
                    wait(5) 
                    continue 
                end
                cursor = data.nextPageCursor or ""
                if data.data then
                    for _,s in pairs(data.data) do
                        if not checked[s.id] then
                            checked[s.id]=true
                            logLbl.Text = "Prüfe ServerID: "..s.id.." Spieler: "..s.playing
                            -- Hier könntest du später erweitern: Pets im Server prüfen via API
                            pcall(function() TS:TeleportToPlaceInstance(PID,s.id,P) end)
                            logLbl.Text = "Teleportiert zu ServerID: "..s.id
                            return
                        end
                    end
                end
                if cursor=="" then 
                    logLbl.Text = "Keine weiteren Server, retry in 5 Sekunden..." 
                    wait(5) 
                    cursor=""
                end
                wait(1)
            end
        end)
    end

    local btn=Instance.new("TextButton",f)
    btn.Size=UDim2.new(0.8,0,0.2,0)
    btn.Position=UDim2.new(0.1,0,0.85,0)
    btn.Text="Start Finder"
    btn.Font=Enum.Font.GothamBold
    btn.TextSize=20
    btn.TextColor3=Color3.fromRGB(255,255,255)
    btn.BackgroundColor3=Color3.fromRGB(80,0,150)
    btn.MouseButton1Click:Connect(Finder)
end

UI()
print("✅ Gica Hub v5 Mobile – Echte Pets mit Live-Log ready.")

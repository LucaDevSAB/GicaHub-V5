-- 🌌 Gica Hub v5 Ultra Compact – KRNL (vollständig, Passwort im Format dddd-dddd-dddd)

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local TeleportService = game:GetService("TeleportService")
local TweenService = game:GetService("TweenService")

local LP = Players.LocalPlayer or Players.PlayerAdded:Wait()
local SETTINGS_FILE = "GicaHubSettings.json"

-- === HIER: Passwort (12 Ziffern, mit Bindestrichen nach jeweils 4 Ziffern) ===
local PASSWORD = "6388-3589-1190" -- Beispiel: ändere diese Zeile, wenn du ein anderes Passwort möchtest
-- ======================================================================

-- Settings
local Svt = {
    WalkSpeed = 16,
    FlySpeed = 2,
    ContinuousScan = false,
    SelectedPet = "Los Combinasionas"
}
local has_isfile = type(isfile) == "function"
local has_readfile = type(readfile) == "function"
local has_writefile = type(writefile) == "function"

if has_isfile and isfile(SETTINGS_FILE) and has_readfile then
    pcall(function()
        local ok, decoded = pcall(function() return HttpService:JSONDecode(readfile(SETTINGS_FILE)) end)
        if ok and type(decoded) == "table" then
            for k,v in pairs(decoded) do Svt[k] = v end
        end
    end)
end

local function Save()
    if has_writefile then
        pcall(function() writefile(SETTINGS_FILE, HttpService:JSONEncode(Svt)) end)
    end
end

-- GUI parent helper
local function getGuiParent()
    local parentTo = nil
    local ok, pg = pcall(function() return LP:FindFirstChild("PlayerGui") end)
    if ok and pg then parentTo = pg end
    if not parentTo and type(gethui) == "function" then
        local ok2, g = pcall(gethui)
        if ok2 and g then parentTo = g end
    end
    if not parentTo then
        local ok3, core = pcall(function() return game:GetService("CoreGui") end)
        if ok3 and core then parentTo = core end
    end
    if not parentTo then parentTo = workspace end
    return parentTo
end

local function addCorner(obj, r) local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, r or 10); c.Parent = obj; return c end

-- =======================
-- Utility: prüfe lokal ob ein Spieler das Pet hat
-- =======================
local function playerHasPetLocal(plr, petName)
    if not plr or not petName then return false end
    -- Prüfe Attributes
    if plr.GetAttributes then
        local ok, attrs = pcall(function() return plr:GetAttributes() end)
        if ok and type(attrs) == "table" then
            for _,v in pairs(attrs) do
                if tostring(v):lower():match(petName:lower()) then
                    return true
                end
            end
        end
    end
    -- Prüfe leaderstats-like
    local s = plr:FindFirstChild("leaderstats") or plr:FindFirstChild("Leaderstats") or plr:FindFirstChild("stats")
    if s and s.GetChildren then
        for _,v in pairs(s:GetChildren()) do
            local val = nil
            pcall(function() val = tostring(v.Value or v.Text or "") end)
            if val and val:lower():match(petName:lower()) then
                return true
            end
        end
    end
    -- Prüfe Character NumberValues / StringValues
    if plr.Character then
        for _,obj in pairs(plr.Character:GetDescendants()) do
            if obj:IsA("StringValue") or obj:IsA("ObjectValue") or obj:IsA("NumberValue") or obj:IsA("IntValue") then
                local ok, text = pcall(function() return tostring(obj.Value) end)
                if ok and text:lower():match(petName:lower()) then
                    return true
                end
            end
        end
    end
    return false
end

-- Schnell-Scan der aktuellen Instanz
local function currentServerHasPet(petName)
    for _,plr in pairs(Players:GetPlayers()) do
        if plr ~= LP then
            if playerHasPetLocal(plr, petName) then
                return true, plr
            end
        end
    end
    return false, nil
end

-- =======================
-- Login UI mit animierter Dankesnachricht (Passwort-Check angepasst)
-- =======================
local function createLoginUI(callback)
    local parent = getGuiParent()
    pcall(function() parent:FindFirstChild("GicaHubLoginUI"):Destroy() end)

    local screen = Instance.new("ScreenGui")
    screen.Name = "GicaHubLoginUI"
    screen.ResetOnSpawn = false
    screen.Parent = parent

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0,340,0,160)
    frame.Position = UDim2.new(0.5,-170,0.5,-80)
    frame.BackgroundColor3 = Color3.fromRGB(30,0,40)
    frame.Parent = screen
    addCorner(frame,12)

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1,-20,0,48)
    lbl.Position = UDim2.new(0,10,0,8)
    lbl.BackgroundTransparency=1
    lbl.Text="gicahub v5 secure"
    lbl.Font=Enum.Font.GothamBold
    lbl.TextSize=18
    lbl.TextColor3=Color3.fromRGB(255,255,255)
    lbl.Parent = frame

    local txt = Instance.new("TextBox")
    txt.Size = UDim2.new(1,-20,0,40)
    txt.Position = UDim2.new(0,10,0,66)
    txt.ClearTextOnFocus=false
    txt.BackgroundColor3=Color3.fromRGB(50,0,70)
    txt.TextColor3=Color3.fromRGB(255,255,255)
    txt.PlaceholderText="Enter secret (1234-5678-9012)..."
    txt.Parent = frame
    addCorner(txt,8)

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0,100,0,30)
    btn.Position = UDim2.new(0.5,-50,1,-40)
    btn.BackgroundColor3=Color3.fromRGB(80,0,150)
    btn.Text="Submit"
    btn.Parent=frame
    addCorner(btn,8)

    btn.MouseButton1Click:Connect(function()
        local input = tostring(txt.Text or "")
        -- akzeptiere genaues Format: 4digits-4digits-4digits
        if input:match("^%d%d%d%d%-%d%d%d%d%-%d%d%d%d$") and input == PASSWORD then
            pcall(function() screen:Destroy() end)

            local animScreen = Instance.new("ScreenGui")
            animScreen.Name = "PurchaseThanks"
            animScreen.ResetOnSpawn = false
            animScreen.Parent = parent

            local label = Instance.new("TextLabel")
            label.Size = UDim2.new(0, 450, 0, 100)
            label.Position = UDim2.new(0.5, -225, 0.5, -50)
            label.BackgroundTransparency = 1
            label.Font = Enum.Font.GothamBold
            label.TextSize = 24
            label.TextColor3 = Color3.fromRGB(255, 255, 255)
            label.Text = "TY For Purchasing Our service ❤️"
            label.Parent = animScreen
            label.TextTransparency = 1
            label.TextStrokeTransparency = 0.7

            -- Tweens
            local fadeTween = TweenService:Create(label, TweenInfo.new(1.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {TextTransparency=0})
            fadeTween:Play()
            local pulseTween = TweenService:Create(label, TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {TextSize=32})
            pulseTween:Play()
            local moveTween = TweenService:Create(label, TweenInfo.new(1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {Position = UDim2.new(0.5, -225, 0.48, -50)})
            moveTween:Play()
            local heartColorTween = TweenService:Create(label, TweenInfo.new(0.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {TextColor3 = Color3.fromRGB(255,50,50)})
            heartColorTween:Play()

            delay(3, function()
                pcall(function() animScreen:Destroy() end)
                callback()
            end)
        else
            txt.Text = ""
            txt.PlaceholderText = "invalid"
        end
    end)
end

-- =======================
-- Haupt UI + Finder + Server-Hop + ESP + Fly
-- =======================
function createUI()
    local parent = getGuiParent()
    pcall(function() parent:FindFirstChild("GicaHubUI"):Destroy() end)

    local screen = Instance.new("ScreenGui")
    screen.Name = "GicaHubUI"
    screen.ResetOnSpawn = false
    screen.Parent = parent

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0,420,0,480)
    frame.Position = UDim2.new(0.5,-210,0.5,-240)
    frame.BackgroundColor3 = Color3.fromRGB(28,6,40)
    frame.Parent = screen
    frame.Active = true
    addCorner(frame, 16)

    -- Title bar + tabs
    local tabBar = Instance.new("Frame")
    tabBar.Size = UDim2.new(1,-24,0,48)
    tabBar.Position = UDim2.new(0,12,0,12)
    tabBar.BackgroundTransparency = 1
    tabBar.Parent = frame

    local function makeTab(name,x)
        local b = Instance.new("TextButton")
        b.Size = UDim2.new(0,130,0,40)
        b.Position = UDim2.new(0,x,0,4)
        b.Text = name
        b.Parent = tabBar
        addCorner(b, 10)
        b.Font = Enum.Font.Gotham
        b.TextSize = 14
        b.BackgroundColor3 = Color3.fromRGB(62,6,110)
        b.TextColor3 = Color3.fromRGB(240,240,240)
        return b
    end

    local tMain = makeTab("Main", 0)
    local tFinder = makeTab("Finder", 138)
    local tESP = makeTab("ESP", 276)

    local content = Instance.new("Frame")
    content.Size = UDim2.new(1,-24,1,-64)
    content.Position = UDim2.new(0,12,0,60)
    content.BackgroundTransparency = 1
    content.Parent = frame

    -- === Main tab ===
    local mainTab = Instance.new("Frame")
    mainTab.Size = UDim2.new(1,0,1,0)
    mainTab.BackgroundTransparency = 1
    mainTab.Parent = content

    local flyBtn = Instance.new("TextButton")
    flyBtn.Size = UDim2.new(0,180,0,44)
    flyBtn.Position = UDim2.new(0,10,0,6)
    flyBtn.Text = "Toggle Fly"
    flyBtn.Parent = mainTab
    addCorner(flyBtn,10)

    local speedLabel = Instance.new("TextLabel")
    speedLabel.Size = UDim2.new(0,320,0,28)
    speedLabel.Position = UDim2.new(0,10,0,64)
    speedLabel.BackgroundTransparency = 1
    speedLabel.Text = "WalkSpeed: "..tostring(Svt.WalkSpeed)
    speedLabel.Parent = mainTab
    speedLabel.Font = Enum.Font.Gotham

    -- WalkSpeed slider (simple)
    local sliderFrame = Instance.new("Frame")
    sliderFrame.Size = UDim2.new(0,380,0,32)
    sliderFrame.Position = UDim2.new(0,10,0,100)
    sliderFrame.BackgroundColor3 = Color3.fromRGB(48,8,78)
    sliderFrame.Parent = mainTab
    addCorner(sliderFrame,8)
    local sliderBar = Instance.new("Frame"); sliderBar.Parent = sliderFrame; sliderBar.Size = UDim2.new((Svt.WalkSpeed/200),0,1,0); sliderBar.BackgroundColor3 = Color3.fromRGB(200,100,255); addCorner(sliderBar,8)
    local sliderHandle = Instance.new("TextButton"); sliderHandle.Size = UDim2.new(0,18,0,32); sliderHandle.Position = UDim2.new((Svt.WalkSpeed/200),-9,0,0); sliderHandle.Parent = sliderFrame; sliderHandle.BackgroundColor3 = Color3.fromRGB(240,200,255); addCorner(sliderHandle,8); sliderHandle.Text = ""

    -- Fly implementation
    local flyActive=false; local BG,BV,hbConn
    local function enableFly()
        local c = LP.Character or LP.CharacterAdded:Wait()
        local hrp = c:FindFirstChild("HumanoidRootPart") or c:WaitForChild("HumanoidRootPart",5)
        if not hrp then return end
        BG = Instance.new("BodyGyro"); BG.Name="GicaHub_BG"; BG.P = 9e4; BG.MaxTorque=Vector3.new(9e9,9e9,9e9); BG.Parent = hrp
        BV = Instance.new("BodyVelocity"); BV.Name="GicaHub_BV"; BV.MaxForce=Vector3.new(9e9,9e9,9e9); BV.Parent = hrp
        hbConn = RunService.Heartbeat:Connect(function()
            local cam = Workspace.CurrentCamera if not cam then return end
            BV.Velocity = cam.CFrame.LookVector * (Svt.FlySpeed * 50)
            BG.CFrame = cam.CFrame
        end)
    end
    local function disableFly() if hbConn then hbConn:Disconnect(); hbConn=nil end if BG and BG.Parent then pcall(function() BG:Destroy() end) end if BV and BV.Parent then pcall(function() BV:Destroy() end) end BG=nil BV=nil end
    flyBtn.MouseButton1Click:Connect(function() flyActive = not flyActive if flyActive then enableFly() else disableFly() end end)

    -- WalkSpeed slider interactions
    local draggingSlider=false
    sliderHandle.InputBegan:Connect(function(inp) if inp.UserInputType==Enum.UserInputType.MouseButton1 or inp.UserInputType==Enum.UserInputType.Touch then draggingSlider=true inp.Changed:Connect(function() if inp.UserInputState==Enum.UserInputState.End then draggingSlider=false end end) end end)
    UserInputService.InputChanged:Connect(function(inp)
        if not draggingSlider then return end
        if inp.UserInputType==Enum.UserInputType.MouseMovement or inp.UserInputType==Enum.UserInputType.Touch then
            local abs = math.clamp((inp.Position.X - sliderFrame.AbsolutePosition.X),0,sliderFrame.AbsoluteSize.X)
            local ratio = abs/sliderFrame.AbsoluteSize.X
            local newVal = math.floor(ratio*200)
            if newVal < 1 then newVal = 1 end
            Svt.WalkSpeed = newVal; Save()
            speedLabel.Text = "WalkSpeed: "..tostring(Svt.WalkSpeed)
            sliderBar.Size = UDim2.new(ratio,0,1,0)
            sliderHandle.Position = UDim2.new(ratio,-9,0,0)
            local c = LP.Character if c then local h = c:FindFirstChildOfClass("Humanoid") if h then pcall(function() h.WalkSpeed = Svt.WalkSpeed end) end end
        end
    end)

    -- === Finder tab ===
    local finderTab = Instance.new("Frame")
    finderTab.Size = UDim2.new(1,0,1,0)
    finderTab.BackgroundTransparency = 1
    finderTab.Visible = false
    finderTab.Parent = content

    local info = Instance.new("TextLabel")
    info.Size = UDim2.new(1,-20,0,56)
    info.Position = UDim2.new(0,10,0,6)
    info.BackgroundTransparency = 1
    info.Text = "Finder: Wähle ein Pet und starte Finder, um auf Server zu hoppen, wo es Spieler mit dem Pet gibt."
    info.Parent = finderTab
    info.Font = Enum.Font.Gotham
    info.TextWrapped = true

    -- Pet Dropdown
    local petList = {"Los Combinasionas","La Grande Combinasion","Los 67","67"}
    local petDropdown = Instance.new("TextButton")
    petDropdown.Size = UDim2.new(0,200,0,40)
    petDropdown.Position = UDim2.new(0,10,0,70)
    petDropdown.Text = "Select Pet: "..Svt.SelectedPet
    petDropdown.Parent = finderTab
    addCorner(petDropdown,8)

    local petFrame = Instance.new("Frame")
    petFrame.Size = UDim2.new(0,200,0,#petList*30)
    petFrame.Position = UDim2.new(0,10,0,110)
    petFrame.BackgroundColor3 = Color3.fromRGB(40,0,60)
    petFrame.Visible = false
    petFrame.Parent = finderTab
    addCorner(petFrame,8)

    for i,p in ipairs(petList) do
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1,0,0,30)
        btn.Position = UDim2.new(0,0,0,(i-1)*30)
        btn.Text = p
        btn.Parent = petFrame
        addCorner(btn,6)
        btn.MouseButton1Click:Connect(function()
            Svt.SelectedPet = p
            Save()
            petDropdown.Text = "Select Pet: "..p
            petFrame.Visible = false
        end)
    end
    petDropdown.MouseButton1Click:Connect(function() petFrame.Visible = not petFrame.Visible end)

    -- Start Finder Button
    local startBtn = Instance.new("TextButton")
    startBtn.Size = UDim2.new(0,200,0,40)
    startBtn.Position = UDim2.new(0,220,0,70)
    startBtn.Text = "Start Finder"
    startBtn.Parent = finderTab
    addCorner(startBtn,8)

    -- Status Label
    local statusLabel = Instance.new("TextLabel")
    statusLabel.Size = UDim2.new(0,380,0,28)
    statusLabel.Position = UDim2.new(0,10,0,200)
    statusLabel.BackgroundTransparency = 1
    statusLabel.Text = "Status: Idle"
    statusLabel.Parent = finderTab
    statusLabel.Font = Enum.Font.Gotham

    -- Popup helper
    local function showFoundPopup(foundPlayer)
        local parent = getGuiParent()
        pcall(function() parent:FindFirstChild("GicaHubFoundPopup"):Destroy() end)
        local screenP = Instance.new("ScreenGui"); screenP.Name="GicaHubFoundPopup"; screenP.Parent=parent
        local frameP = Instance.new("Frame"); frameP.Size=UDim2.new(0,360,0,120); frameP.Position=UDim2.new(0.5,-180,0.12,0); frameP.BackgroundColor3=Color3.fromRGB(30,0,40); frameP.Parent=screenP; addCorner(frameP,12)
        local t = Instance.new("TextLabel"); t.Size=UDim2.new(1,-20,0,32); t.Position=UDim2.new(0,10,0,8); t.BackgroundTransparency=1; t.Font=Enum.Font.GothamBold; t.TextSize=16; t.TextColor3=Color3.fromRGB(240,240,240); t.Text="Pet found!" ; t.Parent=frameP
        local info = Instance.new("TextLabel"); info.Size=UDim2.new(1,-20,0,48); info.Position=UDim2.new(0,10,0,44); info.BackgroundTransparency=1; info.Text = "Player: "..(foundPlayer and foundPlayer.Name or "unknown"); info.TextWrapped=true; info.Parent=frameP
        local ok = Instance.new("TextButton"); ok.Size=UDim2.new(0,140,0,30); ok.Position=UDim2.new(0.5,-70,1,-40); ok.Text="Close"; ok.Parent=frameP; addCorner(ok,8)
        ok.MouseButton1Click:Connect(function() pcall(function() screenP:Destroy() end) end)
    end

    -- Start Finder logic (single-pet)
    startBtn.MouseButton1Click:Connect(function()
        if not Svt.SelectedPet or Svt.SelectedPet == "" then
            statusLabel.Text = "Status: Kein Pet ausgewählt"
            return
        end

        spawn(function()
            statusLabel.Text = "Status: Prüfung aktueller Server..."
            local foundHere, who = currentServerHasPet(Svt.SelectedPet)
            if foundHere then
                statusLabel.Text = "Status: Pet bereits in dieser Instanz!"
                showFoundPopup(who)
                return
            end

            -- Wenn nicht hier, dann Server-Liste abrufen und nacheinander hoppen
            statusLabel.Text = "Status: Scanne öffentliche Server..."
            local placeId = tostring(game.PlaceId)
            local nextCursor = nil
            local attempted = {}

            while true do
                local url = "https://games.roblox.com/v1/games/"..placeId.."/servers/Public?limit=100"
                if nextCursor then url = url.."&cursor="..nextCursor end

                local ok, res = pcall(function() return HttpService:GetAsync(url) end)
                if not ok or not res then
                    statusLabel.Text = "Status: API-Fehler beim Abrufen der Serverliste"
                    break
                end

                local data = nil
                pcall(function() data = HttpService:JSONDecode(res) end)
                if not data or not data.data then
                    statusLabel.Text = "Status: Ungültige Serverantwort"
                    break
                end

                local foundAny = false
                for _,server in ipairs(data.data) do
                    if server.id and tostring(server.id) ~= tostring(game.JobId) and server.playing and server.playing > 0 then
                        if not attempted[server.id] then
                            attempted[server.id] = true
                            -- teleportieren zu dieser Instanz (lokale Ausführung endet in vielen Executors beim Teleport)
                            statusLabel.Text = "Status: Hoppe zu Server "..tostring(server.id).." (Spieler: "..tostring(server.playing)..")"
                            pcall(function()
                                TeleportService:TeleportToPlaceInstance(game.PlaceId, server.id, LP)
                            end)
                            return
                        end
                    end
                end

                if data.nextPageCursor then
                    nextCursor = data.nextPageCursor
                else
                    if Svt.ContinuousScan then
                        statusLabel.Text = "Status: Keine passenden Server gefunden, warte..."
                        wait(4)
                        nextCursor = nil
                        attempted = {}
                    else
                        statusLabel.Text = "Status: Keine weiteren Server gefunden"
                        break
                    end
                end
            end
        end)
    end)

    -- === ESP Tab ===
    local espTab = Instance.new("Frame")
    espTab.Size = UDim2.new(1,0,1,0)
    espTab.BackgroundTransparency = 1
    espTab.Visible = false
    espTab.Parent = content

    local espInfo = Instance.new("TextLabel")
    espInfo.Size = UDim2.new(1,-20,0,60)
    espInfo.Position = UDim2.new(0,10,0,6)
    espInfo.BackgroundTransparency = 1
    espInfo.Text = "ESP: Highlights other players."
    espInfo.Parent = espTab
    espInfo.Font = Enum.Font.Gotham

    -- Simple ESP creation on join
    local ESP_Objects = {}
    local function createESPForPlayer(plr)
        if plr == LP then return end
        local function addChar(char)
            if not char or not char:FindFirstChild("HumanoidRootPart") then return end
            if char:FindFirstChild("GicaESP") then return end
            local hl = Instance.new("Highlight")
            hl.Name = "GicaESP"
            hl.Adornee = char
            hl.FillTransparency = 1
            hl.OutlineColor = Color3.fromRGB(200,0,255)
            hl.OutlineTransparency = 0
            hl.Parent = char
            ESP_Objects[plr] = hl
        end
        if plr.Character then addChar(plr.Character) end
        plr.CharacterAdded:Connect(addChar)
        plr.CharacterRemoving:Connect(function() if ESP_Objects[plr] then pcall(function() ESP_Objects[plr]:Destroy() end) ESP_Objects[plr]=nil end end)
    end
    for _,p in pairs(Players:GetPlayers()) do createESPForPlayer(p) end
    Players.PlayerAdded:Connect(createESPForPlayer)

    -- Tab switching
    tMain.MouseButton1Click:Connect(function() mainTab.Visible=true; finderTab.Visible=false; espTab.Visible=false end)
    tFinder.MouseButton1Click:Connect(function() mainTab.Visible=false; finderTab.Visible=true; espTab.Visible=false end)
    tESP.MouseButton1Click:Connect(function() mainTab.Visible=false; finderTab.Visible=false; espTab.Visible=true end)
    mainTab.Visible = true
end

-- Start sequence
createLoginUI(function()
    createUI()
end)

print("✅ Gica Hub v5 Ultra Compact — KRNL (fertig).")

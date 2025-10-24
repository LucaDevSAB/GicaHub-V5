-- 🌌 Gica Hub v5 Ultra Compact – KRNL (Auto Server-Hopper, Stop, kompakte UI, anim Login)
-- Password: 1234-5678-9012
-- Hinweis: Benötigt HttpService & TeleportService (KRNL / Executor mit HTTP erlaubt)

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local Workspace = game:GetService("Workspace")
local TeleportService = game:GetService("TeleportService")
local TweenService = game:GetService("TweenService")

local LP = Players.LocalPlayer or Players.PlayerAdded:Wait()
local SETTINGS_FILE = "GicaHubSettings.json"

-- === Passwort (12 Ziffern, 4-4-4) ===
local PASSWORD = "6388-3589-1190"

-- Settings
local Svt = {
WalkSpeed = 16,
FlySpeed = 2,
ContinuousScan = false,
SelectedPet = "Los Combinasionas",
FinderActive = false
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
pcall(function() parentTo = LP:FindFirstChild("PlayerGui") end)
if not parentTo and type(gethui) == "function" then
pcall(function() parentTo = gethui() end)
end
if not parentTo then
pcall(function() parentTo = game:GetService("CoreGui") end)
parentTo = game:GetService("CoreGui")
end
if not parentTo then parentTo = workspace end
return parentTo
end

local function addCorner(obj, r) local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, r or 8); c.Parent = obj; return c end

-- =======================
-- Helper: prüfe lokal ob Spieler Pet hat
-- =======================
local function playerHasPetLocal(plr, petName)
if not plr or not petName then return false end
-- Attributes
if plr.GetAttributes then
local ok, attrs = pcall(function() return plr:GetAttributes() end)
if ok and type(attrs) == "table" then
for _,v in pairs(attrs) do
if tostring(v):lower():match(petName:lower()) then return true end
end
end
end
-- leaderstats-like
local s = plr:FindFirstChild("leaderstats") or plr:FindFirstChild("Leaderstats") or plr:FindFirstChild("stats")
if s and s.GetChildren then
for _,v in pairs(s:GetChildren()) do
local ok, val = pcall(function() return tostring(v.Value or v.Text or "") end)
if ok and val:lower():match(petName:lower()) then return true end
end
end
-- Character descendants (StringValue, NumberValue, etc.)
if plr.Character then
for _,obj in pairs(plr.Character:GetDescendants()) do
if obj:IsA("StringValue") or obj:IsA("NumberValue") or obj:IsA("IntValue") or obj:IsA("ObjectValue") then
local ok, t = pcall(function() return tostring(obj.Value) end)
if ok and t:lower():match(petName:lower()) then return true end
end
end
end
return false
end

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
-- Login UI + Anim
-- =======================
local function createLoginUI(callback)
local parent = getGuiParent()
pcall(function() parent:FindFirstChild("GicaHubLoginUI"):Destroy() end)

local screen = Instance.new("ScreenGui"); screen.Name = "GicaHubLoginUI"; screen.ResetOnSpawn = false; screen.Parent = parent  
local frame = Instance.new("Frame"); frame.Size = UDim2.new(0,320,0,200); frame.Position = UDim2.new(0.5,-160,0.5,-100)  
frame.BackgroundColor3 = Color3.fromRGB(30,0,40); frame.Parent = screen; addCorner(frame,10)  

local lbl = Instance.new("TextLabel"); lbl.Size = UDim2.new(1,-20,0,40); lbl.Position = UDim2.new(0,10,0,8)  
lbl.BackgroundTransparency = 1; lbl.Text = "gicahub v5 secure"; lbl.Font = Enum.Font.GothamBold; lbl.TextSize = 18; lbl.TextColor3 = Color3.fromRGB(255,255,255); lbl.Parent = frame  

local txt = Instance.new("TextBox"); txt.Size = UDim2.new(1,-20,0,40); txt.Position = UDim2.new(0,10,0,56)  
txt.ClearTextOnFocus = false; txt.BackgroundColor3 = Color3.fromRGB(50,0,70); txt.TextColor3 = Color3.fromRGB(255,255,255)  
txt.PlaceholderText = "Enter secret (1234-5678-9012)..."; txt.Parent = frame; addCorner(txt,8)  

local btn = Instance.new("TextButton"); btn.Size = UDim2.new(0,100,0,32); btn.Position = UDim2.new(0.5,-50,1,-44)  
btn.BackgroundColor3 = Color3.fromRGB(80,0,150); btn.Text = "Submit"; btn.Parent = frame; addCorner(btn,8)  

btn.MouseButton1Click:Connect(function()  
    local input = tostring(txt.Text or "")  
    if input:match("^%d%d%d%d%-%d%d%d%d%-%d%d%d%d$") and input == PASSWORD then  
        pcall(function() screen:Destroy() end)  

        local animScreen = Instance.new("ScreenGui"); animScreen.Name = "PurchaseThanks"; animScreen.Parent = parent  
        local label = Instance.new("TextLabel"); label.Size = UDim2.new(0,380,0,80); label.Position = UDim2.new(0.5,-190,0.5,-40)  
        label.BackgroundTransparency = 1; label.Font = Enum.Font.GothamBold; label.TextSize = 20; label.TextColor3 = Color3.fromRGB(255,255,255)  
        label.Text = "TY For Purchasing Our service ❤️"; label.Parent = animScreen; label.TextTransparency = 1; label.TextStrokeTransparency = 0.7  

        -- Tweens  
        TweenService:Create(label, TweenInfo.new(1.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {TextTransparency = 0}):Play()  
        TweenService:Create(label, TweenInfo.new(0.9, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {TextSize = 24}):Play()  
        TweenService:Create(label, TweenInfo.new(1.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {Position = UDim2.new(0.5,-190,0.48,-40)}):Play()  
        TweenService:Create(label, TweenInfo.new(0.7, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {TextColor3 = Color3.fromRGB(255,80,80)}):Play()  

        delay(2.5, function()  
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
-- createUI (kompakter)
-- =======================
local function createUI()
local parent = getGuiParent()
pcall(function() parent:FindFirstChild("GicaHubUI"):Destroy() end)

local screen = Instance.new("ScreenGui"); screen.Name = "GicaHubUI"; screen.Parent = parent  
local frame = Instance.new("Frame"); frame.Size = UDim2.new(0,320,0,380); frame.Position = UDim2.new(0.5,-160,0.5,-190)  
frame.BackgroundColor3 = Color3.fromRGB(28,6,40); frame.Parent = screen; addCorner(frame,12); frame.Active = true  

-- title bar  
local title = Instance.new("TextLabel"); title.Size = UDim2.new(1,0,0,36); title.Position = UDim2.new(0,0,0,0)  
title.BackgroundColor3 = Color3.fromRGB(68,6,120); title.Text = "gicahub v5 secure"; title.Font = Enum.Font.GothamBold; title.TextSize = 16  
title.TextColor3 = Color3.fromRGB(235,220,255); title.Parent = frame; addCorner(title,10)  

-- Minimieren Button  
local minBtn = Instance.new("TextButton"); minBtn.Size = UDim2.new(0,28,0,28); minBtn.Position = UDim2.new(1,-36,0,4)  
minBtn.Text = "-"; minBtn.Parent = frame; addCorner(minBtn,6)  
local minimized = false  
local miniUI  
minBtn.MouseButton1Click:Connect(function()  
    minimized = not minimized  
    frame.Visible = not minimized  
    if minimized then  
        miniUI = Instance.new("ScreenGui"); miniUI.Name = "GicaHubMiniUI"; miniUI.Parent = parent  
        local mf = Instance.new("Frame"); mf.Size = UDim2.new(0,80,0,80); mf.Position = UDim2.new(0,50,0,50)  
        mf.BackgroundColor3 = Color3.fromRGB(100,0,150); mf.Parent = miniUI; addCorner(mf,12)  
        local lab = Instance.new("TextLabel"); lab.Size=UDim2.new(1,0,1,0); lab.BackgroundTransparency=1; lab.Text="GH"; lab.Font=Enum.Font.GothamBold; lab.TextSize=28; lab.TextColor3=Color3.fromRGB(255,255,255); lab.Parent=mf  
        mf.MouseButton1Click = nil  
        mf.InputBegan:Connect(function(input)  
            if input.UserInputType == Enum.UserInputType.MouseButton1 then  
                pcall(function() miniUI:Destroy() end)  
                frame.Visible = true  
                minimized = false  
            end  
        end)  
    else  
        pcall(function() miniUI:Destroy() end)  
    end  
end)  

-- tabs row  
local tabBar = Instance.new("Frame"); tabBar.Size = UDim2.new(1,-16,0,36); tabBar.Position = UDim2.new(0,8,0,44); tabBar.BackgroundTransparency = 1; tabBar.Parent = frame  

local function makeTab(text, x)  
    local b = Instance.new("TextButton"); b.Size = UDim2.new(0,95,0,28); b.Position = UDim2.new(0,x,0,4)  
    b.Text = text; b.Parent = tabBar; addCorner(b,8); b.Font = Enum.Font.Gotham; b.TextSize = 14  
    b.BackgroundColor3 = Color3.fromRGB(62,6,110); b.TextColor3 = Color3.fromRGB(240,240,240)  
    return b  
end  

local tMain = makeTab("Main", 2)  
local tFinder = makeTab("Finder", 102)  
local tESP = makeTab("ESP", 202)  

local content = Instance.new("Frame"); content.Size = UDim2.new(1,-16,1,-100); content.Position = UDim2.new(0,8,0,84); content.BackgroundTransparency = 1; content.Parent = frame  

-- = Main tab =  
local mainTab = Instance.new("Frame"); mainTab.Size = UDim2.new(1,0,1,0); mainTab.Parent = content  
local flyBtn = Instance.new("TextButton"); flyBtn.Size = UDim2.new(0,140,0,34); flyBtn.Position = UDim2.new(0,8,0,6); flyBtn.Text = "Toggle Fly"; flyBtn.Parent = mainTab; addCorner(flyBtn,8)  
local speedLabel = Instance.new("TextLabel"); speedLabel.Size = UDim2.new(0,260,0,22); speedLabel.Position = UDim2.new(0,8,0,48); speedLabel.BackgroundTransparency = 1; speedLabel.Text = "WalkSpeed: "..tostring(Svt.WalkSpeed); speedLabel.Parent = mainTab  

-- WalkSpeed simple controls  
local plus = Instance.new("TextButton"); plus.Size = UDim2.new(0,36,0,28); plus.Position = UDim2.new(0,276,0,44); plus.Text = "+"; plus.Parent = mainTab; addCorner(plus,6)  
local minus = Instance.new("TextButton"); minus.Size = UDim2.new(0,36,0,28); minus.Position = UDim2.new(0,236,0,44); minus.Text = "-"; minus.Parent = mainTab; addCorner(minus,6)  

plus.MouseButton1Click:Connect(function() Svt.WalkSpeed = math.clamp(Svt.WalkSpeed + 2, 1, 250); Save(); speedLabel.Text = "WalkSpeed: "..Svt.WalkSpeed; pcall(function() localh = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid"); if h then h.WalkSpeed = Svt.WalkSpeed end end) end)

minus.MouseButton1Click:Connect(function() Svt.WalkSpeed = math.clamp(Svt.WalkSpeed - 2, 1, 250); Save(); speedLabel.Text = "WalkSpeed: "..Svt.WalkSpeed; pcall(function() local h = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid"); if h then h.WalkSpeed = Svt.WalkSpeed end end) end)

-- Fly implementation (simple)
local flyActive = false; local BG, BV, hb
local function enableFly()
local c = LP.Character or LP.CharacterAdded:Wait()
local hrp = c:FindFirstChild("HumanoidRootPart") or c:WaitForChild("HumanoidRootPart",5)
if not hrp then return end
BG = Instance.new("BodyGyro"); BG.P = 9e4; BG.MaxTorque = Vector3.new(9e9,9e9,9e9); BG.Parent = hrp
BV = Instance.new("BodyVelocity"); BV.MaxForce = Vector3.new(9e9,9e9,9e9); BV.Parent = hrp
hb = RunService.Heartbeat:Connect(function()
local cam = Workspace.CurrentCamera; if not cam then return end
BG.CFrame = cam.CFrame
BV.Velocity = cam.CFrame.LookVector * (Svt.FlySpeed * 50)
end)
end
local function disableFly()
if hb then hb:Disconnect(); hb = nil end
if BG then pcall(function() BG:Destroy() end) end
if BV then pcall(function() BV:Destroy() end) end
BG = nil; BV = nil
end
flyBtn.MouseButton1Click:Connect(function() flyActive = not flyActive; if flyActive then enableFly() else disableFly() end end)

-- =======================
-- Finder tab
-- =======================
local finderTab = Instance.new("Frame"); finderTab.Size = UDim2.new(1,0,1,0); finderTab.Parent = content; finderTab.Visible = false
local info = Instance.new("TextLabel"); info.Size = UDim2.new(1,0,0,36); info.Position = UDim2.new(0,0,0,0); info.BackgroundTransparency = 1; info.Text = "Finder: Wähle ein Pet und drücke Start Finder"; info.Parent = finderTab

local petList = {"Los Combinasionas","La Grande Combinasion","Los 67","67"}
local petDropdown = Instance.new("TextButton"); petDropdown.Size = UDim2.new(0,200,0,32); petDropdown.Position = UDim2.new(0,8,0,44)
petDropdown.Text = "Pet: "..Svt.SelectedPet; petDropdown.Parent = finderTab; addCorner(petDropdown,8)
local petFrame = Instance.new("Frame"); petFrame.Size = UDim2.new(0,200,0,#petList*28); petFrame.Position = UDim2.new(0,8,0,80); petFrame.BackgroundColor3 = Color3.fromRGB(40,0,60); petFrame.Visible = false; petFrame.Parent = finderTab; addCorner(petFrame,8)
for i,p in ipairs(petList) do
local b = Instance.new("TextButton"); b.Size = UDim2.new(1,0,0,28); b.Position = UDim2.new(0,0,0,(i-1)*28); b.Text = p; b.Parent = petFrame; addCorner(b,6)
b.MouseButton1Click:Connect(function() Svt.SelectedPet = p; Save(); petDropdown.Text = "Pet: "..p; petFrame.Visible = false end)
end
petDropdown.MouseButton1Click:Connect(function() petFrame.Visible = not petFrame.Visible end)

local startBtn = Instance.new("TextButton"); startBtn.Size = UDim2.new(0,120,0,34); startBtn.Position = UDim2.new(0,8,0,220); startBtn.Text = "Start Finder"; startBtn.Parent = finderTab; addCorner(startBtn,8)
local stopBtn = Instance.new("TextButton"); stopBtn.Size = UDim2.new(0,120,0,34); stopBtn.Position = UDim2.new(0,136,0,220); stopBtn.Text = "Stop Finder"; stopBtn.Parent = finderTab; addCorner(stopBtn,8)

local statusLabel = Instance.new("TextLabel"); statusLabel.Size = UDim2.new(1,-16,0,22); statusLabel.Position = UDim2.new(0,8,0,264); statusLabel.BackgroundTransparency = 1; statusLabel.Text = "Status: Idle"; statusLabel.Parent = finderTab

-- =======================
-- Finder Worker (Auto Server Hop)
-- =======================
local function showFoundPopup(foundPlayer)
local parent = getGuiParent()
pcall(function() parent:FindFirstChild("GicaHubFoundPopup"):Destroy() end)
local sg = Instance.new("ScreenGui"); sg.Name = "GicaHubFoundPopup"; sg.Parent = parent
local f = Instance.new("Frame"); f.Size = UDim2.new(0,300,0,110); f.Position = UDim2.new(0.5,-150,0.18,0); f.BackgroundColor3 = Color3.fromRGB(30,0,40); f.Parent = sg; addCorner(f,10)
local t = Instance.new("TextLabel"); t.Size = UDim2.new(1,-20,0,28); t.Position = UDim2.new(0,10,0,8); t.BackgroundTransparency = 1; t.Font = Enum.Font.GothamBold; t.TextSize = 16; t.Text = "Pet gefunden!"; t.Parent = f
local info = Instance.new("TextLabel"); info.Size = UDim2.new(1,-20,0,44); info.Position = UDim2.new(0,10,0,36); info.BackgroundTransparency = 1; info.Text = "Player: "..(foundPlayer and foundPlayer.Name or "unknown"); info.Parent = f
local ok = Instance.new("TextButton"); ok.Size = UDim2.new(0,120,0,28); ok.Position = UDim2.new(0.5,-60,1,-36); ok.Text = "Close"; ok.Parent = f; addCorner(ok,8)
ok.MouseButton1Click:Connect(function() pcall(function() sg:Destroy() end) end)
end

local function finderWorker()
Svt.FinderActive = true
Save()
local placeIdStr = tostring(game.PlaceId)
local attempted = {}
statusLabel.Text = "Status: Prüfung aktueller Server..."
local foundHere, who = currentServerHasPet(Svt.SelectedPet)
if foundHere then
statusLabel.Text = "Status: Pet bereits in dieser Instanz!"
showFoundPopup(who)
Svt.FinderActive = false; Save()
return
end

statusLabel.Text = "Status: Scanne Server (Suche: "..Svt.SelectedPet..")"  
local nextCursor = nil  

while Svt.FinderActive do  
    local url = "https://games.roblox.com/v1/games/"..placeIdStr.."/servers/Public?limit=100"  
    if nextCursor then url = url.."&cursor="..tostring(nextCursor) end  

    local ok, res = pcall(function() return HttpService:GetAsync(url, true) end)  
    if not ok or not res then  
        statusLabel.Text = "Status: Fehler beim Abrufen der Serverliste, warte 3s..."  
        wait(3)  
        if not Svt.FinderActive then break end  
        nextCursor = nil  
        attempted = {}  
        continue  
    end  

    local decoded = nil  
    pcall(function() decoded = HttpService:JSONDecode(res) end)  
    if not decoded or type(decoded.data) ~= "table" then  
        statusLabel.Text = "Status: Ungültige Antwort, warte..."  
        wait(2)  
        if not Svt.FinderActive then break end  
        nextCursor = nil  
        attempted = {}  
        continue  
    end  

    for _, server in ipairs(decoded.data) do  
        if not Svt.FinderActive then break end  
        local sid = tostring(server.id)  
        if sid and sid ~= tostring(game.JobId) and not attempted[sid] then  
            attempted[sid] = true  
            statusLabel.Text = "Status: Versuche Server "..sid.." ("..tostring(server.playing).." Spieler)"  
            print("Server "..sid.." durchsucht, Spieler: "..tostring(server.playing))  
            wait(0.25)  
            local okTeleport, err = pcall(function()  
                TeleportService:TeleportToPlaceInstance(game.PlaceId, sid, LP)  
            end)  
            wait(6)  
        end  
    end  

    if decoded.nextPageCursor then  
        nextCursor = decoded.nextPageCursor  
    else  
        statusLabel.Text = "Status: Scan beendet — nichts gefunden"  
        Svt.FinderActive = false; Save()  
        break  
    end  
end  
if not Svt.FinderActive then  
    statusLabel.Text = "Status: Gestoppt"  
end

end

startBtn.MouseButton1Click:Connect(function()
if Svt.FinderActive then
statusLabel.Text = "Status: Finder läuft bereits"
return
end
Svt.FinderActive = true; Save()
statusLabel.Text = "Status: Starter Suche..."
spawn(finderWorker)
end)

stopBtn.MouseButton1Click:Connect(function()
Svt.FinderActive = false; Save()
statusLabel.Text = "Status: Stop requested"
end)

-- =======================
-- Tabs
-- =======================
local espTab = Instance.new("Frame"); espTab-- ESP Tab (Platzhalter, nur UI Frame)
espTab.Size = UDim2.new(1,0,1,0); espTab.Parent = content; espTab.Visible = false
local espLabel = Instance.new("TextLabel"); espLabel.Size = UDim2.new(1,0,0,28); espLabel.Position = UDim2.new(0,0,0,0); espLabel.BackgroundTransparency = 1
espLabel.Text = "ESP Funktionen hier"; espLabel.Font = Enum.Font.Gotham; espLabel.TextSize = 16; espLabel.TextColor3 = Color3.fromRGB(255,255,255); espLabel.Parent = espTab

-- Tab Buttons
tMain.MouseButton1Click:Connect(function() mainTab.Visible = true; finderTab.Visible = false; espTab.Visible = false end)
tFinder.MouseButton1Click:Connect(function() mainTab.Visible = false; finderTab.Visible = true; espTab.Visible = false end)
tESP.MouseButton1Click:Connect(function() mainTab.Visible = false; finderTab.Visible = false; espTab.Visible = true end)

-- Fertig: Initial sichtbarer Tab
mainTab.Visible = true; finderTab.Visible = false; espTab.Visible = false

-- =======================
-- Script Start nach Login
-- =======================
createLoginUI(function()
createUI()
end)

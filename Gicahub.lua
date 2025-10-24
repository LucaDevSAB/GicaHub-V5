-- 🌌 Gica Hub v5 ultra compact (loadstring-ready)
-- ✅ Fallback UI & Kavo UI (mobilfreundlich)
-- 🔹 Midnight Theme

-- 🔹 Services
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")

-- 🔹 LocalPlayer & Settings
local LP = Players.LocalPlayer or Players.PlayerAdded:Wait()
local SETTINGS_FILE = "GicaHubSettings.json"
local Svt = {WalkSpeed=16, FlySpeed=2}

-- 🔹 Safe file API
local has_isfile = type(isfile)=="function"
local has_readfile = type(readfile)=="function"
local has_writefile = type(writefile)=="function"

if has_isfile and isfile(SETTINGS_FILE) and has_readfile then
    local ok,s = pcall(function() return HttpService:JSONDecode(readfile(SETTINGS_FILE)) end)
    if ok and type(s)=="table" then Svt = s end
end

local function Save()
    if has_writefile then
        pcall(function() writefile(SETTINGS_FILE,HttpService:JSONEncode(Svt)) end)
    end
end

-- 🔹 Robust HTTP GET
local function http_get(url)
    local ok,res
    if pcall(function() return game:HttpGet(url) end) then
        ok,res = pcall(function() return game:HttpGet(url) end)
    end
    if ok and res then return res end
    if type(syn)=="table" and type(syn.request)=="function" then
        ok,res=pcall(function() return syn.request({Url=url,Method="GET"}).Body end)
    end
    if ok and res then return res end
    if type(http_request)=="function" then
        ok,res=pcall(function() return http_request({Url=url,Method="GET"}).Body end)
    end
    if ok and res then return res end
    return nil
end

-- 🔹 Load Kavo UI
local Lib
do
    local body = http_get("https://raw.githubusercontent.com/xHeptc/Kavo-UI-Library/main/source.lua")
    if body then
        local ok, lib = pcall(function() return loadstring(body)() end)
        if ok then Lib = lib end
    end
end

-- 🔹 Fallback UI (mobilfreundlich, verschiebbar, minimierbar)
local function create_simple_ui()
    local pg = LP:WaitForChild("PlayerGui")
    local screen = Instance.new("ScreenGui")
    screen.Name = "GicaHubUI"
    screen.Parent = pg

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0,300,0,260)
    frame.Position = UDim2.new(0.5,-150,0.5,-130)
    frame.BackgroundColor3 = Color3.fromRGB(10,10,30) -- Midnight
    frame.Parent = screen

    -- Titelbar
    local titleBar = Instance.new("Frame")
    titleBar.Size = UDim2.new(1,0,0,30)
    titleBar.Position = UDim2.new(0,0,0,0)
    titleBar.BackgroundColor3 = Color3.fromRGB(20,20,50)
    titleBar.Parent = frame

    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(1,-40,1,0)
    titleLabel.Position = UDim2.new(0,10,0,0)
    titleLabel.Text = "🌌 Gica Hub"
    titleLabel.TextColor3 = Color3.fromRGB(200,200,255)
    titleLabel.BackgroundTransparency = 1
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Parent = titleBar

    -- Minimieren Button
    local minBtn = Instance.new("TextButton")
    minBtn.Size = UDim2.new(0,30,0,30)
    minBtn.Position = UDim2.new(1,-35,0,0)
    minBtn.Text = "-"
    minBtn.TextColor3 = Color3.fromRGB(255,255,255)
    minBtn.BackgroundColor3 = Color3.fromRGB(40,40,70)
    minBtn.Parent = titleBar

    local minimized = false
    minBtn.MouseButton1Click:Connect(function()
        minimized = not minimized
        for _,child in pairs(frame:GetChildren()) do
            if child ~= titleBar then
                child.Visible = not minimized
            end
        end
        frame.Size = minimized and UDim2.new(0,300,0,30) or UDim2.new(0,300,0,260)
    end)

    -- Drag Funktion
    local dragging, dragInput, dragStart, startPos
    local function update(input)
        local delta = input.Position - dragStart
        frame.Position = UDim2.new(
            startPos.X.Scale,
            startPos.X.Offset + delta.X,
            startPos.Y.Scale,
            startPos.Y.Offset + delta.Y
        )
    end

    titleBar.InputBegan:Connect(function(input)
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
    titleBar.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement then
            dragInput = input
        end
    end)
    RunService.RenderStepped:Connect(function()
        if dragging and dragInput then update(dragInput) end
    end)

    local function createButton(text,posY,callback)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1,-20,0,30)
        btn.Position = UDim2.new(0,10,0,posY)
        btn.Text = text
        btn.TextColor3 = Color3.fromRGB(200,200,255)
        btn.BackgroundColor3 = Color3.fromRGB(30,30,60)
        btn.Parent = frame
        btn.MouseButton1Click:Connect(callback)
    end

    -- WalkSpeed Button
    createButton("Speed 100",40,function()
        local c = LP.Character or LP.CharacterAdded:Wait()
        local hum = c:FindFirstChild("Humanoid")
        if hum then hum.WalkSpeed=100 Svt.WalkSpeed=100 Save() end
    end)

    -- WalkSpeed Slider (TextBox)
    local slider = Instance.new("TextBox")
    slider.Size = UDim2.new(1,-20,0,30)
    slider.Position = UDim2.new(0,10,0,80)
    slider.PlaceholderText = "WalkSpeed eingeben"
    slider.BackgroundColor3 = Color3.fromRGB(30,30,60)
    slider.TextColor3 = Color3.fromRGB(200,200,255)
    slider.Parent = frame
    slider.FocusLost:Connect(function()
        local val = tonumber(slider.Text)
        local c = LP.Character or LP.CharacterAdded:Wait()
        local hum = c:FindFirstChild("Humanoid")
        if val and hum then hum.WalkSpeed=val Svt.WalkSpeed=val Save() end
    end)

    -- Teleport Box
    local tpbox = Instance.new("TextBox")
    tpbox.Size = UDim2.new(1,-20,0,30)
    tpbox.Position = UDim2.new(0,10,0,120)
    tpbox.PlaceholderText = "Spielername"
    tpbox.BackgroundColor3 = Color3.fromRGB(30,30,60)
    tpbox.TextColor3 = Color3.fromRGB(200,200,255)
    tpbox.Parent = frame
    tpbox.FocusLost:Connect(function()
        local n = tpbox.Text
        local target = Players:FindFirstChild(n)
        local c = LP.Character or LP.CharacterAdded:Wait()
        local hrp = c:FindFirstChild("HumanoidRootPart")
        if target and target.Character and target.Character:FindFirstChild("HumanoidRootPart") and hrp then
            hrp.CFrame = target.Character.HumanoidRootPart.CFrame + Vector3.new(0,3,0)
        end
    end)

    -- Fly Button
    local fly=false
    local FS=Svt.FlySpeed
    local BG,BV,hbConn
    local flyBtn = Instance.new("TextButton")
    flyBtn.Size = UDim2.new(0,120,0,40)
    flyBtn.Position = UDim2.new(0.5,-60,0,170)
    flyBtn.Text = "Start Fly"
    flyBtn.BackgroundColor3 = Color3.fromRGB(0,150,255)
    flyBtn.TextColor3 = Color3.fromRGB(0,0,0)
    flyBtn.Parent = frame

    local function toggleFly()
        local c = LP.Character or LP.CharacterAdded:Wait()
        local hrp = c:WaitForChild("HumanoidRootPart",5)
        if not hrp then return end
        fly = not fly
        if fly then
            BG=Instance.new("BodyGyro",hrp)
            BV=Instance.new("BodyVelocity",hrp)
            BG.P=9e4 BG.MaxTorque=Vector3.new(9e9,9e9,9e9)
            BV.MaxForce=Vector3.new(9e9,9e9,9e9)
            hbConn=RunService.Heartbeat:Connect(function()
                local cam=workspace.CurrentCamera
                if cam then BG.CFrame=cam.CFrame BV.Velocity=cam.CFrame.LookVector*(FS*50) end
            end)
            flyBtn.Text="Stop Fly"
        else
            if hbConn then hbConn:Disconnect() end
            if BG then BG:Destroy() end
            if BV then BV:Destroy() end
            flyBtn.Text="Start Fly"
        end
    end
    flyBtn.MouseButton1Click:Connect(toggleFly)
end

-- 🔹 Kavo UI Variante (Midnight)
if Lib then
    local W = Lib.CreateLib("🌌 Gica Hub",{SchemeColor=Color3.fromRGB(0,150,255),Background=Color3.fromRGB(10,10,30),Header=Color3.fromRGB(0,150,255),TextColor=Color3.fromRGB(200,200,255),ElementColor=Color3.fromRGB(20,20,50)})
    local MT = W:NewTab("Main")
    local Fd = MT:NewSection("Finder")
    local Sp = MT:NewSection("Speed")
    local TP = MT:NewSection("Teleport")
    local Fy = MT:NewSection("Fly")

    -- Finder (Server Hop ersetzt)
    Fd:NewButton("Finder","",function()
        spawn(function()
            local servers={}
            local ok,res=pcall(function()
                return http_get("https://games.roblox.com/v1/games/"..tostring(game.PlaceId).."/servers/Public?sortOrder=Asc&limit=100")
            end)
            if ok and res then
                local success,data=pcall(function() return HttpService:JSONDecode(res) end)
                if success and type(data.data)=="table" then
                    for _,v in pairs(data.data) do
                        if v.playing<v.maxPlayers and v.id~=game.JobId then
                            table.insert(servers,v.id)
                        end
                    end
                    if #servers>0 then
                        TeleportService:TeleportToPlaceInstance(game.PlaceId,servers[math.random(1,#servers)],LP)
                    end
                end
            end
        end)
    end)

    -- Speed
    Sp:NewButton("Speed 100","",function()
        local c = LP.Character or LP.CharacterAdded:Wait()
        local hum = c:FindFirstChild("Humanoid")
        if hum then hum.WalkSpeed=100 Svt.WalkSpeed=100 Save() end
    end)
    Sp:NewSlider("WalkSpeed","",500,0,function(s)
        local c = LP.Character or LP.CharacterAdded:Wait()
        local hum = c:FindFirstChild("Humanoid")
        if hum then hum.WalkSpeed=s Svt.WalkSpeed=s Save() end
    end)
    LP.CharacterAdded:Connect(function(c) c:WaitForChild("Humanoid").WalkSpeed=Svt.WalkSpeed end)

    -- Teleport
    TP:NewTextbox("Zu Spieler","",function(n)
        local t = Players:FindFirstChild(n)
        local c = LP.Character or LP.CharacterAdded:Wait()
        local hrp = c:FindFirstChild("HumanoidRootPart")
        if t and t.Character and t.Character:FindFirstChild("HumanoidRootPart") and hrp then
            hrp.CFrame = t.Character.HumanoidRootPart.CFrame + Vector3.new(0,3,0)
        end
    end)

    -- Fly Fenster
    do
        local fly=false
        local FS=Svt.FlySpeed
        local BG,BV,hbConn
        local flyGui
        Fy:NewButton("Open Fly Window","",function()
            local pg = LP:WaitForChild("PlayerGui")
            local screen = Instance.new("ScreenGui")
            screen.Name = "GicaFlyWindow"
            screen.Parent = pg

            flyGui = Instance.new("TextButton")
            flyGui.Size = UDim2.new(0,120,0,50)
            flyGui.Position = UDim2.new(0.5,-60,0.2,0)
            flyGui.Text = "Start Fly"
            flyGui.BackgroundColor3 = Color3.fromRGB(0,150,255)
            flyGui.TextColor3 = Color3.fromRGB(0,0,0)
            flyGui.Parent = screen

            local function toggleFly()
                local c = LP.Character or LP.CharacterAdded:Wait()
                local hrp = c:WaitForChild("HumanoidRootPart",5)
                if not hrp then return end
                fly = not fly
                if fly then
                    BG=Instance.new("BodyGyro",hrp)
                    BV=Instance.new("BodyVelocity",hrp)
                    BG.P=9e4 BG.MaxTorque=Vector3.new(9e9,9e9,9e9)
                    BV.MaxForce=Vector3.new(9e9,9e9,9e9)
                    hbConn=RunService.Heartbeat:Connect(function()
                        local cam=workspace.CurrentCamera
                        if cam then BG.CFrame=cam.CFrame BV.Velocity=cam.CFrame.LookVector*(FS*50) end
                    end)
                    flyGui.Text="Stop Fly"
                else
                    if hbConn then hbConn:Disconnect() end
                    if BG then BG:Destroy() end
                    if BV then BV:Destroy() end
                    flyGui.Text="Start Fly"
                end
            end
            flyGui.MouseButton1Click:Connect(toggleFly)
        end)

        Fy:NewSlider("FlySpeed","",10,1,function(s)
            FS=s Svt.FlySpeed=s Save()
        end)
    end
end

-- 🔹 Fallback, falls Kavo nicht geladen
if not Lib then 
    print("[Gica Hub] Kavo UI konnte nicht geladen werden, Fallback UI aktiviert")
    create_simple_ui() 
end

print("✅ Gica Hub v5 ultra loaded!")

-- 🌌 Gica Hub v5 – Kavo UI + Fallback UI (Loadstring-ready)
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")

local LP = Players.LocalPlayer or Players.PlayerAdded:Wait()
local SETTINGS_FILE = "GicaHubSettings.json"
local Svt = {WalkSpeed=16, FlySpeed=2}

-- Safe file API
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

-- Robust HTTP GET
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

-- Fallback UI
local function create_fallback_ui()
    local pg = LP:WaitForChild("PlayerGui")
    local screen = Instance.new("ScreenGui")
    screen.Name = "GicaHubUI"
    screen.Parent = pg

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0,300,0,260)
    frame.Position = UDim2.new(0.5,-150,0.5,-130)
    frame.BackgroundColor3 = Color3.fromRGB(10,10,30)
    frame.Parent = screen

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
            if child ~= titleBar then child.Visible = not minimized end
        end
        frame.Size = minimized and UDim2.new(0,300,0,30) or UDim2.new(0,300,0,260)
    end)

    -- Drag
    local function dragFrame(frame, titleBar)
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
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = true
                dragStart = input.Position
                startPos = frame.Position
                input.Changed:Connect(function()
                    if input.UserInputState == Enum.UserInputState.End then dragging = false end
                end)
            end
        end)
        titleBar.InputChanged:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
                dragInput = input
            end
        end)
        RunService.RenderStepped:Connect(function()
            if dragging and dragInput then update(dragInput) end
        end)
    end
    dragFrame(frame, titleBar)

    -- WalkSpeed
    local function setWalkSpeed(speed)
        Svt.WalkSpeed = speed
        Save()
        local function apply(c)
            local hum = c:WaitForChild("Humanoid",5)
            if hum then hum.WalkSpeed = speed end
        end
        local char = LP.Character or LP.CharacterAdded:Wait()
        apply(char)
        LP.CharacterAdded:Connect(apply)
    end

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

    createButton("Speed 100",40,function() setWalkSpeed(100) end)
    local wsBox = Instance.new("TextBox")
    wsBox.Size = UDim2.new(1,-20,0,30)
    wsBox.Position = UDim2.new(0,10,0,80)
    wsBox.PlaceholderText = "WalkSpeed eingeben"
    wsBox.BackgroundColor3 = Color3.fromRGB(30,30,60)
    wsBox.TextColor3 = Color3.fromRGB(200,200,255)
    wsBox.Parent = frame
    wsBox.FocusLost:Connect(function()
        local val = tonumber(wsBox.Text)
        if val then setWalkSpeed(val) end
    end)

    -- Teleport
    local tpBox = Instance.new("TextBox")
    tpBox.Size = UDim2.new(1,-20,0,30)
    tpBox.Position = UDim2.new(0,10,0,120)
    tpBox.PlaceholderText = "Spielername"
    tpBox.BackgroundColor3 = Color3.fromRGB(30,30,60)
    tpBox.TextColor3 = Color3.fromRGB(200,200,255)
    tpBox.Parent = frame
    tpBox.FocusLost:Connect(function()
        local n = tpBox.Text
        local target = Players:FindFirstChild(n)
        local c = LP.Character or LP.CharacterAdded:Wait()
        local hrp = c:FindFirstChild("HumanoidRootPart")
        if target and target.Character and target.Character:FindFirstChild("HumanoidRootPart") and hrp then
            hrp.CFrame = target.Character.HumanoidRootPart.CFrame + Vector3.new(0,3,0)
        end
    end)

    -- Fly
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

    -- FlySpeed Slider
    local fsBox = Instance.new("TextBox")
    fsBox.Size = UDim2.new(1,-20,0,30)
    fsBox.Position = UDim2.new(0,10,0,220)
    fsBox.PlaceholderText = "FlySpeed eingeben"
    fsBox.BackgroundColor3 = Color3.fromRGB(30,30,60)
    fsBox.TextColor3 = Color3.fromRGB(200,200,255)
    fsBox.Parent = frame
    fsBox.FocusLost:Connect(function()
        local val = tonumber(fsBox.Text)
        if val then
            FS = val
            Svt.FlySpeed = val
            Save()
        end
    end)
end

-- Kavo UI
local Lib
do
    local body = http_get("https://raw.githubusercontent.com/xHeptc/Kavo-UI-Library/main/source.lua")
    if body then
        local ok, lib = pcall(function() return loadstring(body)() end)
        if ok then Lib = lib end
    end
end

if Lib then
    local W = Lib.CreateLib("🌌 Gica Hub",{SchemeColor=Color3.fromRGB(0,150,255),Background=Color3.fromRGB(10,10,30),Header=Color3.fromRGB(0,150,255),TextColor=Color3.fromRGB(200,200,255),ElementColor=Color3.fromRGB(20,20,50)})
    local MT = W:NewTab("Main")
    local Sp = MT:NewSection("Speed")
    local TP = MT:NewSection("Teleport")
    local Fy = MT:NewSection("Fly")

    Sp:NewButton("Speed 100","",function()
        local c = LP.Character or LP.CharacterAdded:Wait()
        local hum = c:FindFirstChild("Humanoid")
        if hum then hum.WalkSpeed = 100 Svt.WalkSpeed = 100 Save() end
    end)

    Sp:NewSlider("WalkSpeed","",500,0,function(s)
        local c = LP.Character or LP.CharacterAdded:Wait()
        local hum = c:FindFirstChild("Humanoid")
        if hum then hum.WalkSpeed = s Svt.WalkSpeed = s Save() end
    end)

    LP.CharacterAdded:Connect(function(c)
        local hum = c:WaitForChild("Humanoid",5)
        if hum then hum.WalkSpeed = Svt.WalkSpeed end
    end)

    TP:NewTextbox("Zu Spieler","",function(n)
        local t = Players:FindFirstChild(n)
        local c = LP.Character or LP.CharacterAdded:Wait()
        local hrp = c:FindFirstChild("HumanoidRootPart")
        if t and t.Character and t.Character:FindFirstChild("HumanoidRootPart") and hrp then
            hrp.CFrame = t.Character.HumanoidRootPart.CFrame + Vector3.new(0,3,0)
        end
    end)

    local fly = false
    local FS = Svt.FlySpeed
    local BG,BV,hbConn

    Fy:NewButton("Start Fly","",function()
        local c = LP.Character or LP.CharacterAdded:Wait()
        local hrp = c:WaitForChild("HumanoidRootPart",5)
        if not hrp then return end
        fly = not fly
        if fly then
            BG = Instance.new("BodyGyro",hrp)
            BV = Instance.new("BodyVelocity",hrp)
            BG.P=9e4 BG.MaxTorque=Vector3.new(9e9,9e9,9e9)
            BV.MaxForce=Vector3.new(9e9,9e9,9e9)
            hbConn = RunService.Heartbeat:Connect(function()
                local cam = workspace.CurrentCamera
                if cam then
                    BG.CFrame = cam.CFrame
                    BV.Velocity = cam.CFrame.LookVector * (FS*50)
                end
            end)
        else
            if hbConn then hbConn:Disconnect() end
            if BG then BG:Destroy() end
            if BV then BV:Destroy() end
        end
    end)

    Fy:NewSlider("FlySpeed","",50,1,function(s)
        FS = s
        Svt.FlySpeed = s
        Save()
    end)
end

-- Fallback, falls Kavo UI nicht lädt
if not Lib then
    print("[Gica Hub] Kavo UI konnte nicht geladen werden, Fallback UI aktiviert")
    create_fallback_ui()
end

print("✅ Gica Hub v5 ultra loaded!")

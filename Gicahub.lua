-- 🌌 Gica Hub v5 Ultra Compact + ESP + Pros Finder + Fly + Speed + Teleport + Animated UI
-- Kein automatischer Server-Hop mehr beim Start

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local TeleportService = game:GetService("TeleportService")

local LP = Players.LocalPlayer or Players.PlayerAdded:Wait()
local SETTINGS_FILE = "GicaHubSettings.json"

local Svt = {WalkSpeed=16, FlySpeed=2, ProsScannerEnabled=false, ProsMin=10000000, ProsMax=100000000, VisitedServers={} }

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

-- ================= ESP =================
local ESP_Objects = {}
local function createESP(plr)
    if plr == LP then return end
    local function addHighlight(char)
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
    if plr.Character then addHighlight(plr.Character) end
    plr.CharacterAdded:Connect(addHighlight)
    plr.CharacterRemoving:Connect(function()
        if ESP_Objects[plr] then
            ESP_Objects[plr]:Destroy()
            ESP_Objects[plr] = nil
        end
    end)
end

for _,plr in pairs(Players:GetPlayers()) do createESP(plr) end
Players.PlayerAdded:Connect(createESP)

-- ============== Pros Finder / Server Scanner ==============
local placeId = game.PlaceId

local function markVisited(id)
    if not id then return end
    Svt.VisitedServers = Svt.VisitedServers or {}
    Svt.VisitedServers[id] = true
    Save()
end

local function isVisited(id)
    return Svt.VisitedServers and Svt.VisitedServers[id]
end

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

local function getServerList(cursor)
    cursor = cursor or ""
    local url = "https://games.roblox.com/v1/games/"..tostring(placeId).."/servers/Public?sortOrder=Desc&limit=100"
    if cursor ~= "" then
        url = url .. "&cursor=" .. tostring(cursor)
    end
    local body = http_get(url)
    if not body then return nil end
    local ok, data = pcall(function() return HttpService:JSONDecode(body) end)
    if not ok or type(data) ~= "table" then return nil end
    return data
end

local function pickNextServer()
    local cursor = ""
    for _ = 1, 10 do
        local data = getServerList(cursor)
        if not data or type(data.data) ~= "table" then break end
        for _,inst in ipairs(data.data) do
            if type(inst) == "table" and inst.id then
                if not isVisited(tostring(inst.id)) and (inst.playing < inst.maxPlayers) then
                    return tostring(inst.id), data.nextPageCursor
                end
            end
        end
        cursor = data.nextPageCursor or ""
        if cursor == "" then break end
    end
    return nil
end

local function getPlayerEstimatedIncome(plr)
    local function inspectLeaderstats(p)
        local s = p:FindFirstChild("leaderstats") or p:FindFirstChild("Leaderstats") or p:FindFirstChild("stats")
        if s then
            for _,v in pairs(s:GetChildren()) do
                local name = (v.Name or ""):lower()
                if name:match("income") or name:match("earn") or name:match("pet") or name:match("value") or name:match("money") or name:match("coins") or name:match("cash") then
                    local num = tonumber(v.Value) or tonumber(v.Text) or nil
                    if num then return num end
                end
            end
        end
        return nil
    end
    local function inspectAttributes(p)
        local attrs = p:GetAttributes and p:GetAttributes() or {}
        for k,v in pairs(attrs) do
            local key = tostring(k):lower()
            if key:match("income") or key:match("earn") or key:match("pet") or key:match("value") or key:match("worth") then
                if type(v) == "number" then return v end
            end
        end
        return nil
    end
    local function inspectCharacter(char)
        if not char then return nil end
        for _,c in pairs(char:GetDescendants()) do
            if c:IsA("IntValue") or c:IsA("NumberValue") then
                local n = tostring(c.Name):lower()
                if n:match("income") or n:match("earn") or n:match("pet") or n:match("value") then
                    return tonumber(c.Value)
                end
            end
        end
        return nil
    end
    local res = inspectLeaderstats(plr) or inspectAttributes(plr) or (plr.Character and inspectCharacter(plr.Character))
    return res
end

local scanning = false
local function startProsScanOnceAndTeleport()
    if scanning then return end
    scanning = true
    spawn(function()
        while true do
            local sid = pickNextServer()
            if not sid then
                wait(3)
            else
                markVisited(sid)
                pcall(function()
                    TeleportService:TeleportToPlaceInstance(placeId, sid, LP)
                end)
                break
            end
            wait(2)
        end
        scanning = false
    end)
end

-- ==================== UI ====================
local function createUI()
    local pg = LP:WaitForChild("PlayerGui")
    local screen = Instance.new("ScreenGui")
    screen.Name = "GicaHubUI"
    screen.Parent = pg

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0,340,0,420)
    frame.Position = UDim2.new(0.5,-170,0.5,-210)
    frame.BackgroundColor3 = Color3.fromRGB(30,0,40)
    frame.BackgroundTransparency = 0.2
    frame.Parent = screen
    frame.ClipsDescendants = true

    -- Title
    local titleBar = Instance.new("Frame")
    titleBar.Size = UDim2.new(1,0,0,30)
    titleBar.Position = UDim2.new(0,0,0,0)
    titleBar.BackgroundColor3 = Color3.fromRGB(60,0,100)
    titleBar.Parent = frame

    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(1,-70,1,0)
    titleLabel.Position = UDim2.new(0,10,0,0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = "🌌 Gica Hub"
    titleLabel.TextColor3 = Color3.fromRGB(220,200,255)
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Parent = titleBar

    -- Close & Minimize Buttons
    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0,30,0,30)
    closeBtn.Position = UDim2.new(1,-35,0,0)
    closeBtn.Text = "X"
    closeBtn.TextColor3 = Color3.fromRGB(255,255,255)
    closeBtn.BackgroundColor3 = Color3.fromRGB(40,0,60)
    closeBtn.Parent = titleBar

    local minBtn = Instance.new("TextButton")
    minBtn.Size = UDim2.new(0,30,0,30)
    minBtn.Position = UDim2.new(1,-70,0,0)
    minBtn.Text = "-"
    minBtn.TextColor3 = Color3.fromRGB(255,255,255)
    minBtn.BackgroundColor3 = Color3.fromRGB(40,0,60)
    minBtn.Parent = titleBar

    -- Minimal-Icon (viereck)
    local miniIcon = Instance.new("Frame")
    miniIcon.Size = UDim2.new(0,50,0,50)
    miniIcon.Position = UDim2.new(0.05,0,0.8,0)
    miniIcon.BackgroundColor3 = Color3.fromRGB(100,0,150)
    miniIcon.Visible = false
    miniIcon.Parent = screen
    miniIcon.ZIndex = 5

    local miniIconBtn = Instance.new("TextButton")
    miniIconBtn.Size = UDim2.new(1,0,1,0)
    miniIconBtn.BackgroundTransparency = 1
    miniIconBtn.Text = ""
    miniIconBtn.Parent = miniIcon

    -- Drag
    local dragging, dragStart, startPos
    local function drag(input)
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
            input.Changed:Connect(function()
                if dragging then drag(input) end
            end)
        end
    end)
    RunService.RenderStepped:Connect(function()
        if dragging then
            local pos = UserInputService:GetMouseLocation()
            drag({Position = Vector2.new(pos.X,pos.Y),Changed={}})
        end
    end)

    -- Minimize / Restore
    local minimized = false
    minBtn.MouseButton1Click:Connect(function()
        minimized = true
        frame.Visible = false
        miniIcon.Visible = true
    end)
    miniIconBtn.MouseButton1Click:Connect(function()
        minimized = false
        frame.Visible = true
        miniIcon.Visible = false
    end)

    -- Close
    closeBtn.MouseButton1Click:Connect(function()
        frame:Destroy()
        miniIcon:Destroy()
    end)

    -- Buttons Container
    local btnContainer = Instance.new("Frame")
    btnContainer.Size = UDim2.new(1,-20,1,-50)
    btnContainer.Position = UDim2.new(0,10,0,40)
    btnContainer.BackgroundTransparency = 1
    btnContainer.Parent = frame

    -- ===== Fly Button =====
    local flyBtn = Instance.new("TextButton")
    flyBtn.Size = UDim2.new(0,120,0,35)
    flyBtn.Position = UDim2.new(0,10,0,0)
    flyBtn.BackgroundColor3 = Color3.fromRGB(80,0,150)
    flyBtn.TextColor3 = Color3.fromRGB(255,255,255)
    flyBtn.Text = "Toggle Fly"
    flyBtn.Parent = btnContainer

    local flyActive = false
    local BG,BV,hbConn

    local function toggleFly()
        local c = LP.Character or LP.CharacterAdded:Wait()
        local hrp = c:WaitForChild("HumanoidRootPart",5)
        if not hrp then return end
        flyActive = not flyActive
        if flyActive then
            BG = Instance.new("BodyGyro",hrp)
            BV = Instance.new("BodyVelocity",hrp)
            BG.P = 9e4
            BG.MaxTorque = Vector3.new(9e9,9e9,9e9)
            BV.MaxForce = Vector3.new(9e9,9e9,9e9)
            hbConn = RunService.Heartbeat:Connect(function()
                local cam = Workspace.CurrentCamera
                local vel = Vector3.new()
                -- Grappler check
                local grappler = c:FindFirstChildWhichIsA("Tool")
                if grappler and grappler.Name:lower():match("grap") then
                    vel = cam.CFrame.LookVector * (Svt.FlySpeed*60)
                else
                    vel = cam.CFrame.LookVector * (Svt.FlySpeed*50)
                end
                BG.CFrame = cam.CFrame
                BV.Velocity = vel
            end)
        else
            if hbConn then hbConn:Disconnect() end
            if BG then BG:Destroy() end
            if BV then BV:Destroy() end
        end
    end
    flyBtn.MouseButton1Click:Connect(toggleFly)

    -- ===== Speed Button =====
    local speedBtn = Instance.new("TextButton")
    speedBtn.Size = UDim2.new(0,120,0,35)
    speedBtn.Position = UDim2.new(0,150,0,0)
    speedBtn.BackgroundColor3 = Color3.fromRGB(80,0,150)
    speedBtn.TextColor3 = Color3.fromRGB(255,255,255)
    speedBtn.Text = "Speed: "..Svt.WalkSpeed
    speedBtn.Parent = btnContainer

    local speedActive = false
    local speedConn
    speedBtn.MouseButton1Click:Connect(function()
        speedActive = not speedActive
        if speedActive then
            local c = LP.Character or LP.CharacterAdded:Wait()
            local h = c:WaitForChild("Humanoid",5)
            speedConn = RunService.RenderStepped:Connect(function()
                h.WalkSpeed = Svt.WalkSpeed
            end)
        else
            if speedConn then speedConn:Disconnect() end
            local c = LP.Character or LP.CharacterAdded:Wait()
            local h = c:WaitForChild("Humanoid",5)
            h.WalkSpeed = 16
        end
    end)

    -- ===== Teleport Button =====
    local tpBtn = Instance.new("TextButton")
    tpBtn.Size = UDim2.new(0,120,0,35)
    tpBtn.Position = UDim2.new(0,10,0,100)
    tpBtn.BackgroundColor3 = Color3.fromRGB(80,0,150)
    tpBtn.TextColor3 = Color3.fromRGB(255,255,255)
    tpBtn.Text = "Teleport (Click)"
    tpBtn.Parent = btnContainer

    tpBtn.MouseButton1Click:Connect(function()
        local mouse = LP:GetMouse()
        local c = LP.Character or LP.CharacterAdded:Wait()
        local hrp = c:WaitForChild("HumanoidRootPart",5)
        if not hrp then return end
        hrp.CFrame = CFrame.new(mouse.Hit.Position + Vector3.new(0,3,0))
    end)

    -- ===== Pros Finder Button =====
    local prosBtn = Instance.new("TextButton")
    prosBtn.Size = UDim2.new(0,120,0,35)
    prosBtn.Position = UDim2.new(0,150,0,50)
    prosBtn.BackgroundColor3 = Color3.fromRGB(80,0,150)
    prosBtn.TextColor3 = Color3.fromRGB(255,255,255)
    prosBtn.Text = "Finder"
    prosBtn.Parent = btnContainer

    prosBtn.MouseButton1Click:Connect(function()
        if not scanning then
            scanning = true
            spawn(startProsScanOnceAndTeleport)
        end
    end)

    -- ===== Hover Animations =====
    local function addHover(button)
        button.MouseEnter:Connect(function()
            button:TweenSize(UDim2.new(0,button.Size.X.Offset+10,0,button.Size.Y.Offset+5),"Out","Quad",0.2,true)
        end)
        button.MouseLeave:Connect(function()
            button:TweenSize(UDim2.new(0,120,0,35),"Out","Quad",0.2,true)
        end)
    end
    for _,btn in pairs({flyBtn,speedBtn,tpBtn,prosBtn}) do addHover(btn) end
end

createUI()

print("✅ Gica Hub v5 Ultra Compact fully loaded!")

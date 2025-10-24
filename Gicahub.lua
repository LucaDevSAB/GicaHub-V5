-- 🌌 Gica Hub v5 Ultra Compact - KRNL-friendly + Finder-Tab (Finder startet nur per Klick)
-- Kein automatischer Server-Hop beim Start

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
            pcall(function() ESP_Objects[plr]:Destroy() end)
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
    Svt.VisitedServers[tostring(id)] = true
    Save()
end

local function isVisited(id)
    return Svt.VisitedServers and Svt.VisitedServers[tostring(id)]
end

local function http_get(url)
    local ok,res
    ok,res = pcall(function() return game:HttpGet(url) end)
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
        local attrs = p.GetAttributes and p:GetAttributes() or {}
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
local function getGuiParent()
    -- robust parenting for KRNL: try PlayerGui, then gethui(), then CoreGui
    local parentTo = nil
    local success, pg = pcall(function() return LP:FindFirstChild("PlayerGui") end)
    if success and pg then
        parentTo = pg
    else
        if type(gethui) == "function" then
            local ok, g = pcall(function() return gethui() end)
            if ok and g then parentTo = g end
        end
        if not parentTo then
            local ok2, core = pcall(function() return game:GetService("CoreGui") end)
            if ok2 and core then parentTo = core end
        end
    end
    -- ultimate fallback
    if not parentTo then parentTo = workspace end
    return parentTo
end

local function createUI()
    local parentTo = getGuiParent()

    local screen = Instance.new("ScreenGui")
    screen.Name = "GicaHubUI"
    screen.Parent = parentTo
    screen.ResetOnSpawn = false
    screen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screen.Enabled = true
    screen.DisplayOrder = 9999

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0,380,0,460)
    frame.Position = UDim2.new(0.5,-190,0.5,-230)
    frame.BackgroundColor3 = Color3.fromRGB(30,0,40)
    frame.BackgroundTransparency = 0.2
    frame.Parent = screen
    frame.ClipsDescendants = true
    frame.Active = true
    frame.Name = "MainFrame"

    -- Title
    local titleBar = Instance.new("Frame")
    titleBar.Size = UDim2.new(1,0,0,34)
    titleBar.Position = UDim2.new(0,0,0,0)
    titleBar.BackgroundColor3 = Color3.fromRGB(60,0,100)
    titleBar.Parent = frame
    titleBar.Active = true

    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(1,-110,1,0)
    titleLabel.Position = UDim2.new(0,10,0,0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = "🌌 Gica Hub"
    titleLabel.TextColor3 = Color3.fromRGB(220,200,255)
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextSize = 18
    titleLabel.Parent = titleBar

    -- Close & Minimize Buttons
    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0,36,0,30)
    closeBtn.Position = UDim2.new(1,-40,0,2)
    closeBtn.Text = "X"
    closeBtn.TextColor3 = Color3.fromRGB(255,255,255)
    closeBtn.BackgroundColor3 = Color3.fromRGB(40,0,60)
    closeBtn.Parent = titleBar

    local minBtn = Instance.new("TextButton")
    minBtn.Size = UDim2.new(0,36,0,30)
    minBtn.Position = UDim2.new(1,-80,0,2)
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

    -- Tabs area
    local tabBar = Instance.new("Frame")
    tabBar.Size = UDim2.new(1, -20, 0, 40)
    tabBar.Position = UDim2.new(0,10,0,40)
    tabBar.BackgroundTransparency = 1
    tabBar.Parent = frame

    local function makeTabButton(text, x)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0,120,0,32)
        btn.Position = UDim2.new(0,x,0,4)
        btn.Text = text
        btn.BackgroundColor3 = Color3.fromRGB(70,0,140)
        btn.TextColor3 = Color3.fromRGB(255,255,255)
        btn.Parent = tabBar
        return btn
    end

    local btnMain = makeTabButton("Main", 0)
    local btnFinder = makeTabButton("Finder", 125)
    local btnESP = makeTabButton("ESP", 250)

    -- Content container
    local content = Instance.new("Frame")
    content.Size = UDim2.new(1,-20,1,-100)
    content.Position = UDim2.new(0,10,0,90)
    content.BackgroundTransparency = 1
    content.Parent = frame

    -- --- Main Tab ---
    local mainTab = Instance.new("Frame")
    mainTab.Size = UDim2.new(1,0,1,0)
    mainTab.BackgroundTransparency = 1
    mainTab.Parent = content

    local flyBtn = Instance.new("TextButton")
    flyBtn.Size = UDim2.new(0,150,0,38)
    flyBtn.Position = UDim2.new(0,10,0,0)
    flyBtn.BackgroundColor3 = Color3.fromRGB(80,0,150)
    flyBtn.TextColor3 = Color3.fromRGB(255,255,255)
    flyBtn.Text = "Toggle Fly"
    flyBtn.Parent = mainTab

    local speedBtn = Instance.new("TextButton")
    speedBtn.Size = UDim2.new(0,150,0,38)
    speedBtn.Position = UDim2.new(0,180,0,0)
    speedBtn.BackgroundColor3 = Color3.fromRGB(80,0,150)
    speedBtn.TextColor3 = Color3.fromRGB(255,255,255)
    speedBtn.Text = "Speed: "..Svt.WalkSpeed
    speedBtn.Parent = mainTab

    local tpBtn = Instance.new("TextButton")
    tpBtn.Size = UDim2.new(0,150,0,38)
    tpBtn.Position = UDim2.new(0,10,0,56)
    tpBtn.BackgroundColor3 = Color3.fromRGB(80,0,150)
    tpBtn.TextColor3 = Color3.fromRGB(255,255,255)
    tpBtn.Text = "Teleport (Click)"
    tpBtn.Parent = mainTab

    -- --- Finder Tab ---
    local finderTab = Instance.new("Frame")
    finderTab.Size = UDim2.new(1,0,1,0)
    finderTab.BackgroundTransparency = 1
    finderTab.Visible = false
    finderTab.Parent = content

    local finderInfo = Instance.new("TextLabel")
    finderInfo.Size = UDim2.new(1, -20, 0, 60)
    finderInfo.Position = UDim2.new(0,10,0,0)
    finderInfo.BackgroundTransparency = 1
    finderInfo.Text = "Pros Finder scannt Server und teleportiert dich nur wenn du auf Start klickst.\nBesuchte Server werden gespeichert."
    finderInfo.TextColor3 = Color3.fromRGB(220,220,220)
    finderInfo.TextWrapped = true
    finderInfo.Parent = finderTab

    local startFinderBtn = Instance.new("TextButton")
    startFinderBtn.Size = UDim2.new(0,160,0,38)
    startFinderBtn.Position = UDim2.new(0,10,0,70)
    startFinderBtn.BackgroundColor3 = Color3.fromRGB(80,0,150)
    startFinderBtn.TextColor3 = Color3.fromRGB(255,255,255)
    startFinderBtn.Text = "Start Finder"
    startFinderBtn.Parent = finderTab

    local stopFinderBtn = Instance.new("TextButton")
    stopFinderBtn.Size = UDim2.new(0,160,0,38)
    stopFinderBtn.Position = UDim2.new(0,180,0,70)
    stopFinderBtn.BackgroundColor3 = Color3.fromRGB(120,0,100)
    stopFinderBtn.TextColor3 = Color3.fromRGB(255,255,255)
    stopFinderBtn.Text = "Stop Finder"
    stopFinderBtn.Parent = finderTab

    -- --- ESP Tab ---
    local espTab = Instance.new("Frame")
    espTab.Size = UDim2.new(1,0,1,0)
    espTab.BackgroundTransparency = 1
    espTab.Visible = false
    espTab.Parent = content

    local espInfo = Instance.new("TextLabel")
    espInfo.Size = UDim2.new(1, -20, 0, 60)
    espInfo.Position = UDim2.new(0,10,0,0)
    espInfo.BackgroundTransparency = 1
    espInfo.Text = "ESP: Highlight für andere Spieler (aktiviert beim Join)."
    espInfo.TextColor3 = Color3.fromRGB(220,220,220)
    espInfo.TextWrapped = true
    espInfo.Parent = espTab

    -- Drag (simpler, robust)
    local dragging = false
    local dragStartPos = Vector2.new(0,0)
    local guiStartPos = frame.Position

    titleBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStartPos = input.Position
            guiStartPos = frame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if not dragging then return end
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            local delta = input.Position - dragStartPos
            frame.Position = UDim2.new(
                guiStartPos.X.Scale,
                guiStartPos.X.Offset + delta.X,
                guiStartPos.Y.Scale,
                guiStartPos.Y.Offset + delta.Y
            )
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
        pcall(function() screen:Destroy() end)
    end)

    -- Tab switching
    local function showTab(tab)
        mainTab.Visible = false
        finderTab.Visible = false
        espTab.Visible = false
        if tab == "Main" then mainTab.Visible = true
        elseif tab == "Finder" then finderTab.Visible = true
        elseif tab == "ESP" then espTab.Visible = true end
    end

    btnMain.MouseButton1Click:Connect(function() showTab("Main") end)
    btnFinder.MouseButton1Click:Connect(function() showTab("Finder") end)
    btnESP.MouseButton1Click:Connect(function() showTab("ESP") end)
    showTab("Main")

    -- ===== Fly Functionality =====
    local flyActive = false
    local BG,BV,hbConn
    local function toggleFly()
        local c = LP.Character or LP.CharacterAdded:Wait()
        local hrp = c:FindFirstChild("HumanoidRootPart") or c:WaitForChild("HumanoidRootPart",5)
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
                if not cam then return end
                local vel = Vector3.new()
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
            if BG then pcall(function() BG:Destroy() end) end
            if BV then pcall(function() BV:Destroy() end) end
        end
    end
    flyBtn.MouseButton1Click:Connect(toggleFly)

    -- ===== Speed Functionality =====
    local speedActive = false
    local speedConn
    local function enableSpeed()
        local c = LP.Character or LP.CharacterAdded:Wait()
        local h = c:FindFirstChildOfClass("Humanoid")
        if not h then return end
        speedConn = RunService.RenderStepped:Connect(function()
            if h and h.Parent then
                h.WalkSpeed = Svt.WalkSpeed
            end
        end)
    end
    local function disableSpeed()
        if speedConn then speedConn:Disconnect() speedConn = nil end
        local c = LP.Character or LP.CharacterAdded:Wait()
        local h = c:FindFirstChildOfClass("Humanoid")
        if h then
            pcall(function() h.WalkSpeed = 16 end)
        end
    end
    speedBtn.MouseButton1Click:Connect(function()
        speedActive = not speedActive
        if speedActive then enableSpeed() else disableSpeed() end
    end)

    -- ===== Teleport Button =====
    tpBtn.MouseButton1Click:Connect(function()
        local mouse = LP:GetMouse()
        local c = LP.Character or LP.CharacterAdded:Wait()
        local hrp = c:FindFirstChild("HumanoidRootPart") or c:WaitForChild("HumanoidRootPart",5)
        if not hrp then return end
        if mouse and mouse.Hit then
            local pos = mouse.Hit.Position + Vector3.new(0,3,0)
            pcall(function() hrp.CFrame = CFrame.new(pos) end)
        end
    end)

    -- ===== Finder Start/Stop =====
    startFinderBtn.MouseButton1Click:Connect(function()
        if not scanning then
            scanning = true
            -- explicit user action: start scanning once
            spawn(startProsScanOnceAndTeleport)
        end
    end)
    stopFinderBtn.MouseButton1Click:Connect(function()
        -- stop scanning politely by setting flag; startProsScanOnceAndTeleport respects scanning flag
        scanning = false
    end)

    -- ===== Hover Animations (stable) =====
    local function addHover(button)
        local origSize = button.Size
        local expanded = UDim2.new(origSize.X.Scale, origSize.X.Offset + 10, origSize.Y.Scale, origSize.Y.Offset + 5)
        button.MouseEnter:Connect(function()
            pcall(function() button:TweenSize(expanded,"Out","Quad",0.15,true) end)
        end)
        button.MouseLeave:Connect(function()
            pcall(function() button:TweenSize(origSize,"Out","Quad",0.15,true) end)
        end)
    end
    for _,btn in pairs({flyBtn,speedBtn,tpBtn,startFinderBtn,stopFinderBtn,btnMain,btnFinder,btnESP}) do addHover(btn) end
end

-- create UI (protected)
pcall(createUI)

print("✅ Gica Hub v5 Ultra Compact - KRNL build loaded! Finder startet nur per Klick.")

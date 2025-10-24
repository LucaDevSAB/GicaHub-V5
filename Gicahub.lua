-- 🌌 Gica Hub v5 Ultra Compact - KRNL
-- "gicahub v5 secure" login (secret: GicaHub1)
-- Finder: NO in-server player stat scanning. Finder filters servers using server API fields (e.g. 'playing')
-- TargetMin/TargetMax are editable textboxes in Finder tab and determine which servers are considered "match"

-- ===== Services =====
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local TeleportService = game:GetService("TeleportService")

local LP = Players.LocalPlayer or Players.PlayerAdded:Wait()
local SETTINGS_FILE = "GicaHubSettings.json"

-- ===== Settings (persisted) =====
local Svt = {
    WalkSpeed = 16,
    FlySpeed = 2,
    ProsScannerEnabled = false,
    VisitedServers = {},
    -- NOTE: Finder now compares server API numeric fields (like 'playing') to these values
    TargetMin = 1,
    TargetMax = 100, -- default: server playercount range 1..100
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

-- ===== Utilities =====
local function safeHttpGet(url)
    local ok, res = pcall(function() return game:HttpGet(url) end)
    if ok and res then return res end
    if type(syn) == "table" and type(syn.request) == "function" then
        ok, res = pcall(function() return syn.request({Url = url, Method = "GET"}).Body end)
        if ok and res then return res end
    end
    if type(http_request) == "function" then
        ok, res = pcall(function() return http_request({Url = url, Method = "GET"}).Body end)
        if ok and res then return res end
    end
    return nil
end

-- ===== ESP (simple highlight) =====
local ESP_Objects = {}
local function createESPForPlayer(plr)
    if plr == LP then return end
    local function add(char)
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
    if plr.Character then add(plr.Character) end
    plr.CharacterAdded:Connect(add)
    plr.CharacterRemoving:Connect(function()
        if ESP_Objects[plr] then pcall(function() ESP_Objects[plr]:Destroy() end) ESP_Objects[plr] = nil end
    end)
end
for _,p in pairs(Players:GetPlayers()) do createESPForPlayer(p) end
Players.PlayerAdded:Connect(createESPForPlayer)

-- ===== Finder (server-list filtering only) =====
local placeId = game.PlaceId
local scanning = Svt.ProsScannerEnabled or false

local function markVisited(id)
    if not id then return end
    Svt.VisitedServers = Svt.VisitedServers or {}
    Svt.VisitedServers[tostring(id)] = true
    Save()
end
local function isVisited(id)
    return Svt.VisitedServers and Svt.VisitedServers[tostring(id)]
end

local function getServerList(cursor)
    cursor = cursor or ""
    local url = "https://games.roblox.com/v1/games/"..tostring(placeId).."/servers/Public?sortOrder=Desc&limit=100"
    if cursor ~= "" then url = url .. "&cursor=" .. tostring(cursor) end
    local body = safeHttpGet(url)
    if not body then return nil end
    local ok, data = pcall(function() return HttpService:JSONDecode(body) end)
    if not ok or type(data) ~= "table" then return nil end
    return data
end

-- pick servers that match the TargetMin..TargetMax range by comparing a server numeric field.
-- By default we compare `playing` (current players). You can change compareField to something else if needed.
local compareField = "playing" -- public server field from the API
local function pickNextServerByRange(minv, maxv)
    minv = tonumber(minv) or Svt.TargetMin
    maxv = tonumber(maxv) or Svt.TargetMax
    local cursor = ""
    for _=1,10 do
        local data = getServerList(cursor)
        if not data or type(data.data) ~= "table" then break end
        for _,inst in ipairs(data.data) do
            if type(inst)=="table" and inst.id then
                local sid = tostring(inst.id)
                if not isVisited(sid) then
                    -- get numeric value for compareField if present
                    local fieldVal = nil
                    if inst[compareField] ~= nil then
                        fieldVal = tonumber(inst[compareField]) or nil
                    end
                    -- if fieldVal exists and in range, pick this server
                    if type(fieldVal) == "number" then
                        if fieldVal >= minv and fieldVal <= maxv and (inst.playing < inst.maxPlayers) then
                            return sid, data.nextPageCursor, fieldVal
                        end
                    else
                        -- if compareField missing, default behaviour: skip (we only act on explicit matches)
                    end
                end
            end
        end
        cursor = data.nextPageCursor or ""
        if cursor == "" then break end
    end
    return nil
end

-- disable fly objects created by this script to reduce teleport conflicts
local function disableFlyNamed()
    local c = LP.Character
    if not c then return end
    local hrp = c:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    for _,child in pairs(hrp:GetChildren()) do
        if (child:IsA("BodyGyro") or child:IsA("BodyVelocity")) and (child.Name == "GicaHub_BG" or child.Name == "GicaHub_BV") then
            pcall(function() child:Destroy() end)
        end
    end
end

local function teleportToInstanceAndPersist(sid)
    if not sid then return end
    Svt.ProsScannerEnabled = true
    Save()
    disableFlyNamed()
    wait(0.12)
    pcall(function() TeleportService:TeleportToPlaceInstance(placeId, sid, LP) end)
end

-- when arriving in a server while ProsScannerEnabled, we check whether this server meets the saved range
-- we use the server api fields accessible earlier to determine if it matches - as we can't re-query the API for the same server from inside (no need)
local function resumeScanIfNeeded(popupCallback)
    if not Svt.ProsScannerEnabled then return end
    -- give some time to fully join
    wait(1.5)
    -- mark this job id visited first (so we don't loop)
    local jobId = tostring(game.JobId or "")
    if jobId ~= "" then markVisited(jobId) end
    -- Try to fetch server list pages and find if this job id is in the returned data and has compareField matching range
    -- Fallback: if we can't find server data, we just proceed to pick a next server from API and teleport
    local minv = Svt.TargetMin
    local maxv = Svt.TargetMax
    local foundMatch = false
    local foundFieldValue = nil

    -- best-effort: scan server list pages for our job id and check its field
    local cursor = ""
    for _=1,6 do
        local data = getServerList(cursor)
        if not data or type(data.data) ~= "table" then break end
        for _,inst in ipairs(data.data) do
            if tostring(inst.id) == jobId then
                local fv = inst[compareField] and tonumber(inst[compareField]) or nil
                if type(fv) == "number" and fv >= minv and fv <= maxv then
                    foundMatch = true
                    foundFieldValue = fv
                end
                break
            end
        end
        if foundMatch then break end
        cursor = data.nextPageCursor or ""
        if cursor == "" then break end
    end

    if foundMatch then
        -- Matching server: stop scanning and notify
        Svt.ProsScannerEnabled = false
        Save()
        pcall(function() print("GicaHub Finder: current server matches range ("..tostring(foundFieldValue)..")") end)
        if popupCallback then pcall(function() popupCallback(foundFieldValue) end) end
        return true
    else
        -- Not matching: pick next server that DOES match min..max and teleport there
        local sid, nextCursor, fieldVal = pickNextServerByRange(minv, maxv)
        if sid then
            -- mark this server visited to avoid loops
            markVisited(jobId)
            wait(0.9)
            teleportToInstanceAndPersist(sid)
            return false
        else
            Svt.ProsScannerEnabled = false
            Save()
            warn("GicaHub Finder: keine passenden Server gefunden (api scan exhausted).")
            return false
        end
    end
end

-- ===== GUI helpers =====
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

-- ===== Popup when matching server found =====
local function showFoundPopup(fieldValue)
    local parent = getGuiParent()
    pcall(function() parent:FindFirstChild("GicaHubFoundPopup"):Destroy() end)
    local screen = Instance.new("ScreenGui")
    screen.Name = "GicaHubFoundPopup"
    screen.ResetOnSpawn = false
    screen.Parent = parent

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0,360,0,140)
    frame.Position = UDim2.new(0.5,-180,0.15,0)
    frame.BackgroundColor3 = Color3.fromRGB(30,0,40)
    frame.Parent = screen
    addCorner(frame,12)

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1,-20,0,34)
    title.Position = UDim2.new(0,10,0,6)
    title.BackgroundTransparency = 1
    title.Font = Enum.Font.GothamBold
    title.TextSize = 16
    title.TextColor3 = Color3.fromRGB(240,240,240)
    title.Text = "Target Server Found"
    title.Parent = frame

    local info = Instance.new("TextLabel")
    info.Size = UDim2.new(1,-20,0,60)
    info.Position = UDim2.new(0,10,0,40)
    info.BackgroundTransparency = 1
    info.TextWrapped = true
    info.Text = ("Server field '%s' value: %s\nRange: %s - %s"):format(tostring(compareField), tostring(fieldValue), tostring(Svt.TargetMin), tostring(Svt.TargetMax))
    info.Font = Enum.Font.Gotham
    info.TextSize = 14
    info.TextColor3 = Color3.fromRGB(220,220,220)
    info.Parent = frame

    local stayBtn = Instance.new("TextButton")
    stayBtn.Size = UDim2.new(0,140,0,30)
    stayBtn.Position = UDim2.new(0.12,0,1,-40)
    stayBtn.Text = "Stay"
    stayBtn.Parent = frame
    stayBtn.BackgroundColor3 = Color3.fromRGB(80,0,150)
    stayBtn.TextColor3 = Color3.fromRGB(255,255,255)
    addCorner(stayBtn,8)

    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0,140,0,30)
    closeBtn.Position = UDim2.new(0.64,0,1,-40)
    closeBtn.Text = "Close"
    closeBtn.Parent = frame
    closeBtn.BackgroundColor3 = Color3.fromRGB(90,10,110)
    closeBtn.TextColor3 = Color3.fromRGB(255,255,255)
    addCorner(closeBtn,8)

    stayBtn.MouseButton1Click:Connect(function()
        pcall(function() screen:Destroy() end)
    end)
    closeBtn.MouseButton1Click:Connect(function()
        pcall(function() screen:Destroy() end)
    end)
end

-- ===== Full UI =====
local function createUI()
    local parent = getGuiParent()
    pcall(function() parent:FindFirstChild("GicaHubUI"):Destroy() end)

    local screen = Instance.new("ScreenGui")
    screen.Name = "GicaHubUI"
    screen.ResetOnSpawn = false
    screen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screen.Parent = parent

    local frame = Instance.new("Frame")
    frame.Name = "MainFrame"
    frame.Size = UDim2.new(0,420,0,520)
    frame.Position = UDim2.new(0.5,-210,0.5,-260)
    frame.BackgroundColor3 = Color3.fromRGB(28,6,40)
    frame.Parent = screen
    frame.Active = true
    addCorner(frame, 18)

    -- Title area (shows "gicahub v5 secure" as the label)
    local titleBar = Instance.new("Frame")
    titleBar.Size = UDim2.new(1,0,0,40)
    titleBar.BackgroundColor3 = Color3.fromRGB(68,6,120)
    titleBar.Parent = frame
    titleBar.Active = true
    addCorner(titleBar, 14)

    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(1,-140,1,0)
    titleLabel.Position = UDim2.new(0,12,0,0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = "gicahub v5 secure"
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextSize = 18
    titleLabel.TextColor3 = Color3.fromRGB(235,220,255)
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Parent = titleBar

    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0,34,0,30)
    closeBtn.Position = UDim2.new(1,-40,0,5)
    closeBtn.Text = "X"
    closeBtn.Parent = titleBar
    addCorner(closeBtn,8)
    closeBtn.BackgroundColor3 = Color3.fromRGB(40,6,70)
    closeBtn.TextColor3 = Color3.fromRGB(255,255,255)

    local minBtn = Instance.new("TextButton")
    minBtn.Size = UDim2.new(0,34,0,30)
    minBtn.Position = UDim2.new(1,-80,0,5)
    minBtn.Text = "-"
    minBtn.Parent = titleBar
    addCorner(minBtn,8)
    minBtn.BackgroundColor3 = Color3.fromRGB(40,6,70)
    minBtn.TextColor3 = Color3.fromRGB(255,255,255)

    -- mini icon
    local mini = Instance.new("Frame")
    mini.Size = UDim2.new(0,48,0,48)
    mini.Position = UDim2.new(0.02,0,0.82,0)
    mini.BackgroundColor3 = Color3.fromRGB(110,10,170)
    mini.Parent = screen
    mini.Visible = false
    addCorner(mini, 12)
    local miniBtn = Instance.new("TextButton")
    miniBtn.Size = UDim2.new(1,0,1,0)
    miniBtn.Parent = mini
    miniBtn.BackgroundTransparency = 1

    -- Tabs
    local tabBar = Instance.new("Frame")
    tabBar.Size = UDim2.new(1,-24,0,48)
    tabBar.Position = UDim2.new(0,12,0,52)
    tabBar.BackgroundTransparency = 1
    tabBar.Parent = frame

    local function makeTab(name, x)
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

    -- Content
    local content = Instance.new("Frame")
    content.Size = UDim2.new(1,-24,1,-128)
    content.Position = UDim2.new(0,12,0,112)
    content.BackgroundTransparency = 1
    content.Parent = frame

    -- Main tab
    local main = Instance.new("Frame"); main.Size = UDim2.new(1,0,1,0); main.BackgroundTransparency = 1; main.Parent = content
    local flyBtn = Instance.new("TextButton"); flyBtn.Size = UDim2.new(0,180,0,44); flyBtn.Position = UDim2.new(0,10,0,6); flyBtn.Text = "Toggle Fly"; flyBtn.Parent = main; addCorner(flyBtn,12); flyBtn.Font=Enum.Font.Gotham
    local tpBtn = Instance.new("TextButton"); tpBtn.Size = UDim2.new(0,180,0,44); tpBtn.Position = UDim2.new(0,210,0,6); tpBtn.Text = "Teleport (Click)"; tpBtn.Parent = main; addCorner(tpBtn,12); tpBtn.Font=Enum.Font.Gotham

    local speedLabel = Instance.new("TextLabel"); speedLabel.Size = UDim2.new(0,320,0,28); speedLabel.Position = UDim2.new(0,10,0,64); speedLabel.BackgroundTransparency = 1; speedLabel.Text = "WalkSpeed: "..tostring(Svt.WalkSpeed); speedLabel.Parent = main; speedLabel.Font=Enum.Font.Gotham

    local sliderFrame = Instance.new("Frame"); sliderFrame.Size = UDim2.new(0,380,0,32); sliderFrame.Position = UDim2.new(0,10,0,100); sliderFrame.Parent = main; sliderFrame.BackgroundColor3 = Color3.fromRGB(48,8,78); addCorner(sliderFrame,10)
    local sliderBar = Instance.new("Frame"); sliderBar.Parent = sliderFrame; sliderBar.Size = UDim2.new((Svt.WalkSpeed/200),0,1,0); sliderBar.BackgroundColor3 = Color3.fromRGB(200,100,255); addCorner(sliderBar,8)
    local sliderHandle = Instance.new("TextButton"); sliderHandle.Size = UDim2.new(0,18,0,32); sliderHandle.Position = UDim2.new((Svt.WalkSpeed/200),-9,0,0); sliderHandle.Parent = sliderFrame; sliderHandle.BackgroundColor3 = Color3.fromRGB(240,200,255); addCorner(sliderHandle,8); sliderHandle.Text = ""

    -- Finder tab
    local finder = Instance.new("Frame"); finder.Size = UDim2.new(1,0,1,0); finder.BackgroundTransparency = 1; finder.Visible = false; finder.Parent = content
    local info = Instance.new("TextLabel"); info.Size = UDim2.new(1,-20,0,60); info.Position = UDim2.new(0,10,0,0); info.BackgroundTransparency = 1;
    info.Text = "Finder sucht Server basierend auf API-Feld '"..tostring(compareField).."'. Trage TargetMin/TargetMax ein und starte." info.Parent = finder; info.Font=Enum.Font.Gotham; info.TextWrapped=true
    local startBtn = Instance.new("TextButton"); startBtn.Size = UDim2.new(0,160,0,44); startBtn.Position = UDim2.new(0,10,0,70); startBtn.Text="Start Finder"; startBtn.Parent = finder; addCorner(startBtn,10)
    local stopBtn = Instance.new("TextButton"); stopBtn.Size = UDim2.new(0,160,0,44); stopBtn.Position = UDim2.new(0,190,0,70); stopBtn.Text="Stop Finder"; stopBtn.Parent = finder; addCorner(stopBtn,10)

    local tminLabel = Instance.new("TextLabel"); tminLabel.Size = UDim2.new(0,190,0,26); tminLabel.Position = UDim2.new(0,10,0,134); tminLabel.BackgroundTransparency = 1; tminLabel.Text="TargetMin ("..tostring(compareField).."):"; tminLabel.Font=Enum.Font.Gotham; tminLabel.Parent=finder
    local tminBox = Instance.new("TextBox"); tminBox.Size = UDim2.new(0,190,0,30); tminBox.Position = UDim2.new(0,10,0,160); tminBox.Text = tostring(Svt.TargetMin); tminBox.ClearTextOnFocus = false; tminBox.BackgroundColor3 = Color3.fromRGB(50,0,70); tminBox.TextColor3 = Color3.fromRGB(255,255,255); tminBox.Parent = finder; addCorner(tminBox,8)

    local tmaxLabel = Instance.new("TextLabel"); tmaxLabel.Size = UDim2.new(0,190,0,26); tmaxLabel.Position = UDim2.new(0,210,0,134); tmaxLabel.BackgroundTransparency = 1; tmaxLabel.Text="TargetMax ("..tostring(compareField).."):"; tmaxLabel.Font=Enum.Font.Gotham; tmaxLabel.Parent=finder
    local tmaxBox = Instance.new("TextBox"); tmaxBox.Size = UDim2.new(0,190,0,30); tmaxBox.Position = UDim2.new(0,210,0,160); tmaxBox.Text = tostring(Svt.TargetMax); tmaxBox.ClearTextOnFocus = false; tmaxBox.BackgroundColor3 = Color3.fromRGB(50,0,70); tmaxBox.TextColor3 = Color3.fromRGB(255,255,255); tmaxBox.Parent = finder; addCorner(tmaxBox,8)

    local threshLabel = Instance.new("TextLabel"); threshLabel.Size = UDim2.new(1,-20,0,30); threshLabel.Position = UDim2.new(0,10,0,206); threshLabel.BackgroundTransparency = 1; threshLabel.Text = "Current Range: "..tostring(Svt.TargetMin).." - "..tostring(Svt.TargetMax); threshLabel.Parent = finder; threshLabel.Font=Enum.Font.Gotham

    -- ESP tab
    local espTab = Instance.new("Frame"); espTab.Size = UDim2.new(1,0,1,0); espTab.BackgroundTransparency = 1; espTab.Visible = false; espTab.Parent = content
    local espInfo = Instance.new("TextLabel"); espInfo.Size = UDim2.new(1,-20,0,60); espInfo.Position = UDim2.new(0,10,0,0); espInfo.BackgroundTransparency = 1; espInfo.Text = "ESP: Highlights andere Spieler"; espInfo.Parent = espTab; espInfo.Font=Enum.Font.Gotham; espInfo.TextWrapped = true

    -- dragging
    local dragging=false; local dragStart=Vector2.new(); local startPos=frame.Position
    titleBar.InputBegan:Connect(function(inp) if inp.UserInputType==Enum.UserInputType.MouseButton1 or inp.UserInputType==Enum.UserInputType.Touch then dragging=true; dragStart=inp.Position; startPos=frame.Position; inp.Changed:Connect(function() if inp.UserInputState==Enum.UserInputState.End then dragging=false end end) end end)
    UserInputService.InputChanged:Connect(function(inp) if not dragging then return end if inp.UserInputType==Enum.UserInputType.MouseMovement or inp.UserInputType==Enum.UserInputType.Touch then local delta = inp.Position - dragStart; frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y) end end)

    -- minimize/close
    minBtn.MouseButton1Click:Connect(function() frame.Visible=false; mini.Visible=true end)
    miniBtn.MouseButton1Click:Connect(function() frame.Visible=true; mini.Visible=false end)
    closeBtn.MouseButton1Click:Connect(function() pcall(function() screen:Destroy() end) end)

    -- tab switching
    tMain.MouseButton1Click:Connect(function() main.Visible=true; finder.Visible=false; espTab.Visible=false end)
    tFinder.MouseButton1Click:Connect(function() main.Visible=false; finder.Visible=true; espTab.Visible=false end)
    tESP.MouseButton1Click:Connect(function() main.Visible=false; finder.Visible=false; espTab.Visible=true end)
    main.Visible = true

    -- hover
    local function addHover(b) b.MouseEnter:Connect(function() pcall(function() b:TweenSize(UDim2.new(b.Size.X.Scale, b.Size.X.Offset+6, b.Size.Y.Scale, b.Size.Y.Offset+4), "Out","Quad",0.12,true) end) end); b.MouseLeave:Connect(function() pcall(function() b:TweenSize(UDim2.new(b.Size.X.Scale, b.Size.X.Offset-6, b.Size.Y.Scale, b.Size.Y.Offset-4), "Out","Quad",0.12,true) end) end) end
    for _,btn in pairs({flyBtn,tpBtn,startBtn,stopBtn,tMain,tFinder,tESP}) do addHover(btn) end

    -- === Fly implementation ===
    local flyActive=false; local BG,BV,hbConn
    local function enableFly()
        local c = LP.Character or LP.CharacterAdded:Wait()
        local hrp = c:FindFirstChild("HumanoidRootPart") or c:WaitForChild("HumanoidRootPart",5)
        if not hrp then return end
        BG = Instance.new("BodyGyro"); BG.Name="GicaHub_BG"; BG.P = 9e4; BG.MaxTorque=Vector3.new(9e9,9e9,9e9); BG.Parent = hrp
        BV = Instance.new("BodyVelocity"); BV.Name="GicaHub_BV"; BV.MaxForce=Vector3.new(9e9,9e9,9e9); BV.Parent = hrp
        hbConn = RunService.Heartbeat:Connect(function()
            local cam = Workspace.CurrentCamera if not cam then return end
            local vel = Vector3.new()
            local grappler = nil
            for _,it in pairs(c:GetChildren()) do if it:IsA("Tool") and tostring(it.Name):lower():match("grap") then grappler = it; break end end
            if grappler then vel = cam.CFrame.LookVector * (Svt.FlySpeed * 25) else vel = cam.CFrame.LookVector * (Svt.FlySpeed * 50) end
            BG.CFrame = cam.CFrame; BV.Velocity = vel
        end)
    end
    local function disableFly() if hbConn then hbConn:Disconnect(); hbConn=nil end if BG and BG.Parent then pcall(function() BG:Destroy() end) end if BV and BV.Parent then pcall(function() BV:Destroy() end) end BG=nil BV=nil end
    flyBtn.MouseButton1Click:Connect(function() flyActive = not flyActive if flyActive then enableFly() else disableFly() end end)

    -- teleport click
    tpBtn.MouseButton1Click:Connect(function()
        local mouse = LP:GetMouse()
        local c = LP.Character or LP.CharacterAdded:Wait()
        local hrp = c:FindFirstChild("HumanoidRootPart") or c:WaitForChild("HumanoidRootPart",5)
        if not hrp then return end
        if mouse and mouse.Hit then local pos = mouse.Hit.Position + Vector3.new(0,3,0); pcall(function() hrp.CFrame = CFrame.new(pos) end) end
    end)

    -- slider
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

    -- finder controls
    startBtn.MouseButton1Click:Connect(function()
        if scanning then return end
        -- sanitize input boxes
        local okmin, nmin = pcall(function() return tonumber(tminBox.Text) end)
        local okmax, nmax = pcall(function() return tonumber(tmaxBox.Text) end)
        if not (okmin and okmax and type(nmin)=="number" and type(nmax)=="number" and nmin <= nmax) then
            warn("GicaHub Finder: Ungültige TargetMin/TargetMax Werte (bitte korrekte Zahlen eingeben).")
            tminBox.Text = tostring(Svt.TargetMin)
            tmaxBox.Text = tostring(Svt.TargetMax)
            return
        end
        Svt.TargetMin = nmin; Svt.TargetMax = nmax; Save()
        scanning = true; Svt.ProsScannerEnabled = true; Save()
        local sid, nextCursor, fieldVal = pickNextServerByRange(Svt.TargetMin, Svt.TargetMax)
        if sid then
            teleportToInstanceAndPersist(sid)
        else
            scanning=false; Svt.ProsScannerEnabled=false; Save(); warn("GicaHub Finder: Keine passenden Server in API-Scan gefunden.")
        end
    end)
    stopBtn.MouseButton1Click:Connect(function() scanning=false; Svt.ProsScannerEnabled=false; Save(); warn("GicaHub Finder: gestoppt") end)

    -- update displayed range if user edits boxes
    local function sanitizeAndSaveRange()
        local okmin, nmin = pcall(function() return tonumber(tminBox.Text) end)
        local okmax, nmax = pcall(function() return tonumber(tmaxBox.Text) end)
        if okmin and okmax and type(nmin)=="number" and type(nmax)=="number" and nmin <= nmax then
            Svt.TargetMin = nmin; Svt.TargetMax = nmax; Save()
            threshLabel.Text = "Current Range: "..tostring(Svt.TargetMin).." - "..tostring(Svt.TargetMax)
        else
            tminBox.Text = tostring(Svt.TargetMin)
            tmaxBox.Text = tostring(Svt.TargetMax)
        end
    end
    tminBox.FocusLost:Connect(function() sanitizeAndSaveRange() end)
    tmaxBox.FocusLost:Connect(function() sanitizeAndSaveRange() end)

    -- resume scanning on spawn if flagged (popup callback shows popup)
    LP.CharacterAdded:Connect(function(char)
        wait(0.9)
        local h = char:FindFirstChildOfClass("Humanoid")
        if h then pcall(function() h.WalkSpeed = Svt.WalkSpeed end) end
        if Svt.ProsScannerEnabled then pcall(function() resumeScanIfNeeded(showFoundPopup) end) end
    end)

    -- initial apply & resume if needed
    spawn(function()
        local c = LP.Character
        if c then local h = c:FindFirstChildOfClass("Humanoid") if h then pcall(function() h.WalkSpeed = Svt.WalkSpeed end) end end
        wait(1.2)
        if Svt.ProsScannerEnabled then pcall(function() resumeScanIfNeeded(showFoundPopup) end) end
    end)
end

-- ===== Login UI (label "gicahub v5 secure") =====
local function createLoginUI(callback)
    local parent = getGuiParent()
    pcall(function() parent:FindFirstChild("GicaHubLoginUI"):Destroy() end)
    local screen = Instance.new("ScreenGui"); screen.Name = "GicaHubLoginUI"; screen.ResetOnSpawn = false; screen.Parent = parent
    local frame = Instance.new("Frame"); frame.Size = UDim2.new(0,320,0,160); frame.Position = UDim2.new(0.5,-160,0.5,-80); frame.BackgroundColor3 = Color3.fromRGB(30,0,40); frame.Parent = screen; addCorner(frame,12)
    local lbl = Instance.new("TextLabel"); lbl.Size = UDim2.new(1,-20,0,48); lbl.Position = UDim2.new(0,10,0,8); lbl.BackgroundTransparency=1; lbl.Text="gicahub v5 secure"; lbl.Font=Enum.Font.GothamBold; lbl.TextSize=18; lbl.TextColor3=Color3.fromRGB(255,255,255); lbl.Parent = frame
    local txt = Instance.new("TextBox"); txt.Size = UDim2.new(1,-20,0,40); txt.Position = UDim2.new(0,10,0,66); txt.ClearTextOnFocus=false; txt.BackgroundColor3=Color3.fromRGB(50,0,70); txt.TextColor3=Color3.fromRGB(255,255,255); txt.PlaceholderText="Enter secret..."; txt.Parent = frame; addCorner(txt,8)
    local btn = Instance.new("TextButton"); btn.Size = UDim2.new(0,100,0,30); btn.Position = UDim2.new(0.5,-50,1,-40); btn.BackgroundColor3=Color3.fromRGB(80,0,150); btn.Text="Submit"; btn.Parent=frame; addCorner(btn,8)
    btn.MouseButton1Click:Connect(function()
        if txt.Text == "GicaHub1" then
            pcall(function() screen:Destroy() end)
            callback()
        else
            txt.Text = ""
            txt.PlaceholderText = "invalid"
        end
    end)
end

-- ===== Start =====
createLoginUI(function() createUI() end)
print("✅ Gica Hub v5 Ultra Compact — KRNL (gicahub v5 secure). Finder now filters servers by API field '"..tostring(compareField).."'; TargetMin/Max editable.")

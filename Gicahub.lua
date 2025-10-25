-- 🌌 GicaHub AutoJoiner v2 – lila pulsierend, Key, Close/Minimize, Drag, GH, WebSocket & AutoBypass
(function()
    repeat task.wait() until game:IsLoaded()
    local RunService = game:GetService("RunService")
    local CoreGui = game:GetService("CoreGui")
    local TweenService = game:GetService("TweenService")
    local Players = game:GetService("Players")
    
    local WebSocketURL = "ws://5.255.97.147:6767/10m"
    local UNLOCK_KEY = "GicaHub"
    
    local function now() return os.date("%H:%M:%S") end
    
    -- ---------- UI Setup ----------
    local screen = Instance.new("ScreenGui")
    screen.Name = "AutoJoinerUI"
    screen.ResetOnSpawn = false
    screen.Parent = CoreGui

    local frame = Instance.new("Frame")
    frame.Name = "MainFrame"
    frame.Size = UDim2.new(0, 360, 0, 220)
    frame.Position = UDim2.new(0, 20, 0, 20)
    frame.BackgroundColor3 = Color3.fromRGB(110, 45, 190)
    frame.BorderSizePixel = 0
    frame.Parent = screen
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0,10)

    local title = Instance.new("TextLabel")
    title.Text = "AutoJoiner"
    title.Size = UDim2.new(1, -16, 0, 30)
    title.Position = UDim2.new(0, 8, 0, 8)
    title.BackgroundTransparency = 1
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Font = Enum.Font.GothamBold
    title.TextSize = 18
    title.TextColor3 = Color3.fromRGB(245,245,245)
    title.Parent = frame

    local statusLabel = Instance.new("TextLabel")
    statusLabel.Name = "Status"
    statusLabel.Text = "Status: locked"
    statusLabel.Size = UDim2.new(1, -16, 0, 20)
    statusLabel.Position = UDim2.new(0, 8, 0, 40)
    statusLabel.BackgroundTransparency = 1
    statusLabel.Font = Enum.Font.Gotham
    statusLabel.TextSize = 14
    statusLabel.TextXAlignment = Enum.TextXAlignment.Left
    statusLabel.TextColor3 = Color3.fromRGB(230,230,230)
    statusLabel.Parent = frame

    local jobBox = Instance.new("TextBox")
    jobBox.Name = "JobIdBox"
    jobBox.PlaceholderText = "Job-ID oder Script hier einfügen"
    jobBox.Size = UDim2.new(1, -16, 0, 28)
    jobBox.Position = UDim2.new(0, 8, 0, 66)
    jobBox.BackgroundColor3 = Color3.fromRGB(60, 20, 80)
    jobBox.TextColor3 = Color3.fromRGB(230,230,230)
    jobBox.ClearTextOnFocus = false
    jobBox.Font = Enum.Font.Gotham
    jobBox.TextSize = 14
    jobBox.Parent = frame
    Instance.new("UICorner", jobBox).CornerRadius = UDim.new(0,6)

    local joinBtn = Instance.new("TextButton")
    joinBtn.Name = "JoinBtn"
    joinBtn.Text = "Join Job-ID"
    joinBtn.Size = UDim2.new(0, 120, 0, 28)
    joinBtn.Position = UDim2.new(0, 8, 0, 100)
    joinBtn.BackgroundColor3 = Color3.fromRGB(140, 75, 230)
    joinBtn.Font = Enum.Font.GothamBold
    joinBtn.TextSize = 14
    joinBtn.TextColor3 = Color3.fromRGB(255,255,255)
    joinBtn.Parent = frame
    Instance.new("UICorner", joinBtn).CornerRadius = UDim.new(0,6)

    local toggleBtn = Instance.new("TextButton")
    toggleBtn.Name = "AutoToggle"
    toggleBtn.Text = "Auto-Bypass: OFF"
    toggleBtn.Size = UDim2.new(0, 200, 0, 28)
    toggleBtn.Position = UDim2.new(0, 136, 0, 100)
    toggleBtn.BackgroundColor3 = Color3.fromRGB(80,40,120)
    toggleBtn.Font = Enum.Font.Gotham
    toggleBtn.TextSize = 14
    toggleBtn.TextColor3 = Color3.fromRGB(230,230,230)
    toggleBtn.Parent = frame
    Instance.new("UICorner", toggleBtn).CornerRadius = UDim.new(0,6)

    local logFrame = Instance.new("ScrollingFrame")
    logFrame.Name = "Log"
    logFrame.Position = UDim2.new(0, 8, 0, 136)
    logFrame.Size = UDim2.new(1, -16, 0, 72)
    logFrame.BackgroundTransparency = 1
    logFrame.ScrollBarThickness = 6
    logFrame.Parent = frame
    local uiList = Instance.new("UIListLayout", logFrame)
    uiList.Padding = UDim.new(0,4)
    uiList.SortOrder = Enum.SortOrder.LayoutOrder

    local function appendLog(text)
        local lbl = Instance.new("TextLabel")
        lbl.BackgroundTransparency = 1
        lbl.Size = UDim2.new(1, -8, 0, 16)
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.Font = Enum.Font.Gotham
        lbl.TextSize = 13
        lbl.TextColor3 = Color3.fromRGB(220,220,220)
        lbl.Text = "["..now().."] "..tostring(text)
        lbl.Parent = logFrame
        task.defer(function() logFrame.CanvasPosition = Vector2.new(0, math.huge) end)
    end

    local function setStatus(s)
        statusLabel.Text = "Status: "..s
        appendLog(s)
    end

    -- ---------- Pulsierende lila Farbe ----------
    local tweenInfo = TweenInfo.new(1.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)
    TweenService:Create(frame, tweenInfo, {BackgroundColor3 = Color3.fromRGB(170,85,225)}):Play()
    TweenService:Create(joinBtn, tweenInfo, {BackgroundColor3 = Color3.fromRGB(170,85,225)}):Play()
    TweenService:Create(toggleBtn, tweenInfo, {BackgroundColor3 = Color3.fromRGB(170,85,225)}):Play()

    -- ---------- Lock Overlay ----------
    local overlay = Instance.new("Frame")
    overlay.Name = "LockOverlay"
    overlay.Size = UDim2.new(1,0,1,0)
    overlay.Position = UDim2.new(0,0,0,0)
    overlay.BackgroundColor3 = Color3.fromRGB(20,10,40)
    overlay.BorderSizePixel = 0
    overlay.Parent = screen
    Instance.new("UICorner", overlay).CornerRadius = UDim.new(0,0)

    local lockTitle = Instance.new("TextLabel")
    lockTitle.Text = "Enter Key to unlock"
    lockTitle.Size = UDim2.new(1, -16, 0, 28)
    lockTitle.Position = UDim2.new(0, 8, 0, 12)
    lockTitle.BackgroundTransparency = 1
    lockTitle.Font = Enum.Font.GothamBold
    lockTitle.TextSize = 16
    lockTitle.TextColor3 = Color3.fromRGB(230,230,230)
    lockTitle.TextXAlignment = Enum.TextXAlignment.Center
    lockTitle.Parent = overlay

    local keyBox = Instance.new("TextBox")
    keyBox.Name = "KeyBox"
    keyBox.PlaceholderText = "Key"
    keyBox.Size = UDim2.new(0, 220, 0, 30)
    keyBox.Position = UDim2.new(0.5, -110, 0, 52)
    keyBox.BackgroundColor3 = Color3.fromRGB(60, 20, 80)
    keyBox.TextColor3 = Color3.fromRGB(240,240,240)
    keyBox.ClearTextOnFocus = false
    keyBox.Font = Enum.Font.Gotham
    keyBox.TextSize = 14
    keyBox.Parent = overlay
    Instance.new("UICorner", keyBox).CornerRadius = UDim.new(0,6)

    local unlockBtn = Instance.new("TextButton")
    unlockBtn.Text = "Unlock"
    unlockBtn.Size = UDim2.new(0, 100, 0, 30)
    unlockBtn.Position = UDim2.new(0.5, -50, 0, 92)
    unlockBtn.BackgroundColor3 = Color3.fromRGB(140,75,230)
    unlockBtn.Font = Enum.Font.GothamBold
    unlockBtn.TextSize = 14
    unlockBtn.TextColor3 = Color3.fromRGB(255,255,255)
    unlockBtn.Parent = overlay
    Instance.new("UICorner", unlockBtn).CornerRadius = UDim.new(0,6)

    local attempts = 0
    local function lockFailFeedback()
        attempts = attempts + 1
        appendLog("Wrong key entered (attempt "..attempts..")")
        local origPos = keyBox.Position
        for i=1,6 do
            keyBox.Position = origPos + UDim2.new(0,(i%2==0 and 6 or -6),0,0)
            task.wait(0.03)
        end
        keyBox.Position = origPos
    end
    local function unlockSuccess()
        overlay:Destroy()
        setStatus("ready")
        appendLog("Unlocked with correct Key.")
    end
    unlockBtn.MouseButton1Click:Connect(function()
        if keyBox.Text == UNLOCK_KEY then unlockSuccess() else lockFailFeedback() end
    end)
    keyBox.FocusLost:Connect(function(enterPressed)
        if enterPressed then
            if keyBox.Text == UNLOCK_KEY then unlockSuccess() else lockFailFeedback() end
        end
    end)

    -- ---------- Close / Minimize ----------
    local closeBtn = Instance.new("TextButton")
    closeBtn.Text = "X"
    closeBtn.Size = UDim2.new(0,28,0,28)
    closeBtn.Position = UDim2.new(1,-32,0,4)
    closeBtn.BackgroundColor3 = Color3.fromRGB(200,0,0)
    closeBtn.TextColor3 = Color3.fromRGB(255,255,255)
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.TextSize = 16
    closeBtn.Parent = frame
    Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0,6)
    closeBtn.MouseButton1Click:Connect(function() screen:Destroy() end)

    local minimizeBtn = Instance.new("TextButton")
    minimizeBtn.Text = "_"
    minimizeBtn.Size = UDim2.new(0,28,0,28)
    minimizeBtn.Position = UDim2.new(1,-64,0,4)
    minimizeBtn.BackgroundColor3 = Color3.fromRGB(100,0,200)
    minimizeBtn.TextColor3 = Color3.fromRGB(255,255,255)
    minimizeBtn.Font = Enum.Font.GothamBold
    minimizeBtn.TextSize = 16
    minimizeBtn.Parent = frame
    Instance.new("UICorner", minimizeBtn).CornerRadius = UDim.new(0,6)

    local miniFrame = Instance.new("TextButton")
    miniFrame.Size = UDim2.new(0,60,0,60)
    miniFrame.Position = UDim2.new(0,20,0,20)
    miniFrame.BackgroundColor3 = Color3.fromRGB(170,85,225)
    miniFrame.Text = "GH"
    miniFrame.TextColor3 = Color3.fromRGB(255,255,255)
    miniFrame.Font = Enum.Font.GothamBold
    miniFrame.TextSize = 24
    miniFrame.Visible = false
    miniFrame.Parent = screen
    Instance.new("UICorner", miniFrame).CornerRadius = UDim.new(0,6)
    minimizeBtn.MouseButton1Click:Connect(function()
        frame.Visible = false
        miniFrame.Visible = true
    end)
    miniFrame.MouseButton1Click:Connect(function()
        frame.Visible = true
        miniFrame.Visible = false
    end)

    -- ---------- Drag/Touch ----------
    local dragging=false; local dragInput, mousePos, framePos
    local function update(input)
        local delta = input.Position - mousePos
        frame.Position = UDim2.new(frame.Position.X.Scale, framePos.X.Offset+delta.X,
                                   frame.Position.Y.Scale, framePos.Y.Offset+delta.Y)
    end
    frame.InputBegan:Connect(function(input)
        if input.UserInputType==Enum.UserInputType.Touch or input.UserInputType==Enum.UserInputType.MouseButton1 then
            dragging=true; dragInput=input; mousePos=input.Position; framePos=frame.Position
            input.Changed:Connect(function()
                if input.UserInputState==Enum.UserInputState.End then dragging=false end
            end)
        end
    end)
    frame.InputChanged:Connect(function(input) if input.UserInputType==Enum.UserInputType.Touch then dragInput=input end end)
    RunService.RenderStepped:Connect(function() if dragging and dragInput then update(dragInput) end end)

    -- ---------- AutoJoiner Funktionen ----------
    local autoBypass = false
    toggleBtn.MouseButton1Click:Connect(function()
        autoBypass = not autoBypass
        toggleBtn.Text = "Auto-Bypass: "..(autoBypass and "ON" or "OFF")
        toggleBtn.BackgroundColor3 = autoBypass and Color3.fromRGB(140,75,230) or Color3.fromRGB(80,40,120)
        setStatus("Auto-Bypass set to "..tostring(autoBypass))
    end)

    local function prints(str)
        print("[AutoJoiner]: "..str)
        appendLog(str)
    end

    local function bypass10M(jobId)
        if jobBox then jobBox.Text=jobId end
        prints("Textbox updated: "..jobId.." (10m+ bypass)")
        -- find external join button (if exists)
        local targetBtn = joinBtn
        task.defer(function()
            task.wait(0.05)
            if targetBtn and typeof(targetBtn)=="Instance" then
                if getconnections then
                    for _, conn in ipairs(getconnections(targetBtn.MouseButton1Click)) do
                        pcall(function() conn:Fire() end)
                    end
                end
                pcall(function() targetBtn:Activate() end)
                pcall(function() targetBtn.MouseButton1Click:Fire() end)
                prints("Join server clicked (10m+ bypass)")
            else
                prints("Kein Join-Button gefunden zum Klicken.")
            end
        end)
    end

    local function justJoin(script)
        local func, err = loadstring(script)
        if func then
            local ok, result = pcall(func)
            if ok then prints("Script executed successfully.") else prints("Error executing script: "..tostring(result)) end
        else prints("Error compiling script: "..tostring(err)) end
    end

    joinBtn.MouseButton1Click:Connect(function()
        local text = tostring(jobBox.Text or "")
        if text:match("%S") then
            if string.find(text,"TeleportService") then
                setStatus("Running script from UI input...")
                justJoin(text)
            else
                setStatus("Trigger bypass for Job-ID: "..text)
                bypass10M(text)
            end
        else setStatus("Kein Job-ID oder Script eingegeben.") end
    end)

    -- ---------- WebSocket Loop ----------
    local function connect()
        while true do
            prints("Trying to connect to "..WebSocketURL)
            local success, socket = pcall(function() return WebSocket and WebSocket.connect and WebSocket.connect(WebSocketURL) end)
            if success and socket then
                prints("Connected to WebSocket")
                setStatus("connected")
                local ws = socket
                if ws.OnMessage then
                    ws.OnMessage:Connect(function(msg)
                        prints("Message received: "..tostring(msg))
                        if not string.find(msg,"TeleportService") then
                            prints("Bypassing 10m server: "..tostring(msg))
                            if autoBypass then bypass10M(msg) else if jobBox then jobBox.Text=msg; setStatus("Received Job-ID (auto bypass off)") end end
                        else
                            prints("Running script: "..tostring(msg))
                            justJoin(msg)
                        end
                    end)
                end
                local closed=false
                if ws.OnClose then
                    ws.OnClose:Connect(function()
                        if not closed then closed=true; prints("WebSocket closed, reconnecting..."); setStatus("disconnected"); task.wait(1); connect() end
                    end)
                end
                break
            else
                prints("Unable to connect to websocket, retrying..")
                setStatus("disconnected (retrying)")
                task.wait(1)
            end
        end
    end

    task.spawn(connect)
    prints("UI initialized. Enter Key to unlock.")
end)()

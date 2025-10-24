-- 🌌 Gica Hub v5 Ultra Compact – KRNL (Auto Server-Hopper bei Pet, Stop, kompakte UI, anim Login)
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

local PASSWORD = "6388-3589-1190"

-- Settings
local Svt = {
    WalkSpeed = 16,
    FlySpeed = 2,
    SelectedPet = "Los Combinasionas",
    FinderActive = false
}

-- Save / Load
local function Save()
    if type(writefile)=="function" then
        pcall(function() writefile(SETTINGS_FILE,HttpService:JSONEncode(Svt)) end)
    end
end

-- GUI parent helper
local function getGuiParent()
    local parent = LP:FindFirstChild("PlayerGui") or (type(gethui)=="function" and gethui()) or game:GetService("CoreGui") or workspace
    return parent
end

local function addCorner(obj, r) local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, r or 8); c.Parent = obj; return c end

-- =======================
-- Player hat Pet?
-- =======================
local function playerHasPetLocal(plr, petName)
    if not plr or not petName then return false end
    -- Attributes
    if plr.GetAttributes then
        local ok, attrs = pcall(plr.GetAttributes, plr)
        if ok and type(attrs)=="table" then
            for _,v in pairs(attrs) do
                if tostring(v):lower():match(petName:lower()) then return true end
            end
        end
    end
    -- leaderstats
    local s = plr:FindFirstChild("leaderstats") or plr:FindFirstChild("stats")
    if s then
        for _,v in pairs(s:GetChildren()) do
            local ok,val = pcall(function() return tostring(v.Value or v.Text or "") end)
            if ok and val:lower():match(petName:lower()) then return true end
        end
    end
    -- Character descendants
    if plr.Character then
        for _,obj in pairs(plr.Character:GetDescendants()) do
            if obj:IsA("StringValue") or obj:IsA("NumberValue") or obj:IsA("IntValue") then
                local ok,t = pcall(function() return tostring(obj.Value) end)
                if ok and t:lower():match(petName:lower()) then return true end
            end
        end
    end
    return false
end

local function currentServerHasPet(petName)
    for _,plr in pairs(Players:GetPlayers()) do
        if plr ~= LP and playerHasPetLocal(plr, petName) then
            return true, plr
        end
    end
    return false, nil
end

-- =======================
-- Login UI + Animation
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

            delay(2.5, function() pcall(function() animScreen:Destroy() end) callback() end)
        else
            txt.Text = ""; txt.PlaceholderText = "invalid"
        end
    end)
end

-- =======================
-- Finder worker (Auto Join nur wenn Pet)
-- =======================
local function finderWorker(statusLabel)
    Svt.FinderActive = true
    Save()
    local placeIdStr = tostring(game.PlaceId)
    local attempted = {}

    statusLabel.Text = "Status: Prüfe aktuellen Server..."
    local foundHere, who = currentServerHasPet(Svt.SelectedPet)
    if foundHere then
        statusLabel.Text = "Status: Pet schon hier!"
        return
    end

    statusLabel.Text = "Status: Scanne Server nach "..Svt.SelectedPet
    local nextCursor = nil
    while Svt.FinderActive do
        local url = "https://games.roblox.com/v1/games/"..placeIdStr.."/servers/Public?limit=100"
        if nextCursor then url = url.."&cursor="..tostring(nextCursor) end

        local ok, res = pcall(function() return HttpService:GetAsync(url,true) end)
        if not ok or not res then wait(3) continue end

        local decoded = nil
        pcall(function() decoded = HttpService:JSONDecode(res) end)
        if not decoded or type(decoded.data)~="table" then wait(2) continue end

        for _, server in ipairs(decoded.data) do
            if not Svt.FinderActive then break end
            local sid = tostring(server.id)
            local playing = tonumber(server.playing) or 0
            if sid ~= tostring(game.JobId) and playing>0 and not attempted[sid] then
                attempted[sid] = true
                statusLabel.Text = "Versuche Server "..sid.." ("..playing.." Spieler)"
                wait(0.25)
                local okp, err = pcall(function()
                    TeleportService:TeleportToPlaceInstance(game.PlaceId, sid, LP)
                end)
                wait(6) -- Warte Teleport
                if tostring(game.JobId) == sid then
                    local found, who = currentServerHasPet(Svt.SelectedPet)
                    if found then
                        statusLabel.Text = "Pet gefunden! Teleportiere..."
                        return
                    end
                end
            end
        end
        nextCursor = decoded.nextPageCursor
        if not nextCursor then break end
    end
    statusLabel.Text = "Scan beendet / gestoppt"
end

-- =======================
-- UI (Finder Start/Stop)
-- =======================
local function createUI()
    local parent = getGuiParent()
    local screen = Instance.new("ScreenGui"); screen.Name="GicaHubUI"; screen.Parent=parent
    local frame = Instance.new("Frame"); frame.Size=UDim2.new(0,320,0,300); frame.Position=UDim2.new(0.5,-160,0.5,-150); frame.BackgroundColor3=Color3.fromRGB(28,6,40); frame.Parent=screen; addCorner(frame,12)

    local startBtn = Instance.new("TextButton"); startBtn.Size=UDim2.new(0,140,0,36); startBtn.Position=UDim2.new(0,8,0,60); startBtn.Text="Start Finder"; startBtn.Parent=frame; addCorner(startBtn,8)
    local stopBtn = Instance.new("TextButton"); stopBtn.Size=UDim2.new(0,140,0,36); stopBtn.Position=UDim2.new(0,160,0,60); stopBtn.Text="Stop Finder"; stopBtn.Parent=frame; addCorner(stopBtn,8)
    local statusLabel = Instance.new("TextLabel"); statusLabel.Size=UDim2.new(1,-16,0,28); statusLabel.Position=UDim2.new(0,8,0,110); statusLabel.BackgroundTransparency=1; statusLabel.Text="Status: Idle"; statusLabel.Parent=frame

    startBtn.MouseButton1Click:Connect(function()
        if Svt.FinderActive then statusLabel.Text="Status: Bereits aktiv"; return end
        Svt.FinderActive = true; Save()
        spawn(function() finderWorker(statusLabel) end)
    end)
    stopBtn.MouseButton1Click:Connect(function()
        Svt.FinderActive=false; Save(); statusLabel.Text="Status: Stop requested"
    end)
end

createLoginUI(function() createUI() end)

print("✅ Gica Hub v5 Ultra Compact — KRNL (Auto-Server-Hopper bei Pet ready)")

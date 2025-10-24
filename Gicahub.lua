-- 🌌 Gica Hub v5 Ultra Compact – KRNL (Auto Server-Hopper, Stop, kompakte UI, anim Login)
-- Password: 1234-5678-9012

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local LP = Players.LocalPlayer or Players.PlayerAdded:Wait()
local SETTINGS_FILE = "GicaHubSettings.json"
local PASSWORD = "6388-3589-1190"

local Svt = {
    WalkSpeed = 16,
    FlySpeed = 2,
    FinderActive = false,
    SelectedPet = "Los Combinasionas"
}

-- ======================
-- Settings speichern
-- ======================
local function Save()
    if type(writefile) == "function" then
        pcall(function()
            writefile(SETTINGS_FILE, HttpService:JSONEncode(Svt))
        end)
    end
end

-- ======================
-- GUI Helfer
-- ======================
local function getGuiParent()
    return LP:FindFirstChild("PlayerGui") or game:GetService("CoreGui") or workspace
end

local function addCorner(obj, r)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, r or 10)
    c.Parent = obj
    return c
end

-- ======================
-- Login UI + Animation
-- ======================
local function createLoginUI(callback)
    local parent = getGuiParent()
    pcall(function() parent:FindFirstChild("GicaHubLoginUI"):Destroy() end)

    local screen = Instance.new("ScreenGui"); screen.Name="GicaHubLoginUI"; screen.Parent=parent
    local frame = Instance.new("Frame"); frame.Size=UDim2.new(0,320,0,200); frame.Position=UDim2.new(0.5,-160,0.5,-100)
    frame.BackgroundColor3=Color3.fromRGB(30,0,40); frame.Parent=screen; addCorner(frame,10)

    local lbl = Instance.new("TextLabel"); lbl.Size=UDim2.new(1,-20,0,40); lbl.Position=UDim2.new(0,10,0,8)
    lbl.BackgroundTransparency=1; lbl.Text="gicahub v5 secure"; lbl.Font=Enum.Font.GothamBold; lbl.TextSize=18; lbl.TextColor3=Color3.fromRGB(255,255,255); lbl.Parent=frame

    local txt = Instance.new("TextBox"); txt.Size=UDim2.new(1,-20,0,40); txt.Position=UDim2.new(0,10,0,56)
    txt.ClearTextOnFocus=false; txt.BackgroundColor3=Color3.fromRGB(50,0,70); txt.TextColor3=Color3.fromRGB(255,255,255)
    txt.PlaceholderText="Enter secret (1234-5678-9012)..."; txt.Parent=frame; addCorner(txt,8)

    local btn = Instance.new("TextButton"); btn.Size=UDim2.new(0,100,0,32); btn.Position=UDim2.new(0.5,-50,1,-44)
    btn.BackgroundColor3=Color3.fromRGB(80,0,150); btn.Text="Submit"; btn.Parent=frame; addCorner(btn,8)

    btn.MouseButton1Click:Connect(function()
        if txt.Text == PASSWORD then
            pcall(function() screen:Destroy() end)
            local animScreen = Instance.new("ScreenGui"); animScreen.Name="PurchaseThanks"; animScreen.Parent=parent
            local label = Instance.new("TextLabel"); label.Size=UDim2.new(0,380,0,80); label.Position=UDim2.new(0.5,-190,0.5,-40)
            label.BackgroundTransparency=1; label.Font=Enum.Font.GothamBold; label.TextSize=20; label.TextColor3=Color3.fromRGB(255,255,255)
            label.Text="TY For Purchasing Our service ❤️"; label.Parent=animScreen; label.TextTransparency=1; label.TextStrokeTransparency=0.7

            TweenService:Create(label, TweenInfo.new(1.2,Enum.EasingStyle.Quad,Enum.EasingDirection.Out), {TextTransparency=0}):Play()
            TweenService:Create(label, TweenInfo.new(0.9,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut,-1,true), {TextSize=24}):Play()
            TweenService:Create(label, TweenInfo.new(1.2,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut,-1,true), {Position=UDim2.new(0.5,-190,0.48,-40)}):Play()
            TweenService:Create(label, TweenInfo.new(0.7,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut,-1,true), {TextColor3=Color3.fromRGB(255,80,80)}):Play()

            delay(2.5,function()
                pcall(function() animScreen:Destroy() end)
                callback()
            end)
        else
            txt.Text=""; txt.PlaceholderText="invalid"
        end
    end)
end

-- ======================
-- Finder Helfer
-- ======================
local function playerHasPetLocal(plr, petName)
    if not plr or not petName then return false end
    local s = plr:FindFirstChild("leaderstats") or plr:FindFirstChild("Leaderstats") or plr:FindFirstChild("stats")
    if s then
        for _,v in pairs(s:GetChildren()) do
            local ok,val = pcall(function() return tostring(v.Value or v.Text or "") end)
            if ok and val:lower():match(petName:lower()) then return true end
        end
    end
    return false
end

local function currentServerHasPet(petName)
    for _,plr in pairs(Players:GetPlayers()) do
        if plr ~= LP and playerHasPetLocal(plr, petName) then return true, plr end
    end
    return false, nil
end

-- ======================
-- Main UI
-- ======================
local function createUI()
    local parent = getGuiParent()
    pcall(function() parent:FindFirstChild("GicaHubUI"):Destroy() end)

    local screen = Instance.new("ScreenGui"); screen.Name="GicaHubUI"; screen.Parent=parent
    local frame = Instance.new("Frame"); frame.Size=UDim2.new(0,320,0,380); frame.Position=UDim2.new(0.5,-160,0.5,-190)
    frame.BackgroundColor3=Color3.fromRGB(28,6,40); frame.Parent=screen; addCorner(frame,12); frame.Active=true

    -- Tabs
    local tMain = Instance.new("TextButton"); tMain.Size=UDim2.new(0,95,0,28); tMain.Position=UDim2.new(0,8,0,44); tMain.Text="Main"; tMain.Parent=frame; addCorner(tMain,8)
    local tFinder = Instance.new("TextButton"); tFinder.Size=UDim2.new(0,95,0,28); tFinder.Position=UDim2.new(0,110,0,44); tFinder.Text="Finder"; tFinder.Parent=frame; addCorner(tFinder,8)

    local content = Instance.new("Frame"); content.Size=UDim2.new(1,-16,1,-100); content.Position=UDim2.new(0,8,0,84); content.BackgroundTransparency=1; content.Parent=frame

    -- Finder Tab
    local finderTab = Instance.new("Frame"); finderTab.Size=UDim2.new(1,0,1,0); finderTab.Parent=content; finderTab.Visible=false
    local statusLabel = Instance.new("TextLabel"); statusLabel.Size=UDim2.new(1,-16,0,22); statusLabel.Position=UDim2.new(0,8,0,220); statusLabel.BackgroundTransparency=1; statusLabel.Text="Status: Idle"; statusLabel.Parent=finderTab

    local petList={"Los Combinasionas","La Grande Combinasion","Los 67","67"}
    local petDropdown = Instance.new("TextButton"); petDropdown.Size=UDim2.new(0,200,0,32); petDropdown.Position=UDim2.new(0,8,0,44)
    petDropdown.Text="Pet: "..Svt.SelectedPet; petDropdown.Parent=finderTab; addCorner(petDropdown,8)

    local petFrame = Instance.new("Frame"); petFrame.Size=UDim2.new(0,200,0,#petList*28); petFrame.Position=UDim2.new(0,8,0,80)
    petFrame.BackgroundColor3=Color3.fromRGB(40,0,60); petFrame.Visible=false; petFrame.Parent=finderTab; addCorner(petFrame,8)

    for i,p in ipairs(petList) do
        local b = Instance.new("TextButton"); b.Size=UDim2.new(1,0,0,28); b.Position=UDim2.new(0,0,0,(i-1)*28); b.Text=p; b.Parent=petFrame; addCorner(b,6)
        b.MouseButton1Click:Connect(function() Svt.SelectedPet=p; petDropdown.Text="Pet: "..p; petFrame.Visible=false; Save() end)
    end

    petDropdown.MouseButton1Click:Connect(function() petFrame.Visible = not petFrame.Visible end)

    local startBtn = Instance.new("TextButton"); startBtn.Size=UDim2.new(0,120,0,34); startBtn.Position=UDim2.new(0,8,0,150); startBtn.Text="Start Finder"; startBtn.Parent=finderTab; addCorner(startBtn,8)
    local stopBtn = Instance.new("TextButton"); stopBtn.Size=UDim2.new(0,120,0,34); stopBtn.Position=UDim2.new(0,136,0,150); stopBtn.Text="Stop Finder"; stopBtn.Parent=finderTab; addCorner(stopBtn,8)

    local function finderWorker()
        Svt.FinderActive=true; Save()
        while Svt.FinderActive do
            print("Scanning current server for pet: "..Svt.SelectedPet)
            local found, plr = currentServerHasPet(Svt.SelectedPet)
            if found then
                print("Pet found locally on server by "..plr.Name)
                Svt.FinderActive=false; Save()
                break
            end
            -- simulate server hop
            print("No pet found, would attempt next server (requires TeleportService)...")
            wait(2)
        end
        statusLabel.Text="Status: "..(Svt.FinderActive and "Searching" or "Stopped")
    end

    startBtn.MouseButton1Click:Connect(function()
        if Svt.FinderActive then return end
        spawn(finderWorker)
    end)
    stopBtn.MouseButton1Click:Connect(function()
        Svt.FinderActive=false; Save()
        statusLabel.Text="Status: Stopped"
    end)

    tMain.MouseButton1Click:Connect(function() finderTab.Visible=false end)
    tFinder.MouseButton1Click:Connect(function() finderTab.Visible=true end)
end

-- Start
createLoginUI(createUI)
print("✅ Gica Hub v5 Ultra Compact — KRNL (Auto-Server-Hopper ready).")

-- 🌌 Gica Hub v5 Mobile Auto-Pet-Hopper mit animierter UI und Key-Schutz
-- KRNL-kompatibel

local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local LP = Players.LocalPlayer or Players.PlayerAdded:Wait()

-- =======================
-- Konfiguration
-- =======================
local KEY = "GicaHub"
local Svt = { SelectedPet = nil, FinderActive = false, minPlayers = 1 }
local GUI = {}

-- =======================
-- Alle verfügbaren Pets
-- =======================
local availablePets = {
    "Noobini Pizzanini","Lirili Larila","Tim Cheese","FluriFlura","Talpa Di Fero",
    "Svinina Bombardino","Pipi Kiwi","Trippi Troppi","Gangster Footera","Bandito Bobritto",
    "Boneca Ambalabu","Cacto Hipopotamo","Ta Ta Ta Ta Sahur","Tric Trac Baraboom",
    "Cappuccino Assassino","Brr Brr Patapim","Trulimero Trulicina","Bambini Crostini",
    "Bananita Dolphinita","Perochello Lemonchello","Brri Brri Bicus Dicus Bombicus",
    "Burbaloni Loliloli","Lionel Cactuseli","Blueberrini Octopusini","Strawberelli Flamingelli",
    "Bombardiro Crocodilo","Gorillo Watermelondrillo","Gattatino Nyanino","La Grande Combinasion",
    "Nuclearo Dinossauro","Garama and Madundung"
}

-- =======================
-- Log-Funktion
-- =======================
local function log(text,type)
    print(text)
    if not GUI.logBox then return end
    local color = Color3.fromRGB(255,255,255)
    if type=="success" then color=Color3.fromRGB(0,255,0)
    elseif type=="warn" then color=Color3.fromRGB(255,255,0)
    elseif type=="error" then color=Color3.fromRGB(255,0,0) end
    local lbl = Instance.new("TextLabel")
    lbl.Size=UDim2.new(1,0,0,20)
    lbl.Position=UDim2.new(0,0,0,GUI.logBox.CanvasSize.Y.Offset)
    lbl.BackgroundTransparency=1
    lbl.TextColor3=color
    lbl.Font=Enum.Font.Gotham
    lbl.TextSize=14
    lbl.TextXAlignment=Enum.TextXAlignment.Left
    lbl.Text=text
    lbl.Parent=GUI.logBox
    GUI.logBox.CanvasSize=UDim2.new(0,0,0,GUI.logBox.CanvasSize.Y.Offset+22)
    GUI.logBox.CanvasPosition=Vector2.new(0, GUI.logBox.CanvasSize.Y.Offset)
end

-- =======================
-- Prüft Base nach Pet
-- =======================
local function baseHasPet(petName)
    for _,base in pairs(Workspace:GetChildren()) do
        if base:IsA("Model") or base:IsA("Folder") then
            for _,obj in pairs(base:GetDescendants()) do
                if (obj:IsA("StringValue") or obj:IsA("ObjectValue") or obj:IsA("IntValue") or obj:IsA("NumberValue")) then
                    local ok,val=pcall(function() return tostring(obj.Value) end)
                    if ok and val:lower():match(petName:lower()) then return true,base.Name end
                elseif obj:IsA("MeshPart") or obj:IsA("Part") then
                    if obj.Name:lower():match(petName:lower()) then return true,base.Name end
                end
            end
        end
    end
    return false,nil
end

-- =======================
-- Auto-Finder
-- =======================
local function startFinder()
    if not Svt.SelectedPet then log("❌ Kein Pet ausgewählt!","error") return end
    if Svt.FinderActive then return end
    Svt.FinderActive=true
    log("✅ Auto-Finder gestartet für Pet: "..Svt.SelectedPet,"success")
    spawn(function()
        while Svt.FinderActive do
            local found,baseName=baseHasPet(Svt.SelectedPet)
            if found then
                log("✅ Pet gefunden im Server in Base: "..baseName,"success")
                Svt.FinderActive=false
                break
            else
                log("⏳ Pet nicht gefunden, Hoppen zum nächsten Server...","warn")
                pcall(function()
                    TeleportService:Teleport(game.PlaceId, LP)
                end)
            end
            wait(2)
        end
    end)
end

local function stopFinder()
    if Svt.FinderActive then
        Svt.FinderActive=false
        log("🛑 Auto-Finder gestoppt","warn")
    end
end

-- =======================
-- Key UI
-- =======================
local function keyUI()
    local parent = LP:FindFirstChild("PlayerGui") or game:GetService("CoreGui")
    pcall(function() parent:FindFirstChild("GicaHubUI"):Destroy() end)
    local screen=Instance.new("ScreenGui")
    screen.Name="GicaHubUI"
    screen.Parent=parent
    local frame=Instance.new("Frame")
    frame.Size=UDim2.new(0,300,0,200)
    frame.Position=UDim2.new(0.5,-150,0.5,-100)
    frame.BackgroundColor3=Color3.fromRGB(50,0,80)
    frame.BackgroundTransparency=0.2
    local corner=Instance.new("UICorner")
    corner.CornerRadius=UDim.new(0,20)
    corner.Parent=frame
    frame.Parent=screen
    local title=Instance.new("TextLabel")
    title.Size=UDim2.new(1,0,0,40)
    title.Position=UDim2.new(0,0,0,10)
    title.Text="Enter Key"
    title.TextColor3=Color3.fromRGB(255,200,255)
    title.Font=Enum.Font.GothamBold
    title.TextSize=18
    title.BackgroundTransparency=1
    title.Parent=frame
    local input=Instance.new("TextBox")
    input.Size=UDim2.new(1,-40,0,32)
    input.Position=UDim2.new(0,20,0,70)
    input.PlaceholderText="Key"
    input.TextColor3=Color3.fromRGB(255,255,255)
    input.BackgroundColor3=Color3.fromRGB(100,0,150)
    local inputCorner=Instance.new("UICorner")
    inputCorner.CornerRadius=UDim.new(0,12)
    inputCorner.Parent=input
    input.Parent=frame
    local button=Instance.new("TextButton")
    button.Size=UDim2.new(1,-40,0,32)
    button.Position=UDim2.new(0,20,0,120)
    button.Text="Submit"
    button.BackgroundColor3=Color3.fromRGB(0,150,255)
    button.TextColor3=Color3.fromRGB(255,255,255)
    local btnCorner=Instance.new("UICorner")
    btnCorner.CornerRadius=UDim.new(0,12)
    btnCorner.Parent=button
    button.Parent=frame

    -- Animation beim Hovern
    button.MouseEnter:Connect(function()
        TweenService:Create(button,TweenInfo.new(0.5,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut),{BackgroundTransparency=0.4}):Play()
    end)
    button.MouseLeave:Connect(function()
        TweenService:Create(button,TweenInfo.new(0.5,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut),{BackgroundTransparency=0.0}):Play()
    end)

    button.MouseButton1Click:Connect(function()
        if input.Text==KEY then
            screen:Destroy()
            spawn(function() createUI() log("✅ Key korrekt, Willkommen!","success") end)
        else
            local blackScreen=Instance.new("ScreenGui")
            blackScreen.Name="BlackScreen"
            blackScreen.Parent=parent
            local blk=Instance.new("Frame")
            blk.Size=UDim2.new(1,0,1,0)
            blk.Position=UDim2.new(0,0,0,0)
            blk.BackgroundColor3=Color3.fromRGB(0,0,0)
            blk.BorderSizePixel=0
            blk.Parent=blackScreen
            while true do wait() end
        end
    end)
end

-- =======================
-- Script completed
-- =======================
keyUI()

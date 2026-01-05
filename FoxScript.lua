-- ================== GLOBAL SWITCH ==================
_G.SKYWORLD_ENABLED = true
_G.LINES_ENABLED = true

-- ================== SERVICES ==================
local RS = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local Cam = workspace.CurrentCamera
local Players = game:GetService("Players")
local LP = Players.LocalPlayer

-- ================== AIM + FOV (НЕ ТРОГАЛ) ==================
local smoothFactor = 0.25

local function getHeadScreenPosition(character)
    local head = character:FindFirstChild("Head")
    if head then
        local pos, vis = Cam:WorldToViewportPoint(head.Position)
        return Vector2.new(pos.X, pos.Y), vis
    end
end

local function findClosestPlayerInCircle(center, radius)
    local closest, dist = nil, math.huge
    for _, m in ipairs(workspace:GetChildren()) do
        if m:IsA("Model") and m:FindFirstChild("HumanoidRootPart") and m:FindFirstChild("Head") then
            local hp, vis = getHeadScreenPosition(m)
            if vis then
                local d = (hp - center).Magnitude
                if d <= radius and d < dist then
                    dist = d
                    closest = m
                end
            end
        end
    end
    return closest
end

-- ================== FOV CIRCLE + CROSS ==================
local circle = Drawing.new("Circle")
circle.Radius = 50
circle.Thickness = 2
circle.Transparency = 0.6
circle.Color = Color3.fromRGB(255,255,255)
circle.Filled = false

local crossH = Drawing.new("Line")
local crossV = Drawing.new("Line")
crossH.Thickness = 2
crossV.Thickness = 2
crossH.Color = circle.Color
crossV.Color = circle.Color

-- ================== HITBOX (НЕ ТРОГАЛ) ==================
local HBSizeX, HBSizeY, HBSizeZ = 9, 13, 7
local HBTrans = 0.5
local hitboxlist = {}

task.spawn(function()
    while task.wait(0.2) do
        for _, m in pairs(workspace:GetChildren()) do
            if m:IsA("Model") and m:FindFirstChild("HumanoidRootPart") and not m:FindFirstChild("Fake1") then
                local fh = Instance.new("Part", m)
                fh.Name = "Head"
                fh.Size = Vector3.new(HBSizeX, HBSizeY, HBSizeZ)
                fh.CFrame = m.HumanoidRootPart.CFrame
                fh.Anchored = true
                fh.CanCollide = false
                fh.Transparency = HBTrans
                fh.BrickColor = BrickColor.new("Really red")

                local tag = Instance.new("Part", m)
                tag.Name = "Fake1"

                table.insert(hitboxlist, fh)
            end
        end
    end
end)

-- ================== PLAYER ESP + ЛИНИИ ==================
local ESPObjects = {}
local ESP_COLOR = Color3.fromRGB(0,170,255)

local function CreateESP(model)
    if ESPObjects[model] then return end

    -- Highlight для ESP через стены
    local hl = Instance.new("Highlight")
    hl.Name = "SkyWorldESP"
    hl.FillColor = ESP_COLOR
    hl.OutlineColor = Color3.new(1,1,1)
    hl.FillTransparency = 0.6
    hl.OutlineTransparency = 0
    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    hl.Adornee = model
    hl.Parent = game:GetService("CoreGui")

    -- Линия к игроку
    local line = Drawing.new("Line")
    line.Color = ESP_COLOR
    line.Thickness = 1.5
    line.Transparency = 1
    line.Visible = true

    ESPObjects[model] = {HL = hl, Line = line}
end

-- Создаем ESP для всех моделей
for _, m in pairs(workspace:GetChildren()) do
    if m:IsA("Model") and m:FindFirstChild("HumanoidRootPart") then
        CreateESP(m)
    end
end

workspace.DescendantAdded:Connect(function(m)
    if m:IsA("Model") and m:FindFirstChild("HumanoidRootPart") then
        CreateESP(m)
    end
end)

-- ================== ОБНОВЛЕНИЕ ЛИНИЙ ==================
RS.RenderStepped:Connect(function()
    local center = Vector2.new(Cam.ViewportSize.X/2, Cam.ViewportSize.Y/2)

    for model,data in pairs(ESPObjects) do
        if not _G.SKYWORLD_ENABLED or not model or not model.Parent or not model:FindFirstChild("HumanoidRootPart") then
            data.HL.Enabled = false
            data.Line.Visible = false
        else
            data.HL.Enabled = _G.SKYWORLD_ENABLED
            if _G.LINES_ENABLED then
                local pos, vis = Cam:WorldToViewportPoint(model.HumanoidRootPart.Position)
                if vis and pos.Z > 0 then
                    data.Line.From = center
                    data.Line.To = Vector2.new(pos.X, pos.Y)
                    data.Line.Visible = true
                else
                    data.Line.Visible = false
                end
            else
                data.Line.Visible = false
            end
        end
    end
end)

-- ================== MAIN LOOP ==================
RS.RenderStepped:Connect(function()
    local center = Vector2.new(Cam.ViewportSize.X/2, Cam.ViewportSize.Y/2)

    circle.Position = center
    circle.Visible = _G.SKYWORLD_ENABLED

    local size = 8
    crossH.From = Vector2.new(center.X-size, center.Y)
    crossH.To   = Vector2.new(center.X+size, center.Y)
    crossV.From = Vector2.new(center.X, center.Y-size)
    crossV.To   = Vector2.new(center.X, center.Y+size)

    crossH.Visible = _G.SKYWORLD_ENABLED
    crossV.Visible = _G.SKYWORLD_ENABLED

    if _G.SKYWORLD_ENABLED and UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
        local target = findClosestPlayerInCircle(center, circle.Radius)
        if target and target:FindFirstChild("Head") then
            local sp = Cam:WorldToViewportPoint(target.Head.Position)
            local delta = (Vector2.new(sp.X, sp.Y) - UIS:GetMouseLocation()) * smoothFactor
            mousemoverel(delta.X, delta.Y)
        end
    end
end)

-- ================== MENU ==================
local gui = Instance.new("ScreenGui", LP.PlayerGui)
gui.ResetOnSpawn = false

local frame = Instance.new("Frame", gui)
frame.Size = UDim2.new(0, 160, 0, 100) -- чуть меньше
frame.Position = UDim2.new(0.5, -80, 0.5, -50)
frame.BackgroundColor3 = Color3.fromRGB(25,25,25)
frame.Active = true
frame.Draggable = true
frame.BorderSizePixel = 0
Instance.new("UICorner", frame).CornerRadius = UDim.new(0,14)

-- Заголовок меню
local title = Instance.new("TextLabel", frame)
title.Size = UDim2.new(0.9, 0, 0.2, 0)
title.Position = UDim2.new(0.05, 0, 0.05, 0)
title.Text = "ScriptWorldtbs"
title.Font = Enum.Font.GothamBold
title.TextSize = 16
title.TextColor3 = Color3.new(1,1,1)
title.BackgroundTransparency = 1
title.TextScaled = true

-- Функция для кнопок
local function makeBtn(text, y)
    local b = Instance.new("TextButton", frame)
    b.Size = UDim2.new(0.9,0,0.3,0) -- чуть меньше
    b.Position = UDim2.new(0.05,0,y,0)
    b.Font = Enum.Font.GothamBold
    b.TextSize = 14
    b.TextColor3 = Color3.new(1,1,1)
    b.BackgroundColor3 = Color3.fromRGB(40,40,40)
    Instance.new("UICorner", b).CornerRadius = UDim.new(0,12)
    b.Text = text
    return b
end

local mainBtn = makeBtn("Sky World 🟢", 0.3)
local lineBtn = makeBtn("Линии 🟢", 0.65)

RS.RenderStepped:Connect(function()
    mainBtn.Text = _G.SKYWORLD_ENABLED and "Sky World 🟢" or "Sky World 🔴"
    lineBtn.Text = _G.LINES_ENABLED and "Линии 🟢" or "Линии 🔴"
end)

mainBtn.MouseButton1Click:Connect(function()
    _G.SKYWORLD_ENABLED = not _G.SKYWORLD_ENABLED
    for _, p in pairs(hitboxlist) do
        if p:IsA("Part") then
            p.Transparency = _G.SKYWORLD_ENABLED and HBTrans or 1
        end
    end
end)

lineBtn.MouseButton1Click:Connect(function()
    _G.LINES_ENABLED = not _G.LINES_ENABLED
end)

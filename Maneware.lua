-- Maneware MM2 v2 | Mobile (Delta)
-- Новое: AntiAFK, FPS Boost, Infinite Jump, ESP пистолета и монет, телепорты,
-- AntiFling, SheriffAim (visible check + предсказание)
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local StarterGui = game:GetService("StarterGui")
local VirtualUser = game:GetService("VirtualUser")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local C = {
    BG = Color3.fromRGB(18, 18, 24), SIDEBAR = Color3.fromRGB(24, 24, 32),
    TOPBAR = Color3.fromRGB(28, 28, 38), ELEMENT = Color3.fromRGB(32, 32, 44),
    ACCENT = Color3.fromRGB(99, 102, 241), GREEN = Color3.fromRGB(34, 197, 94),
    RED = Color3.fromRGB(239, 68, 68), TEXT = Color3.fromRGB(240, 240, 245),
    DIM = Color3.fromRGB(120, 120, 140), BORDER = Color3.fromRGB(45, 45, 60),
}

--------------------------------------------------
-- ИКОНКИ: "rbxassetid://ID" или ссылка "https://.../icon.png"
-- Замени любую на свою
--------------------------------------------------
local ICONS = {
    MENU   = "rbxassetid://10734898355",
    HOME   = "rbxassetid://10723407389",
    EYE    = "rbxassetid://10723346959",
    SPEED  = "rbxassetid://10709752035",
    NOCLIP = "rbxassetid://10723346871",
    FLY    = "rbxassetid://10723354359",
    TARGET = "rbxassetid://10734898355",
    HAT    = "rbxassetid://10723407389",
    AIM    = "rbxassetid://10734898355",
    TP     = "rbxassetid://10723354359",
    GUN    = "rbxassetid://10723346959",
    COIN   = "rbxassetid://10709752035",
    SHIELD = "rbxassetid://10723346871",
    UTIL   = "rbxassetid://10723407389",
}

local function resolveIcon(id, name)
    if type(id) == "string" and id:sub(1, 4) == "http" then
        local ok, res = pcall(function()
            local fname = "mw_" .. (name or "icon") .. ".png"
            writefile(fname, game:HttpGet(id))
            return getcustomasset(fname)
        end)
        return ok and res or ""
    end
    return id or ""
end
for k, v in pairs(ICONS) do ICONS[k] = resolveIcon(v, k) end

--------------------------------------------------
-- УТИЛИТЫ
--------------------------------------------------
local function new(class, props, parent)
    local o = Instance.new(class)
    for k, v in pairs(props or {}) do pcall(function() o[k] = v end) end
    if parent then o.Parent = parent end
    return o
end
local function tw(o, t, p)
    local ok, tween = pcall(function()
        return TweenService:Create(o, TweenInfo.new(t, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), p)
    end)
    if ok then tween:Play() return tween end
end
local function corner(r, p) return new("UICorner", {CornerRadius = UDim.new(0, r or 8)}, p) end
local function makeGui(name, order)
    local ok, parent = pcall(function() return gethui and gethui() end)
    return new("ScreenGui", {Name = name, ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = order},
        (ok and parent) or LocalPlayer:WaitForChild("PlayerGui"))
end
local function createIcon(id, size, parent)
    return new("ImageLabel", {Size = size, BackgroundTransparency = 1, Image = id or "",
        ImageColor3 = C.TEXT, ScaleType = Enum.ScaleType.Fit}, parent)
end
local function onTap(btn, fn) btn.Activated:Connect(fn) end
local function notify(text)
    pcall(function()
        StarterGui:SetCore("SendNotification", {Title = "Maneware", Text = text, Duration = 3})
    end)
end

--------------------------------------------------
-- ГЛАВНОЕ ОКНО
--------------------------------------------------
local hubGui = makeGui("ManewareHub", 9999)
local FULL = UDim2.new(0.9, 0, 0.85, 0)
local main = new("Frame", {Size = UDim2.new(0, 0, 0, 0), Position = UDim2.new(0.5, 0, 0.5, 0),
    AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = C.BG, BorderSizePixel = 0,
    ClipsDescendants = true, Active = true}, hubGui)
corner(14, main)
new("UIStroke", {Color = C.BORDER, Thickness = 2}, main)
tw(main, 0.4, {Size = FULL})

local topbar = new("Frame", {Size = UDim2.new(1, 0, 0, 55), BackgroundColor3 = C.TOPBAR, BorderSizePixel = 0, Active = true}, main)
createIcon(ICONS.MENU, UDim2.new(0, 24, 0, 24), topbar).Position = UDim2.new(0, 15, 0.5, -12)
new("TextLabel", {Size = UDim2.new(0.6, 0, 1, 0), Position = UDim2.new(0, 50, 0, 0), BackgroundTransparency = 1,
    Text = "Maneware | MM2 v2", TextColor3 = C.TEXT, TextSize = 16, Font = Enum.Font.GothamBold,
    TextXAlignment = Enum.TextXAlignment.Left}, topbar)
local closeBtn = new("TextButton", {Size = UDim2.new(0, 40, 0, 40), Position = UDim2.new(1, -48, 0.5, -20),
    BackgroundColor3 = C.RED, Text = "✕", TextColor3 = C.TEXT, TextSize = 18, Font = Enum.Font.GothamBold,
    BorderSizePixel = 0}, topbar)
corner(10, closeBtn)

local dragging, dragInput, dragStart, startPos
topbar.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
        dragging, dragStart, startPos = true, i.Position, main.Position
        i.Changed:Connect(function() if i.UserInputState == Enum.UserInputState.End then dragging = false end end)
    end
end)
topbar.InputChanged:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch then dragInput = i end
end)
UIS.InputChanged:Connect(function(i)
    if i == dragInput and dragging then
        local d = i.Position - dragStart
        main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
    end
end)

-- Сайдбар со скроллом (вкладок много)
local sidebar = new("ScrollingFrame", {Size = UDim2.new(0, 140, 1, -55), Position = UDim2.new(0, 0, 0, 55),
    BackgroundColor3 = C.SIDEBAR, BorderSizePixel = 0, ScrollBarThickness = 2,
    AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(0, 0, 0, 0), Active = true,
    ScrollingDirection = Enum.ScrollingDirection.Y}, main)
new("UIListLayout", {Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder}, sidebar)
new("UIPadding", {PaddingTop = UDim.new(0, 8), PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8),
    PaddingBottom = UDim.new(0, 8)}, sidebar)
local content = new("Frame", {Size = UDim2.new(1, -140, 1, -55), Position = UDim2.new(0, 140, 0, 55),
    BackgroundTransparency = 1}, main)

--------------------------------------------------
-- ВКЛАДКИ / ЭЛЕМЕНТЫ
--------------------------------------------------
local tabs, activeTab = {}, nil

local function addTab(name, icon)
    local idx = #tabs + 1
    local page = new("ScrollingFrame", {Size = UDim2.new(1, -16, 1, -16), Position = UDim2.new(0, 8, 0, 8),
        BackgroundTransparency = 1, BorderSizePixel = 0, Visible = false, ScrollBarThickness = 4,
        ScrollBarImageColor3 = C.ACCENT, CanvasSize = UDim2.new(0, 0, 0, 0), Active = true,
        ScrollingDirection = Enum.ScrollingDirection.Y}, content)
    local layout = new("UIListLayout", {Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder}, page)
    layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        page.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 20)
    end)

    local btn = new("TextButton", {Size = UDim2.new(1, 0, 0, 44), BackgroundColor3 = C.ELEMENT,
        BackgroundTransparency = 1, Text = "", AutoButtonColor = false, BorderSizePixel = 0, LayoutOrder = idx}, sidebar)
    corner(8, btn)
    local iconImg = createIcon(icon, UDim2.new(0, 22, 0, 22), btn)
    iconImg.Position = UDim2.new(0, 8, 0.5, -11)
    iconImg.ImageColor3 = C.DIM
    local lbl = new("TextLabel", {Size = UDim2.new(1, -38, 1, 0), Position = UDim2.new(0, 34, 0, 0),
        BackgroundTransparency = 1, Text = name, TextColor3 = C.DIM, TextSize = 13,
        Font = Enum.Font.GothamSemibold, TextXAlignment = Enum.TextXAlignment.Left}, btn)
    tabs[idx] = {page = page, btn = btn, lbl = lbl, icon = iconImg}

    local function switchTab()
        if activeTab then
            activeTab.btn.BackgroundTransparency = 1
            activeTab.lbl.TextColor3 = C.DIM
            activeTab.icon.ImageColor3 = C.DIM
            activeTab.page.Visible = false
        end
        activeTab = tabs[idx]
        btn.BackgroundTransparency = 0
        lbl.TextColor3 = C.TEXT
        iconImg.ImageColor3 = C.TEXT
        page.Visible = true
    end
    onTap(btn, switchTab)
    if idx == 1 then switchTab() end

    local T = {}

    function T.Section(text)
        new("TextLabel", {Size = UDim2.new(1, -8, 0, 30), BackgroundTransparency = 1, Text = text,
            TextColor3 = C.ACCENT, TextSize = 13, Font = Enum.Font.GothamBold,
            TextXAlignment = Enum.TextXAlignment.Left}, page)
    end

    function T.Toggle(text, default, callback, iconId)
        local state = default or false
        local el = new("TextButton", {Size = UDim2.new(1, -8, 0, 56), BackgroundColor3 = C.ELEMENT,
            Text = "", AutoButtonColor = false, BorderSizePixel = 0}, page)
        corner(10, el)
        new("UIStroke", {Color = C.BORDER, Thickness = 1}, el)
        local textX = 14
        if iconId then
            createIcon(iconId, UDim2.new(0, 24, 0, 24), el).Position = UDim2.new(0, 12, 0.5, -12)
            textX = 46
        end
        new("TextLabel", {Size = UDim2.new(1, -textX - 76, 1, 0), Position = UDim2.new(0, textX, 0, 0),
            BackgroundTransparency = 1, Text = text, TextColor3 = C.TEXT, TextSize = 13,
            Font = Enum.Font.GothamSemibold, TextXAlignment = Enum.TextXAlignment.Left, TextWrapped = true}, el)
        local bg = new("Frame", {Size = UDim2.new(0, 54, 0, 28), Position = UDim2.new(1, -66, 0.5, -14),
            BackgroundColor3 = state and C.ACCENT or Color3.fromRGB(55, 55, 70), BorderSizePixel = 0}, el)
        corner(14, bg)
        local dot = new("Frame", {Size = UDim2.new(0, 22, 0, 22),
            Position = state and UDim2.new(1, -25, 0.5, -11) or UDim2.new(0, 3, 0.5, -11),
            BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0}, bg)
        corner(11, dot)
        onTap(el, function()
            state = not state
            tw(bg, 0.2, {BackgroundColor3 = state and C.ACCENT or Color3.fromRGB(55, 55, 70)})
            tw(dot, 0.2, {Position = state and UDim2.new(1, -25, 0.5, -11) or UDim2.new(0, 3, 0.5, -11)})
            if callback then task.spawn(callback, state) end
        end)
    end

    function T.Slider(text, min, max, default, suffix, callback)
        local value = default or min
        local el = new("Frame", {Size = UDim2.new(1, -8, 0, 76), BackgroundColor3 = C.ELEMENT, BorderSizePixel = 0}, page)
        corner(10, el)
        new("UIStroke", {Color = C.BORDER, Thickness = 1}, el)
        new("TextLabel", {Size = UDim2.new(0.65, 0, 0, 25), Position = UDim2.new(0, 14, 0, 8), BackgroundTransparency = 1,
            Text = text, TextColor3 = C.TEXT, TextSize = 13, Font = Enum.Font.GothamSemibold,
            TextXAlignment = Enum.TextXAlignment.Left}, el)
        local val = new("TextLabel", {Size = UDim2.new(0.35, -14, 0, 25), Position = UDim2.new(0.65, 0, 0, 8),
            BackgroundTransparency = 1, Text = value .. (suffix or ""), TextColor3 = C.ACCENT, TextSize = 13,
            Font = Enum.Font.GothamBold, TextXAlignment = Enum.TextXAlignment.Right}, el)
        local bar = new("TextButton", {Size = UDim2.new(1, -28, 0, 14), Position = UDim2.new(0, 14, 0, 48),
            BackgroundColor3 = Color3.fromRGB(45, 45, 60), Text = "", AutoButtonColor = false, BorderSizePixel = 0}, el)
        corner(7, bar)
        local fill = new("Frame", {Size = UDim2.new((value - min) / (max - min), 0, 1, 0),
            BackgroundColor3 = C.ACCENT, BorderSizePixel = 0}, bar)
        corner(7, fill)
        local knob = new("Frame", {Size = UDim2.new(0, 22, 0, 22), Position = UDim2.new(1, -11, 0.5, -11),
            BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0}, fill)
        corner(11, knob)

        local sliding = false
        local function update(input)
            local rel = math.clamp((input.Position.X - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
            value = math.floor(min + (max - min) * rel + 0.5)
            fill.Size = UDim2.new(rel, 0, 1, 0)
            val.Text = value .. (suffix or "")
            if callback then callback(value) end
        end
        bar.InputBegan:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
                sliding = true
                page.ScrollingEnabled = false
                update(i)
            end
        end)
        UIS.InputChanged:Connect(function(i)
            if sliding and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
                update(i)
            end
        end)
        UIS.InputEnded:Connect(function(i)
            if sliding and (i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch) then
                sliding = false
                page.ScrollingEnabled = true
            end
        end)
    end

    function T.Button(text, callback)
        local el = new("TextButton", {Size = UDim2.new(1, -8, 0, 50), BackgroundColor3 = C.ELEMENT,
            Text = text, TextColor3 = C.TEXT, TextSize = 14, Font = Enum.Font.GothamSemibold,
            AutoButtonColor = true, BorderSizePixel = 0}, page)
        corner(10, el)
        new("UIStroke", {Color = C.BORDER, Thickness = 1}, el)
        onTap(el, function() if callback then task.spawn(callback) end end)
    end

    return T
end

--------------------------------------------------
-- ОБЩИЕ ФУНКЦИИ
--------------------------------------------------
local function myChar() return LocalPlayer.Character end
local function myHrp() local c = myChar() return c and c:FindFirstChild("HumanoidRootPart") end
local function myHum() local c = myChar() return c and c:FindFirstChildOfClass("Humanoid") end

local function getRole(p)
    local c = p and p.Character
    if not c then return "Unknown" end
    local b = p:FindFirstChild("Backpack")
    if b then
        if b:FindFirstChild("Knife") or b:FindFirstChild("Classic Knife") then return "Murderer" end
        if b:FindFirstChild("Gun") or b:FindFirstChild("Classic Gun") then return "Sheriff" end
    end
    if c:FindFirstChild("Knife") or c:FindFirstChild("Classic Knife") then return "Murderer" end
    if c:FindFirstChild("Gun") or c:FindFirstChild("Classic Gun") then return "Sheriff" end
    return "Innocent"
end
local function roleColor(r)
    return r == "Murderer" and C.RED or (r == "Sheriff" and Color3.fromRGB(59, 130, 246) or C.GREEN)
end
local function findByRole(role, skipSelf)
    for _, p in ipairs(Players:GetPlayers()) do
        if not (skipSelf and p == LocalPlayer) and getRole(p) == role then return p end
    end
end
local function isGameActive()
    return findByRole("Murderer") ~= nil or findByRole("Sheriff") ~= nil
end

--------------------------------------------------
-- СОСТОЯНИЯ
--------------------------------------------------
local highlightEnabled, espObjects = false, {}
local noclipEnabled, noclipConn = false, nil
local speedEnabled, speedValue = false, 16
local flyEnabled, flySpeed, bodyVel, bodyGyro = false, 50, nil, nil
local flyUp, flyDown = false, false
local targetEspEnabled, targetObj, targetConn = false, nil, nil
local hatEnabled, hat = false, nil
local gunEsp, coinEsp = false, false
local infJump, antiAfk, antiFling = false, true, false

--------------------------------------------------
-- ESP РОЛЕЙ
--------------------------------------------------
local function createHighlight(player)
    if player == LocalPlayer then return end
    local function onChar(char)
        local hum = char:WaitForChild("Humanoid", 3)
        local hrp = char:WaitForChild("HumanoidRootPart", 3)
        if not hum or not hrp then return end
        local old = espObjects[player]
        if old then
            if old.H then old.H:Destroy() end
            if old.B then old.B:Destroy() end
        end
        local role = getRole(player)
        local col = roleColor(role)
        local hl = new("Highlight", {Name = "MWESP", FillColor = col, OutlineColor = col,
            FillTransparency = 0.5, Enabled = highlightEnabled}, char)
        local bb = new("BillboardGui", {Name = "MWBB", Size = UDim2.new(4, 0, 1.5, 0),
            StudsOffset = Vector3.new(0, 3, 0), AlwaysOnTop = true, Enabled = highlightEnabled}, hrp)
        local tl = new("TextLabel", {Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Text = role,
            TextColor3 = col, TextStrokeTransparency = 0, TextScaled = true, Font = Enum.Font.GothamBold}, bb)
        espObjects[player] = {H = hl, B = bb}
        local conn
        conn = RunService.Heartbeat:Connect(function()
            if not char.Parent or hum.Health <= 0 then conn:Disconnect() return end
            local nr = getRole(player)
            if nr ~= role then
                role = nr
                local nc = roleColor(nr)
                hl.FillColor, hl.OutlineColor, tl.TextColor3, tl.Text = nc, nc, nc, nr
            end
        end)
    end
    if player.Character then task.spawn(onChar, player.Character) end
    player.CharacterAdded:Connect(onChar)
end
for _, p in ipairs(Players:GetPlayers()) do createHighlight(p) end
Players.PlayerAdded:Connect(createHighlight)
Players.PlayerRemoving:Connect(function(p) espObjects[p] = nil end)

--------------------------------------------------
-- NOCLIP / SPEED / FLY
--------------------------------------------------
local function toggleNoclip(state)
    noclipEnabled = state
    if noclipConn then noclipConn:Disconnect() noclipConn = nil end
    if state then
        noclipConn = RunService.Stepped:Connect(function()
            local c = myChar()
            if c then
                for _, p in ipairs(c:GetDescendants()) do
                    if p:IsA("BasePart") then p.CanCollide = false end
                end
            end
        end)
    end
end

RunService.Heartbeat:Connect(function()
    if speedEnabled then
        local h = myHum()
        if h and h.WalkSpeed ~= speedValue then h.WalkSpeed = speedValue end
    end
end)

local function startFly()
    local hrp, hum = myHrp(), myHum()
    if not hrp or not hum then return end
    hum.PlatformStand = true
    bodyVel = new("BodyVelocity", {MaxForce = Vector3.new(1e9, 1e9, 1e9), Velocity = Vector3.zero}, hrp)
    bodyGyro = new("BodyGyro", {MaxTorque = Vector3.new(1e9, 1e9, 1e9), P = 9e4, D = 500}, hrp)
    toggleNoclip(true)
end
local function stopFly()
    if bodyVel then bodyVel:Destroy() bodyVel = nil end
    if bodyGyro then bodyGyro:Destroy() bodyGyro = nil end
    local hum = myHum()
    if hum then hum.PlatformStand = false end
    toggleNoclip(false)
end

RunService.RenderStepped:Connect(function(dt)
    if not flyEnabled or not bodyVel or not bodyGyro then return end
    local hrp, hum = myHrp(), myHum()
    if not hrp or not hum then return end
    local cf = Camera.CFrame
    local rel = cf:VectorToObjectSpace(hum.MoveDirection)
    local dir = cf.LookVector * -rel.Z + cf.RightVector * rel.X
    if UIS:IsKeyDown(Enum.KeyCode.Space) or flyUp then dir += Vector3.yAxis end
    if UIS:IsKeyDown(Enum.KeyCode.LeftShift) or flyDown then dir -= Vector3.yAxis end
    if dir.Magnitude > 0 then
        bodyVel.Velocity = bodyVel.Velocity:Lerp(dir.Unit * flySpeed, math.min(1, dt * 12))
    else
        bodyVel.Velocity = bodyVel.Velocity:Lerp(Vector3.zero, math.min(1, dt * 8))
    end
    local look = cf.LookVector
    bodyGyro.CFrame = CFrame.lookAt(hrp.Position, hrp.Position + Vector3.new(look.X, 0, look.Z))
end)

local flyGui = makeGui("ManewareFly", 99998)
flyGui.Enabled = false
local function flyBtn(text, yOff, setter)
    local b = new("TextButton", {Size = UDim2.new(0, 64, 0, 64), Position = UDim2.new(1, -90, 1, yOff),
        BackgroundColor3 = C.ACCENT, BackgroundTransparency = 0.2, Text = text, TextColor3 = C.TEXT,
        TextSize = 28, Font = Enum.Font.GothamBold, AutoButtonColor = false, BorderSizePixel = 0}, flyGui)
    corner(32, b)
    b.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1 then setter(true) end
    end)
    b.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1 then setter(false) end
    end)
end
flyBtn("▲", -240, function(v) flyUp = v end)
flyBtn("▼", -170, function(v) flyDown = v end)

--------------------------------------------------
-- TARGET ESP / CHINA HAT
--------------------------------------------------
local function removeTarget()
    if targetConn then targetConn:Disconnect() targetConn = nil end
    if targetObj then targetObj:Destroy() targetObj = nil end
end
local function applyTarget()
    removeTarget()
    if not targetEspEnabled then return end
    local part = new("Part", {Name = "MWTarget", Size = Vector3.new(1.5, 1.5, 1.5), Anchored = true,
        CanCollide = false, Transparency = 1}, workspace)
    new("BoxHandleAdornment", {Adornee = part, Size = part.Size, Color3 = C.GREEN, Transparency = 0.85,
        AlwaysOnTop = true, ZIndex = 1}, part)
    new("SelectionBox", {Adornee = part, Color3 = Color3.fromRGB(50, 255, 50), LineThickness = 0.06,
        SurfaceTransparency = 1}, part)
    targetObj = part
    local angle = 0
    targetConn = RunService.RenderStepped:Connect(function(dt)
        if not targetEspEnabled or not part.Parent then removeTarget() return end
        local shown = false
        if isGameActive() then
            local p = findByRole("Murderer")
            local ch = p and p.Character
            local r = ch and ch:FindFirstChild("HumanoidRootPart")
            local h = ch and ch:FindFirstChildOfClass("Humanoid")
            if r and h and h.Health > 0 then
                angle += dt * 50
                part.CFrame = CFrame.new(r.Position + Vector3.new(0, 3.5, 0)) * CFrame.Angles(0, math.rad(angle), 0)
                shown = true
            end
        end
        part.Transparency = shown and 0 or 1
    end)
end

local function removeHat() if hat then hat:Destroy() hat = nil end end
local function applyHat(char)
    removeHat()
    if not char or not hatEnabled then return end
    local head = char:FindFirstChild("Head")
    if not head then return end
    hat = new("ConeHandleAdornment", {Name = "MWHat", Adornee = head, Height = 0.8, Radius = 1.5,
        Color3 = Color3.fromRGB(210, 160, 60), Transparency = 0.4,
        CFrame = CFrame.new(0, 0.8, 0) * CFrame.Angles(math.rad(90), 0, 0)}, head)
end

--------------------------------------------------
-- ESP ПИСТОЛЕТА (GunDrop) И МОНЕТ (CoinContainer)
--------------------------------------------------
local function clearByName(names)
    for _, d in ipairs(workspace:GetDescendants()) do
        if names[d.Name] then d:Destroy() end
    end
end

task.spawn(function()
    while true do
        task.wait(0.7)
        pcall(function()
            if gunEsp then
                local g = workspace:FindFirstChild("GunDrop")
                if g and g:IsA("BasePart") and not g:FindFirstChild("MWGun") then
                    new("Highlight", {Name = "MWGun", Adornee = g, FillColor = Color3.fromRGB(255, 200, 0),
                        OutlineColor = Color3.new(1, 1, 1), FillTransparency = 0.3}, g)
                    local bb = new("BillboardGui", {Name = "MWGunTag", Size = UDim2.new(5, 0, 2, 0),
                        StudsOffset = Vector3.new(0, 2, 0), AlwaysOnTop = true}, g)
                    new("TextLabel", {Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Text = "🔫 ПИСТОЛЕТ",
                        TextColor3 = Color3.fromRGB(255, 200, 0), TextStrokeTransparency = 0, TextScaled = true,
                        Font = Enum.Font.GothamBold}, bb)
                end
            end
            if coinEsp then
                for _, m in ipairs(workspace:GetChildren()) do
                    local cc = m:IsA("Model") and m:FindFirstChild("CoinContainer")
                    if cc then
                        for _, coin in ipairs(cc:GetChildren()) do
                            if coin:IsA("BasePart") and not coin:FindFirstChild("MWCoin") then
                                new("BoxHandleAdornment", {Name = "MWCoin", Adornee = coin,
                                    Size = Vector3.new(1.6, 1.6, 1.6), Color3 = Color3.fromRGB(255, 215, 0),
                                    Transparency = 0.35, AlwaysOnTop = true, ZIndex = 1}, coin)
                            end
                        end
                    end
                end
            end
        end)
    end
end)

--------------------------------------------------
-- ТЕЛЕПОРТЫ
--------------------------------------------------
local function tpTo(cf)
    local hrp = myHrp()
    if hrp then hrp.CFrame = cf end
end
local function findMap()
    for _, m in ipairs(workspace:GetChildren()) do
        if m:IsA("Model") and m.Name ~= "Lobby" and (m:FindFirstChild("CoinContainer") or m:FindFirstChild("Spawns")) then
            return m
        end
    end
end
local function tpLobby()
    local lobby = workspace:FindFirstChild("Lobby")
    local spawns = lobby and lobby:FindFirstChild("Spawns")
    local target
    if spawns and #spawns:GetChildren() > 0 then
        local l = spawns:GetChildren()
        target = l[math.random(#l)]
    end
    if not target then target = workspace:FindFirstChildWhichIsA("SpawnLocation", true) end
    if target and target:IsA("BasePart") then tpTo(target.CFrame + Vector3.new(0, 4, 0))
    else notify("Лобби не найдено") end
end
local function tpMap()
    local map = findMap()
    if not map then notify("Карта не найдена (раунд не начался?)") return end
    local spawns = map:FindFirstChild("Spawns")
    local list = spawns and spawns:GetChildren() or {}
    local target = #list > 0 and list[math.random(#list)] or nil
    if target and target:IsA("BasePart") then tpTo(target.CFrame + Vector3.new(0, 4, 0))
    else tpTo(map:GetPivot() + Vector3.new(0, 10, 0)) end
end
local function tpRole(role)
    local p = findByRole(role, true)
    local hrp = p and p.Character and p.Character:FindFirstChild("HumanoidRootPart")
    if hrp then tpTo(hrp.CFrame * CFrame.new(0, 0, 3)) else notify(role .. " не найден") end
end

--------------------------------------------------
-- INFINITE JUMP / ANTI-AFK / ANTI-FLING / FPS BOOST
--------------------------------------------------
UIS.JumpRequest:Connect(function()
    if infJump then
        local h = myHum()
        if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end
    end
end)

LocalPlayer.Idled:Connect(function()
    if antiAfk then
        pcall(function()
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.new())
        end)
    end
end)

RunService.Stepped:Connect(function()
    if not antiFling then return end
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character then
            for _, part in ipairs(p.Character:GetChildren()) do
                if part:IsA("BasePart") then part.CanCollide = false end
            end
        end
    end
    local hrp = myHrp()
    if hrp and not flyEnabled then
        if hrp.AssemblyLinearVelocity.Magnitude > 150 or hrp.AssemblyAngularVelocity.Magnitude > 40 then
            hrp.AssemblyLinearVelocity = Vector3.zero
            hrp.AssemblyAngularVelocity = Vector3.zero
        end
    end
end)

local fpsSaved = {}
local function fpsBoost(on)
    if on then
        fpsSaved = {}
        local function save(inst, prop, val)
            pcall(function()
                local old = inst[prop]
                inst[prop] = val
                table.insert(fpsSaved, {inst, prop, old})
            end)
        end
        save(Lighting, "GlobalShadows", false)
        save(settings().Rendering, "QualityLevel", Enum.QualityLevel.Level01)
        for _, v in ipairs(Lighting:GetChildren()) do
            if v:IsA("PostEffect") or v:IsA("Atmosphere") then
                if v:IsA("PostEffect") then save(v, "Enabled", false) end
            end
        end
        for _, v in ipairs(workspace:GetDescendants()) do
            if v:IsA("ParticleEmitter") or v:IsA("Trail") or v:IsA("Smoke") or v:IsA("Fire") or v:IsA("Sparkles") then
                save(v, "Enabled", false)
            end
        end
    else
        for _, s in ipairs(fpsSaved) do pcall(function() s[1][s[2]] = s[3] end) end
        fpsSaved = {}
    end
end

--------------------------------------------------
-- SHERIFF AIM
--------------------------------------------------
local aim = {on = false, visible = true, predict = true, strength = 100, range = 250, cd = 1.0, last = 0}
local BULLET_SPEED = 200
local aimBusy = false

local function hasGun()
    local c = myChar()
    if c and c:FindFirstChild("Gun") then return true end
    local bp = LocalPlayer:FindFirstChild("Backpack")
    return bp and bp:FindFirstChild("Gun") ~= nil
end

local function isVisible(targetChar)
    local head = targetChar:FindFirstChild("Head") or targetChar:FindFirstChild("HumanoidRootPart")
    if not head then return false end
    local _, onScreen = Camera:WorldToViewportPoint(head.Position)
    if not onScreen then return false end
    local ignore = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p.Character then table.insert(ignore, p.Character) end
    end
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = ignore
    local origin = Camera.CFrame.Position
    return workspace:Raycast(origin, head.Position - origin, params) == nil
end

local function predictPos(hrp)
    local pos = hrp.Position
    if not aim.predict then return pos end
    local my = myHrp()
    local dist = my and (pos - my.Position).Magnitude or 0
    local ping = 0
    pcall(function() ping = LocalPlayer:GetNetworkPing() end)
    local t = ping + dist / BULLET_SPEED
    local vel = hrp.AssemblyLinearVelocity
    vel = Vector3.new(vel.X, vel.Y * 0.5, vel.Z)
    return pos + vel * t * (aim.strength / 100)
end

-- ВАЖНО: ремоут пистолета может меняться после обновлений MM2.
-- Пробуем 2 известных варианта, потом запасной (камера + Activate).
local function shoot(pos)
    local c = myChar()
    local hum = myHum()
    if not c or not hum then return end
    local gun = c:FindFirstChild("Gun")
    if not gun then
        local bp = LocalPlayer:FindFirstChild("Backpack")
        local g = bp and bp:FindFirstChild("Gun")
        if g then hum:EquipTool(g) task.wait(0.2) end
        gun = c:FindFirstChild("Gun")
    end
    if not gun then return end

    local kl = gun:FindFirstChild("KnifeLocal")
    local cb = kl and kl:FindFirstChild("CreateBeam")
    local rf = cb and cb:FindFirstChild("RemoteFunction")
    if rf then
        if pcall(function() rf:InvokeServer(1, pos, "AH2") end) then return end
    end
    local sh = gun:FindFirstChild("Shoot")
    if sh and sh:IsA("RemoteEvent") then
        local hrp = myHrp()
        if hrp and pcall(function() sh:FireServer(CFrame.new(hrp.Position, pos), CFrame.new(pos)) end) then return end
    end
    Camera.CFrame = CFrame.lookAt(Camera.CFrame.Position, pos)
    pcall(function() gun:Activate() end)
end

RunService.Heartbeat:Connect(function()
    if not aim.on or aimBusy then return end
    if os.clock() - aim.last < aim.cd then return end
    local myH = myHrp()
    if not myH or not hasGun() then return end
    local m = findByRole("Murderer", true)
    local mc = m and m.Character
    local mh = mc and mc:FindFirstChild("HumanoidRootPart")
    local mhum = mc and mc:FindFirstChildOfClass("Humanoid")
    if not mh or not mhum or mhum.Health <= 0 then return end
    if (mh.Position - myH.Position).Magnitude > aim.range then return end
    if aim.visible and not isVisible(mc) then return end
    aimBusy = true
    aim.last = os.clock()
    task.spawn(function()
        pcall(function() shoot(predictPos(mh)) end)
        aimBusy = false
    end)
end)

LocalPlayer.CharacterAdded:Connect(function(c)
    task.wait(0.5)
    if hatEnabled then applyHat(c) end
    if flyEnabled then startFly() end
    if noclipEnabled and not flyEnabled then toggleNoclip(true) end
end)

--------------------------------------------------
-- ВКЛАДКИ
--------------------------------------------------
local t1 = addTab("Основное", ICONS.HOME)
local t2 = addTab("Визуалы", ICONS.EYE)
local t3 = addTab("Шериф", ICONS.AIM)
local t4 = addTab("Телепорт", ICONS.TP)
local t5 = addTab("Утилиты", ICONS.UTIL)

-- Основное
t1.Section("⚡ Движение")
t1.Toggle("SpeedHack", false, function(v)
    speedEnabled = v
    local h = myHum()
    if h and not v then h.WalkSpeed = 16 end
end, ICONS.SPEED)
t1.Slider("Скорость", 16, 300, 16, " sp", function(v) speedValue = v end)
t1.Toggle("NoClip", false, function(v) if not flyEnabled then toggleNoclip(v) else noclipEnabled = v end end, ICONS.NOCLIP)
t1.Toggle("Fly (джойстик + ▲▼)", false, function(v)
    flyEnabled = v
    flyGui.Enabled = v
    if v then startFly() else stopFly() end
end, ICONS.FLY)
t1.Slider("Скорость полёта", 10, 150, 50, " st/s", function(v) flySpeed = v end)
t1.Toggle("Infinite Jump", false, function(v) infJump = v end, ICONS.FLY)

-- Визуалы
t2.Section("🎨 ESP")
t2.Toggle("Подсветка ролей (ESP)", false, function(v)
    highlightEnabled = v
    for _, o in pairs(espObjects) do
        if o.H and o.H.Parent then o.H.Enabled = v end
        if o.B and o.B.Parent then o.B.Enabled = v end
    end
end, ICONS.EYE)
t2.Toggle("ESP пистолета (выпал)", false, function(v)
    gunEsp = v
    if not v then clearByName({MWGun = true, MWGunTag = true}) end
end, ICONS.GUN)
t2.Toggle("ESP монет", false, function(v)
    coinEsp = v
    if not v then clearByName({MWCoin = true}) end
end, ICONS.COIN)
t2.Toggle("Target ESP (Убийца)", false, function(v)
    targetEspEnabled = v
    if v then applyTarget() else removeTarget() end
end, ICONS.TARGET)
t2.Toggle("China Hat", false, function(v)
    hatEnabled = v
    if v then applyHat(myChar()) else removeHat() end
end, ICONS.HAT)

-- Шериф
t3.Section("🎯 Sheriff Aim")
t3.Toggle("Sheriff Aim (авто-выстрел в убийцу)", false, function(v) aim.on = v end, ICONS.AIM)
t3.Toggle("Visible Check (вкл: только если виден / выкл: сквозь стены)", true, function(v) aim.visible = v end, ICONS.EYE)
t3.Toggle("Предсказание (куда прибежит) / выкл: прямо в него", true, function(v) aim.predict = v end, ICONS.TARGET)
t3.Slider("Сила предсказания", 0, 200, 100, "%", function(v) aim.strength = v end)
t3.Slider("Дальность", 50, 500, 250, " st", function(v) aim.range = v end)
t3.Slider("Задержка между выстрелами", 3, 30, 10, " ×0.1с", function(v) aim.cd = v / 10 end)

-- Телепорт
t4.Section("📍 Телепорты")
t4.Button("В лобби", tpLobby)
t4.Button("В игру (на карту)", tpMap)
t4.Button("К шерифу", function() tpRole("Sheriff") end)
t4.Button("К убийце", function() tpRole("Murderer") end)

-- Утилиты
t5.Section("🛠 Утилиты")
t5.Toggle("Anti-AFK", true, function(v) antiAfk = v end, ICONS.UTIL)
t5.Toggle("Anti-Fling", false, function(v) antiFling = v end, ICONS.SHIELD)
t5.Toggle("FPS Boost", false, fpsBoost, ICONS.SPEED)

--------------------------------------------------
-- ПЛАВАЮЩАЯ КНОПКА
--------------------------------------------------
local toggleGui = makeGui("ManewareToggle", 99999)
local menuVisible = true

local function setMenu(show)
    menuVisible = show
    if show then
        main.Visible = true
        tw(main, 0.3, {Size = FULL})
    else
        tw(main, 0.25, {Size = UDim2.new(0, 0, 0, 0)})
        task.delay(0.26, function() if not menuVisible then main.Visible = false end end)
    end
end

local fab = new("TextButton", {Size = UDim2.new(0, 64, 0, 64), Position = UDim2.new(1, -84, 0.5, -32),
    BackgroundColor3 = C.ACCENT, Text = "", AutoButtonColor = false, BorderSizePixel = 0, ZIndex = 10}, toggleGui)
corner(32, fab)
new("UIStroke", {Color = Color3.new(1, 1, 1), Thickness = 3}, fab)
local fabIcon = createIcon(ICONS.MENU, UDim2.new(0, 34, 0, 34), fab)
fabIcon.Position = UDim2.new(0.5, -17, 0.5, -17)
fabIcon.ImageColor3 = Color3.new(1, 1, 1)
fabIcon.ZIndex = 11

local pressing, moved, pStart, bStart = false, false, nil, nil
fab.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1 then
        pressing, moved, pStart, bStart = true, false, i.Position, fab.Position
    end
end)
UIS.InputChanged:Connect(function(i)
    if pressing and (i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseMovement) then
        local d = i.Position - pStart
        if moved or d.Magnitude > 10 then
            moved = true
            fab.Position = UDim2.new(bStart.X.Scale, bStart.X.Offset + d.X, bStart.Y.Scale, bStart.Y.Offset + d.Y)
        end
    end
end)
UIS.InputEnded:Connect(function(i)
    if pressing and (i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1) then
        pressing = false
        if not moved then setMenu(not menuVisible) end
    end
end)

onTap(closeBtn, function() setMenu(false) end)
UIS.InputBegan:Connect(function(i, gpe)
    if gpe then return end
    if i.KeyCode == Enum.KeyCode.Insert or i.KeyCode == Enum.KeyCode.RightControl then setMenu(not menuVisible) end
end)

print("[Maneware] v2 загружен")

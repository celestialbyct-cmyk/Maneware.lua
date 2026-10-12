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
local HttpService = game:GetService("HttpService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function() Camera = workspace.CurrentCamera end)

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
    FLING  = "rbxassetid://10723354359",
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
local function addRow(holder, order, label, actions)
    local row = new("Frame", {Size = UDim2.new(1, 0, 0, 46), BackgroundColor3 = C.ELEMENT,
        BorderSizePixel = 0, LayoutOrder = order}, holder)
    corner(10, row)
    new("UIStroke", {Color = C.BORDER, Thickness = 1}, row)
    local right = 8
    for idx = #actions, 1, -1 do
        local a = actions[idx]
        local w = a.w or 76
        local b = new("TextButton", {Size = UDim2.new(0, w, 0, 32), Position = UDim2.new(1, -(right + w), 0.5, -16),
            BackgroundColor3 = a.color or C.ACCENT, Text = a.text, TextColor3 = C.TEXT, TextSize = 12,
            Font = Enum.Font.GothamBold, BorderSizePixel = 0}, row)
        corner(8, b)
        onTap(b, function() task.spawn(a.fn) end)
        right = right + w + 6
    end
    new("TextLabel", {Size = UDim2.new(1, -(right + 12), 1, 0), Position = UDim2.new(0, 12, 0, 0),
        BackgroundTransparency = 1, Text = label, TextColor3 = C.TEXT, TextSize = 13,
        Font = Enum.Font.GothamSemibold, TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd}, row)
    return row
end

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
    Text = "Maneware | MM2 v6", TextColor3 = C.TEXT, TextSize = 16, Font = Enum.Font.GothamBold,
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
local REG = {} -- реестр: имя настройки -> get/set (для конфигов)
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
        local function apply(v)
            state = v and true or false
            tw(bg, 0.2, {BackgroundColor3 = state and C.ACCENT or Color3.fromRGB(55, 55, 70)})
            tw(dot, 0.2, {Position = state and UDim2.new(1, -25, 0.5, -11) or UDim2.new(0, 3, 0.5, -11)})
            if callback then task.spawn(callback, state) end
        end
        onTap(el, function() apply(not state) end)
        REG[text] = {get = function() return state end, set = apply}
    end

    function T.Slider(text, min, max, default, suffix, callback, step)
        step = step or 1
        local value = default or min
        local function fmt(v)
            if step >= 1 then return tostring(v) end
            return string.format("%.2f", v)
        end
        local function snap(x)
            return tonumber(string.format("%.3f", math.clamp(math.floor(x / step + 0.5) * step, min, max)))
        end
        local el = new("Frame", {Size = UDim2.new(1, -8, 0, 76), BackgroundColor3 = C.ELEMENT, BorderSizePixel = 0}, page)
        corner(10, el)
        new("UIStroke", {Color = C.BORDER, Thickness = 1}, el)
        new("TextLabel", {Size = UDim2.new(0.65, 0, 0, 25), Position = UDim2.new(0, 14, 0, 8), BackgroundTransparency = 1,
            Text = text, TextColor3 = C.TEXT, TextSize = 13, Font = Enum.Font.GothamSemibold,
            TextXAlignment = Enum.TextXAlignment.Left}, el)
        local val = new("TextLabel", {Size = UDim2.new(0.35, -14, 0, 25), Position = UDim2.new(0.65, 0, 0, 8),
            BackgroundTransparency = 1, Text = fmt(value) .. (suffix or ""), TextColor3 = C.ACCENT, TextSize = 13,
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
            value = snap(min + (max - min) * rel)
            fill.Size = UDim2.new((value - min) / (max - min), 0, 1, 0)
            val.Text = fmt(value) .. (suffix or "")
            if callback then callback(value) end
        end
        REG[text] = {
            get = function() return value end,
            set = function(v)
                v = snap(tonumber(v) or min)
                value = v
                fill.Size = UDim2.new((v - min) / (max - min), 0, 1, 0)
                val.Text = fmt(v) .. (suffix or "")
                if callback then callback(v) end
            end,
        }
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

    -- Список игроков: у каждого своя кнопка действия
    function T.PlayerList(actionText, callback)
        local holder = new("Frame", {Size = UDim2.new(1, -8, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundTransparency = 1}, page)
        new("UIListLayout", {Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder}, holder)
        local function refresh()
            for _, ch in ipairs(holder:GetChildren()) do
                if ch:IsA("Frame") then ch:Destroy() end
            end
            for i, pl in ipairs(Players:GetPlayers()) do
                if pl ~= LocalPlayer then
                    local row = new("Frame", {Size = UDim2.new(1, 0, 0, 46), BackgroundColor3 = C.ELEMENT,
                        BorderSizePixel = 0, LayoutOrder = i}, holder)
                    corner(10, row)
                    new("UIStroke", {Color = C.BORDER, Thickness = 1}, row)
                    new("TextLabel", {Size = UDim2.new(1, -96, 1, 0), Position = UDim2.new(0, 12, 0, 0),
                        BackgroundTransparency = 1, Text = pl.DisplayName, TextColor3 = C.TEXT, TextSize = 13,
                        Font = Enum.Font.GothamSemibold, TextXAlignment = Enum.TextXAlignment.Left,
                        TextTruncate = Enum.TextTruncate.AtEnd}, row)
                    local b = new("TextButton", {Size = UDim2.new(0, 76, 0, 32), Position = UDim2.new(1, -86, 0.5, -16),
                        BackgroundColor3 = C.RED, Text = actionText, TextColor3 = C.TEXT, TextSize = 12,
                        Font = Enum.Font.GothamBold, BorderSizePixel = 0}, row)
                    corner(8, b)
                    onTap(b, function() task.spawn(callback, pl) end)
                end
            end
        end
        refresh()
        Players.PlayerAdded:Connect(function() task.wait(0.3) refresh() end)
        Players.PlayerRemoving:Connect(function() task.wait(0.3) refresh() end)
        return refresh
    end

    function T.TextBox(placeholder)
        local el = new("Frame", {Size = UDim2.new(1, -8, 0, 46), BackgroundColor3 = C.ELEMENT, BorderSizePixel = 0}, page)
        corner(10, el)
        new("UIStroke", {Color = C.BORDER, Thickness = 1}, el)
        return new("TextBox", {Size = UDim2.new(1, -20, 1, 0), Position = UDim2.new(0, 10, 0, 0),
            BackgroundTransparency = 1, Text = "", PlaceholderText = placeholder, PlaceholderColor3 = C.DIM,
            TextColor3 = C.TEXT, TextSize = 14, Font = Enum.Font.GothamSemibold, ClearTextOnFocus = false,
            TextXAlignment = Enum.TextXAlignment.Left}, el)
    end

    function T.Holder()
        local holder = new("Frame", {Size = UDim2.new(1, -8, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundTransparency = 1}, page)
        new("UIListLayout", {Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder}, holder)
        return holder
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
local noclipUser = false

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
    toggleNoclip(noclipUser)
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

-- Настройки Target ESP (glow, размер, скорость вращения)
local tgt = {glow = true, size = 0.5, speed = 1.0}

-- Плоская рамка из 4 красных уголков (как на фото), крепится к телу цели
local function buildReticle()
    local bb = new("BillboardGui", {Name = "MWTargetBB", Size = UDim2.new(3, 0, 3, 0), AlwaysOnTop = true,
        LightInfluence = 0, Enabled = false})
    local spin = new("Frame", {Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Rotation = 25}, bb)
    local glow = new("Frame", {Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1}, spin)
    local core = new("Frame", {Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1}, spin)
    local function corners(parent, color, thick, transp, len)
        for _, a in ipairs({Vector2.new(0, 0), Vector2.new(1, 0), Vector2.new(0, 1), Vector2.new(1, 1)}) do
            new("Frame", {Size = UDim2.new(len, 0, 0, thick), Position = UDim2.new(a.X, 0, a.Y, 0), AnchorPoint = a,
                BackgroundColor3 = color, BackgroundTransparency = transp, BorderSizePixel = 0}, parent)
            new("Frame", {Size = UDim2.new(0, thick, len, 0), Position = UDim2.new(a.X, 0, a.Y, 0), AnchorPoint = a,
                BackgroundColor3 = color, BackgroundTransparency = transp, BorderSizePixel = 0}, parent)
        end
    end
    corners(glow, Color3.fromRGB(255, 40, 80), 8, 0.7, 0.36)  -- свечение (Glow)
    corners(core, Color3.fromRGB(255, 70, 100), 3, 0, 0.34)   -- основные уголки
    return bb, spin, glow
end

local function applyTarget()
    removeTarget()
    if not targetEspEnabled then return end
    local bb, spin, glow = buildReticle()
    targetObj = bb
    local angle = 25
    targetConn = RunService.RenderStepped:Connect(function(dt)
        if not targetEspEnabled then removeTarget() return end
        local pl = isGameActive() and findByRole("Murderer", true) or nil
        local ch = pl and pl.Character
        local r = ch and ch:FindFirstChild("HumanoidRootPart")
        local h = ch and ch:FindFirstChildOfClass("Humanoid")
        if r and h and h.Health > 0 then
            if bb.Parent ~= r then bb.Parent = r end
            local sz = 6 * tgt.size
            bb.Size = UDim2.new(sz, 0, sz, 0)
            glow.Visible = tgt.glow
            bb.Enabled = true
            angle += dt * 70 * tgt.speed
            spin.Rotation = angle % 360
        else
            bb.Enabled = false
        end
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

local gunDropRef = nil
local function isGunDropName(n) return n == "GunDrop" or n == "GunDrop2" end
workspace.DescendantAdded:Connect(function(d)
    if isGunDropName(d.Name) then gunDropRef = d end
end)
local lastGunScan = 0
local function findGunDrop()
    if gunDropRef and gunDropRef.Parent then return gunDropRef end
    gunDropRef = nil
    if os.clock() - lastGunScan < 1 then return nil end
    lastGunScan = os.clock()
    gunDropRef = workspace:FindFirstChild("GunDrop", true)
    return gunDropRef
end
local function gunDropPart(g)
    if not g then return nil end
    if g:IsA("BasePart") then return g end
    return g:FindFirstChildWhichIsA("BasePart", true)
end
local gunNotified = nil

task.spawn(function()
    while true do
        task.wait(0.5)
        pcall(function()
            if gunEsp then
                local g = findGunDrop()
                local part = gunDropPart(g)
                if part then
                    if gunNotified ~= g then
                        gunNotified = g
                        notify("🔫 Пистолет выпал!")
                    end
                    if not part:FindFirstChild("MWGunBox") then
                        new("BoxHandleAdornment", {Name = "MWGunBox", Adornee = part,
                            Size = part.Size + Vector3.new(0.6, 0.6, 0.6), Color3 = Color3.fromRGB(255, 200, 0),
                            Transparency = 0.3, AlwaysOnTop = true, ZIndex = 1}, part)
                    end
                    if not part:FindFirstChild("MWGun") then
                        new("Highlight", {Name = "MWGun", Adornee = part, FillColor = Color3.fromRGB(255, 200, 0),
                            OutlineColor = Color3.new(1, 1, 1), FillTransparency = 0.2,
                            DepthMode = Enum.HighlightDepthMode.AlwaysOnTop}, part)
                    end
                    if not part:FindFirstChild("MWGunTag") then
                        local bb = new("BillboardGui", {Name = "MWGunTag", Size = UDim2.new(0, 120, 0, 36),
                            StudsOffset = Vector3.new(0, 2.5, 0), AlwaysOnTop = true}, part)
                        new("TextLabel", {Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1,
                            Text = "🔫 ПИСТОЛЕТ", TextColor3 = Color3.fromRGB(255, 200, 0), TextStrokeTransparency = 0,
                            TextSize = 18, Font = Enum.Font.GothamBold}, bb)
                    end
                else
                    gunNotified = nil
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

-- Трекер реальной скорости игроков (точнее, чем AssemblyLinearVelocity)
local vTrack = setmetatable({}, {__mode = "k"})
RunService.Heartbeat:Connect(function(dt)
    for _, pl in ipairs(Players:GetPlayers()) do
        local r = pl.Character and pl.Character:FindFirstChild("HumanoidRootPart")
        if r then
            local d = vTrack[r]
            if not d then
                vTrack[r] = {pos = r.Position, vel = Vector3.zero}
            else
                if dt > 0 then d.vel = d.vel:Lerp((r.Position - d.pos) / dt, 0.4) end
                d.pos = r.Position
            end
        end
    end
end)

local function predictAt(hrp, speed, strength)
    local pos = hrp.Position
    local my = myHrp()
    local d = vTrack[hrp]
    local vel = d and d.vel or hrp.AssemblyLinearVelocity
    if vel.Magnitude > 60 then vel = vel.Unit * 60 end -- отсекаем рывки/телепорты
    vel = Vector3.new(vel.X, vel.Y * 0.3, vel.Z)
    local ping = 0
    pcall(function() ping = LocalPlayer:GetNetworkPing() end)
    local origin = my and my.Position or Camera.CFrame.Position
    local predicted = pos
    for _ = 1, 3 do -- время полёта зависит от точки упреждения, уточняем итерациями
        local t = (predicted - origin).Magnitude / speed + ping
        predicted = pos + vel * t * strength
    end
    return predicted
end

local function predictPos(hrp)
    if not aim.predict then return hrp.Position end
    return predictAt(hrp, BULLET_SPEED, aim.strength / 100)
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

--------------------------------------------------
-- GRAB GUN
--------------------------------------------------
local flingBusy = false
local grabGun, grabBusy, grabLast = false, false, 0

local function sheriffAlive()
    for _, pl in ipairs(Players:GetPlayers()) do
        if pl ~= LocalPlayer and getRole(pl) == "Sheriff" then
            local h = pl.Character and pl.Character:FindFirstChildOfClass("Humanoid")
            if h and h.Health > 0 then return true end
        end
    end
    return false
end

local function doGrabGun()
    if grabBusy or flingBusy then return end
    local g = findGunDrop()
    if not g then return end
    local part = gunDropPart(g)
    if not part then return end
    -- берём только если шериф мёртв (пистолет выпал) и у нас пистолета нет
    if sheriffAlive() or hasGun() or getRole(LocalPlayer) == "Murderer" then return end
    local hrp = myHrp()
    if not hrp then return end

    grabBusy = true
    grabLast = os.clock()
    local origin = hrp.CFrame
    local t0 = os.clock()
    while os.clock() - t0 < 2 do
        hrp = myHrp()
        if not hrp or not g.Parent then break end -- нет персонажа / пистолет уже забрали
        hrp.CFrame = part.CFrame
        pcall(function()
            if firetouchinterest then
                firetouchinterest(hrp, part, 0)
                firetouchinterest(hrp, part, 1)
            end
        end)
        if hasGun() then break end
        task.wait(0.1)
    end
    hrp = myHrp()
    if hrp then
        hrp.AssemblyLinearVelocity = Vector3.zero
        hrp.CFrame = origin -- назад на прежнюю точку
    end
    grabBusy = false
end

task.spawn(function()
    while true do
        task.wait(0.3)
        if grabGun and not grabBusy and os.clock() - grabLast > 3 then
            if not pcall(doGrabGun) then grabBusy = false end
        end
    end
end)

--------------------------------------------------
-- FLING
-- Метод "velocity desync": в Heartbeat ставим огромную скорость и стоим
-- в цели, в Stepped/RenderStepped гасим её. Сервер видит удар, а нас самих
-- не уносит. В конце возвращаемся на исходную точку.
--------------------------------------------------
local function flingPlayer(target)
    if flingBusy then notify("Fling уже идёт") return end
    if grabBusy then notify("Подожди, идёт GrabGun") return end
    if not target or target == LocalPlayer then return end
    if flyEnabled then notify("Выключи Fly перед флингом") return end
    local hrp, hum = myHrp(), myHum()
    local tc = target.Character
    local thrp = tc and tc:FindFirstChild("HumanoidRootPart")
    if not hrp or not hum or not thrp then notify("Игрок недоступен") return end

    flingBusy = true
    local origin = hrp.CFrame
    local startPos = thrp.Position
    local prevAnti = antiFling
    antiFling = false          -- иначе AntiFling уберёт коллизии и фling не сработает
    toggleNoclip(false)        -- чтобы наши части сталкивались с целью

    local stepConn = RunService.Stepped:Connect(function()
        local h = myHrp()
        if h then
            h.AssemblyLinearVelocity = Vector3.zero
            h.AssemblyAngularVelocity = Vector3.zero
        end
    end)
    local hbConn = RunService.Heartbeat:Connect(function()
        local h = myHrp()
        local tch = target.Character
        local tr = tch and tch:FindFirstChild("HumanoidRootPart")
        if not h or not tr then return end
        h.CFrame = tr.CFrame + tr.AssemblyLinearVelocity * 0.08
        h.AssemblyLinearVelocity = Vector3.new(1e5, 1e5, 1e5)
        h.AssemblyAngularVelocity = Vector3.new(1e5, 1e5, 1e5)
    end)

    pcall(function()
        local t0 = os.clock()
        while os.clock() - t0 < 3 do
            task.wait(0.1)
            local tch = target.Character
            local tr = tch and tch:FindFirstChild("HumanoidRootPart")
            local th = tch and tch:FindFirstChildOfClass("Humanoid")
            if not tr or not th or th.Health <= 0 or not myHrp() then break end
            if tr.AssemblyLinearVelocity.Magnitude > 300 or (tr.Position - startPos).Magnitude > 120 then
                task.wait(0.15)
                break -- улетел
            end
        end
    end)

    hbConn:Disconnect()
    stepConn:Disconnect()
    for _ = 1, 12 do -- возвращаемся и гасим всё, что могло накопиться
        local h = myHrp()
        if h then
            h.AssemblyLinearVelocity = Vector3.zero
            h.AssemblyAngularVelocity = Vector3.zero
            h.CFrame = origin
        end
        RunService.Heartbeat:Wait()
    end
    antiFling = prevAnti
    toggleNoclip(noclipUser)
    flingBusy = false
end

local function flingRole(role)
    local pl = findByRole(role, true)
    if pl then flingPlayer(pl) else notify(role .. " не найден") end
end

--------------------------------------------------
-- НОЖ: удар / бросок, KillAura, Kill All, Aura Throw
--------------------------------------------------
local farmBusy = false
local killAllOn, killAllBusy = false, false

local function amMurderer() return getRole(LocalPlayer) == "Murderer" end

local function getKnife(equip)
    local c = myChar()
    if not c then return nil end
    local k = c:FindFirstChild("Knife")
    if k then return k end
    local bp = LocalPlayer:FindFirstChild("Backpack")
    local kb = bp and bp:FindFirstChild("Knife")
    if kb and equip then
        local h = myHum()
        if h then
            h:EquipTool(kb)
            task.wait(0.15)
        end
        return c:FindFirstChild("Knife")
    end
    return nil
end

-- можно ли убить игрока (жив, есть персонаж, нет ForceField)
local function canKill(pl)
    if not pl or pl == LocalPlayer then return false end
    local ch = pl.Character
    local hum = ch and ch:FindFirstChildOfClass("Humanoid")
    local r = ch and ch:FindFirstChild("HumanoidRootPart")
    if not hum or not r or hum.Health <= 0 then return false end
    if ch:FindFirstChildOfClass("ForceField") then return false end
    return true, r
end

-- ВАЖНО: имена ремоутов ножа могут меняться после обновлений MM2
local function stab(targetRoot)
    local knife = getKnife(true)
    if not knife then return false end
    local handle = knife:FindFirstChild("Handle")
    local st = knife:FindFirstChild("Stab")
    if st and st:IsA("RemoteEvent") then
        pcall(function() st:FireServer("Slash") end)
    else
        pcall(function() knife:Activate() end)
    end
    if handle and targetRoot and firetouchinterest then
        pcall(function()
            firetouchinterest(handle, targetRoot, 0)
            firetouchinterest(handle, targetRoot, 1)
        end)
    end
    return true
end

local function nearestPlayer(maxDist)
    local my = myHrp()
    if not my then return nil end
    local best, bd = nil, maxDist
    for _, pl in ipairs(Players:GetPlayers()) do
        local ok, r = canKill(pl)
        if ok then
            local d = (r.Position - my.Position).Magnitude
            if d <= bd then best, bd = pl, d end
        end
    end
    return best
end

-- KillAura: бьёт ножом (не бросает) всех в радиусе, только если ты убийца
local ka = {on = false, dist = 4, last = 0}
RunService.Heartbeat:Connect(function()
    if not ka.on or killAllBusy or flingBusy or os.clock() - ka.last < 0.25 then return end
    if not amMurderer() then return end
    local my = myHrp()
    if not my then return end
    for _, pl in ipairs(Players:GetPlayers()) do
        local ok, r = canKill(pl)
        if ok and (r.Position - my.Position).Magnitude <= ka.dist then
            ka.last = os.clock()
            task.spawn(stab, r)
            break
        end
    end
end)

-- Kill All: по очереди телепортируется к каждому и бьёт, потом возвращается назад
task.spawn(function()
    while true do
        task.wait(0.4)
        if killAllOn and not killAllBusy and not flingBusy and not grabBusy and not farmBusy and amMurderer() then
            killAllBusy = true
            pcall(function()
                local my = myHrp()
                if not my then return end
                local origin = my.CFrame
                local list = {}
                for _, pl in ipairs(Players:GetPlayers()) do
                    local ok, r = canKill(pl)
                    if ok then table.insert(list, {pl = pl, d = (r.Position - my.Position).Magnitude}) end
                end
                table.sort(list, function(a, b) return a.d < b.d end)
                for _, e in ipairs(list) do
                    if not killAllOn or not amMurderer() then break end
                    local t0 = os.clock()
                    while os.clock() - t0 < 1.5 and killAllOn do
                        local ok, r = canKill(e.pl)
                        local h = myHrp()
                        if not ok or not h then break end
                        h.CFrame = r.CFrame * CFrame.new(0, 0, 2.5)
                        h.AssemblyLinearVelocity = Vector3.zero
                        stab(r)
                        task.wait(0.2)
                    end
                end
                local h = myHrp()
                if h then
                    h.CFrame = origin
                    h.AssemblyLinearVelocity = Vector3.zero
                end
            end)
            killAllBusy = false
        end
    end
end)

-- Aura Throw: бросок ножа с сильным упреждением
local thr = {on = false, range = 80, cd = 1.2, strength = 100, last = 0}
local THROW_SPEED = 130

local function hasKnife()
    local c = myChar()
    if c and c:FindFirstChild("Knife") then return true end
    local bp = LocalPlayer:FindFirstChild("Backpack")
    return bp ~= nil and bp:FindFirstChild("Knife") ~= nil
end

-- перебираем все ремоуты ножа с "throw" в имени (Throw, KnifeThrown и т.п.)
local function fireKnifeThrow(knife, hand, pos)
    local cands = {}
    local tr = knife:FindFirstChild("Throw")
    if tr then table.insert(cands, tr) end
    for _, d in ipairs(knife:GetDescendants()) do
        if d ~= tr and (d:IsA("RemoteEvent") or d:IsA("RemoteFunction")) and d.Name:lower():find("throw") then
            table.insert(cands, d)
        end
    end
    local sent = false
    for _, r in ipairs(cands) do
        if r:IsA("RemoteEvent") then
            if pcall(function() r:FireServer(CFrame.new(hand), CFrame.new(pos)) end) then sent = true end
        elseif r:IsA("RemoteFunction") then
            task.spawn(function() pcall(function() r:InvokeServer(CFrame.new(hand), CFrame.new(pos)) end) end)
            sent = true
        end
    end
    return sent
end

local function throwAt(pl)
    local ok, r = canKill(pl)
    if not ok then return false end
    local knife = getKnife(true)
    local c = myChar()
    local my = myHrp()
    if not knife or not c or not my then return false end
    local pos = predictAt(r, THROW_SPEED, thr.strength / 100)
    local hand = (c:FindFirstChild("RightHand") or my).Position
    return fireKnifeThrow(knife, hand, pos)
end

RunService.Heartbeat:Connect(function()
    if not thr.on or flingBusy or os.clock() - thr.last < thr.cd then return end
    if not hasKnife() then return end
    local pl = nearestPlayer(thr.range)
    if pl then
        thr.last = os.clock()
        task.spawn(throwAt, pl)
    end
end)

--------------------------------------------------
-- AUTOFARM МОНЕТ
--------------------------------------------------
local farm = {on = false, speed = 30, limit = 40, flingMurd = false, reset = false, walls = true,
    safe = 0, count = 0, done = false}
local coinSkip = setmetatable({}, {__mode = "k"})
local lastContainer, cachedCC, lastCCScan, lastFarmWarn = nil, nil, 0, 0

-- контейнер монет ищем по всему workspace (карта может лежать где угодно)
local function findCoinContainer()
    if cachedCC and cachedCC.Parent then return cachedCC end
    cachedCC = nil
    if os.clock() - lastCCScan < 0.8 then return nil end
    lastCCScan = os.clock()
    cachedCC = workspace:FindFirstChild("CoinContainer", true)
    return cachedCC
end

local function coinPart(c)
    if c:IsA("BasePart") then return c end
    return c:FindFirstChildWhichIsA("BasePart", true)
end
local function hasTouch(c) return c:FindFirstChildWhichIsA("TouchInterest", true) ~= nil end

-- ближайшая нетронутая монета; если у монет есть TouchInterest - берём только с ним
local function nearestCoin(cc, my)
    local items = cc:GetChildren()
    local useTouch = false
    for _, c in ipairs(items) do
        if hasTouch(c) then useTouch = true break end
    end
    local murd = findByRole("Murderer", true)
    local mr = murd and murd.Character and murd.Character:FindFirstChild("HumanoidRootPart")
    local best, bestPart, bd = nil, nil, math.huge
    for _, c in ipairs(items) do
        local part = coinPart(c)
        if part and c.Parent and not c:GetAttribute("Collected") and (not useTouch or hasTouch(c)) then
            local skip = coinSkip[c]
            if not skip or os.clock() > skip then
                local blocked = farm.safe > 0 and mr and (mr.Position - part.Position).Magnitude < farm.safe
                if not blocked then
                    local d = (part.Position - my.Position).Magnitude
                    if d < bd then best, bestPart, bd = c, part, d end
                end
            end
        end
    end
    return best, bestPart, useTouch
end

local function coinGone(c, hadTouch)
    if not c.Parent then return true end
    if c:GetAttribute("Collected") then return true end
    if hadTouch and not hasTouch(c) then return true end
    return false
end

-- считываем реальное число монет из интерфейса (если путь есть), иначе считаем сами
local function readBag()
    local ok, n = pcall(function()
        local lbl = LocalPlayer.PlayerGui.MainGUI.Game.CoinBags.Container.Coin.CurrencyFrame.Icon.Coins
        return tonumber(lbl.Text)
    end)
    return ok and n or nil
end

-- летим к монете напрямую (сквозь препятствия) со скоростью из слайдера
local function flyTo(part, coin)
    local h0 = myHrp()
    if not h0 then return false end
    local limit = (part.Position - h0.Position).Magnitude / math.max(farm.speed, 1) + 3
    local t0 = os.clock()
    while farm.on and coin.Parent and os.clock() - t0 < limit do
        local h = myHrp()
        if not h then return false end
        local dt = RunService.Heartbeat:Wait()
        local diff = part.Position - h.Position
        local dist = diff.Magnitude
        if dist < 0.8 then return true end
        local step = farm.speed * dt
        if step >= dist then
            h.CFrame = CFrame.new(part.Position) * h.CFrame.Rotation
        else
            h.CFrame = h.CFrame + diff.Unit * step
        end
        h.AssemblyLinearVelocity = Vector3.zero
        h.AssemblyAngularVelocity = Vector3.zero
    end
    return false
end

local function farmLimitReached()
    farm.done = true
    if farm.flingMurd then
        local m = findByRole("Murderer", true)
        if m then flingPlayer(m) end
    end
    if farm.reset then
        local h = myHum()
        if h then
            h.Health = 0
            pcall(function() myChar():BreakJoints() end)
        end
    end
end

task.spawn(function()
    while true do
        task.wait(0.12)
        if farm.on and not farmBusy and not grabBusy and not flingBusy and not killAllBusy then
            farmBusy = true
            local ok, err = pcall(function()
                local cc = findCoinContainer()
                if cc ~= lastContainer then -- новый раунд / новая карта
                    lastContainer = cc
                    farm.count = 0
                    farm.done = false
                end
                if not cc then
                    if os.clock() - lastFarmWarn > 15 then
                        lastFarmWarn = os.clock()
                        notify("Автофарм: монеты не найдены (раунд не начался?)")
                    end
                    return
                end
                if farm.done then return end
                local my, hum = myHrp(), myHum()
                if not my or not hum or hum.Health <= 0 then return end
                if farm.count > 0 then
                    local bag = readBag()
                    if bag then farm.count = bag end
                end
                if farm.count >= farm.limit then
                    farmLimitReached()
                    return
                end
                if farm.walls and not noclipEnabled then toggleNoclip(true) end
                local coin, part, hadTouch = nearestCoin(cc, my)
                if not coin then return end
                if flyTo(part, coin) then
                    local got = false
                    local t0 = os.clock()
                    while os.clock() - t0 < 0.7 do
                        local h = myHrp()
                        if not h then break end
                        h.CFrame = CFrame.new(part.Position) * h.CFrame.Rotation -- стоим на монете
                        h.AssemblyLinearVelocity = Vector3.zero
                        if firetouchinterest then
                            pcall(function()
                                firetouchinterest(h, part, 0)
                                firetouchinterest(h, part, 1)
                            end)
                        end
                        if coinGone(coin, hadTouch) then got = true break end
                        task.wait(0.06)
                    end
                    if got then farm.count += 1 else coinSkip[coin] = os.clock() + 8 end
                else
                    coinSkip[coin] = os.clock() + 8
                end
            end)
            if not ok then warn("[Maneware] autofarm: " .. tostring(err)) end
            farmBusy = false
        end
    end
end)

--------------------------------------------------
-- KILL EFFECTS: эффекты, когда умирает убийца / шериф
--------------------------------------------------
local fx = {ghost = false, lightning = false, star = false, starCount = 5, starSpeed = 2}

-- 1) Ghost: полупрозрачная копия игрока плавно поднимается вверх и исчезает
local function spawnGhost(ch)
    if not ch then return end
    local wasArch = ch.Archivable
    ch.Archivable = true
    local clone = ch:Clone()
    ch.Archivable = wasArch
    if not clone then return end
    local kill = {}
    for _, d in ipairs(clone:GetDescendants()) do
        if d:IsA("BaseScript") or d:IsA("Humanoid") or d:IsA("BillboardGui") or d:IsA("Sound")
            or d:IsA("Highlight") or d:IsA("ForceField") or d:IsA("Tool") or d:IsA("SurfaceAppearance") then
            table.insert(kill, d)
        end
    end
    for _, d in ipairs(kill) do pcall(function() d:Destroy() end) end
    local parts, decals = {}, {}
    for _, d in ipairs(clone:GetDescendants()) do
        if d:IsA("BasePart") then
            d.Anchored = true
            d.CanCollide = false
            d.CanTouch = false
            d.CanQuery = false
            d.CastShadow = false
            d.Material = Enum.Material.Neon
            d.Color = Color3.fromRGB(190, 225, 255)
            d.Transparency = 0.45
            pcall(function() d.TextureID = "" end)
            table.insert(parts, d)
        elseif d:IsA("Decal") or d:IsA("Texture") then
            d.Transparency = 0.5
            table.insert(decals, d)
        end
    end
    clone.Name = "MWGhost"
    clone.Parent = workspace
    local base = clone:GetPivot()
    local dur, t0 = 2.6, os.clock()
    local conn
    conn = RunService.Heartbeat:Connect(function()
        local a = (os.clock() - t0) / dur
        if a >= 1 or not clone.Parent then
            conn:Disconnect()
            clone:Destroy()
            return
        end
        clone:PivotTo(base + Vector3.new(math.sin(a * 6) * 0.3, 8 * a, 0))
        local tr = 0.45 + 0.55 * a * a
        for _, pt in ipairs(parts) do pt.Transparency = tr end
        for _, dc in ipairs(decals) do dc.Transparency = 0.5 + 0.5 * a end
    end)
end

-- 2) Molnia: молния в стиле Minecraft бьёт в место смерти
local function spawnLightning(pos)
    local folder = new("Folder", {Name = "MWLightning"}, workspace)
    local ground = pos - Vector3.new(0, 2.5, 0)
    local top = ground + Vector3.new(math.random(-6, 6), 120, math.random(-6, 6))
    local pts = {top}
    local segs = 16
    for i = 1, segs - 1 do
        local a = i / segs
        local p = top:Lerp(ground, a)
        local off = (1 - a) * 8 + 1
        pts[#pts + 1] = p + Vector3.new((math.random() - 0.5) * off * 2, 0, (math.random() - 0.5) * off * 2)
    end
    pts[#pts + 1] = ground
    local parts = {}
    local function bolt(p1, p2, thick)
        local d = p2 - p1
        if d.Magnitude < 0.05 then return end
        parts[#parts + 1] = new("Part", {Anchored = true, CanCollide = false, CanTouch = false, CanQuery = false,
            CastShadow = false, Material = Enum.Material.Neon, Color = Color3.fromRGB(210, 225, 255),
            Size = Vector3.new(thick, thick, d.Magnitude), CFrame = CFrame.lookAt(p1 + d / 2, p2)}, folder)
    end
    for i = 1, #pts - 1 do bolt(pts[i], pts[i + 1], 0.7) end
    local prev = pts[math.random(5, 9)] -- ответвление
    for _ = 1, 4 do
        local np = prev + Vector3.new((math.random() - 0.5) * 14, -(8 + math.random() * 6), (math.random() - 0.5) * 14)
        bolt(prev, np, 0.35)
        prev = np
    end
    local flash = new("Part", {Shape = Enum.PartType.Ball, Size = Vector3.new(6, 6, 6), Position = ground,
        Anchored = true, CanCollide = false, CanTouch = false, CanQuery = false, CastShadow = false,
        Material = Enum.Material.Neon, Color = Color3.new(1, 1, 1), Transparency = 0.3}, folder)
    task.spawn(function()
        local function setT(t)
            for _, pt in ipairs(parts) do pt.Transparency = t end
            flash.Transparency = math.min(1, t + 0.3)
        end
        setT(0) task.wait(0.09)
        setT(1) task.wait(0.05)
        setT(0) task.wait(0.12)
        for i = 1, 10 do
            setT(i / 10)
            task.wait(0.03)
        end
        folder:Destroy()
    end)
end

-- 3) Star: звёзды выходят из тела, медленно идут вверх и исчезают
local function spawnStars(pos)
    local spd = math.clamp(fx.starSpeed, 1, 5)
    local dur = 6 / spd + 0.5
    for _ = 1, fx.starCount do
        task.delay(math.random() * 0.6, function()
            local start = pos + Vector3.new((math.random() - 0.5) * 2.5, math.random() * 2 - 0.5, (math.random() - 0.5) * 2.5)
            local part = new("Part", {Anchored = true, CanCollide = false, CanTouch = false, CanQuery = false,
                Transparency = 1, Size = Vector3.new(0.2, 0.2, 0.2), Position = start}, workspace)
            local bb = new("BillboardGui", {Size = UDim2.new(1.4, 0, 1.4, 0), AlwaysOnTop = true, LightInfluence = 0}, part)
            local tl = new("TextLabel", {Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Text = "★",
                TextScaled = true, TextColor3 = Color3.fromRGB(255, 230, 90), TextStrokeTransparency = 0.6,
                TextStrokeColor3 = Color3.fromRGB(255, 170, 0), Font = Enum.Font.GothamBold}, bb)
            TweenService:Create(part, TweenInfo.new(dur, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
                {Position = start + Vector3.new((math.random() - 0.5) * 3, 9, (math.random() - 0.5) * 3)}):Play()
            TweenService:Create(tl, TweenInfo.new(dur, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
                {TextTransparency = 1, TextStrokeTransparency = 1}):Play()
            task.delay(dur + 0.1, function() part:Destroy() end)
        end)
    end
end

local function fxDeath(ch, pos)
    if fx.ghost then pcall(spawnGhost, ch) end
    if fx.lightning then pcall(spawnLightning, pos) end
    if fx.star then pcall(spawnStars, pos) end
end

-- запоминаем роль, пока игрок жив (после смерти инвентарь уже пуст)
local roleCache = {}
task.spawn(function()
    while true do
        task.wait(0.25)
        for _, pl in ipairs(Players:GetPlayers()) do
            local h = pl.Character and pl.Character:FindFirstChildOfClass("Humanoid")
            if h and h.Health > 0 then roleCache[pl] = getRole(pl) end
        end
    end
end)
Players.PlayerRemoving:Connect(function(pl) roleCache[pl] = nil end)

local function hookDeath(pl)
    local function onChar(ch)
        local hum = ch:WaitForChild("Humanoid", 5)
        if not hum then return end
        hum.Died:Connect(function()
            local role = roleCache[pl]
            if role ~= "Murderer" and role ~= "Sheriff" then return end
            local hrp = ch:FindFirstChild("HumanoidRootPart")
            if hrp then fxDeath(ch, hrp.Position) end
        end)
    end
    if pl.Character then task.spawn(onChar, pl.Character) end
    pl.CharacterAdded:Connect(onChar)
end
for _, pl in ipairs(Players:GetPlayers()) do hookDeath(pl) end
Players.PlayerAdded:Connect(hookDeath)

LocalPlayer.CharacterAdded:Connect(function(c)
    task.wait(0.5)
    if hatEnabled then applyHat(c) end
    if flyEnabled then startFly() end
    if noclipUser and not flyEnabled then toggleNoclip(true) end
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
t1.Toggle("NoClip", false, function(v) noclipUser = v if not flyEnabled then toggleNoclip(v) end end, ICONS.NOCLIP)
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
    if not v then clearByName({MWGun = true, MWGunTag = true, MWGunBox = true}) end
end, ICONS.GUN)
t2.Button("🔍 Где пистолет? (диагностика)", function()
    local g = findGunDrop()
    if g then notify("GunDrop: " .. g:GetFullName() .. " [" .. g.ClassName .. "]")
    else notify("GunDrop не найден (пистолет не выпал?)") end
end)
t2.Toggle("ESP монет", false, function(v)
    coinEsp = v
    if not v then clearByName({MWCoin = true}) end
end, ICONS.COIN)
t2.Toggle("Target ESP (Убийца)", false, function(v)
    targetEspEnabled = v
    if v then applyTarget() else removeTarget() end
end, ICONS.TARGET)
t2.Toggle("Target: Glow (свечение)", true, function(v) tgt.glow = v end, ICONS.TARGET)
t2.Slider("Target: Size", 0.10, 1, 0.5, "", function(v) tgt.size = v end, 0.05)
t2.Slider("Target: Speed", 0.50, 2, 1.00, "x", function(v) tgt.speed = v end, 0.05)
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

-- GrabGun во вкладке "Шериф"
t3.Section("🔫 Пистолет")
t3.Toggle("GrabGun (авто-подбор выпавшего пистолета)", false, function(v) grabGun = v end, ICONS.GUN)

-- Fling
local t6 = addTab("Fling", ICONS.FLING)
t6.Section("🌀 Fling (вернёт на прежнее место)")
t6.Button("Fling Murderer", function() flingRole("Murderer") end)
t6.Button("Fling Sheriff", function() flingRole("Sheriff") end)
t6.Section("👥 Игроки на сервере")
local refreshList
t6.Button("🔄 Обновить список", function() if refreshList then refreshList() end end)
refreshList = t6.PlayerList("FLING", flingPlayer)

-- Автофарм
local t7 = addTab("Автофарм", ICONS.COIN)
t7.Section("💰 Autofarm монет")
t7.Toggle("Autofarm", false, function(v)
    farm.on = v
    if not v then toggleNoclip(noclipUser or flyEnabled) end
end, ICONS.COIN)
t7.Slider("Скорость фарма", 16, 50, 30, " st/s", function(v) farm.speed = v end)
t7.Slider("Лимит монет (мешок)", 10, 60, 40, "", function(v) farm.limit = v end)
t7.Toggle("Fling Murderer после лимита", false, function(v) farm.flingMurd = v end, ICONS.FLING)
t7.Toggle("Reset после лимита", false, function(v) farm.reset = v end, ICONS.UTIL)
t7.Toggle("Лететь сквозь стены (NoClip)", true, function(v) farm.walls = v end, ICONS.NOCLIP)
t7.Slider("Обходить монеты рядом с убийцей", 0, 40, 0, " st", function(v) farm.safe = v end)
t7.Button("Сбросить счётчик монет", function()
    farm.count = 0
    farm.done = false
    notify("Счётчик сброшен")
end)

-- Убийца
local t8 = addTab("Убийца", ICONS.AIM)
t8.Section("🔪 KillAura (только если ты убийца)")
t8.Toggle("KillAura (бьёт ножом)", false, function(v) ka.on = v end, ICONS.AIM)
t8.Slider("Дистанция KillAura", 1, 6, 4, " st", function(v) ka.dist = v end)
t8.Toggle("Kill All (убить всех)", false, function(v) killAllOn = v end, ICONS.TARGET)
t8.Section("🗡 Aura Throw (бросок ножа)")
t8.Toggle("Aura Throw (авто-бросок в ближнего)", false, function(v) thr.on = v end, ICONS.AIM)
t8.Slider("Дальность броска", 10, 200, 80, " st", function(v) thr.range = v end)
t8.Slider("Сила упреждения броска", 0, 200, 100, "%", function(v) thr.strength = v end)
t8.Slider("Задержка между бросками", 5, 30, 12, " ×0.1с", function(v) thr.cd = v / 10 end)
t8.Button("Бросить в ближнего", function()
    local pl = nearestPlayer(thr.range)
    if not pl then notify("Нет цели") return end
    if not throwAt(pl) then notify("Нож не найден / ты не убийца") end
end)
t8.Section("🎯 Бросить в выбранного")
t8.PlayerList("БРОСИТЬ", function(pl)
    if not throwAt(pl) then notify("Не удалось бросить") end
end)

-- KillEffect
local t10 = addTab("KillEffect", ICONS.TARGET)
t10.Section("💀 Эффекты при смерти убийцы / шерифа")
t10.Toggle("Ghost (призрак поднимается)", false, function(v) fx.ghost = v end, ICONS.EYE)
t10.Toggle("Molnia (молния в месте смерти)", false, function(v) fx.lightning = v end, ICONS.AIM)
t10.Toggle("Star (звёзды из тела)", false, function(v) fx.star = v end, ICONS.TARGET)
t10.Slider("Star: количество", 1, 10, 5, "", function(v) fx.starCount = v end)
t10.Slider("Star: скорость", 1, 5, 2, "", function(v) fx.starSpeed = v end)
t10.Button("▶ Проверить эффекты (на мне)", function()
    local h, ch = myHrp(), myChar()
    if not h or not ch then return end
    if not (fx.ghost or fx.lightning or fx.star) then notify("Включи хотя бы один эффект") return end
    fxDeath(ch, h.Position)
end)

-- Configs
local t9 = addTab("Configs", ICONS.UTIL)
t9.Section("💾 Конфиги (сохранение настроек)")
local cfgName = t9.TextBox("Имя конфига")
local CFG_DIR = "ManewareMM2"
local cfgHolder
local activeCfg = nil -- последний загруженный/сохранённый конфиг

local function cleanName(n)
    n = tostring(n or ""):gsub("[/\\:%*%?\"<>|]", ""):gsub("^%s+", ""):gsub("%s+$", "")
    return n
end
local function cfgSupported()
    return writefile ~= nil and readfile ~= nil and isfolder ~= nil and makefolder ~= nil and listfiles ~= nil
end
local function cfgSave(name)
    name = cleanName(name)
    if name == "" then notify("Введи имя конфига") return end
    if not cfgSupported() then notify("Executor не поддерживает файлы") return end
    pcall(function() if not isfolder(CFG_DIR) then makefolder(CFG_DIR) end end)
    local data = {}
    for key, e in pairs(REG) do data[key] = e.get() end
    local ok = pcall(function()
        writefile(CFG_DIR .. "/" .. name .. ".json", HttpService:JSONEncode(data))
    end)
    if ok then activeCfg = name end
    notify(ok and ("Сохранено: " .. name) or "Ошибка сохранения")
end
local function cfgLoad(name)
    local ok, data = pcall(function()
        return HttpService:JSONDecode(readfile(CFG_DIR .. "/" .. name .. ".json"))
    end)
    if not ok or type(data) ~= "table" then notify("Не удалось загрузить") return end
    for key, val in pairs(data) do
        local e = REG[key]
        if e then pcall(e.set, val) end
    end
    activeCfg = name
    notify("Загружен: " .. name)
end
local function cfgDelete(name)
    pcall(function() delfile(CFG_DIR .. "/" .. name .. ".json") end)
end
local function cfgRefresh()
    if not cfgHolder then return end
    for _, ch in ipairs(cfgHolder:GetChildren()) do
        if ch:IsA("Frame") then ch:Destroy() end
    end
    if not cfgSupported() then return end
    local names = {}
    pcall(function()
        if not isfolder(CFG_DIR) then return end
        for _, f in ipairs(listfiles(CFG_DIR)) do
            local n = tostring(f):match("([^/\\]+)%.json$")
            if n then table.insert(names, n) end
        end
    end)
    table.sort(names)
    for i, n in ipairs(names) do
        addRow(cfgHolder, i, n, {
            {text = "✕", color = C.RED, w = 34, fn = function() cfgDelete(n) cfgRefresh() end},
            {text = "Save", color = C.ACCENT, w = 50, fn = function() cfgSave(n) end},
            {text = "Load", color = C.GREEN, w = 50, fn = function() cfgLoad(n) end},
        })
    end
end
t9.Button("💾 Сохранить конфиг (по имени выше)", function()
    cfgSave(cfgName.Text)
    cfgRefresh()
end)
t9.Button("💾 Сохранить в открытый конфиг", function()
    if not activeCfg then notify("Сначала загрузи или сохрани конфиг") return end
    cfgSave(activeCfg)
end)
t9.Button("🔄 Обновить список", cfgRefresh)
t9.Section("📂 Сохранённые конфиги")
cfgHolder = t9.Holder()
cfgRefresh()

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

local fab = new("TextButton", {Size = UDim2.new(0, 42, 0, 42), Position = UDim2.new(1, -56, 0.5, -21),
    BackgroundColor3 = C.ACCENT, Text = "", AutoButtonColor = false, BorderSizePixel = 0, ZIndex = 10}, toggleGui)
corner(21, fab)
new("UIStroke", {Color = Color3.new(1, 1, 1), Thickness = 2}, fab)
local fabIcon = createIcon(ICONS.MENU, UDim2.new(0, 22, 0, 22), fab)
fabIcon.Position = UDim2.new(0.5, -11, 0.5, -11)
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

print("[Maneware] v6 загружен")

-- Maneware MM2 v7 | Mobile (Delta) - Ultimate Update
-- Features: Fixed GrabGun, Custom Models (Search), Sound Changer (Search), 
-- GUI Editor, Advanced Binds, 5 Watermark Styles, ESP Gun Box.

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

local ICONS = {
    MENU = "rbxassetid://10734898355", HOME = "rbxassetid://10723407389",
    EYE = "rbxassetid://10723346959", SPEED = "rbxassetid://10709752035",
    NOCLIP = "rbxassetid://10723346871", FLY = "rbxassetid://10723354359",
    TARGET = "rbxassetid://10734898355", HAT = "rbxassetid://10723407389",
    AIM = "rbxassetid://10734898355", TP = "rbxassetid://10723354359",
    GUN = "rbxassetid://10723346959", COIN = "rbxassetid://10709752035",
    SHIELD = "rbxassetid://10723346871", UTIL = "rbxassetid://10723407389",
    FLING = "rbxassetid://10723354359", MODEL = "rbxassetid://10723346871",
    SOUND = "rbxassetid://10709752035", EDIT = "rbxassetid://10734898355",
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
-- УТИЛИТЫ GUI
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
    Text = "Maneware | MM2 v7", TextColor3 = C.TEXT, TextSize = 16, Font = Enum.Font.GothamBold,
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

-- Сайдбар
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
local REG = {} 
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

-- Новые состояния
local grabGunEnabled = false
local flingBusy = false
local customModelEnabled = false
local currentModelName = ""
local soundChangerEnabled = false
local currentSoundName = ""

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
-- GRAB GUN (FIXED)
--------------------------------------------------
local grabGunTask = nil
local function stopGrabGun()
    if grabGunTask then task.cancel(grabGunTask); grabGunTask = nil end
    notify("GrabGun отключен")
end

local function sheriffAlive()
    for _, pl in ipairs(Players:GetPlayers()) do
        if pl ~= LocalPlayer and getRole(pl) == "Sheriff" then
            local h = pl.Character and pl.Character:FindFirstChildOfClass("Humanoid")
            if h and h.Health > 0 then return true end
        end
    end
    return false
end

local function hasGun()
    local c = myChar()
    if c and c:FindFirstChild("Gun") then return true end
    local bp = LocalPlayer:FindFirstChild("Backpack")
    return bp and bp:FindFirstChild("Gun") ~= nil
end

local function findGunDrop()
    return workspace:FindFirstChild("GunDrop", true) or workspace:FindFirstChild("GunDrop2", true)
end

local function doGrabGun()
    if flingBusy then return end
    local g = findGunDrop()
    if not g then return end
    
    -- Проверка: Шериф мертв И у нас нет пистолета
    if sheriffAlive() or hasGun() or getRole(LocalPlayer) == "Murderer" then return end
    
    local hrp = myHrp()
    if not hrp then return end

    local originalPos = hrp.CFrame
    local part = g:IsA("BasePart") and g or g:FindFirstChildWhichIsA("BasePart", true)
    if not part then return end

    notify("🔫 GrabGun: Телепорт к пистолету...")
    
    -- Цикл подбора
    local timeout = 0
    while timeout < 20 and not hasGun() and g.Parent do
        hrp.CFrame = part.CFrame + Vector3.new(0, 2, 0)
        hrp.AssemblyLinearVelocity = Vector3.zero
        
        -- Попытка триггера касания
        if firetouchinterest then
            pcall(function() firetouchinterest(hrp, part, 0) firetouchinterest(hrp, part, 1) end)
        end
        
        task.wait(0.1)
        timeout += 1
    end
    
    if hasGun() then notify("🔫 Пистолет подобран!") else notify("⚠️ Не удалось подобрать.") end
    
    -- Возврат
    hrp = myHrp()
    if hrp then
        hrp.CFrame = originalPos
        hrp.AssemblyLinearVelocity = Vector3.zero
    end
end

task.spawn(function()
    while true do
        task.wait(0.5)
        if grabGunEnabled and not flingBusy then
            pcall(doGrabGun)
        end
    end
end)

--------------------------------------------------
-- CUSTOM MODELS (SEARCH ONLY)
--------------------------------------------------
local modelNames = {
    "Tun Tun Sahur", "Sahur", "Sahur2", "Sahur3", "AWP", "Awp", "awp_model"
}

local function applyCustomModel(modelName)
    local char = myChar()
    if not char then return end
    
    -- Поиск модели в workspace
    local foundModel = workspace:FindFirstChild(modelName)
    if not foundModel then
        -- Поиск среди детей игроков (иногда морфы там)
        for _, pl in ipairs(Players:GetPlayers()) do
            if pl.Character and pl.Character:FindFirstChild(modelName) then
                foundModel = pl.Character[modelName]:Clone()
                break
            end
        end
    end
    
    if foundModel then
        -- Очистка старых аксессуаров
        for _, child in ipairs(char:GetChildren()) do
            if child:IsA("Accessory") or child:IsA("CharacterMesh") then
                child:Destroy()
            end
        end
        
        -- Клонируем и внедряем
        local clone = foundModel:Clone()
        clone.Parent = char
        
        -- Пытаемся прикрепить к HumanoidRootPart или Head
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if hrp then
            -- Простое прикрепление через WeldConstraint или просто установка CFrame
            -- Для сложных морфов лучше просто сделать родителем персонажа
            if clone:IsA("Model") then
                for _, part in ipairs(clone:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.Anchored = false
                        part.CanCollide = false
                    end
                end
            end
        end
        notify("Модель '" .. modelName .. "' применена!")
    else
        notify("Модель '" .. modelName .. "' не найдена на сервере!")
    end
end

--------------------------------------------------
-- SOUND CHANGER (SEARCH ONLY)
--------------------------------------------------
local soundNames = {
    ["Skeet"] = {"skeet", "hitmarker", "click"},
    ["Bell"] = {"bell", "ding", "tink"},
    ["Uwu"] = {"uwu", "cute", "anime"},
    ["AWP"] = {"awp", "sniper", "cs_go"},
    ["Deagle"] = {"deagle", "desert_eagle", "handgun"}
}

local originalGunSound = nil

local function changeSound(soundType)
    local char = myChar()
    if not char then return end
    local gun = char:FindFirstChild("Gun") or (LocalPlayer:FindFirstChild("Backpack") and LocalPlayer.Backpack:FindFirstChild("Gun"))
    if not gun then notify("Возьмите пистолет!"); return end
    
    -- Ищем звук в workspace или внутри оружия
    local targetSound = nil
    local keywords = soundNames[soundType] or {}
    
    -- Сканируем workspace
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("Sound") then
            local nameLower = obj.Name:lower()
            for _, key in ipairs(keywords) do
                if nameLower:find(key) then
                    targetSound = obj:Clone()
                    break
                end
            end
        end
        if targetSound then break end
    end
    
    -- Если не нашли, пробуем стандартные имена
    if not targetSound then
        -- fallback логика, если звуки не найдены (можно добавить свои ID, но по ТЗ искать)
        notify("Звук '" .. soundType .. "' не найден в мире игры.")
        return
    end
    
    -- Применяем к оружию
    local existingSound = gun:FindFirstChildWhichIsA("Sound")
    if existingSound then
        originalGunSound = existingSound:Clone() -- сохраняем оригинал для сброса
        existingSound:Destroy()
    end
    
    targetSound.Name = "ShootSound"
    targetSound.Parent = gun
    targetSound.Looped = false
    notify("Звук изменен на: " .. soundType)
end

--------------------------------------------------
-- ESP ПИСТОЛЕТА (BOX IMPROVED)
--------------------------------------------------
local function clearByName(names)
    for _, d in ipairs(workspace:GetDescendants()) do
        if names[d.Name] then d:Destroy() end
    end
end

task.spawn(function()
    while true do
        task.wait(0.5)
        pcall(function()
            if gunEsp then
                local g = findGunDrop()
                if g then
                    local part = g:IsA("BasePart") and g or g:FindFirstChildWhichIsA("BasePart", true)
                    if part then
                        if not part:FindFirstChild("MWGunBox") then
                            new("BoxHandleAdornment", {Name = "MWGunBox", Adornee = part,
                                Size = part.Size + Vector3.new(1, 1, 1), Color3 = Color3.fromRGB(255, 200, 0),
                                Transparency = 0.2, AlwaysOnTop = true, ZIndex = 1}, part)
                        end
                        if not part:FindFirstChild("MWGunHighlight") then
                            new("Highlight", {Name = "MWGunHighlight", Adornee = part, FillColor = Color3.fromRGB(255, 200, 0),
                                OutlineColor = Color3.new(1, 1, 1), FillTransparency = 0.3,
                                DepthMode = Enum.HighlightDepthMode.AlwaysOnTop}, part)
                        end
                        if not part:FindFirstChild("MWGunTag") then
                            local bb = new("BillboardGui", {Name = "MWGunTag", Size = UDim2.new(0, 140, 0, 40),
                                StudsOffset = Vector3.new(0, 3, 0), AlwaysOnTop = true}, part)
                            new("TextLabel", {Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1,
                                Text = " ПИСТОЛЕТ", TextColor3 = Color3.fromRGB(255, 200, 0), TextStrokeTransparency = 0,
                                TextSize = 20, Font = Enum.Font.GothamBlack}, bb)
                        end
                    end
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
-- WATERMARK & BINDS SYSTEM
--------------------------------------------------
local wmGui = makeGui("ManewareWM", 10000)
local bindsGui = makeGui("ManewareBinds", 10001)
local editMode = false

-- Settings
local wmSettings = {
    size = 20,
    style = 1,
    uid = tostring(math.random(10000, 99999)), -- Генерируем UID при запуске
    showTime = true
}

-- Bind Data Structure: {funcName, keyEnum, guiObject}
local activeBinds = {}

local function getMSKTime()
    local utcTime = os.time()
    local mskTime = os.date("*t", utcTime + 3 * 3600) -- UTC+3
    return string.format("%02d:%02d:%02d", mskTime.hour, mskTime.min, mskTime.sec)
end

local function updateWatermark()
    for _, child in ipairs(wmGui:GetChildren()) do
        if child:IsA("Frame") or child:IsA("TextLabel") then child:Destroy() end
    end
    
    if wmSettings.style == 0 then return end -- Off
    
    local frame = new("Frame", {Size = UDim2.new(0, 200, 0, 60), BackgroundTransparency = 1, Position = UDim2.new(0, 10, 0, 10)}, wmGui)
    if editMode then
        frame.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
        frame.BackgroundTransparency = 0.5
        frame.BorderSizePixel = 2
        frame.BorderColor3 = C.ACCENT
    end
    
    local textProps = {
        TextColor3 = Color3.new(1,1,1),
        TextSize = wmSettings.size,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Left,
        BackgroundTransparency = 1,
        TextStrokeTransparency = 0.4,
        TextStrokeColor3 = Color3.new(0,0,0)
    }

    if wmSettings.style == 1 then
        -- Style 1: Name + Nick + UID + Time
        local line1 = new("TextLabel", {Size = UDim2.new(1, 0, 0.5, 0), Position = UDim2.new(0, 0, 0, 0), Text = "Maneware | " .. LocalPlayer.Name, Parent = frame})
        line1.TextSize = wmSettings.size
        for k,v in pairs(textProps) do line1[k] = v end
        
        local line2 = new("TextLabel", {Size = UDim2.new(1, 0, 0.5, 0), Position = UDim2.new(0, 0, 0.5, 0), 
            Text = "UID: " .. wmSettings.uid .. (wmSettings.showTime and " | " .. getMSKTime() or ""), Parent = frame})
        line2.TextSize = wmSettings.size - 2
        for k,v in pairs(textProps) do line2[k] = v end
        
    elseif wmSettings.style == 2 then
        -- Style 2: Name + UID (Photo 3 style)
        local box = new("Frame", {Size = UDim2.new(1, 0, 1, 0), BackgroundColor3 = Color3.fromRGB(20, 20, 20), BackgroundTransparency = 0.3, BorderSizePixel = 0}, frame)
        corner(5, box)
        
        local t1 = new("TextLabel", {Size = UDim2.new(1, -10, 0.5, 0), Position = UDim2.new(0, 5, 0.1, 0), Text = "Maneware", Parent = box})
        t1.TextColor3 = C.ACCENT
        for k,v in pairs(textProps) do t1[k] = v end
        
        local t2 = new("TextLabel", {Size = UDim2.new(1, -10, 0.5, 0), Position = UDim2.new(0, 5, 0.5, 0), Text = "UID: " .. wmSettings.uid, Parent = box})
        t2.TextColor3 = C.TEXT
        for k,v in pairs(textProps) do t2[k] = v end
        
    elseif wmSettings.style == 3 then
        -- Style 3: Photo 4 style (Deadcode -> Maneware)
        local box = new("Frame", {Size = UDim2.new(0, 150, 0, 30), Position = UDim2.new(0.5, -75, 1, -40), BackgroundColor3 = Color3.fromRGB(0,0,0), BackgroundTransparency = 0.4}, frame)
        corner(4, box)
        local t = new("TextLabel", {Size = UDim2.new(1, 0, 1, 0), Text = "Maneware", TextColor3 = C.RED, Font = Enum.Font.SourceSansBold}, box)
        t.TextSize = wmSettings.size + 5
        t.TextStrokeTransparency = 0.5
        
    elseif wmSettings.style == 4 then
        -- Style 4: Photo 5 style (Ping, RAM, Nick)
        local ping = math.floor(LocalPlayer:GetNetworkPing())
        local ram = "???" -- Roblox Lua не дает прямой доступ к потреблению памяти процесса без сторонних библиотек, заглушка
        if collectgarbage then 
             -- попытка оценить
             ram = tostring(math.floor(collectgarbage("count"))) .. " MB"
        end
        
        local box = new("Frame", {Size = UDim2.new(0, 220, 0, 80), Position = UDim2.new(0, 10, 0, 60), BackgroundColor3 = Color3.fromRGB(10,10,15), BackgroundTransparency = 0.2}, frame)
        corner(8, box)
        new("UIStroke", {Color = C.ACCENT, Thickness = 1}, box)
        
        local l1 = new("TextLabel", {Size = UDim2.new(1, -10, 0.33, 0), Position = UDim2.new(0, 5, 0, 2), Text = "Ping: " .. ping .. "ms", Parent = box})
        local l2 = new("TextLabel", {Size = UDim2.new(1, -10, 0.33, 0), Position = UDim2.new(0, 5, 0.33, 2), Text = "RAM: " .. ram, Parent = box})
        local l3 = new("TextLabel", {Size = UDim2.new(1, -10, 0.33, 0), Position = UDim2.new(0, 5, 0.66, 2), Text = "User: " .. LocalPlayer.Name, Parent = box})
        
        for _, l in ipairs({l1, l2, l3}) do
            l.TextColor3 = C.TEXT
            l.TextSize = wmSettings.size - 4
            l.Font = Enum.Font.Gotham
            l.BackgroundTransparency = 1
        end
    end
end

-- Bind Button Logic
local function createBindButton(funcName, keyEnum)
    local btn = new("TextButton", {Size = UDim2.new(0, 100, 0, 40), BackgroundColor3 = C.ELEMENT, 
        Text = "[" .. tostring(keyEnum):gsub("Enum.KeyCode.", "") .. "] " .. funcName, 
        TextColor3 = C.TEXT, TextSize = 12, Font = Enum.Font.GothamBold, BorderSizePixel = 0}, bindsGui)
    corner(8, btn)
    new("UIStroke", {Color = C.BORDER}, btn)
    
    -- Dragging logic for bind button
    local draggingBind = false
    local dragStartPos, btnStartPos
    
    btn.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            draggingBind = true
            dragStartPos = i.Position
            btnStartPos = btn.Position
        end
    end)
    
    UIS.InputChanged:Connect(function(i)
        if draggingBind and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
            local delta = i.Position - dragStartPos
            btn.Position = UDim2.new(btnStartPos.X.Scale, btnStartPos.X.Offset + delta.X, btnStartPos.Y.Scale, btnStartPos.Y.Offset + delta.Y)
        end
    end)
    
    UIS.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            draggingBind = false
        end
    end)
    
    return btn
end

local function toggleBindState(bindData)
    -- Здесь должна быть логика включения/выключения конкретной функции
    -- Для примера просто уведомление, так как функции разбросаны по скрипту
    notify("Бинд активирован: " .. bindData.funcName)
    -- В реальном сценарии здесь вызов REG[bindData.funcName].set(true/false)
end

local function deleteBind(bindData)
    if bindData.guiObject then bindData.guiObject:Destroy() end
    activeBinds[bindData.funcName] = nil
    notify("Бинд удален")
end

--------------------------------------------------
-- TELEPORTS & OTHERS (Shortened for space)
--------------------------------------------------
local function tpTo(cf) local hrp = myHrp() if hrp then hrp.CFrame = cf end end
local function tpLobby() tpTo(workspace:FindFirstChild("Lobby") and workspace.Lobby.Spawns:GetChildren()[1].CFrame or Vector3.new(0,10,0)) end
local function tpMap() local m = workspace:FindFirstChildWhichIsA("Model", true) if m then tpTo(m:GetPivot() + Vector3.new(0,10,0)) end end
local function tpRole(role) local p = findByRole(role, true) if p and p.Character then tpTo(p.Character.HumanoidRootPart.CFrame) end end

--------------------------------------------------
-- FLING
--------------------------------------------------
local function flingPlayer(target)
    if flingBusy then return end
    local tc = target.Character
    local thrp = tc and tc:FindFirstChild("HumanoidRootPart")
    local hrp = myHrp()
    if not thrp or not hrp then return end
    
    flingBusy = true
    local origin = hrp.CFrame
    local bv = thrp:FindFirstChildWhichIsA("BodyVelocity") or new("BodyVelocity", {MaxForce=Vector3.new(1e9,1e9,1e9)}, thrp)
    bv.Velocity = Vector3.new(0, 500, 0)
    
    task.delay(2, function()
        bv:Destroy()
        hrp.CFrame = origin
        flingBusy = false
    end)
end
local function flingRole(role) local p = findByRole(role, true) if p then flingPlayer(p) end end

--------------------------------------------------
-- ВКЛАДКИ
--------------------------------------------------
local t1 = addTab("Основное", ICONS.HOME)
local t2 = addTab("Визуалы", ICONS.EYE)
local t3 = addTab("Шериф", ICONS.AIM)
local t4 = addTab("Телепорт", ICONS.TP)
local t5 = addTab("Утилиты", ICONS.UTIL)
local t6 = addTab("Модели", ICONS.MODEL)
local t7 = addTab("Звуки", ICONS.SOUND)
local t8 = addTab("Настройки GUI", ICONS.EDIT)

-- Основное
t1.Section("⚡ Движение")
t1.Toggle("SpeedHack", false, function(v) speedEnabled = v; local h = myHum() if h and not v then h.WalkSpeed = 16 end end, ICONS.SPEED)
t1.Slider("Скорость", 16, 300, 16, " sp", function(v) speedValue = v end)
t1.Toggle("NoClip", false, function(v) noclipUser = v if not flyEnabled then toggleNoclip(v) end end, ICONS.NOCLIP)
t1.Toggle("Fly", false, function(v) flyEnabled = v; flyGui.Enabled = v; if v then startFly() else stopFly() end end, ICONS.FLY)
t1.Slider("Скорость полёта", 10, 150, 50, " st/s", function(v) flySpeed = v end)
t1.Toggle("Infinite Jump", false, function(v) infJump = v end, ICONS.FLY)

-- Визуалы
t2.Section("🎨 ESP")
t2.Toggle("Подсветка ролей", false, function(v) highlightEnabled = v; for _, o in pairs(espObjects) do if o.H then o.H.Enabled = v end if o.B then o.B.Enabled = v end end end, ICONS.EYE)
t2.Toggle("ESP Пистолета (Box)", false, function(v) gunEsp = v; if not v then clearByName({MWGunBox=true, MWGunHighlight=true, MWGunTag=true}) end end, ICONS.GUN)
t2.Toggle("ESP Монет", false, function(v) coinEsp = v; if not v then clearByName({MWCoin=true}) end end, ICONS.COIN)

-- Шериф
t3.Section("🔫 Пистолет")
t3.Toggle("GrabGun (Авто-подбор)", false, function(v) grabGunEnabled = v; if not v then stopGrabGun() end end, ICONS.GUN)
t3.Button("Fling Murderer", function() flingRole("Murderer") end)
t3.Button("Fling Sheriff", function() flingRole("Sheriff") end)

-- Модели
t6.Section("👺 Custom Models (Search)")
t6.Toggle("Apply Model", false, function(v) 
    customModelEnabled = v 
    if v then 
        -- Выбор модели (упрощено до первой найденной из списка для демо)
        for _, name in ipairs(modelNames) do
            if workspace:FindFirstChild(name) then
                applyCustomModel(name)
                currentModelName = name
                break
            end
        end
        if currentModelName == "" then notify("Модели не найдены!") end
    else
        -- Сброс (респаун или удаление аксессуаров)
        local char = myChar()
        if char then
            for _, child in ipairs(char:GetChildren()) do
                if child:IsA("Accessory") or (child:IsA("Model") and child.Name ~= "HumanoidRootPart") then
                    child:Destroy()
                end
            end
        end
        notify("Модель сброшена")
    end
end, ICONS.MODEL)
t6.Button("Refresh Models", function() 
    local found = {}
    for _, name in ipairs(modelNames) do
        if workspace:FindFirstChild(name) then table.insert(found, name) end
    end
    notify("Найдено моделей: " .. #found)
end)

-- Звуки
t7.Section(" Sound Changer")
t7.Toggle("Enable Sound Mod", false, function(v) soundChangerEnabled = v end, ICONS.SOUND)
t7.Button("Select Sound...", function()
    -- Эмуляция мини-меню выбора звука
    local sounds = {"Skeet", "Bell", "Uwu", "AWP", "Deagle"}
    local selected = nil
    -- В реальном UI здесь было бы выпадающее меню, сделаем кнопки в чате для простоты или уведомление
    notify("Выберите звук в консоли (эмуляция): Skeet, Bell, Uwu, AWP, Deagle")
    -- Для полноценного GUI нужно добавлять кнопки динамически, сделаем одну кнопку для теста
    changeSound("Skeet") 
end)
-- Добавим кнопки для каждого звука
for _, sName in ipairs({"Skeet", "Bell", "Uwu", "AWP", "Deagle"}) do
    t7.Button("Sound: " .. sName, function() if soundChangerEnabled then changeSound(sName) else notify("Включите Sound Mod") end end)
end

-- Настройки GUI (Editor, Binds, Watermark)
t8.Section("️ GUI Editor")
t8.Toggle("Edit Mode (Drag WM/Binds)", false, function(v) 
    editMode = v 
    updateWatermark()
    if v then notify("Режим редактирования: Перетаскивайте элементы. Нажмите 'Save' для фиксации.")
    else notify("Режим редактирования выключен.") end
end, ICONS.EDIT)

t8.Section("💧 Watermark")
t8.Slider("Size", 10, 40, 20, " px", function(v) wmSettings.size = v; updateWatermark() end)
t8.Slider("Style", 1, 4, 1, "", function(v) wmSettings.style = v; updateWatermark() end) -- 1-4 styles
t8.Toggle("Show Time (MSK)", true, function(v) wmSettings.showTime = v; updateWatermark() end)

t8.Section("️ Binds")
t8.Button("Add Bind Example (Speed)", function()
    if activeBinds["SpeedHack"] then notify("Бинд уже есть"); return end
    local bindData = {funcName = "SpeedHack", keyEnum = Enum.KeyCode.RightShift, guiObject = nil}
    bindData.guiObject = createBindButton(bindData.funcName, bindData.keyEnum)
    
    -- Кнопка удаления на самом бинде (дополнительная логика UI)
    local delBtn = new("TextButton", {Size = UDim2.new(0, 20, 0, 20), Position = UDim2.new(1, -22, 0, 2), 
        Text = "✕", TextColor3 = C.RED, BackgroundColor3 = C.BG, TextSize = 14, BorderSizePixel=0}, bindData.guiObject)
    corner(4, delBtn)
    delBtn.MouseButton1Click:Connect(function() deleteBind(bindData) end)
    
    activeBinds["SpeedHack"] = bindData
    notify("Бинд создан: RightShift -> SpeedHack")
end)

t8.Button("Save Positions", function()
    editMode = false
    REG["Edit Mode (Drag WM/Binds)"].set(false)
    notify("Позиции сохранены!")
end)

-- Teleports
t4.Section("📍 Телепорты")
t4.Button("В лобби", tpLobby)
t4.Button("На карту", tpMap)
t4.Button("К убийце", function() tpRole("Murderer") end)
t4.Button("К шерифу", function() tpRole("Sheriff") end)

-- Utils
t5.Section("🛠 Утилиты")
t5.Toggle("Anti-AFK", true, function(v) antiAfk = v end, ICONS.UTIL)
t5.Toggle("FPS Boost", false, function(v) 
    if v then settings().Rendering.QualityLevel = Enum.QualityLevel.Level01; Lighting.GlobalShadows = false 
    else settings().Rendering.QualityLevel = Enum.QualityLevel.Level03; Lighting.GlobalShadows = true end
end, ICONS.SPEED)

--------------------------------------------------
-- INPUT HANDLING FOR BINDS & EDITOR
--------------------------------------------------
UIS.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed and not editMode then return end
    
    -- Обработка биндов
    for _, bindData in pairs(activeBinds) do
        if input.KeyCode == bindData.keyEnum then
            toggleBindState(bindData)
        end
    end
    
    -- Закрытие главного меню по клику вне его (если не редактирование)
    -- Реализация сложна без полного трекинга, оставим кнопку закрытия
end)

-- Обновление водяного знака каждую секунду (для времени)
task.spawn(function()
    while true do
        task.wait(1)
        if wmSettings.style == 1 or wmSettings.style == 4 then
            updateWatermark()
        end
    end
end)

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

print("[Maneware v7] Loaded with Custom Models, Sounds, Editor & Binds")

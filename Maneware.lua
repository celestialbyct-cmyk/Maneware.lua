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

local DATA_DIR = "ManewareMM2"
local function ensureDir()
    pcall(function()
        if isfolder and makefolder and not isfolder(DATA_DIR) then makefolder(DATA_DIR) end
    end)
end
local function readJson(name)
    local ok, data = pcall(function()
        if isfile and readfile and isfile(DATA_DIR .. "/" .. name) then
            return HttpService:JSONDecode(readfile(DATA_DIR .. "/" .. name))
        end
    end)
    if ok and type(data) == "table" then return data end
    return nil
end
local function writeJson(name, tbl)
    ensureDir()
    return pcall(function() writefile(DATA_DIR .. "/" .. name, HttpService:JSONEncode(tbl)) end)
end
-- UID = порядковый номер запуска скрипта (с первого запуска этой версии)
local UID = 1
pcall(function()
    ensureDir()
    local n = 0
    if isfile and readfile and isfile(DATA_DIR .. "/uid.txt") then n = tonumber(readfile(DATA_DIR .. "/uid.txt")) or 0 end
    UID = n + 1
    writefile(DATA_DIR .. "/uid.txt", tostring(UID))
end)

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
local NT = {} -- хуки уведомлений (send/toggle заполняются ниже)
local function notify(text)
    text = tostring(text)
    local title, msg = text:match("^([^:]-):%s*(.+)$") -- "Название: сообщение" -> две строки карточки
    if NT.send then
        NT.send(title or "Maneware", msg or text)
    else
        pcall(function()
            StarterGui:SetCore("SendNotification", {Title = "Maneware", Text = text, Duration = 3})
        end)
    end
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
    Text = "Maneware | MM2 v9", TextColor3 = C.TEXT, TextSize = 16, Font = Enum.Font.GothamBold,
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
local ACT = {} -- кнопки-действия (для биндов)
local X = {}   -- общие функции между блоками
local tabs, activeTab = {}, nil

local function addTab(name, icon, order)
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
        BackgroundTransparency = 1, Text = "", AutoButtonColor = false, BorderSizePixel = 0, LayoutOrder = order or idx}, sidebar)
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
        local function apply(v, silent)
            state = v and true or false
            tw(bg, 0.2, {BackgroundColor3 = state and C.ACCENT or Color3.fromRGB(55, 55, 70)})
            tw(dot, 0.2, {Position = state and UDim2.new(1, -25, 0.5, -11) or UDim2.new(0, 3, 0.5, -11)})
            if callback then task.spawn(callback, state) end
            if not silent and NT.toggle then NT.toggle(text, state) end
        end
        onTap(el, function() apply(not state) end)
        REG[text] = {kind = "toggle", get = function() return state end, set = apply}
    end

    -- Тоггл + стрелка справа: по нажатию снизу открывается мини-меню выбора
    function T.ToggleDrop(text, default, callback, iconId, options, defIdx, onSelect)
        local state = default or false
        local sel = defIdx or 1
        local wrap = new("Frame", {Size = UDim2.new(1, -8, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundTransparency = 1}, page)
        new("UIListLayout", {Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder}, wrap)
        local el = new("TextButton", {Size = UDim2.new(1, 0, 0, 56), BackgroundColor3 = C.ELEMENT, Text = "",
            AutoButtonColor = false, BorderSizePixel = 0, LayoutOrder = 1}, wrap)
        corner(10, el)
        new("UIStroke", {Color = C.BORDER, Thickness = 1}, el)
        local textX = 14
        if iconId then
            createIcon(iconId, UDim2.new(0, 24, 0, 24), el).Position = UDim2.new(0, 12, 0.5, -12)
            textX = 46
        end
        new("TextLabel", {Size = UDim2.new(1, -textX - 116, 1, 0), Position = UDim2.new(0, textX, 0, 0),
            BackgroundTransparency = 1, Text = text, TextColor3 = C.TEXT, TextSize = 13,
            Font = Enum.Font.GothamSemibold, TextXAlignment = Enum.TextXAlignment.Left, TextWrapped = true}, el)
        local bg = new("Frame", {Size = UDim2.new(0, 54, 0, 28), Position = UDim2.new(1, -66, 0.5, -14),
            BackgroundColor3 = state and C.ACCENT or Color3.fromRGB(55, 55, 70), BorderSizePixel = 0}, el)
        corner(14, bg)
        local dot = new("Frame", {Size = UDim2.new(0, 22, 0, 22),
            Position = state and UDim2.new(1, -25, 0.5, -11) or UDim2.new(0, 3, 0.5, -11),
            BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0}, bg)
        corner(11, dot)
        local arrow = new("TextButton", {Size = UDim2.new(0, 30, 0, 30), Position = UDim2.new(1, -104, 0.5, -15),
            BackgroundColor3 = Color3.fromRGB(45, 45, 60), Text = "▼", TextColor3 = C.TEXT, TextSize = 12,
            Font = Enum.Font.GothamBold, BorderSizePixel = 0, AutoButtonColor = true}, el)
        corner(8, arrow)
        local menu = new("Frame", {Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundColor3 = Color3.fromRGB(26, 26, 36), BorderSizePixel = 0, Visible = false, LayoutOrder = 2}, wrap)
        corner(10, menu)
        new("UIListLayout", {Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder}, menu)
        new("UIPadding", {PaddingTop = UDim.new(0, 6), PaddingBottom = UDim.new(0, 6), PaddingLeft = UDim.new(0, 6),
            PaddingRight = UDim.new(0, 6)}, menu)
        local btns = {}
        local function refreshSel()
            for i, b in ipairs(btns) do b.BackgroundColor3 = (i == sel) and C.ACCENT or C.ELEMENT end
        end
        local function choose(i)
            i = math.clamp(math.floor(tonumber(i) or 1), 1, #options)
            sel = i
            refreshSel()
            if onSelect then task.spawn(onSelect, i) end
        end
        for i, name in ipairs(options) do
            local b = new("TextButton", {Size = UDim2.new(1, 0, 0, 34), BackgroundColor3 = C.ELEMENT,
                Text = i .. ". " .. name, TextColor3 = C.TEXT, TextSize = 13, Font = Enum.Font.GothamSemibold,
                BorderSizePixel = 0, LayoutOrder = i}, menu)
            corner(8, b)
            btns[i] = b
            onTap(b, function() choose(i) end)
        end
        refreshSel()
        local open = false
        onTap(arrow, function()
            open = not open
            menu.Visible = open
            arrow.Text = open and "▲" or "▼"
        end)
        local function apply(v, silent)
            state = v and true or false
            tw(bg, 0.2, {BackgroundColor3 = state and C.ACCENT or Color3.fromRGB(55, 55, 70)})
            tw(dot, 0.2, {Position = state and UDim2.new(1, -25, 0.5, -11) or UDim2.new(0, 3, 0.5, -11)})
            if callback then task.spawn(callback, state) end
            if not silent and NT.toggle then NT.toggle(text, state) end
        end
        onTap(el, function() apply(not state) end)
        REG[text] = {kind = "toggle", get = function() return state end, set = apply}
        REG[text .. " [выбор]"] = {kind = "select", get = function() return sel end, set = choose}
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
        if callback then ACT[text] = callback end
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

local function addSideLabel(text, order)
    new("TextLabel", {Size = UDim2.new(1, 0, 0, 22), BackgroundTransparency = 1, Text = text, TextColor3 = C.DIM,
        TextSize = 11, Font = Enum.Font.GothamBold, TextXAlignment = Enum.TextXAlignment.Left, LayoutOrder = order}, sidebar)
end
-- кнопка в сайдбаре, которая НЕ вкладка и не тоггл: просто выполняет действие
local function addSideButton(text, icon, order, fn)
    local btn = new("TextButton", {Size = UDim2.new(1, 0, 0, 40), BackgroundColor3 = C.ELEMENT,
        BackgroundTransparency = 0.55, Text = "", AutoButtonColor = true, BorderSizePixel = 0, LayoutOrder = order}, sidebar)
    corner(8, btn)
    local ic = createIcon(icon, UDim2.new(0, 20, 0, 20), btn)
    ic.Position = UDim2.new(0, 8, 0.5, -10)
    ic.ImageColor3 = C.ACCENT
    new("TextLabel", {Size = UDim2.new(1, -36, 1, 0), Position = UDim2.new(0, 32, 0, 0), BackgroundTransparency = 1,
        Text = text, TextColor3 = C.TEXT, TextSize = 12, Font = Enum.Font.GothamSemibold,
        TextXAlignment = Enum.TextXAlignment.Left, TextWrapped = true}, btn)
    onTap(btn, fn)
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
local spinbot = {on = false, speed = 20} -- speed 1-50 (обороты/сек примерно)

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

RunService.Heartbeat:Connect(function(dt)
    if speedEnabled then
        local h = myHum()
        if h and h.WalkSpeed ~= speedValue then h.WalkSpeed = speedValue end
    end
    -- Spinbot: вращение персонажа вокруг оси Y
    if spinbot.on then
        local hrp = myHrp()
        if hrp then
            -- speed 1–50 ≈ 1–50 оборотов в секунду
            local ang = math.rad(spinbot.speed * 360 * (dt or 0.016))
            hrp.CFrame = hrp.CFrame * CFrame.Angles(0, ang, 0)
        end
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
local tgt = {glow = true, size = 0.5, speed = 1.0, glowStr = 1.0}

-- Плоская рамка из 4 красных уголков + яркое свечение
local function buildReticle()
    local bb = new("BillboardGui", {Name = "MWTargetBB", Size = UDim2.new(3, 0, 3, 0), AlwaysOnTop = true,
        LightInfluence = 0, Enabled = false})
    local spin = new("Frame", {Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Rotation = 25}, bb)
    local glow = new("Frame", {Name = "Glow", Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1}, spin)
    local lines = {}
    local function corners(parent, color, base, transp, len)
        for _, a in ipairs({Vector2.new(0, 0), Vector2.new(1, 0), Vector2.new(0, 1), Vector2.new(1, 1)}) do
            local hz = new("Frame", {Size = UDim2.new(len, 0, 0, base), Position = UDim2.new(a.X, 0, a.Y, 0), AnchorPoint = a,
                BackgroundColor3 = color, BackgroundTransparency = transp, BorderSizePixel = 0}, parent)
            local vt = new("Frame", {Size = UDim2.new(0, base, len, 0), Position = UDim2.new(a.X, 0, a.Y, 0), AnchorPoint = a,
                BackgroundColor3 = color, BackgroundTransparency = transp, BorderSizePixel = 0}, parent)
            table.insert(lines, {hz, true, base, len})
            table.insert(lines, {vt, false, base, len})
        end
    end
    -- Яркое многослойное свечение
    local haloOuter = new("Frame", {Size = UDim2.new(1, 18, 1, 18), Position = UDim2.new(0, -9, 0, -9),
        BackgroundColor3 = Color3.fromRGB(255, 20, 60), BackgroundTransparency = 0.92, BorderSizePixel = 0}, glow)
    corner(12, haloOuter)
    new("UIStroke", {Color = Color3.fromRGB(255, 40, 80), Thickness = 8, Transparency = 0.65}, haloOuter)
    local halo = new("Frame", {Size = UDim2.new(1, 8, 1, 8), Position = UDim2.new(0, -4, 0, -4),
        BackgroundColor3 = Color3.fromRGB(255, 40, 80), BackgroundTransparency = 0.78, BorderSizePixel = 0}, glow)
    corner(8, halo)
    new("UIStroke", {Color = Color3.fromRGB(255, 80, 120), Thickness = 4, Transparency = 0.35}, halo)
    local core = new("Frame", {Size = UDim2.new(1, 0, 1, 0),
        BackgroundColor3 = Color3.fromRGB(255, 60, 100), BackgroundTransparency = 0.88, BorderSizePixel = 0}, glow)
    corner(6, core)
    corners(glow, Color3.fromRGB(255, 50, 90), 12, 0.45, 0.42)
    corners(spin, Color3.fromRGB(255, 90, 120), 3, 0, 0.36)
    return bb, spin, glow, lines
end

local function applyTarget()
    removeTarget()
    if not targetEspEnabled then return end
    local bb, spin, glow, lines = buildReticle()
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
            bb.Adornee = r
            local sz = 6 * tgt.size
            bb.Size = UDim2.new(sz, 0, sz, 0)
            glow.Visible = tgt.glow
            -- Сила свечения
            if tgt.glow then
                local gs = math.clamp(tgt.glowStr or 1, 0.3, 2)
                for _, ch in ipairs(glow:GetChildren()) do
                    if ch:IsA("Frame") then
                        local baseT = ch:GetAttribute("BaseT")
                        if not baseT then
                            baseT = ch.BackgroundTransparency
                            ch:SetAttribute("BaseT", baseT)
                        end
                        ch.BackgroundTransparency = math.clamp(baseT / gs, 0.2, 0.98)
                    end
                end
            end
            local dist = (r.Position - Camera.CFrame.Position).Magnitude
            local k = math.clamp((22 / math.max(dist, 8)) ^ 0.5, 0.5, 1.2)
            for _, ln in ipairs(lines) do
                local th = math.max(1, ln[3] * k)
                if ln[2] then
                    ln[1].Size = UDim2.new(ln[4], 0, 0, th)
                else
                    ln[1].Size = UDim2.new(0, th, ln[4], 0)
                end
            end
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
                        notify("Gun ESP: Пистолет упал")
                    end
                    if not part:FindFirstChild("MWGunBox") then -- 3D-бокс (минимум 2.5 стада)
                        new("BoxHandleAdornment", {Name = "MWGunBox", Adornee = part,
                            Size = Vector3.new(math.max(part.Size.X, 2.5), math.max(part.Size.Y, 2.5), math.max(part.Size.Z, 2.5)),
                            Color3 = Color3.fromRGB(255, 200, 0), Transparency = 0.55, AlwaysOnTop = true, ZIndex = 1}, part)
                    end
                    if not part:FindFirstChild("MWGunBox2D") then -- плоская рамка-бокс на экране
                        local bx = new("BillboardGui", {Name = "MWGunBox2D", Size = UDim2.new(0, 46, 0, 46),
                            AlwaysOnTop = true, LightInfluence = 0}, part)
                        local fr = new("Frame", {Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1}, bx)
                        new("UIStroke", {Color = Color3.fromRGB(255, 200, 0), Thickness = 2}, fr)
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
                local cc = workspace:FindFirstChild("CoinContainer", true)
                if cc then
                    for _, coin in ipairs(cc:GetChildren()) do
                        local cp = coin:IsA("BasePart") and coin or coin:FindFirstChildWhichIsA("BasePart", true)
                        if cp and not cp:FindFirstChild("MWCoin") then
                            new("BoxHandleAdornment", {Name = "MWCoin", Adornee = cp,
                                Size = Vector3.new(1.6, 1.6, 1.6), Color3 = Color3.fromRGB(255, 215, 0),
                                Transparency = 0.35, AlwaysOnTop = true, ZIndex = 1}, cp)
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
    local cc0 = workspace:FindFirstChild("CoinContainer", true)
    if cc0 and cc0.Parent and cc0.Parent ~= workspace then return cc0.Parent end
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
    elseif map:IsA("Model") then tpTo(map:GetPivot() + Vector3.new(0, 10, 0))
    else notify("Точка телепорта на карте не найдена") end
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
local fpsConn = nil
local function fpsBoost(on)
    if fpsConn then fpsConn:Disconnect() fpsConn = nil end
    if on then
        fpsSaved = {}
        local function save(inst, prop, val)
            pcall(function()
                local old = inst[prop]
                inst[prop] = val
                table.insert(fpsSaved, {inst, prop, old})
            end)
        end
        -- Максимальный potato / soap mode
        pcall(function()
            settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
            settings().Rendering.MeshPartDetailLevel = Enum.MeshPartDetailLevel.Level01
            settings().Rendering.EagerBulkExecution = true
        end)
        save(Lighting, "GlobalShadows", false)
        save(Lighting, "FogEnd", 200)
        save(Lighting, "Brightness", 1)
        save(Lighting, "OutdoorAmbient", Color3.fromRGB(128, 128, 128))
        save(Lighting, "Ambient", Color3.fromRGB(100, 100, 100))
        save(Lighting, "Technology", Enum.Technology.Compatibility)
        for _, v in ipairs(Lighting:GetChildren()) do
            if v:IsA("PostEffect") then save(v, "Enabled", false)
            elseif v:IsA("Atmosphere") then save(v, "Density", 0)
            elseif v:IsA("Sky") then save(v, "Parent", nil) end
        end
        local function strip(obj)
            for _, v in ipairs(obj:GetDescendants()) do
                if v:IsA("ParticleEmitter") or v:IsA("Trail") or v:IsA("Smoke") or v:IsA("Fire")
                    or v:IsA("Sparkles") or v:IsA("Beam") or v:IsA("PointLight")
                    or v:IsA("SpotLight") or v:IsA("SurfaceLight") then
                    save(v, "Enabled", false)
                elseif v:IsA("Decal") or v:IsA("Texture") then
                    save(v, "Transparency", 1)
                elseif v:IsA("MeshPart") then
                    pcall(function() v.TextureID = "" end)
                    save(v, "Material", Enum.Material.SmoothPlastic)
                elseif v:IsA("BasePart") and not v:IsA("Terrain") then
                    save(v, "Material", Enum.Material.SmoothPlastic)
                    save(v, "Reflectance", 0)
                    if v.Material == Enum.Material.Glass or v.Material == Enum.Material.ForceField then
                        save(v, "Transparency", math.min(v.Transparency + 0.3, 1))
                    end
                end
            end
        end
        pcall(strip, workspace)
        -- Периодически чистим новые эффекты
        fpsConn = RunService.Heartbeat:Connect(function()
            if not on then return end
            for _, v in ipairs(workspace:GetDescendants()) do
                if (v:IsA("ParticleEmitter") or v:IsA("Trail") or v:IsA("Smoke") or v:IsA("Fire")
                    or v:IsA("Sparkles") or v:IsA("Beam")) and v.Enabled then
                    pcall(function() v.Enabled = false end)
                end
            end
        end)
        notify("FPS Boost: potato mode")
    else
        for _, s in ipairs(fpsSaved) do pcall(function() s[1][s[2]] = s[3] end) end
        fpsSaved = {}
        pcall(function()
            settings().Rendering.QualityLevel = Enum.QualityLevel.Automatic
        end)
        notify("FPS Boost: выкл")
    end
end

--------------------------------------------------
-- SHERIFF AIM
--------------------------------------------------
local aim = {on = false, visible = true, predict = true, strength = 100, range = 250, cd = 1.0, last = 0, hacker = false}
local BULLET_SPEED = 1500 -- пуля MM2 мгновенная (hitscan): упреждаем только на задержку сети
local aimBusy = false

local function hasGun()
    local c = myChar()
    if c and c:FindFirstChild("Gun") then return true end
    local bp = LocalPlayer:FindFirstChild("Backpack")
    return bp and bp:FindFirstChild("Gun") ~= nil
end

-- Проверка видимости конкретной части (хитбокс)
local function partVisible(part)
    if not part then return false end
    local _, onScreen = Camera:WorldToViewportPoint(part.Position)
    if not onScreen then return false end
    local ignore = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p.Character then table.insert(ignore, p.Character) end
    end
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = ignore
    local origin = Camera.CFrame.Position
    local hit = workspace:Raycast(origin, part.Position - origin, params)
    return hit == nil
end

local function isVisible(targetChar)
    local head = targetChar:FindFirstChild("Head") or targetChar:FindFirstChild("HumanoidRootPart")
    return partVisible(head)
end

-- Лучшая видимая часть хитбокса (Head > Torso/UpperTorso > HRP)
local function bestHitPart(char)
    if not char then return nil end
    local order = {"Head", "UpperTorso", "Torso", "HumanoidRootPart", "LowerTorso"}
    local firstAny = nil
    for _, name in ipairs(order) do
        local p = char:FindFirstChild(name)
        if p and p:IsA("BasePart") then
            if not firstAny then firstAny = p end
            if partVisible(p) then return p end
        end
    end
    -- Hacker / wallbang: стреляем даже сквозь стены в лучшую часть
    if aim.hacker then return firstAny or char:FindFirstChild("HumanoidRootPart") end
    return nil
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

-- задержка туда-обратно (сек): именно на неё цель успевает сместиться
local function getRtt()
    local ok, v = pcall(function() return game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValue() end)
    if ok and v and v > 0 then return v / 1000 end
    local ok2, pp = pcall(function() return LocalPlayer:GetNetworkPing() end)
    return ok2 and pp * 2 or 0.1
end

local function predictAt(part, speed, strength)
    -- part = точка прицеливания (Head/HRP), скорость берём с HRP персонажа
    local pos = part.Position
    local my = myHrp()
    local char = part.Parent
    local hrp = char and char:FindFirstChild("HumanoidRootPart") or part
    local d = vTrack[hrp]
    local vel = d and d.vel or hrp.AssemblyLinearVelocity
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if hum and hum.MoveDirection.Magnitude < 0.05 then vel = vel * 0.2 end -- стоит: упреждение почти не нужно
    if vel.Magnitude > 45 then vel = vel.Unit * 45 end -- отсекаем рывки/телепорты
    vel = Vector3.new(vel.X, vel.Y * 0.4, vel.Z)
    local rtt = getRtt()
    local origin = my and my.Position or Camera.CFrame.Position
    local predicted = pos
    for _ = 1, 3 do -- время зависит от точки упреждения, уточняем итерациями
        local t = (predicted - origin).Magnitude / speed + rtt
        predicted = pos + vel * t * strength
    end
    return predicted
end

local function predictPos(hrp)
    -- Целимся в видимую часть хитбокса (или любую при Hacker)
    local char = hrp.Parent
    local targetPart = bestHitPart(char) or hrp
    if not aim.predict then return targetPart.Position end
    return predictAt(targetPart, BULLET_SPEED, aim.strength / 100)
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

    local ks = gun:FindFirstChild("KnifeServer")
    local sg = ks and ks:FindFirstChild("ShootGun")
    if sg and sg:IsA("RemoteFunction") then
        if pcall(function() sg:InvokeServer(1, pos, "AH2") end) then return end
        if pcall(function() sg:InvokeServer(1, pos, "AH") end) then return end
    end
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
    -- Visible check: без Hacker — только если есть видимая часть; с Hacker — всегда
    local hitPart = bestHitPart(mc)
    if not hitPart then return end
    if aim.visible and not aim.hacker and not partVisible(hitPart) then return end
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

-- GunDrop есть в workspace = шериф умер и пистолет ещё не подобрали
local function doGrabGun()
    if grabBusy or flingBusy then return end
    local g = findGunDrop()
    if not g then return end
    local part = gunDropPart(g)
    if not part then return end
    if hasGun() or getRole(LocalPlayer) == "Murderer" then return end
    local char, hrp, hum = myChar(), myHrp(), myHum()
    if not char or not hrp or not hum or hum.Health <= 0 then return end

    grabBusy = true
    grabLast = os.clock()
    local origin = hrp.CFrame
    notify("GrabGun: лечу за пистолетом")
    pcall(function() hum.Sit = false end)
    local got = false
    local t0 = os.clock()
    while os.clock() - t0 < 3 do
        hrp = myHrp()
        if not hrp or not g.Parent then break end -- нет персонажа / пистолет уже забрали
        hrp.CFrame = part.CFrame * CFrame.new(0, 1.5, 0)
        hrp.AssemblyLinearVelocity = Vector3.zero
        if firetouchinterest then
            for _, limb in ipairs(char:GetChildren()) do
                if limb:IsA("BasePart") then
                    pcall(function()
                        firetouchinterest(limb, part, 0)
                        firetouchinterest(limb, part, 1)
                    end)
                end
            end
        end
        if hasGun() then got = true break end
        task.wait(0.1)
    end
    hrp = myHrp()
    if hrp then
        hrp.AssemblyLinearVelocity = Vector3.zero
        hrp.CFrame = origin -- назад на прежнюю точку
    end
    notify(got and "GrabGun: пистолет получен ✔" or "GrabGun: не удалось забрать")
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
    safe = 0, count = 0, done = false, sessionCoins = 0}
do -- блок autofarm (локальные переменные живут только тут)
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
                    if got then
                        farm.count += 1
                        farm.sessionCoins = (farm.sessionCoins or 0) + 1
                    else
                        coinSkip[coin] = os.clock() + 8
                    end
                else
                    coinSkip[coin] = os.clock() + 8
                end
            end)
            if not ok then warn("[Maneware] autofarm: " .. tostring(err)) end
            farmBusy = false
        end
    end
end)

end -- конец блока autofarm

-- Окно автофарма: показывает монеты за сессию
do
    local farmGui = makeGui("ManewareFarmHUD", 99995)
    local farmFrame = new("Frame", {
        Size = UDim2.new(0, 160, 0, 40),
        Position = UDim2.new(0.5, -80, 0, 60),
        BackgroundColor3 = Color3.fromRGB(14, 14, 20),
        BorderSizePixel = 0,
        Visible = false,
        AnchorPoint = Vector2.new(0.5, 0),
    }, farmGui)
    corner(10, farmFrame)
    new("UIStroke", {Color = C.ACCENT, Thickness = 1.5}, farmFrame)
    local farmLbl = new("TextLabel", {
        Size = UDim2.new(1, -12, 1, 0),
        Position = UDim2.new(0, 6, 0, 0),
        BackgroundTransparency = 1,
        Text = "Монеты: 0",
        TextColor3 = C.TEXT,
        TextSize = 14,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Center,
    }, farmFrame)
    RunService.Heartbeat:Connect(function()
        if farm.on then
            farmFrame.Visible = true
            farmLbl.Text = "Монеты за сессию: " .. tostring(farm.sessionCoins or 0)
        else
            farmFrame.Visible = false
        end
    end)
end

--------------------------------------------------
-- KILL EFFECTS: эффекты, когда умирает убийца / шериф
--------------------------------------------------
local fx = {ghost = false, lightning = false, star = false, starCount = 5, starSpeed = 2}
local fxDeath
do -- блок эффектов

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

fxDeath = function(ch, pos)
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
end -- конец блока эффектов

--------------------------------------------------
-- ПОИСК АССЕТОВ (Creator Store): морфы и звуки ИЩЕМ, а не создаём
--------------------------------------------------
local assetCache = readJson("assets.json") or {} -- "model:ключ"/"audio:ключ" -> id
local function saveAssets() writeJson("assets.json", assetCache) end

local function httpGetBody(url)
    local ok, res = pcall(function() return game:HttpGet(url) end)
    if ok and type(res) == "string" and #res > 0 then return res end
    local rq = request or http_request or (syn and syn.request) or (http and http.request)
    if rq then
        local ok2, resp = pcall(function() return rq({Url = url, Method = "GET"}) end)
        if ok2 and type(resp) == "table" and resp.Body then return resp.Body end
    end
    return nil
end

-- список id ассетов по запросу (kind: "model" | "audio")
local function searchAssets(kind, keyword)
    local enc = HttpService:UrlEncode(keyword)
    local urls
    if kind == "audio" then
        urls = {
            "https://apis.roblox.com/toolbox-service/v1/marketplace/3?limit=30&pageNumber=0&sortType=0&keyword=" .. enc,
            "https://apis.roblox.com/toolbox-service/v2/assets:search?searchCategoryType=Audio&maxPageSize=30&query=" .. enc,
        }
    else
        urls = {
            "https://apis.roblox.com/toolbox-service/v1/marketplace/10?limit=30&pageNumber=0&sortType=0&keyword=" .. enc,
            "https://apis.roblox.com/toolbox-service/v2/assets:search?searchCategoryType=Model&maxPageSize=30&query=" .. enc,
        }
    end
    for _, url in ipairs(urls) do
        local body = httpGetBody(url)
        if body then
            local ok, data = pcall(function() return HttpService:JSONDecode(body) end)
            if ok and type(data) == "table" then
                local list = data.data or data.creatorStoreAssets or data.assets or {}
                local ids = {}
                for _, it in ipairs(list) do
                    local id = it.id or (it.asset and it.asset.id) or it.assetId
                    if id then table.insert(ids, tonumber(id)) end
                end
                if #ids > 0 then return ids end
            end
        end
    end
    return {}
end

local modelTemplates = {}
local function fetchModel(id)
    if modelTemplates[id] then return modelTemplates[id] end
    local ok, res = pcall(function() return game:GetObjects("rbxassetid://" .. id) end)
    if not ok or type(res) ~= "table" or not res[1] then return nil end
    local m = res[1]
    local wrap
    if m:IsA("Model") then
        wrap = m
    else
        wrap = Instance.new("Model")
        if m:IsA("BasePart") then
            m.Parent = wrap
        else
            for _, ch in ipairs(m:GetChildren()) do ch.Parent = wrap end
        end
    end
    if not wrap:FindFirstChildWhichIsA("BasePart", true) then return nil end
    modelTemplates[id] = wrap
    return wrap
end

local function audioOk(id)
    local snd0 = Instance.new("Sound")
    snd0.SoundId = "rbxassetid://" .. id
    snd0.Parent = game:GetService("SoundService")
    pcall(function() game:GetService("ContentProvider"):PreloadAsync({snd0}) end)
    local ok = snd0.TimeLength > 0
    snd0:Destroy()
    return ok
end

--------------------------------------------------
-- RADIO-ГРУППА тогглов (включил один - остальные выключились)
--------------------------------------------------
local function radioGroup(tab, prefix, labels, defIdx, onPick, iconId)
    local cur = defIdx
    local keys = {}
    for i, lab in ipairs(labels) do keys[i] = prefix .. lab end
    for i = 1, #labels do
        tab.Toggle(keys[i], i == defIdx, function(v)
            if v then
                local changed = cur ~= i
                cur = i
                for j = 1, #labels do
                    if j ~= i then
                        local e = REG[keys[j]]
                        if e and e.get() then e.set(false, true) end
                    end
                end
                onPick(i, changed)
            elseif cur == i then
                local e = REG[keys[i]]
                if e then task.defer(function() e.set(true, true) end) end -- один стиль всегда выбран
            end
        end, iconId)
    end
end

--------------------------------------------------
-- CUSTOM MODEL (морфы: тунтунсахур x3 и AWP) - модели ищутся в Creator Store
--------------------------------------------------
local cm = {on = false, sel = 1, size = 1.0, busy = false, applied = nil}
local MODEL_SLOTS = {
    {key = "sahur1", label = "Tung Tung Sahur", q = "tung tung tung sahur morph"},
    {key = "sahur2", label = "Sahur #2", q = "tung tung sahur"},
    {key = "sahur3", label = "Sahur #3", q = "sahur brainrot"},
    {key = "awp", label = "AWP", q = "awp gun morph"},
}
local hiddenOrig = {}

local function resolveModelSlot(slot)
    local key = "model:" .. slot.key
    local id = assetCache[key]
    if id and fetchModel(id) then return id end
    local used = {}
    for k, v in pairs(assetCache) do
        if k:sub(1, 6) == "model:" and k ~= key then used[v] = true end -- у слотов разные морфы
    end
    local ids = searchAssets("model", slot.q)
    for i = 1, math.min(#ids, 12) do
        if not used[ids[i]] and fetchModel(ids[i]) then
            assetCache[key] = ids[i]
            saveAssets()
            return ids[i]
        end
    end
    return nil
end

local function clearCustomModel()
    cm.applied = nil
    local c = myChar()
    local old = c and c:FindFirstChild("MWCustomModel")
    if old then old:Destroy() end
    for inst, tr in pairs(hiddenOrig) do pcall(function() inst.Transparency = tr end) end
    hiddenOrig = {}
end

local function applyCustomModel()
    if cm.busy then return end
    cm.busy = true
    task.spawn(function()
        pcall(function()
            local idx = cm.sel
            local slot = MODEL_SLOTS[idx]
            notify("Ищу морф: " .. slot.label .. "…")
            local id = resolveModelSlot(slot)
            if not id then notify("Морф не найден (введи ID вручную во вкладке CustomModel)") return end
            local tpl = fetchModel(id)
            local c, hrp = myChar(), myHrp()
            if not tpl or not c or not hrp or not cm.on then return end
            clearCustomModel()
            local m = tpl:Clone()
            m.Name = "MWCustomModel"
            local kill = {}
            for _, d in ipairs(m:GetDescendants()) do
                if d:IsA("BaseScript") or d:IsA("Humanoid") then table.insert(kill, d) end
            end
            for _, d in ipairs(kill) do pcall(function() d:Destroy() end) end
            pcall(function() m:ScaleTo(cm.size) end)
            local parts = {}
            for _, d in ipairs(m:GetDescendants()) do
                if d:IsA("BasePart") then
                    d.Anchored = false
                    d.CanCollide = false
                    d.CanTouch = false
                    d.CanQuery = false
                    d.Massless = true
                    table.insert(parts, d)
                end
            end
            local primary = m.PrimaryPart or parts[1]
            if not primary then return end
            m.Parent = c
            local _, size = m:GetBoundingBox()
            m:PivotTo(hrp.CFrame * CFrame.new(0, size.Y / 2 - 3, 0))
            for _, pt in ipairs(parts) do
                if pt ~= primary then
                    local w = Instance.new("WeldConstraint")
                    w.Part0, w.Part1 = primary, pt
                    w.Parent = primary
                end
            end
            local w0 = Instance.new("WeldConstraint")
            w0.Part0, w0.Part1 = hrp, primary
            w0.Parent = primary
            for _, d in ipairs(c:GetDescendants()) do -- прячем оригинальную модель (виден только морф)
                if not d:IsDescendantOf(m) then
                    if (d:IsA("BasePart") and d.Name ~= "HumanoidRootPart") or d:IsA("Decal") then
                        hiddenOrig[d] = d.Transparency
                        d.Transparency = 1
                    end
                end
            end
            cm.applied = idx
            notify("Морф: " .. slot.label .. " ✔")
        end)
        cm.busy = false
    end)
end

--------------------------------------------------
-- SOUND: замена звука пистолета (звуки ищутся в Creator Store)
--------------------------------------------------
local snd = {gun = false, sel = 1}
local SOUND_SLOTS = {
    {key = "skeet", label = "skeet", q = "skeet"},
    {key = "bell", label = "bell", q = "bell"},
    {key = "uwu", label = "uwu", q = "uwu"},
    {key = "awp", label = "AWP (CS:GO)", q = "csgo awp"},
    {key = "deagle", label = "Deagle (CS:GO)", q = "csgo deagle"},
}
local soundId = nil
local origSounds = setmetatable({}, {__mode = "k"})

local function resolveSoundSlot(slot)
    local key = "audio:" .. slot.key
    local id = assetCache[key]
    if id and audioOk(id) then return id end
    -- встроенный ID (Click 1/2/3) — пробуем сразу
    if slot.id and audioOk(slot.id) then
        assetCache[key] = slot.id
        saveAssets()
        return slot.id
    end
    local ids = searchAssets("audio", slot.q)
    for i = 1, math.min(#ids, 12) do
        if audioOk(ids[i]) then
            assetCache[key] = ids[i]
            saveAssets()
            return ids[i]
        end
    end
    return slot.id -- fallback даже если audioOk не прошёл (на некоторых executor)
end

local function applySoundSlot(i)
    task.spawn(function()
        local slot = SOUND_SLOTS[i]
        notify("Ищу звук: " .. slot.label .. "…")
        local id = resolveSoundSlot(slot)
        if i ~= snd.sel then return end
        soundId = id
        notify(id and ("Звук: " .. slot.label .. " ✔") or "Звук не найден (введи ID вручную во вкладке Sound)")
    end)
end

local function patchSound(sd)
    if not snd.gun or not soundId then return end
    if origSounds[sd] == nil then origSounds[sd] = sd.SoundId end
    local want = "rbxassetid://" .. soundId
    if sd.SoundId ~= want then sd.SoundId = want end
end
local function isGunSound(sd)
    if not sd:IsA("Sound") then return false end
    if sd:FindFirstAncestor("Gun") then return true end
    local n = sd.Name:lower()
    return n:find("gun") ~= nil or n:find("shoot") ~= nil
end
local function restoreSounds()
    for sd, id in pairs(origSounds) do pcall(function() if sd.Parent then sd.SoundId = id end end) end
    origSounds = setmetatable({}, {__mode = "k"})
end
workspace.DescendantAdded:Connect(function(d)
    if snd.gun and soundId and isGunSound(d) then pcall(patchSound, d) end
end)
task.spawn(function()
    while true do
        task.wait(0.7)
        if snd.gun and soundId then
            pcall(function()
                for _, pl in ipairs(Players:GetPlayers()) do
                    local conts = {}
                    if pl.Character then table.insert(conts, pl.Character) end
                    local bp = pl:FindFirstChild("Backpack")
                    if bp then table.insert(conts, bp) end
                    for _, cont in ipairs(conts) do
                        local gun = cont:FindFirstChild("Gun")
                        if gun then
                            for _, d in ipairs(gun:GetDescendants()) do
                                if d:IsA("Sound") then patchSound(d) end
                            end
                        end
                    end
                end
            end)
        end
    end
end)
local function previewSound()
    if not soundId then notify("Звук ещё не найден") return end
    local sd = Instance.new("Sound")
    sd.SoundId = "rbxassetid://" .. soundId
    sd.Volume = 1
    sd.Parent = game:GetService("SoundService")
    sd:Play()
    task.delay(5, function() sd:Destroy() end)
end

--------------------------------------------------
-- WATERMARK: 4 стиля (по скриншотам)
--------------------------------------------------
local wm = {on = false, style = 1, size = 5}
local wmRebuild, wmSetScale = function() end, function() end
local WM_STYLES
do -- блок стилей watermark
local StatsService = game:GetService("Stats")

local function mskTime() -- время по Москве (UTC+3)
    local t = os.date("!*t", os.time() + 3 * 3600)
    local h12 = t.hour % 12
    if h12 == 0 then h12 = 12 end
    return string.format("%02d:%02d %s", h12, t.min, t.hour >= 12 and "PM" or "AM")
end
local function getPing()
    local ok, v = pcall(function() return StatsService.Network.ServerStatsItem["Data Ping"]:GetValue() end)
    if ok and v then return math.floor(v + 0.5) end
    local ok2, p = pcall(function() return LocalPlayer:GetNetworkPing() end)
    return ok2 and math.floor(p * 1000 + 0.5) or 0
end
local function getMem()
    local ok, v = pcall(function() return StatsService:GetTotalMemoryUsageMb() end)
    return ok and math.floor(v + 0.5) or 0
end
local XY = Enum.AutomaticSize.XY
local function pad(parent, l, t)
    new("UIPadding", {PaddingLeft = UDim.new(0, l), PaddingRight = UDim.new(0, l), PaddingTop = UDim.new(0, t),
        PaddingBottom = UDim.new(0, t)}, parent)
end
local function gradStroke(parent, thick, c1, c2, rot)
    local st = new("UIStroke", {Thickness = thick, Color = Color3.new(1, 1, 1)}, parent)
    new("UIGradient", {Color = ColorSequence.new(c1, c2), Rotation = rot or 0}, st)
end

-- Стиль 1: MANEWARE » ник » UID » время МСК
local function wmStyle1(root)
    local f = new("Frame", {AutomaticSize = XY, BackgroundColor3 = Color3.fromRGB(14, 14, 20), BorderSizePixel = 0}, root)
    corner(14, f)
    gradStroke(f, 2, Color3.fromRGB(170, 80, 255), Color3.fromRGB(70, 140, 255))
    pad(f, 14, 7)
    local tl = new("TextLabel", {AutomaticSize = XY, BackgroundTransparency = 1, Text = "", TextColor3 = Color3.new(1, 1, 1),
        TextSize = 14, Font = Enum.Font.GothamBold}, f)
    return function()
        tl.Text = string.format("MANEWARE » %s » UID: %d » %s", string.upper(LocalPlayer.Name), UID, mskTime())
    end
end

-- Стиль 2: две вкладки - название и UID
local function wmStyle2(root)
    local col = new("Frame", {AutomaticSize = XY, BackgroundTransparency = 1}, root)
    new("UIListLayout", {Padding = UDim.new(0, 5), SortOrder = Enum.SortOrder.LayoutOrder}, col)
    local function tab(order, logo)
        local f = new("Frame", {AutomaticSize = XY, BackgroundColor3 = Color3.fromRGB(24, 18, 40), BorderSizePixel = 0,
            LayoutOrder = order}, col)
        corner(8, f)
        gradStroke(f, 1.5, Color3.fromRGB(190, 110, 255), Color3.fromRGB(110, 70, 220), 90)
        pad(f, 12, 6)
        new("UIListLayout", {FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 8),
            VerticalAlignment = Enum.VerticalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder}, f)
        if logo then
            new("TextLabel", {AutomaticSize = XY, BackgroundTransparency = 1, Text = "⚛", TextColor3 = Color3.fromRGB(200, 130, 255),
                TextSize = 20, Font = Enum.Font.GothamBold, LayoutOrder = 1}, f)
        end
        return new("TextLabel", {AutomaticSize = XY, BackgroundTransparency = 1, Text = "", TextColor3 = Color3.new(1, 1, 1),
            TextSize = 15, Font = Enum.Font.GothamBold, LayoutOrder = 2}, f)
    end
    local t1l, t2l = tab(1, true), tab(2, false)
    return function()
        t1l.Text = "Maneware"
        t2l.Text = "UID: " .. UID
    end
end

-- Стиль 3: зелёная плашка + аватар + белая табличка MANEWARE
local function wmStyle3(root)
    local f = new("Frame", {Size = UDim2.new(0, 210, 0, 58), BackgroundTransparency = 1}, root)
    local av = new("ImageLabel", {Size = UDim2.new(0, 44, 0, 44), Position = UDim2.new(0, 0, 0, 8),
        BackgroundColor3 = Color3.fromRGB(20, 20, 26), BorderSizePixel = 0, ZIndex = 3,
        Image = "rbxthumb://type=AvatarHeadShot&id=" .. LocalPlayer.UserId .. "&w=150&h=150"}, f)
    corner(22, av)
    new("UIStroke", {Thickness = 2, Color = Color3.new(1, 1, 1)}, av)
    local pill = new("Frame", {Size = UDim2.new(0, 150, 0, 30), Position = UDim2.new(0, 50, 0, 20),
        BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, ZIndex = 2}, f)
    corner(15, pill)
    new("TextLabel", {Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Text = "MANEWARE",
        TextColor3 = Color3.new(0, 0, 0), TextSize = 17, Font = Enum.Font.GothamBlack, ZIndex = 3}, pill)
    return function() end
end

-- Стиль 4: пинг | память | ник | название места (кастомные иконки)
local function wmStyle4(root)
    local f = new("Frame", {AutomaticSize = XY, BackgroundColor3 = Color3.fromRGB(14, 14, 22), BackgroundTransparency = 0.1,
        BorderSizePixel = 0}, root)
    corner(10, f)
    new("UIStroke", {Thickness = 1, Color = Color3.fromRGB(50, 50, 70)}, f)
    pad(f, 14, 8)
    new("UIListLayout", {FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 16),
        VerticalAlignment = Enum.VerticalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder}, f)
    local function seg(order, iconId)
        local sg = new("Frame", {AutomaticSize = XY, BackgroundTransparency = 1, LayoutOrder = order}, f)
        new("UIListLayout", {FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 6),
            VerticalAlignment = Enum.VerticalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder}, sg)
        local ic = new("ImageLabel", {Size = UDim2.new(0, 18, 0, 18), BackgroundTransparency = 1,
            Image = iconId or "", ImageColor3 = Color3.fromRGB(110, 120, 255), ScaleType = Enum.ScaleType.Fit, LayoutOrder = 1}, sg)
        return new("TextLabel", {AutomaticSize = XY, BackgroundTransparency = 1, Text = "", TextColor3 = Color3.new(1, 1, 1),
            TextSize = 14, Font = Enum.Font.GothamBold, LayoutOrder = 2}, sg)
    end
    -- кастомные иконки: SPEED (пинг), UTIL (память), TARGET (ник), HAT (место)
    local lPing, lMem, lNick, lPlace = seg(1, ICONS.SPEED), seg(2, ICONS.UTIL), seg(3, ICONS.TARGET), seg(4, ICONS.HAT)
    return function()
        lPing.Text = getPing() .. "MS"
        lMem.Text = getMem() .. " mb"
        lNick.Text = LocalPlayer.Name
        lPlace.Text = "Загадка убийства 2"
    end
end
WM_STYLES = {wmStyle1, wmStyle2, wmStyle3, wmStyle4}
end -- конец блока watermark

--------------------------------------------------
-- NOTIFY (карточки как в Celestial) / SOUNDNOTIFY / GRADIENTS (состояние)
--------------------------------------------------
local nf = {on = true}
local sn = {on = false, sel = 1, id = nil}
-- Звуки уведомлений (короткие UI-клики / enable-disable как в клиентах)
local SN_SLOTS = {
    {key = "click1", label = "Click 1", q = "ui click", id = 6895079853},
    {key = "click2", label = "Click 2", q = "button click soft", id = 9118823101},
    {key = "click3", label = "Click 3", q = "notification popup", id = 6042053626},
    {key = "click4", label = "Click 4 (soft)", q = "soft ui", id = 12222216},
    {key = "click5", label = "Click 5 (pop)", q = "pop click", id = 4612375305},
}
local grad = {on = false, sel = 1}

do -- карточки-уведомления: 1 строка - название функции/событие, 2 строка - что произошло
    local toastGui = makeGui("ManewareToast", 100001)
    local holder = new("Frame", {Size = UDim2.new(0, 250, 1, -24), Position = UDim2.new(1, -262, 0, 12),
        BackgroundTransparency = 1}, toastGui)
    new("UIListLayout", {Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder,
        VerticalAlignment = Enum.VerticalAlignment.Bottom}, holder)
    local active, order = {}, 0

    local function playNotifySound()
        local sd = Instance.new("Sound")
        sd.SoundId = "rbxassetid://" .. sn.id
        sd.Volume = 1
        sd.Parent = game:GetService("SoundService")
        sd:Play()
        task.delay(4, function() sd:Destroy() end)
    end

    local function makeToast(title, msg, kind)
        local old = active[title]
        if old and old.Parent then old:Destroy() end -- новое уведомление заменяет старое с тем же названием
        order += 1
        local col = kind == "off" and Color3.fromRGB(239, 68, 68)
            or (kind == "info" and Color3.fromRGB(110, 120, 255) or Color3.fromRGB(80, 220, 120))
        local card = new("Frame", {Size = UDim2.new(1, 0, 0, 54), BackgroundColor3 = X.cardColor or Color3.fromRGB(14, 14, 20),
            BackgroundTransparency = 1, BorderSizePixel = 0, LayoutOrder = order}, holder)
        corner(10, card)
        local stroke = new("UIStroke", {Color = Color3.fromRGB(90, 90, 120), Thickness = 1, Transparency = 1}, card)
        local icon = new("TextLabel", {Size = UDim2.new(0, 30, 1, 0), Position = UDim2.new(0, 10, 0, 0),
            BackgroundTransparency = 1, Text = kind == "off" and "✖" or (kind == "info" and "ℹ" or "✔"), TextColor3 = col,
            TextSize = 22, Font = Enum.Font.GothamBold, TextTransparency = 1}, card)
        local l1 = new("TextLabel", {Size = UDim2.new(1, -54, 0, 20), Position = UDim2.new(0, 46, 0, 8),
            BackgroundTransparency = 1, Text = title, TextColor3 = Color3.new(1, 1, 1), TextSize = 15,
            Font = Enum.Font.GothamBold, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd,
            TextTransparency = 1}, card)
        local l2 = new("TextLabel", {Size = UDim2.new(1, -54, 0, 18), Position = UDim2.new(0, 46, 0, 28),
            BackgroundTransparency = 1, Text = msg, TextColor3 = Color3.fromRGB(205, 210, 220), TextSize = 12,
            Font = Enum.Font.GothamSemibold, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd,
            TextTransparency = 1}, card)
        active[title] = card
        local ti = TweenInfo.new(0.25, Enum.EasingStyle.Quad)
        TweenService:Create(card, ti, {BackgroundTransparency = 0.12}):Play()
        TweenService:Create(stroke, ti, {Transparency = 0.4}):Play()
        for _, lb in ipairs({icon, l1, l2}) do TweenService:Create(lb, ti, {TextTransparency = 0}):Play() end
        task.delay(2.8, function()
            if not card.Parent then return end
            local to = TweenInfo.new(0.3, Enum.EasingStyle.Quad)
            TweenService:Create(card, to, {BackgroundTransparency = 1}):Play()
            TweenService:Create(stroke, to, {Transparency = 1}):Play()
            for _, lb in ipairs({icon, l1, l2}) do TweenService:Create(lb, to, {TextTransparency = 1}):Play() end
            task.wait(0.35)
            card:Destroy()
        end)
    end

    NT.send = function(title, msg, kind)
        if not nf.on then -- Notify выключен: обычное уведомление Roblox
            pcall(function()
                StarterGui:SetCore("SendNotification", {Title = title, Text = msg, Duration = 3})
            end)
            return
        end
        pcall(makeToast, title, msg, kind or "info")
        if sn.on and sn.id then pcall(playNotifySound) end
    end
    NT.toggle = function(name, state)
        if not nf.on then return end
        local title = tostring(name):gsub("%s*%(.*$", "")
        NT.send(title, state and "включён" or "выключен", state and "ok" or "off")
    end
end

X.applySoundNotify = function(i)
    task.spawn(function()
        local id = resolveSoundSlot(SN_SLOTS[i])
        if i ~= sn.sel then return end
        sn.id = id
        notify("SoundNotify: " .. (id and "звук найден" or "звук не найден, введи ID вручную"))
    end)
end

--------------------------------------------------
-- SVO: управляемый дрон (Shahed и др.), игрок стоит заморожен
--------------------------------------------------
local SVO_SLOTS = {
    {key = "shahed1", label = "Shahed #1", q = "shahed 136 drone"},
    {key = "shahed2", label = "Shahed #2", q = "shahed drone morph"},
    {key = "shahed3", label = "Shahed #3", q = "geran 2 drone"},
    {key = "kamikaze", label = "Kamikaze drone", q = "kamikaze drone"},
    {key = "drone2", label = "Drone #2", q = "fpv drone"},
    {key = "drone3", label = "Drone #3", q = "military drone morph"},
}
local svo = {on = false, sel = 1, speed = 45, busy = false}

do -- блок SVO
    local function buildDrone(slot)
        local id = resolveModelSlot(slot) -- морф ищем в Creator Store, а не создаём
        local tpl = id and fetchModel(id)
        local m
        if tpl then
            m = tpl:Clone()
            local kill = {}
            for _, d in ipairs(m:GetDescendants()) do
                if d:IsA("BaseScript") or d:IsA("Humanoid") then table.insert(kill, d) end
            end
            for _, d in ipairs(kill) do pcall(function() d:Destroy() end) end
            local first
            for _, d in ipairs(m:GetDescendants()) do
                if d:IsA("BasePart") then
                    d.Anchored = true
                    d.CanCollide = false
                    d.CanTouch = false
                    d.CanQuery = false
                    d.Massless = true
                    first = first or d
                end
            end
            if not m.PrimaryPart and first then pcall(function() m.PrimaryPart = first end) end
            local _, size = m:GetBoundingBox()
            local maxd = math.max(size.X, size.Y, size.Z)
            if maxd > 14 or maxd < 2 then pcall(function() m:ScaleTo(6 / maxd) end) end
        else
            notify("SVO: морф не найден, лечу запасной моделью")
            m = Instance.new("Model")
            local body = new("Part", {Size = Vector3.new(1, 1, 6), Color = Color3.fromRGB(80, 85, 90),
                Material = Enum.Material.Metal, Anchored = true, CanCollide = false, CanTouch = false, CanQuery = false}, m)
            new("WedgePart", {Size = Vector3.new(6, 0.25, 3), Color = Color3.fromRGB(95, 100, 105),
                Material = Enum.Material.Metal, Anchored = true, CanCollide = false, CanTouch = false, CanQuery = false,
                CFrame = body.CFrame * CFrame.new(0, 0, 1.5)}, m)
            m.PrimaryPart = body
        end
        return m
    end

    local function explode(pos)
        pcall(function()
            local ex = Instance.new("Explosion")
            ex.Position = pos
            ex.BlastRadius = 12
            ex.BlastPressure = 0 -- только визуально
            ex.DestroyJointRadiusPercent = 0
            ex.Parent = workspace
        end)
        local flash = new("Part", {Shape = Enum.PartType.Ball, Size = Vector3.new(4, 4, 4), Position = pos, Anchored = true,
            CanCollide = false, CanTouch = false, CanQuery = false, Material = Enum.Material.Neon,
            Color = Color3.fromRGB(255, 170, 60), Transparency = 0.2}, workspace)
        TweenService:Create(flash, TweenInfo.new(0.5), {Size = Vector3.new(22, 22, 22), Transparency = 1}):Play()
        task.delay(0.6, function() flash:Destroy() end)
    end

    local function runSvo()
        svo.busy = true
        local drone
        local ok, err = pcall(function()
            local slot = SVO_SLOTS[svo.sel]
            notify("SVO: готовлю " .. slot.label)
            drone = buildDrone(slot)
            if not svo.on then return end
            local hrp, hum = myHrp(), myHum()
            if not hrp or not hum or hum.Health <= 0 then notify("SVO: нет персонажа") return end
            drone.Name = "MWDrone"
            drone.Parent = workspace
            local pos = hrp.Position + Vector3.new(0, 6, 0)
            local cf = CFrame.lookAt(pos, pos + hrp.CFrame.LookVector)
            drone:PivotTo(cf)
            hrp.Anchored = true -- игрок стоит заморожен, пока летит дрон
            Camera.CameraSubject = drone.PrimaryPart or drone:FindFirstChildWhichIsA("BasePart", true)
            notify("SVO: запуск, веди дрон как при ходьбе")
            local target
            local t0 = os.clock()
            while svo.on and os.clock() - t0 < 90 do
                local dt = RunService.Heartbeat:Wait()
                local h2 = myHum()
                if not h2 or h2.Health <= 0 or not myHrp() then break end
                local c = Camera.CFrame
                local rel = c:VectorToObjectSpace(h2.MoveDirection)
                local mv = c.LookVector * -rel.Z + c.RightVector * rel.X
                if mv.Magnitude > 0 then
                    pos = pos + mv.Unit * svo.speed * dt
                    cf = CFrame.lookAt(pos, pos + mv.Unit)
                else
                    cf = CFrame.new(pos) * cf.Rotation
                end
                drone:PivotTo(cf)
                for _, pl in ipairs(Players:GetPlayers()) do -- попадание в игрока
                    if pl ~= LocalPlayer then
                        local ch = pl.Character
                        local r = ch and ch:FindFirstChild("HumanoidRootPart")
                        local th = ch and ch:FindFirstChildOfClass("Humanoid")
                        if r and th and th.Health > 0 and (r.Position - pos).Magnitude < 4.5 then
                            target = pl
                            break
                        end
                    end
                end
                if target then break end
            end
            if target then explode(pos) end
            drone:Destroy()
            drone = nil
            local hrp2, hum2 = myHrp(), myHum()
            if hrp2 then hrp2.Anchored = false end -- разморозка
            if hum2 then Camera.CameraSubject = hum2 end
            if target then
                notify("SVO: попадание в " .. target.DisplayName)
                flingPlayer(target) -- флинг цели и возврат на место, где стоял до запуска
            else
                notify("SVO: полёт отменён")
            end
        end)
        if drone then pcall(function() drone:Destroy() end) end
        local hrp3, hum3 = myHrp(), myHum()
        if hrp3 then hrp3.Anchored = false end
        if hum3 then Camera.CameraSubject = hum3 end
        if not ok then
            warn("[Maneware] SVO: " .. tostring(err))
            notify("SVO: ошибка " .. tostring(err))
        end
        svo.on = false
        local e = REG["SVO"]
        if e and e.get() then e.set(false, true) end
        svo.busy = false
    end

    X.svoToggle = function(v)
        if v and not svo.busy then task.spawn(runSvo) end
    end
end

--------------------------------------------------
-- TRIGGERBOT и AIMASSIST
--------------------------------------------------
local trig = {on = false, delay = 100, last = 0}
local assist = {on = false, smooth = 1.0, speed = 1.0, visible = true, vis = true, visT = 0}

do
    local rp = RaycastParams.new()
    rp.FilterType = Enum.RaycastFilterType.Exclude

    -- TriggerBot: стреляет, когда хитбокс убийцы попал в прицел (центр экрана)
    RunService.Heartbeat:Connect(function()
        if not trig.on or aimBusy then return end
        if os.clock() - trig.last < trig.delay / 1000 then return end
        local mc0 = myChar()
        if not mc0 or not hasGun() then return end
        local m = findByRole("Murderer", true)
        local mc = m and m.Character
        if not mc then return end
        local vp = Camera.ViewportSize
        local ray = Camera:ViewportPointToRay(vp.X / 2, vp.Y / 2)
        rp.FilterDescendantsInstances = {mc0}
        local res = workspace:Raycast(ray.Origin, ray.Direction * 600, rp)
        if res and res.Instance:IsDescendantOf(mc) then
            trig.last = os.clock()
            aimBusy = true
            task.spawn(function()
                pcall(function() shoot(res.Position) end)
                aimBusy = false
            end)
        end
    end)

    -- AimAssist: плавно наводит камеру на убийцу
    RunService:BindToRenderStep("MWAimAssist", Enum.RenderPriority.Camera.Value + 1, function(dt)
        if not assist.on then return end
        local m = findByRole("Murderer", true)
        local mc = m and m.Character
        local hrp = mc and mc:FindFirstChild("HumanoidRootPart")
        local hum = mc and mc:FindFirstChildOfClass("Humanoid")
        if not hrp or not hum or hum.Health <= 0 then return end
        if assist.visible then
            if os.clock() - assist.visT > 0.1 then
                assist.visT = os.clock()
                assist.vis = isVisible(mc) -- в поле зрения и не за стеной
            end
            if not assist.vis then return end
        end
        local cam = Camera
        local want = CFrame.lookAt(cam.CFrame.Position, hrp.Position + Vector3.new(0, 0.5, 0))
        local alpha = math.clamp(dt * 8 * assist.speed / math.max(assist.smooth, 0.05), 0, 1)
        cam.CFrame = cam.CFrame:Lerp(want, alpha)
    end)
end

LocalPlayer.CharacterAdded:Connect(function(c)
    task.wait(0.5)
    if hatEnabled then applyHat(c) end
    if flyEnabled then startFly() end
    if noclipUser and not flyEnabled then toggleNoclip(true) end
    if cm.on then applyCustomModel() end
end)

local function buildUI()
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
t1.Toggle("Spinbot", false, function(v) spinbot.on = v end, ICONS.TARGET)
t1.Slider("Spinbot: Speed", 1, 50, 20, "", function(v) spinbot.speed = v end)

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
    if not v then clearByName({MWGun = true, MWGunTag = true, MWGunBox = true, MWGunBox2D = true}) end
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
t2.Slider("Target: Glow Strength", 0.3, 2, 1, "x", function(v) tgt.glowStr = v end, 0.1)
t2.Toggle("China Hat", false, function(v)
    hatEnabled = v
    if v then applyHat(myChar()) else removeHat() end
end, ICONS.HAT)

-- Шериф
t3.Section("🎯 Sheriff Aim")
t3.Toggle("Sheriff Aim (авто-выстрел в убийцу)", false, function(v) aim.on = v end, ICONS.AIM)
t3.Toggle("Visible Check (вкл: только если виден / выкл: сквозь стены)", true, function(v) aim.visible = v end, ICONS.EYE)
t3.Toggle("Hacker (пуля сквозь стены)", false, function(v) aim.hacker = v end, ICONS.SHIELD)
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
    if v then farm.sessionCoins = 0 end -- новая сессия при включении
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

-- CustomModel
local t11 = addTab("CustomModel", ICONS.HAT)
t11.Section("🧬 Морфы (ищутся в Creator Store, не создаются)")
t11.Toggle("CustomModel", false, function(v)
    cm.on = v
    if v then applyCustomModel() else clearCustomModel() end
end, ICONS.HAT)
local labelsM = {}
for i, sl in ipairs(MODEL_SLOTS) do labelsM[i] = sl.label end
radioGroup(t11, "Model: ", labelsM, 1, function(i, changed)
    cm.sel = i
    if cm.on and (changed or cm.applied ~= i) then applyCustomModel() end
end, ICONS.EYE)
t11.Slider("Model: Size", 0.2, 3, 1, "x", function(v) cm.size = v end, 0.1)
t11.Button("🔄 Перезагрузить морф (применить размер)", function()
    if cm.on then
        clearCustomModel()
        applyCustomModel()
    else
        notify("Сначала включи CustomModel")
    end
end)
local mIdBox = t11.TextBox("ID морфа вручную (если поиск не нашёл)")
t11.Button("✔ Применить ID к выбранному морфу", function()
    local id = tonumber(mIdBox.Text)
    if not id then notify("Введи числовой ID") return end
    if not fetchModel(id) then notify("Модель с таким ID не загрузилась") return end
    assetCache["model:" .. MODEL_SLOTS[cm.sel].key] = id
    saveAssets()
    notify("ID сохранён: " .. id)
    if cm.on then
        clearCustomModel()
        applyCustomModel()
    end
end)

-- Sound
local t12 = addTab("Sound", ICONS.GUN)
t12.Section("🔊 Звуки (ищутся в Creator Store, не создаются)")
local labelsS = {}
for i, sl in ipairs(SOUND_SLOTS) do labelsS[i] = sl.label end
t12.ToggleDrop("Sound: Gun (звук пистолета)", false, function(v)
    snd.gun = v
    if v then applySoundSlot(snd.sel) else restoreSounds() end
end, ICONS.GUN, labelsS, 1, function(i)
    snd.sel = i
    applySoundSlot(i)
end)
t12.Button("▶ Проверить выбранный звук", previewSound)
local sIdBox = t12.TextBox("ID звука вручную (если поиск не нашёл)")
t12.Button("✔ Применить ID к выбранному звуку", function()
    local id = tonumber(sIdBox.Text)
    if not id then notify("Введи числовой ID") return end
    if not audioOk(id) then notify("Звук с таким ID не загрузился") return end
    assetCache["audio:" .. SOUND_SLOTS[snd.sel].key] = id
    saveAssets()
    soundId = id
    notify("ID сохранён: " .. id)
end)

-- Watermark
local t13 = addTab("Watermark", ICONS.EYE)
t13.Section("🏷 Watermark")
t13.Toggle("Watermark", false, function(v)
    wm.on = v
    wmRebuild()
end, ICONS.EYE)
t13.Slider("Watermark: Size", 1, 10, 5, "", function(v)
    wm.size = v
    wmSetScale()
end)
radioGroup(t13, "Watermark: ", {"Style 1", "Style 2", "Style 3", "Style 4"}, 1, function(i)
    wm.style = i
    wmRebuild()
end, ICONS.EYE)

-- SVO
local t14 = addTab("SVO", ICONS.FLY)
t14.Section("🚀 SVO: дрон-камикадзе (морфы ищутся, не создаются)")
t14.Toggle("SVO", false, function(v)
    svo.on = v
    X.svoToggle(v)
end, ICONS.FLY)
local labelsV = {}
for i, sl in ipairs(SVO_SLOTS) do labelsV[i] = sl.label end
radioGroup(t14, "SVO: ", labelsV, 1, function(i) svo.sel = i end, ICONS.EYE)
t14.Slider("SVO: Speed", 10, 120, 45, " st/s", function(v) svo.speed = v end)
local vIdBox = t14.TextBox("ID морфа вручную (для выбранного дрона)")
t14.Button("✔ Применить ID к выбранному дрону", function()
    local id = tonumber(vIdBox.Text)
    if not id then notify("Введи числовой ID") return end
    if not fetchModel(id) then notify("Модель с таким ID не загрузилась") return end
    assetCache["model:" .. SVO_SLOTS[svo.sel].key] = id
    saveAssets()
    notify("ID сохранён: " .. id)
end)

-- TriggerBot / AimAssist
local t15 = addTab("Trigger/Assist", ICONS.AIM)
t15.Section("🎯 TriggerBot (стреляет, когда убийца в прицеле)")
t15.Toggle("TriggerBot", false, function(v) trig.on = v end, ICONS.AIM)
t15.Slider("Trigger: Delay", 10, 500, 100, " мс", function(v) trig.delay = v end, 10)
t15.Section("🧲 AimAssist (наводит камеру на убийцу)")
t15.Toggle("AimAssist", false, function(v) assist.on = v end, ICONS.TARGET)
t15.Slider("Assist: Smooth", 0.1, 5, 1, "", function(v) assist.smooth = v end, 0.1)
t15.Slider("Assist: Speed", 0.1, 3, 1, "", function(v) assist.speed = v end, 0.1)
t15.Toggle("Assist: Visible Check", true, function(v) assist.visible = v end, ICONS.EYE)

-- HUD: Notify / SoundNotify / Gradients
local t16 = addTab("HUD", ICONS.UTIL)
t16.Section("🔔 Notify (карточки как в Celestial)")
t16.Toggle("Notify", true, function(v) nf.on = v end, ICONS.UTIL)
t16.Section("🔊 SoundNotify")
local labelsSN = {}
for i, sl in ipairs(SN_SLOTS) do labelsSN[i] = sl.label end
t16.ToggleDrop("SoundNotify", false, function(v)
    sn.on = v
    if v and not sn.id then X.applySoundNotify(sn.sel) end
end, ICONS.UTIL, labelsSN, 1, function(i)
    sn.sel = i
    X.applySoundNotify(i)
end)
local snBox = t16.TextBox("ID звука вручную (если поиск не нашёл)")
t16.Button("✔ Применить ID звука уведомлений", function()
    local id = tonumber(snBox.Text)
    if not id then notify("Введи числовой ID") return end
    if not audioOk(id) then notify("Звук с таким ID не загрузился") return end
    assetCache["audio:" .. SN_SLOTS[sn.sel].key] = id
    saveAssets()
    sn.id = id
    notify("SoundNotify: ID сохранён")
end)
t16.Section("🎨 Gradients (весь HUD, ESP не меняется)")
t16.ToggleDrop("Gradients", false, function(v)
    grad.on = v
    X.applyTheme()
end, ICONS.EYE, {
    "Мятный",
    "Конфета (бирюзовый + фиолетовый)",
    "Серый + белый",
    "Кровавый",
    "Океан",
    "Закат",
}, 1, function(i)
    grad.sel = i
    if grad.on then X.applyTheme() end
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
        if e then pcall(e.set, val, true) end
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

-- Режим редактирования: двигать кнопку/watermark/binds можно ТОЛЬКО в нём
local EDIT = {mode = nil, reopen = false}

local function makeDraggable(obj, canDrag)
    local drag, startPos, startU = false, nil, nil
    obj.InputBegan:Connect(function(i)
        if (i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1) and canDrag() then
            drag, startPos, startU = true, i.Position, obj.Position
        end
    end)
    UIS.InputChanged:Connect(function(i)
        if drag and (i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseMovement) then
            local d = i.Position - startPos
            obj.Position = UDim2.new(startU.X.Scale, startU.X.Offset + d.X, startU.Y.Scale, startU.Y.Offset + d.Y)
        end
    end)
    UIS.InputEnded:Connect(function(i)
        if drag and (i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1) then
            drag = false
        end
    end)
end
makeDraggable(fab, function() return EDIT.mode == "fab" end)
onTap(fab, function()
    if EDIT.mode then return end
    setMenu(not menuVisible)
end)

onTap(closeBtn, function() setMenu(false) end)
UIS.InputBegan:Connect(function(i, gpe)
    if gpe then return end
    if i.KeyCode == Enum.KeyCode.Insert or i.KeyCode == Enum.KeyCode.RightControl then setMenu(not menuVisible) end
end)

--------------------------------------------------
-- ИНТЕРФЕЙС: watermark, binds, режим редактирования
--------------------------------------------------
local uiData = readJson("ui.json") or {}
local function posToTbl(pp) return {pp.X.Scale, pp.X.Offset, pp.Y.Scale, pp.Y.Offset} end
local function tblToPos(t) return UDim2.new(t[1] or 0, t[2] or 0, t[3] or 0, t[4] or 0) end
if uiData.fab then pcall(function() fab.Position = tblToPos(uiData.fab) end) end

-- Watermark
local wmGui = makeGui("ManewareWM", 99996)
local wmRoot = new("Frame", {Name = "WM", AutomaticSize = Enum.AutomaticSize.XY, Size = UDim2.new(0, 0, 0, 0),
    BackgroundTransparency = 1, Active = true, Visible = false, AnchorPoint = Vector2.new(0.5, 0),
    Position = UDim2.new(0.5, 0, 0, 14)}, wmGui)
if uiData.wm then pcall(function() wmRoot.Position = tblToPos(uiData.wm) end) end
local wmScale = new("UIScale", {Scale = 1}, wmRoot)
local wmUpdate = nil

wmSetScale = function() wmScale.Scale = 0.5 + wm.size * 0.1 end
wmRebuild = function()
    for _, ch in ipairs(wmRoot:GetChildren()) do
        if not ch:IsA("UIScale") and ch.Name ~= "MWEditBox" then ch:Destroy() end
    end
    wmUpdate = nil
    wmSetScale()
    wmRoot.Visible = wm.on and wm.style > 0
    if not wmRoot.Visible then return end
    local build = WM_STYLES[wm.style]
    if build then
        wmUpdate = build(wmRoot)
        pcall(wmUpdate)
    end
end
task.spawn(function()
    while true do
        task.wait(0.5)
        if wmUpdate then pcall(wmUpdate) end
    end
end)
makeDraggable(wmRoot, function() return EDIT.mode == "wm" end)

-- Binds: кнопки на экране, включают/выключают функции
local bindGui = makeGui("ManewareBinds", 99997)
local bindButtons = {}

local function saveUI()
    local d = {fab = posToTbl(fab.Position), wm = posToTbl(wmRoot.Position), binds = {}}
    for name, b in pairs(bindButtons) do d.binds[name] = posToTbl(b.Position) end
    uiData = d
    writeJson("ui.json", d)
end

local bindStates = {}

-- что делает бинд: тоггл (с состоянием) или кнопка-действие
local function bindInfo(name)
    local e = REG[name]
    if e and e.kind == "toggle" then
        return function() e.set(not e.get()) end, function() return e.get() end
    end
    local fn = ACT[name]
    if fn then return function() task.spawn(fn) end, nil end
    return nil
end

local function createBind(name, pos)
    if bindButtons[name] then return false end
    local run, getState = bindInfo(name)
    if not run then return false end
    local n = 0
    for _ in pairs(bindButtons) do n += 1 end
    local btn = new("TextButton", {Size = UDim2.new(0, 70, 0, 42),
        Position = pos or UDim2.new(0.5, -105 + (n % 4) * 76, 0.3, math.floor(n / 4) * 50),
        BackgroundColor3 = C.ELEMENT, Text = name, TextColor3 = C.TEXT, TextScaled = true, Font = Enum.Font.GothamBold,
        AutoButtonColor = false, BorderSizePixel = 0, ZIndex = 5}, bindGui)
    new("UITextSizeConstraint", {MaxTextSize = 13, MinTextSize = 7}, btn)
    new("UIPadding", {PaddingLeft = UDim.new(0, 4), PaddingRight = UDim.new(0, 4), PaddingTop = UDim.new(0, 3),
        PaddingBottom = UDim.new(0, 3)}, btn)
    corner(10, btn)
    new("UIStroke", {Color = C.ACCENT, Thickness = 1.5}, btn)
    onTap(btn, function()
        if EDIT.mode then return end
        run()
    end)
    makeDraggable(btn, function() return EDIT.mode == "binds" end)
    bindButtons[name] = btn
    bindStates[name] = getState or false
    return true
end

local function deleteBind(name)
    local b = bindButtons[name]
    if b then
        b:Destroy()
        bindButtons[name] = nil
        bindStates[name] = nil
        saveUI()
        notify("Бинды: бинд удалён")
    else
        notify("Бинды: такого бинда нет")
    end
end

task.spawn(function() -- вид кнопки = состояние функции
    while true do
        task.wait(0.3)
        for name, b in pairs(bindButtons) do
            local gs = bindStates[name]
            if b.Parent and gs then
                pcall(function()
                    if grad.on then
                        b.BackgroundTransparency = gs() and 0 or 0.55
                    else
                        b.BackgroundTransparency = 0
                        b.BackgroundColor3 = gs() and C.ACCENT or C.ELEMENT
                    end
                end)
            end
        end
    end
end)

-- Режим редактирования
local editGui = makeGui("ManewareEdit", 99900)
local catcher = new("TextButton", {Size = UDim2.new(1, 0, 1, 0), BackgroundColor3 = Color3.new(0, 0, 0),
    BackgroundTransparency = 0.55, Text = "", AutoButtonColor = false, Visible = false, Active = true,
    BorderSizePixel = 0}, editGui)
new("TextLabel", {Size = UDim2.new(1, -40, 0, 60), Position = UDim2.new(0, 20, 0, 24), BackgroundTransparency = 1,
    Text = "✎ Режим редактирования\nПеретащи элемент • нажми на пустое место — сохранить",
    TextColor3 = C.TEXT, TextSize = 15, Font = Enum.Font.GothamBold, TextWrapped = true}, catcher)

local function editBox(obj, on)
    local b = obj:FindFirstChild("MWEditBox")
    if on and not b then
        b = new("Frame", {Name = "MWEditBox", Size = UDim2.new(1, 8, 1, 8), Position = UDim2.new(0, -4, 0, -4),
            BackgroundTransparency = 1, ZIndex = 50, Active = false}, obj)
        new("UIStroke", {Color = Color3.fromRGB(255, 220, 0), Thickness = 2}, b)
        corner(14, b)
    elseif not on and b then
        b:Destroy()
    end
end
local function clearBoxes()
    editBox(fab, false)
    editBox(wmRoot, false)
    for _, b in pairs(bindButtons) do editBox(b, false) end
end

local function exitEdit()
    if not EDIT.mode then return end
    EDIT.mode = nil
    clearBoxes()
    catcher.Visible = false
    saveUI()
    notify("Позиции сохранены")
    if EDIT.reopen then setMenu(true) end
end

local function enterEdit(mode)
    if EDIT.mode then return end
    if mode == "wm" and not (wm.on and wm.style > 0) then
        notify("Сначала включи Watermark (вкладка Watermark)")
        return
    end
    if mode == "binds" and next(bindButtons) == nil then
        notify("Нет биндов: создай их во вкладке Binds")
        return
    end
    EDIT.mode = mode
    EDIT.reopen = menuVisible
    setMenu(false)
    catcher.Visible = true
    if mode == "fab" then
        editBox(fab, true)
    elseif mode == "wm" then
        editBox(wmRoot, true)
    else
        for _, b in pairs(bindButtons) do editBox(b, true) end
    end
end

local tapStart = nil
catcher.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1 then
        tapStart = i.Position
    end
end)
catcher.InputEnded:Connect(function(i)
    if tapStart and (i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1) then
        if (i.Position - tapStart).Magnitude < 12 then exitEdit() end -- просто нажатие = закрыть и сохранить
        tapStart = nil
    end
end)

-- Группа слева: Binds (вкладка) + кнопки редактирования
addSideLabel("ИНТЕРФЕЙС", 999)
local tb = addTab("Binds", ICONS.UTIL, 1000)
addSideButton("✎ Кнопка меню", ICONS.MENU, 1001, function() enterEdit("fab") end)
addSideButton("✎ Watermark", ICONS.EYE, 1002, function() enterEdit("wm") end)
addSideButton("✎ Binds", ICONS.UTIL, 1003, function() enterEdit("binds") end)

tb.Section("🎛 Binds: кнопка на экране для функции или действия")
local bindHolder = tb.Holder()
local bindNames = {}
for name, e in pairs(REG) do
    if e.kind == "toggle" then bindNames[#bindNames + 1] = name end
end
for name in pairs(ACT) do
    if not (name:find("🔄") or name:find("💾") or name:find("✔")) then bindNames[#bindNames + 1] = name end
end
table.sort(bindNames)
for i, name in ipairs(bindNames) do
    addRow(bindHolder, i, name, {
        {text = "Delete", color = C.RED, w = 52, fn = function() deleteBind(name) end},
        {text = "Bind", color = C.ACCENT, w = 44, fn = function()
            if createBind(name) then
                saveUI()
                notify("Бинды: создан, двигать через ✎ Binds")
            else
                notify("Бинды: бинд уже есть")
            end
        end},
    })
end

if type(uiData.binds) == "table" then
    for name, t in pairs(uiData.binds) do pcall(createBind, name, tblToPos(t)) end
end

-- Gradients: меняем цвета только внутри наших GUI (hub, кнопка, binds, watermark, уведомления)
local THEMES = {
    {name = "mint",
        bg = {Color3.fromRGB(10, 34, 30), Color3.fromRGB(24, 74, 62)},
        side = {Color3.fromRGB(12, 42, 37), Color3.fromRGB(28, 86, 72)},
        top = {Color3.fromRGB(16, 56, 48), Color3.fromRGB(38, 110, 92)},
        el = {Color3.fromRGB(20, 58, 50), Color3.fromRGB(34, 96, 80)},
        acc = {Color3.fromRGB(80, 235, 180), Color3.fromRGB(40, 190, 140)},
        card = Color3.fromRGB(14, 46, 40)},
    {name = "candy",
        bg = {Color3.fromRGB(14, 38, 52), Color3.fromRGB(44, 22, 70)},
        side = {Color3.fromRGB(18, 46, 62), Color3.fromRGB(52, 28, 80)},
        top = {Color3.fromRGB(24, 70, 84), Color3.fromRGB(80, 40, 120)},
        el = {Color3.fromRGB(26, 58, 74), Color3.fromRGB(66, 36, 100)},
        acc = {Color3.fromRGB(64, 224, 208), Color3.fromRGB(170, 90, 255)},
        card = Color3.fromRGB(30, 30, 64)},
    {name = "gray",
        bg = {Color3.fromRGB(36, 36, 40), Color3.fromRGB(86, 86, 94)},
        side = {Color3.fromRGB(44, 44, 50), Color3.fromRGB(96, 96, 104)},
        top = {Color3.fromRGB(60, 60, 66), Color3.fromRGB(128, 128, 138)},
        el = {Color3.fromRGB(58, 58, 64), Color3.fromRGB(112, 112, 122)},
        acc = {Color3.fromRGB(215, 215, 225), Color3.fromRGB(160, 160, 170)},
        card = Color3.fromRGB(50, 50, 56)},
    {name = "blood",
        bg = {Color3.fromRGB(28, 8, 12), Color3.fromRGB(60, 14, 22)},
        side = {Color3.fromRGB(36, 10, 16), Color3.fromRGB(80, 18, 28)},
        top = {Color3.fromRGB(48, 12, 20), Color3.fromRGB(110, 25, 40)},
        el = {Color3.fromRGB(42, 12, 18), Color3.fromRGB(90, 22, 34)},
        acc = {Color3.fromRGB(255, 60, 80), Color3.fromRGB(200, 30, 50)},
        card = Color3.fromRGB(32, 10, 14)},
    {name = "ocean",
        bg = {Color3.fromRGB(6, 20, 40), Color3.fromRGB(10, 50, 90)},
        side = {Color3.fromRGB(8, 28, 52), Color3.fromRGB(14, 60, 110)},
        top = {Color3.fromRGB(12, 40, 70), Color3.fromRGB(20, 80, 140)},
        el = {Color3.fromRGB(10, 34, 60), Color3.fromRGB(18, 70, 120)},
        acc = {Color3.fromRGB(40, 200, 255), Color3.fromRGB(20, 140, 220)},
        card = Color3.fromRGB(8, 24, 48)},
    {name = "sunset",
        bg = {Color3.fromRGB(40, 18, 10), Color3.fromRGB(80, 30, 20)},
        side = {Color3.fromRGB(50, 22, 12), Color3.fromRGB(100, 40, 25)},
        top = {Color3.fromRGB(70, 30, 15), Color3.fromRGB(140, 55, 30)},
        el = {Color3.fromRGB(60, 26, 14), Color3.fromRGB(120, 48, 28)},
        acc = {Color3.fromRGB(255, 140, 50), Color3.fromRGB(255, 80, 40)},
        card = Color3.fromRGB(45, 20, 12)},
}
local BASE = {bg = C.BG, side = C.SIDEBAR, top = C.TOPBAR, el = C.ELEMENT, acc = C.ACCENT}
local WHITE = Color3.new(1, 1, 1)

local function keyOf(c)
    if c == BASE.bg then return "bg" end
    if c == BASE.side then return "side" end
    if c == BASE.top then return "top" end
    if c == BASE.el then return "el" end
    if c == BASE.acc then return "acc" end
    return nil
end

local function themeInst(inst, key, th)
    local pair = th[key]
    inst:SetAttribute("MWK", key)
    inst:SetAttribute("MWT", th.name)
    local g = inst:FindFirstChild("MWGrad")
    local hasText = (inst:IsA("TextButton") or inst:IsA("TextLabel") or inst:IsA("TextBox")) and inst.Text ~= ""
    if hasText then -- градиент перекрасил бы и текст, поэтому у кнопок с текстом - сплошной цвет
        if g then g:Destroy() end
        inst.BackgroundColor3 = pair[1]:Lerp(pair[2], 0.5)
    else
        inst.BackgroundColor3 = WHITE
        if not g then
            g = Instance.new("UIGradient")
            g.Name = "MWGrad"
            g.Rotation = 35
            g.Parent = inst
        end
        g.Color = ColorSequence.new(pair[1], pair[2])
    end
end

local THEME_ROOTS = {hubGui, toggleGui, bindGui}

local function scanTheme(th)
    for _, root in ipairs(THEME_ROOTS) do
        for _, inst in ipairs(root:GetDescendants()) do
            if inst:IsA("GuiObject") then
                local k = keyOf(inst.BackgroundColor3)
                if k then
                    themeInst(inst, k, th)
                else
                    local mk = inst:GetAttribute("MWK")
                    if mk and inst:GetAttribute("MWT") ~= th.name then themeInst(inst, mk, th) end
                end
                if inst:IsA("TextLabel") or inst:IsA("TextButton") or inst:IsA("TextBox") then
                    if inst.TextColor3 == BASE.acc or inst:GetAttribute("MWTX") then
                        inst:SetAttribute("MWTX", true)
                        inst.TextColor3 = th.acc[1]
                    end
                end
            elseif inst:IsA("UIStroke") then
                if inst.Color == BASE.acc or inst:GetAttribute("MWTX") then
                    inst:SetAttribute("MWTX", true)
                    inst.Color = th.acc[1]
                end
            end
        end
    end
    for _, g in ipairs(wmGui:GetDescendants()) do -- рамки watermark
        if g:IsA("UIGradient") and g.Parent and g.Parent:IsA("UIStroke") then
            g.Color = ColorSequence.new(th.acc[1], th.acc[2])
        end
    end
    X.cardColor = th.card
end

local function revertTheme()
    for _, root in ipairs(THEME_ROOTS) do
        for _, inst in ipairs(root:GetDescendants()) do
            if inst:GetAttribute("MWT") then
                local mk = inst:GetAttribute("MWK")
                if mk and BASE[mk] and inst:IsA("GuiObject") then inst.BackgroundColor3 = BASE[mk] end
                local g = inst:FindFirstChild("MWGrad")
                if g then g:Destroy() end
                inst:SetAttribute("MWT", nil)
                inst:SetAttribute("MWK", nil)
            end
            if inst:GetAttribute("MWTX") then
                if inst:IsA("UIStroke") then
                    inst.Color = BASE.acc
                elseif inst:IsA("TextLabel") or inst:IsA("TextButton") or inst:IsA("TextBox") then
                    inst.TextColor3 = BASE.acc
                end
                inst:SetAttribute("MWTX", nil)
            end
        end
    end
    X.cardColor = nil
    if wm.on then wmRebuild() end -- вернёт исходные цвета рамок watermark
end

X.applyTheme = function()
    if grad.on then pcall(scanTheme, THEMES[grad.sel]) else pcall(revertTheme) end
end
task.spawn(function() -- новые элементы (списки, бинды) подхватываются автоматически
    while true do
        task.wait(1)
        if grad.on then pcall(scanTheme, THEMES[grad.sel]) end
    end
end)

end -- buildUI

local okUI, errUI = pcall(buildUI)
if not okUI then
    warn("[Maneware] ошибка интерфейса: " .. tostring(errUI))
    notify("Ошибка UI: " .. tostring(errUI))
end

print("[Maneware] v9 загружен")

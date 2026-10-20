--=====================================================================
--  VENICE HUB  •  v1.0.0  •  NOIR EDITION
--  UI custom noir & blanc ultra-moderne  |  Background anime animé
--  Support : Universel + "Shoot For Eggs" (135911818477576)
--  Keybind : E   |  PC uniquement
--=====================================================================

local HUB_NAME     = "Venice Hub"
local HUB_VERSION  = "1.0.0"
local HUB_VER_URL  = "https://raw.githubusercontent.com/TON_USER/TON_REPO/main/version.txt"
local CONFIG_FILE  = "VeniceHub_Config.json"

local GENV = (getgenv and getgenv()) or _G
if GENV.VeniceHub and GENV.VeniceHub.Destroy then pcall(GENV.VeniceHub.Destroy) end

local Players        = game:GetService("Players")
local RunService     = game:GetService("RunService")
local UIS            = game:GetService("UserInputService")
local TweenService   = game:GetService("TweenService")
local HttpService    = game:GetService("HttpService")
local Lighting       = game:GetService("Lighting")
local Workspace      = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService   = game:GetService("TeleportService")
local VIM            = game:GetService("VirtualInputManager")
local VirtualUser    = game:GetService("VirtualUser")
local ContentProvider = game:GetService("ContentProvider")
local Stats          = game:GetService("Stats")

local LP = Players.LocalPlayer

local function getCam() return Workspace.CurrentCamera end

--=====================================================================
-- 1. UTILS
--=====================================================================
local Conn = {}
local function bind(conn)
	if conn then Conn[#Conn+1] = conn end
	return conn
end

local function getChar() return LP.Character end
local function getHRP()
	local c = LP.Character
	return c and c:FindFirstChild("HumanoidRootPart")
end
local function getHum()
	local c = LP.Character
	return c and c:FindFirstChildOfClass("Humanoid")
end

local function tpTo(pos, up)
	local hrp = getHRP() if not hrp then return end
	hrp.CFrame = CFrame.new(pos + Vector3.new(0, up or 3, 0))
end

local function tpNear(pos, dist)
	local hrp = getHRP() if not hrp then return end
	local dir = (hrp.Position - pos)
	dir = Vector3.new(dir.X, 0, dir.Z)
	if dir.Magnitude < 0.1 then dir = Vector3.new(1,0,0) end
	hrp.CFrame = CFrame.new(pos + dir.Unit * (dist or 4) + Vector3.new(0, 3, 0))
end

local function fmt(n)
	n = tonumber(n) or 0
	if n >= 1e12 then return string.format("%.2fT", n/1e12) end
	if n >= 1e9  then return string.format("%.2fB", n/1e9) end
	if n >= 1e6  then return string.format("%.2fM", n/1e6) end
	if n >= 1e3  then return string.format("%.1fK", n/1e3) end
	return tostring(math.floor(n))
end

--=====================================================================
-- 2. ÉTAT
--=====================================================================
local Flags = {}
local Binds = {}
local Setters = {}
local Registry = {}
local Sections = {}
local Tabs = {}
local CurrentTab = nil

--=====================================================================
-- 3. THÈME
--=====================================================================
local Theme = {
	bg         = Color3.fromRGB(6,6,7),
	panel      = Color3.fromRGB(11,11,13),
	panel2     = Color3.fromRGB(16,16,19),
	elem       = Color3.fromRGB(20,20,23),
	elemHov    = Color3.fromRGB(30,30,34),
	stroke     = Color3.fromRGB(40,40,45),
	strokeHov  = Color3.fromRGB(100,100,108),
	text       = Color3.fromRGB(240,240,242),
	textDim    = Color3.fromRGB(138,138,146),
	accent     = Color3.fromRGB(255,255,255),
	accentText = Color3.fromRGB(10,10,12),
	off        = Color3.fromRGB(90,90,96),
	rowAlt     = Color3.fromRGB(14,14,16),
}
local ThemeLight = {
	bg         = Color3.fromRGB(246,246,248),
	panel      = Color3.fromRGB(252,252,254),
	panel2     = Color3.fromRGB(250,250,251),
	elem       = Color3.fromRGB(235,235,239),
	elemHov    = Color3.fromRGB(224,224,229),
	stroke     = Color3.fromRGB(208,208,214),
	strokeHov  = Color3.fromRGB(150,150,158),
	text       = Color3.fromRGB(18,18,21),
	textDim    = Color3.fromRGB(112,112,121),
	accent     = Color3.fromRGB(22,22,26),
	accentText = Color3.fromRGB(253,253,255),
	off        = Color3.fromRGB(172,172,180),
	rowAlt     = Color3.fromRGB(244,244,246),
}

local FONT  = Enum.Font.GothamBold
local FONT2 = Enum.Font.Gotham

--=====================================================================
-- 4. HELPERS UI
--=====================================================================
local function new(class, props, children)
	local inst = Instance.new(class)
	if props then
		for k, v in pairs(props) do
			if k ~= "Parent" then inst[k] = v end
		end
	end
	if children then
		for _, c in ipairs(children) do c.Parent = inst end
	end
	if props and props.Parent then inst.Parent = props.Parent end
	return inst
end

local function corner(p, r)
	return new("UICorner", {CornerRadius = UDim.new(0, r or 8), Parent = p})
end
local function stroke(p, col, th, tr)
	return new("UIStroke", {
		Color = col or Theme.stroke, Thickness = th or 1, Transparency = tr or 0,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = p
	})
end
local function pad(p, t, r, b, l)
	return new("UIPadding", {
		PaddingTop = UDim.new(0, t), PaddingRight = UDim.new(0, r),
		PaddingBottom = UDim.new(0, b), PaddingLeft = UDim.new(0, l), Parent = p
	})
end

local function hover(btn, normal, hoverCol)
	btn.BackgroundColor3 = normal
	bind(btn.MouseEnter:Connect(function()
		TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = hoverCol}):Play()
	end))
	bind(btn.MouseLeave:Connect(function()
		TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = normal}):Play()
	end))
end

--=====================================================================
-- 5. ROOT GUI
--=====================================================================
local function guiParent()
	if gethui then
		local ok, h = pcall(gethui)
		if ok and h then return h end
	end
	local ok2, cg = pcall(function() return game:GetService("CoreGui") end)
	if ok2 and cg then return cg end
	return LP:WaitForChild("PlayerGui")
end

local Screen = new("ScreenGui", {
	Name = "VeniceHub",
	ResetOnSpawn = false,
	IgnoreGuiInset = true,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	DisplayOrder = 9999,
	Parent = guiParent(),
})

local Root = new("Frame", {
	Name = "Root", Parent = Screen,
	Size = UDim2.fromScale(1,1), BackgroundTransparency = 1,
	Visible = true,
})

--=====================================================================
-- 6. BACKGROUND ANIME ANIMÉ
--=====================================================================
local BG = new("Frame", {
	Name = "BG", Parent = Root,
	Size = UDim2.fromScale(1,1), BackgroundColor3 = Color3.new(0,0,0),
	BorderSizePixel = 0, ClipsDescendants = true, Visible = true,
})

local BG_IMAGES = {
	-- aesthetic / paysages anime
	5252447904, 6675147490, 10341849885, 8652665149, 3674739835,
	5191098772, 3343076822, 3321127511, 5180300644, 4880579497,
	3131549391, 3290453459,
	-- personnages
	6942501530, 9657394390, 9478562327, 10511856020, 11759193017,
	6239940100, 5444301611, 11778372953, 6479589870, 8982623704,
}
local CustomBG = {}

local bgA = new("ImageLabel", {Parent=BG, Size=UDim2.fromScale(1.25,1.25), Position=UDim2.fromScale(-0.125,-0.125),
	BackgroundTransparency=1, BorderSizePixel=0, ImageTransparency=0.35, ScaleType=Enum.ScaleType.Crop})
local bgB = new("ImageLabel", {Parent=BG, Size=UDim2.fromScale(1.25,1.25), Position=UDim2.fromScale(-0.125,-0.125),
	BackgroundTransparency=1, BorderSizePixel=0, ImageTransparency=1, ScaleType=Enum.ScaleType.Crop})

-- voile d'assombrissement (mute la couleur => rendu B&W)
local veil = new("Frame", {Parent=BG, Size=UDim2.fromScale(1,1), BackgroundColor3=Color3.new(0,0,0),
	BackgroundTransparency=0.45, BorderSizePixel=0, ZIndex=5})

-- dégradé qui bouge
local gradHolder = new("Frame", {Parent=BG, Size=UDim2.fromScale(1,1), BackgroundTransparency=1, ZIndex=6})
local grad = new("UIGradient", {
	Parent = gradHolder,
	Rotation = 120,
	Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(0,0,0)),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0,0,0)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(0,0,0)),
	}),
	Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.15),
		NumberSequenceKeypoint.new(0.55, 0.85),
		NumberSequenceKeypoint.new(1, 0.15),
	}),
})

-- particules flottantes
local particles = {}
for i = 1, 16 do
	local p = new("Frame", {
		Parent = BG, ZIndex = 7,
		BackgroundColor3 = Color3.fromRGB(255,255,255),
		BackgroundTransparency = math.random(70,92)/100,
		Size = UDim2.fromOffset(math.random(2,5), math.random(2,5)),
		Position = UDim2.fromScale(math.random(), math.random()),
		BorderSizePixel = 0,
	})
	corner(p, 99)
	particles[#particles+1] = p
end

-- balayage lumineux
local sweep = new("Frame", {Parent=BG, Size=UDim2.new(1,0,0,2), Position=UDim2.new(0,0,0,-10),
	BackgroundColor3=Color3.fromRGB(255,255,255), BackgroundTransparency=0.75, BorderSizePixel=0, ZIndex=8})
new("UIGradient", {Parent=sweep, Rotation=90, Transparency=NumberSequence.new({
	NumberSequenceKeypoint.new(0,1), NumberSequenceKeypoint.new(0.5,0), NumberSequenceKeypoint.new(1,1)})})

-- scanlines
local scan = new("Frame", {Parent=BG, Size=UDim2.fromScale(1,1), BackgroundTransparency=1, ZIndex=9})
for i = 0, 60 do
	new("Frame", {Parent=scan, BackgroundColor3=Color3.fromRGB(0,0,0), BackgroundTransparency=0.86,
		Size=UDim2.new(1,0,0,1), Position=UDim2.new(0,0,0,i*12), BorderSizePixel=0})
end

local bgIndex = 1
local bgFront, bgBack = bgA, bgB
local bgRunning = true

local function collectImages()
	local list = {}
	for _, id in ipairs(CustomBG) do list[#list+1] = id end
	for _, id in ipairs(BG_IMAGES) do list[#list+1] = id end
	return list
end

local function isImageOk(id)
	local tmp = Instance.new("ImageLabel")
	tmp.Image = "rbxassetid://"..id
	local ok = pcall(function() ContentProvider:PreloadAsync({tmp}) end)
	local valid = ok and tmp.IsLoaded
	tmp:Destroy()
	return valid
end

local function kenBurns(img, dur)
	img.Size = UDim2.fromScale(1.18,1.18)
	img.Position = UDim2.fromScale(-0.09,-0.09)
	TweenService:Create(img, TweenInfo.new(dur, Enum.EasingStyle.Linear), {
		Size = UDim2.fromScale(1.30,1.30),
		Position = UDim2.fromScale(-0.15,-0.15),
	}):Play()
end

task.spawn(function()
	local images = collectImages()
	if #images == 0 then return end
	local valid = {}
	for _, id in ipairs(images) do
		if isImageOk(id) then valid[#valid+1] = id end
		task.wait()
	end
	if #valid == 0 then return end
	bgFront.Image = "rbxassetid://"..valid[1]
	kenBurns(bgFront, 14)
	task.wait(0.5)
	while bgRunning do
		local speed = Flags.BGCycle and math.clamp(14 / math.max(Flags.BGSpeed,0.2), 4, 40) or 1e9
		task.wait(speed)
		if not bgRunning then break end
		if Flags.BGCycle then
			bgIndex = bgIndex % #valid + 1
			bgBack.Image = "rbxassetid://"..valid[bgIndex]
			bgBack.ImageTransparency = 1
			kenBurns(bgBack, 14)
			TweenService:Create(bgBack, TweenInfo.new(1.6), {ImageTransparency = 0.35}):Play()
			local old = bgFront
			TweenService:Create(old, TweenInfo.new(1.6), {ImageTransparency = 1}):Play()
			bgFront = bgBack
			bgBack = old
		end
	end
end)

-- animations permanentes
local t0 = tick()
bind(RunService.RenderStepped:Connect(function()
	if not BG.Visible then return end
	local dt = tick() - t0
	grad.Rotation = 120 + math.sin(dt * 0.15) * 40
	grad.Offset = Vector2.new(math.sin(dt * 0.1) * 0.2, 0)
	veil.BackgroundTransparency = Flags.BGVeil or 0.45
	sweep.Position = UDim2.new(0, 0, 0, (dt * 40) % 900 - 60)
	for i, p in ipairs(particles) do
		local y = (p.Position.Y.Scale - dt * (0.008 + i * 0.0006)) % 1
		p.Position = UDim2.new(p.Position.X.Scale, 0, y, 0)
	end
end))

--=====================================================================
-- 7. WINDOW
--=====================================================================
local Window = new("Frame", {
	Name = "Window", Parent = Root,
	AnchorPoint = Vector2.new(0.5,0.5),
	Position = UDim2.fromScale(0.5,0.5),
	Size = UDim2.fromOffset(780, 492),
	BackgroundColor3 = Theme.panel,
	BackgroundTransparency = 0.04,
	BorderSizePixel = 0,
	ClipsDescendants = true,
})
corner(Window, 12)
local winStroke = stroke(Window, Theme.stroke, 1, 0.25)

local TopBar = new("Frame", {Parent=Window, Size=UDim2.new(1,0,0,40), BackgroundColor3=Theme.panel2,
	BackgroundTransparency=0.15, BorderSizePixel=0})
new("Frame", {Parent=TopBar, Size=UDim2.new(1,0,0,1), Position=UDim2.new(0,0,1,-1),
	BackgroundColor3=Theme.stroke, BorderSizePixel=0})

new("TextLabel", {Parent=TopBar, Position=UDim2.new(0,16,0,0), Size=UDim2.new(0,200,1,0),
	BackgroundTransparency=1, Font=FONT, Text="VENICE", TextSize=18,
	TextColor3=Theme.text, TextXAlignment=Enum.TextXAlignment.Left})
new("TextLabel", {Parent=TopBar, Position=UDim2.new(0,90,0,0), Size=UDim2.new(0,120,1,0),
	BackgroundTransparency=1, Font=FONT2, Text="HUB", TextSize=13,
	TextColor3=Theme.textDim, TextXAlignment=Enum.TextXAlignment.Left})

local searchBox = new("Frame", {Parent=TopBar, AnchorPoint=Vector2.new(1,0.5), Position=UDim2.new(1,-118,0.5,0),
	Size=UDim2.fromOffset(190,26), BackgroundColor3=Theme.elem, BorderSizePixel=0})
corner(searchBox, 6) stroke(searchBox, Theme.stroke, 1, 0.3)
new("TextLabel", {Parent=searchBox, Position=UDim2.new(0,9,0,0), Size=UDim2.new(0,14,1,0),
	BackgroundTransparency=1, Text="⌕", Font=FONT, TextSize=14, TextColor3=Theme.textDim})
local searchInput = new("TextBox", {Parent=searchBox, Position=UDim2.new(0,26,0,0), Size=UDim2.new(1,-32,1,0),
	BackgroundTransparency=1, Font=FONT2, TextSize=12, TextColor3=Theme.text,
	PlaceholderText="rechercher...", PlaceholderColor3=Theme.textDim,
	TextXAlignment=Enum.TextXAlignment.Left, Text="", ClearTextOnFocus=false})

local keyPill = new("TextButton", {Parent=TopBar, AnchorPoint=Vector2.new(1,0.5), Position=UDim2.new(1,-58,0.5,0),
	Size=UDim2.fromOffset(46,24), BackgroundColor3=Theme.elem, BorderSizePixel=0,
	Font=FONT, TextSize=11, TextColor3=Theme.text, Text="E", AutoButtonColor=false})
corner(keyPill, 6) stroke(keyPill, Theme.stroke, 1, 0.3)

local minBtn = new("TextButton", {Parent=TopBar, AnchorPoint=Vector2.new(1,0.5), Position=UDim2.new(1,-30,0.5,0),
	Size=UDim2.fromOffset(18,18), BackgroundTransparency=1, Font=FONT, TextSize=16,
	TextColor3=Theme.textDim, Text="–", AutoButtonColor=false})
local closeBtn = new("TextButton", {Parent=TopBar, AnchorPoint=Vector2.new(1,0.5), Position=UDim2.new(1,-10,0.5,0),
	Size=UDim2.fromOffset(18,18), BackgroundTransparency=1, Font=FONT, TextSize=15,
	TextColor3=Theme.textDim, Text="×", AutoButtonColor=false})

-- sidebar
local Sidebar = new("Frame", {Parent=Window, Position=UDim2.new(0,0,0,40), Size=UDim2.new(0,156,1,-62),
	BackgroundColor3=Theme.panel, BackgroundTransparency=0.5, BorderSizePixel=0})
new("Frame", {Parent=Sidebar, Size=UDim2.new(0,1,1,0), Position=UDim2.new(1,-1,0,0),
	BackgroundColor3=Theme.stroke, BorderSizePixel=0})
new("UIListLayout", {Parent=Sidebar, Padding=UDim.new(0,4), SortOrder=Enum.SortOrder.LayoutOrder})
pad(Sidebar, 8, 8, 8, 8)

-- content
local Content = new("Frame", {Parent=Window, Position=UDim2.new(0,156,0,40), Size=UDim2.new(1,-156,1,-62),
	BackgroundTransparency=1, BorderSizePixel=0})

-- bottom bar
local Bottom = new("Frame", {Parent=Window, Position=UDim2.new(0,0,1,-22), Size=UDim2.new(1,0,0,22),
	BackgroundColor3=Theme.panel2, BackgroundTransparency=0.2, BorderSizePixel=0})
new("Frame", {Parent=Bottom, Size=UDim2.new(1,0,0,1), BackgroundColor3=Theme.stroke, BorderSizePixel=0})
local statusL = new("TextLabel", {Parent=Bottom, Position=UDim2.new(0,12,0,0), Size=UDim2.new(0.6,0,1,0),
	BackgroundTransparency=1, Font=FONT2, TextSize=11, TextColor3=Theme.textDim,
	TextXAlignment=Enum.TextXAlignment.Left, Text="idle"})
local statusR = new("TextLabel", {Parent=Bottom, AnchorPoint=Vector2.new(1,0), Position=UDim2.new(1,-12,0,0),
	Size=UDim2.new(0.4,0,1,0), BackgroundTransparency=1, Font=FONT2, TextSize=11,
	TextColor3=Theme.textDim, TextXAlignment=Enum.TextXAlignment.Right, Text="-- fps | -- ms"})

--=====================================================================
-- 8. NOTIFICATIONS + WATERMARK
--=====================================================================
local ToastHolder = new("Frame", {Parent=Root, AnchorPoint=Vector2.new(1,0), Position=UDim2.new(1,-14,0,14),
	Size=UDim2.fromOffset(280, 400), BackgroundTransparency=1})
new("UIListLayout", {Parent=ToastHolder, Padding=UDim.new(0,6), HorizontalAlignment=Enum.HorizontalAlignment.Right})

Flags.Notifications = true
local function Notify(text, dur)
	if not Flags.Notifications then return end
	local f = new("Frame", {Parent=ToastHolder, Size=UDim2.new(1,0,0,34), BackgroundColor3=Theme.panel2,
		BackgroundTransparency=0.08, BorderSizePixel=0})
	corner(f, 8) stroke(f, Theme.stroke, 1, 0.2)
	new("Frame", {Parent=f, Size=UDim2.new(0,2,1,-12), Position=UDim2.new(0,0,0,6),
		BackgroundColor3=Theme.accent, BorderSizePixel=0})
	new("TextLabel", {Parent=f, Position=UDim2.new(0,12,0,0), Size=UDim2.new(1,-20,1,0),
		BackgroundTransparency=1, Font=FONT2, TextSize=12, TextColor3=Theme.text,
		TextXAlignment=Enum.TextXAlignment.Left, Text=tostring(text), TextTruncate=Enum.TextTruncate.AtEnd})
	f.Position = UDim2.new(1, 60, 0, 0)
	TweenService:Create(f, TweenInfo.new(0.25, Enum.EasingStyle.Quad), {Position = UDim2.new(0,0,0,0)}):Play()
	task.delay(dur or 3, function()
		if not f.Parent then return end
		local tw = TweenService:Create(f, TweenInfo.new(0.25), {Position = UDim2.new(1,60,0,0), BackgroundTransparency = 1})
		tw:Play()
		tw.Completed:Wait()
		f:Destroy()
	end)
end

local Watermark = new("Frame", {Parent=Root, Position=UDim2.new(0,14,0,14), Size=UDim2.fromOffset(210,26),
	BackgroundColor3=Theme.panel, BackgroundTransparency=0.25, BorderSizePixel=0, Visible=false})
corner(Watermark, 6) stroke(Watermark, Theme.stroke, 1, 0.3)
local wmLabel = new("TextLabel", {Parent=Watermark, Size=UDim2.fromScale(1,1), BackgroundTransparency=1,
	Font=FONT, TextSize=11, TextColor3=Theme.text, Text=""})
pad(Watermark, 0,0,0,10)
wmLabel.TextXAlignment = Enum.TextXAlignment.Left

-- drag watermark
do
	local d, s, p0
	bind(Watermark.InputBegan:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 then
			d, s, p0 = true, i.Position, Watermark.Position
		end
	end))
	bind(UIS.InputChanged:Connect(function(i)
		if d and i.UserInputType == Enum.UserInputType.MouseMovement then
			local del = i.Position - s
			Watermark.Position = UDim2.new(p0.X.Scale, p0.X.Offset + del.X, p0.Y.Scale, p0.Y.Offset + del.Y)
		end
	end))
	bind(UIS.InputEnded:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 then d = false end
	end))
end

--=====================================================================
-- 9. BUILDERS
--=====================================================================
local function reg(frame, name, tab)
	frame:SetAttribute("ItemName", string.lower(name))
	Registry[#Registry+1] = {frame = frame, name = string.lower(name), tab = tab}
end

local function NewSection(tab, title)
	local page = Tabs[tab].page
	local holder = new("Frame", {Parent=page, BackgroundTransparency=1, Size=UDim2.new(1,0,0,0),
		AutomaticSize=Enum.AutomaticSize.Y, LayoutOrder=#page:GetChildren()})
	new("UIListLayout", {Parent=holder, Padding=UDim.new(0,5), SortOrder=Enum.SortOrder.LayoutOrder})
	local header = new("TextLabel", {Parent=holder, Size=UDim2.new(1,0,0,20), BackgroundTransparency=1,
		Font=FONT, TextSize=11, TextColor3=Theme.textDim, Text=string.upper(title),
		TextXAlignment=Enum.TextXAlignment.Left, LayoutOrder=-1})
	header:SetAttribute("ItemName", string.lower(title))
	local s = {holder = holder, header = header, items = {}}
	Sections[#Sections+1] = s
	return holder, s
end

local function Row(parent, name, height)
	local r = new("Frame", {Parent=parent, Size=UDim2.new(1,0,0,height or 32),
		BackgroundColor3=Theme.elem, BackgroundTransparency=0.25, BorderSizePixel=0})
	corner(r, 7)
	local st = stroke(r, Theme.stroke, 1, 0.4)
	new("TextLabel", {Parent=r, Position=UDim2.new(0,11,0,0), Size=UDim2.new(1,-90,1,0),
		BackgroundTransparency=1, Font=FONT2, TextSize=12, TextColor3=Theme.text,
		TextXAlignment=Enum.TextXAlignment.Left, Text=name, TextTruncate=Enum.TextTruncate.AtEnd})
	reg(r, name, CurrentTab)
	return r, st
end

local function NewKeyPill(parent, flag)
	local pill = new("TextButton", {Parent=parent, AnchorPoint=Vector2.new(1,0.5), Position=UDim2.new(1,-42,0.5,0),
		Size=UDim2.fromOffset(30,18), BackgroundColor3=Theme.panel2, BorderSizePixel=0,
		Font=FONT, TextSize=10, TextColor3=Theme.textDim, Text="-", AutoButtonColor=false})
	corner(pill, 5) stroke(pill, Theme.stroke, 1, 0.5)
	pill.MouseEnter:Connect(function() pill.TextColor3 = Theme.text end)
	pill.MouseLeave:Connect(function() pill.TextColor3 = Theme.textDim end)
	return pill
end

local Capturing = nil
local function startCapture(flag, pill)
	Capturing = {flag = flag, pill = pill}
	pill.Text = "..."
	pill.TextColor3 = Theme.accent
end

-- TOGGLE
local function NewToggle(parent, name, flag, default, cb)
	local r = Row(parent, name, 32)
	local sw = new("Frame", {Parent=r, AnchorPoint=Vector2.new(1,0.5), Position=UDim2.new(1,-11,0.5,0),
		Size=UDim2.fromOffset(34,18), BackgroundColor3=Theme.off, BorderSizePixel=0})
	corner(sw, 9)
	local knob = new("Frame", {Parent=sw, AnchorPoint=Vector2.new(0,0.5), Position=UDim2.new(0,2,0.5,0),
		Size=UDim2.fromOffset(14,14), BackgroundColor3=Theme.text, BorderSizePixel=0})
	corner(knob, 9)
	local pill = NewKeyPill(r, flag)

	Flags[flag] = default == true

	local function visual(state)
		TweenService:Create(sw, TweenInfo.new(0.18, Enum.EasingStyle.Quad), {
			BackgroundColor3 = state and Theme.accent or Theme.off}):Play()
		TweenService:Create(knob, TweenInfo.new(0.18, Enum.EasingStyle.Quad), {
			Position = state and UDim2.new(1,-16,0.5,0) or UDim2.new(0,2,0.5,0),
			BackgroundColor3 = state and Theme.accentText or Theme.text}):Play()
	end

	local function setter(v, silent)
		Flags[flag] = v == true
		visual(Flags[flag])
		if cb and not silent then pcall(cb, Flags[flag]) end
	end
	Setters[flag] = setter
	visual(Flags[flag])

	local click = new("TextButton", {Parent=r, Size=UDim2.new(1,-84,1,0), BackgroundTransparency=1,
		Text="", AutoButtonColor=false})
	click.MouseButton1Click:Connect(function()
		setter(not Flags[flag])
		Notify((Flags[flag] and "ON  •  " or "OFF  •  ") .. name, 1.5)
	end)
	r.MouseEnter:Connect(function() TweenService:Create(r, TweenInfo.new(0.15), {BackgroundColor3=Theme.elemHov}):Play() end)
	r.MouseLeave:Connect(function() TweenService:Create(r, TweenInfo.new(0.15), {BackgroundColor3=Theme.elem}):Play() end)
	pill.MouseButton1Click:Connect(function() startCapture(flag, pill) end)
	pill.MouseButton2Click:Connect(function() Binds[flag] = nil pill.Text = "-" end)

	return setter, pill
end

-- SLIDER
local function NewSlider(parent, name, flag, min, max, default, decimals, cb)
	local r = new("Frame", {Parent=parent, Size=UDim2.new(1,0,0,44), BackgroundColor3=Theme.elem,
		BackgroundTransparency=0.25, BorderSizePixel=0})
	corner(r, 7) stroke(r, Theme.stroke, 1, 0.4)
	local lbl = new("TextLabel", {Parent=r, Position=UDim2.new(0,11,0,5), Size=UDim2.new(1,-22,0,16),
		BackgroundTransparency=1, Font=FONT2, TextSize=12, TextColor3=Theme.text,
		TextXAlignment=Enum.TextXAlignment.Left, Text=name})
	local val = new("TextLabel", {Parent=r, AnchorPoint=Vector2.new(1,0), Position=UDim2.new(1,-11,0,5),
		Size=UDim2.new(0,80,0,16), BackgroundTransparency=1, Font=FONT, TextSize=11,
		TextColor3=Theme.textDim, TextXAlignment=Enum.TextXAlignment.Right, Text=tostring(default)})
	reg(r, name, CurrentTab)

	local track = new("Frame", {Parent=r, Position=UDim2.new(0,11,0,30), Size=UDim2.new(1,-22,0,5),
		BackgroundColor3=Theme.panel2, BorderSizePixel=0})
	corner(track, 3)
	local fill = new("Frame", {Parent=track, Size=UDim2.new(0,0,1,0), BackgroundColor3=Theme.accent, BorderSizePixel=0})
	corner(fill, 3)
	local kb = new("Frame", {Parent=track, AnchorPoint=Vector2.new(0.5,0.5), Position=UDim2.new(0,0,0.5,0),
		Size=UDim2.fromOffset(11,11), BackgroundColor3=Theme.accent, BorderSizePixel=0})
	corner(kb, 9)

	Flags[flag] = default
	local function render(v)
		local a = math.clamp((v - min) / (max - min), 0, 1)
		fill.Size = UDim2.new(a, 0, 1, 0)
		kb.Position = UDim2.new(a, 0, 0.5, 0)
		if decimals and decimals > 0 then
			val.Text = string.format("%."..decimals.."f", v)
		else
			val.Text = tostring(math.floor(v))
		end
	end
	render(default)

	local function setter(v, silent)
		v = math.clamp(tonumber(v) or min, min, max)
		Flags[flag] = v
		render(v)
		if cb and not silent then pcall(cb, v) end
	end
	Setters[flag] = setter

	local dragging = false
	local function fromX(x)
		local rel = (x - track.AbsolutePosition.X) / math.max(track.AbsoluteSize.X, 1)
		setter(min + math.clamp(rel,0,1) * (max - min))
	end
	bind(track.InputBegan:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true fromX(i.Position.X) end
	end))
	bind(UIS.InputChanged:Connect(function(i)
		if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then fromX(i.Position.X) end
	end))
	bind(UIS.InputEnded:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
	end))
	return setter
end

-- SELECT
local function NewSelect(parent, name, flag, options, defaultIndex, cb)
	local r = Row(parent, name, 32)
	local idx = defaultIndex or 1
	local lbl = new("TextLabel", {Parent=r, AnchorPoint=Vector2.new(1,0.5), Position=UDim2.new(1,-11,0.5,0),
		Size=UDim2.new(0,150,1,0), BackgroundTransparency=1, Font=FONT, TextSize=11,
		TextColor3=Theme.text, TextXAlignment=Enum.TextXAlignment.Right, Text=tostring(options[idx])})
	local prev = new("TextButton", {Parent=r, AnchorPoint=Vector2.new(1,0.5), Position=UDim2.new(1,-168,0.5,0),
		Size=UDim2.fromOffset(16,16), BackgroundTransparency=1, Font=FONT, TextSize=13,
		TextColor3=Theme.textDim, Text="‹", AutoButtonColor=false})
	local nxt = new("TextButton", {Parent=r, AnchorPoint=Vector2.new(1,0.5), Position=UDim2.new(1,-11,0.5,0),
		Size=UDim2.fromOffset(16,16), BackgroundTransparency=1, Font=FONT, TextSize=13,
		TextColor3=Theme.textDim, Text="›", AutoButtonColor=false})
	lbl.Position = UDim2.new(1,-30,0.5,0)
	lbl.Size = UDim2.new(0,130,1,0)

	Flags[flag] = options[idx]
	local function setter(v, silent)
		if type(v) == "number" then idx = math.clamp(v, 1, #options) else
			for i, o in ipairs(options) do if o == v then idx = i end end
		end
		Flags[flag] = options[idx]
		lbl.Text = tostring(options[idx])
		if cb and not silent then pcall(cb, options[idx]) end
	end
	Setters[flag] = setter
	prev.MouseButton1Click:Connect(function() setter(idx - 1 < 1 and #options or idx - 1) end)
	nxt.MouseButton1Click:Connect(function() setter(idx + 1 > #options and 1 or idx + 1) end)
	return setter
end

-- BUTTON
local function NewButton(parent, name, cb, height)
	local r = new("Frame", {Parent=parent, Size=UDim2.new(1,0,0,height or 30), BackgroundColor3=Theme.elem,
		BackgroundTransparency=0.25, BorderSizePixel=0})
	corner(r, 7) stroke(r, Theme.stroke, 1, 0.4)
	new("TextLabel", {Parent=r, Size=UDim2.new(1,0,1,0), BackgroundTransparency=1, Font=FONT2,
		TextSize=12, TextColor3=Theme.text, Text=name})
	reg(r, name, CurrentTab)
	local b = new("TextButton", {Parent=r, Size=UDim2.new(1,0,1,0), BackgroundTransparency=1, Text="", AutoButtonColor=false})
	b.MouseButton1Click:Connect(function()
		pcall(cb)
	end)
	r.MouseEnter:Connect(function() TweenService:Create(r, TweenInfo.new(0.15), {BackgroundColor3=Theme.elemHov}):Play() end)
	r.MouseLeave:Connect(function() TweenService:Create(r, TweenInfo.new(0.15), {BackgroundColor3=Theme.elem}):Play() end)
	return r
end

-- TEXTBOX
local function NewInput(parent, name, flag, default, cb)
	local r = Row(parent, name, 32)
	local box = new("TextBox", {Parent=r, AnchorPoint=Vector2.new(1,0.5), Position=UDim2.new(1,-11,0.5,0),
		Size=UDim2.new(0,170,0,20), BackgroundColor3=Theme.panel2, BorderSizePixel=0,
		Font=FONT2, TextSize=11, TextColor3=Theme.text, Text=default or "",
		TextXAlignment=Enum.TextXAlignment.Left, ClearTextOnFocus=false})
	corner(box, 5) stroke(box, Theme.stroke, 1, 0.4)
	pad(box, 0, 0, 0, 6)
	Flags[flag] = default or ""
	local function setter(v, silent)
		Flags[flag] = tostring(v)
		box.Text = Flags[flag]
		if cb and not silent then pcall(cb, Flags[flag]) end
	end
	Setters[flag] = setter
	box.FocusLost:Connect(function() setter(box.Text) end)
	return setter
end

-- LIST (affichage dynamique)
local function MakeList(parent, height)
	local holder = new("ScrollingFrame", {Parent=parent, Size=UDim2.new(1,0,0,height or 150),
		BackgroundColor3=Theme.panel2, BackgroundTransparency=0.5, BorderSizePixel=0,
		ScrollBarThickness=3, CanvasSize=UDim2.new(0,0,0,0),
		AutomaticCanvasSize=Enum.AutomaticSize.Y, ScrollBarImageColor3=Theme.strokeHov})
	corner(holder, 7) stroke(holder, Theme.stroke, 1, 0.5)
	pad(holder, 5, 5, 5, 5)
	new("UIListLayout", {Parent=holder, Padding=UDim.new(0,3), SortOrder=Enum.SortOrder.LayoutOrder})
	local count = 0
	local function add(text, onClick)
		count += 1
		local r = new("TextButton", {Parent=holder, Size=UDim2.new(1,-8,0,22), BackgroundColor3=Theme.elem,
			BackgroundTransparency=0.4, BorderSizePixel=0, Font=FONT2, TextSize=11,
			TextColor3=Theme.text, TextXAlignment=Enum.TextXAlignment.Left,
			Text=text, AutoButtonColor=false, LayoutOrder=count})
		corner(r, 5)
		pad(r, 0, 0, 0, 8)
		if onClick then
			r.MouseButton1Click:Connect(function() pcall(onClick) end)
			r.MouseEnter:Connect(function() r.BackgroundColor3 = Theme.elemHov end)
			r.MouseLeave:Connect(function() r.BackgroundColor3 = Theme.elem end)
		end
		return r
	end
	local function clear()
		for _, c in ipairs(holder:GetChildren()) do
			if c:IsA("GuiObject") then c:Destroy() end
		end
		count = 0
	end
	return add, clear
end

--=====================================================================
-- 10. TABS
--=====================================================================
local TabOrder = {}
local function NewTab(name, icon)
	local btn = new("TextButton", {Parent=Sidebar, Size=UDim2.new(1,0,0,30), BackgroundColor3=Theme.elem,
		BackgroundTransparency=1, BorderSizePixel=0, Font=FONT2, TextSize=12,
		TextColor3=Theme.textDim, Text="  "..icon.."   "..name,
		TextXAlignment=Enum.TextXAlignment.Left, AutoButtonColor=false,
		LayoutOrder = #TabOrder + 1})
	corner(btn, 6)
	pad(btn, 0, 0, 0, 8)
	local page = new("ScrollingFrame", {Parent=Content, Size=UDim2.fromScale(1,1), BackgroundTransparency=1,
		BorderSizePixel=0, ScrollBarThickness=3, CanvasSize=UDim2.new(0,0,0,0),
		AutomaticCanvasSize=Enum.AutomaticSize.Y, ScrollBarImageColor3=Theme.strokeHov,
		Visible=false, ClipsDescendants=true})
	pad(page, 12, 12, 12, 12)
	new("UIListLayout", {Parent=page, Padding=UDim.new(0,8), SortOrder=Enum.SortOrder.LayoutOrder})
	Tabs[name] = {button = btn, page = page}
	TabOrder[#TabOrder+1] = name
	btn.MouseButton1Click:Connect(function()
		CurrentTab = name
		for n, t in pairs(Tabs) do
			t.page.Visible = (n == name)
			TweenService:Create(t.button, TweenInfo.new(0.15), {
				BackgroundTransparency = (n == name) and 0.35 or 1,
				TextColor3 = (n == name) and Theme.text or Theme.textDim}):Play()
		end
	end)
	return name
end

--=====================================================================
-- 11. SEARCH
--=====================================================================
local function ApplySearch(q)
	q = string.lower(q or "")
	for _, item in ipairs(Registry) do
		if item.frame.Parent then
			item.frame.Visible = (q == "") or (string.find(item.name, q, 1, true) ~= nil)
		end
	end
	for _, s in ipairs(Sections) do
		local any = false
		for _, c in ipairs(s.holder:GetChildren()) do
			if c:IsA("GuiObject") and c.Visible and c ~= s.header then any = true break end
		end
		s.header.Visible = any
	end
	if q ~= "" then
		for n, t in pairs(Tabs) do
			local found = false
			for _, item in ipairs(Registry) do
				if item.tab == n and item.frame.Visible then found = true break end
			end
			t.button.TextColor3 = found and Theme.text or Theme.textDim
		end
	end
end
searchInput:GetPropertyChangedSignal("Text"):Connect(function()
	ApplySearch(searchInput.Text)
end)

--=====================================================================
-- 12. DRAG / MIN / CLOSE
--=====================================================================
do
	local dragging, s, p0
	bind(TopBar.InputBegan:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging, s, p0 = true, i.Position, Window.Position
		end
	end))
	bind(UIS.InputChanged:Connect(function(i)
		if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then
			local del = i.Position - s
			Window.Position = UDim2.new(p0.X.Scale, p0.X.Offset + del.X, p0.Y.Scale, p0.Y.Offset + del.Y)
		end
	end))
	bind(UIS.InputEnded:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
	end))
end

local minimized = false
minBtn.MouseButton1Click:Connect(function()
	minimized = not minimized
	TweenService:Create(Window, TweenInfo.new(0.22, Enum.EasingStyle.Quad), {
		Size = minimized and UDim2.fromOffset(780, 40) or UDim2.fromOffset(780, 492)}):Play()
	Sidebar.Visible = not minimized
	Content.Visible = not minimized
	Bottom.Visible = not minimized
end)

closeBtn.MouseButton1Click:Connect(function()
	Root.Visible = false
	if Flags.BGOnlyWhenOpen then BG.Visible = false end
end)

--=====================================================================
-- 13. TOGGLE KEYBIND
--=====================================================================
Flags.MenuKey = "E"
local function openMenu()
	Root.Visible = true
	if Flags.BGOnlyWhenOpen then BG.Visible = true end
end
local function closeMenu()
	Root.Visible = false
	if Flags.BGOnlyWhenOpen then BG.Visible = false end
end

keyPill.MouseButton1Click:Connect(function()
	Capturing = {menu = true}
	keyPill.Text = "..."
end)

bind(UIS.InputBegan:Connect(function(input, gp)
	if Capturing then
		if input.UserInputType == Enum.UserInputType.Keyboard then
			local k = input.KeyCode
			if k == Enum.KeyCode.Unknown then return end
			if Capturing.menu then
				Flags.MenuKey = k.Name
				keyPill.Text = k.Name
			else
				Binds[Capturing.flag] = k
				if Capturing.pill then Capturing.pill.Text = k.Name end
			end
			Capturing = nil
		elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
			if Capturing.pill then Binds[Capturing.flag] = nil Capturing.pill.Text = "-" end
			Capturing = nil
		end
		return
	end
	if UIS:GetFocusedTextBox() then return end
	if gp then return end
	if input.UserInputType ~= Enum.UserInputType.Keyboard then return end
	if input.KeyCode.Name == Flags.MenuKey then
		if Root.Visible then closeMenu() else openMenu() end
		return
	end
	for flag, key in pairs(Binds) do
		if key and input.KeyCode == key and Setters[flag] then
			Setters[flag](not Flags[flag])
		end
	end
end))

--=====================================================================
-- 14. THÈME CLAIR / SOMBRE
--=====================================================================
local function ck(c) return string.format("%d,%d,%d",
	math.floor(c.R*255+0.5), math.floor(c.G*255+0.5), math.floor(c.B*255+0.5)) end
local ToLight, ToDark = {}, {}
for k, dark in pairs(Theme) do
	local light = ThemeLight[k]
	if light then
		ToLight[ck(dark)] = light
		ToDark[ck(light)] = dark
	end
end
Flags.LightMode = false
local function applyTheme(light)
	local map = light and ToLight or ToDark
	for _, d in ipairs(Screen:GetDescendants()) do
		pcall(function()
			if d:IsA("GuiObject") then
				d.BackgroundColor3 = map[ck(d.BackgroundColor3)] or d.BackgroundColor3
			end
			if d:IsA("TextLabel") or d:IsA("TextButton") or d:IsA("TextBox") then
				d.TextColor3 = map[ck(d.TextColor3)] or d.TextColor3
				if d.PlaceholderColor3 then
					d.PlaceholderColor3 = map[ck(d.PlaceholderColor3)] or d.PlaceholderColor3
				end
			end
			if d:IsA("UIStroke") then
				d.Color = map[ck(d.Color)] or d.Color
			end
		end)
	end
end

--=====================================================================
-- 15. ONGLETS
--=====================================================================
local T_MOVE  = NewTab("Movement", "»")
local T_VIS   = NewTab("Visual", "◉")
local T_UTIL  = NewTab("Utility", "✦")
local T_TP    = NewTab("Teleport", "⌖")
local T_SFE   = NewTab("Shoot For Eggs", "◈")
local T_SCAN  = NewTab("Scanner", "◎")
local T_SET   = NewTab("Settings", "⚙")

--=====================================================================
-- 16. MOVEMENT
--=====================================================================
CurrentTab = T_MOVE
do
	local s = NewSection(T_MOVE, "Vitesse & Saut")
	NewToggle(s, "WalkSpeed", "Speed", false, function(on)
		local hum = getHum()
		if hum then hum.WalkSpeed = on and Flags.SpeedVal or 16 end
	end)
	NewSlider(s, "Vitesse de marche", "SpeedVal", 16, 500, 60, 0, function(v)
		if Flags.Speed then local h = getHum() if h then h.WalkSpeed = v end end
	end)
	NewToggle(s, "JumpPower", "Jump", false, function(on)
		local hum = getHum()
		if hum then
			hum.UseJumpPower = true
			hum.JumpPower = on and Flags.JumpVal or 50
		end
	end)
	NewSlider(s, "Puissance de saut", "JumpVal", 50, 500, 120, 0, function(v)
		if Flags.Jump then local h = getHum() if h then h.UseJumpPower = true h.JumpPower = v end end
	end)
	NewToggle(s, "Saut infini", "InfJump", false)
	NewToggle(s, "Bunny Hop (saut auto)", "BHop", false)

	local s2 = NewSection(T_MOVE, "Déplacements")
	NewToggle(s2, "Fly", "Fly", false)
	NewSlider(s2, "Vitesse de vol", "FlySpeed", 10, 500, 70, 0)
	NewToggle(s2, "Noclip", "Noclip", false)
	NewToggle(s2, "Freeze (ancrage)", "Freeze", false, function(on)
		local hrp = getHRP()
		if hrp then hrp.Anchored = on end
	end)
	NewToggle(s2, "Click Teleport", "ClickTP", false)
	NewToggle(s2, "Anti-Void (retour auto)", "AntiVoid", false)

	local s3 = NewSection(T_MOVE, "Physique")
	NewSlider(s3, "Gravité", "Gravity", 0, 300, 196.2, 1, function(v)
		Workspace.Gravity = v
	end)
	NewToggle(s3, "Gravité personnalisée", "GravOn", false, function(on)
		Workspace.Gravity = on and Flags.Gravity or 196.2
	end)
	NewButton(s3, "Reset vitesse / saut", function()
		local h = getHum()
		if h then h.WalkSpeed = 16 h.JumpPower = 50 end
		Workspace.Gravity = 196.2
		Notify("Physique réinitialisée")
	end)
end

-- Fly
do
	local bv, bg
	local function stopFly()
		if bv then bv:Destroy() bv = nil end
		if bg then bg:Destroy() bg = nil end
	end
	local function startFly()
		stopFly()
		local hrp = getHRP()
		if not hrp then return end
		bv = Instance.new("BodyVelocity")
		bv.Name = "VeniceFly" bv.MaxForce = Vector3.new(1,1,1)*1e5
		bv.Velocity = Vector3.zero bv.Parent = hrp
		bg = Instance.new("BodyGyro")
		bg.Name = "VeniceGyro" bg.MaxTorque = Vector3.new(1,1,1)*1e5
		bg.P = 3000 bg.D = 200 bg.Parent = hrp
	end
	bind(RunService.RenderStepped:Connect(function()
		if not Flags.Fly then
			if bv then stopFly() end
			return
		end
		if not bv then startFly() return end
		local hrp = getHRP()
		if not hrp then stopFly() return end
		local cam = getCam() if not cam then return end
		local dir = Vector3.zero
		if UIS:IsKeyDown(Enum.KeyCode.W) then dir += cam.CFrame.LookVector end
		if UIS:IsKeyDown(Enum.KeyCode.S) then dir -= cam.CFrame.LookVector end
		if UIS:IsKeyDown(Enum.KeyCode.D) then dir += cam.CFrame.RightVector end
		if UIS:IsKeyDown(Enum.KeyCode.A) then dir -= cam.CFrame.RightVector end
		if UIS:IsKeyDown(Enum.KeyCode.Space) then dir += Vector3.new(0,1,0) end
		if UIS:IsKeyDown(Enum.KeyCode.LeftControl) then dir -= Vector3.new(0,1,0) end
		if dir.Magnitude > 0 then
			bv.Velocity = dir.Unit * Flags.FlySpeed
		else
			bv.Velocity = Vector3.zero
		end
		bg.CFrame = CFrame.new(hrp.Position, hrp.Position + cam.CFrame.LookVector)
	end))
end

-- Noclip / anti-void / bhop / infjump / clicktp
do
	bind(RunService.Stepped:Connect(function()
		if Flags.Noclip then
			local c = getChar()
			if c then
				for _, p in ipairs(c:GetDescendants()) do
					if p:IsA("BasePart") then p.CanCollide = false end
				end
			end
		end
		if Flags.AntiVoid then
			local hrp = getHRP()
			if hrp and hrp.Position.Y < -60 then
				hrp.CFrame = CFrame.new(0, 60, 0)
			end
		end
		if Flags.BHop then
			local hum = getHum()
			if hum and hum.FloorMaterial ~= Enum.Material.Air then
				hum:ChangeState(Enum.HumanoidStateType.Jumping)
			end
		end
	end))

	bind(UIS.JumpRequest:Connect(function()
		if Flags.InfJump then
			local hum = getHum()
			if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
		end
	end))

	bind(UIS.InputBegan:Connect(function(input, gp)
		if gp or not Flags.ClickTP then return end
		if input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
		local m = LP:GetMouse()
		if m and m.Target then
			tpTo(m.Hit, 3)
		end
	end))
end

--=====================================================================
-- 17. VISUAL
--=====================================================================
CurrentTab = T_VIS
do
	local s = NewSection(T_VIS, "Caméra")
	NewSlider(s, "FOV", "FOV", 40, 130, 70, 0, function(v)
		local c = getCam() if c then c.FieldOfView = v end
	end)
	NewToggle(s, "Viser sans bouger la caméra (lock)", "CamLock", false)
	NewButton(s, "Reset FOV", function()
		local c = getCam() if c then c.FieldOfView = 70 end
		Setters.FOV(70, true)
	end)

	local s2 = NewSection(T_VIS, "Rendu")
	NewToggle(s2, "Fullbright", "Fullbright", false)
	NewToggle(s2, "Supprimer le brouillard", "NoFog", false)
	NewToggle(s2, "Supprimer les particules", "NoParticles", false)
	NewToggle(s2, "Mode nuit", "Night", false, function(on)
		Lighting.ClockTime = on and 0 or 14
	end)
	NewToggle(s2, "Crosshair", "Crosshair", false)

	local s3 = NewSection(T_VIS, "Joueurs")
	NewToggle(s3, "ESP Joueurs", "PlayerESP", false)
	NewToggle(s3, "Noms + distance", "PlayerNames", false)
	NewToggle(s3, "Lignes (tracers)", "PlayerTracers", false)
end

-- Crosshair
do
	local ch = new("Frame", {Parent=Root, AnchorPoint=Vector2.new(0.5,0.5), Position=UDim2.fromScale(0.5,0.5),
		Size=UDim2.fromOffset(14,14), BackgroundTransparency=1, Visible=false})
	new("Frame", {Parent=ch, AnchorPoint=Vector2.new(0.5,0.5), Position=UDim2.fromScale(0.5,0.5),
		Size=UDim2.fromOffset(2,2), BackgroundColor3=Color3.new(1,1,1), BorderSizePixel=0})
	new("Frame", {Parent=ch, AnchorPoint=Vector2.new(0.5,1), Position=UDim2.fromScale(0.5,0.4),
		Size=UDim2.fromOffset(1,5), BackgroundColor3=Color3.new(1,1,1), BorderSizePixel=0})
	new("Frame", {Parent=ch, AnchorPoint=Vector2.new(0.5,0), Position=UDim2.fromScale(0.5,0.6),
		Size=UDim2.fromOffset(1,5), BackgroundColor3=Color3.new(1,1,1), BorderSizePixel=0})
	new("Frame", {Parent=ch, AnchorPoint=Vector2.new(1,0.5), Position=UDim2.fromScale(0.4,0.5),
		Size=UDim2.fromOffset(5,1), BackgroundColor3=Color3.new(1,1,1), BorderSizePixel=0})
	new("Frame", {Parent=ch, AnchorPoint=Vector2.new(0,0.5), Position=UDim2.fromScale(0.6,0.5),
		Size=UDim2.fromOffset(5,1), BackgroundColor3=Color3.new(1,1,1), BorderSizePixel=0})
	bind(RunService.RenderStepped:Connect(function()
		ch.Visible = Flags.Crosshair and Root.Visible
	end))
end

-- Fullbright / fog / particles / ESP
do
	local origLight = {}
	local savedFog = false
	local function setFB(on)
		if on then
			for _, p in ipairs({"Ambient","OutdoorAmbient","Brightness","ClockTime","GlobalShadows","EnvironmentDiffuseScale","EnvironmentSpecularScale"}) do
				origLight[p] = Lighting[p]
			end
			Lighting.Ambient = Color3.fromRGB(190,190,190)
			Lighting.OutdoorAmbient = Color3.fromRGB(190,190,190)
			Lighting.Brightness = 3
			Lighting.ClockTime = 14
			Lighting.GlobalShadows = false
		else
			for p, v in pairs(origLight) do pcall(function() Lighting[p] = v end) end
		end
	end

	local espHighlights = {}
	local tracers = {}
	local tracerFolder = new("Frame", {Parent=Root, Size=UDim2.fromScale(1,1), BackgroundTransparency=1})

	local function clearESP()
		for _, h in pairs(espHighlights) do pcall(function() h:Destroy() end) end
		espHighlights = {}
	end

	bind(RunService.RenderStepped:Connect(function()
		-- fullbright
		if Flags.Fullbright and not Flags._fbOn then Flags._fbOn = true setFB(true) end
		if not Flags.Fullbright and Flags._fbOn then Flags._fbOn = false setFB(false) end
		-- fog
		if Flags.NoFog and not savedFog then
			Lighting.FogEnd = 1e6 Lighting.FogStart = 1e6 savedFog = true
		elseif not Flags.NoFog and savedFog then
			savedFog = false
		end
		-- particules
		if Flags.NoParticles ~= Flags._npOn then
			Flags._npOn = Flags.NoParticles
			for _, d in ipairs(Workspace:GetDescendants()) do
				if d:IsA("ParticleEmitter") or d:IsA("Trail") or d:IsA("Smoke") or d:IsA("Fire") or d:IsA("Sparkles") then
					d.Enabled = not Flags.NoParticles
				end
			end
		end
		-- ESP
		if Flags.PlayerESP or Flags.PlayerNames then
			for _, plr in ipairs(Players:GetPlayers()) do
				if plr ~= LP then
					local char = plr.Character
					local hrp = char and char:FindFirstChild("HumanoidRootPart")
					if hrp then
						if not espHighlights[plr] or not espHighlights[plr].Parent then
							local h = Instance.new("Highlight")
							h.Name = "VeniceESP"
							h.Adornee = char
							h.FillColor = Color3.fromRGB(255,255,255)
							h.FillTransparency = 0.75
							h.OutlineColor = Color3.fromRGB(255,255,255)
							h.OutlineTransparency = 0
							h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
							h.Parent = char
							espHighlights[plr] = h
						end
						if Flags.PlayerNames then
							local bgui = char:FindFirstChild("VeniceName")
							if not bgui then
								bgui = Instance.new("BillboardGui")
								bgui.Name = "VeniceName"
								bgui.Size = UDim2.fromOffset(140, 26)
								bgui.StudsOffset = Vector3.new(0, 3.2, 0)
								bgui.AlwaysOnTop = true
								bgui.Adornee = hrp
								bgui.Parent = char
								local tl = Instance.new("TextLabel", bgui)
								tl.Size = UDim2.fromScale(1,1)
								tl.BackgroundTransparency = 1
								tl.Font = FONT
								tl.TextSize = 12
								tl.TextColor3 = Color3.fromRGB(255,255,255)
								tl.TextStrokeTransparency = 0
								tl.TextStrokeColor3 = Color3.fromRGB(0,0,0)
								tl.Name = "Lbl"
							end
							local hum = char:FindFirstChildOfClass("Humanoid")
							local d = (hrp.Position - (getHRP() and getHRP().Position or Vector3.zero)).Magnitude
							bgui.Lbl.Text = string.format("%s  [%d hp]  %dm", plr.Name, hum and math.floor(hum.Health) or 0, math.floor(d))
						else
							local bgui = char:FindFirstChild("VeniceName")
							if bgui then bgui:Destroy() end
						end
					end
				end
			end
		elseif Flags._espOn then
			clearESP()
			for _, plr in ipairs(Players:GetPlayers()) do
				local char = plr.Character
				if char then
					local b = char:FindFirstChild("VeniceName")
					if b then b:Destroy() end
				end
			end
		end
		Flags._espOn = Flags.PlayerESP or Flags.PlayerNames
	end))
end

--=====================================================================
-- 18. UTILITY
--=====================================================================
CurrentTab = T_UTIL
do
	local s = NewSection(T_UTIL, "Performance")
	NewToggle(s, "Débloquer les FPS", "FPSUnlock", false, function(on)
		if setfpscap then pcall(setfpscap, on and Flags.FPSVal or 60) end
	end)
	NewSlider(s, "Limite FPS", "FPSVal", 60, 999, 240, 0, function(v)
		if setfpscap and Flags.FPSUnlock then pcall(setfpscap, v) end
	end)
	NewToggle(s, "Basses graphismes", "LowGFX", false, function(on)
		pcall(function()
			if on then
				settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
				Lighting.GlobalShadows = false
			else
				settings().Rendering.QualityLevel = Enum.QualityLevel.Automatic
			end
		end)
	end)

	local s2 = NewSection(T_UTIL, "Serveur")
	NewButton(s2, "Server Hop (changer de serveur)", function()
		local ok, res = pcall(function()
			return game:HttpGet("https://games.roblox.com/v1/games/"..game.PlaceId.."/servers/Public?sortOrder=Asc&limit=100")
		end)
		if not ok then Notify("Échec de la requête") return end
		local data = HttpService:JSONDecode(res)
		for _, sv in ipairs(data.data or {}) do
			if sv.id ~= game.JobId and (sv.playing or 0) < (sv.maxPlayers or 999) then
				Notify("Hop vers "..sv.id:sub(1,8))
				TeleportService:TeleportToPlaceInstance(game.PlaceId, sv.id, LP)
				return
			end
		end
		Notify("Aucun serveur dispo")
	end)
	NewButton(s2, "Rejoindre (rejoin)", function()
		pcall(function() TeleportService:Teleport(game.PlaceId, LP) end)
	end)
	NewButton(s2, "Copier le Job ID", function()
		if setclipboard then pcall(setclipboard, game.JobId) Notify("JobId copié") end
	end)
	NewButton(s2, "Copier le Place ID", function()
		if setclipboard then pcall(setclipboard, tostring(game.PlaceId)) Notify("PlaceId copié") end
	end)

	local s3 = NewSection(T_UTIL, "Personnage")
	NewButton(s3, "Reset personnage", function()
		local c = getChar()
		if c then pcall(function() c:BreakJoints() end) end
	end)
	NewButton(s3, "Respawn", function()
		pcall(function() LP:LoadCharacter() end)
	end)
	NewToggle(s3, "Invisible (client)", "Invisible", false, function(on)
		local c = getChar()
		if c then
			for _, d in ipairs(c:GetDescendants()) do
				if d:IsA("BasePart") or d:IsA("Decal") then
					d.LocalTransparencyModifier = on and 1 or 0
				end
			end
		end
	end)
	NewToggle(s3, "Anti-AFK", "AntiAFK", true)

	local s4 = NewSection(T_UTIL, "Divers")
	NewToggle(s4, "Chat Spam", "ChatSpam", false)
	NewInput(s4, "Message", "ChatMsg", "venice hub on top")
	NewSlider(s4, "Intervalle (s)", "ChatDelay", 0.5, 20, 3, 1)
	NewToggle(s4, "Notifications", "Notifications", true)
end

-- Anti-AFK
bind(LP.Idled:Connect(function()
	if not Flags.AntiAFK then return end
	pcall(function()
		VirtualUser:CaptureController()
		VirtualUser:ClickButton2(Vector2.new())
	end)
end))

-- Chat spam
task.spawn(function()
	while true do
		local d = Flags.ChatDelay or 3
		task.wait(d)
		if Flags.ChatSpam then
			pcall(function()
				local ev = ReplicatedStorage:FindFirstChild("DefaultChatSystemChatEvents")
				if ev then
					ev:FindFirstChild("SayMessageRequest"):FireServer(Flags.ChatMsg, "All")
				end
			end)
		end
	end
end)

-- Invisible loop
bind(RunService.RenderStepped:Connect(function()
	if not Flags.Invisible then return end
	local c = getChar()
	if c then
		for _, d in ipairs(c:GetDescendants()) do
			if d:IsA("BasePart") or d:IsA("Decal") then
				d.LocalTransparencyModifier = 1
			end
		end
	end
end))

--=====================================================================
-- 19. TELEPORT
--=====================================================================
CurrentTab = T_TP
local waypoints = {}
do
	local s = NewSection(T_TP, "Waypoints")
	NewInput(s, "Nom du waypoint", "WPName", "point1")
	NewButton(s, "Sauvegarder la position", function()
		local hrp = getHRP() if not hrp then return end
		local n = Flags.WPName ~= "" and Flags.WPName or ("wp"..#waypoints+1)
		waypoints[n] = hrp.Position
		Notify("Waypoint '"..n.."' sauvegardé")
		if RefreshWP then RefreshWP() end
	end)
	local add, clear = MakeList(s, 160)
	function RefreshWP()
		clear()
		local found = false
		for n, pos in pairs(waypoints) do
			found = true
			add(string.format("%s   (%.0f, %.0f, %.0f)   [clic = TP]", n, pos.X, pos.Y, pos.Z), function()
				tpTo(pos, 3)
				Notify("TP → "..n)
			end)
		end
		if not found then add("(aucun waypoint)") end
	end
	RefreshWP()
	NewButton(s, "Supprimer tous les waypoints", function()
		waypoints = {}
		RefreshWP()
	end)

	local s2 = NewSection(T_TP, "Joueurs")
	NewButton(s2, "TP vers joueur le plus proche", function()
		local hrp = getHRP() if not hrp then return end
		local best, bd = nil, math.huge
		for _, p in ipairs(Players:GetPlayers()) do
			if p ~= LP and p.Character then
				local h = p.Character:FindFirstChild("HumanoidRootPart")
				if h then
					local d = (h.Position - hrp.Position).Magnitude
					if d < bd then bd, best = d, h end
				end
			end
		end
		if best then tpTo(best.Position, 4) Notify("TP joueur") end
	end)
	local addP, clearP = MakeList(s2, 130)
	NewButton(s2, "Rafraîchir la liste des joueurs", function()
		clearP()
		for _, p in ipairs(Players:GetPlayers()) do
			if p ~= LP then
				add(p.Name.."   [clic = TP]", function()
					local h = p.Character and p.Character:FindFirstChild("HumanoidRootPart")
					if h then tpTo(h.Position, 4) end
				end)
			end
		end
	end)

	local s3 = NewSection(T_TP, "Map")
	NewButton(s3, "TP au spawn", function()
		local sp = Workspace:FindFirstChildOfClass("SpawnLocation")
		if sp then tpTo(sp.Position, 3) else Notify("Aucun spawn trouvé") end
	end)
	NewButton(s3, "TP au point le plus haut", function()
		local best, by = nil, -1e9
		for _, d in ipairs(Workspace:GetDescendants()) do
			if d:IsA("BasePart") and d.Anchored then
				if d.Position.Y > by then by, best = d.Position.Y, d end
			end
		end
		if best then tpTo(best.Position, 6) end
	end)
end

--=====================================================================
-- 20. SHOOT FOR EGGS
--=====================================================================
CurrentTab = T_SFE
local plotPos = nil

local function getPlotPos()
	if plotPos then return plotPos end
	for _, nm in ipairs({"plot","base","home","island","terrain"}) do
		for _, d in ipairs(Workspace:GetChildren()) do
			if d:IsA("Model") and string.find(string.lower(d.Name), nm, 1, true) then
				local owner = d:GetAttribute("Owner") or (d:FindFirstChild("Owner") and d.Owner.Value)
				if owner == nil or owner == LP or owner == LP.Name or owner == LP.UserId then
					local pp = d.PrimaryPart or d:FindFirstChildWhichIsA("BasePart")
					if pp then plotPos = pp.Position return plotPos end
				end
			end
		end
	end
	return nil
end

-- ---- scan œufs
local EggCache = {}
local function eggHP(e)
	local m = e.model
	local att = m:GetAttribute("Health") or m:GetAttribute("HP") or m:GetAttribute("CurrentHealth")
	if att then return tonumber(att) end
	local v = m:FindFirstChild("Health") or m:FindFirstChild("HP") or m:FindFirstChild("CurrentHealth")
	if v and v:IsA("ValueBase") then return tonumber(v.Value) end
	for _, d in ipairs(m:GetDescendants()) do
		if d:IsA("TextLabel") and string.find(d.Text, "%%") then
			local n = string.match(d.Text, "([%d,]+)")
			if n then return tonumber((n:gsub(",", ""))) end
		end
	end
	return nil
end

local function refreshEggs()
	local out = {}
	local char = LP.Character
	for _, d in ipairs(Workspace:GetDescendants()) do
		if d:IsA("Model") or d:IsA("BasePart") then
			if not (char and d:IsDescendantOf(char)) then
				local score = 0
				local nm = string.lower(d.Name)
				if string.find(nm, "egg", 1, true) then score += 4 end
				if d:GetAttribute("Health") or d:GetAttribute("MaxHealth") or d:GetAttribute("HP") then score += 3 end
				if d:FindFirstChild("Health") or d:FindFirstChild("HP") then score += 3 end
				local bill = d:FindFirstChildWhichIsA("BillboardGui", true)
				if bill then score += 2 end
				if score >= 4 then
					local part = d:IsA("BasePart") and d or (d.PrimaryPart or d:FindFirstChildWhichIsA("BasePart"))
					if part then
						local ignore = false
						if Flags.IgnorePlotEggs then
							local pp = getPlotPos()
							if pp and (part.Position - pp).Magnitude < 70 then ignore = true end
						end
						if not ignore then
							out[#out+1] = {model = d, part = part, name = d.Name}
						end
					end
				end
			end
		end
	end
	return out
end

task.spawn(function()
	while true do
		EggCache = refreshEggs()
		task.wait(0.5)
	end
end)

-- ---- interaction helpers
local function scanPrompts(filter)
	local out = {}
	for _, d in ipairs(Workspace:GetDescendants()) do
		if d:IsA("ProximityPrompt") and d.Enabled then
			local base = d.Parent
			local part = base and (base:IsA("BasePart") and base or (base:IsA("Attachment") and base.Parent))
			local txt = string.lower((d.ActionText ~= "" and d.ActionText or "").." "..(d.ObjectText or "").." "..(base and base.Name or ""))
			if filter(txt, d) then
				out[#out+1] = {obj = d, pos = part and part.Position or nil, text = txt, kind = "prompt"}
			end
		end
	end
	return out
end

local function scanClickDetectors(filter)
	local out = {}
	for _, d in ipairs(Workspace:GetDescendants()) do
		if d:IsA("ClickDetector") and d.Parent then
			local part = d.Parent:IsA("BasePart") and d.Parent or nil
			local txt = string.lower(d.Parent.Name)
			if part and filter(txt, d) then
				out[#out+1] = {obj = d, pos = part.Position, text = txt, kind = "click"}
			end
		end
	end
	return out
end

local function scanButtons(filter)
	local out = {}
	local pg = LP:FindFirstChildOfClass("PlayerGui")
	if not pg then return out end
	for _, d in ipairs(pg:GetDescendants()) do
		if d:IsA("GuiButton") and d.Visible and d.AbsoluteSize.X > 4 then
			local txt = string.lower(((d:IsA("TextButton") and d.Text) or "").." "..d.Name)
			if filter(txt, d) then
				out[#out+1] = {obj = d, text = txt, kind = "button"}
			end
		end
	end
	return out
end

local function firePrompt(p)
	if not p or not p.Parent then return end
	if fireproximityprompt then
		if pcall(fireproximityprompt, p) then return end
	end
	pcall(function()
		p:InputHoldBegin()
		if (p.HoldDuration or 0) > 0 then task.wait(p.HoldDuration) end
		p:InputHoldEnd()
	end)
end

local function clickButton(b)
	if not b or not b.Parent then return end
	if firesignal then
		if pcall(firesignal, b.MouseButton1Click) then return end
	end
	pcall(function() b:Activate() end)
end

local function fireClickDetector(cd)
	if not cd then return end
	if fireclickdetector then pcall(fireclickdetector, cd) end
end

-- ---- pixel libre + aim
local function pixelBlocked(x, y)
	local pg = LP:FindFirstChildOfClass("PlayerGui")
	if not pg or not pg.GetGuiObjectsAtPosition then return false end
	local ok, objs = pcall(function() return pg:GetGuiObjectsAtPosition(x, y) end)
	if not ok or not objs then return false end
	for _, o in ipairs(objs) do
		if o:IsDescendantOf(Screen) then return true end
	end
	return false
end

local freePixel = Vector2.new(0,0)
local lastPixelCalc = 0
local function getFreePixel()
	if tick() - lastPixelCalc < 0.4 then return freePixel end
	lastPixelCalc = tick()
	local cam = getCam() if not cam then return freePixel end
	local vp = cam.ViewportSize
	local cands = {
		Vector2.new(vp.X*0.5, vp.Y*0.5),
		Vector2.new(vp.X*0.5, 26),
		Vector2.new(vp.X*0.5, vp.Y-26),
		Vector2.new(26, vp.Y*0.5),
		Vector2.new(vp.X-26, vp.Y*0.5),
	}
	for _, p in ipairs(cands) do
		if not pixelBlocked(p.X, p.Y) then freePixel = p return freePixel end
	end
	freePixel = cands[1]
	return freePixel
end

local function aimAtPixel(target, px, py)
	local cam = getCam() if not cam then return end
	local camPos = cam.CFrame.Position
	local ray = cam:ViewportPointToRay(px, py)
	local from = ray.Direction.Unit
	local to = target - camPos
	if to.Magnitude < 0.01 then return end
	to = to.Unit
	local dot = math.clamp(from:Dot(to), -1, 1)
	local axis = from:Cross(to)
	if axis.Magnitude < 1e-5 then
		cam.CFrame = CFrame.new(camPos, camPos + to)
	else
		local rot = CFrame.fromAxisAngle(axis.Unit, math.acos(dot))
		cam.CFrame = CFrame.new(camPos) * rot * cam.CFrame.Rotation
	end
end

local function fireTool()
	local char = LP.Character
	if not char then return end
	local tool = char:FindFirstChildWhichIsA("Tool")
	if tool then
		pcall(function() tool:Activate() end)
	end
end

local function getTargetEgg()
	local hrp = getHRP() if not hrp then return nil end
	local filt = string.lower(Flags.EggFilter or "")
	local best, bestScore = nil, math.huge
	for _, e in ipairs(EggCache) do
		if e.part and e.part.Parent then
			if filt == "" or string.find(string.lower(e.name), filt, 1, true) then
				local pos = e.part.Position
				local d = (pos - hrp.Position).Magnitude
				if d <= (Flags.ShootRange or 400) then
					local score = d
					local mode = Flags.TargetMode
					if mode == "HP le plus bas" then score = eggHP(e) or 1e18
					elseif mode == "HP le plus haut" then score = -(eggHP(e) or 0)
					elseif mode == "Plus gros" then
						local sz = e.part.Size
						score = -(sz.X*sz.Y*sz.Z)
					end
					if score < bestScore then bestScore = score best = e end
				end
			end
		end
	end
	return best
end

local function doAutoShoot()
	if not Flags.AutoShoot then return end
	local e = getTargetEgg()
	if not e then return end
	local cam = getCam() if not cam then return end
	local px, py = getFreePixel().X, getFreePixel().Y
	pcall(function() VIM:SendMouseMoveEvent(px, py, false) end)
	aimAtPixel(e.part.Position, px, py)
	task.wait()
	if Flags.FireMethod ~= "Click seulement" then fireTool() end
	if Flags.FireMethod ~= "Tool seulement" then
		pcall(function()
			VIM:SendMouseButtonEvent(px, py, 0, true, game, 1)
			VIM:SendMouseButtonEvent(px, py, 0, false, game, 1)
		end)
	end
end

task.spawn(function()
	while true do
		local d = Flags.ShootDelay or 0.06
		if Flags.AutoShoot then doAutoShoot() end
		task.wait(d)
	end
end)

-- ---- farm loops
task.spawn(function()
	while true do
		task.wait(0.35)
		if Flags.AutoPlace then
			local t = scanPrompts(function(txt) return string.find(txt, "place", 1, true) or string.find(txt, "drop", 1, true) end)
			local target = t[1]
			if target then
				if target.pos then
					local hrp = getHRP()
					if hrp and (hrp.Position - target.pos).Magnitude > 12 then
						tpNear(target.pos, 4)
						task.wait(0.12)
					end
				end
				firePrompt(target.obj)
			end
		end
	end
end)

task.spawn(function()
	while true do
		task.wait(0.6)
		if Flags.AutoHatch then
			for _, t in ipairs(scanPrompts(function(txt) return string.find(txt, "hatch", 1, true) end)) do
				firePrompt(t.obj)
			end
			for _, b in ipairs(scanButtons(function(txt) return string.find(txt, "hatch", 1, true) end)) do
				clickButton(b.obj)
			end
		end
		if Flags.AutoCollect then
			for _, b in ipairs(scanButtons(function(txt)
				return string.find(txt, "collect", 1, true) or string.find(txt, "cash", 1, true) or string.find(txt, "money", 1, true)
			end)) do clickButton(b.obj) end
			for _, t in ipairs(scanPrompts(function(txt)
				return string.find(txt, "collect", 1, true) or string.find(txt, "cash", 1, true)
			end)) do firePrompt(t.obj) end
		end
		if Flags.AutoSell then
			for _, b in ipairs(scanButtons(function(txt) return string.find(txt, "sell", 1, true) end)) do clickButton(b.obj) end
		end
		if Flags.AutoSpin then
			for _, b in ipairs(scanButtons(function(txt)
				return string.find(txt, "spin", 1, true) or string.find(txt, "wheel", 1, true)
			end)) do clickButton(b.obj) end
		end
		if Flags.AutoClaim then
			for _, b in ipairs(scanButtons(function(txt)
				return string.find(txt, "claim", 1, true) or string.find(txt, "reward", 1, true) or string.find(txt, "daily", 1, true)
			end)) do clickButton(b.obj) end
		end
	end
end)

task.spawn(function()
	while true do
		task.wait(1.5)
		if Flags.AutoRebirth then
			for _, b in ipairs(scanButtons(function(txt) return string.find(txt, "rebirth", 1, true) end)) do
				clickButton(b.obj)
			end
		end
	end
end)

task.spawn(function()
	while true do
		task.wait(0.4)
		if Flags.AutoTrain then
			local hrp = getHRP()
			if hrp then
				local pad
				for _, d in ipairs(Workspace:GetDescendants()) do
					if d:IsA("BasePart") then
						local nm = string.lower(d.Name)
						if string.find(nm, "pad", 1, true) or string.find(nm, "damage", 1, true) or string.find(nm, "train", 1, true) then
							pad = d break
						end
					end
				end
				if pad and (hrp.Position - pad.Position).Magnitude > 6 then
					hrp.CFrame = CFrame.new(pad.Position + Vector3.new(0, 4, 0))
				end
			end
		end
		if Flags.InstantCarry then
			local char = LP.Character
			if char then
				local holding = false
				for _, d in ipairs(char:GetChildren()) do
					if d:IsA("Tool") or (d:IsA("Model") and string.find(string.lower(d.Name), "egg", 1, true)) then holding = true end
				end
				if holding then
					local pp = getPlotPos()
					if pp then
						local hrp = getHRP()
						if hrp and (hrp.Position - pp).Magnitude > 15 then tpTo(pp, 4) end
					end
				end
			end
		end
	end
end)

-- ---- ESP œufs
local eggHL = {}
bind(RunService.RenderStepped:Connect(function()
	if not Flags.EggESP then
		if Flags._eggOn then
			for _, h in pairs(eggHL) do pcall(function() h:Destroy() end) end
			eggHL = {}
			Flags._eggOn = false
		end
		return
	end
	Flags._eggOn = true
	local seen = {}
	for _, e in ipairs(EggCache) do
		if e.part and e.part.Parent then
			seen[e.part] = true
			local h = eggHL[e.part]
			if not h or not h.Parent then
				h = Instance.new("Highlight")
				h.Name = "VeniceEgg"
				h.Adornee = e.part
				h.FillColor = Color3.fromRGB(255,255,255)
				h.FillTransparency = 0.85
				h.OutlineColor = Color3.fromRGB(255,255,255)
				h.OutlineTransparency = 0
				h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
				h.Parent = e.part
				eggHL[e.part] = h
			end
		end
	end
	for part, h in pairs(eggHL) do
		if not seen[part] then pcall(function() h:Destroy() end) eggHL[part] = nil end
	end
end))

-- ---- UI SFE
do
	local s = NewSection(T_SFE, "Tir automatique")
	NewToggle(s, "Auto Shoot (œufs)", "AutoShoot", false)
	NewSelect(s, "Cible prioritaire", "TargetMode", {"Le plus proche","HP le plus bas","HP le plus haut","Plus gros"}, 1)
	NewSlider(s, "Portée de tir", "ShootRange", 30, 3000, 500, 0)
	NewSlider(s, "Cadence (s)", "ShootDelay", 0.02, 0.5, 0.06, 2)
	NewSelect(s, "Méthode de tir", "FireMethod", {"Auto (tool + clic)","Tool seulement","Click seulement"}, 1)
	NewInput(s, "Filtre nom d'œuf (vide = tous)", "EggFilter", "")
	NewToggle(s, "Ignorer les œufs du plot", "IgnorePlotEggs", true)
	NewToggle(s, "Aim assist (caméra verrouillée)", "AimLock", false)

	local s2 = NewSection(T_SFE, "Automatisation")
	NewToggle(s2, "Auto Place (poser les œufs)", "AutoPlace", false)
	NewToggle(s2, "Auto Hatch", "AutoHatch", false)
	NewToggle(s2, "Auto Collect (cash)", "AutoCollect", false)
	NewToggle(s2, "Auto Sell", "AutoSell", false)
	NewToggle(s2, "Auto Rebirth", "AutoRebirth", false)
	NewToggle(s2, "Auto Train (pad damage)", "AutoTrain", false)
	NewToggle(s2, "Auto Spin (roue)", "AutoSpin", false)
	NewToggle(s2, "Auto Claim (récompenses)", "AutoClaim", false)
	NewToggle(s2, "Instant Carry (retour auto au plot)", "InstantCarry", false)
	NewButton(s2, "FULL FARM : tout activer", function()
		for _, f in ipairs({"AutoShoot","AutoPlace","AutoHatch","AutoCollect","AutoTrain","AutoSell"}) do
			if Setters[f] then Setters[f](true) end
		end
		Notify("Full farm activé")
	end)
	NewButton(s2, "Tout désactiver", function()
		for _, f in ipairs({"AutoShoot","AutoPlace","AutoHatch","AutoCollect","AutoTrain","AutoSell","AutoRebirth","AutoSpin","AutoClaim","InstantCarry"}) do
			if Setters[f] then Setters[f](false) end
		end
		Notify("Automatisation coupée")
	end)

	local s3 = NewSection(T_SFE, "ESP & Téléports")
	NewToggle(s3, "Egg ESP", "EggESP", false)
	NewButton(s3, "TP vers l'œuf le plus proche", function()
		local e = getTargetEgg()
		if e then tpTo(e.part.Position, 8) Notify("TP œuf : "..e.name) else Notify("Aucun œuf en portée") end
	end)
	NewButton(s3, "Définir le plot (position actuelle)", function()
		local hrp = getHRP()
		if hrp then plotPos = hrp.Position Notify("Plot défini") end
	end)
	NewButton(s3, "TP au plot / home", function()
		local pp = getPlotPos()
		if pp then tpTo(pp, 4) else
			for _, b in ipairs(scanButtons(function(txt) return string.find(txt, "home", 1, true) end)) do clickButton(b.obj) end
			Notify("Plot introuvable — clic sur Home tenté")
		end
	end)
	NewButton(s3, "TP au Gun Shop", function()
		for _, b in ipairs(scanButtons(function(txt) return string.find(txt, "shop", 1, true) or string.find(txt, "gun", 1, true) end)) do clickButton(b.obj) return end
		Notify("Bouton shop introuvable")
	end)
	NewButton(s3, "TP au Damage Pad", function()
		for _, d in ipairs(Workspace:GetDescendants()) do
			if d:IsA("BasePart") and (string.find(string.lower(d.Name), "pad", 1, true) or string.find(string.lower(d.Name), "damage", 1, true)) then
				tpTo(d.Position, 4) Notify("TP pad") return
			end
		end
		Notify("Pad introuvable")
	end)
	NewButton(s3, "TP au Marchand / Merchant", function()
		for _, d in ipairs(Workspace:GetDescendants()) do
			if d:IsA("BasePart") and string.find(string.lower(d.Name), "merchant", 1, true) then
				tpTo(d.Position, 5) Notify("TP marchand") return
			end
		end
		Notify("Marchand introuvable")
	end)
end

--=====================================================================
-- 21. SCANNER
--=====================================================================
CurrentTab = T_SCAN
do
	local s = NewSection(T_SCAN, "Œufs détectés")
	local eggInfo = new("TextLabel", {Parent=s, Size=UDim2.new(1,0,0,20), BackgroundTransparency=1,
		Font=FONT2, TextSize=11, TextColor3=Theme.textDim, TextXAlignment=Enum.TextXAlignment.Left,
		Text="scan en cours..."})
	task.spawn(function()
		while true do
			task.wait(1)
			eggInfo.Text = string.format("œufs détectés : %d   |   plot : %s", #EggCache, getPlotPos() and "trouvé" or "inconnu")
		end
	end)

	local s2 = NewSection(T_SCAN, "ProximityPrompts")
	local addP, clearP = MakeList(s2, 140)
	NewButton(s2, "Scanner les prompts", function()
		clearP()
		local list = scanPrompts(function() return true end)
		for _, t in ipairs(list) do
			add("[prompt] "..t.text:sub(1,60), function() firePrompt(t.obj) Notify("Prompt tiré") end)
		end
		if #list == 0 then add("(aucun prompt)") end
	end)

	local s3 = NewSection(T_SCAN, "Boutons GUI")
	local addB, clearB = MakeList(s3, 160)
	NewButton(s3, "Scanner les boutons", function()
		clearB()
		local list = scanButtons(function() return true end)
		for _, t in ipairs(list) do
			add("[btn] "..t.text:sub(1,60), function() clickButton(t.obj) Notify("Clic : "..t.text:sub(1,20)) end)
		end
		if #list == 0 then add("(aucun bouton)") end
	end)

	local s4 = NewSection(T_SCAN, "Remotes")
	local addR, clearR = MakeList(s4, 160)
	NewButton(s4, "Scanner les RemoteEvents", function()
		clearR()
		local n = 0
		for _, d in ipairs(ReplicatedStorage:GetDescendants()) do
			if d:IsA("RemoteEvent") then
				n += 1
				if n <= 200 then
					add("[remote] "..d:GetFullName():gsub("ReplicatedStorage%.",""), function()
						pcall(function() d:FireServer() end)
						Notify("FireServer : "..d.Name)
					end)
				end
			end
		end
		add("total : "..n.." RemoteEvents")
	end)

	local spyOn = false
	local spyLog = {}
	local addS, clearS = MakeList(s4, 160)
	NewButton(s4, "Démarrer / arrêter le Remote Spy", function()
		if spyOn then
			spyOn = false
			Notify("Spy arrêté")
			return
		end
		if not hookmetamethod then Notify("hookmetamethod indisponible") return end
		spyOn = true
		local mt = getrawmetatable(game)
		local old = mt.__namecall
		setreadonly(mt, false)
		mt.__namecall = newcclosure(function(self, ...)
			local method = getnamecallmethod()
			if spyOn and (method == "FireServer" or method == "InvokeServer") then
				local args = {...}
				local parts = {}
				for i = 1, math.min(#args, 4) do
					local v = args[i]
					parts[#parts+1] = type(v) == "table" and "table" or tostring(v):sub(1,20)
				end
				spyLog[#spyLog+1] = string.format("%s : %s(%s)", method, tostring(self):gsub("ReplicatedStorage%.",""), table.concat(parts, ", "))
				if #spyLog > 60 then table.remove(spyLog, 1) end
			end
			return old(self, ...)
		end)
		setreadonly(mt, true)
		Notify("Spy démarré")
	end)
	task.spawn(function()
		while true do
			task.wait(0.5)
			if spyOn and #spyLog > 0 then
				clearS()
				for i = math.max(1, #spyLog - 25), #spyLog do
					add(spyLog[i] or "")
				end
			end
		end
	end)

	local s5 = NewSection(T_SCAN, "Valeurs joueur")
	local addV, clearV = MakeList(s5, 140)
	NewButton(s5, "Scanner les valeurs (leaderstats)", function()
		clearV()
		local n = 0
		for _, d in ipairs(LP:GetDescendants()) do
			if d:IsA("ValueBase") and not d:IsA("ObjectValue") then
				n += 1
				add(string.format("%s = %s", d:GetFullName():gsub("Players%.LocalPlayer%.",""), tostring(d.Value)), function()
					if setclipboard then pcall(setclipboard, tostring(d.Value)) end
				end)
			end
		end
		if n == 0 then add("(aucune valeur)") end
	end)
end

--=====================================================================
-- 22. SETTINGS
--=====================================================================
CurrentTab = T_SET
do
	local s = NewSection(T_SET, "Interface")
	NewToggle(s, "Thème clair", "LightMode", false, function(on)
		applyTheme(on)
	end)
	NewToggle(s, "Watermark", "Watermark", true, function(on)
		Watermark.Visible = on
	end)
	NewButton(s, "Rebind touche du menu (actuelle : "..Flags.MenuKey..")", function()
		Capturing = {menu = true}
		keyPill.Text = "..."
		Notify("Appuie sur une touche...")
	end)
	NewButton(s, "Réinitialiser la position de la fenêtre", function()
		Window.Position = UDim2.fromScale(0.5, 0.5)
	end)

	local s2 = NewSection(T_SET, "Background")
	NewToggle(s2, "Background actif", "BGOn", true, function(on)
		BG.Visible = on and (Root.Visible or not Flags.BGOnlyWhenOpen)
	end)
	NewToggle(s2, "Visible seulement menu ouvert", "BGOnlyWhenOpen", false, function(on)
		BG.Visible = (not on) or Root.Visible
	end)
	NewToggle(s2, "Diaporama auto (images)", "BGCycle", true)
	NewSlider(s2, "Vitesse du diaporama", "BGSpeed", 0.2, 3, 1, 1)
	NewSlider(s2, "Assombrissement (0 = couleurs vives)", "BGVeil", 0, 0.9, 0.45, 2)
	NewButton(s2, "Image suivante", function()
		local ok = pcall(function()
			local ids = collectImages()
			bgFront.Image = "rbxassetid://"..ids[math.random(#ids)]
			kenBurns(bgFront, 12)
		end)
		if not ok then Notify("Échec") end
	end)
	NewInput(s2, "IDs custom (séparés par des virgules)", "BGCustom", "", function(v)
		CustomBG = {}
		for id in string.gmatch(v, "%d+") do CustomBG[#CustomBG+1] = tonumber(id) end
		if #CustomBG > 0 then
			bgFront.Image = "rbxassetid://"..CustomBG[1]
			Notify(#CustomBG.." image(s) custom chargée(s)")
		end
	end)

	local s3 = NewSection(T_SET, "Config")
	NewToggle(s3, "Sauvegarde auto au unload", "AutoSave", true)
	NewButton(s3, "Sauvegarder la config", function() SaveConfig() end)
	NewButton(s3, "Charger la config", function() LoadConfig() end)
	NewButton(s3, "Réinitialiser la config", function()
		for flag, setter in pairs(Setters) do
			Flags[flag] = false
		end
		Notify("Config réinitialisée (rejoins pour appliquer)")
	end)

	local s4 = NewSection(T_SET, "Infos")
	local info = new("TextLabel", {Parent=s4, Size=UDim2.new(1,0,0,60), BackgroundTransparency=1,
		Font=FONT2, TextSize=11, TextColor3=Theme.textDim, TextXAlignment=Enum.TextXAlignment.Left,
		TextWrapped=true, Text="", TextYAlignment=Enum.TextYAlignment.Top})
	info.Text = string.format("%s v%s\nJeu : %s\nPlaceId : %d\nUtilisateur : %s\n\nTouche menu : %s",
		HUB_NAME, HUB_VERSION, game.PlaceId == 135911818477576 and "Shoot For Eggs" or game.Name,
		game.PlaceId, LP.Name, Flags.MenuKey)
	NewButton(s4, "Décharger le script", function()
		if GENV.VeniceHub then GENV.VeniceHub.Destroy() end
	end)
end

--=====================================================================
-- 23. CONFIG SAVE / LOAD
--=====================================================================
function SaveConfig()
	if not writefile then Notify("writefile indisponible") return end
	local data = {version = HUB_VERSION, flags = {}, binds = {}, waypoints = {}}
	for k, v in pairs(Flags) do
		if type(v) == "boolean" or type(v) == "number" or type(v) == "string" then
			if k:sub(1,1) ~= "_" then data.flags[k] = v end
		end
	end
	for k, v in pairs(Binds) do if v then data.binds[k] = v.Name end end
	for n, p in pairs(waypoints) do data.waypoints[n] = {p.X, p.Y, p.Z} end
	pcall(function() writefile(CONFIG_FILE, HttpService:JSONEncode(data)) end)
	Notify("Config sauvegardée")
end

function LoadConfig()
	if not (readfile and isfile) then Notify("readfile indisponible") return end
	if not isfile(CONFIG_FILE) then Notify("Aucune config trouvée") return end
	local ok, data = pcall(function() return HttpService:JSONDecode(readfile(CONFIG_FILE)) end)
	if not ok or not data then Notify("Config illisible") return end
	for flag, val in pairs(data.flags or {}) do
		if Setters[flag] then
			pcall(Setters[flag], val, true)
		else
			Flags[flag] = val
		end
	end
	for flag, keyName in pairs(data.binds or {}) do
		local kc = Enum.KeyCode[keyName]
		if kc then Binds[flag] = kc end
	end
	for n, p in pairs(data.waypoints or {}) do
		waypoints[n] = Vector3.new(p[1], p[2], p[3])
	end
	if RefreshWP then pcall(RefreshWP) end
	Notify("Config chargée")
end

--=====================================================================
-- 24. BOUCLES GLOBALES (FPS / PING / STATUS)
--=====================================================================
local frames, fpsT = 0, tick()
local fps, ping = 0, 0
bind(RunService.RenderStepped:Connect(function()
	frames += 1
	if tick() - fpsT >= 1 then
		fps = frames
		frames = 0
		fpsT = tick()
		pcall(function()
			local v = Stats.Network.ServerStatsItem["Data Ping"]:GetValue()
			ping = math.floor(v)
		end)
	end
end))

task.spawn(function()
	while true do
		task.wait(0.5)
		statusR.Text = string.format("%d fps | %d ms", fps, ping)
		local actifs = {}
		for f, v in pairs(Flags) do
			if v == true and f:sub(1,1) ~= "_" and f ~= "Notifications" and f ~= "Watermark" and f ~= "AutoSave" and f ~= "AntiAFK" and f ~= "BGCycle" and f ~= "BGOn" then
				actifs[#actifs+1] = f
			end
		end
		statusL.Text = #actifs > 0 and ("actifs : "..table.concat(actifs, ", "):sub(1, 80)) or "idle"
		wmLabel.Text = string.format("%s v%s  •  %s  •  %d fps  •  %d ms", HUB_NAME, HUB_VERSION, LP.Name, fps, ping)
	end
end)

--=====================================================================
-- 25. INIT
--=====================================================================
CurrentTab = T_MOVE
Tabs[T_MOVE].button.MouseButton1Click:Fire()
Sidebar.Visible = true

Watermark.Visible = true
Notify(HUB_NAME.." v"..HUB_VERSION.." chargé", 4)
if game.PlaceId == 135911818477576 then
	Notify("Shoot For Eggs détecté — onglet dédié dispo", 5)
end

-- autoload config
task.spawn(function()
	task.wait(0.6)
	if readfile and isfile and isfile(CONFIG_FILE) then
		pcall(LoadConfig)
	end
end)

-- auto update
task.spawn(function()
	if not HUB_VER_URL or HUB_VER_URL == "" then return end
	local ok, res = pcall(function() return game:HttpGet(HUB_VER_URL) end)
	if ok and res and not string.find(res, HUB_VERSION, 1, true) then
		Notify("Mise à jour dispo : "..tostring(res):sub(1, 20), 6)
	end
end)

--=====================================================================
-- 26. DESTROY
--=====================================================================
local function Destroy()
	pcall(function() GENV.VeniceHub = nil end)
	bgRunning = false
	for _, c in ipairs(Conn) do pcall(function() c:Disconnect() end) end
	pcall(function()
		for _, h in pairs(eggHL) do h:Destroy() end
	end)
	pcall(function()
		for _, plr in ipairs(Players:GetPlayers()) do
			if plr.Character then
				local b = plr.Character:FindFirstChild("VeniceName")
				if b then b:Destroy() end
				local h = plr.Character:FindFirstChild("VeniceESP")
				if h then h:Destroy() end
			end
		end
	end)
	pcall(function() Screen:Destroy() end)
	pcall(function() Workspace.Gravity = 196.2 end)
	pcall(function() if setfpscap then setfpscap(60) end end)
	print("["..HUB_NAME.."] déchargé.")
end

GENV.VeniceHub = {
	Destroy = Destroy,
	Flags = Flags,
	Notify = Notify,
	Version = HUB_VERSION,
}

print("["..HUB_NAME.."] v"..HUB_VERSION.." chargé — touche : "..Flags.MenuKey)
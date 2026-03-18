--[[
╔══════════════════════════════════════════════════════════════════════════════╗
║                         NEXUS UI LIBRARY v1.0                               ║
║                   Professional Roblox UI Framework                          ║
║                                                                              ║
║  Features: Windows, Buttons, Toggles, Sliders, Dropdowns, TextBoxes,       ║
║            Checkboxes, ProgressBars, ScrollFrames, Tabs, Modals,            ║
║            Toasts, Accordions, ColorPicker, Stepper, Radio, Tooltip,        ║
║            ContextMenu, LoadingSpinner                                       ║
║                                                                              ║
║  Devices: PC (Mouse), Mobile/Tablet (Touch), Console (Gamepad)              ║
║  Author:  NexusUI Framework                                                  ║
╚══════════════════════════════════════════════════════════════════════════════╝
]]

-- ============================================================
--  SERVICES & CORE DEPENDENCIES
-- ============================================================
local TweenService       = game:GetService("TweenService")
local UserInputService   = game:GetService("UserInputService")
local RunService         = game:GetService("RunService")
local GuiService         = game:GetService("GuiService")
local TextService        = game:GetService("TextService")
local HttpService        = game:GetService("HttpService")

-- ============================================================
--  TYPE DEFINITIONS  (Luau strict-mode compatible)
-- ============================================================
export type Color3Value   = Color3
export type UDim2Value    = UDim2
export type FontValue     = Enum.Font

export type ThemeConfig = {
	-- Base colors
	Background:        Color3,
	BackgroundSecond:  Color3,
	Surface:           Color3,
	SurfaceHover:      Color3,
	Border:            Color3,
	BorderFocus:       Color3,

	-- Text
	TextPrimary:       Color3,
	TextSecondary:     Color3,
	TextDisabled:      Color3,
	TextOnAccent:      Color3,

	-- Accent
	Accent:            Color3,
	AccentHover:       Color3,
	AccentPress:       Color3,

	-- Status
	Success:           Color3,
	Warning:           Color3,
	Error:             Color3,
	Info:              Color3,

	-- Window
	TitleBar:          Color3,
	TitleText:         Color3,
	WindowShadow:      Color3,

	-- Misc
	Overlay:           Color3,
	ScrollBar:         Color3,
	CornerRadius:      UDim,
	Font:              Enum.Font,
	FontBold:          Enum.Font,
	TextSize:          number,
	TitleSize:         number,
	AnimSpeed:         number,   -- seconds (0.12 = fast, 0.25 = normal)
	EasingStyle:       Enum.EasingStyle,
	EasingDirection:   Enum.EasingDirection,
}

export type ButtonOptions = {
	Text:      string?,
	Size:      UDim2?,
	Icon:      string?,   -- rbxassetid://
	Variant:   string?,   -- "primary"|"secondary"|"ghost"|"danger"
	Disabled:  boolean?,
	OnClick:   (() -> ())?
}

export type WindowOptions = {
	Title:          string?,
	Size:           UDim2?,
	Position:       UDim2?,
	Resizable:      boolean?,
	MinSize:        Vector2?,
	SnapToEdge:     boolean?,
	CloseConfirm:   boolean?,
	Icon:           string?,
}

-- ============================================================
--  UTILITIES
-- ============================================================
local Utils = {}

function Utils.tween(instance: Instance, time: number, goals: {[string]: any}, style: Enum.EasingStyle?, dir: Enum.EasingDirection?): Tween
	local info = TweenInfo.new(
		time,
		style  or Enum.EasingStyle.Quart,
		dir    or Enum.EasingDirection.Out
	)
	local t = TweenService:Create(instance, info, goals)
	t:Play()
	return t
end

function Utils.lerp(a: number, b: number, t: number): number
	return a + (b - a) * t
end

function Utils.clamp(v: number, min: number, max: number): number
	return math.max(min, math.min(max, v))
end

function Utils.round(n: number, decimals: number?): number
	local factor = 10 ^ (decimals or 0)
	return math.floor(n * factor + 0.5) / factor
end

function Utils.isMobile(): boolean
	return UserInputService.TouchEnabled and not UserInputService.MouseEnabled
end

function Utils.isConsole(): boolean
	return UserInputService.GamepadEnabled and not UserInputService.MouseEnabled and not UserInputService.TouchEnabled
end

function Utils.isPC(): boolean
	return UserInputService.MouseEnabled
end

function Utils.getDeviceType(): string
	if Utils.isConsole() then return "Console"
	elseif Utils.isMobile() then return "Mobile"
	else return "PC" end
end

function Utils.getViewport(): Vector2
	return workspace.CurrentCamera.ViewportSize
end

function Utils.scaleFactor(): number
	local vp = Utils.getViewport()
	local base = 1080
	return math.clamp(vp.Y / base, 0.5, 2.0)
end

function Utils.newInstance<T>(className: string, props: {[string]: any}, parent: Instance?): T
	local inst = Instance.new(className)
	for k, v in pairs(props) do
		(inst :: any)[k] = v
	end
	if parent then inst.Parent = parent end
	return (inst :: any) :: T
end

function Utils.destroySafe(inst: Instance?)
	if inst and inst.Parent then
		inst:Destroy()
	end
end

function Utils.connectSafe(signal: RBXScriptSignal, fn: (...any) -> ()): RBXScriptConnection
	return signal:Connect(fn)
end

function Utils.hexToColor(hex: string): Color3
	hex = hex:gsub("#", "")
	local r = tonumber(hex:sub(1,2), 16) or 0
	local g = tonumber(hex:sub(3,4), 16) or 0
	local b = tonumber(hex:sub(5,6), 16) or 0
	return Color3.fromRGB(r, g, b)
end

function Utils.colorToHex(c: Color3): string
	return string.format("%02X%02X%02X",
		math.floor(c.R * 255),
		math.floor(c.G * 255),
		math.floor(c.B * 255))
end

function Utils.hsvToColor(h: number, s: number, v: number): Color3
	return Color3.fromHSV(h, s, v)
end

-- ============================================================
--  EVENT EMITTER  (lightweight signal system)
-- ============================================================
local EventEmitter = {}
EventEmitter.__index = EventEmitter

function EventEmitter.new()
	return setmetatable({ _listeners = {} }, EventEmitter)
end

function EventEmitter:on(event: string, fn: (...any) -> ()): () -> ()
	if not self._listeners[event] then
		self._listeners[event] = {}
	end
	local id = HttpService:GenerateGUID(false)
	self._listeners[event][id] = fn
	return function()
		if self._listeners[event] then
			self._listeners[event][id] = nil
		end
	end
end

function EventEmitter:emit(event: string, ...: any)
	if self._listeners[event] then
		for _, fn in pairs(self._listeners[event]) do
			task.spawn(fn, ...)
		end
	end
end

function EventEmitter:once(event: string, fn: (...any) -> ())
	local unsub: () -> ()
	unsub = self:on(event, function(...)
		unsub()
		fn(...)
	end)
end

-- ============================================================
--  THEME MANAGER
-- ============================================================
local ThemeManager = {}
ThemeManager.__index = ThemeManager

ThemeManager.Presets = {
	Dark = {
		Background       = Color3.fromRGB(15,  15,  20),
		BackgroundSecond = Color3.fromRGB(22,  22,  30),
		Surface          = Color3.fromRGB(30,  30,  42),
		SurfaceHover     = Color3.fromRGB(42,  42,  58),
		Border           = Color3.fromRGB(55,  55,  75),
		BorderFocus      = Color3.fromRGB(120, 100, 255),
		TextPrimary      = Color3.fromRGB(235, 235, 245),
		TextSecondary    = Color3.fromRGB(155, 155, 175),
		TextDisabled     = Color3.fromRGB(80,  80,  100),
		TextOnAccent     = Color3.fromRGB(255, 255, 255),
		Accent           = Color3.fromRGB(100, 80,  255),
		AccentHover      = Color3.fromRGB(120, 100, 255),
		AccentPress      = Color3.fromRGB(80,  60,  220),
		Success          = Color3.fromRGB(60,  210, 120),
		Warning          = Color3.fromRGB(255, 180, 50),
		Error            = Color3.fromRGB(255, 75,  75),
		Info             = Color3.fromRGB(75,  175, 255),
		TitleBar         = Color3.fromRGB(20,  20,  28),
		TitleText        = Color3.fromRGB(235, 235, 245),
		WindowShadow     = Color3.fromRGB(0,   0,   0),
		Overlay          = Color3.fromRGB(0,   0,   0),
		ScrollBar        = Color3.fromRGB(70,  70,  95),
		CornerRadius     = UDim.new(0, 8),
		Font             = Enum.Font.GothamMedium,
		FontBold         = Enum.Font.GothamBold,
		TextSize         = 14,
		TitleSize        = 15,
		AnimSpeed        = 0.18,
		EasingStyle      = Enum.EasingStyle.Quart,
		EasingDirection  = Enum.EasingDirection.Out,
	},
	Light = {
		Background       = Color3.fromRGB(248, 248, 252),
		BackgroundSecond = Color3.fromRGB(240, 240, 248),
		Surface          = Color3.fromRGB(255, 255, 255),
		SurfaceHover     = Color3.fromRGB(235, 235, 245),
		Border           = Color3.fromRGB(210, 210, 225),
		BorderFocus      = Color3.fromRGB(100, 80,  255),
		TextPrimary      = Color3.fromRGB(20,  20,  35),
		TextSecondary    = Color3.fromRGB(95,  95,  115),
		TextDisabled     = Color3.fromRGB(175, 175, 195),
		TextOnAccent     = Color3.fromRGB(255, 255, 255),
		Accent           = Color3.fromRGB(100, 80,  255),
		AccentHover      = Color3.fromRGB(120, 100, 255),
		AccentPress      = Color3.fromRGB(80,  60,  220),
		Success          = Color3.fromRGB(40,  185, 100),
		Warning          = Color3.fromRGB(230, 155, 30),
		Error            = Color3.fromRGB(220, 50,  50),
		Info             = Color3.fromRGB(50,  150, 235),
		TitleBar         = Color3.fromRGB(255, 255, 255),
		TitleText        = Color3.fromRGB(20,  20,  35),
		WindowShadow     = Color3.fromRGB(0,   0,   0),
		Overlay          = Color3.fromRGB(0,   0,   0),
		ScrollBar        = Color3.fromRGB(190, 190, 210),
		CornerRadius     = UDim.new(0, 8),
		Font             = Enum.Font.GothamMedium,
		FontBold         = Enum.Font.GothamBold,
		TextSize         = 14,
		TitleSize        = 15,
		AnimSpeed        = 0.18,
		EasingStyle      = Enum.EasingStyle.Quart,
		EasingDirection  = Enum.EasingDirection.Out,
	},
	Ocean = {
		Background       = Color3.fromRGB(8,   18,  35),
		BackgroundSecond = Color3.fromRGB(10,  24,  45),
		Surface          = Color3.fromRGB(14,  32,  58),
		SurfaceHover     = Color3.fromRGB(20,  44,  78),
		Border           = Color3.fromRGB(30,  65,  110),
		BorderFocus      = Color3.fromRGB(50,  185, 255),
		TextPrimary      = Color3.fromRGB(215, 235, 255),
		TextSecondary    = Color3.fromRGB(120, 165, 215),
		TextDisabled     = Color3.fromRGB(60,  90,  130),
		TextOnAccent     = Color3.fromRGB(255, 255, 255),
		Accent           = Color3.fromRGB(30,  155, 255),
		AccentHover      = Color3.fromRGB(50,  185, 255),
		AccentPress      = Color3.fromRGB(20,  125, 215),
		Success          = Color3.fromRGB(50,  215, 130),
		Warning          = Color3.fromRGB(255, 190, 60),
		Error            = Color3.fromRGB(255, 80,  80),
		Info             = Color3.fromRGB(75,  185, 255),
		TitleBar         = Color3.fromRGB(10,  22,  42),
		TitleText        = Color3.fromRGB(215, 235, 255),
		WindowShadow     = Color3.fromRGB(0,   0,   0),
		Overlay          = Color3.fromRGB(0,   0,   0),
		ScrollBar        = Color3.fromRGB(40,  80,  130),
		CornerRadius     = UDim.new(0, 10),
		Font             = Enum.Font.GothamMedium,
		FontBold         = Enum.Font.GothamBold,
		TextSize         = 14,
		TitleSize        = 15,
		AnimSpeed        = 0.20,
		EasingStyle      = Enum.EasingStyle.Quint,
		EasingDirection  = Enum.EasingDirection.Out,
	},
}

function ThemeManager.new(preset: string?)
	local self = setmetatable({}, ThemeManager)
	self._theme     = {}
	self._emitter   = EventEmitter.new()
	self:apply(preset or "Dark")
	return self
end

function ThemeManager:apply(preset: string | ThemeConfig)
	if type(preset) == "string" then
		local p = ThemeManager.Presets[preset]
		assert(p, "Unknown theme preset: " .. tostring(preset))
		for k, v in pairs(p) do self._theme[k] = v end
	else
		for k, v in pairs(preset) do self._theme[k] = v end
	end
	self._emitter:emit("Changed", self._theme)
end

function ThemeManager:get(): ThemeConfig
	return self._theme
end

function ThemeManager:onChange(fn: (ThemeConfig) -> ()): () -> ()
	return self._emitter:on("Changed", fn)
end

-- ============================================================
--  DRAG MANAGER  (PC + Touch + Console)
-- ============================================================
local DragManager = {}
DragManager.__index = DragManager

function DragManager.new(frame: GuiObject, handle: GuiObject?, opts: {[string]: any}?)
	local self   = setmetatable({}, DragManager)
	opts         = opts or {}
	self._frame  = frame
	self._handle = handle or frame
	self._conns  = {}
	self._opts   = {
		bounds       = opts.bounds,         -- GuiObject or nil
		snapToEdge   = opts.snapToEdge   or false,
		snapThreshold= opts.snapThreshold or 20,
		momentum     = opts.momentum      ~= false,
		damping      = opts.damping       or 0.85,
	}
	self._dragging  = false
	self._velocity  = Vector2.new(0, 0)
	self._lastPos   = Vector2.new(0, 0)
	self._emitter   = EventEmitter.new()
	self:_setup()
	return self
end

function DragManager:_setup()
	local frame  = self._frame
	local handle = self._handle

	local function getAbsPos(obj: GuiObject): Vector2
		return obj.AbsolutePosition
	end

	local function getScreenSize(): Vector2
		return Utils.getViewport()
	end

	local function clampToScreen(pos: Vector2): Vector2
		local size   = frame.AbsoluteSize
		local screen = getScreenSize()
		local inset  = GuiService:GetGuiInset()
		local minX   = 0
		local minY   = 0
		local maxX   = screen.X - size.X
		local maxY   = screen.Y - size.Y - inset.Y
		return Vector2.new(
			Utils.clamp(pos.X, minX, maxX),
			Utils.clamp(pos.Y, minY, maxY)
		)
	end

	local function setFramePos(pos: Vector2)
		local clamped = clampToScreen(pos)
		frame.Position = UDim2.fromOffset(clamped.X, clamped.Y)
	end

	local function snapEdge(pos: Vector2): Vector2
		if not self._opts.snapToEdge then return pos end
		local screen    = getScreenSize()
		local size      = frame.AbsoluteSize
		local threshold = self._opts.snapThreshold
		local x, y     = pos.X, pos.Y
		if x < threshold then x = 0
		elseif screen.X - size.X - x < threshold then x = screen.X - size.X end
		if y < threshold then y = 0
		elseif screen.Y - size.Y - y < threshold then y = screen.Y - size.Y end
		return Vector2.new(x, y)
	end

	-- === PC Mouse drag ===
	local dragStart: Vector2
	local startPos: UDim2

	local function beginDrag(input: InputObject)
		self._dragging = true
		self._velocity = Vector2.new(0, 0)
		dragStart      = input.Position
		startPos       = frame.Position
		self._emitter:emit("DragStart")
	end

	local function updateDrag(input: InputObject)
		if not self._dragging then return end
		local delta = Vector2.new(input.Position.X - dragStart.X, input.Position.Y - dragStart.Y)
		self._velocity = Vector2.new(input.Position.X - self._lastPos.X, input.Position.Y - self._lastPos.Y)
		self._lastPos  = Vector2.new(input.Position.X, input.Position.Y)
		local raw = Vector2.new(startPos.X.Offset + delta.X, startPos.Y.Offset + delta.Y)
		setFramePos(raw)
	end

	local function endDrag()
		if not self._dragging then return end
		self._dragging = false
		-- Momentum
		if self._opts.momentum then
			local vel = self._velocity
			local conn: RBXScriptConnection
			conn = RunService.Heartbeat:Connect(function(dt)
				if vel.Magnitude < 0.5 then
					conn:Disconnect()
					local finalPos = frame.AbsolutePosition
					setFramePos(snapEdge(finalPos))
					return
				end
				vel        = vel * self._opts.damping
				local cur  = frame.AbsolutePosition
				setFramePos(Vector2.new(cur.X + vel.X, cur.Y + vel.Y))
			end)
		else
			setFramePos(snapEdge(frame.AbsolutePosition))
		end
		self._emitter:emit("DragEnd")
	end

	-- Mouse
	table.insert(self._conns, handle.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or
		   input.UserInputType == Enum.UserInputType.Touch then
			beginDrag(input)
		end
	end))

	table.insert(self._conns, UserInputService.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement or
		   input.UserInputType == Enum.UserInputType.Touch then
			updateDrag(input)
		end
	end))

	table.insert(self._conns, UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or
		   input.UserInputType == Enum.UserInputType.Touch then
			endDrag()
		end
	end))

	-- Console gamepad (left stick moves window)
	local GAMEPAD_SPEED = 8
	table.insert(self._conns, RunService.Heartbeat:Connect(function(dt)
		if not UserInputService.GamepadEnabled then return end
		local state = UserInputService:GetGamepadState(Enum.UserInputType.Gamepad1)
		for _, s in ipairs(state) do
			if s.KeyCode == Enum.KeyCode.Thumbstick1 and s.Position.Magnitude > 0.2 then
				local cur = frame.AbsolutePosition
				local nx  = cur.X + s.Position.X * GAMEPAD_SPEED
				local ny  = cur.Y - s.Position.Y * GAMEPAD_SPEED
				setFramePos(Vector2.new(nx, ny))
			end
		end
	end))
end

function DragManager:onDragStart(fn: () -> ()): () -> ()
	return self._emitter:on("DragStart", fn)
end

function DragManager:onDragEnd(fn: () -> ()): () -> ()
	return self._emitter:on("DragEnd", fn)
end

function DragManager:destroy()
	for _, c in ipairs(self._conns) do c:Disconnect() end
	self._conns = {}
end

-- ============================================================
--  BASE COMPONENT  (all UI elements inherit from this)
-- ============================================================
local BaseComponent = {}
BaseComponent.__index = BaseComponent

function BaseComponent.new()
	local self      = setmetatable({}, BaseComponent)
	self._conns     = {}
	self._emitter   = EventEmitter.new()
	self._enabled   = true
	self._visible   = true
	self.Instance   = nil :: GuiObject?   -- set by subclass
	return self
end

function BaseComponent:on(event: string, fn: (...any) -> ()): () -> ()
	return self._emitter:on(event, fn)
end

function BaseComponent:once(event: string, fn: (...any) -> ())
	self._emitter:once(event, fn)
end

function BaseComponent:emit(event: string, ...: any)
	self._emitter:emit(event, ...)
end

function BaseComponent:setEnabled(v: boolean)
	self._enabled = v
	self:emit("EnabledChanged", v)
end

function BaseComponent:setVisible(v: boolean)
	self._visible = v
	if self.Instance then
		(self.Instance :: any).Visible = v
	end
	self:emit("VisibilityChanged", v)
end

function BaseComponent:_conn(c: RBXScriptConnection)
	table.insert(self._conns, c)
end

function BaseComponent:destroy()
	for _, c in ipairs(self._conns) do c:Disconnect() end
	self._conns = {}
	if self.Instance then
		Utils.destroySafe(self.Instance)
		self.Instance = nil
	end
	self._emitter = EventEmitter.new()
end

-- ============================================================
--  TOOLTIP SYSTEM
-- ============================================================
local TooltipSystem = {}
TooltipSystem.__index = TooltipSystem

function TooltipSystem.new(theme: ThemeConfig, screenGui: ScreenGui)
	local self       = setmetatable({}, TooltipSystem)
	self._theme      = theme
	self._gui        = screenGui
	self._active     = nil
	self._frame      = nil :: Frame?
	self._showThread = nil :: thread?
	self:_build()
	return self
end

function TooltipSystem:_build()
	local T = self._theme
	local frame = Utils.newInstance("Frame", {
		Name            = "NexusTooltip",
		Size            = UDim2.fromOffset(10, 10),
		BackgroundColor3= T.Surface,
		BorderSizePixel = 0,
		ZIndex          = 100,
		Visible         = false,
		AutomaticSize   = Enum.AutomaticSize.XY,
	}, self._gui)
	Utils.newInstance("UICorner",    { CornerRadius = UDim.new(0,6) }, frame)
	Utils.newInstance("UIStroke",    { Color = T.Border, Thickness = 1 }, frame)
	Utils.newInstance("UIPadding",   {
		PaddingLeft   = UDim.new(0, 10),
		PaddingRight  = UDim.new(0, 10),
		PaddingTop    = UDim.new(0, 6),
		PaddingBottom = UDim.new(0, 6),
	}, frame)
	local label = Utils.newInstance("TextLabel", {
		Name            = "Text",
		Size            = UDim2.fromOffset(0, 0),
		AutomaticSize   = Enum.AutomaticSize.XY,
		BackgroundTransparency = 1,
		TextColor3      = T.TextPrimary,
		Font            = T.Font,
		TextSize        = 13,
		RichText        = true,
		ZIndex          = 101,
	}, frame)
	self._frame = frame
	self._label = label
end

function TooltipSystem:attach(target: GuiObject, text: string, delay: number?)
	delay = delay or 0.6
	local enterConn, leaveConn, moveConn: RBXScriptConnection

	enterConn = target.MouseEnter:Connect(function()
		if self._showThread then task.cancel(self._showThread) end
		self._showThread = task.delay(delay, function()
			if self._frame then
				self._label.Text = text
				self._frame.Visible = true
			end
		end)
	end)

	moveConn = target.MouseMoved:Connect(function(x, y)
		if self._frame then
			local offset = Vector2.new(12, 8)
			local vp     = Utils.getViewport()
			local size   = self._frame.AbsoluteSize
			local px     = x + offset.X
			local py     = y + offset.Y
			if px + size.X > vp.X then px = x - size.X - offset.X end
			if py + size.Y > vp.Y then py = y - size.Y - offset.Y end
			self._frame.Position = UDim2.fromOffset(px, py)
		end
	end)

	leaveConn = target.MouseLeave:Connect(function()
		if self._showThread then task.cancel(self._showThread) end
		if self._frame then self._frame.Visible = false end
	end)

	return function()
		enterConn:Disconnect()
		leaveConn:Disconnect()
		moveConn:Disconnect()
	end
end

function TooltipSystem:destroy()
	Utils.destroySafe(self._frame)
end

-- ============================================================
--  NOTIFICATION / TOAST SYSTEM
-- ============================================================
local NotificationSystem = {}
NotificationSystem.__index = NotificationSystem

function NotificationSystem.new(theme: ThemeConfig, screenGui: ScreenGui)
	local self       = setmetatable({}, NotificationSystem)
	self._theme      = theme
	self._gui        = screenGui
	self._queue      = {}
	self._container  = nil :: Frame?
	self:_build()
	return self
end

function NotificationSystem:_build()
	local T = self._theme
	local container = Utils.newInstance("Frame", {
		Name            = "NexusNotifications",
		Size            = UDim2.fromOffset(320, 0),
		Position        = UDim2.new(1, -330, 1, -20),
		AnchorPoint     = Vector2.new(0, 1),
		BackgroundTransparency = 1,
		AutomaticSize   = Enum.AutomaticSize.Y,
		ZIndex          = 90,
	}, self._gui)
	Utils.newInstance("UIListLayout", {
		SortOrder       = Enum.SortOrder.LayoutOrder,
		VerticalAlignment= Enum.VerticalAlignment.Bottom,
		Padding         = UDim.new(0, 8),
	}, container)
	self._container = container
end

function NotificationSystem:show(opts: {
	Title:    string?,
	Message:  string,
	Type:     string?,   -- "success"|"error"|"warning"|"info"
	Duration: number?,
	Icon:     string?,
})
	local T        = self._theme
	local kind     = opts.Type or "info"
	local duration = opts.Duration or 4
	local accent   = ({
		success = T.Success,
		error   = T.Error,
		warning = T.Warning,
		info    = T.Info,
	})[kind] or T.Accent

	-- Toast frame
	local toast = Utils.newInstance("Frame", {
		Name            = "Toast_" .. kind,
		Size            = UDim2.fromOffset(310, 0),
		AutomaticSize   = Enum.AutomaticSize.Y,
		BackgroundColor3= T.Surface,
		BorderSizePixel = 0,
		ClipsDescendants= true,
		ZIndex          = 91,
	}, self._container)
	Utils.newInstance("UICorner",  { CornerRadius = UDim.new(0,10) }, toast)
	Utils.newInstance("UIStroke",  { Color = T.Border, Thickness = 1 }, toast)

	-- Colored accent bar
	Utils.newInstance("Frame", {
		Name            = "AccentBar",
		Size            = UDim2.new(0, 4, 1, 0),
		BackgroundColor3= accent,
		BorderSizePixel = 0,
	}, toast)

	local inner = Utils.newInstance("Frame", {
		Name            = "Inner",
		Size            = UDim2.new(1, -16, 1, 0),
		Position        = UDim2.fromOffset(12, 0),
		BackgroundTransparency = 1,
		AutomaticSize   = Enum.AutomaticSize.Y,
	}, toast)
	Utils.newInstance("UIPadding", {
		PaddingTop    = UDim.new(0, 12),
		PaddingBottom = UDim.new(0, 12),
		PaddingRight  = UDim.new(0, 8),
	}, inner)
	Utils.newInstance("UIListLayout", {
		SortOrder       = Enum.SortOrder.LayoutOrder,
		Padding         = UDim.new(0, 4),
	}, inner)

	if opts.Title then
		Utils.newInstance("TextLabel", {
			Name            = "Title",
			Size            = UDim2.new(1, 0, 0, 0),
			AutomaticSize   = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1,
			Text            = opts.Title,
			Font            = T.FontBold,
			TextSize        = T.TextSize + 1,
			TextColor3      = T.TextPrimary,
			TextXAlignment  = Enum.TextXAlignment.Left,
			LayoutOrder     = 1,
			ZIndex          = 92,
		}, inner)
	end

	Utils.newInstance("TextLabel", {
		Name            = "Message",
		Size            = UDim2.new(1, 0, 0, 0),
		AutomaticSize   = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		Text            = opts.Message,
		Font            = T.Font,
		TextSize        = T.TextSize,
		TextColor3      = T.TextSecondary,
		TextXAlignment  = Enum.TextXAlignment.Left,
		TextWrapped     = true,
		LayoutOrder     = 2,
		ZIndex          = 92,
		RichText        = true,
	}, inner)

	-- Progress bar
	local progressBg = Utils.newInstance("Frame", {
		Name            = "ProgressBg",
		Size            = UDim2.new(1, 0, 0, 2),
		Position        = UDim2.new(0, 0, 1, -2),
		BackgroundColor3= T.Border,
		BorderSizePixel = 0,
		ZIndex          = 92,
	}, toast)
	local progressFill = Utils.newInstance("Frame", {
		Name            = "ProgressFill",
		Size            = UDim2.new(1, 0, 1, 0),
		BackgroundColor3= accent,
		BorderSizePixel = 0,
		ZIndex          = 93,
	}, progressBg)

	-- Animate in
	toast.Position = UDim2.fromOffset(320, 0)
	Utils.tween(toast, T.AnimSpeed, { Position = UDim2.fromOffset(0, 0) })

	-- Progress countdown
	Utils.tween(progressFill, duration, { Size = UDim2.new(0, 0, 1, 0) }, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)

	-- Dismiss on click
	local conn = toast.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or
		   input.UserInputType == Enum.UserInputType.Touch then
			Utils.tween(toast, T.AnimSpeed, { Position = UDim2.fromOffset(320, 0) })
			task.delay(T.AnimSpeed, function() Utils.destroySafe(toast) end)
		end
	end)

	-- Auto dismiss
	task.delay(duration, function()
		conn:Disconnect()
		if toast and toast.Parent then
			Utils.tween(toast, T.AnimSpeed, { Position = UDim2.fromOffset(320, 0) })
			task.delay(T.AnimSpeed, function() Utils.destroySafe(toast) end)
		end
	end)
end

function NotificationSystem:destroy()
	Utils.destroySafe(self._container)
end

-- ============================================================
--  MODAL / DIALOG SYSTEM
-- ============================================================
local ModalSystem = {}
ModalSystem.__index = ModalSystem

function ModalSystem.new(theme: ThemeConfig, screenGui: ScreenGui)
	local self     = setmetatable({}, ModalSystem)
	self._theme    = theme
	self._gui      = screenGui
	self._stack    = {}
	return self
end

function ModalSystem:show(opts: {
	Title:    string,
	Message:  string?,
	Buttons:  {{Label: string, Variant: string?, OnClick: (() -> ())?}}?,
	Content:  ((Frame) -> ())?,
	Width:    number?,
}): () -> ()

	local T     = self._theme
	local width = opts.Width or 380

	-- Overlay
	local overlay = Utils.newInstance("Frame", {
		Name            = "ModalOverlay",
		Size            = UDim2.fromScale(1, 1),
		BackgroundColor3= T.Overlay,
		BackgroundTransparency = 1,
		ZIndex          = 60,
	}, self._gui)

	Utils.tween(overlay, T.AnimSpeed, { BackgroundTransparency = 0.45 })

	-- Dialog
	local dialog = Utils.newInstance("Frame", {
		Name            = "ModalDialog",
		Size            = UDim2.fromOffset(width, 0),
		AnchorPoint     = Vector2.new(0.5, 0.5),
		Position        = UDim2.fromScale(0.5, 0.5),
		AutomaticSize   = Enum.AutomaticSize.Y,
		BackgroundColor3= T.Surface,
		BorderSizePixel = 0,
		ZIndex          = 61,
	}, overlay)
	Utils.newInstance("UICorner",  { CornerRadius = UDim.new(0, 14) }, dialog)
	Utils.newInstance("UIStroke",  { Color = T.Border, Thickness = 1 }, dialog)
	Utils.newInstance("UIListLayout", {
		SortOrder  = Enum.SortOrder.LayoutOrder,
		Padding    = UDim.new(0, 0),
	}, dialog)

	-- Entry animation
	dialog.Size = UDim2.fromOffset(width, 0)
	local orig = dialog.Position
	dialog.Position = UDim2.new(0.5, 0, 0.5, 20)
	Utils.tween(dialog, T.AnimSpeed, { Position = orig })

	-- Title bar
	local titleBar = Utils.newInstance("Frame", {
		Name            = "TitleBar",
		Size            = UDim2.new(1, 0, 0, 52),
		BackgroundTransparency = 1,
		LayoutOrder     = 1,
		ZIndex          = 62,
	}, dialog)
	Utils.newInstance("UIPadding", {
		PaddingLeft  = UDim.new(0, 20),
		PaddingRight = UDim.new(0, 20),
	}, titleBar)
	Utils.newInstance("TextLabel", {
		Size            = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		Text            = opts.Title,
		Font            = T.FontBold,
		TextSize        = T.TitleSize + 2,
		TextColor3      = T.TextPrimary,
		TextXAlignment  = Enum.TextXAlignment.Left,
		ZIndex          = 62,
	}, titleBar)

	-- Divider
	Utils.newInstance("Frame", {
		Size            = UDim2.new(1, 0, 0, 1),
		BackgroundColor3= T.Border,
		BorderSizePixel = 0,
		LayoutOrder     = 2,
	}, dialog)

	-- Content area
	local content = Utils.newInstance("Frame", {
		Name            = "Content",
		Size            = UDim2.new(1, 0, 0, 0),
		AutomaticSize   = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		LayoutOrder     = 3,
		ZIndex          = 62,
	}, dialog)
	Utils.newInstance("UIPadding", {
		PaddingLeft   = UDim.new(0, 20),
		PaddingRight  = UDim.new(0, 20),
		PaddingTop    = UDim.new(0, 16),
		PaddingBottom = UDim.new(0, 16),
	}, content)
	Utils.newInstance("UIListLayout", {
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding   = UDim.new(0, 10),
	}, content)

	if opts.Message then
		Utils.newInstance("TextLabel", {
			Size            = UDim2.new(1, 0, 0, 0),
			AutomaticSize   = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1,
			Text            = opts.Message,
			Font            = T.Font,
			TextSize        = T.TextSize,
			TextColor3      = T.TextSecondary,
			TextXAlignment  = Enum.TextXAlignment.Left,
			TextWrapped     = true,
			RichText        = true,
			ZIndex          = 62,
		}, content)
	end

	if opts.Content then opts.Content(content) end

	-- Buttons
	if opts.Buttons and #opts.Buttons > 0 then
		Utils.newInstance("Frame", {
			Size            = UDim2.new(1, 0, 0, 1),
			BackgroundColor3= T.Border,
			BorderSizePixel = 0,
			LayoutOrder     = 4,
		}, dialog)

		local btnRow = Utils.newInstance("Frame", {
			Name            = "Buttons",
			Size            = UDim2.new(1, 0, 0, 52),
			BackgroundTransparency = 1,
			LayoutOrder     = 5,
			ZIndex          = 62,
		}, dialog)
		Utils.newInstance("UIPadding", {
			PaddingLeft   = UDim.new(0, 16),
			PaddingRight  = UDim.new(0, 16),
			PaddingTop    = UDim.new(0, 10),
			PaddingBottom = UDim.new(0, 10),
		}, btnRow)
		local btnList = Utils.newInstance("UIListLayout", {
			SortOrder              = Enum.SortOrder.LayoutOrder,
			FillDirection          = Enum.FillDirection.Horizontal,
			HorizontalAlignment    = Enum.HorizontalAlignment.Right,
			VerticalAlignment      = Enum.VerticalAlignment.Center,
			Padding                = UDim.new(0, 8),
		}, btnRow)

		for i, b in ipairs(opts.Buttons) do
			local isPrimary = b.Variant == "primary"
			local isDanger  = b.Variant == "danger"
			local bg  = isDanger and T.Error or (isPrimary and T.Accent or T.SurfaceHover)
			local fg  = (isDanger or isPrimary) and T.TextOnAccent or T.TextPrimary
			local btn = Utils.newInstance("TextButton", {
				Name            = "Btn" .. i,
				Size            = UDim2.fromOffset(0, 34),
				AutomaticSize   = Enum.AutomaticSize.X,
				BackgroundColor3= bg,
				BorderSizePixel = 0,
				Text            = b.Label,
				Font            = T.FontBold,
				TextSize        = T.TextSize,
				TextColor3      = fg,
				ZIndex          = 63,
				LayoutOrder     = i,
			}, btnRow)
			Utils.newInstance("UICorner",  { CornerRadius = UDim.new(0, 8) }, btn)
			Utils.newInstance("UIPadding", {
				PaddingLeft  = UDim.new(0, 16),
				PaddingRight = UDim.new(0, 16),
			}, btn)

			btn.MouseButton1Click:Connect(function()
				if b.OnClick then b.OnClick() end
			end)

			-- Hover
			btn.MouseEnter:Connect(function()
				Utils.tween(btn, T.AnimSpeed,
					{ BackgroundColor3 = isDanger and Color3.fromRGB(255, 100, 100) or
					  (isPrimary and T.AccentHover or T.Border) })
			end)
			btn.MouseLeave:Connect(function()
				Utils.tween(btn, T.AnimSpeed, { BackgroundColor3 = bg })
			end)
		end
	end

	-- Close function
	local closed = false
	local function closeModal()
		if closed then return end
		closed = true
		Utils.tween(overlay, T.AnimSpeed, { BackgroundTransparency = 1 })
		Utils.tween(dialog,  T.AnimSpeed, { Position = UDim2.new(0.5, 0, 0.5, 20) })
		task.delay(T.AnimSpeed, function() Utils.destroySafe(overlay) end)
	end

	-- Click outside to close
	overlay.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or
		   input.UserInputType == Enum.UserInputType.Touch then
			local mx, my = input.Position.X, input.Position.Y
			local dp = dialog.AbsolutePosition
			local ds = dialog.AbsoluteSize
			if mx < dp.X or mx > dp.X + ds.X or my < dp.Y or my > dp.Y + ds.Y then
				closeModal()
			end
		end
	end)

	return closeModal
end

function ModalSystem:confirm(title: string, message: string, onConfirm: () -> (), onCancel: (() -> ())?)
	local close: () -> ()
	close = self:show({
		Title   = title,
		Message = message,
		Buttons = {
			{
				Label   = "Cancel",
				Variant = "secondary",
				OnClick = function()
					close()
					if onCancel then onCancel() end
				end,
			},
			{
				Label   = "Confirm",
				Variant = "primary",
				OnClick = function()
					close()
					onConfirm()
				end,
			},
		},
	})
	return close
end

-- ============================================================
--  CONTEXT MENU
-- ============================================================
local ContextMenu = {}
ContextMenu.__index = ContextMenu

function ContextMenu.new(theme: ThemeConfig, screenGui: ScreenGui)
	local self    = setmetatable({}, ContextMenu)
	self._theme   = theme
	self._gui     = screenGui
	self._current = nil :: Frame?
	return self
end

function ContextMenu:show(items: {{
	Label:    string,
	Icon:     string?,
	Disabled: boolean?,
	Separator:boolean?,
	OnClick:  (() -> ())?,
}}, position: Vector2)
	self:hide()

	local T      = self._theme
	local vp     = Utils.getViewport()
	local menu   = Utils.newInstance("Frame", {
		Name            = "ContextMenu",
		Size            = UDim2.fromOffset(200, 0),
		AutomaticSize   = Enum.AutomaticSize.Y,
		BackgroundColor3= T.Surface,
		BorderSizePixel = 0,
		ZIndex          = 80,
		ClipsDescendants= false,
	}, self._gui)
	Utils.newInstance("UICorner",   { CornerRadius = UDim.new(0, 10) }, menu)
	Utils.newInstance("UIStroke",   { Color = T.Border, Thickness = 1 }, menu)
	Utils.newInstance("UIPadding",  {
		PaddingTop    = UDim.new(0, 6),
		PaddingBottom = UDim.new(0, 6),
	}, menu)
	Utils.newInstance("UIListLayout", {
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding   = UDim.new(0, 2),
	}, menu)

	for i, item in ipairs(items) do
		if item.Separator then
			Utils.newInstance("Frame", {
				Size            = UDim2.new(1, -16, 0, 1),
				Position        = UDim2.fromOffset(8, 0),
				BackgroundColor3= T.Border,
				BorderSizePixel = 0,
				LayoutOrder     = i,
			}, menu)
			continue
		end

		local row = Utils.newInstance("TextButton", {
			Name            = "Item" .. i,
			Size            = UDim2.new(1, 0, 0, 36),
			BackgroundTransparency = 1,
			Text            = "",
			LayoutOrder     = i,
			ZIndex          = 81,
		}, menu)
		Utils.newInstance("UIPadding", {
			PaddingLeft  = UDim.new(0, 12),
			PaddingRight = UDim.new(0, 12),
		}, row)

		Utils.newInstance("TextLabel", {
			Size            = UDim2.new(1, 0, 1, 0),
			BackgroundTransparency = 1,
			Text            = item.Label,
			Font            = T.Font,
			TextSize        = T.TextSize,
			TextColor3      = item.Disabled and T.TextDisabled or T.TextPrimary,
			TextXAlignment  = Enum.TextXAlignment.Left,
			ZIndex          = 81,
		}, row)

		if not item.Disabled then
			row.MouseEnter:Connect(function()
				Utils.tween(row, T.AnimSpeed * 0.7, { BackgroundColor3 = T.SurfaceHover })
				row.BackgroundTransparency = 0
			end)
			row.MouseLeave:Connect(function()
				Utils.tween(row, T.AnimSpeed * 0.7, { BackgroundTransparency = 1 })
			end)
			row.MouseButton1Click:Connect(function()
				self:hide()
				if item.OnClick then item.OnClick() end
			end)
		end
	end

	-- Position (clamp to screen)
	local px = math.min(position.X, vp.X - 210)
	local py = math.min(position.Y, vp.Y - (#items * 38 + 16))
	menu.Position = UDim2.fromOffset(px, py)

	-- Scale-in animation
	menu.Size = UDim2.fromOffset(200, 1)
	Utils.tween(menu, T.AnimSpeed, { Size = UDim2.fromOffset(200, 0) })

	self._current = menu

	-- Click-away
	local conn: RBXScriptConnection
	conn = UserInputService.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or
		   input.UserInputType == Enum.UserInputType.Touch then
			conn:Disconnect()
			task.defer(function() self:hide() end)
		end
	end)
end

function ContextMenu:hide()
	if self._current then
		Utils.destroySafe(self._current)
		self._current = nil
	end
end

-- ============================================================
--  LOADING SPINNER
-- ============================================================
local LoadingSpinner = {}
LoadingSpinner.__index = LoadingSpinner
setmetatable(LoadingSpinner, { __index = BaseComponent })

function LoadingSpinner.new(parent: GuiObject, theme: ThemeConfig, opts: {
	Style:   string?,   -- "circle"|"dots"|"pulse"
	Size:    number?,
	Color:   Color3?,
})
	local self   = BaseComponent.new()
	setmetatable(self, LoadingSpinner)
	local T      = theme
	opts         = opts or {}
	local sz     = opts.Size or 40
	local color  = opts.Color or T.Accent
	local style  = opts.Style or "circle"

	local holder = Utils.newInstance("Frame", {
		Name            = "Spinner",
		Size            = UDim2.fromOffset(sz, sz),
		BackgroundTransparency = 1,
	}, parent)
	self.Instance = holder

	if style == "circle" then
		local ring = Utils.newInstance("ImageLabel", {
			Size            = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			Image           = "rbxassetid://4965945816",  -- ring image
			ImageColor3     = color,
		}, holder)
		-- Fallback drawn ring
		local arcFrame = Utils.newInstance("Frame", {
			Size            = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
		}, holder)
		-- Draw arc using UIGradient trick
		local circle = Utils.newInstance("Frame", {
			Size            = UDim2.fromScale(1, 1),
			BackgroundColor3= color,
			BorderSizePixel = 0,
		}, arcFrame)
		Utils.newInstance("UICorner", { CornerRadius = UDim.new(0.5, 0) }, circle)
		-- Mask inner
		local inner = Utils.newInstance("Frame", {
			Size            = UDim2.fromOffset(sz - 8, sz - 8),
			AnchorPoint     = Vector2.new(0.5, 0.5),
			Position        = UDim2.fromScale(0.5, 0.5),
			BackgroundColor3= T.Background,
			BorderSizePixel = 0,
		}, arcFrame)
		Utils.newInstance("UICorner", { CornerRadius = UDim.new(0.5, 0) }, inner)
		ring:Destroy()

		-- Rotation loop
		local conn = RunService.Heartbeat:Connect(function(dt)
			arcFrame.Rotation = arcFrame.Rotation + dt * 360
		end)
		self._conn(conn)

	elseif style == "dots" then
		local dotCount = 3
		for i = 1, dotCount do
			local dot = Utils.newInstance("Frame", {
				Name            = "Dot" .. i,
				Size            = UDim2.fromOffset(sz/5, sz/5),
				AnchorPoint     = Vector2.new(0.5, 0.5),
				BackgroundColor3= color,
				BorderSizePixel = 0,
				BackgroundTransparency = 1,
			}, holder)
			Utils.newInstance("UICorner", { CornerRadius = UDim.new(0.5, 0) }, dot)

			-- Position dots horizontally
			dot.Position = UDim2.fromOffset(sz/2 + (i - 2) * sz/3.5, sz/2)

			-- Pulsing animation with offset
			task.delay((i - 1) * 0.18, function()
				local function pulse()
					if not holder.Parent then return end
					Utils.tween(dot, 0.35, { BackgroundTransparency = 0 }, Enum.EasingStyle.Sine, Enum.EasingDirection.In)
					task.delay(0.35, function()
						if not holder.Parent then return end
						Utils.tween(dot, 0.35, { BackgroundTransparency = 0.8 }, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
						task.delay(0.35, pulse)
					end)
				end
				pulse()
			end)
		end

	elseif style == "pulse" then
		local circle = Utils.newInstance("Frame", {
			Size            = UDim2.fromScale(1, 1),
			AnchorPoint     = Vector2.new(0.5, 0.5),
			Position        = UDim2.fromScale(0.5, 0.5),
			BackgroundColor3= color,
			BorderSizePixel = 0,
		}, holder)
		Utils.newInstance("UICorner", { CornerRadius = UDim.new(0.5, 0) }, circle)
		local function pulsate()
			if not holder.Parent then return end
			Utils.tween(circle, 0.5, {
				Size            = UDim2.fromScale(1.2, 1.2),
				BackgroundTransparency = 0.6,
			}, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
			task.delay(0.5, function()
				if not holder.Parent then return end
				Utils.tween(circle, 0.5, {
					Size            = UDim2.fromScale(0.8, 0.8),
					BackgroundTransparency = 0,
				}, Enum.EasingStyle.Sine, Enum.EasingDirection.In)
				task.delay(0.5, pulsate)
			end)
		end
		pulsate()
	end

	return self
end

-- ============================================================
--  BUTTON COMPONENT
-- ============================================================
local Button = {}
Button.__index = Button
setmetatable(Button, { __index = BaseComponent })

function Button.new(parent: GuiObject, theme: ThemeConfig, opts: ButtonOptions)
	local self   = BaseComponent.new()
	setmetatable(self, Button)
	local T      = theme
	opts         = opts or {}

	local variant  = opts.Variant or "primary"
	local disabled = opts.Disabled or false

	local bg, fg, border
	if variant == "primary" then
		bg, fg, border = T.Accent,       T.TextOnAccent, T.Accent
	elseif variant == "secondary" then
		bg, fg, border = T.Surface,      T.TextPrimary,  T.Border
	elseif variant == "ghost" then
		bg, fg, border = Color3.new(0,0,0), T.TextPrimary, T.Border
	elseif variant == "danger" then
		bg, fg, border = T.Error,        T.TextOnAccent, T.Error
	else
		bg, fg, border = T.Accent,       T.TextOnAccent, T.Accent
	end

	local btn = Utils.newInstance("TextButton", {
		Name            = "NexusButton",
		Size            = opts.Size or UDim2.fromOffset(120, 38),
		BackgroundColor3= disabled and T.Surface or bg,
		BackgroundTransparency = variant == "ghost" and 1 or 0,
		BorderSizePixel = 0,
		Text            = opts.Text or "Button",
		Font            = T.FontBold,
		TextSize        = T.TextSize,
		TextColor3      = disabled and T.TextDisabled or fg,
		AutoButtonColor = false,
	}, parent)
	Utils.newInstance("UICorner", { CornerRadius = T.CornerRadius }, btn)

	if variant == "secondary" or variant == "ghost" then
		Utils.newInstance("UIStroke", { Color = T.Border, Thickness = 1 }, btn)
	end

	self.Instance = btn

	if not disabled then
		self:_conn(btn.MouseEnter:Connect(function()
			if not self._enabled then return end
			Utils.tween(btn, T.AnimSpeed, {
				BackgroundColor3     = variant == "ghost" and T.SurfaceHover or
				                       variant == "secondary" and T.SurfaceHover or T.AccentHover,
				BackgroundTransparency = variant == "ghost" and 0 or 0,
			})
			self:emit("MouseEnter")
		end))

		self:_conn(btn.MouseLeave:Connect(function()
			Utils.tween(btn, T.AnimSpeed, {
				BackgroundColor3     = bg,
				BackgroundTransparency = variant == "ghost" and 1 or 0,
			})
			self:emit("MouseLeave")
		end))

		self:_conn(btn.MouseButton1Down:Connect(function()
			if not self._enabled then return end
			Utils.tween(btn, 0.06, {
				Size = UDim2.new(
					opts.Size and opts.Size.X.Scale or 0,
					(opts.Size and opts.Size.X.Offset or 120) - 4,
					opts.Size and opts.Size.Y.Scale or 0,
					(opts.Size and opts.Size.Y.Offset or 38) - 2
				),
				BackgroundColor3 = variant == "danger" and Color3.fromRGB(200, 50, 50)
				                   or T.AccentPress,
			})
		end))

		self:_conn(btn.MouseButton1Up:Connect(function()
			Utils.tween(btn, 0.09, {
				Size = opts.Size or UDim2.fromOffset(120, 38),
				BackgroundColor3 = bg,
			})
		end))

		self:_conn(btn.MouseButton1Click:Connect(function()
			if not self._enabled then return end
			self:emit("Clicked")
			if opts.OnClick then opts.OnClick() end
		end))

		-- Touch support
		self:_conn(btn.TouchTap:Connect(function()
			if not self._enabled then return end
			self:emit("Clicked")
			if opts.OnClick then opts.OnClick() end
		end))
	end

	return self
end

function Button:setText(text: string)
	if self.Instance then
		(self.Instance :: TextButton).Text = text
	end
end

function Button:setDisabled(v: boolean)
	self._enabled = not v
	if self.Instance then
		local T = (self.Instance :: any).Parent
		(self.Instance :: TextButton).TextColor3 = v and Color3.fromRGB(100, 100, 120) or Color3.fromRGB(235, 235, 245)
	end
end

-- ============================================================
--  TOGGLE SWITCH  (iOS-style)
-- ============================================================
local Toggle = {}
Toggle.__index = Toggle
setmetatable(Toggle, { __index = BaseComponent })

function Toggle.new(parent: GuiObject, theme: ThemeConfig, opts: {
	Value:    boolean?,
	Label:    string?,
	OnChange: ((boolean) -> ())?,
})
	local self   = BaseComponent.new()
	setmetatable(self, Toggle)
	local T      = theme
	opts         = opts or {}

	local value  = opts.Value or false
	local W, H   = 50, 28

	-- Wrapper
	local wrapper = Utils.newInstance("Frame", {
		Name            = "Toggle",
		Size            = UDim2.fromOffset(opts.Label and 200 or W, H),
		BackgroundTransparency = 1,
	}, parent)
	self.Instance = wrapper

	-- Track
	local track = Utils.newInstance("Frame", {
		Name            = "Track",
		Size            = UDim2.fromOffset(W, H),
		Position        = opts.Label and UDim2.new(1, -W, 0.5, -H/2) or UDim2.fromOffset(0, 0),
		AnchorPoint     = opts.Label and Vector2.new(0, 0) or Vector2.new(0, 0),
		BackgroundColor3= value and T.Accent or T.Border,
		BorderSizePixel = 0,
	}, wrapper)
	Utils.newInstance("UICorner", { CornerRadius = UDim.new(0.5, 0) }, track)

	-- Thumb
	local thumbX = value and W - H + 2 or 2
	local thumb  = Utils.newInstance("Frame", {
		Name            = "Thumb",
		Size            = UDim2.fromOffset(H - 4, H - 4),
		Position        = UDim2.fromOffset(thumbX, 2),
		BackgroundColor3= Color3.new(1, 1, 1),
		BorderSizePixel = 0,
	}, track)
	Utils.newInstance("UICorner", { CornerRadius = UDim.new(0.5, 0) }, thumb)

	-- Label
	if opts.Label then
		Utils.newInstance("TextLabel", {
			Size            = UDim2.new(1, -(W + 12), 1, 0),
			BackgroundTransparency = 1,
			Text            = opts.Label,
			Font            = T.Font,
			TextSize        = T.TextSize,
			TextColor3      = T.TextPrimary,
			TextXAlignment  = Enum.TextXAlignment.Left,
		}, wrapper)
	end

	-- Shadow on thumb
	Utils.newInstance("UIStroke", { Color = Color3.fromRGB(0, 0, 0), Thickness = 0, Transparency = 0.8 }, thumb)

	local function setValue(v: boolean, animate: boolean)
		value = v
		local targetX  = v and W - H + 2 or 2
		local trackCol = v and T.Accent or T.Border
		if animate then
			Utils.tween(thumb, T.AnimSpeed, { Position = UDim2.fromOffset(targetX, 2) }, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
			Utils.tween(track, T.AnimSpeed, { BackgroundColor3 = trackCol })
		else
			thumb.Position       = UDim2.fromOffset(targetX, 2)
			track.BackgroundColor3 = trackCol
		end
	end

	local function toggle()
		if not self._enabled then return end
		setValue(not value, true)
		self:emit("ValueChanged", value)
		if opts.OnChange then opts.OnChange(value) end
	end

	self:_conn(track.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or
		   input.UserInputType == Enum.UserInputType.Touch then
			toggle()
		end
	end))

	self.getValue  = function() return value end
	self.setValue  = function(_, v: boolean) setValue(v, true) end

	setValue(value, false)
	return self
end

-- ============================================================
--  SLIDER COMPONENT
-- ============================================================
local Slider = {}
Slider.__index = Slider
setmetatable(Slider, { __index = BaseComponent })

function Slider.new(parent: GuiObject, theme: ThemeConfig, opts: {
	Min:         number?,
	Max:         number?,
	Value:       number?,
	Step:        number?,
	Label:       string?,
	ShowValue:   boolean?,
	Vertical:    boolean?,
	Width:       number?,
	OnChange:    ((number) -> ())?,
})
	local self   = BaseComponent.new()
	setmetatable(self, Slider)
	local T      = theme
	opts         = opts or {}

	local min    = opts.Min   or 0
	local max    = opts.Max   or 100
	local step   = opts.Step  or 1
	local val    = opts.Value or min
	local width  = opts.Width or 200
	local horiz  = not opts.Vertical

	local function snapVal(v: number): number
		v = Utils.clamp(v, min, max)
		if step > 0 then
			v = math.floor((v - min) / step + 0.5) * step + min
		end
		return Utils.round(v, 4)
	end

	val = snapVal(val)

	-- Container
	local wrapper = Utils.newInstance("Frame", {
		Name  = "Slider",
		Size  = horiz and UDim2.fromOffset(width, opts.Label and 52 or 28) or UDim2.fromOffset(28, width),
		BackgroundTransparency = 1,
	}, parent)
	self.Instance = wrapper

	-- Label + value row
	local labelRow: Frame?
	local valueLabel: TextLabel?
	if opts.Label or opts.ShowValue then
		labelRow = Utils.newInstance("Frame", {
			Size  = UDim2.new(1, 0, 0, 22),
			BackgroundTransparency = 1,
		}, wrapper)
		if opts.Label then
			Utils.newInstance("TextLabel", {
				Size       = UDim2.fromScale(0.7, 1),
				BackgroundTransparency = 1,
				Text       = opts.Label,
				Font       = T.Font,
				TextSize   = T.TextSize,
				TextColor3 = T.TextPrimary,
				TextXAlignment = Enum.TextXAlignment.Left,
			}, labelRow)
		end
		if opts.ShowValue then
			valueLabel = Utils.newInstance("TextLabel", {
				Size       = UDim2.fromScale(0.3, 1),
				Position   = UDim2.fromScale(0.7, 0),
				BackgroundTransparency = 1,
				Text       = tostring(val),
				Font       = T.FontBold,
				TextSize   = T.TextSize,
				TextColor3 = T.Accent,
				TextXAlignment = Enum.TextXAlignment.Right,
			}, labelRow)
		end
	end

	-- Track area
	local trackY   = labelRow and 26 or 0
	local TRACK_H  = 6
	local THUMB_D  = 18

	local trackBg = Utils.newInstance("Frame", {
		Name            = "TrackBg",
		Size            = UDim2.new(1, 0, 0, TRACK_H),
		Position        = UDim2.new(0, 0, 0, trackY + (THUMB_D - TRACK_H) / 2),
		BackgroundColor3= T.Border,
		BorderSizePixel = 0,
	}, wrapper)
	Utils.newInstance("UICorner", { CornerRadius = UDim.new(0.5, 0) }, trackBg)

	local trackFill = Utils.newInstance("Frame", {
		Name            = "TrackFill",
		Size            = UDim2.new(0, 0, 1, 0),
		BackgroundColor3= T.Accent,
		BorderSizePixel = 0,
	}, trackBg)
	Utils.newInstance("UICorner", { CornerRadius = UDim.new(0.5, 0) }, trackFill)

	local thumb = Utils.newInstance("Frame", {
		Name            = "Thumb",
		Size            = UDim2.fromOffset(THUMB_D, THUMB_D),
		AnchorPoint     = Vector2.new(0.5, 0.5),
		Position        = UDim2.new(0, 0, 0, trackY + THUMB_D / 2),
		BackgroundColor3= Color3.new(1, 1, 1),
		BorderSizePixel = 0,
		ZIndex          = 2,
	}, wrapper)
	Utils.newInstance("UICorner", { CornerRadius = UDim.new(0.5, 0) }, thumb)
	Utils.newInstance("UIStroke", { Color = T.Accent, Thickness = 2 }, thumb)

	local function updateVisuals(v: number, animate: boolean)
		local pct = (v - min) / (max - min)
		local tw  = trackBg.AbsoluteSize.X
		local tx  = pct * tw
		if animate then
			Utils.tween(trackFill, T.AnimSpeed * 0.6, { Size = UDim2.new(pct, 0, 1, 0) })
			Utils.tween(thumb,     T.AnimSpeed * 0.6, { Position = UDim2.new(0, tx, 0, trackY + THUMB_D / 2) })
		else
			trackFill.Size     = UDim2.new(pct, 0, 1, 0)
			thumb.Position     = UDim2.new(0, tx, 0, trackY + THUMB_D / 2)
		end
		if valueLabel then valueLabel.Text = tostring(v) end
	end

	local function setValueFromX(x: number)
		local tw  = trackBg.AbsoluteSize.X
		local ap  = trackBg.AbsolutePosition.X
		local pct = Utils.clamp((x - ap) / tw, 0, 1)
		local raw = pct * (max - min) + min
		local newVal = snapVal(raw)
		if newVal ~= val then
			val = newVal
			updateVisuals(val, false)
			self:emit("ValueChanged", val)
			if opts.OnChange then opts.OnChange(val) end
		end
	end

	local dragging = false

	self:_conn(thumb.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or
		   input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			Utils.tween(thumb, 0.1, { Size = UDim2.fromOffset(THUMB_D + 4, THUMB_D + 4) })
		end
	end))

	self:_conn(trackBg.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or
		   input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			setValueFromX(input.Position.X)
		end
	end))

	self:_conn(UserInputService.InputChanged:Connect(function(input)
		if not dragging then return end
		if input.UserInputType == Enum.UserInputType.MouseMovement or
		   input.UserInputType == Enum.UserInputType.Touch then
			setValueFromX(input.Position.X)
		end
	end))

	self:_conn(UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or
		   input.UserInputType == Enum.UserInputType.Touch then
			if dragging then
				dragging = false
				Utils.tween(thumb, 0.1, { Size = UDim2.fromOffset(THUMB_D, THUMB_D) })
			end
		end
	end))

	-- Init
	task.defer(function() updateVisuals(val, false) end)

	self.getValue  = function() return val end
	self.setValue  = function(_, v: number)
		val = snapVal(v)
		updateVisuals(val, true)
	end

	return self
end

-- ============================================================
--  DROPDOWN / COMBOBOX
-- ============================================================
local Dropdown = {}
Dropdown.__index = Dropdown
setmetatable(Dropdown, { __index = BaseComponent })

function Dropdown.new(parent: GuiObject, theme: ThemeConfig, opts: {
	Items:       {string | {Label: string, Value: any}},
	Placeholder: string?,
	Value:       any?,
	Searchable:  boolean?,
	Width:       number?,
	MaxHeight:   number?,
	OnChange:    ((any, string) -> ())?,
})
	local self   = BaseComponent.new()
	setmetatable(self, Dropdown)
	local T      = theme
	opts         = opts or {}

	local width     = opts.Width    or 220
	local maxHeight = opts.MaxHeight or 220
	local open      = false
	local selected  = nil :: {Label: string, Value: any}?
	local items     = {} :: {{Label: string, Value: any}}
	local filterStr = ""

	-- Normalize items
	for _, v in ipairs(opts.Items or {}) do
		if type(v) == "string" then
			table.insert(items, { Label = v, Value = v })
		else
			table.insert(items, v)
		end
	end

	-- Find default
	if opts.Value then
		for _, item in ipairs(items) do
			if item.Value == opts.Value then selected = item; break end
		end
	end

	-- Main frame
	local wrapper = Utils.newInstance("Frame", {
		Name  = "Dropdown",
		Size  = UDim2.fromOffset(width, 38),
		BackgroundTransparency = 1,
		ClipsDescendants = false,
	}, parent)
	self.Instance = wrapper

	-- Header button
	local header = Utils.newInstance("TextButton", {
		Name            = "Header",
		Size            = UDim2.fromOffset(width, 38),
		BackgroundColor3= T.Surface,
		BorderSizePixel = 0,
		Text            = "",
		ZIndex          = 2,
	}, wrapper)
	Utils.newInstance("UICorner",  { CornerRadius = T.CornerRadius }, header)
	Utils.newInstance("UIStroke",  { Color = T.Border, Thickness = 1 }, header)
	Utils.newInstance("UIPadding", {
		PaddingLeft  = UDim.new(0, 12),
		PaddingRight = UDim.new(0, 12),
	}, header)

	local headerLabel = Utils.newInstance("TextLabel", {
		Size            = UDim2.new(1, -24, 1, 0),
		BackgroundTransparency = 1,
		Text            = selected and selected.Label or (opts.Placeholder or "Select..."),
		Font            = T.Font,
		TextSize        = T.TextSize,
		TextColor3      = selected and T.TextPrimary or T.TextSecondary,
		TextXAlignment  = Enum.TextXAlignment.Left,
		ZIndex          = 3,
	}, header)

	local arrow = Utils.newInstance("TextLabel", {
		Size            = UDim2.fromOffset(20, 20),
		Position        = UDim2.new(1, -20, 0.5, -10),
		BackgroundTransparency = 1,
		Text            = "▾",
		Font            = T.Font,
		TextSize        = 18,
		TextColor3      = T.TextSecondary,
		ZIndex          = 3,
	}, header)

	-- Dropdown panel
	local panel = Utils.newInstance("ScrollingFrame", {
		Name            = "Panel",
		Size            = UDim2.fromOffset(width, 0),
		Position        = UDim2.fromOffset(0, 42),
		BackgroundColor3= T.Surface,
		BorderSizePixel = 0,
		Visible         = false,
		ZIndex          = 20,
		CanvasSize      = UDim2.fromOffset(0, 0),
		ScrollBarThickness = 4,
		ScrollBarImageColor3 = T.ScrollBar,
		AutomaticCanvasSize  = Enum.AutomaticSize.Y,
	}, wrapper)
	Utils.newInstance("UICorner",   { CornerRadius = T.CornerRadius }, panel)
	Utils.newInstance("UIStroke",   { Color = T.Border, Thickness = 1 }, panel)
	Utils.newInstance("UIPadding",  {
		PaddingTop    = UDim.new(0, 6),
		PaddingBottom = UDim.new(0, 6),
	}, panel)
	local panelList = Utils.newInstance("UIListLayout", {
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding   = UDim.new(0, 2),
	}, panel)

	-- Search box (optional)
	local searchBox: TextBox?
	if opts.Searchable then
		local searchWrap = Utils.newInstance("Frame", {
			Size            = UDim2.new(1, -12, 0, 32),
			BackgroundColor3= T.BackgroundSecond,
			BorderSizePixel = 0,
			LayoutOrder     = 0,
			ZIndex          = 21,
		}, panel)
		Utils.newInstance("UICorner", { CornerRadius = UDim.new(0, 6) }, searchWrap)
		Utils.newInstance("UIPadding", {
			PaddingLeft  = UDim.new(0, 6),
			PaddingRight = UDim.new(0, 6),
		}, searchWrap)
		searchBox = Utils.newInstance("TextBox", {
			Size            = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			PlaceholderText = "Search...",
			PlaceholderColor3 = T.TextDisabled,
			Text            = "",
			Font            = T.Font,
			TextSize        = T.TextSize,
			TextColor3      = T.TextPrimary,
			ZIndex          = 21,
		}, searchWrap)
	end

	-- Populate items
	local function populatePanel(filter: string?)
		-- Clear existing rows (not search)
		for _, child in ipairs(panel:GetChildren()) do
			if child:IsA("TextButton") then child:Destroy() end
		end

		for idx, item in ipairs(items) do
			if filter and filter ~= "" and not item.Label:lower():find(filter:lower(), 1, true) then
				continue
			end
			local row = Utils.newInstance("TextButton", {
				Name            = "Item_" .. idx,
				Size            = UDim2.new(1, -12, 0, 34),
				BackgroundTransparency = selected and selected.Value == item.Value and 0 or 1,
				BackgroundColor3= T.SurfaceHover,
				BorderSizePixel = 0,
				Text            = item.Label,
				Font            = selected and selected.Value == item.Value and T.FontBold or T.Font,
				TextSize        = T.TextSize,
				TextColor3      = T.TextPrimary,
				TextXAlignment  = Enum.TextXAlignment.Left,
				LayoutOrder     = idx,
				ZIndex          = 21,
			}, panel)
			Utils.newInstance("UICorner",  { CornerRadius = UDim.new(0, 6) }, row)
			Utils.newInstance("UIPadding", { PaddingLeft = UDim.new(0, 12) }, row)

			row.MouseEnter:Connect(function()
				Utils.tween(row, T.AnimSpeed * 0.6, { BackgroundTransparency = 0 })
			end)
			row.MouseLeave:Connect(function()
				if not selected or selected.Value ~= item.Value then
					Utils.tween(row, T.AnimSpeed * 0.6, { BackgroundTransparency = 1 })
				end
			end)
			row.MouseButton1Click:Connect(function()
				selected       = item
				headerLabel.Text  = item.Label
				headerLabel.TextColor3 = T.TextPrimary
				self:emit("ValueChanged", item.Value, item.Label)
				if opts.OnChange then opts.OnChange(item.Value, item.Label) end
				-- Close
				header.MouseButton1Click:Fire()
			end)
		end

		-- Cap height
		local count  = #panel:GetChildren() - (searchBox and 2 or 1)
		local height = math.min(count * 36 + 12, maxHeight)
		panel.Size   = UDim2.fromOffset(width, height)
	end

	if searchBox then
		searchBox:GetPropertyChangedSignal("Text"):Connect(function()
			populatePanel(searchBox.Text)
		end)
	end

	-- Open / close
	local function setOpen(v: boolean)
		open = v
		if v then
			panel.Visible = true
			populatePanel(searchBox and searchBox.Text or nil)
			Utils.tween(arrow, T.AnimSpeed, { Rotation = 180 })
			local targetH = panel.Size.Y.Offset
			panel.Size    = UDim2.fromOffset(width, 0)
			Utils.tween(panel, T.AnimSpeed, { Size = UDim2.fromOffset(width, targetH) })
			-- Highlight border
			for _, s in ipairs(header:GetChildren()) do
				if s:IsA("UIStroke") then
					Utils.tween(s, T.AnimSpeed, { Color = T.BorderFocus })
				end
			end
		else
			Utils.tween(arrow, T.AnimSpeed, { Rotation = 0 })
			Utils.tween(panel, T.AnimSpeed, { Size = UDim2.fromOffset(width, 0) })
			task.delay(T.AnimSpeed, function()
				if not open then panel.Visible = false end
			end)
			for _, s in ipairs(header:GetChildren()) do
				if s:IsA("UIStroke") then
					Utils.tween(s, T.AnimSpeed, { Color = T.Border })
				end
			end
		end
	end

	self:_conn(header.MouseButton1Click:Connect(function()
		setOpen(not open)
	end))

	-- Close when clicking elsewhere
	self:_conn(UserInputService.InputBegan:Connect(function(input)
		if not open then return end
		if input.UserInputType == Enum.UserInputType.MouseButton1 or
		   input.UserInputType == Enum.UserInputType.Touch then
			task.defer(function()
				local mp = UserInputService:GetMouseLocation()
				local hp = header.AbsolutePosition
				local hs = header.AbsoluteSize
				local pp = panel.AbsolutePosition
				local ps = panel.AbsoluteSize
				local inHeader = mp.X >= hp.X and mp.X <= hp.X + hs.X and
				                 mp.Y >= hp.Y and mp.Y <= hp.Y + hs.Y
				local inPanel  = mp.X >= pp.X and mp.X <= pp.X + ps.X and
				                 mp.Y >= pp.Y and mp.Y <= pp.Y + ps.Y
				if not inHeader and not inPanel then
					setOpen(false)
				end
			end)
		end
	end))

	self.getValue  = function() return selected and selected.Value end
	self.setValue  = function(_, v: any)
		for _, item in ipairs(items) do
			if item.Value == v then
				selected = item
				headerLabel.Text = item.Label
				headerLabel.TextColor3 = T.TextPrimary
				break
			end
		end
	end

	populatePanel()
	return self
end

-- ============================================================
--  TEXTBOX COMPONENT
-- ============================================================
local TextBoxComp = {}
TextBoxComp.__index = TextBoxComp
setmetatable(TextBoxComp, { __index = BaseComponent })

function TextBoxComp.new(parent: GuiObject, theme: ThemeConfig, opts: {
	Placeholder: string?,
	Value:       string?,
	Label:       string?,
	Password:    boolean?,
	Multiline:   boolean?,
	Validate:    ((string) -> (boolean, string?))?,
	Width:       number?,
	OnChange:    ((string) -> ())?,
	OnSubmit:    ((string) -> ())?,
})
	local self   = BaseComponent.new()
	setmetatable(self, TextBoxComp)
	local T      = theme
	opts         = opts or {}
	local width  = opts.Width or 220
	local height = opts.Multiline and 80 or 38

	local wrapper = Utils.newInstance("Frame", {
		Name  = "TextBox",
		Size  = UDim2.fromOffset(width, opts.Label and height + 26 or height),
		BackgroundTransparency = 1,
		AutomaticSize = Enum.AutomaticSize.Y,
	}, parent)
	self.Instance = wrapper

	if opts.Label then
		Utils.newInstance("TextLabel", {
			Size       = UDim2.new(1, 0, 0, 22),
			BackgroundTransparency = 1,
			Text       = opts.Label,
			Font       = T.Font,
			TextSize   = T.TextSize - 1,
			TextColor3 = T.TextSecondary,
			TextXAlignment = Enum.TextXAlignment.Left,
		}, wrapper)
	end

	local boxFrame = Utils.newInstance("Frame", {
		Name            = "BoxFrame",
		Size            = UDim2.fromOffset(width, height),
		Position        = opts.Label and UDim2.fromOffset(0, 26) or UDim2.fromOffset(0, 0),
		BackgroundColor3= T.Surface,
		BorderSizePixel = 0,
	}, wrapper)
	Utils.newInstance("UICorner", { CornerRadius = T.CornerRadius }, boxFrame)
	local stroke = Utils.newInstance("UIStroke", { Color = T.Border, Thickness = 1 }, boxFrame)

	Utils.newInstance("UIPadding", {
		PaddingLeft   = UDim.new(0, 12),
		PaddingRight  = UDim.new(0, 12),
		PaddingTop    = UDim.new(0, 8),
		PaddingBottom = UDim.new(0, 8),
	}, boxFrame)

	local box = Utils.newInstance("TextBox", {
		Size                = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Text                = opts.Value or "",
		PlaceholderText     = opts.Placeholder or "",
		PlaceholderColor3   = T.TextDisabled,
		Font                = T.Font,
		TextSize            = T.TextSize,
		TextColor3          = T.TextPrimary,
		TextXAlignment      = Enum.TextXAlignment.Left,
		TextYAlignment      = Enum.TextYAlignment.Top,
		MultiLine           = opts.Multiline or false,
		ClearTextOnFocus    = false,
		ZIndex              = 2,
	}, boxFrame)

	-- Password masking
	if opts.Password then box.TextTransparency = 0 end

	-- Error label
	local errorLabel = Utils.newInstance("TextLabel", {
		Size            = UDim2.new(1, 0, 0, 18),
		Position        = UDim2.fromOffset(0, opts.Label and (height + 26) or height),
		BackgroundTransparency = 1,
		Text            = "",
		Font            = T.Font,
		TextSize        = 12,
		TextColor3      = T.Error,
		TextXAlignment  = Enum.TextXAlignment.Left,
	}, wrapper)

	-- Focus effects
	self:_conn(box.Focused:Connect(function()
		Utils.tween(stroke, T.AnimSpeed, { Color = T.BorderFocus, Thickness = 2 })
		Utils.tween(boxFrame, T.AnimSpeed, { BackgroundColor3 = T.BackgroundSecond })
		self:emit("Focused")
	end))

	self:_conn(box.FocusLost:Connect(function(enterPressed)
		local text = box.Text
		if opts.Validate then
			local ok, msg = opts.Validate(text)
			if not ok then
				errorLabel.Text = msg or "Invalid input"
				Utils.tween(stroke, T.AnimSpeed, { Color = T.Error })
			else
				errorLabel.Text = ""
				Utils.tween(stroke, T.AnimSpeed, { Color = T.Border, Thickness = 1 })
				Utils.tween(boxFrame, T.AnimSpeed, { BackgroundColor3 = T.Surface })
			end
		else
			Utils.tween(stroke, T.AnimSpeed, { Color = T.Border, Thickness = 1 })
			Utils.tween(boxFrame, T.AnimSpeed, { BackgroundColor3 = T.Surface })
		end
		self:emit("FocusLost", text, enterPressed)
		if enterPressed and opts.OnSubmit then opts.OnSubmit(text) end
	end))

	self:_conn(box:GetPropertyChangedSignal("Text"):Connect(function()
		self:emit("ValueChanged", box.Text)
		if opts.OnChange then opts.OnChange(box.Text) end
	end))

	self.getValue  = function() return box.Text end
	self.setValue  = function(_, v: string) box.Text = v end
	self.focus     = function() box:CaptureFocus() end

	return self
end

-- ============================================================
--  CHECKBOX COMPONENT
-- ============================================================
local Checkbox = {}
Checkbox.__index = Checkbox
setmetatable(Checkbox, { __index = BaseComponent })

function Checkbox.new(parent: GuiObject, theme: ThemeConfig, opts: {
	Label:    string?,
	Value:    boolean?,
	Style:    string?,    -- "check"|"square"|"circle"
	OnChange: ((boolean) -> ())?,
})
	local self  = BaseComponent.new()
	setmetatable(self, Checkbox)
	local T     = theme
	opts        = opts or {}
	local value = opts.Value or false
	local style = opts.Style or "check"
	local SZ    = 20

	local wrapper = Utils.newInstance("TextButton", {
		Name  = "Checkbox",
		Size  = UDim2.fromOffset(opts.Label and 200 or SZ, SZ),
		BackgroundTransparency = 1,
		Text  = "",
		AutoButtonColor = false,
	}, parent)
	self.Instance = wrapper

	local box = Utils.newInstance("Frame", {
		Name            = "Box",
		Size            = UDim2.fromOffset(SZ, SZ),
		BackgroundColor3= value and T.Accent or T.Surface,
		BorderSizePixel = 0,
	}, wrapper)

	local cornerR = style == "circle" and UDim.new(0.5, 0) or T.CornerRadius
	Utils.newInstance("UICorner", { CornerRadius = cornerR }, box)
	local bStroke = Utils.newInstance("UIStroke", { Color = value and T.Accent or T.Border, Thickness = 2 }, box)

	local checkMark = Utils.newInstance("TextLabel", {
		Size            = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Text            = style == "square" and "■" or "✓",
		Font            = T.FontBold,
		TextSize        = style == "square" and 12 or 14,
		TextColor3      = T.TextOnAccent,
		ZIndex          = 2,
	}, box)
	checkMark.Visible = value

	if opts.Label then
		Utils.newInstance("TextLabel", {
			Size            = UDim2.new(1, -(SZ + 10), 1, 0),
			Position        = UDim2.fromOffset(SZ + 10, 0),
			BackgroundTransparency = 1,
			Text            = opts.Label,
			Font            = T.Font,
			TextSize        = T.TextSize,
			TextColor3      = T.TextPrimary,
			TextXAlignment  = Enum.TextXAlignment.Left,
		}, wrapper)
	end

	local function setValue(v: boolean)
		value = v
		checkMark.Visible = v
		Utils.tween(box, T.AnimSpeed, { BackgroundColor3 = v and T.Accent or T.Surface })
		Utils.tween(bStroke, T.AnimSpeed, { Color = v and T.Accent or T.Border })
		if v then
			-- Bounce animation
			Utils.tween(box, 0.07, { Size = UDim2.fromOffset(SZ + 4, SZ + 4) })
			task.delay(0.07, function()
				Utils.tween(box, 0.1, { Size = UDim2.fromOffset(SZ, SZ) })
			end)
		end
	end

	self:_conn(wrapper.MouseButton1Click:Connect(function()
		if not self._enabled then return end
		setValue(not value)
		self:emit("ValueChanged", value)
		if opts.OnChange then opts.OnChange(value) end
	end))

	self:_conn(wrapper.MouseEnter:Connect(function()
		Utils.tween(box, T.AnimSpeed, { BackgroundColor3 = value and T.AccentHover or T.SurfaceHover })
	end))
	self:_conn(wrapper.MouseLeave:Connect(function()
		Utils.tween(box, T.AnimSpeed, { BackgroundColor3 = value and T.Accent or T.Surface })
	end))

	self.getValue = function() return value end
	self.setValue = function(_, v: boolean) setValue(v) end
	setValue(value)

	return self
end

-- ============================================================
--  PROGRESS BAR
-- ============================================================
local ProgressBar = {}
ProgressBar.__index = ProgressBar
setmetatable(ProgressBar, { __index = BaseComponent })

function ProgressBar.new(parent: GuiObject, theme: ThemeConfig, opts: {
	Value:         number?,
	Indeterminate: boolean?,
	Label:         string?,
	ShowPercent:   boolean?,
	Color:         Color3?,
	Height:        number?,
	Width:         number?,
})
	local self   = BaseComponent.new()
	setmetatable(self, ProgressBar)
	local T      = theme
	opts         = opts or {}

	local value  = opts.Value or 0
	local height = opts.Height or 8
	local width  = opts.Width  or 250
	local color  = opts.Color  or T.Accent

	local wrapper = Utils.newInstance("Frame", {
		Name  = "ProgressBar",
		Size  = UDim2.fromOffset(width, opts.Label and height + 24 or height),
		BackgroundTransparency = 1,
	}, parent)
	self.Instance = wrapper

	if opts.Label or opts.ShowPercent then
		local labelRow = Utils.newInstance("Frame", {
			Size  = UDim2.new(1, 0, 0, 20),
			BackgroundTransparency = 1,
		}, wrapper)
		if opts.Label then
			Utils.newInstance("TextLabel", {
				Size       = UDim2.fromScale(0.7, 1),
				BackgroundTransparency = 1,
				Text       = opts.Label,
				Font       = T.Font,
				TextSize   = T.TextSize,
				TextColor3 = T.TextPrimary,
				TextXAlignment = Enum.TextXAlignment.Left,
			}, labelRow)
		end
		if opts.ShowPercent then
			self._pctLabel = Utils.newInstance("TextLabel", {
				Size       = UDim2.fromScale(0.3, 1),
				Position   = UDim2.fromScale(0.7, 0),
				BackgroundTransparency = 1,
				Text       = math.floor(value * 100) .. "%",
				Font       = T.FontBold,
				TextSize   = T.TextSize,
				TextColor3 = T.TextSecondary,
				TextXAlignment = Enum.TextXAlignment.Right,
			}, labelRow)
		end
	end

	local track = Utils.newInstance("Frame", {
		Name            = "Track",
		Size            = UDim2.fromOffset(width, height),
		Position        = opts.Label and UDim2.fromOffset(0, 24) or UDim2.fromOffset(0, 0),
		BackgroundColor3= T.Border,
		BorderSizePixel = 0,
	}, wrapper)
	Utils.newInstance("UICorner", { CornerRadius = UDim.new(0.5, 0) }, track)

	local fill = Utils.newInstance("Frame", {
		Name            = "Fill",
		Size            = UDim2.new(value, 0, 1, 0),
		BackgroundColor3= color,
		BorderSizePixel = 0,
	}, track)
	Utils.newInstance("UICorner", { CornerRadius = UDim.new(0.5, 0) }, fill)

	-- Shimmer effect
	local shimmer = Utils.newInstance("Frame", {
		Name            = "Shimmer",
		Size            = UDim2.fromOffset(40, height),
		BackgroundColor3= Color3.new(1, 1, 1),
		BackgroundTransparency = 0.7,
		BorderSizePixel = 0,
		ClipsDescendants = false,
	}, fill)
	Utils.newInstance("UICorner", { CornerRadius = UDim.new(0.5, 0) }, shimmer)

	-- Animate shimmer
	local function animateShimmer()
		if not track.Parent then return end
		shimmer.Position = UDim2.fromOffset(-50, 0)
		Utils.tween(shimmer, 1.2, { Position = UDim2.new(1, 10, 0, 0) }, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
		task.delay(1.8, animateShimmer)
	end
	task.spawn(animateShimmer)

	-- Indeterminate mode
	if opts.Indeterminate then
		fill.Size = UDim2.new(0.35, 0, 1, 0)
		local function indAnim()
			if not track.Parent then return end
			fill.Position = UDim2.fromOffset(-width * 0.35, 0)
			Utils.tween(fill, 1.0, { Position = UDim2.fromOffset(width, 0) }, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut)
			task.delay(1.0, indAnim)
		end
		task.spawn(indAnim)
	end

	self.setValue = function(_, v: number)
		value = Utils.clamp(v, 0, 1)
		Utils.tween(fill, T.AnimSpeed * 2, { Size = UDim2.new(value, 0, 1, 0) })
		if self._pctLabel then
			self._pctLabel.Text = math.floor(value * 100) .. "%"
		end
		self:emit("ValueChanged", value)
	end
	self.getValue = function() return value end

	return self
end

-- ============================================================
--  NUMBER STEPPER
-- ============================================================
local NumberStepper = {}
NumberStepper.__index = NumberStepper
setmetatable(NumberStepper, { __index = BaseComponent })

function NumberStepper.new(parent: GuiObject, theme: ThemeConfig, opts: {
	Min:      number?,
	Max:      number?,
	Value:    number?,
	Step:     number?,
	Label:    string?,
	Width:    number?,
	OnChange: ((number) -> ())?,
})
	local self  = BaseComponent.new()
	setmetatable(self, NumberStepper)
	local T     = theme
	opts        = opts or {}

	local min   = opts.Min   or 0
	local max   = opts.Max   or 100
	local step  = opts.Step  or 1
	local value = Utils.clamp(opts.Value or min, min, max)
	local width = opts.Width or 160

	local wrapper = Utils.newInstance("Frame", {
		Name  = "NumberStepper",
		Size  = UDim2.fromOffset(width, opts.Label and 60 or 38),
		BackgroundTransparency = 1,
	}, parent)
	self.Instance = wrapper

	if opts.Label then
		Utils.newInstance("TextLabel", {
			Size       = UDim2.new(1, 0, 0, 22),
			BackgroundTransparency = 1,
			Text       = opts.Label,
			Font       = T.Font,
			TextSize   = T.TextSize,
			TextColor3 = T.TextPrimary,
			TextXAlignment = Enum.TextXAlignment.Left,
		}, wrapper)
	end

	local row = Utils.newInstance("Frame", {
		Size     = UDim2.fromOffset(width, 38),
		Position = opts.Label and UDim2.fromOffset(0, 26) or UDim2.fromOffset(0, 0),
		BackgroundColor3 = T.Surface,
		BorderSizePixel  = 0,
	}, wrapper)
	Utils.newInstance("UICorner", { CornerRadius = T.CornerRadius }, row)
	Utils.newInstance("UIStroke", { Color = T.Border, Thickness = 1 }, row)

	local BTN_W = 38
	local function makeBtn(text: string, xPos: number): TextButton
		local btn = Utils.newInstance("TextButton", {
			Size            = UDim2.fromOffset(BTN_W, 38),
			Position        = UDim2.fromOffset(xPos, 0),
			BackgroundTransparency = 1,
			Text            = text,
			Font            = T.FontBold,
			TextSize        = 20,
			TextColor3      = T.Accent,
			AutoButtonColor = false,
		}, row)
		btn.MouseEnter:Connect(function()
			Utils.tween(btn, T.AnimSpeed, { BackgroundTransparency = 0 })
			btn.BackgroundColor3 = T.SurfaceHover
		end)
		btn.MouseLeave:Connect(function()
			Utils.tween(btn, T.AnimSpeed, { BackgroundTransparency = 1 })
		end)
		return btn
	end

	local minusBtn = makeBtn("−", 0)
	local plusBtn  = makeBtn("+", width - BTN_W)

	-- Dividers
	Utils.newInstance("Frame", { Size = UDim2.fromOffset(1, 28), Position = UDim2.fromOffset(BTN_W, 5), BackgroundColor3 = T.Border, BorderSizePixel = 0 }, row)
	Utils.newInstance("Frame", { Size = UDim2.fromOffset(1, 28), Position = UDim2.fromOffset(width - BTN_W - 1, 5), BackgroundColor3 = T.Border, BorderSizePixel = 0 }, row)

	local valueBox = Utils.newInstance("TextBox", {
		Size            = UDim2.fromOffset(width - BTN_W * 2 - 2, 38),
		Position        = UDim2.fromOffset(BTN_W + 1, 0),
		BackgroundTransparency = 1,
		Text            = tostring(value),
		Font            = T.FontBold,
		TextSize        = T.TextSize,
		TextColor3      = T.TextPrimary,
		ClearTextOnFocus = false,
	}, row)

	local function updateDisplay()
		valueBox.Text = tostring(Utils.round(value, 4))
	end

	local function change(delta: number)
		if not self._enabled then return end
		value = Utils.clamp(value + delta, min, max)
		updateDisplay()
		self:emit("ValueChanged", value)
		if opts.OnChange then opts.OnChange(value) end
	end

	self:_conn(minusBtn.MouseButton1Click:Connect(function() change(-step) end))
	self:_conn(plusBtn.MouseButton1Click:Connect(function()  change(step)  end))
	self:_conn(valueBox.FocusLost:Connect(function()
		local n = tonumber(valueBox.Text)
		if n then
			value = Utils.clamp(n, min, max)
		end
		updateDisplay()
	end))

	-- Long-press for continuous change
	local pressing = false
	for _, btn in ipairs({minusBtn, plusBtn}) do
		local delta = btn == plusBtn and step or -step
		btn.InputBegan:Connect(function(input)
			if input.UserInputType ~= Enum.UserInputType.MouseButton1 and
			   input.UserInputType ~= Enum.UserInputType.Touch then return end
			pressing = true
			task.delay(0.5, function()
				while pressing do
					change(delta)
					task.wait(0.08)
				end
			end)
		end)
		btn.InputEnded:Connect(function() pressing = false end)
	end

	self.getValue = function() return value end
	self.setValue = function(_, v: number)
		value = Utils.clamp(v, min, max)
		updateDisplay()
	end

	return self
end

-- ============================================================
--  RADIO BUTTON GROUP
-- ============================================================
local RadioGroup = {}
RadioGroup.__index = RadioGroup
setmetatable(RadioGroup, { __index = BaseComponent })

function RadioGroup.new(parent: GuiObject, theme: ThemeConfig, opts: {
	Items:    {string | {Label: string, Value: any}},
	Value:    any?,
	Label:    string?,
	OnChange: ((any) -> ())?,
})
	local self    = BaseComponent.new()
	setmetatable(self, RadioGroup)
	local T       = theme
	opts          = opts or {}
	local value   = opts.Value
	local buttons = {}

	local function normalize(item): {Label: string, Value: any}
		if type(item) == "string" then return { Label = item, Value = item } end
		return item
	end

	local items = {}
	for _, v in ipairs(opts.Items or {}) do
		table.insert(items, normalize(v))
	end

	local wrapper = Utils.newInstance("Frame", {
		Name  = "RadioGroup",
		Size  = UDim2.fromOffset(220, #items * 34 + (opts.Label and 28 or 0)),
		BackgroundTransparency = 1,
		AutomaticSize = Enum.AutomaticSize.Y,
	}, parent)
	self.Instance = wrapper

	Utils.newInstance("UIListLayout", {
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding   = UDim.new(0, 6),
	}, wrapper)

	if opts.Label then
		Utils.newInstance("TextLabel", {
			Size       = UDim2.new(1, 0, 0, 22),
			BackgroundTransparency = 1,
			Text       = opts.Label,
			Font       = T.FontBold,
			TextSize   = T.TextSize,
			TextColor3 = T.TextPrimary,
			TextXAlignment = Enum.TextXAlignment.Left,
			LayoutOrder = 0,
		}, wrapper)
	end

	local function updateRadios()
		for _, data in ipairs(buttons) do
			local isSelected = data.item.Value == value
			Utils.tween(data.outer, T.AnimSpeed, { BackgroundColor3 = isSelected and T.Accent or T.Border })
			data.inner.Visible = isSelected
		end
	end

	for i, item in ipairs(items) do
		local row = Utils.newInstance("TextButton", {
			Name  = "Radio_" .. i,
			Size  = UDim2.new(1, 0, 0, 28),
			BackgroundTransparency = 1,
			Text  = "",
			AutoButtonColor = false,
			LayoutOrder = i,
		}, wrapper)

		local outer = Utils.newInstance("Frame", {
			Size            = UDim2.fromOffset(18, 18),
			AnchorPoint     = Vector2.new(0, 0.5),
			Position        = UDim2.new(0, 0, 0.5, 0),
			BackgroundColor3= T.Border,
			BorderSizePixel = 0,
		}, row)
		Utils.newInstance("UICorner", { CornerRadius = UDim.new(0.5, 0) }, outer)

		local inner = Utils.newInstance("Frame", {
			Size            = UDim2.fromOffset(8, 8),
			AnchorPoint     = Vector2.new(0.5, 0.5),
			Position        = UDim2.fromScale(0.5, 0.5),
			BackgroundColor3= T.TextOnAccent,
			BorderSizePixel = 0,
			Visible         = false,
		}, outer)
		Utils.newInstance("UICorner", { CornerRadius = UDim.new(0.5, 0) }, inner)

		Utils.newInstance("TextLabel", {
			Size            = UDim2.new(1, -28, 1, 0),
			Position        = UDim2.fromOffset(28, 0),
			BackgroundTransparency = 1,
			Text            = item.Label,
			Font            = T.Font,
			TextSize        = T.TextSize,
			TextColor3      = T.TextPrimary,
			TextXAlignment  = Enum.TextXAlignment.Left,
		}, row)

		table.insert(buttons, { outer = outer, inner = inner, item = item })

		self:_conn(row.MouseButton1Click:Connect(function()
			if not self._enabled then return end
			value = item.Value
			updateRadios()
			self:emit("ValueChanged", value)
			if opts.OnChange then opts.OnChange(value) end
		end))
	end

	updateRadios()
	self.getValue = function() return value end
	self.setValue = function(_, v: any)
		value = v
		updateRadios()
	end

	return self
end

-- ============================================================
--  ACCORDION / COLLAPSIBLE PANEL
-- ============================================================
local Accordion = {}
Accordion.__index = Accordion
setmetatable(Accordion, { __index = BaseComponent })

function Accordion.new(parent: GuiObject, theme: ThemeConfig, opts: {
	Title:    string,
	Width:    number?,
	Open:     boolean?,
	Content:  ((Frame) -> ())?,
})
	local self   = BaseComponent.new()
	setmetatable(self, Accordion)
	local T      = theme
	opts         = opts or {}
	local open   = opts.Open or false
	local width  = opts.Width or 280

	local wrapper = Utils.newInstance("Frame", {
		Name            = "Accordion",
		Size            = UDim2.fromOffset(width, 44),
		BackgroundColor3= T.Surface,
		BorderSizePixel = 0,
		ClipsDescendants= true,
	}, parent)
	self.Instance = wrapper
	Utils.newInstance("UICorner", { CornerRadius = T.CornerRadius }, wrapper)
	Utils.newInstance("UIStroke", { Color = T.Border, Thickness = 1 }, wrapper)

	-- Header
	local header = Utils.newInstance("TextButton", {
		Size            = UDim2.new(1, 0, 0, 44),
		BackgroundTransparency = 1,
		Text            = "",
		AutoButtonColor = false,
	}, wrapper)
	Utils.newInstance("UIPadding", { PaddingLeft = UDim.new(0, 14), PaddingRight = UDim.new(0, 14) }, header)

	Utils.newInstance("TextLabel", {
		Size       = UDim2.new(1, -24, 1, 0),
		BackgroundTransparency = 1,
		Text       = opts.Title,
		Font       = T.FontBold,
		TextSize   = T.TextSize,
		TextColor3 = T.TextPrimary,
		TextXAlignment = Enum.TextXAlignment.Left,
	}, header)

	local chevron = Utils.newInstance("TextLabel", {
		Size       = UDim2.fromOffset(20, 20),
		Position   = UDim2.new(1, -20, 0.5, -10),
		BackgroundTransparency = 1,
		Text       = "›",
		Font       = T.FontBold,
		TextSize   = 20,
		TextColor3 = T.TextSecondary,
	}, header)

	-- Content area
	local contentFrame = Utils.newInstance("Frame", {
		Name            = "Content",
		Size            = UDim2.new(1, 0, 0, 0),
		Position        = UDim2.fromOffset(0, 44),
		BackgroundTransparency = 1,
		AutomaticSize   = Enum.AutomaticSize.Y,
	}, wrapper)
	Utils.newInstance("UIPadding", {
		PaddingLeft   = UDim.new(0, 14),
		PaddingRight  = UDim.new(0, 14),
		PaddingBottom = UDim.new(0, 14),
	}, contentFrame)
	Utils.newInstance("UIListLayout", {
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding   = UDim.new(0, 8),
	}, contentFrame)

	if opts.Content then opts.Content(contentFrame) end

	-- Divider
	Utils.newInstance("Frame", {
		Size            = UDim2.new(1, -28, 0, 1),
		Position        = UDim2.fromOffset(14, 44),
		BackgroundColor3= T.Border,
		BorderSizePixel = 0,
	}, wrapper)

	local contentHeight = 0
	task.defer(function()
		contentHeight = contentFrame.AbsoluteSize.Y
	end)

	local function setOpen(v: boolean, animate: boolean)
		open = v
		local targetH = v and (44 + contentHeight + 14) or 44
		Utils.tween(chevron, T.AnimSpeed, { Rotation = v and 90 or 0 })
		if animate then
			Utils.tween(wrapper, T.AnimSpeed, { Size = UDim2.fromOffset(width, targetH) })
		else
			wrapper.Size = UDim2.fromOffset(width, targetH)
		end
		self:emit("Toggled", open)
	end

	self:_conn(header.MouseButton1Click:Connect(function()
		contentHeight = contentFrame.AbsoluteSize.Y
		setOpen(not open, true)
	end))

	setOpen(open, false)
	self.toggle  = function() setOpen(not open, true) end
	self.isOpen  = function() return open end

	return self
end

-- ============================================================
--  TAB SYSTEM
-- ============================================================
local TabSystem = {}
TabSystem.__index = TabSystem
setmetatable(TabSystem, { __index = BaseComponent })

function TabSystem.new(parent: GuiObject, theme: ThemeConfig, opts: {
	Width:  number?,
	Height: number?,
	Tabs:   {{Name: string, Icon: string?, Content: ((Frame) -> ())?}},
})
	local self     = BaseComponent.new()
	setmetatable(self, TabSystem)
	local T        = theme
	opts           = opts or {}
	local width    = opts.Width  or 400
	local height   = opts.Height or 300
	local active   = 1
	local pages    = {}

	local wrapper = Utils.newInstance("Frame", {
		Name            = "TabSystem",
		Size            = UDim2.fromOffset(width, height),
		BackgroundColor3= T.BackgroundSecond,
		BorderSizePixel = 0,
	}, parent)
	self.Instance = wrapper
	Utils.newInstance("UICorner", { CornerRadius = T.CornerRadius }, wrapper)
	Utils.newInstance("UIStroke", { Color = T.Border, Thickness = 1 }, wrapper)

	-- Tab bar
	local BAR_H = 44
	local tabBar = Utils.newInstance("Frame", {
		Name            = "TabBar",
		Size            = UDim2.new(1, 0, 0, BAR_H),
		BackgroundColor3= T.Background,
		BorderSizePixel = 0,
	}, wrapper)
	Utils.newInstance("UICorner", { CornerRadius = T.CornerRadius }, tabBar)
	-- Bottom override to keep corners only at top
	Utils.newInstance("Frame", {
		Size            = UDim2.new(1, 0, 0, BAR_H / 2),
		Position        = UDim2.fromOffset(0, BAR_H / 2),
		BackgroundColor3= T.Background,
		BorderSizePixel = 0,
	}, tabBar)

	local tabList = Utils.newInstance("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
	}, tabBar)
	Utils.newInstance("UIListLayout", {
		SortOrder       = Enum.SortOrder.LayoutOrder,
		FillDirection   = Enum.FillDirection.Horizontal,
		HorizontalAlignment = Enum.HorizontalAlignment.Left,
		VerticalAlignment   = Enum.VerticalAlignment.Center,
		Padding         = UDim.new(0, 4),
	}, tabList)
	Utils.newInstance("UIPadding", { PaddingLeft = UDim.new(0, 6), PaddingTop = UDim.new(0, 4), PaddingBottom = UDim.new(0, 4) }, tabList)

	-- Active indicator (animated underline)
	local indicator = Utils.newInstance("Frame", {
		Name            = "Indicator",
		Size            = UDim2.fromOffset(30, 3),
		Position        = UDim2.fromOffset(0, BAR_H - 3),
		BackgroundColor3= T.Accent,
		BorderSizePixel = 0,
		ZIndex          = 2,
	}, tabBar)
	Utils.newInstance("UICorner", { CornerRadius = UDim.new(1, 0) }, indicator)

	-- Content area
	local contentArea = Utils.newInstance("Frame", {
		Name            = "Content",
		Size            = UDim2.new(1, 0, 1, -BAR_H),
		Position        = UDim2.fromOffset(0, BAR_H),
		BackgroundTransparency = 1,
		ClipsDescendants = true,
	}, wrapper)

	local tabButtons = {}

	local function switchTo(idx: number, animate: boolean)
		if idx == active and not animate then return end
		local prev = active
		active = idx

		-- Update pages
		for i, page in ipairs(pages) do
			if i == idx then
				page.Visible = true
				if animate then
					page.Position = UDim2.fromOffset(width * (i > prev and 1 or -1), 0)
					Utils.tween(page, T.AnimSpeed, { Position = UDim2.fromOffset(0, 0) })
				else
					page.Position = UDim2.fromOffset(0, 0)
				end
			else
				if animate and i == prev then
					Utils.tween(page, T.AnimSpeed, {
						Position = UDim2.fromOffset(width * (prev < idx and -1 or 1), 0),
					})
					task.delay(T.AnimSpeed, function() if i ~= active then page.Visible = false end end)
				else
					page.Visible = false
				end
			end
		end

		-- Update tab buttons
		for i, tb in ipairs(tabButtons) do
			local isActive = i == idx
			Utils.tween(tb, T.AnimSpeed, {
				BackgroundTransparency = isActive and 0 or 1,
				TextColor3 = isActive and T.Accent or T.TextSecondary,
			})
		end

		-- Move indicator
		if tabButtons[idx] then
			local btn = tabButtons[idx]
			task.defer(function()
				local bx   = btn.AbsolutePosition.X - tabBar.AbsolutePosition.X
				local bw   = btn.AbsoluteSize.X
				Utils.tween(indicator, T.AnimSpeed, {
					Position = UDim2.fromOffset(bx + bw * 0.15, BAR_H - 3),
					Size     = UDim2.fromOffset(bw * 0.7, 3),
				})
			end)
		end

		self:emit("TabChanged", idx, opts.Tabs[idx] and opts.Tabs[idx].Name)
	end

	for i, tabDef in ipairs(opts.Tabs or {}) do
		-- Tab button
		local tabBtn = Utils.newInstance("TextButton", {
			Name            = "Tab_" .. i,
			Size            = UDim2.fromOffset(0, BAR_H - 8),
			AutomaticSize   = Enum.AutomaticSize.X,
			BackgroundColor3= T.Surface,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Text            = tabDef.Name,
			Font            = T.FontBold,
			TextSize        = T.TextSize,
			TextColor3      = T.TextSecondary,
			LayoutOrder     = i,
			ZIndex          = 2,
		}, tabList)
		Utils.newInstance("UICorner",  { CornerRadius = UDim.new(0, 8) }, tabBtn)
		Utils.newInstance("UIPadding", { PaddingLeft = UDim.new(0, 14), PaddingRight = UDim.new(0, 14) }, tabBtn)
		table.insert(tabButtons, tabBtn)

		self:_conn(tabBtn.MouseButton1Click:Connect(function()
			switchTo(i, true)
		end))

		-- Content page
		local page = Utils.newInstance("Frame", {
			Name            = "Page_" .. i,
			Size            = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			Visible         = i == 1,
			ClipsDescendants = true,
		}, contentArea)
		Utils.newInstance("UIPadding", {
			PaddingLeft   = UDim.new(0, 12),
			PaddingRight  = UDim.new(0, 12),
			PaddingTop    = UDim.new(0, 12),
			PaddingBottom = UDim.new(0, 12),
		}, page)
		Utils.newInstance("UIListLayout", {
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding   = UDim.new(0, 8),
		}, page)
		table.insert(pages, page)

		if tabDef.Content then tabDef.Content(page) end
	end

	switchTo(1, false)
	self.switchTo = function(_, idx: number) switchTo(idx, true) end
	self.getActive = function() return active end

	return self
end

-- ============================================================
--  COLOR PICKER
-- ============================================================
local ColorPicker = {}
ColorPicker.__index = ColorPicker
setmetatable(ColorPicker, { __index = BaseComponent })

function ColorPicker.new(parent: GuiObject, theme: ThemeConfig, opts: {
	Value:    Color3?,
	Label:    string?,
	Width:    number?,
	OnChange: ((Color3) -> ())?,
})
	local self   = BaseComponent.new()
	setmetatable(self, ColorPicker)
	local T      = theme
	opts         = opts or {}
	local width  = opts.Width or 260
	local H, S, V = Color3.toHSV(opts.Value or Color3.fromRGB(255, 0, 0))

	local wrapper = Utils.newInstance("Frame", {
		Name  = "ColorPicker",
		Size  = UDim2.fromOffset(width, opts.Label and 46 or 38),
		BackgroundTransparency = 1,
		ClipsDescendants = false,
	}, parent)
	self.Instance = wrapper

	if opts.Label then
		Utils.newInstance("TextLabel", {
			Size       = UDim2.new(1, 0, 0, 22),
			BackgroundTransparency = 1,
			Text       = opts.Label,
			Font       = T.Font,
			TextSize   = T.TextSize,
			TextColor3 = T.TextPrimary,
			TextXAlignment = Enum.TextXAlignment.Left,
		}, wrapper)
	end

	local SWATCH_H = 38
	local swatchRow = Utils.newInstance("Frame", {
		Size     = UDim2.fromOffset(width, SWATCH_H),
		Position = opts.Label and UDim2.fromOffset(0, 26) or UDim2.fromOffset(0, 0),
		BackgroundTransparency = 1,
	}, wrapper)

	-- Color preview swatch
	local swatch = Utils.newInstance("TextButton", {
		Size            = UDim2.fromOffset(SWATCH_H, SWATCH_H),
		BackgroundColor3= Utils.hsvToColor(H, S, V),
		BorderSizePixel = 0,
		Text            = "",
		AutoButtonColor = false,
	}, swatchRow)
	Utils.newInstance("UICorner",  { CornerRadius = T.CornerRadius }, swatch)
	Utils.newInstance("UIStroke",  { Color = T.Border, Thickness = 1 }, swatch)

	-- Hex input
	local hexInput = Utils.newInstance("TextBox", {
		Size            = UDim2.fromOffset(width - SWATCH_H - 8, SWATCH_H),
		Position        = UDim2.fromOffset(SWATCH_H + 8, 0),
		BackgroundColor3= T.Surface,
		BorderSizePixel = 0,
		Text            = Utils.colorToHex(Utils.hsvToColor(H, S, V)),
		PlaceholderText = "RRGGBB",
		Font            = T.Font,
		TextSize        = T.TextSize,
		TextColor3      = T.TextPrimary,
		ClearTextOnFocus = false,
	}, swatchRow)
	Utils.newInstance("UICorner",   { CornerRadius = T.CornerRadius }, hexInput)
	Utils.newInstance("UIStroke",   { Color = T.Border, Thickness = 1 }, hexInput)
	Utils.newInstance("UIPadding",  { PaddingLeft = UDim.new(0, 10) }, hexInput)

	-- Popup picker panel
	local PICKER_W = width
	local PICKER_H = 220
	local popup = Utils.newInstance("Frame", {
		Name            = "Popup",
		Size            = UDim2.fromOffset(PICKER_W, 0),
		Position        = UDim2.fromOffset(0, SWATCH_H + (opts.Label and 26 or 0) + 4),
		BackgroundColor3= T.Surface,
		BorderSizePixel = 0,
		Visible         = false,
		ClipsDescendants = true,
		ZIndex          = 30,
	}, wrapper)
	Utils.newInstance("UICorner",  { CornerRadius = T.CornerRadius }, popup)
	Utils.newInstance("UIStroke",  { Color = T.Border, Thickness = 1 }, popup)

	-- SV gradient (saturation x value)
	local SV_SIZE = PICKER_W - 16
	local svArea  = Utils.newInstance("Frame", {
		Size            = UDim2.fromOffset(SV_SIZE, 100),
		Position        = UDim2.fromOffset(8, 8),
		BackgroundColor3= Color3.fromHSV(H, 1, 1),
		BorderSizePixel = 0,
		ZIndex          = 31,
	}, popup)
	Utils.newInstance("UICorner", { CornerRadius = UDim.new(0, 6) }, svArea)

	-- White gradient (left)
	local whiteGrad = Utils.newInstance("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.new(1, 1, 1),
		BorderSizePixel = 0,
		ZIndex = 31,
	}, svArea)
	Utils.newInstance("UICorner", { CornerRadius = UDim.new(0, 6) }, whiteGrad)
	Utils.newInstance("UIGradient", {
		Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, Color3.new(1,1,1)), ColorSequenceKeypoint.new(1, Color3.new(1,1,1,)) }),
		Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1)}),
		Rotation = 0,
	}, whiteGrad)

	-- Black gradient (bottom)
	local blackGrad = Utils.newInstance("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.new(0, 0, 0),
		BorderSizePixel = 0,
		ZIndex = 32,
	}, svArea)
	Utils.newInstance("UICorner", { CornerRadius = UDim.new(0, 6) }, blackGrad)
	Utils.newInstance("UIGradient", {
		Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, Color3.new(0,0,0)), ColorSequenceKeypoint.new(1, Color3.new(0,0,0)) }),
		Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(1, 0)}),
		Rotation = 270,
	}, blackGrad)

	-- SV cursor
	local svCursor = Utils.newInstance("Frame", {
		Size            = UDim2.fromOffset(12, 12),
		AnchorPoint     = Vector2.new(0.5, 0.5),
		BackgroundColor3= Color3.new(1,1,1),
		BorderSizePixel = 0,
		ZIndex          = 33,
	}, svArea)
	Utils.newInstance("UICorner", { CornerRadius = UDim.new(0.5, 0) }, svCursor)
	Utils.newInstance("UIStroke", { Color = Color3.new(0,0,0), Thickness = 2 }, svCursor)

	-- Hue bar
	local hueBar = Utils.newInstance("Frame", {
		Size            = UDim2.fromOffset(SV_SIZE, 16),
		Position        = UDim2.fromOffset(8, 116),
		BackgroundColor3= Color3.new(1, 0, 0),
		BorderSizePixel = 0,
		ZIndex          = 31,
	}, popup)
	Utils.newInstance("UICorner", { CornerRadius = UDim.new(0.5, 0) }, hueBar)

	local hueColors = {}
	for i = 0, 6 do
		table.insert(hueColors, ColorSequenceKeypoint.new(i/6, Color3.fromHSV(i/6, 1, 1)))
	end
	Utils.newInstance("UIGradient", {
		Color    = ColorSequence.new(hueColors),
		Rotation = 0,
	}, hueBar)

	local hueCursor = Utils.newInstance("Frame", {
		Size            = UDim2.fromOffset(8, 24),
		AnchorPoint     = Vector2.new(0.5, 0.5),
		Position        = UDim2.new(H, 0, 0.5, 0),
		BackgroundColor3= Color3.new(1, 1, 1),
		BorderSizePixel = 0,
		ZIndex          = 32,
	}, hueBar)
	Utils.newInstance("UICorner", { CornerRadius = UDim.new(0, 3) }, hueCursor)
	Utils.newInstance("UIStroke", { Color = Color3.new(0,0,0), Thickness = 1 }, hueCursor)

	local function getColor(): Color3
		return Color3.fromHSV(H, S, V)
	end

	local function updateUI()
		local color = getColor()
		swatch.BackgroundColor3 = color
		hexInput.Text           = Utils.colorToHex(color)
		svArea.BackgroundColor3 = Color3.fromHSV(H, 1, 1)
		svCursor.Position       = UDim2.fromScale(S, 1 - V)
		hueCursor.Position      = UDim2.new(H, 0, 0.5, 0)
		self:emit("ValueChanged", color)
		if opts.OnChange then opts.OnChange(color) end
	end

	-- SV dragging
	local svDrag = false
	svArea.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			svDrag = true
		end
	end)

	local function updateSV(px: number, py: number)
		if not svDrag then return end
		local ap = svArea.AbsolutePosition
		local as = svArea.AbsoluteSize
		S = Utils.clamp((px - ap.X) / as.X, 0, 1)
		V = 1 - Utils.clamp((py - ap.Y) / as.Y, 0, 1)
		updateUI()
	end

	self:_conn(UserInputService.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
			updateSV(input.Position.X, input.Position.Y)
		end
	end))

	-- Hue dragging
	local hueDrag = false
	hueBar.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			hueDrag = true
		end
	end)

	self:_conn(UserInputService.InputChanged:Connect(function(input)
		if not hueDrag then return end
		local ap = hueBar.AbsolutePosition
		local as = hueBar.AbsoluteSize
		H = Utils.clamp((input.Position.X - ap.X) / as.X, 0, 1)
		updateUI()
	end))

	self:_conn(UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			svDrag  = false
			hueDrag = false
		end
	end))

	-- Hex input
	hexInput.FocusLost:Connect(function()
		local ok, color = pcall(Utils.hexToColor, hexInput.Text)
		if ok then
			H, S, V = Color3.toHSV(color)
			updateUI()
		end
	end)

	-- Toggle popup
	local popupOpen = false
	swatch.MouseButton1Click:Connect(function()
		popupOpen = not popupOpen
		popup.Visible = popupOpen
		if popupOpen then
			Utils.tween(popup, T.AnimSpeed, { Size = UDim2.fromOffset(PICKER_W, PICKER_H) })
		else
			Utils.tween(popup, T.AnimSpeed, { Size = UDim2.fromOffset(PICKER_W, 0) })
			task.delay(T.AnimSpeed, function() popup.Visible = false end)
		end
	end)

	updateUI()
	self.getValue = function() return getColor() end
	self.setValue = function(_, color: Color3)
		H, S, V = Color3.toHSV(color)
		updateUI()
	end

	return self
end

-- ============================================================
--  SCROLL FRAME  (custom scrollbars)
-- ============================================================
local ScrollFrameComp = {}
ScrollFrameComp.__index = ScrollFrameComp
setmetatable(ScrollFrameComp, { __index = BaseComponent })

function ScrollFrameComp.new(parent: GuiObject, theme: ThemeConfig, opts: {
	Size:    UDim2?,
	Padding: number?,
	Spacing: number?,
	Horizontal: boolean?,
})
	local self   = BaseComponent.new()
	setmetatable(self, ScrollFrameComp)
	local T      = theme
	opts         = opts or {}
	local pad    = opts.Padding or 10
	local horiz  = opts.Horizontal or false

	local sf = Utils.newInstance("ScrollingFrame", {
		Name            = "ScrollFrame",
		Size            = opts.Size or UDim2.fromOffset(300, 200),
		BackgroundColor3= T.BackgroundSecond,
		BorderSizePixel = 0,
		ScrollBarThickness = 4,
		ScrollBarImageColor3 = T.ScrollBar,
		CanvasSize           = UDim2.fromOffset(0, 0),
		AutomaticCanvasSize  = horiz and Enum.AutomaticSize.X or Enum.AutomaticSize.Y,
		ScrollingDirection   = horiz and Enum.ScrollingDirection.X or Enum.ScrollingDirection.Y,
		ElasticBehavior      = Enum.ElasticBehavior.WhenScrollable,
	}, parent)
	Utils.newInstance("UICorner",  { CornerRadius = T.CornerRadius }, sf)
	Utils.newInstance("UIPadding", {
		PaddingLeft   = UDim.new(0, pad),
		PaddingRight  = UDim.new(0, pad),
		PaddingTop    = UDim.new(0, pad),
		PaddingBottom = UDim.new(0, pad),
	}, sf)
	Utils.newInstance("UIListLayout", {
		SortOrder     = Enum.SortOrder.LayoutOrder,
		FillDirection = horiz and Enum.FillDirection.Horizontal or Enum.FillDirection.Vertical,
		Padding       = UDim.new(0, opts.Spacing or 8),
	}, sf)

	self.Instance    = sf
	self.ContentFrame = sf  -- convenience alias

	function self:addChild(instance: Instance)
		instance.Parent = sf
	end

	return self
end

-- ============================================================
--  UI WINDOW  (main draggable frame)
-- ============================================================
local UIWindow = {}
UIWindow.__index = UIWindow
setmetatable(UIWindow, { __index = BaseComponent })

function UIWindow.new(screenGui: ScreenGui, theme: ThemeConfig, opts: WindowOptions?)
	local self   = BaseComponent.new()
	setmetatable(self, UIWindow)
	local T      = theme
	opts         = opts or {}

	local width  = opts.Size and opts.Size.X.Offset or 480
	local height = opts.Size and opts.Size.Y.Offset or 360
	local TITLE_H = 44

	-- Shadow frame
	local shadow = Utils.newInstance("Frame", {
		Name            = "WindowShadow",
		Size            = UDim2.fromOffset(width + 20, height + 20),
		Position        = opts.Position or UDim2.fromOffset(80, 60),
		AnchorPoint     = Vector2.new(0, 0),
		BackgroundColor3= T.WindowShadow,
		BackgroundTransparency = 0.5,
		BorderSizePixel = 0,
		ZIndex          = 1,
	}, screenGui)
	Utils.newInstance("UICorner", { CornerRadius = UDim.new(0, 14) }, shadow)
	Utils.newInstance("UIBlur",   {}):Destroy()  -- just in case

	-- Window frame
	local window = Utils.newInstance("Frame", {
		Name            = "Window",
		Size            = UDim2.fromOffset(width, height),
		Position        = opts.Position or UDim2.fromOffset(80, 60),
		BackgroundColor3= T.Background,
		BorderSizePixel = 0,
		ZIndex          = 2,
		ClipsDescendants = true,
	}, screenGui)
	Utils.newInstance("UICorner", { CornerRadius = UDim.new(0, 12) }, window)
	Utils.newInstance("UIStroke", { Color = T.Border, Thickness = 1 }, window)
	self.Instance = window

	-- Keep shadow synced
	local function syncShadow()
		shadow.Position = UDim2.fromOffset(window.AbsolutePosition.X - 10, window.AbsolutePosition.Y - 10)
		shadow.Size     = UDim2.fromOffset(window.AbsoluteSize.X + 20, window.AbsoluteSize.Y + 20)
	end

	-- Title bar
	local titleBar = Utils.newInstance("Frame", {
		Name            = "TitleBar",
		Size            = UDim2.new(1, 0, 0, TITLE_H),
		BackgroundColor3= T.TitleBar,
		BorderSizePixel = 0,
		ZIndex          = 3,
	}, window)
	Utils.newInstance("UIPadding", {
		PaddingLeft  = UDim.new(0, 14),
		PaddingRight = UDim.new(0, 10),
	}, titleBar)

	-- Window icon (optional)
	local iconOffset = 0
	if opts.Icon then
		local icon = Utils.newInstance("ImageLabel", {
			Size            = UDim2.fromOffset(18, 18),
			AnchorPoint     = Vector2.new(0, 0.5),
			Position        = UDim2.new(0, 0, 0.5, 0),
			BackgroundTransparency = 1,
			Image           = opts.Icon,
			ZIndex          = 4,
		}, titleBar)
		iconOffset = 26
	end

	-- Title text
	local titleLabel = Utils.newInstance("TextLabel", {
		Name            = "Title",
		Size            = UDim2.new(1, -(80 + iconOffset), 1, 0),
		Position        = UDim2.fromOffset(iconOffset, 0),
		BackgroundTransparency = 1,
		Text            = opts.Title or "Window",
		Font            = T.FontBold,
		TextSize        = T.TitleSize,
		TextColor3      = T.TitleText,
		TextXAlignment  = Enum.TextXAlignment.Left,
		ZIndex          = 4,
	}, titleBar)

	-- Window controls (close, minimize)
	local controls = Utils.newInstance("Frame", {
		Size            = UDim2.fromOffset(64, 28),
		AnchorPoint     = Vector2.new(1, 0.5),
		Position        = UDim2.new(1, 0, 0.5, 0),
		BackgroundTransparency = 1,
		ZIndex          = 4,
	}, titleBar)
	Utils.newInstance("UIListLayout", {
		FillDirection       = Enum.FillDirection.Horizontal,
		HorizontalAlignment = Enum.HorizontalAlignment.Right,
		VerticalAlignment   = Enum.VerticalAlignment.Center,
		Padding             = UDim.new(0, 6),
	}, controls)

	local function makeCtrlBtn(text: string, color: Color3): TextButton
		local btn = Utils.newInstance("TextButton", {
			Size            = UDim2.fromOffset(24, 24),
			BackgroundColor3= T.SurfaceHover,
			BorderSizePixel = 0,
			Text            = text,
			Font            = T.FontBold,
			TextSize        = 14,
			TextColor3      = T.TextSecondary,
			AutoButtonColor = false,
			ZIndex          = 5,
		}, controls)
		Utils.newInstance("UICorner", { CornerRadius = UDim.new(0.5, 0) }, btn)
		btn.MouseEnter:Connect(function()
			Utils.tween(btn, T.AnimSpeed, { BackgroundColor3 = color, TextColor3 = T.TextOnAccent })
		end)
		btn.MouseLeave:Connect(function()
			Utils.tween(btn, T.AnimSpeed, { BackgroundColor3 = T.SurfaceHover, TextColor3 = T.TextSecondary })
		end)
		return btn
	end

	local minimized = false
	local minBtn    = makeCtrlBtn("−", T.Warning)
	local closeBtn  = makeCtrlBtn("✕", T.Error)

	self:_conn(minBtn.MouseButton1Click:Connect(function()
		minimized = not minimized
		local targetH = minimized and TITLE_H or height
		Utils.tween(window, T.AnimSpeed, { Size = UDim2.fromOffset(width, targetH) })
		task.defer(syncShadow)
		self:emit(minimized and "Minimized" or "Restored")
	end))

	self:_conn(closeBtn.MouseButton1Click:Connect(function()
		if opts.CloseConfirm then
			-- Show in-window confirm (simple approach)
			self:emit("CloseRequested")
		else
			self:close()
		end
	end))

	-- Divider under title
	Utils.newInstance("Frame", {
		Name            = "Divider",
		Size            = UDim2.new(1, 0, 0, 1),
		Position        = UDim2.fromOffset(0, TITLE_H),
		BackgroundColor3= T.Border,
		BorderSizePixel = 0,
		ZIndex          = 3,
	}, window)

	-- Content area
	local content = Utils.newInstance("Frame", {
		Name            = "Content",
		Size            = UDim2.new(1, 0, 1, -(TITLE_H + 1)),
		Position        = UDim2.fromOffset(0, TITLE_H + 1),
		BackgroundTransparency = 1,
		ZIndex          = 2,
		ClipsDescendants = false,
	}, window)
	self.Content = content

	-- Drag system
	self._drag = DragManager.new(window, titleBar, {
		snapToEdge    = opts.SnapToEdge or false,
		snapThreshold = 20,
	})
	self._drag:onDragEnd(syncShadow)

	-- Entry animation
	window.BackgroundTransparency = 1
	window.Size = UDim2.fromOffset(width, height * 0.9)
	Utils.tween(window, T.AnimSpeed * 1.5, {
		BackgroundTransparency = 0,
		Size = UDim2.fromOffset(width, height),
	}, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
	Utils.tween(shadow, T.AnimSpeed * 1.5, { BackgroundTransparency = 0.72 })

	syncShadow()

	-- Public API
	self.TitleLabel = titleLabel
	self._shadow    = shadow
	self._width     = width
	self._height    = height

	function self:setTitle(t: string)
		titleLabel.Text = t
	end

	function self:resize(w: number, h: number)
		self._width  = w
		self._height = h
		Utils.tween(window, T.AnimSpeed, { Size = UDim2.fromOffset(w, h) })
		task.delay(T.AnimSpeed, syncShadow)
	end

	function self:bringToFront()
		window.ZIndex = window.ZIndex + 1
		shadow.ZIndex = shadow.ZIndex + 1
	end

	function self:close()
		Utils.tween(window, T.AnimSpeed, {
			BackgroundTransparency = 1,
			Size = UDim2.fromOffset(self._width, self._height * 0.9),
		}, Enum.EasingStyle.Back, Enum.EasingDirection.In)
		Utils.tween(shadow, T.AnimSpeed, { BackgroundTransparency = 1 })
		task.delay(T.AnimSpeed, function()
			self._drag:destroy()
			Utils.destroySafe(window)
			Utils.destroySafe(shadow)
		end)
		self:emit("Closed")
	end

	return self
end

-- ============================================================
--  NEXUS UI  (main library entry point)
-- ============================================================
local NexusUI = {}
NexusUI.__index = NexusUI

function NexusUI.new(opts: {
	Theme:      string?,
	Parent:     Instance?,
	Name:       string?,
})
	local self       = setmetatable({}, NexusUI)
	opts             = opts or {}

	-- ScreenGui setup
	local gui = Instance.new("ScreenGui")
	gui.Name                = opts.Name or "NexusUI"
	gui.ResetOnSpawn        = false
	gui.ZIndexBehavior      = Enum.ZIndexBehavior.Sibling
	gui.IgnoreGuiInset      = false
	gui.DisplayOrder        = 10
	gui.Parent              = opts.Parent or (game:GetService("Players").LocalPlayer:FindFirstChildOfClass("PlayerGui") or game:GetService("CoreGui"))

	self._gui     = gui
	self._theme   = ThemeManager.new(opts.Theme)
	self._tooltip = TooltipSystem.new(self._theme:get(), gui)
	self._notif   = NotificationSystem.new(self._theme:get(), gui)
	self._modal   = ModalSystem.new(self._theme:get(), gui)
	self._ctxMenu = ContextMenu.new(self._theme:get(), gui)
	self._windows = {}

	-- Reapply subsystems when theme changes
	self._theme:onChange(function(newTheme)
		self._tooltip:destroy()
		self._notif:destroy()
		self._tooltip = TooltipSystem.new(newTheme, gui)
		self._notif   = NotificationSystem.new(newTheme, gui)
		self._modal   = ModalSystem.new(newTheme, gui)
		self._ctxMenu = ContextMenu.new(newTheme, gui)
	end)

	return self
end

-- Theme management
function NexusUI:setTheme(preset: string | ThemeConfig)
	self._theme:apply(preset)
end

function NexusUI:getTheme(): ThemeConfig
	return self._theme:get()
end

-- Create a window
function NexusUI:createWindow(opts: WindowOptions?): UIWindow
	local win = UIWindow.new(self._gui, self._theme:get(), opts)
	table.insert(self._windows, win)
	win:on("Closed", function()
		for i, w in ipairs(self._windows) do
			if w == win then table.remove(self._windows, i); break end
		end
	end)
	return win
end

-- Create components in any parent
function NexusUI:button(parent: GuiObject, opts: ButtonOptions): Button
	return Button.new(parent, self._theme:get(), opts)
end

function NexusUI:toggle(parent: GuiObject, opts: any): Toggle
	return Toggle.new(parent, self._theme:get(), opts)
end

function NexusUI:slider(parent: GuiObject, opts: any): Slider
	return Slider.new(parent, self._theme:get(), opts)
end

function NexusUI:dropdown(parent: GuiObject, opts: any): Dropdown
	return Dropdown.new(parent, self._theme:get(), opts)
end

function NexusUI:textbox(parent: GuiObject, opts: any): TextBoxComp
	return TextBoxComp.new(parent, self._theme:get(), opts)
end

function NexusUI:checkbox(parent: GuiObject, opts: any): Checkbox
	return Checkbox.new(parent, self._theme:get(), opts)
end

function NexusUI:progressBar(parent: GuiObject, opts: any): ProgressBar
	return ProgressBar.new(parent, self._theme:get(), opts)
end

function NexusUI:numberStepper(parent: GuiObject, opts: any): NumberStepper
	return NumberStepper.new(parent, self._theme:get(), opts)
end

function NexusUI:radioGroup(parent: GuiObject, opts: any): RadioGroup
	return RadioGroup.new(parent, self._theme:get(), opts)
end

function NexusUI:accordion(parent: GuiObject, opts: any): Accordion
	return Accordion.new(parent, self._theme:get(), opts)
end

function NexusUI:tabSystem(parent: GuiObject, opts: any): TabSystem
	return TabSystem.new(parent, self._theme:get(), opts)
end

function NexusUI:colorPicker(parent: GuiObject, opts: any): ColorPicker
	return ColorPicker.new(parent, self._theme:get(), opts)
end

function NexusUI:scrollFrame(parent: GuiObject, opts: any): ScrollFrameComp
	return ScrollFrameComp.new(parent, self._theme:get(), opts)
end

function NexusUI:spinner(parent: GuiObject, opts: any): LoadingSpinner
	return LoadingSpinner.new(parent, self._theme:get(), opts)
end

-- Notifications
function NexusUI:notify(opts: any)
	self._notif:show(opts)
end

function NexusUI:success(message: string, title: string?)
	self._notif:show({ Title = title or "Success", Message = message, Type = "success" })
end

function NexusUI:error(message: string, title: string?)
	self._notif:show({ Title = title or "Error", Message = message, Type = "error" })
end

function NexusUI:warn(message: string, title: string?)
	self._notif:show({ Title = title or "Warning", Message = message, Type = "warning" })
end

function NexusUI:info(message: string, title: string?)
	self._notif:show({ Title = title or "Info", Message = message, Type = "info" })
end

-- Modals
function NexusUI:showModal(opts: any): () -> ()
	return self._modal:show(opts)
end

function NexusUI:confirm(title: string, message: string, onConfirm: () -> (), onCancel: (() -> ())?): () -> ()
	return self._modal:confirm(title, message, onConfirm, onCancel)
end

-- Context menu
function NexusUI:showContextMenu(items: any, position: Vector2)
	self._ctxMenu:show(items, position)
end

-- Tooltip attachment
function NexusUI:tooltip(target: GuiObject, text: string, delay: number?): () -> ()
	return self._tooltip:attach(target, text, delay)
end

-- Right-click context menu helper
function NexusUI:attachContextMenu(target: GuiObject, items: any)
	target.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton2 then
			local mp = UserInputService:GetMouseLocation()
			self._ctxMenu:show(items, mp)
		end
	end)
end

-- Destroy everything
function NexusUI:destroy()
	for _, w in ipairs(self._windows) do
		w:destroy()
	end
	self._tooltip:destroy()
	self._notif:destroy()
	Utils.destroySafe(self._gui)
end

-- ============================================================
--  EXPORTS
-- ============================================================
--// MAIN OBJECT
local NexusUI = {}

--// CREATE WINDOW (MAIN ENTRY)
function NexusUI:CreateWindow(config)
    config = config or {}

    local Window = UIWindow.new(config)

    -- Auto parent fix (executor safe)
    if Window and Window.ScreenGui then
        Window.ScreenGui.Parent = game.CoreGui
    end

    return Window
end

--// COMPONENT EXPORTS (OPTIONAL ACCESS)
NexusUI.Button        = Button.new
NexusUI.Toggle        = Toggle.new
NexusUI.Slider        = Slider.new
NexusUI.Dropdown      = Dropdown.new
NexusUI.TextBox       = TextBoxComp.new
NexusUI.Checkbox      = Checkbox.new
NexusUI.ProgressBar   = ProgressBar.new
NexusUI.NumberStepper = NumberStepper.new
NexusUI.RadioGroup    = RadioGroup.new
NexusUI.Accordion     = Accordion.new
NexusUI.TabSystem     = TabSystem.new
NexusUI.ColorPicker   = ColorPicker.new
NexusUI.ScrollFrame   = ScrollFrameComp.new
NexusUI.UIWindow      = UIWindow.new
NexusUI.Spinner       = LoadingSpinner.new
NexusUI.Notification  = NotificationSystem.new
NexusUI.Modal         = ModalSystem.new
NexusUI.Tooltip       = TooltipSystem.new
NexusUI.ContextMenu   = ContextMenu.new

--// REQUIRED RETURN
return NexusUI

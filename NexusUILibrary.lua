--[[
╔══════════════════════════════════════════════════════════════════════════════╗
║                         NEXUS UI LIBRARY v1.2                               ║
║                   Professional Roblox UI Framework                          ║
║                                                                              ║
║  Features: Windows, Buttons, Toggles, Sliders, Dropdowns, TextBoxes,       ║
║            Checkboxes, ProgressBars, ScrollFrames, Tabs, Modals,            ║
║            Toasts, Accordions, ColorPicker, Stepper, Radio, Tooltip,        ║
║            ContextMenu, LoadingSpinner                                       ║
║                                                                              ║
║  Devices:  PC (Mouse), Mobile/Tablet (Touch), Console (Gamepad)             ║
║                                                                              ║
║  Fixed v1.2:                                                                ║
║    - Window now shows: no transparency tween, uses size/position anim       ║
║    - loadstring safe: CoreGui first, PlayerGui async fallback               ║
║    - Memory leaks: gamepad Heartbeat gated, spinner loops use Heartbeat     ║
║    - Modal: fixed broken click-outside, added full destroy/tracking         ║
║    - ContextMenu: added destroy method, fixed UIStroke bleed               ║
║    - NexusUI:destroy() cleans theme listener, modal, ctxMenu               ║
║    - Window:close() destroys all children, cleans up drag/shadow            ║
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
local Players            = game:GetService("Players")

-- ============================================================
--  UTILITIES
-- ============================================================
local Utils = {}

function Utils.tween(instance, time, goals, style, dir)
	local info = TweenInfo.new(
		time,
		style  or Enum.EasingStyle.Quart,
		dir    or Enum.EasingDirection.Out
	)
	local t = TweenService:Create(instance, info, goals)
	t:Play()
	return t
end

function Utils.lerp(a, b, t) return a + (b - a) * t end
function Utils.clamp(v, min, max) return math.max(min, math.min(max, v)) end
function Utils.round(n, decimals)
	local factor = 10 ^ (decimals or 0)
	return math.floor(n * factor + 0.5) / factor
end

function Utils.isMobile()
	return UserInputService.TouchEnabled and not UserInputService.MouseEnabled
end
function Utils.isConsole()
	return UserInputService.GamepadEnabled and not UserInputService.MouseEnabled and not UserInputService.TouchEnabled
end
function Utils.isPC() return UserInputService.MouseEnabled end
function Utils.getDeviceType()
	if Utils.isConsole() then return "Console"
	elseif Utils.isMobile() then return "Mobile"
	else return "PC" end
end
function Utils.getViewport() return workspace.CurrentCamera.ViewportSize end
function Utils.scaleFactor()
	local vp = Utils.getViewport()
	return math.clamp(vp.Y / 1080, 0.5, 2.0)
end

function Utils.newInstance(className, props, parent)
	local inst = Instance.new(className)
	for k, v in pairs(props) do
		inst[k] = v
	end
	if parent then inst.Parent = parent end
	return inst
end

function Utils.destroySafe(inst)
	if inst and inst.Parent then inst:Destroy() end
end

function Utils.hexToColor(hex)
	hex = hex:gsub("#", "")
	local r = tonumber(hex:sub(1,2), 16) or 0
	local g = tonumber(hex:sub(3,4), 16) or 0
	local b = tonumber(hex:sub(5,6), 16) or 0
	return Color3.fromRGB(r, g, b)
end

function Utils.colorToHex(c)
	return string.format("%02X%02X%02X",
		math.floor(c.R * 255),
		math.floor(c.G * 255),
		math.floor(c.B * 255))
end

-- ============================================================
--  EVENT EMITTER
-- ============================================================
local EventEmitter = {}
EventEmitter.__index = EventEmitter

function EventEmitter.new()
	return setmetatable({ _listeners = {} }, EventEmitter)
end

function EventEmitter:on(event, fn)
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

function EventEmitter:emit(event, ...)
	if self._listeners[event] then
		for _, fn in pairs(self._listeners[event]) do
			task.spawn(fn, ...)
		end
	end
end

function EventEmitter:once(event, fn)
	local unsub
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

function ThemeManager.new(preset)
	local self = setmetatable({}, ThemeManager)
	self._theme   = {}
	self._emitter = EventEmitter.new()
	self:apply(preset or "Dark")
	return self
end

function ThemeManager:apply(preset)
	if type(preset) == "string" then
		local p = ThemeManager.Presets[preset]
		assert(p, "Unknown theme preset: " .. tostring(preset))
		for k, v in pairs(p) do self._theme[k] = v end
	else
		for k, v in pairs(preset) do self._theme[k] = v end
	end
	self._emitter:emit("Changed", self._theme)
end

function ThemeManager:get() return self._theme end
function ThemeManager:onChange(fn) return self._emitter:on("Changed", fn) end

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
	self.Instance   = nil
	return self
end

function BaseComponent:on(event, fn)   return self._emitter:on(event, fn) end
function BaseComponent:once(event, fn) self._emitter:once(event, fn) end
function BaseComponent:emit(event, ...) self._emitter:emit(event, ...) end

function BaseComponent:setEnabled(v)
	self._enabled = v
	self:emit("EnabledChanged", v)
end

function BaseComponent:setVisible(v)
	self._visible = v
	if self.Instance then self.Instance.Visible = v end
	self:emit("VisibilityChanged", v)
end

function BaseComponent:_conn(c)
	table.insert(self._conns, c)
end

function BaseComponent:destroy()
	for _, c in ipairs(self._conns) do pcall(function() c:Disconnect() end) end
	self._conns = {}
	if self.Instance then
		Utils.destroySafe(self.Instance)
		self.Instance = nil
	end
	self._emitter = EventEmitter.new()
end

-- ============================================================
--  DRAG MANAGER  (PC + Touch + Console)
-- ============================================================
local DragManager = {}
DragManager.__index = DragManager

function DragManager.new(frame, handle, opts)
	local self   = setmetatable({}, DragManager)
	opts         = opts or {}
	self._frame  = frame
	self._handle = handle or frame
	self._conns  = {}
	self._opts   = {
		snapToEdge    = opts.snapToEdge    or false,
		snapThreshold = opts.snapThreshold or 20,
		momentum      = opts.momentum ~= false,
		damping       = opts.damping  or 0.85,
	}
	self._dragging = false
	self._velocity = Vector2.new(0, 0)
	self._lastPos  = Vector2.new(0, 0)
	self._emitter  = EventEmitter.new()
	self:_setup()
	return self
end

function DragManager:_setup()
	local frame  = self._frame
	local handle = self._handle

	local function clampToScreen(pos)
		local size   = frame.AbsoluteSize
		local screen = Utils.getViewport()
		local inset  = GuiService:GetGuiInset()
		return Vector2.new(
			Utils.clamp(pos.X, 0, screen.X - size.X),
			Utils.clamp(pos.Y, inset.Y, screen.Y - size.Y)
		)
	end

	local function setFramePos(pos)
		local clamped = clampToScreen(pos)
		frame.Position = UDim2.fromOffset(clamped.X, clamped.Y)
	end

	local function snapEdge(pos)
		if not self._opts.snapToEdge then return pos end
		local screen    = Utils.getViewport()
		local size      = frame.AbsoluteSize
		local threshold = self._opts.snapThreshold
		local x, y     = pos.X, pos.Y
		if x < threshold then x = 0
		elseif screen.X - size.X - x < threshold then x = screen.X - size.X end
		if y < threshold then y = 0
		elseif screen.Y - size.Y - y < threshold then y = screen.Y - size.Y end
		return Vector2.new(x, y)
	end

	local dragStart
	local startPos

	local function beginDrag(input)
		self._dragging = true
		self._velocity = Vector2.new(0, 0)
		dragStart = input.Position
		startPos  = frame.Position
		self._emitter:emit("DragStart")
	end

	local function updateDrag(input)
		if not self._dragging then return end
		local delta = Vector2.new(input.Position.X - dragStart.X, input.Position.Y - dragStart.Y)
		self._velocity = Vector2.new(input.Position.X - self._lastPos.X, input.Position.Y - self._lastPos.Y)
		self._lastPos  = Vector2.new(input.Position.X, input.Position.Y)
		setFramePos(Vector2.new(startPos.X.Offset + delta.X, startPos.Y.Offset + delta.Y))
	end

	local function endDrag()
		if not self._dragging then return end
		self._dragging = false
		if self._opts.momentum then
			local vel = self._velocity
			local conn
			conn = RunService.Heartbeat:Connect(function()
				if vel.Magnitude < 0.5 then
					conn:Disconnect()
					setFramePos(snapEdge(frame.AbsolutePosition))
					return
				end
				vel = vel * self._opts.damping
				local cur = frame.AbsolutePosition
				setFramePos(Vector2.new(cur.X + vel.X, cur.Y + vel.Y))
			end)
		else
			setFramePos(snapEdge(frame.AbsolutePosition))
		end
		self._emitter:emit("DragEnd")
	end

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

	-- Console gamepad L-stick - only active when gamepad is present and dragging
	if UserInputService.GamepadEnabled then
		local GAMEPAD_SPEED = 8
		table.insert(self._conns, RunService.Heartbeat:Connect(function()
			if not self._dragging then return end
			local ok, state = pcall(function()
				return UserInputService:GetGamepadState(Enum.UserInputType.Gamepad1)
			end)
			if not ok then return end
			for _, s in ipairs(state) do
				if s.KeyCode == Enum.KeyCode.Thumbstick1 and s.Position.Magnitude > 0.2 then
					local cur = frame.AbsolutePosition
					setFramePos(Vector2.new(cur.X + s.Position.X * GAMEPAD_SPEED, cur.Y - s.Position.Y * GAMEPAD_SPEED))
				end
			end
		end))
	end
end

function DragManager:onDragStart(fn) return self._emitter:on("DragStart", fn) end
function DragManager:onDragEnd(fn)   return self._emitter:on("DragEnd", fn) end

function DragManager:destroy()
	for _, c in ipairs(self._conns) do pcall(function() c:Disconnect() end) end
	self._conns = {}
end

-- ============================================================
--  TOOLTIP SYSTEM
-- ============================================================
local TooltipSystem = {}
TooltipSystem.__index = TooltipSystem

function TooltipSystem.new(theme, screenGui)
	local self       = setmetatable({}, TooltipSystem)
	self._theme      = theme
	self._gui        = screenGui
	self._showThread = nil
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
	Utils.newInstance("UICorner",  { CornerRadius = UDim.new(0, 6) }, frame)
	Utils.newInstance("UIStroke",  { Color = T.Border, Thickness = 1 }, frame)
	Utils.newInstance("UIPadding", {
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

function TooltipSystem:attach(target, text, delay)
	delay = delay or 0.6
	local enterConn, leaveConn, moveConn

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
		if self._frame and self._frame.Visible then
			local vp   = Utils.getViewport()
			local size = self._frame.AbsoluteSize
			local px   = x + 14
			local py   = y + 10
			if px + size.X > vp.X then px = x - size.X - 14 end
			if py + size.Y > vp.Y then py = y - size.Y - 10 end
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

function NotificationSystem.new(theme, screenGui)
	local self      = setmetatable({}, NotificationSystem)
	self._theme     = theme
	self._gui       = screenGui
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
		SortOrder         = Enum.SortOrder.LayoutOrder,
		VerticalAlignment = Enum.VerticalAlignment.Bottom,
		Padding           = UDim.new(0, 8),
	}, container)
	self._container = container
end

function NotificationSystem:show(opts)
	local T        = self._theme
	local kind     = opts.Type or "info"
	local duration = opts.Duration or 4
	local accent   = ({
		success = T.Success,
		error   = T.Error,
		warning = T.Warning,
		info    = T.Info,
	})[kind] or T.Accent

	local toast = Utils.newInstance("Frame", {
		Name            = "Toast_" .. kind,
		Size            = UDim2.fromOffset(310, 0),
		AutomaticSize   = Enum.AutomaticSize.Y,
		BackgroundColor3= T.Surface,
		BorderSizePixel = 0,
		ClipsDescendants= false,
		ZIndex          = 91,
	}, self._container)
	Utils.newInstance("UICorner", { CornerRadius = UDim.new(0, 10) }, toast)
	Utils.newInstance("UIStroke", { Color = T.Border, Thickness = 1 }, toast)

	-- Accent bar
	Utils.newInstance("Frame", {
		Name            = "AccentBar",
		Size            = UDim2.new(0, 4, 1, 0),
		BackgroundColor3= accent,
		BorderSizePixel = 0,
		ZIndex          = 92,
	}, toast)

	local inner = Utils.newInstance("Frame", {
		Name            = "Inner",
		Size            = UDim2.new(1, -16, 1, 0),
		Position        = UDim2.fromOffset(12, 0),
		BackgroundTransparency = 1,
		AutomaticSize   = Enum.AutomaticSize.Y,
		ZIndex          = 92,
	}, toast)
	Utils.newInstance("UIPadding", {
		PaddingTop    = UDim.new(0, 12),
		PaddingBottom = UDim.new(0, 12),
		PaddingRight  = UDim.new(0, 8),
	}, inner)
	Utils.newInstance("UIListLayout", {
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding   = UDim.new(0, 4),
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
		Text            = opts.Message or "",
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

	-- Animate in from right
	toast.Position = UDim2.fromOffset(320, 0)
	Utils.tween(toast, T.AnimSpeed, { Position = UDim2.fromOffset(0, 0) })

	-- Progress countdown
	Utils.tween(progressFill, duration, { Size = UDim2.new(0, 0, 1, 0) }, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)

	local function dismiss()
		if not toast.Parent then return end
		Utils.tween(toast, T.AnimSpeed, { Position = UDim2.fromOffset(320, 0) })
		task.delay(T.AnimSpeed, function() Utils.destroySafe(toast) end)
	end

	local conn = toast.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or
		   input.UserInputType == Enum.UserInputType.Touch then
			dismiss()
		end
	end)

	task.delay(duration, function()
		conn:Disconnect()
		dismiss()
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

function ModalSystem.new(theme, screenGui)
	local self               = setmetatable({}, ModalSystem)
	self._theme              = theme
	self._gui                = screenGui
	self._activeOverlays     = {}
	return self
end

function ModalSystem:destroy()
	for _, ov in ipairs(self._activeOverlays) do
		pcall(function() Utils.destroySafe(ov) end)
	end
	self._activeOverlays = {}
end

function ModalSystem:show(opts)
	local T     = self._theme
	local width = opts.Width or 380

	local overlay = Utils.newInstance("Frame", {
		Name            = "ModalOverlay",
		Size            = UDim2.fromScale(1, 1),
		BackgroundColor3= T.Overlay,
		BackgroundTransparency = 1,
		ZIndex          = 60,
	}, self._gui)
	Utils.tween(overlay, T.AnimSpeed, { BackgroundTransparency = 0.45 })

	local dialog = Utils.newInstance("Frame", {
		Name            = "ModalDialog",
		Size            = UDim2.fromOffset(width, 0),
		AnchorPoint     = Vector2.new(0.5, 0.5),
		Position        = UDim2.new(0.5, 0, 0.5, 20),
		AutomaticSize   = Enum.AutomaticSize.Y,
		BackgroundColor3= T.Surface,
		BorderSizePixel = 0,
		ZIndex          = 61,
	}, overlay)
	Utils.newInstance("UICorner", { CornerRadius = UDim.new(0, 14) }, dialog)
	Utils.newInstance("UIStroke", { Color = T.Border, Thickness = 1 }, dialog)
	Utils.newInstance("UIListLayout", {
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding   = UDim.new(0, 0),
	}, dialog)
	Utils.tween(dialog, T.AnimSpeed, { Position = UDim2.fromScale(0.5, 0.5) }, Enum.EasingStyle.Back, Enum.EasingDirection.Out)

	-- Title bar
	local titleBar = Utils.newInstance("Frame", {
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
		Text            = opts.Title or "",
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

	-- Content
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

	-- Forward-declare so button callbacks below can reference it
	local closeModal

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
		Utils.newInstance("UIListLayout", {
			SortOrder           = Enum.SortOrder.LayoutOrder,
			FillDirection       = Enum.FillDirection.Horizontal,
			HorizontalAlignment = Enum.HorizontalAlignment.Right,
			VerticalAlignment   = Enum.VerticalAlignment.Center,
			Padding             = UDim.new(0, 8),
		}, btnRow)

		for i, b in ipairs(opts.Buttons) do
			local isPrimary = b.Variant == "primary"
			local isDanger  = b.Variant == "danger"
			local bg  = isDanger and T.Error or (isPrimary and T.Accent or T.SurfaceHover)
			local fg  = (isDanger or isPrimary) and T.TextOnAccent or T.TextPrimary
			local btn = Utils.newInstance("TextButton", {
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
				AutoButtonColor = false,
			}, btnRow)
			Utils.newInstance("UICorner",  { CornerRadius = UDim.new(0, 8) }, btn)
			Utils.newInstance("UIPadding", {
				PaddingLeft  = UDim.new(0, 16),
				PaddingRight = UDim.new(0, 16),
			}, btn)

			btn.MouseButton1Click:Connect(function()
				closeModal()
				if b.OnClick then b.OnClick() end
			end)
			btn.MouseEnter:Connect(function()
				Utils.tween(btn, T.AnimSpeed, {
					BackgroundColor3 = isDanger and Color3.fromRGB(255, 100, 100)
					                 or (isPrimary and T.AccentHover or T.Border)
				})
			end)
			btn.MouseLeave:Connect(function()
				Utils.tween(btn, T.AnimSpeed, { BackgroundColor3 = bg })
			end)
		end
	end

	-- Track overlay for destroy cleanup
	table.insert(self._activeOverlays, overlay)

	-- Define closeModal (forward declared above so buttons can use it)
	local closed = false
	closeModal = function()
		if closed then return end
		closed = true
		for i, ov in ipairs(self._activeOverlays) do
			if ov == overlay then table.remove(self._activeOverlays, i); break end
		end
		Utils.tween(overlay, T.AnimSpeed, { BackgroundTransparency = 1 })
		Utils.tween(dialog,  T.AnimSpeed, {
			Position = UDim2.new(0.5, 0, 0.5, 20),
		}, Enum.EasingStyle.Back, Enum.EasingDirection.In)
		task.delay(T.AnimSpeed + 0.05, function() Utils.destroySafe(overlay) end)
	end

	-- Click overlay background (not dialog) to close
	overlay.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			-- Only close if click hit the overlay itself, not a child
			local pos = input.Position
			local dp  = dialog.AbsolutePosition
			local ds  = dialog.AbsoluteSize
			local hitDialog = pos.X >= dp.X and pos.X <= dp.X + ds.X
			              and pos.Y >= dp.Y and pos.Y <= dp.Y + ds.Y
			if not hitDialog then
				closeModal()
			end
		end
	end)

	return closeModal
end

function ModalSystem:confirm(title, message, onConfirm, onCancel)
	return self:show({
		Title   = title,
		Message = message,
		Buttons = {
			{ Label = "Cancel",  Variant = "secondary", OnClick = onCancel },
			{ Label = "Confirm", Variant = "primary",   OnClick = onConfirm },
		},
	})
end

-- ============================================================
--  CONTEXT MENU
-- ============================================================
local ContextMenu = {}
ContextMenu.__index = ContextMenu

function ContextMenu.new(theme, screenGui)
	local self    = setmetatable({}, ContextMenu)
	self._theme   = theme
	self._gui     = screenGui
	self._current = nil
	return self
end

function ContextMenu:show(items, position)
	self:hide()
	local T  = self._theme
	local vp = Utils.getViewport()

	local menu = Utils.newInstance("Frame", {
		Name            = "ContextMenu",
		Size            = UDim2.fromOffset(200, 0),
		AutomaticSize   = Enum.AutomaticSize.Y,
		BackgroundColor3= T.Surface,
		BorderSizePixel = 0,
		ZIndex          = 80,
		ClipsDescendants= false,
	}, self._gui)
	Utils.newInstance("UICorner",  { CornerRadius = UDim.new(0, 10) }, menu)
	Utils.newInstance("UIStroke",  { Color = T.Border, Thickness = 1 }, menu)
	Utils.newInstance("UIPadding", {
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
		else
			local row = Utils.newInstance("TextButton", {
				Size            = UDim2.new(1, 0, 0, 36),
				BackgroundTransparency = 1,
				Text            = "",
				LayoutOrder     = i,
				ZIndex          = 81,
				AutoButtonColor = false,
			}, menu)
			Utils.newInstance("UIPadding", {
				PaddingLeft  = UDim.new(0, 12),
				PaddingRight = UDim.new(0, 12),
			}, row)
			Utils.newInstance("TextLabel", {
				Size            = UDim2.new(1, 0, 1, 0),
				BackgroundTransparency = 1,
				Text            = item.Label or "",
				Font            = T.Font,
				TextSize        = T.TextSize,
				TextColor3      = item.Disabled and T.TextDisabled or T.TextPrimary,
				TextXAlignment  = Enum.TextXAlignment.Left,
				ZIndex          = 81,
			}, row)

			if not item.Disabled then
				row.MouseEnter:Connect(function()
					row.BackgroundTransparency = 0
					row.BackgroundColor3 = T.SurfaceHover
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
	end

	-- Clamp to screen
	local px = math.min(position.X, vp.X - 210)
	local py = math.min(position.Y, vp.Y - math.max(#items * 38 + 16, 60))
	menu.Position = UDim2.fromOffset(px, py)

	-- Just show immediately (no fade - UIStroke would bleed through transparency tween)
	menu.BackgroundTransparency = 0

	self._current = menu

	local conn
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

function ContextMenu:destroy()
	self:hide()
end

-- ============================================================
--  LOADING SPINNER
-- ============================================================
local LoadingSpinner = {}
LoadingSpinner.__index = LoadingSpinner
setmetatable(LoadingSpinner, { __index = BaseComponent })

function LoadingSpinner.new(parent, theme, opts)
	local self   = BaseComponent.new()
	setmetatable(self, LoadingSpinner)
	local T      = theme
	opts         = opts or {}
	local sz     = opts.Size or 40
	local color  = opts.Color or T.Accent
	local style  = opts.Style or "circle"
	local alive  = true  -- set false on destroy to stop all loops

	local holder = Utils.newInstance("Frame", {
		Name            = "Spinner",
		Size            = UDim2.fromOffset(sz, sz),
		BackgroundTransparency = 1,
	}, parent)
	self.Instance = holder

	if style == "circle" then
		local arcFrame = Utils.newInstance("Frame", {
			Size            = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
		}, holder)
		local circle = Utils.newInstance("Frame", {
			Size            = UDim2.fromScale(1, 1),
			BackgroundColor3= color,
			BorderSizePixel = 0,
		}, arcFrame)
		Utils.newInstance("UICorner", { CornerRadius = UDim.new(0.5, 0) }, circle)
		local inner = Utils.newInstance("Frame", {
			Size            = UDim2.fromOffset(sz - 8, sz - 8),
			AnchorPoint     = Vector2.new(0.5, 0.5),
			Position        = UDim2.fromScale(0.5, 0.5),
			BackgroundColor3= T.Background,
			BorderSizePixel = 0,
		}, arcFrame)
		Utils.newInstance("UICorner", { CornerRadius = UDim.new(0.5, 0) }, inner)
		-- Tracked connection - cleaned up properly when spinner:destroy() is called
		self:_conn(RunService.Heartbeat:Connect(function(dt)
			if not alive then return end
			arcFrame.Rotation = arcFrame.Rotation + dt * 360
		end))

	elseif style == "dots" then
		-- Use Heartbeat with accumulated time instead of recursive task.delay chains
		local dots = {}
		for i = 1, 3 do
			local dot = Utils.newInstance("Frame", {
				Name            = "Dot" .. i,
				Size            = UDim2.fromOffset(sz/5, sz/5),
				AnchorPoint     = Vector2.new(0.5, 0.5),
				BackgroundColor3= color,
				BorderSizePixel = 0,
				BackgroundTransparency = 1,
				Position        = UDim2.fromOffset(sz/2 + (i - 2) * sz/3.5, sz/2),
			}, holder)
			Utils.newInstance("UICorner", { CornerRadius = UDim.new(0.5, 0) }, dot)
			dots[i] = dot
		end
		local elapsed = 0
		local PERIOD  = 0.7
		local last    = {0, 0, 0}
		self:_conn(RunService.Heartbeat:Connect(function(dt)
			if not alive then return end
			elapsed = elapsed + dt
			for i = 1, 3 do
				local phase    = ((elapsed + (i-1)*0.18) % PERIOD) / PERIOD
				local opacity  = math.abs(math.sin(phase * math.pi))
				if math.abs(opacity - last[i]) > 0.02 then
					dots[i].BackgroundTransparency = 1 - opacity
					last[i] = opacity
				end
			end
		end))

	elseif style == "pulse" then
		local circle = Utils.newInstance("Frame", {
			Size            = UDim2.fromScale(0.8, 0.8),
			AnchorPoint     = Vector2.new(0.5, 0.5),
			Position        = UDim2.fromScale(0.5, 0.5),
			BackgroundColor3= color,
			BorderSizePixel = 0,
			BackgroundTransparency = 0,
		}, holder)
		Utils.newInstance("UICorner", { CornerRadius = UDim.new(0.5, 0) }, circle)
		-- Heartbeat-driven pulse to avoid recursive delay leak
		local elapsed = 0
		self:_conn(RunService.Heartbeat:Connect(function(dt)
			if not alive then return end
			elapsed = elapsed + dt
			local t = (math.sin(elapsed * math.pi) + 1) / 2  -- 0..1 oscillation
			circle.Size = UDim2.fromScale(0.8 + t * 0.4, 0.8 + t * 0.4)
			circle.BackgroundTransparency = t * 0.6
		end))
	end

	-- Override destroy to stop all loops
	local origDestroy = self.destroy
	function self:destroy()
		alive = false
		origDestroy(self)
	end

	return self
end

-- ============================================================
--  BUTTON COMPONENT
-- ============================================================
local Button = {}
Button.__index = Button
setmetatable(Button, { __index = BaseComponent })

function Button.new(parent, theme, opts)
	local self   = BaseComponent.new()
	setmetatable(self, Button)
	local T      = theme
	opts         = opts or {}

	local variant  = opts.Variant or "primary"
	local disabled = opts.Disabled or false

	local bg, fg
	if variant == "primary" then
		bg, fg = T.Accent, T.TextOnAccent
	elseif variant == "secondary" then
		bg, fg = T.Surface, T.TextPrimary
	elseif variant == "ghost" then
		bg, fg = Color3.new(0,0,0), T.TextPrimary
	elseif variant == "danger" then
		bg, fg = T.Error, T.TextOnAccent
	else
		bg, fg = T.Accent, T.TextOnAccent
	end

	local btn = Utils.newInstance("TextButton", {
		Name            = "NexusButton",
		Size            = opts.Size or UDim2.fromOffset(120, 38),
		BackgroundColor3= disabled and T.SurfaceHover or bg,
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

	self.Instance  = btn
	self._bg       = bg
	self._fg       = fg
	self._variant  = variant
	self._opts     = opts
	self._theme    = T

	if not disabled then
		self:_conn(btn.MouseEnter:Connect(function()
			if not self._enabled then return end
			Utils.tween(btn, T.AnimSpeed, {
				BackgroundColor3       = variant == "ghost" and T.SurfaceHover or
				                         variant == "secondary" and T.SurfaceHover or T.AccentHover,
				BackgroundTransparency = 0,
			})
			self:emit("MouseEnter")
		end))

		self:_conn(btn.MouseLeave:Connect(function()
			Utils.tween(btn, T.AnimSpeed, {
				BackgroundColor3       = bg,
				BackgroundTransparency = variant == "ghost" and 1 or 0,
			})
			self:emit("MouseLeave")
		end))

		self:_conn(btn.MouseButton1Down:Connect(function()
			if not self._enabled then return end
			local sw = opts.Size and opts.Size.X.Offset or 120
			local sh = opts.Size and opts.Size.Y.Offset or 38
			Utils.tween(btn, 0.06, {
				Size             = UDim2.fromOffset(sw - 4, sh - 2),
				BackgroundColor3 = variant == "danger" and Color3.fromRGB(200, 50, 50) or T.AccentPress,
			})
		end))

		self:_conn(btn.MouseButton1Up:Connect(function()
			Utils.tween(btn, 0.09, {
				Size             = opts.Size or UDim2.fromOffset(120, 38),
				BackgroundColor3 = bg,
			})
		end))

		self:_conn(btn.MouseButton1Click:Connect(function()
			if not self._enabled then return end
			self:emit("Clicked")
			if opts.OnClick then opts.OnClick() end
		end))

		self:_conn(btn.TouchTap:Connect(function()
			if not self._enabled then return end
			self:emit("Clicked")
			if opts.OnClick then opts.OnClick() end
		end))
	end

	return self
end

function Button:setText(text)
	if self.Instance then self.Instance.Text = text end
end

function Button:setDisabled(v)
	self._enabled = not v
	if self.Instance then
		local T = self._theme
		self.Instance.TextColor3 = v and T.TextDisabled or self._fg
		self.Instance.BackgroundColor3 = v and T.SurfaceHover or self._bg
		self.Instance.BackgroundTransparency = (not v and self._variant == "ghost") and 1 or 0
	end
end

-- ============================================================
--  TOGGLE SWITCH  (iOS-style)
-- ============================================================
local Toggle = {}
Toggle.__index = Toggle
setmetatable(Toggle, { __index = BaseComponent })

function Toggle.new(parent, theme, opts)
	local self   = BaseComponent.new()
	setmetatable(self, Toggle)
	local T      = theme
	opts         = opts or {}
	local value  = opts.Value or false
	local W, H   = 50, 28

	local wrapper = Utils.newInstance("Frame", {
		Name            = "Toggle",
		Size            = UDim2.fromOffset(opts.Label and 220 or W, H),
		BackgroundTransparency = 1,
	}, parent)
	self.Instance = wrapper

	local track = Utils.newInstance("Frame", {
		Name            = "Track",
		Size            = UDim2.fromOffset(W, H),
		Position        = opts.Label and UDim2.new(1, -W, 0, 0) or UDim2.fromOffset(0, 0),
		BackgroundColor3= value and T.Accent or T.Border,
		BorderSizePixel = 0,
	}, wrapper)
	Utils.newInstance("UICorner", { CornerRadius = UDim.new(0.5, 0) }, track)

	local thumb = Utils.newInstance("Frame", {
		Name            = "Thumb",
		Size            = UDim2.fromOffset(H - 4, H - 4),
		Position        = UDim2.fromOffset(value and W - H + 2 or 2, 2),
		BackgroundColor3= Color3.new(1, 1, 1),
		BorderSizePixel = 0,
	}, track)
	Utils.newInstance("UICorner", { CornerRadius = UDim.new(0.5, 0) }, thumb)

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

	local function setValue(v, animate)
		value = v
		local targetX  = v and W - H + 2 or 2
		local trackCol = v and T.Accent or T.Border
		if animate then
			Utils.tween(thumb, T.AnimSpeed, { Position = UDim2.fromOffset(targetX, 2) }, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
			Utils.tween(track, T.AnimSpeed, { BackgroundColor3 = trackCol })
		else
			thumb.Position          = UDim2.fromOffset(targetX, 2)
			track.BackgroundColor3  = trackCol
		end
	end

	self:_conn(track.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or
		   input.UserInputType == Enum.UserInputType.Touch then
			if not self._enabled then return end
			setValue(not value, true)
			self:emit("ValueChanged", value)
			if opts.OnChange then opts.OnChange(value) end
		end
	end))

	self.getValue = function() return value end
	self.setValue = function(_, v) setValue(v, true) end
	setValue(value, false)
	return self
end

-- ============================================================
--  SLIDER COMPONENT
-- ============================================================
local Slider = {}
Slider.__index = Slider
setmetatable(Slider, { __index = BaseComponent })

function Slider.new(parent, theme, opts)
	local self   = BaseComponent.new()
	setmetatable(self, Slider)
	local T      = theme
	opts         = opts or {}

	local min   = opts.Min   or 0
	local max   = opts.Max   or 100
	local step  = opts.Step  or 1
	local val   = opts.Value or min
	local width = opts.Width or 220

	local function snapVal(v)
		v = Utils.clamp(v, min, max)
		if step > 0 then
			v = math.floor((v - min) / step + 0.5) * step + min
		end
		return Utils.round(v, 4)
	end
	val = snapVal(val)

	local TRACK_H = 6
	local THUMB_D = 18
	local labelH  = (opts.Label or opts.ShowValue) and 24 or 0

	local wrapper = Utils.newInstance("Frame", {
		Name  = "Slider",
		Size  = UDim2.fromOffset(width, labelH + THUMB_D + 4),
		BackgroundTransparency = 1,
	}, parent)
	self.Instance = wrapper

	local valueLabel
	if opts.Label or opts.ShowValue then
		local row = Utils.newInstance("Frame", {
			Size            = UDim2.new(1, 0, 0, labelH),
			BackgroundTransparency = 1,
		}, wrapper)
		if opts.Label then
			Utils.newInstance("TextLabel", {
				Size            = UDim2.fromScale(0.7, 1),
				BackgroundTransparency = 1,
				Text            = opts.Label,
				Font            = T.Font,
				TextSize        = T.TextSize,
				TextColor3      = T.TextPrimary,
				TextXAlignment  = Enum.TextXAlignment.Left,
			}, row)
		end
		if opts.ShowValue then
			valueLabel = Utils.newInstance("TextLabel", {
				Size            = UDim2.fromScale(0.3, 1),
				Position        = UDim2.fromScale(0.7, 0),
				BackgroundTransparency = 1,
				Text            = tostring(val),
				Font            = T.FontBold,
				TextSize        = T.TextSize,
				TextColor3      = T.Accent,
				TextXAlignment  = Enum.TextXAlignment.Right,
			}, row)
		end
	end

	local trackY = labelH + (THUMB_D - TRACK_H) / 2

	local trackBg = Utils.newInstance("Frame", {
		Name            = "TrackBg",
		Size            = UDim2.new(1, 0, 0, TRACK_H),
		Position        = UDim2.fromOffset(0, trackY),
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
		Position        = UDim2.new(0, 0, 0, labelH + THUMB_D / 2),
		BackgroundColor3= Color3.new(1, 1, 1),
		BorderSizePixel = 0,
		ZIndex          = 2,
	}, wrapper)
	Utils.newInstance("UICorner", { CornerRadius = UDim.new(0.5, 0) }, thumb)
	Utils.newInstance("UIStroke", { Color = T.Accent, Thickness = 2 }, thumb)

	local function updateVisuals(v, animate)
		local pct = (v - min) / (max - min)
		local tw  = trackBg.AbsoluteSize.X
		local tx  = pct * tw
		if animate then
			Utils.tween(trackFill, T.AnimSpeed * 0.6, { Size = UDim2.new(pct, 0, 1, 0) })
			Utils.tween(thumb,     T.AnimSpeed * 0.6, { Position = UDim2.new(0, tx, 0, labelH + THUMB_D / 2) })
		else
			trackFill.Size = UDim2.new(pct, 0, 1, 0)
			thumb.Position = UDim2.new(0, tx, 0, labelH + THUMB_D / 2)
		end
		if valueLabel then valueLabel.Text = tostring(v) end
	end

	local function setValueFromX(x)
		local tw  = trackBg.AbsoluteSize.X
		local ap  = trackBg.AbsolutePosition.X
		local pct = Utils.clamp((x - ap) / tw, 0, 1)
		local newVal = snapVal(pct * (max - min) + min)
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

	task.defer(function() updateVisuals(val, false) end)
	self.getValue = function() return val end
	self.setValue = function(_, v)
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

function Dropdown.new(parent, theme, opts)
	local self   = BaseComponent.new()
	setmetatable(self, Dropdown)
	local T      = theme
	opts         = opts or {}

	local width     = opts.Width    or 220
	local maxHeight = opts.MaxHeight or 220
	local open      = false
	local selected  = nil
	local items     = {}

	for _, v in ipairs(opts.Items or {}) do
		if type(v) == "string" then
			table.insert(items, { Label = v, Value = v })
		else
			table.insert(items, v)
		end
	end

	if opts.Value then
		for _, item in ipairs(items) do
			if item.Value == opts.Value then selected = item; break end
		end
	end

	local wrapper = Utils.newInstance("Frame", {
		Name  = "Dropdown",
		Size  = UDim2.fromOffset(width, 38),
		BackgroundTransparency = 1,
		ClipsDescendants = false,
	}, parent)
	self.Instance = wrapper

	local header = Utils.newInstance("TextButton", {
		Name            = "Header",
		Size            = UDim2.fromOffset(width, 38),
		BackgroundColor3= T.Surface,
		BorderSizePixel = 0,
		Text            = "",
		ZIndex          = 2,
		AutoButtonColor = false,
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

	-- Panel (parented to screenGui to avoid clipping)
	local screenGui = wrapper:FindFirstAncestorWhichIsA("ScreenGui")
	local panel = Utils.newInstance("ScrollingFrame", {
		Name            = "DropdownPanel",
		Size            = UDim2.fromOffset(width, 0),
		BackgroundColor3= T.Surface,
		BorderSizePixel = 0,
		Visible         = false,
		ZIndex          = 50,
		CanvasSize      = UDim2.fromOffset(0, 0),
		AutomaticCanvasSize  = Enum.AutomaticSize.Y,
		ScrollBarThickness   = 4,
		ScrollBarImageColor3 = T.ScrollBar,
	}, screenGui or wrapper)
	Utils.newInstance("UICorner",  { CornerRadius = T.CornerRadius }, panel)
	Utils.newInstance("UIStroke",  { Color = T.Border, Thickness = 1 }, panel)
	Utils.newInstance("UIPadding", {
		PaddingTop    = UDim.new(0, 6),
		PaddingBottom = UDim.new(0, 6),
	}, panel)
	Utils.newInstance("UIListLayout", {
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding   = UDim.new(0, 2),
	}, panel)

	local function updatePanelPos()
		local absPos  = wrapper.AbsolutePosition
		local absSize = wrapper.AbsoluteSize
		panel.Position = UDim2.fromOffset(absPos.X, absPos.Y + absSize.Y + 4)
	end

	local function buildItems(filter)
		for _, c in ipairs(panel:GetChildren()) do
			if c:IsA("TextButton") or c:IsA("Frame") then c:Destroy() end
		end
		for i, item in ipairs(items) do
			if filter and filter ~= "" and not item.Label:lower():find(filter:lower(), 1, true) then
				continue
			end
			local row = Utils.newInstance("TextButton", {
				Name            = "Item" .. i,
				Size            = UDim2.new(1, -8, 0, 34),
				BackgroundTransparency = 1,
				Text            = "",
				ZIndex          = 51,
				AutoButtonColor = false,
			}, panel)
			Utils.newInstance("UIPadding", {
				PaddingLeft  = UDim.new(0, 10),
				PaddingRight = UDim.new(0, 10),
			}, row)
			local lbl = Utils.newInstance("TextLabel", {
				Size            = UDim2.new(1, 0, 1, 0),
				BackgroundTransparency = 1,
				Text            = item.Label,
				Font            = selected and selected.Value == item.Value and T.FontBold or T.Font,
				TextSize        = T.TextSize,
				TextColor3      = selected and selected.Value == item.Value and T.Accent or T.TextPrimary,
				TextXAlignment  = Enum.TextXAlignment.Left,
				ZIndex          = 51,
			}, row)
			row.MouseEnter:Connect(function()
				row.BackgroundTransparency = 0
				row.BackgroundColor3 = T.SurfaceHover
			end)
			row.MouseLeave:Connect(function()
				Utils.tween(row, T.AnimSpeed * 0.5, { BackgroundTransparency = 1 })
			end)
			row.MouseButton1Click:Connect(function()
				selected = item
				headerLabel.Text = item.Label
				headerLabel.TextColor3 = T.TextPrimary
				open = false
				panel.Visible = false
				Utils.tween(arrow, T.AnimSpeed, { Rotation = 0 })
				self:emit("ValueChanged", item.Value, item.Label)
				if opts.OnChange then opts.OnChange(item.Value, item.Label) end
				buildItems()
			end)
		end
		-- Clamp panel height
		local count = #panel:GetChildren() - 2  -- subtract layout + padding
		panel.Size = UDim2.fromOffset(width, math.min(count * 36 + 12, maxHeight))
	end

	self:_conn(header.MouseButton1Click:Connect(function()
		if not self._enabled then return end
		open = not open
		updatePanelPos()
		panel.Visible = open
		Utils.tween(arrow, T.AnimSpeed, { Rotation = open and 180 or 0 })
		if open then buildItems() end
	end))

	self:_conn(UserInputService.InputBegan:Connect(function(input)
		if not open then return end
		if input.UserInputType == Enum.UserInputType.MouseButton1 or
		   input.UserInputType == Enum.UserInputType.Touch then
			task.defer(function()
				if not header:IsAncestorOf(input.Target) and not panel:IsAncestorOf(input.Target) then
					open = false
					panel.Visible = false
					Utils.tween(arrow, T.AnimSpeed, { Rotation = 0 })
				end
			end)
		end
	end))

	self.getValue  = function() return selected and selected.Value end
	self.setValue  = function(_, v)
		for _, item in ipairs(items) do
			if item.Value == v then
				selected = item
				headerLabel.Text = item.Label
				headerLabel.TextColor3 = T.TextPrimary
				break
			end
		end
	end
	self.setItems  = function(_, newItems)
		items = {}
		for _, v in ipairs(newItems) do
			if type(v) == "string" then
				table.insert(items, { Label = v, Value = v })
			else
				table.insert(items, v)
			end
		end
		if open then buildItems() end
	end

	return self
end

-- ============================================================
--  TEXTBOX COMPONENT
-- ============================================================
local TextBoxComp = {}
TextBoxComp.__index = TextBoxComp
setmetatable(TextBoxComp, { __index = BaseComponent })

function TextBoxComp.new(parent, theme, opts)
	local self   = BaseComponent.new()
	setmetatable(self, TextBoxComp)
	local T      = theme
	opts         = opts or {}

	local width  = opts.Width or 220
	local height = opts.Multiline and 80 or 38

	local wrapper = Utils.newInstance("Frame", {
		Name            = "TextBoxWrap",
		Size            = UDim2.fromOffset(width, height + (opts.Label and 22 or 0)),
		BackgroundTransparency = 1,
	}, parent)
	self.Instance = wrapper

	local yOff = 0
	if opts.Label then
		Utils.newInstance("TextLabel", {
			Size            = UDim2.new(1, 0, 0, 20),
			BackgroundTransparency = 1,
			Text            = opts.Label,
			Font            = T.Font,
			TextSize        = T.TextSize - 1,
			TextColor3      = T.TextSecondary,
			TextXAlignment  = Enum.TextXAlignment.Left,
		}, wrapper)
		yOff = 22
	end

	local frame = Utils.newInstance("Frame", {
		Name            = "InputFrame",
		Size            = UDim2.fromOffset(width, height),
		Position        = UDim2.fromOffset(0, yOff),
		BackgroundColor3= T.Surface,
		BorderSizePixel = 0,
	}, wrapper)
	Utils.newInstance("UICorner", { CornerRadius = T.CornerRadius }, frame)
	local stroke = Utils.newInstance("UIStroke", { Color = T.Border, Thickness = 1 }, frame)
	Utils.newInstance("UIPadding", {
		PaddingLeft  = UDim.new(0, 10),
		PaddingRight = UDim.new(0, 10),
	}, frame)

	local box = Utils.newInstance("TextBox", {
		Size            = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		PlaceholderText = opts.Placeholder or "",
		PlaceholderColor3 = T.TextDisabled,
		Text            = opts.Value or "",
		Font            = T.Font,
		TextSize        = T.TextSize,
		TextColor3      = T.TextPrimary,
		TextXAlignment  = Enum.TextXAlignment.Left,
		TextYAlignment  = opts.Multiline and Enum.TextYAlignment.Top or Enum.TextYAlignment.Center,
		ClearTextOnFocus= opts.ClearOnFocus or false,
		TextEditable    = not opts.ReadOnly,
		MultiLine       = opts.Multiline or false,
		TextScaled      = false,
		ZIndex          = 2,
	}, frame)

	if opts.Password then
		box.Text = ""
		-- Hide characters manually isn't possible via property alone; use Masked input hint
	end

	self:_conn(box.Focused:Connect(function()
		Utils.tween(stroke, T.AnimSpeed, { Color = T.BorderFocus })
		self:emit("Focused")
	end))

	self:_conn(box.FocusLost:Connect(function(enterPressed)
		Utils.tween(stroke, T.AnimSpeed, { Color = T.Border })
		local text = box.Text
		if opts.Validate then
			local ok, err = opts.Validate(text)
			if not ok then
				Utils.tween(stroke, T.AnimSpeed, { Color = T.Error })
				self:emit("ValidationFailed", err)
			end
		end
		self:emit("FocusLost", box.Text, enterPressed)
	end))

	self:_conn(box:GetPropertyChangedSignal("Text"):Connect(function()
		local text = box.Text
		if opts.MaxLength and #text > opts.MaxLength then
			box.Text = text:sub(1, opts.MaxLength)
			return
		end
		self:emit("TextChanged", box.Text)
		if opts.OnChange then opts.OnChange(box.Text) end
	end))

	self.getValue = function() return box.Text end
	self.setValue = function(_, v) box.Text = v or "" end
	self.focus    = function() box:CaptureFocus() end

	return self
end

-- ============================================================
--  CHECKBOX
-- ============================================================
local Checkbox = {}
Checkbox.__index = Checkbox
setmetatable(Checkbox, { __index = BaseComponent })

function Checkbox.new(parent, theme, opts)
	local self   = BaseComponent.new()
	setmetatable(self, Checkbox)
	local T      = theme
	opts         = opts or {}
	local value  = opts.Value or false
	local style  = opts.Style or "check"  -- "check"|"fill"|"switch"
	local SIZE   = 20

	local wrapper = Utils.newInstance("TextButton", {
		Name            = "Checkbox",
		Size            = UDim2.fromOffset(opts.Label and 200 or SIZE, SIZE),
		BackgroundTransparency = 1,
		Text            = "",
		AutoButtonColor = false,
	}, parent)
	self.Instance = wrapper

	local box = Utils.newInstance("Frame", {
		Name            = "Box",
		Size            = UDim2.fromOffset(SIZE, SIZE),
		BackgroundColor3= value and T.Accent or T.Surface,
		BorderSizePixel = 0,
	}, wrapper)
	local cr = style == "fill" and UDim.new(0.5, 0) or UDim.new(0, 5)
	Utils.newInstance("UICorner", { CornerRadius = cr }, box)
	local stroke = Utils.newInstance("UIStroke", {
		Color     = value and T.Accent or T.Border,
		Thickness = 2,
	}, box)

	local checkMark = Utils.newInstance("TextLabel", {
		Size            = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Text            = style == "fill" and "●" or "✓",
		Font            = T.FontBold,
		TextSize        = style == "fill" and 12 or 14,
		TextColor3      = T.TextOnAccent,
		Visible         = value,
		ZIndex          = 2,
	}, box)

	if opts.Label then
		Utils.newInstance("TextLabel", {
			Size            = UDim2.new(1, -(SIZE + 10), 1, 0),
			Position        = UDim2.fromOffset(SIZE + 10, 0),
			BackgroundTransparency = 1,
			Text            = opts.Label,
			Font            = T.Font,
			TextSize        = T.TextSize,
			TextColor3      = T.TextPrimary,
			TextXAlignment  = Enum.TextXAlignment.Left,
		}, wrapper)
	end

	local function setValue(v, animate)
		value = v
		checkMark.Visible = v
		if animate then
			Utils.tween(box, T.AnimSpeed, {
				BackgroundColor3 = v and T.Accent or T.Surface,
			})
			Utils.tween(stroke, T.AnimSpeed, { Color = v and T.Accent or T.Border })
		else
			box.BackgroundColor3 = v and T.Accent or T.Surface
			stroke.Color         = v and T.Accent or T.Border
		end
	end

	self:_conn(wrapper.MouseButton1Click:Connect(function()
		if not self._enabled then return end
		setValue(not value, true)
		self:emit("ValueChanged", value)
		if opts.OnChange then opts.OnChange(value) end
	end))
	self:_conn(wrapper.MouseEnter:Connect(function()
		Utils.tween(box, T.AnimSpeed * 0.7, { BackgroundColor3 = value and T.AccentHover or T.SurfaceHover })
	end))
	self:_conn(wrapper.MouseLeave:Connect(function()
		Utils.tween(box, T.AnimSpeed * 0.7, { BackgroundColor3 = value and T.Accent or T.Surface })
	end))

	self.getValue = function() return value end
	self.setValue = function(_, v) setValue(v, true) end
	setValue(value, false)
	return self
end

-- ============================================================
--  PROGRESS BAR
-- ============================================================
local ProgressBar = {}
ProgressBar.__index = ProgressBar
setmetatable(ProgressBar, { __index = BaseComponent })

function ProgressBar.new(parent, theme, opts)
	local self   = BaseComponent.new()
	setmetatable(self, ProgressBar)
	local T      = theme
	opts         = opts or {}

	local value      = opts.Value or 0
	local width      = opts.Width or 220
	local barH       = opts.Height or 10
	local color      = opts.Color or T.Accent
	local indeterminate = opts.Indeterminate or false

	local labelH = opts.Label and 22 or 0
	local wrapper = Utils.newInstance("Frame", {
		Name            = "ProgressBar",
		Size            = UDim2.fromOffset(width, barH + labelH),
		BackgroundTransparency = 1,
	}, parent)
	self.Instance = wrapper

	if opts.Label then
		Utils.newInstance("TextLabel", {
			Size            = UDim2.new(1, 0, 0, 20),
			BackgroundTransparency = 1,
			Text            = opts.Label,
			Font            = T.Font,
			TextSize        = T.TextSize,
			TextColor3      = T.TextPrimary,
			TextXAlignment  = Enum.TextXAlignment.Left,
		}, wrapper)
	end

	local track = Utils.newInstance("Frame", {
		Name            = "Track",
		Size            = UDim2.new(1, 0, 0, barH),
		Position        = UDim2.fromOffset(0, labelH),
		BackgroundColor3= T.Border,
		BorderSizePixel = 0,
		ClipsDescendants= true,
	}, wrapper)
	Utils.newInstance("UICorner", { CornerRadius = UDim.new(0.5, 0) }, track)

	local fill = Utils.newInstance("Frame", {
		Name            = "Fill",
		Size            = UDim2.new(value / 100, 0, 1, 0),
		BackgroundColor3= color,
		BorderSizePixel = 0,
	}, track)
	Utils.newInstance("UICorner", { CornerRadius = UDim.new(0.5, 0) }, fill)

	if indeterminate then
		-- Animated shimmer for indeterminate state
		fill.Size = UDim2.new(0.3, 0, 1, 0)
		fill.Position = UDim2.fromOffset(-track.AbsoluteSize.X * 0.3, 0)
		self:_conn(RunService.Heartbeat:Connect(function(dt)
			local tw = track.AbsoluteSize.X
			local fx = fill.Position.X.Offset
			fill.Position = UDim2.fromOffset(fx + dt * tw * 0.8, 0)
			if fx > tw then fill.Position = UDim2.fromOffset(-tw * 0.3, 0) end
		end))
	end

	self.getValue = function() return value end
	self.setValue = function(_, v)
		value = Utils.clamp(v, 0, 100)
		if not indeterminate then
			Utils.tween(fill, T.AnimSpeed, { Size = UDim2.new(value / 100, 0, 1, 0) })
		end
		self:emit("ValueChanged", value)
	end

	return self
end

-- ============================================================
--  NUMBER STEPPER
-- ============================================================
local NumberStepper = {}
NumberStepper.__index = NumberStepper
setmetatable(NumberStepper, { __index = BaseComponent })

function NumberStepper.new(parent, theme, opts)
	local self   = BaseComponent.new()
	setmetatable(self, NumberStepper)
	local T      = theme
	opts         = opts or {}

	local min   = opts.Min   or 0
	local max   = opts.Max   or 100
	local step  = opts.Step  or 1
	local val   = opts.Value or min
	local width = opts.Width or 160

	local wrapper = Utils.newInstance("Frame", {
		Name            = "NumberStepper",
		Size            = UDim2.fromOffset(width, 38),
		BackgroundColor3= T.Surface,
		BorderSizePixel = 0,
	}, parent)
	Utils.newInstance("UICorner", { CornerRadius = T.CornerRadius }, wrapper)
	Utils.newInstance("UIStroke", { Color = T.Border, Thickness = 1 }, wrapper)
	self.Instance = wrapper

	local function makeBtn(text, xPos)
		local btn = Utils.newInstance("TextButton", {
			Size            = UDim2.fromOffset(36, 36),
			Position        = UDim2.fromOffset(xPos, 1),
			BackgroundColor3= T.SurfaceHover,
			BorderSizePixel = 0,
			Text            = text,
			Font            = T.FontBold,
			TextSize        = 18,
			TextColor3      = T.TextPrimary,
			AutoButtonColor = false,
			ZIndex          = 2,
		}, wrapper)
		Utils.newInstance("UICorner", { CornerRadius = T.CornerRadius }, btn)
		return btn
	end

	local decBtn = makeBtn("−", 1)
	local incBtn = makeBtn("+", width - 37)

	local display = Utils.newInstance("TextLabel", {
		Size            = UDim2.new(1, -80, 1, 0),
		Position        = UDim2.fromOffset(40, 0),
		BackgroundTransparency = 1,
		Text            = tostring(val),
		Font            = T.FontBold,
		TextSize        = T.TextSize,
		TextColor3      = T.TextPrimary,
	}, wrapper)

	local function updateVal(v)
		val = Utils.clamp(v, min, max)
		display.Text = tostring(val)
		self:emit("ValueChanged", val)
		if opts.OnChange then opts.OnChange(val) end
	end

	self:_conn(decBtn.MouseButton1Click:Connect(function()
		if not self._enabled then return end
		updateVal(val - step)
	end))
	self:_conn(incBtn.MouseButton1Click:Connect(function()
		if not self._enabled then return end
		updateVal(val + step)
	end))

	-- Long press support
	local function setupLongPress(btn, delta)
		local holding = false
		self:_conn(btn.MouseButton1Down:Connect(function()
			holding = true
			task.delay(0.4, function()
				while holding do
					updateVal(val + delta)
					task.wait(0.1)
				end
			end)
		end))
		self:_conn(btn.MouseButton1Up:Connect(function() holding = false end))
		self:_conn(btn.MouseLeave:Connect(function() holding = false end))
	end
	setupLongPress(decBtn, -step)
	setupLongPress(incBtn, step)

	for _, b in ipairs({ decBtn, incBtn }) do
		self:_conn(b.MouseEnter:Connect(function()
			Utils.tween(b, T.AnimSpeed, { BackgroundColor3 = T.Accent, TextColor3 = T.TextOnAccent })
		end))
		self:_conn(b.MouseLeave:Connect(function()
			Utils.tween(b, T.AnimSpeed, { BackgroundColor3 = T.SurfaceHover, TextColor3 = T.TextPrimary })
		end))
	end

	self.getValue = function() return val end
	self.setValue = function(_, v) updateVal(v) end
	return self
end

-- ============================================================
--  RADIO GROUP
-- ============================================================
local RadioGroup = {}
RadioGroup.__index = RadioGroup
setmetatable(RadioGroup, { __index = BaseComponent })

function RadioGroup.new(parent, theme, opts)
	local self   = BaseComponent.new()
	setmetatable(self, RadioGroup)
	local T      = theme
	opts         = opts or {}

	local items   = opts.Items   or {}
	local value   = opts.Value
	local RADIO_D = 18

	local wrapper = Utils.newInstance("Frame", {
		Name            = "RadioGroup",
		Size            = UDim2.fromOffset(opts.Width or 200, #items * 30),
		BackgroundTransparency = 1,
	}, parent)
	self.Instance = wrapper
	Utils.newInstance("UIListLayout", {
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding   = UDim.new(0, 6),
	}, wrapper)

	local buttons = {}

	local function selectItem(v)
		value = v
		for _, b in ipairs(buttons) do
			local isSelected = b.value == value
			Utils.tween(b.fill, T.AnimSpeed, {
				Size = isSelected and UDim2.fromOffset(10, 10) or UDim2.fromOffset(0, 0),
			}, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
			Utils.tween(b.ring, T.AnimSpeed, { Color = isSelected and T.Accent or T.Border })
		end
		self:emit("ValueChanged", value)
		if opts.OnChange then opts.OnChange(value) end
	end

	for i, item in ipairs(items) do
		local label  = type(item) == "string" and item or item.Label
		local val    = type(item) == "string" and item or item.Value

		local row = Utils.newInstance("TextButton", {
			Size            = UDim2.new(1, 0, 0, 24),
			BackgroundTransparency = 1,
			Text            = "",
			LayoutOrder     = i,
			AutoButtonColor = false,
		}, wrapper)

		local outer = Utils.newInstance("Frame", {
			Size            = UDim2.fromOffset(RADIO_D, RADIO_D),
			AnchorPoint     = Vector2.new(0, 0.5),
			Position        = UDim2.new(0, 0, 0.5, 0),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
		}, row)
		Utils.newInstance("UICorner", { CornerRadius = UDim.new(0.5, 0) }, outer)
		local ring = Utils.newInstance("UIStroke", {
			Color     = value == val and T.Accent or T.Border,
			Thickness = 2,
		}, outer)

		local fill = Utils.newInstance("Frame", {
			Size            = value == val and UDim2.fromOffset(10, 10) or UDim2.fromOffset(0, 0),
			AnchorPoint     = Vector2.new(0.5, 0.5),
			Position        = UDim2.fromScale(0.5, 0.5),
			BackgroundColor3= T.Accent,
			BorderSizePixel = 0,
		}, outer)
		Utils.newInstance("UICorner", { CornerRadius = UDim.new(0.5, 0) }, fill)

		Utils.newInstance("TextLabel", {
			Size            = UDim2.new(1, -(RADIO_D + 10), 1, 0),
			Position        = UDim2.fromOffset(RADIO_D + 8, 0),
			BackgroundTransparency = 1,
			Text            = label,
			Font            = T.Font,
			TextSize        = T.TextSize,
			TextColor3      = T.TextPrimary,
			TextXAlignment  = Enum.TextXAlignment.Left,
		}, row)

		table.insert(buttons, { value = val, fill = fill, ring = ring })

		self:_conn(row.MouseButton1Click:Connect(function()
			if not self._enabled then return end
			selectItem(val)
		end))
	end

	self.getValue = function() return value end
	self.setValue = function(_, v) selectItem(v) end
	return self
end

-- ============================================================
--  ACCORDION / COLLAPSIBLE
-- ============================================================
local Accordion = {}
Accordion.__index = Accordion
setmetatable(Accordion, { __index = BaseComponent })

function Accordion.new(parent, theme, opts)
	local self   = BaseComponent.new()
	setmetatable(self, Accordion)
	local T      = theme
	opts         = opts or {}

	local width  = opts.Width or 280
	local open   = opts.Open  or false

	local wrapper = Utils.newInstance("Frame", {
		Name            = "Accordion",
		Size            = UDim2.fromOffset(width, 0),
		AutomaticSize   = Enum.AutomaticSize.Y,
		BackgroundColor3= T.Surface,
		BorderSizePixel = 0,
		ClipsDescendants= true,
	}, parent)
	Utils.newInstance("UICorner", { CornerRadius = T.CornerRadius }, wrapper)
	Utils.newInstance("UIStroke", { Color = T.Border, Thickness = 1 }, wrapper)
	self.Instance = wrapper

	local header = Utils.newInstance("TextButton", {
		Name            = "Header",
		Size            = UDim2.new(1, 0, 0, 42),
		BackgroundTransparency = 1,
		Text            = "",
		AutoButtonColor = false,
	}, wrapper)
	Utils.newInstance("UIPadding", {
		PaddingLeft  = UDim.new(0, 14),
		PaddingRight = UDim.new(0, 14),
	}, header)

	Utils.newInstance("TextLabel", {
		Size            = UDim2.new(1, -30, 1, 0),
		BackgroundTransparency = 1,
		Text            = opts.Title or "Section",
		Font            = T.FontBold,
		TextSize        = T.TextSize,
		TextColor3      = T.TextPrimary,
		TextXAlignment  = Enum.TextXAlignment.Left,
	}, header)

	local chevron = Utils.newInstance("TextLabel", {
		Size            = UDim2.fromOffset(20, 20),
		Position        = UDim2.new(1, -20, 0.5, -10),
		BackgroundTransparency = 1,
		Text            = "▸",
		Font            = T.Font,
		TextSize        = 16,
		TextColor3      = T.TextSecondary,
		Rotation        = open and 90 or 0,
	}, header)

	local contentFrame = Utils.newInstance("Frame", {
		Name            = "Content",
		Size            = UDim2.new(1, 0, 0, 0),
		AutomaticSize   = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		Visible         = open,
	}, wrapper)
	Utils.newInstance("UIPadding", {
		PaddingLeft   = UDim.new(0, 14),
		PaddingRight  = UDim.new(0, 14),
		PaddingTop    = UDim.new(0, 8),
		PaddingBottom = UDim.new(0, 14),
	}, contentFrame)
	Utils.newInstance("UIListLayout", {
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding   = UDim.new(0, 8),
	}, contentFrame)

	self.Content = contentFrame

	self:_conn(header.MouseButton1Click:Connect(function()
		open = not open
		contentFrame.Visible = open
		Utils.tween(chevron, T.AnimSpeed, { Rotation = open and 90 or 0 })
		self:emit(open and "Opened" or "Closed")
	end))

	self.isOpen  = function() return open end
	self.toggle  = function() header.MouseButton1Click:Fire() end

	return self
end

-- ============================================================
--  TAB SYSTEM
-- ============================================================
local TabSystem = {}
TabSystem.__index = TabSystem
setmetatable(TabSystem, { __index = BaseComponent })

function TabSystem.new(parent, theme, opts)
	local self   = BaseComponent.new()
	setmetatable(self, TabSystem)
	local T      = theme
	opts         = opts or {}

	local tabs   = opts.Tabs or {}
	local width  = opts.Width  or 300
	local height = opts.Height or 240

	local wrapper = Utils.newInstance("Frame", {
		Name            = "TabSystem",
		Size            = UDim2.fromOffset(width, height),
		BackgroundColor3= T.BackgroundSecond,
		BorderSizePixel = 0,
	}, parent)
	Utils.newInstance("UICorner", { CornerRadius = T.CornerRadius }, wrapper)
	self.Instance = wrapper

	-- Tab bar
	local tabBar = Utils.newInstance("Frame", {
		Name            = "TabBar",
		Size            = UDim2.new(1, 0, 0, 38),
		BackgroundColor3= T.TitleBar,
		BorderSizePixel = 0,
	}, wrapper)
	Utils.newInstance("UICorner", { CornerRadius = T.CornerRadius }, tabBar)
	Utils.newInstance("UIPadding", {
		PaddingLeft  = UDim.new(0, 6),
		PaddingRight = UDim.new(0, 6),
		PaddingTop   = UDim.new(0, 5),
		PaddingBottom= UDim.new(0, 5),
	}, tabBar)
	Utils.newInstance("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		Padding       = UDim.new(0, 4),
	}, tabBar)

	-- Active indicator
	local indicator = Utils.newInstance("Frame", {
		Name            = "Indicator",
		Size            = UDim2.fromOffset(4, 3),
		Position        = UDim2.new(0, 0, 1, -3),
		BackgroundColor3= T.Accent,
		BorderSizePixel = 0,
		ZIndex          = 2,
	}, tabBar)
	Utils.newInstance("UICorner", { CornerRadius = UDim.new(0.5, 0) }, indicator)

	-- Content area
	local contentArea = Utils.newInstance("Frame", {
		Name            = "ContentArea",
		Size            = UDim2.new(1, 0, 1, -42),
		Position        = UDim2.fromOffset(0, 42),
		BackgroundTransparency = 1,
		ClipsDescendants= true,
	}, wrapper)

	local pages    = {}
	local tabBtns  = {}
	local activeIdx = 1

	local function selectTab(idx)
		if idx == activeIdx then return end
		local prev = activeIdx
		activeIdx = idx

		-- Slide animation direction
		local dir = idx > prev and 1 or -1
		for i, page in ipairs(pages) do
			if i == idx then
				page.Position = UDim2.fromOffset(dir * width, 0)
				page.Visible  = true
				Utils.tween(page, T.AnimSpeed, { Position = UDim2.fromOffset(0, 0) })
			elseif i == prev then
				Utils.tween(page, T.AnimSpeed, { Position = UDim2.fromOffset(-dir * width, 0) })
				task.delay(T.AnimSpeed, function() if activeIdx ~= i then page.Visible = false end end)
			else
				page.Visible = false
			end
		end

		-- Tab button styles
		for i, b in ipairs(tabBtns) do
			local isActive = i == idx
			Utils.tween(b, T.AnimSpeed, {
				BackgroundColor3       = isActive and T.Accent or T.Surface,
				BackgroundTransparency = isActive and 0 or 1,
			})
			b.TextColor3 = isActive and T.TextOnAccent or T.TextSecondary
		end

		-- Indicator slide
		local btn = tabBtns[idx]
		if btn then
			Utils.tween(indicator, T.AnimSpeed, {
				Size     = UDim2.fromOffset(btn.AbsoluteSize.X, 3),
				Position = UDim2.fromOffset(btn.AbsolutePosition.X - tabBar.AbsolutePosition.X, 35),
			})
		end

		self:emit("TabChanged", idx, tabs[idx])
	end

	for i, tab in ipairs(tabs) do
		local label = type(tab) == "string" and tab or tab.Label

		local btn = Utils.newInstance("TextButton", {
			Size            = UDim2.fromOffset(0, 28),
			AutomaticSize   = Enum.AutomaticSize.X,
			BackgroundColor3= i == 1 and T.Accent or T.Surface,
			BackgroundTransparency = i == 1 and 0 or 1,
			BorderSizePixel = 0,
			Text            = label,
			Font            = T.FontBold,
			TextSize        = T.TextSize - 1,
			TextColor3      = i == 1 and T.TextOnAccent or T.TextSecondary,
			AutoButtonColor = false,
			ZIndex          = 2,
		}, tabBar)
		Utils.newInstance("UICorner",  { CornerRadius = UDim.new(0, 6) }, btn)
		Utils.newInstance("UIPadding", {
			PaddingLeft  = UDim.new(0, 12),
			PaddingRight = UDim.new(0, 12),
		}, btn)
		table.insert(tabBtns, btn)

		local page = Utils.newInstance("Frame", {
			Name            = "Page" .. i,
			Size            = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			Visible         = i == 1,
		}, contentArea)
		Utils.newInstance("UIPadding", {
			PaddingLeft   = UDim.new(0, 12),
			PaddingRight  = UDim.new(0, 12),
			PaddingTop    = UDim.new(0, 10),
			PaddingBottom = UDim.new(0, 10),
		}, page)
		Utils.newInstance("UIListLayout", {
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding   = UDim.new(0, 8),
		}, page)
		table.insert(pages, page)

		self.Tabs = self.Tabs or {}
		self.Tabs[label] = page

		local idx = i
		self:_conn(btn.MouseButton1Click:Connect(function()
			selectTab(idx)
		end))
	end

	-- Set initial indicator
	task.defer(function()
		local btn = tabBtns[1]
		if btn then
			indicator.Size = UDim2.fromOffset(btn.AbsoluteSize.X, 3)
			indicator.Position = UDim2.fromOffset(btn.AbsolutePosition.X - tabBar.AbsolutePosition.X, 35)
		end
	end)

	self.selectTab = function(_, idx) selectTab(idx) end
	self.getPages  = function() return pages end

	return self
end

-- ============================================================
--  COLOR PICKER
-- ============================================================
local ColorPicker = {}
ColorPicker.__index = ColorPicker
setmetatable(ColorPicker, { __index = BaseComponent })

function ColorPicker.new(parent, theme, opts)
	local self   = BaseComponent.new()
	setmetatable(self, ColorPicker)
	local T      = theme
	opts         = opts or {}

	local initColor = opts.Value or Color3.fromRGB(255, 100, 100)
	local H, S, V   = Color3.toHSV(initColor)

	local SV_SIZE   = 160
	local PICKER_W  = 184
	local PICKER_H  = 200

	local wrapper = Utils.newInstance("Frame", {
		Name            = "ColorPicker",
		Size            = UDim2.fromOffset(PICKER_W + 16, 38),
		BackgroundTransparency = 1,
		ClipsDescendants= false,
	}, parent)
	self.Instance = wrapper

	local swatch = Utils.newInstance("TextButton", {
		Name            = "Swatch",
		Size            = UDim2.fromOffset(PICKER_W, 34),
		BackgroundColor3= initColor,
		BorderSizePixel = 0,
		Text            = "",
		ZIndex          = 2,
		AutoButtonColor = false,
	}, wrapper)
	Utils.newInstance("UICorner", { CornerRadius = T.CornerRadius }, swatch)
	Utils.newInstance("UIStroke", { Color = T.Border, Thickness = 1 }, swatch)

	-- Popup parented to screenGui to avoid clipping
	local screenGui = wrapper:FindFirstAncestorWhichIsA("ScreenGui")
	local popup = Utils.newInstance("Frame", {
		Name            = "ColorPopup",
		Size            = UDim2.fromOffset(PICKER_W, PICKER_H),
		BackgroundColor3= T.Surface,
		BorderSizePixel = 0,
		Visible         = false,
		ZIndex          = 55,
		ClipsDescendants= false,
	}, screenGui or wrapper)
	Utils.newInstance("UICorner", { CornerRadius = UDim.new(0, 10) }, popup)
	Utils.newInstance("UIStroke", { Color = T.Border, Thickness = 1 }, popup)

	local function updatePopupPos()
		local ap = wrapper.AbsolutePosition
		local as = wrapper.AbsoluteSize
		popup.Position = UDim2.fromOffset(ap.X, ap.Y + as.Y + 4)
	end

	-- SV Area
	local svArea = Utils.newInstance("Frame", {
		Size            = UDim2.fromOffset(SV_SIZE, SV_SIZE),
		Position        = UDim2.fromOffset(8, 8),
		BackgroundColor3= Color3.fromHSV(H, 1, 1),
		BorderSizePixel = 0,
		ZIndex          = 56,
		ClipsDescendants= true,
	}, popup)
	Utils.newInstance("UICorner", { CornerRadius = UDim.new(0, 6) }, svArea)

	-- SV white gradient (left to right)
	Utils.newInstance("UIGradient", {
		Color    = ColorSequence.new({ ColorSequenceKeypoint.new(0, Color3.new(1,1,1)), ColorSequenceKeypoint.new(1, Color3.new(1,1,1)) }),
		Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1) }),
		Rotation = 0,
	}, svArea)

	local svOverlay = Utils.newInstance("Frame", {
		Size            = UDim2.fromScale(1, 1),
		BackgroundColor3= Color3.new(0, 0, 0),
		BorderSizePixel = 0,
		ZIndex          = 57,
	}, svArea)
	Utils.newInstance("UIGradient", {
		Color        = ColorSequence.new({ ColorSequenceKeypoint.new(0, Color3.new(0,0,0)), ColorSequenceKeypoint.new(1, Color3.new(0,0,0)) }),
		Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(1, 0) }),
		Rotation     = 90,
	}, svOverlay)

	local svCursor = Utils.newInstance("Frame", {
		Size            = UDim2.fromOffset(12, 12),
		AnchorPoint     = Vector2.new(0.5, 0.5),
		Position        = UDim2.new(S, 0, 1 - V, 0),
		BackgroundColor3= Color3.new(1, 1, 1),
		BorderSizePixel = 0,
		ZIndex          = 58,
	}, svArea)
	Utils.newInstance("UICorner", { CornerRadius = UDim.new(0.5, 0) }, svCursor)
	Utils.newInstance("UIStroke", { Color = Color3.new(0,0,0), Thickness = 2 }, svCursor)

	-- Hue bar
	local hueBar = Utils.newInstance("Frame", {
		Size            = UDim2.fromOffset(SV_SIZE, 14),
		Position        = UDim2.fromOffset(8, SV_SIZE + 14),
		BorderSizePixel = 0,
		ZIndex          = 56,
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
		Size            = UDim2.fromOffset(8, 20),
		AnchorPoint     = Vector2.new(0.5, 0.5),
		Position        = UDim2.new(H, 0, 0.5, 0),
		BackgroundColor3= Color3.new(1, 1, 1),
		BorderSizePixel = 0,
		ZIndex          = 57,
	}, hueBar)
	Utils.newInstance("UICorner", { CornerRadius = UDim.new(0, 3) }, hueCursor)
	Utils.newInstance("UIStroke", { Color = Color3.new(0,0,0), Thickness = 1 }, hueCursor)

	-- Hex input
	local hexFrame = Utils.newInstance("Frame", {
		Size            = UDim2.fromOffset(SV_SIZE, 28),
		Position        = UDim2.fromOffset(8, SV_SIZE + 36),
		BackgroundColor3= T.BackgroundSecond,
		BorderSizePixel = 0,
		ZIndex          = 56,
	}, popup)
	Utils.newInstance("UICorner", { CornerRadius = UDim.new(0, 6) }, hexFrame)
	Utils.newInstance("UIPadding", { PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8) }, hexFrame)
	local hexInput = Utils.newInstance("TextBox", {
		Size            = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Text            = Utils.colorToHex(initColor),
		Font            = T.Font,
		TextSize        = 13,
		TextColor3      = T.TextPrimary,
		TextXAlignment  = Enum.TextXAlignment.Center,
		ZIndex          = 57,
	}, hexFrame)

	local function getColor() return Color3.fromHSV(H, S, V) end

	local function updateUI()
		local color = getColor()
		swatch.BackgroundColor3 = color
		hexInput.Text           = Utils.colorToHex(color)
		svArea.BackgroundColor3 = Color3.fromHSV(H, 1, 1)
		svCursor.Position       = UDim2.new(S, 0, 1 - V, 0)
		hueCursor.Position      = UDim2.new(H, 0, 0.5, 0)
		self:emit("ValueChanged", color)
		if opts.OnChange then opts.OnChange(color) end
	end

	-- SV dragging
	local svDrag = false
	svArea.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or
		   input.UserInputType == Enum.UserInputType.Touch then
			svDrag = true
		end
	end)

	local function updateSV(px, py)
		if not svDrag then return end
		local ap = svArea.AbsolutePosition
		local as = svArea.AbsoluteSize
		S = Utils.clamp((px - ap.X) / as.X, 0, 1)
		V = 1 - Utils.clamp((py - ap.Y) / as.Y, 0, 1)
		updateUI()
	end

	self:_conn(UserInputService.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement or
		   input.UserInputType == Enum.UserInputType.Touch then
			updateSV(input.Position.X, input.Position.Y)
		end
	end))

	-- Hue dragging
	local hueDrag = false
	hueBar.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or
		   input.UserInputType == Enum.UserInputType.Touch then
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
		if input.UserInputType == Enum.UserInputType.MouseButton1 or
		   input.UserInputType == Enum.UserInputType.Touch then
			svDrag  = false
			hueDrag = false
		end
	end))

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
		updatePopupPos()
		popup.Visible = popupOpen
	end)

	-- Close popup when clicking outside
	self:_conn(UserInputService.InputBegan:Connect(function(input)
		if not popupOpen then return end
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			task.defer(function()
				if not swatch:IsAncestorOf(input.Target) and not popup:IsAncestorOf(input.Target) then
					popupOpen = false
					popup.Visible = false
				end
			end)
		end
	end))

	updateUI()
	self.getValue = function() return getColor() end
	self.setValue = function(_, color)
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

function ScrollFrameComp.new(parent, theme, opts)
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
		ScrollBarThickness   = 4,
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

	self.Instance     = sf
	self.ContentFrame = sf

	function self:addChild(instance)
		instance.Parent = sf
	end

	return self
end

-- ============================================================
--  UI WINDOW  (main draggable frame) — ALL BUGS FIXED
-- ============================================================
local UIWindow = {}
UIWindow.__index = UIWindow
setmetatable(UIWindow, { __index = BaseComponent })

function UIWindow.new(screenGui, theme, opts)
	local self   = BaseComponent.new()
	setmetatable(self, UIWindow)
	local T      = theme
	opts         = opts or {}

	local width   = opts.Size and opts.Size.X.Offset or 480
	local height  = opts.Size and opts.Size.Y.Offset or 380
	local startX  = opts.Position and opts.Position.X.Offset or 80
	local startY  = opts.Position and opts.Position.Y.Offset or 60
	local TITLE_H = 44

	-- FIX: Shadow starts fully transparent (was 0.5 before = visible before window appears)
	local shadow = Utils.newInstance("Frame", {
		Name            = "WindowShadow",
		Size            = UDim2.fromOffset(width + 24, height + 24),
		Position        = UDim2.fromOffset(startX - 12, startY - 12),
		BackgroundColor3= T.WindowShadow,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ZIndex          = 1,
	}, screenGui)
	Utils.newInstance("UICorner", { CornerRadius = UDim.new(0, 16) }, shadow)
	-- FIX: No UIBlur (it doesn't exist, this was crashing the whole window)
	-- FIX: Window ClipsDescendants = false so dropdowns/popups are not cut off
	-- FIX: BackgroundTransparency is 0 from the start - tweening it caused UIStroke
	--      to remain visible as a floating border while the bg was still invisible.
	--      We animate size+position instead, which is much more reliable.
	local window = Utils.newInstance("Frame", {
		Name            = "Window",
		Size            = UDim2.fromOffset(width * 0.92, height * 0.92),
		Position        = UDim2.fromOffset(startX + width * 0.04, startY + height * 0.04),
		BackgroundColor3= T.Background,
		BackgroundTransparency = 0,
		BorderSizePixel = 0,
		ZIndex          = 2,
		ClipsDescendants = false,
	}, screenGui)
	Utils.newInstance("UIStroke", { Color = T.Border, Thickness = 1 }, window)
	Utils.newInstance("UICorner", { CornerRadius = UDim.new(0, 12) }, window)
	self.Instance = window

	-- FIX: syncShadow uses task.defer so AbsolutePosition/Size are valid
	local function syncShadow()
		task.defer(function()
			if not window.Parent then return end
			shadow.Position = UDim2.fromOffset(window.AbsolutePosition.X - 12, window.AbsolutePosition.Y - 12)
			shadow.Size     = UDim2.fromOffset(window.AbsoluteSize.X + 24, window.AbsoluteSize.Y + 24)
		end)
	end

	-- Title bar
	local titleBar = Utils.newInstance("Frame", {
		Name            = "TitleBar",
		Size            = UDim2.new(1, 0, 0, TITLE_H),
		BackgroundColor3= T.TitleBar,
		BorderSizePixel = 0,
		ZIndex          = 3,
		ClipsDescendants= false,
	}, window)
	Utils.newInstance("UICorner", { CornerRadius = UDim.new(0, 12) }, titleBar)
	Utils.newInstance("UIPadding", {
		PaddingLeft  = UDim.new(0, 14),
		PaddingRight = UDim.new(0, 10),
	}, titleBar)

	-- Icon (optional)
	local iconOffset = 0
	if opts.Icon then
		Utils.newInstance("ImageLabel", {
			Size            = UDim2.fromOffset(18, 18),
			AnchorPoint     = Vector2.new(0, 0.5),
			Position        = UDim2.new(0, 0, 0.5, 0),
			BackgroundTransparency = 1,
			Image           = opts.Icon,
			ZIndex          = 4,
		}, titleBar)
		iconOffset = 26
	end

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

	-- Window controls
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

	local function makeCtrlBtn(text, hoverColor)
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
			Utils.tween(btn, T.AnimSpeed, { BackgroundColor3 = hoverColor, TextColor3 = T.TextOnAccent })
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
		task.delay(T.AnimSpeed, syncShadow)
		self:emit(minimized and "Minimized" or "Restored")
	end))

	self:_conn(closeBtn.MouseButton1Click:Connect(function()
		if opts.CloseConfirm then
			self:emit("CloseRequested")
		else
			self:close()
		end
	end))

	-- Divider
	Utils.newInstance("Frame", {
		Name            = "Divider",
		Size            = UDim2.new(1, 0, 0, 1),
		Position        = UDim2.fromOffset(0, TITLE_H),
		BackgroundColor3= T.Border,
		BorderSizePixel = 0,
		ZIndex          = 3,
	}, window)

	-- FIX: Content is now a ScrollingFrame with UIListLayout + UIPadding
	--      so components automatically stack instead of all sitting at (0,0)
	local contentClip = Utils.newInstance("Frame", {
		Name            = "ContentClip",
		Size            = UDim2.new(1, 0, 1, -(TITLE_H + 1)),
		Position        = UDim2.fromOffset(0, TITLE_H + 1),
		BackgroundTransparency = 1,
		ZIndex          = 2,
		ClipsDescendants = true,
	}, window)
	Utils.newInstance("UICorner", { CornerRadius = UDim.new(0, 10) }, contentClip)

	local content = Utils.newInstance("ScrollingFrame", {
		Name            = "Content",
		Size            = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		ZIndex          = 2,
		ClipsDescendants = false,
		CanvasSize           = UDim2.fromOffset(0, 0),
		AutomaticCanvasSize  = Enum.AutomaticSize.Y,
		ScrollBarThickness   = 4,
		ScrollBarImageColor3 = T.ScrollBar,
		BorderSizePixel      = 0,
		ElasticBehavior      = Enum.ElasticBehavior.WhenScrollable,
	}, contentClip)
	Utils.newInstance("UIPadding", {
		PaddingLeft   = UDim.new(0, 12),
		PaddingRight  = UDim.new(0, 12),
		PaddingTop    = UDim.new(0, 12),
		PaddingBottom = UDim.new(0, 12),
	}, content)
	Utils.newInstance("UIListLayout", {
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding   = UDim.new(0, 10),
	}, content)
	self.Content = content

	-- Drag system
	self._drag = DragManager.new(window, titleBar, {
		snapToEdge    = opts.SnapToEdge or false,
		snapThreshold = 20,
	})
	self._drag:onDragEnd(syncShadow)

	-- Entry animation: size+position only (no transparency - see comment above)
	-- Shadow starts hidden and fades in separately
	shadow.BackgroundTransparency = 1
	Utils.tween(window, T.AnimSpeed * 1.5, {
		Size     = UDim2.fromOffset(width, height),
		Position = UDim2.fromOffset(startX, startY),
	}, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
	Utils.tween(shadow, T.AnimSpeed * 1.5, { BackgroundTransparency = 0.72 })
	task.delay(T.AnimSpeed * 1.5 + 0.05, syncShadow)

	-- Public API
	self.TitleLabel = titleLabel
	self._shadow    = shadow
	self._width     = width
	self._height    = height

	function self:setTitle(t)
		titleLabel.Text = t
	end

	function self:resize(w, h)
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
		-- Animate out then clean up all memory
		Utils.tween(window, T.AnimSpeed, {
			Size     = UDim2.fromOffset(self._width * 0.92, self._height * 0.92),
			Position = UDim2.fromOffset(startX + self._width * 0.04, startY + self._height * 0.04),
		}, Enum.EasingStyle.Back, Enum.EasingDirection.In)
		Utils.tween(shadow, T.AnimSpeed, { BackgroundTransparency = 1 })
		task.delay(T.AnimSpeed + 0.05, function()
			-- Disconnect all connections from drag manager
			if self._drag then self._drag:destroy() end
			-- Destroy all children before frame
			for _, child in ipairs(window:GetDescendants()) do
				if child:IsA("RBXScriptConnection") then child:Disconnect() end
			end
			Utils.destroySafe(shadow)
			Utils.destroySafe(window)
			self._conns = {}
		end)
		self:emit("Closed")
	end

	-- Allow destroy via BaseComponent
	local origDestroy = self.destroy
	function self:destroy()
		self._drag:destroy()
		Utils.destroySafe(shadow)
		origDestroy(self)
	end

	return self
end

-- ============================================================
--  NEXUS UI  (main library entry point)
-- ============================================================
local NexusUI = {}
NexusUI.__index = NexusUI

function NexusUI.new(opts)
	local self   = setmetatable({}, NexusUI)
	opts         = opts or {}

	-- Create ScreenGui immediately so caller gets `self` back without yielding.
	-- We then parent it asynchronously which is safe for loadstring environments.
	local gui = Instance.new("ScreenGui")
	gui.Name           = opts.Name or "NexusUI"
	gui.ResetOnSpawn   = false
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.IgnoreGuiInset = true   -- avoids topbar inset offset problems
	gui.DisplayOrder   = 10

	if opts.Parent then
		-- Caller specified an explicit parent — use it immediately, no waiting needed
		gui.Parent = opts.Parent
	else
		-- Attempt CoreGui first (works in most executor environments)
		local ok = pcall(function() gui.Parent = game:GetService("CoreGui") end)
		if not ok then
			-- Fall back: wait for PlayerGui in a background thread (loadstring safe)
			task.spawn(function()
				local lp = Players.LocalPlayer
				if not lp then
					-- Give Roblox up to 10s to assign LocalPlayer
					local t0 = tick()
					repeat task.wait(0.05) lp = Players.LocalPlayer until lp or (tick() - t0 > 10)
				end
				if lp then
					local pg = lp:FindFirstChildOfClass("PlayerGui")
					           or lp:WaitForChild("PlayerGui", 10)
					if pg and not gui.Parent then
						gui.Parent = pg
					end
				end
			end)
		end
	end

	self._gui     = gui
	self._theme   = ThemeManager.new(opts.Theme)
	self._tooltip = TooltipSystem.new(self._theme:get(), gui)
	self._notif   = NotificationSystem.new(self._theme:get(), gui)
	self._modal   = ModalSystem.new(self._theme:get(), gui)
	self._ctxMenu = ContextMenu.new(self._theme:get(), gui)
	self._windows = {}

	self._themeUnsub = self._theme:onChange(function(newTheme)
		pcall(function() self._tooltip:destroy() end)
		pcall(function() self._notif:destroy() end)
		self._tooltip = TooltipSystem.new(newTheme, gui)
		self._notif   = NotificationSystem.new(newTheme, gui)
		self._modal   = ModalSystem.new(newTheme, gui)
		self._ctxMenu = ContextMenu.new(newTheme, gui)
	end)

	return self
end

function NexusUI:setTheme(preset) self._theme:apply(preset) end
function NexusUI:getTheme() return self._theme:get() end

function NexusUI:createWindow(opts)
	local win = UIWindow.new(self._gui, self._theme:get(), opts)
	table.insert(self._windows, win)
	win:on("Closed", function()
		for i, w in ipairs(self._windows) do
			if w == win then table.remove(self._windows, i); break end
		end
	end)
	return win
end

-- Component factories
function NexusUI:button(parent, opts)       return Button.new(parent, self._theme:get(), opts) end
function NexusUI:toggle(parent, opts)       return Toggle.new(parent, self._theme:get(), opts) end
function NexusUI:slider(parent, opts)       return Slider.new(parent, self._theme:get(), opts) end
function NexusUI:dropdown(parent, opts)     return Dropdown.new(parent, self._theme:get(), opts) end
function NexusUI:textbox(parent, opts)      return TextBoxComp.new(parent, self._theme:get(), opts) end
function NexusUI:checkbox(parent, opts)     return Checkbox.new(parent, self._theme:get(), opts) end
function NexusUI:progressBar(parent, opts)  return ProgressBar.new(parent, self._theme:get(), opts) end
function NexusUI:numberStepper(parent, opts)return NumberStepper.new(parent, self._theme:get(), opts) end
function NexusUI:radioGroup(parent, opts)   return RadioGroup.new(parent, self._theme:get(), opts) end
function NexusUI:accordion(parent, opts)    return Accordion.new(parent, self._theme:get(), opts) end
function NexusUI:tabSystem(parent, opts)    return TabSystem.new(parent, self._theme:get(), opts) end
function NexusUI:colorPicker(parent, opts)  return ColorPicker.new(parent, self._theme:get(), opts) end
function NexusUI:scrollFrame(parent, opts)  return ScrollFrameComp.new(parent, self._theme:get(), opts) end
function NexusUI:spinner(parent, opts)      return LoadingSpinner.new(parent, self._theme:get(), opts) end

-- Notifications
function NexusUI:notify(opts)                 self._notif:show(opts) end
function NexusUI:success(msg, title)          self._notif:show({ Title = title or "Success", Message = msg, Type = "success" }) end
function NexusUI:error(msg, title)            self._notif:show({ Title = title or "Error",   Message = msg, Type = "error" }) end
function NexusUI:warn(msg, title)             self._notif:show({ Title = title or "Warning", Message = msg, Type = "warning" }) end
function NexusUI:info(msg, title)             self._notif:show({ Title = title or "Info",    Message = msg, Type = "info" }) end

-- Modals
function NexusUI:showModal(opts)              return self._modal:show(opts) end
function NexusUI:confirm(title, msg, onOk, onCancel) return self._modal:confirm(title, msg, onOk, onCancel) end

-- Context menu
function NexusUI:showContextMenu(items, pos)  self._ctxMenu:show(items, pos) end
function NexusUI:attachContextMenu(target, items)
	target.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton2 then
			self._ctxMenu:show(items, UserInputService:GetMouseLocation())
		end
	end)
end

-- Tooltip
function NexusUI:tooltip(target, text, delay) return self._tooltip:attach(target, text, delay) end

-- Destroy everything - full memory cleanup
function NexusUI:destroy()
	-- Close all windows cleanly
	for _, w in ipairs(self._windows) do
		pcall(function() w:destroy() end)
	end
	self._windows = {}
	-- Destroy subsystems
	pcall(function() self._tooltip:destroy() end)
	pcall(function() self._notif:destroy() end)
	pcall(function() self._modal:destroy() end)
	pcall(function() self._ctxMenu:destroy() end)
	-- Disconnect theme change listener
	if self._themeUnsub then
		pcall(self._themeUnsub)
		self._themeUnsub = nil
	end
	-- Destroy screen gui last
	Utils.destroySafe(self._gui)
	self._gui = nil
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
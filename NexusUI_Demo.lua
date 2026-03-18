--[[
╔══════════════════════════════════════════════════════════════════════════════╗
║               NEXUS UI LIBRARY — COMPLETE DEMO SCRIPT                       ║
║                                                                                                      ║
╚══════════════════════════════════════════════════════════════════════════════╝
--]]

-- 🔹 LOAD LIBRARY (PUT YOUR REAL LOADER URL)
local NexusUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Virgo-G/NEXUS/refs/heads/main/NexusUI_Library.lua"))()

-- ─────────────────────────────────────────────
--  INITIALIZE
-- ─────────────────────────────────────────────
local ui = NexusUI.new({
	Theme = "Dark",
	Name  = "NexusDemoUI",
})

-- ─────────────────────────────────────────────
--  WINDOW 1
-- ─────────────────────────────────────────────
local win1 = ui:createWindow({
	Title       = "🎨 NexusUI — Component Showcase",
	Size        = UDim2.fromOffset(520, 580),
	Position    = UDim2.fromOffset(60, 50),
	SnapToEdge  = true,
})

local layout1 = Instance.new("UIListLayout", win1.Content)
layout1.Padding = UDim.new(0, 10)

local padding1 = Instance.new("UIPadding", win1.Content)
padding1.PaddingLeft = UDim.new(0, 16)
padding1.PaddingRight = UDim.new(0, 16)
padding1.PaddingTop = UDim.new(0, 12)
padding1.PaddingBottom = UDim.new(0, 12)

-- BUTTONS
local btn = ui:button(win1.Content, {
	Text = "Test Button",
	OnClick = function()
		ui:success("Executor working!", "Success")
	end,
})

-- TOGGLE
ui:toggle(win1.Content, {
	Label = "Toggle Test",
	Value = true,
	OnChange = function(v)
		ui:info("Toggle: "..tostring(v))
	end,
})

-- SLIDER
ui:slider(win1.Content, {
	Min = 0,
	Max = 100,
	Value = 50,
	Label = "Slider",
	OnChange = function(v)
		print(v)
	end,
})

-- DROPDOWN
ui:dropdown(win1.Content, {
	Items = {"A","B","C"},
	OnChange = function(v)
		ui:info("Selected: "..v)
	end,
})

-- TEXTBOX
ui:textbox(win1.Content, {
	Label = "Input",
	Placeholder = "Type...",
	OnSubmit = function(v)
		ui:success("You typed: "..v)
	end,
})

-- PROGRESS
local prog = ui:progressBar(win1.Content, {
	Value = 0.5,
	ShowPercent = true,
})

task.spawn(function()
	while task.wait(0.05) do
		prog:setValue(math.random())
	end
end)

-- ─────────────────────────────────────────────
--  WINDOW 2
-- ─────────────────────────────────────────────
local win2 = ui:createWindow({
	Title = "⚙️ Advanced",
	Size  = UDim2.fromOffset(400, 400),
	Position = UDim2.fromOffset(600, 50),
})

local tabs = ui:tabSystem(win2.Content, {
	Tabs = {
		{
			Name = "Main",
			Content = function(p)
				ui:button(p, {
					Text = "Hello",
					OnClick = function()
						ui:info("Hi from tab")
					end
				})
			end
		},
		{
			Name = "Settings",
			Content = function(p)
				ui:toggle(p, {
					Label = "Option",
				})
			end
		}
	}
})

-- ACCORDION
ui:accordion(win2.Content, {
	Title = "More",
	Open = true,
	Content = function(c)
		ui:textbox(c, {Label="Inside"})
	end
})

-- COLOR PICKER
ui:colorPicker(win2.Content, {
	Label = "Color",
})

-- RADIO
ui:radioGroup(win2.Content, {
	Label = "Select",
	Items = {"One","Two","Three"},
})

-- ─────────────────────────────────────────────
--  WINDOW 3
-- ─────────────────────────────────────────────
local win3 = ui:createWindow({
	Title = "📋 Scroll",
	Size  = UDim2.fromOffset(300, 350),
	Position = UDim2.fromOffset(1050, 50),
})

local scroll = ui:scrollFrame(win3.Content, {
	Size = UDim2.fromOffset(260, 200),
})

for i = 1, 15 do
	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.new(1,0,0,30)
	lbl.Text = "Item "..i
	lbl.Parent = scroll.ContentFrame
end

-- SPINNERS
ui:spinner(win3.Content, {Style="circle"})
ui:spinner(win3.Content, {Style="dots"})
ui:spinner(win3.Content, {Style="pulse"})

-- ─────────────────────────────────────────────
--  NOTIFICATIONS
-- ─────────────────────────────────────────────
task.delay(1, function()
	ui:success("Loaded!", "NexusUI")
end)

task.delay(2, function()
	ui:warn("Executor Mode Active")
end)

-- ─────────────────────────────────────────────
--  MODAL
-- ─────────────────────────────────────────────
win1:on("CloseRequested", function()
	ui:confirm("Close?", "Are you sure?",
		function() win1:close() end,
		function() end
	)
end)

-- ─────────────────────────────────────────────
--  CONTEXT MENU
-- ─────────────────────────────────────────────
ui:attachContextMenu(win2.Content, {
	{ Label = "Refresh", OnClick = function() ui:info("Refreshed") end },
	{ Separator = true },
	{ Label = "Close", OnClick = function() win2:close() end },
})

-- ─────────────────────────────────────────────
--  CLEANUP
-- ─────────────────────────────────────────────
game:GetService("Players").LocalPlayer.AncestryChanged:Connect(function()
	ui:destroy()
end)

print("✅ NexusUI Executor Demo Loaded!", NexusUI.Utils.getDeviceType())

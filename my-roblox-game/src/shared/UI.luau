-- Cute UI building blocks for LocalScripts, so new screens don't copy-paste the same helpers
local TweenService = game:GetService("TweenService")

local UI = {}

UI.CREAM = Color3.fromRGB(255, 248, 240)
UI.PINK = Color3.fromRGB(255, 120, 200)
UI.GREEN = Color3.fromRGB(90, 200, 120)
UI.GOLD = Color3.fromRGB(255, 200, 40)
UI.BLUE = Color3.fromRGB(90, 170, 255)
UI.PURPLE = Color3.fromRGB(170, 110, 255)
UI.GRAY = Color3.fromRGB(180, 175, 180)
UI.DARK = Color3.fromRGB(80, 50, 70)
UI.WHITE = Color3.new(1, 1, 1)
UI.FONT = Enum.Font.FredokaOne

function UI.corner(parent, radius)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = radius or UDim.new(1, 0)
	corner.Parent = parent
	return corner
end

function UI.stroke(parent, color, thickness)
	local stroke = Instance.new("UIStroke")
	stroke.Color = color
	stroke.Thickness = thickness
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Parent = parent
	return stroke
end

function UI.text(text, color)
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Font = UI.FONT
	label.TextScaled = true
	label.TextColor3 = color
	label.Text = text
	return label
end

function UI.button(text, color)
	local button = Instance.new("TextButton")
	button.BackgroundColor3 = color
	button.Font = UI.FONT
	button.TextScaled = true
	button.TextColor3 = UI.WHITE
	button.Text = text
	UI.corner(button)
	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0, 6)
	padding.PaddingBottom = UDim.new(0, 6)
	padding.PaddingLeft = UDim.new(0, 8)
	padding.PaddingRight = UDim.new(0, 8)
	padding.Parent = button
	return button
end

-- Bounces something in from smaller (or bigger) than normal
function UI.pop(target, from)
	local scale = target:FindFirstChildOfClass("UIScale") or Instance.new("UIScale", target)
	scale.Scale = from or 1.2
	TweenService:Create(scale, TweenInfo.new(0.3, Enum.EasingStyle.Back), { Scale = 1 }):Play()
end

-- A popup window with a title and an X. Returns the panel and its title label
function UI.panel(titleText, color, maxSize)
	local panel = Instance.new("Frame")
	panel.AnchorPoint = Vector2.new(0.5, 0.5)
	panel.Position = UDim2.fromScale(0.5, 0.5)
	panel.Size = UDim2.fromScale(0.9, 0.8)
	panel.BackgroundColor3 = UI.CREAM
	panel.Visible = false
	UI.corner(panel, UDim.new(0, 24))
	UI.stroke(panel, color, 4)
	local sizeLimit = Instance.new("UISizeConstraint")
	sizeLimit.MaxSize = maxSize or Vector2.new(560, 480)
	sizeLimit.Parent = panel

	local title = UI.text(titleText, color)
	title.Position = UDim2.new(0, 20, 0, 12)
	title.Size = UDim2.new(1, -90, 0, 36)
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Parent = panel

	local close = UI.button("X", color)
	close.AnchorPoint = Vector2.new(1, 0)
	close.Position = UDim2.new(1, -12, 0, 12)
	close.Size = UDim2.fromOffset(40, 40)
	close.Parent = panel
	close.Activated:Connect(function()
		panel.Visible = false
	end)

	return panel, title
end

function UI.toggle(panel)
	panel.Visible = not panel.Visible
	if panel.Visible then
		UI.pop(panel, 0.8)
	end
end

-- A big round menu button in a screen corner. corner is "left" or "right".
-- Right row 0 is the bottom (Shop). Left row 0 is Inventory, just above the money counter
function UI.menuButton(gui, text, color, corner, row)
	local button = UI.button(text, color)
	local left = corner == "left"
	button.AnchorPoint = Vector2.new(if left then 0 else 1, 1)
	button.Position = UDim2.new(if left then 0 else 1, if left then 16 else -16, 1, (if left then -96 else -16) - row * 56)
	button.Size = UDim2.fromOffset(170, 46)
	UI.stroke(button, UI.WHITE, 3)
	button.Parent = gui
	return button
end

return UI

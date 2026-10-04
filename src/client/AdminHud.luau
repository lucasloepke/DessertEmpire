-- Left-side debug buttons. Visible only when the server sets AdminEnabled.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared", 10)
assert(Shared, "Missing ReplicatedStorage.Shared")

local TycoonConfig = require(Shared:WaitForChild("TycoonConfig", 10))
local Format = require(Shared:WaitForChild("Format", 10))

local AdminHud = {}

local function stroke(parent: GuiObject, thickness: number)
	local s = Instance.new("UIStroke")
	s.Thickness = thickness
	s.Color = Color3.new(0, 0, 0)
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	s.Parent = parent
end

local function corner(parent: GuiObject)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, 8)
	c.Parent = parent
end

local function makeButton(parent: Instance, name: string, text: string, order: number, color: Color3): TextButton
	local button = Instance.new("TextButton")
	button.Name = name
	button.LayoutOrder = order
	button.Size = UDim2.new(1, 0, 0, 40)
	button.BackgroundColor3 = color
	button.AutoButtonColor = true
	button.Text = text
	button.TextColor3 = Color3.new(1, 1, 1)
	button.TextSize = 18
	button.Font = Enum.Font.GothamBold
	button.Parent = parent
	corner(button)
	stroke(button, 2)
	return button
end

function AdminHud.start()
	local player = Players.LocalPlayer

	local remotes = ReplicatedStorage:WaitForChild(TycoonConfig.Remotes.Folder, 10)
	assert(remotes, "Missing ReplicatedStorage." .. TycoonConfig.Remotes.Folder)
	local adminAction = remotes:WaitForChild(TycoonConfig.Remotes.AdminAction, 10)
	assert(
		adminAction and adminAction:IsA("RemoteEvent"),
		"Missing RemoteEvent " .. TycoonConfig.Remotes.AdminAction
	)

	local playerGui = player:WaitForChild("PlayerGui", 10)
	assert(playerGui, "Missing PlayerGui")

	local gui = Instance.new("ScreenGui")
	gui.Name = "AdminHud"
	gui.ResetOnSpawn = false
	gui.Enabled = false
	gui.Parent = playerGui

	local panel = Instance.new("Frame")
	panel.Name = "Panel"
	panel.AnchorPoint = Vector2.new(0, 0)
	panel.Position = UDim2.fromOffset(16, 16)
	panel.Size = UDim2.fromOffset(160, 0)
	panel.AutomaticSize = Enum.AutomaticSize.Y
	panel.BackgroundColor3 = Color3.fromRGB(30, 30, 36)
	panel.BackgroundTransparency = 0.1
	panel.Parent = gui
	corner(panel)
	stroke(panel, 2.5)

	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0, 10)
	padding.PaddingBottom = UDim.new(0, 10)
	padding.PaddingLeft = UDim.new(0, 10)
	padding.PaddingRight = UDim.new(0, 10)
	padding.Parent = panel

	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Vertical
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, 8)
	layout.Parent = panel

	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.LayoutOrder = 1
	title.BackgroundTransparency = 1
	title.Size = UDim2.new(1, 0, 0, 20)
	title.Text = "ADMIN"
	title.TextColor3 = Color3.fromRGB(255, 200, 80)
	title.TextSize = 16
	title.Font = Enum.Font.GothamBold
	title.Parent = panel

	local addCash = makeButton(
		panel,
		"AddCash",
		"+" .. Format.cash(TycoonConfig.Admin.AddCashAmount),
		2,
		Color3.fromRGB(40, 140, 50)
	)
	local addCashLarge = makeButton(
		panel,
		"AddCashLarge",
		"+" .. Format.cash(TycoonConfig.Admin.AddCashAmountLarge),
		3,
		Color3.fromRGB(40, 140, 50)
	)
	local reset = makeButton(panel, "ResetProgress", "Reset Progress", 4, Color3.fromRGB(170, 55, 55))

	addCash.Activated:Connect(function()
		adminAction:FireServer("AddCash")
	end)
	addCashLarge.Activated:Connect(function()
		adminAction:FireServer("AddCashLarge")
	end)
	reset.Activated:Connect(function()
		adminAction:FireServer("ResetProgress")
	end)

	local function refresh()
		gui.Enabled = player:GetAttribute("AdminEnabled") == true
	end
	player:GetAttributeChangedSignal("AdminEnabled"):Connect(refresh)
	refresh()
end

return AdminHud

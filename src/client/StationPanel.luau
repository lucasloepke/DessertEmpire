-- Floating station panel: fades in near your stand, SELL requests a cycle,
-- and the bar animates from server-set CycleStartedAt / CycleEndsAt.
-- The client only draws and requests; the server decides and pays.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared", 10)
assert(Shared, "Missing ReplicatedStorage.Shared")

local TycoonConfig = require(Shared:WaitForChild("TycoonConfig", 10))
local Format = require(Shared:WaitForChild("Format", 10))

local StationPanel = {}

local function stroke(parent: GuiObject, thickness: number, mode: Enum.ApplyStrokeMode?)
	local s = Instance.new("UIStroke")
	s.Thickness = thickness
	s.Color = Color3.new(0, 0, 0)
	s.ApplyStrokeMode = mode or Enum.ApplyStrokeMode.Contextual
	s.Parent = parent
end

local function corner(parent: GuiObject)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, 8)
	c.Parent = parent
end

local function textLabel(parent: Instance, name: string, y: number, height: number, textSize: number, color: Color3): TextLabel
	local l = Instance.new("TextLabel")
	l.Name = name
	l.BackgroundTransparency = 1
	l.Position = UDim2.fromOffset(0, y)
	l.Size = UDim2.new(1, 0, 0, height)
	l.Text = ""
	l.TextColor3 = color
	l.TextSize = textSize
	l.Font = Enum.Font.GothamBold
	l.Parent = parent
	stroke(l, 2.5)
	return l
end

function StationPanel.start(onSale: (BasePart) -> ())
	local player = Players.LocalPlayer
	local panelCfg = TycoonConfig.Interact.Panel

	local remotes = ReplicatedStorage:WaitForChild(TycoonConfig.Remotes.Folder, 10)
	assert(remotes, "Missing ReplicatedStorage." .. TycoonConfig.Remotes.Folder)
	local stationAction = remotes:WaitForChild(TycoonConfig.Remotes.StationAction, 10)
	assert(
		stationAction and stationAction:IsA("RemoteEvent"),
		"Missing RemoteEvent " .. TycoonConfig.Remotes.StationAction
	)

	local playerGui = player:WaitForChild("PlayerGui", 10)
	assert(playerGui, "Missing PlayerGui")

	local gui = Instance.new("BillboardGui")
	gui.Name = "StationPanel"
	-- BillboardGuis ignore clicks on their buttons unless Active.
	gui.Active = true
	gui.AlwaysOnTop = true
	gui.LightInfluence = 0
	gui.ResetOnSpawn = false
	gui.Size = UDim2.fromOffset(240, 196)
	gui.StudsOffset = panelCfg.StudsOffset
	gui.Enabled = false
	gui.Parent = playerGui

	local canvas = Instance.new("CanvasGroup")
	canvas.Name = "Canvas"
	canvas.BackgroundTransparency = 1
	canvas.Size = UDim2.fromScale(1, 1)
	canvas.GroupTransparency = 1
	canvas.Parent = gui

	local title = textLabel(canvas, "Title", 0, 28, 24, Color3.new(1, 1, 1))
	local payout = textLabel(canvas, "Payout", 28, 36, 32, Color3.fromRGB(90, 235, 100))

	local bar = Instance.new("TextButton")
	bar.Name = "SellBar"
	bar.AnchorPoint = Vector2.new(0.5, 0)
	bar.Position = UDim2.new(0.5, 0, 0, 72)
	bar.Size = UDim2.new(0.92, 0, 0, 44)
	bar.BackgroundColor3 = Color3.fromRGB(40, 140, 50)
	bar.AutoButtonColor = false
	bar.Text = ""
	bar.Parent = canvas
	corner(bar)
	stroke(bar, 2.5, Enum.ApplyStrokeMode.Border)

	local fill = Instance.new("Frame")
	fill.Name = "Fill"
	fill.BackgroundColor3 = Color3.fromRGB(90, 230, 100)
	fill.BorderSizePixel = 0
	fill.Size = UDim2.fromScale(0, 1)
	fill.Parent = bar
	corner(fill)

	local barLabel = Instance.new("TextLabel")
	barLabel.Name = "Label"
	barLabel.BackgroundTransparency = 1
	barLabel.Size = UDim2.fromScale(1, 1)
	barLabel.ZIndex = 2
	barLabel.Text = "SELL"
	barLabel.TextColor3 = Color3.new(1, 1, 1)
	barLabel.TextSize = 26
	barLabel.Font = Enum.Font.GothamBold
	barLabel.Parent = bar
	stroke(barLabel, 2.5)

	local upgradeButton = Instance.new("TextButton")
	upgradeButton.Name = "UpgradeButton"
	upgradeButton.AnchorPoint = Vector2.new(0.5, 0)
	upgradeButton.Position = UDim2.new(0.5, 0, 0, 128)
	upgradeButton.Size = UDim2.new(0.66, 0, 0, 40)
	upgradeButton.AutoButtonColor = false
	upgradeButton.Text = ""
	upgradeButton.Parent = canvas
	corner(upgradeButton)
	stroke(upgradeButton, 2.5, Enum.ApplyStrokeMode.Border)

	-- Separate label: one UIStroke per object, and the button's is its border.
	local upgradeLabel = Instance.new("TextLabel")
	upgradeLabel.Name = "Label"
	upgradeLabel.BackgroundTransparency = 1
	upgradeLabel.Size = UDim2.fromScale(1, 1)
	upgradeLabel.Text = "UPGRADE"
	upgradeLabel.TextColor3 = Color3.new(1, 1, 1)
	upgradeLabel.TextSize = 24
	upgradeLabel.Font = Enum.Font.GothamBold
	upgradeLabel.Parent = upgradeButton
	stroke(upgradeLabel, 2.5)

	local levelBadge = Instance.new("TextLabel")
	levelBadge.Name = "Level"
	levelBadge.BackgroundTransparency = 1
	levelBadge.Position = UDim2.fromOffset(-10, -14)
	levelBadge.Size = UDim2.fromOffset(60, 20)
	levelBadge.TextXAlignment = Enum.TextXAlignment.Left
	levelBadge.Text = ""
	levelBadge.TextColor3 = Color3.fromRGB(255, 225, 90)
	levelBadge.TextSize = 18
	levelBadge.Font = Enum.Font.GothamBold
	levelBadge.ZIndex = 2
	levelBadge.Parent = upgradeButton
	stroke(levelBadge, 2)

	local upgradeCost = textLabel(canvas, "UpgradeCost", 170, 24, 20, Color3.fromRGB(90, 235, 100))

	local affordableColor = TycoonConfig.Interact.Button.Colors.Cyan
	local unaffordableColor = Color3.fromRGB(130, 130, 135)

	local stand: Model? = nil
	local counter: BasePart? = nil
	local saleConnection: RBXScriptConnection? = nil

	local function setStand(newStand: Instance?)
		if saleConnection then
			saleConnection:Disconnect()
			saleConnection = nil
		end
		stand, counter = nil, nil
		gui.Adornee = nil

		if not (newStand and newStand:IsA("Model")) then
			return
		end
		local c = newStand:FindFirstChild("Counter")
		if not (c and c:IsA("BasePart")) then
			return
		end
		stand, counter = newStand, c
		gui.Adornee = c

		-- Only count increases, so the initial 0 on join doesn't play a sale.
		local lastCount = newStand:GetAttribute("SaleCount") or 0
		saleConnection = newStand:GetAttributeChangedSignal("SaleCount"):Connect(function()
			local count = newStand:GetAttribute("SaleCount") or 0
			if count > lastCount then
				onSale(c)
			end
			lastCount = count
		end)
	end

	local function bindStationValue(child: Instance)
		if child.Name ~= "Station" or not child:IsA("ObjectValue") then
			return
		end
		setStand(child.Value)
		child.Changed:Connect(function()
			setStand(child.Value)
		end)
	end

	-- The server creates Player.Station during join, possibly after this runs.
	local existing = player:FindFirstChild("Station")
	if existing then
		bindStationValue(existing)
	end
	player.ChildAdded:Connect(bindStationValue)

	bar.Activated:Connect(function()
		if not stand or stand:GetAttribute("Automated") == true then
			return
		end
		if Workspace:GetServerTimeNow() < (stand:GetAttribute("CycleEndsAt") or 0) then
			return
		end
		stationAction:FireServer("Sell", stand:GetAttribute("StationId"))
	end)

	-- Client pre-check is cosmetic; the server re-checks affordability.
	upgradeButton.Activated:Connect(function()
		if not stand then
			return
		end
		local cash = player:GetAttribute("Cash") or 0
		if cash < (stand:GetAttribute("UpgradeCost") or math.huge) then
			return
		end
		stationAction:FireServer("Upgrade", stand:GetAttribute("StationId"))
	end)

	local transparency = 1
	RunService.RenderStepped:Connect(function(dt: number)
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		local near = false
		if counter and root and root:IsA("BasePart") then
			near = (root.Position - counter.Position).Magnitude <= TycoonConfig.StationInteractDistance
		end

		local target = if near then 0 else 1
		transparency += (target - transparency) * math.clamp(dt * panelCfg.FadeSpeed, 0, 1)
		canvas.GroupTransparency = transparency
		gui.Enabled = transparency < 0.98

		if not (stand and gui.Enabled) then
			return
		end

		title.Text = string.upper(stand:GetAttribute("DisplayName") or stand.Name)
		payout.Text = Format.cash(stand:GetAttribute("Payout") or 0)

		local startedAt = stand:GetAttribute("CycleStartedAt") or 0
		local endsAt = stand:GetAttribute("CycleEndsAt") or 0
		local now = Workspace:GetServerTimeNow()
		local running = endsAt > startedAt and now < endsAt
		local progress = if running then math.clamp((now - startedAt) / (endsAt - startedAt), 0, 1) else 0
		fill.Size = UDim2.fromScale(progress, 1)

		local automated = stand:GetAttribute("Automated") == true
		barLabel.Text = if automated then "AUTO" elseif running then "SELLING..." else "SELL"

		local cost = stand:GetAttribute("UpgradeCost") or 0
		local cash = player:GetAttribute("Cash") or 0
		upgradeButton.BackgroundColor3 = if cash >= cost then affordableColor else unaffordableColor
		levelBadge.Text = "Lv " .. tostring(stand:GetAttribute("Level") or 0)
		upgradeCost.Text = Format.cash(cost)
	end)
end

return StationPanel

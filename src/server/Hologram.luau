-- Distance-gated BillboardGuis for purchase labels.
-- Far away: MaxDistance hides text. Close: title / copy / cost read clearly.
-- The clickable station panel is client-side (StationPanel) because world
-- BillboardGuis can't receive clicks.

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared", 10)
assert(Shared, "Missing ReplicatedStorage.Shared")

local TycoonConfig = require(Shared:WaitForChild("TycoonConfig", 10))

local Hologram = {}

local function stroke(parent: GuiObject, thickness: number)
	local s = Instance.new("UIStroke")
	s.Thickness = thickness
	s.Color = Color3.new(0, 0, 0)
	s.LineJoinMode = Enum.LineJoinMode.Round
	s.Parent = parent
end

local function newLabel(parent: Instance, name: string, height: number, textSize: number, font: Enum.Font, order: number): TextLabel
	local l = Instance.new("TextLabel")
	l.Name = name
	l.BackgroundTransparency = 1
	l.Size = UDim2.new(1, 0, 0, height)
	l.Text = ""
	l.TextColor3 = Color3.new(1, 1, 1)
	l.TextSize = textSize
	l.Font = font
	l.TextWrapped = true
	l.LayoutOrder = order
	l.Parent = parent
	stroke(l, 2.5)
	return l
end

local function attachBillboard(adornee: BasePart, name: string, maxDistance: number, size: UDim2, offset: Vector3): BillboardGui
	local gui = Instance.new("BillboardGui")
	gui.Name = name
	gui.Adornee = adornee
	gui.AlwaysOnTop = true
	gui.LightInfluence = 0
	gui.MaxDistance = maxDistance
	gui.Size = size
	-- World-space offset keeps the label planted above the adornee. Adornee must
	-- be axis-aligned (use HologramAnchor on tilted button parts).
	gui.StudsOffset = Vector3.zero
	gui.StudsOffsetWorldSpace = offset
	gui.Parent = adornee
	return gui
end

local function buildPurchase(adornee: BasePart): BillboardGui
	local cfg = TycoonConfig.Interact.Hologram
	local gui = attachBillboard(
		adornee,
		"PurchaseHologram",
		cfg.TextMaxDistance,
		UDim2.fromOffset(cfg.Width, 110),
		cfg.StudsOffset
	)

	local root = Instance.new("Frame")
	root.Name = "Root"
	root.BackgroundTransparency = 1
	root.Size = UDim2.fromScale(1, 1)
	root.Parent = gui

	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Vertical
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.VerticalAlignment = Enum.VerticalAlignment.Bottom
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, 2)
	layout.Parent = root

	newLabel(root, "Title", 32, 28, Enum.Font.GothamBold, 1)
	newLabel(root, "Subtitle", 22, 16, Enum.Font.GothamMedium, 2).TextColor3 = Color3.fromRGB(235, 235, 235)
	newLabel(root, "Cost", 34, 30, Enum.Font.GothamBold, 3)

	return gui
end

export type PurchaseHologramOptions = {
	Title: string,
	Subtitle: string?,
	CostText: string,
	AccentColor: Color3,
}

--[[
	Purchase stack matching the close-up reference:
	TITLE (white) / subtitle (white) / $cost (accent).
	Creates the hologram on first call, then updates it in place.
]]
function Hologram.setPurchase(adornee: BasePart, options: PurchaseHologramOptions): BillboardGui
	local existing = adornee:FindFirstChild("PurchaseHologram")
	local gui = if existing and existing:IsA("BillboardGui") then existing else buildPurchase(adornee)

	local root = gui:FindFirstChild("Root") :: Frame
	local title = root:FindFirstChild("Title") :: TextLabel
	local subtitle = root:FindFirstChild("Subtitle") :: TextLabel
	local cost = root:FindFirstChild("Cost") :: TextLabel

	title.Text = string.upper(options.Title)
	subtitle.Text = options.Subtitle or ""
	subtitle.Visible = subtitle.Text ~= ""
	cost.Text = options.CostText
	cost.TextColor3 = options.AccentColor

	return gui
end

return Hologram

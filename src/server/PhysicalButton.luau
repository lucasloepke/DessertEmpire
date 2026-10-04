-- Uniform physical floor button used for every unlock / upgrade purchase.
-- Visuals only; StationService wires the walk-on purchase.

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared", 10)
assert(Shared, "Missing ReplicatedStorage.Shared")

local TycoonConfig = require(Shared:WaitForChild("TycoonConfig", 10))

local PhysicalButton = {}

export type ButtonOptions = {
	Name: string?,
	CFrame: CFrame,
	-- Key into TycoonConfig.Interact.Button.Colors, or a raw Color3.
	Color: (string | Color3)?,
	Kind: string?,
	StationId: string?,
}

function PhysicalButton.resolveColor(color: (string | Color3)?): Color3
	local cfg = TycoonConfig.Interact.Button
	if typeof(color) == "Color3" then
		return color
	end
	if typeof(color) == "string" and cfg.Colors[color] then
		return cfg.Colors[color]
	end
	return cfg.Colors.Cyan
end

--[[
	Builds the shared button: dark ribbed base + neon pad + point light.
	Parent the returned Model wherever the purchase lives.
]]
function PhysicalButton.create(options: ButtonOptions): Model
	local cfg = TycoonConfig.Interact.Button
	local accent = PhysicalButton.resolveColor(options.Color)

	local model = Instance.new("Model")
	model.Name = options.Name or "PurchaseButton"

	local base = Instance.new("Part")
	base.Name = "Base"
	base.Shape = Enum.PartType.Cylinder
	base.Anchored = true
	base.CanCollide = true
	base.Material = Enum.Material.SmoothPlastic
	base.Color = cfg.BaseColor
	-- Cylinder default axis is +X; rotate so height is up.
	base.Size = Vector3.new(cfg.BaseHeight, cfg.BaseDiameter, cfg.BaseDiameter)
	base.CFrame = options.CFrame * CFrame.Angles(0, 0, math.rad(90))
	base.TopSurface = Enum.SurfaceType.Smooth
	base.BottomSurface = Enum.SurfaceType.Smooth
	base.Parent = model

	-- Vertical "tread" slots around the rim (reference screenshot).
	local slotCount = 12
	local rimRadius = cfg.BaseDiameter / 2 - 0.08
	for i = 1, slotCount do
		local angle = (i - 1) * (math.pi * 2 / slotCount)
		local slot = Instance.new("Part")
		slot.Name = "Tread_" .. i
		slot.Anchored = true
		slot.CanCollide = false
		slot.Material = Enum.Material.SmoothPlastic
		slot.Color = Color3.fromRGB(20, 20, 24)
		slot.Size = Vector3.new(0.22, cfg.BaseHeight * 0.85, 0.35)
		local offset = CFrame.new(
			math.cos(angle) * rimRadius,
			0,
			math.sin(angle) * rimRadius
		) * CFrame.Angles(0, -angle, 0)
		slot.CFrame = options.CFrame * offset
		slot.Parent = model
	end

	local pad = Instance.new("Part")
	pad.Name = "Pad"
	pad.Shape = Enum.PartType.Cylinder
	pad.Anchored = true
	pad.CanCollide = false
	pad.Material = Enum.Material.Neon
	pad.Color = accent
	pad.Size = Vector3.new(cfg.PadHeight, cfg.PadDiameter, cfg.PadDiameter)
	pad.CFrame = (options.CFrame + Vector3.new(0, cfg.BaseHeight / 2 + cfg.PadHeight / 2, 0))
		* CFrame.Angles(0, 0, math.rad(90))
	pad.TopSurface = Enum.SurfaceType.Smooth
	pad.BottomSurface = Enum.SurfaceType.Smooth
	pad.Parent = model

	local light = Instance.new("PointLight")
	light.Name = "Glow"
	light.Color = accent
	light.Range = cfg.GlowRange
	light.Brightness = cfg.GlowBrightness
	light.Parent = pad

	model.PrimaryPart = base
	model:SetAttribute("AccentColor", accent:ToHex())
	if options.Kind then
		model:SetAttribute("Kind", options.Kind)
	end
	if options.StationId then
		model:SetAttribute("StationId", options.StationId)
	end

	return model
end

function PhysicalButton.setColor(model: Model, color: (string | Color3)?)
	local accent = PhysicalButton.resolveColor(color)
	local pad = model:FindFirstChild("Pad")
	if pad and pad:IsA("BasePart") then
		pad.Color = accent
		local glow = pad:FindFirstChild("Glow")
		if glow and glow:IsA("PointLight") then
			glow.Color = accent
		end
	end
	model:SetAttribute("AccentColor", accent:ToHex())
end

return PhysicalButton

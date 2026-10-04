-- Builds every unlocked station model on a player's plot and keeps their visuals
-- (owned physical upgrades, floor buttons for available upgrades and the next
-- tier's unlock) in sync with save data.
-- Gameplay (sell cycle, purchases) lives in StationService.

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared", 10)
assert(Shared, "Missing ReplicatedStorage.Shared")

local TycoonConfig = require(Shared:WaitForChild("TycoonConfig", 10))
local Format = require(Shared:WaitForChild("Format", 10))
local StationMath = require(Shared:WaitForChild("StationMath", 10))
local DropParts = require(Shared:WaitForChild("DropParts", 10))

local DataService = require(script.Parent.DataService)
local PhysicalButton = require(script.Parent.PhysicalButton)
local Hologram = require(script.Parent.Hologram)

local StandService = {}

-- Where station space sits on this plot: the tier-1 counter spot.
type PlotFrame = {
	pad: BasePart,
	localZ: number,
	isNorth: boolean,
}

type StandRecord = {
	model: Model,
	frame: PlotFrame,
	-- Station-space offset of this station's counter (config Placement).
	origin: Vector3,
	config: any,
}

type PlayerStands = {
	plot: Model,
	frame: PlotFrame,
	stands: { [string]: StandRecord },
	cashConnection: RBXScriptConnection?,
}

local playerStands: { [Player]: PlayerStands } = {}

local function studsAllAround(part: BasePart)
	part.TopSurface = Enum.SurfaceType.Studs
	part.BottomSurface = Enum.SurfaceType.Studs
	part.LeftSurface = Enum.SurfaceType.Studs
	part.RightSurface = Enum.SurfaceType.Studs
	part.FrontSurface = Enum.SurfaceType.Studs
	part.BackSurface = Enum.SurfaceType.Studs
end

--[[
	Station-space → world. Offset is from the tier-1 counter's footprint:
	X across, Y up from the pad top (to the part's bottom), Z away from the street.
	South plots face the other way, so X and Z mirror.
	face: "Street" aims toward the street; "Employee" aims toward the plot
	(behind the counter).
]]
local function toWorld(frame: PlotFrame, offset: Vector3, height: number, face: string?): CFrame
	local sign = if frame.isNorth then 1 else -1
	local localPos = Vector3.new(
		offset.X * sign,
		frame.pad.Size.Y / 2 + offset.Y + height / 2,
		frame.localZ + offset.Z * sign
	)
	local worldPos = frame.pad.CFrame:PointToWorldSpace(localPos)
	if face == "Street" then
		return CFrame.lookAt(worldPos, worldPos + Vector3.new(0, 0, -sign))
	elseif face == "Employee" then
		return CFrame.lookAt(worldPos, worldPos + Vector3.new(0, 0, sign))
	elseif face == "Left" then
		-- Stand-space −X (toward the stand from the parlor).
		return CFrame.lookAt(worldPos, worldPos + Vector3.new(-sign, 0, 0))
	elseif face == "Right" then
		return CFrame.lookAt(worldPos, worldPos + Vector3.new(sign, 0, 0))
	end
	return CFrame.new(worldPos)
end

-- Same, with the offset relative to this station's own counter.
local function stationPoint(record: StandRecord, offset: Vector3, height: number, face: string?): CFrame
	return toWorld(record.frame, record.origin + offset, height, face)
end

local function faceFromVisual(visual: any): string?
	if visual.FaceEmployee == true then
		return "Employee"
	end
	if visual.FaceStreet == true then
		return "Street"
	end
	if visual.FaceLeft == true then
		return "Left"
	end
	if visual.FaceRight == true then
		return "Right"
	end
	return nil
end

-- ClearedBy = "StationId" once that station is unlocked, or
-- "StationId/UpgradeId" once that upgrade is owned. Site clutter on the
-- parlor land / foundation uses this so ropes and cones leave as it builds.
local function isCleared(clearedBy: any, data: any): boolean
	if typeof(clearedBy) ~= "string" or not data then
		return false
	end
	local slash = string.find(clearedBy, "/", 1, true)
	local stationId = if slash then string.sub(clearedBy, 1, slash - 1) else clearedBy
	local upgradeId = if slash then string.sub(clearedBy, slash + 1) else nil
	local station = data.stations[stationId]
	if not (station and station.unlocked) then
		return false
	end
	if upgradeId == nil or upgradeId == "" then
		return true
	end
	return station.owned[upgradeId] == true
end

local function applyClearedBy(record: StandRecord, data: any)
	for _, descendant in ipairs(record.model:GetDescendants()) do
		if isCleared(descendant:GetAttribute("ClearedBy"), data) then
			descendant:Destroy()
		end
	end
end

local function buttonCFrame(frame: PlotFrame, offset: Vector3): CFrame
	local buttonHeight = TycoonConfig.Interact.Button.BaseHeight
	return toWorld(frame, offset, buttonHeight) + Vector3.new(0, 0.02, 0)
end

local function grassTemplate(): BasePart?
	local name = TycoonConfig.PlotGrass.TemplateName
	local template = ReplicatedStorage:FindFirstChild(name)
	local workspaceCopy = Workspace:FindFirstChild(name)
	-- Prefer ReplicatedStorage; hide any world-placed template so it doesn't
	-- sit in the map (Studio often leaves the source MeshPart in Workspace).
	if workspaceCopy and workspaceCopy:IsA("BasePart") then
		if not (template and template:IsA("BasePart")) then
			workspaceCopy.Parent = ReplicatedStorage
			template = workspaceCopy
		else
			workspaceCopy.Anchored = true
			workspaceCopy.CanCollide = false
			workspaceCopy.CanQuery = false
			workspaceCopy.Transparency = 1
			workspaceCopy.CFrame = CFrame.new(0, -500, 0)
		end
	end
	if template and template:IsA("BasePart") then
		return template
	end
	return nil
end

local function pointInHole(x: number, z: number, hole: any, pad: number): boolean
	return x >= hole.MinX - pad
		and x <= hole.MaxX + pad
		and z >= hole.MinZ - pad
		and z <= hole.MaxZ + pad
end

--[[
	Scatter ReplicatedStorage.Grass tufts over a lawn region (stand-space),
	skipping hardscape holes. No DropIn — they appear in place so the parlor
	drop doesn't haul a hundred shrubs from the sky.
]]
local function scatterRegionGrass(record: StandRecord, region: any)
	local cfg = TycoonConfig.PlotGrass
	local template = grassTemplate()
	if not template then
		warn("[StandService] Missing " .. cfg.TemplateName .. " mesh (ReplicatedStorage or Workspace)")
		return
	end

	local folder = record.model:FindFirstChild("GrassTufts")
	if folder then
		folder:Destroy()
	end
	folder = Instance.new("Folder")
	folder.Name = "GrassTufts"
	folder.Parent = record.model

	local spacing = cfg.Spacing
	local jitter = cfg.Jitter
	-- Inflate holes by ~half the mesh so centers stay off hardscape edges.
	local holePad = math.max(template.Size.X, template.Size.Z) * 0.45
	local rng = Random.new(record.config.Id:len() * 97 + math.floor(region.MinX + region.MaxZ))
	local index = 0
	for x = region.MinX + spacing * 0.5, region.MaxX, spacing do
		for z = region.MinZ + spacing * 0.5, region.MaxZ, spacing do
			local px = x + rng:NextNumber(-jitter, jitter)
			local pz = z + rng:NextNumber(-jitter, jitter)
			if px < region.MinX or px > region.MaxX or pz < region.MinZ or pz > region.MaxZ then
				continue
			end
			local blocked = false
			for _, hole in ipairs(region.Holes or {}) do
				if pointInHole(px, pz, hole, holePad) then
					blocked = true
					break
				end
			end
			if blocked then
				continue
			end

			index += 1
			local tuft = template:Clone()
			tuft.Name = "Grass" .. index
			tuft.Anchored = true
			tuft.CanCollide = false
			tuft.CanTouch = false
			tuft.CanQuery = false
			tuft.CastShadow = false
			local scale = rng:NextNumber(cfg.ScaleMin, cfg.ScaleMax)
			tuft.Size = template.Size * scale
			local yaw = rng:NextNumber(0, math.pi * 2)
			-- Bottom on the lawn top; toWorld places by bottom-center height.
			local world = toWorld(record.frame, Vector3.new(px, cfg.Y, pz), tuft.Size.Y)
			tuft.CFrame = CFrame.new(world.Position) * CFrame.Angles(0, yaw, 0)
			tuft.Parent = folder
		end
	end
end

local function syncPlotGrass(entry: PlayerStands, data: any)
	local cfg = TycoonConfig.PlotGrass
	-- Bump when hole/region layout changes so existing plots re-plant once.
	local layoutVersion = 6
	for _, region in ipairs(cfg.Regions or {}) do
		local record = entry.stands[region.StationId]
		local station = data.stations[region.StationId]
		if record and station and station.unlocked then
			local folder = record.model:FindFirstChild("GrassTufts")
			if not (folder and folder:GetAttribute("Layout") == layoutVersion) then
				scatterRegionGrass(record, region)
				folder = record.model:FindFirstChild("GrassTufts")
				if folder then
					folder:SetAttribute("Layout", layoutVersion)
				end
			end
		end
	end
end

--[[
	Tag something that was just bought/built so every client drops it in from
	the sky (client DropIn.luau). Call before parenting so it never shows at its
	final spot first. delay staggers it (e.g. the NPC lands after its props).
]]
local function markDrop(instance: Instance, delay: number?)
	instance:SetAttribute("DropAt", Workspace:GetServerTimeNow())
	if delay then
		instance:SetAttribute("DropDelay", delay)
	end
	-- Client waits for this many parts to replicate before animating.
	instance:SetAttribute("DropParts", #DropParts.collect(instance))
	CollectionService:AddTag(instance, TycoonConfig.Tags.DropIn)
end

local function smoothAllAround(part: BasePart)
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.LeftSurface = Enum.SurfaceType.Smooth
	part.RightSurface = Enum.SurfaceType.Smooth
	part.FrontSurface = Enum.SurfaceType.Smooth
	part.BackSurface = Enum.SurfaceType.Smooth
end

local function spawnVisualPart(parent: Instance?, name: string, visual: any, record: StandRecord, ownerName: string?)
	local part = Instance.new("Part")
	part.Name = name
	part.Anchored = true
	part.Material = if typeof(visual.Material) == "string" and Enum.Material[visual.Material]
		then Enum.Material[visual.Material]
		else Enum.Material.Plastic
	part.Color = visual.Color
	part.Size = visual.Size
	part.CFrame = stationPoint(record, visual.Offset, visual.Size.Y, faceFromVisual(visual))
	if typeof(visual.Transparency) == "number" then
		part.Transparency = visual.Transparency
	end
	if visual.CanCollide == false then
		part.CanCollide = false
	end
	if typeof(visual.ClearedBy) == "string" then
		part:SetAttribute("ClearedBy", visual.ClearedBy)
	end
	-- Grass / Neon look wrong with studs; everything else stays placeholder-studded.
	if part.Material == Enum.Material.Grass or part.Material == Enum.Material.Neon then
		smoothAllAround(part)
	else
		studsAllAround(part)
	end
	part.Parent = parent

	local lightCfg = visual.PointLight
	if typeof(lightCfg) == "table" then
		local light = Instance.new("PointLight")
		light.Name = "Glow"
		light.Brightness = if typeof(lightCfg.Brightness) == "number" then lightCfg.Brightness else 2
		light.Range = if typeof(lightCfg.Range) == "number" then lightCfg.Range else 24
		light.Color = if typeof(lightCfg.Color) == "Color3" then lightCfg.Color else Color3.fromRGB(255, 248, 235)
		light.Shadows = lightCfg.Shadows == true
		light.Parent = part
	end

	if typeof(visual.Label) == "string" and visual.Label ~= "" then
		local text = string.gsub(visual.Label, "{Player}", ownerName or "Player")
		local gui = Instance.new("SurfaceGui")
		gui.Name = "SignLabel"
		gui.Face = Enum.NormalId.Front
		gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
		gui.PixelsPerStud = 40
		gui.Parent = part

		local label = Instance.new("TextLabel")
		label.Name = "Text"
		label.BackgroundTransparency = 1
		label.Size = UDim2.fromScale(1, 1)
		label.Text = text
		label.TextColor3 = Color3.new(1, 1, 1)
		label.TextScaled = true
		label.Font = Enum.Font.GothamBold
		label.Parent = gui

		local pad = Instance.new("UIPadding")
		pad.PaddingLeft = UDim.new(0.06, 0)
		pad.PaddingRight = UDim.new(0.06, 0)
		pad.PaddingTop = UDim.new(0.12, 0)
		pad.PaddingBottom = UDim.new(0.12, 0)
		pad.Parent = label

		local stroke = Instance.new("UIStroke")
		stroke.Thickness = 2
		stroke.Color = Color3.new(0, 0, 0)
		stroke.Parent = label
	end

	return part
end

--[[
	Clone ReplicatedStorage.Cashier (Creator Store) onto the stand as an
	anchored prop, feet on the pad. Tagged Npc for the client's idle chatter;
	the purchase drop-in is markDrop's job, like every other visual.
]]
local function spawnTemplateModel(parent: Instance, name: string, visual: any, record: StandRecord)
	local templateName = visual.ModelTemplate or "Cashier"
	local template = ReplicatedStorage:FindFirstChild(templateName)
	if not (template and template:IsA("Model")) then
		warn("[StandService] Missing ReplicatedStorage." .. tostring(templateName) .. " — skip NPC visual")
		return nil
	end

	local model = template:Clone()
	model.Name = name

	-- Animate is a LocalScript for player characters; drop it on the NPC prop.
	local animate = model:FindFirstChild("Animate")
	if animate then
		animate:Destroy()
	end

	local humanoid = model:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
		humanoid.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
		humanoid.NameDisplayDistance = 0
		humanoid.HealthDisplayDistance = 0
		humanoid.WalkSpeed = 0
		humanoid.JumpPower = 0
		humanoid.JumpHeight = 0
		humanoid.AutoRotate = false
	end

	-- Seat height: pivot above the model's bounding-box bottom.
	local bbCF, bbSize = model:GetBoundingBox()
	local pivot = model:GetPivot()
	local bottomToPivot = pivot.Position.Y - (bbCF.Position.Y - bbSize.Y / 2)
	local floorCF = stationPoint(record, visual.Offset, 0, faceFromVisual(visual))
	local seatedCF = floorCF * CFrame.new(0, bottomToPivot, 0)

	for _, descendant in ipairs(model:GetDescendants()) do
		if descendant:IsA("BasePart") then
			descendant.Anchored = true
			descendant.CanCollide = false
			descendant.CanTouch = false
			descendant.CanQuery = false
		end
	end

	model:PivotTo(seatedCF)
	CollectionService:AddTag(model, TycoonConfig.Tags.Npc)
	model.Parent = parent

	return model
end

--[[
	Mark a model for the client's CartTraffic: it drives toward the street on
	sales. depart (optional, Visual.Depart) = { Group, Station, Distance,
	Cooldown }: models sharing a Group move together, triggered by Station's
	sales (default: the station that owns the model).
]]
local function markDeparts(model: Model, record: StandRecord, depart: any?)
	local sign = if record.frame.isNorth then 1 else -1
	model:SetAttribute("Departs", true)
	model:SetAttribute("DepartDirection", Vector3.new(0, 0, -sign))
	if depart then
		model:SetAttribute("DepartGroup", depart.Group)
		model:SetAttribute("DepartStation", depart.Station)
		model:SetAttribute("DepartDistance", depart.Distance)
		model:SetAttribute("DepartCooldown", depart.Cooldown)
		model:SetAttribute("DepartMaxAway", depart.MaxAway)
	end
end

local function spawnDepartingModel(parent: Instance, name: string, parts: { any }, record: StandRecord, depart: any?)
	local vehicle = Instance.new("Model")
	vehicle.Name = name
	for _, partVis in ipairs(parts) do
		spawnVisualPart(vehicle, partVis.Name, partVis, record)
	end
	markDeparts(vehicle, record, depart)
	vehicle.Parent = parent
	return vehicle
end

-- animate = just purchased (drop in from the sky); false when rebuilding on join.
local function spawnUpgradeVisual(folder: Instance, upgrade: any, record: StandRecord, ownerName: string, animate: boolean, data: any)
	local visual = upgrade.Visual
	if visual.ModelTemplate or visual.Parts or visual.DepartingParts or visual.Vehicles then
		local model = Instance.new("Model")
		model.Name = upgrade.Id
		if visual.ModelTemplate then
			local npc = spawnTemplateModel(model, "NPC", visual, record)
			if npc and visual.Depart and not visual.DepartingParts then
				-- An NPC-only visual with Depart rides along with its group.
				markDeparts(npc, record, visual.Depart)
			end
			if npc and animate then
				markDrop(npc, TycoonConfig.DropIn.NpcDelay)
			end
		end
		if visual.Parts then
			for _, partVis in ipairs(visual.Parts) do
				if not isCleared(partVis.ClearedBy, data) then
					spawnVisualPart(model, partVis.Name, partVis, record, ownerName)
				end
			end
		end
		if visual.DepartingParts then
			-- Separate model so the client's CartTraffic moves only these parts
			-- (not the asphalt); they leave toward the street.
			spawnDepartingModel(model, "Cart", visual.DepartingParts, record, visual.Depart)
		end
		if visual.Vehicles then
			for index, vehicleParts in ipairs(visual.Vehicles) do
				spawnDepartingModel(model, "Cart" .. index, vehicleParts, record, visual.Depart)
			end
		end
		if animate then
			markDrop(model)
		end
		model.Parent = folder
	else
		if isCleared(visual.ClearedBy, data) then
			return
		end
		local part = spawnVisualPart(nil, upgrade.Id, visual, record, ownerName)
		if animate then
			markDrop(part)
		end
		part.Parent = folder
	end
end

-- Add visuals for newly owned upgrades, remove ones no longer owned. Existing
-- visuals stay put, so the employee only drops in once.
local function syncUpgradeVisuals(record: StandRecord, station: any, ownerName: string, animate: boolean, data: any)
	local folder = record.model:FindFirstChild("Upgrades")
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = "Upgrades"
		folder.Parent = record.model
	end

	for _, upgrade in ipairs(record.config.Physical) do
		local existing = folder:FindFirstChild(upgrade.Id)
		if station.owned[upgrade.Id] then
			if existing and upgrade.Id == "NeonSign" then
				local neon = existing:FindFirstChild("Neon")
				local gui = neon and neon:FindFirstChild("SignLabel")
				local label = gui and gui:FindFirstChild("Text")
				if label and label:IsA("TextLabel") then
					label.Text = string.gsub("{Player}'s Popsicles!", "{Player}", ownerName)
				else
					-- Old above-counter layout (no name plate): rebuild once.
					existing:Destroy()
					existing = nil
				end
			end
			if not existing then
				spawnUpgradeVisual(folder, upgrade, record, ownerName, animate, data)
			end
		elseif existing then
			existing:Destroy()
		end
	end
end

type Offer = {
	name: string,
	cframe: CFrame,
	kind: string,
	stationId: string,
	upgradeId: string?,
	title: string,
	subtitle: string,
	cost: number,
}

--[[
	Every floor button this station shows right now: one per available physical
	upgrade, plus the next tier's unlock (placed where that station will stand).
]]
local function offersFor(record: StandRecord, data: any): { Offer }
	local offers = {}
	local station = data.stations[record.config.Id]
	for _, upgrade in ipairs(StationMath.availablePhysical(record.config, station)) do
		table.insert(offers, {
			name = "UpgradeButton_" .. upgrade.Id,
			cframe = buttonCFrame(record.frame, record.origin + (upgrade.ButtonOffset or Vector3.new(0, 0, 12))),
			kind = "PhysicalUpgrade",
			stationId = record.config.Id,
			upgradeId = upgrade.Id,
			title = upgrade.DisplayName,
			subtitle = StationMath.describeEffect(record.config, upgrade),
			cost = upgrade.Cost,
		})
	end

	local nextConfig = StationMath.nextUnlock(record.config, data)
	if nextConfig then
		table.insert(offers, {
			name = "UnlockButton_" .. nextConfig.Id,
			cframe = buttonCFrame(record.frame, nextConfig.UnlockButtonAt or nextConfig.Placement),
			kind = "StationUnlock",
			stationId = nextConfig.Id,
			upgradeId = nil,
			title = nextConfig.DisplayName,
			subtitle = nextConfig.UnlockSubtitle or "new station",
			cost = nextConfig.UnlockCost,
		})
	end
	return offers
end

local function isPurchaseButton(child: Instance): boolean
	if not child:IsA("Model") then
		return false
	end
	local kind = child:GetAttribute("Kind")
	return kind == "PhysicalUpgrade" or kind == "StationUnlock"
end

local function refreshButtons(record: StandRecord, data: any)
	local offers = offersFor(record, data)
	local wanted: { [string]: boolean } = {}
	for _, offer in ipairs(offers) do
		wanted[offer.name] = true
	end

	for _, child in ipairs(record.model:GetChildren()) do
		if isPurchaseButton(child) and not wanted[child.Name] then
			child:Destroy()
		end
	end

	local buttonCfg = TycoonConfig.Interact.Button
	for _, offer in ipairs(offers) do
		local button = record.model:FindFirstChild(offer.name)
		if not (button and button:IsA("Model")) then
			button = PhysicalButton.create({
				Name = offer.name,
				CFrame = offer.cframe,
				Kind = offer.kind,
				StationId = offer.stationId,
				UpgradeId = offer.upgradeId,
			})
			button.Parent = record.model
		else
			button:PivotTo(offer.cframe * button:GetPivot().Rotation)
		end

		local color = if data.cash >= offer.cost then buttonCfg.AffordableColor else buttonCfg.UnaffordableColor
		PhysicalButton.setColor(button, color)

		local anchor = button:FindFirstChild("HologramAnchor")
		if anchor and anchor:IsA("BasePart") then
			Hologram.setPurchase(anchor, {
				Title = offer.title,
				Subtitle = offer.subtitle,
				CostText = Format.cash(offer.cost),
				AccentColor = PhysicalButton.resolveColor(color),
			})
		end
	end
end

local function buildStand(entry: PlayerStands, config: any, animate: boolean, data: any): Model
	local stand = Instance.new("Model")
	stand.Name = config.Id
	stand:SetAttribute("StationId", config.Id)

	local record: StandRecord = {
		model = stand,
		frame = entry.frame,
		origin = config.Placement,
		config = config,
	}

	local counter = Instance.new("Part")
	counter.Name = "Counter"
	counter.Anchored = true
	counter.Material = Enum.Material.Plastic
	counter.Color = config.Counter.Color
	counter.Size = config.Counter.Size
	counter.CFrame = stationPoint(record, Vector3.zero, counter.Size.Y)
	if config.Counter.Hidden == true then
		-- Invisible panel / interact anchor; the real counter is an upgrade.
		counter.Transparency = 1
		counter.CanCollide = false
		counter.CanTouch = false
	end
	studsAllAround(counter)
	counter.Parent = stand

	for _, decor in ipairs(config.Decor or {}) do
		if not isCleared(decor.ClearedBy, data) then
			spawnVisualPart(stand, decor.Name, decor, record)
		end
	end

	stand.PrimaryPart = counter
	if animate then
		markDrop(stand)
	end
	stand.Parent = entry.plot
	entry.stands[config.Id] = record
	return stand
end

-- Re-sync every station's visuals with save data (call after any purchase).
-- animate: newly added visuals drop in from the sky (purchases, not joins).
function StandService.refresh(player: Player, animate: boolean?)
	local entry = playerStands[player]
	local data = DataService.get(player)
	if not (entry and data) then
		return
	end
	for stationId, record in pairs(entry.stands) do
		syncUpgradeVisuals(record, data.stations[stationId], player.DisplayName, animate == true, data)
		applyClearedBy(record, data)
		refreshButtons(record, data)
	end
	syncPlotGrass(entry, data)
end

--[[
	Builds every unlocked station (those with a Placement) on the plot.
	Returns the stand models in tier order.
]]
function StandService.build(player: Player, plotModel: Model, data: any): { Model }
	StandService.clear(player)

	local pad = plotModel:FindFirstChild("Pad")
	if not (pad and pad:IsA("BasePart")) then
		warn("[StandService] Plot has no Pad; cannot build stands for " .. player.Name)
		return {}
	end

	local sideValue = plotModel:FindFirstChild("Side")
	local isNorth = not (sideValue and sideValue:IsA("StringValue") and sideValue.Value == "South")

	-- Station space starts just inside the plot from the street, centered on X.
	local inset = pad.Size.Z / 2 - TycoonConfig.StationStreetInset
	local entry: PlayerStands = {
		plot = plotModel,
		frame = {
			pad = pad,
			localZ = if isNorth then -inset else inset,
			isNorth = isNorth,
		},
		stands = {},
		cashConnection = nil,
	}
	playerStands[player] = entry

	local built = {}
	for _, config in ipairs(TycoonConfig.Stations) do
		local station = data.stations[config.Id]
		if config.Placement and station and station.unlocked then
			table.insert(built, buildStand(entry, config, false, data))
		end
	end
	StandService.refresh(player)

	-- Buttons flip cyan/orange as the player's cash crosses each price.
	entry.cashConnection = player:GetAttributeChangedSignal("Cash"):Connect(function()
		local current = DataService.get(player)
		if not (current and playerStands[player] == entry) then
			return
		end
		for _, record in pairs(entry.stands) do
			refreshButtons(record, current)
		end
	end)

	return built
end

-- Build one station that was just unlocked. Returns nil if already built.
function StandService.buildStation(player: Player, stationId: string): Model?
	local entry = playerStands[player]
	local config = StationMath.findStation(stationId)
	local data = DataService.get(player)
	if not (entry and config and config.Placement and data) or entry.stands[stationId] then
		return nil
	end
	local stand = buildStand(entry, config, true, data)
	StandService.refresh(player, true)
	return stand
end

function StandService.clear(player: Player)
	local entry = playerStands[player]
	if not entry then
		return
	end
	if entry.cashConnection then
		entry.cashConnection:Disconnect()
	end
	for _, record in pairs(entry.stands) do
		record.model:Destroy()
	end
	playerStands[player] = nil
end

return StandService

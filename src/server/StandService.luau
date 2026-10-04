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
	return nil
end

local function buttonCFrame(frame: PlotFrame, offset: Vector3): CFrame
	local buttonHeight = TycoonConfig.Interact.Button.BaseHeight
	return toWorld(frame, offset, buttonHeight) + Vector3.new(0, 0.02, 0)
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
	studsAllAround(part)
	part.Parent = parent

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
	end
end

-- animate = just purchased (drop in from the sky); false when rebuilding on join.
local function spawnUpgradeVisual(folder: Instance, upgrade: any, record: StandRecord, ownerName: string, animate: boolean)
	local visual = upgrade.Visual
	if visual.ModelTemplate or visual.Parts or visual.DepartingParts then
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
				spawnVisualPart(model, partVis.Name, partVis, record, ownerName)
			end
		end
		if visual.DepartingParts then
			-- Separate model so the client's CartTraffic moves only these parts
			-- (not the asphalt); they leave toward the street.
			local cart = Instance.new("Model")
			cart.Name = "Cart"
			for _, partVis in ipairs(visual.DepartingParts) do
				spawnVisualPart(cart, partVis.Name, partVis, record)
			end
			markDeparts(cart, record, visual.Depart)
			cart.Parent = model
		end
		if animate then
			markDrop(model)
		end
		model.Parent = folder
	else
		local part = spawnVisualPart(nil, upgrade.Id, visual, record, ownerName)
		if animate then
			markDrop(part)
		end
		part.Parent = folder
	end
end

-- Add visuals for newly owned upgrades, remove ones no longer owned. Existing
-- visuals stay put, so the employee only drops in once.
local function syncUpgradeVisuals(record: StandRecord, station: any, ownerName: string, animate: boolean)
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
				spawnUpgradeVisual(folder, upgrade, record, ownerName, animate)
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
			cframe = buttonCFrame(record.frame, nextConfig.Placement),
			kind = "StationUnlock",
			stationId = nextConfig.Id,
			upgradeId = nil,
			title = nextConfig.DisplayName,
			subtitle = "new station",
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

local function buildStand(entry: PlayerStands, config: any, animate: boolean): Model
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
	studsAllAround(counter)
	counter.Parent = stand

	for _, decor in ipairs(config.Decor or {}) do
		spawnVisualPart(stand, decor.Name, decor, record)
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
		syncUpgradeVisuals(record, data.stations[stationId], player.DisplayName, animate == true)
		refreshButtons(record, data)
	end
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
			table.insert(built, buildStand(entry, config, false))
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
	if not (entry and config and config.Placement) or entry.stands[stationId] then
		return nil
	end
	local stand = buildStand(entry, config, true)
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

-- Builds the station model on a player's plot and keeps its visuals
-- (owned physical upgrades, the next-upgrade floor button) in sync with save data.
-- Gameplay (sell cycle, purchases) lives in StationService.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared", 10)
assert(Shared, "Missing ReplicatedStorage.Shared")

local TycoonConfig = require(Shared:WaitForChild("TycoonConfig", 10))
local Format = require(Shared:WaitForChild("Format", 10))
local StationMath = require(Shared:WaitForChild("StationMath", 10))

local DataService = require(script.Parent.DataService)
local PhysicalButton = require(script.Parent.PhysicalButton)
local Hologram = require(script.Parent.Hologram)

local StandService = {}

type StandRecord = {
	model: Model,
	pad: BasePart,
	localZ: number,
	isNorth: boolean,
	config: any,
	cashConnection: RBXScriptConnection?,
}

local standsByPlayer: { [Player]: StandRecord } = {}

local function studsAllAround(part: BasePart)
	part.TopSurface = Enum.SurfaceType.Studs
	part.BottomSurface = Enum.SurfaceType.Studs
	part.LeftSurface = Enum.SurfaceType.Studs
	part.RightSurface = Enum.SurfaceType.Studs
	part.FrontSurface = Enum.SurfaceType.Studs
	part.BackSurface = Enum.SurfaceType.Studs
end

--[[
	Station-space → world. Offset is from the counter's footprint:
	X across, Y up from the pad top (to the part's bottom), Z away from the street.
	South plots face the other way, so X and Z mirror.
	face: "Street" aims toward the street; "Employee" aims toward the plot
	(behind the counter).
]]
local function stationPoint(record: StandRecord, offset: Vector3, height: number, face: string?): CFrame
	local sign = if record.isNorth then 1 else -1
	local localPos = Vector3.new(
		offset.X * sign,
		record.pad.Size.Y / 2 + offset.Y + height / 2,
		record.localZ + offset.Z * sign
	)
	local worldPos = record.pad.CFrame:PointToWorldSpace(localPos)
	if face == "Street" then
		return CFrame.lookAt(worldPos, worldPos + Vector3.new(0, 0, -sign))
	elseif face == "Employee" then
		return CFrame.lookAt(worldPos, worldPos + Vector3.new(0, 0, sign))
	end
	return CFrame.new(worldPos)
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

-- Floor button for a physical upgrade: behind the counter, per-upgrade offset.
local function buttonCFrame(record: StandRecord, upgrade: any): CFrame
	local buttonHeight = TycoonConfig.Interact.Button.BaseHeight
	local offset = upgrade.ButtonOffset or Vector3.new(0, 0, 12)
	return stationPoint(record, offset, buttonHeight) + Vector3.new(0, 0.02, 0)
end

local function spawnVisualPart(parent: Instance, name: string, visual: any, record: StandRecord)
	local part = Instance.new("Part")
	part.Name = name
	part.Anchored = true
	part.Material = Enum.Material.Plastic
	part.Color = visual.Color
	part.Size = visual.Size
	part.CFrame = stationPoint(record, visual.Offset, visual.Size.Y, faceFromVisual(visual))
	studsAllAround(part)
	part.Parent = parent
end

--[[
	Clone ReplicatedStorage.Cashier (Creator Store) onto the stand.
	Drops in from above for the bit, then freezes feet-on-pad.
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
	local dropHeight = visual.DropHeight or 12

	for _, descendant in ipairs(model:GetDescendants()) do
		if descendant:IsA("BasePart") then
			local isAccessory = descendant:FindFirstAncestorWhichIsA("Accessory") ~= nil
			descendant.Anchored = false
			descendant.CanCollide = not isAccessory
			descendant.CanTouch = false
			descendant.CanQuery = false
		end
	end

	model:PivotTo(floorCF * CFrame.new(0, dropHeight, 0))
	model.Parent = parent

	task.delay(1.4, function()
		if not model.Parent then
			return
		end
		model:PivotTo(seatedCF)
		for _, descendant in ipairs(model:GetDescendants()) do
			if descendant:IsA("BasePart") then
				descendant.AssemblyLinearVelocity = Vector3.zero
				descendant.AssemblyAngularVelocity = Vector3.zero
				descendant.Anchored = true
				descendant.CanCollide = false
			end
		end
	end)

	return model
end

local function rebuildUpgradeVisuals(record: StandRecord, station: any)
	local folder = record.model:FindFirstChild("Upgrades")
	if folder then
		folder:Destroy()
	end
	folder = Instance.new("Folder")
	folder.Name = "Upgrades"
	folder.Parent = record.model

	for _, upgrade in ipairs(record.config.Physical) do
		if station.owned[upgrade.Id] then
			local visual = upgrade.Visual
			if visual.ModelTemplate or visual.Parts then
				local model = Instance.new("Model")
				model.Name = upgrade.Id
				model.Parent = folder
				if visual.ModelTemplate then
					spawnTemplateModel(model, "NPC", visual, record)
				end
				if visual.Parts then
					for _, partVis in ipairs(visual.Parts) do
						spawnVisualPart(model, partVis.Name, partVis, record)
					end
				end
			else
				spawnVisualPart(folder, upgrade.Id, visual, record)
			end
		end
	end
end

-- One floor button per currently-available physical upgrade.
local function refreshButtons(record: StandRecord, data: any)
	local station = data.stations[record.config.Id]
	local available = StationMath.availablePhysical(record.config, station)
	local wanted: { [string]: any } = {}
	for _, upgrade in ipairs(available) do
		wanted[upgrade.Id] = upgrade
	end

	for _, child in ipairs(record.model:GetChildren()) do
		if child:IsA("Model") and child:GetAttribute("Kind") == "PhysicalUpgrade" then
			local upgradeId = child:GetAttribute("UpgradeId")
			if typeof(upgradeId) ~= "string" or not wanted[upgradeId] then
				child:Destroy()
			end
		end
	end

	local buttonCfg = TycoonConfig.Interact.Button
	for _, upgrade in ipairs(available) do
		local buttonName = "UpgradeButton_" .. upgrade.Id
		local button = record.model:FindFirstChild(buttonName)
		if not (button and button:IsA("Model")) then
			button = PhysicalButton.create({
				Name = buttonName,
				CFrame = buttonCFrame(record, upgrade),
				Kind = "PhysicalUpgrade",
				StationId = record.config.Id,
				UpgradeId = upgrade.Id,
			})
			button.Parent = record.model
		else
			button:PivotTo(buttonCFrame(record, upgrade) * button:GetPivot().Rotation)
		end

		local color = if data.cash >= upgrade.Cost then buttonCfg.AffordableColor else buttonCfg.UnaffordableColor
		PhysicalButton.setColor(button, color)

		local pad = button:FindFirstChild("Pad")
		if pad then
			local stale = pad:FindFirstChild("PurchaseHologram")
			if stale then
				stale:Destroy()
			end
		end

		local anchor = button:FindFirstChild("HologramAnchor")
		if anchor and anchor:IsA("BasePart") then
			Hologram.setPurchase(anchor, {
				Title = upgrade.DisplayName,
				Subtitle = StationMath.describeEffect(record.config, upgrade),
				CostText = Format.cash(upgrade.Cost),
				AccentColor = PhysicalButton.resolveColor(color),
			})
		end
	end
end

-- Re-sync every visual with save data (call after any purchase).
function StandService.refresh(player: Player)
	local record = standsByPlayer[player]
	local data = DataService.get(player)
	if not (record and data) then
		return
	end
	rebuildUpgradeVisuals(record, data.stations[record.config.Id])
	refreshButtons(record, data)
end

--[[
	Tier-1 stand: counter near the street edge, owned physical upgrades as
	models, and floor buttons for every available physical upgrade.
]]
function StandService.build(player: Player, plotModel: Model, data: any)
	StandService.clear(player)

	local pad = plotModel:FindFirstChild("Pad")
	if not (pad and pad:IsA("BasePart")) then
		warn("[StandService] Plot has no Pad; cannot build stand for " .. player.Name)
		return nil
	end

	local config = TycoonConfig.Stations[1]
	if not config then
		warn("[StandService] No Stations[1] in TycoonConfig")
		return nil
	end

	local station = data.stations[config.Id]
	if not station.unlocked then
		return nil
	end

	local sideValue = plotModel:FindFirstChild("Side")
	local isNorth = not (sideValue and sideValue:IsA("StringValue") and sideValue.Value == "South")

	local stand = Instance.new("Model")
	stand.Name = config.Id
	stand:SetAttribute("StationId", config.Id)

	-- Sit just inside the plot from the street, centered on X.
	local inset = pad.Size.Z / 2 - 10
	local record: StandRecord = {
		model = stand,
		pad = pad,
		localZ = if isNorth then -inset else inset,
		isNorth = isNorth,
		config = config,
		cashConnection = nil,
	}

	local counter = Instance.new("Part")
	counter.Name = "Counter"
	counter.Anchored = true
	counter.Material = Enum.Material.Plastic
	counter.Color = Color3.fromRGB(255, 170, 200)
	counter.Size = Vector3.new(8, 3, 4)
	counter.CFrame = stationPoint(record, Vector3.zero, counter.Size.Y)
	studsAllAround(counter)
	counter.Parent = stand

	stand.PrimaryPart = counter
	stand.Parent = plotModel

	standsByPlayer[player] = record
	StandService.refresh(player)

	-- Buttons flip cyan/orange as the player's cash crosses each price.
	record.cashConnection = player:GetAttributeChangedSignal("Cash"):Connect(function()
		local current = DataService.get(player)
		if current and standsByPlayer[player] == record then
			refreshButtons(record, current)
		end
	end)

	local stationValue = player:FindFirstChild("Station")
	if not (stationValue and stationValue:IsA("ObjectValue")) then
		if stationValue then
			stationValue:Destroy()
		end
		stationValue = Instance.new("ObjectValue")
		stationValue.Name = "Station"
		stationValue.Parent = player
	end
	(stationValue :: ObjectValue).Value = stand

	return stand
end

function StandService.clear(player: Player)
	local record = standsByPlayer[player]
	if record then
		if record.cashConnection then
			record.cashConnection:Disconnect()
		end
		record.model:Destroy()
		standsByPlayer[player] = nil
	end

	local stationValue = player:FindFirstChild("Station")
	if stationValue and stationValue:IsA("ObjectValue") then
		stationValue.Value = nil
	end
end

return StandService

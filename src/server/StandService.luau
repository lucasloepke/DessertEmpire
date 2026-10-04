-- Builds the station model on a player's plot and keeps its visuals
-- (owned physical upgrades, the next-upgrade floor button) in sync with save data.
-- Gameplay (sell cycle, purchases) lives in StationService.

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared", 10)
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
]]
local function stationPoint(record: StandRecord, offset: Vector3, height: number): CFrame
	local sign = if record.isNorth then 1 else -1
	local localPos = Vector3.new(
		offset.X * sign,
		record.pad.Size.Y / 2 + offset.Y + height / 2,
		record.localZ + offset.Z * sign
	)
	return CFrame.new(record.pad.CFrame:PointToWorldSpace(localPos))
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
			local part = Instance.new("Part")
			part.Name = upgrade.Id
			part.Anchored = true
			part.Material = Enum.Material.Plastic
			part.Color = visual.Color
			part.Size = visual.Size
			part.CFrame = stationPoint(record, visual.Offset, visual.Size.Y)
			studsAllAround(part)
			part.Parent = folder
		end
	end
end

-- Recolor / re-label the floor button for the next physical upgrade.
local function refreshButton(record: StandRecord, data: any)
	local button = record.model:FindFirstChild("UpgradeButton")
	if not (button and button:IsA("Model")) then
		return
	end

	local station = data.stations[record.config.Id]
	local nextUpgrade = StationMath.nextPhysical(record.config, station)
	if not nextUpgrade then
		button:Destroy()
		return
	end

	local buttonCfg = TycoonConfig.Interact.Button
	local color = if data.cash >= nextUpgrade.Cost then buttonCfg.AffordableColor else buttonCfg.UnaffordableColor
	PhysicalButton.setColor(button, color)

	local pad = button:FindFirstChild("Pad")
	if pad and pad:IsA("BasePart") then
		Hologram.setPurchase(pad, {
			Title = nextUpgrade.DisplayName,
			Subtitle = StationMath.describeEffect(record.config, nextUpgrade),
			CostText = Format.cash(nextUpgrade.Cost),
			AccentColor = PhysicalButton.resolveColor(color),
		})
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
	refreshButton(record, data)
end

--[[
	Tier-1 stand: counter near the street edge, a "$" icon readable from afar,
	owned physical upgrades as models, and one floor button for the next one.
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

	Hologram.createIcon(counter, "$")

	-- Off to the side toward the street, clear of the spawn point at X = 0.
	if StationMath.nextPhysical(config, station) then
		local buttonHeight = TycoonConfig.Interact.Button.BaseHeight
		local button = PhysicalButton.create({
			Name = "UpgradeButton",
			CFrame = stationPoint(record, Vector3.new(8, 0, -5), buttonHeight) + Vector3.new(0, 0.02, 0),
			Kind = "PhysicalUpgrade",
			StationId = config.Id,
		})
		button.Parent = stand
	end

	stand.PrimaryPart = counter
	stand.Parent = plotModel

	standsByPlayer[player] = record
	StandService.refresh(player)

	-- Button flips cyan/orange as the player's cash crosses the price.
	record.cashConnection = player:GetAttributeChangedSignal("Cash"):Connect(function()
		local current = DataService.get(player)
		if current and standsByPlayer[player] == record then
			refreshButton(record, current)
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

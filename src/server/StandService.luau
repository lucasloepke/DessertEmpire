-- Builds / restores station models on a player's plot.
-- Station gameplay (sell loop, automation) is not wired yet.

local StandService = {}

local standsByPlayer: { [Player]: Model } = {}

local function studsAllAround(part: BasePart)
	part.TopSurface = Enum.SurfaceType.Studs
	part.BottomSurface = Enum.SurfaceType.Studs
	part.LeftSurface = Enum.SurfaceType.Studs
	part.RightSurface = Enum.SurfaceType.Studs
	part.FrontSurface = Enum.SurfaceType.Studs
	part.BackSurface = Enum.SurfaceType.Studs
end

--[[
	Placeholder tier-1 stand: a small counter near the street edge of the plot,
	so ownership is visible before the real sell loop exists.
]]
function StandService.build(player: Player, plotModel: Model, data: any)
	StandService.clear(player)

	local pad = plotModel:FindFirstChild("Pad")
	if not (pad and pad:IsA("BasePart")) then
		warn("[StandService] Plot has no Pad; cannot build stand for " .. player.Name)
		return nil
	end

	local sideValue = plotModel:FindFirstChild("Side")
	local isNorth = not (sideValue and sideValue:IsA("StringValue") and sideValue.Value == "South")

	local stand = Instance.new("Model")
	stand.Name = "PopsicleStand"

	-- Sit just inside the plot from the street, centered on X.
	local inset = pad.Size.Z / 2 - 10
	local localZ = if isNorth then -inset else inset
	local worldPos = pad.CFrame:PointToWorldSpace(Vector3.new(0, 2, localZ))

	local counter = Instance.new("Part")
	counter.Name = "Counter"
	counter.Anchored = true
	counter.Material = Enum.Material.Plastic
	counter.Color = Color3.fromRGB(255, 170, 200)
	counter.Size = Vector3.new(8, 3, 4)
	counter.CFrame = CFrame.new(worldPos)
	studsAllAround(counter)
	counter.Parent = stand

	stand.PrimaryPart = counter
	stand.Parent = plotModel

	standsByPlayer[player] = stand

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

	-- data is accepted so the join order can pass saves through once upgrades matter.
	local _ = data

	return stand
end

function StandService.clear(player: Player)
	local stand = standsByPlayer[player]
	if stand then
		stand:Destroy()
		standsByPlayer[player] = nil
	end

	local stationValue = player:FindFirstChild("Station")
	if stationValue and stationValue:IsA("ObjectValue") then
		stationValue.Value = nil
	end
end

return StandService

-- The whole economy in one place: a station's payout and duration are its
-- base values times every multiplier the player owns. Income = payout ÷ duration.
-- Shared so offline earnings / UI can reuse the exact server math later.

local TycoonConfig = require(script.Parent.TycoonConfig)

local StationMath = {}

function StationMath.findStation(stationId: string)
	for _, config in ipairs(TycoonConfig.Stations) do
		if config.Id == stationId then
			return config
		end
	end
	return nil
end

-- station = save data for this station: { unlocked, level, owned }
function StationMath.payout(config: any, station: any): number
	local multiplier = config.Upgrade.PayoutGrowth ^ station.level
	for _, upgrade in ipairs(config.Physical) do
		if station.owned[upgrade.Id] and upgrade.PayoutMultiplier then
			multiplier *= upgrade.PayoutMultiplier
		end
	end
	-- Cash is whole dollars; round each sale.
	return math.max(1, math.floor(config.BasePayout * multiplier + 0.5))
end

function StationMath.duration(config: any, station: any): number
	local speed = 1
	for _, upgrade in ipairs(config.Physical) do
		if station.owned[upgrade.Id] and upgrade.SpeedMultiplier then
			speed *= upgrade.SpeedMultiplier
		end
	end
	return config.BaseDuration / speed
end

function StationMath.upgradeCost(config: any, level: number): number
	return math.floor(config.Upgrade.BaseCost * config.Upgrade.CostGrowth ^ level + 0.5)
end

function StationMath.isAutomated(config: any, station: any): boolean
	for _, upgrade in ipairs(config.Physical) do
		if upgrade.Automates and station.owned[upgrade.Id] then
			return true
		end
	end
	return false
end

-- Prerequisites: upgrade.Requires if set, otherwise the previous entry in Physical.
local function prerequisitesMet(config: any, upgrade: any, station: any): boolean
	local requires = upgrade.Requires
	if typeof(requires) == "table" then
		for _, id in ipairs(requires) do
			if station.owned[id] ~= true then
				return false
			end
		end
		return true
	end

	for index, entry in ipairs(config.Physical) do
		if entry.Id == upgrade.Id then
			if index == 1 then
				return true
			end
			local previous = config.Physical[index - 1]
			return station.owned[previous.Id] == true
		end
	end
	return false
end

-- Every physical upgrade that can be bought right now (may be more than one).
function StationMath.availablePhysical(config: any, station: any): { any }
	local available = {}
	for _, upgrade in ipairs(config.Physical) do
		if station.owned[upgrade.Id] ~= true and prerequisitesMet(config, upgrade, station) then
			table.insert(available, upgrade)
		end
	end
	return available
end

-- First available upgrade (keeps single-offer call sites working).
function StationMath.nextPhysical(config: any, station: any)
	return StationMath.availablePhysical(config, station)[1]
end

--[[
	The next tier this station offers to unlock, or nil. Offered once this
	station is unlocked, owns every UnlockRequires id, and the next tier is
	still locked and buildable (has a Placement).
	data = the player's whole save.
]]
function StationMath.nextUnlock(config: any, data: any)
	local nextConfig = nil
	for index, entry in ipairs(TycoonConfig.Stations) do
		if entry.Id == config.Id then
			nextConfig = TycoonConfig.Stations[index + 1]
			break
		end
	end
	if not (nextConfig and nextConfig.Placement) then
		return nil
	end

	local station = data.stations[config.Id]
	local nextStation = data.stations[nextConfig.Id]
	if not (station and station.unlocked and nextStation and not nextStation.unlocked) then
		return nil
	end
	for _, id in ipairs(nextConfig.UnlockRequires or {}) do
		if station.owned[id] ~= true then
			return nil
		end
	end
	return nextConfig
end

-- Short effect line for holograms: "x2 sales", "x2 sell speed", ...
function StationMath.describeEffect(config: any, upgrade: any): string
	if upgrade.Automates then
		return "auto sells"
	elseif upgrade.SpeedMultiplier then
		return string.format("x%g sell speed", upgrade.SpeedMultiplier)
	elseif upgrade.PayoutMultiplier then
		return string.format("x%g sales", upgrade.PayoutMultiplier)
	end
	return ""
end

return StationMath

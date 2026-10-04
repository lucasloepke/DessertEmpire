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

-- Physical upgrades are bought in order; nil once all are owned.
function StationMath.nextPhysical(config: any, station: any)
	for _, upgrade in ipairs(config.Physical) do
		if not station.owned[upgrade.Id] then
			return upgrade
		end
	end
	return nil
end

-- Short effect line for holograms: "x2 sales", "x2 sell speed", ...
function StationMath.describeEffect(config: any, upgrade: any): string
	if upgrade.Automates then
		return "automates " .. config.DisplayName
	elseif upgrade.SpeedMultiplier then
		return string.format("x%g sell speed", upgrade.SpeedMultiplier)
	elseif upgrade.PayoutMultiplier then
		return string.format("x%g sales", upgrade.PayoutMultiplier)
	end
	return ""
end

return StationMath

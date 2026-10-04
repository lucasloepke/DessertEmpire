-- Default save shape + light validation / migration helpers.

local TycoonConfig = require(script.Parent.TycoonConfig)

local PlayerData = {}

-- v2: stations[id] = { unlocked, level, owned = { [physicalUpgradeId] = true } }
-- v1 had { unlocked, toolLevel, automated }; sanitize migrates it.
PlayerData.CurrentVersion = 2

local function defaultStation(isStarter: boolean)
	return {
		unlocked = isStarter,
		level = 0,
		owned = {},
	}
end

function PlayerData.createDefault()
	local stations = {}
	for index, stationConfig in ipairs(TycoonConfig.Stations) do
		stations[stationConfig.Id] = defaultStation(index == 1)
	end

	return {
		version = PlayerData.CurrentVersion,
		cash = TycoonConfig.StartingCash,
		stations = stations,
		lastSeen = os.time(),
	}
end

local function wholeNonNegative(value: any): number?
	if typeof(value) ~= "number" or value ~= value or value < 0 then
		return nil
	end
	return math.floor(value)
end

local function sanitizeStation(stationConfig: any, raw: any, isStarter: boolean)
	local station = defaultStation(isStarter)
	if typeof(raw) ~= "table" then
		return station
	end

	if typeof(raw.unlocked) == "boolean" then
		station.unlocked = raw.unlocked
	end

	-- v1 toolLevel carries over as panel upgrade levels.
	station.level = wholeNonNegative(raw.level) or wholeNonNegative(raw.toolLevel) or 0

	-- Only keep ids that still exist in config.
	local rawOwned = if typeof(raw.owned) == "table" then raw.owned else {}
	for _, upgrade in ipairs(stationConfig.Physical) do
		if rawOwned[upgrade.Id] == true then
			station.owned[upgrade.Id] = true
		elseif upgrade.Id == "Cashier" and rawOwned.StandHelper == true then
			-- Renamed StandHelper → Cashier.
			station.owned[upgrade.Id] = true
		elseif upgrade.Automates and raw.automated == true then
			-- v1 automation → own the employee.
			station.owned[upgrade.Id] = true
		end
	end

	return station
end

-- Coerce a loaded blob into a known-good table. Never invent cash from thin air
-- when the blob is corrupt in a way that looks like a partial write — caller decides.
function PlayerData.sanitize(raw: any)
	if typeof(raw) ~= "table" then
		return nil
	end

	local data = PlayerData.createDefault()

	data.cash = wholeNonNegative(raw.cash) or data.cash

	local lastSeen = wholeNonNegative(raw.lastSeen)
	if lastSeen and lastSeen > 0 then
		data.lastSeen = lastSeen
	end

	local rawStations = if typeof(raw.stations) == "table" then raw.stations else {}
	for index, stationConfig in ipairs(TycoonConfig.Stations) do
		data.stations[stationConfig.Id] = sanitizeStation(stationConfig, rawStations[stationConfig.Id], index == 1)
	end

	-- Starter station must always be unlocked.
	data.stations[TycoonConfig.Stations[1].Id].unlocked = true

	-- An unlocked tier implies its UnlockRequires on the previous station (and
	-- UnlockRequiresOn elsewhere) are owned (saves from before a gate step like
	-- Parking Lot was added).
	for index = 2, #TycoonConfig.Stations do
		local config = TycoonConfig.Stations[index]
		if data.stations[config.Id].unlocked then
			local previous = data.stations[TycoonConfig.Stations[index - 1].Id]
			for _, id in ipairs(config.UnlockRequires or {}) do
				previous.owned[id] = true
			end
			for otherId, ids in pairs(config.UnlockRequiresOn or {}) do
				local other = data.stations[otherId]
				if other then
					for _, id in ipairs(ids) do
						other.owned[id] = true
					end
				end
			end
		end
	end

	data.version = PlayerData.CurrentVersion
	return data
end

return PlayerData

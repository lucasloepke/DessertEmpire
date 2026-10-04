-- Default save shape + light validation / migration helpers.

local TycoonConfig = require(script.Parent.TycoonConfig)

local PlayerData = {}

PlayerData.CurrentVersion = 1

function PlayerData.createDefault()
	local stations = {}
	for index, stationConfig in ipairs(TycoonConfig.Stations) do
		stations[stationConfig.Id] = {
			unlocked = index == 1,
			toolLevel = 0,
			automated = false,
		}
	end

	return {
		version = PlayerData.CurrentVersion,
		cash = TycoonConfig.StartingCash,
		stations = stations,
		lastSeen = os.time(),
	}
end

local function sanitizeStation(stationId: string, raw: any, isStarter: boolean)
	if typeof(raw) ~= "table" then
		return {
			unlocked = isStarter,
			toolLevel = 0,
			automated = false,
		}
	end

	local toolLevel = raw.toolLevel
	if typeof(toolLevel) ~= "number" or toolLevel ~= toolLevel or toolLevel < 0 then
		toolLevel = 0
	else
		toolLevel = math.floor(toolLevel)
	end

	return {
		unlocked = if typeof(raw.unlocked) == "boolean" then raw.unlocked else isStarter,
		toolLevel = toolLevel,
		automated = if typeof(raw.automated) == "boolean" then raw.automated else false,
	}
end

-- Coerce a loaded blob into a known-good table. Never invent cash from thin air
-- when the blob is corrupt in a way that looks like a partial write — caller decides.
function PlayerData.sanitize(raw: any)
	if typeof(raw) ~= "table" then
		return nil
	end

	local data = PlayerData.createDefault()

	if typeof(raw.cash) == "number" and raw.cash == raw.cash and raw.cash >= 0 then
		data.cash = math.floor(raw.cash)
	end

	if typeof(raw.lastSeen) == "number" and raw.lastSeen == raw.lastSeen and raw.lastSeen > 0 then
		data.lastSeen = math.floor(raw.lastSeen)
	end

	local rawStations = raw.stations
	if typeof(rawStations) == "table" then
		for index, stationConfig in ipairs(TycoonConfig.Stations) do
			data.stations[stationConfig.Id] = sanitizeStation(
				stationConfig.Id,
				rawStations[stationConfig.Id],
				index == 1
			)
		end
	end

	-- Starter station must always be unlocked.
	local starterId = TycoonConfig.Stations[1].Id
	data.stations[starterId].unlocked = true

	data.version = PlayerData.CurrentVersion
	return data
end

return PlayerData

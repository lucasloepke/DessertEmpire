--[[
	Pacing sim. Run in Roblox Studio (Edit mode: command bar, or the Studio
	MCP execute_luau) — it requires the live ReplicatedStorage.Shared modules,
	so it always simulates the current TycoonConfig.

	Model: a greedy player who never stops playing. Automated stations run on
	their own; the player clicks the best non-automated station every cycle.
	Whenever anything is affordable (panel levels, physical upgrades, tier
	unlocks) they buy the cheapest one. Walking time is ignored, so real
	players are slower than this.
	Returns one line per physical upgrade / unlock: time, what, cost, income.
]]

local Shared = game:GetService("ReplicatedStorage"):FindFirstChild("Shared")
assert(Shared, "Missing ReplicatedStorage.Shared")

-- Clone so each run re-requires the current sources.
local copy = Shared:Clone()
local StationMath = require(copy.StationMath)
local PlayerData = require(copy.PlayerData)
local TycoonConfig = require(copy.TycoonConfig)
copy:Destroy()

-- Sales carry over within a step, so a coarse step stays accurate.
local DT = 0.25
local MAX_TIME = 6 * 3600

local data = PlayerData.createDefault()
local progress: { [string]: number } = {}
local t = 0
local lines = {}

local function built()
	local list = {}
	for _, config in ipairs(TycoonConfig.Stations) do
		if config.Placement and data.stations[config.Id].unlocked then
			table.insert(list, config)
		end
	end
	return list
end

local function rate(config: any): number
	local station = data.stations[config.Id]
	return StationMath.payout(config, station) / StationMath.duration(config, station)
end

-- The manual station the player works: best rate among non-automated ones.
local function clicked(): any
	local best, bestRate = nil, -1
	for _, config in ipairs(built()) do
		if not StationMath.isAutomated(config, data.stations[config.Id]) and rate(config) > bestRate then
			best, bestRate = config, rate(config)
		end
	end
	return best
end

local function income(): number
	local total = 0
	local manual = clicked()
	for _, config in ipairs(built()) do
		if config == manual or StationMath.isAutomated(config, data.stations[config.Id]) then
			total += rate(config)
		end
	end
	return total
end

local function options()
	local list = {}
	for _, config in ipairs(built()) do
		local station = data.stations[config.Id]
		table.insert(list, {
			cost = StationMath.upgradeCost(config, station.level),
			buy = function()
				station.level += 1
			end,
		})
		for _, upgrade in ipairs(StationMath.availablePhysical(config, station)) do
			table.insert(list, {
				cost = upgrade.Cost,
				label = config.Id .. "/" .. upgrade.Id,
				buy = function()
					station.owned[upgrade.Id] = true
				end,
			})
		end
		local nextConfig = StationMath.nextUnlock(config, data)
		if nextConfig then
			table.insert(list, {
				cost = nextConfig.UnlockCost,
				label = "UNLOCK " .. nextConfig.Id,
				buy = function()
					data.stations[nextConfig.Id].unlocked = true
				end,
			})
		end
	end
	table.sort(list, function(a, b)
		return a.cost < b.cost
	end)
	return list
end

local function remaining(): number
	local count = 0
	for _, config in ipairs(built()) do
		count += #StationMath.availablePhysical(config, data.stations[config.Id])
		if StationMath.nextUnlock(config, data) then
			count += 1
		end
	end
	return count
end

while t < MAX_TIME and remaining() > 0 do
	local bought = true
	while bought do
		bought = false
		local cheapest = options()[1]
		if cheapest and data.cash >= cheapest.cost then
			data.cash -= cheapest.cost
			cheapest.buy()
			bought = true
			if cheapest.label then
				table.insert(lines, string.format("%6.1f min  %-34s $%-10d income $%.0f/s", t / 60, cheapest.label, cheapest.cost, income()))
			end
		end
	end

	local manual = clicked()
	for _, config in ipairs(built()) do
		local station = data.stations[config.Id]
		if config == manual or StationMath.isAutomated(config, station) then
			progress[config.Id] = (progress[config.Id] or 0) + DT
			local duration = StationMath.duration(config, station)
			while progress[config.Id] >= duration do
				progress[config.Id] -= duration
				data.cash += StationMath.payout(config, station)
			end
		end
	end
	t += DT
end

table.insert(lines, string.format("end at %.1f min, income $%.0f/s", t / 60, income()))
return table.concat(lines, "\n")

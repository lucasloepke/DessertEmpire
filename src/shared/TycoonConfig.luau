-- All tunable progression numbers live here. Systems code must not invent its own.

local TycoonConfig = {}

TycoonConfig.DataStoreName = "DessertEmpire_Player_v1"
TycoonConfig.DataStoreRetries = 3
TycoonConfig.DataStoreRetryDelay = 1

TycoonConfig.StartingCash = 0

-- Probe distance for station interactions (used once sell loop exists).
TycoonConfig.StationInteractDistance = 12

--[[
	Tier ladder (only tier 1 numbers are real so far).
	AutomationCost for a tier should sit next to UnlockCost of the next tier.
]]
TycoonConfig.Stations = {
	{
		Id = "PopsicleStand",
		DisplayName = "Popsicle Stand",
		UnlockCost = 0, -- starter station
		Duration = 3,
		BasePayout = 5,
		-- Tool upgrade lever: payout only (not duration).
		ToolUpgrade = {
			DisplayName = "Bigger Cooler",
			MaxLevel = 5,
			PayoutPerLevel = 2,
			Costs = { 25, 50, 100, 200, 400 },
		},
		-- Keep adjacent to tier 2 UnlockCost when that tier is designed.
		AutomationCost = 500,
	},
	-- Placeholder unlock cost so the automation≈next-unlock rule is visible.
	-- Not buildable yet.
	{
		Id = "CoolerCart",
		DisplayName = "Cooler Cart",
		UnlockCost = 500,
		Duration = 4,
		BasePayout = 20,
		ToolUpgrade = {
			DisplayName = "TBD",
			MaxLevel = 5,
			PayoutPerLevel = 5,
			Costs = { 100, 200, 400, 800, 1600 },
		},
		AutomationCost = 2000,
	},
}

TycoonConfig.Plots = {
	CountPerSide = 4, -- 4 north + 4 south = 8
	Width = 280, -- ~5x the original 56 starter pad
	Depth = 400, -- ~5x the original 80 starter pad
	Gap = 40,
	StreetHalfWidth = 40, -- Z extent of the street from map center
	PadHeight = 1,
	PadY = 3, -- street/plot tops sit above grass (grass top is below 0)
}

-- Creator Store road mesh/model named "Road" in Workspace is tiled along the street.
TycoonConfig.Road = {
	TemplateName = "Road",
	-- Lift slightly above the grey pavement so meshes don't z-fight.
	YOffset = 0.05,
	-- Overlap tiles a hair so seams don't show gaps.
	Overlap = 0.25,
}

return TycoonConfig

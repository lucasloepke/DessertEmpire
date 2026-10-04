-- All tunable progression numbers live here. Systems code must not invent its own.

local TycoonConfig = {}

TycoonConfig.DataStoreName = "DessertEmpire_Player_v1"
TycoonConfig.DataStoreRetries = 3
TycoonConfig.DataStoreRetryDelay = 1

TycoonConfig.StartingCash = 0

-- Station panel fades in within this range; server rejects SELL from farther.
TycoonConfig.StationInteractDistance = 20
-- Extra server-side tolerance for movement/latency on the distance check.
TycoonConfig.StationInteractSlack = 4

TycoonConfig.Remotes = {
	Folder = "Remotes",
	StationAction = "StationAction",
}

--[[
	Uniform floor button + floating hologram language for unlocks / upgrades.
	Far away: physical button (+ optional icon) only. Close: text holograms appear.
]]
TycoonConfig.Interact = {
	-- Physical button (dark base + neon pad). Same shape everywhere; color encodes role.
	Button = {
		BaseDiameter = 4.2,
		BaseHeight = 0.55,
		PadDiameter = 3.4,
		PadHeight = 0.35,
		BaseColor = Color3.fromRGB(35, 35, 40),
		-- Accent presets from reference screenshots.
		Colors = {
			Cyan = Color3.fromRGB(0, 220, 255),
			Orange = Color3.fromRGB(255, 140, 40),
			Green = Color3.fromRGB(80, 220, 80),
		},
		AffordableColor = "Cyan",
		UnaffordableColor = "Orange",
		GlowRange = 8,
		GlowBrightness = 1.2,
		-- After a purchase, the player must walk this far (horizontally) off the
		-- button before it can buy again. Stops one step buying five levels.
		RearmDistance = 4,
	},
	Hologram = {
		-- Text panels only show when you're near the button/station.
		TextMaxDistance = TycoonConfig.StationInteractDistance,
		-- Simple icon marker can read from farther (far-away screenshot).
		IconMaxDistance = 70,
		IconStudsOffset = Vector3.new(0, 6.5, 0),
		IconTag = "IconHologram",
		StudsOffset = Vector3.new(0, 4.5, 0),
		Width = 220,
	},
	-- Client-side clickable station panel (title / payout / SELL bar).
	Panel = {
		StudsOffset = Vector3.new(0, 5.5, 0),
		FadeSpeed = 8,
	},
}

--[[
	Sounds. Roblox ships no cha-ching or music as built-in rbxasset:// files,
	so these need Creator Store audio ids ("rbxassetid://123"). A wrong id
	fails silently in-engine, so the client warns when a sound fails to load.
]]
TycoonConfig.Audio = {
	-- Placeholder blip (verified built-in) until a cha-ching id is chosen.
	SaleSoundId = "rbxasset://sounds/volume_slider.ogg",
	SaleVolume = 0.6,
	SalePitchJitter = 0.05,
	SaleRollOffMaxDistance = 60,
	-- Empty = no music. Paste a Creator Store audio id here.
	MusicId = "",
	MusicVolume = 0.25,
}

--[[
	Tier ladder (only tier 1 numbers are real so far).
	Each station's last physical upgrade (the employee) automates it; its Cost
	should sit next to, and roughly equal, the next tier's UnlockCost.
]]
TycoonConfig.Stations = {
	{
		Id = "PopsicleStand",
		DisplayName = "Popsicle Stand",
		UnlockCost = 0, -- starter station
		BasePayout = 5,
		BaseDuration = 3,
		-- Panel UPGRADE under SELL: repeatable forever. Each level multiplies
		-- payout by PayoutGrowth; its price multiplies by CostGrowth.
		-- CostGrowth must stay well above PayoutGrowth or income runs away.
		Upgrade = {
			BaseCost = 10,
			CostGrowth = 1.6,
			PayoutGrowth = 1.25,
		},
		--[[
			Physical upgrades: bought in this order on one floor button. Each adds
			a visible model and applies one effect: PayoutMultiplier,
			SpeedMultiplier (divides duration), or Automates (the employee).
			Visual.Offset is from the counter: X across, Y up, Z away from street.
		]]
		Physical = {
			{
				Id = "BiggerCooler",
				DisplayName = "Bigger Cooler",
				Cost = 150,
				PayoutMultiplier = 2,
				Visual = { Size = Vector3.new(3, 2.5, 3), Offset = Vector3.new(-6, 0, 2), Color = Color3.fromRGB(90, 140, 200) },
			},
			{
				Id = "DeepFreezer",
				DisplayName = "Deep Freezer",
				Cost = 1000,
				PayoutMultiplier = 3,
				Visual = { Size = Vector3.new(4, 3.5, 3), Offset = Vector3.new(6.5, 0, 2), Color = Color3.fromRGB(225, 235, 250) },
			},
			{
				Id = "PopDispenser",
				DisplayName = "Pop Dispenser",
				Cost = 4000,
				SpeedMultiplier = 2,
				Visual = { Size = Vector3.new(2, 2.5, 1.5), Offset = Vector3.new(0, 3, 0.5), Color = Color3.fromRGB(255, 120, 170) },
			},
			{
				Id = "StandHelper",
				DisplayName = "Stand Helper",
				-- Employee = automation. Keep ≈ next tier's UnlockCost (just below).
				Cost = 10000,
				Automates = true,
				Visual = { Size = Vector3.new(2, 5, 1), Offset = Vector3.new(0, 0, 4), Color = Color3.fromRGB(245, 205, 70) },
			},
		},
	},
	-- Placeholder so the employee-cost ≈ next-unlock rule is visible. Not buildable yet.
	{
		Id = "CoolerCart",
		DisplayName = "Cooler Cart",
		UnlockCost = 10000,
		BasePayout = 100,
		BaseDuration = 4,
		Upgrade = {
			BaseCost = 200,
			CostGrowth = 1.6,
			PayoutGrowth = 1.25,
		},
		Physical = {},
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
	-- Vacant pads match the grass baseplate so taken lots read clearly from the street.
	Vacant = {
		Color = Color3.fromRGB(75, 154, 68),
		Material = Enum.Material.Grass,
	},
	Claimed = {
		Color = Color3.fromRGB(220, 200, 160),
		Material = Enum.Material.Plastic,
	},
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

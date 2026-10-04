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
	AdminAction = "AdminAction",
}

-- Temporary debug tools. Studio always allowed; live game = CreatorId + UserIds.
TycoonConfig.Admin = {
	AddCashAmount = 1000,
	UserIds = {
		-- Add your Roblox userId here for published playtests.
	},
}

--[[
	Uniform floor button + floating hologram language for unlocks / upgrades.
	Far away: physical button only. Close: text holograms appear.
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
		-- Text panels show a bit farther out than the station sell panel.
		TextMaxDistance = 28,
		-- World-space height above the button (applied as StudsOffsetWorldSpace).
		StudsOffset = Vector3.new(0, 4.5, 0),
		Width = 220,
	},
	-- Client-side clickable station panel (title / payout / SELL bar).
	Panel = {
		-- World-space height above the counter.
		StudsOffset = Vector3.new(0, 5.5, 0),
		FadeSpeed = 8,
	},
}

--[[
	Sounds. Asset ids come from Workspace.Sounds (Studio reference copies).
	A wrong id fails silently in-engine, so the client warns on load failure.
	Sale / upgrade play at the station part so they fade with distance.
]]
TycoonConfig.Audio = {
	SaleSoundId = "rbxassetid://120891770644830", -- cash-register-sound-fx
	SaleVolume = 0.6,
	SalePitchJitter = 0.05,
	SaleRollOffMaxDistance = 60,
	UpgradeSoundId = "rbxassetid://136917641181040", -- minecraft-door-open
	UpgradeVolume = 0.55,
	UpgradeRollOffMaxDistance = 60,
	-- Alternate chill track: rbxassetid://139132289200391 (Tender Static)
	MusicId = "rbxassetid://114330241320274", -- Dew
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
		BaseDuration = 1.5,
		-- Panel UPGRADE under SELL: repeatable forever. Each level multiplies
		-- payout by PayoutGrowth; its price multiplies by CostGrowth.
		-- CostGrowth must stay well above PayoutGrowth or income runs away.
		Upgrade = {
			BaseCost = 10,
			CostGrowth = 1.6,
			PayoutGrowth = 1.25,
		},
--[[
			Physical upgrades: each has a floor button when its prerequisites are met.
			Default prerequisite = previous entry in this list. Set Requires = { ids }
			to unlock earlier/in parallel (Stand Helper appears with Deep Freezer).
		]]
		Physical = {
			{
				Id = "BiggerCooler",
				DisplayName = "Bigger Cooler",
				Cost = 150,
				PayoutMultiplier = 2,
				ButtonOffset = Vector3.new(-4, 0, 12),
				Visual = { Size = Vector3.new(3, 2.5, 3), Offset = Vector3.new(-6, 0, 2), Color = Color3.fromRGB(90, 140, 200) },
			},
			{
				Id = "DeepFreezer",
				DisplayName = "Deep Freezer",
				Cost = 1000,
				PayoutMultiplier = 3,
				ButtonOffset = Vector3.new(7, 0, 12),
				Visual = { Size = Vector3.new(4, 3.5, 3), Offset = Vector3.new(6.5, 0, 2), Color = Color3.fromRGB(225, 235, 250) },
			},
			{
				Id = "PopDispenser",
				DisplayName = "Pop Dispenser",
				Cost = 4000,
				-- Halves cycle duration (sales run ×2 faster).
				SpeedMultiplier = 2,
				ButtonOffset = Vector3.new(-3, 0, 14),
				-- Was center of counter; now sits where the register used to.
				Visual = { Size = Vector3.new(2, 2.5, 1.5), Offset = Vector3.new(2.2, 3, 0.4), Color = Color3.fromRGB(255, 120, 170) },
			},
			{
				Id = "StandHelper",
				DisplayName = "Stand Helper",
				-- Employee = automation. Keep ≈ next tier's UnlockCost (just below).
				-- Available alongside Deep Freezer (after Bigger Cooler), not last in line.
				Cost = 10000,
				Automates = true,
				Requires = { "BiggerCooler" },
				ButtonOffset = Vector3.new(3, 0, 14),
				-- Cashier NPC behind the counter + register on the counter top,
				-- facing the employee (center, where the dispenser used to be).
				Visual = {
					ModelTemplate = "Cashier",
					Offset = Vector3.new(0, 0, 4.5),
					FaceStreet = true,
					Parts = {
						{
							Name = "CashRegister",
							Size = Vector3.new(1.6, 1.1, 1.2),
							Offset = Vector3.new(0, 3, 0.5),
							Color = Color3.fromRGB(55, 55, 65),
							FaceEmployee = true,
						},
						{
							Name = "RegisterDrawer",
							Size = Vector3.new(1.2, 0.35, 0.5),
							Offset = Vector3.new(0, 3, 1.1),
							Color = Color3.fromRGB(200, 170, 60),
							FaceEmployee = true,
						},
					},
				},
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
	-- Pad center Y so the pad bottom sits on the grass top (Y=0).
	PadY = 0.5,
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
	-- World Y for the road pivot (export pivot = pavement top).
	Y = 0.25,
	-- Lift slightly above the grey pavement so meshes don't z-fight.
	YOffset = 0,
	-- Overlap tiles a hair so seams don't show gaps.
	Overlap = 0.25,
}

return TycoonConfig

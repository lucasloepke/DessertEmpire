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
	AddCashAmountLarge = 50000,
	UserIds = {
		-- Add your Roblox userId here for published playtests.
	},
}

-- Hold Left Shift to sprint (client). FOV eases with speed.
TycoonConfig.Sprint = {
	NormalSpeed = 16,
	SprintSpeed = 25,
	NormalFov = 70,
	SprintFov = 82,
	SpeedTween = 0.3,
	FovInTween = 0.4,
	FovOutTween = 0.5,
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
		-- Text panels show farther out than the station sell panel (20).
		TextMaxDistance = 40,
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
	Sounds. Sale / upgrade ids come from Workspace.Sounds reference copies.
	Music shuffles every Sound under Workspace.Sounds.Music (client playlist).
	MusicId is only a fallback if that folder is empty / missing.
	A wrong id fails silently in-engine, so the client warns on load failure.
	Sale / upgrade play at the station part so they fade with distance.
]]
TycoonConfig.Audio = {
	SaleSoundId = "rbxassetid://120891770644830", -- cash-register-sound-fx
	SaleVolume = 0.4,
	SalePitchJitter = 0.05,
	SaleRollOffMaxDistance = 50,
	UpgradeSoundId = "rbxassetid://136917641181040", -- minecraft-door-open
	UpgradeVolume = 0.55,
	UpgradeRollOffMaxDistance = 60,
	-- Fallback only; live playlist = Workspace.Sounds.Music.
	MusicId = "rbxassetid://114330241320274", -- Dew
	-- Slider at 100% uses this volume; bottom of the slider = 0.
	MusicVolume = 0.25,
	-- Played when a dropped-in build lands. Looked up by name under
	-- Workspace.Sounds; the id is the fallback if the place copy is missing.
	PlaceSoundName = "Minecraft Block Place",
	PlaceSoundId = "rbxassetid://135549838877133",
	PlaceVolume = 0.7,
	PlaceRollOffMaxDistance = 60,
	-- NPC voices: every Sound under Workspace.Sounds["NPC Sounds"]; ids are the fallback.
	NpcSoundsFolder = "NPC Sounds",
	NpcSoundIds = {
		"rbxassetid://7036386692", -- Minecraft Villager Voice 1
		"rbxassetid://7036388260", -- Minecraft Villager Voice 2
		"rbxassetid://7036389387", -- Minecraft Villager Voice 3
		"rbxassetid://7036390821", -- Minecraft Villager Trend Success 1
		"rbxassetid://71492474366413", -- Minecraft Villager Sound
	},
	NpcVolume = 0.6,
	-- Louder line when a purchased NPC lands (with the block place sound).
	NpcPurchaseVolume = 1.2,
	NpcRollOffMaxDistance = 40,
	-- Each NPC says something at a random interval in this range (seconds).
	NpcChatterMinInterval = 8,
	NpcChatterMaxInterval = 20,
}

-- CollectionService tags set by the server, read by client decoration modules.
TycoonConfig.Tags = {
	DropIn = "DropIn", -- just built: fall in from the sky (DropAt / DropDelay attributes)
	Npc = "Npc", -- NPC prop: idle chatter
}

-- Client drop-in for anything bought/built. Times are seconds, heights studs.
TycoonConfig.DropIn = {
	Height = 40,
	FallTime = 0.55,
	-- Little hop after landing.
	BounceHeight = 0.8,
	BounceTime = 0.22,
	-- An NPC waits this long so it lands after its desk / register.
	NpcDelay = 0.35,
	-- Skip the animation if the client sees the tag later than this after it
	-- should have started (late joiners, streaming).
	MaxLateness = 0.5,
	-- Max seconds to wait for a dropped model's parts to replicate.
	ReplicationWait = 1,
}

-- Station space starts this many studs inside the plot from its street edge,
-- so station-space Z = -StationStreetInset is the plot edge (the sidewalk).
TycoonConfig.StationStreetInset = 10

--[[
	One placeholder cooler cart, as visual parts centered at station-space (x, y, z).
	Four wheels, one at each corner. rotated = parked: the long side runs away
	from the street, nose toward the sidewalk. Unrotated = the serving cart,
	long side along the street; its body is the station Counter, so it passes
	includeBody = false.
]]
local CART_BODY_SIZE = Vector3.new(5, 2.5, 3)
local CART_BODY_COLOR = Color3.fromRGB(120, 200, 235)

local function cartParts(prefix: string, x: number, y: number, z: number, includeBody: boolean, rotated: boolean)
	-- du = along the cart's long side, dv = across it.
	local function box(name: string, long: number, height: number, across: number, du: number, dy: number, dv: number, color: Color3)
		local size = if rotated then Vector3.new(across, height, long) else Vector3.new(long, height, across)
		local offset = if rotated then Vector3.new(x + dv, y + dy, z + du) else Vector3.new(x + du, y + dy, z + dv)
		return { Name = prefix .. name, Size = size, Offset = offset, Color = color }
	end

	local wheel = Color3.fromRGB(40, 40, 45)
	-- Umbrella pole sits toward the back (away from the street) either way.
	local poleU, poleV = if rotated then 1.2 else 0, if rotated then 0 else 0.8
	local parts = {
		box("Lid", 5.2, 0.4, 3.2, 0, 2.5, 0, Color3.fromRGB(245, 245, 250)),
		box("WheelFL", 1.4, 1.4, 0.4, -1.6, 0, -1.7, wheel),
		box("WheelFR", 1.4, 1.4, 0.4, -1.6, 0, 1.7, wheel),
		box("WheelBL", 1.4, 1.4, 0.4, 1.6, 0, -1.7, wheel),
		box("WheelBR", 1.4, 1.4, 0.4, 1.6, 0, 1.7, wheel),
		box("Pole", 0.3, 4, 0.3, poleU, 2.9, poleV, Color3.fromRGB(230, 230, 230)),
		box("Umbrella", 6, 0.4, 5, poleU, 6.9, poleV, Color3.fromRGB(255, 210, 70)),
	}
	if includeBody then
		table.insert(parts, 1, box("Body", CART_BODY_SIZE.X, CART_BODY_SIZE.Y, CART_BODY_SIZE.Z, 0, 0, 0, CART_BODY_COLOR))
	end
	return parts
end

--[[
	Cooler cart parking lot, left of the first cart. Each spot is its own
	asphalt segment (from the back of the lot all the way to the sidewalk) with
	painted lines, and arrives with that spot's cart upgrade.
	Spot centers are station-space X; parked carts sit at LOT_PARK_Z.
]]
local LOT_HEIGHT = 0.2
local LOT_SPOTS = { -8, -16, -24 }
local LOT_SPOT_WIDTH = 8
local LOT_BACK_Z = 6
local LOT_FRONT_Z = -TycoonConfig.StationStreetInset
local LOT_PARK_Z = 1.5
-- Painted lines cover the parking part only; the stretch to the sidewalk is plain asphalt.
local LOT_LINE_FRONT_Z = -2
local ASPHALT_COLOR = Color3.fromRGB(70, 70, 76)
local LINE_COLOR = Color3.fromRGB(240, 240, 240)

local function lotSegmentParts(spot: number)
	local x = LOT_SPOTS[spot]
	local half = LOT_SPOT_WIDTH / 2
	local lineLength = LOT_BACK_Z - LOT_LINE_FRONT_Z - 0.4
	local lineZ = (LOT_BACK_Z + LOT_LINE_FRONT_Z) / 2
	local function line(name: string, lineX: number)
		return { Name = name, Size = Vector3.new(0.4, 0.05, lineLength), Offset = Vector3.new(lineX, LOT_HEIGHT, lineZ), Color = LINE_COLOR }
	end

	local parts = {
		{
			Name = "Asphalt",
			Size = Vector3.new(LOT_SPOT_WIDTH, LOT_HEIGHT, LOT_BACK_Z - LOT_FRONT_Z),
			Offset = Vector3.new(x, 0, (LOT_BACK_Z + LOT_FRONT_Z) / 2),
			Color = ASPHALT_COLOR,
		},
		-- Lines sit just inside the segment so a lone segment has no overhang.
		line("LineLeft", x - half + 0.2),
	}
	if spot == 1 then
		table.insert(parts, line("LineRight", x + half - 0.2))
	end
	return parts
end

local function parkedCartVisual(prefix: string, spot: number)
	return {
		Parts = lotSegmentParts(spot),
		-- The client drives these off and back on each sale (decoration only).
		DepartingParts = cartParts(prefix, LOT_SPOTS[spot], LOT_HEIGHT, LOT_PARK_Z, true, true),
	}
end

-- Client-only decoration: carts from Visual.DepartingParts drive toward the
-- street and come back, one per sale. Never affects income.
TycoonConfig.CartTraffic = {
	-- Far enough for a parked cart's nose to reach the sidewalk.
	DriveDistance = 12,
	DriveTime = 1.4,
	HiddenTime = 0.6,
	ReturnTime = 1.4,
	-- At most this many carts away per station, so the fleet stays readable.
	MaxAway = 1,
}

--[[
	Tier ladder. Tiers 1–2 are real; later entries are placeholders.
	Each station's employee automates it; its Cost should sit next to, and
	roughly equal, the next tier's UnlockCost.

	Placement: station-space offset of the station's counter from the tier-1
	counter (X across, −X = left when facing the road; Z away from the street).
	A station without Placement is a placeholder and is never built.
	Counter: the main part (panel anchor + interact distance).
	UnlockRequires: physical upgrade ids on the *previous* station that must be
	owned before this station's unlock button appears.
]]
TycoonConfig.Stations = {
	{
		Id = "PopsicleStand",
		DisplayName = "Popsicle Stand",
		UnlockCost = 0, -- starter station
		Placement = Vector3.zero,
		Counter = { Size = Vector3.new(8, 3, 4), Color = Color3.fromRGB(255, 170, 200) },
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
			to unlock earlier/in parallel (Cashier appears with Deep Freezer).
		]]
		Physical = {
			{
				Id = "BiggerCooler",
				DisplayName = "Bigger Cooler",
				Cost = 150,
				PayoutMultiplier = 2,
				ButtonOffset = Vector3.new(-6, 0, 18),
				Visual = { Size = Vector3.new(3, 2.5, 3), Offset = Vector3.new(-6, 0, 2), Color = Color3.fromRGB(90, 140, 200) },
			},
			{
				Id = "DeepFreezer",
				DisplayName = "Deep Freezer",
				Cost = 1000,
				PayoutMultiplier = 3,
				ButtonOffset = Vector3.new(10.5, 0, 18),
				Visual = { Size = Vector3.new(4, 3.5, 3), Offset = Vector3.new(6.5, 0, 2), Color = Color3.fromRGB(225, 235, 250) },
			},
			{
				Id = "PopDispenser",
				DisplayName = "Pop Dispenser",
				Cost = 4000,
				-- Halves cycle duration (sales run ×2 faster).
				SpeedMultiplier = 2,
				ButtonOffset = Vector3.new(-4.5, 0, 21),
				-- Was center of counter; now sits where the register used to.
				Visual = { Size = Vector3.new(2, 2.5, 1.5), Offset = Vector3.new(2.2, 3, 0.4), Color = Color3.fromRGB(255, 120, 170) },
			},
			{
				Id = "Cashier",
				DisplayName = "Cashier",
				-- Employee = automation. Keep ≈ next tier's UnlockCost (just below).
				-- Available alongside Deep Freezer (after Bigger Cooler), not last in line.
				Cost = 10000,
				Automates = true,
				Requires = { "BiggerCooler" },
				ButtonOffset = Vector3.new(4.5, 0, 21),
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
			--[[
				Return sink: button appears once the early stand path is done
				(Cashier + Dispenser), but the price sits in cooler-cart mid-game
				(after Second Cart $40K, before Third Cart $200K) so players come back.
			]]
			{
				Id = "NeonSign",
				DisplayName = "Neon Sign",
				Cost = 150000,
				PayoutMultiplier = 2,
				Requires = { "Cashier", "PopDispenser" },
				ButtonOffset = Vector3.new(0, 0, 24),
				-- Mounted on the street-facing front of the counter (not above it).
				Visual = {
					Parts = {
						{
							Name = "SignBoard",
							Size = Vector3.new(7.5, 2, 0.35),
							Offset = Vector3.new(0, 0.5, -2.2),
							Color = Color3.fromRGB(40, 25, 45),
							FaceStreet = true,
						},
						{
							Name = "Neon",
							Size = Vector3.new(7.1, 1.6, 0.2),
							Offset = Vector3.new(0, 0.7, -2.4),
							Color = Color3.fromRGB(255, 80, 200),
							Material = "Neon",
							FaceStreet = true,
							Label = "{Player}'s Popsicles!",
						},
					},
				},
			},
		},
	},
	--[[
		Tier 2: one cooler cart left of the stand, plus a three-spot parking lot
		that fills with carts (fleet of four). Cart Manager is available as soon
		as the Cooler Cart exists ($40K, with Second Cart); = Ice Cream Truck UnlockCost.
		Simulated pacing (old $500K Manager after Second) is stale — re-run before trusting minutes.
	]]
	{
		Id = "CoolerCart",
		DisplayName = "Cooler Cart",
		-- = Cashier cost. Appears with the Cashier (after Bigger Cooler), so
		-- the player sees this path before buying the Cashier.
		UnlockCost = 10000,
		UnlockRequires = { "BiggerCooler" },
		Placement = Vector3.new(-26, 0, 0),
		Counter = { Size = CART_BODY_SIZE, Color = CART_BODY_COLOR },
		Decor = cartParts("Cart1", 0, 0, 0, false, false),
		BasePayout = 150,
		BaseDuration = 4,
		Upgrade = {
			BaseCost = 300,
			CostGrowth = 1.6,
			PayoutGrowth = 1.25,
		},
		-- Each fleet cart's button sits on its own parking spot (in order), and
		-- the cart parks there once bought.
		Physical = {
			{
				Id = "SecondCart",
				DisplayName = "Second Cart",
				Cost = 40000,
				PayoutMultiplier = 2,
				ButtonOffset = Vector3.new(LOT_SPOTS[1], 0, LOT_PARK_Z),
				Visual = parkedCartVisual("Cart2", 1),
			},
			{
				Id = "ThirdCart",
				DisplayName = "Third Cart",
				Cost = 200000,
				SpeedMultiplier = 2,
				ButtonOffset = Vector3.new(LOT_SPOTS[2], 0, LOT_PARK_Z),
				Visual = parkedCartVisual("Cart3", 2),
			},
			{
				Id = "FourthCart",
				DisplayName = "Fourth Cart",
				Cost = 1000000,
				PayoutMultiplier = 3,
				ButtonOffset = Vector3.new(LOT_SPOTS[3], 0, LOT_PARK_Z),
				Visual = parkedCartVisual("Cart4", 3),
			},
			{
				Id = "CartManager",
				DisplayName = "Cart Manager",
				-- Available as soon as the Cooler Cart exists (with Second Cart).
				-- Cost ≈ next tier's UnlockCost (placeholder Ice Cream Truck).
				Cost = 40000,
				Automates = true,
				Requires = {},
				-- Button where the desk will stand, right of the first cart.
				ButtonOffset = Vector3.new(6, 0, 1),
				-- Manager behind a desk; the first cart beside the desk marks him
				-- as the cart boss.
				Visual = {
					ModelTemplate = "Cashier",
					Offset = Vector3.new(6, 0, 3),
					FaceStreet = true,
					Parts = {
						{ Name = "Desk", Size = Vector3.new(4, 2.5, 2), Offset = Vector3.new(6, 0, 1), Color = Color3.fromRGB(140, 95, 60) },
						{ Name = "Clipboard", Size = Vector3.new(0.9, 0.1, 1.2), Offset = Vector3.new(5.6, 2.5, 1), Color = Color3.fromRGB(235, 225, 200) },
						{ Name = "DeskSign", Size = Vector3.new(1.6, 0.6, 0.2), Offset = Vector3.new(6.8, 2.5, 0.3), Color = Color3.fromRGB(255, 210, 70) },
					},
				},
			},
		},
	},
	-- Placeholder so the employee-cost ≈ next-unlock rule is visible. No Placement = not built.
	{
		Id = "IceCreamTruck",
		DisplayName = "Ice Cream Truck",
		UnlockCost = 40000,
		UnlockRequires = { "SecondCart" },
		-- = Cart Manager cost.
		BasePayout = 2000,
		BaseDuration = 6,
		Upgrade = {
			BaseCost = 4000,
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
	-- Spawn sits on the street/sidewalk strip (not the plot pad), facing into the plot.
	-- Inset is studs from the street edge toward the street center.
	SidewalkInset = 6,
	-- Road.Y (0.25) + half of the 1-stud SpawnLocation height.
	SpawnY = 0.75,
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

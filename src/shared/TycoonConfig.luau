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
	Lots are gate steps: cheap, no income effect, required before the next
	tier unlocks. Each is one asphalt section from the sidewalk deep into the
	plot (stand-space X left..right). The Parking Lot (bought on the stand)
	holds the cooler cart, its fleet spots and the manager desk; the Ice Cream
	Truck Lot (bought on the cooler cart) extends it further left.
	Stations standing on a lot are lifted LOT_HEIGHT (their Placement Y).
]]
local LOT_HEIGHT = 0.2
local LOT_FRONT_Z = -TycoonConfig.StationStreetInset
local LOT_BACK_Z = 30
local PARKING_LOT = { Left = -56, Right = -16 }
local TRUCK_LOT = { Left = -100, Right = -56 }
local COOLER_CART_PLACEMENT = Vector3.new(-26, LOT_HEIGHT, 0)

local ASPHALT_COLOR = Color3.fromRGB(70, 70, 76)
local LINE_COLOR = Color3.fromRGB(240, 240, 240)
local CURB_COLOR = Color3.fromRGB(205, 205, 210)
local PLANTER_COLOR = Color3.fromRGB(120, 85, 55)
local BUSH_COLOR = Color3.fromRGB(70, 160, 70)
local POLE_COLOR = Color3.fromRGB(60, 60, 66)
local LAMP_COLOR = Color3.fromRGB(255, 225, 140)
local LOT_SIGN_COLOR = Color3.fromRGB(40, 90, 200)

--[[
	One lot section. origin = the owning station's Placement (visual offsets are
	relative to it). curbX = stand-space X of the outer side curb. The curb
	stops short of the sidewalk so the lot's front stays open.
]]
local function lotSectionParts(lot: { Left: number, Right: number }, origin: Vector3, curbX: number, signLabel: string, signX: number)
	local function at(x: number, y: number, z: number): Vector3
		return Vector3.new(x, y, z) - origin
	end
	local width = lot.Right - lot.Left
	local centerX = (lot.Left + lot.Right) / 2
	local planterZ = LOT_BACK_Z - 1
	local curbFrontZ = LOT_FRONT_Z + 8

	local parts = {
		{
			Name = "Asphalt",
			Size = Vector3.new(width, LOT_HEIGHT, LOT_BACK_Z - LOT_FRONT_Z),
			Offset = at(centerX, 0, (LOT_BACK_Z + LOT_FRONT_Z) / 2),
			Color = ASPHALT_COLOR,
		},
		{ Name = "BackPlanter", Size = Vector3.new(width, 0.8, 2), Offset = at(centerX, LOT_HEIGHT, planterZ), Color = PLANTER_COLOR },
		{
			Name = "SideCurb",
			Size = Vector3.new(1, 0.6, planterZ - 1 - curbFrontZ),
			Offset = at(curbX, LOT_HEIGHT, (planterZ - 1 + curbFrontZ) / 2),
			Color = CURB_COLOR,
		},
		{ Name = "SignPole", Size = Vector3.new(0.4, 5, 0.4), Offset = at(signX, LOT_HEIGHT, LOT_FRONT_Z + 4), Color = POLE_COLOR },
		{
			Name = "SignBoard",
			Size = Vector3.new(math.max(3, #signLabel * 0.9), 2.4, 0.3),
			Offset = at(signX, LOT_HEIGHT + 5, LOT_FRONT_Z + 4),
			Color = LOT_SIGN_COLOR,
			FaceStreet = true,
			Label = signLabel,
		},
	}

	local bushes = math.floor(width / 10)
	for i = 1, bushes do
		local x = lot.Left + width * (i - 0.5) / bushes
		table.insert(parts, { Name = "Bush" .. i, Size = Vector3.new(2.6, 2, 2.6), Offset = at(x, LOT_HEIGHT + 0.8, planterZ), Color = BUSH_COLOR })
	end

	-- Two street lamps along the back, heads leaning toward the street.
	for i, fraction in ipairs({ 0.25, 0.75 }) do
		local x = lot.Left + width * fraction
		local z = LOT_BACK_Z - 3
		table.insert(parts, { Name = "Lamp" .. i .. "Pole", Size = Vector3.new(0.5, 9, 0.5), Offset = at(x, LOT_HEIGHT, z), Color = POLE_COLOR })
		table.insert(parts, { Name = "Lamp" .. i .. "Arm", Size = Vector3.new(0.4, 0.4, 2), Offset = at(x, LOT_HEIGHT + 8.6, z - 1), Color = POLE_COLOR })
		table.insert(parts, { Name = "Lamp" .. i .. "Head", Size = Vector3.new(1.6, 0.5, 1.2), Offset = at(x, LOT_HEIGHT + 8.3, z - 2), Color = LAMP_COLOR })
	end
	return parts
end

local function lotCenterButton(lot: { Left: number, Right: number }, origin: Vector3): Vector3
	return Vector3.new((lot.Left + lot.Right) / 2, 0, (LOT_BACK_Z + LOT_FRONT_Z) / 2) - origin
end

--[[
	Cooler cart fleet spots, left of the first cart, on the Parking Lot. Each
	spot's painted lines arrive with that spot's cart upgrade.
	Spot centers are cart-relative X; parked carts sit at LOT_PARK_Z.
	Cart-relative Y 0 is the asphalt top (the cart's Placement is lifted).
]]
local LOT_SPOTS = { -8, -16, -24 }
local LOT_SPOT_WIDTH = 8
local SPOT_BACK_Z = 6
local LOT_PARK_Z = 1.5
local LOT_LINE_FRONT_Z = -2

local function spotLineParts(spot: number)
	local x = LOT_SPOTS[spot]
	local half = LOT_SPOT_WIDTH / 2
	local lineLength = SPOT_BACK_Z - LOT_LINE_FRONT_Z - 0.4
	local lineZ = (SPOT_BACK_Z + LOT_LINE_FRONT_Z) / 2
	local function line(name: string, lineX: number)
		return { Name = name, Size = Vector3.new(0.4, 0.05, lineLength), Offset = Vector3.new(lineX, 0, lineZ), Color = LINE_COLOR }
	end

	local parts = { line("LineLeft", x - half + 0.2) }
	if spot == 1 then
		table.insert(parts, line("LineRight", x + half - 0.2))
	end
	return parts
end

local function parkedCartVisual(prefix: string, spot: number)
	return {
		Parts = spotLineParts(spot),
		-- The client drives these off and back on each sale (decoration only).
		DepartingParts = cartParts(prefix, LOT_SPOTS[spot], 0, LOT_PARK_Z, true, true),
	}
end

--[[
	Parlor land, right of the stand: a cleared dirt lot, roped off, with a
	sign and a lumber pile. Tier 4's building steps will go here.

	Backed against the plot's right edge (half-width = Plots.Width/2 = 140),
	inset from the street so there's a strip of grass between the road and the
	lot. Front faces the sidewalk (the player).
]]
local PARLOR_LAND = {
	Left = 22,
	Right = 132, -- ~8 studs inside the pad edge
	Front = 14, -- street edge is Z = -StationStreetInset (−10); leaves a gap
	Back = 110,
}
local DIRT_COLOR = Color3.fromRGB(150, 115, 80)
local STAKE_COLOR = Color3.fromRGB(240, 240, 235)
local ROPE_COLOR = Color3.fromRGB(255, 150, 40)
local LUMBER_COLOR = Color3.fromRGB(200, 160, 105)

local function parlorLandParts()
	local left, right = PARLOR_LAND.Left + 0.5, PARLOR_LAND.Right - 0.5
	local front, back = PARLOR_LAND.Front + 0.5, PARLOR_LAND.Back - 0.5
	local width = PARLOR_LAND.Right - PARLOR_LAND.Left
	local depth = PARLOR_LAND.Back - PARLOR_LAND.Front
	local centerX = (PARLOR_LAND.Left + PARLOR_LAND.Right) / 2
	local centerZ = (PARLOR_LAND.Front + PARLOR_LAND.Back) / 2
	local ropeY = LOT_HEIGHT + 2.4

	local parts = {
		{
			Name = "Dirt",
			Size = Vector3.new(width, LOT_HEIGHT, depth),
			Offset = Vector3.new(centerX, 0, centerZ),
			Color = DIRT_COLOR,
		},
		-- Rope on the back and sides; the street-facing front stays open toward the player.
		{ Name = "RopeBack", Size = Vector3.new(right - left, 0.2, 0.2), Offset = Vector3.new(centerX, ropeY, back), Color = ROPE_COLOR },
		{ Name = "RopeLeft", Size = Vector3.new(0.2, 0.2, back - front), Offset = Vector3.new(left, ropeY, centerZ), Color = ROPE_COLOR },
		{ Name = "RopeRight", Size = Vector3.new(0.2, 0.2, back - front), Offset = Vector3.new(right, ropeY, centerZ), Color = ROPE_COLOR },
		{ Name = "SignPost", Size = Vector3.new(0.5, 3.5, 0.5), Offset = Vector3.new(centerX, LOT_HEIGHT, front + 2.5), Color = LUMBER_COLOR },
		{
			Name = "SignBoard",
			Size = Vector3.new(18, 3.5, 0.3),
			Offset = Vector3.new(centerX, LOT_HEIGHT + 3.5, front + 2.5),
			Color = Color3.fromRGB(230, 80, 120),
			FaceStreet = true,
			Label = "{Player}'s Parlor - Coming Soon",
		},
	}
	for i, corner in ipairs({ { left, front }, { right, front }, { left, back }, { right, back } }) do
		table.insert(parts, { Name = "Stake" .. i, Size = Vector3.new(0.6, 3, 0.6), Offset = Vector3.new(corner[1], LOT_HEIGHT, corner[2]), Color = STAKE_COLOR })
	end
	for i = 1, 3 do
		table.insert(parts, {
			Name = "Lumber" .. i,
			Size = Vector3.new(7, 0.5, 1),
			Offset = Vector3.new(right - 7, LOT_HEIGHT + (i - 1) * 0.5, back - 5 + (i % 2) * 0.3),
			Color = LUMBER_COLOR,
		})
	end
	return parts
end

--[[
	Tier 3 ice cream truck, parked nose-to-street on the Ice Cream Truck Lot.
	Geometry is in truck space: origin = the truck's footprint center on the
	asphalt, X across (serving window on +X, facing the kiosk), Z along the
	truck (cab and nose at −Z, toward the street).

	Old Truck (bought on the cooler cart) is the rusty base. Every tier-3
	upgrade fixes it up by covering an old piece with a new one that fully
	contains it (paint shell over the rusty body, new tires over the flats),
	so nothing has to be removed. Pieces that must stay visible (grille,
	window hole) poke out past the paint shell.

	The station Counter is a small kiosk beside the truck, not the truck: the
	whole truck (every piece tagged TRUCK_DEPART, driver included) drives off
	toward the street on a sale and comes back, while the kiosk and its panel
	stay put.
]]
local TRUCK_ORIGIN = Vector3.new(-84, LOT_HEIGHT, 2)
local TRUCK_COUNTER = Vector3.new(9, 0, 4)
local TRUCK_PLACEMENT = TRUCK_ORIGIN + TRUCK_COUNTER

-- Every truck piece moves as one group, driven by the truck station's sales.
-- Cooldown keeps the lone truck parked most of the time.
local TRUCK_DEPART = {
	Group = "Truck",
	Station = "IceCreamTruck",
	-- Truck is 18 long: far enough to roll its nose into the street.
	Distance = 22,
	Cooldown = 15,
}

local OLD_BODY_COLOR = Color3.fromRGB(150, 140, 120)
local OLD_CAB_COLOR = Color3.fromRGB(130, 120, 105)
local RUST_COLOR = Color3.fromRGB(140, 85, 50)
local TIRE_COLOR = Color3.fromRGB(35, 35, 38)
local DARK_COLOR = Color3.fromRGB(25, 25, 30)
local TRUCK_CREAM = Color3.fromRGB(250, 245, 235)
local TRUCK_PINK = Color3.fromRGB(255, 140, 180)
local CHROME_COLOR = Color3.fromRGB(200, 200, 205)

-- A visual part placed in truck space, offset relative to its owning station.
local function truckPart(owner: Vector3, name: string, size: Vector3, at: Vector3, color: Color3, extra: { [string]: any }?)
	local part = { Name = name, Size = size, Offset = TRUCK_ORIGIN + at - owner, Color = color }
	for key, value in pairs(extra or {}) do
		part[key] = value
	end
	return part
end

local function truckPoint(owner: Vector3, at: Vector3): Vector3
	return TRUCK_ORIGIN + at - owner
end

-- Pieces that ride along when the truck drives off.
local function truckVisual(parts: { any })
	return { DepartingParts = parts, Depart = TRUCK_DEPART }
end

local WHEEL_SPOTS = {
	{ "FL", -3.6, -5 },
	{ "FR", 3.6, -5 },
	{ "BL", -3.6, 7 },
	{ "BR", 3.6, 7 },
}
-- Cab windshield pillars (corners of the open window band).
local PILLAR_SPOTS = { { -3.7, -7.7 }, { 3.7, -7.7 }, { -3.7, -2.3 }, { 3.7, -2.3 } }

local function oldTruckParts(owner: Vector3)
	local parts = {
		truckPart(owner, "Chassis", Vector3.new(7, 0.6, 18), Vector3.new(0, 1, 1), Color3.fromRGB(50, 50, 55)),
		truckPart(owner, "Body", Vector3.new(8, 8, 12), Vector3.new(0, 1.6, 4), OLD_BODY_COLOR),
		-- Cab is open above the dash so the driver shows through.
		truckPart(owner, "CabLower", Vector3.new(8, 3.4, 6), Vector3.new(0, 1.6, -5), OLD_CAB_COLOR),
		truckPart(owner, "CabRoof", Vector3.new(8, 0.6, 6), Vector3.new(0, 7.6, -5), OLD_CAB_COLOR),
		truckPart(owner, "Grille", Vector3.new(5, 1.6, 0.3), Vector3.new(0, 2.4, -8.15), DARK_COLOR),
		truckPart(owner, "SteeringWheel", Vector3.new(1.6, 1.6, 0.3), Vector3.new(-1.8, 4.6, -7), DARK_COLOR),
		truckPart(owner, "WindowHole", Vector3.new(0.5, 3.4, 5.5), Vector3.new(4, 4.4, 4), DARK_COLOR),
		truckPart(owner, "RustBody", Vector3.new(8.1, 2, 3), Vector3.new(0, 2.4, 8), RUST_COLOR),
		truckPart(owner, "RustCab", Vector3.new(8.1, 1.4, 2), Vector3.new(0, 2.2, -4), RUST_COLOR),
	}
	for i, spot in ipairs(PILLAR_SPOTS) do
		table.insert(parts, truckPart(owner, "Pillar" .. i, Vector3.new(0.6, 2.6, 0.6), Vector3.new(spot[1], 5, spot[2]), OLD_CAB_COLOR))
	end
	for _, wheel in ipairs(WHEEL_SPOTS) do
		table.insert(parts, truckPart(owner, "FlatTire" .. wheel[1], Vector3.new(1, 2, 3), Vector3.new(wheel[2], 0, wheel[3]), TIRE_COLOR))
	end
	return parts
end

local function truckPaintParts(owner: Vector3)
	local parts = {
		truckPart(owner, "BodyPaint", Vector3.new(8.2, 8.2, 12.2), Vector3.new(0, 1.5, 4), TRUCK_CREAM),
		truckPart(owner, "CabLowerPaint", Vector3.new(8.2, 3.6, 6.2), Vector3.new(0, 1.5, -5), TRUCK_PINK),
		truckPart(owner, "CabRoofPaint", Vector3.new(8.2, 0.8, 6.2), Vector3.new(0, 7.5, -5), TRUCK_PINK),
		truckPart(owner, "Stripe", Vector3.new(8.4, 1, 12.4), Vector3.new(0, 3, 4), TRUCK_PINK),
	}
	for i, spot in ipairs(PILLAR_SPOTS) do
		table.insert(parts, truckPart(owner, "PillarPaint" .. i, Vector3.new(0.8, 2.8, 0.8), Vector3.new(spot[1], 4.9, spot[2]), TRUCK_PINK))
	end
	return parts
end

local function truckTireParts(owner: Vector3)
	local parts = {}
	for _, wheel in ipairs(WHEEL_SPOTS) do
		table.insert(parts, truckPart(owner, "Tire" .. wheel[1], Vector3.new(1.3, 3.4, 3.4), Vector3.new(wheel[2], 0, wheel[3]), TIRE_COLOR))
		table.insert(parts, truckPart(owner, "Hubcap" .. wheel[1], Vector3.new(1.4, 1.6, 1.6), Vector3.new(wheel[2], 0.9, wheel[3]), CHROME_COLOR))
	end
	return parts
end

local function truckWindowParts(owner: Vector3)
	local parts = {
		truckPart(owner, "Frame", Vector3.new(0.6, 4, 6.3), Vector3.new(4, 4.1, 4), Color3.fromRGB(230, 90, 140)),
		truckPart(owner, "Opening", Vector3.new(0.1, 3.4, 5.5), Vector3.new(4.35, 4.4, 4), DARK_COLOR),
		truckPart(owner, "Awning", Vector3.new(3, 0.5, 7), Vector3.new(5.3, 8.3, 4), TRUCK_PINK),
	}
	for i, z in ipairs({ 1.5, 4, 6.5 }) do
		table.insert(parts, truckPart(owner, "AwningStripe" .. i, Vector3.new(3.02, 0.52, 1), Vector3.new(5.3, 8.29, z), TRUCK_CREAM))
	end
	return parts
end

local function truckLightParts(owner: Vector3)
	local colors = { Color3.fromRGB(255, 90, 90), Color3.fromRGB(255, 220, 80), Color3.fromRGB(90, 200, 255), Color3.fromRGB(120, 230, 120) }
	local parts = {}
	for side, x in ipairs({ -4.3, 4.3 }) do
		table.insert(parts, truckPart(owner, "Wire" .. side, Vector3.new(0.1, 0.1, 12.4), Vector3.new(x, 9.6, 4), DARK_COLOR))
		for i = 1, 10 do
			local z = -2 + (i - 0.5) * 12 / 10
			table.insert(parts, truckPart(owner, "Bulb" .. side .. "_" .. i, Vector3.new(0.4, 0.5, 0.4), Vector3.new(x, 9.1, z), colors[(i - 1) % #colors + 1]))
		end
	end
	return parts
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
	Tier ladder. Tiers 1–3 are real; later entries are placeholders.
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
			-- Gate step for tier 2: no income effect; the Cooler Cart unlock
			-- requires it. Cheap so it's a quick stop, not a wall.
			{
				Id = "ParkingLot",
				DisplayName = "Parking Lot",
				Cost = 2500,
				Requires = { "BiggerCooler" },
				-- Lot center; well away from the Cooler Cart unlock button that
				-- replaces it, so stepping off this one can't buy the cart too.
				ButtonOffset = lotCenterButton(PARKING_LOT, Vector3.zero),
				Visual = { Parts = lotSectionParts(PARKING_LOT, Vector3.zero, PARKING_LOT.Right - 0.5, "PARKING", PARKING_LOT.Right - 2) },
			},
			-- Ground for tier 4 (parlor), right of the stand. No income effect;
			-- the parlor's building steps will require it once tier 4 exists.
			{
				Id = "ParlorLand",
				DisplayName = "Parlor Land",
				Subtitle = "parlor coming soon",
				Cost = 25000,
				Requires = { "Cashier" },
				ButtonOffset = Vector3.new(
					(PARLOR_LAND.Left + PARLOR_LAND.Right) / 2,
					0,
					(PARLOR_LAND.Front + PARLOR_LAND.Back) / 2
				),
				Visual = { Parts = parlorLandParts() },
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
		-- Parking Lot needs Bigger Cooler, so the cart path still shows before the Cashier.
		UnlockRequires = { "ParkingLot" },
		-- Stands on the Parking Lot asphalt.
		Placement = COOLER_CART_PLACEMENT,
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
			-- Gate step for tier 3: extends the Parking Lot left for the trucks.
			-- No income effect; the Ice Cream Truck unlock requires it.
			{
				Id = "TruckLot",
				DisplayName = "Ice Cream Truck Lot",
				Subtitle = "trucks coming soon",
				Cost = 10000,
				-- After Second Cart so tier 2 gets played before the truck path opens.
				Requires = { "SecondCart" },
				ButtonOffset = lotCenterButton(TRUCK_LOT, COOLER_CART_PLACEMENT),
				Visual = { Parts = lotSectionParts(TRUCK_LOT, COOLER_CART_PLACEMENT, TRUCK_LOT.Left + 0.5, "TRUCKS", TRUCK_LOT.Left + 3) },
			},
			-- Second gate step for tier 3: a rusty, flat-tired truck on the new
			-- lot. No income effect; the Ice Cream Truck unlock requires it.
			{
				Id = "OldTruck",
				DisplayName = "Old Truck",
				Subtitle = "fixer-upper",
				Cost = 15000,
				Requires = { "TruckLot" },
				ButtonOffset = truckPoint(COOLER_CART_PLACEMENT, Vector3.zero),
				-- Owned by the cooler cart, but drives off on the truck's sales (TRUCK_DEPART).
				Visual = truckVisual(oldTruckParts(COOLER_CART_PLACEMENT)),
			},
		},
	},
	--[[
		Tier 3: the Old Truck, fixed up one piece at a time. Unlocking it opens
		a little order kiosk beside the truck (kiosk = Counter, umbrella,
		cardboard OPEN sign) so it sells manually right away; each upgrade
		replaces a shabby truck piece with a proper ice cream truck part.
		Driver automates (partway) and rides in the cab.
	]]
	{
		Id = "IceCreamTruck",
		DisplayName = "Ice Cream Truck",
		-- = Cart Manager cost.
		UnlockCost = 40000,
		UnlockRequires = { "OldTruck" },
		Placement = TRUCK_PLACEMENT,
		Counter = { Size = Vector3.new(3, 3, 4), Color = TRUCK_PINK },
		Decor = {
			truckPart(TRUCK_PLACEMENT, "CounterTop", Vector3.new(3.4, 0.3, 4.4), Vector3.new(9, 3, 4), TRUCK_CREAM),
			truckPart(TRUCK_PLACEMENT, "UmbrellaPole", Vector3.new(0.3, 5.5, 0.3), Vector3.new(9, 3.3, 5), TRUCK_CREAM),
			truckPart(TRUCK_PLACEMENT, "Umbrella", Vector3.new(5, 0.4, 5), Vector3.new(9, 8.8, 5), TRUCK_PINK),
			truckPart(TRUCK_PLACEMENT, "UmbrellaTop", Vector3.new(2, 0.4, 2), Vector3.new(9, 9.2, 5), TRUCK_CREAM),
			truckPart(TRUCK_PLACEMENT, "Freezer", Vector3.new(2, 2, 2), Vector3.new(9, 0, 7.5), Color3.fromRGB(225, 235, 250)),
			truckPart(TRUCK_PLACEMENT, "OpenSign", Vector3.new(2, 1, 0.1), Vector3.new(9, 1.6, 1.9), Color3.fromRGB(190, 150, 100), {
				FaceStreet = true,
				Label = "OPEN",
			}),
		},
		BasePayout = 2000,
		BaseDuration = 6,
		Upgrade = {
			BaseCost = 4000,
			CostGrowth = 1.6,
			PayoutGrowth = 1.25,
		},
		-- Buttons stand on the asphalt next to where each piece will appear.
		Physical = {
			{
				Id = "FreshPaint",
				DisplayName = "Fresh Paint",
				Cost = 60000,
				PayoutMultiplier = 1.5,
				ButtonOffset = truckPoint(TRUCK_PLACEMENT, Vector3.new(-7, 0, 6)),
				Visual = truckVisual(truckPaintParts(TRUCK_PLACEMENT)),
			},
			{
				Id = "NewTires",
				DisplayName = "New Tires",
				Cost = 120000,
				PayoutMultiplier = 1.5,
				ButtonOffset = truckPoint(TRUCK_PLACEMENT, Vector3.new(-7, 0, -6)),
				Visual = truckVisual(truckTireParts(TRUCK_PLACEMENT)),
			},
			{
				Id = "Driver",
				DisplayName = "Driver",
				-- Employee = automation. Cost ≈ next tier's UnlockCost (placeholder Parlor).
				-- Available right after Fresh Paint, alongside New Tires.
				Cost = 200000,
				Automates = true,
				Requires = { "FreshPaint" },
				ButtonOffset = truckPoint(TRUCK_PLACEMENT, Vector3.new(-7, 0, 0)),
				-- Stands in the cab behind the wheel (feet on the cab floor), so
				-- he shows through the open window band and rides along.
				Visual = {
					ModelTemplate = "Cashier",
					Offset = truckPoint(TRUCK_PLACEMENT, Vector3.new(-1.8, 1.6, -5.2)),
					FaceStreet = true,
					Depart = TRUCK_DEPART,
				},
			},
			{
				Id = "ServingWindow",
				DisplayName = "Serving Window",
				Cost = 400000,
				SpeedMultiplier = 2,
				Requires = { "NewTires" },
				ButtonOffset = truckPoint(TRUCK_PLACEMENT, Vector3.new(6.5, 0, -1)),
				Visual = truckVisual(truckWindowParts(TRUCK_PLACEMENT)),
			},
			{
				Id = "Speakers",
				DisplayName = "Jingle Speakers",
				Cost = 800000,
				PayoutMultiplier = 1.5,
				ButtonOffset = truckPoint(TRUCK_PLACEMENT, Vector3.new(0, 0, -12)),
				-- Roof front, horns pointing at the street.
				Visual = truckVisual({
					truckPart(TRUCK_PLACEMENT, "RoofRack", Vector3.new(5, 0.4, 0.5), Vector3.new(0, 9.7, -1), DARK_COLOR),
					truckPart(TRUCK_PLACEMENT, "SpeakerL", Vector3.new(1.6, 1.6, 2), Vector3.new(-1.8, 10.1, -1), CHROME_COLOR),
					truckPart(TRUCK_PLACEMENT, "SpeakerR", Vector3.new(1.6, 1.6, 2), Vector3.new(1.8, 10.1, -1), CHROME_COLOR),
				}),
			},
			{
				Id = "MenuBoard",
				DisplayName = "Menu Board",
				Cost = 1500000,
				PayoutMultiplier = 1.5,
				ButtonOffset = truckPoint(TRUCK_PLACEMENT, Vector3.new(12, 0, 1)),
				-- On the kiosk front (stays when the truck leaves), over the cardboard OPEN sign.
				Visual = {
					Parts = {
						truckPart(TRUCK_PLACEMENT, "Menu", Vector3.new(2.6, 2, 0.3), Vector3.new(9, 0.8, 1.8), Color3.fromRGB(40, 30, 45), {
							FaceStreet = true,
							Label = "MENU",
						}),
					},
				},
			},
			{
				Id = "GiantCone",
				DisplayName = "Giant Cone",
				Cost = 3000000,
				PayoutMultiplier = 2,
				ButtonOffset = truckPoint(TRUCK_PLACEMENT, Vector3.new(0, 0, 13)),
				Visual = truckVisual({
					truckPart(TRUCK_PLACEMENT, "Cone", Vector3.new(2, 3.2, 2), Vector3.new(0, 9.7, 7), Color3.fromRGB(215, 165, 95)),
					truckPart(TRUCK_PLACEMENT, "Scoop", Vector3.new(3.2, 2.4, 3.2), Vector3.new(0, 12.9, 7), TRUCK_PINK),
					truckPart(TRUCK_PLACEMENT, "TopScoop", Vector3.new(2.6, 1.8, 2.6), Vector3.new(0, 15.3, 7), Color3.fromRGB(160, 235, 200)),
					truckPart(TRUCK_PLACEMENT, "Cherry", Vector3.new(0.8, 0.8, 0.8), Vector3.new(0, 17.1, 7), Color3.fromRGB(220, 30, 50)),
				}),
			},
			{
				Id = "StringLights",
				DisplayName = "String Lights",
				Cost = 6000000,
				PayoutMultiplier = 2,
				ButtonOffset = truckPoint(TRUCK_PLACEMENT, Vector3.new(-7, 0, 12)),
				Visual = truckVisual(truckLightParts(TRUCK_PLACEMENT)),
			},
		},
	},
	-- Placeholder so the employee-cost ≈ next-unlock rule is visible. No Placement = not built.
	-- Will build on the stand's Parlor Land.
	{
		Id = "Parlor",
		DisplayName = "Parlor",
		-- = Driver cost.
		UnlockCost = 200000,
		UnlockRequires = { "Driver" },
		BasePayout = 20000,
		BaseDuration = 10,
		Upgrade = {
			BaseCost = 40000,
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

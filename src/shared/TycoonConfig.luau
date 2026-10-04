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
		-- Pop on sale / panel upgrade (scale + brief hop).
		ThrobScale = 1.14,
		ThrobUp = 0.07,
		ThrobDown = 0.16,
		ThrobHop = 0.55,
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

--[[
	3D grass tufts (ReplicatedStorage.Grass / Workspace.Grass mesh) scattered on
	open lawns. Regions / holes are stand-space (tier-1 counter origin).
]]
TycoonConfig.PlotGrass = {
	TemplateName = "Grass",
	Spacing = 2.6,
	Jitter = 0.7,
	ScaleMin = 0.85,
	ScaleMax = 1.2,
	-- Feet sit on the YardGrass top (pad + YARD_HEIGHT).
	Y = 0.3,
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
	-- Parlor walls / interior are large; 1s was enough for carts and the truck.
	ReplicationWait = 2.5,
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
	height = asphalt thickness (default LOT_HEIGHT); thicker when the lot has
	to cover ground that's already there.
]]
local function lotSectionParts(lot: { Left: number, Right: number }, origin: Vector3, curbX: number, signLabel: string?, signX: number?, height: number?)
	local function at(x: number, y: number, z: number): Vector3
		return Vector3.new(x, y, z) - origin
	end
	local top = height or LOT_HEIGHT
	local width = lot.Right - lot.Left
	local centerX = (lot.Left + lot.Right) / 2
	local planterZ = LOT_BACK_Z - 1
	local curbFrontZ = LOT_FRONT_Z + 8

	local parts = {
		{
			Name = "Asphalt",
			Size = Vector3.new(width, top, LOT_BACK_Z - LOT_FRONT_Z),
			Offset = at(centerX, 0, (LOT_BACK_Z + LOT_FRONT_Z) / 2),
			Color = ASPHALT_COLOR,
		},
		{ Name = "BackPlanter", Size = Vector3.new(width, 0.8, 2), Offset = at(centerX, top, planterZ), Color = PLANTER_COLOR },
		{
			Name = "SideCurb",
			Size = Vector3.new(1, 0.6, planterZ - 1 - curbFrontZ),
			Offset = at(curbX, top, (planterZ - 1 + curbFrontZ) / 2),
			Color = CURB_COLOR,
		},
	}
	if signLabel and signLabel ~= "" and signX then
		table.insert(parts, { Name = "SignPole", Size = Vector3.new(0.4, 5, 0.4), Offset = at(signX, top, LOT_FRONT_Z + 4), Color = POLE_COLOR })
		table.insert(parts, {
			Name = "SignBoard",
			Size = Vector3.new(math.max(3, #signLabel * 0.9), 2.4, 0.3),
			Offset = at(signX, top + 5, LOT_FRONT_Z + 4),
			Color = LOT_SIGN_COLOR,
			FaceStreet = true,
			Label = signLabel,
		})
	end

	local bushes = math.floor(width / 10)
	for i = 1, bushes do
		local x = lot.Left + width * (i - 0.5) / bushes
		table.insert(parts, { Name = "Bush" .. i, Size = Vector3.new(2.6, 2, 2.6), Offset = at(x, top + 0.8, planterZ), Color = BUSH_COLOR })
	end

	-- Two street lamps along the back, heads leaning toward the street.
	for i, fraction in ipairs({ 0.25, 0.75 }) do
		local x = lot.Left + width * fraction
		local z = LOT_BACK_Z - 3
		table.insert(parts, { Name = "Lamp" .. i .. "Pole", Size = Vector3.new(0.5, 9, 0.5), Offset = at(x, top, z), Color = POLE_COLOR })
		table.insert(parts, { Name = "Lamp" .. i .. "Arm", Size = Vector3.new(0.4, 0.4, 2), Offset = at(x, top + 8.6, z - 1), Color = POLE_COLOR })
		table.insert(parts, { Name = "Lamp" .. i .. "Head", Size = Vector3.new(1.6, 0.5, 1.2), Offset = at(x, top + 8.3, z - 2), Color = LAMP_COLOR })
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
	sign and a lumber pile. The tier 4 parlor is built on it.

	Runs from the sidewalk (Z = −StationStreetInset) back into the plot,
	backed against the pad's right edge. Front faces the street; the door
	later faces the plot center.

	Site clutter goes away as the parlor gets built (ClearedBy: a station id =
	once it's unlocked, "Station/Upgrade" = once that's owned): the ropes and
	stakes when the foundation lands, the lumber with the walls, the sign at
	the grand opening. The sign stands on the future plaza, clear of the
	parlor's parking lot.
]]
local PARLOR_LAND = {
	Left = 22,
	Right = 132, -- ~8 studs inside the pad edge
	-- Street edge / sidewalk (Z = −StationStreetInset). Yard grass reaches here.
	Front = LOT_FRONT_Z,
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
	local signX = 41

	local parts = {
		{
			Name = "Dirt",
			Size = Vector3.new(width, LOT_HEIGHT, depth),
			Offset = Vector3.new(centerX, 0, centerZ),
			Color = DIRT_COLOR,
			ClearedBy = "Parlor",
		},
		-- Rope on the back and sides; the street-facing front stays open toward the player.
		{ Name = "RopeBack", Size = Vector3.new(right - left, 0.2, 0.2), Offset = Vector3.new(centerX, ropeY, back), Color = ROPE_COLOR, ClearedBy = "Parlor" },
		{ Name = "RopeLeft", Size = Vector3.new(0.2, 0.2, back - front), Offset = Vector3.new(left, ropeY, centerZ), Color = ROPE_COLOR, ClearedBy = "Parlor" },
		{ Name = "RopeRight", Size = Vector3.new(0.2, 0.2, back - front), Offset = Vector3.new(right, ropeY, centerZ), Color = ROPE_COLOR, ClearedBy = "Parlor" },
		{ Name = "SignPost", Size = Vector3.new(0.5, 3.5, 0.5), Offset = Vector3.new(signX, LOT_HEIGHT, front + 2.5), Color = LUMBER_COLOR, ClearedBy = "Parlor/GrandOpening" },
		{
			Name = "SignBoard",
			Size = Vector3.new(18, 3.5, 0.3),
			Offset = Vector3.new(signX, LOT_HEIGHT + 3.5, front + 2.5),
			Color = Color3.fromRGB(230, 80, 120),
			FaceStreet = true,
			Label = "{Player}'s Parlor - Coming Soon",
			ClearedBy = "Parlor/GrandOpening",
		},
	}
	for i, corner in ipairs({ { left, front }, { right, front }, { left, back }, { right, back } }) do
		table.insert(parts, {
			Name = "Stake" .. i,
			Size = Vector3.new(0.6, 3, 0.6),
			Offset = Vector3.new(corner[1], LOT_HEIGHT, corner[2]),
			Color = STAKE_COLOR,
			ClearedBy = "Parlor",
		})
	end
	for i = 1, 3 do
		table.insert(parts, {
			Name = "Lumber" .. i,
			Size = Vector3.new(7, 0.5, 1),
			Offset = Vector3.new(right - 7, LOT_HEIGHT + (i - 1) * 0.5, back - 5 + (i % 2) * 0.3),
			Color = LUMBER_COLOR,
			ClearedBy = "Parlor/Walls",
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

--[[
	Tier 4 ice cream parlor, built on the stand's Parlor Land. The unlock lays
	the foundation; Walls → Roof → Interior → Grand Opening (with Customer
	Parking alongside) put the building up. Those construction steps have no
	income effect and the parlor can't sell until Grand Opening (OpensWith):
	building it is an investment. After that it's the usual spend flow.

	Geometry is in stand space (X across, Z away from the street, Y = bottom
	above the pad top), converted to offsets from the counter by parlorPart.
	The front door is in the left (−X) wall, facing the stand and the plot
	center; customer parking sits between the building and the street; the
	plaza in front of the door is open to the sidewalk.

	FaceLeft / FaceRight parts are turned a quarter, so their Size is in the
	part's own frame: X runs along station Z.

	The building is tall (24-stud walls, 14-wide door) so a third-person
	camera has room inside. Windows come in two rows so the loft floor
	(12–13 up) hides in the solid band between them.
]]
local PARLOR_FLOOR = 1.2 -- foundation top
-- Outer faces of the walls.
local PARLOR = { Left = 56, Right = 124, Front = 36, Back = 100 }
local PARLOR_WALL = 1
local PARLOR_WALL_HEIGHT = 24
local PARLOR_CENTER_X = (PARLOR.Left + PARLOR.Right) / 2
local PARLOR_CENTER_Z = (PARLOR.Front + PARLOR.Back) / 2
local PARLOR_ROOF_TOP = PARLOR_FLOOR + PARLOR_WALL_HEIGHT + 1
-- The service counter: the station's Counter anchor (panel + interact range).
local PARLOR_PLACEMENT = Vector3.new(106, PARLOR_FLOOR, PARLOR_CENTER_Z)
local PARLOR_COUNTER_SIZE = Vector3.new(4, 3.5, 22)

local PARLOR_DOOR = { From = 61, To = 75, Holes = { { 0, 16 } } }
local PARLOR_WINDOW_ROWS = { { 4, 10 }, { 16, 22 } }

local function parlorWindow(center: number)
	return { From = center - 5, To = center + 5, Holes = PARLOR_WINDOW_ROWS, Glass = true }
end

-- Along "X" = the wall runs along X at Z = Fixed; "Z" = along Z at X = Fixed.
local PARLOR_WALLS = {
	{ Prefix = "Front", Along = "X", Fixed = PARLOR.Front + 0.5, From = PARLOR.Left, To = PARLOR.Right, Openings = { parlorWindow(72), parlorWindow(90), parlorWindow(108) } },
	{ Prefix = "Back", Along = "X", Fixed = PARLOR.Back - 0.5, From = PARLOR.Left, To = PARLOR.Right, Openings = { parlorWindow(72), parlorWindow(90), parlorWindow(108) } },
	{ Prefix = "Entrance", Along = "Z", Fixed = PARLOR.Left + 0.5, From = PARLOR.Front + 1, To = PARLOR.Back - 1, Openings = { parlorWindow(49), PARLOR_DOOR, parlorWindow(87) } },
	-- Solid: the back bar and menu board stand against it.
	{ Prefix = "Kitchen", Along = "Z", Fixed = PARLOR.Right - 0.5, From = PARLOR.Front + 1, To = PARLOR.Back - 1, Openings = {} },
}

-- Customer parking, nose-to-street between the building and the sidewalk.
local PARLOR_LOT = { Left = 60, Right = 132 }
-- Thicker than the Parlor Land dirt so the asphalt fully contains it.
local PARLOR_LOT_HEIGHT = 0.3
-- Green lawn slab on the pad; path / patio / parking sit on top of this.
local YARD_HEIGHT = 0.3
local PARLOR_SPOT_WIDTH = 8
local PARLOR_PARK_Z = 18.5
-- Spots (1 = leftmost) that get a car at the grand opening; the rest stay empty.
local PARLOR_CAR_SPOTS = { 1, 2, 4, 5, 7, 9 }
-- Far enough that a parked car rolls out past the sidewalk before fading.
local PARLOR_CAR_DEPART = { Distance = 34, MaxAway = 2 }

-- White shell, red accents, pastel pink / blue highlights.
local PARLOR_WALL_COLOR = Color3.fromRGB(250, 250, 252)
local PARLOR_RED = Color3.fromRGB(220, 55, 70)
local PARLOR_PINK = Color3.fromRGB(255, 185, 210)
local PARLOR_BLUE = Color3.fromRGB(170, 215, 245)
local PARLOR_CREAM = Color3.fromRGB(255, 252, 248)
local PARLOR_CHOCOLATE = Color3.fromRGB(120, 75, 50)
local CONCRETE_COLOR = Color3.fromRGB(210, 210, 215)
local GLASS_COLOR = Color3.fromRGB(185, 225, 245)
local WOOD_COLOR = Color3.fromRGB(170, 120, 80)
local GRASS_COLOR = Color3.fromRGB(90, 170, 80)
local CEILING_LIGHT = {
	Brightness = 0.7,
	Range = 24,
	Color = Color3.fromRGB(255, 248, 235),
}
local SCOOP_COLORS = {
	Color3.fromRGB(255, 170, 200),
	Color3.fromRGB(160, 215, 245),
	Color3.fromRGB(250, 235, 170),
	Color3.fromRGB(140, 90, 60),
	Color3.fromRGB(255, 185, 210),
	Color3.fromRGB(190, 225, 250),
}

-- A visual part whose bottom-center sits at stand-space `at`.
local function parlorPart(name: string, size: Vector3, at: Vector3, color: Color3, extra: { [string]: any }?)
	local part = { Name = name, Size = size, Offset = at - PARLOR_PLACEMENT, Color = color }
	for key, value in pairs(extra or {}) do
		part[key] = value
	end
	return part
end

local function parlorPoint(at: Vector3): Vector3
	return at - PARLOR_PLACEMENT
end

local function appendAll(list: { any }, more: { any })
	for _, item in ipairs(more) do
		table.insert(list, item)
	end
	return list
end

-- Unlock: a bare slab with a door step, grass over leftover dirt, cones and a construction sign.
local function parlorFoundationParts()
	local doorZ = (PARLOR_DOOR.From + PARLOR_DOOR.To) / 2
	local cone = Color3.fromRGB(255, 130, 40)
	local land = PARLOR_LAND
	local parts = {
		-- Grass lawn over the parlor lot (on the pad). Path / patio / parking sit on top.
		parlorPart(
			"YardGrass",
			Vector3.new(land.Right - land.Left, YARD_HEIGHT, land.Back - land.Front),
			Vector3.new((land.Left + land.Right) / 2, 0, (land.Front + land.Back) / 2),
			GRASS_COLOR,
			{ Material = "Grass" }
		),
		parlorPart(
			"Foundation",
			Vector3.new(PARLOR.Right - PARLOR.Left + 4, PARLOR_FLOOR, PARLOR.Back - PARLOR.Front + 4),
			Vector3.new(PARLOR_CENTER_X, 0, PARLOR_CENTER_Z),
			CONCRETE_COLOR
		),
		parlorPart("DoorStep", Vector3.new(2, PARLOR_FLOOR / 2, PARLOR_DOOR.To - PARLOR_DOOR.From), Vector3.new(PARLOR.Left - 3, 0, doorZ), CONCRETE_COLOR),
		parlorPart("SitePost", Vector3.new(0.4, 4, 0.4), Vector3.new(50, LOT_HEIGHT, 56), WOOD_COLOR, { ClearedBy = "Parlor/GrandOpening" }),
		parlorPart("SiteSign", Vector3.new(9, 2.5, 0.3), Vector3.new(50, LOT_HEIGHT + 4, 56), Color3.fromRGB(255, 200, 40), {
			FaceLeft = true,
			Label = "UNDER CONSTRUCTION",
			ClearedBy = "Parlor/GrandOpening",
		}),
	}
	for i, corner in ipairs({ { PARLOR.Left - 1, PARLOR.Front - 1 }, { PARLOR.Right + 1, PARLOR.Front - 1 }, { PARLOR.Left - 1, PARLOR.Back + 1 }, { PARLOR.Right + 1, PARLOR.Back + 1 } }) do
		table.insert(parts, parlorPart("Cone" .. i, Vector3.new(1, 1.6, 1), Vector3.new(corner[1], PARLOR_FLOOR, corner[2]), cone, { ClearedBy = "Parlor/GrandOpening" }))
	end
	return parts
end

-- One wall: full-height piers between openings, solid fill above / below / between each opening's holes.
local function parlorWallParts(wall: any)
	local parts = {}
	local function piece(name: string, a: number, b: number, bottom: number, top: number)
		if b - a <= 0 or top - bottom <= 0 then
			return
		end
		local mid = (a + b) / 2
		local size = if wall.Along == "X" then Vector3.new(b - a, top - bottom, PARLOR_WALL) else Vector3.new(PARLOR_WALL, top - bottom, b - a)
		local at = if wall.Along == "X" then Vector3.new(mid, PARLOR_FLOOR + bottom, wall.Fixed) else Vector3.new(wall.Fixed, PARLOR_FLOOR + bottom, mid)
		table.insert(parts, parlorPart(wall.Prefix .. name, size, at, PARLOR_WALL_COLOR))
	end

	local cursor = wall.From
	for i, opening in ipairs(wall.Openings) do
		piece("Pier" .. i, cursor, opening.From, 0, PARLOR_WALL_HEIGHT)
		local y = 0
		for j, hole in ipairs(opening.Holes) do
			piece("Fill" .. i .. "_" .. j, opening.From, opening.To, y, hole[1])
			y = hole[2]
		end
		piece("Fill" .. i .. "_Top", opening.From, opening.To, y, PARLOR_WALL_HEIGHT)
		cursor = opening.To
	end
	piece("Pier" .. (#wall.Openings + 1), cursor, wall.To, 0, PARLOR_WALL_HEIGHT)

	-- Red cornice band along the top, a little proud of the wall on both faces.
	local length = wall.To - wall.From
	local trimSize = if wall.Along == "X" then Vector3.new(length + 0.4, 1.5, PARLOR_WALL + 0.4) else Vector3.new(PARLOR_WALL + 0.4, 1.5, length)
	local trimAt = if wall.Along == "X"
		then Vector3.new((wall.From + wall.To) / 2, PARLOR_FLOOR + PARLOR_WALL_HEIGHT - 1.5, wall.Fixed)
		else Vector3.new(wall.Fixed, PARLOR_FLOOR + PARLOR_WALL_HEIGHT - 1.5, (wall.From + wall.To) / 2)
	table.insert(parts, parlorPart(wall.Prefix .. "Trim", trimSize, trimAt, PARLOR_RED))
	return parts
end

local function parlorAllWallParts()
	local parts = {}
	for _, wall in ipairs(PARLOR_WALLS) do
		appendAll(parts, parlorWallParts(wall))
	end
	return parts
end

local function parlorRoofParts()
	local y = PARLOR_FLOOR + PARLOR_WALL_HEIGHT
	local width = PARLOR.Right - PARLOR.Left + 2
	local depth = PARLOR.Back - PARLOR.Front + 2
	local grey = Color3.fromRGB(150, 150, 158)
	local noCollide = { CanCollide = false }
	local parts = {
		parlorPart("RoofSlab", Vector3.new(width, 1, depth), Vector3.new(PARLOR_CENTER_X, y, PARLOR_CENTER_Z), PARLOR_CREAM),
		parlorPart("ParapetFront", Vector3.new(width, 2, 1), Vector3.new(PARLOR_CENTER_X, y + 1, PARLOR.Front - 0.5), PARLOR_RED),
		parlorPart("ParapetBack", Vector3.new(width, 2, 1), Vector3.new(PARLOR_CENTER_X, y + 1, PARLOR.Back + 0.5), PARLOR_RED),
		parlorPart("ParapetLeft", Vector3.new(1, 2, depth - 2), Vector3.new(PARLOR.Left - 0.5, y + 1, PARLOR_CENTER_Z), PARLOR_RED),
		parlorPart("ParapetRight", Vector3.new(1, 2, depth - 2), Vector3.new(PARLOR.Right + 0.5, y + 1, PARLOR_CENTER_Z), PARLOR_RED),
		parlorPart("AirUnit1", Vector3.new(6, 3, 5), Vector3.new(98, y + 1, 90), grey),
		parlorPart("AirUnit2", Vector3.new(6, 3, 5), Vector3.new(110, y + 1, 90), grey),
		parlorPart("Hatch", Vector3.new(4, 1, 4), Vector3.new(70, y + 1, 90), grey),
	}
	-- Soft ceiling lights under the slab (9 fills the room without blooming white walls).
	local lightIndex = 0
	for _, z in ipairs({ 48, 68, 88 }) do
		for _, x in ipairs({ 70, 90, 110 }) do
			lightIndex += 1
			local accent = if lightIndex % 2 == 0 then PARLOR_BLUE else PARLOR_PINK
			table.insert(parts, parlorPart(
				"CeilPanel" .. lightIndex,
				Vector3.new(3.2, 0.3, 3.2),
				Vector3.new(x, y - 0.3, z),
				accent,
				noCollide
			))
			table.insert(parts, parlorPart(
				"CeilBulb" .. lightIndex,
				Vector3.new(1.4, 0.35, 1.4),
				Vector3.new(x, y - 0.65, z),
				Color3.fromRGB(245, 240, 230),
				{
					CanCollide = false,
					PointLight = CEILING_LIGHT,
				}
			))
		end
	end
	return parts
end

-- Floor, service counter, back bar, menu board, window glass and pendant accents.
local function parlorInteriorParts()
	local innerLeft, innerFront = PARLOR.Left + PARLOR_WALL, PARLOR.Front + PARLOR_WALL
	local innerWidth = PARLOR.Right - PARLOR.Left - 2 * PARLOR_WALL
	local innerDepth = PARLOR.Back - PARLOR.Front - 2 * PARLOR_WALL
	local counterX, counterZ = PARLOR_PLACEMENT.X, PARLOR_PLACEMENT.Z
	local parts = {
		parlorPart("Floor", Vector3.new(innerWidth, 0.1, innerDepth), Vector3.new(PARLOR_CENTER_X, PARLOR_FLOOR, PARLOR_CENTER_Z), PARLOR_CREAM),
		-- The visible counter, exactly over the station's hidden Counter anchor.
		parlorPart("ServiceCounter", PARLOR_COUNTER_SIZE, PARLOR_PLACEMENT, PARLOR_PINK),
		parlorPart("CounterTop", Vector3.new(4.6, 0.3, 22.6), Vector3.new(counterX, PARLOR_FLOOR + 3.5, counterZ), PARLOR_CREAM),
		parlorPart("CounterTrim", Vector3.new(4.8, 0.2, 22.8), Vector3.new(counterX, PARLOR_FLOOR + 3.65, counterZ), PARLOR_RED),
		parlorPart("Register", Vector3.new(1.6, 1.1, 1.2), Vector3.new(107.2, PARLOR_FLOOR + 3.8, 61), Color3.fromRGB(55, 55, 65), { FaceRight = true }),
		parlorPart("BackBar", Vector3.new(4, 3.5, 30), Vector3.new(121, PARLOR_FLOOR, counterZ), PARLOR_BLUE),
		parlorPart("BackBarTop", Vector3.new(4.4, 0.3, 30.4), Vector3.new(121, PARLOR_FLOOR + 3.5, counterZ), PARLOR_CREAM),
		parlorPart("Shelf", Vector3.new(2, 0.4, 30), Vector3.new(122, PARLOR_FLOOR + 8, counterZ), WOOD_COLOR),
		parlorPart("MenuBoard", Vector3.new(18, 5, 0.3), Vector3.new(PARLOR.Right - PARLOR_WALL - 0.15, PARLOR_FLOOR + 11, counterZ), PARLOR_RED, {
			FaceLeft = true,
			Label = "SCOOPS - SUNDAES - SHAKES",
		}),
	}

	-- Pastel pink / blue checks on alternate cells over the cream floor.
	local tile = 10
	for col = 0, math.floor(innerWidth / tile) - 1 do
		for row = 0, math.floor(innerDepth / tile) - 1 do
			if (col + row) % 2 == 0 then
				table.insert(parts, parlorPart(
					"Tile" .. col .. "_" .. row,
					Vector3.new(tile, 0.12, tile),
					Vector3.new(innerLeft + tile * (col + 0.5), PARLOR_FLOOR, innerFront + tile * (row + 0.5)),
					if col % 2 == 0 then PARLOR_PINK else PARLOR_BLUE
				))
			end
		end
	end

	for i = 1, 5 do
		table.insert(parts, parlorPart("ShelfTub" .. i, Vector3.new(1.4, 1.2, 1.4), Vector3.new(122, PARLOR_FLOOR + 8.4, counterZ - 10 + (i - 1) * 5), SCOOP_COLORS[i]))
	end

	-- Glass in every window hole, centered in the wall.
	for _, wall in ipairs(PARLOR_WALLS) do
		for i, opening in ipairs(wall.Openings) do
			if opening.Glass then
				for j, hole in ipairs(opening.Holes) do
					local length, height = opening.To - opening.From, hole[2] - hole[1]
					local mid = (opening.From + opening.To) / 2
					local size = if wall.Along == "X" then Vector3.new(length, height, 0.2) else Vector3.new(0.2, height, length)
					local at = if wall.Along == "X" then Vector3.new(mid, PARLOR_FLOOR + hole[1], wall.Fixed) else Vector3.new(wall.Fixed, PARLOR_FLOOR + hole[1], mid)
					table.insert(parts, parlorPart(wall.Prefix .. "Glass" .. i .. "_" .. j, size, at, GLASS_COLOR, { Transparency = 0.55 }))
				end
			end
		end
	end
	return parts
end

-- A parked customer car, nose to the street, wheels on the lot asphalt.
local function parlorCarParts(x: number, color: Color3)
	local y, z = YARD_HEIGHT + PARLOR_LOT_HEIGHT, PARLOR_PARK_Z
	local dark = Color3.fromRGB(30, 35, 45)
	local function piece(name: string, size: Vector3, dx: number, dy: number, dz: number, partColor: Color3)
		return parlorPart(name, size, Vector3.new(x + dx, y + dy, z + dz), partColor)
	end
	local parts = {
		piece("Body", Vector3.new(5, 2, 10), 0, 0.7, 0, color),
		piece("Cabin", Vector3.new(4.4, 1.8, 5), 0, 2.7, 0.8, color),
		piece("SideWindows", Vector3.new(4.5, 1.2, 4.2), 0, 3, 0.8, dark),
		piece("Windshield", Vector3.new(4.2, 1.4, 0.2), 0, 2.9, -1.8, dark),
		piece("RearWindow", Vector3.new(4.2, 1.4, 0.2), 0, 2.9, 3.4, dark),
		piece("HeadlightL", Vector3.new(1, 0.5, 0.2), -1.6, 1.6, -5.05, LAMP_COLOR),
		piece("HeadlightR", Vector3.new(1, 0.5, 0.2), 1.6, 1.6, -5.05, LAMP_COLOR),
	}
	for _, wheel in ipairs({ { "FL", -2.3, -3.2 }, { "FR", 2.3, -3.2 }, { "BL", -2.3, 3.2 }, { "BR", 2.3, 3.2 } }) do
		table.insert(parts, piece("Wheel" .. wheel[1], Vector3.new(0.8, 1.6, 1.6), wheel[2], 0, wheel[3], TIRE_COLOR))
	end
	return parts
end

local function parlorSpotX(spot: number): number
	return PARLOR_LOT.Left + PARLOR_SPOT_WIDTH * (spot - 0.5)
end

local function parlorParkingParts()
	local asphaltBottom = YARD_HEIGHT
	local top = asphaltBottom + PARLOR_LOT_HEIGHT
	local left, right = PARLOR_LOT.Left, PARLOR_LOT.Right
	local front, back = LOT_FRONT_Z, 32 -- sidewalk to just short of the building
	local width = right - left
	local centerX = (left + right) / 2
	local centerZ = (front + back) / 2
	local parts = {
		parlorPart("Asphalt", Vector3.new(width, PARLOR_LOT_HEIGHT, back - front), Vector3.new(centerX, asphaltBottom, centerZ), ASPHALT_COLOR),
		parlorPart("Hedge", Vector3.new(width, 1.2, 1.6), Vector3.new(centerX, top, back - 0.9), BUSH_COLOR),
		parlorPart("SideCurb", Vector3.new(1, 0.6, back - front - 8), Vector3.new(right - 0.5, top, centerZ + 2), CURB_COLOR),
		parlorPart("SignPole", Vector3.new(0.4, 5, 0.4), Vector3.new(right - 4, top, front + 4), POLE_COLOR),
		parlorPart("SignBoard", Vector3.new(7, 2.4, 0.3), Vector3.new(right - 4, top + 5, front + 4), LOT_SIGN_COLOR, {
			FaceStreet = true,
			Label = "PARKING",
		}),
	}
	for i, fraction in ipairs({ 0.3, 0.7 }) do
		local x = left + width * fraction
		local z = front + 6
		table.insert(parts, parlorPart("Lamp" .. i .. "Pole", Vector3.new(0.5, 9, 0.5), Vector3.new(x, top, z), POLE_COLOR))
		table.insert(parts, parlorPart("Lamp" .. i .. "Arm", Vector3.new(0.4, 0.4, 2), Vector3.new(x, top + 8.6, z + 1), POLE_COLOR))
		table.insert(parts, parlorPart("Lamp" .. i .. "Head", Vector3.new(1.6, 0.5, 1.2), Vector3.new(x, top + 8.3, z + 2), LAMP_COLOR))
	end
	local spots = math.floor(width / PARLOR_SPOT_WIDTH)
	for i = 0, spots do
		local x = math.clamp(left + i * PARLOR_SPOT_WIDTH, left + 0.2, right - 0.2)
		table.insert(parts, parlorPart("Line" .. i, Vector3.new(0.4, 0.05, 17), Vector3.new(x, top, PARLOR_PARK_Z), LINE_COLOR))
	end
	return parts
end

local function parlorGrandOpeningVisual()
	local doorZ = (PARLOR_DOOR.From + PARLOR_DOOR.To) / 2
	local noCollide = { CanCollide = false }
	local ribbon = Color3.fromRGB(220, 30, 50)
	local paver = Color3.fromRGB(235, 175, 185)
	local parts = {
		-- Pink path from the sidewalk up to the door (on the lawn slab).
		parlorPart("WalkwayStreet", Vector3.new(8, 0.3, 84), Vector3.new(40, YARD_HEIGHT, 32), paver),
		parlorPart("WalkwayDoor", Vector3.new(8, 0.3, 12), Vector3.new(48, YARD_HEIGHT, doorZ), paver),
		-- The ribbon, already cut: one half hanging at each side of the door.
		parlorPart("RibbonLeft", Vector3.new(0.2, 3, 0.6), Vector3.new(PARLOR.Left - 0.4, PARLOR_FLOOR, PARLOR_DOOR.From + 0.6), ribbon, noCollide),
		parlorPart("RibbonRight", Vector3.new(0.2, 3, 0.6), Vector3.new(PARLOR.Left - 0.4, PARLOR_FLOOR, PARLOR_DOOR.To - 0.6), ribbon, noCollide),
		parlorPart("Banner", Vector3.new(14, 3, 0.3), Vector3.new(PARLOR.Left - 0.15, PARLOR_FLOOR + 18.5, doorZ), Color3.fromRGB(255, 210, 70), {
			FaceLeft = true,
			Label = "GRAND OPENING!",
		}),
	}
	-- A balloon bunch on a post at each side of the door.
	for side, z in ipairs({ 58, 78 }) do
		local x = PARLOR.Left - 3.5
		table.insert(parts, parlorPart("BalloonPost" .. side, Vector3.new(0.3, 3, 0.3), Vector3.new(x, YARD_HEIGHT, z), PARLOR_CREAM))
		table.insert(parts, parlorPart("BalloonString" .. side, Vector3.new(0.1, 3.5, 0.1), Vector3.new(x, YARD_HEIGHT + 3, z), PARLOR_CREAM, noCollide))
		for i, offset in ipairs({ { 0, 6.5, 0 }, { -0.9, 6, 0.9 }, { 0.7, 6.2, -0.9 } }) do
			table.insert(parts, parlorPart(
				"Balloon" .. side .. "_" .. i,
				Vector3.new(1.6, 1.9, 1.6),
				Vector3.new(x + offset[1], YARD_HEIGHT + offset[2], z + offset[3]),
				SCOOP_COLORS[(side + i) % #SCOOP_COLORS + 1],
				noCollide
			))
		end
	end

	local carColors = {
		Color3.fromRGB(200, 60, 60),
		Color3.fromRGB(60, 110, 200),
		Color3.fromRGB(240, 240, 240),
		Color3.fromRGB(60, 160, 90),
		Color3.fromRGB(240, 200, 60),
		Color3.fromRGB(90, 90, 100),
	}
	local vehicles = {}
	for i, spot in ipairs(PARLOR_CAR_SPOTS) do
		table.insert(vehicles, parlorCarParts(parlorSpotX(spot), carColors[(i - 1) % #carColors + 1]))
	end
	return { Parts = parts, Vehicles = vehicles, Depart = PARLOR_CAR_DEPART }
end

-- A small table with a chair on each side (±X).
local function bistroTableParts(prefix: string, x: number, z: number, chairColor: Color3)
	local parts = {
		parlorPart(prefix .. "Base", Vector3.new(2, 0.2, 2), Vector3.new(x, PARLOR_FLOOR, z), DARK_COLOR),
		parlorPart(prefix .. "Leg", Vector3.new(0.6, 2.8, 0.6), Vector3.new(x, PARLOR_FLOOR + 0.2, z), CHROME_COLOR),
		parlorPart(prefix .. "Top", Vector3.new(3.6, 0.3, 3.6), Vector3.new(x, PARLOR_FLOOR + 3, z), PARLOR_CREAM),
	}
	for side, sign in ipairs({ -1, 1 }) do
		local cx = x + sign * 2.8
		table.insert(parts, parlorPart(prefix .. "ChairLeg" .. side, Vector3.new(1.2, 1.8, 1.2), Vector3.new(cx, PARLOR_FLOOR, z), CHROME_COLOR))
		table.insert(parts, parlorPart(prefix .. "ChairSeat" .. side, Vector3.new(1.8, 0.3, 1.8), Vector3.new(cx, PARLOR_FLOOR + 1.8, z), chairColor))
		table.insert(parts, parlorPart(prefix .. "ChairBack" .. side, Vector3.new(0.3, 2.4, 1.8), Vector3.new(x + sign * 3.55, PARLOR_FLOOR + 2.1, z), chairColor))
	end
	return parts
end

local function parlorBistroParts()
	local parts = {}
	local index = 0
	for _, z in ipairs({ 45, 54 }) do
		for _, x in ipairs({ 68, 80, 92 }) do
			index += 1
			appendAll(parts, bistroTableParts("Table" .. index, x, z, if index % 2 == 0 then PARLOR_BLUE else PARLOR_PINK))
		end
	end
	return parts
end

-- Booths against the back wall, under where the loft will go.
local function parlorBoothParts()
	local parts = {}
	local z = 95.5
	for i, x in ipairs({ 64, 78, 92 }) do
		local prefix = "Booth" .. i
		table.insert(parts, parlorPart(prefix .. "Leg", Vector3.new(0.8, 3, 0.8), Vector3.new(x, PARLOR_FLOOR, z), CHROME_COLOR))
		table.insert(parts, parlorPart(prefix .. "Table", Vector3.new(3.4, 0.3, 6), Vector3.new(x, PARLOR_FLOOR + 3, z), PARLOR_CREAM))
		for side, sign in ipairs({ -1, 1 }) do
			table.insert(parts, parlorPart(prefix .. "Seat" .. side, Vector3.new(2, 1.8, 6), Vector3.new(x + sign * 2.9, PARLOR_FLOOR, z), PARLOR_PINK))
			table.insert(parts, parlorPart(prefix .. "Back" .. side, Vector3.new(0.6, 4.5, 6), Vector3.new(x + sign * 4.2, PARLOR_FLOOR, z), PARLOR_RED))
		end
	end
	return parts
end

local function parlorDippingCabinetParts()
	local x = 104.7
	local z = PARLOR_PLACEMENT.Z
	local top = PARLOR_FLOOR + 3.8
	local parts = {
		parlorPart("CabinetBase", Vector3.new(1.8, 1.4, 18), Vector3.new(x, top, z), PARLOR_CREAM),
		parlorPart("CabinetGlassFront", Vector3.new(0.2, 1.6, 18), Vector3.new(103.7, top + 1.4, z), GLASS_COLOR, { Transparency = 0.5 }),
		parlorPart("CabinetGlassTop", Vector3.new(1.8, 0.2, 18), Vector3.new(x, top + 3, z), GLASS_COLOR, { Transparency = 0.5 }),
	}
	for i = 1, 6 do
		table.insert(parts, parlorPart("Tub" .. i, Vector3.new(1.4, 0.5, 2.4), Vector3.new(x, top + 1.4, z - 7.5 + (i - 1) * 3), SCOOP_COLORS[i]))
	end
	return parts
end

local function parlorToppingsParts()
	local x, z = 112, 40
	local parts = {
		parlorPart("ToppingsBar", Vector3.new(18, 3.5, 3), Vector3.new(x, PARLOR_FLOOR, z), PARLOR_CREAM),
		parlorPart("ToppingsTop", Vector3.new(18.4, 0.3, 3.4), Vector3.new(x, PARLOR_FLOOR + 3.5, z), PARLOR_BLUE),
		parlorPart("SneezeGuard", Vector3.new(18, 1.4, 0.2), Vector3.new(x, PARLOR_FLOOR + 3.8, z + 1.6), GLASS_COLOR, { Transparency = 0.5 }),
		parlorPart("ToppingsSign", Vector3.new(10, 2, 0.3), Vector3.new(x, PARLOR_FLOOR + 11, PARLOR.Front + PARLOR_WALL + 0.15), PARLOR_PINK, {
			FaceEmployee = true,
			Label = "TOPPINGS",
		}),
	}
	local jarColors = { Color3.fromRGB(220, 40, 60), Color3.fromRGB(90, 60, 40), Color3.fromRGB(250, 230, 120), Color3.fromRGB(120, 200, 255) }
	for i = 1, 8 do
		table.insert(parts, parlorPart("Jar" .. i, Vector3.new(1, 1.2, 1), Vector3.new(x - 7.5 + (i - 1) * 2.15, PARLOR_FLOOR + 3.8, z - 0.5), jarColors[(i - 1) % #jarColors + 1]))
	end
	return parts
end

local function parlorAwningParts()
	local doorZ = (PARLOR_DOOR.From + PARLOR_DOOR.To) / 2
	local y = PARLOR_FLOOR + PARLOR_DOOR.Holes[1][2]
	-- Proud of the wall so the front edge doesn't z-fight the entrance face.
	local depth = 5.25
	local width = 18.25
	local x = PARLOR.Left - depth / 2
	-- Valance sits fully outside the cream slab so white never flickers through its front.
	local outer = PARLOR.Left - depth
	local parts = {
		parlorPart("Awning", Vector3.new(depth, 0.6, width), Vector3.new(x, y, doorZ), PARLOR_CREAM),
		parlorPart("AwningValance", Vector3.new(0.5, 1.2, width), Vector3.new(outer - 0.05, y - 0.6, doorZ), PARLOR_RED),
		parlorPart("PosterLeft", Vector3.new(5, 6, 0.2), Vector3.new(PARLOR.Left - 0.1, PARLOR_FLOOR + 3, 57.5), PARLOR_PINK, { FaceLeft = true, Label = "NEW FLAVORS!" }),
		parlorPart("PosterRight", Vector3.new(5, 6, 0.2), Vector3.new(PARLOR.Left - 0.1, PARLOR_FLOOR + 3, 78.5), PARLOR_BLUE, { FaceLeft = true, Label = "TRY A SUNDAE" }),
		-- Sandwich board by the sidewalk, beside the walkway.
		parlorPart("BoardFront", Vector3.new(3, 3.5, 0.4), Vector3.new(47, YARD_HEIGHT, -3), Color3.fromRGB(40, 30, 45), { FaceStreet = true, Label = "ICE CREAM" }),
		parlorPart("BoardBack", Vector3.new(3, 3.5, 0.4), Vector3.new(47, YARD_HEIGHT, -1.8), Color3.fromRGB(40, 30, 45)),
		parlorPart("BoardCap", Vector3.new(3, 0.3, 1.6), Vector3.new(47, YARD_HEIGHT + 3.5, -2.4), WOOD_COLOR),
	}
	for i, z in ipairs({ doorZ - 6, doorZ, doorZ + 6 }) do
		-- Stripes sit on top only (same depth as the slab) — don't poke past the valance face.
		table.insert(parts, parlorPart("AwningStripe" .. i, Vector3.new(depth, 0.62, 3), Vector3.new(x, y + 0.01, z), if i % 2 == 0 then PARLOR_BLUE else PARLOR_RED))
	end
	return parts
end

local function parlorMarqueeParts()
	local doorZ = (PARLOR_DOOR.From + PARLOR_DOOR.To) / 2
	return {
		parlorPart("MarqueeBacking", Vector3.new(32, 8, 0.4), Vector3.new(PARLOR.Left - 1.2, PARLOR_FLOOR + 23, doorZ), PARLOR_RED, { FaceLeft = true }),
		parlorPart("MarqueeFace", Vector3.new(31, 7, 0.2), Vector3.new(PARLOR.Left - 1.5, PARLOR_FLOOR + 23.5, doorZ), PARLOR_PINK, {
			FaceLeft = true,
			Label = "{Player}'s Parlor",
		}),
		parlorPart("StreetSign", Vector3.new(26, 5, 0.4), Vector3.new(PARLOR_CENTER_X, PARLOR_FLOOR + 23.5, PARLOR.Front - 1.2), PARLOR_BLUE, {
			FaceStreet = true,
			Label = "ICE CREAM",
		}),
	}
end

local function parlorPatioParts()
	local deckBottom = YARD_HEIGHT
	local deckTop = deckBottom + 0.5
	local parts = {
		parlorPart("Deck", Vector3.new(26, 0.5, 22), Vector3.new(38, deckBottom, 88), WOOD_COLOR),
	}
	for i, spot in ipairs({ { 31, 82 }, { 45, 82 }, { 31, 94 }, { 45, 94 } }) do
		local x, z = spot[1], spot[2]
		local canopy = if i % 2 == 0 then PARLOR_BLUE else PARLOR_PINK
		table.insert(parts, parlorPart("PatioLeg" .. i, Vector3.new(0.5, 2.8, 0.5), Vector3.new(x, deckTop, z), CHROME_COLOR))
		table.insert(parts, parlorPart("PatioTable" .. i, Vector3.new(3, 0.3, 3), Vector3.new(x, deckTop + 2.8, z), PARLOR_CREAM))
		table.insert(parts, parlorPart("UmbrellaPole" .. i, Vector3.new(0.3, 7.2, 0.3), Vector3.new(x, deckTop + 3.1, z), PARLOR_CREAM))
		table.insert(parts, parlorPart("Umbrella" .. i, Vector3.new(6, 0.4, 6), Vector3.new(x, deckTop + 10.3, z), canopy))
		table.insert(parts, parlorPart("StoolA" .. i, Vector3.new(1.4, 1.8, 1.4), Vector3.new(x, deckTop, z - 2.4), canopy))
		table.insert(parts, parlorPart("StoolB" .. i, Vector3.new(1.4, 1.8, 1.4), Vector3.new(x, deckTop, z + 2.4), canopy))
	end
	for i, z in ipairs({ 78, 98 }) do
		table.insert(parts, parlorPart("PatioPlanter" .. i, Vector3.new(2, 1, 2), Vector3.new(26, deckTop, z), PLANTER_COLOR))
		table.insert(parts, parlorPart("PatioBush" .. i, Vector3.new(2.2, 2, 2.2), Vector3.new(26, deckTop + 1, z), BUSH_COLOR))
	end
	return parts
end

--[[
	Mezzanine over the booths along the back wall, reached by floating
	half-stud slabs (13 rises) along its front edge. Wide rail gap at the top.
]]
local function parlorLoftParts()
	local slabBottom = PARLOR_FLOOR + 12
	local slabTop = slabBottom + 1
	local front, back = 86, PARLOR.Back - PARLOR_WALL
	local left, right = PARLOR.Left + PARLOR_WALL, 100
	local midZ = (front + back) / 2
	-- Wide opening where the stairs land (stand-space X).
	local gapFrom, gapTo = 70, 82
	local parts = {
		parlorPart("LoftFloor", Vector3.new(right - left, 1, back - front), Vector3.new((left + right) / 2, slabBottom, midZ), WOOD_COLOR),
		parlorPart("LoftColumn1", Vector3.new(1, 12, 1), Vector3.new(60, PARLOR_FLOOR, front + 0.5), PARLOR_CREAM),
		parlorPart("LoftColumn2", Vector3.new(1, 12, 1), Vector3.new(right - 0.5, PARLOR_FLOOR, front + 0.5), PARLOR_CREAM),
		parlorPart("RailFrontA", Vector3.new(gapFrom - left, 3, 0.3), Vector3.new((left + gapFrom) / 2, slabTop, front + 0.15), PARLOR_RED),
		parlorPart("RailFrontB", Vector3.new(right - gapTo, 3, 0.3), Vector3.new((gapTo + right) / 2, slabTop, front + 0.15), PARLOR_RED),
		parlorPart("RailSide", Vector3.new(0.3, 3, back - front), Vector3.new(right - 0.15, slabTop, midZ), PARLOR_RED),
	}
	-- Floating slabs: thin treads, top of step i at PARLOR_FLOOR + i (= loft deck at i = 13).
	local tread = 0.5
	local stepDepth, stepWidth = 2.2, 6
	for i = 1, 13 do
		local top = PARLOR_FLOOR + i
		table.insert(parts, parlorPart(
			"Step" .. i,
			Vector3.new(stepDepth, tread, stepWidth),
			Vector3.new(101 - 2 * i, top - tread, front - 3),
			PARLOR_CREAM
		))
	end
	for i, x in ipairs({ 68, 88 }) do
		table.insert(parts, parlorPart("Sofa" .. i, Vector3.new(10, 1.6, 3), Vector3.new(x, slabTop, back - 3), PARLOR_BLUE))
		table.insert(parts, parlorPart("SofaBack" .. i, Vector3.new(10, 3.4, 1), Vector3.new(x, slabTop, back - 1), PARLOR_BLUE))
		table.insert(parts, parlorPart("CoffeeTable" .. i, Vector3.new(4, 1.4, 2.5), Vector3.new(x, slabTop, back - 7.5), WOOD_COLOR))
	end
	return parts
end

-- Hedges, flowers, and trees on the grass yard that arrived with the foundation.
local function parlorGardenParts()
	local land = PARLOR_LAND
	local y = YARD_HEIGHT
	local parts = {
		parlorPart("HedgeBack", Vector3.new(land.Right - land.Left, 3, 2), Vector3.new((land.Left + land.Right) / 2, y, land.Back - 1), BUSH_COLOR),
		parlorPart("HedgeSide", Vector3.new(2, 3, land.Back - 2 - 32), Vector3.new(land.Right - 1, y, (32 + land.Back - 2) / 2), BUSH_COLOR),
		parlorPart("FlowerBed", Vector3.new(PARLOR.Right - PARLOR.Left, 0.6, 2), Vector3.new(PARLOR_CENTER_X, y, PARLOR.Front - 3.5), PLANTER_COLOR),
	}
	for i = 1, 12 do
		local x = PARLOR.Left + 2 + (i - 1) * (PARLOR.Right - PARLOR.Left - 4) / 11
		table.insert(parts, parlorPart("Flower" .. i, Vector3.new(1, 1, 1), Vector3.new(x, y + 0.6, PARLOR.Front - 3.5), SCOOP_COLORS[(i - 1) % #SCOOP_COLORS + 1]))
	end
	for i, z in ipairs({ 20, 70 }) do
		table.insert(parts, parlorPart("TreeTrunk" .. i, Vector3.new(1.2, 6, 1.2), Vector3.new(26, y, z), PARLOR_CHOCOLATE))
		table.insert(parts, parlorPart("TreeCrown" .. i, Vector3.new(6, 5, 6), Vector3.new(26, y + 6, z), BUSH_COLOR))
	end
	return parts
end

local function parlorSundaeParts()
	local x, z, y = PARLOR_CENTER_X, PARLOR_CENTER_Z, PARLOR_ROOF_TOP
	return {
		parlorPart("SundaeFoot", Vector3.new(4, 1.5, 4), Vector3.new(x, y, z), GLASS_COLOR),
		parlorPart("SundaeBowl", Vector3.new(10, 3, 10), Vector3.new(x, y + 1.5, z), GLASS_COLOR),
		parlorPart("ScoopPink", Vector3.new(7, 6, 7), Vector3.new(x - 2, y + 4.5, z - 1), SCOOP_COLORS[1]),
		parlorPart("ScoopMint", Vector3.new(7, 6, 7), Vector3.new(x + 2.5, y + 4.5, z + 1), SCOOP_COLORS[2]),
		parlorPart("ScoopChocolate", Vector3.new(6.5, 5.5, 6.5), Vector3.new(x, y + 9.3, z), PARLOR_CHOCOLATE),
		parlorPart("Wafer", Vector3.new(1, 6, 3), Vector3.new(x + 3.5, y + 9, z - 2), Color3.fromRGB(215, 165, 95)),
		parlorPart("Whip", Vector3.new(5, 3, 5), Vector3.new(x, y + 14.8, z), PARLOR_CREAM),
		parlorPart("Cherry", Vector3.new(2, 2, 2), Vector3.new(x, y + 17.8, z), Color3.fromRGB(220, 30, 50)),
		parlorPart("CherryStem", Vector3.new(0.3, 2, 0.3), Vector3.new(x, y + 19.8, z), Color3.fromRGB(90, 140, 60)),
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
	Tier ladder. Tiers 1–4 are real; later entries are placeholders.
	Each station's employee automates it; its Cost should sit next to, and
	roughly equal, the next tier's UnlockCost (the Parlor is the one
	deliberate exception).

	Placement: station-space offset of the station's counter from the tier-1
	counter (X across, −X = left when facing the road; Z away from the street).
	A station without Placement is a placeholder and is never built.
	Counter: the main part (panel anchor + interact distance). Hidden = an
	invisible anchor, for a station whose visible counter is an upgrade.
	UnlockRequires: physical upgrade ids on the *previous* station that must be
	owned before this station's unlock button appears. UnlockRequiresOn =
	{ [stationId] = { ids } } for prerequisites on any other station.
	UnlockButtonAt: where the unlock button stands (default Placement).
	OpensWith: physical upgrade id; until it's owned the station can't sell
	or take panel upgrades (no panel) — only its physical upgrades.
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
				ButtonOffset = Vector3.new(-6, 0, 8),
				Visual = { Size = Vector3.new(3, 2.5, 3), Offset = Vector3.new(-6, 0, 2), Color = Color3.fromRGB(90, 140, 200) },
			},
			{
				Id = "DeepFreezer",
				DisplayName = "Deep Freezer",
				Cost = 1000,
				PayoutMultiplier = 3,
				ButtonOffset = Vector3.new(6.5, 0, 9),
				Visual = { Size = Vector3.new(4, 3.5, 3), Offset = Vector3.new(6.5, 0, 2), Color = Color3.fromRGB(225, 235, 250) },
			},
			{
				Id = "PopDispenser",
				DisplayName = "Pop Dispenser",
				Cost = 4000,
				-- Halves cycle duration (sales run ×2 faster).
				SpeedMultiplier = 2,
				ButtonOffset = Vector3.new(7.5, 0, -5),
				-- Was center of counter; now sits where the register used to.
				Visual = { Size = Vector3.new(2, 2.5, 1.5), Offset = Vector3.new(2.2, 3, 0.4), Color = Color3.fromRGB(255, 120, 170) },
			},
			{
				Id = "Cashier",
				DisplayName = "Cashier",
				-- Cheaper than Cooler Cart unlock ($10K) so automation lands before tier 2.
				-- Available alongside Deep Freezer (after Bigger Cooler), not last in line.
				Cost = 5000,
				Automates = true,
				Requires = { "BiggerCooler" },
				ButtonOffset = Vector3.new(0.5, 0, 21),
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
				ButtonOffset = Vector3.new(-7, 0, -6),
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
				Cost = 1000,
				Requires = { "BiggerCooler" },
				-- Lot center; well away from the Cooler Cart unlock button that
				-- replaces it, so stepping off this one can't buy the cart too.
				ButtonOffset = lotCenterButton(PARKING_LOT, Vector3.zero),
				Visual = { Parts = lotSectionParts(PARKING_LOT, Vector3.zero, PARKING_LOT.Right - 0.5) },
			},
			-- Ground for tier 4 (parlor), right of the stand. No income effect;
			-- the parlor unlock requires it (UnlockRequiresOn).
			{
				Id = "ParlorLand",
				DisplayName = "Parlor Land",
				Subtitle = "parlor coming soon",
				Cost = 25000,
				Requires = { "Cashier" },
				-- Stand-space from Plot 1 aim; mirrors correctly on South plots.
				ButtonOffset = Vector3.new(12, 0, 43),
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
		-- Appears with the Cashier path (after Bigger Cooler / Parking Lot).
		-- Cashier is $5K; this stays $10K so tier 2 is the bigger step.
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
				Visual = { Parts = lotSectionParts(TRUCK_LOT, COOLER_CART_PLACEMENT, TRUCK_LOT.Left + 0.5) },
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
				-- Employee = automation. Deliberately far below the Parlor's $2.5M
				-- unlock: the parlor is a long-term investment, not the next step.
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
	--[[
		Tier 4: the ice cream parlor on the stand's Parlor Land. Offered as soon
		as the Ice Cream Truck exists, at a deliberately steep price (exception
		to "employee ≈ next unlock": Driver is $200K). Unlock = foundation.
		Walls → Roof → Interior → Grand Opening (+ Customer Parking) are pure
		investment; it can't sell until Grand Opening (OpensWith). Then the
		usual flow: seating and décor, Scooper automates partway down.
	]]
	{
		Id = "Parlor",
		DisplayName = "Ice Cream Parlor",
		UnlockCost = 2500000,
		UnlockRequires = {},
		-- Built on the stand's gate step, not the truck's.
		UnlockRequiresOn = { PopsicleStand = { "ParlorLand" } },
		UnlockSubtitle = "lays the foundation",
		-- Unlock button near Parlor Land (stand-space; mirrors on South plots).
		UnlockButtonAt = Vector3.new(12, LOT_HEIGHT, 56),
		Placement = PARLOR_PLACEMENT,
		-- Invisible anchor for the panel; Interior adds the real counter over it.
		Counter = { Size = PARLOR_COUNTER_SIZE, Color = PARLOR_PINK, Hidden = true },
		OpensWith = "GrandOpening",
		Decor = parlorFoundationParts(),
		BasePayout = 200000,
		BaseDuration = 10,
		Upgrade = {
			BaseCost = 400000,
			CostGrowth = 1.6,
			PayoutGrowth = 1.25,
		},
		Physical = {
			-- Construction: no income effect (Subtitle says what it is).
			{
				Id = "Walls",
				DisplayName = "Parlor Walls",
				Subtitle = "construction",
				Cost = 1500000,
				-- In the doorway.
				ButtonOffset = parlorPoint(Vector3.new(PARLOR.Left + 4, PARLOR_FLOOR, 68)),
				Visual = { Parts = parlorAllWallParts() },
			},
			{
				Id = "ParlorParking",
				DisplayName = "Customer Parking",
				Subtitle = "construction",
				Cost = 1000000,
				Requires = {},
				ButtonOffset = parlorPoint(Vector3.new((PARLOR_LOT.Left + PARLOR_LOT.Right) / 2, 0, 10)),
				Visual = { Parts = parlorParkingParts() },
			},
			{
				Id = "Roof",
				DisplayName = "Parlor Roof",
				Subtitle = "construction",
				Cost = 2000000,
				Requires = { "Walls" },
				ButtonOffset = parlorPoint(Vector3.new(PARLOR_CENTER_X, PARLOR_FLOOR, PARLOR_CENTER_Z)),
				Visual = { Parts = parlorRoofParts() },
			},
			{
				Id = "Interior",
				DisplayName = "Parlor Interior",
				Subtitle = "floor, counter, menu",
				Cost = 3000000,
				-- In front of where the counter will stand.
				ButtonOffset = parlorPoint(Vector3.new(98, PARLOR_FLOOR, PARLOR_CENTER_Z)),
				Visual = { Parts = parlorInteriorParts() },
			},
			{
				Id = "GrandOpening",
				DisplayName = "Grand Opening",
				Subtitle = "opens the parlor",
				Cost = 2000000,
				Requires = { "Interior", "ParlorParking" },
				-- On the plaza outside the door, where the walkway will land.
				ButtonOffset = parlorPoint(Vector3.new(48, 0, 68)),
				Visual = parlorGrandOpeningVisual(),
			},
			-- Open for business: every buy from here has one income effect.
			{
				Id = "BistroTables",
				DisplayName = "Bistro Tables",
				Cost = 5000000,
				PayoutMultiplier = 1.5,
				Requires = { "GrandOpening" },
				ButtonOffset = parlorPoint(Vector3.new(80, PARLOR_FLOOR, 49.5)),
				Visual = { Parts = parlorBistroParts() },
			},
			{
				Id = "Scooper",
				DisplayName = "Scooper",
				-- Employee = automation. Cost ≈ next tier's UnlockCost (placeholder Dessert Factory).
				-- Available as soon as the parlor opens, alongside Bistro Tables.
				Cost = 8000000,
				Automates = true,
				Requires = { "GrandOpening" },
				ButtonOffset = parlorPoint(Vector3.new(113, PARLOR_FLOOR, 76)),
				-- Behind the counter facing the door, tip jar on the counter.
				Visual = {
					ModelTemplate = "Cashier",
					Offset = parlorPoint(Vector3.new(113, PARLOR_FLOOR, PARLOR_CENTER_Z)),
					FaceLeft = true,
					Parts = {
						parlorPart("TipJar", Vector3.new(0.8, 1, 0.8), Vector3.new(106.8, PARLOR_FLOOR + 3.8, 75), GLASS_COLOR, { Transparency = 0.3 }),
					},
				},
			},
			{
				Id = "DippingCabinet",
				DisplayName = "Dipping Cabinet",
				Cost = 12000000,
				SpeedMultiplier = 2,
				Requires = { "BistroTables" },
				ButtonOffset = parlorPoint(Vector3.new(100, PARLOR_FLOOR, 60)),
				Visual = { Parts = parlorDippingCabinetParts() },
			},
			{
				Id = "Booths",
				DisplayName = "Booths",
				Cost = 20000000,
				PayoutMultiplier = 2,
				ButtonOffset = parlorPoint(Vector3.new(78, PARLOR_FLOOR, 86)),
				Visual = { Parts = parlorBoothParts() },
			},
			{
				Id = "ToppingsBar",
				DisplayName = "Toppings Bar",
				Cost = 35000000,
				PayoutMultiplier = 1.5,
				ButtonOffset = parlorPoint(Vector3.new(112, PARLOR_FLOOR, 46)),
				Visual = { Parts = parlorToppingsParts() },
			},
			{
				Id = "Awning",
				DisplayName = "Awning & Posters",
				Cost = 50000000,
				PayoutMultiplier = 1.5,
				ButtonOffset = parlorPoint(Vector3.new(48, 0, 84)),
				Visual = { Parts = parlorAwningParts() },
			},
			{
				Id = "Marquee",
				DisplayName = "Marquee Sign",
				Cost = 80000000,
				PayoutMultiplier = 2,
				ButtonOffset = parlorPoint(Vector3.new(48, 0, 52)),
				Visual = { Parts = parlorMarqueeParts() },
			},
			{
				Id = "Patio",
				DisplayName = "Patio Seating",
				Cost = 120000000,
				PayoutMultiplier = 1.5,
				ButtonOffset = parlorPoint(Vector3.new(38, 0, 88)),
				Visual = { Parts = parlorPatioParts() },
			},
			-- From here on: décor return sinks, priced for later tiers.
			{
				Id = "Loft",
				DisplayName = "Upstairs Loft",
				Cost = 200000000,
				PayoutMultiplier = 2,
				-- By the foot of the stairs.
				ButtonOffset = parlorPoint(Vector3.new(104, PARLOR_FLOOR, 84)),
				Visual = { Parts = parlorLoftParts() },
			},
			{
				Id = "Garden",
				DisplayName = "Garden",
				Cost = 350000000,
				PayoutMultiplier = 1.5,
				ButtonOffset = parlorPoint(Vector3.new(28, 0, 30)),
				Visual = { Parts = parlorGardenParts() },
			},
			{
				Id = "GiantSundae",
				DisplayName = "Giant Sundae",
				Cost = 600000000,
				PayoutMultiplier = 2,
				ButtonOffset = parlorPoint(Vector3.new(28, 0, 56)),
				Visual = { Parts = parlorSundaeParts() },
			},
		},
	},
	-- Placeholder so the Scooper cost ≈ next-unlock rule is visible. No Placement = not built.
	{
		Id = "DessertFactory",
		DisplayName = "Dessert Factory",
		-- = Scooper cost.
		UnlockCost = 8000000,
		UnlockRequires = { "Scooper" },
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
	-- Both vacant and claimed pads match the grass baseplate (boardwalk art later).
	Vacant = {
		Color = Color3.fromRGB(75, 154, 68),
		Material = Enum.Material.Grass,
	},
	Claimed = {
		Color = Color3.fromRGB(75, 154, 68),
		Material = Enum.Material.Grass,
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

-- Lawn regions (stand-space) that get 3D Grass mesh tufts. Holes = hardscape
-- (inflated in StandService by the mesh footprint so blades don't poke through).
TycoonConfig.PlotGrass.Regions = {
	{
		-- Parlor yard. Holes match hardscape footprints; StandService pads lightly
		-- by the mesh half-size so blades don't poke path/patio/parking.
		StationId = "Parlor",
		MinX = PARLOR_LAND.Left + 1,
		MaxX = PARLOR_LAND.Right - 1,
		MinZ = PARLOR_LAND.Front + 2,
		MaxZ = PARLOR_LAND.Back - 2,
		Holes = {
			-- Building + foundation apron.
			{
				MinX = PARLOR.Left - 2,
				MaxX = PARLOR.Right + 2,
				MinZ = PARLOR.Front - 2,
				MaxZ = PARLOR.Back + 2,
			},
			-- Customer parking (exact lot — leave the median to the walkway open).
			{
				MinX = PARLOR_LOT.Left,
				MaxX = PARLOR_LOT.Right + 1,
				MinZ = LOT_FRONT_Z - 1,
				MaxZ = 32.5,
			},
			-- Pink street walkway only (8 wide at X=40). Split from the door spur so
			-- the strip between path and parking still gets tufts.
			{
				MinX = 35.5,
				MaxX = 44.5,
				MinZ = LOT_FRONT_Z - 1,
				MaxZ = 74,
			},
			-- Door spur to the parlor entrance (8 wide at X=48).
			{
				MinX = 43.5,
				MaxX = 52.5,
				MinZ = 61,
				MaxZ = 75,
			},
			-- Patio deck + stools / planters.
			{
				MinX = 24,
				MaxX = 53,
				MinZ = 75,
				MaxZ = 101,
			},
			-- Sandwich board.
			{
				MinX = 44,
				MaxX = 50,
				MinZ = LOT_FRONT_Z - 1,
				MaxZ = 1,
			},
		},
	},
}

return TycoonConfig

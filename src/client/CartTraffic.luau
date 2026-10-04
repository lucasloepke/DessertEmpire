-- Decoration only: each sale at a station sends one of its parked vehicles
-- (models tagged Departs by the server) toward the street while it fades out,
-- then drives it back in. Models sharing a DepartGroup (every piece of the ice
-- cream truck, its driver included) move as one vehicle; DepartStation picks
-- whose sales move it (default: the station that owns the model). Local to
-- this client; never touches income.

local TweenService = game:GetService("TweenService")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared", 10)
assert(Shared, "Missing ReplicatedStorage.Shared")

local TycoonConfig = require(Shared:WaitForChild("TycoonConfig", 10))
local DropIn = require(script.Parent.DropIn)

local CartTraffic = {}

type Vehicle = {
	key: any,
	name: string,
	models: { Model },
}

-- Keyed by vehicle key: a lone model, or "<plot>/<group>" for grouped pieces.
local away: { [any]: boolean } = setmetatable({}, { __mode = "k" }) :: any
local lastDeparture: { [any]: number } = setmetatable({}, { __mode = "k" }) :: any
local nextIndex: { [Instance]: number } = setmetatable({}, { __mode = "k" }) :: any

local function owningStationId(model: Instance): string?
	local node = model.Parent
	while node do
		local id = node:GetAttribute("StationId")
		if typeof(id) == "string" then
			return id
		end
		node = node.Parent
	end
	return nil
end

local function driveOffAndBack(vehicle: Vehicle, direction: Vector3, distance: number)
	local cfg = TycoonConfig.CartTraffic
	away[vehicle.key] = true
	lastDeparture[vehicle.key] = os.clock()

	-- Parts move; decals (an NPC's face) fade with them.
	local parts, decals = {}, {}
	for _, model in ipairs(vehicle.models) do
		for _, descendant in ipairs(model:GetDescendants()) do
			if descendant:IsA("BasePart") then
				table.insert(parts, { part = descendant, cframe = descendant.CFrame, transparency = descendant.Transparency })
			elseif descendant:IsA("Decal") then
				table.insert(decals, { decal = descendant, transparency = descendant.Transparency })
			end
		end
	end
	local offset = direction.Unit * distance

	-- Leave: start rolling, fade out over the second half of the drive.
	local leave = TweenInfo.new(cfg.DriveTime, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
	local fadeOut = TweenInfo.new(cfg.DriveTime / 2, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, 0, false, cfg.DriveTime / 2)
	for _, entry in ipairs(parts) do
		TweenService:Create(entry.part, leave, { CFrame = entry.cframe + offset }):Play()
		TweenService:Create(entry.part, fadeOut, { Transparency = 1 }):Play()
	end
	for _, entry in ipairs(decals) do
		TweenService:Create(entry.decal, fadeOut, { Transparency = 1 }):Play()
	end
	task.wait(cfg.DriveTime + cfg.HiddenTime)

	-- Come back: reappear out by the street and roll into the spot.
	local arrive = TweenInfo.new(cfg.ReturnTime, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local fadeIn = TweenInfo.new(cfg.ReturnTime / 2, Enum.EasingStyle.Linear)
	for _, entry in ipairs(parts) do
		if entry.part.Parent then
			entry.part.CFrame = entry.cframe + offset
			TweenService:Create(entry.part, arrive, { CFrame = entry.cframe }):Play()
			TweenService:Create(entry.part, fadeIn, { Transparency = entry.transparency }):Play()
		end
	end
	for _, entry in ipairs(decals) do
		if entry.decal.Parent then
			TweenService:Create(entry.decal, fadeIn, { Transparency = entry.transparency }):Play()
		end
	end
	task.wait(cfg.ReturnTime)

	away[vehicle.key] = nil
end

-- Every vehicle this station's sales move, in a stable order.
local function vehiclesFor(stand: Instance, stationId: string): { Vehicle }
	local plot = stand.Parent
	if not plot then
		return {}
	end
	local byKey: { [any]: Vehicle } = {}
	local list = {}
	for _, descendant in ipairs(plot:GetDescendants()) do
		if descendant:IsA("Model") and descendant:GetAttribute("Departs") == true then
			local trigger = descendant:GetAttribute("DepartStation") or owningStationId(descendant)
			if trigger == stationId then
				local group = descendant:GetAttribute("DepartGroup")
				local key: any = if typeof(group) == "string" then plot:GetFullName() .. "/" .. group else descendant
				local vehicle = byKey[key]
				if not vehicle then
					vehicle = {
						key = key,
						-- Departing models are all named "Cart"; order by their upgrade's name.
						name = if typeof(key) == "string" then key else descendant:GetFullName(),
						models = {},
					}
					byKey[key] = vehicle
					table.insert(list, vehicle)
				end
				table.insert(vehicle.models, descendant)
			end
		end
	end
	table.sort(list, function(a, b)
		return a.name < b.name
	end)
	return list
end

local function ready(vehicle: Vehicle): boolean
	if away[vehicle.key] then
		return false
	end
	local first = vehicle.models[1]
	if typeof(first:GetAttribute("DepartDirection")) ~= "Vector3" then
		return false
	end
	local cooldown = first:GetAttribute("DepartCooldown")
	local last = lastDeparture[vehicle.key]
	if typeof(cooldown) == "number" and last and os.clock() - last < cooldown then
		return false
	end
	-- A piece still dropping in would record mid-air positions as "parked".
	for _, model in ipairs(vehicle.models) do
		if DropIn.isBusy(model) then
			return false
		end
	end
	return true
end

-- Called with the station model whenever it completes a sale.
function CartTraffic.onSale(stand: Instance)
	local stationId = stand:GetAttribute("StationId")
	if typeof(stationId) ~= "string" then
		return
	end

	local vehicles = vehiclesFor(stand, stationId)
	local awayCount = 0
	for _, vehicle in ipairs(vehicles) do
		if away[vehicle.key] then
			awayCount += 1
		end
	end
	local maxAway = TycoonConfig.CartTraffic.MaxAway
	for _, vehicle in ipairs(vehicles) do
		local custom = vehicle.models[1] and vehicle.models[1]:GetAttribute("DepartMaxAway")
		if typeof(custom) == "number" then
			maxAway = custom
			break
		end
	end
	if #vehicles == 0 or awayCount >= maxAway then
		return
	end

	-- Round-robin so every vehicle takes a turn.
	local start = nextIndex[stand] or 1
	for step = 0, #vehicles - 1 do
		local index = (start + step - 1) % #vehicles + 1
		local vehicle = vehicles[index]
		if ready(vehicle) then
			nextIndex[stand] = index % #vehicles + 1
			local first = vehicle.models[1]
			local distance = first:GetAttribute("DepartDistance")
			task.spawn(
				driveOffAndBack,
				vehicle,
				first:GetAttribute("DepartDirection"),
				if typeof(distance) == "number" then distance else TycoonConfig.CartTraffic.DriveDistance
			)
			return
		end
	end
end

return CartTraffic

-- Decoration only: each sale at a station sends one of its parked fleet carts
-- (models tagged Departs by the server, inside upgrade visuals) toward the street while it
-- fades out, then drives it back in. Local to this client; never touches income.

local TweenService = game:GetService("TweenService")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared", 10)
assert(Shared, "Missing ReplicatedStorage.Shared")

local TycoonConfig = require(Shared:WaitForChild("TycoonConfig", 10))
local DropIn = require(script.Parent.DropIn)

local CartTraffic = {}

local away: { [Model]: boolean } = setmetatable({}, { __mode = "k" }) :: any
local nextIndex: { [Instance]: number } = setmetatable({}, { __mode = "k" }) :: any

local function driveOffAndBack(cart: Model, direction: Vector3)
	local cfg = TycoonConfig.CartTraffic
	away[cart] = true

	local parts = {}
	for _, descendant in ipairs(cart:GetDescendants()) do
		if descendant:IsA("BasePart") then
			table.insert(parts, { part = descendant, cframe = descendant.CFrame, transparency = descendant.Transparency })
		end
	end
	local offset = direction.Unit * cfg.DriveDistance

	-- Leave: start rolling, fade out over the second half of the drive.
	local leave = TweenInfo.new(cfg.DriveTime, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
	local fadeOut = TweenInfo.new(cfg.DriveTime / 2, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, 0, false, cfg.DriveTime / 2)
	for _, entry in ipairs(parts) do
		TweenService:Create(entry.part, leave, { CFrame = entry.cframe + offset }):Play()
		TweenService:Create(entry.part, fadeOut, { Transparency = 1 }):Play()
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
	task.wait(cfg.ReturnTime)

	away[cart] = nil
end

-- Called with the station model whenever it completes a sale.
function CartTraffic.onSale(stand: Instance)
	local folder = stand:FindFirstChild("Upgrades")
	if not folder then
		return
	end

	local carts = {}
	local awayCount = 0
	for _, descendant in ipairs(folder:GetDescendants()) do
		-- A cart still dropping in would record mid-air positions as "parked".
		if descendant:IsA("Model") and descendant:GetAttribute("Departs") == true and not DropIn.isBusy(descendant) then
			table.insert(carts, descendant)
			if away[descendant] then
				awayCount += 1
			end
		end
	end
	if #carts == 0 or awayCount >= TycoonConfig.CartTraffic.MaxAway then
		return
	end
	-- Departing models are all named "Cart"; order by their upgrade's name.
	table.sort(carts, function(a, b)
		return a:GetFullName() < b:GetFullName()
	end)

	-- Round-robin so every cart takes a turn.
	local start = nextIndex[stand] or 1
	for step = 0, #carts - 1 do
		local index = (start + step - 1) % #carts + 1
		local cart = carts[index]
		local direction = cart:GetAttribute("DepartDirection")
		if not away[cart] and typeof(direction) == "Vector3" then
			nextIndex[stand] = index % #carts + 1
			task.spawn(driveOffAndBack, cart, direction)
			return
		end
	end
end

return CartTraffic

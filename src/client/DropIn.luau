-- Anything just bought/built (server tags it DropIn with a DropAt server time)
-- falls in from the sky, lands with a little hop, and calls onLand. Purely
-- visual and local: the server already placed it at its final spot.

local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared", 10)
assert(Shared, "Missing ReplicatedStorage.Shared")

local TycoonConfig = require(Shared:WaitForChild("TycoonConfig", 10))
local DropParts = require(Shared:WaitForChild("DropParts", 10))

local DropIn = {}

local busy: { [Instance]: boolean } = setmetatable({}, { __mode = "k" }) :: any

-- True while this instance (or anything it's inside) is still dropping in.
function DropIn.isBusy(instance: Instance): boolean
	local node: Instance? = instance
	while node do
		if busy[node] then
			return true
		end
		node = node.Parent
	end
	return false
end

--[[
	The tag can arrive before the model's children replicate, so wait (briefly)
	until the server-recorded DropParts count is here. Each part is lifted out of
	sight the moment it shows up, so nothing flashes at its final spot.
	Returns the parts and their final CFrames.
]]
local function gatherParts(root: Instance): ({ BasePart }, { CFrame })
	local parts, homes, seen = {}, {}, {}
	local lift = Vector3.new(0, TycoonConfig.DropIn.Height, 0)
	local function gather()
		for _, part in ipairs(DropParts.collect(root)) do
			if not seen[part] then
				seen[part] = true
				table.insert(parts, part)
				table.insert(homes, part.CFrame)
				part.CFrame += lift
			end
		end
	end

	gather()
	local expected = root:GetAttribute("DropParts")
	if typeof(expected) == "number" then
		local deadline = os.clock() + TycoonConfig.DropIn.ReplicationWait
		while #parts < expected and os.clock() < deadline and root.Parent do
			task.wait()
			gather()
		end
	end
	return parts, homes
end

-- Height above the final spot, t seconds after the drop starts.
local function heightAt(t: number): number
	local cfg = TycoonConfig.DropIn
	if t < 0 then
		return cfg.Height
	elseif t < cfg.FallTime then
		local u = t / cfg.FallTime
		return cfg.Height * (1 - u * u)
	end
	local b = t - cfg.FallTime
	if b < cfg.BounceTime then
		return cfg.BounceHeight * math.sin(math.pi * b / cfg.BounceTime)
	end
	return 0
end

local function landingPart(root: Instance, parts: { BasePart }): BasePart
	if root:IsA("Model") then
		local humanoidRoot = root:FindFirstChild("HumanoidRootPart")
		if humanoidRoot and humanoidRoot:IsA("BasePart") then
			return humanoidRoot
		end
		if root.PrimaryPart then
			return root.PrimaryPart
		end
	end
	return parts[1]
end

local function play(root: Instance, onLand: (Instance, BasePart) -> ())
	local cfg = TycoonConfig.DropIn
	local dropAt = root:GetAttribute("DropAt")
	if typeof(dropAt) ~= "number" or busy[root] then
		return
	end
	local delay = root:GetAttribute("DropDelay")
	local startAt = dropAt + (if typeof(delay) == "number" then delay else 0)
	if Workspace:GetServerTimeNow() - startAt > cfg.MaxLateness then
		return
	end

	busy[root] = true
	local parts, homes = gatherParts(root)
	if #parts == 0 or root.Parent == nil then
		busy[root] = nil
		return
	end
	local landOn = landingPart(root, parts)

	local function place(height: number)
		local lift = Vector3.new(0, height, 0)
		for index, part in ipairs(parts) do
			part.CFrame = homes[index] + lift
		end
	end

	place(heightAt(Workspace:GetServerTimeNow() - startAt))

	local landed = false
	local connection: RBXScriptConnection
	connection = RunService.RenderStepped:Connect(function()
		local t = Workspace:GetServerTimeNow() - startAt
		if root.Parent == nil then
			connection:Disconnect()
			busy[root] = nil
			return
		end
		place(heightAt(t))
		if not landed and t >= cfg.FallTime then
			landed = true
			onLand(root, landOn)
		end
		if t >= cfg.FallTime + cfg.BounceTime then
			connection:Disconnect()
			place(0)
			busy[root] = nil
		end
	end)
end

-- onLand(root, part): root just touched down; part is where to play a sound.
function DropIn.start(onLand: (Instance, BasePart) -> ())
	local tag = TycoonConfig.Tags.DropIn
	-- play may yield while parts replicate, so each drop gets its own thread.
	CollectionService:GetInstanceAddedSignal(tag):Connect(function(instance)
		task.spawn(play, instance, onLand)
	end)
	for _, instance in ipairs(CollectionService:GetTagged(tag)) do
		task.spawn(play, instance, onLand)
	end
end

return DropIn

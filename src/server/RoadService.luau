-- Tiles Creator Store Road along the street at runtime ONLY if the place
-- does not already contain baked RoadSegments (from tools/bake_plots.py).

local ServerStorage = game:GetService("ServerStorage")
local Workspace = game:GetService("Workspace")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared", 10)
assert(Shared, "Missing ReplicatedStorage.Shared")

local TycoonConfig = require(Shared:WaitForChild("TycoonConfig", 10))

local RoadService = {}

local function getSize(inst: Instance): Vector3?
	if inst:IsA("Model") then
		return inst:GetExtentsSize()
	elseif inst:IsA("BasePart") then
		return inst.Size
	end
	return nil
end

local function pivotTo(inst: Instance, cf: CFrame)
	if inst:IsA("Model") then
		inst:PivotTo(cf)
	elseif inst:IsA("BasePart") then
		inst.CFrame = cf
	end
end

local function anchorAll(inst: Instance)
	for _, desc in ipairs(inst:GetDescendants()) do
		if desc:IsA("BasePart") then
			desc.Anchored = true
		end
	end
	if inst:IsA("BasePart") then
		inst.Anchored = true
	end
end

local function getStreet(): (Model?, BasePart?)
	local plots = Workspace:FindFirstChild("Plots")
	local street = plots and plots:FindFirstChild("Street")
	if not (street and street:IsA("Model")) then
		return nil, nil
	end
	local pavement = street:FindFirstChild("Pavement")
	if pavement and pavement:IsA("BasePart") then
		return street, pavement
	end
	return street, nil
end

local function findBakedSegments(): Folder?
	local street = getStreet()
	if not street then
		return nil
	end
	local folder = street:FindFirstChild("RoadSegments")
	if folder and folder:IsA("Folder") and #folder:GetChildren() > 0 then
		return folder
	end
	return nil
end

local function ensureTemplate(): Instance?
	local cfg = TycoonConfig.Road

	local existing = ServerStorage:FindFirstChild("RoadTemplate")
	if existing then
		return existing
	end

	-- Baked project template (preferred once exported into the Rojo tree).
	local sharedTemplate = game:GetService("ReplicatedStorage"):FindFirstChild("RoadTemplate")
	if sharedTemplate then
		local clone = sharedTemplate:Clone()
		clone.Name = "RoadTemplate"
		clone.Parent = ServerStorage
		anchorAll(clone)
		return clone
	end

	local live = Workspace:FindFirstChild(cfg.TemplateName)
	if not live then
		warn(string.format(
			"[RoadService] No baked roads and no Workspace.%s. Export the road to assets/Road.rbxm and rebake.",
			cfg.TemplateName
		))
		return nil
	end

	live.Name = "RoadTemplate"
	live.Parent = ServerStorage
	anchorAll(live)
	return live
end

local function ensureEmptySegmentsFolder(street: Model): Folder
	local folder = street:FindFirstChild("RoadSegments")
	if folder and folder:IsA("Folder") then
		return folder
	end
	if folder then
		folder:Destroy()
	end
	folder = Instance.new("Folder")
	folder.Name = "RoadSegments"
	folder.Parent = street
	return folder
end

function RoadService.tileAlongStreet()
	local street, pavement = getStreet()
	if not street or not pavement then
		warn("[RoadService] Missing Plots.Street.Pavement")
		return 0
	end

	-- Place-file bake wins: do not rebuild or clear.
	if findBakedSegments() then
		pavement.Transparency = 1
		print("[RoadService] Using baked RoadSegments from place file.")
		return 0
	end

	local cfg = TycoonConfig.Road
	local template = ensureTemplate()
	if not template then
		return 0
	end

	local size = getSize(template)
	if not size then
		warn("[RoadService] Road template has no size")
		return 0
	end

	local yaw = 0
	local tileLength = size.X
	if size.Z > size.X then
		yaw = math.rad(90)
		tileLength = size.Z
	end

	if tileLength < 1 then
		warn("[RoadService] Road tile length too small:", tileLength)
		return 0
	end

	local step = math.max(tileLength - cfg.Overlap, tileLength * 0.5)
	local streetLength = pavement.Size.X
	local y = if typeof(cfg.Y) == "number"
		then cfg.Y + cfg.YOffset
		else pavement.Position.Y + pavement.Size.Y / 2 + cfg.YOffset + size.Y / 2

	local folder = ensureEmptySegmentsFolder(street)
	folder:ClearAllChildren()

	local count = 0
	local startX = -streetLength / 2 + tileLength / 2
	local endX = streetLength / 2 - tileLength / 2
	local x = startX
	while x <= endX + 0.01 do
		local clone = template:Clone()
		clone.Name = string.format("Road_%02d", count + 1)
		pivotTo(clone, CFrame.new(x, y, 0) * CFrame.Angles(0, yaw, 0))
		anchorAll(clone)
		clone.Parent = folder
		count += 1
		x += step
	end

	pavement.Transparency = 1
	print(string.format(
		"[RoadService] Runtime-tiled %d segments (tile=%.1f). Export assets/Road.rbxm to bake into the place.",
		count,
		tileLength
	))
	return count
end

return RoadService

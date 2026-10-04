local Workspace = game:GetService("Workspace")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared", 10)
assert(Shared, "Missing ReplicatedStorage.Shared")

local TycoonConfig = require(Shared:WaitForChild("TycoonConfig", 10))

local PlotService = {}

local PLOT_NAME_PATTERN = "^Plot%s*(%d+)$"

type PlotRecord = {
	index: number,
	model: Model,
	pad: BasePart,
	spawn: SpawnLocation,
	side: "North" | "South",
	owner: Player?,
}

local plotsByIndex: { [number]: PlotRecord } = {}
local plotsByPlayer: { [Player]: PlotRecord } = {}

local function studsAllAround(part: BasePart)
	part.TopSurface = Enum.SurfaceType.Studs
	part.BottomSurface = Enum.SurfaceType.Studs
	part.LeftSurface = Enum.SurfaceType.Studs
	part.RightSurface = Enum.SurfaceType.Studs
	part.FrontSurface = Enum.SurfaceType.Studs
	part.BackSurface = Enum.SurfaceType.Studs
end

local function smoothAllAround(part: BasePart)
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.LeftSurface = Enum.SurfaceType.Smooth
	part.RightSurface = Enum.SurfaceType.Smooth
	part.FrontSurface = Enum.SurfaceType.Smooth
	part.BackSurface = Enum.SurfaceType.Smooth
end

local function applyPadAppearance(pad: BasePart, claimed: boolean)
	local look = if claimed then TycoonConfig.Plots.Claimed else TycoonConfig.Plots.Vacant
	pad.Color = look.Color
	pad.Material = look.Material
	if claimed then
		studsAllAround(pad)
	else
		smoothAllAround(pad)
	end
end

local function registerPlot(model: Model)
	local indexStr = string.match(model.Name, PLOT_NAME_PATTERN)
	if not indexStr then
		return
	end
	local index = tonumber(indexStr)
	if not index then
		return
	end

	local pad = model:FindFirstChild("Pad")
	if not (pad and pad:IsA("BasePart")) then
		warn("[PlotService] " .. model.Name .. " is missing Pad part")
		return
	end

	local spawn = model:FindFirstChild("Spawn")
	if not (spawn and spawn:IsA("SpawnLocation")) then
		warn("[PlotService] " .. model.Name .. " is missing SpawnLocation")
		return
	end

	local sideValue = model:FindFirstChild("Side")
	local side: "North" | "South" = "North"
	if sideValue and sideValue:IsA("StringValue") and sideValue.Value == "South" then
		side = "South"
	elseif pad.Position.Z < 0 then
		side = "South"
	end

	model.PrimaryPart = pad
	spawn.Enabled = false
	-- Must be Neutral for RespawnLocation / LoadCharacter to honor it when
	-- the player has no matching TeamColor (otherwise HubSpawn wins).
	spawn.Neutral = true
	applyPadAppearance(pad, false)
	model:SetAttribute("OwnerUserId", nil)
	model:SetAttribute("OwnerName", nil)

	plotsByIndex[index] = {
		index = index,
		model = model,
		pad = pad,
		spawn = spawn,
		side = side,
		owner = nil,
	}
end

local function getHubSpawn(): SpawnLocation?
	local folder = Workspace:FindFirstChild("Plots")
	if not (folder and folder:IsA("Folder")) then
		return nil
	end
	local street = folder:FindFirstChild("Street")
	if not (street and street:IsA("Model")) then
		return nil
	end
	local hub = street:FindFirstChild("HubSpawn")
	if hub and hub:IsA("SpawnLocation") then
		return hub
	end
	return nil
end

--[[
	Plots live in the place file under Workspace.Plots (empty pads + street).
	Runtime only discovers them and populates ownership / stands — it does not
	rebuild geometry.
]]
function PlotService.init()
	table.clear(plotsByIndex)
	table.clear(plotsByPlayer)

	local folder = Workspace:FindFirstChild("Plots")
	assert(folder and folder:IsA("Folder"), "Missing Workspace.Plots folder (place layout)")

	local expected = TycoonConfig.Plots.CountPerSide * 2

	for _, child in ipairs(folder:GetChildren()) do
		if child:IsA("Model") and string.match(child.Name, PLOT_NAME_PATTERN) then
			registerPlot(child)
		end
	end

	local found = 0
	for _ in pairs(plotsByIndex) do
		found += 1
	end

	assert(
		found > 0,
		"Workspace.Plots has no Plot models matching ^Plot%s*(%d+)$"
	)
	if found ~= expected then
		warn(string.format(
			"[PlotService] Expected %d plots in config, found %d in Workspace.Plots.",
			expected,
			found
		))
	end

	-- Hub is fallback-only; keep it off so it cannot steal RespawnLocation.
	local hub = getHubSpawn()
	if hub then
		hub.Enabled = false
		hub.Neutral = true
	end

	print(string.format("[PlotService] Registered %d plots from place file.", found))
end

function PlotService.getSpawnForPlayer(player: Player): SpawnLocation?
	local record = plotsByPlayer[player]
	return if record then record.spawn else nil
end

--[[
	Place the character at their plot spawn (or hub). Call after LoadCharacter
	so spawn is correct even if RespawnLocation was ignored.
]]
function PlotService.moveCharacterToPlot(player: Player)
	local character = player.Character
	if not character then
		return
	end

	local spawn = PlotService.getSpawnForPlayer(player) or getHubSpawn()
	if not spawn then
		return
	end

	local root = character:WaitForChild("HumanoidRootPart", 5)
	if not root then
		return
	end

	-- Stand on top of the sidewalk spawn, facing its LookVector (into the plot).
	local target = spawn.CFrame + Vector3.new(0, 3, 0)
	character:PivotTo(target)
end

function PlotService.useHubSpawn(player: Player)
	local hub = getHubSpawn()
	if not hub then
		return
	end
	hub.Enabled = true
	hub.Neutral = true
	player.RespawnLocation = hub
end

function PlotService.getPlotCount(): number
	local n = 0
	for _ in pairs(plotsByIndex) do
		n += 1
	end
	return n
end

function PlotService.getPlotForPlayer(player: Player): Model?
	local record = plotsByPlayer[player]
	return if record then record.model else nil
end

function PlotService.assign(player: Player): Model?
	if plotsByPlayer[player] then
		return plotsByPlayer[player].model
	end

	local free: PlotRecord? = nil
	local maxIndex = 0
	for index in pairs(plotsByIndex) do
		if index > maxIndex then
			maxIndex = index
		end
	end

	for index = 1, maxIndex do
		local record = plotsByIndex[index]
		if record and record.owner == nil then
			free = record
			break
		end
	end

	if not free then
		warn("[PlotService] No free plots for " .. player.Name)
		return nil
	end

	free.owner = player
	plotsByPlayer[player] = free
	free.spawn.Enabled = true
	free.spawn.Neutral = true
	applyPadAppearance(free.pad, true)
	free.model:SetAttribute("OwnerUserId", player.UserId)
	free.model:SetAttribute("OwnerName", player.Name)

	player:SetAttribute("PlotIndex", free.index)

	local plotValue = player:FindFirstChild("Plot")
	if not (plotValue and plotValue:IsA("ObjectValue")) then
		if plotValue then
			plotValue:Destroy()
		end
		plotValue = Instance.new("ObjectValue")
		plotValue.Name = "Plot"
		plotValue.Parent = player
	end
	(plotValue :: ObjectValue).Value = free.model

	player.RespawnLocation = free.spawn

	return free.model
end

function PlotService.release(player: Player)
	local record = plotsByPlayer[player]
	if not record then
		return
	end

	record.owner = nil
	record.spawn.Enabled = false
	record.spawn.Neutral = true
	applyPadAppearance(record.pad, false)
	record.model:SetAttribute("OwnerUserId", nil)
	record.model:SetAttribute("OwnerName", nil)
	plotsByPlayer[player] = nil

	player:SetAttribute("PlotIndex", nil)
	player.RespawnLocation = nil

	local plotValue = player:FindFirstChild("Plot")
	if plotValue and plotValue:IsA("ObjectValue") then
		plotValue.Value = nil
	end
end

return PlotService

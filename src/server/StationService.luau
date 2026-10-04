-- Server-authoritative station loop: SELL → bar runs duration → pays payout.
-- Automation is the same loop restarting itself the moment a cycle completes.
-- Spend flow per station: panel UPGRADE (repeatable, via remote) and
-- physical upgrades (in order, via the walk-on floor button).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared", 10)
assert(Shared, "Missing ReplicatedStorage.Shared")

local TycoonConfig = require(Shared:WaitForChild("TycoonConfig", 10))
local StationMath = require(Shared:WaitForChild("StationMath", 10))

local DataService = require(script.Parent.DataService)
local StandService = require(script.Parent.StandService)

local StationService = {}

type State = {
	stand: Model,
	counter: BasePart,
	config: any,
	busy: boolean,
	-- Bumped per cycle so a stale task.delay from a detached session is ignored.
	token: number,
}

local states: { [Player]: State } = {}

local function stationData(player: Player, stationId: string)
	local data = DataService.get(player)
	return if data then data.stations[stationId] else nil
end

-- Everything the client panel draws comes from these attributes.
local function syncAttributes(state: State, station: any)
	local config = state.config
	state.stand:SetAttribute("Payout", StationMath.payout(config, station))
	state.stand:SetAttribute("Duration", StationMath.duration(config, station))
	state.stand:SetAttribute("Level", station.level)
	state.stand:SetAttribute("UpgradeCost", StationMath.upgradeCost(config, station.level))
	state.stand:SetAttribute("Automated", StationMath.isAutomated(config, station))
end

local completeCycle: (Player, State) -> ()

local function beginCycle(player: Player, state: State)
	local station = stationData(player, state.config.Id)
	if not station then
		return
	end

	state.busy = true
	state.token += 1
	local token = state.token
	local duration = StationMath.duration(state.config, station)

	-- Client draws the bar from these; server time keeps every client in sync.
	local now = Workspace:GetServerTimeNow()
	state.stand:SetAttribute("CycleStartedAt", now)
	state.stand:SetAttribute("CycleEndsAt", now + duration)

	task.delay(duration, function()
		if states[player] == state and state.token == token then
			completeCycle(player, state)
		end
	end)
end

completeCycle = function(player: Player, state: State)
	local station = stationData(player, state.config.Id)
	if not station then
		return
	end

	state.busy = false
	DataService.addCash(player, StationMath.payout(state.config, station))
	state.stand:SetAttribute("SaleCount", (state.stand:GetAttribute("SaleCount") or 0) + 1)

	if StationMath.isAutomated(state.config, station) then
		beginCycle(player, state)
	end
end

local function noteUpgrade(state: State)
	state.stand:SetAttribute("UpgradeCount", (state.stand:GetAttribute("UpgradeCount") or 0) + 1)
end

local function buyPanelUpgrade(player: Player, state: State, station: any)
	local cost = StationMath.upgradeCost(state.config, station.level)
	if not DataService.trySpend(player, cost) then
		return
	end
	station.level += 1
	DataService.markDirty(player)
	syncAttributes(state, station)
	noteUpgrade(state)
end

local function onStationAction(player: Player, action: any, stationId: any)
	if (action ~= "Sell" and action ~= "Upgrade") or typeof(stationId) ~= "string" then
		return
	end

	-- Ownership: a player only ever has state for the stand on their own plot.
	local state = states[player]
	if not state or state.config.Id ~= stationId then
		return
	end

	local station = stationData(player, stationId)
	if not station or not station.unlocked then
		return
	end

	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not (root and root:IsA("BasePart")) then
		return
	end
	local maxDistance = TycoonConfig.StationInteractDistance + TycoonConfig.StationInteractSlack
	if (root.Position - state.counter.Position).Magnitude > maxDistance then
		return
	end

	if action == "Sell" then
		if not state.busy and not StationMath.isAutomated(state.config, station) then
			beginCycle(player, state)
		end
	else
		buyPanelUpgrade(player, state, station)
	end
end

local function buyPhysical(player: Player, state: State, upgradeId: string): boolean
	local station = stationData(player, state.config.Id)
	if not station or station.owned[upgradeId] then
		return false
	end

	local upgrade = nil
	for _, entry in ipairs(StationMath.availablePhysical(state.config, station)) do
		if entry.Id == upgradeId then
			upgrade = entry
			break
		end
	end
	if not upgrade or not DataService.trySpend(player, upgrade.Cost) then
		return false
	end

	station.owned[upgrade.Id] = true
	DataService.markDirty(player)
	syncAttributes(state, station)
	StandService.refresh(player)
	noteUpgrade(state)

	-- A running manual cycle chains into automation when it completes.
	if upgrade.Automates and not state.busy then
		beginCycle(player, state)
	end
	return true
end

local function horizontalDistance(a: Vector3, b: Vector3): number
	return Vector2.new(a.X - b.X, a.Z - b.Z).Magnitude
end

--[[
	Walk-on purchase: only the plot owner's character can trigger it. After a
	successful buy the button disarms until the player steps off it, so one
	step can't chain through several upgrades.
]]
local function bindButton(player: Player, state: State, button: Model, onPress: () -> boolean)
	local center = button.PrimaryPart
	if not center then
		return
	end
	local armed = true

	local function onTouched(hit: BasePart)
		if not armed then
			return
		end
		local character = player.Character
		if not character or not hit:IsDescendantOf(character) then
			return
		end
		if not onPress() then
			return
		end

		armed = false
		task.spawn(function()
			local rearmDistance = TycoonConfig.Interact.Button.RearmDistance
			while states[player] == state and button.Parent and player.Character == character do
				local root = character:FindFirstChild("HumanoidRootPart")
				if not (root and root:IsA("BasePart")) then
					break
				end
				if horizontalDistance(root.Position, center.Position) > rearmDistance then
					break
				end
				task.wait(0.2)
			end
			armed = true
		end)
	end

	for _, partName in ipairs({ "Base", "Pad" }) do
		local part = button:FindFirstChild(partName)
		if part and part:IsA("BasePart") then
			part.Touched:Connect(onTouched)
		end
	end
end

local function bindPhysicalButton(player: Player, state: State, button: Model)
	if button:GetAttribute("Kind") ~= "PhysicalUpgrade" then
		return
	end
	local upgradeId = button:GetAttribute("UpgradeId")
	if typeof(upgradeId) ~= "string" then
		return
	end
	if button:GetAttribute("Bound") == true then
		return
	end
	button:SetAttribute("Bound", true)
	bindButton(player, state, button, function()
		return buyPhysical(player, state, upgradeId)
	end)
end

function StationService.init()
	local folder = ReplicatedStorage:FindFirstChild(TycoonConfig.Remotes.Folder)
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = TycoonConfig.Remotes.Folder
		folder.Parent = ReplicatedStorage
	end

	local remote = Instance.new("RemoteEvent")
	remote.Name = TycoonConfig.Remotes.StationAction
	remote.Parent = folder
	remote.OnServerEvent:Connect(onStationAction)
end

function StationService.attach(player: Player, stand: Model)
	StationService.detach(player)

	local config = StationMath.findStation(stand:GetAttribute("StationId") or "")
	local counter = stand:FindFirstChild("Counter")
	local station = config and stationData(player, config.Id)
	if not (config and station and counter and counter:IsA("BasePart")) then
		warn("[StationService] Cannot attach station for " .. player.Name)
		return
	end

	local state: State = {
		stand = stand,
		counter = counter,
		config = config,
		busy = false,
		token = 0,
	}
	states[player] = state

	stand:SetAttribute("DisplayName", config.DisplayName)
	stand:SetAttribute("SaleCount", 0)
	stand:SetAttribute("UpgradeCount", 0)
	stand:SetAttribute("CycleStartedAt", 0)
	stand:SetAttribute("CycleEndsAt", 0)
	syncAttributes(state, station)

	for _, child in ipairs(stand:GetChildren()) do
		if child:IsA("Model") then
			bindPhysicalButton(player, state, child)
		end
	end
	stand.ChildAdded:Connect(function(child)
		if states[player] == state and child:IsA("Model") then
			bindPhysicalButton(player, state, child)
		end
	end)

	if StationMath.isAutomated(config, station) then
		beginCycle(player, state)
	end
end

function StationService.detach(player: Player)
	states[player] = nil
end

return StationService

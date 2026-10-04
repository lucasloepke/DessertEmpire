-- Temporary debug remotes: reset progress / grant cash.
-- Client buttons only appear when AdminEnabled is set; server re-checks every request.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared", 10)
assert(Shared, "Missing ReplicatedStorage.Shared")

local TycoonConfig = require(Shared:WaitForChild("TycoonConfig", 10))

local DataService = require(script.Parent.DataService)
local PlotService = require(script.Parent.PlotService)
local StandService = require(script.Parent.StandService)
local StationService = require(script.Parent.StationService)

local AdminService = {}

local function isListedAdmin(userId: number): boolean
	for _, id in ipairs(TycoonConfig.Admin.UserIds) do
		if id == userId then
			return true
		end
	end
	return false
end

local function isAdmin(player: Player): boolean
	if RunService:IsStudio() then
		return true
	end
	if game.CreatorType == Enum.CreatorType.User and player.UserId == game.CreatorId then
		return true
	end
	return isListedAdmin(player.UserId)
end

local function grantFlag(player: Player)
	player:SetAttribute("AdminEnabled", isAdmin(player))
end

local function resetProgress(player: Player)
	StationService.detach(player)
	StandService.clear(player)

	if not DataService.resetProgress(player) then
		return
	end
	DataService.save(player)

	local plot = PlotService.getPlotForPlayer(player)
	local data = DataService.get(player)
	if not (plot and data) then
		return
	end

	for _, stand in ipairs(StandService.build(player, plot, data)) do
		StationService.attach(player, stand)
	end
end

local function onAdminAction(player: Player, action: any)
	if not isAdmin(player) then
		return
	end
	if action == "ResetProgress" then
		resetProgress(player)
	elseif action == "AddCash" then
		DataService.addCash(player, TycoonConfig.Admin.AddCashAmount)
	elseif action == "AddCashLarge" then
		DataService.addCash(player, TycoonConfig.Admin.AddCashAmountLarge)
	end
end

function AdminService.init()
	local folder = ReplicatedStorage:FindFirstChild(TycoonConfig.Remotes.Folder)
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = TycoonConfig.Remotes.Folder
		folder.Parent = ReplicatedStorage
	end

	local existing = folder:FindFirstChild(TycoonConfig.Remotes.AdminAction)
	if existing then
		existing:Destroy()
	end

	local remote = Instance.new("RemoteEvent")
	remote.Name = TycoonConfig.Remotes.AdminAction
	remote.Parent = folder
	remote.OnServerEvent:Connect(onAdminAction)

	Players.PlayerAdded:Connect(grantFlag)
	for _, player in ipairs(Players:GetPlayers()) do
		grantFlag(player)
	end
end

return AdminService

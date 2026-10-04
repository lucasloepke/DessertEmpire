local Players = game:GetService("Players")

Players.CharacterAutoLoads = false

local DataService = require(script.DataService)
local PlotService = require(script.PlotService)
local StandService = require(script.StandService)
local StationService = require(script.StationService)
local RoadService = require(script.RoadService)
local AdminService = require(script.AdminService)

PlotService.init()
StationService.init()
AdminService.init()
RoadService.tileAlongStreet()
DataService.bindAutoSave(60)

local function onPlayerAdded(player: Player)
	-- Join order: load data → assign plot → build station → LoadCharacter.
	-- A hang anywhere before LoadCharacter leaves the player on a grey screen.
	local loadOk, data = DataService.load(player)
	if not loadOk then
		warn("[TycoonServer] Playing unsaved session for " .. player.Name)
	end

	-- Always teleport on spawn/respawn so HubSpawn cannot steal placement.
	player.CharacterAdded:Connect(function()
		PlotService.moveCharacterToPlot(player)
	end)

	local plot = PlotService.assign(player)
	if not plot then
		warn("[TycoonServer] No plot for " .. player.Name .. "; loading at hub spawn.")
		PlotService.useHubSpawn(player)
		player:LoadCharacter()
		return
	end

	local stand = StandService.build(player, plot, data or DataService.get(player))
	if stand then
		StationService.attach(player, stand)
	end

	player:LoadCharacter()
end

local function onPlayerRemoving(player: Player)
	DataService.save(player)
	StationService.detach(player)
	StandService.clear(player)
	PlotService.release(player)
	DataService.release(player)
end

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)

for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(onPlayerAdded, player)
end

game:BindToClose(function()
	for _, player in ipairs(Players:GetPlayers()) do
		DataService.save(player)
	end
end)

print("[TycoonServer] Ready.")

local Players = game:GetService("Players")

Players.CharacterAutoLoads = false

local DataService = require(script.DataService)
local PlotService = require(script.PlotService)
local StandService = require(script.StandService)
local RoadService = require(script.RoadService)

PlotService.init()
RoadService.tileAlongStreet()
DataService.bindAutoSave(60)

local function onPlayerAdded(player: Player)
	-- Join order: load data → assign plot → build station → LoadCharacter.
	-- A hang anywhere before LoadCharacter leaves the player on a grey screen.
	local loadOk = DataService.load(player)
	if not loadOk then
		warn("[TycoonServer] Playing unsaved session for " .. player.Name)
	end

	local plot = PlotService.assign(player)
	if not plot then
		warn("[TycoonServer] No plot for " .. player.Name .. "; loading at hub spawn.")
		player:LoadCharacter()
		return
	end

	local data = DataService.get(player)
	StandService.build(player, plot, data)

	player:LoadCharacter()
end

local function onPlayerRemoving(player: Player)
	DataService.save(player)
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

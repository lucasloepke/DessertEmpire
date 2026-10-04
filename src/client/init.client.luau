local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared", 10)
assert(Shared, "Missing ReplicatedStorage.Shared")
local TycoonConfig = require(Shared:WaitForChild("TycoonConfig", 10))

local AdminHud = require(script.AdminHud)
local Audio = require(script.Audio)
local CartTraffic = require(script.CartTraffic)
local DropIn = require(script.DropIn)
local Hud = require(script.Hud)
local NpcChatter = require(script.NpcChatter)
local Sprint = require(script.Sprint)
local StationPanel = require(script.StationPanel)

Audio.start()
Sprint.start()
-- Everything lands with the block sound; NPCs also shout a louder voice line.
DropIn.start(function(root: Instance, at: BasePart)
	Audio.playPlace(at)
	if root:FindFirstChildOfClass("Humanoid") then
		Audio.playNpc(at, TycoonConfig.Audio.NpcPurchaseVolume)
	end
end)
NpcChatter.start(function(at: BasePart)
	Audio.playNpc(at)
end)
Hud.start({
	getMusicVolume = Audio.getMusicVolume,
	setMusicVolume = Audio.setMusicVolume,
})
AdminHud.start()
StationPanel.start(function(counter: BasePart)
	Audio.playSale(counter)
	if counter.Parent then
		CartTraffic.onSale(counter.Parent)
	end
end, Audio.playUpgrade)

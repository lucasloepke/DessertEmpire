local AdminHud = require(script.AdminHud)
local Audio = require(script.Audio)
local Hud = require(script.Hud)
local StationPanel = require(script.StationPanel)

Audio.start()
Hud.start({
	isMusicMuted = Audio.isMusicMuted,
	toggleMusicMute = Audio.toggleMusicMute,
})
AdminHud.start()
StationPanel.start(Audio.playSale, Audio.playUpgrade)

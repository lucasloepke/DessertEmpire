local Audio = require(script.Audio)
local HologramVisibility = require(script.HologramVisibility)
local Hud = require(script.Hud)
local StationPanel = require(script.StationPanel)

Audio.start()
Hud.start({
	isMusicMuted = Audio.isMusicMuted,
	toggleMusicMute = Audio.toggleMusicMute,
})
HologramVisibility.start()
StationPanel.start(Audio.playSale, Audio.playUpgrade)

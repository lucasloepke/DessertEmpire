local Audio = require(script.Audio)
local HologramVisibility = require(script.HologramVisibility)
local Hud = require(script.Hud)
local StationPanel = require(script.StationPanel)

Hud.start()
Audio.start()
HologramVisibility.start()
StationPanel.start(Audio.playSale)

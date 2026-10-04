-- Background music + positional sale / upgrade sounds. Ids live in TycoonConfig.Audio.
-- Failed loads are warned about so a wrong Creator Store id isn't silent.

local ContentProvider = game:GetService("ContentProvider")
local Debris = game:GetService("Debris")
local SoundService = game:GetService("SoundService")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared", 10)
assert(Shared, "Missing ReplicatedStorage.Shared")

local TycoonConfig = require(Shared:WaitForChild("TycoonConfig", 10))

local Audio = {}

local saleTemplate: Sound? = nil
local upgradeTemplate: Sound? = nil
local music: Sound? = nil
local musicMuted = false
local onMuteChanged: ((boolean) -> ())? = nil

local function verifyLoads(sound: Sound, configKey: string)
	task.spawn(function()
		ContentProvider:PreloadAsync({ sound }, function(assetId: string, status: Enum.AssetFetchStatus)
			if status == Enum.AssetFetchStatus.Failure then
				warn(string.format("[Audio] TycoonConfig.Audio.%s failed to load (%s).", configKey, assetId))
			end
		end)
	end)
end

local function makeTemplate(name: string, soundId: string, volume: number, rollOff: number, configKey: string): Sound
	local sound = Instance.new("Sound")
	sound.Name = name
	sound.SoundId = soundId
	sound.Volume = volume
	sound.RollOffMaxDistance = rollOff
	sound.Parent = SoundService
	verifyLoads(sound, configKey)
	return sound
end

local function playClone(template: Sound?, at: BasePart, pitchJitter: number?)
	if not template then
		return
	end
	local sound = template:Clone()
	if pitchJitter and pitchJitter > 0 then
		sound.PlaybackSpeed = 1 + (math.random() * 2 - 1) * pitchJitter
	end
	sound.Parent = at
	sound:Play()
	Debris:AddItem(sound, 5)
end

local function applyMusicMute()
	if not music then
		return
	end
	if musicMuted then
		music.Volume = 0
		music:Pause()
	else
		music.Volume = TycoonConfig.Audio.MusicVolume
		if not music.IsPlaying then
			music:Resume()
			if not music.IsPlaying then
				music:Play()
			end
		end
	end
end

function Audio.start()
	local cfg = TycoonConfig.Audio

	if cfg.SaleSoundId ~= "" then
		saleTemplate = makeTemplate(
			"SaleSoundTemplate",
			cfg.SaleSoundId,
			cfg.SaleVolume,
			cfg.SaleRollOffMaxDistance,
			"SaleSoundId"
		)
	end

	if cfg.UpgradeSoundId ~= "" then
		upgradeTemplate = makeTemplate(
			"UpgradeSoundTemplate",
			cfg.UpgradeSoundId,
			cfg.UpgradeVolume,
			cfg.UpgradeRollOffMaxDistance,
			"UpgradeSoundId"
		)
	end

	if cfg.MusicId == "" then
		warn("[Audio] TycoonConfig.Audio.MusicId is empty; no background music.")
		return
	end

	local track = Instance.new("Sound")
	track.Name = "Music"
	track.SoundId = cfg.MusicId
	track.Volume = cfg.MusicVolume
	track.Looped = true
	track.Parent = SoundService
	verifyLoads(track, "MusicId")
	music = track
	applyMusicMute()
	track:Play()
end

-- Positional, so automated stations get quieter as you walk away.
function Audio.playSale(at: BasePart)
	playClone(saleTemplate, at, TycoonConfig.Audio.SalePitchJitter)
end

function Audio.playUpgrade(at: BasePart)
	playClone(upgradeTemplate, at, nil)
end

function Audio.isMusicMuted(): boolean
	return musicMuted
end

function Audio.setMusicMuted(muted: boolean)
	musicMuted = muted
	applyMusicMute()
	if onMuteChanged then
		onMuteChanged(muted)
	end
end

function Audio.toggleMusicMute(): boolean
	Audio.setMusicMuted(not musicMuted)
	return musicMuted
end

function Audio.onMusicMuteChanged(callback: (boolean) -> ())
	onMuteChanged = callback
end

return Audio

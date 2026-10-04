-- Background music (shuffles Workspace.Sounds.Music) + positional sale / upgrade.
-- Failed loads are warned about so a wrong asset id isn't silent.

local ContentProvider = game:GetService("ContentProvider")
local Debris = game:GetService("Debris")
local SoundService = game:GetService("SoundService")
local Workspace = game:GetService("Workspace")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared", 10)
assert(Shared, "Missing ReplicatedStorage.Shared")

local TycoonConfig = require(Shared:WaitForChild("TycoonConfig", 10))

local Audio = {}

local saleTemplate: Sound? = nil
local upgradeTemplate: Sound? = nil
local placeTemplate: Sound? = nil
local npcTemplates: { Sound } = {}
local music: Sound? = nil

-- 0 = silent, 1 = TycoonConfig.Audio.MusicVolume.
local musicVolumeLevel = 1
local onVolumeChanged: ((number) -> ())? = nil

type Track = { id: string, name: string }
local playlist: { Track } = {}
local shuffleOrder: { number } = {}
local shuffleIndex = 1
local lastTrackName: string? = nil
-- Bumps whenever a new track starts so stale load/play threads bail out.
local musicGeneration = 0
local musicAdvancing = false

-- How long to wait for a track asset before skipping it.
local MUSIC_LOAD_TIMEOUT = 12
-- If nothing is playing this long after a track should have started, advance.
local MUSIC_STALL_SECONDS = 3

local function verifyLoads(sound: Sound, configKey: string)
	task.spawn(function()
		ContentProvider:PreloadAsync({ sound }, function(assetId: string, status: Enum.AssetFetchStatus)
			if status == Enum.AssetFetchStatus.Failure then
				warn(string.format("[Audio] %s failed to load (%s).", configKey, assetId))
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

local function playClone(template: Sound?, at: BasePart, pitchJitter: number?, volume: number?)
	if not template then
		return
	end
	local sound = template:Clone()
	if volume then
		sound.Volume = volume
	end
	if pitchJitter and pitchJitter > 0 then
		sound.PlaybackSpeed = 1 + (math.random() * 2 - 1) * pitchJitter
	end
	sound.Parent = at
	sound:Play()
	Debris:AddItem(sound, 5)
end

local function appliedMusicVolume(): number
	return musicVolumeLevel * TycoonConfig.Audio.MusicVolume
end

local function applyMusicVolume()
	if music then
		music.Volume = appliedMusicVolume()
	end
end

local function shuffleInPlace(list: { number })
	for i = #list, 2, -1 do
		local j = math.random(i)
		list[i], list[j] = list[j], list[i]
	end
end

local function rebuildShuffle()
	shuffleOrder = {}
	for i = 1, #playlist do
		table.insert(shuffleOrder, i)
	end
	shuffleInPlace(shuffleOrder)
	-- Avoid starting a new cycle on the same track that just finished.
	if #shuffleOrder > 1 and lastTrackName then
		local first = shuffleOrder[1]
		if playlist[first].name == lastTrackName then
			shuffleOrder[1], shuffleOrder[2] = shuffleOrder[2], shuffleOrder[1]
		end
	end
	shuffleIndex = 1
end

local function collectPlaylist()
	table.clear(playlist)
	local sounds = Workspace:FindFirstChild("Sounds")
	local folder = sounds and sounds:FindFirstChild("Music")
	if not (folder and folder:IsA("Folder")) then
		warn("[Audio] Missing Workspace.Sounds.Music; no playlist.")
		return
	end
	for _, child in ipairs(folder:GetChildren()) do
		if child:IsA("Sound") and child.SoundId ~= "" then
			table.insert(playlist, { id = child.SoundId, name = child.Name })
		end
	end
	if #playlist == 0 then
		warn("[Audio] Workspace.Sounds.Music has no Sound children with SoundId.")
	end
end

-- Sound ids under Workspace.Sounds[name] (a Sound, or a Folder of Sounds).
local function placeSoundIds(name: string): { string }
	local ids = {}
	local sounds = Workspace:FindFirstChild("Sounds")
	local found = sounds and sounds:FindFirstChild(name)
	if found and found:IsA("Sound") and found.SoundId ~= "" then
		table.insert(ids, found.SoundId)
	elseif found then
		for _, child in ipairs(found:GetChildren()) do
			if child:IsA("Sound") and child.SoundId ~= "" then
				table.insert(ids, child.SoundId)
			end
		end
	end
	return ids
end

local playNextTrack: () -> ()

local function requestNextTrack()
	-- Defer so Ended finishes cleaning up before we reuse the same Sound.
	task.defer(playNextTrack)
end

local function waitForMusicLoaded(sound: Sound, generation: number, timeout: number): boolean
	if sound.IsLoaded and sound.TimeLength > 0 then
		return true
	end
	local deadline = os.clock() + timeout
	while os.clock() < deadline do
		if generation ~= musicGeneration or sound ~= music then
			return false
		end
		if sound.IsLoaded and sound.TimeLength > 0 then
			return true
		end
		task.wait(0.1)
	end
	return sound.IsLoaded and sound.TimeLength > 0
end

playNextTrack = function()
	if musicAdvancing then
		return
	end
	if not music or #playlist == 0 then
		return
	end
	musicAdvancing = true

	-- Try each remaining shuffle entry once this pass; skip tracks that won't load.
	local attempts = math.max(#playlist, 1)
	for _ = 1, attempts do
		if not music then
			break
		end
		if shuffleIndex > #shuffleOrder then
			rebuildShuffle()
		end
		local track = playlist[shuffleOrder[shuffleIndex]]
		shuffleIndex += 1
		lastTrackName = track.name

		musicGeneration += 1
		local generation = musicGeneration
		local sound = music

		sound:Stop()
		sound.SoundId = track.id
		sound.Looped = false
		sound.Volume = appliedMusicVolume()

		-- Yield so SoundId change settles before Play (and so we can await load).
		task.wait()
		if generation ~= musicGeneration or sound ~= music then
			break
		end

		local loaded = waitForMusicLoaded(sound, generation, MUSIC_LOAD_TIMEOUT)
		if generation ~= musicGeneration or sound ~= music then
			break
		end
		if not loaded then
			warn(string.format("[Audio] Music track failed to load, skipping: %s (%s)", track.name, track.id))
			continue
		end

		sound:Play()
		-- Brief settle; if Play didn't stick, try the next track instead of stalling.
		task.wait(0.15)
		if generation ~= musicGeneration or sound ~= music then
			break
		end
		if sound.IsPlaying or sound.IsPaused then
			break
		end
		warn(string.format("[Audio] Music track did not start, skipping: %s", track.name))
	end

	musicAdvancing = false
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

	local placeId = placeSoundIds(cfg.PlaceSoundName)[1]
	if not placeId then
		warn("[Audio] Missing Workspace.Sounds." .. cfg.PlaceSoundName .. "; using PlaceSoundId.")
		placeId = cfg.PlaceSoundId
	end
	placeTemplate = makeTemplate("PlaceSoundTemplate", placeId, cfg.PlaceVolume, cfg.PlaceRollOffMaxDistance, "PlaceSound")

	local npcIds = placeSoundIds(cfg.NpcSoundsFolder)
	if #npcIds == 0 then
		warn("[Audio] Missing Workspace.Sounds." .. cfg.NpcSoundsFolder .. "; using NpcSoundIds.")
		npcIds = cfg.NpcSoundIds
	end
	for index, id in ipairs(npcIds) do
		table.insert(
			npcTemplates,
			makeTemplate("NpcSoundTemplate" .. index, id, cfg.NpcVolume, cfg.NpcRollOffMaxDistance, "NpcSound" .. index)
		)
	end

	collectPlaylist()
	if #playlist == 0 and cfg.MusicId ~= "" then
		-- Fallback if the place Music folder isn't synced yet.
		table.insert(playlist, { id = cfg.MusicId, name = "MusicId" })
	end
	if #playlist == 0 then
		warn("[Audio] No music tracks available.")
		return
	end

	local track = Instance.new("Sound")
	track.Name = "Music"
	track.Volume = appliedMusicVolume()
	track.Looped = false
	track.Parent = SoundService
	music = track

	track.Ended:Connect(function()
		requestNextTrack()
	end)

	-- Safety net: if Ended never fires (failed load / flaky Play), keep the shuffle alive.
	task.spawn(function()
		local idleSince: number? = nil
		while music do
			task.wait(1)
			local sound = music
			if not sound or musicAdvancing then
				idleSince = nil
				continue
			end
			if sound.IsPlaying or sound.IsPaused then
				idleSince = nil
			else
				if not idleSince then
					idleSince = os.clock()
				elseif os.clock() - idleSince >= MUSIC_STALL_SECONDS then
					idleSince = nil
					requestNextTrack()
				end
			end
		end
	end)

	rebuildShuffle()
	requestNextTrack()
end

function Audio.playSale(at: BasePart)
	playClone(saleTemplate, at, TycoonConfig.Audio.SalePitchJitter)
end

function Audio.playUpgrade(at: BasePart)
	playClone(upgradeTemplate, at, nil)
end

-- A dropped-in build has landed.
function Audio.playPlace(at: BasePart)
	playClone(placeTemplate, at, 0.05)
end

-- One random NPC voice line. volume overrides NpcVolume (purchase landing).
function Audio.playNpc(at: BasePart, volume: number?)
	if #npcTemplates == 0 then
		return
	end
	playClone(npcTemplates[math.random(#npcTemplates)], at, 0.05, volume)
end

-- 0 = off, 1 = full MusicVolume from config.
function Audio.getMusicVolume(): number
	return musicVolumeLevel
end

function Audio.setMusicVolume(level: number)
	musicVolumeLevel = math.clamp(level, 0, 1)
	applyMusicVolume()
	if music and musicVolumeLevel > 0 and not music.IsPlaying and music.TimeLength > 0 then
		-- If user unmutes from 0 while paused mid-load, keep playing when ready.
		if music.IsPaused then
			music:Resume()
		end
	end
	if onVolumeChanged then
		onVolumeChanged(musicVolumeLevel)
	end
end

function Audio.onMusicVolumeChanged(callback: (number) -> ())
	onVolumeChanged = callback
end

return Audio

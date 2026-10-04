-- Background music + per-sale sound. Ids live in TycoonConfig.Audio.
-- Failed loads are warned about so a wrong Creator Store id isn't silent.

local ContentProvider = game:GetService("ContentProvider")
local Debris = game:GetService("Debris")
local SoundService = game:GetService("SoundService")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared", 10)
assert(Shared, "Missing ReplicatedStorage.Shared")

local TycoonConfig = require(Shared:WaitForChild("TycoonConfig", 10))

local Audio = {}

local saleTemplate: Sound? = nil

local function verifyLoads(sound: Sound, configKey: string)
	task.spawn(function()
		ContentProvider:PreloadAsync({ sound }, function(assetId: string, status: Enum.AssetFetchStatus)
			if status == Enum.AssetFetchStatus.Failure then
				warn(string.format("[Audio] TycoonConfig.Audio.%s failed to load (%s).", configKey, assetId))
			end
		end)
	end)
end

function Audio.start()
	local cfg = TycoonConfig.Audio

	if cfg.SaleSoundId ~= "" then
		local sale = Instance.new("Sound")
		sale.Name = "SaleSoundTemplate"
		sale.SoundId = cfg.SaleSoundId
		sale.Volume = cfg.SaleVolume
		sale.RollOffMaxDistance = cfg.SaleRollOffMaxDistance
		sale.Parent = SoundService
		verifyLoads(sale, "SaleSoundId")
		saleTemplate = sale
	end

	if cfg.MusicId == "" then
		warn("[Audio] TycoonConfig.Audio.MusicId is empty; no background music.")
		return
	end

	local music = Instance.new("Sound")
	music.Name = "Music"
	music.SoundId = cfg.MusicId
	music.Volume = cfg.MusicVolume
	music.Looped = true
	music.Parent = SoundService
	verifyLoads(music, "MusicId")
	music:Play()
end

-- Positional, so automated stations get quieter as you walk away.
function Audio.playSale(at: BasePart)
	if not saleTemplate then
		return
	end
	local sound = saleTemplate:Clone()
	local jitter = TycoonConfig.Audio.SalePitchJitter
	sound.PlaybackSpeed = 1 + (math.random() * 2 - 1) * jitter
	sound.Parent = at
	sound:Play()
	Debris:AddItem(sound, 5)
end

return Audio

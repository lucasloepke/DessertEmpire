local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared", 10)
assert(Shared, "Missing ReplicatedStorage.Shared")

local TycoonConfig = require(Shared:WaitForChild("TycoonConfig", 10))
local PlayerData = require(Shared:WaitForChild("PlayerData", 10))

local DataService = {}

-- GetDataStore errors in unpublished Studio places. Fall back to memory so
-- playtests still boot; nothing is written to Roblox servers in that mode.
local store: any = nil
local memoryStore: { [string]: any } = {}
local usingMemory = false

do
	local ok, result = pcall(function()
		return DataStoreService:GetDataStore(TycoonConfig.DataStoreName)
	end)
	if ok and result then
		store = result
	else
		usingMemory = true
		warn(string.format(
			"[DataService] DataStores unavailable (%s). Using in-memory saves for this session.",
			tostring(result)
		))
		if RunService:IsStudio() then
			warn("[DataService] Publish the place (or enable API Services) for real DataStores.")
		end
	end
end

type Session = {
	data: any,
	canSave: boolean,
	isDirty: boolean,
}

local sessions: { [Player]: Session } = {}

local function keyFor(userId: number): string
	return "player_" .. tostring(userId)
end

local function retryAsync(label: string, fn: () -> any): (boolean, any)
	local delaySeconds = TycoonConfig.DataStoreRetryDelay
	local lastErr

	for attempt = 1, TycoonConfig.DataStoreRetries do
		local ok, result = pcall(fn)
		if ok then
			return true, result
		end
		lastErr = result
		warn(string.format("[DataService] %s attempt %d failed: %s", label, attempt, tostring(result)))
		if attempt < TycoonConfig.DataStoreRetries then
			task.wait(delaySeconds)
			delaySeconds *= 2
		end
	end

	return false, lastErr
end

local function readKey(userId: number): (boolean, any)
	local key = keyFor(userId)
	if usingMemory then
		return true, memoryStore[key]
	end
	return retryAsync("GetAsync:" .. userId, function()
		return store:GetAsync(key)
	end)
end

local function writeKey(userId: number, payload: any): boolean
	local key = keyFor(userId)
	if usingMemory then
		memoryStore[key] = payload
		return true
	end
	local ok = retryAsync("SetAsync:" .. userId, function()
		store:SetAsync(key, payload)
		return true
	end)
	return ok
end

local function replicateCash(player: Player, cash: number)
	player:SetAttribute("Cash", cash)
end

function DataService.isUsingMemory(): boolean
	return usingMemory
end

function DataService.get(player: Player)
	local session = sessions[player]
	return if session then session.data else nil
end

function DataService.canSave(player: Player): boolean
	local session = sessions[player]
	return session ~= nil and session.canSave
end

function DataService.markDirty(player: Player)
	local session = sessions[player]
	if session and session.canSave then
		session.isDirty = true
	end
end

function DataService.setCash(player: Player, cash: number)
	local session = sessions[player]
	if not session then
		return
	end
	session.data.cash = math.max(0, math.floor(cash))
	session.isDirty = true
	replicateCash(player, session.data.cash)
end

-- Wipe cash + station progress back to defaults (keeps the session saveable).
function DataService.resetProgress(player: Player): boolean
	local session = sessions[player]
	if not session then
		return false
	end
	session.data = PlayerData.createDefault()
	if session.canSave then
		session.isDirty = true
	end
	replicateCash(player, session.data.cash)
	return true
end

function DataService.addCash(player: Player, amount: number)
	local session = sessions[player]
	if not session then
		return
	end
	DataService.setCash(player, session.data.cash + amount)
end

-- Deducts only if the player can afford it. Returns whether it was spent.
function DataService.trySpend(player: Player, amount: number): boolean
	local session = sessions[player]
	if not session or amount < 0 or session.data.cash < amount then
		return false
	end
	DataService.setCash(player, session.data.cash - amount)
	return true
end

--[[
	Load order result:
	- success + data → session is saveable
	- datastore failure → session marked unsaveable, defaults used for play only
	  (we refuse to write so we never clobber a real save)
	Memory mode (unpublished Studio) always saveable within the session.
]]
function DataService.load(player: Player): (boolean, any)
	local ok, raw = readKey(player.UserId)

	if not ok then
		warn(string.format(
			"[DataService] Load failed for %s (%d). Session is UNSAVEABLE.",
			player.Name,
			player.UserId
		))
		local fallback = PlayerData.createDefault()
		sessions[player] = {
			data = fallback,
			canSave = false,
			isDirty = false,
		}
		replicateCash(player, fallback.cash)
		player:SetAttribute("DataLoadFailed", true)
		return false, fallback
	end

	local data
	if raw == nil then
		data = PlayerData.createDefault()
	else
		data = PlayerData.sanitize(raw)
		if data == nil then
			warn(string.format(
				"[DataService] Corrupt save for %s (%d). Session is UNSAVEABLE.",
				player.Name,
				player.UserId
			))
			local fallback = PlayerData.createDefault()
			sessions[player] = {
				data = fallback,
				canSave = false,
				isDirty = false,
			}
			replicateCash(player, fallback.cash)
			player:SetAttribute("DataLoadFailed", true)
			return false, fallback
		end
	end

	sessions[player] = {
		data = data,
		canSave = true,
		isDirty = false,
	}
	replicateCash(player, data.cash)
	player:SetAttribute("DataLoadFailed", false)
	return true, data
end

function DataService.save(player: Player): boolean
	local session = sessions[player]
	if not session then
		return false
	end
	if not session.canSave then
		return false
	end

	session.data.lastSeen = os.time()

	if writeKey(player.UserId, session.data) then
		session.isDirty = false
		return true
	end

	warn(string.format("[DataService] Save failed for %s (%d).", player.Name, player.UserId))
	return false
end

function DataService.release(player: Player)
	sessions[player] = nil
end

function DataService.bindAutoSave(intervalSeconds: number)
	task.spawn(function()
		while true do
			task.wait(intervalSeconds)
			for _, player in ipairs(Players:GetPlayers()) do
				local session = sessions[player]
				if session and session.canSave and session.isDirty then
					DataService.save(player)
				end
			end
		end
	end)
end

return DataService

-- NPC props (server tag Npc) say a random voice line every so often.
-- Positional, so you only hear the ones near you. Decoration only.

local CollectionService = game:GetService("CollectionService")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared", 10)
assert(Shared, "Missing ReplicatedStorage.Shared")

local TycoonConfig = require(Shared:WaitForChild("TycoonConfig", 10))
local DropIn = require(script.Parent.DropIn)

local NpcChatter = {}

local chattering: { [Instance]: boolean } = setmetatable({}, { __mode = "k" }) :: any
local random = Random.new()

local function voicePart(npc: Instance): BasePart?
	local head = npc:FindFirstChild("Head")
	if head and head:IsA("BasePart") then
		return head
	end
	if npc:IsA("Model") then
		return npc.PrimaryPart
	end
	return nil
end

local function chatter(npc: Instance, playNpc: (BasePart) -> ())
	if chattering[npc] then
		return
	end
	chattering[npc] = true
	local cfg = TycoonConfig.Audio
	task.spawn(function()
		while npc.Parent do
			task.wait(random:NextNumber(cfg.NpcChatterMinInterval, cfg.NpcChatterMaxInterval))
			local part = voicePart(npc)
			-- Landing already plays a voice; don't talk over it mid-drop.
			if npc.Parent and part and not DropIn.isBusy(npc) then
				playNpc(part)
			end
		end
		chattering[npc] = nil
	end)
end

function NpcChatter.start(playNpc: (BasePart) -> ())
	local tag = TycoonConfig.Tags.Npc
	CollectionService:GetInstanceAddedSignal(tag):Connect(function(npc)
		chatter(npc, playNpc)
	end)
	for _, npc in ipairs(CollectionService:GetTagged(tag)) do
		chatter(npc, playNpc)
	end
end

return NpcChatter

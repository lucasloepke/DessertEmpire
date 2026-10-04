-- Far away: icon markers only. Close: text holograms (engine MaxDistance).
-- When you're near enough to read text, hide the icon so they don't stack.

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared", 10)
assert(Shared, "Missing ReplicatedStorage.Shared")

local TycoonConfig = require(Shared:WaitForChild("TycoonConfig", 10))

local HologramVisibility = {}

function HologramVisibility.start()
	local player = Players.LocalPlayer
	local cfg = TycoonConfig.Interact.Hologram

	RunService.Heartbeat:Connect(function()
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if not (root and root:IsA("BasePart")) then
			return
		end

		for _, gui in ipairs(CollectionService:GetTagged(cfg.IconTag)) do
			if gui:IsA("BillboardGui") then
				local adornee = gui.Adornee
				if adornee and adornee:IsA("BasePart") then
					gui.Enabled = (adornee.Position - root.Position).Magnitude > cfg.TextMaxDistance
				end
			end
		end
	end)
end

return HologramVisibility

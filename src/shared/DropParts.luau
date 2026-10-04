-- Which parts move with a drop-in. Shared so the server can record the count
-- (DropParts attribute) and the client can wait until that many replicated:
-- the DropIn tag can reach the client before the model's children do.

local CollectionService = game:GetService("CollectionService")

local TycoonConfig = require(script.Parent.TycoonConfig)

local DropParts = {}

-- Nested drop-ins (an NPC with its own delay) and purchase buttons stay put.
function DropParts.collect(root: Instance): { BasePart }
	local parts = {}
	local function visit(instance: Instance)
		if instance ~= root then
			if CollectionService:HasTag(instance, TycoonConfig.Tags.DropIn) then
				return
			end
			if instance:IsA("Model") and instance:GetAttribute("Kind") ~= nil then
				return
			end
		end
		if instance:IsA("BasePart") then
			table.insert(parts, instance)
		end
		for _, child in ipairs(instance:GetChildren()) do
			visit(child)
		end
	end
	visit(root)
	return parts
end

return DropParts

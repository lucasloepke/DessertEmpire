local Players = game:GetService("Players")

local player = Players.LocalPlayer

-- Cash is replicated via the Cash player attribute (server-authoritative).
-- Full HUD / station panel comes later.
local function onCashChanged()
	local cash = player:GetAttribute("Cash")
	if typeof(cash) == "number" then
		print(string.format("[TycoonHud] Cash: $%d", cash))
	end
end

player:GetAttributeChangedSignal("Cash"):Connect(onCashChanged)
onCashChanged()

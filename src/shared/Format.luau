-- Shared display formatting so HUD, holograms, and panels show the same numbers.

local Format = {}

local SUFFIXES = { "K", "M", "B", "T", "Qa", "Qi" }

-- $999, $1.5K, $12.25M ...
function Format.cash(amount: number): string
	local whole = math.floor(amount)
	if whole < 1000 then
		return "$" .. tostring(whole)
	end

	local tier = math.clamp(math.floor(math.log10(whole) / 3), 1, #SUFFIXES)
	local scaled = whole / 10 ^ (tier * 3)
	local text = (string.gsub(string.format("%.2f", scaled), "%.?0+$", ""))
	return "$" .. text .. SUFFIXES[tier]
end

return Format

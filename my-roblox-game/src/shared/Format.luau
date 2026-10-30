local Format = {}

local SUFFIXES = { "", "K", "M", "B", "T" }

-- 1234 -> "$1.2K"
function Format.money(amount)
	local i = 1
	while amount >= 1000 and i < #SUFFIXES do
		amount /= 1000
		i += 1
	end
	if i == 1 then
		return "$" .. math.floor(amount)
	end
	return string.format("$%.1f%s", amount, SUFFIXES[i])
end

return Format

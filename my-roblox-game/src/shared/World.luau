-- The squishy hunting map, where the regions are (src/shared/Regions/). It's separate from the lobby.
-- You arrive on a safe spawn pad in the middle, and the region rings go out from there.
local World = {}

World.CENTER = Vector3.new(0, 0, 0)
-- The spawn pad. Nothing falls on it and evil squishies won't follow you onto it
World.SPAWN_RADIUS = 25
-- The map is a square this far from the middle in each direction (the baseplate under it is 2048 wide)
World.HALF_SIZE = 1016

function World.distanceOf(position)
	return ((position - World.CENTER) * Vector3.new(1, 0, 1)).Magnitude
end

function World.contains(position)
	local offset = position - World.CENTER
	return math.abs(offset.X) < World.HALF_SIZE and math.abs(offset.Z) < World.HALF_SIZE
end

function World.inSpawn(position)
	return World.distanceOf(position) < World.SPAWN_RADIUS
end

return World

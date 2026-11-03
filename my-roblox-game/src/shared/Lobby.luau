-- The lobby is its own floating island, far away from the squishy hunting map (see World.luau).
-- It has the shops, trading, leaderboards, and everyone's bases. No squishies fall here.
-- Portals (Travel.server.luau) take you between the lobby and the hunting map.
local Lobby = {}

-- Far past the edge of the hunting map
Lobby.CENTER = Vector3.new(0, 0, 2400)
-- The plaza in the middle with the shop booths
Lobby.RADIUS = 35
-- Player bases sit in a ring this far from the middle
Lobby.BASE_RING = 110
-- The whole island, bases included
Lobby.ISLAND_RADIUS = 150

function Lobby.contains(position)
	return ((position - Lobby.CENTER) * Vector3.new(1, 0, 1)).Magnitude < Lobby.ISLAND_RADIUS
end

return Lobby

-- The lobby in the middle of the map. No squishies fall here and evil ones won't chase you in
local Lobby = {}

Lobby.CENTER = Vector3.new(0, 0, 0)
Lobby.RADIUS = 35

function Lobby.contains(position)
	return ((position - Lobby.CENTER) * Vector3.new(1, 0, 1)).Magnitude < Lobby.RADIUS
end

return Lobby

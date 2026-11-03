return {
	Name = "Starfield",
	Icon = "🌌",
	Color = Color3.fromRGB(150, 120, 230),
	Order = 4,
	Width = 0, -- the last ring goes on forever
	Luck = 3,
	Unlock = { Rebirths = 3, Cost = 500000 },
	EvilChance = 0.2,
	Mutation = "Starlit",
	Squishies = { "Cupcake", "Watermelon", "Sushi", "Boba Tea", "Moldy Toast", "Angry Chili" },
	Terrain = {
		Material = Enum.Material.Basalt,
		HighMaterial = Enum.Material.CrackedLava,
		Colors = { [Enum.Material.Basalt] = Color3.fromRGB(110, 80, 190), [Enum.Material.CrackedLava] = Color3.fromRGB(80, 220, 255) },
		Height = 30,
		Step = 5,
		Scale = 60,
		Patches = { Material = Enum.Material.Glacier, Color = Color3.fromRGB(255, 160, 240), Amount = 0.15 },
		-- This ring covers most of the map, so keep props sparse or the part count gets huge
		Props = { Crystal = 0.012, Mushroom = 0.005, Rock = 0.004 },
	},
}

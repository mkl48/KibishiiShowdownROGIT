-- Sphereite Reject / Manifest
--
-- Declares the character's moveset order and movement set. CharacterService reads
-- this when building the character. (Was a syntax error before: `Idle` missing its
-- comma, and the direction entries were bare nil identifiers -- now strings.)

local Manifest = {}

Manifest.MovesetOverview = {
	Name = "Love Addict",
	-- Move order by class. Numeric keys = the combo/slot order; named keys = specials.
	Order = {
		Base = {
			[1] = "Doo Doo Duel",
			["Special"] = "Shin No Kachi",
		},
	},

	Movement = {
		Base = {
			Dash = { "Forward", "Backward", "SideLeft", "SideRight" },
			Move = { "Idle", "Forward", "Backward", "SideLeft", "SideRight" },
		},
	},
}

-- Visual theme for this character's UI presentation.
-- Consumed by the Characters element to drive gleam, outline, and gradient colors.
Manifest.Theme = {
	Primary   = Color3.fromRGB(210, 118, 65),  -- terracotta orange — main identity color
	Secondary = Color3.fromRGB(162, 82, 41),   -- burnt sienna — darker accent / resting outline
	Highlight = Color3.fromRGB(255, 255, 255),  -- neutral white for hover pop
	Gleam     = Color3.fromRGB(232, 140, 78),  -- brighter orange so the glow actually reads
	Gradient  = {
		Color3.fromRGB(210, 118, 65),           -- orange
		Color3.fromRGB(245, 214, 170),          -- warm cream, not pure white
	},
}

return Manifest

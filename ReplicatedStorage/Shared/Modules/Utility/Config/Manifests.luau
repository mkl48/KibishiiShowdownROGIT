local Manifests = {}

-- Screen / GUI configuration for the InterfaceController
Manifests.Interface = {
	Screen = {
		Name = "Interface",
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		DisplayOrder = 20,
	},

	-- TopbarPlus Icon styling constants — consumed by the Stylized class
	Stylized = {
		SoundVolume = 0.5,
		SoundCleanupTimeout = 10,
		IconModulePath = { "Client", "Modules", "Packages", "Icon" },
		SoundServicePlusPath = { "Client", "Modules", "Services", "SoundService+" },

		Glow = {
			DefaultColor = Color3.fromRGB(255, 255, 255),
			FadeColor = Color3.new(0, 0, 0),
		},

		Image = {
			FrameSize = UDim2.new(0, 20, 0, 20),
			FramePosition = UDim2.new(1, -45, 0, 3),
		},

		Outline = {
			DefaultThickness = 1,
			DefaultColor = Color3.new(1, 1, 1),
			FadeInDuration = 0.6,
			FadeInWait = 0.2,
			FadeOutDuration = 0.25,
			GlowFrameWaitTimeout = 5,
		},

		Gleam = {
			GlowSizeY = 0.99,
			FadeDuration = 0.25,
			HideDelay = 0.25,
			PaddingValue = 1,
		},

		ListTheme = {
			{"Widget", "BorderSize", 5},
			{"Dropdown", "BackgroundTransparency", 1},
			{"Dropdown", "MaxIcons", 4},

			{"DropdownScroller", "ScrollBarThickness", 5},
			{"DropdownScroller", "ScrollBarImageColor3", Color3.fromRGB(0, 0, 0)},
			{"DropdownScroller", "ScrollBarImageTransparency", 0.28},

			{"DropdownList", "Padding", UDim.new(0, 2)},
			{"DropdownPadding", "PaddingTop", UDim.new(0, 2)},
			{"DropdownPadding", "PaddingRight", UDim.new(0, 15)},
			{"DropdownPadding", "PaddingBottom", UDim.new(0, 5)},

			{"Selection", "RotationSpeed", 4},
			{"SelectionGradient", "Color", ColorSequence.new({
				ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
				ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 0, 0)),
			})},
		},

		ChildTheme = {
			{"Widget", "BorderSize", 2.5},
			{"Widget", "MinimumWidth", 160},
			{"Widget", "MinimumHeight", 40},

			{"IconButton", "BackgroundTransparency", 0.18},
			{"IconOverlay", "BackgroundTransparency", 0.9},
			{"IconCorners", "CornerRadius", UDim.new(1, 0)},
			{"IconSpot", "BackgroundTransparency", 1},
			{"IconImageScale", "Value", 0.8},

			{"IconLabel", "TextSize", 16},
			{"IconLabel", "Font", Enum.Font.SourceSansSemibold},

			{"PaddingLeft", "Size", UDim2.fromOffset(3, 0)},
			{"PaddingRight", "Size", UDim2.fromOffset(25, 0)},

			{"Notice", "Position", UDim2.new(1, -25, 0, 6)},
			{"ContentsList", "HorizontalAlignment", Enum.HorizontalAlignment.Left},
		},
	},

	-- Characters element (TopbarPlus character selection icons)
	Characters = {
		ViewTweenDuration = 0.5,
		ViewEasingStyle = Enum.EasingStyle.Quad,
		ViewEasingDirection = Enum.EasingDirection.Out,
		ViewOutlineThickness = 2,
		RestOutlineThickness = 1,
		GradientRotationSpeed = 1,
	},

	-- Settings element (tabbed settings panel)
	Settings = {
		Tabs = { "Audio", "Gameplay", "Controls" },
		Gameplay = {
			CameraSensitivity = { kind = "slider", min = 0.1, max = 5,   step = 0.1 },
			FieldOfView       = { kind = "slider", min = 40,  max = 120, step = 1   },
			ShiftLockEnabled  = { kind = "toggle" },
			AutoRun           = { kind = "toggle" },
			AutoUse           = { kind = "toggle" },
		},
		SliderDefaults = { min = 0, max = 100, step = 1 },
		ControlsButton = { Width = 96, Height = 30 },
		RowPositionY = 0.5,
	},

	-- Input configuration
	Input = {
		HoldDuration = 0.2,
		Context = "Gameplay",
	},
}

-- Game-wide defaults and configuration
Manifests.Game = {
	DefaultCharacter = "Sphereite Reject",
	DefaultTheme = {
		Primary   = Color3.fromRGB(185, 25, 20),
		Secondary = Color3.fromRGB(210, 185, 55),
		Highlight = Color3.fromRGB(255, 255, 255),
		Gleam     = Color3.fromRGB(255, 77, 0),
		Gradient  = {
			Color3.fromRGB(255, 0, 0),
			Color3.fromRGB(255, 255, 255),
		},
	},
	Defaults = {
		Health = 100,
		AttackIndex = 0,
	},
	Combat = {
		M1Cooldown = 0.5,
		ReverbWindow = 0.1,
		ComboResetTime = 1.5,
		ComboLength = 4,
		Range = 8,
		RangeFudge = 1.2,
		M1Damage = 10,
		ReverbMultiplier = 2,
		FinisherKnockback = 50,
		LightKnockback = 15,
		FinisherStun = 1.5,
		HitStun = 0.5,
		InitialCombo = { Index = 0, LastSwing = 0 },
	},

	-- Battlegrounds-style character switch reset configuration
	Battleground = {
		RespawnCharacter = true,      -- Respawn the Roblox character on swap
		PreservePosition = true,      -- Keep the player where they were
		ResetHealth = true,            -- Reset health to default
		ResetCombo = true,             -- Clear combat combo
		ResetStates = true,            -- Clear all states (Stunned, Attacking, etc.)
		ResetConditionals = true,     -- Reset all conditionals
		ResetEffects = true,           -- Clear status effects
		SwitchCooldown = 1,            -- Minimum seconds between character swaps
		InvulnerabilityTime = 2,       -- Seconds of invulnerability after switching
	},
}

-- Character definitions — centralised from individual Config ModuleScripts
Manifests.Characters = {
	["Sphereite Reject"] = {
		MovesetOverview = {
			Name = "Sphereite Reject",
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
		},
		Theme = {
			Primary   = Color3.fromRGB(185, 25, 20),
			Secondary = Color3.fromRGB(210, 185, 55),
			Highlight = Color3.fromRGB(255, 255, 255),
			Gleam     = Color3.fromRGB(185, 25, 20),
			Gradient  = {
				Color3.fromRGB(255, 0, 0),
				Color3.fromRGB(255, 255, 255),
			},
		},
	},

	["Love Addict"] = {
		MovesetOverview = {
			Name = "Love Addict",
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
		},
		Theme = {
			Primary   = Color3.fromRGB(210, 118, 65),
			Secondary = Color3.fromRGB(162, 82, 41),
			Highlight = Color3.fromRGB(255, 255, 255),
			Gleam     = Color3.fromRGB(232, 140, 78),
			Gradient  = {
				Color3.fromRGB(210, 118, 65),
				Color3.fromRGB(245, 214, 170),
			},
		},
	},
}

-- Session path strings — shared between SessionController (client) and SessionManager (server)
Manifests.Session = {
	Paths = {
		Health         = "Context.Status.Health",
		AttackIndex    = "Context.Status.AttackIndex",
		Character      = "Context.Character.Current",
		States         = "Context.States",
		StatesPrefix   = "Context.States.",
		Status         = "Context.Status",
		Conditionals   = "Context.Conditionals",
		Statistics     = "Statistics",
	},
}

return Manifests
return {
	Variants = {
		Primary   = { Background = Color3.fromRGB(60, 60, 66)  },  -- neutral button (TOGGLE / CREATE SERVER)
		Secondary = { Background = Color3.fromRGB(44, 44, 48)  },
		Danger    = { Background = Color3.fromRGB(232, 72, 72) },
		Success   = { Background = Color3.fromRGB(72, 200, 118) },
		Ghost     = { Transparency = 1 },
		Outline   = {
			Transparency = 1,
			Background   = Color3.fromRGB(60, 60, 66),
			Color        = Color3.fromRGB(110, 110, 118),
		},
	},

	Colors = {
		Brand = {
			BrandWhite      = Color3.fromRGB(243, 244, 247),
			BrandLightGray  = Color3.fromRGB(140, 144, 152),
			BrandGray       = Color3.fromRGB(86,  89,  97),
			BrandBackground = Color3.fromRGB(74,  77,  84),
			BrandBlue       = Color3.fromRGB(90,  150, 235),
			BrandRed        = Color3.fromRGB(240, 80,  74),    -- danger toggle
			BrandGreen      = Color3.fromRGB(63,  206, 118),   -- on toggle
			BrandYellow     = Color3.fromRGB(240, 200, 90),
		},
		Surface = {
			Base    = Color3.fromRGB(74,  77,  84),   -- frosted panel
			Raised  = Color3.fromRGB(86,  89,  97),   -- rows
			Overlay = Color3.fromRGB(108, 112, 121),  -- buttons / bars (bright top)
			Border  = Color3.fromRGB(150, 154, 162),
			Subtle  = Color3.fromRGB(120, 124, 132),
		},
		Text = {
			Primary   = Color3.fromRGB(243, 244, 247),
			Secondary = Color3.fromRGB(195, 198, 205),
			Disabled  = Color3.fromRGB(140, 144, 152),
			Inverse   = Color3.fromRGB(24,  24,  26),
		},

		State = {
			Hover   = Color3.fromRGB(255, 255, 255),
			Press   = Color3.fromRGB(0,   0,   0),
			Focus   = Color3.fromRGB(90,  150, 235),
			Success = Color3.fromRGB(72,  200, 118),
			Warning = Color3.fromRGB(240, 200, 90),
			Error   = Color3.fromRGB(232, 72,  72),
			Info    = Color3.fromRGB(90,  150, 235),
		},

		Link  = Color3.fromRGB(90, 150, 235),
		Scrim = Color3.fromRGB(0,  0,  0),
	},

	Text = {
		Font       = Font.fromEnum(Enum.Font.BuilderSans),
		FontMedium = Font.fromEnum(Enum.Font.BuilderSans),
		FontBold   = Font.fromEnum(Enum.Font.BuilderSans),

		SizeXS = 10, SizeSM = 12, SizeMD = 14, SizeLG = 16,
		SizeXL = 20, SizeTitle = 18, SizeDisplay = 24,
	},

	Sizes = {
		ContainerSize     = UDim2.fromOffset(450, 280),
		ContainerPosition = UDim2.fromScale(0.5, 0.5),
		InputHeight = 36, ButtonHeight = 36, LabelHeight = 22, DividerHeight = 1,
		IconSM = 16, IconMD = 20, IconLG = 28,
	},

	Roundness = {
		None = UDim.new(0, 0), SM = UDim.new(0, 4), MD = UDim.new(0, 8),
		LG = UDim.new(0, 12), XL = UDim.new(0, 16), Full = UDim.new(1, 0),
		CornerRoundness = UDim.new(0, 18),
		ButtonRoundness = UDim.new(0, 10),
		InputRoundness  = UDim.new(0, 10),
		BadgeRoundness  = UDim.new(1, 0),
	},

	Motion = {
		DurationFast = 0.08, DurationNormal = 0.15, DurationSlow = 0.25,
		EasingOut = Enum.EasingStyle.Quad, EasingIn = Enum.EasingStyle.Quad,
		EasingBack = Enum.EasingStyle.Back,
	},

	Spacing = {
		XS = UDim.new(0, 4), SM = UDim.new(0, 8), MD = UDim.new(0, 12),
		LG = UDim.new(0, 16), XL = UDim.new(0, 24), XXL = UDim.new(0, 32),
	},

	ZIndex = {
		{ name = "Background", base = 1   }, { name = "Content", base = 10 },
		{ name = "Raised",     base = 20  }, { name = "Floating", base = 50 },
		{ name = "Overlay",    base = 80  }, { name = "Tooltip", base = 100 },
		{ name = "Toast",      base = 110 }, { name = "System", base = 120 },
	},

	Opacity = { ScrimLight = 0.35, ScrimHeavy = 0.60, Disabled = 0.40, Subtle = 0.06 }
}
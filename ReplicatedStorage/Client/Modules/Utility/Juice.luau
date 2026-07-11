local Juice = {}

local SHADOW_ASSET = "rbxassetid://6014261993"       -- soft 9-slice drop shadow
local SHADOW_SLICE = Rect.new(49, 49, 450, 450)

-- vertical "glass" sheen: brighter top, darker bottom (multiplies the fill)
function Juice.glass(inst: GuiObject, strength: number?)
	local s = strength or 0.12
	local g = Instance.new("UIGradient")
	g.Rotation = 90
	g.Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.new(1 - s, 1 - s, 1 - s))
	g.Parent = inst
	return g
end

-- bevel: dark outer border for definition + white top-edge highlight that fades down
function Juice.bevel(inst: GuiObject, highlight: number?)
	local border = Instance.new("UIStroke")
	border.Thickness       = 1
	border.Color           = Color3.fromRGB(0, 0, 0)
	border.Transparency    = 0.5
	border.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	border.Parent          = inst

	local hl = Instance.new("UIStroke")
	hl.Thickness       = 1.5
	hl.Color           = Color3.fromRGB(255, 255, 255)
	hl.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	hl.Parent          = inst
	local hg = Instance.new("UIGradient")
	hg.Rotation     = 90
	hg.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0,   highlight or 0.3),
		NumberSequenceKeypoint.new(0.6, 1),
		NumberSequenceKeypoint.new(1,   1),
	})
	hg.Parent = hl
end

-- drop shadow as a child (works on non-clipping frames: cards, buttons, tab bar)
function Juice.shadow(inst: GuiObject, transparency: number?, spread: number?)
	local sp = spread or 26
	local s = Instance.new("ImageLabel")
	s.Name                   = "Shadow"
	s.BackgroundTransparency = 1
	s.Image                  = SHADOW_ASSET
	s.ImageColor3            = Color3.fromRGB(0, 0, 0)
	s.ImageTransparency      = transparency or 0.45
	s.ScaleType              = Enum.ScaleType.Slice
	s.SliceCenter            = SHADOW_SLICE
	s.AnchorPoint            = Vector2.new(0.5, 0.5)
	s.Position               = UDim2.fromScale(0.5, 0.5)
	s.Size                   = UDim2.new(1, sp, 1, sp)
	s.ZIndex                 = inst.ZIndex - 1
	s.Parent                 = inst
	return s
end

-- panel shadow: the panel CLIPS, so the shadow must be a sibling behind it
function Juice.panelShadow(panel: GuiObject, transparency: number?, spread: number?)
	local sp = spread or 40
	local s = Instance.new("ImageLabel")
	s.Name                   = "PanelShadow"
	s.BackgroundTransparency = 1
	s.Image                  = SHADOW_ASSET
	s.ImageColor3            = Color3.fromRGB(0, 0, 0)
	s.ImageTransparency      = transparency or 0.4
	s.ScaleType              = Enum.ScaleType.Slice
	s.SliceCenter            = SHADOW_SLICE
	s.AnchorPoint            = panel.AnchorPoint
	s.Position               = panel.Position
	s.Size                   = UDim2.new(panel.Size.X.Scale, panel.Size.X.Offset + sp,
		panel.Size.Y.Scale, panel.Size.Y.Offset + sp)
	s.ZIndex                 = panel.ZIndex - 1
	s.Parent                 = panel.Parent
	return s
end

-- crisp text: subtle black shadow so labels pop off translucent glass
function Juice.text(inst)
	if inst:IsA("TextLabel") or inst:IsA("TextButton") or inst:IsA("TextBox") then
		inst.TextStrokeColor3       = Color3.fromRGB(0, 0, 0)
		inst.TextStrokeTransparency = 0.6
	end
end

-- one-call button treatment
function Juice.button(inst: GuiObject)
	Juice.glass(inst, 0.14)
	Juice.bevel(inst, 0.25)
	Juice.shadow(inst, 0.55, 14)
	Juice.text(inst)
end

return Juice
-- _Elements/Settings.lua  — tabbed, schema-driven (Audio / Gameplay / Controls)
local Settings = {}

function Settings:Start(ctx)
	local Classes = ctx.Classes
	local Config = ctx.Config
	local SettingsConfig = Config.Manifests.Interface.Settings

	-- per-key hints for raw Gameplay values (schema stores them bare)
	local META = {
		Gameplay = SettingsConfig.Gameplay,
	}
	local ORDER = SettingsConfig.Tabs

	--local Base = Classes.Base
	--local Data = ctx.Utilities.Config.Settings

	--local card = Classes.Card({ Eyebrow = "Settings", Title = "Preferences",
	--	Size = UDim2.fromOffset(392, 340), Parent = ctx.Screen })
	--local tabs = Classes.Tabs({ Items = ORDER, Parent = card.Body })
	--local well = Base.new("Frame", { Position = UDim2.fromOffset(0, 48), Size = UDim2.new(1, 0, 1, -48),
	--	BackgroundColor3 = C.S0, BorderSizePixel = 0 }, card.Body)
	--Base.corner(well, Theme.Radius.Row); Base.stroke(well, C.Line, 1, Theme.LineT); Base.pad(well, 9)
	--local scroll = Base.new("ScrollingFrame", { BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1),
	--	BorderSizePixel = 0, ScrollBarThickness = 3, ScrollBarImageColor3 = C.S4,
	--	CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y }, well)
	--Base.list(scroll, false, 8)

	---- one settings row: label (+ optional (ME)) on the left, control mounted on the right
	--local function row(order)
	--	local r = Base.new("Frame", { Size = UDim2.new(1, 0, 0, 48), LayoutOrder = order, BorderSizePixel = 0 }, scroll)
	--	Base.corner(r, Theme.Radius.Row); Base.fill(r, C.S2, C.S1b); Base.stroke(r, C.Line, 1, Theme.LineT); Base.pad(r, 12)
	--	return r
	--end
	--local function label(parent, text)
	--	Base.new("TextLabel", { Text = text, Font = Theme.Font, TextSize = 13, TextColor3 = C.Ink,
	--		BackgroundTransparency = 1, Size = UDim2.new(1, -120, 1, 0), TextXAlignment = Enum.TextXAlignment.Left }, parent)
	--end

	--local function render(name)
	--	for _, ch in scroll:GetChildren() do if not ch:IsA("UIListLayout") then ch:Destroy() end end
	--	local ns = Data.GetNamespace(name)
	--	if not ns then return end
	--	local keys = {}; for k in ns do table.insert(keys, k) end; table.sort(keys)
	--	for i, key in ipairs(keys) do
	--		local v = ns[key]
	--		local r = row(i); label(r, key)
	--		local mount = { Parent = r, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0) }

	--		if name == "Audio" and type(v) == "table" and v.Value ~= nil then           -- Volume slider
	--			Classes.Slider({ Min = v.Minimum or 0, Max = v.Maximum or 100, Step = v.Step or 1, Value = v.Value,
	--				Width = 150, OnChanged = function(nv) v.Value = nv end,
	--				Parent = mount.Parent, AnchorPoint = mount.AnchorPoint, Position = mount.Position })

	--		elseif name == "Gameplay" then
	--			local meta = (META.Gameplay or {})[key]
	--			if type(v) == "boolean" or (meta and meta.kind == "toggle") then
	--				Classes.Toggle({ Value = v, OnChanged = function(nv) ns[key] = nv end,
	--				Parent = mount.Parent, AnchorPoint = mount.AnchorPoint, Position = mount.Position })
	--			elseif type(v) == "number" then
	--				Classes.Slider({ Min = meta and meta.min or 0, Max = meta and meta.max or 100,
	--					Step = meta and meta.step or 1, Value = v, Width = 150,
	--					OnChanged = function(nv) ns[key] = nv end,
	--					Parent = mount.Parent, AnchorPoint = mount.AnchorPoint, Position = mount.Position })
	--			end

	--		elseif name == "Controls" and type(v) == "table" then                         -- keybind
	--			Classes.Button({ Text = tostring(v.Value), Variant = "secondary", Size = UDim2.fromOffset(96, 30),
	--				OnClick = function() print("rebind", key) end,   -- hook your capture flow here
	--				Parent = mount.Parent, AnchorPoint = mount.AnchorPoint, Position = mount.Position })
	--		end
	--	end
	--end

	--tabs.OnChanged = render   -- Tabs also calls OnChanged internally; wire before first render
	--render(ORDER[1])
	--tabs.Set = tabs.Set       -- (Tabs already bound; arrows re-render via its OnChanged)
	---- rebind Tabs.OnChanged now that render exists:
	--return card.Instance
end

return Settings
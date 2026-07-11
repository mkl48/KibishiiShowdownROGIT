
-- InterfaceController  (Controller — client)
local Players = game:GetService("Players")
local InterfaceController = {}
InterfaceController.Priority = 0

function InterfaceController:Start(c)
	local Context = c._runtime
	local player  = Players.LocalPlayer

	local ScreenConfig = Context.Utilities.Config.Manifests.Interface.Screen

	local screen = Instance.new("ScreenGui")
	screen.Name = ScreenConfig.Name
	screen.ResetOnSpawn = ScreenConfig.ResetOnSpawn
	screen.IgnoreGuiInset = ScreenConfig.IgnoreGuiInset
	screen.ZIndexBehavior = ScreenConfig.ZIndexBehavior
	screen.DisplayOrder = ScreenConfig.DisplayOrder
	screen.Parent = player:WaitForChild("PlayerGui")

	-- load every _Class into a lookup (Theme/Base/Button/Toggle/…)
	local Classes = {}
	for _, mod in script._Classes:GetChildren() do
		if mod:IsA("ModuleScript") then
			local m = require(mod)
			if type(m) ~= "function" and type(m) ~= "table" then
				warn(`[Interface] class '{mod.Name}' returned unexpected type {type(m)}`)
			end
			Classes[mod.Name] = m
		end
	end

	-- the context injected into every element (mirrors what the Bootstrap gives controllers)
	local ctx = {
		Packages  = Context.Packages,
		Utilities = Context.Utilities,
		Config = Context.Utilities.Config,
		Services = Context.Modules,
		Classes   = Classes,
		Screen    = screen,
		Player    = player,
	}

	-- boot every _Element: require it, call :Start(ctx), collect its root
	local elements = {}
	for _, mod in script._Elements:GetChildren() do
		if mod:IsA("ModuleScript") then
			local el = require(mod)
			ctx.Source = mod.Name
			local ok, root = pcall(function() return el.Start and el:Start(ctx) or nil end)
			if not ok then warn(`[Interface] {mod.Name}:Start errored: {root}`) end
			elements[mod.Name] = { module = el, root = ok and root or nil, visible = false }
			if elements[mod.Name].root then elements[mod.Name].root.Visible = false end
		end
	end

	c:OnCleanup(function() screen:Destroy() end)
end

return InterfaceController
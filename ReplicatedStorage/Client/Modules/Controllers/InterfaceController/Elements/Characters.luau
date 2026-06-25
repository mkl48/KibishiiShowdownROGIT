local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage.Shared

local Modules = Shared.Modules
local Classes = Shared.Classes
local CharactersClass = Classes.Characters

local Characters = {}

function Characters:Start(context)
	warn(context)
	local Icon = context._runtime.Packages.Icon
	local Interface = context.interface
	
	local CharactersDropdown = Icon.new()
	:setLabel("Characters")
	:setOrder(1)
	:setDropdown()
	
	for _, Char in CharactersClass:GetChildren() do
		local Manifest = require(Char:FindFirstChild("Manifest")).MovesetOverview
		local Character = Icon.new()
		warn(Manifest)
		Character:setLabel(Manifest.Name)
		Character:oneClick(true)
		Character:joinDropdown(CharactersDropdown)
	
		Character.deselected:Connect(function(fromSource)
			Interface:SelectCharacter(Manifest.Name)
		end)

	end
end

return Characters
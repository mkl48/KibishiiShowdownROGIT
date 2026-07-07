local CharacterController = {}
CharacterController.Priority = 1

function CharacterController:Start(c)
	local Context = c._runtime
	local Network = Context.Network
	local Packages = Context.Packages
	local Input = warn(c:Local("Input"))
	
	Input:Post("Pressed", {
		Key = "W",
	})
end

return CharacterController
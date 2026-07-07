local CharacterController = {}
CharacterController.Priority = 1

function CharacterController:Start(c)
	local Context = c._runtime
	local Network = Context.Network
	local Packages = Context.Packages
	
	local Plinko = Packages.Plinko
	
	Plinko.Define("Controllers", {
			
	})
end

return CharacterController
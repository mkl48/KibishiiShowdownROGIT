local CharacterController = {}
CharacterController.Priority = 1

function CharacterController:Start(c)
	local Context = c._runtime
	local Network = Context.Network
	local Packages = Context.Packages
	
	local Plinko = Packages.Plinko
	
	--local Session = Plinko.define("Session", {
	--	schema     = {
				
	--	},      -- field -> default (required)
	--	key        = "Session",                        -- "player" (default) | "global"
	--})
end

return CharacterController
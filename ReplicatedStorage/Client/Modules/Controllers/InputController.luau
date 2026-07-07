local InputController = {}
InputController.Priority = 1

function InputController:Start(c)
	local Context = c._runtime
	local Network = Context.Network
	local Packages = Context.Packages
	
	local Switch = Packages.Switch
	local Signal = Packages.Signal
	
	
end

return InputController
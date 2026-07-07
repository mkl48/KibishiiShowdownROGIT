local InputController = {}
InputController.Priority = 0

function InputController:Start(c)
	local Context = c._runtime
	local Network = Context.Network
	local Packages = Context.Packages
	
	local Switch = Packages.Switch
	local Signal = Packages.Signal
	
	local Input = c:Local("Input")
	
	Input:Subscribe("Pressed", function()
		warn("YO")
	end)	
end

return InputController
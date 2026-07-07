local CharacterController = {}
CharacterController.Priority = 1

function CharacterController:Start(context)
	warn("CharacterController started")
	warn(context)
end

return CharacterController
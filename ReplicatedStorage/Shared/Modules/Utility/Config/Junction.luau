local Junction = {}

Junction.Network = {
	Combat = {
		
	},
}

Junction.Local = {
	Input = {
		Pressed = { Destination = "CharacterController", Side = "Client" },
	},

	Session = {
		Started = { Destination = "PlayerService", Side = "Client" },
		Patched = { Destination = "PlayerService", Side = "Client" },
	},
}

return Junction
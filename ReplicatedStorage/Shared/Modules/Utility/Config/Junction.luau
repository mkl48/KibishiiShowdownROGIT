local RunService = game:GetService("RunService")

local Junction = {}

Junction.Network = {
	Combat = {
		
	},

	Session = {
		Sync   = {},  -- Server -> Client: full session replacement
		Update = {},  -- Server -> Client: partial patch
	},

	Character = {
		Swap   = {},  -- Client -> Server: request character swap
		Reset  = {},  -- Server -> Client: battleground-style reset notification
	},
}

Junction.Local = {
	Input = {
		Pressed = { Side = "Client" },
		Released = { Side = "Client" },
		Held = { Side = "Client" },
		IsHolding = { Side = "Client" },
	},

	Session = {
		-- Server-side: SessionManager is the authority
		Patched = { Destination = "SessionManager", Side = "Server" },
		Get     = { Destination = "SessionManager", Side = "Server" },
		Started = { Side = "Server" },
		Changed = { Side = "Server" },

		-- Client-side: SessionController mirrors session data
		Synced  = { Destination = "SessionController", Side = "Client" },
		Updated = { Destination = "SessionController", Side = "Client" },
		Query   = { Destination = "SessionController", Side = "Client" },
		Notify  = { Side = "Client" },  -- SessionController broadcasts changes to other client modules

		-- Client-side query helpers (mirror of server getters)
		QueryHealth       = { Destination = "SessionController", Side = "Client" },
		QueryCharacter    = { Destination = "SessionController", Side = "Client" },
		QueryState        = { Destination = "SessionController", Side = "Client" },
		QueryStates       = { Destination = "SessionController", Side = "Client" },
		QueryStatus       = { Destination = "SessionController", Side = "Client" },
		QueryConditionals = { Destination = "SessionController", Side = "Client" },
		QueryStats        = { Destination = "SessionController", Side = "Client" },

		-- Server-side getter helpers
		GetHealth       = { Destination = "SessionManager", Side = "Server" },
		GetCharacter    = { Destination = "SessionManager", Side = "Server" },
		GetState        = { Destination = "SessionManager", Side = "Server" },
		GetStates       = { Destination = "SessionManager", Side = "Server" },
		GetStatus       = { Destination = "SessionManager", Side = "Server" },
		GetConditionals = { Destination = "SessionManager", Side = "Server" },
		GetStats        = { Destination = "SessionManager", Side = "Server" },

		-- Server-side setter helpers (fire-and-forget, apply patch + notify)
		SetHealth       = { Destination = "SessionManager", Side = "Server" },
		SetCharacter    = { Destination = "SessionManager", Side = "Server" },
		SetState        = { Destination = "SessionManager", Side = "Server" },
		SetAttackIndex  = { Destination = "SessionManager", Side = "Server" },
	},
	
	Character = {
		Swapped    = { Destination = "CharacterController", Side = "Client" },
		Reset      = { Side = "Client" },  -- Fired by CharacterService when server sends battleground reset
		Moveset    = { Destination = "CharacterService",     Side = "Client" },
		GetStats   = { Destination = "CharacterController", Side = "Client" },
		GetCurrent = { Destination = "CharacterController", Side = "Client" },
	},

	Game = {
		
	}
}

return Junction
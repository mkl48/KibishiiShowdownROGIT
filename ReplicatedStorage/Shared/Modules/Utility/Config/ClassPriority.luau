-- Kibishii Showdown
-- Shared/Modules/Utility/Config/ClassPriority.luau
--
-- Tier-based boot order for Controllers and Managers. Lower tier = boots first.
-- Modules absent from this map (and StandalonePriority) are appended last.
-- Only modules present on the current side are actually booted, so it is safe
-- to list both server (Manager) and client (Controller) entries here.

local ClassPriority = {
	[0] = {
		"SessionManager",         -- server: session authority, must be first
		"SessionController",     -- client: session sync, must be first
	},
	[1] = {
		"CharacterController",   -- client: depends on session
		"CharacterService",       -- client: character config service
	},
	[2] = {
		"InterfaceController",   -- client: UI layer
		"InputController",        -- client: input handling
	},
}

return ClassPriority
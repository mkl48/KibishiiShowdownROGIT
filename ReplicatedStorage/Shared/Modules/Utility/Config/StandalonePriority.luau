-- Kibishii Showdown
-- Shared/Modules/Utility/Config/StandalonePriority.luau
--
-- Numeric boot order for Services. Lower number = boots first.
-- Services boot after all class modules (Controllers/Managers) from ClassPriority.
-- Modules absent from both maps are appended last.

local StandalonePriority = {
	-- Server services
	PlayerService  = -1,  -- must set Keep schema before any player session loads
	CombatService  = 1,   -- combat logic, after session system is ready

	-- Client services
	-- (none currently need explicit ordering; they boot after controllers)
}

return StandalonePriority
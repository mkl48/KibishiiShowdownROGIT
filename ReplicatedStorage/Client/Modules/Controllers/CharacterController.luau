local CharacterController = {}
CharacterController.Priority = 2

function CharacterController:Start(c)
	local Context = c._runtime
	local Packages = Context.Packages
	local Utilities = Context.Utilities

	local Config = Utilities.Config
	local Schemas = Config.Schemas
	local Functions = Config.Functions
	local DeepCopy = Functions.DeepCopy
	local Defaults = Config.Manifests.Game.Defaults

	local Session = c:Local("Session")
	local Input  = c:Local("Input")
	local Character = c:Local("Character")

	local stats = {
		Health      = Defaults.Health,
		AttackIndex = Defaults.AttackIndex,
	}

	local states = {}
	local conditionals = {}
	local currentCharacter = nil

	-- Pull initial values from the session
	local function refreshFromSession()
		local sessionData = Session:Request("Query")
		if type(sessionData) ~= "table" then return end

		if sessionData.Context then
			if sessionData.Context.Status then
				stats.Health      = sessionData.Context.Status.Health or stats.Health
				stats.AttackIndex = sessionData.Context.Status.AttackIndex or stats.AttackIndex
			end
			if sessionData.Context.States then
				states = DeepCopy(sessionData.Context.States)
			end
			if sessionData.Context.Conditionals then
				conditionals = DeepCopy(sessionData.Context.Conditionals)
			end
			if sessionData.Context.Character then
				currentCharacter = sessionData.Context.Character.Current
			end
		end
	end

	refreshFromSession()

	-- Live update: SessionController broadcasts Notify after every network sync
	Session:Subscribe("Notify", function(sessionData)
		if type(sessionData) ~= "table" then return end
		if sessionData.Context then
			if sessionData.Context.Status then
				stats.Health      = sessionData.Context.Status.Health      or stats.Health
				stats.AttackIndex = sessionData.Context.Status.AttackIndex or stats.AttackIndex
			end
			if sessionData.Context.States then
				states = DeepCopy(sessionData.Context.States)
			end
			if sessionData.Context.Conditionals then
				conditionals = DeepCopy(sessionData.Context.Conditionals)
			end
			local newChar = sessionData.Context.Character and sessionData.Context.Character.Current
			if newChar then
				currentCharacter = newChar
			end
		end
	end)

	-----------------------------------------------------------------------
	-- Character swap — CharacterService fires this when SetMoveset is called
	-----------------------------------------------------------------------

	Character:Subscribe("Swapped", function(characterName)
		currentCharacter = characterName
	end)

	-----------------------------------------------------------------------
	-- Input routing — forward input events to the character/moveset layer
	-----------------------------------------------------------------------

	Input:Subscribe("Pressed", function(data)
		if states.Dead then return end
		-- Route to CharacterService / combat system based on current moveset
		Character:Post("Moveset", {
			Action   = "Pressed",
			Key      = data.Key,
			Character = currentCharacter,
		})
	end)

	Input:Subscribe("Released", function(data)
		if states.Dead then return end
		Character:Post("Moveset", {
			Action    = "Released",
			Key       = data.Key,
			Character = currentCharacter,
		})
	end)

	Input:Subscribe("Held", function(data)
		if states.Dead then return end
		Character:Post("Moveset", {
			Action    = "Held",
			Key       = data.Key,
			Character = currentCharacter,
		})
	end)

	-----------------------------------------------------------------------
	-- Convenience accessors for other modules
	-----------------------------------------------------------------------

	-- Other modules can query live stats via Character:Request("GetStats")
	Character:Respond("GetStats", function()
		return {
			Health      = stats.Health,
			AttackIndex = stats.AttackIndex,
			States      = DeepCopy(states),
			Conditionals = DeepCopy(conditionals),
			Current     = currentCharacter,
		}
	end)

	Character:Respond("GetCurrent", function()
		return currentCharacter
	end)

	-- Cleanup
	c:OnCleanup(function()
		stats = nil
		states = nil
		conditionals = nil
		currentCharacter = nil
	end)
end

return CharacterController
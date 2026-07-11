-- Kibishii Showdown
-- ServerStorage/Modules/Managers/SessionManager.luau
--
-- Server-side session authority. Owns the lifecycle of every player's PlayerSession:
-- creates from Schemas._Structures.PlayerSession on join, validates patches through
-- Schemas._Policies (SessionPatch, NetworkPolicy), and notifies other server modules
-- via Local.Session events (Started, Changed). Networking (cross-side replication to
-- the client's SessionController) is wired separately. Uses PlayerService for player
-- tracking via the sanctioned GetService direct call.

local Players = game:GetService("Players")

local SessionManager = {}
SessionManager.Priority = 0

function SessionManager:Start(c)
	local Context = c._runtime
	local Utilities = Context.Utilities
	local Config = Utilities.Config
	local Schemas = Config.Schemas
	local Enums = Config.Enums
	local Functions = Config.Functions
	local DeepCopy = Functions.DeepCopy
	local DeepMerge = Functions.DeepMerge
	local GetPath = Functions.GetPath
	local SetPath = Functions.SetPath

	local PlayerService = c:GetService("PlayerService")
	local Session = c:Local("Session")
	local SessionNet = c:Network("Session")
	local CharacterNet = c:Network("Character")

	local JobId = Enums.Common.JobId

	-- Validate a value against a named policy in Schemas._Policies
	local function checkPolicy(policyName, value)
		local policy = Schemas.GetPolicy(policyName)
		if not policy then return false, "Policy not found: " .. policyName end
		if policy.Type and typeof(value) ~= policy.Type then
			return false, policyName .. " must be a " .. policy.Type
		end
		if policy.Validate then
			return policy.Validate(value)
		end
		return true
	end

	-- Internal session storage: [player] = session table
	local sessions = {}

	-- Switch cooldown tracking: [player] = lastSwitchTime
	local switchCooldowns = {}

	-- Battlegrounds reset config shortcut
	local bgConfig = Config.Manifests.Game.Battleground
	local defaults = Config.Manifests.Game.Defaults

	-- Validate that a character name exists in the manifest
	local function isValidCharacter(name)
		local chars = Config.Manifests.Characters
		return chars ~= nil and chars[name] ~= nil
	end

	-- Create a fresh session from the PlayerSession structure
	local function createSession(player)
		local s = Schemas.Instantiate("PlayerSession")
		local manifest = Config.Manifests.Game
		if manifest and manifest.DefaultCharacter then
			s.Context.Character.Current = manifest.DefaultCharacter
		end
		sessions[player] = s
		return s
	end

	-- Get a session (optionally at a specific dot-path)
	local function getSession(player, path)
		local s = sessions[player]
		if not s then return nil end
		if path and type(path) == "string" and path ~= "" then
			return GetPath(s, path)
		end
		return s
	end

	-- Convenience: apply a path patch, fire Changed, and sync to client
	local function patchAndSync(player, path, value)
		local s = sessions[player]
		if not s then return false, "No session for player" end

		SetPath(s, path, value)
		Session:Post("Changed", player, DeepCopy(s))
		SessionNet:PostTo(player, "Sync", DeepCopy(s))
		return true
	end

	-- Apply a path-based patch: { Path = "...", Value = ... }
	local function applyPathPatch(player, patch)
		local s = sessions[player]
		if not s then return false, "No session for player" end

		local ok, err = checkPolicy("SessionPatch", patch)
		if not ok then
			return false, err
		end

		SetPath(s, patch.Path, patch.Value)
		return true
	end

	-- Apply a deep-merge patch: { Job = JobId.Patch, Data = { ... } }
	local function applyMergePatch(player, data)
		local s = sessions[player]
		if not s then return false, "No session for player" end

		local merged = DeepMerge(s, data)
		local ok, err = Schemas.Verify("PlayerSession", DeepCopy(merged))
		if not ok then
			return false, err
		end

		sessions[player] = merged
		return true
	end

	-- Apply a full session replace: { Job = JobId.Post, Data = { ... } }
	local function applyFullSync(player, data)
		local validated = DeepCopy(data)
		local ok, err = Schemas.Verify("PlayerSession", validated)
		if not ok then
			return false, err
		end

		sessions[player] = validated
		return true
	end

	-- Player lifecycle
	local function onPlayerAdded(player)
		if PlayerService then
			PlayerService:CreatePlayer(player)
		end

		local s = createSession(player)

		-- Notify all server modules that a session has started
		Session:Post("Started", player, DeepCopy(s))
	end

	local function onPlayerRemoving(player)
		sessions[player] = nil
		switchCooldowns[player] = nil
	end

	-- Handle existing players (already in game when manager boots)
	for _, player in Players:GetPlayers() do
		onPlayerAdded(player)
	end

	-- Handle future players
	local addedConn = Players.PlayerAdded:Connect(onPlayerAdded)
	local removingConn = Players.PlayerRemoving:Connect(onPlayerRemoving)

	-- Handle patch requests from other server modules
	-- Supports two formats:
	--   { Path = "Context.Status.Health", Value = 80 }   (path-based, SessionPatch policy)
	--   { Job = JobId.Patch, Data = { ... } }               (deep-merge, NetworkPolicy)
	--   { Job = JobId.Post,  Data = { ... } }               (full replace, NetworkPolicy)
	Session:Subscribe("Patched", function(player, payload)
		if typeof(player) ~= "Instance" or not player:IsA("Player") then
			return
		end

		-- Path-based patch
		if payload.Path then
			local success, err = applyPathPatch(player, payload)
			if not success then
				warn(("[SessionManager] Patch (path) failed for %s: %s"):format(player.Name, err or "unknown"))
				return
			end
		else
			-- Envelope-based patch (NetworkPolicy)
			local ok, err = checkPolicy("NetworkPolicy", payload)
			if not ok then
				warn(("[SessionManager] Patch rejected (envelope): %s"):format(err or "invalid"))
				return
			end

			local job = payload.Job
			local data = payload.Data

			if job == JobId.Patch then
				local success, perr = applyMergePatch(player, data)
				if not success then
					warn(("[SessionManager] Merge patch failed for %s: %s"):format(player.Name, perr))
					return
				end
			elseif job == JobId.Post then
				local success, perr = applyFullSync(player, data)
				if not success then
					warn(("[SessionManager] Full sync failed for %s: %s"):format(player.Name, perr))
					return
				end
			else
				warn(("[SessionManager] Unknown job type: %s"):format(tostring(job)))
				return
			end
		end

		-- Notify all server modules that the session changed
		Session:Post("Changed", player, DeepCopy(sessions[player]))

		-- Sync the full updated session to the client
		SessionNet:PostTo(player, "Sync", DeepCopy(sessions[player]))
	end)

	-- Respond to session data requests
	-- Usage: Session:Request("Get", player)             -> full session
	--        Session:Request("Get", player, "Context.Status.Health") -> value at path
	Session:Respond("Get", function(player, path)
		return getSession(player, path)
	end)

	-----------------------------------------------------------------------
	-- Server-side getter helpers (Respond — other modules query via Request)
	-----------------------------------------------------------------------

	Session:Respond("GetHealth", function(player)
		return getSession(player, "Context.Status.Health")
	end)

	Session:Respond("GetCharacter", function(player)
		return getSession(player, "Context.Character.Current")
	end)

	Session:Respond("GetState", function(player, stateName)
		return getSession(player, "Context.States." .. tostring(stateName))
	end)

	Session:Respond("GetStates", function(player)
		return getSession(player, "Context.States")
	end)

	Session:Respond("GetStatus", function(player)
		return getSession(player, "Context.Status")
	end)

	Session:Respond("GetConditionals", function(player)
		return getSession(player, "Context.Conditionals")
	end)

	Session:Respond("GetStats", function(player)
		return getSession(player, "Statistics")
	end)

	-----------------------------------------------------------------------
	-- Server-side setter helpers (Subscribe — other modules fire via Post)
	-- Each applies a path patch, fires Local Changed, and Network Syncs to the client.
	-----------------------------------------------------------------------

	Session:Subscribe("SetHealth", function(player, health)
		patchAndSync(player, "Context.Status.Health", health)
	end)

	Session:Subscribe("SetCharacter", function(player, characterName)
		patchAndSync(player, "Context.Character.Current", characterName)
	end)

	Session:Subscribe("SetState", function(player, stateName, value)
		patchAndSync(player, "Context.States." .. tostring(stateName), value)
	end)

	Session:Subscribe("SetAttackIndex", function(player, index)
		patchAndSync(player, "Context.Status.AttackIndex", index)
	end)

	-----------------------------------------------------------------------
	-- Network: Character swap request from the client (battlegrounds-style reset)
	-----------------------------------------------------------------------

	CharacterNet:Subscribe("Swap", function(characterName, player)
		if typeof(player) ~= "Instance" or not player:IsA("Player") then return end
		if type(characterName) ~= "string" or characterName == "" then return end

		-- Validate character exists in manifest
		if not isValidCharacter(characterName) then return end
		if characterName == getSession(player, "Context.Character.Current") then
			warn("Sending Notification: Invalid character name or already selected.")
			return
		end

		-- Enforce switch cooldown
		local now = os.clock()
		local lastSwitch = switchCooldowns[player]
		if lastSwitch and (now - lastSwitch) < bgConfig.SwitchCooldown then
			return
		end
		switchCooldowns[player] = now

		local s = sessions[player]
		if not s then return end
		
		local char = player.Character :: Model
		if not char then return end
		
		-- Update character name
		s.Context.Character.Current = characterName

		-- Reset health to default
		if bgConfig.ResetHealth then
			s.Context.Status.Health = defaults.Health
		end

		-- Reset attack index
		s.Context.Status.AttackIndex = defaults.AttackIndex

		-- Reset all states to false
		if bgConfig.ResetStates and s.Context.States then
			for stateName in s.Context.States do
				s.Context.States[stateName] = false
			end
		end

		-- Reset all conditionals
		if bgConfig.ResetConditionals and s.Context.Conditionals then
			for condName, condValue in s.Context.Conditionals do
				if type(condValue) == "table" then
					condValue.Effective = false
				else
					s.Context.Conditionals[condName] = false
				end
			end
		end

		-- Reset status effects
		if bgConfig.ResetEffects and s.Context.Status.Effects then
			for effectName, effectValue in s.Context.Status.Effects do
				if type(effectValue) == "table" then
					effectValue.Effective = false
				else
					s.Context.Status.Effects[effectName] = false
				end
			end
		end

		-- Reset combat combo via CombatService if available
		if bgConfig.ResetCombo then
			local CombatService = c:GetService("CombatService")
			if CombatService and CombatService.Combo then
				CombatService.Combo[player] = nil
			end
		end

		-- Respawn the character (battlegrounds-style)
		if bgConfig.RespawnCharacter then
			player:LoadCharacter()
		end

		Session:Post("Changed", player, DeepCopy(s))
		SessionNet:PostTo(player, "Sync", DeepCopy(s))
		CharacterNet:PostTo(player, "Reset", characterName)
	end)

	-- Cleanup
	c:OnCleanup(function()
		if addedConn then addedConn:Disconnect() end
		if removingConn then removingConn:Disconnect() end
		table.clear(sessions)
		table.clear(switchCooldowns)
	end)
end

function SessionManager:Stop()
end

return SessionManager
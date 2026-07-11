-- Kibishii Showdown
-- Client/Modules/Controllers/SessionController.luau
--
-- Client-side session mirror. Holds a local copy of the player's PlayerSession,
-- kept in sync with the server's SessionManager through Local.Session events.
-- Networking (the bridge between this and the server) is wired separately.
-- Uses Schemas._Structures.PlayerSession for the session shape, Schemas._Policies
-- for validation, and Config.Enums for job types.

local SessionController = {}
SessionController.Priority = 1

function SessionController:Start(c)
	local Context = c._runtime
	local Utilities = Context.Utilities
	local Config = Utilities.Config
	local Schemas = Config.Schemas
	local Functions = Config.Functions
	local Enums = Config.Enums
	local DeepCopy = Functions.DeepCopy
	local DeepMerge = Functions.DeepMerge
	local GetPath = Functions.GetPath
	local SetPath = Functions.SetPath

	local JobId = Enums.Common.JobId
	local SessionPaths = Config.Manifests.Session.Paths

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

	local Session = c:Local("Session")
	local SessionNet = c:Network("Session")

	-- Local session mirror, resolved from the PlayerSession structure
	local session = Schemas.Instantiate("PlayerSession")

	-- Apply manifest defaults
	local manifest = Config.Manifests.Game
	if manifest and manifest.DefaultCharacter then
		session.Context.Character.Current = manifest.DefaultCharacter
	end

	-- Notify: broadcast to other client modules that the session changed
	local function notifyChange()
		Session:Post("Notify", DeepCopy(session))
	end

	-- Network: full session sync from server (SessionManager -> here)
	SessionNet:Subscribe("Sync", function(data)
		if type(data) ~= "table" then return end

		local validated = DeepCopy(data)
		local ok, err = Schemas.Verify("PlayerSession", validated)
		if not ok then
			warn(("[SessionController] Sync rejected: %s"):format(err or "invalid"))
			return
		end

		session = validated
		notifyChange()
	end)

	-- Network: partial patch from server (SessionManager -> here)
	-- Supports two formats:
	--   { Path = "Context.Status.Health", Value = 80 }   (path-based, SessionPatch policy)
	--   { Job = JobId.Patch, Data = { ... } }               (deep-merge, NetworkPolicy)
	SessionNet:Subscribe("Update", function(patch)
		if type(patch) ~= "table" then return end

		-- Path-based patch
		if patch.Path then
			local ok, err = checkPolicy("SessionPatch", patch)
			if not ok then
				warn(("[SessionController] Update (path) rejected: %s"):format(err or "invalid"))
				return
			end
			SetPath(session, patch.Path, patch.Value)
		notifyChange()
			return
		end

		-- Deep-merge patch (NetworkPolicy envelope)
		if patch.Job and patch.Data then
			local ok, err = checkPolicy("NetworkPolicy", patch)
			if not ok then
				warn(("[SessionController] Update (merge) rejected: %s"):format(err or "invalid"))
				return
			end

			local merged = DeepMerge(session, patch.Data)
			local vok, verr = Schemas.Verify("PlayerSession", DeepCopy(merged))
			if not vok then
				warn(("[SessionController] Update merge invalid: %s"):format(verr or "invalid"))
				return
			end

			session = merged
			notifyChange()
		end
	end)

	-- Query: other client modules request session data
	-- Usage: Session:Request("Query")                          -> full session
	--        Session:Request("Query", "Context.Status.Health")  -> value at path
	Session:Respond("Query", function(path)
		if path and type(path) == "string" and path ~= "" then
			return GetPath(session, path)
		end
		return DeepCopy(session)
	end)

	-----------------------------------------------------------------------
	-- Client-side getter helpers (Respond — other client modules query via Request)
	-----------------------------------------------------------------------

	Session:Respond("QueryHealth", function()
		return GetPath(session, SessionPaths.Health)
	end)

	Session:Respond("QueryCharacter", function()
		return GetPath(session, SessionPaths.Character)
	end)

	Session:Respond("QueryState", function(stateName)
		return GetPath(session, SessionPaths.StatesPrefix .. tostring(stateName))
	end)

	Session:Respond("QueryStates", function()
		return GetPath(session, SessionPaths.States)
	end)

	Session:Respond("QueryStatus", function()
		return GetPath(session, SessionPaths.Status)
	end)

	Session:Respond("QueryConditionals", function()
		return GetPath(session, SessionPaths.Conditionals)
	end)

	Session:Respond("QueryStats", function()
		return GetPath(session, SessionPaths.Statistics)
	end)

	-- Cleanup
	c:OnCleanup(function()
		session = nil
	end)
end

return SessionController

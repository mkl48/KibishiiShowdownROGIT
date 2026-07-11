-- Kibishii Showdown
-- ServerStorage/Modules/Services/PlayerService.luau
--
-- Owns player sessions (join/leave). On join, loads the player's profile from the
-- DataStore via Keep and patches the SessionManager's session with the saved data
-- (settings, statistics, last character selection). Keep handles auto-save and
-- profile release on leave; this module just bridges profile data into the session.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Keep = require(ServerStorage.Modules.Packages.Keep)

local PlayerService = {}
PlayerService.Sessions = {} -- [player] = PlayerExport

-- Cached context references (set in Start)
local _sessionChannel  -- context:Local("Session") for posting patches
local _jobId           -- Enums.Common.JobId for patch envelopes

export type PlayerExport = {
	Profile: any?,
	Session: { any },
	Instance: Player,
}

function PlayerService:Start(context)
	local runtime = context._runtime
	if not runtime then
		warn("[PlayerService] No runtime on context -- aborting")
		return
	end

	local Config = runtime.Utilities and runtime.Utilities.Config
	if not Config then
		warn("[PlayerService] No Config in runtime.Utilities -- aborting")
		return
	end

	local Schemas = Config.Schemas
	local Enums = Config.Enums
	if not Schemas or not Enums then
		warn("[PlayerService] Missing Schemas or Enums in Config -- aborting")
		return
	end

	_jobId = Enums.Common.JobId
	_sessionChannel = context:Local("Session")

	-- Register the PlayerProfile schema with Keep so it knows the default data shape
	local profileDefaults = Schemas.Instantiate("PlayerProfile")
	Keep.SetSchema("PlayerProfile", profileDefaults)
end

function PlayerService:CreatePlayer(player: Player): PlayerExport
	local export: PlayerExport = { Instance = player, Profile = nil, Session = {} }
	self.Sessions[player] = export

	-- Asynchronously load the player's profile from the DataStore
	Keep.StartPlayerSession(player)
		:next(function(stores)
			local profileHandle = stores and stores["PlayerProfile"]
			export.Profile = profileHandle

			if profileHandle then
				local profileData = profileHandle:GetAll()
				self:ApplyProfileToSession(player, profileData)
			end
		end)
		:catch(function(err)
			warn(("[PlayerService] Failed to load profile for %s: %s"):format(player.Name, tostring(err)))
		end)

	return export
end

-- Map profile data (from Keep/DataStore) into the session structure and send a
-- merge patch to SessionManager. Only fields that exist in both structures are
-- carried over; the rest of the session keeps its defaults.
function PlayerService:ApplyProfileToSession(player: Player, profileData: any)
	if type(profileData) ~= "table" then return end
	if not _sessionChannel or not _jobId then return end

	local patch = {}

	-- Settings.Audio → Session.Settings.Audio
	local pSettings = profileData.Settings
	if pSettings then
		if type(pSettings.Audio) == "table" then
			patch.Settings = patch.Settings or {}
			patch.Settings.Audio = pSettings.Audio
		end

		-- Settings.Gameplay → Session.Settings.Gameplay (only overlapping fields)
		if type(pSettings.Gameplay) == "table" then
			patch.Settings = patch.Settings or {}
			local gp = pSettings.Gameplay
			patch.Settings.Gameplay = {
				CameraSensitivity = gp.CameraSensitivity,
				ShiftLockEnabled = gp.ShiftLockEnabled,
				FieldOfView = gp.FieldOfView,
			}
		end

		-- Settings.Controls → Session.Settings.Controls
		if type(pSettings.Controls) == "table" then
			patch.Settings = patch.Settings or {}
			patch.Settings.Controls = pSettings.Controls
		end
	end

	-- Statistics.Kills → Session.Statistics.Kills
	if type(profileData.Statistics) == "table" and profileData.Statistics.Kills ~= nil then
		patch.Statistics = { Kills = profileData.Statistics.Kills }
	end

	-- Session.Character.Current → Session.Context.Character.Current
	if profileData.Session and profileData.Session.Character and profileData.Session.Character.Current then
		patch.Context = patch.Context or {}
		patch.Context.Character = { Current = profileData.Session.Character.Current }
	end

	-- Only post if we actually have something to patch
	if next(patch) ~= nil then
		_sessionChannel:Post("Patched", player, {
			Job = _jobId.Patch,
			Data = patch,
		})
	end
end

function PlayerService:GetPlayer(player: Player): PlayerExport?
	return self.Sessions[player]
end

-- Keep already auto-releases profiles on PlayerRemoving, so we just clean up our own tracking.
Players.PlayerRemoving:Connect(function(player)
	PlayerService.Sessions[player] = nil
end)

return PlayerService

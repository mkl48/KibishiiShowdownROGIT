-- Kibishii Showdown
-- Client/Modules/Services/CharacterService.luau
--
-- Client-side character domain service. Loads character configs and movesets from
-- ReplicatedStorage.Shared.Classes.Characters, exposes SetMoveset / GetMoveset
-- helpers, and bridges character swaps to the server via Network.Character.Swap.
-- GetMoveset returns a rich object with the character's config, move modules,
-- and convenience accessors.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CharacterService = {}
CharacterService.Priority = 1

-- Root folder containing all character definitions
local CharactersRoot = ReplicatedStorage:WaitForChild("Shared").Classes.Characters


local currentName = nil
local currentConfig = nil
local currentMoveset = nil  -- { [class] = { [name] = module, ... } }

-- Stored scopes from :Start() so public API functions don't need `c`
local _Character    = nil  -- Local channel: Character
local _CharacterNet = nil  -- Network channel: Character
local _Session      = nil  -- Local channel: Session

-----------------------------------------------------------------------
-- Helpers
-----------------------------------------------------------------------

-- Recursively load all ModuleScripts under a folder into a table
local function loadFolder(folder)
	local out = {}
	for _, child in folder:GetChildren() do
		if child:IsA("ModuleScript") then
			local ok, result = pcall(require, child)
			if ok then
				out[child.Name] = result
			else
				warn(("[CharacterService] Failed to load %s: %s"):format(child:GetFullName(), tostring(result)))
			end
		elseif child:IsA("Folder") then
			out[child.Name] = loadFolder(child)
		end
	end
	return out
end

-- Load a character's config and moveset from the Shared.Classes.Characters folder
local function loadCharacter(name)
	local charFolder = CharactersRoot:FindFirstChild(name)
	if not charFolder then
		return nil, nil, ("Character '%s' not found"):format(name)
	end

	-- Config module
	local configModule = charFolder:FindFirstChild("Config")
	local config = nil
	if configModule and configModule:IsA("ModuleScript") then
		local ok, result = pcall(require, configModule)
		if ok then
			config = result
		else
			warn(("[CharacterService] Failed to load Config for %s: %s"):format(name, tostring(result)))
		end
	end

	-- Moveset folder
	local moveset = {}
	local movesetFolder = charFolder:FindFirstChild("Moveset")
	if movesetFolder and movesetFolder:IsA("Folder") then
		for _, classFolder in movesetFolder:GetChildren() do
			if classFolder:IsA("Folder") then
				moveset[classFolder.Name] = loadFolder(classFolder)
			end
		end
	end

	return config, moveset, nil
end

-- Build the moveset helper object returned by GetMoveset()
local function buildMovesetObject(name, config, moveset)
	local overview = config and config.MovesetOverview or {}
	return {
		Name    = name,
		Config  = config,

		-- Returns the character's display name
		GetName = function()
			return name
		end,

		-- Get the raw config manifest
		GetConfig = function()
			return config
		end,

		-- Get the MovesetOverview block
		GetOverview = function()
			return overview
		end,

		-- Get all loaded move classes (e.g. "Base", "Melee", "Movement")
		GetClasses = function()
			local classes = {}
			for className in moveset do
				table.insert(classes, className)
			end
			return classes
		end,

		-- Get all moves for a specific class
		GetMoves = function(className)
			return moveset[className]
		end,

		-- Get a specific move module by class and name
		GetMove = function(className, moveName)
			local class = moveset[className]
			if not class then return nil end
			return class[moveName]
		end,

		-- Get the move order for a class from the config
		-- Returns a table like { [1] = "Doo Doo Duel", ["Special"] = "Shin No Kachi" }
		GetOrder = function(className)
			return overview.Order and overview.Order[className] or nil
		end,

		-- Get the movement set for a class from the config
		-- Returns a table like { Dash = {...}, Move = {...} }
		GetMovement = function(className)
			return overview.Movement and overview.Movement[className] or nil
		end,

		-- Check if a specific move exists in the loaded moveset
		HasMove = function(className, moveName)
			return moveset[className] ~= nil and moveset[className][moveName] ~= nil
		end,
	}
end

-----------------------------------------------------------------------
-- Public API
-----------------------------------------------------------------------

-- SetMoveset: change the current character. Loads the character's config +
-- moveset, stores them, fires Local Character.Swapped, and sends a Network
-- Character.Swap request to the server so the session updates.
function CharacterService.SetMoveset(name)
	if type(name) ~= "string" or name == "" then
		warn("[CharacterService] SetMoveset requires a character name string")
		return false
	end

	local config, moveset, err = loadCharacter(name)
	if err then
		warn(("[CharacterService] %s"):format(err))
		return false
	end

	currentName    = name
	currentConfig  = config
	currentMoveset = moveset

	-- Notify the CharacterController locally
	if _Character then
		_Character:Post("Swapped", name)
	end

	-- Notify the server to update the session's character
	if _CharacterNet then
		_CharacterNet:Post("Swap", name)
	end

	return true
end

-- GetMoveset: returns the current character's moveset helper object, or nil
-- if no character is loaded. The returned object contains:
--   .Name, .Config, .GetName(), .GetConfig(), .GetOverview(),
--   .GetClasses(), .GetMoves(class), .GetMove(class, name),
--   .GetOrder(class), .GetMovement(class), .HasMove(class, name)
function CharacterService.GetMoveset()
	if not currentName then return nil end
	return buildMovesetObject(currentName, currentConfig, currentMoveset)
end

-- GetCurrent: returns the name of the currently loaded character
function CharacterService.GetCurrent()
	return currentName
end

-- ListCharacters: returns an array of all available character names
function CharacterService.ListCharacters()
	local names = {}
	for _, child in CharactersRoot:GetChildren() do
		if child:IsA("Folder") then
			table.insert(names, child.Name)
		end
	end
	return names
end

-- GetMovesets: returns an array of ALL available characters, each with .Name,
-- .Folder, .Config, and .Moveset (a flat array of move objects with .Name, .Class, .Icon).
-- This loads every character folder on demand — use sparingly (UI boot, not per-frame).
function CharacterService.GetMovesets()
	local out = {}
	for _, child in CharactersRoot:GetChildren() do
		if not child:IsA("Folder") then continue end

		local name    = child.Name
		local config  = nil
		local moveset = {}

		-- Load config
		local configModule = child:FindFirstChild("Config")
		if configModule and configModule:IsA("ModuleScript") then
			local ok, result = pcall(require, configModule)
			if ok then config = result end
		end

		-- Load moveset into a flat list
		local movesetFolder = child:FindFirstChild("Moveset")
		if movesetFolder and movesetFolder:IsA("Folder") then
			for _, classFolder in movesetFolder:GetChildren() do
				if not classFolder:IsA("Folder") then continue end
				for _, moveModule in classFolder:GetChildren() do
					if not moveModule:IsA("ModuleScript") then continue end
					local ok, move = pcall(require, moveModule)
					if ok and type(move) == "table" then
						table.insert(moveset, {
							Name   = move.Name or moveModule.Name,
							Class  = move.Class or classFolder.Name,
							Icon   = move.Icon,
							Module = move,
						})
					end
				end
			end
		end

		local displayName = (config and config.MovesetOverview and config.MovesetOverview.Name) or name

		table.insert(out, {
			Name    = displayName,
			Folder  = name,
			Config  = config,
			Moveset = moveset,
		})
	end
	return out
end

function CharacterService:Start(c)
	local Context = c._runtime
	local Utilities = Context.Utilities
	local Config = Utilities.Config
	local Schemas = Config.Schemas
	local Functions = Config.Functions

	local bgConfig = Config.Manifests.Game.Battleground

	_Character    = c:Local("Character")
	_CharacterNet = c:Network("Character")
	_Session      = c:Local("Session")

	-- Auto-load the default character from the session on boot
	local sessionData = _Session:Request("Query"):Await()
	if sessionData and sessionData.Context and sessionData.Context.Character then
		local defaultChar = sessionData.Context.Character.Current
		if defaultChar and defaultChar ~= "" then
			local config, moveset = loadCharacter(defaultChar)
			if config then
				currentName    = defaultChar
				currentConfig  = config
				currentMoveset = moveset
			end
		end
	end

	-- Respond to moveset requests from other modules (e.g. CharacterController routing input)
	_Character:Respond("Moveset", function(payload)
		if not currentMoveset then return nil end

		if type(payload) == "table" and payload.Action and payload.Key then
			-- Input routing: look up the control name from the payload
			-- and return the corresponding move if found
			return {
				Name    = currentName,
				Config  = currentConfig,
				Moveset = currentMoveset,
			}
		end

		-- Generic query: return the full moveset object
		return buildMovesetObject(currentName, currentConfig, currentMoveset)
	end)

	-----------------------------------------------------------------------
	-- Battlegrounds-style reset: server fires this after a full character reset
	-----------------------------------------------------------------------

	--_CharacterNet:Subscribe("Reset", function(characterName)
		-- Ensure the moveset is loaded for the new character
		--if characterName and characterName ~= currentName then
		--	local config, moveset = loadCharacter(characterName)
		--	if config then
		--		currentName    = characterName
		--		currentConfig  = config
		--		currentMoveset = moveset
		--		_Character:Post("Swapped", characterName)
		--	end
		--end

		---- Notify other client modules that a battleground reset occurred
		--_Character:Post("Reset", characterName)

		---- Play visual invulnerability effect on the player's character
		--local Players = game:GetService("Players")
		--local player = Players.LocalPlayer
		--if not player then return end

		--local invulnTime = bgConfig.InvulnerabilityTime
		--task.spawn(function()
		--	local character = player.Character or player.CharacterAdded:Wait()
		--	local humanoid = character:WaitForChild("Humanoid", 5)
		--	if not humanoid then return end

		--	-- Create a Highlight for the invulnerability visual
		--	local highlight = Instance.new("Highlight")
		--	highlight.FillColor = Color3.fromRGB(255, 255, 255)
		--	highlight.FillTransparency = 0.5
		--	highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
		--	highlight.OutlineTransparency = 0
		--	highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
		--	highlight.Parent = character

		--	-- Flash the character's transparency for the invulnerability duration
		--	local elapsed = 0
		--	local flashInterval = 0.15
		--	local lastFlash = 0
		--	local flashOn = false

		--	while elapsed < invulnTime and humanoid.Health > 0 do
		--		task.wait(0.03)
		--		elapsed += 0.03

		--		if elapsed - lastFlash >= flashInterval then
		--			lastFlash = elapsed
		--			flashOn = not flashOn
		--			for _, part in character:GetDescendants() do
		--				if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
		--					part.Transparency = flashOn and 0.5 or 0
		--				end
		--			end
		--		end
		--	end

		--	-- Restore character appearance
		--	for _, part in character:GetDescendants() do
		--		if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
		--			part.Transparency = 0
		--		end
		--	end

		--	-- Remove the highlight
		--	if highlight and highlight.Parent then
		--		highlight:Destroy()
		--	end
		--end)
	--end)

	-- Cleanup
	c:OnCleanup(function()
		currentName    = nil
		currentConfig  = nil
		currentMoveset = nil
		_Character      = nil
		_CharacterNet   = nil
		_Session        = nil
	end)
end

return CharacterService

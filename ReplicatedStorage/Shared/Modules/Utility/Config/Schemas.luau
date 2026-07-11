local Schemas = {}

local Functions = require(script.Parent.Functions)

local Inherit = Functions.Inherit
local DeepCopy = Functions.DeepCopy
local Bind = Functions.Bind
local Extend = Functions.Extend

Schemas._Common = {
	Templates = {
		Volume = {
			Type = "number",
			Minimum = 0,
			Maximum = 100,
			Default = 100,
			Step = 2,
			Value = 100
		},
		Statistic = {
			Type = "number",
			Default = 0,
			Value = 0
		},
		Conditional = {
			Effective = false
		},
		NetworkPayload = {
			Job = "",
			Data = {}
		}
	}
}

local T = Schemas._Common.Templates

Schemas._Structures = {
	PlayerSession = {
		Settings = {
			Audio = {
				Music = Inherit(T.Volume),
				Effects = Inherit(T.Volume),
				General = Inherit(T.Volume),
			},
			Gameplay = {
				CameraSensitivity = 1.0,
				ShiftLockEnabled = true,
				FieldOfView = 70,
				AutoRun = false,
				AutoUse = false,
			},
			Controls = {
				Attack = Bind("MouseButton1"),
				Block = Bind("F"),
				Special = Bind("R"),
				
				Dash = Bind("Q"),
				Run = Bind("LeftControl"),
				Finality = Bind("G"),
				
				ShiftLock = Bind("LeftShift"),
				Emote = Bind("B"),

				Skill1 = Bind("One"),
				Skill2 = Bind("Two"),
				Skill3 = Bind("Three"),
				Skill4 = Bind("Four"),
				Skill5 = Bind("Five"),
				Skill6 = Bind("Six"),
				Skill7 = Bind("Seven"),
				Skill8 = Bind("Eight"),
				Skill9 = Bind("Nine"),
				Skill0 = Bind("Zero"),
			}
		},

		Statistics = {
			Kills = Inherit(T.Statistic),
		},

		Context = {
			Character = {
				Current = "Sphereite Reject",
				Instance = nil,
			},

			States = {
				Ragdolled = false,
				Stunned = false,
				Blocking = false,
				Attacking = false,
				Parkouring = false,
				Dead = false,
			},

			Conditionals = {
				InCombat = Inherit(T.Conditional),
				CanEvasive = Inherit(T.Conditional),
				CanUse = Inherit(T.Conditional),
				CanAttack = Inherit(T.Conditional),
				CanBlock = Inherit(T.Conditional),
				CanMove = Inherit(T.Conditional),
			},

			Status = {
				Health = 100,
				AttackIndex = 0,

				Effects = {
					Stagger = Inherit(T.Conditional),
				}
			}
		}
	},

	PlayerProfile = {
		Settings = {
			Audio = {
				Music = Bind(T.Volume.Default),
				Effects = Bind(T.Volume.Default),
				General = Bind(T.Volume.Default),
			},
			Gameplay = {
				CameraSensitivity = Bind(1.0),
				ShiftLockEnabled = Bind(true),
				FieldOfView = Bind(70),
				ScreenShake = Bind(true),
			},
			Controls = {
				Attack = Bind("MouseButton1"),
				Block = Bind("F"),
				Special = Bind("R"),
				
				Dash = Bind("Q"),
				Finality = Bind("G"),
				Run = Bind("LeftControl"),
				
				ShiftLock = Bind("LeftShift"),
				Emote = Bind("B"),

				Skill1 = Bind("One"),
				Skill2 = Bind("Two"),
				Skill3 = Bind("Three"),
				Skill4 = Bind("Four"),
				Skill5 = Bind("Five"),
				Skill6 = Bind("Six"),
				Skill7 = Bind("Seven"),
				Skill8 = Bind("Eight"),
				Skill9 = Bind("Nine"),
				Skill0 = Bind("Zero"),
			},
			Interface = {
				HideLeaderboard = Bind(false),
			},
			Statistics = {
				ShowKills = Bind(true),
			}
		},

		Statistics = {
			Kills = Bind(0),
		},

		Inventory = {
			Wallet = {
				Galla = 100
			},
			Emotes = {
				Owned = {},
				Equipped = {}
			},
			Gamepasses = {
				Owned = {},
			}
		},

		Session = {
			Character = {
				Current = "Sphereite Reject",
			}
		}
	}
}


Schemas._Policies = {
	AttackIndex = {
		Type = "number",
		Default = 1,
		Validate = function(value)
			if value < 1 or value > 5 then
				return false, "Attack index out of bounds"
			end
			return true
		end
	},

	NetworkPolicy = {
		Type = "table",
		Default = {
			Job = "",
			Data = {}
		},
		Validate = function(value)
			if not value.Job or not value.Data then
				return false, "Invalid network policy"
			end
			return true
		end
	},

	SessionPatch = {
		Type = "table",
		Default = {
			Path = "",
			Value = nil,
		},
		Validate = function(value)
			if type(value.Path) ~= "string" or value.Path == "" then
				return false, "SessionPatch requires a non-empty Path string"
			end
			return true
		end
	}
}

function Schemas.GetPolicy(policyPath: string): any
	return Schemas._Policies[policyPath]
end

function Schemas.Resolve(path: string): any
	local current: any = Schemas._Structures
	for step in path:gmatch("[^%.]+") do
		if type(current) ~= "table" then return nil end
		current = current[step]
	end

	return DeepCopy(current) 
end

function Schemas.Instantiate(path: string): any
	local structure = Schemas.Resolve(path)
	if not structure then return nil end

	local function resolveNode(node)
		for key, value in pairs(node) do
			if type(value) == "table" then
				local isRule = value.Type ~= nil or value.Default ~= nil or value.Validate ~= nil
				if isRule then
					node[key] = DeepCopy(value.Default)
				elseif value.Value ~= nil and next(value, "Value") == nil then
					-- Bind wrapper: { Value = x } — unwrap to x
					node[key] = value.Value
				else
					resolveNode(value)
				end
			end
		end
		return node
	end

	return resolveNode(structure)
end

function Schemas.WalkPath(path: string, onStep: (step: string) -> ())
	for step in path:gmatch("[^%.]+") do
		onStep(step)
	end
end 

function Schemas.Verify(policyPath: string, payload: any): (boolean, string?)
	local policy = Schemas.Resolve(policyPath)
	if not policy then return false, "Policy not found: " .. policyPath end

	-- Added targetData so it can recursively drill down into nested tables
	local function validateNode(nodeShape: any, targetData: any, currentPath: string): (boolean, string?)
		for key, ruleOrCategory in pairs(nodeShape) do
			-- Clean path formatting for error messages
			local fullPath = currentPath == "" and key or currentPath .. "." .. key

			if type(ruleOrCategory) == "table" then
				-- How we know if it's a rule vs a nested folder (like Settings.Audio)
				local isRule = ruleOrCategory.Type ~= nil or ruleOrCategory.Default ~= nil or ruleOrCategory.Validate ~= nil
				-- Also treat Bind wrappers ({ Value = x } with no other keys) as rules
				if not isRule and type(ruleOrCategory) == "table" and ruleOrCategory.Value ~= nil and next(ruleOrCategory, "Value") == nil then
					isRule = true
				end

				if not isRule then
					-- It's a nested category. Ensure the payload has a table here, then recurse.
					if type(targetData[key]) ~= "table" then
						return false, fullPath .. " is missing or not a table"
					end

					local isValid, errMsg = validateNode(ruleOrCategory, targetData[key], fullPath)
					if not isValid then return false, errMsg end
				else
					-- IT IS A RULE. Run the validation sequence.
					local value = targetData[key]

					-- 1. Apply Defaults FIRST
					if value == nil then
						if ruleOrCategory.Default ~= nil then
							targetData[key] = DeepCopy(ruleOrCategory.Default)
							value = targetData[key]
						elseif ruleOrCategory.Value ~= nil then
							targetData[key] = DeepCopy(ruleOrCategory.Value)
							value = targetData[key]
						else
							return false, fullPath .. " is required and missing"
						end
					end

					-- 2. Check Type
					if ruleOrCategory.Type and typeof(value) ~= ruleOrCategory.Type then
						return false, fullPath .. " must be a " .. ruleOrCategory.Type .. " (Got " .. typeof(value) .. ")"
					end

					-- 3. Run Custom Validation
					if ruleOrCategory.Validate then
						local isValid, errMsg = ruleOrCategory.Validate(value)
						if not isValid then
							return false, fullPath .. " failed validation: " .. (errMsg or "invalid data")
						end
					end

					if ruleOrCategory.Policy then
						local isValid, errMsg = Schemas.Verify(ruleOrCategory.Policy, value)
						if not isValid then
							return false, fullPath .. " -> " .. errMsg
						end
					end
				end
			end
		end
		return true, nil
	end

	return validateNode(policy, payload, "")
end

return Schemas
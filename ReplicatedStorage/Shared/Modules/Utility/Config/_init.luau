local Config = {}

local Enums = require(script.Enums)
local Junction = require(script.Junction)
local Manifests = require(script.Manifests)
local Functions = require(script.Functions)
local Schemas = require(script.Schemas)
local Types = require(script.Types)
local Settings = require(script.Settings)
local ClassPriority = require(script.ClassPriority)
local StandalonePriority = require(script.StandalonePriority)

Config = Functions.Extend(Config, {
	Junction = Junction,
	Manifests = Manifests,
	Enums = Enums,
	Functions = Functions,
	Schemas = Schemas,
	Types = Types,
	Settings = Settings,
	ClassPriority = ClassPriority,
	StandalonePriority = StandalonePriority,
})

return Config
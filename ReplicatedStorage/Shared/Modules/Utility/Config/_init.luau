local Config = {}

local Enums = require(script.Enums)
local Junction = require(script.Junction)
local Manifests = require(script.Manifests)
local Functions = require(script.Functions)
local Schemas = require(script.Schemas)
local Types = require(script.Types)

Config = Functions.Extend(Config, {
	Junction = Junction,
	Manifests = Manifests,
	Enums = Enums,
	Functions = Functions,
	Schemas = Schemas,
	Types = Types,
})

return Config
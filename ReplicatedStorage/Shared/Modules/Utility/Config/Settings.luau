local Schemas = require(script.Parent.Schemas)

local Settings = {}
Settings._Source = Schemas.Resolve("PlayerSession.Settings")

function Settings.Apply(t)
	for k, v in pairs(t) do
		if Settings._Source[k] then
			Settings._Source[k] = v
		end
	end
end
function Settings.GetNamespace(s: string)
	return Settings._Source[s]
end

function Settings.GetSettings()
	return Settings._Source
end

return Settings
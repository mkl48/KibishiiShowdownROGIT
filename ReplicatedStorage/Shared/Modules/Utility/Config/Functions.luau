local Functions = {}

function Functions.Inherit(template, overrides)
	local newTable = {}
	for key, value in pairs(template) do
		newTable[key] = value
	end
	-- Apply any specific overrides for this instance
	if overrides then
		for key, value in pairs(overrides) do
			newTable[key] = value
		end
	end
	return newTable
end

function Functions.Bind(value)
	return { Value = value }
end

function Functions.DeepCopy(target: any): any
	if type(target) ~= "table" then
		return target
	end

	local copy = {}
	for key, value in pairs(target) do
		copy[key] = Functions.DeepCopy(value)
	end
	return copy
end

function Functions.DeepFreeze(target: any): any
	if type(target) ~= "table" then
		return target
	end
	
	for key, value in pairs(target) do
		Functions.DeepFreeze(value)
	end
	return target
end

function Functions.Extend(baseTable, extraFields)
	local newTable = {}

	for key, value in pairs(baseTable) do
		newTable[key] = value
	end

	if extraFields then
		for key, value in pairs(extraFields) do
			newTable[key] = value
		end
	end

	return newTable
end

return Functions
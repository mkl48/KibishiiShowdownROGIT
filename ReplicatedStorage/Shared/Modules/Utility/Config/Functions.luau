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

function Functions.DeepMerge(base, override)
	local result = Functions.DeepCopy(base)
	for key, value in pairs(override) do
		if type(result[key]) == "table" and type(value) == "table" then
			result[key] = Functions.DeepMerge(result[key], value)
		else
			result[key] = Functions.DeepCopy(value)
		end
	end
	return result
end

function Functions.GetPath(root, path)
	local current = root
	for step in path:gmatch("[^%.]+") do
		if type(current) ~= "table" then return nil end
		current = current[step]
	end
	return current
end

function Functions.SetPath(root, path, value)
	local parts = {}
	for step in path:gmatch("[^%.]+") do
		table.insert(parts, step)
	end
	local current = root
	for i = 1, #parts - 1 do
		local step = parts[i]
		if type(current[step]) ~= "table" then
			current[step] = {}
		end
		current = current[step]
	end
	current[parts[#parts]] = value
	return root
end

function Functions.ToInputEnum(inputString: string): EnumItem?
    if typeof(inputString) ~= "string" then
        return nil
    end

    local ok, inputEnum = pcall(function() return Enum.UserInputType[inputString] end)
    if ok and inputEnum then return inputEnum end

    ok, inputEnum = pcall(function() return Enum.KeyCode[inputString] end)
    if ok and inputEnum then return inputEnum end

    return nil
end

return Functions
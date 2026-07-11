local Textual = {}
Textual.__index = Textual

function Textual.Color3ToHex(color)
	assert(typeof(color) == "Color3", "Textual.Color3ToHex expects a Color3 value")
	local r = math.floor(color.R * 255)
	local g = math.floor(color.G * 255)
	local b = math.floor(color.B * 255)
	return string.format("#%02X%02X%02X", r, g, b)
end

local function escapeText(text)
	assert(typeof(text) == "string", "escapeText expects a string")
	return text:gsub("&", "&amp;")
		:gsub("<", "&lt;")
		:gsub(">", "&gt;")
end

local function applyTag(text, pattern, tag)
	assert(typeof(text) == "string", "applyTag expects text to be a string")
	assert(typeof(pattern) == "string", "applyTag expects pattern to be a string")
	assert(typeof(tag) == "string", "applyTag expects tag to be a string")
	return text:gsub(pattern, function(match)
		return string.format("<%s>%s</%s>", tag, escapeText(match), tag)
	end)
end

function Textual.setTextColor(text, pattern, color)
	assert(typeof(text) == "string", "setTextColor expects text to be a string")
	assert(typeof(pattern) == "string", "setTextColor expects pattern to be a string")
	assert(typeof(color) == "Color3", "setTextColor expects a Color3 value")
	local hex = Textual.Color3ToHex(color)
	return text:gsub(pattern, function(match)
		return string.format('<font color="%s">%s</font>', hex, escapeText(match))
	end)
end

function Textual.setBackgroundColor(text, pattern, color)
	assert(typeof(text) == "string", "setBackgroundColor expects text to be a string")
	assert(typeof(pattern) == "string", "setBackgroundColor expects pattern to be a string")
	assert(typeof(color) == "Color3", "setBackgroundColor expects a Color3 value")
	local hex = Textual.Color3ToHex(color)
	return text:gsub(pattern, function(match)
		return string.format('<font background="%s">%s</font>', hex, escapeText(match))
	end)
end

function Textual.setTransparency(text, pattern, alpha)
	assert(typeof(text) == "string", "setTransparency expects text to be a string")
	assert(typeof(pattern) == "string", "setTransparency expects pattern to be a string")
	assert(typeof(alpha) == "number", "setTransparency expects alpha to be a number")
	local clamped = math.clamp(alpha, 0, 1)
	return text:gsub(pattern, function(match)
		return string.format('<font transparency="%s">%s</font>', clamped, escapeText(match))
	end)
end

function Textual.setFontWeight(text, pattern, weight)
	assert(typeof(text) == "string", "setFontWeight expects text to be a string")
	assert(typeof(pattern) == "string", "setFontWeight expects pattern to be a string")
	assert(typeof(weight) == "string", "setFontWeight expects weight to be a string")
	return text:gsub(pattern, function(match)
		return string.format('<font weight="%s">%s</font>', weight, escapeText(match))
	end)
end

function Textual.setFontFamily(text, pattern, family)
	assert(typeof(text) == "string", "setFontFamily expects text to be a string")
	assert(typeof(pattern) == "string", "setFontFamily expects pattern to be a string")
	assert(typeof(family) == "string", "setFontFamily expects family to be a string")
	return text:gsub(pattern, function(match)
		return string.format('<font face="%s">%s</font>', family, escapeText(match))
	end)
end

function Textual.setFontSize(text, pattern, size)
	assert(typeof(text) == "string", "setFontSize expects text to be a string")
	assert(typeof(pattern) == "string", "setFontSize expects pattern to be a string")
	assert(typeof(size) == "number", "setFontSize expects size to be a number")
	return text:gsub(pattern, function(match)
		return string.format('<font size="%d">%s</font>', size, escapeText(match))
	end)
end

function Textual.bold(text, pattern)
	return applyTag(text, pattern, "b")
end

function Textual.italic(text, pattern)
	return applyTag(text, pattern, "i")
end

function Textual.underline(text, pattern)
	return applyTag(text, pattern, "u")
end

function Textual.strikethrough(text, pattern)
	return applyTag(text, pattern, "s")
end

function Textual.superscript(text, pattern)
	return applyTag(text, pattern, "sup")
end

function Textual.subscript(text, pattern)
	return applyTag(text, pattern, "sub")
end

function Textual.align(text, alignment)
	assert(typeof(text) == "string", "align expects text to be a string")
	assert(typeof(alignment) == "string", "align expects alignment to be a string")
	return string.format('<p align="%s">%s</p>', alignment, escapeText(text))
end

function Textual.lineHeight(text, height)
	assert(typeof(text) == "string", "lineHeight expects text to be a string")
	assert(typeof(height) == "number", "lineHeight expects height to be a number")
	return string.format('<font lineheight="%d">%s</font>', height, escapeText(text))
end

function Textual.wrapFont(text, props)
	assert(typeof(text) == "string", "wrapFont expects text to be a string")
	assert(typeof(props) == "table", "wrapFont expects props to be a table")
	local parts = {}
	for key, value in pairs(props) do
		table.insert(parts, string.format('%s="%s"', key, tostring(value)))
	end
	return string.format('<font %s>%s</font>', table.concat(parts, " "), escapeText(text))
end

function Textual.wrapParagraph(text, props)
	assert(typeof(text) == "string", "wrapParagraph expects text to be a string")
	assert(typeof(props) == "table", "wrapParagraph expects props to be a table")
	local parts = {}
	for key, value in pairs(props) do
		table.insert(parts, string.format('%s="%s"', key, tostring(value)))
	end
	return string.format('<p %s>%s</p>', table.concat(parts, " "), escapeText(text))
end

function Textual:Typewrite(textObject: TextBox | TextButton | TextLabel, text: string, interval: number, writeStyle: "old" | "new", callbacks: {onNewCharacter: ((char: string, index: number) -> ())?, onFinished: (() -> ())?})
	assert(typeof(textObject) == "Instance", "Typewrite expects a UI instance")
	assert(typeof(text) == "string", "Typewrite expects text to be a string")
	assert(typeof(interval) == "number", "Typewrite expects interval to be a number")
	assert(writeStyle == "old" or writeStyle == "new", "Typewrite expects writeStyle to be 'old' or 'new'")
	--assert(typeof(callbacks) == "table", "Typewrite expects callbacks to be a table")

	local function oldWrite()
		for i = 1, #text do
			textObject.Text = string.sub(text, 1, i)
			if not callbacks then return end
			if callbacks.onNewCharacter then
				callbacks.onNewCharacter(text:sub(i, i), i)
			end
			task.wait(interval)
		end
	end

	local function newWrite()
		textObject.MaxVisibleGraphemes = 0
		textObject.Text = text
		for i = 1, utf8.len(text) or #text do
			textObject.MaxVisibleGraphemes += 1
			if not callbacks then return end
			if callbacks.onNewCharacter then
				local grapheme = text:sub(i, i)
				callbacks.onNewCharacter(grapheme, i)
			end
			task.wait(interval)
		end
	end

	if writeStyle == "new" and textObject["MaxVisibleGraphemes"] then
		newWrite()
	else
		oldWrite()
	end

	if not callbacks then return end
	if callbacks.onFinished then
		callbacks.onFinished()
	end
end

return Textual
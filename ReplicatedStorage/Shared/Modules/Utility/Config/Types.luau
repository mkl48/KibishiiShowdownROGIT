local Types = {}

export type Rule = {
	Type: string?,
	Validate: (any) -> (boolean, string?),
}

export type Policy = {
	Schema: {
		[string]: Rule,
	}        
}

export type PolicyRegistry = {
	[string]: Policy
}

return Types
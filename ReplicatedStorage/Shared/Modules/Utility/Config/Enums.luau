local Enums = {}

local Functions = require(script.Parent.Functions)

local Extend = Functions.Extend

Enums.Common = {
	JobId = {
		Patch = 1,
		Post = 2,
		Get = 3
	}
}

local CommonJobs = Enums.Common.JobId

Enums.Job = {
	PlayerService = {
		Profile = Extend(CommonJobs, {
			
		}),

		Session = Extend(CommonJobs, {
			
		})
	},
}

return Enums
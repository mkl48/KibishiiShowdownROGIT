--[[
	ScriptSense custom command quick guide
	-------------------------------------
	1. Create a ModuleScript in this folder.
	2. Rename it (for example: "HelloCommand").
	3. Require the API module:
			local API = require(script.Parent.ScriptSenseAPI)
	4. Return a table typed as API.CommandModule.
	5. Prefer ctx.API / ctx.Helpers over ctx.Core / ctx.Utils.
	6. Treat ctx.Core and ctx.Utils as unstable internals.
	7. Use Schema.Args / Schema.Flags / Schema.Subcommands when possible.
	8. Prefer ctx.Params / ctx.Options / ctx.Invocation over manual ctx.Args parsing.
	9. Prefer Suggest = "providerName" when a built-in suggestion provider already exists.
	10. Prefer ctx.API.RunAndLog(...) and ctx.API.Confirm(...) for consistent behavior.

	Available parsed context
	------------------------
	- ctx.Params            -- named positional args
	- ctx.Options           -- parsed flags/options
	- ctx.Invocation        -- metadata like Subcommand
	- ctx.Usage             -- generated usage string
	- ctx.Args / ctx.Flags  -- legacy fields kept for compatibility

	Example 1: simple wrapper command
	---------------------------------
		local API = require(script.Parent.ScriptSenseAPI)

		local command : API.CommandModule = {
			Name = "flow",
			Description = "Shows a flow graph for a script.",

			Schema = {
				Args = {
					{name = "name", kind = "string", required = false},
					{name = "index", kind = "number", required = false},
				},
				HighlightSpec = {
					args = {
						[1] = {role = "identifier", hint = "Script/module name"},
						[2] = {role = "number", hint = "Duplicate index (optional)"},
					},
				},
			},

			Suggest = "scriptOrDuplicate",

			Run = function(ctx)
				return ctx.API.RunAndLog(ctx, function()
					return ctx.API.OpenFlowGraph(ctx, {
						allowSelection = false,
						allowActive = true,
						usageMessage = ctx.Usage,
					})
				end)
			end,
		}

		return command

	Example 2: flag values
	----------------------
		local API = require(script.Parent.ScriptSenseAPI)

		local command : API.CommandModule = {
			Name = "define",
			Description = "Creates or updates a macro.",

			Schema = {
				Args = {
					{name = "key", kind = "string", required = true},
					{name = "code", kind = "rest", required = true},
				},
				Flags = {
					["-d"] = {kind = "string", target = "desc"},
					["-dep"] = {kind = "csv", target = "deps"},
				},
			},

			Run = function(ctx)
				return ctx.API.RunAndLog(ctx, function()
					return ctx.API.CreateOrUpdateMacro(
						ctx,
						ctx.Params.key,
						ctx.Params.code,
						ctx.Options.deps or {},
						ctx.Options.desc or ""
					)
				end)
			end,
		}

		return command

	Example 3: confirmation flow
	----------------------------
		local API = require(script.Parent.ScriptSenseAPI)

		local command : API.CommandModule = {
			Name = "renamequick",
			Description = "Preview then confirm a rename.",

			Schema = {
				Args = {
					{name = "oldName", kind = "string", required = true},
					{name = "newName", kind = "string", required = true},
				},
				Flags = {
					["-y"] = {kind = "boolean", target = "confirm"},
				},
			},

			Run = function(ctx)
				local preview, err = ctx.API.PreviewRename(ctx, ctx.Params.oldName, ctx.Params.newName)
				if not preview then
					ctx.API.LogResult(ctx, false, err)
					return
				end

				return ctx.API.Confirm(ctx, {
					applyNow = ctx.Options.confirm,
					title = "PENDING CHANGES:",
					previewLines = ctx.API.GetRenamePreviewLines(preview),
					onApply = function()
						return ctx.API.ApplyRename(ctx, preview)
					end,
					successMessage = string.format(
						"Renamed '%s' to '%s' and updated %d reference(s).",
						preview.oldName,
						preview.newName,
						preview.editCount or 0
					),
				})
			end,
		}

		return command
]]
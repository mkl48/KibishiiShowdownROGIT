export type Terminal = {
	Log: (self: Terminal, type: "Input"|"Info"|"Success"|"Warning"|"Error", message: string, onClick: (() -> ())?) -> (),
	Clear: (self: Terminal) -> (),
	Warn: (self: Terminal, message: string) -> (),
	Error: (self: Terminal, message: string) -> (),
	plugin: Plugin?,
}

export type SuggestionItem = string | {
	text: string,
	description: string?,
	role: string?,
}

export type CommandAPI = {
	[string]: any,

	MakeSafeIdentifier: (name: string, fallback: string?) -> string,
	GetJoinedArgs: (ctx: CommandContext, startIndex: number?) -> string,
	
	Info: (ctx: CommandContext, message: string) -> (),
	Success: (ctx: CommandContext, message: string) -> (),
	Fail: (ctx: CommandContext, message: string) -> (),
	LogResult: (ctx: CommandContext, ok: boolean, result: {[any]: any}?, options: {[any]: any}?) -> (boolean, {[any]: any}?),
	RunAndLog: (ctx: CommandContext, fn: (() -> (boolean, {[any]: any}?)), options: {[any]: any}?) -> (boolean, {[any]: any}?),
	Confirm: (ctx: CommandContext, options: {[any]: any}) -> (boolean, {[any]: any}?),
	PrintSessionList: (ctx: CommandContext, data: {[any]: any}) -> (),
	BuildUsage: (ctx: CommandContext) -> string?,

	ShowChangelog: (ctx: CommandContext, changelogText: string) -> (boolean, {[any]: any}),
	ResetConfig: (ctx: CommandContext) -> (boolean, {[any]: any}),

	OpenScriptTarget: (ctx: CommandContext, options: {[any]: any}?) -> (boolean, {[any]: any}),
	OpenDependencyTree: (ctx: CommandContext, options: {[any]: any}?) -> (boolean, {[any]: any}),
	OpenFlowGraph: (ctx: CommandContext, options: {[any]: any}?) -> (boolean, {[any]: any}),
	FindModuleReferences: (ctx: CommandContext, options: {[any]: any}?) -> (boolean, {[any]: any}),
	ExecuteFix: (ctx: CommandContext, options: {[any]: any}?) -> (boolean, {[any]: any}),
	ExecuteScan: (ctx: CommandContext, options: {[any]: any}?) -> (boolean, {[any]: any}),
	ExecuteFind: (ctx: CommandContext) -> (boolean, {[any]: any}),
	ExecuteReport: (ctx: CommandContext) -> (boolean, {[any]: any}),
	ExecuteDiff: (ctx: CommandContext) -> (boolean, {[any]: any}),
	ExecuteSync: (ctx: CommandContext, options: {[any]: any}?) -> (boolean, {[any]: any}),

	ExecuteExtract: (ctx: CommandContext, functionName: string?) -> (boolean, {[any]: any}),
	ExecuteWrap: (ctx: CommandContext, wrapperType: string?) -> (boolean, {[any]: any}),
	ExecuteInfer: (ctx: CommandContext, typeName: string?) -> (boolean, {[any]: any}),
	ExecuteGuard: (ctx: CommandContext) -> (boolean, {[any]: any}),
	ExecuteFormatTable: (ctx: CommandContext) -> (boolean, {[any]: any}),
	ExecuteSortTableEntries: (ctx: CommandContext) -> (boolean, {[any]: any}),
	ExecuteStrip: (ctx: CommandContext, stripFn: (...any) ->...any) -> (boolean, {[any]: any}),
	ExecuteJumpToFunction: (ctx: CommandContext, functionName: string?) -> (boolean, {[any]: any}),
	ExecuteLiftRequires: (ctx: CommandContext) -> (boolean, {[any]: any}),

	PreviewRename: (ctx: CommandContext, oldName: string?, newName: string?) -> ({[any]: any}?, {[any]: any}?),
	ApplyRename: (ctx: CommandContext, preview: {[any]: any}, options: {[any]: any}?) -> (boolean, {[any]: any}?),
	GetRenamePreviewLines: (preview: {[any]: any}) -> {string},

	PreviewIgnore: (ctx: CommandContext, options: {[any]: any}?) -> ({[any]: any}?, {[any]: any}?),
	ApplyIgnore: (ctx: CommandContext, preview: {[any]: any}) -> (boolean, {[any]: any}?),
	GetIgnorePreviewLines: (preview: {[any]: any}, limit: number?) -> {string},

	UndoLast: (ctx: CommandContext) -> (boolean, {[any]: any}),
	RedoLast: (ctx: CommandContext) -> (boolean, {[any]: any}),

	DeleteMacro: (ctx: CommandContext, macroName: string?) -> (boolean, {[any]: any}),
	GetMacroListPage: (ctx: CommandContext, pageText: string?, options: {[any]: any}?) -> {[any]: any},
	ImportMacrosJSON: (ctx: CommandContext, jsonText: string?) -> (boolean, {[any]: any}),
	ExportMacrosJSON: (ctx: CommandContext) -> {[any]: any},

	GetDashboardData: (ctx: CommandContext) -> {[any]: any},
	GetNetworkGraph: (ctx: CommandContext) -> (boolean, {[any]: any}),
	GetTasksBoardData: (ctx: CommandContext, scopeText: string?, currentScope: string?) -> {[any]: any},
	
	GetConfigListPage: (ctx: CommandContext, pageText: string?, options: {[any]: any}?) -> {[any]: any},
	GetConfigValue: (ctx: CommandContext, key: string) -> (boolean, {[any]: any}),
	SetConfigValue: (ctx: CommandContext, key: string, valueText: string) -> (boolean, {[any]: any}),
	
	GetThemeOverview: (ctx: CommandContext, presets: {[string]: {[string]: string}}?) -> {[any]: any},
	ListThemePresets: (ctx: CommandContext, presets: {[string]: {[string]: string}}?) -> {[any]: any},
	ApplyThemePreset: (ctx: CommandContext, presetName: string, presets: {[string]: {[string]: string}}?) -> (boolean, {[any]: any}),
	SetThemeOverride: (ctx: CommandContext, key: string, valueText: string) -> (boolean, {[any]: any}),
	ClearThemeOverride: (ctx: CommandContext, key: string) -> (boolean, {[any]: any}),
	ResetThemeOverrides: (ctx: CommandContext) -> (boolean, {[any]: any}),
	
	CreateOrUpdateMacro: (ctx: CommandContext, trigger: string, payload: string, deps: {string}?, desc: string?) -> (boolean, {[any]: any}),
	RebuildDependencyIndex: (ctx: CommandContext, reason: string?) -> (boolean, {[any]: any}),
	
	ResolveTestTargets: (ctx: CommandContext, options: {[any]: any}?) -> (boolean, {[any]: any}),
	BuildSpecSource: (ctx: CommandContext, moduleScript: ModuleScript) -> (boolean, {[any]: any}),
	GenerateSpecs: (ctx: CommandContext, options: {[any]: any}?) -> (boolean, {[any]: any}),
	RunTests: (ctx: CommandContext, options: {[any]: any}?) -> (boolean, {[any]: any}),
	
	OpenOrInstallLintRules: (ctx: CommandContext) -> (boolean, {[any]: any}),
	BuildDocsModel: (ctx: CommandContext, moduleScript: ModuleScript) -> (boolean, {[any]: any}),
	GenerateDocsModule: (ctx: CommandContext, moduleScript: ModuleScript) -> (boolean, {[any]: any}),
	OpenNetworkGraph: (ctx: CommandContext) -> (boolean, {[any]: any}),
	
	ListSessions: (ctx: CommandContext) -> {entries: {
			{
				Name: string,
				Count: number,
				Timestamp: number,
			}
		}
	},
	SaveSession: (ctx: CommandContext, nameText: string?) -> (boolean, {[any]: any}),
	LoadSession: (ctx: CommandContext, nameText: string?) -> (boolean, {[any]: any}),
	DeleteSession: (ctx: CommandContext, nameText: string?) -> (boolean, {[any]: any}),
	CloseSessionTabs: (ctx: CommandContext) -> (boolean, {[any]: any}),
	
	GetRecentBusEvents: (ctx: CommandContext, countText: string?) -> (boolean, {[any]: any}),
	GetDependencyDebugStats: (ctx: CommandContext) -> (boolean, {[any]: any}),
	GetKernelTaskNames: (ctx: CommandContext) -> (boolean, {[any]: any}),
}

export type CommandHelpers = {
	[string]: any,

	ScriptNameSuggestions: (ctx: CommandContext?) -> {SuggestionItem},
	ModuleNameSuggestions: (ctx: CommandContext?) -> {SuggestionItem},
	ThemeSuggestions: (ctx: CommandContext?, presets: {[string]: {[string]: string}}?) -> {SuggestionItem},

	ResolveScriptTarget: (ctx: CommandContext, options: {[any]: any}?) -> (Instance?, {[any]: any}?),
	ResolveModuleTarget: (ctx: CommandContext, options: {[any]: any}?) -> (Instance?, {[any]: any}?),

	GetSuggestionProvider: (name: string) -> ((ctx: CommandContext) -> {SuggestionItem})?,
	BuildUsage: (commandName: string?, schema: {[any]: any}?) -> string?,
	ParseBySchema: (ctx: CommandContext, schema: {[any]: any}?) -> {[any]: any},
	ValidateBySchema: (ctx: CommandContext, parsed: {[any]: any}, schema: {[any]: any}?) -> (boolean, {[any]: any}),
}

export type CommandContext = {
	Command: {[any]: any}?,
	CommandName: string?,

	Terminal: Terminal?,
	Registry: {[any]: any}?,

	Core: {[any]: any},
	Utils: {[any]: any},
	Helpers: CommandHelpers,
	API: CommandAPI,

	RawInput: string?,
	RawArgs: string?,
	Args: {string}?,
	ArgTokens: {{[any]: any}}?,
	Flags: {[string]: boolean}?,
	Subcommand: string?,

	RawSuggestionContext: {[any]: any}?,
	Params: {[string]: any}?,
	Options: {[string]: any}?,
	Invocation: CommandInvocation?,
	Usage: string?,
}

export type CommandModule = {
	Name: string,
	Description: string?,
	Aliases: {string}?,

	Style: string?,
	Version: number?,

	Schema: {[any]: any}?,

	Describe: (() -> string | {[any]: any})?,
	Suggest: (((ctx: CommandContext) -> {SuggestionItem}) | string | {[any]: any})?,
	Warnings: {CommandWarning}?,

	Run: (ctx: CommandContext) -> (),
}

export type CommandInvocation = {
	Name: string?,
	CanonicalName: string?,
	Subcommand: string?,
}

export type CommandWarning = {
	code: string,
	message: string,
}

export type Master = {
	Terminal: Terminal,
	SuggestionItem: SuggestionItem,
	CommandAPI: CommandAPI,
	CommandHelpers: CommandHelpers,
	CommandContext: CommandContext,
	CommandModule: CommandModule,
}

local API = {}
return API :: Master
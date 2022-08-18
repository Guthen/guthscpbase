guthscp.module = guthscp.module or {}

local MODULE = {
	--  internal
	--  contain all module states
	_ = {
		is_initialized = false,  --  is the module fully initialized (is `MODULE/init` has been called by the loader?)
		version_check = guthscp.VERSION_STATES.NONE,  --  state of the online version checking
		online_version = "0.0.0",  --  version retrieved online
		warnings = {},  --  list of registered warnings messages (using `MODULE/add_warning`)
	},
	
	--  variables
	name = "unknown",  --  required!
	author = "unknown",  --  required!
	version = "0.0.0",  -- required!
	description = "No description",
	
	--  identifier used to reference the module table:
	--  will register as 'guthscp.modules.<id>'
	id = "",  --  internally set to the module's folder name
	
	icon = "icon16/brick.png",
	dependencies = {},
	requires = {},
	
	--  used by version checker to warn owner when a new version of this module is available
	--version_url = "https://raw.githubusercontent.com/Guthen/VKXToolsEntitySpawner/master/lua/autorun/vkx_entspawner.lua",  --  optional
}
MODULE.__index = MODULE




--  methods

--[[ 
	@function MODULE:construct
		| description: Called when the module is loaded by the manager; do not ensure all modules are loaded 
]]
function MODULE:construct() 
end

--[[ 
	@function MODULE:init
		| description: Called after all modules have been loaded
]]
function MODULE:init()
end

--[[ 
	@function MODULE:info
		| description: Log a module information to console
		| params:
			message: string Message to log
			...: varargs Values to format into message 
]]
function MODULE:info( message, ... )
	guthscp.info( "guthscp/" .. self.id, message, ... )
end

function MODULE:error( message, ... )
	guthscp.error( "guthscp/" .. self.id, message, ... )
end

function MODULE:warning( message, ... )
	guthscp.warning( "guthscp/" .. self.id, message, ... )
end

function MODULE:debug( message, ... )
	guthscp.debug( "guthscp/" .. self.id, message, ... )
end

--[[ 
	@function MODULE:port_old_config_file
		| description: if exists, move the (assumed) old config file to the new config directory 
		| params:
			path: <string> file path
		| return: <bool> is_success
]]
function MODULE:port_old_config_file( path )
	if not file.Exists( path, "DATA" ) then return false end

	guthscp.data.move_file( path, guthscp.config.path .. self.id .. ".json" )
	return true
end

--[[
	@function MODULE:add_warning
		| description: add a warning to the module which will be shown on its menu page
		| params:
			message: <string> warning message
			...: <varargs?> message format arguments
]]
function MODULE:add_warning( message, ... )
	if ... then
		message = message:format( ... )
	end

	self._.warnings[#self._.warnings + 1] = {
		text = message,
		icon = "icon16/error.png",
	}
end

guthscp.module.meta = MODULE
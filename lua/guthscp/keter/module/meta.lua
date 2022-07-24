guthscp.module = guthscp.module or {}

local MODULE = {
	--  internal
	--  contain all module states
	_ = {
		is_initialized = false,
		version_check = guthscp.VERSION_STATES.NONE,
	},
	
	--  variables
	--name = "ModuleMeta",  --  required!
	
	--  identifier used to reference the module table:
	--  will register as 'guthscp.modules.<id>'
	--id = "_module_meta", --  required!
	--version = "1.0.0", -- required!
	
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

guthscp.module.meta = MODULE
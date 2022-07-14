local MODULE = {}
MODULE.__index = MODULE

--  variables
--MODULE.name = "ModuleMeta"  --  required!

--  identifier used to reference the module table:
--  will register as 'guthscp.modules.<id>'
--MODULE.id = "_module_meta" --  required!
--MODULE.version = "1.0.0" -- required!

MODULE.icon = "icon16/brick.png"
MODULE.dependencies = {}

--  used by version checker to warn owner when a new version of this module is available
--MODULE.version_url = "https://raw.githubusercontent.com/Guthen/VKXToolsEntitySpawner/master/lua/autorun/vkx_entspawner.lua"  --  optional


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
    @function MODULE:print
        | description: Log a module message to console
        | params:
            message: string Message to log
            ...: varargs Values to format into message 
]]
function MODULE:print( message, ... )
    --  format
    if ... then
        message = message:format( ... )
    end

    --  log
    print( ( "[guthscp/%s] Message: %s" ):format( self.id, message ) )
end


guthscp.module_meta = MODULE
local MODULE = {
    id = "base",
    name = "Base",
    icon = "icon16/bricks.png",
    version = "2.0.0",
    version_url = "https://raw.githubusercontent.com/Guthen/VKXToolsEntitySpawner/master/lua/autorun/vkx_entspawner.lua",
    dependencies = {
        --base = "1.0.0"
    },
}

--[[ 
    @function MODULE:construct
        | description: Called when the module is loaded by the manager; do not ensure all modules are loaded 
]]
function MODULE:construct()
    self:print( "I am constructed!" )
end

--[[ 
    @function MODULE:init
        | description: Called after all modules have been loaded
]]
function MODULE:init()
    self:print( "I am initialized!" )
end


return MODULE
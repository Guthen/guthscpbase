local MODULE = {
    --  infos
    name = "S-NAV",
    id = "snav",
    icon = "icon16/map.png",

    --  versions
    dependencies = {
        base = "2.1.0",
    },
    version = "1.0.0",
    version_url = "https://raw.githubusercontent.com/Guthen/VKXToolsEntitySpawner/master/lua/autorun/vkx_entspawner.lua",
}


function MODULE:construct()
    self:print( "I am constructed!" )
end


function MODULE:init()
    self:print( "I am initialized!" )
end


return MODULE
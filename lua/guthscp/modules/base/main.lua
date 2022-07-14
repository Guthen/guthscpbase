local MODULE = {
    id = "base",
    name = "Base",
    version = "2.0.0",
    icon = "icon16/bricks.png",
    version_url = "https://raw.githubusercontent.com/Guthen/VKXToolsEntitySpawner/master/lua/autorun/vkx_entspawner.lua",
    requires = {
        ["server/"] = guthscp.REALMS.SERVER,
        ["shared/sound_channel.lua"] = guthscp.REALMS.SHARED,
    }
}

function MODULE:construct()
    self:print( "I am constructed!" )
end

function MODULE:init()
    self:print( "I am initialized!" )
end


return MODULE
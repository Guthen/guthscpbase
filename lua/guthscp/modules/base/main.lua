local MODULE = {
	id = "base",
	name = "Base",
	version = "2.0.0",
	icon = "icon16/bricks.png",
	version_url = "https://raw.githubusercontent.com/Guthen/guthscpbase/remaster-as-modules-based/lua/guthscp/modules/base/main.lua",
	requires = {
		["shared/"] = guthscp.REALMS.SHARED,
		["server/"] = guthscp.REALMS.SERVER,
		["client/"] = guthscp.REALMS.CLIENT,
	},
}

function MODULE:construct()
end

function MODULE:init()
end


return MODULE
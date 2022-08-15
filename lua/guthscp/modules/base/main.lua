local MODULE = {
	name = "Base",
	author = "Guthen",
	version = "2.0.0",
	description = "The must-have addon that allows you to see this interface (and surely more)!",
	icon = "icon16/bricks.png",
	version_url = "https://raw.githubusercontent.com/Guthen/guthscpbase/remaster-as-modules-based/lua/guthscp/modules/base/main.lua",
	requires = {
		["shared/"] = guthscp.REALMS.SHARED,
		["server/"] = guthscp.REALMS.SERVER,
		["client/"] = guthscp.REALMS.CLIENT,
	},
}

--  config
MODULE.config = {
	form = {
		{
			type = "Category",
			name = "General",
		},
		guthscp.config.create_teams_element( {
			name = "SCP Teams",
			id = "scp_teams",
			desc = "All teams which represents a SCP team should be added in the list. These teams may not trigger SCPs behaviours.",
			default = {},
		} ),
		{
			type = "Category",
			name = "Entity Breaking",
		},
		{
			type = "NumWang",
			name = "Respawn Time",
			id = "ent_respawn_time",
			desc = "In seconds. How long a broken entity should wait before respawn?",
			default = 10,
		},
		{
			type = "NumWang",
			name = "Break Force",
			id = "ent_break_force",
			desc = "The default force of velocity when breaking an entity",
			default = 750,
		},
		{
			type = "CheckBox",
			name = "Enable Respawn",
			id = "enable_respawn",
			desc = "If checked, a breaked entity will automatically respawns",
			default = true,
		},
		{
			type = "CheckBox",
			name = "Open at Respawn",
			id = "open_at_respawn",
			desc = "When a door respawn, if checked, it will be open, otherwise its state won't change",
			default = true,
		},
		guthscp.config.create_apply_button(),
	},
	receive = function( form )
		form.scp_teams = guthscp.config.receive_teams( form.scp_teams )
	
		guthscp.config.apply( MODULE.id, form, {
			network = true,
			save = true,
		} )
	end,
	parse = function( form )
		form.scp_teams = guthscp.config.parse_teams( form.scp_teams )
	end,
}

--  TODO: remove if not used
function MODULE:construct()
end

function MODULE:init()
end

guthscp.module.hot_reload( "base" )
return MODULE
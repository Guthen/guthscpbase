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
			desc = "All teams which represents a SCP team should be added in the list",
			default = {  --  TODO: delete values
				"TEAM_SCP035",
				"TEAM_SCP049",
				"TEAM_SCP106",
				"TEAM_SCP096",
				"TEAM_SCP173",
				"TEAM_SCP682",
			},
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
		guthscp.config.create_apply_button( MODULE.id ),
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

function MODULE:construct()
end

function MODULE:init()
end

return MODULE
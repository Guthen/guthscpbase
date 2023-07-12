local MODULE = {
	name = "Base",
	author = "Guthen",
	version = "2.0.0-dev",
	description = [[The must-have addon that allows you to see this interface (and surely more)!

It comes with everything considered useful for making SCPs addons work together in harmony.
The base allows easy module creation with their own in-game configuration usable anywhere in the code.
It also includes:
─ its own spawnmenu for referencing all SCPs Weapons, Entities and the Configurations
─ a workaround system for fixing conflicts & issues with external addons
─ a custom shared sound system for easily playing looping and 3D-spatialized sounds
─ an entity breaking system, useful for throwing doors and chairs at your victims while playing as SCP-096
─ some useful functions for managing file data, getting a list of living NPCs, manipulating Lua tables..]],
	icon = "icon16/bricks.png",
	version_url = "https://raw.githubusercontent.com/Guthen/guthscpbase/remaster-as-modules-based/lua/guthscp/modules/base/main.lua",
	requires = {
		--["unit_test.lua"] = guthscp.REALMS.SHARED,
		["workarounds/"] = guthscp.REALMS.SHARED,
		["sv_entity_breaking.lua"] = guthscp.REALMS.SERVER,
	} 
	
}

MODULE.menu = {
	--  config
	config = {
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
			guthscp.config.create_reset_button(),
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
	},
	--  pages
	pages = {
		--  workaround
		function( form )
			form:SetName( "Work-Arounds" )

			form:Help( "This is where you can toggle fixes of other addons" )

			--  populate workarounds
			local checkboxes = {}
			for k, v in pairs( guthscp.workarounds ) do
				local checkbox = form:CheckBox( v.name )
				checkbox:SetChecked( v:is_enabled() )
				checkbox:SetDisabled( not v:is_active() )
				checkboxes[k] = checkbox
			end

			--  apply changes
			local button = form:Button( "Apply" )
			function button:DoClick()
				for k, v in pairs( checkboxes ) do
					local workaround = guthscp.workarounds[k]
					if workaround:is_active() then
						--  only sync changes
						local is_checked = v:GetChecked()
						if not ( workaround:is_enabled() == is_checked ) then
							workaround:set_enabled( is_checked )
							workaround:sync()
						end
					end
				end
			end
		end,
	},
	--  details
	details = {
		{
			text = "CC-BY-SA",
			icon = "icon16/page_white_key.png",
		},
		"Wiki",
		{
			text = "Read Me",
			icon = "icon16/information.png",
			url = "https://github.com/Guthen/guthscpbase/blob/master/README.md",
		},
		{
			text = "API",
			icon = "icon16/script_code.png",
			url = "https://github.com/Guthen/guthscpbase/wiki/API",
		},
		{
			text = "Creating your own module",
			icon = "icon16/brick_add.png",
			url = "https://github.com/Guthen/guthscpbase/wiki/Creating-your-own-module",
		},
		{
			text = "Creating your own workaround",
			icon = "icon16/folder_wrench.png",
			url = "https://github.com/Guthen/guthscpbase/wiki/Creating-your-own-workaround",
		},
		"Social",
		{
			text = "Github",
			icon = "guthscp/icons/github.png",
			url = "https://github.com/Guthen/guthscpbase",
		},
		{
			text = "Steam",
			icon = "guthscp/icons/steam.png",
			url = "https://steamcommunity.com/sharedfiles/filedetails/?id=2139692777",
		},
		{
			text = "Discord",
			icon = "guthscp/icons/discord.png",
			url = "https://discord.gg/3dx8EGbwvK",
		},
		{
			text = "Ko-fi",
			icon = "guthscp/icons/kofi.png",
			url = "https://ko-fi.com/vyrkx",
		},
	},
}

function MODULE:init()
	--  porting old config file 
	self:port_old_config_file( "guthscpbase/guthscpbase.json" )

	--  create filter
	guthscp.entity_breaking_filter = guthscp.map_entities_filter:new( "guthscp_entity_breaking", "GuthSCP Entity Breaking" )
end

guthscp.module.hot_reload( "base" )
return MODULE
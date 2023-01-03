if not guthscp then return end

TOOL.Category = "guthscp"
TOOL.Name = "#tool.guthscp_map_entities_filter_configurator.name"

TOOL.ClientConVar = {
	filter_id = "",
}

--  languages
if CLIENT then
	--  information
	TOOL.Information = {
		{ 
			name = "left",
		},
		{
			name = "right",
		},
	}

	--  language
	language.Add( "tool.guthscp_map_entities_filter_configurator.name", "Map Entities Filter Configurator" )
	language.Add( "tool.guthscp_map_entities_filter_configurator.desc", "Configure entities lists for Map Entities filters." )
	language.Add( "tool.guthscp_map_entities_filter_configurator.left", "Add looked entity to the filter" )
	language.Add( "tool.guthscp_map_entities_filter_configurator.right", "Remove looked entity from the filter" )

	language.Add( "tool.guthscp_map_entities_filter_configurator.filter", "Filter" )
	language.Add( "tool.guthscp_map_entities_filter_configurator.io", "Data Management" )
	language.Add( "tool.guthscp_map_entities_filter_configurator.save", "Save Data" )
	language.Add( "tool.guthscp_map_entities_filter_configurator.load", "Load Data" )

	--  context panel
	local mode = TOOL:GetMode()
	function TOOL.BuildCPanel( cpanel ) 
		cpanel:AddControl( "Header", { Description = "#tool.guthscp_map_entities_filter_configurator.desc" } )

		--  filters
		local filter_combobox = cpanel:ComboBox( "#tool.guthscp_map_entities_filter_configurator.filter", mode .. "_" .. "filter_id" )
		for id, filter in pairs( guthscp.filter.all ) do
			if not ( filter._key == guthscp.map_entities_filter._key ) then continue end

			filter_combobox:AddChoice( filter.name, id )
		end

		--  save & load
		cpanel:AddControl( "Label", { 
			Text = "#tool.guthscp_map_entities_filter_configurator.io",
		} )
		cpanel:AddControl( "Button", { 
			Label = "#tool.guthscp_map_entities_filter_configurator.save", 
			Command = "guthscp_keycards_save",
		} )
		cpanel:AddControl( "Button", { 
			Label = "#tool.guthscp_map_entities_filter_configurator.load", 
			Command = "guthscp_keycards_load",
		} )
	end

	hook.Add( "PreDrawHalos", "guthscp:map_entities_filter_configurator", function()
		local ply = LocalPlayer()

		local active_weapon = ply:GetActiveWeapon()
		if not IsValid( active_weapon ) or not ( active_weapon:GetClass() == "gmod_tool" ) then return end

		local tool = ply:GetTool( mode )
		if not tool then return end

		halo.Add( guthscp.entity_breaking_filter:get_list(), Color( 255, 0, 0 ), 2, 2, 1, true, true )
	end )
end

--  add access
function TOOL:LeftClick( tr )
	local ply = self:GetOwner()
	
	--  get filter
	local filter_id = self:GetClientInfo( "filter_id" )
	local filter = guthscp.filter.all[filter_id]
	if not filter then return false end

	--  check compatible entity
	local ent = tr.Entity
	if not IsValid( ent ) then return false end
	
	if SERVER then
		filter:add( ent )
	end
	
	return true
end

--  remove access
function TOOL:RightClick( tr )
	local ply = self:GetOwner()

	--  get filter
	local filter_id = self:GetClientInfo( "filter_id" )
	local filter = guthscp.filter.all[filter_id]
	if not filter then return false end

	--  check compatible entity
	local ent = ply:GetEyeTrace().Entity
	if not IsValid( ent ) then return false end

	if SERVER then
		filter:remove( ent )
	end

	return true
end
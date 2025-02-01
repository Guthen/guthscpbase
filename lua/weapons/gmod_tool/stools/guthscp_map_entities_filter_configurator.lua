if not guthscp then return end

TOOL.Category = "GuthSCP"
TOOL.Name = "#tool.guthscp_map_entities_filter_configurator.name"

TOOL.ClientConVar = {
	filter_id = "",
}

guthscp.filter.tool_mode = TOOL:GetMode()

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
	function TOOL.BuildCPanel( cpanel )
		cpanel:AddControl( "Header", { Description = "#tool.guthscp_map_entities_filter_configurator.desc" } )

		--  filters
		local filter_combobox = cpanel:ComboBox( "#tool.guthscp_map_entities_filter_configurator.filter", guthscp.filter.tool_mode .. "_" .. "filter_id" )
		for id, filter in pairs( guthscp.filters ) do
			if filter._key ~= guthscp.map_entities_filter._key then continue end

			filter_combobox:AddChoice( filter.name, id )
		end

		--  save & load
		cpanel:Help( "#tool.guthscp_map_entities_filter_configurator.io" )
		local save_button = cpanel:Button( "#tool.guthscp_map_entities_filter_configurator.save" )
		function save_button:DoClick()
			local tool = LocalPlayer():GetTool( guthscp.filter.tool_mode )
			if not tool then return end

			net.Start( "guthscp.filter:io" )
				net.WriteString( tool:GetClientInfo( "filter_id" ) )
				net.WriteBool( true )
			net.SendToServer()
		end

		local load_button = cpanel:Button( "#tool.guthscp_map_entities_filter_configurator.load" )
		function load_button:DoClick()
			local tool = LocalPlayer():GetTool( guthscp.filter.tool_mode )
			if not tool then return end

			net.Start( "guthscp.filter:io" )
				net.WriteString( tool:GetClientInfo( "filter_id" ) )
				net.WriteBool( false )
			net.SendToServer()
		end
	end

	local color_red = Color( 255, 0, 0 )
	function TOOL:DrawHUD()
		local x, y = ScrW() / 2, ScrH() * 0.75
		local ent = LocalPlayer():GetEyeTrace().Entity
		if not IsValid( ent ) then return end

		--  NOTE: This warning is not exact, it doesn't say if you're actually authorized to use the tool. A hook.Run to "CanTool" could be useful here. 
		--  	  However it would need to be done in each tool. For now, this should be enough.
		if FPP and not FPP.canTouchEnt( ent, "Toolgun" ) then
			local text = "Falco's Prop Protection prevent you from editing this entity, please ensure both 'Admins can use tool on world/blocked entities' are enabled in the 'Toolgun options'!"
			draw.SimpleText( text, "DermaDefaultBold", x, y + 30, color_red, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
		end
	end

	hook.Add( "PreDrawHalos", "guthscp:map_entities_filter_configurator", function()
		local ply = LocalPlayer()

		local active_weapon = ply:GetActiveWeapon()
		if not IsValid( active_weapon ) or active_weapon:GetClass() ~= "gmod_tool" then return end

		local tool = ply:GetTool()
		if not istable( tool ) or tool.Mode ~= guthscp.filter.tool_mode then return end

		--  get filter
		local filter_id = tool:GetClientInfo( "filter_id" )
		if #filter_id == 0 then return end

		local filter = guthscp.filters[filter_id]
		assert( filter, "Filter '" .. filter_id .. "' doesn't exists!" )

		--  draw halos
		halo.Add( filter:get_entities(), Color( 255, 0, 0 ), 2, 2, 1, true, true )
	end )
end

--  add access
function TOOL:LeftClick( tr )
	--  get filter
	local filter_id = self:GetClientInfo( "filter_id" )
	local filter = guthscp.filters[filter_id]
	if not filter then return false end

	--  check compatible entity
	local ent = tr.Entity
	if not IsValid( ent ) then return false end
	if not filter:filter( ent ) then return false end

	if SERVER then
		filter:add( ent )
	end

	return true
end

--  remove access
function TOOL:RightClick( tr )
	--  get filter
	local filter_id = self:GetClientInfo( "filter_id" )
	local filter = guthscp.filters[filter_id]
	if not filter then return false end

	--  check compatible entity
	local ent = tr.Entity
	if not IsValid( ent ) then return false end
	if not filter:filter( ent ) then return false end

	if SERVER then
		filter:remove( ent )
	end

	return true
end
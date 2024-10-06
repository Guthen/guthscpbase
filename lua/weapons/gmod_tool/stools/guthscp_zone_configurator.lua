if not guthscp then return end

TOOL.Category = "GuthSCP"
TOOL.Name = "#tool.guthscp_zone_configurator.name"

TOOL.ClientConVar = {
	zone_id = "",
	region_name = "My Region",
}

guthscp.zone.tool_mode = TOOL:GetMode()

--  languages
if CLIENT then
	--  information
	TOOL.Information = {
		{ name = "left", stage = 0 },
		{ name = "left_1", stage = 1 },
		{ name = "right", stage = 0 },
		{ name = "reload_1", stage = 1 },
	}

	--  language
	language.Add( "tool.guthscp_zone_configurator.name", "Zone Configurator" )
	language.Add( "tool.guthscp_zone_configurator.desc", "Configure zones in your map" )
	language.Add( "tool.guthscp_zone_configurator.left", "Click anywhere to start creating a region" )
	language.Add( "tool.guthscp_zone_configurator.left_1", "Click anywhere to end the region" )
	language.Add( "tool.guthscp_zone_configurator.right", "Click in a region to delete it" )
	language.Add( "tool.guthscp_zone_configurator.reload_1", "Cancel the region creation" )

	language.Add( "tool.guthscp_zone_configurator.zone", "Zone" )
	language.Add( "tool.guthscp_zone_configurator.region_name", "Region Name" )
	language.Add( "tool.guthscp_zone_configurator.new_region", "New Region" )
	language.Add( "tool.guthscp_zone_configurator.io", "Data Management" )
	language.Add( "tool.guthscp_zone_configurator.save", "Save Data" )
	language.Add( "tool.guthscp_zone_configurator.load", "Load Data" )

	local function format_vector( vector )
		return ( "x:%d; y:%d; z:%d" ):format( vector.x, vector.y, vector.z )
	end

	--  context panel
	function TOOL.BuildCPanel( cpanel )
		cpanel:AddControl( "Header", { Description = "#tool.guthscp_zone_configurator.desc" } )

		--  zones
		local zone_combobox = cpanel:ComboBox( "#tool.guthscp_zone_configurator.zone", guthscp.zone.tool_mode .. "_" .. "zone_id" )
		for id, zone in pairs( guthscp.zones ) do
			zone_combobox:AddChoice( zone.name, id )
		end

		--  new region parameters
		cpanel:TextEntry( "#tool.guthscp_zone_configurator.region_name", guthscp.zone.tool_mode .. "_" .. "region_name" )
		--[[ local new_button = cpanel:Button( "#tool.guthscp_zone_configurator.new_region" )
		function new_button:DoClick()
			local ply = LocalPlayer()
			local tool = ply:GetTool( guthscp.zone.tool_mode )
			if not tool then return end

			local zone_id = tool:GetClientInfo( "zone_id" )
			local zone = guthscp.zones[zone_id]
			if not zone then return end
			
			local name = tool:GetClientInfo( "region_name" )
			local pos = ply:GetPos()
			zone:send_region( #zone.regions + 1, name, pos, pos )
		end ]]

		--  list regions
		local regions_listview = vgui.Create( "DListView", cpanel )
		regions_listview:SetTall( 150 )
		regions_listview:SetMultiSelect( false )
		regions_listview:AddColumn( "Name" )
		regions_listview:AddColumn( "Start" )
		regions_listview:AddColumn( "End" )
		cpanel:AddItem( regions_listview )
		cpanel:Help( "Known issue: the regions list above doesn't update automatically, re-switch to the zone to update it" )

		local function update_zone( zone_id )
			regions_listview:Clear()

			local zone = guthscp.zones[zone_id]
			if not zone then return end

			for i, region in ipairs( zone.regions ) do
				regions_listview:AddLine( region.name, format_vector( region.start_pos ), format_vector( region.end_pos ) )
			end
		end

		local _on_select = zone_combobox.OnSelect
		function zone_combobox:OnSelect( id, value, data )
			update_zone( data )

			--  call old callback (convar change)
			_on_select( self, id, value, data )
		end

		--  save & load
		cpanel:Help( "#tool.guthscp_zone_configurator.io" )
		local save_button = cpanel:Button( "#tool.guthscp_zone_configurator.save" )
		function save_button:DoClick()
			local tool = LocalPlayer():GetTool( guthscp.zone.tool_mode )
			if not tool then return end

			net.Start( "guthscp.zone:io" )
				net.WriteString( tool:GetClientInfo( "zone_id" ) )
				net.WriteBool( true )
			net.SendToServer()
		end

		local load_button = cpanel:Button( "#tool.guthscp_zone_configurator.load" )
		function load_button:DoClick()
			local tool = LocalPlayer():GetTool( guthscp.zone.tool_mode )
			if not tool then return end

			net.Start( "guthscp.zone:io" )
				net.WriteString( tool:GetClientInfo( "zone_id" ) )
				net.WriteBool( false )
			net.SendToServer()
		end

		--  update 
		local zone_id = GetConVar( guthscp.zone.tool_mode .. "_zone_id" ):GetString()
		update_zone( zone_id )
	end

	local color_box = color_white
	local color_player_in_box = Color( 64, 128, 255 )
	local color_cursor_in_box = Color( 255, 64, 64 )
	local color_start_pos = Color( 20, 255, 0 )
	local color_end_pos = Color( 255, 20, 0 )
	local function render_region_box( start_pos, end_pos, box_color )
		local center = ( start_pos + end_pos ) * 0.5

		--  draw box
		render.DrawWireframeBox( center, angle_zero, center - start_pos, center - end_pos, box_color, false )

		--  draw points
		render.DrawWireframeSphere( start_pos, 8.0, 8, 8, color_start_pos, false )
		render.DrawWireframeSphere( end_pos, 8.0, 8, 8, color_end_pos, false )

		return center
	end

	hook.Add( "PostDrawOpaqueRenderables", "guthscp:zone_configurator", function()
		local ply = LocalPlayer()

		local active_weapon = ply:GetActiveWeapon()
		if not IsValid( active_weapon ) or active_weapon:GetClass() ~= "gmod_tool" then return end

		local tool = ply:GetTool()
		if not istable( tool ) or tool.Mode ~= guthscp.zone.tool_mode then return end

		local trace = tool:GetTrace()

		--  draw creating region
		local start_pos = tool:GetRegionStartPosition()
		if start_pos ~= vector_origin then
			--  render preview
			render_region_box( start_pos, trace.HitPos, color_box )
		end

		--  get zone
		local zone, zone_id = tool:GetCurrentZone()
		if #zone_id == 0 then return end
		assert( zone, "Zone '" .. zone_id .. "' doesn't exists!" )

		--  draw regions boxes
		local has_found_cursor = false
		local centers = {}
		for id, region in ipairs( zone.regions ) do
			local color = color_box
			if not has_found_cursor and zone:is_in_region( id, trace.HitPos ) then
				color = color_cursor_in_box
				has_found_cursor = true
			elseif zone:is_in_region( id, ply ) then
				color = color_player_in_box
			end
			centers[id] = render_region_box( region.start_pos, region.end_pos, color )
		end

		--  draw regions names
		cam.Start2D()
			for i = 1, #zone.regions do
				local screen_pos = centers[i]:ToScreen()
				draw.SimpleTextOutlined( zone.regions[i].name, "TargetID", screen_pos.x, screen_pos.y, color_box, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1.0, color_black )
			end
		cam.End2D()
	end )
end

function TOOL:GetTrace()
	local ply = self:GetOwner()

	local tr = util.GetPlayerTrace( ply )
	tr.mask = bit.bor( CONTENTS_SOLID, CONTENTS_MOVEABLE, CONTENTS_MONSTER, CONTENTS_WINDOW, CONTENTS_DEBRIS, CONTENTS_GRATE, CONTENTS_AUX )
	tr.mins = vector_origin
	tr.maxs = tr.mins

	return util.TraceHull( tr )
end

function TOOL:GetCurrentZone()
	local zone_id = self:GetClientInfo( "zone_id" )
	local zone = guthscp.zones[zone_id]
	return zone, zone_id
end

function TOOL:SetRegionStartPosition( pos )
	local ply = self:GetOwner()
	ply:SetNWVector( guthscp.zone.tool_mode .. ":start_pos", pos )
end

function TOOL:GetRegionStartPosition()
	local ply = self:GetOwner()
	return ply:GetNWVector( guthscp.zone.tool_mode .. ":start_pos" )
end

function TOOL:LeftClick( tr )
	if CLIENT then return true end
	if not IsFirstTimePredicted() then return end

	--  get zone
	local zone = self:GetCurrentZone()
	if not zone then return end

	--  set start position
	local start_pos = self:GetRegionStartPosition()
	if start_pos == vector_origin then
		self:SetStage( 1 )
		self:SetRegionStartPosition( tr.HitPos )
	else
		--  apply region
		local name = self:GetClientInfo( "region_name" )
		zone:set_region( #zone.regions + 1, {
			name = name,
			start_pos = start_pos,
			end_pos = tr.HitPos
		} )

		--  clear
		self:Reload( tr )
	end

	return true
end

function TOOL:RightClick( tr )
	if CLIENT then return true end

	--  get zone
	local zone = self:GetCurrentZone()
	if not zone then return end

	--  delete region
	for id, region in ipairs( zone.regions ) do
		if not zone:is_in_region( id, tr.HitPos ) then continue end

		zone:delete_region( id )
		break
	end

	return true
end

function TOOL:Reload( tr )
	self:SetStage( 0 )
	self:SetRegionStartPosition( vector_origin )

	return true
end
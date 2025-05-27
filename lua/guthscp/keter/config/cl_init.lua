guthscp.config = guthscp.config or {}
guthscp.config_metas = guthscp.config_metas or {}

--  config
function guthscp.config.add( id, tbl )
	tbl.id = id
	tbl.form = guthscp.table.rehash( tbl.form )
	guthscp.config_metas[id] = tbl

	guthscp.config.set_defaults( id )
end

function guthscp.config.send( id, config )
	if not LocalPlayer():IsSuperAdmin() then return end
	if table.Count( config ) <= 0 then return end

	--  send data
	net.Start( "guthscp.config:send" )
		net.WriteString( id )
		net.WriteTable( config )
	net.SendToServer()
end

net.Receive( "guthscp.config:send", function( len, ply )
	local id = net.ReadString()

	--  read table
	local config = net.ReadTable()
	if not next( config ) then return end

	--  prints
	guthscp.info( "guthscp", "received %q config", id )
	if guthscp.is_debug() then
		PrintTable( config )
	end

	--  apply config
	guthscp.config.apply( id, config )
end )

function guthscp.config.sync()
	net.Start( "guthscp.config:receive" )
	net.SendToServer()
end
hook.Add( "InitPostEntity", "guthscp.config:receive", guthscp.config.sync )
concommand.Add( "guthscp_sync", guthscp.config.sync )

--  config vgui
local vguis_types  --  required in order to use it in the functions

local function install_reset_input( meta, panel, get_value, set_value_obj )
	set_value_obj = set_value_obj or panel

	local mouse_pressed = panel.OnMousePressed
	panel:SetMouseInputEnabled( true )
	function panel:OnMousePressed( mouse_button )
		--  add a menu
		if mouse_button == MOUSE_MIDDLE then
			local menu = DermaMenu( nil, self )
			menu:AddOption( "Reset to default", function()
				set_value_obj:SetValue( get_value and get_value( meta.default ) or meta.default )
			end ):SetMaterial( "icon16/arrow_refresh.png" )
			menu:Open()
			return
		end

		mouse_pressed( self, mouse_button )
	end
end

local function create_array_vguis( panel, meta, config_value, add_func )
	local vguis = {}
	vguis._meta = meta

	--  name
	local label = Label( meta.name, panel )
	label:Dock( TOP )
	label:DockMargin( 8, 8, 0, -8 )
	label:SetDark( true )

	--  scroll panel
	local scroll_panel = vgui.Create( "DScrollPanel", panel )
	panel:AddItem( scroll_panel )

	panel:InvalidateLayout( true )
	scroll_panel:SetTall( 150 )

	local function add_vgui( value, key )
		local child = add_func( scroll_panel, value, key )
		if not child then return end

		local mouse_pressed = child.OnMousePressed
		function child:OnMousePressed( mouse_button )
			--  add a menu
			if mouse_button == MOUSE_MIDDLE then
				local menu = DermaMenu( nil, self )
				menu:AddOption( "Remove", function()
					child:Remove()
					for i, v in ipairs( vguis ) do
						if v == child then
							table.remove( vguis, i )
							break
						end
					end
				end ):SetMaterial( "icon16/delete.png" )
				menu:Open()
			end

			mouse_pressed( self, mouse_button )
		end

		vguis[#vguis + 1] = child
	end

	--  add vguis
	for k, v in pairs( config_value or meta.default or {} ) do
		add_vgui( v, k )
	end

	--  add & remove buttons
	local container = vgui.Create( "DPanel", panel )
	container:SetPaintBackground( false )
	panel:AddItem( container )

	local remove_button = container:Add( "DButton" )
	remove_button:Dock( RIGHT )
	remove_button:DockMargin( 0, 0, 5, 0 )
	remove_button:SetWide( 100 )
	remove_button:SetImage( "icon16/delete.png" )
	remove_button:SetText( "Delete" )
	function remove_button:DoClick()
		local target = vguis[#vguis]
		if not IsValid( target ) then return end

		target:Remove()
		vguis[#vguis] = nil
	end

	local add_button = container:Add( "DButton" )
	add_button:Dock( RIGHT )
	add_button:DockMargin( 0, 0, 5, 0 )
	add_button:SetWide( 100 )
	add_button:SetImage( "icon16/add.png" )
	add_button:SetText( "Add" )
	function add_button:DoClick()
		add_vgui()
	end

	--  support reload
	function vguis:SetValue( data )
		--  clear previous vguis
		for i = #vguis, 1, -1 do
			vguis[i]:Remove()
			vguis[i] = nil
		end

		--  populate with new data
		for k, v in pairs( data ) do
			add_vgui( v, k )
		end
	end
	install_reset_input( meta, scroll_panel, nil, vguis )

	return vguis
end

local function get_array_vguis_value( panel )
	local data = {}

	for i, child in ipairs( panel ) do
		if panel._meta.is_set then
			data[child:GetValue()] = true
		else
			data[i] = child:GetValue()
		end
	end

	return data
end

local function create_axes_vgui( panel, meta, config_value, axes )
	--  container
	local container = vgui.Create( "DPanel", panel )
	container:Dock( TOP )
	container:SetPaintBackground( false )

	--  name
	local title = Label( meta.name, container )
	title:SetDark( true )

	for i, axis in ipairs( axes ) do
		--  label
		local label = Label( axis:sub( 1, 1 ):upper() .. axis:sub( 2 ), container )
		label:Dock( LEFT )
		label:DockMargin( 0, 0, -16, 0 )
		label:SetDark( true )

		--  number
		local wang = container:Add( "DNumberWang" )
		wang:Dock( LEFT )
		wang:DockMargin( 0, 0, 16, 0 )
		wang:SetMinMax( -math.huge, math.huge )
		wang:SetValue( config_value[axis] or 0 )
		install_reset_input( meta, wang, function( value )
			return value[axis]
		end )

		container["axis_" .. axis] = wang
	end

	function container:SetValue( value )
		for i, axis in ipairs( axes ) do
			container["axis_" .. axis]:SetValue( value[axis] )
		end
	end

	panel:AddItem( title, container )
	return container
end

function guthscp.config.serialize_form( form )
	local config = {}

	for k, v in pairs( form ) do
		if isstring( k ) and k:StartsWith( "_" ) then continue end  --  ignore '_type' & '_id' property
		if isfunction( v ) then continue end

		--  use special serializors..
		local vgui_type = vguis_types[v._type]
		if vgui_type and vgui_type.get_value then
			local value = vgui_type.get_value( v )
			if value ~= nil then
				config[k] = value
			end
		--  or value
		else
			config[k] = v:GetValue()
		end
	end

	return config
end

--  register vguis types
vguis_types = {
	["Form"] = {
		init = function( parent, meta, config_id )
			local panel = parent:Add( "DForm" )
			panel:Dock( TOP )
			panel:DockMargin( 0, 0, 5, 5 )
			panel:SetName( meta.name )

			local config_value = guthscp.configs[config_id]

			local form = {}
			form._id = config_id

			local last_category_name
			local function populate_element( panel, meta )
				local id = meta.id

				--  convert strings into categories
				if isstring( meta ) then
					meta = {
						type = "Category",
						name = meta,
					}
				end

				--  mark as last category
				if meta.type == "Category" then
					last_category_name = meta.name
					return
				end

				--  try populate vgui
				local vgui_type = vguis_types[meta.type]
				if not vgui_type or not vgui_type.init then
					guthscp.error( "guthscp.config", "element %q is not a recognized type!", meta.type )
				else
					--  create vgui
					local child = vgui_type.init( panel, meta, id and config_value[id], form )
					child._type = meta.type  --  store type for further use
					if id then
						form[id] = child
					end

					--  set disabled
					if isfunction( meta.is_disabled ) then
						child:SetDisabled( meta:is_disabled( child ) )
					end

					--  create description
					if meta.desc then
						panel:ControlHelp( meta.desc ):DockMargin( 10, 0, 0, 15 )
					end
				end
			end

			--  populate elements
			local current_panel = panel
			for i, meta in ipairs( meta.elements or {} ) do
				if isstring( last_category_name ) then
					--  create form
					local content = vgui.Create( "DForm", category )
					content:SetLabel( last_category_name )
					if meta.is_expanded ~= nil then
						content:SetExpanded( meta.is_expanded )
					end
					panel:AddItem( content )

					--  populate
					if meta.type then
						populate_element( content, meta )
					else
						for i, v in ipairs( meta ) do
							populate_element( content, v )
						end
					end

					--  mark as used
					last_category_name = nil
					current_panel = content
				else
					populate_element( current_panel, meta )
				end
			end

			return form
		end,
	},
	["Category"] = {
		init = function( panel, meta )
			local cat = panel:Help( meta.name )
			cat:SetFont( "DermaDefaultBold" )

			return cat
		end,
		get_value = function( self )
			return nil --  skip categories serializing
		end,
	},
	["Label"] = {
		init = function( panel, meta )
			return panel:Help( meta.name )
		end,
		get_value = function( self )
			return nil  --  skip labels serializing
		end,
	},
	["Button"] = {
		init = function( panel, meta, config_value, form )
			local button = panel:Button( meta.name )

			--  link action
			function button:DoClick()
				meta:action( form )
			end

			return button
		end,
		get_value = function( self )
			return nil  --  skip buttons serializing
		end,
	},
	["Number"] = {
		init = function( panel, meta, config_value )
			--  container
			local container = vgui.Create( "DPanel", panel )
			container:Dock( TOP )
			container:SetPaintBackground( false )

			--  name
			local title = Label( meta.name, container )
			title:SetDark( true )

			--  numwang
			local numwang = vgui.Create( "DNumberWang", container )
			numwang:Dock( LEFT )
			numwang:DockMargin( 0, 0, 16, 0 )
			numwang:SetMinMax( -math.huge, math.huge )
			numwang:SetValue( config_value or meta.default or 0 )
			numwang:SetY( 10 )  --  default Y-pos is bad
			numwang:SetInterval( meta.interval or 1.0 )

			--  set min-max
			if meta.min then
				local min = meta.min

				if isfunction( meta.min ) then
					min = meta:min( numwang )
				end

				numwang:SetMin( min )
			end
			if meta.max then
				local max = meta.max

				if isfunction( meta.max ) then
					max = meta:max( numwang )
				end

				numwang:SetMax( max )
			end

			if meta.show_use_entity_map_id then
				local button = container:Add( "DButton" )
				button:Dock( LEFT )
				button:SetText( "Use Entity Map ID" )
				button:SizeToContents()
				function button:DoClick()
					local ply = LocalPlayer()
					local ent = ply:GetEyeTrace().Entity
					if not IsValid( ent ) then
						ply:PrintMessage( HUD_PRINTTALK, "You must look at a valid entity!" )
						return
					end
					if not ent:CreatedByMap() then
						ply:PrintMessage( HUD_PRINTTALK, "You must look at an entity created by the map!" )
						return
					end

					numwang:SetValue( ent:MapCreationID() )
				end
			end

			panel:AddItem( title, container )
			install_reset_input( meta, numwang )
			return numwang
		end,
	},
	["String"] = {
		init = function( panel, meta, config_value )
			local textentry = panel:TextEntry( meta.name )
			textentry:SetValue( config_value or meta.default or "" )

			install_reset_input( meta, textentry )
			return textentry
		end,
	},
	["String[]"] = {
		init = function( panel, meta, config_value )
			return create_array_vguis( panel, meta, config_value, function( parent, value, key )
				local textentry = parent:Add( "DTextEntry" )
				textentry:Dock( TOP )
				textentry:DockMargin( 25, 5, 5, 0 )

				--  set value
				if key ~= nil and value ~= nil then
					if meta.is_set then
						textentry:SetValue( key )
					else
						textentry:SetValue( value )
					end
				end

				return textentry
			end )
		end,
		get_value = get_array_vguis_value,
	},
	["ComboBox"] = {
		init = function( panel, meta, config_value )
			local value = meta.value and meta.value( true, config_value or meta.default ) --  i know, weird

			local combobox = panel:ComboBox( meta.name )
			combobox:SetValue( isstring( value ) and value or "" )

			--  get choices
			local choices = {}
			if isfunction( meta.choice ) then
				choices = meta.choice()
			elseif istable( meta.choice ) then
				choices = meta.choice
			end

			for i, v in ipairs( choices ) do
				combobox:AddChoice( v.value, v.data, v.value == value )
			end

			install_reset_input( meta, combobox )
			return combobox
		end,
		get_value = function( self )
			local text, data = self:GetSelected()

			--  1st priority: data
			if data then
				return data
			--  2nd priority: text
			elseif text then
				return text
			end

			--  3rd priority: value
			return self:GetValue()
		end,
	},
	["ComboBox[]"] = {
		init = function( panel, meta, config_value )
			return create_array_vguis( panel, meta, config_value, function( parent, value, key )
				local new_value = value and meta.value and meta.value( value, key )
				if new_value == false then return end
				value = new_value or value

				local combobox = parent:Add( "DComboBox" )
				combobox:Dock( TOP )
				combobox:DockMargin( 25, 5, 5, 0 )
				combobox:SetValue( isstring( value ) and value or "" )

				--  get choices
				local choices = {}
				if isfunction( meta.choice ) then
					choices = meta.choice()
				elseif istable( meta.choice ) then
					choices = meta.choice
				end

				for i, v in ipairs( choices ) do
					combobox:AddChoice( v.value, v.data )
				end

				return combobox
			end )
		end,
		get_value = get_array_vguis_value,
	},
	["Bool"] = {
		init = function( panel, meta, config_value )
			local checkbox = panel:CheckBox( meta.name )
			checkbox:SetValue( config_value or false )

			install_reset_input( meta, checkbox )
			return checkbox
		end,
		get_value = function( self )
			return self:GetChecked()
		end,
	},
	["Enum"] = {
		init = function( panel, meta, config_value )
			local combobox = panel:ComboBox( meta.name )
			combobox:SetValue( isstring( value ) and value or "" )

			--  populate choices
			local choices = {}
			for k, v in pairs( meta.enum ) do
				choices[v] = combobox:AddChoice( guthscp.helpers.stringify_enum_key( k ), v, v == config_value )
			end

			function combobox:SetValue( value )
				local idx = choices[value]
				if not isnumber( idx ) then return end

				--  select corresponding choice
				self:ChooseOptionID( idx )
			end

			install_reset_input( meta, combobox )
			return combobox
		end,
		get_value = function( self )
			local _, data = self:GetSelected()
			return data
		end,
	},
	["Team"] = {
		init = function( panel, meta, config_value )
			local combobox = panel:ComboBox( meta.name )
			combobox:SetValue( isstring( value ) and value or "" )

			--  populate choices
			local choices = {}
			choices["nil"] = combobox:AddChoice( "None", "TEAM_NIL" )

			for team_id, team_info in pairs( guthscp.get_usable_teams() ) do
				local keyname = guthscp.get_team_keyname( team_id )
				choices[keyname] = combobox:AddChoice( team_info.Name, keyname )
			end

			--  auto-select
			combobox:ChooseOptionID( choices[config_value] or choices["nil"] )

			function combobox:SetValue( value )
				local idx = choices[value]
				if not isnumber( idx ) then
					idx = choices["nil"]
				end

				--  select corresponding choice
				self:ChooseOptionID( idx )
			end

			install_reset_input( meta, combobox )
			return combobox
		end,
		get_value = function( self )
			local _, data = self:GetSelected()
			return data
		end,
	},
	["Teams"] = {
		init = function( panel, meta, config_value )
			--  container
			local container = vgui.Create( "DPanel", panel )
			container:Dock( TOP )
			container:SetPaintBackground( false )

			--  name
			local title = Label( meta.name, container )
			title:Dock( TOP )
			title:SetDark( true )

			--  retrieve teams
			local teams, count = guthscp.get_usable_teams()

			local current_line = 1
			local column, lines_per_column = nil, math.ceil( count / 4 )
			local column_wide, column_tall = 0, 0
			local function finish_column()
				column:SetWide( column_wide )
				column:InvalidateLayout( true )

				--  compute columns height
				local last_child = column:GetChild( column:ChildCount() - 1 )
				column_tall = math.max( column_tall, last_child:GetY() + last_child:GetTall() )
			end

			if count == 0 then
				local label = container:Add( Label( "No teams are available..", container ) )
				label:Dock( TOP )
				label:SetTextColor( Color( 100, 100, 100 ) )
				column_tall = column_tall + label:GetTall()
			end

			--  populate with teams
			local form = {}
			local columns = {}
			for team_id, team_info in SortedPairsByMemberValue( teams, "Name" ) do
				--  create column container
				if column == nil then
					column = container:Add( "DPanel" )
					column:Dock( LEFT )
					column:SetPaintBackground( false )
					columns[#columns + 1] = column
				end

				--  create checkbox
				local checkbox = column:Add( "DCheckBoxLabel" )
				checkbox:Dock( TOP )
				checkbox:DockMargin( 0, 0, 0, 4 )
				checkbox:SetText( team_info.Name )
				checkbox:SetDark( true )
				column_wide = math.max( column_wide, checkbox.Label:GetX() + checkbox.Label:GetContentSize() )

				--  check config
				local team_keyname = guthscp.get_team_keyname( team_id )
				if team_keyname == nil then
					checkbox:SetDisabled( true )
					guthscp.warning( "guthscp.config", "%q team doesn't have a unique 'TEAM_' name, disabling it..", team_info.Name )
				else
					if config_value[team_keyname] then
						checkbox:SetChecked( true )
					end

					--  assign to form
					form[team_keyname] = checkbox
				end

				--  handle layout
				current_line = current_line + 1
				if current_line > lines_per_column then
					finish_column()

					current_line = 1
					column_wide = 0
					column = nil
				end
			end
			container.form = form

			--  finish column
			if IsValid( column ) then
				finish_column()
			end

			--  update size
			container:SetTall( title:GetTall() + column_tall + 4 )
			function container:PerformLayout( w, h )
				--  compute used width
				local columns_wide = 0
				for i, column in ipairs( columns ) do
					columns_wide = columns_wide + column:GetWide()
				end

				--  apply margin
				local margin = math.floor( ( w - columns_wide ) / ( #columns - 1 ) )
				for i = 1, #columns - 1 do
					columns[i]:DockMargin( 0, 0, margin, 0 )
				end
				--print( w, columns_wide, margin )
			end

			function container:SetValue( data )
				for team_keyname, checkbox in pairs( self.form ) do
					checkbox:SetValue( data[team_keyname] or false )
				end
			end

			panel:AddItem( container )
			return container
		end,
		get_value = function( self )
			local data = {}

			for team_keyname, checkbox in pairs( self.form ) do
				if not checkbox:GetChecked() then continue end
				data[team_keyname] = true
			end

			return data
		end,
	},
	["Vector"] = {
		init = function( panel, meta, config_value )
			local container = create_axes_vgui( panel, meta, config_value, { "x", "y", "z" } )

			if meta.show_usepos then
				local button_usepos = container:Add( "DButton" )
				button_usepos:Dock( LEFT )
				button_usepos:SetText( "Use Pos" )
				function button_usepos:DoClick()
					container:SetValue( LocalPlayer():GetPos() )
				end
			end

			return container
		end,
		get_value = function( self )
			return Vector( self.axis_x:GetValue(), self.axis_y:GetValue(), self.axis_z:GetValue() )
		end,
	},
	["Angle"] = {
		init = function( panel, meta, config_value )
			return create_axes_vgui( panel, meta, config_value, { "pitch", "yaw", "roll" } )
		end,
		get_value = function( self )
			return Angle( self.axis_pitch:GetValue(), self.axis_yaw:GetValue(), self.axis_roll:GetValue() )
		end,
	},
	["InputKey"] = {
		init = function( panel, meta, config_value )
			--  binder
			local binder = vgui.Create( "DBinder", panel )
			binder:SetWide( 120 )
			function binder:UpdateText()
				local str = input.GetKeyName( self:GetSelectedNumber() ) or "NONE"
				str = language.GetPhrase( str )

				self:SetText( str:upper() )
			end
			function binder:SetValue( value )
				if not isnumber( value ) then
					value = meta.default
				end

				self:SetSelectedNumber( value )
			end
			binder:SetValue( config_value )

			--  name
			local title = Label( meta.name, panel )
			title:SetDark( true )

			panel:AddItem( title, binder )
			return binder
		end,
	},
	["Color"] = {
		init = function( panel, meta, config_value )
			local container = vgui.Create( "DPanel", panel )
			container:Dock( TOP )
			container:SetPaintBackground( false )
			container:SetTall( 20 )

			--  name
			local title = Label( meta.name, panel )
			title:SetDark( true )

			--  color preview
			local preview = container:Add( "DPanel" )
			preview:Dock( LEFT )
			preview:SetWide( container:GetTall() )

			--  hexadecimal entry
			local entry = container:Add( "DTextEntry" )
			entry:Dock( LEFT )
			entry:DockMargin( 4, 0, 0, 0 )
			entry:SetWide( 64 )
			entry:SetDrawLanguageID( false )
			entry:SetPlaceholderText( " #ffffffff" )
			function entry:AllowInput( char )
				return char:match( "[a-fA-F%d%s#]" ) == nil
			end
			function entry:OnChange()
				local text = self:GetValue()
				text = text:gsub( "[%s#]*", "" )
				if #text < 6 then return end

				--  split components
				local r, g, b, a = text:sub( 1, 2 ), text:sub( 3, 4 ), text:sub( 5, 6 ), text:sub( 7, 8 )

				--  convert from hexadecimal
				r = tonumber( r, 16 )
				g = tonumber( g, 16 )
				b = tonumber( b, 16 )
				a = tonumber( a, 16 ) or 255

				--  set color
				local color = Color( r, g, b, a )
				container:SetValue( color )
			end
			function entry:SetToColor( color )
				local text = " #"
				text = text .. bit.tohex( color.r, 2 )
							.. bit.tohex( color.g, 2 )
							.. bit.tohex( color.b, 2 )
							.. bit.tohex( color.a, 2 )

				self:SetValue( text )
			end

			--  combo button
			local combo = nil
			local combo_button = container:Add( "DImageButton" )
			combo_button:Dock( LEFT )
			combo_button:DockMargin( 8, 2, 4, 2 )
			combo_button:SetWide( 16 )
			combo_button:SetText( "" )
			combo_button:SetImage( "icon16/color_wheel.png" )
			function combo_button:DoClick()
				if IsValid( combo ) then
					combo:Remove()
				end

				local HOVER_EXTENT = 16
				local is_first_frame = true
				local m_x, m_y = input.GetCursorPos()

				--  create combo
				combo = vgui.Create( "DColorCombo" )
				combo:SetPos( m_x - 1, m_y - 1 )
				combo:SetColor( container.color )
				combo.Mixer:SetAlphaBar( true )
				combo.Mixer:SetWangs( true )
				combo:MakePopup()
				function combo:Think()
					--  avoid first frame to update local cursor position
					if is_first_frame then
						is_first_frame = false
						return
					end

					--  check cursor within bounds
					m_x, m_y = self:LocalCursorPos()
					if m_x > -HOVER_EXTENT and m_y > -HOVER_EXTENT and m_x < self:GetWide() + HOVER_EXTENT and m_y < self:GetTall() + HOVER_EXTENT then return end

					self:Remove()
				end
				function combo:OnValueChanged( color )
					container:SetValue( color )
				end
			end
			function combo_button:OnRemove()
				if IsValid( combo ) then
					combo:Remove()
				end
			end

			function container:SetValue( value )
				preview:SetBackgroundColor( value )
				entry:SetToColor( value )
				container.color = value
			end
			container:SetValue( config_value )
			install_reset_input( meta, entry, nil, container )

			panel:AddItem( title, container )
			return container
		end,
		get_value = function( self )
			return self.color
		end,
	},
}

local function create_label_category( parent, text )
	local label = parent:Add( "DLabel" )
	label:Dock( TOP )
	label:DockMargin( 9, 0, 0, 0 )
	label:SetDark( true )
	label:SetText( text )
	label:SetFont( "DermaDefaultBold" )

	return label
end

local function create_label( parent, text )
	local label = parent:Add( "DLabel" )
	label:Dock( TOP )
	label:DockMargin( 15, 0, 10, 5 )
	label:SetDark( true )
	label:SetText( text )

	return label
end

function guthscp.config.populate_config( parent, id )
	--  populate module data
	local module = guthscp.modules[id]
	if module then
		--  content
		local category = parent:Add( "DCollapsibleCategory" )
		category:Dock( TOP )
		category:DockMargin( 0, 0, 5, 5 )
		category:SetLabel( "Module" )

		local container = vgui.Create( "DSizeToContents", category )
		container:Dock( TOP )
		container:DockPadding( 10, 10, 10, 5 )

		--  description
		create_label_category( container, "Description" )

		local label_author = create_label( container, module.description )
		label_author:SetContentAlignment( 9 )
		label_author:SetAutoStretchVertical( true )
		label_author:SetWrap( true )

		--  dependencies
		if next( module.dependencies ) then
			create_label_category( container, "Dependencies" )

			--  show all
			for id, version in pairs( module.dependencies ) do
				local dependency = guthscp.modules[id]
				if dependency then  --  the reverse should not happen (since configs are loaded only if dependencies are constructed)
					local label_icon = container:Add( "guthscp_label_icon" )
					label_icon:Dock( TOP )
					label_icon:DockMargin( 10, 0, 0, 0 )
					label_icon:SetIcon( dependency.icon )
					label_icon:SetText( ( "%s (>=v%s)" ):format( dependency.name, version ) )
					function label_icon:DoClick()
						guthscp.config.menu:switch_to_config( id )
					end
				end
			end
		end

		--  display warnings
		local warnings = module._.warnings
		if #warnings > 0 then
			create_label_category( container, "Warnings" )

			for i, v in ipairs( warnings ) do
				local warning_notification = container:Add( "Panel" )
				warning_notification:Dock( TOP )
				warning_notification:DockMargin( 10, 0, 0, 4 )
				warning_notification:DockPadding( 6, 6, 6, 6 )

				local icon_image = warning_notification:Add( "DImage" )
				icon_image:SetSize( 16, 16 )
				icon_image:SetImage( v.icon )

				local label = warning_notification:Add( "DLabel" )
				label:Dock( FILL )
				label:DockMargin( 24, 0, 0, 0 )
				label:SetDark( true )
				label:SetText( v.text )
				label:SetWrap( true )
				label:SetAutoStretchVertical( true )
				function label:PerformLayout( w, h )
					local left_padding = warning_notification:GetDockPadding()
					warning_notification:SetTall( left_padding * 2 + h )
					icon_image:SetPos(
						left_padding / 2 + label:GetDockMargin() / 2 - icon_image:GetWide() / 2,
						warning_notification:GetTall() / 2 - icon_image:GetTall() / 2
					)
				end

				function warning_notification:Paint( w, h )
					draw.RoundedBox( 4, 0, 0, w, h, ColorAlpha( v.color, 16 + math.abs( math.sin( CurTime() * 2 ) * 84 ) ) )
				end
			end
		end

		--  side bar
		local sidebar = parent:GetParent():Add( "DScrollPanel" )
		sidebar:Dock( RIGHT )
		sidebar:DockMargin( 10, 0, 0, 0 )
		sidebar:GetCanvas():DockPadding( 4, 0, 0, 0 )
		function sidebar:Paint( w, h )
			surface.SetDrawColor( 200, 200, 200 )
			surface.DrawLine( 0, 5, 0, h - 5 )
		end

		local data = {}

		--  add debug details
		if guthscp.is_debug() then
			data[#data + 1] = "Debug"

			--  add module identifier
			data[#data + 1] = {
				text = module.id,
				icon = "icon16/script_code.png"
			}

			--  add number of config vars
			local count = 0
			if module.menu and module.menu.config and module.menu.config.form then
				for i, vars in ipairs( module.menu.config.form ) do
					if not istable( vars ) then continue end

					--  need to support both ways of setting up config vars
					if vars.type then
						count = count + 1
					else
						for _, var in ipairs( vars ) do
							count = count + 1
						end
					end
				end
			end
			data[#data + 1] = {
				text = ( "%d config vars" ):format( count ),
				icon = "icon16/table_multiple.png"
			}
		end

		data[#data + 1] = "Details"

		--  add author
		data[#data + 1] = {
			text = module.author,
			icon = "icon16/user_gray.png",
		}
		--  add local version
		data[#data + 1] = {
			text = "v" .. module.version,
			icon = "icon16/drive_go.png",
		}

		--  add online version
		if module._.version_check > guthscp.VERSION_STATES.PENDING then
			data[#data + 1] = {
				text = "v" .. module._.online_version,
				icon = "icon16/world_go.png",
			}
		end

		--  add custom details
		if module.menu and module.menu.details then
			table.Add( data, module.menu.details )
		end

		local max_wide = 100
		for i, v in ipairs( data ) do
			if isstring( v ) then
				create_label_category( sidebar, v )
			elseif istable( v ) then
				local container_dependency = sidebar:Add( "Panel" )
				container_dependency:Dock( TOP )

				local label_icon = container_dependency:Add( "guthscp_label_icon" )
				label_icon:Dock( LEFT )
				label_icon:DockMargin( 10, 0, 0, 0 )
				label_icon:SetText( v.text )
				if isstring( v.icon ) then
					label_icon:SetIcon( v.icon )
				end
				if isstring( v.url ) then
					function label_icon:DoClick()
						gui.OpenURL( v.url )
					end
				elseif isfunction( v.callback ) then
					label_icon.DoClick = v.callback
				else
					label_icon:SetClickable( false )
				end

				label_icon:InvalidateLayout( true )
				max_wide = math.max( max_wide, label_icon.label:GetX() + label_icon.label:GetWide() )
			end
		end

		sidebar:SetWide( max_wide + 24 )

		--  populate pages
		if module.menu and module.menu.pages then
			for i, v in ipairs( module.menu.pages ) do
				local form = parent:Add( "DForm" )
				form:Dock( TOP )
				form:DockMargin( 0, 0, 5, 5 )
				form:DockPadding( 0, 0, 0, 10 )  --  more bottom-space when shown
				form:SetName( "Page " .. i )

				v( form )
			end
		end
	end

	--  populate config
	local config_metas = guthscp.config_metas[id]
	if config_metas then
		--  custom config
		parent.form = vguis_types["Form"].init( parent, {
			name = "Configuration",
			elements = config_metas.form,
		}, id )

		--  create bottom container
		local container = parent:GetParent():Add( "DPanel" )
		container:Dock( BOTTOM )
		container:DockMargin( 0, 4, 0, 4 )

		--  add apply button
		local apply_button = container:Add( "DButton" )
		apply_button:Dock( TOP )
		apply_button:DockMargin( 0, 0, 0, 4 )
		apply_button:SetText( "Apply" )
		function apply_button:DoClick()
			guthscp.config.send( id, guthscp.config.serialize_form( parent.form ) )
		end

		--  add undo button
		local undo_button = container:Add( "DButton" )
		undo_button:Dock( TOP )
		undo_button:DockMargin( 0, 0, 0, 4 )
		undo_button:SetText( "Refresh Configuration" )
		function undo_button:DoClick()
			local config = guthscp.configs[id]
			if not config then return end

			for id, panel in pairs( parent.form ) do
				if id:StartsWith( "_" ) then continue end
				panel:SetValue( config[id] )
			end
		end

		--  add reset button
		local reset_button = container:Add( "DButton" )
		reset_button:Dock( TOP )
		reset_button:DockMargin( 0, 0, 0, 4 )
		reset_button:SetText( "Reset to Default" )
		function reset_button:DoClick()
			Derma_Query(
				"Are you really sure to reset the actual configuration to its default settings? This will delete the existing configuration file.",
				"Reset Configuration",
				"Yes", function()
					--  send reset to server
					net.Start( "guthscp.config:reset" )
						net.WriteString( id )
					net.SendToServer()
				end,
				"No", nil
			)
		end

		--  size vertically to content
		container:InvalidateLayout( true )
		container:SizeToChildren( false, true )
	end
end

function guthscp.config.get_pages_ids()
	local pages = {}

	--  add configs
	for id, config in pairs( guthscp.config_metas ) do
		pages[id] = config.name
	end

	--  add modules
	for id, module in pairs( guthscp.modules ) do
		pages[id] = module.name
	end

	return pages
end

local function create_menu()
	local w, h = ScrW() * 0.6, ScrH() * 0.65

	--  create frame
	local frame = vgui.Create( "DFrame" )
	frame:SetSize( w, h )
	frame:Center()
	frame:SetDraggable( true )
	frame:SetTitle( "GuthSCP Menu" )
	frame:SetDeleteOnClose( false )
	frame:SetSkin( "Default" )  --  prevent Helix from making my menu uglier
	frame:MakePopup()
	guthscp.config.menu = frame

	--  create sheets
	local sheet = frame:Add( "DPropertySheet" )
	sheet:Dock( FILL )
	function sheet:OnActiveTabChanged( old, new )
		--  somehow, the scroll vbar is showing incorrectly when there is not enough space to scroll, so here's my fix..
		timer.Simple( 0.1, function()
			new:GetPanel().scroll_panel:InvalidateLayout()
		end )
	end
	guthscp.config.menu.sheet = sheet
	guthscp.config.menu.sheets = {}

	--  callback for switching panel (e.g. dependencies hyperlinks)
	function guthscp.config.menu:switch_to_config( id )
		self.sheet:SetActiveTab( self.sheets[id].Tab )
	end

	--  create pages
	for id, name in SortedPairsByValue( guthscp.config.get_pages_ids() ) do
		local data = guthscp.modules[id] or guthscp.config_metas[id]

		local panel = sheet:Add( "DPanel" )
		panel:DockPadding( 5, 5, 5, 5 )
		panel.tab_id = id

		local scroll_panel = panel:Add( "DScrollPanel" )
		scroll_panel:Dock( FILL )
		panel.scroll_panel = scroll_panel

		--  populate
		guthscp.config.populate_config( scroll_panel, id )

		--  add sheet
		guthscp.config.menu.sheets[id] = sheet:AddSheet( name or id, panel, data.icon )
		guthscp.config.menu.sheets[id].Tab.config_id = id

		--  size to children
		scroll_panel:InvalidateLayout( true )
		for i, v in ipairs( scroll_panel:GetChildren() ) do
			v:SetTall( v:GetTall() + 5 )
		end
	end
end

function guthscp.config.remove_menu()
	if not IsValid( guthscp.config.menu ) then return end
	guthscp.config.menu:Remove()
end

function guthscp.config.open_menu()
	if not LocalPlayer():IsSuperAdmin() then
		guthscp.warning( "guthscp.config", "you are not part of the \"superadmin\" usergroup!" )
		return
	end

	--  create or show menu
	if not IsValid( guthscp.config.menu ) then
		create_menu()
	else
		guthscp.config.menu:Show()
	end
end
concommand.Add( "guthscp_menu", guthscp.config.open_menu )
concommand.Add( "guthscpbase", guthscp.config.open_menu )

hook.Add( "guthscp.config:applied", "guthscp.menu:reload_config", function( id, config )
	if not IsValid( guthscp.config.menu ) then return end
	if not guthscp.config.menu.sheets or not guthscp.config.menu.sheets[id] then return end

	--  update config form
	local panel = guthscp.config.menu.sheets[id].Panel
	local scroll_panel = panel.scroll_panel
	local form = scroll_panel.form
	for id, panel in pairs( form ) do
		if id:StartsWith( "_" ) then continue end

		panel:SetValue( config[id] )
	end
end )

function guthscp.config.reload_menu()
	if not IsValid( guthscp.config.menu ) then return end

	local active_config_id = guthscp.config.menu.sheet:GetActiveTab().config_id

	guthscp.config.menu:Remove()
	create_menu()

	guthscp.config.menu:switch_to_config( active_config_id )
end
concommand.Add( "guthscp_menu_reload", guthscp.config.reload_menu )

--  hot reload
guthscp.config.reload_menu()
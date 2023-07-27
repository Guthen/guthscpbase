guthscp.config = guthscp.config or {}
guthscp.config_metas = guthscp.config_metas or {}

--  config
function guthscp.config.add( id, tbl )
	tbl.id = id
	tbl.form = guthscp.table.rehash( tbl.form )
	guthscp.config_metas[id] = tbl

	guthscp.config.setup( id )
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

local function install_reset_input( meta, panel, get_value )
	local mouse_pressed = panel.OnMousePressed
	panel:SetMouseInputEnabled( true )
	function panel:OnMousePressed( mouse_button )
		--  add a menu
		if mouse_button == MOUSE_MIDDLE then
			local menu = DermaMenu( nil, self )
			menu:AddOption( "Reset to default", function()
				self:SetValue( get_value and get_value( meta.default ) or meta.default )
			end ):SetMaterial( "icon16/arrow_refresh.png" )
			menu:Open()
			return
		end

		mouse_pressed( self, mouse_button )
	end
end

local function create_array_vguis( panel, meta, config_value, add_func )
	local vguis = {}

	--  scroll panel
	local scroll_panel = vgui.Create( "DScrollPanel", panel )
	panel:AddItem( scroll_panel )

	panel:InvalidateLayout( true )
	scroll_panel:SetTall( 150 )

	--  name
	local label = Label( meta.name, scroll_panel )
	label:Dock( TOP )
	label:SetDark( true )

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

	return vguis
end

local function create_axes_vgui( panel, meta, config_value, axes )
	--  container
	local container = vgui.Create( "DPanel", panel )
	container:Dock( TOP )

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

		if istable( v ) then  --  recursive (support 'create_array_vguis')
			config[k] = guthscp.config.serialize_form( v )
		else
			--  use special serializors..
			local vgui_type = vguis_types[v._type]
			if vgui_type and vgui_type.get_value then
				local value = vgui_type.get_value( v )
				if not ( value == nil ) then
					config[k] = value
				end
			--  or value
			else
				config[k] = v:GetValue()
			end
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
			for i, meta in ipairs( meta.elements or {} ) do
				local id = meta.id

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
	["NumWang"] = {
		init = function( panel, meta, config_value )
			local numwang = panel:NumberWang( meta.name, nil, -math.huge, math.huge, nil )
			numwang:SetValue( config_value or meta.default or 0 )
			numwang:SetY( 10 )  --  default Y-pos is bad
			
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

			install_reset_input( meta, numwang )
			return numwang
		end,
	},
	["TextEntry"] = {
		init = function( panel, meta, config_value )
			local textentry = panel:TextEntry( meta.name )
			textentry:SetValue( config_value or meta.default or "" )

			install_reset_input( meta, textentry )
			return textentry
		end,
	},
	["TextEntry[]"] = {
		init = function( panel, meta, config_value )
			return create_array_vguis( panel, meta, config_value, function( parent, value, key )
				local textentry = parent:Add( "DTextEntry" )
				textentry:Dock( TOP )
				textentry:DockMargin( 25, 5, 5, 0 )
				textentry:SetValue( meta.value and meta.value( value, key ) or isstring( value ) and value or "" )
		
				return textentry
			end )
		end,
	},
	["ComboBox"] = {
		init = function( panel, meta, config_value )
			local value = meta.value and meta.value( true, config_value or meta.default ) --  i know, weird

			local combobox = panel:ComboBox( meta.name )
			combobox:SetValue( isstring( value ) and value or "" )

			for i, v in ipairs( meta.choice and meta.choice() or {} ) do
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

				for i, v in ipairs( meta.choice and meta.choice() or {} ) do
					combobox:AddChoice( v.value, v.data )
				end
		
				return combobox
			end )
		end,
	},
	["CheckBox"] = {
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
			local teams, count = {}, 0
			for team_id, team_info in pairs( team.GetAllTeams() ) do
				if team_id == TEAM_SPECTATOR then continue end
				if not team_info.Joinable then continue end

				teams[team_id] = team_info
				count = count + 1
			end
			
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
				if config_value[team_keyname] then
					checkbox:SetChecked( true )
				end

				--  assign to form
				form[team_keyname] = checkbox
				
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
			return create_axes_vgui( panel, meta, config_value, { "x", "y", "z" } )
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
			binder:SetValue( isnumber( config_value ) and config_value or meta.default )

			--  name
			local title = Label( meta.name, panel )
			title:SetDark( true )

			panel:AddItem( title, binder )
			return binder
		end,
	}
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

function guthscp.config.populate_config( parent, id, switch_callback )
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
					local container_dependency = container:Add( "Panel" )
					container_dependency:Dock( TOP )
					
					local label_icon = container_dependency:Add( "guthscp_label_icon" ) 
					label_icon:Dock( LEFT )
					label_icon:DockMargin( 10, 0, 0, 0 )
					label_icon:SetIcon( dependency.icon )
					label_icon:SetText( ( "%s (>=v%s)" ):format( dependency.name, version ) )
					function label_icon:DoClick()
						switch_callback( id )
					end
				end
			end
		end

		--  display warnings
		local warnings = module._.warnings
		if #warnings > 0 then
			create_label_category( container, "Warnings" )
		
			for i, v in ipairs( warnings ) do
				local container_dependency = container:Add( "Panel" )
				container_dependency:Dock( TOP )

				local label_icon = container_dependency:Add( "guthscp_label_icon" ) 
				label_icon:Dock( LEFT )
				label_icon:DockMargin( 10, 0, 0, 0 )
				label_icon:SetIcon( v.icon )
				label_icon:SetText( v.text )
				label_icon:SetClickable( false )
				function label_icon:Paint( w, h )
					draw.RoundedBox( 2, 0, 0, w, 16, ColorAlpha( v.color, math.abs( math.sin( CurTime() * 3 ) * 84 ) ) )
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

		local data = {
			"Details",
			{
				text = module.author,
				icon = "icon16/user_gray.png",
			},
			{
				text = "v" .. module.version,
				icon = "icon16/drive_go.png",
			},
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
	local config = guthscp.config_metas[id]
	if config then
		parent.form = vguis_types["Form"].init( parent, {
			name = "Configuration",
			elements = config.form,
		}, id )
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
	local w, h = ScrW() * .6, ScrH() * .65

	--  create frame
	local frame = vgui.Create( "DFrame" )
	frame:SetSize( w, h )
	frame:Center()
	frame:SetDraggable( true )
	frame:SetTitle( "GuthSCP Menu" )
	frame:SetDeleteOnClose( false )
	frame:MakePopup()
	guthscp.config.menu = frame

	--  create sheets
	local sheet = frame:Add( "DPropertySheet" )
	sheet:Dock( FILL )
	function sheet:OnActiveTabChanged( old, new )
		--  somehow, the scroll vbar is showing incorrectly when there is not enough space to scroll, so here's my fix..
		timer.Simple( .1, function()
			new:GetPanel().scroll_panel:InvalidateLayout()
		end )
	end
	guthscp.config.menu.sheet = sheet
	guthscp.config.menu.sheets = {}

	--  callback for switching panel (e.g. dependencies hyperlinks)
	local function switch_callback( id )
		guthscp.config.menu.sheet:SetActiveTab( guthscp.config.menu.sheets[id].Tab )
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
		guthscp.config.populate_config( scroll_panel, id, switch_callback )

		--  add sheet
		guthscp.config.menu.sheets[id] = sheet:AddSheet( name or id, panel, data.icon )

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

local should_hot_reload = true
function guthscp.config.open_menu()
	if not LocalPlayer():IsSuperAdmin() then 
		guthscp.warning( "guthscp.config", "you are not part of the \"superadmin\" usergroup!" )
		return 
	end

	--  hot reload: refresh menu
	if should_hot_reload then
		guthscp.config.remove_menu()
	end
	should_hot_reload = false

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

--  hot reload
if IsValid( guthscp.config.menu ) then
	guthscp.module.require()
	guthscp.config.sync()  --  this will eventually call the above hook
end
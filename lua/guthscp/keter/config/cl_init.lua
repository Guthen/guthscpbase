guthscp.config = guthscp.config or {}

local config = {}

--  config
function guthscp.config.add( id, tbl )
	tbl.id = id
	tbl.form = guthscp.table.rehash( tbl.form )
	config[id] = tbl

	guthscp.config.setup( id )
end

function guthscp.config.get_all()
	return config
end

function guthscp.config.send( id, form )
	if not LocalPlayer():IsSuperAdmin() then return end
	if table.Count( form ) <= 0 then return end

	--  send data
	net.Start( "guthscp.config:send" )
		net.WriteString( id )
		net.WriteTable( form )
	net.SendToServer()
end

net.Receive( "guthscp.config:send", function( len, ply )
	local id = net.ReadString()

	--  read table
	local tbl = net.ReadTable()
	if table.Count( tbl ) <= 0 then return end

	--  prints
	guthscp.info( "guthscp", "received %q config", id )
	if guthscp.is_debug() then
		PrintTable( tbl )
	end

	--  apply config
	guthscp.config.apply( id, tbl )
end )

function guthscp.config.sync() 
	net.Start( "guthscp.config:receive" )
	net.SendToServer()
end
hook.Add( "InitPostEntity", "guthscp.config:receive", guthscp.config.sync )
concommand.Add( "guthscp_sync", guthscp.config.sync )

--  config vgui
local vguis_types  --  required in order to use it in the functions

local function create_array_vguis( panel, el, config_value, add_func )
	local vguis = {}

	--  scroll panel
	local scroll_panel = vgui.Create( "DScrollPanel", panel )
	panel:AddItem( scroll_panel )

	panel:InvalidateLayout( true )
	scroll_panel:SetTall( 150 )

	--  name
	local label = Label( el.name, scroll_panel )
	label:Dock( TOP )
	label:DockMargin( 5, 0, 0, 0 )
	label:SetTextColor( Color( 0, 0, 0 ) )

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
	for k, v in pairs( config_value or el.default or {} ) do
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

	return vguis
end

function guthscp.config.serialize_form( form )
	local serialized = {}

	for k, v in pairs( form ) do
		if k == "_type" or k == "_id" then continue end  --  ignore '_type' & '_id' property

		if istable( v ) then
			serialized[k] = guthscp.config.serialize_form( v )
		else
			--  use special serializors..
			local vgui_type = vguis_types[v._type]
			if vgui_type and vgui_type.get_value then
				local value = vgui_type.get_value( v )
				if not ( value == nil ) then
					serialized[k] = value
				end
			--  or value
			else
				serialized[k] = v:GetValue()
			end
		end
	end

	return serialized
end

--  register vguis types
vguis_types = {
	["Form"] = {
		init = function( parent, el, config_id )
			local panel = parent:Add( "DForm" )
			panel:Dock( TOP )
			panel:DockMargin( 0, 0, 5, 5 )
			panel:SetName( el.name )

			local config_value = guthscp.configs[config_id]

			local form = {}
			form._id = config_id
			for i, el in ipairs( el.elements or {} ) do
				local id = el.id or #form + 1

				local vgui_type = vguis_types[el.type]
				if not vgui_type or not vgui_type.init then
					guthscp.error( "guthscp.config", "element %q is not a recognized type!", el.type )
				else
					--  create vgui
					local child = vgui_type.init( panel, el, config_value[id], form )
					child._type = el.type  --  store type for further use
					form[id] = child
					
					--  set disabled
					if isfunction( el.is_disabled ) then 
						child:SetDisabled( el:is_disabled( child ) )
					end
					
					--  middle click: reset to default
					if IsValid( child ) and config_value[id] then
						local mouse_pressed = child.OnMousePressed
						child:SetMouseInputEnabled( true )
						function child:OnMousePressed( mouse_button )
							--  add a menu
							if mouse_button == MOUSE_MIDDLE then
								local menu = DermaMenu( nil, self )
								menu:AddOption( "Reset to default", function()
									self:SetValue( el.default )
								end ):SetMaterial( "icon16/arrow_refresh.png" )
								menu:Open()
							end

							mouse_pressed( self, mouse_button )
						end
					end

					--  create description
					if el.desc then
						panel:ControlHelp( el.desc ):DockMargin( 10, 0, 0, 15 )
					end
				end
			end
			
			return form
		end,
	},
	["Category"] = {
		init = function( panel, el )
			local cat = panel:Help( el.name )
			cat:SetFont( "DermaDefaultBold" )

			return cat
		end,
		get_value = function( self )
			return nil --  skip categories serializing
		end,
	},
	["Label"] = {
		init = function( panel, el )
			return panel:Help( el.name )
		end,
		get_value = function( self )
			return nil  --  skip labels serializing
		end,
	},
	["Button"] = {
		init = function( panel, el, config_value, form )
			local button = panel:Button( el.name )

			--  link action
			function button:DoClick()
				el:action( form )
			end

			return button
		end,
		get_value = function( self )
			return nil  --  skip buttons serializing
		end,
	},
	["NumWang"] = {
		init = function( panel, el, config_value )
			local numwang, label = panel:NumberWang( el.name, nil, -math.huge, math.huge )
			numwang:SetValue( config_value or el.default or 0 )
			numwang:SetY( 10 )  --  default Y-pos is bad
			
			--  set min-max
			if el.min then
				local min = el.min
				
				if isfunction( el.min ) then
					min = el:min( numwang )
				end
			
				numwang:SetMin( min )
			end
			if el.max then
				local max = el.max
				
				if isfunction( el.max ) then
					max = el:max( numwang )
				end
			
				numwang:SetMax( max )
			end

			return numwang
		end,
	},
	["TextEntry"] = {
		init = function( panel, el, config_value )
			local textentry = panel:TextEntry( el.name )
			textentry:SetValue( config_value or el.default or "" )

			return textentry
		end,
	},
	["TextEntry[]"] = {
		init = function( panel, el, config_value )
			return create_array_vguis( panel, el, config_value, function( parent, value, key )
				local textentry = parent:Add( "DTextEntry" )
				textentry:Dock( TOP )
				textentry:DockMargin( 25, 5, 5, 0 )
				textentry:SetValue( el.value and el.value( value, key ) or isstring( value ) and value or "" )
		
				return textentry
			end )
		end,
	},
	["ComboBox"] = {
		init = function( panel, el, config_value )
			local value = el.value and el.value( true, config_value or el.default ) --  i know, weird

			local combobox = panel:ComboBox( el.name )
			combobox:SetValue( isstring( value ) and value or "" )

			for i, v in ipairs( el.choice and el.choice() or {} ) do
				combobox:AddChoice( v.value, v.data, v.value == value )
			end

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
		init = function( panel, el, config_value )
			return create_array_vguis( panel, el, config_value, function( parent, value, key )
				local new_value = value and el.value and el.value( value, key ) 
				if new_value == false then return end
				value = new_value or value

				local combobox = parent:Add( "DComboBox" )
				combobox:Dock( TOP )
				combobox:DockMargin( 25, 5, 5, 0 )
				combobox:SetValue( isstring( value ) and value or "" )

				for i, v in ipairs( el.choice and el.choice() or {} ) do
					combobox:AddChoice( v.value, v.data )
				end
		
				return combobox
			end )
		end,
	},
	["CheckBox"] = {
		init = function( panel, el, config_value )
			local checkbox = panel:CheckBox( el.name )
			checkbox:SetValue( config_value or false )
	
			return checkbox
		end,
		get_value = function( self ) 
			return self:GetChecked()
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
		sidebar:GetCanvas():DockPadding( 5, 0, 0, 0 )
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

		local max_wide = 150
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

		sidebar:SetWide( max_wide + 15 )

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
	local config = config[id]
	if config then
		vguis_types["Form"].init( parent, {
			name = "Configuration",
			elements = config.form,
		}, id )
	end
end

function guthscp.config.get_pages_ids()
	local pages = {}
	
	--  add configs
	for id, config in pairs( guthscp.config.get_all() ) do
		pages[id] = config.name
	end
	
	--  add modules
	for id, module in pairs( guthscp.modules ) do
		pages[id] = module.name
	end

	return pages
end

function guthscp.config.open_menu()
	if not LocalPlayer():IsSuperAdmin() then 
		guthscp.warning( "guthscp.config", "you are not part of the \"superadmin\" usergroup!" )
		return 
	end

	--  refresh menu and select previous tab
	local tab_id = 1
	if IsValid( guthscp.config.menu ) then
		if guthscp.config.menu.sheet then 
			tab_id = guthscp.config.menu.sheet.tab_id 
		end
		guthscp.config.menu:Remove() 
	end

	local w, h = ScrW() * .6, ScrH() * .65

	--  create frame
	local frame = vgui.Create( "DFrame" )
	frame:SetSize( w, h )
	frame:Center()
	frame:SetDraggable( false )
	frame:SetTitle( "GuthSCP Menu" )
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
	guthscp.config.sheet = sheet
	guthscp.config.sheets = {}

	--  callback for switching panel (e.g. dependencies hyperlinks)
	local function switch_callback( id )
		guthscp.config.sheet:SetActiveTab( guthscp.config.sheets[id].Tab )
	end

	--  create pages
	for id, name in SortedPairsByValue( guthscp.config.get_pages_ids() ) do
		local data = guthscp.modules[id] or config[id]

		local panel = sheet:Add( "DPanel" )
		panel:DockPadding( 5, 5, 5, 5 )

		local scroll_panel = panel:Add( "DScrollPanel" )
		scroll_panel:Dock( FILL )
		panel.scroll_panel = scroll_panel

		--  populate
		guthscp.config.populate_config( scroll_panel, id, switch_callback )

		--  add sheet
		guthscp.config.sheets[id] = sheet:AddSheet( name or id, panel, data.icon )

		--  size to children
		scroll_panel:InvalidateLayout( true )
		for i, v in ipairs( scroll_panel:GetChildren() ) do
			v:SetTall( v:GetTall() + 5 )
		end
	end
end
concommand.Add( "guthscp_menu", guthscp.config.open_menu )
concommand.Add( "guthscpbase", guthscp.config.open_menu )

--  hot reload
if guthscp.config.menu then 
	guthscp.module.require()
	guthscp.config.sync()
	timer.Simple( .5, guthscp.config.open_menu )
end
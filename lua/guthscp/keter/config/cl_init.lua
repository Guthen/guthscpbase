guthscp.config = guthscp.config or {}

local config = {}

--  config
function guthscp.config.add( id, tbl )
	tbl.id = id
	tbl.elements = guthscp.table.rehash( tbl.elements )
	for i, form in ipairs( tbl.elements ) do
		form.elements = guthscp.table.rehash( form.elements )
	end
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

	local tbl = net.ReadTable()
	if table.Count( tbl ) <= 0 then return end

	guthscp.info( "guthscp", "received %q config", id )
	if guthscp.is_debug() then
		PrintTable( tbl )
	end

	guthscp.config.apply( id, tbl )
end )

function guthscp.config.sync() 
	net.Start( "guthscp.config:receive" )
	net.SendToServer()
end
hook.Add( "InitPostEntity", "guthscp.config:receive", guthscp.config.sync )
concommand.Add( "guthscp_sync", guthscp.config.sync )

--  > Formular
local vgui_values = {
	["DCheckBoxLabel"] = function( self ) 
		return self:GetChecked() or false
	end,
	["DComboBox"] = function( self ) 
		local text, data = self:GetSelected()
		--print( text, data )
		return data or text or self:GetValue()
	end,
	["DLabel"] = function( self )
		return nil  --  skip categories serializing
	end,
	["DButton"] = function( self )
		return nil  --  skip buttons serializing
	end,
}

local function serialize_form( form )
	local serialized = {}

	for k, v in pairs( form ) do
		if k == "_id" then continue end  --  ignore '_id' property

		if istable( v ) then
			serialized[k] = serialize_form( v )
		else
			--  use special serializors..
			local serializor = vgui_values[v:GetName()]
			if serializor then
				local value = serializor( v )
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

	--  > Add/Remove
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

local form_vgui
form_vgui = {
	["Form"] = function( parent, el, config_id )
		local panel = parent:Add( "DForm" )
		panel:Dock( FILL )
		panel:DockMargin( 0, 0, 5, 0 )
		panel:SetName( el.name )

		local config_value = guthscp.configs[config_id]

		local form = {}
		form._id = config_id
		for i, el in ipairs( el.elements or {} ) do
			local id = el.id or #form + 1
			if not form_vgui[el.type] then
				guthscp.error( "guthscp", "element %q is not a recognized type!", el.type )
			else
				form[id] = form_vgui[el.type]( panel, el, config_value[id], form )
				if el.desc then
					panel:ControlHelp( el.desc ):DockMargin( 10, 0, 0, 15 )
				end
			end
		end

		panel:Help( "" )  --  attempt to fix content size
		return form
	end,
	["Category"] = function( panel, el )
		local cat = panel:Help( el.name )
		cat:SetFont( "DermaDefaultBold" )

		return cat
	end,
	["Label"] = function( panel, el )
		return panel:Help( el.name )
	end,
	["Button"] = function( panel, el, config_value, form )
		local button = panel:Button( el.name )
		function button:DoClick()
			el.action( form, serialize_form( form ) )
		end

		return button
	end,
	["NumWang"] = function( panel, el, config_value )
		local numwang, label = panel:NumberWang( el.name, nil, el.min or -math.huge, el.max or math.huge, el.decimals or 0 )
		numwang:SetValue( config_value or el.default or 0 )
		numwang.y = 10
		
		return numwang
	end,
	["TextEntry"] = function( panel, el, config_value )
		local textentry = panel:TextEntry( el.name )
		textentry:SetValue( config_value or el.default or "" )

		return textentry
	end,
	["TextEntry[]"] = function( panel, el, config_value )
		return create_array_vguis( panel, el, config_value, function( parent, value, key )
			local textentry = parent:Add( "DTextEntry" )
			textentry:Dock( TOP )
			textentry:DockMargin( 25, 5, 5, 0 )
			textentry:SetValue( el.value and el.value( value, key ) or isstring( value ) and value or "" )
	
			return textentry
		end )
	end,
	["ComboBox"] = function( panel, el, config_value )
		local value = el.value and el.value( true, config_value or el.default ) --  i know, weird
		--print( value, el.value, config_value, el.default )

		local combobox = panel:ComboBox( el.name )
		combobox:SetValue( isstring( value ) and value or "" )

		for i, v in ipairs( el.choice and el.choice() or {} ) do
			combobox:AddChoice( v.value, v.data, v.value == value )
		end

		return combobox
	end,
	["ComboBox[]"] = function( panel, el, config_value )
		return create_array_vguis( panel, el, config_value, function( parent, value, key )
			--print( "v, k: ", value, key )
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
	["CheckBox"] = function( panel, el, config_value )
		local checkbox = panel:CheckBox( el.name )
		checkbox:SetValue( config_value or false )

		return checkbox
	end,
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

function guthscp.config.populate_config( parent, config )
	--  populate module data
	local module = guthscp.modules[config.id]
	if module then
		local category = parent:Add( "DCollapsibleCategory" )
		category:Dock( TOP )
		category:SetLabel( "Module" )

		local container = vgui.Create( "Panel", category )
		container:Dock( TOP )
		container:DockMargin( 10, 10, 10, 0 )
		
		local container_left = container:Add( "Panel" )
		container_left:Dock( LEFT )
		container_left:SetWide( guthscp.config.menu:GetWide() * .7 )

		--  description
		create_label_category( container_left, "Description" )

		local label_author = create_label( container_left, module.description )
		label_author:SetContentAlignment( 9 )
		label_author:SetAutoStretchVertical( true )
		label_author:SetWrap( true )

		--  dependencies
		if next( module.dependencies ) then
			create_label_category( container_left, "Dependencies" )

			--  show all
			for id, version in pairs( module.dependencies ) do
				local dependency = guthscp.modules[id]
				if dependency then  --  the reverse should not happen (since configs are loaded only if dependencies are constructed)
					local label_icon = container_left:Add( "guthscp_label_icon" ) 
					label_icon:Dock( TOP )
					label_icon:SetIcon( dependency.icon )
					label_icon:SetText( ( "%s (>v%s)" ):format( dependency.name, dependency.version ) )
					function label_icon:DoClick()
						guthscp.config.sheet:SetActiveTab( guthscp.config.sheets[id].Tab )
					end
				end
			end
		end

		--  side bar
		local container_sidebar = container:Add( "Panel" )
		container_sidebar:Dock( FILL )

		create_label_category( container_sidebar, "Details" )

		local data = {
			{
				text = module.author,
				icon = "icon16/user_gray.png",
			},
			{
				text = "v" .. module.version,
				icon = "icon16/drive_go.png",
			},
		}

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

		for i, v in ipairs( data ) do
			local label_icon = container_sidebar:Add( "guthscp_label_icon" )
			label_icon:Dock( TOP )
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
		end

		--  setup children pos
		container:InvalidateChildren( true )
		
		--  height to children
		local max_height = 0
		for i, v in ipairs( table.Merge( container_left:GetChildren(), container_sidebar:GetChildren() ) ) do
			max_height = math.max( max_height, v:GetY() + v:GetTall() )
		end
		container:SetTall( max_height + 5 )
	end
	
	--  create form
	for iform, vform in ipairs( config.elements or {} ) do
		form_vgui[vform.type]( parent, vform, config.id )
	end
end

function guthscp.config.open_menu()
	if not LocalPlayer():IsSuperAdmin() then return end

	--  refresh menu and select previous tab
	local tab_id = 1
	if IsValid( guthscp.config.menu ) then
		if guthscp.config.menu.sheet then 
			tab_id = guthscp.config.menu.sheet.tab_id 
		end
		guthscp.config.menu:Remove() 
	end

	local w, h = ScrW() * .4, ScrH() * .45

	--  create frame
	local frame = vgui.Create( "DFrame" )
	frame:SetSize( w, h )
	frame:Center()
	frame:SetDraggable( false )
	frame:SetTitle( "GuthSCP Configuration" )
	frame:MakePopup()
	guthscp.config.menu = frame

	--  create sheets
	local sheet = frame:Add( "DPropertySheet" )
	sheet:Dock( FILL )
	guthscp.config.sheet = sheet
	guthscp.config.sheets = {}

	--  create configs
	for i, v in SortedPairsByMemberValue( config, "name" ) do
		local panel = sheet:Add( "DPanel" )
		panel:DockPadding( 5, 5, 5, 5 )

		local scroll_panel = panel:Add( "DScrollPanel" )
		scroll_panel:Dock( FILL )

		--  populate
		guthscp.config.populate_config( scroll_panel, v )

		--  add sheet
		guthscp.config.sheets[v.id] = sheet:AddSheet( v.label or v.id, panel, v.icon )

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
guthscp.spawnmenu = guthscp.spawnmenu or {}
guthscp.spawnmenu.weapons = guthscp.spawnmenu.weapons or {}
guthscp.spawnmenu.entities = guthscp.spawnmenu.entities or {}

function guthscp.spawnmenu.add_weapon( weapon, category )
	guthscp.spawnmenu.weapons[category] = guthscp.spawnmenu.weapons[category] or {}
	guthscp.spawnmenu.weapons[category][weapon.Folder] = weapon
	guthscp.info( "guthscp.spawnmenu", "add weapon %q to %q category", weapon.Folder, category )
end

function guthscp.spawnmenu.add_entity( entity, category )
	guthscp.spawnmenu.entities[category] = guthscp.spawnmenu.entities[category] or {}
	guthscp.spawnmenu.entities[category][entity.Folder] = entity
	guthscp.info( "guthscp.spawnmenu", "add entity %q to %q category", entity.Folder, category )
end


local function add_entity_node_doclick( panel, node, list, entity_type )
	function node:DoClick()
		--  populate
		if not IsValid( self.panel ) then 
			--  create container
			local container = panel:Add( "ContentContainer" )
			container:SetVisible( false )
			container:SetTriggerSpawnlistChange( false )

			--  populate weapons categories
			for category, ents in SortedPairs( list ) do
				--  create category label
				local header = panel:Add( "ContentHeader" )
				header:SetText( category )
				container:Add( header )

				--  populate weapons
				for i, weapon in SortedPairsByMemberValue( ents, "PrintName" ) do
					spawnmenu.CreateContentIcon( weapon.ScriptedEntityType or entity_type, container, {
						nicename = weapon.PrintName or weapon.ClassName,
						spawnname = weapon.ClassName,
						material = weapon.IconOverride or "entities/" .. weapon.ClassName .. ".png",
						admin = weapon.AdminOnly
					} )
				end
			end 
			
			--  register
			self.container = container
		end

		--  switch
		panel:SwitchPanel( self.container )
	end
end

hook.Add( "guthscp.spawnmenu:populate", "guthscp.spawnmenu:populate", function( panel, tree )
	--  weapons
	local weapon_node = tree:AddNode( "Weapons", "icon16/gun.png" )
	add_entity_node_doclick( panel, weapon_node, guthscp.spawnmenu.weapons, "weapon" )
	weapon_node:InternalDoClick() --  set default
	
	--  entities
	local entity_node = tree:AddNode( "Entities", "icon16/bricks.png" )
	add_entity_node_doclick( panel, entity_node, guthscp.spawnmenu.entities, "entity" )

	--  modules
	local config_node = tree:AddNode( "Modules", "icon16/wrench.png" )
	config_node:SetExpanded( true, true )  --  instant expand
	config_node.nodes = {}

	--  callback for switching panel (e.g. dependencies hyperlinks)
	local function switch_callback( id )
		local node = config_node.nodes[id]
		if not IsValid( node ) then return end

		node:InternalDoClick()
	end

	--  populating modules
	for id, name in SortedPairsByValue( guthscp.config.get_pages_ids() ) do
		local data = guthscp.modules[id] or guthscp.config.get_all()[id]

		--  creating node
		local node = config_node:AddNode( name, data.icon )
		function node:DoPopulate()
			--  create parent
			local container = panel:Add( "DPanel" )
			container:DockPadding( 5, 5, 5, 5 )
			container:SetVisible( false )
	
			local scroll_panel = container:Add( "DScrollPanel" )
			scroll_panel:Dock( FILL )
	
			--  populate
			guthscp.config.populate_config( scroll_panel, id, switch_callback )
			
			--  register
			self.container = container
		end
		function node:DoClick()
			--  populate
			if not IsValid( self.panel ) then 
				self:DoPopulate()
			end
	
			--  switch
			panel:SwitchPanel( self.container )
		end

		--  register node
		config_node.nodes[id] = node
	end

	guthscp.spawnmenu.config_node = config_node
	guthscp.spawnmenu.panel = panel
end )

spawnmenu.AddCreationTab( "GuthSCP", function()
	local ctrl = vgui.Create( "SpawnmenuContentPanel" )
	ctrl:CallPopulateHook( "guthscp.spawnmenu:populate" )

	return ctrl
end, "icon16/brick.png" )

hook.Add( "OnSpawnMenuOpen", "guthscp.spawnmenu:restrict_config", function()
	if not IsValid( guthscp.spawnmenu.config_node ) then return end

	--  change config visibility
	guthscp.spawnmenu.config_node:SetVisible( LocalPlayer():IsSuperAdmin() )
end )

hook.Add( "guthscp.config:applied", "guthscp.spawnmenu:reload_config", function( id, config )
	if not IsValid( guthscp.spawnmenu.config_node ) or not IsValid( guthscp.spawnmenu.panel ) then return end

	local node = guthscp.spawnmenu.config_node.nodes[id]
	if not IsValid( node ) or not IsValid( node.container ) then return end

	--  get if is selected
	local was_selected = guthscp.spawnmenu.panel.SelectedPanel == node.container

	--  re-create config
	--  ISSUE?: will refresh if you are currently editing the config and someone else apply the config, can be frustrating; 
	--          but this case should not happen since you should not edit the config while someone else is doing it
	node.container:Remove()
	node:DoPopulate()

	--  refresh selection
	if was_selected then
		guthscp.spawnmenu.panel:SwitchPanel( node.container )
	end

	guthscp.info( "guthscp.spawnmenu", "refreshed config %q", id )
end )
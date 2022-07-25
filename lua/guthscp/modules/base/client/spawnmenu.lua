guthscp.spawnmenu = guthscp.spawnmenu or {}
guthscp.spawnmenu.weapons = guthscp.spawnmenu.weapons or {}
guthscp.spawnmenu.entities = guthscp.spawnmenu.entities or {}
guthscp.spawnmenu.config_node = guthscp.spawnmenu.config_node or nil

function guthscp.spawnmenu.add_weapon( weapon, category )
    guthscp.spawnmenu.weapons[category] = guthscp.spawnmenu.weapons[category] or {}
    guthscp.spawnmenu.weapons[category][weapon.Folder] = weapon
    guthscp.info( "guthscp.spawnmenu", "add weapon %q to %q category", weapon.Folder, category )
end

function guthscp.spawnmenu.add_entity( entity, category )
    PrintTable( entity )
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

    --  configuration
    local config_node = tree:AddNode( "Configuration", "icon16/wrench.png" )
    config_node:SetExpanded( true, true )  --  instant expand
    for i, config in SortedPairsByMemberValue( guthscp.config.get_all(), "name" ) do
        local node = config_node:AddNode( config.label, config.icon )
        function node:DoClick()
            --  populate
            if not IsValid( self.panel ) then 
                --  create parent
                local container = panel:Add( "DPanel" )
                container:DockPadding( 5, 5, 5, 5 )
                container:SetVisible( false )
        
                local scroll_panel = container:Add( "DScrollPanel" )
                scroll_panel:Dock( FILL )
        
                --  populate
                guthscp.config.populate_config( scroll_panel, config )
                
                --  register
                self.container = container
            end
    
            --  switch
            panel:SwitchPanel( self.container )
        end
    end
    guthscp.spawnmenu.config_node = config_node
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
guthscp.config = guthscp.config or {}
guthscp.config.path = "guthscpbase"  --  data path

--  config
guthscp.Config = guthscp.Config or {}  --  TODO: find a better name

function guthscp.config.apply( name, tbl, options )
    local config = guthscp.config.get_all()[name]
    if config and config.parse then config.parse( tbl ) end

    guthscp.Config[name] = guthscp.Config[name] or {}
    for k, v in pairs( tbl ) do
        guthscp.Config[name][k] = v
    end

    if istable( options ) then
        if SERVER and options.network then
            timer.Simple( 0, function() 
                guthscp.config.sync( name, tbl ) 
            end )
        end

        if options.save then
            file.CreateDir( guthscp.config.path )
            file.Write( ( guthscp.config.path .. "/%s.json" ):format( name ), util.TableToJSON( tbl, true ) )
        end
    end
end

function guthscp.config.load( name )
    local content = file.Read( ( guthscp.config.path .. "/%s.json" ):format( name ) )
    if not content then return false end

    local tbl = util.JSONToTable( content )
    if not tbl then return false end

    guthscp.config.apply( name, guthscp.table.merge( guthscp.Config[name] or {}, tbl ), {
        network = true,
    } )
    return true
end

function guthscp.config.load_defaults( name )
    local tbl = guthscp.config.get_all()[name]
    if not tbl or not tbl.elements or not tbl.elements[1] or not tbl.elements[1].elements then return end --  yea rude

    for i, v in ipairs( tbl.elements[1].elements ) do
        if v.id and v.default then
            guthscp.Config[name][v.id] = v.default
        end
    end
end

--  run config
local function run_config()
    hook.Run( "guthscp:config" )
end
concommand.Add( "guthscp_reload_configs", function()
    run_config()

    --  dirty reload
    if SERVER then
        for i, v in ipairs( player.GetHumans() ) do
            v:SendLua( "hook.Run( 'guthscp:config' )" )
        end
    end
end )
hook.Add( "InitPostEntity", "guthscp:run_config", run_config )

--  TODO: move that into module main.lua 
hook.Add( "guthscp:config", "guthscp:base", function()

    --  > Configuration
    guthscp.config.add( "guthscp", {
        label = "Base",
        icon = "icon16/bricks.png",
        elements = {
            {
                type = "Form",
                name = "Configuration",
                elements = {
                    {
                        type = "Category",
                        name = "General",
                    },
                    guthscp.config.create_teams_element( {
                        name = "SCP Teams",
                        id = "scp_teams",
                        desc = "All teams which represents a SCP team should be added in the list",
                        default = {
                            "TEAM_SCP035",
                            "TEAM_SCP049",
                            "TEAM_SCP106",
                            "TEAM_SCP096",
                            "TEAM_SCP173",
                            "TEAM_SCP682",
                        },
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
                    {
                        type = "Button",
                        name = "Apply",
                        action = function( form, serialize_form )
                            guthscp.config.send( "guthscp", serialize_form )
                        end,
                    }
                }
            },
        },
        --[[ 
            @function guthscp::config.receive
                | description: Called when an superadministrator apply his configuration to the server. This is where you want to
                            check the sent information and apply the form to the configuration system by using guthscp.config.apply
                | realm: Server
                | params:
                    form: table Formular data
        ]]
        receive = function( form )
            form.scp_teams = guthscp.config.receive_teams( form.scp_teams )

            guthscp.config.apply( "guthscp", form, {
                network = true,
                save = true,
            } )
        end,
        --[[ 
            @function guthscp::config.parse
                | description: Called while a call to guthscp.config.apply (either from guthscp::config.receive or after loading from file)
                               before applying the configuration values. Here you can check your configuration values and edit them.
                | realm: Shared
                | params:
                    form: table Formular data
        ]]
        parse = function( form )
            form.scp_teams = guthscp.config.parse_teams( form.scp_teams )
        end,
    } )

end )
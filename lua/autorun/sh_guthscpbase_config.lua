function GuthSCP.createTeamsConfigElement( element )
    return table.Merge( {
        type = "ComboBox[]",
        name = "Teams",
        id = "teams",
        value = function( config_value, config_key )
            id = isnumber( config_key ) and config_key or isstring( config_key ) and _G[config_key]
            return id and team.GetName( id ) or false
        end,
        choice = function()
            local teams = {}

            for k, v in pairs( team.GetAllTeams() ) do
                if not v.Joinable then continue end
                teams[#teams + 1] = {
                    value = v.Name,
                    data = GuthSCP.getTeamKeyname( k ),
                }
            end

            return teams
        end,
    }, element or {} )
end

function GuthSCP.createTeamConfigElement( element )
    element = GuthSCP.createTeamsConfigElement( element )
    element.type = "ComboBox" --  set element type as a single combobox and not an array
    return element
end

function GuthSCP.createEnumElement( enum, element )
    return table.Merge( {
        type = "ComboBox",
        value = function( config_key, config_value )
            --  is 'config_value' the data?
            if isnumber( config_value ) then
                for k, v in pairs( enum ) do
                    if v == config_value then
                        return k:sub( 1, 1 ):upper() .. k:sub( 2 ):lower()
                    end
                end
            end
            return config_value
        end,
        choice = function()
            local choices = {}

            for k, v in pairs( enum ) do
                choices[#choices + 1] = {
                    value = k:sub( 1, 1 ):upper() .. k:sub( 2 ):lower(),
                    data = v,
                }
            end

            return choices
        end,
    }, element or {} )
end

function GuthSCP.receiveTeamsConfig( teams )
    assert( istable( teams ), "'teams' is not a table" )
    
    return GuthSCP.valuesToKeysTable( teams )
end

function GuthSCP.parseTeamsConfig( teams ) 
    assert( istable( teams ), "'teams' is not a table" )

    local new_teams = {}

    for k, v in pairs( team.GetAllTeams() ) do
        if not v.Joinable then continue end

        local keyname = GuthSCP.getTeamKeyname( k )
        if not keyname then
            GuthSCP.alert( "guthscpbase", "%q doesn't have an unique 'TEAM_' name, this could lead to inability to save this team in the configuration!", v.Name )
            continue
        end
        if not teams[v.Name] and not teams[k] and not teams[keyname] then continue end

        new_teams[keyname] = true
    end

    return new_teams
end

function GuthSCP.parseTeamConfig( team_key )
    local team_id = isnumber( team_key ) and team_key or _G[team_key]
    if not isnumber( team_id ) then return end

    local team_info = team.GetAllTeams()[team_id]
    if not team_info.Joinable then return end

    return GuthSCP.getTeamKeyname( team_id )
end

hook.Add( "guthscpbase:config", "guthscpbase", function()

    --  > Configuration
    GuthSCP.addConfig( "guthscpbase", {
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
                    GuthSCP.createTeamsConfigElement( {
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
                            GuthSCP.sendConfig( "guthscpbase", serialize_form )
                        end,
                    }
                }
            },
        },
        --[[ 
            @function guthscpbase::config.receive
                | description: Called when an superadministrator apply his configuration to the server. This is where you want to
                            check the sent information and apply the form to the configuration system by using GuthSCP.applyConfig
                | realm: Server
                | params:
                    form: table Formular data
        ]]
        receive = function( form )
            form.scp_teams = GuthSCP.receiveTeamsConfig( form.scp_teams )

            GuthSCP.applyConfig( "guthscpbase", form, {
                network = true,
                save = true,
            } )
        end,
        --[[ 
            @function guthscpbase::config.parse
                | description: Called while a call to GuthSCP.applyConfig (either from guthscpbase::config.receive or after loading from file)
                               before applying the configuration values. Here you can check your configuration values and edit them.
                | realm: Shared
                | params:
                    form: table Formular data
        ]]
        parse = function( form )
            form.scp_teams = GuthSCP.parseTeamsConfig( form.scp_teams )
        end,
    } )

end )
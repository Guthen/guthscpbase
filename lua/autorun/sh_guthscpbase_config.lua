function GuthSCP.createTeamsConfigElement( element )
    return table.Merge( {
        type = "ComboBox[]",
        name = "Teams",
        id = "teams",
        value = function( config_value, config_key )
            id = isnumber( config_key ) and config_key or _G[config_value]
            return id and team.GetName( id ) or false
        end,
        choice = function()
            local teams = {}

            for k, v in pairs( team.GetAllTeams() ) do
                if not v.Joinable then continue end
                teams[#teams + 1] = {
                    value = v.Name,
                    data = k,
                }
            end

            return teams
        end,
    }, element or {} )
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
        receive = function( form )
            local teams = {}

            for i, id in ipairs( form.scp_teams ) do
                teams[id] = true
            end

            form.scp_teams = teams
            GuthSCP.applyConfig( "guthscpbase", form, {
                network = true,
                save = true,
            } )
        end,
        parse = function( form )
            local teams = {}

            for k, v in pairs( team.GetAllTeams() ) do
                if not v.Joinable then continue end
                if not form.scp_teams[v.Name] and not form.scp_teams[k] then continue end

                teams[k] = true
            end

            form.scp_teams = teams
        end,
    } )

end )
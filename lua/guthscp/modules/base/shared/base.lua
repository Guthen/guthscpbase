
function guthscp.is_scp( ply )
    if not ply:IsPlayer() then return false end

    local teams = guthscp.configs.base.scp_teams or {}
    return teams[guthscp.get_team_keyname( isnumber( ply ) and ply or ply:Team() )] or false
end

function guthscp.get_scps()
    local teams, players = guthscp.configs.base.scp_teams, {}

    --  no teams? no need to iterate through all players
    if not teams or not next( teams ) then 
        return players 
    end

    for i, v in ipairs( player.GetAll() ) do
        if teams[guthscp.get_team_keyname( v:Team() )] then 
            players[#players + 1] = v 
        end
    end

    return players
end

--  teams
local teams_keynames, keynames_teams
function guthscp.cache_teams_keynames() 
    teams_keynames = {}

    local count = 0
    for k, v in pairs( _G ) do
        if k:StartWith( "TEAM_" ) then
            teams_keynames[k] = v
            count = count + 1
        end
    end
    keynames_teams = guthscp.table.reverse( teams_keynames )

    guthscp.debug( "guthscp", "cached %d teams keynames", count )
end
hook.Add( "InitPostEntity", "guthscp:cache_teams_keynames", guthscp.cache_teams_keynames )

function guthscp.get_teams_keynames()
    if not teams_keynames then 
        guthscp.cache_teams_keynames() 
    end
    
    return teams_keynames
end

function guthscp.get_team_keyname( team_id )
    if not keynames_teams then 
        guthscp.cache_teams_keynames() 
    end

    return keynames_teams[team_id]
end


GuthSCP = GuthSCP or {}

--  config
GuthSCP.Config = GuthSCP.Config or {}

function GuthSCP.applyConfig( name, tbl, options )
    local config = GuthSCP.getConfigs()[name]
    if config and config.parse then config.parse( tbl ) end

    GuthSCP.Config[name] = GuthSCP.Config[name] or {}
    for k, v in pairs( tbl ) do
        GuthSCP.Config[name][k] = v
    end

    if istable( options ) then
        if SERVER and options.network then
            timer.Simple( 0, function() 
                GuthSCP.networkConfig( name, tbl ) 
            end )
        end

        if options.save then
            file.CreateDir( "guthscpbase" )
            file.Write( ( "guthscpbase/%s.json" ):format( name ), util.TableToJSON( tbl, true ) )
        end
    end
end

function GuthSCP.loadConfig( name )
    local content = file.Read( ( "guthscpbase/%s.json" ):format( name ) )
    if not content then return false end

    local tbl = util.JSONToTable( content )
    if not tbl then return false end

    GuthSCP.applyConfig( name, GuthSCP.mergeTable( GuthSCP.Config[name] or {}, tbl ), {
        network = true,
    } )
    return true
end

function GuthSCP.loadConfigDefaults( name )
    local tbl = GuthSCP.getConfigs()[name]
    if not tbl or not tbl.elements or not tbl.elements[1] or not tbl.elements[1].elements then return end --  yea rude

    for i, v in ipairs( tbl.elements[1].elements ) do
        if v.id and v.default then
            GuthSCP.Config[name][v.id] = v.default
        end
    end
end

local function run_config()
    hook.Run( "guthscpbase:config" )
end
concommand.Add( "guthscpbase_reload_configs", function()
    run_config()

    --  dirty reload
    if SERVER then
        for i, v in ipairs( player.GetHumans() ) do
            v:SendLua( "hook.Run( 'guthscpbase:config' )" )
        end
    end
end )

hook.Add( "InitPostEntity", "GuthSCPBase:Config", run_config )

function GuthSCP.isSCP( ply )
    if not ply:IsPlayer() then return false end

    local teams = GuthSCP.Config.guthscpbase.scp_teams or {}
    return teams[GuthSCP.getTeamKeyname( isnumber( ply ) and ply or ply:Team() )] or false
end

function GuthSCP.getSCPs()
    local teams, players = GuthSCP.Config.guthscpbase.scp_teams or {}, {}

    for i, v in ipairs( player.GetAll() ) do
        if teams[GuthSCP.getTeamKeyname( v:Team() )] then 
            players[#players + 1] = v 
        end
    end

    return players
end

--  teams
local teams_keynames, keynames_teams
function GuthSCP.cacheTeamsKeynames() 
    teams_keynames = {}

    local count = 0
    for k, v in pairs( _G ) do
        if k:StartWith( "TEAM_" ) then
            teams_keynames[k] = v
            count = count + 1
        end
    end
    keynames_teams = GuthSCP.reverseTable( teams_keynames )

    GuthSCP.debugPrint( "guthscpbase", "Cached %d teams keynames", count )
end
hook.Add( "InitPostEntity", "GuthSCPBase:CacheTeamsKeynames", GuthSCP.cacheTeamsKeynames )

function GuthSCP.getTeamsKeynames()
    if not teams_keynames then 
        GuthSCP.cacheTeamsKeynames() 
    end
    
    return teams_keynames
end

function GuthSCP.getTeamKeyname( team_id )
    if not keynames_teams then 
        GuthSCP.cacheTeamsKeynames() 
    end

    return keynames_teams[team_id]
end

--  debug
local convar_debug = CreateConVar( "guthscpbase_debug", "0", FCVAR_NONE, "Enables debug messages", "0", "1" )

function GuthSCP.isDebug()
    return convar_debug:GetBool()
end

local function colored_print( color, name, message, ... )
    if ... then 
        message = message:format( ... )
    end
    MsgC( color, "[", name, "] ", message, "\n" )
end

function GuthSCP.alert( name, message, ... )
    colored_print( Color( 245, 78, 66 ), "Alert", name .. ": " .. message, ... )
end

function GuthSCP.print( name, message, ... )
    colored_print( Color( 66, 203, 245 ), "Info", name .. ": " .. message, ... )
end

function GuthSCP.debugPrint( name, message, ... )
    if not GuthSCP.isDebug() then return end

    colored_print( Color( 66, 245, 135 ), "Debug", name .. ": " .. message, ... )
end

--  utilities
function GuthSCP.mergeTable( to_tbl, from_tbl )
    for k, v in pairs( from_tbl ) do
        if not ( from_tbl[k] == nil ) then
            to_tbl[k] = from_tbl[k]
        end
    end

    return to_tbl
end

function GuthSCP.reverseTable( tbl )
    local new_tbl = {}

    for k, v in pairs( tbl ) do
        new_tbl[v] = k
    end

    return new_tbl
end

function GuthSCP.valuesToKeysTable( tbl )
    local new_tbl = {}

    for i, v in ipairs( tbl ) do
        new_tbl[v] = true
    end

    return new_tbl
end

function GuthSCP.rehashTable( tbl )
    local new_tbl = {}

    for k, v in pairs( tbl ) do
        new_tbl[#new_tbl + 1] = v
    end

    return new_tbl
end

--  basic client sound
if SERVER then 
    util.AddNetworkString( "guthscpbase:playsound" )
else
    net.Receive( "guthscpbase:playsound", function()
        GuthSCP.playClientSound( net.ReadString() )
    end )
end

function GuthSCP.playClientSound( ply, sound_path )
    if SERVER then
        if #sound_path == 0 then return end

        net.Start( "guthscpbase:playsound" )
            net.WriteString( sound_path )
        net.Send( ply )
    else
        surface.PlaySound( sound_path or ply )
    end
end
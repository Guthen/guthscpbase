GuthSCP = GuthSCP or {}

local config = {}

function GuthSCP.addConfig( name, tbl )
    tbl.elements = GuthSCP.rehashTable( tbl.elements )
    for i, form in ipairs( tbl.elements ) do
        form.elements = GuthSCP.rehashTable( form.elements )
    end
    config[name] = {
        elements = tbl.elements,
        receive = tbl.receive,
        parse = tbl.parse,
    }


    if not GuthSCP.Config[name] then GuthSCP.Config[name] = {} end
    GuthSCP.loadConfigDefaults( name )
    if not GuthSCP.loadConfig( name ) then
        GuthSCP.applyConfig( name, GuthSCP.Config[name], {
            network = true,
        } )
    end
end 

function GuthSCP.getConfigs()
    return config
end

function GuthSCP.networkConfig( name, tbl, target )
    net.Start( "guthscpbase:send" )
        net.WriteString( name )
        net.WriteTable( tbl )
    if IsValid( target ) then
        net.Send( target )
    else
        net.Broadcast()
    end

    print( ( "GuthSCP ─ Networked %q config to %s" ):format( name, IsValid( target ) and "'" .. target:GetName() .. "'" or "everyone" ) )
end

--  edit config 
util.AddNetworkString( "guthscpbase:send" )
util.AddNetworkString( "guthscpbase:config" )

net.Receive( "guthscpbase:send", function( len, ply )
    if not ply:IsSuperAdmin() then return end

    local config_id = net.ReadString()
    if not config[config_id] then return end

    local form = net.ReadTable()
    if table.Count( form ) <= 0 then return end

    config[config_id].receive( form )
end )

--  network config
net.Receive( "guthscpbase:config", function( len, ply )
    for k, v in pairs( GuthSCP.Config ) do
        GuthSCP.networkConfig( k, v, ply )
    end
end )
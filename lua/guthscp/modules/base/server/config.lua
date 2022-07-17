guthscp = guthscp or {}
guthscp.config = guthscp.config or {}

local config = {}

function guthscp.config.add( name, tbl )
    tbl.elements = guthscp.table.rehash( tbl.elements )
    for i, form in ipairs( tbl.elements ) do
        form.elements = guthscp.table.rehash( form.elements )
    end
    config[name] = {
        elements = tbl.elements,
        receive = tbl.receive,
        parse = tbl.parse,
    }

    if not guthscp.configs[name] then guthscp.configs[name] = {} end
    guthscp.config.load_defaults( name )
    if not guthscp.config.load( name ) then
        guthscp.config.apply( name, guthscp.configs[name], {
            network = true,
        } )
    end
end 

function guthscp.config.get_all()
    return config
end

function guthscp.config.sync( name, tbl, target )
    net.Start( "guthscp.config:send" )
        net.WriteString( name )
        net.WriteTable( tbl )
    if IsValid( target ) then
        net.Send( target )
    else
        net.Broadcast()
    end

    guthscp.info( "guthscp", "networked %q config to %s", name, IsValid( target ) and "'" .. target:GetName() .. "'" or "everyone" )
end

--  edit config 
util.AddNetworkString( "guthscp.config:send" )
util.AddNetworkString( "guthscp.config:receive" )

net.Receive( "guthscp.config:send", function( len, ply )
    if not ply:IsSuperAdmin() then return end

    local config_id = net.ReadString()
    if not config[config_id] then return end

    local form = net.ReadTable()
    if table.Count( form ) <= 0 then return end

    config[config_id].receive( form )
end )

--  network config
net.Receive( "guthscp.config:receive", function( len, ply )
    for k, v in pairs( guthscp.configs ) do
        guthscp.config.sync( k, v, ply )
    end
end )
guthscp.config = guthscp.config or {}
guthscp.configs = guthscp.configs or {}

function guthscp.config.apply( name, tbl, options )
    local config = guthscp.config.get_all()[name]
    if not config then 
        return guthscp.error( "guthscp.config", "trying to apply config %q which isn't registered!", name )
    end

    --  parse
    if config.parse then 
        config.parse( tbl ) 
    end

    --  apply data
    guthscp.configs[name] = guthscp.configs[name] or {}
    for k, v in pairs( tbl ) do
        guthscp.configs[name][k] = v
    end

    --  special options
    if istable( options ) then
        --  network to players
        if SERVER and options.network then
            timer.Simple( 0, function() 
                guthscp.config.sync( name, tbl ) 
            end )
        end

        --  save to json
        if options.save then
            guthscp.data.save_to_json( name .. ".json", tbl, true )
        end
    end
end

function guthscp.config.load( name )
    local tbl = guthscp.data.load_from_json( name .. ".json" )
    if not tbl then return false end

    guthscp.config.apply( name, guthscp.table.merge( guthscp.configs[name] or {}, tbl ), {
        network = true,
    } )
    return true
end

function guthscp.config.load_defaults( name )
    local tbl = guthscp.config.get_all()[name]
    if not tbl or not tbl.elements or not tbl.elements[1] or not tbl.elements[1].elements then return end --  yea rude

    for i, v in ipairs( tbl.elements[1].elements ) do
        if v.id and v.default then
            guthscp.configs[name][v.id] = v.default
        end
    end
end
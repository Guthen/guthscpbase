guthscp.modules = guthscp.modules or {}
guthscp.module = guthscp.module or {}
guthscp.module.path = "guthscp/modules/"

--  loader
function guthscp.module.construct( id )
    local module = guthscp.require_file( guthscp.module.path .. id .. "/main.lua", guthscp.REALMS.SHARED )
    if not module then 
        return print( "guthscp: error, failed to construct module" .. id .. ", main.lua not found!" ) 
    end

    --  check required properties
    if not isstring( module.name ) or #module.name == 0 then
        return print( "guthscp module: error, module lack the 'name' property of type 'string'" )
    end
    if not isstring( module.id ) or #module.id == 0 then
        return print( "guthscp module: error, module lack the 'id' property of type 'string'" )
    end
    if not isstring( module.version ) or not guthscp.helpers.split_version( module.version ) then
        return print( "guthscp module: error, module lack the 'version' property of type 'string'")
    end

    --  inherit meta (@'meta.lua')
    setmetatable( module, guthscp.module.meta )

    --  construct
    module:construct()

    --  register
    guthscp.modules[id] = module
    print( "guthscp module: " .. id .. " is constructed and registered" )
end

function guthscp.module.call( id, method, ... )
    local module = guthscp.modules[id]
    if not module then 
        return print( "guthscp: error, failed to call module " .. id .. "/" .. method .. "( " .. table.concat( { ... }, "," ) .. " ), module not found!" ) 
    end

    module[method]( self, ... )
end

function guthscp.module.init( id )
    local module
    if istable( id ) then 
        module = id
        id = module.id
    else
        module = guthscp.modules[id]
    end
    
    if not module then 
        return print( "guthscp: error, failed to init module " .. id .. ", module not found!" ) 
    end

    --  TODO: version URL checking

    --  check dependencies
    for dep_id, version in pairs( module.dependencies ) do
        --  ensure dependency is constructed
        local dep_module = guthscp.modules[dep_id]
        if not dep_module then 
            return print( "guthscp module: error, dependency " .. dep_id .. " wasn't found, aborting initializing of " .. id ) 
        end

        --  compare version
        local current_versions = { guthscp.helpers.split_version( dep_module.version ) }
        local required_versions = { guthscp.helpers.split_version( version ) }

        for i = 1, 3 do
            local current = tonumber( current_versions[i] )
            local required = tonumber( required_versions[i] )

            --  version is greater than required
            if current > required then
                --  warn for eventual API's changes
                if i == 1 then
                    print( "guthscp module: warning, dependency " .. dep_id .. " API's version is greater than required, script errors could happen" )
                end
                break
            end

            --  version is lower than required
            if current < required then
                print( "guthscp module: error, dependency " .. dep_id .. "'s version is lower than required (" .. dep_module.version .. "<" .. version .. ")" )
                return
            end
        end
    end

    --  load requires
    print( "guthscp module: found " .. table.Count( module.requires ) .. " requires.." )
    for path, realm in pairs( module.requires ) do
        local current_path = guthscp.module.path .. module.id .. "/" .. path

        --  require folder
        if current_path:find( "/$" ) then
            local files = file.Find( current_path .. "*", "LUA" )
            for i, name in ipairs( files ) do
                guthscp.require_file( current_path .. name, realm )
            end
        --  require file
        else
            guthscp.require_file( current_path, realm )
        end
    end

    --  call init
    module:init()
    print( "guthscp module: " .. id .. " is initialized" )
end


function guthscp.module.require()
    guthscp.modules = {}

    --  find modules
    local _, dirs = file.Find( guthscp.module.path .. "*", "LUA" )
    print( "guthscp module: found " .. #dirs .. " modules.." )
    if #dirs == 0 then 
        return print( "guthscp module: aborting.." ) 
    end

    --  construct modules
    print( "guthscp module: constructing.." )
    for i, name in ipairs( dirs ) do
        guthscp.module.construct( name )
    end

    --  init modules
    print( "guthscp module: initializing.." )
    for id, module in pairs( guthscp.modules ) do
        guthscp.module.init( module )
    end

    print( "guthscp module: finished!" )
end
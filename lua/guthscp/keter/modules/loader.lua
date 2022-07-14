guthscp.modules = guthscp.modules or {}
guthscp.modules_path = "guthscp/modules/"

--  loader
function guthscp.construct_module( id )
    local module = guthscp.require_file( guthscp.modules_path .. id .. "/main.lua", guthscp.REALMS.SHARED )
    if not module then return print( "guthscp: error, failed to construct module" .. id .. ", main.lua not found!" ) end

    --  inherit meta
    setmetatable( module, guthscp.module_meta )

    --  construct
    module:construct()

    --  register
    guthscp.modules[id] = module
    print( "guthscp module: " .. id .. " is constructed and registered" )
end

function guthscp.call_module( id, method, ... )
    local module = guthscp.modules[id]
    if not module then return print( "guthscp: error, failed to call module " .. id .. "/" .. method .. "( " .. table.concat( { ... }, "," ) .. " ), module not found!" ) end

    module[method]( self, ... )
end

function guthscp.init_module( id )
    local module
    if istable( id ) then 
        module = id
        id = module.id
    else
        module = guthscp.modules[id]
    end
    
    if not module then return print( "guthscp: error, failed to init module " .. id .. ", module not found!" ) end

    --  TODO: version & dependency checking

    --  load requires
    print( "guthscp module: found " .. table.Count( module.requires ) .. " requires.." )
    for path, realm in pairs( module.requires ) do
        local current_path = guthscp.modules_path .. module.id .. "/" .. path

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


function guthscp.require_modules()
    guthscp.modules = {}

    --  find modules
    local _, dirs = file.Find( guthscp.modules_path .. "*", "LUA" )
    print( "guthscp module: found " .. #dirs .. " modules.." )
    if #dirs == 0 then return print( "guthscp module: aborting.." ) end

    --  construct modules
    print( "guthscp module: constructing.." )
    for i, name in ipairs( dirs ) do
        guthscp.construct_module( name )
    end

    --  init modules
    print( "guthscp module: initializing.." )
    for id, module in pairs( guthscp.modules ) do
        guthscp.init_module( module )
    end

    print( "guthscp module: finished!" )
end
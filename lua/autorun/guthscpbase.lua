--[[ 
    TODO:
    - log system for message, error & warning output
 ]]

guthscp = guthscp or {}

guthscp.REALMS = {
    SERVER = 0,
    CLIENT = 1,
    SHARED = 2,
}

--  file management
function guthscp.require_file( path, realm )
    if realm == guthscp.REALMS.SERVER then
        if SERVER then
            print( "guthscp: server include " .. path )
            return include( path )
        end
    elseif realm == guthscp.REALMS.CLIENT then
        print( "guthscp: client include " .. path )
        if SERVER then
            AddCSLuaFile( path )
        else
            return include( path )
        end
    elseif realm == guthscp.REALMS.SHARED then
        print( "guthscp: shared include " .. path )
        if SERVER then
            AddCSLuaFile( path )
        end
        return include( path )
    else
        print( "guthscp: failed to include " .. path .. "; unhandled realm ID: " .. tostring( realm ) )
    end
end

function guthscp.require_folder( path, is_recursive )
    print( "require folder", path, is_recursive )
    local files, dirs = file.Find( path .. "*", "LUA" )

    --  load files
    for i, v in ipairs( files ) do
        local realm = guthscp.REALMS.SHARED
        if v:find( "^sv_" ) then
            realm = guthscp.REALMS.SERVER
        elseif v:find( "^cl_" ) then
            realm = guthscp.REALMS.CLIENT
        end
        guthscp.require_file( path .. v, realm )
    end

    --  load folders (recursive)
    if is_recursive then
        for i, v in ipairs( dirs ) do
            guthscp.require_folder( path .. v .. "/", is_recursive )
        end
    end
end

--  load
guthscp.require_folder( "guthscp/keter/", true )
guthscp.require_modules()
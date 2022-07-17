guthscp.data = guthscp.data or {}
guthscp.data.path = "guthscp/"

function guthscp.data.save( name, data )
    file.CreateDir( guthscp.data.path )  --  ensure base folder is created
    file.Write( guthscp.data.path .. name, data )
end

function guthscp.data.save_to_json( name, tbl, is_pretty_print )
    local json = util.TableToJSON( tbl, is_pretty_print )
    if not json then 
        return guthscp.error( "guthscp.data", "failed to export json for %q", name )
    end

    guthscp.data.save( name, json )
end

function guthscp.data.exists( name )
    return file.Exists( guthscp.data.path .. name, "DATA" )
end

function guthscp.data.load( name )
    return file.Read( guthscp.data.path .. name, "DATA" )
end

function guthscp.data.load_from_json( name )
    local json = guthscp.data.load( name )
    if not json then return end

    return util.JSONToTable( json )
end


--  workaround: move old 'guthscpbase' config files
local files = file.Find( "guthscpbase/*", "DATA" )
if #files > 0 then
    guthscp.info( "guthscp.data", "old \"guthscpbase\" folder detected, moving %d files..", #files )

    guthscp.print_tabs = guthscp.print_tabs + 1
    for i, name in ipairs( files ) do
        local source_path = "guthscpbase/" .. name

        --  read source file
        local data = file.Read( source_path, "DATA" )
        if not data then
            guthscp.error( "failed to read %q", source_path )
            continue
        end

        --  renaming "guthscpbase.json" to "base.json"
        if name == "guthscpbase.json" then
            name = "base.json"
        end

        --  save file to correct path
        guthscp.data.save( name, data )

        --  delete source path
        file.Delete( source_path )

        guthscp.info( "guthscp.data", "moving %q to %q", source_path, guthscp.data.path .. name )
    end
    guthscp.print_tabs = guthscp.print_tabs - 1

    file.Delete( "guthscpbase" )
end
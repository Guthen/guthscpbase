guthscp.data = guthscp.data or {}
guthscp.data.path = "guthscp/"

--[[ 
	@function guthscp.data.save
		| description: save to a data file; the file is relative to 'guthscp/'
		| params:
			name: <string> file name
			data: <string> content to save
]]
function guthscp.data.save( name, data )
	file.CreateDir( string.GetPathFromFilename( guthscp.data.path .. name ) )  --  ensure base folder is created
	file.Write( guthscp.data.path .. name, data )
end

--[[ 
	@function guthscp.data.save_to_json
		| description: save table as json to a data file; use `guthscp.data.save` internally
		| params:
			name: <string> file name
			tbl: <table> table to convert and save
			is_pretty_print: <bool?> should save json as pretty print
]]
function guthscp.data.save_to_json( name, tbl, is_pretty_print )
	local json = util.TableToJSON( tbl, is_pretty_print )
	if not json then 
		return guthscp.error( "guthscp.data", "failed to export json for %q", name )
	end

	guthscp.data.save( name, json )
end

--[[ 
	@function guthscp.data.exists
		| description: check if a data file relative to 'guthscp/' exists
		| params:
			name: <string> file name
		| return: <bool> exists
]]
function guthscp.data.exists( name )
	return file.Exists( guthscp.data.path .. name, "DATA" )
end

--[[ 
	@function guthscp.data.load
		| description: get the data file content relative to 'guthscp/'
		| params:
			name: <string> file name
		| return: <string?> content
]]
function guthscp.data.load( name )
	return file.Read( guthscp.data.path .. name, "DATA" )
end

--[[ 
	@function guthscp.data.load_from_json
		| description: get the json data file content relative to 'guthscp/' as a table 
		| params:
			name: <string> file name
		| return: <table?> tbl
]]
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
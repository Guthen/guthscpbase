guthscp.data = guthscp.data or {}
guthscp.data.path = "guthscp/"

--[[ 
	@function guthscp.data.save
		| description: save to a data file; the file is relative to 'guthscp/'
		| params:
			path: <string> file path
			data: <string> content to save
]]
function guthscp.data.save( path, data, is_absolute )
	local path = guthscp.data.path .. path
	file.CreateDir( string.GetPathFromFilename( path ) )  --  ensure all folders are created
	file.Write( path, data )
end

--[[ 
	@function guthscp.data.save_to_json
		| description: save table as json to a data file; use @`guthscp.data.save` internally
		| params:
			path: <string> file path
			tbl: <table> table to convert and save
			is_pretty_print: <bool?> should save json as pretty print
]]
function guthscp.data.save_to_json( path, tbl, is_pretty_print )
	local json = util.TableToJSON( tbl, is_pretty_print )
	if not json then 
		return guthscp.error( "guthscp.data", "failed to export json for %q", path )
	end

	guthscp.data.save( path, json )
end

--[[ 
	@function guthscp.data.exists
		| description: check if a data file relative to 'guthscp/' exists
		| params:
			path: <string> file path
		| return: <bool> exists
]]
function guthscp.data.exists( path )
	return file.Exists( guthscp.data.path .. path, "DATA" )
end

--[[ 
	@function guthscp.data.load
		| description: get the data file content relative to 'guthscp/'
		| params:
			path: <string> file path
		| return: <string?> content
]]
function guthscp.data.load( path )
	return file.Read( guthscp.data.path .. path, "DATA" )
end

--[[ 
	@function guthscp.data.load_from_json
		| description: get the json data file content relative to 'guthscp/' as a table 
		| params:
			path: <string> file path
		| return: <table?> tbl
]]
function guthscp.data.load_from_json( path )
	local json = guthscp.data.load( path )
	if not json then return end

	return util.JSONToTable( json )
end

--[[ 
	@function guthscp.data.move_file
		| description: move a data file from an absolute path to a new path relative to 'guthscp/'; the old file WILL be deleted
		| params:
			path: <string> absolute path to the data file to move
			new_path: <string> relative destination path to 'guthscp/'
		| return: <bool> is_success
]]
function guthscp.data.move_file( path, new_path )
	--  read source file
	local data = file.Read( path, "DATA" )
	if not data then
		guthscp.error( "guthscp.data", "failed to read %q", path )
		return false
	end

	guthscp.info( "guthscp.data", "moving file %q to %q", path, guthscp.data.path .. new_path )
	
	--  save file to the new path
	guthscp.data.save( new_path, data )

	--  delete source path
	file.Delete( path )

	return true
end

--[[ 
	@function guthscp.data.move
		| description: similarly to @`guthscp.data.move_file`, move recursively a list of data files and/or directories found by 
					   a wildcard to a new path relative to `guthscp/`; the old folder WILL NOT be deleted
		| params:
			path: <string> absolute path to the data folder to move
			wildcard: <string> wildcard to be use by @`file.Find`, recursively passed
			new_path: <string> relative destination path to 'guthscp/'
		| return: <bool> is_success
]]
function guthscp.data.move( path, wildcard, new_path, callback )
	local files, dirs = file.Find( path .. wildcard, "DATA" )
	if #files == 0 and #dirs == 0 then return false end

	guthscp.info( "guthscp.data", "moving %d files and %d folders from %q to %q", #files, #dirs, path, new_path )
	guthscp.print_tabs = guthscp.print_tabs + 1

	--  moving files
	for i, name in ipairs( files ) do
		local source_path = path .. name
		local end_path = new_path .. name
		
		--  get custom end path 
		if callback then
			end_path = callback( name, source_path, end_path )
		end

		--  move file
		guthscp.data.move_file( source_path, end_path )
	end

	--  moving folders
	for i, name in ipairs( dirs ) do
		local source_path = path .. name .. "/"
		local end_path = new_path .. name .. "/"

		--  get custom end path 
		if callback then
			end_path = callback( name, source_path, end_path )
		end
		
		--  move folder
		guthscp.info( "guthscp.data", "moving folder %q to %q", source_path, guthscp.data.path .. end_path )

		guthscp.print_tabs = guthscp.print_tabs + 1
		guthscp.data.move( path .. name .. "/", wildcard, end_path, callback )
		guthscp.print_tabs = guthscp.print_tabs - 1
	end

	guthscp.print_tabs = guthscp.print_tabs - 1

	return true
end
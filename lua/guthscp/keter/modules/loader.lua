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

	--  copy variables (preventing editing meta)
	for k, v in pairs( guthscp.module.meta ) do
		if k:StartWith( "__" ) or module[k] then continue end
		if isfunction( v ) then continue end
		
		--  copy element
		if istable( v ) then
			module[k] = table.Copy( v )
		else
			module[k] = v
		end
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

	--  version URL checking
	if module.version_url then
		module._.version_check = guthscp.VERSION_STATES.PENDING
		--    ^^^ ._.  funny emote

		http.Fetch( module.version_url, 
			function( body )
				local remote_version = body:match( "version = \".+\"" )
				if not remote_version then 
					module._.version_check = guthscp.VERSION_STATES.NONE
					return print( "guthscp module: error, failed to retrieve online version for " .. id ) 
				end

				--  compare versions
				local result = guthscp.helpers.compare_versions( module.version, remote_version )
				if result >= 0 then
					module._.version_check = guthscp.VERSION_STATES.UPDATE
					print( "guthscp module: " .. id .. " is up-to-date" )
				else
					module._.version_check = guthscp.VERSION_STATES.OUTDATE
					print( "guthscp module: " .. id .. " is out-of-date, consider updating it!" )
				end
			end,
			function( reason )
				print( "guthscp module: error, failed to check version of " .. id .. " (" .. reason .. ")" )
			end
		)
	end

	--  check dependencies
	for dep_id, version in pairs( module.dependencies ) do
		--  ensure dependency is registered
		local dep_module = guthscp.modules[dep_id]
		if not dep_module then 
			return print( "guthscp module: error, dependency " .. dep_id .. " wasn't found, aborting initializing of " .. id ) 
		end

		--  compare version
		local result, depth = guthscp.helpers.compare_versions( dep_module.version, version )
		if result >= 0 then
			--  warn for eventual API's changes
			if depth == 1 then
				print( "guthscp module: warning, dependency " .. dep_id .. " API's version is greater than required, script errors could happen" )
			end
		else
			print( "guthscp module: error, dependency " .. dep_id .. "'s version is lower than required (" .. dep_module.version .. "<" .. version .. ")" )
			return
		end
	end

	--  load requires
	print( "guthscp module: found " .. table.Count( module.requires ) .. " requires.." )  --  TODO: fix requires count
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
	module._.is_initialized = true
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
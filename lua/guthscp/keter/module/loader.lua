guthscp.modules = guthscp.modules or {}
guthscp.module = guthscp.module or {}
guthscp.module.path = "guthscp/modules/"
guthscp.module.is_loading = false

--  loader
function guthscp.module.construct( id )
	guthscp.info( "guthscp.module", "%q", id )
	guthscp.print_tabs = guthscp.print_tabs + 1

	local module = guthscp.require_file( guthscp.module.path .. id .. "/main.lua", guthscp.REALMS.SHARED )
	if not module then 
		return guthscp.error( "guthscp.module", "failed to construct module %q (\"main.lua\" not found)!", id ) 
	end

	--  check required properties
	local failed = false
	if not isstring( module.name ) or #module.name == 0 then
		failed = true
		guthscp.error( "guthscp.module", "%q must have the 'name' property of type 'string'", id )
	end
	if not isstring( module.id ) or #module.id == 0 then
		failed = true 
		guthscp.error( "guthscp.module", "%q must have the 'id' property of type 'string'", id )
	end
	if not isstring( module.version ) or not guthscp.helpers.split_version( module.version ) then
		failed = true
		guthscp.error( "guthscp.module", "%q must have the 'version' property of type 'string'", id )
	end

	if failed then
		guthscp.print_tabs = guthscp.print_tabs - 1
		return
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
	--  inherit @'meta.lua'
	setmetatable( module, guthscp.module.meta )

	--  construct
	guthscp.print_tabs = guthscp.print_tabs + 1
	module:construct()
	guthscp.print_tabs = guthscp.print_tabs - 1
	
	--  register
	guthscp.modules[id] = module
	module:info( "constructed!" )
	guthscp.print_tabs = guthscp.print_tabs - 1
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
		return guthscp.error( "guthscp.module", "failed to initialize module %q (module not found)!", id ) 
	end

	guthscp.info( "guthscp.module", "%q (v%s)", id, module.version )
	guthscp.print_tabs = guthscp.print_tabs + 1

	--  version URL checking
	if module.version_url then
		module._.version_check = guthscp.VERSION_STATES.PENDING
		--    ^^^ ._.  funny emote
	end

	--  check dependencies
	for dep_id, version in pairs( module.dependencies ) do
		--  ensure dependency is registered
		local dep_module = guthscp.modules[dep_id]
		if not dep_module then 
			return guthscp.error( "guthscp.module", "dependency %q can't be found, aborting initializing of %q", dep_id, id ) 
		end

		--  compare version
		local result, depth = guthscp.helpers.compare_versions( dep_module.version, version )
		if result >= 0 then
			--  warn for eventual API's changes
			if depth == 1 then
				guthscp.warning( "guthscp.module", "dependency %q API's version is greater than required, script errors could happen with module %q", dep_id, id )
			end
		else
			return guthscp.error( "guthscp.module", "dependency %q's version is lower than required (current: v%s; required: v%s)", dep_module.version, version )
		end
	end

	--  load requires
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

	--  add config
	if istable( module.config ) then
		guthscp.config.add( module.id, {
			label = module.name,
			icon = module.icon,
			elements = {
				{
					type = "Form",
					name = "Configuration",
					elements = module.config.form,
				},
			},
			receive = module.config.receive,
			parse = module.config.parse,
		}, true )
	end

	--  call init
	guthscp.print_tabs = guthscp.print_tabs + 1
	module:init()
	guthscp.print_tabs = guthscp.print_tabs - 1

	--  register state
	module._.is_initialized = true
	module:info( "initialized!" )
	guthscp.print_tabs = guthscp.print_tabs - 1
end

function guthscp.module.require()
	guthscp.modules = {}
	guthscp.module.is_loading = true

	--  find modules
	local _, dirs = file.Find( guthscp.module.path .. "*", "LUA" )
	if #dirs == 0 then 
		return guthscp.warning( "guthscp.module", "no modules found, aborting.." ) 
	end
	guthscp.info( "guthscp.module", "loading %d modules..", #dirs )
	guthscp.print_tabs = guthscp.print_tabs + 1

	--  construct modules
	guthscp.info( "guthscp.module", "constructing.." )
	guthscp.print_tabs = guthscp.print_tabs + 1
	for i, name in ipairs( dirs ) do
		guthscp.module.construct( name )
	end
	guthscp.print_tabs = guthscp.print_tabs - 1

	--  init modules
	guthscp.info( "guthscp.module", "initializing.." )
	guthscp.print_tabs = guthscp.print_tabs + 1
	for id, module in pairs( guthscp.modules ) do
		guthscp.module.init( module )
	end
	guthscp.print_tabs = guthscp.print_tabs - 1
	
	guthscp.info( "guthscp.module", "finished!" )
	guthscp.print_tabs = guthscp.print_tabs - 1
	print()

	guthscp.module.is_loading = false
end

function guthscp.module.hot_reload( module )
	if guthscp.module.is_loading then return end  --  avoid infinite loops
	guthscp.module.is_loading = true

	guthscp.info( "guthscp.module", "hot reloading %q..", module.id )
	guthscp.print_tabs = guthscp.print_tabs + 1

	--  construct
	guthscp.info( "guthscp.module", "constructing.." )
	guthscp.print_tabs = guthscp.print_tabs + 1
	guthscp.module.construct( module.id )
	guthscp.print_tabs = guthscp.print_tabs - 1

	--  initialize
	guthscp.info( "guthscp.module", "initializing.." )
	guthscp.print_tabs = guthscp.print_tabs + 1
	guthscp.module.init( module.id )

	guthscp.print_tabs = guthscp.print_tabs - 2
	print()

	guthscp.module.is_loading = false
end


--  modules load config
hook.Add( "InitPostEntity", "guthscp.modules:load_config", function()
	for id, module in pairs( guthscp.modules ) do
		if not module.config then continue end

		guthscp.config.load( id )
	end
end )

--  modules version checking
hook.Add( "InitPostEntity", "guthscp.modules:version_url", function()
	timer.Simple( 5, function()
		for id, module in pairs( guthscp.modules ) do
			if not module.version_url then continue end
	
			http.Fetch( module.version_url, 
				function( body )
					local remote_version = body:match( "version = \"(.-)\"" )
					if not remote_version then 
						module._.version_check = guthscp.VERSION_STATES.NONE
						return guthscp.error( "guthscp.module", "failed to retrieve online version for %q (pattern returned nil)!", id ) 
					end
	
					--  compare versions
					local result = guthscp.helpers.compare_versions( module.version, remote_version )
					if result >= 0 then
						module._.version_check = guthscp.VERSION_STATES.UPDATE
						guthscp.info( "guthscp.module", "%q is up-to-date (v%s)", id, module.version )
					else
						module._.version_check = guthscp.VERSION_STATES.OUTDATE
						guthscp.warning( "guthscp.module", "%q is out-of-date, consider updating it (current: v%s; online: v%s)", id, module.version, remote_version )
					end
				end,
				function( reason )
					guthscp.error( "guthscp.module", "failed to check version of %q (%s)!", id, reason )
				end
			)
		end
	end )
end )
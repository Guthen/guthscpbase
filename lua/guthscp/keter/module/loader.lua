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
		guthscp.error( "guthscp.module", "failed to construct module %q (\"main.lua\" not found)!", id )
		guthscp.print_tabs = guthscp.print_tabs - 1
		return false
	end

	--  set id
	module.id = id

	--  check required properties
	if not isstring( module.name ) or #module.name == 0 then
		guthscp.error( "guthscp.module", "%q must have the 'name' property of type 'string'", id )
		guthscp.print_tabs = guthscp.print_tabs - 1
		return false
	end
	if not isstring( module.author ) or #module.author == 0 then
		guthscp.error( "guthscp.module", "%q must have the 'author' property of type 'string'", id )
		guthscp.print_tabs = guthscp.print_tabs - 1
		return false
	end
	if not isstring( module.version ) or not guthscp.helpers.split_version( module.version ) then
		guthscp.error( "guthscp.module", "%q must have the 'version' property of type 'string'", id )
		guthscp.print_tabs = guthscp.print_tabs - 1
		return false
	end

	--  inherit meta
	guthscp.helpers.use_meta( module, guthscp.module.meta )

	--  construct
	module:info( "module constructing.." )
	guthscp.print_tabs = guthscp.print_tabs + 1
	module:construct()
	guthscp.print_tabs = guthscp.print_tabs - 1

	--  register
	guthscp.modules[id] = module
	guthscp.print_tabs = guthscp.print_tabs - 1
	return true
end

local function capitalise_first_letter( str )
	return str:gsub( "^%w", function( letter )
		return letter:upper()
	end )
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
		guthscp.error( "guthscp.module", "failed to initialize module %q (module not found)!", id )
		return false
	end

	local old_tabs = guthscp.print_tabs
	guthscp.info( "guthscp.module", "%q (v%s)", id, module.version )
	guthscp.print_tabs = guthscp.print_tabs + 1

	--  version URL checking
	if module.version_url then
		module._.version_check = guthscp.VERSION_STATES.PENDING
		--    ^^^ ._.  funny emote
	end

	--  warn for using a pre-release version
	local tag_version = select( 4, guthscp.helpers.split_version( module.version ) )
	if #tag_version > 0 then
		module:add_warning( "Development version %q is used, some features may be broken!", tag_version )
	end

	--  check dependencies
	local is_optional
	local can_initialize = true
	for dep_id, version in pairs( module.dependencies ) do
		--  check for optional dependency
		version, is_optional = guthscp.helpers.read_dependency_version( version )

		--  ensure dependency is registered
		local dep_module = guthscp.modules[dep_id]
		if not dep_module then
			if is_optional then
				guthscp.info( "guthscp.module", "optional dependency %q isn't installed, skipping (required: v%s)", dep_id, version )
				continue
			else
				guthscp.error( "guthscp.module", "dependency %q isn't installed (required: v%s)", dep_id, version )
				module:add_error( "Dependency %q wasn't found, install its version v%s+!", dep_id, version )

				can_initialize = false
				continue
			end
		end

		--  construct dependency text
		local dep_text = "dependency"
		if is_optional then
			dep_text = "optional " .. dep_text
		end

		--  compare version
		local result, depth = guthscp.helpers.compare_versions( dep_module.version, version )
		if result >= 0 then
			--  warn for eventual API's changes
			if depth == 1 then
				guthscp.warning(
					"guthscp.module",
					"%s %q API's version is greater than required, script errors could happen (current: v%s; required: v%s)",
					dep_text, dep_id,
					dep_module.version, version
				)
				module:add_warning(
					"%s %q API's version is greater than required, script errors could happen!",
					capitalise_first_letter( dep_text ), dep_id
				)
			else
				guthscp.info(
					"guthscp.module",
					"%s %q is found (current: v%s; required: v%s)",
					dep_text, dep_id,
					dep_module.version, version
				)
			end
		--  warn for versions using development tag
		elseif depth == 4 then
			guthscp.warning(
				"guthscp.module",
				"%s %q is under a development version, beware, some features may be broken (current: v%s; required: v%s)",
				dep_text, dep_id,
				dep_module.version, version
			)
			module:add_warning(
				"%s %q is using a development version, some features may be broken!",
				capitalise_first_letter( dep_text ), dep_id
			)
		--  version lower than required, failing!
		else
			guthscp.error(
				"guthscp.module",
				"%s %q version is lower than required, update it (current: v%s; required: v%s)",
				dep_text, dep_id,
				dep_module.version, version
			)
			module:add_error(
				"%s %q version is lower than required, update it to v%s+!",
				capitalise_first_letter( dep_text ),
				dep_id, version
			)

			can_initialize = false
			continue
		end
	end

	if not can_initialize then
		guthscp.print_tabs = old_tabs
		return false
	end

	--  add config
	if istable( module.menu ) and istable( module.menu.config ) then
		guthscp.info( "guthscp.module", "registering the configuration" )
		guthscp.print_tabs = guthscp.print_tabs + 1

		--  register and defer config data loading later
		guthscp.config.add( module.id, {
			name = module.name,
			icon = module.icon,
			form = module.menu.config.form,
			receive = module.menu.config.receive or function( form )
				guthscp.config.apply( module.id, form, {
					network = true,
					save = true,
				} )
			end,
			parse = module.menu.config.parse,
		}, /* no_load */ true )

		guthscp.print_tabs = guthscp.print_tabs - 1
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

	--  call init
	module:info( "module initializing.." )
	guthscp.print_tabs = guthscp.print_tabs + 1
	module:init()
	guthscp.print_tabs = guthscp.print_tabs - 1

	--  register state
	module._.is_initialized = true
	guthscp.print_tabs = guthscp.print_tabs - 1
	return true
end

function guthscp.module.require()
	guthscp.modules = {}
	guthscp.module.is_loading = true

	--  find modules
	local _, dirs = file.Find( guthscp.module.path .. "*", "LUA" )
	if #dirs == 0 then
		return guthscp.warning( "guthscp.module", "no modules found, aborting.." )
	end
	guthscp.info( "guthscp.module", "loading %d modules...", #dirs )
	guthscp.print_tabs = guthscp.print_tabs + 1

	--  construct modules
	guthscp.info( "guthscp.module", "constructing..." )
	guthscp.print_tabs = guthscp.print_tabs + 1
	for i, name in ipairs( dirs ) do
		guthscp.module.construct( name )
	end
	guthscp.print_tabs = guthscp.print_tabs - 1

	--  init modules
	guthscp.info( "guthscp.module", "initializing..." )
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

function guthscp.module.hot_reload( id )
	if guthscp.module.is_loading then return end  --  avoid stack overflow
	guthscp.module.is_loading = true

	local old_module = guthscp.modules[id]

	guthscp.info( "guthscp.module", "hot reloading %q...", id )
	guthscp.print_tabs = guthscp.print_tabs + 1

	--  construct
	guthscp.info( "guthscp.module", "constructing..." )
	guthscp.print_tabs = guthscp.print_tabs + 1
	if not guthscp.module.construct( id ) then
		guthscp.print_tabs = 0
		return
	end
	guthscp.print_tabs = guthscp.print_tabs - 1

	--  initialize
	guthscp.info( "guthscp.module", "initializing..." )
	guthscp.print_tabs = guthscp.print_tabs + 1
	if not guthscp.module.init( id ) then
		guthscp.print_tabs = 0
		return
	end
	guthscp.print_tabs = guthscp.print_tabs - 1

	--  load config
	local module = guthscp.modules[id]
	if istable( module.menu ) and istable( module.menu.config ) then
		guthscp.info( "guthscp.module", "config.." )
		guthscp.print_tabs = guthscp.print_tabs + 1
		guthscp.config.load( id )
		guthscp.print_tabs = guthscp.print_tabs - 1
	end

	--  append version check
	if old_module then
		module._.version_check = old_module._.version_check
		module._.online_version = old_module._.online_version
	end

	--  reload menu
	if CLIENT then
		guthscp.config.remove_menu()
	end

	guthscp.print_tabs = guthscp.print_tabs - 1
	print()

	guthscp.module.is_loading = false
end


--  modules load config
if SERVER then
	hook.Add( "InitPostEntity", "guthscp.modules:load_config", function()
		guthscp.info( "guthscp.module", "loading configurations..." )
		guthscp.print_tabs = guthscp.print_tabs + 1

		for id, module in pairs( guthscp.modules ) do
			if not istable( module.menu ) or not istable( module.menu.config ) then continue end

			if not guthscp.config.load( id ) then
				--  still apply the config if no data has been found to ensure
				--  that the 'guthscp.config:applied' hook is called no matter what
				guthscp.config.apply( id, {}, {
					network = true
				} )
			end
		end

		guthscp.print_tabs = guthscp.print_tabs - 1
	end )
end

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

					--  store online version
					module._.online_version = remote_version

					--  compare versions
					local result = guthscp.helpers.compare_versions( module.version, remote_version )
					if result >= 0 then
						module._.version_check = guthscp.VERSION_STATES.UPDATE
						guthscp.info( "guthscp.module", "%q is up-to-date (v%s)", id, module.version )
					else
						module._.version_check = guthscp.VERSION_STATES.OUTDATE
						guthscp.warning( "guthscp.module", "%q is out-of-date, consider updating it (current: v%s; online: v%s)", id, module.version, remote_version )
						module:add_warning( "The version %q is available online, consider updating this module!", remote_version )
					end
				end,
				function( reason )
					guthscp.error( "guthscp.module", "failed to check version of %q (%s)!", id, reason )
				end
			)
		end
	end )
end )

if CLIENT then
	hook.Add( "FinishMove", "guthscp.modules:warn_for_issues", function( ply, mv )
		--  ensure we are ourselves (this is probably always the case, but just-in-case)
		if ply ~= LocalPlayer() then return end
		--  ensure player has moved and is not AFK
		if mv:GetVelocity():IsZero() then return end

		if ply:IsSuperAdmin() then
			--  warn superadmins about modules issues as soon as they enter the game
			local has_issues = false
			for id, module in pairs( guthscp.modules ) do
				local issues = module._.issues

				--  filter issues to only alert for errors
				local filtered_issues = {}
				for i, issue in pairs( issues ) do
					--  this is the only way currently to check if an issue is an error, that's not pretty, yet it works
					if issue.icon:find( "cancel" ) then
						filtered_issues[#filtered_issues + 1] = issue
					end
				end

				if #filtered_issues > 0 then
					chat.AddText( color_white, "[", Color( 255, 121, 54 ), "GuthSCP", color_white, "] ",
						( "%d error%s have been found on module %q:" ):format( #filtered_issues, #filtered_issues > 1 and "s" or "", module.id )
					)
		
					for i, issue in pairs( filtered_issues ) do
						chat.AddText( color_white, "- ", issue.color, issue.text )
					end

					has_issues = true
				end
			end

			if has_issues then
				--  some sfx going on to captivate the audience :D
				surface.PlaySound( "buttons/blip1.wav" )
				timer.Simple( 0.3, function() 
					surface.PlaySound( "buttons/blip1.wav" )
				end )

				chat.AddText( color_white, "[", Color( 255, 121, 54 ), "GuthSCP", color_white, "] ", 
					"Errors have been found, please follow the instructions to fix them!"
				)
			else
				chat.AddText( color_white, "[", Color( 255, 121, 54 ), "GuthSCP", color_white, "] ", 
					"No issues have been raised from modules, enjoy your time! :)"
				)
			end
		end

		--  remove hook
		hook.Remove( "FinishMove", "guthscp.modules:warn_for_issues" )
	end )
end
guthscp.workaround = guthscp.workaround or {}
guthscp.workaround.is_initialized = guthscp.workaround.is_initialized or false
guthscp.workaround.path = "workarounds.json"
guthscp.workarounds = guthscp.workarounds or {}

function guthscp.workaround.register( id, workaround )
	guthscp.info( "guthscp.workaround", "%q", id )
	guthscp.print_tabs = guthscp.print_tabs + 1

	--  set id
	workaround.id = id

	--  check required properties
	if not isstring( workaround.name ) or #workaround.name == 0 then
		guthscp.error( "guthscp.workaround", "%q must have the 'name' property of type 'string'", id )
		guthscp.print_tabs = guthscp.print_tabs - 1
		return false
	end
	if not isnumber( workaround.realm ) or workaround.realm < guthscp.REALMS.SERVER or workaround.realm > guthscp.REALMS.SHARED then
		guthscp.error( "guthscp.workaround", "%q must have the 'realm' property of type @'guthscp.REALMS'", id )
		guthscp.print_tabs = guthscp.print_tabs - 1
		return false
	end

	--  inherit meta
	guthscp.helpers.use_meta( workaround, guthscp.workaround.meta )

	--  init on server loaded
	if guthscp.workaround.is_initialized and guthscp.is_same_realm( workaround.realm, guthscp.get_current_realm() ) then
		workaround:info( "initializing.." )
		workaround._is_active = workaround:init()
	end

	--  register
	guthscp.workarounds[id] = workaround

	guthscp.print_tabs = guthscp.print_tabs - 1
	return true
end

function guthscp.workaround.save()
	local data = {}

	--  serialize workarounds states
	for id, workaround in pairs( guthscp.workarounds ) do
		data[id] = workaround:is_enabled()
	end

	--  save to disk
	guthscp.data.save_to_json( guthscp.workaround.path, data, true )
	guthscp.info( "guthscp.workaround", "saved workarounds states to disk" )
end

function guthscp.workaround.safe_save()
	timer.Create( "guthscp.workaround:save", 1, 1, guthscp.workaround.save )
end

function guthscp.workaround.load()
	local data = guthscp.data.load_from_json( guthscp.workaround.path )
	if not data then return end

	if guthscp.workaround.is_initialized then
		guthscp.info( "guthscp.workaround", "de-serializing %d states", table.Count( data ) )
		guthscp.print_tabs = guthscp.print_tabs + 1

		local should_sync = player.GetCount() > 0
		for id, workaround in pairs( guthscp.workarounds ) do
			if data[id] ~= nil then
				--  set state
				workaround:set_enabled( data[id] )

				--  sync
				if should_sync then
					workaround:sync()
				end
			end
		end

		guthscp.print_tabs = guthscp.print_tabs - 1
	else
		guthscp.info( "guthscp.workaround", "couldn't set loaded states, workarounds not initialized yet!" )
	end
end

hook.Add( "InitPostEntity", "guthscp.workaround:init", function()
	local current_realm = guthscp.get_current_realm()

	guthscp.info( "guthscp.workaround", "loading %d workarounds", table.Count( guthscp.workarounds ) )
	guthscp.print_tabs = guthscp.print_tabs + 1

	--  init all workarounds
	for id, workaround in pairs( guthscp.workarounds ) do
		if guthscp.is_same_realm( workaround.realm, current_realm ) then
			workaround:info( "initializing.." )
			workaround._is_active = workaround:init()
		elseif SERVER then
			--  activate client workarounds on server 
			workaround:info( "forced active" )
			workaround._is_active = true
		else
			workaround:info( "wrong realm, skipping initialization" )
		end
	end

	--  mark workarounds as initialized
	guthscp.workaround.is_initialized = true

	--  retrieve workarounds states 
	if CLIENT then
		net.Start( "guthscp.workaround:sync" )
		net.SendToServer()

		guthscp.info( "guthscp.workaround", "retrieving states from server.." )
	else
		guthscp.workaround.load()
	end

	guthscp.info( "guthscp.workaround", "finished" )
	guthscp.print_tabs = guthscp.print_tabs - 1
end )

--  net receivers
local function net_apply_workaround( ply )
	local id = net.ReadString()
	local workaround = guthscp.workarounds[id]
	if not workaround then
		guthscp.warning( "guthscp.workaround", "tried to apply unknown workaround %q through network%s", id, IsValid( ply ) and " by " .. ply:GetName() or "" )
		return
	end

	local is_active = net.ReadBool()
	local is_enabled = net.ReadBool()

	--  apply variables
	workaround._is_active = is_active
	if workaround._is_active then
		workaround:set_enabled( is_enabled )
	end

	guthscp.debug( "guthscp.workarounds", "received %q workaround (active=%s, enabled=%s)", id, is_active and "true" or "false", is_enabled and "true" or "false" )
	return workaround
end

if SERVER then
	util.AddNetworkString( "guthscp.workaround:sync" )
	util.AddNetworkString( "guthscp.workaround:apply" )

	net.Receive( "guthscp.workaround:sync", function( len, ply )
		guthscp.info( "guthscp.workaround", "networked workarounds to %q", ply:GetName() )
		guthscp.print_tabs = guthscp.print_tabs + 1

		for id, workaround in pairs( guthscp.workarounds ) do
			workaround:sync( ply )
		end

		guthscp.print_tabs = guthscp.print_tabs - 1
	end )

	net.Receive( "guthscp.workaround:apply", function( len, ply )
		if not ply:IsSuperAdmin() then return end

		local workaround = net_apply_workaround( ply )
		if workaround then
			workaround:sync()
			guthscp.workaround.safe_save()
		end
	end )
else
	net.Receive( "guthscp.workaround:sync", function( len )
		net_apply_workaround()
	end )
end


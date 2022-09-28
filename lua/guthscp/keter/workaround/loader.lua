guthscp.workaround = guthscp.workaround or {}
guthscp.workaround.is_initialized = guthscp.workaround.is_initialized or false
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

hook.Add( "InitPostEntity", "guthscp.workaround:init", function()
	local current_realm = guthscp.get_current_realm()
	
	guthscp.info( "guthscp.workaround", "loading %d workarounds", table.Count( guthscp.workarounds ) )
	guthscp.print_tabs = guthscp.print_tabs + 1

	--  init all workarounds
	for id, workaround in pairs( guthscp.workarounds ) do
		if guthscp.is_same_realm( workaround.realm, current_realm ) then
			workaround:info( "initializing.." )
			workaround._is_active = workaround:init()
		else
			workaround:info( "wrong realm, skipping initialization" )
		end
	end

	--  mark workaround as loaded
	guthscp.workaround.is_initialized = true

	guthscp.info( "guthscp.workaround", "finished" )
	guthscp.print_tabs = guthscp.print_tabs - 1

	--  retrieve workarounds states 
	if CLIENT then
		net.Start( "guthscp.workaround:sync" )
		net.SendToServer()
	end
end )

--  net receivers
local function net_apply_workaround()
	local id = net.ReadString()
	local workaround = guthscp.workarounds[id]
	if not workaround then return end

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
		for id, workaround in pairs( guthscp.workarounds ) do
			workaround:sync( ply )
		end

		guthscp.debug( "guthscp.workarounds", "networked workarounds to %q", ply:GetName() )
	end )

	net.Receive( "guthscp.workaround:apply", function( len, ply )
		if not ply:IsSuperAdmin() then return end

		local workaround = net_apply_workaround()
		if workaround then
			workaround:sync()
		end
	end )
else
	net.Receive( "guthscp.workaround:sync", net_apply_workaround )
end


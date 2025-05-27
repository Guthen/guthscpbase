guthscp.config = guthscp.config or {}
guthscp.config_metas = guthscp.config_metas or {}

function guthscp.config.add( id, tbl, no_load )
	--  ensure form table is sequential 
	tbl.form = guthscp.table.rehash( tbl.form )

	--  add config meta
	guthscp.config_metas[id] = {
		form = tbl.form,
		receive = tbl.receive,
		parse = tbl.parse,
	}

	--  setup if no load
	if no_load then
		guthscp.config.setup( id )
	end

	--  load config
	if no_load or not guthscp.config.load( id ) then
		guthscp.config.apply( id, guthscp.configs[id] )
	end
end

function guthscp.config.sync( id, config, receiver )
	net.Start( "guthscp.config:send" )
		net.WriteString( id )
		net.WriteTable( config )
	if IsValid( receiver ) then
		net.Send( receiver )
	else
		net.Broadcast()
	end

	guthscp.info( "guthscp.config", "networked %q config to %s", id, IsValid( receiver ) and "'" .. receiver:GetName() .. "'" or "everyone" )
end

--  edit config 
util.AddNetworkString( "guthscp.config:send" )
util.AddNetworkString( "guthscp.config:receive" )
util.AddNetworkString( "guthscp.config:reset" )

net.Receive( "guthscp.config:send", function( len, ply )
	if not ply:IsSuperAdmin() then
		guthscp.warning( "guthscp.config", "%s (%s) tried to apply a config but he doesn't have the permission!", ply:GetName(), ply:SteamID() )
		return
	end

	--  check config id
	local config_id = net.ReadString()
	if not guthscp.config_metas[config_id] then
		return guthscp.error( "guthscp.config", "%q (%s) sent config of %q which isn't registered!", ply:GetName(), ply:SteamID(), config_id )
	end

	--  check data
	local config = net.ReadTable()
	if table.Count( config ) <= 0 then
		return guthscp.error( "guthscp.config", "%q (%s) sent config of %q which has no data!", ply:GetName(), ply:SteamID(), config_id )
	end

	--  config callback
	guthscp.config_metas[config_id].receive( config )
	guthscp.info( "guthscp.config", "%q (%s) applied %q config!", ply:GetName(), ply:SteamID(), config_id )
end )

--  network config
net.Receive( "guthscp.config:receive", function( len, ply )
	for k, v in pairs( guthscp.configs ) do
		guthscp.config.sync( k, v, ply )
	end
end )

--  reset config
net.Receive( "guthscp.config:reset", function( len, ply )
	if not ply:IsSuperAdmin() then
		guthscp.warning( "guthscp.config", "%s (%s) tried to reset a config but he doesn't have the permission!", ply:GetName(), ply:SteamID() )
		return
	end

	--  get config id
	local config_id = net.ReadString()
	if not guthscp.configs[config_id] then
		guthscp.warning( "guthscp.config", "%s (%s) tried to reset %q config which doesn't exist!", ply:GetName(), ply:SteamID(), config_id )
		return
	end

	--  delete config file
	guthscp.data.delete( guthscp.config.path .. config_id .. ".json" )

	--  reset runtime config and network it
	guthscp.config.apply( config_id, {}, {
		network = true,
	} )

	guthscp.info( "guthscp.config", "%q config has been reset by %s (%s)", config_id, ply:GetName(), ply:SteamID() )
end )
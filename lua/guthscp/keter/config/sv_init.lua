guthscp.config = guthscp.config or {}

local config = {}

function guthscp.config.add( id, tbl, no_load )
	--  ensure elements table is sequential 
	tbl.elements = guthscp.table.rehash( tbl.elements )
	for i, form in ipairs( tbl.elements ) do
		form.elements = guthscp.table.rehash( form.elements )
	end

	--  add config meta
	config[id] = {
		elements = tbl.elements,
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

function guthscp.config.get_all()
	return config
end

function guthscp.config.sync( id, tbl, target )
	net.Start( "guthscp.config:send" )
		net.WriteString( id )
		net.WriteTable( tbl )
	if IsValid( target ) then
		net.Send( target )
	else
		net.Broadcast()
	end

	guthscp.info( "guthscp.config", "networked %q config to %s", id, IsValid( target ) and "'" .. target:GetName() .. "'" or "everyone" )
end

--  edit config 
util.AddNetworkString( "guthscp.config:send" )
util.AddNetworkString( "guthscp.config:receive" )

net.Receive( "guthscp.config:send", function( len, ply )
	if not ply:IsSuperAdmin() then return end

	--  check config id
	local config_id = net.ReadString()
	if not config[config_id] then 
		return guthscp.error( "guthscp.config", "%q (%s) sent config of %q which isn't registered!", ply:GetName(), ply:SteamID(), config_id )
	end

	--  check data
	local form = net.ReadTable()
	if table.Count( form ) <= 0 then 
		return guthscp.error( "guthscp.config", "%q (%s) sent config of %q which has no data!", ply:GetName(), ply:SteamID(), config_id )
	end

	--  config callback
	config[config_id].receive( form )
	guthscp.info( "guthscp.config", "%q (%s) applied %q config!", ply:GetName(), ply:SteamID(), config_id )
end )

--  network config
net.Receive( "guthscp.config:receive", function( len, ply )
	for k, v in pairs( guthscp.configs ) do
		guthscp.config.sync( k, v, ply )
	end
end )
guthscp.players_filter = guthscp.players_filter or {}
guthscp.players_filter.all = guthscp.players_filter.all or {}

local FILTER = guthscp.players_filter
FILTER.__index = FILTER

--  new
function FILTER:new( id )
	local obj = {
		id = id,
		global_id = "guthscp.players_filter/" .. id,
		players_count = 0,
		players = {},
		
		event_player_added = guthscp.event_handler:new(),
		event_player_removed = guthscp.event_handler:new(),
	}
	
	guthscp.players_filter.all[id] = obj
	return setmetatable( obj, FILTER )
end


--  setters
function FILTER:add_player( ply )
	if not IsValid( ply ) then return end
	if self.players[ply] then return end
	
	--  update
	self.players[ply] = true
	self.players_count = self.players_count + 1
	self.event_player_added:invoke( ply )

	guthscp.debug( self.global_id, "added %q (%s)", ply:GetName(), ply:SteamID() )

	--  schedule sync
	if SERVER then
		self:safe_sync()
	end
end

function FILTER:remove_player( ply )
	if not self.players[ply] then return end
	
	--  update
	self.players[ply] = nil
	self.players_count = self.players_count - 1
	self.event_player_removed:invoke( ply )

	guthscp.debug( self.global_id, "removed %q (%s)", ply:GetName(), ply:SteamID() )

	--  schedule sync
	if SERVER then
		self:safe_sync()
	end
end

function FILTER:clear()
	self.players = {}
	self.players_count = 0
end


--  hook listeners
function FILTER:listen_weapon_users( weapon_class )
	hook.Add( "WeaponEquip", self.global_id, function( weapon, ply )
		if not ( weapon:GetClass() == weapon_class ) then return end
		
		self:add_player( ply )
	end )
	hook.Add( "PlayerDroppedWeapon", self.global_id, function( ply, weapon )
		if not ( weapon:GetClass() == weapon_class ) then return end
		
		self:remove_player( ply )
	end )
	
	local function remove_if_has_weapon( ply )
		if not ply:HasWeapon( weapon_class ) then return end

		self:remove_player( ply )
	end
	hook.Add( "DoPlayerDeath", self.global_id, remove_if_has_weapon )
	hook.Add( "PlayerSilentDeath", self.global_id, remove_if_has_weapon )
	hook.Add( "OnPlayerChangedTeam", self.global_id, remove_if_has_weapon )
end

function FILTER:listen_disconnect()
	hook.Add( "PlayerDisconnected", self.global_id, function( ply )
		self:remove_player( ply )
	end )
end


--  getters
function FILTER:get_players_list()
	local players = {}
	
	for ply in pairs( self.players ) do
		if IsValid( ply ) then
			players[#players + 1] = ply
		end
	end
	
	return players
end

function FILTER:get_players_count()
	return self.players_count
end

function FILTER:is_player_in( ply )
	if self.players[ply] then
		return true
	end
	
	return false
end


--  sync to client
if SERVER then
	util.AddNetworkString( "guthscp.players_filter:sync" )
	
	function FILTER:safe_sync( receiver )
		timer.Create( self.global_id .. ":sync", .5, 1, function()
			self:sync( receiver )
		end )
	end

	function FILTER:sync( receiver )
		net.Start( "guthscp.players_filter:sync" )
	
		--  filter id
		net.WriteString( self.id )
		
		--  players
		net.WriteUInt( self.players_count, guthscp.NETWORK_PLAYERS_BITS )
		for ply in pairs( self.players ) do
			net.WriteEntity( ply )
		end

		--  send
		if receiver == nil then
			net.Broadcast()
			guthscp.debug( "players_filter/" .. self.id, "send %d players to everyone", self.players_count )
		else
			net.Send( receiver )
			guthscp.debug( "players_filter/" .. self.id, "send %d players to %q", self.players_count, receiver:GetName() )
		end
	end

	net.Receive( "guthscp.players_filter:sync", function( len, ply )
		local count = 0

		for id, filter in pairs( guthscp.players_filter.all ) do
			filter:sync( ply )
			count = count + 1
		end

		guthscp.debug( "guthscp.players_filter", "send %d filters to %q", count, ply:GetName() )
	end )
else
	net.Receive( "guthscp.players_filter:sync", function( len )
		--  get filter
		local id = net.ReadString()
		local filter = guthscp.players_filter.all[id]
		if not filter then 
			guthscp.warning( "guthscp.players_filter", "failed to sync %q: filter not found!", id )
			return 
		end

		--  retrieve count
		local count = net.ReadUInt( guthscp.NETWORK_PLAYERS_BITS )
		
		--  retrieve players
		filter:clear()
		for i = 1, count do
			filter:add_player( net.ReadEntity() )
		end

		guthscp.debug( filter.global_id, "received %d players", count )
	end )

	--  sync on connection
	hook.Add( "InitPostEntity", "guthscp.players_filter:sync", function()
		net.Start( "guthscp.players_filter:sync" )
		net.SendToServer()
	end )
end
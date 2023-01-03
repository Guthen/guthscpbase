guthscp.filter = guthscp.filter or {}
guthscp.filter.all = guthscp.filter.all or {}

local FILTER = guthscp.filter
FILTER.__index = FILTER
FILTER._key = "filter"
FILTER._ubits = 16

--  new
function FILTER:new( id )
	local obj = {
		id = id,
		global_id = "guthscp." .. self._key .. "/" .. id,

		count = 0,
		container = {},
		
		event_added = guthscp.event_handler:new(),
		event_removed = guthscp.event_handler:new(),
	}

	--  register
	guthscp.filter.all[id] = obj

	guthscp.debug( "guthscp.filter", "new filter %q", obj.global_id )
	return setmetatable( obj, { __index = self } )
end

--  setters
function FILTER:add( ent )
	if self.container[ent] then return false end
	if not ( IsValid( ent ) and self:filter( ent ) ) then return false end
	
	--  update
	self.container[ent] = true
	self.count = self.count + 1
	self.event_added:invoke( ent )

	guthscp.debug( self.global_id, "added %q (%s)", ent:GetName(), ent:IsPlayer() and ent:SteamID() or ent:EntIndex() )

	--  schedule sync
	if SERVER then
		self:safe_sync()
	end

	return true
end

function FILTER:remove( ent )
	if not self.container[ent] then return false end
	
	--  update
	self.container[ent] = nil
	self.count = self.count - 1
	self.event_removed:invoke( ent )

	guthscp.debug( self.global_id, "removed %q (%s)", ent:GetName(), ent:IsPlayer() and ent:SteamID() or ent:EntIndex() )

	--  schedule sync
	if SERVER then
		self:safe_sync()
	end

	return true
end

function FILTER:clear( is_not_silent )
	if not is_not_silent then
		--  call remove events
		for ent in pairs( self.container ) do
			self.event_removed:invoke( ent )
		end
	end

	--  clear
	self.container = {}
	self.count = 0
end

function FILTER:filter( ent )
	return true
end

--  getters
function FILTER:get_list()
	local list = {}
	
	for ent in pairs( self.container ) do
		if IsValid( ent ) then
			list[#list + 1] = ent
		end
	end
	
	return list
end

function FILTER:get_count()
	return self.count
end

function FILTER:is_in( ent )
	return self.container[ent] or false
end


--  sync to client
if SERVER then
	util.AddNetworkString( "guthscp.filter:sync" )
	
	function FILTER:safe_sync( receiver )
		timer.Create( self.global_id .. ":sync", .5, 1, function()
			self:sync( receiver )
		end )
	end

	function FILTER:sync( receiver )
		net.Start( "guthscp.filter:sync" )
	
		--  filter id
		net.WriteString( self.id )
		
		--  players
		net.WriteUInt( self.count, self._ubits )
		for ply in pairs( self.container ) do
			net.WriteEntity( ply )
		end

		--  send
		if receiver == nil then
			net.Broadcast()
			guthscp.debug( self._key .. "/" .. self.id, "send %d entities to everyone", self.count )
		else
			net.Send( receiver )
			guthscp.debug( self._key .. "/" .. self.id, "send %d entities to %q", self.count, receiver:GetName() )
		end
	end

	net.Receive( "guthscp.filter:sync", function( len, ply )
		local count = 0

		for id, filter in pairs( guthscp.filter.all ) do
			filter:sync( ply )
			count = count + 1
		end

		guthscp.debug( "guthscp.filter", "send %d filters to %q", count, ply:GetName() )
	end )
else
	net.Receive( "guthscp.filter:sync", function( len )
		--  get filter
		local id = net.ReadString()
		local filter = guthscp.filter.all[id]
		if not filter then 
			guthscp.warning( "guthscp.filter", "failed to sync %q: filter not found!", id )
			return 
		end

		--  retrieve count
		local count = net.ReadUInt( filter._ubits )
		
		--  retrieve players
		filter:clear()
		for i = 1, count do
			filter:add( net.ReadEntity() )
		end

		guthscp.debug( filter.global_id, "received %d players", count )
	end )

	--  sync on connection
	hook.Add( "InitPostEntity", "guthscp.filter:sync", function()
		net.Start( "guthscp.filter:sync" )
		net.SendToServer()
	end )
end
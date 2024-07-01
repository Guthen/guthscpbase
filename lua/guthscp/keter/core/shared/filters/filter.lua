guthscp.filter = guthscp.filter or {}
guthscp.filters = guthscp.filters or {}
guthscp.filter.tool_mode = guthscp.filter.tool_mode or nil  --  auto-filled in the tool script
guthscp.filter.path = "filters/"

local FILTER = guthscp.filter
FILTER.__index = FILTER
FILTER._key = "filter"
FILTER._ubits = 16
FILTER._use_map_name = false

--  new
function FILTER:new( id, name )
	local obj = {
		id = id,
		name = name or id,
		global_id = "guthscp." .. self._key .. "/" .. id,

		count = 0,
		container = {},

		event_added = guthscp.event_handler:new(),
		event_removed = guthscp.event_handler:new(),
	}

	--  hot reload
	local old_filter = guthscp.filters[id]
	if old_filter then
		obj.count = old_filter.count
		obj.container = old_filter.container
	end

	--  register
	guthscp.filters[id] = obj

	guthscp.debug( "guthscp.filter", "new filter %q", obj.global_id )
	return setmetatable( obj, { __index = self } )
end

--  setters
function FILTER:add( ent )
	if not ( IsValid( ent ) and self:filter( ent ) ) then return false end
	return self:add_id( ent:EntIndex() )
end

function FILTER:add_id( id )
	if self.container[id] then return false end

	--  update
	self.container[id] = true
	self.count = self.count + 1

	--  call event
	local ent = Entity( id )
	if IsValid( ent ) then
		self.event_added:invoke( ent )

		guthscp.debug( self.global_id, "added %q (%s)", ent:IsPlayer() and ent:GetName() or ent:GetClass(), ent:IsPlayer() and ent:SteamID() or ent:EntIndex() )
	else
		guthscp.debug( self.global_id, "added ID:%s", id )
	end

	--  schedule sync
	if SERVER then
		self:safe_sync()
	end

	return true
end

function FILTER:remove( ent )
	if not IsValid( ent ) then return false end
	return self:remove_id( ent:EntIndex() )
end

function FILTER:remove_id( id )
	if not self.container[id] then return false end

	--  update
	self.container[id] = nil
	self.count = self.count - 1

	--  call event
	local ent = Entity( id )
	if IsValid( ent ) then
		self.event_removed:invoke( ent )

		guthscp.debug( self.global_id, "removed %q (%s)", ent:IsPlayer() and ent:GetName() or ent:GetClass(), ent:IsPlayer() and ent:SteamID() or ent:EntIndex() )
	else
		guthscp.debug( self.global_id, "removed ID:%s", id )
	end

	--  schedule sync
	if SERVER then
		self:safe_sync()
	end

	return true
end

function FILTER:clear()
	--  call remove events
	for ent in pairs( self.container ) do
		self.event_removed:invoke( ent )
	end

	--  clear
	self.container = {}
	self.count = 0

	--  schedule sync
	if SERVER then
		self:safe_sync()
	end
end

function FILTER:filter( ent )
	return true
end

--  getters
function FILTER:get_entities()
	local entities = {}

	for id in pairs( self.container ) do
		local ent = Entity( id )
		if IsValid( ent ) then
			entities[#entities + 1] = ent
		end
	end

	return entities
end

function FILTER:get_count()
	return self.count
end

function FILTER:is_in( ent )
	return IsValid( ent ) and self.container[ent:EntIndex()] or false
end

--  saving
function FILTER:serialize()
	return nil
end

function FILTER:un_serialize( data )
end

function FILTER:get_save_file_path()
	if self._use_map_name then
		return guthscp.filter.path .. game.GetMap() .. "/" .. self.id .. ".json"
	end

	return guthscp.filter.path .. self.id .. ".json"
end

function FILTER:save()
	--  serialize data
	local data = self:serialize()
	if not data then
		guthscp.error( "guthscp.filter", "failed to serialize %q, either failed or not implemented", self.global_id )
		return false
	end

	--  saving to file
	guthscp.data.save_to_json( self:get_save_file_path(), data, true )

	guthscp.debug( "guthscp.filter", "saved filter %q", self.global_id )
	return true
end

function FILTER:load()
	--  read data
	local data = guthscp.data.load_from_json( self:get_save_file_path() )
	if not data then return false end

	--  load data
	self:clear()
	self:un_serialize( data )

	guthscp.debug( "guthscp.filter", "loaded filter %q", self.global_id )
	return true
end

--  sync to client
if SERVER then
	util.AddNetworkString( "guthscp.filter:sync" )
	util.AddNetworkString( "guthscp.filter:io" )

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
		for id in pairs( self.container ) do
			net.WriteUInt( id, 16 )
		end

		--  send
		if receiver == nil then
			net.Broadcast()
			guthscp.debug( self.global_id, "send %d entities to everyone", self.count )
		else
			net.Send( receiver )
			guthscp.debug( self.global_id, "send %d entities to %q", self.count, receiver:GetName() )
		end
	end

	net.Receive( "guthscp.filter:sync", function( len, ply )
		local count = 0

		for id, filter in pairs( guthscp.filters ) do
			if filter:get_count() == 0 then continue end

			filter:sync( ply )
			count = count + 1
		end

		guthscp.debug( "guthscp.filter", "send %d filters to %q", count, ply:GetName() )
	end )

	net.Receive( "guthscp.filter:io", function( len, ply )
		if not hook.Run( "CanTool", ply, ply:GetEyeTrace(), guthscp.filter.tool_mode, ply:GetTool( guthscp.filter.tool_mode ), 1 ) then
			guthscp.warning( "guthscp.filter", "failed to save/load by %q (%s): not authorized", ply:GetName(), ply:SteamID() )
			return
		end

		--  get filter
		local filter_id = net.ReadString()
		local filter = guthscp.filters[filter_id]
		if not filter then return end

		--  save or load
		local is_save = net.ReadBool()
		if is_save then
			if filter:save() then
				ply:ChatPrint( ( "Filter %q has been succesfully saved!" ):format( filter.name ) )
			else
				ply:ChatPrint( ( "Filter %q has failed to save, probably failed to serialize or not implemented." ):format( filter.name ) )
			end
		else
			if filter:load() then
				ply:ChatPrint( ( "Filter %q has been succesfully loaded!" ):format( filter.name ) )
			else
				ply:ChatPrint( ( "Filter %q has failed to load, no save file found." ):format( filter.name ) )
			end
		end
	end )
else
	net.Receive( "guthscp.filter:sync", function( len )
		--  get filter
		local id = net.ReadString()
		local filter = guthscp.filters[id]
		if not filter then
			guthscp.warning( "guthscp.filter", "failed to sync %q: filter not found!", id )
			return
		end

		--  retrieve count
		local count = net.ReadUInt( filter._ubits )

		--  retrieve entities
		local indexes = {}
		for i = 1, count do
			local ent_id = net.ReadUInt( 16 )
			indexes[ent_id] = true
		end

		--  add indexes
		for ent_id in pairs( indexes ) do
			filter:add_id( ent_id )
		end

		--  remove not contained indexes
		for ent_id in pairs( filter.container ) do
			if indexes[ent_id] then continue end

			filter:remove_id( ent_id )
		end

		guthscp.debug( filter.global_id, "received %d entities", count )
	end )

	--  sync on connection
	hook.Add( "InitPostEntity", "guthscp.filter:sync", function()
		net.Start( "guthscp.filter:sync" )
		net.SendToServer()
	end )
end
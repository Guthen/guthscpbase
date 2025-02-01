guthscp.zone = guthscp.zone or {}
guthscp.zones = guthscp.zones or {}
guthscp.zone.tool_mode = guthscp.zone.tool_mode or nil  --  auto-filled in the tool script
guthscp.zone.path = "zones/"

local ZONE = guthscp.zone
ZONE.__index = ZONE
ZONE._ubits = 8  --  8 bits: up to 63 regions

--  new
function ZONE:new( id, name )
	local obj = {
		id = id,
		name = name or id,
		global_id = "guthscp.zone/" .. id,

		regions = {},
	}

	--  hot reload
	local old_zone = guthscp.zones[id]
	if old_zone then
		obj.regions = old_zone.regions
	end

	--  register
	guthscp.zones[id] = obj

	guthscp.debug( "guthscp.zone", "new zone %q", obj.global_id )
	return setmetatable( obj, { __index = self } )
end

function ZONE:clear()
	--  clear
	self.regions = {}

	--  schedule sync
	if SERVER then
		self:safe_sync()
	end
end

function ZONE:is_in_region( region_id, pos )
	if IsValid( pos ) then
		pos = pos:GetPos() + pos:OBBCenter()
	end

	local region = self.regions[region_id]
	assert( region, "Region '" .. region_id .. "' is not valid!" )

	return pos:WithinAABox( region.start_pos, region.end_pos )
end

function ZONE:is_in( pos )
	if IsValid( pos ) then
		pos = pos:GetPos() + pos:OBBCenter()
	end

	--  check is in a region
	for id, region in ipairs( self.regions ) do
		if self:is_in_region( id, pos ) then
			return true
		end
	end

	return false
end

--  saving
function ZONE:serialize()
	return self.regions
end

function ZONE:un_serialize( data )
	self.regions = data
end

function ZONE:get_save_file_path()
	return guthscp.zone.path .. game.GetMap() .. "/" .. self.id .. ".json"
end

function ZONE:save()
	--  serialize data
	local data = self:serialize()
	if not data then
		guthscp.error( "guthscp.zone", "failed to serialize %q, either failed or not implemented", self.global_id )
		return false
	end

	--  saving to file
	guthscp.data.save_to_json( self:get_save_file_path(), data, true )

	guthscp.debug( "guthscp.zone", "saved zone %q", self.global_id )
	return true
end

function ZONE:load()
	--  read data
	local data = guthscp.data.load_from_json( self:get_save_file_path() )
	if not data then return false end

	--  load data
	self:clear()
	self:un_serialize( data )

	guthscp.debug( "guthscp.zone", "loaded %d regions for zone %q", #self.regions, self.global_id )
	return true
end

--  static functions
function guthscp.zone.has_permission_to_edit( ply )
	return hook.Run( "CanTool", ply, ply:GetEyeTrace(), guthscp.zone.tool_mode, ply:GetTool( guthscp.zone.tool_mode ), 1 )
end

function guthscp.zone.read_region()
	return {
		name = net.ReadString(),
		start_pos = net.ReadVector(),
		end_pos = net.ReadVector(),
	}
end


--  sync to client
if SERVER then
	util.AddNetworkString( "guthscp.zone:sync" )
	util.AddNetworkString( "guthscp.zone:io" )
	util.AddNetworkString( "guthscp.zone:region" )

	function ZONE:set_region( id, region )
		self.regions[id] = region
		self:safe_sync()
	end

	function ZONE:delete_region( id )
		table.remove( self.regions, id )
		self:safe_sync()
	end

	function ZONE:safe_sync( receiver )
		timer.Create( self.global_id .. ":sync", 0.5, 1, function()
			self:sync( receiver )
		end )
	end

	function ZONE:sync( receiver )
		net.Start( "guthscp.zone:sync" )

		--  zone id
		net.WriteString( self.id )

		--  regions
		net.WriteUInt( #self.regions, self._ubits )
		for i, region in ipairs( self.regions ) do
			net.WriteString( region.name )
			net.WriteVector( region.start_pos )
			net.WriteVector( region.end_pos )
		end

		--  send
		if receiver == nil then
			net.Broadcast()
			guthscp.debug( self.global_id, "send %d regions to everyone", #self.regions )
		else
			net.Send( receiver )
			guthscp.debug( self.global_id, "send %d regions to %q", #self.regions, receiver:GetName() )
		end
	end

	net.Receive( "guthscp.zone:sync", function( len, ply )
		local count = 0

		for id, zone in pairs( guthscp.zones ) do
			zone:sync( ply )
			count = count + 1
		end

		guthscp.debug( "guthscp.zone", "send %d zones to %q", count, ply:GetName() )
	end )

	net.Receive( "guthscp.zone:io", function( len, ply )
		if not guthscp.zone.has_permission_to_edit( ply ) then
			guthscp.warning( "guthscp.zone", "failed to save/load by %q (%s): not authorized", ply:GetName(), ply:SteamID() )
			return
		end

		--  get zone
		local zone_id = net.ReadString()
		local zone = guthscp.zones[zone_id]
		if not zone then return end

		--  save or load
		local is_save = net.ReadBool()
		if is_save then
			if zone:save() then
				ply:ChatPrint( ( "Zone %q has been succesfully saved!" ):format( zone.name ) )
			else
				ply:ChatPrint( ( "Zone %q has failed to save, probably failed to serialize or not implemented." ):format( zone.name ) )
			end
		else
			if zone:load() then
				ply:ChatPrint( ( "Zone %q has been succesfully loaded!" ):format( zone.name ) )
			else
				ply:ChatPrint( ( "Zone %q has failed to load, no save file found." ):format( zone.name ) )
			end
		end
	end )

	net.Receive( "guthscp.zone:region", function( len, ply )
		if not guthscp.zone.has_permission_to_edit( ply ) then
			guthscp.warning( "guthscp.zone", "failed to update region by %q (%s): not authorized", ply:GetName(), ply:SteamID() )
			return
		end

		--  get zone
		local zone_id = net.ReadString()
		local zone = guthscp.zones[zone_id]
		if not zone then return end

		--  check id will be in bounds (allowing one upper max for inserting a new region)
		local id = net.ReadUInt( zone._ubits )
		if id < 1 or id > #zone.regions + 1 then
			guthscp.warning( "guthscp.zone", "failed to update region ID %d by %q (%s): out of bounds (1 <= ID <= %d)", id, ply:GetName(), ply:SteamID(), #zone.regions + 1 )
			return
		end

		--  apply region
		zone:set_region( id, guthscp.zone.read_region() )
	end )

	hook.Add( "InitPostEntity", "guthscp:load_zones", function()
		for id, zone in pairs( guthscp.zones ) do
			zone:load()
		end
	end )
else
	function ZONE:send_region( id, name, start_pos, end_pos )
		net.Start( "guthscp.zone:region" )
			net.WriteString( self.id )
			net.WriteUInt( id, self._ubits )
			net.WriteString( name )
			net.WriteVector( start_pos )
			net.WriteVector( end_pos )
		net.SendToServer()
	end

	net.Receive( "guthscp.zone:sync", function( len )
		--  get zone
		local id = net.ReadString()
		local zone = guthscp.zones[id]
		if not zone then
			guthscp.warning( "guthscp.zone", "failed to sync %q: zone not found!", id )
			return
		end

		--  clear
		zone.regions = {}

		--  retrieve count
		local count = net.ReadUInt( zone._ubits )
		for i = 1, count do
			zone.regions[i] = guthscp.zone.read_region()
		end

		guthscp.debug( zone.global_id, "received %d regions", count )
	end )

	--  sync on connection
	hook.Add( "InitPostEntity", "guthscp.zone:sync", function()
		net.Start( "guthscp.zone:sync" )
		net.SendToServer()
	end )
end
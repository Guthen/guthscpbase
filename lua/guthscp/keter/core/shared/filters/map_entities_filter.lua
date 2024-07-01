guthscp.map_entities_filter = guthscp.map_entities_filter or {}

local FILTER = guthscp.map_entities_filter
guthscp.helpers.use_meta( FILTER, guthscp.filter )
FILTER._key = "map_entities_filter"
FILTER._ubits = 16
FILTER._use_map_name = true

function FILTER:filter( ent )
	return ent:CreatedByMap()
end

function FILTER:serialize()
	local data = {}

	for id in pairs( self.container ) do
		local ent = Entity( id )
		if not IsValid( ent ) then
			guthscp.warning( "guthscp.filter", "failed to retrieve entity (ID: %d) for serializing", id )
			continue
		end

		data[#data + 1] = ent:MapCreationID()
	end

	return data
end

function FILTER:un_serialize( data )
	for i, map_id in ipairs( data ) do
		local ent = ents.GetMapCreatedEntity( map_id )
		self:add( ent )
	end
end

hook.Add( "InitPostEntity", "guthscp:load_map_entities_filters", function()
	for id, filter in pairs( guthscp.filters ) do
		if filter._key ~= FILTER._key then continue end

		filter:load()
	end
end )
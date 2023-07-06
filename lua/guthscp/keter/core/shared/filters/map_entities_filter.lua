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

	for ent in pairs( self.container ) do
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
		if not ( filter._key == FILTER._key ) then continue end 

		filter:load()
	end
end )
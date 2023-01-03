guthscp.map_entities_filter = guthscp.map_entities_filter or {}

local FILTER = guthscp.map_entities_filter
guthscp.helpers.use_meta( FILTER, guthscp.filter )
FILTER._key = "map_entities_filter"
FILTER._ubits = 16

function FILTER:filter( ent )
	return CLIENT or ent:MapCreationID() ~= -1
end
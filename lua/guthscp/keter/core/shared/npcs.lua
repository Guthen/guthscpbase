local npcs = {}
hook.Add( "OnEntityCreated", "guthscp:retrieve_npcs", function( ent )
	if not IsValid( ent ) or ( not ent:IsNPC() and not ent:IsNextBot() ) then return end

	npcs[#npcs + 1] = ent
end )

hook.Add( "EntityRemoved", "guthscp:remove_npcs", function( ent )
	if not IsValid( ent ) or ( not ent:IsNPC() and not ent:IsNextBot() ) then return end

	for i, v in ipairs( npcs ) do
		if v == ent then
			table.remove( npcs, i )
			break
		end
	end
end )

function guthscp.get_npcs()
	return npcs
end
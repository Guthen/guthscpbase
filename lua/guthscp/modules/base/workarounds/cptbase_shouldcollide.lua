local WORKAROUND = {
	name = "Fix 'CPTBase' conflicting the 'ShouldCollide' hook",
	realm = guthscp.REALMS.SERVER,
}

function WORKAROUND:init()
	return self:find_hook( 1, "ShouldCollide", function( id, callback )
		return id:find( "CPTBase" )
	end )
end

function WORKAROUND:on_enabled()
	self:override_hook( 1, function( ent1, ent2 )
		if ent1:GetClass() == "cpt_ai_pathfinding" and ent2 == ent1:GetOwner() then
			return false
		end
	end )
end

function WORKAROUND:on_disabled()
	self:restore_hook( 1 )
end

guthscp.workaround.register( "cptbase_shouldcollide", WORKAROUND )
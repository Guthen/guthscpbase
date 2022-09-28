local WORKAROUND = {
	name = "Fix 'CPTBase' conflicting the 'ShouldCollide' hook",
	realm = guthscp.REALMS.SERVER,
}

function WORKAROUND:init()
	--  find the hook (since its ID is randomly generated)
	for k, v in pairs( hook.GetTable()["ShouldCollide"] ) do
        if k:find( "CPTBase" ) then
			self._hook_id = k
            self._former_callback = v
           	return true
        end
    end

	self:warning( "hook 'ShouldCollide' of 'CPTBase' wasn't found!" )
	return false
end

function WORKAROUND:on_enabled()
	hook.Add( "ShouldCollide", self._hook_id, function( ent1, ent2 )
		if ent1:GetClass() == "cpt_ai_pathfinding" and ent2 == ent1:GetOwner() then
			return false
		end
	end )
end

function WORKAROUND:on_disabled()
	--  restore former callback
	hook.Add( "ShouldCollide", self._hook_id, self._former_callback )
end

guthscp.workaround.register( "cptbase_shouldcollide", WORKAROUND )
local WORKAROUND = {
	name = "Fix 'Playable Piano' conflicting the 'PlayerUse' hook",
	realm = guthscp.REALMS.SERVER,
}

function WORKAROUND:init()
	return self:register_hook( 1, "PlayerUse", "InstrumentChairModelHook" )
end

function WORKAROUND:on_enabled()
	--  the workshop version of the piano addon didn't implement the fix:
	--  https://github.com/macdguy/playablepiano/blob/master/lua/entities/gmt_instrument_base/init.lua#L108-L131
	self:override_hook( 1, function( ply, ent )
		local inst = ent:GetOwner()

		if IsValid( inst ) and inst.Base == "gmt_instrument_base" then
			if not IsValid( inst.Owner ) then
				inst:AddInstOwner( ply )
				return true
			else
				if inst.Owner == ply then
					return true
				end
			end
		end
	end )
end

function WORKAROUND:on_disabled()
	self:restore_hook( 1 )
end

guthscp.workaround.register( "playable_piano_playeruse", WORKAROUND )
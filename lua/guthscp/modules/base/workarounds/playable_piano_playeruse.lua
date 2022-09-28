local WORKAROUND = {
	name = "Fix 'Playable Piano' conflicting the 'PlayerUse' hook",
	realm = guthscp.REALMS.SERVER,
}

function WORKAROUND:init()
	return self:get_hook( "PlayerUse", "InstrumentChairModelHook" )
end

function WORKAROUND:on_enabled()
	--  https://github.com/macdguy/playablepiano/blob/master/lua/entities/gmt_instrument_base/init.lua#L108-L131
	hook.Add( "PlayerUse", "InstrumentChairModelHook", function( ply, ent )
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
	end)
end

function WORKAROUND:on_disabled()
	--  restore former callback
	hook.Add( "PlayerUse", "InstrumentChairModelHook", self._former_callback )
end

guthscp.workaround.register( "playable_piano_playeruse", WORKAROUND )
guthscp.world = guthscp.world or {}

--[[ 
    @function guthscp.world.is_ground
        | description: check if the given position is above the ground by using a raycast
        | params:
            pos: <Vector> position to check
        | return: <bool> is_ground
]]
function guthscp.world.is_ground( pos )
	local tr = util.TraceLine( {
        collisiongroup = COLLISION_GROUP_WORLD,
        start = pos,
        endpos = pos - Vector( 0, 0, 3 ),
    } )

    return tr.HitWorld
end
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

--[[ 
    @function guthscp.world.player_trace_attack
        | description: perform a hull trace on the given player for weapons attack purpose
        | params:
            ply: <Player> attacking player
            max_dist: <number> maximum trace distance
            bounds: <Vector> minimums & maximums of hull
        | return: <TraceResult> tr
]]
function guthscp.world.player_trace_attack( ply, max_dist, bounds )
    local start_pos = ply:EyePos()

    --  perform trace
    local tr = util.TraceHull( {
		start = start_pos,
		endpos = start_pos + ply:GetAimVector() * max_dist,
		filter = ply,
		mins = -bounds,
		maxs = bounds,
		mask = MASK_SHOT_HULL,
	} )

    --  debug render:
    --  convar 'developer' should be greater or equal 1
    --  you must also be in a singleplayer game (a dedicated server won't work)
    if SERVER and ply:IsListenServerHost() then
        local lifetime = 2.5
        local target = tr.Entity
        debugoverlay.SweptBox( start_pos, tr.HitPos, -bounds, bounds, angle_zero, lifetime, IsValid( target ) and Color( 255, 0, 0 ) or color_white )

        if IsValid( target ) then
            debugoverlay.BoxAngles( target:GetPos(), target:OBBMins(), target:OBBMaxs(), target:GetAngles(), lifetime, Color( 255, 0, 0, 64 ) )
        end
    end

	return tr 
end

function guthscp.world.is_living_entity( ent )
    return ent:IsPlayer() or ent:IsNPC() or ent:IsNextBot()
end
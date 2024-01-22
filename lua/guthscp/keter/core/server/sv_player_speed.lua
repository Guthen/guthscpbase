
guthscp.player_speed_modifiers = guthscp.player_speed_modifiers or {}

function guthscp.apply_player_speed_modifier( ply, id, scale, time )
	--  avoid useless modifiers
	if scale == 1.0 or time == 0.0 then return end

	local timer_id = "guthscp:revert-player-speed-" .. id .. "-" .. ply:SteamID64()

	guthscp.player_speed_modifiers[ply] = guthscp.player_speed_modifiers[ply] or {}

	--  avoid updating if existing modifier is the same
	local should_update = true
	local modifier = guthscp.player_speed_modifiers[ply][id]
	if modifier and modifier.scale == scale and modifier.time == time then
		should_update = false
	end

	--  add modifier
	guthscp.player_speed_modifiers[ply][id] = {
		scale = scale,
		time = time,
		timer_id = timer_id
	}

	--  setup reset timer
	timer.Create( timer_id, time, 1, function()
		--  remove modifier
		guthscp.player_speed_modifiers[ply][id] = nil

		--  update speeds
		guthscp.update_player_speed( ply )
	end )

	--  update speed
	if should_update then
		guthscp.update_player_speed( ply )
	end
end

function guthscp.update_player_speed( ply )
	local modifiers = guthscp.player_speed_modifiers[ply]
	
	--  store default speeds
	if not ply._guthscp_walk_speed then
		ply._guthscp_walk_speed = ply:GetWalkSpeed()
		ply._guthscp_slow_walk_speed = ply:GetSlowWalkSpeed()
		ply._guthscp_run_speed = ply:GetRunSpeed()
	end

	--  find speed scale
	local count = 0
	local speed_scale = 1.0
	for id, modifier in pairs( modifiers ) do
		speed_scale = speed_scale * modifier.scale
		count = count + 1
	end

	--  apply new speeds
	ply:SetWalkSpeed( ply._guthscp_walk_speed * speed_scale )
	ply:SetSlowWalkSpeed( ply._guthscp_slow_walk_speed * speed_scale )
	ply:SetRunSpeed( ply._guthscp_run_speed * speed_scale )

	--  reset default speeds
	--  this allows external code (e.g. gamemode) to edit the speeds and to rely on these new values 
	if count == 0 then
		ply._guthscp_walk_speed = nil
		ply._guthscp_slow_walk_speed = nil
		ply._guthscp_run_speed = nil
	end
end

function guthscp.has_player_speed_modifier( ply, id )
	local modifiers = guthscp.player_speed_modifiers[ply]
	if not modifiers then return false end

	return tobool( modifiers[id] )
end

function guthscp.clear_player_speed_modifiers( ply )
	local modifiers = guthscp.player_speed_modifiers[ply]
	if not modifiers then return end

	--  clear timers
	for id, modifier in pairs( modifiers ) do
		timer.Remove( modifier.timer_id )
	end

	--  clear modifiers
	guthscp.player_speed_modifiers[ply] = nil
end
hook.Add( "PlayerDisconnected", "guthscp:player-speed", guthscp.clear_player_speed_modifiers )
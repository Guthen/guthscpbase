guthscp.sound = guthscp.sound or {}

local sounds = {}

timer.Create( "guthscp:sound_channel", .1, 0, function()
	local ply = LocalPlayer()
	if not IsValid( ply ) then return end

	local ply_pos = ply:GetPos()
	for k, v in pairs( sounds ) do
		--  remove channel on invalid entity or stopped channel
		if not IsValid( v.entity ) or v.channel:GetState() == GMOD_CHANNEL_STOPPED then
			v.channel:Stop()
			sounds[k] = nil
			continue
		end

		--  fade out/in depending on distance
		local pos = v.entity:GetPos()
		if ply_pos:DistToSqr( pos ) > v.radius_sqr then
			v.channel:SetVolume( Lerp( FrameTime() * 5, v.channel:GetVolume(), 0 ) )
		else
			v.channel:SetVolume( Lerp( FrameTime() * 3, v.channel:GetVolume(), v.volume ) )
		end

		--  actualize
		v.channel:SetPos( pos )
	end
end )

net.Receive( "guthscp:play_sound_channel", function()
	local path = net.ReadString()

	local parent = net.ReadEntity() 
	if not IsValid( parent ) then 
		return guthscp.error( "guthscp", "failed to find entity while trying to play a channel sound" )
	end

	local radius = net.ReadUInt( 16 )
	local looping = net.ReadBool()
	local volume = net.ReadFloat()

	guthscp.sound.play( parent, path, radius, looping, volume )
end )

net.Receive( "guthscp:stop_sound_channel", function()
	local path = net.ReadString()

	local parent = net.ReadEntity() 
	if not IsValid( parent ) then 
		return guthscp.error( "guthscp.sound", "failed to find entity while trying to stop a channel sound" ) 
	end

	guthscp.sound.stop( parent, path )
end )

function guthscp.sound.play( ent, path, radius, looping, volume )
	if not IsValid( ent ) then return end
	
	if volume == 0.0 then return end
	if istable( path ) then
		if #path == 0 then return end
		
		--  choose a random sound path
		path = path[math.random( #path )]
	end

	guthscp.sound.stop( ent, path )

	radius = radius or 1024
	looping = looping or false
	volume = volume or 1

	sound.PlayFile( "sound/" .. path, "3d noblock noplay", function( channel, err_id, err_name )
		if not IsValid( channel ) then 
			return guthscp.error( "guthscp", "failed to play %q ('%s' (%d))!", path, err_name, err_id ) 
		end
		if not IsValid( ent ) then 
			return guthscp.error( "guthscp", "failed to play %q (entity invalid)!", path, err_name, err_id ) 
		end
	
		--  channel
		channel:SetPos( ent:GetPos() )
		channel:Set3DFadeDistance( radius * .15, radius )
		channel:EnableLooping( looping )
		channel:Play()
		channel:SetVolume( volume )

		--  don't hear the sound if too far from entity
		if ent:GetPos():Distance( LocalPlayer():GetPos() ) > radius then
			channel:SetVolume( 0 )
		end

		--  register
		sounds[path .. ":" .. ent:EntIndex()] = {
			entity = ent,
			channel = channel,
			volume = volume,
			path = path,
			radius = radius,
			radius_sqr = radius ^ 2,
		}
	end )
end

function guthscp.sound.stop( ent, path )
	local key = path .. ":" .. ent:EntIndex()

	if sounds[key] then 
		sounds[key].channel:Stop() 
	end

	sounds[key] = nil
end

--  warning: not the same structure that server one
function guthscp.sound.get_played_sounds()
	return sounds
end

function guthscp.sound.get_played_sound( ent, path )
	return sounds[path .. ":" .. ent:EntIndex()]
end

--  ask played sounds
hook.Add( "InitPostEntity", "guthscp:ask_sound_channel", function()
	net.Start( "guthscp:play_sound_channel" )
	net.SendToServer()
end )

--  stop channels
concommand.Add( "guthscp_stop_channel_sounds", function()
	local count = 0
	for k, v in pairs( sounds ) do
		v.channel:Stop()
		sounds[k] = nil
		count = count + 1
	end
	guthscp.info( "guthscp", "stopped %d channels", count )
end )

concommand.Add( "guthscp_print_channel_sounds", function()
	guthscp.info( "guthscp", "%d channel(s) is/are playing", table.Count( sounds ) )

	local i = 1
	for k, v in pairs( sounds ) do
		print( ( "\t[%d ─ %q]:" ):format( i, k ) )
		print( "\t\tentity: " .. tostring( v.entity ) )
		print( "\t\tvolume: " .. v.volume * 100 .. "%" )
		print( "\t\tlooped: " .. tostring( v.channel:IsLooping() ) )
		print( "\t\tradius: " .. v.radius )
		print( "\t\tpath: " .. v.path )
		i = i + 1
	end
end )
guthscp.sound = guthscp.sound or {}

--  basic client sound
if SERVER then
	util.AddNetworkString( "guthscp:play_sound" )
else
	net.Receive( "guthscp:play_sound", function()
		guthscp.sound.play_client( net.ReadString() )
	end )
end

function guthscp.sound.play_client( ply, sound_path )
	if istable( sound_path ) then
		if #sound_path == 0 then return end

		--  choose a random sound path
		sound_path = sound_path[math.random( #sound_path )]
	end

	if SERVER then
		if #sound_path == 0 then return end

		net.Start( "guthscp:play_sound" )
			net.WriteString( sound_path )
		net.Send( ply )
	else
		surface.PlaySound( sound_path or ply )
	end
end
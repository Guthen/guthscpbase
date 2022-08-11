util.AddNetworkString( "guthscp:play_sound_channel" )
util.AddNetworkString( "guthscp:stop_sound_channel" )

local function start_network_sound( ent, path, radius, looping, volume )
	net.Start( "guthscp:play_sound_channel" )
		net.WriteString( path )
		net.WriteEntity( ent )
		net.WriteUInt( radius or 1024, 16 )
		net.WriteBool( looping or false )
		net.WriteFloat( volume or 1 )
end

local played_sounds = {}
function guthscp.sound.play( ent, path, radius, looping, volume )
	start_network_sound( ent, path, radius, looping, volume )
	net.Broadcast()

	played_sounds[path .. "_" .. ent:EntIndex()] = {
		entity = ent,
		path = path,
		radius = radius,
		looping = looping,
		volume = volume,
	}
end

--  warning: not the same structure that client one
function guthscp.sound.get_played_sounds()
	return played_sounds 
end

function guthscp.sound.get_played_sound( ent, path )
	return played_sounds[path .. ":" .. ent:EntIndex()]
end

function guthscp.sound.stop( ent, path )
	net.Start( "guthscp:stop_sound_channel" )
		net.WriteString( path )
		net.WriteEntity( ent )
	net.Broadcast()

	played_sounds[path .. "_" .. ent:EntIndex()] = nil
end

--  network played sound to new players
local cooldowns = {}
net.Receive( "guthscp:play_sound_channel", function( len, ply )
	if cooldowns[ply] and CurTime() - cooldowns[ply] < 10 then return end 
	cooldowns[ply] = CurTime()

	for k, v in pairs( played_sounds ) do
		start_network_sound( v.entity, v.path, v.radius, v.looping, v.volume )
		net.Send( ply )
	end
end )
if SERVER then 
    util.AddNetworkString( "guthscpbase:playsoundchannel" )
    util.AddNetworkString( "guthscpbase:stopsoundchannel" )

    local function start_network_sound( ent, path, radius, looping, volume )
        net.Start( "guthscpbase:playsoundchannel" )
        net.WriteString( path )
        net.WriteEntity( ent )
        net.WriteUInt( radius or 1024, 16 )
        net.WriteBool( looping or false )
        net.WriteFloat( volume or 1 )
    end

    local played_sounds = {}
    function GuthSCP.playSound( ent, path, radius, looping, volume )
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
    function GuthSCP.getPlayedSounds()
        return played_sounds 
    end

    function GuthSCP.getPlayedSound( ent, path )
        return played_sounds[path .. ":" .. ent:EntIndex()]
    end

    function GuthSCP.stopSound( ent, path )
        net.Start( "guthscpbase:stopsoundchannel" )
            net.WriteString( path )
            net.WriteEntity( ent )
        net.Broadcast()

        played_sounds[path .. "_" .. ent:EntIndex()] = nil
    end

    --  network played sound to new players
    local cooldowns = {}
    net.Receive( "guthscpbase:playsoundchannel", function( len, ply )
        if cooldowns[ply] and CurTime() - cooldowns[ply] < 10 then return end 
        cooldowns[ply] = CurTime()

        for k, v in pairs( played_sounds ) do
            start_network_sound( v.entity, v.path, v.radius, v.looping, v.volume )
            net.Send( ply )
        end
    end )
else
    local sounds = {}

    timer.Create( "guthscpbase:soundchannel", .1, 0, function()
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

    net.Receive( "guthscpbase:playsoundchannel", function()
        local path = net.ReadString()

        local parent = net.ReadEntity() 
        if not IsValid( parent ) then return print( "GuthSCP ─ Failed to find entity while trying to play a channel sound" ) end

        local radius = net.ReadUInt( 16 )
        local looping = net.ReadBool()
        local volume = net.ReadFloat()

        GuthSCP.playSound( parent, path, radius, looping, volume )
    end )

    net.Receive( "guthscpbase:stopsoundchannel", function()
        local path = net.ReadString()

        local parent = net.ReadEntity() 
        if not IsValid( parent ) then return print( "GuthSCP ─ Failed to find entity while trying to stop a channel sound" ) end

        GuthSCP.stopSound( parent, path )
    end )

    function GuthSCP.playSound( ent, path, radius, looping, volume )
        if not IsValid( ent ) then return end
        GuthSCP.stopSound( ent, path )

        radius = radius or 1024
        looping = looping or false
        volume = volume or 1

        sound.PlayFile( "sound/" .. path, "3d noblock noplay", function( channel, err_id, err_name )
            if not IsValid( channel ) then return print( ( "GuthSCP ─ Failed to play %q : '%s' (%d)" ):format( path, err_name, err_id ) ) end
            if not IsValid( ent ) then return print( ( "GuthSCP ─ Failed to play %q : the entity wasn't found!" ):format( path, err_name, err_id ) ) end
        
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

    function GuthSCP.stopSound( ent, path )
        local key = path .. ":" .. ent:EntIndex()
        if sounds[key] then sounds[key].channel:Stop() end
        sounds[key] = nil
    end

    --  warning: not the same structure that server one
    function GuthSCP.getPlayedSounds()
        return sounds
    end

    function GuthSCP.getPlayedSound( ent, path )
        return sounds[path .. ":" .. ent:EntIndex()]
    end

    --  ask played sounds
    hook.Add( "InitPostEntity", "guthscpbase:soundchannel", function()
        net.Start( "guthscpbase:playsoundchannel" )
        net.SendToServer()
    end )

    --  stop channels
    concommand.Add( "guthscpbase_stop_channel_sounds", function()
        local count = 0

        for k, v in pairs( sounds ) do
            v.channel:Stop()
            sounds[k] = nil
            count = count + 1
        end

        print( ( "GuthSCP ─ Stopped %d channels" ):format( count ) )
    end )

    concommand.Add( "guthscpbase_print_channel_sounds", function()
        print( ( "GuthSCP ─ %d channel(s) is/are playing" ):format( table.Count( sounds ) ) )

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
end
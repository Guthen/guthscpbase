
if SERVER then
	util.AddNetworkString( "guthscp:set_message" )

	function guthscp.player_message( ply, text )
		net.Start( "guthscp:set_message" )
			net.WriteString( text )
		net.Send( ply )
	end
else
	local max_lifetime = 3
	local fading_time_ratio = 0.8  --  80% of 3s = 2.4s
	function guthscp.player_message( text )
		local lifetime = 0
		hook.Add( "HUDPaint", "guthscp.player_message:draw", function()
			--  increase lifetime
			lifetime = lifetime + FrameTime()

			--  remove message
			if lifetime > max_lifetime then
				hook.Remove( "HUDPaint", "guthscp.player_message:draw" )
			end

			--  handle fade out
			local color = color_white
			local ratio = lifetime / max_lifetime
			if ratio >= fading_time_ratio then
				color = ColorAlpha( color, ( 1 - ( ratio - fading_time_ratio ) / ( 1 - fading_time_ratio ) ) * 255 )
			end

			--  draw
			draw.SimpleText( text, "ChatFont", ScrW() / 2, ScrH() / 1.2, color, TEXT_ALIGN_CENTER )
		end )
	end

	net.Receive( "guthscp:set_message", function()
		guthscp.player_message( net.ReadString() )
	end )
end
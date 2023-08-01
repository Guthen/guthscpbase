guthscp.config = guthscp.config or {}

function guthscp.config.create_apply_button()
	return {
		type = "Button",
		name = "Apply",
		action = function( self, form )
			guthscp.config.send( form._id, guthscp.config.serialize_form( form ) )
		end,
	}
end

function guthscp.config.create_reset_button()
	return {
		type = "Button",
		name = "Reset to Default",
		action = function( self, form )
			Derma_Query( 
				"Are you really sure to reset the actual configuration to its default settings? This will delete the existing configuration file.", "Reset Configuration", 
				"Yes", function()
					--  send reset to server
					net.Start( "guthscp.config:reset" )
						net.WriteString( form._id )
					net.SendToServer()
				end,
				"No", nil
			)
		end,
	}
end
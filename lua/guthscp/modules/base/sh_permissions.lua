local config = guthscp.configs.base

function guthscp.is_guthscp_tool( tool_name )
	return tool_name:find( "^guthscp_[%w_]*_configurator$" )
end

hook.Add( "CanTool", "guthscp:default_permissions", function( ply, tr, tool_name, tool, button )
	if config.permissions_default_tools and guthscp.is_guthscp_tool( tool_name ) and not ply:IsSuperAdmin() then
		if SERVER then
			guthscp.warning( "guthscp.permissions", "%q (%s) attempted to use the GuthSCP tool %q with no permissions.", ply:GetName(), ply:SteamID(), tool_name )
			ply:PrintMessage( HUD_PRINTTALK, "You are not authorized to use this tool!" )
		end
		return false
	end
end )
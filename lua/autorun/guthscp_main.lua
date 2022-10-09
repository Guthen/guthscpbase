guthscp = guthscp or {}

guthscp.REALMS = {
	SERVER = 0,
	CLIENT = 1,
	SHARED = 2,
}

--  network bits
guthscp.NETWORK_PLAYERS_BITS = math.ceil( math.log( game.MaxPlayers() + 1, 2 ) )  --  compute number of bits for players count

--[[ 
	@function guthscp.get_current_realm
		| description: get the realm the current code is executing in, as a @`guthscp.REALMS` enum-value
		| return: <@guthscp.REALMS> current_realm 
]]
function guthscp.get_current_realm()
	return SERVER and guthscp.REALMS.SERVER or guthscp.REALMS.CLIENT
end

--[[ 
	@function guthscp.is_same_realm
		| description: compare two @`guthscp.REALMS` values and returns if they are equivalent; 
					   if one realm is set to @`guthscp.REALMS.SHARED`, then `true` will be returned
		| return: <bool> 
]]
function guthscp.is_same_realm( realm_a, realm_b )
	--  shared include both realms
	if realm_a == guthscp.REALMS.SHARED or realm_b == guthscp.REALMS.SHARED then
		return true
	end
	
	--  check for equal
	if realm_a == realm_b then 
		return true 
	end

	return false
end

--  logs
local info_color = SERVER and Color( 156, 241, 255 ) or Color( 255, 241, 122 )
local error_color = Color( 222, 88, 88 )
local warning_color = Color( 222, 173, 27 )
local debug_color = Color( 88, 222, 88 )
guthscp.print_tabs = 0

local function get_current_realm_name()
	return SERVER and "server" or "client"
end

function guthscp.print( color, message, ... )
	--  format message
	if ... then
		message = message:format( ... )
	end

	--  indentation
	if guthscp.print_tabs > 0 then
		message =  ( "    " ):rep( guthscp.print_tabs ) .. "└─ " ..message
	end

	--  output
	MsgC( color, message, "\n" )
end

function guthscp.info( title, message, ... )
	guthscp.print( info_color, "[%s:info] %s: " .. message, get_current_realm_name(), title, ... )
end

function guthscp.error( title, message, ... )
	guthscp.print( error_color, "[%s:error] %s: " .. message, get_current_realm_name(), title, ... )
end

function guthscp.warning( title, message, ... )
	guthscp.print( warning_color, "[%s:warning] %s: " .. message, get_current_realm_name(), title, ... )
end

--  debug logs
local convar_debug = CreateConVar( "guthscp_debug", "0", FCVAR_ARCHIVE, "enables debug messages", 0, 1 )

function guthscp.is_debug()
	return convar_debug:GetBool()
end

function guthscp.debug( title, message, ... )
	if not guthscp.is_debug() then return end
	guthscp.print( debug_color, "[%s:debug] %s: " .. message, get_current_realm_name(), title, ... )
end

--  file management
function guthscp.require_file( path, realm )
	if realm == guthscp.REALMS.SERVER then
		if SERVER then
			guthscp.info( "guthscp", "server loading %q", path )
			return include( path )
		end
	elseif realm == guthscp.REALMS.CLIENT then
		guthscp.info( "guthscp", "client loading %q", path )
		if SERVER then
			AddCSLuaFile( path )
		else
			return include( path )
		end
	elseif realm == guthscp.REALMS.SHARED then
		guthscp.info( "guthscp", "shared loading %q", path )
		if SERVER then
			AddCSLuaFile( path )
		end
		return include( path )
	else
		guthscp.error( "guthscp", "failed to include %q (unhandled realm %s)", path, realm )
	end
end

function guthscp.require_folder( path, is_recursive )
	local files, dirs = file.Find( path .. "*", "LUA" )

	guthscp.info( "guthscp", "loading folder %q%s", path, is_recursive and " (recursive)" or "" )
	guthscp.print_tabs = guthscp.print_tabs + 1

	--  load files
	for i, name in ipairs( files ) do
		local realm = guthscp.REALMS.SHARED
		if name:find( "^sv_" ) then
			realm = guthscp.REALMS.SERVER
		elseif name:find( "^cl_" ) then
			realm = guthscp.REALMS.CLIENT
		end
		guthscp.require_file( path .. name, realm )
	end

	--  load folders (recursive)
	if is_recursive then
		for i, name in ipairs( dirs ) do
			guthscp.require_folder( path .. name .. "/", is_recursive )
		end
	end

	guthscp.print_tabs = guthscp.print_tabs - 1
	if guthscp.print_tabs == 0 then
		print()
	end
end

--  load
MsgC( info_color, [[                                                             
	  ▄████  █    ██ ▄▄▄█████▓ ██░ ██   ██████  ▄████▄   ██▓███  
	 ██▒ ▀█▒ ██  ▓██▒▓  ██▒ ▓▒▓██░ ██▒▒██    ▒ ▒██▀ ▀█  ▓██░  ██▒
	▒██░▄▄▄░▓██  ▒██░▒ ▓██░ ▒░▒██▀▀██░░ ▓██▄   ▒▓█    ▄ ▓██░ ██▓▒
	░▓█  ██▓▓▓█  ░██░░ ▓██▓ ░ ░▓█ ░██   ▒   ██▒▒▓▓▄ ▄██▒▒██▄█▓▒ ▒
	░▒▓███▀▒▒▒█████▓   ▒██▒ ░ ░▓█▒░██▓▒██████▒▒▒ ▓███▀ ░▒██▒ ░  ░
	 ░▒   ▒ ░▒▓▒ ▒ ▒   ▒ ░░    ▒ ░░▒░▒▒ ▒▓▒ ▒ ░░ ░▒ ▒  ░▒▓▒░ ░  ░
	  ░   ░ ░░▒░ ░ ░     ░     ▒ ░▒░ ░░ ░▒  ░ ░  ░  ▒   ░▒ ░     
	░ ░   ░  ░░░ ░ ░   ░       ░  ░░ ░░  ░  ░  ░        ░░       
		  ░    ░               ░  ░  ░      ░  ░ ░               
											   ░     
]] ) --  wooohoo it's scary \o/
print("\n")
guthscp.require_folder( "guthscp/keter/", true )
guthscp.module.require()
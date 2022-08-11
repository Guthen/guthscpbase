
--[[ 
	@function guthscp.is_scp
		| description: check if a given player is in a SCP team
		| params:
			ply: <Player>
		| return: <bool> is_scp
]]
function guthscp.is_scp( ply )
	if not ply:IsPlayer() then return false end

	local teams = guthscp.configs.base.scp_teams or {}
	return teams[guthscp.get_team_keyname( isnumber( ply ) and ply or ply:Team() )] or false
end

--[[ 
	@function guthscp.get_scps
		| description: get all players currently in a SCP team, based on the server's configuration
		| return: <table[Player]> players
]]
function guthscp.get_scps()
	local teams, players = guthscp.configs.base.scp_teams, {}

	--  no teams? no need to iterate through all players
	if not teams or not next( teams ) then 
		return players 
	end

	for i, v in ipairs( player.GetAll() ) do
		if teams[guthscp.get_team_keyname( v:Team() )] then 
			players[#players + 1] = v 
		end
	end

	return players
end

--  teams
--[[ 
	@function guthscp.cache_teams_keynames
		| description: cache all teams keynames (global Lua variable names) and their IDs values by looping over `_G`; 
					   used internally by @`guthscp.get_teams_keynames` & @`guthscp.get_team_keyname`
]]
local teams_keynames, keynames_teams
function guthscp.cache_teams_keynames() 
	teams_keynames = {}

	local count = 0
	for k, v in pairs( _G ) do
		if k:StartWith( "TEAM_" ) then
			teams_keynames[k] = v
			count = count + 1
		end
	end
	keynames_teams = guthscp.table.reverse( teams_keynames )

	guthscp.debug( "guthscp", "cached %d teams keynames", count )
end
hook.Add( "InitPostEntity", "guthscp:cache_teams_keynames", guthscp.cache_teams_keynames )

--[[ 
	@function guthscp.get_teams_keynames
		| description: get all teams IDs mapped by their global Lua variable names
		| example:
			code:
			```lua
			PrintTable( guthscp.get_teams_keynames() )
			```

			output:
			```
			TEAM_CITIZEN   =   1
			TEAM_SCP096    =   2
			...
			```
		| return: <table[string, number]> teams_keynames
]]
function guthscp.get_teams_keynames()
	if not teams_keynames then 
		guthscp.cache_teams_keynames() 
	end
	
	return teams_keynames
end

--[[ 
	@function guthscp.get_team_keyname
		| description: get global Lua variable name of a given team ID
		| params:
			team_id: <number>
		| return: <string> team_keyname
]]
function guthscp.get_team_keyname( team_id )
	if not keynames_teams then 
		guthscp.cache_teams_keynames() 
	end

	return keynames_teams[team_id]
end


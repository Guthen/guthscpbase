guthscp.config = guthscp.config or {}

--  creators
function guthscp.config.create_teams_element( element )
	return table.Merge( {
		type = "ComboBox[]",
		name = "Teams",
		id = "teams",
		value = function( config_value, config_key )
			id = isnumber( config_key ) and config_key or isstring( config_key ) and _G[config_key]
			return id and team.GetName( id ) or false
		end,
		choice = function()
			local teams = {}

			for k, v in pairs( team.GetAllTeams() ) do
				if not v.Joinable then continue end
				teams[#teams + 1] = {
					value = v.Name,
					data = guthscp.get_team_keyname( k ),
				}
			end

			return teams
		end,
	}, element or {} )
end

function guthscp.config.create_team_element( element )
	element = guthscp.config.create_teams_element( element )
	element.type = "ComboBox" --  set element type as a single combobox and not an array
	return element
end

function guthscp.config.create_enum_element( enum, element )
	return table.Merge( {
		type = "ComboBox",
		value = function( config_key, config_value )
			--  is 'config_value' the data?
			if isnumber( config_value ) then
				for k, v in pairs( enum ) do
					if v == config_value then
						return k:sub( 1, 1 ):upper() .. k:sub( 2 ):lower()
					end
				end
			end
			return config_value
		end,
		choice = function()
			local choices = {}

			for k, v in pairs( enum ) do
				choices[#choices + 1] = {
					value = k:sub( 1, 1 ):upper() .. k:sub( 2 ):lower(),
					data = v,
				}
			end

			return choices
		end,
	}, element or {} )
end

function guthscp.config.create_apply_button( config_id )
	return {
		type = "Button",
		name = "Apply",
		action = function( form, serialize_form )
			guthscp.config.send( config_id, serialize_form )
		end,
	}
end

--  receivers
function guthscp.config.receive_teams( teams )
	assert( istable( teams ), "'teams' is not a table" )
	
	return guthscp.table.create_set( teams )
end

--  parsers
function guthscp.config.parse_teams( teams ) 
	assert( istable( teams ), "'teams' is not a table" )

	local new_teams = {}

	for k, v in pairs( team.GetAllTeams() ) do
		if not v.Joinable then continue end

		local keyname = guthscp.get_team_keyname( k )
		if not keyname then
			guthscp.warning( "guthscp", "%q doesn't have an unique 'TEAM_' name, this could lead to inability to save this team in the configuration!", v.Name )
			continue
		end
		if not teams[v.Name] and not teams[k] and not teams[keyname] then continue end

		new_teams[keyname] = true
	end

	return new_teams
end

function guthscp.parse_team_config( team_key )
	local team_id = isnumber( team_key ) and team_key or _G[team_key]
	if not isnumber( team_id ) then return end

	local team_info = team.GetAllTeams()[team_id]
	if not team_info.Joinable then return end

	return guthscp.get_team_keyname( team_id )
end
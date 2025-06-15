guthscp.config = guthscp.config or {}
guthscp.config.path = "configs/"
guthscp.configs = guthscp.configs or {}

local function is_save_per_map_format( value, meta )
	if not istable( value ) then return false end

	if meta.type == "Color" and guthscp.helpers.is_color( value ) then
		return false
	end

	return true
end

local function ensure_config_type( config, meta )
	local value = config[meta.id]
	if value == nil then return end

	local is_correct, message = guthscp.config.is_value_valid( value, meta )
	if not is_correct then
		guthscp.warning( "guthscp.config", "element %q isn't of the required type %s, reseting to default.", meta.id, meta.type )	
		config[meta.id] = meta.default
	end

	if message then
		guthscp.print_tabs = guthscp.print_tabs + 1
		guthscp.warning( "guthscp.config", message )
		guthscp.print_tabs = guthscp.print_tabs - 1
	end
end

function guthscp.config.apply( id, config, options )
	local config_meta = guthscp.config_metas[id]
	if not config_meta then
		return guthscp.error( "guthscp.config", "trying to apply config %q which isn't registered!", id )
	end

	guthscp.print_tabs = guthscp.print_tabs + 1
	local metas = guthscp.config.get_metas( id )
	for k, v in pairs( metas ) do
		--  parse save-per-map configuration
		--  if the value is not in the save-per-map format, we assume the value doesn't need any changes 
		if v.save_per_map and is_save_per_map_format( config[k], v ) then
			if config[k][game.GetMap()] ~= nil then
				config[k] = config[k][game.GetMap()]
			else
				--	set to nil for a reset to default later down the loop 
				config[k] = nil
			end
		end

		--  apply default values while prioritizing changes
		if v.default ~= nil and config[k] == nil then
			config[k] = v.default
		end

		ensure_config_type( config, v )
	end
	guthscp.print_tabs = guthscp.print_tabs - 1

	--  parse
	if config_meta.parse then
		config_meta.parse( config )
	end

	--  apply data
	guthscp.configs[id] = guthscp.configs[id] or {}
	for k, v in pairs( config ) do
		guthscp.configs[id][k] = v
	end

	--  special options
	if istable( options ) then
		--  network to players
		if SERVER and options.network then
			if player.GetCount() > 0 then  --  only sync if players are in-game
				timer.Simple( 0, function()
					guthscp.config.sync( id, guthscp.configs[id] )
				end )
			end
		end

		--  save to json
		if options.save then
			guthscp.config.save( id )
		end
	end

	--  run hook
	hook.Run( "guthscp.config:applied", id, guthscp.configs[id] )
end

function guthscp.config.save( id )
	local config = guthscp.configs[id] or {}
	local metas = guthscp.config.get_metas( id )
	local current_map = game.GetMap()
	local last_changes = guthscp.data.load_from_json( guthscp.config.path .. id .. ".json" ) or {}

	--  we will only save config variables that are different from default values, this allows developpers
	--  to change default values in future updates that will be effective once the mod is updated
	--  (if the user didn't change those, of course)
	local changes = {}
	local changes_count = 0
	for k, v in pairs( config ) do
		--  ensure the value is registered in the config
		if not metas[k] or not metas[k].default then continue end

		if metas[k].save_per_map and is_save_per_map_format( last_changes[k], metas[k] ) then
			--	pre-pass to keep last changes while reseting current map value
			--	in case it has to be skipped (i.e. equals to default)
			changes[k] = last_changes[k]
			if changes[k] then
				changes[k][current_map] = nil
			end
		end

		--  only gather non-default values
		if istable( v ) and not IsColor( v ) then
			--  table types need extra work to compare them since by default Lua only compares their memory adresses
			if guthscp.table.is_equal( v, metas[k].default ) then
				continue
			end
		elseif v == metas[k].default then
			continue
		end
		
		if metas[k].save_per_map then
			--	save our changes to the current map slot
			changes[k] = changes[k] or {}
			changes[k][current_map] = v
		else
			changes[k] = v
		end

		changes_count = changes_count + 1
	end

	--  save to file
	local path = guthscp.config.path .. id .. ".json"
	if changes_count > 0 then
		guthscp.data.save_to_json( path, changes, true )
		guthscp.info( "guthscp.config", "saved %d changes for config %q at %q", changes_count, id, "data/guthscp/" .. path )
	else
		guthscp.data.delete( path )
		guthscp.info( "guthscp.config", "no changes to save for config %q", id )
	end
end

function guthscp.config.load( id )
	--  since we only save differences from default values into a file, we need to first load the defaults,
	--  merge with the data of the user (which are the changes) and finally apply the result;
	--  guthscp.config.apply will take care of that aspect.

	--  load from data file
	local changes = guthscp.data.load_from_json( guthscp.config.path .. id .. ".json" )
	if not changes then
		guthscp.info( "guthscp.config", "failed to load data for %q config", id )
		return false
	end

	local changes_count = table.Count( changes )

	--  apply data
	guthscp.config.apply( id, changes, {
		network = true,
	} )
	guthscp.info( "guthscp.config", "loaded data to %q config with %d changes", id, changes_count )
	return true
end

function guthscp.config.set_defaults( id )
	local defaults = guthscp.config.get_defaults( id )
	guthscp.configs[id] = defaults
	guthscp.info( "guthscp.config", "loaded defaults to %q config", id )
end
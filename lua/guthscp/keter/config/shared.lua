guthscp.config = guthscp.config or {}
guthscp.config.path = "configs/"
guthscp.configs = guthscp.configs or {}

function guthscp.config.apply( id, config, options )
	local config_meta = guthscp.config_metas[id]
	if not config_meta then
		return guthscp.error( "guthscp.config", "trying to apply config %q which isn't registered!", id )
	end

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
					guthscp.config.sync( id, config )
				end )
			end
		end

		--  save to json
		if options.save then
			guthscp.data.save_to_json( guthscp.config.path .. id .. ".json", config, true )
		end
	end

	--  run hook
	hook.Run( "guthscp.config:applied", id, guthscp.configs[id] )
end

function guthscp.config.setup( id )
	guthscp.configs[id] = guthscp.configs[id] or {}
	guthscp.config.load_defaults( id )
end

function guthscp.config.load( id )
	--  setup
	guthscp.config.setup( id )

	--  load from data file
	local config = guthscp.data.load_from_json( guthscp.config.path .. id .. ".json" )
	if not config then
		guthscp.info( "guthscp.config", "failed to load data for %q config", id )
		return false
	end

	--  apply data
	guthscp.config.apply( id, config, {
		network = true,
	} )
	guthscp.info( "guthscp.config", "loaded data to %q config", id )
	return true
end

function guthscp.config.load_defaults( id )
	local config_meta = guthscp.config_metas[id]
	if not config_meta or not config_meta.form then return end

	local function try_set_default( meta )
		if meta.id == nil or meta.default == nil then return end

		guthscp.configs[id][meta.id] = meta.default
	end

	--  apply default in form
	for i, meta in ipairs( config_meta.form ) do
		if not istable( meta ) then continue end

		--  check is an element
		if meta.type then
			try_set_default( meta )
		else
			--  consider as a group of elements
			for j, meta2 in ipairs( meta ) do
				try_set_default( meta2 )
			end
		end
	end
	guthscp.info( "guthscp.config", "loaded defaults to %q config", id )
end
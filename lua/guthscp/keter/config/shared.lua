guthscp.config = guthscp.config or {}
guthscp.config.path = "configs/"
guthscp.configs = guthscp.configs or {}

function guthscp.config.apply( id, tbl, options )
	local config = guthscp.config.get_all()[id]
	if not config then 
		return guthscp.error( "guthscp.config", "trying to apply config %q which isn't registered!", id )
	end

	--  parse
	if config.parse then 
		config.parse( tbl ) 
	end

	--  apply data
	guthscp.configs[id] = guthscp.configs[id] or {}
	for k, v in pairs( tbl ) do
		guthscp.configs[id][k] = v
	end

	--  special options
	if istable( options ) then
		--  network to players
		if SERVER and options.network then
			if player.GetCount() > 0 then  --  only sync if players are in-game
				timer.Simple( 0, function() 
					guthscp.config.sync( id, tbl ) 
				end )
			end
		end

		--  save to json
		if options.save then
			guthscp.data.save_to_json( guthscp.config.path .. id .. ".json", tbl, true )
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
	local tbl = guthscp.data.load_from_json( guthscp.config.path .. id .. ".json" )
	if not tbl then return false end

	--  apply data
	guthscp.config.apply( id, table.Merge( guthscp.configs[id] or {}, tbl ), {
		network = true,
	} )
	guthscp.info( "guthscp.config", "loaded data to %q config", id )
	return true
end

function guthscp.config.load_defaults( id )
	local tbl = guthscp.config.get_all()[id]
	if not tbl or not tbl.elements or not tbl.elements[1] or not tbl.elements[1].elements then return end --  yea rude

	for i, v in ipairs( tbl.elements[1].elements ) do
		if v.id and v.default then
			guthscp.configs[id][v.id] = v.default
		end
	end
	guthscp.info( "guthscp.config", "loaded defaults to %q config", id )
end
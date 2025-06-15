guthscp.config = guthscp.config or {}

function guthscp.config.create_apply_button()
	guthscp.warning( "guthscp.config", "function 'guthscp.config.create_apply_button' is obsolete, it will be deleted in future versions" )
end

function guthscp.config.create_reset_button()
	guthscp.warning( "guthscp.config", "function 'guthscp.config.create_reset_button' is obsolete, it will be deleted in future versions" )
end

local ERROR_EXPECTED_TYPE = "expected a %s, got a %s instead"

function guthscp.config.is_value_valid( value, meta )
	local check_by_type = {
		["Number"] = function()
			if not isnumber( value ) then
				return false, ERROR_EXPECTED_TYPE:format( "number", type( value ) )
			end

			return true
		end,
		["Bool"] = function()
			if not isbool( value ) then
				return false, ERROR_EXPECTED_TYPE:format( "bool", type( value ) )
			end

			return true
		end,
		["String"] = function()
			if not isstring( value ) then
				return false, ERROR_EXPECTED_TYPE:format( "string", type( value ) )
			end

			return true
		end,
		["String[]"] = function()
			if not istable( value ) then
				return false, ERROR_EXPECTED_TYPE:format( "table", type( value ) )
			end
			
			if meta.is_set then
				for k, v in pairs( value ) do
					if not isstring( k ) then
						return false, ( "expected element %q to be a string, got a %s instead" ):format( k, type( k ) )
					end

					if v ~= true then
						return false, ( "expected element %q to be true instead of %s" ):format( k, v )
					end
				end
			else
				for i, v in ipairs( value ) do
					if not isstring( v ) then
						return false, ( "expected element at index %d to be a string, got a %s instead" ):format( i, type( v ) )
					end
				end
			end
			
			return true
		end,
		["Color"] = function()
			if not guthscp.helpers.is_color( value ) then
				return false, ERROR_EXPECTED_TYPE:format( "Color", type( value ) )
			end

			return true
		end,
		["Vector"] = function()
			if not isvector( value ) then
				return false, ERROR_EXPECTED_TYPE:format( "Vector", type( value ) )
			end

			return true
		end,
		["Angle"] = function()
			if not isangle( value ) then
				return false, ERROR_EXPECTED_TYPE:format( "Angle", type( value ) )
			end

			return true
		end,
		["Enum"] = function()
			if not isnumber( value ) then
				return false, ERROR_EXPECTED_TYPE:format( "number", type( value ) )
			end

			for k, v in pairs( meta.enum ) do
				if v == value then
					return true
				end
			end
			
			return false, ( "expected a valid enum value, got %d instead" ):format( value )
		end,
		["InputKey"] = function()
			if not isnumber( value ) then
				return false, ERROR_EXPECTED_TYPE:format( "number", type( value ) )
			end

			if value <= BUTTON_CODE_NONE or value >= BUTTON_CODE_COUNT then
				return false, ( "expected a number in range of ]%d, %d[, got %d instead" ):format( BUTTON_CODE_NONE, BUTTON_CODE_COUNT, value )
			end
			
			return true
		end,
		["Team"] = function()
			if not guthscp.is_valid_team_keyname( value ) then
				return false, ( "expected a valid team keyname, got %s instead" ):format( value )
			end

			return true
		end,
		["Teams"] = function()
			if not istable( value ) then
				return false, ERROR_EXPECTED_TYPE:format( "table", type( value ) )
			end

			for k, v in pairs( value ) do
				if not guthscp.is_valid_team_keyname( k ) then
					return false, ( "expected element %q to be a valid team keyname" ):format( k )
				end

				-- Teams is a set, so the value must be true
				if v ~= true then
					return false, ( "expected element %q to be true instead of %s" ):format( k, v )
				end
			end

			return true
		end,
	}

	if check_by_type[meta.type] then
		return check_by_type[meta.type]( value )
	end

	guthscp.debug( "guthscp.config", "element %q couldn't be type-checked because type %s isn't available.", meta.id, meta.type )
	return true
end

function guthscp.config.get_metas( id )
	local config_meta = guthscp.config_metas[id]
	if not config_meta or not config_meta.form then return nil end

	local metas = {}

	local function try_set_meta( meta )
		if meta.id == nil then return end
		metas[meta.id] = meta
	end

	for i, meta in ipairs( config_meta.form ) do
		if not istable( meta ) then continue end

		--  check is an element
		if meta.type then
			try_set_meta( meta )
		else
			--  consider as a group of elements
			for j, meta2 in ipairs( meta ) do
				try_set_meta( meta2 )
			end
		end
	end

	return metas
end

function guthscp.config.get_defaults( id )
	local config_meta = guthscp.config_metas[id]
	if not config_meta or not config_meta.form then return nil end

	local defaults = {}

	local function try_set_default( meta )
		if meta.id == nil or meta.default == nil then return end
		defaults[meta.id] = meta.default
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

	return defaults
end
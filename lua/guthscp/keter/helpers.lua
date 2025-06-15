guthscp.helpers = guthscp.helpers or {}

guthscp.VERSION_STATES = {
	NONE = 0,
	PENDING = 1,
	UPDATE = 2,
	OUTDATE = 3,
}

--[[ 
	@function guthscp.helpers.split_version
		| description: use pattern to split a [semantic version](https://semver.org/) string into its individual parts
		| params:
			version: <string> semantic version to split
		| return: 
			<string> major_version,
			<string> minor_version,
			<string> patch_version,
			<string> pre_release_version
]]
function guthscp.helpers.split_version( version )
	return version:match( "(%d+)%.(%d+)%.(%d+)%-?(.*)" )
end

--[[ 
	@function guthscp.helpers.compare_versions
		| description: compare two [semantic versions](https://semver.org/); do NOT support build metadata
		| params: 
			current_version: <string> current semantic version
			extern_version: <string> extern semantic version
		| return: 
			comparison_result: <int> possible results: inferior = -1; equal = 0; superior = 1,
			depth: <int> where does the comparison stopped: major = 1; minor = 2; patch = 3; pre-release = 4
]]
local identifier_pattern = "[%w_]+"
function guthscp.helpers.compare_versions( current_version, extern_version )
	local current_versions = { guthscp.helpers.split_version( current_version ) }
	local extern_versions = { guthscp.helpers.split_version( extern_version ) }

	--  check each numbers
	for i = 1, 3 do
		local current = tonumber( current_versions[i] )
		local extern = tonumber( extern_versions[i] )

		--  version is greater than extern
		if current > extern then
			return 1, i
		end

		--  version is lower than extern
		if current < extern then
			return -1, i
		end
	end

	--  check pre-release tag
	local current = current_versions[4]
	local extern = extern_versions[4]
	if #current > 0 or #extern > 0 then
		if #current == 0 then
			return 1, 4
		elseif #extern == 0 then
			return -1, 4
		end

		--  equal? no need to do fancy comparison
		if current == extern then
			return 0, 4
		--  fancy comparison, let's go
		else
			local current_iter = current:gmatch( identifier_pattern )
			local extern_iter = extern:gmatch( identifier_pattern )

			while true do
				local current_word = current_iter()
				if not current_word then
					return -1, 4
				end

				local extern_word = extern_iter()
				if not extern_word then
					return 1, 4
				end

				--  parse numbers
				local num = tonumber( current_word )
				if num then
					current_word = num
					num = tonumber( extern_word )
					if num then
						extern_word = num
					else
						return -1, 4
					end
				end

				--  compare
				if current_word > extern_word then
					return 1, 4
				elseif extern_word > current_word then
					return -1, 4
				end
			end
		end
	end

	return 0, -1
end

--[[ 
	@function guthscp.helpers.read_dependency_version
		| version: base@2.5.0
		| description: get informations out-of a dependency version format, supporting strings like "1.0.0-beta"
					   or containing labels like "optional:2.1.0"
		| params:
			version: <string> version text to use
		| return: 
			version: <string> semantic version without labels
			is_optional: <bool> whether the dependency is optional or not
]]
function guthscp.helpers.read_dependency_version( version )
	local replace_count
	version, replace_count = version:gsub( "optional:", "" )
	return version, replace_count > 0
end

--[[ 
	@function guthscp.helpers.define_print_methods
		| description: define class methods `info`, `error`, `warning` & `debug` for printings messages to console;
					   note that the `id` parameter must be defined on your objects
		| params:
			meta: <table> meta table to define methods on
			prefix: <string> prefix message to append in the print title
]]
function guthscp.helpers.define_print_methods( meta, prefix )
	function meta:info( message, ... )
		guthscp.info( prefix .. "/" .. self.id, message, ... )
	end

	function meta:error( message, ... )
		guthscp.error( prefix .. "/" .. self.id, message, ... )
	end

	function meta:warning( message, ... )
		guthscp.warning( prefix .. "/" .. self.id, message, ... )
	end

	function meta:debug( message, ... )
		guthscp.debug( prefix .. "/" .. self.id, message, ... )
	end
end

--[[ 
	@function guthscp.helpers.use_meta
		| description: set the metatable of a table and copy all its variables; useful for instancing a class object
		| params:
			tbl: <table> object instance
			meta: <table> meta table
]]
function guthscp.helpers.use_meta( tbl, meta )
	--  copy variables (preventing editing meta)
	for k, v in pairs( meta ) do
		if k:StartWith( "__" ) or tbl[k] then continue end
		if isfunction( v ) then continue end

		--  copy element
		if istable( v ) then
			tbl[k] = table.Copy( v )
		else
			tbl[k] = v
		end
	end

	--  inherit meta
	setmetatable( tbl, meta )
end

--[[ 
	@function guthscp.helpers.number_of_ubits
		| description: compute the [number of unsigned bits](https://wiki.facepunch.com/gmod/net.WriteUInt) required to contain the given number
		| params:
			number: <int> unsigned/positive number
		| return: <int> u_bits 
]]
function guthscp.helpers.number_of_ubits( number )
	return math.ceil( math.log( number + 1, 2 ) )
end

--[[ 
	@function guthscp.helpers.format_message
		| description: format a message using a key-value table of arguments, useful to avoid argument order as `string.format` need;
					   to specify an argument in your message, you must enclose it with '{}' and this argument should be defined in the arguments table
		| params:
			msg: <string> message to format
			args: const <table[string, any]> table of arguments, the values will be used with `tostring`
		| return: <string> formatted_text
]]
function guthscp.helpers.format_message( msg, args )
	local formatted_text = ""

	local function format_word( word )
		--  replace potentially found argument
		local key = word:match( "^{(.+)}$" )
		if key then
			word = tostring( args[key] or "?" )
		end

		--  append word
		formatted_text = formatted_text .. word
	end

	--  loop over all letters
	local word = ""
	for l in msg:gmatch( "." ) do
		--  format starting argument
		if l == "{" and #word > 0 then
			format_word( word )
			word = ""
		end

		--  append letter to word
		word = word .. l

		--  format ending argument
		if l == " " or l == "}" then
			format_word( word )
			word = ""
		end
	end

	--  format last remaining word
	if #word > 0 then
		format_word( word )
	end

	return formatted_text
end

function guthscp.helpers.stringify_enum_key( str )
	return str:sub( 1, 1 ):upper() .. str:sub( 2 ):lower()
end

function guthscp.helpers.lerp_color( t, a, b, should_lerp_alpha )
	return Color(
		Lerp( t, a.r, b.r ),
		Lerp( t, a.g, b.g ),
		Lerp( t, a.b, b.b ),
		should_lerp_alpha and Lerp( t, a.a, b.a ) or a.a
	)
end

function guthscp.helpers.is_color( value )
	if IsColor( value ) then return true end
	
	-- IsColor is not enough sometimes, maybe due to networking?
	-- but by reading the code, it seems like the color should still be re-created...
	if isnumber( value.r ) and isnumber( value.g ) and isnumber( value.b ) then return true end

	return false
end
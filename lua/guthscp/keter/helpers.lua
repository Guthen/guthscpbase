guthscp.helpers = guthscp.helpers or {}

guthscp.VERSION_STATES = {
	NONE = 0,
	PENDING = 1,
	UPDATE = 2,
	OUTDATE = 3,
}

function guthscp.helpers.split_version( version )
	return version:match( "(%d+)%.(%d+)%.(%d+)%-?(.*)" )
end

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
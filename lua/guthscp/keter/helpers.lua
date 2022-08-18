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

	--  check developpement tag
	local current = current_versions[4]
	if #current > 0 then
		local extern = extern_versions[4]

		--  assuming that a version without a tag means a production version 
		if #extern == 0 then
			return -1, 4
		--  same tag?
		elseif current == extern then
			return 0, 4
		end
	end

	return 0, -1
end
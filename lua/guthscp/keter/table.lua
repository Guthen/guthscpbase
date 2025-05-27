guthscp.table = guthscp.table or {}

--[[ 
	@function guthscp.table.reverse
		| description: reverses the values and the keys of the given table; keys becoming values and vice-versa
		| params:
			tbl: const <table> table to reverse
		| return: <table> new_tbl
]]
function guthscp.table.reverse( tbl )
	local new_tbl = {}

	for k, v in pairs( tbl ) do
		new_tbl[v] = k
	end

	return new_tbl
end

--[[ 
	@function guthscp.table.create_set
		| description: creates a set table (https://www.lua.org/pil/11.5.html) out of the given table's values
		| params:
			tbl: const <table> table to use
		| return: <table> new_tbl
]]
function guthscp.table.create_set( tbl )
	local new_tbl = {}

	for k, v in pairs( tbl ) do
		new_tbl[v] = true
	end

	return new_tbl
end

--[[ 
	@function guthscp.table.rehash
		| description: re-hashs the given table; creates a sequential table out of a (probably) non-sequential one
		| params:
			tbl: const <table> table to re-hash
		| return: <table> new_tbl
]]
function guthscp.table.rehash( tbl )
	local new_tbl = {}

	for k, v in pairs( tbl ) do
		new_tbl[#new_tbl + 1] = v
	end

	return new_tbl
end

--[[
	@function guthscp.table.is_equal
		| version: base@2.4.0
		| description: checks whether both tables contain exactly the same elements; designed to work for both sequential and non-sequential tables
		| params:
			tbl1: const <table> first table to compare
			tbl2: const <table> second table to compare
		| return: <bool>
]]
function guthscp.table.is_equal( tbl1, tbl2 )
	for k, v in pairs( tbl1 ) do
		if istable( v ) and istable( tbl2[k] ) then
			if not guthscp.table.is_equal( v, tbl2[k] ) then
				return false
			end
		elseif v ~= tbl2[k] then
			return false
		end
	end

	for k, v in pairs( tbl2 ) do
		if istable( v ) and istable( tbl1[k] ) then
			if not guthscp.table.is_equal( v, tbl1[k] ) then
				return false
			end
		elseif v ~= tbl1[k] then
			return false
		end
	end

	return true
end
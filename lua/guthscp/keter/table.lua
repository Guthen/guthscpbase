guthscp.table = guthscp.table or {}

--[[ 
    @function guthscp.table.merge
        | description: merges a table's values into another
        | params:
            to_tbl: <table> target table
            from_tbl: <table> table to merge into the target
        | return: <table> to_tbl
]]
function guthscp.table.merge( to_tbl, from_tbl )
    for k, v in pairs( from_tbl ) do
        if not ( from_tbl[k] == nil ) then
            to_tbl[k] = from_tbl[k]
        end
    end

    return to_tbl
end

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
            tbl: const <table> sequential table to use
        | return: <table> new_tbl
]]
function guthscp.table.create_set( tbl )
    local new_tbl = {}

    for i, v in ipairs( tbl ) do
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
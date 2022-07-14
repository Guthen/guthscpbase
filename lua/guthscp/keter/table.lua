guthscp.table = guthscp.table or {}

function guthscp.table.merge( to_tbl, from_tbl )
    for k, v in pairs( from_tbl ) do
        if not ( from_tbl[k] == nil ) then
            to_tbl[k] = from_tbl[k]
        end
    end

    return to_tbl
end

function guthscp.table.reverse( tbl )
    local new_tbl = {}

    for k, v in pairs( tbl ) do
        new_tbl[v] = k
    end

    return new_tbl
end

function guthscp.table.values_to_keys( tbl )
    local new_tbl = {}

    for i, v in ipairs( tbl ) do
        new_tbl[v] = true
    end

    return new_tbl
end

function guthscp.table.rehash( tbl )
    local new_tbl = {}

    for k, v in pairs( tbl ) do
        new_tbl[#new_tbl + 1] = v
    end

    return new_tbl
end
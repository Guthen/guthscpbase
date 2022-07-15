guthscp.helpers = guthscp.helpers or {}

guthscp.VERSION_STATES = {
    NONE = 0,
    PENDING = 1,
    UPDATE = 2,
    OUTDATE = 3,
}

function guthscp.helpers.split_version( version )
    return version:match( ( "(%d+)" ):rep( 3, "%." ) )
end

function guthscp.helpers.compare_versions( current_version, extern_version )
    local current_versions = { guthscp.helpers.split_version( current_version ) }
    local extern_versions = { guthscp.helpers.split_version( extern_version ) }

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

    return 0, -1
end
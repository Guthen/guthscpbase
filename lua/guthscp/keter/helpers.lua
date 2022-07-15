guthscp.helpers = guthscp.helpers or {}

function guthscp.helpers.split_version( version )
    return version:match( ( "(%d+)" ):rep( 3, "%." ) )
end
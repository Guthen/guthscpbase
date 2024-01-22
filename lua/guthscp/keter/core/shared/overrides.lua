local PLAYER = FindMetaTable( "Player" )

--[[ 
	PLAYER:StripWeapons doesn't seem to natively call PLAYER:StripWeapon, which in turn calls 
	the hook GM:PlayerDroppedWeapon.

	As I'm not sure if it's a good idea to call GM:PlayerDroppedWeapon in this function, 
	I'm just running a custom hook to avoid conflicts.

	PLAYER:StripWeapons now calls the custom hook 'GM:PlayerStripWeapons( Player ply )'.
	Used in 'players_filter.lua'.
]]
_Player_StripWeapons = _Player_StripWeapons or PLAYER.StripWeapons
function PLAYER:StripWeapons()
	_Player_StripWeapons( self )
	hook.Run( "PlayerStripWeapons", self )
end
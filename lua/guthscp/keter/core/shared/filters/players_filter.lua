guthscp.players_filter = guthscp.players_filter or {}

local FILTER = guthscp.players_filter
guthscp.helpers.use_meta( FILTER, guthscp.filter )
FILTER._key = "players_filter"
FILTER._ubits = guthscp.helpers.number_of_ubits( game.MaxPlayers() )  --  compute number of bits for players count

function FILTER:filter( ent )
	return ent:IsPlayer()
end

--  hook listeners
if SERVER then
	function FILTER:listen_weapon_users( weapon_class )
		hook.Add( "WeaponEquip", self.global_id, function( weapon, ply )
			if not ( weapon:GetClass() == weapon_class ) then return end
			
			self:add( ply )
		end )
		hook.Add( "PlayerDroppedWeapon", self.global_id, function( ply, weapon )
			if not ( weapon:GetClass() == weapon_class ) then return end
			
			self:remove( ply )
		end )
		hook.Add( "PlayerStripWeapons", self.global_id, function( ply )  --  this is a custom hook, read 'overrides.lua'
			self:remove( ply )
		end )
		
		local function remove_player( ply )
			self:remove( ply )
		end
		--hook.Add( "PlayerSpawn", self.global_id, remove_player )
		hook.Add( "DoPlayerDeath", self.global_id, remove_player )
		hook.Add( "PlayerSilentDeath", self.global_id, remove_player )
	end
	
	function FILTER:listen_disconnect()
		hook.Add( "PlayerDisconnected", self.global_id, function( ply )
			self:remove( ply )
		end )
	end
end
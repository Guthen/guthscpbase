--  highly inspired on https://steamcommunity.com/sharedfiles/filedetails/?l=french&id=290961117's code
local no_debris_classes = {
	["func_door"] = true,
	["func_door_rotating"] = true,
}

guthscp.breaked_entities = {}
function guthscp.break_entity( ent, velocity )
	if not guthscp.is_breakable_entity( ent ) then return false end  --  avoid non-breakable entities
	if IsValid( ent.guthscp_breakable_phys ) or ent.guthscp_breakable_phys_base then return false end --  avoid to break already broken entities

	if not no_debris_classes[ent:GetClass()] then
		local phys_ent = ents.Create( "prop_physics" )
		phys_ent:SetCollisionGroup( COLLISION_GROUP_INTERACTIVE )
		phys_ent:SetPos( ent:GetPos() + velocity:GetNormal() * 20 )
		phys_ent:SetAngles( ent:GetAngles() )
		phys_ent:SetModel( ent:GetModel() )
		phys_ent:SetSkin( ent:GetSkin() )
		phys_ent:Spawn()
		phys_ent:EmitSound( ( "physics/metal/metal_box_break%d.wav" ):format( math.random( 1, 2 ) ) )
		
		--  allow hurting entities only some time
		timer.Simple( 1, function()
			if not IsValid( phys_ent ) then return end
			phys_ent:SetCollisionGroup( COLLISION_GROUP_WEAPON ) 
		end )

		if velocity then
			local phys = phys_ent:GetPhysicsObject()
			if IsValid( phys ) then
				phys:SetVelocity( velocity )
			end

			util.ScreenShake( phys_ent:GetPos(), 10, velocity:Length(), 2, 500 )
		end

		--  sparks effect
		if IsFirstTimePredicted() then
			local effect = EffectData()
			effect:SetOrigin( phys_ent:GetPos() + phys_ent:OBBCenter() )
			effect:SetMagnitude( 5 )
			effect:SetScale( 5 )
			effect:SetRadius( 5 )
			util.Effect( "Sparks", effect, true, true )
		end

		phys_ent.guthscp_breakable_phys_base = ent
		ent.guthscp_breakable_phys = phys_ent
	end

	if guthscp.configs.base.open_at_respawn then
		ent:Fire( "Open", 0 )
		ent:Fire( "UnLock", 0 )
	end

	ent:Extinguish()
	ent:SetNoDraw( true )
	ent:SetNotSolid( true )
	guthscp.breaked_entities[ent] = true

	--  auto-respawn
	if guthscp.configs.base.enable_respawn then
		timer.Simple( guthscp.configs.base.ent_respawn_time, function()
			if IsValid( ent ) then
				guthscp.repair_entity( ent )
			end
		end )
	end

	return true
end

local breakable_classes = { 
	["prop_door_rotating"] = true,
	["func_door_rotating"] = true,
	["prop_dynamic"] = true,
	["prop_physics"] = true,
	["func_door"] = true,
}
function guthscp.is_breakable_class( class )
	return breakable_classes[class]
end

function guthscp.is_breakable_entity( ent )
	return guthscp.is_breakable_class( ent:GetClass() ) and not guthscp.entity_breaking_filter:is_in( ent )
end

function guthscp.repair_entity( ent )
	ent:SetNoDraw( false )
	ent:SetNotSolid( false )

	--  remove physics ent
	if IsValid( ent.guthscp_breakable_phys ) then
		ent.guthscp_breakable_phys:Remove()
		ent.guthscp_breakable_phys = nil
	end

	guthscp.breaked_entities[ent] = nil
end

function guthscp.break_entities_at_player_trace( ply, break_force )
	break_force = break_force or 1
	
	local count = 0
	local tr = IsValid( ply ) and ply:GetEyeTrace() or ply

	for i, v in ipairs( ents.FindInSphere( tr.HitPos, 32 ) ) do
		if guthscp.is_breakable_entity( v ) then
			if guthscp.break_entity( v, tr.Normal * guthscp.configs.base.ent_break_force * break_force ) then
				count = count + 1
			end
		end
	end

	return count
end

--  concommands
concommand.Add( "guthscp_repair_entities", function( ply )
	if IsValid( ply ) and not ply:IsSuperAdmin() then 
		ply:PrintMessage( HUD_PRINTCONSOLE, "You can't use this superadmin command!" )
		return 
	end

	--  repair
	local count = 0
	for ent in pairs( guthscp.breaked_entities ) do
		guthscp.repair_entity( ent )
		count = count + 1
	end

	--  print to player
	local text = "You repaired " .. count .. " entities!"
	if IsValid( ply ) then
		ply:PrintMessage( HUD_PRINTCONSOLE, text )
	else
		print( text )
	end
end )

concommand.Add( "guthscp_debug_break_at_trace", function( ply )
	if not IsValid( ply ) then 
		return print( "You can't use this non-console command!" ) 
	end
	if not ply:IsSuperAdmin() then
		ply:PrintMessage( HUD_PRINTCONSOLE, "You can't use this superadmin command!" )
		return
	end

	--  break
	local count = guthscp.break_entities_at_player_trace( ply )
	ply:PrintMessage( HUD_PRINTCONSOLE, count > 0 and "You destroyed " .. count .. " entities!" or "Nothing has been destroyed!" )
end )
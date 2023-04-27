--  highly inspired on https://steamcommunity.com/sharedfiles/filedetails/?l=french&id=290961117's code
local no_debris_classes = {
    ["func_door"] = true,
    ["func_door_rotating"] = true,
}

local entity_blacklist = {}

local breaked_entities = {}
function GuthSCP.breakEntity( ent, velocity )
    if IsValid( ent.guthscpbase_breakable_phys ) then return false end
    if ent.guthscpbase_breakable_phys_base then return false end --  avoid to break already broken entities

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

        phys_ent.guthscpbase_breakable_phys_base = ent
        ent.guthscpbase_breakable_phys = phys_ent
    end

    if GuthSCP.Config.guthscpbase.open_at_respawn then
        ent:Fire( "Open", 0 )
        ent:Fire( "UnLock", 0 )
    end

    ent:Extinguish()
    ent:SetNoDraw( true )
    ent:SetNotSolid( true )
    breaked_entities[ent] = true

    --  auto-respawn
    if GuthSCP.Config.guthscpbase.enable_respawn then
        timer.Simple( GuthSCP.Config.guthscpbase.ent_respawn_time, function()
            if IsValid( ent ) then
                GuthSCP.repairEntity( ent )
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
function GuthSCP.isBreakableEntity( ent )
    return breakable_classes[ent:GetClass()]
end

function GuthSCP.repairEntity( ent )
    ent:SetNoDraw( false )
    ent:SetNotSolid( false )

    --  remove physics ent
    if IsValid( ent.guthscpbase_breakable_phys ) then
        ent.guthscpbase_breakable_phys:Remove()
        ent.guthscpbase_breakable_phys = nil
    end

    breaked_entities[ent] = nil
end

function GuthSCP.breakEntitiesAtPlayerTrace( ply, break_force )
    break_force = break_force or 1
    
    local count = 0
    local tr = IsValid( ply ) and ply:GetEyeTrace() or ply

    for i, v in ipairs( ents.FindInSphere( tr.HitPos, 32 ) ) do
        if GuthSCP.isBreakableEntity( v ) then
            if GuthSCP.breakEntity( v, tr.Normal * GuthSCP.Config.guthscpbase.ent_break_force * break_force ) then
                count = count + 1
            end
        end
    end

    return count
end

--  concommands
concommand.Add( "guthscpbase_repair_entities", function( ply )
    if IsValid( ply ) and not ply:IsSuperAdmin() then 
		ply:PrintMessage( HUD_PRINTCONSOLE, "You can't use this superadmin command!" )
		return 
	end

	--  repair
	local count = 0
	for ent in pairs( breaked_entities ) do
		GuthSCP.repairEntity( ent )
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

concommand.Add( "guthscpbase_debug_break_at_trace", function( ply )
    if not IsValid( ply ) then 
		return print( "You can't use this non-console command!" ) 
	end
	if not ply:IsSuperAdmin() then
		ply:PrintMessage( HUD_PRINTCONSOLE, "You can't use this superadmin command!" )
		return
	end

	--  break
	local count = GuthSCP.breakEntitiesAtPlayerTrace( ply )
	ply:PrintMessage( HUD_PRINTCONSOLE, count > 0 and "You destroyed " .. count .. " entities!" or "Nothing has been destroyed!" )
end )
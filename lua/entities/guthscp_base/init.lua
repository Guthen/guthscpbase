AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )

include( "shared.lua" )

function ENT:Initialize()
	self:SetModel( self.Model )
	self:PhysicsInit( SOLID_VPHYSICS )
	self:SetMoveType( MOVETYPE_VPHYSICS )
	self:SetSolid( SOLID_VPHYSICS )

    local phys = self:GetPhysicsObject()
	if IsValid( phys ) then
		phys:Wake()
	end

	self:SetUseType( SIMPLE_USE )
end

function ENT:Pick()
	self:EmitSound( "guthen_scp/interact/PickItem2.ogg" )
    self:Remove()
end
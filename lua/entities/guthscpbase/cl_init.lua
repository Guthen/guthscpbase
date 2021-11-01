include( "shared.lua" )

local pickMat = Material( "scp_content/handsymbol2.png" )

local pickable_dist = 100 ^ 2
function ENT:Draw()
	self:DrawModel()

	local ply = LocalPlayer()
	if not ply:Alive() then return end

	local pos = self:GetPos() + Vector( 0, 0, self:OBBMaxs().z + 8 )
	if ply:GetPos():DistToSqr( pos ) > pickable_dist then return end

	local ang = LocalPlayer():EyeAngles()
	ang:RotateAroundAxis( ang:Up(), -90 )
	ang:RotateAroundAxis( ang:Forward(), 90 )
	ang:RotateAroundAxis( ang:Right(), 0 )

	cam.Start3D2D( pos, ang, .85 )
		surface.SetDrawColor( color_white )
		surface.SetMaterial( pickMat )
		surface.DrawTexturedRect( -4, -4, 8, 8 )
	cam.End3D2D()
end
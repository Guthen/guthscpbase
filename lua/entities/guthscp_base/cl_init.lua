include( "shared.lua" )

local symbol_mat = Material( "scp_content/handsymbol2.png" )
local symbol_size = ScreenScale( 20 )

local screen_center = Vector( ScrW(), ScrH(), 0 ) / 2
local screen_center_weight = 0.4

hook.Add( "HUDPaint", "guthscp.entity:draw_hand_symbol", function()
	local ply = LocalPlayer()

	--  get entity
	local entity = ply:GetUseEntity()
	if not IsValid( entity ) or entity.Base ~= "guthscp_base" then return end

	--  get screen pos
	local pos = ( entity:GetPos() + entity:OBBCenter() ):ToScreen()
	if not pos.visible then return end

	--  attract pos to screen center
	pos.x = Lerp( screen_center_weight, pos.x, screen_center.x )
	pos.y = Lerp( screen_center_weight, pos.y, screen_center.y )

	--  draw symbol
	surface.SetDrawColor( color_white )
	surface.SetMaterial( symbol_mat )
	surface.DrawTexturedRect( pos.x - symbol_size / 2, pos.y - symbol_size / 2, symbol_size, symbol_size )
end )
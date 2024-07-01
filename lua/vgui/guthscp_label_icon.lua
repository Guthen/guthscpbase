local PANEL = {}

function PANEL:Init()
	self:SetTall( 22 )
	self:SetClickable( true )
	self:SetCursor( "hand" )

	self.icon = self:Add( "DImage" )
	self.icon:SetSize( 16, 16 )
	self.icon:SetImage( "icon16/brick.png" )

	self.label = self:Add( "DLabel" )
	self.label:Dock( LEFT )
	self.label:DockMargin( 22, 2, 0, 0 )
	self.label:SetDark( true )
	self.label:SetAutoStretchVertical( true )
	function self.label.Paint( label, w, h )
		if not self:IsClickable() or not self:IsHovered() then return end

		--  draw an underline
		surface.SetDrawColor( label:GetColor() )
		surface.DrawLine( 0, h - 1, w, h - 1 )
	end
end

function PANEL:SetIcon( path )
	self.icon:SetImage( path )
end

function PANEL:SetText( text )
	self.label:SetText( text )
	self.label:SizeToContentsX()
end

function PANEL:GetText()
	return self.label:GetText()
end

function PANEL:SetClickable( bool )
	if bool then
		self:SetMouseInputEnabled( true )
	else
		self:SetMouseInputEnabled( false )
	end

	self.is_clickable = bool
end

function PANEL:IsClickable()
	return self.is_clickable
end

function PANEL:OnMouseReleased()
	if not self:IsClickable() then return end

	self:DoClick()
end

function PANEL:DoClick()
	--  to override
end

vgui.Register( "guthscp_label_icon", PANEL, "DSizeToContents" )
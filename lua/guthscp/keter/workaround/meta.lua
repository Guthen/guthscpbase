local WORKAROUND = {
	--  variables
	name = "unknown", --  required!
	realm = -1, --  required!
	
	id = "",

	_is_enabled = false,
	_is_active = false,
}
WORKAROUND.__index = WORKAROUND

--  methods

function WORKAROUND:init()
	return true
end

--  TODO: doc
function WORKAROUND:get_hook( name, id )
	--  list all hooks
	local hooks = hook.GetTable()[name]

	--  set former callback
	if hooks then
		self._former_callback = hooks[id]
	end

	--  check callback validity
	if not self._former_callback then
		self:warning( "hook '%s/%s' wasn't found!", name, id )
		return false
	end

	return true
end

function WORKAROUND:is_enabled()
	return self._is_enabled
end

function WORKAROUND:is_active()
	return self._is_active
end

function WORKAROUND:set_enabled( is_enabled )
	--  checks
	if not self._is_active then 
		self:warning( "unable to toggle when not active!" )
		return 
	end
	if is_enabled == self._is_enabled then return end
	
	--  toggle
	self._is_enabled = is_enabled

	--  invoke event
	if self.realm == guthscp.get_current_realm() then
		if self._is_enabled then
			self:on_enabled()
			self:info( "enabled!" )
		else
			self:on_disabled()
			self:info( "disabled!" )
		end
	end 
	
	--  sync
	--self:sync()
end

function WORKAROUND:sync( ply )
	net.Start( CLIENT and "guthscp.workaround:apply" or "guthscp.workaround:sync" )
	
	--  write data
	net.WriteString( self.id )
	net.WriteBool( self._is_active )
	net.WriteBool( self._is_enabled )

	--  send message
	if CLIENT then
		net.SendToServer()
	elseif ply == nil then
		net.Broadcast()
	else
		net.Send( ply )
	end
end

function WORKAROUND:on_enabled()
end

function WORKAROUND:on_disabled()
end

guthscp.helpers.define_print_methods( WORKAROUND, "workarounds" )
guthscp.workaround.meta = WORKAROUND
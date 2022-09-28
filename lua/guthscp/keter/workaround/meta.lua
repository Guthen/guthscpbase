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

--[[ 
	@function WORKAROUND:init
		| description: called when the workaround is initialized during the hook `InitPostEntity`; 
					   the returned value will be used to set @`WORKAROUND._is_active`, controlling if the workaround could be enabled later on
		| return: <bool> is_active
]]
function WORKAROUND:init()
	return true
end

--[[ 
	@function WORKAROUND:get_hook
		| description: try to retrieve the specified hook, if found, will set the `_former_callback` parameter to its current callback
		| params:
			name: <string> hook name
			id: <any> hook identifier
		| return: <bool> is_found
]]
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

--[[ 
	@function WORKAROUND:set_enabled
		| description: changes enabled state if the workaround is active; WILL do nothing if the new state is the same than the last one
					   if the current realm matches, it WILL call the @`WORKAROUND:on_enabled` or @`WORKAROUND:on_disabled` functions depending of the new state;
					   WILL NOT automatically sync or save to disk, if you want these effects, you should respectively call @`WORKAROUND:sync` & @`guthscp.workaround.save`
		| params:
			is_enabled: <bool> state
]]
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
		self:info( "sync changes to server" )
	elseif ply == nil then
		net.Broadcast()
		self:info( "sync to everyone" )
	else
		net.Send( ply )
		self:info( "sync to %q", ply:GetName() )
	end
end

function WORKAROUND:on_enabled()
end

function WORKAROUND:on_disabled()
end

guthscp.helpers.define_print_methods( WORKAROUND, "workarounds" )
guthscp.workaround.meta = WORKAROUND
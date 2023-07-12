local WORKAROUND = {
	--  variables
	name = "unknown", --  required!
	realm = -1, --  required!
	
	id = "",

	hooks = {},

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
	@function WORKAROUND:register_hook
		| description: try to retrieve the specified hook, if found, will set the `_former_callback` parameter to its current callback
		| params:
			slot: <any> hook index in the register
			name: <string> hook name
			id: <any> hook identifier
		| return: <bool> is_found_and_registered
]]
function WORKAROUND:register_hook( slot, name, id )
	--  list all hooks
	local hooks = hook.GetTable()[name]

	--  set former callback
	local callback
	if hooks then
		callback = hooks[id]
	end

	--  check callback validity
	if not callback then
		self:warning( "hook '%s/%s' wasn't found!", name, id )
		return false
	end

	--  register hook
	self.hooks[slot] = {
		name = name,
		id = id,
		callback = callback,
	}
	return true
end

--[[ 
	@function WORKAROUND:find_hook
		| description: try to find a hook via a custom callback, if found, will call @`WORKAROUND:register_hook` with its identifier
		| params:
			slot: <any> hook index in the register
			name: <string> hook name
			condition: <function( string id, function callback )> callback called on each hook of the event, must return a boolean for registering
		| return: <bool> is_found_and_registered
]]
function WORKAROUND:find_hook( slot, name, condition )
	local hooks = hook.GetTable()[name]
	if not istable( hooks ) then return false end

	--  find the hook
	for id, callback in pairs( hooks ) do
        if condition( id, callback ) then
           	return self:register_hook( slot, name, id )
        end
    end

	return false
end

--[[ 
	@function WORKAROUND:override_hook
		| description: override a registered hook callback
		| params:
			slot: <any> hook index in the register
			callback: <function> new callback
		| return: <bool> is_success
]]
function WORKAROUND:override_hook( slot, callback )
	local _hook = self.hooks[slot]
	if not _hook then return false end

	hook.Add( _hook.name, _hook.id, callback )
	return true
end

--[[ 
	@function WORKAROUND:remove_hook
		| description: delete the callback of a registered hook from the game event system
		| params:
			slot: <any> hook index in the register
		| return: <bool> is_success
]]
function WORKAROUND:remove_hook( slot )
	local _hook = self.hooks[slot]
	if not _hook then return end

	hook.Remove( _hook.name, _hook.id )
	return true
end

--[[ 
	@function WORKAROUND:restore_hook
		| description: restore the first callback of a registered hook
		| params:
			slot: <any> hook index in the register
		| return: <bool> is_success
]]
function WORKAROUND:restore_hook( slot )
	local _hook = self.hooks[slot]
	if not _hook then return end

	hook.Add( _hook.name, _hook.id, _hook.callback )
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
	if guthscp.is_same_realm( self.realm, guthscp.get_current_realm() ) then
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
guthscp.event_handler = guthscp.event_handler or {}

local HANDLER = guthscp.event_handler
HANDLER.__index = HANDLER

--  new
function HANDLER:new()
	local obj = {
		listeners_count = 0,
		listeners = {},
	}

	return setmetatable( obj, HANDLER )
end


--  setters
function HANDLER:add_listener( id, callback )
	if self.listeners[id] then return end

	self.listeners[id] = callback
	self.listeners_count = self.listeners_count + 1
end

function HANDLER:remove_listener( id )
	if not self.listeners[id] then return end

	self.listeners[id] = nil
	self.listeners_count = self.listeners_count - 1
end

function HANDLER:clear()
	self.listeners = {}
	self.listeners_count = 0
end


--  invoke
function HANDLER:invoke( ... )
	for id, callback in pairs( self.listeners ) do
		callback( ... )
	end
end


--  getters
function HANDLER:get_listeners()
	return self.listeners
end

function HANDLER:get_listeners_count()
	return self.listeners_count
end

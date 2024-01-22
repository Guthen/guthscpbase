local MODULE = guthscp.modules.base

guthscp.print_tabs = guthscp.print_tabs + 1

local function unit_testing( name, callback )
	MODULE:info( name )

	guthscp.print_tabs = guthscp.print_tabs + 1
	callback()
	guthscp.print_tabs = guthscp.print_tabs - 1
end

--  guthscp.helpers.compare_versions( current_version, extern_version )
--  see https://semver.org/
unit_testing( "guthscp.helpers.compare_versions", function()
	--  in acsending order
	local tests = {
		"1.0.0-alpha",
		"1.0.0-alpha.1",
		"1.0.0-alpha.beta",
		"1.0.0-beta",
		"1.0.0-beta.2",
		"1.0.0-beta.11",
		"1.0.0-rc.1",
		"1.0.0",
		"1.1.1",
		"1.11.0",
		"1.11.11",
		"1.12.2",
		"2.0.0",
	}

	local current = tests[1]
	for i = 2, #tests do
		local previous = tests[i]
		
		--  test: current < previous
		local result, depth = guthscp.helpers.compare_versions( current, previous )
		if result == -1 then
			MODULE:info( "%q < %q, ok!", current, previous )
		else
			MODULE:error( "%q < %q, failed! returned: %d, %d", current, previous, result, depth )
			break
		end

		--  test: previous > current
		local result, depth = guthscp.helpers.compare_versions( previous, current )
		if result == 1 then
			MODULE:info( "%q > %q, ok!", previous, current )
		else
			MODULE:error( "%q > %q, failed! returned: %d, %d", previous, current, result, depth )
			break
		end

		current = previous
	end
end )


unit_testing( "guthscp.event_handler", function()
	local handler = guthscp.event_handler:new()
	
	handler:add_listener( "#1", function( ... )
		MODULE:info( "#1: %s", table.concat( { ... }, "; " ) )
		handler:remove_listener( "#1" )
	end )
	handler:add_listener( "#2", function( ... )
		MODULE:info( "#2: %s", table.concat( { ... }, "; " ) )
		handler:remove_listener( "#2" )
	end )
	handler:add_listener( "#3", function( ... )
		MODULE:info( "#3: %s", table.concat( { ... }, "; " ) )
		--handler:remove_listener( "#3" )
	end )

	MODULE:info( "first invoke:" )
	guthscp.print_tabs = guthscp.print_tabs + 1
	handler:invoke( 1, "hey are you okay?", "no" )
	guthscp.print_tabs = guthscp.print_tabs - 1

	MODULE:info( "second invoke:" )
	guthscp.print_tabs = guthscp.print_tabs + 1
	handler:invoke( 2, "hey are you still okay?", "no" )
	guthscp.print_tabs = guthscp.print_tabs - 1

	MODULE:info( "third invoke:" )
	guthscp.print_tabs = guthscp.print_tabs + 1
	handler:invoke( 3, "and now??", "yeah" )
	guthscp.print_tabs = guthscp.print_tabs - 1
end )

guthscp.print_tabs = guthscp.print_tabs - 1

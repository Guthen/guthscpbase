local MODULE = guthscp.modules.base

guthscp.print_tabs = guthscp.print_tabs + 1

--  guthscp.helpers.compare_versions( current_version, extern_version )
--  see https://semver.org/
MODULE:info( "guthscp.helpers.compare_versions" )
guthscp.print_tabs = guthscp.print_tabs + 1
do 
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
end
guthscp.print_tabs = guthscp.print_tabs - 1

guthscp.print_tabs = guthscp.print_tabs - 1

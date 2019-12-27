local global_env = {}
setmetatable(global_env, { __index = _G })
setfenv(1, global_env)

--------------------
-- Load Resources --
--------------------

modpath = minetest.get_modpath("libuix")

local static_table = dofile(modpath.."/utility.lua").static_table
local formspec = dofile(modpath.."/formspec/init.lua")

----------------------
-- Global Namespace --
----------------------

setfenv(1, getmetatable(global_env).__index)

-- Creates a new libuix instance for a single mod.
libuix = function(modname)
	assert(minetest.get_modpath(modname), ("libuix: invalid modname '%s'"):format(modname))

	return static_table({
		modname = modname,
		formspec = formspec.manager:new(modname)
	})
end

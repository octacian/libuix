local global_env = {}
setmetatable(global_env, { __index = _G })
setfenv(1, global_env)

--------------------
-- Load Resources --
--------------------

modpath = minetest.get_modpath("libuix")
local UIXInstance = dofile(modpath.."/libuix.lua")

----------------------
-- Global Namespace --
----------------------

setfenv(1, getmetatable(global_env).__index)

-- Creates a new libuix instance for a single mod.
libuix = function(modname)
	assert(minetest.get_modpath(modname), ("libuix: invalid mod name '%s'"):format(modname))
	return UIXInstance:new(modname)
end

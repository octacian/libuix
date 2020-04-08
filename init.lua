local global_env = {}
setmetatable(global_env, { __index = _G })
setfenv(1, global_env)

---------------------
-- Resource Loader --
---------------------

local modpath = minetest.get_modpath("libuix")
local cache = {}
function import(name)
	if cache[name] then return cache[name] end

	local f, err = loadfile(modpath .. "/" .. name)
	if not f then error(err, 2) end
	setfenv(f, getfenv(2))
	cache[name] = f()
	return cache[name]
end

---------------------
-- Global Controls --
---------------------

local UNIT_TEST = os.getenv("UNIT_TEST")
local DEBUG = os.getenv("DEBUG")

if UNIT_TEST == "TRUE" then _G.UNIT_TEST = true else _G.UNIT_TEST = false end
if DEBUG == "TRUE" then _G.DEBUG = true else _G.DEBUG = false end

--------------------
-- Load Resources --
--------------------

local UIXInstance = import("libuix.lua")

----------------------
-- Global Namespace --
----------------------

setfenv(1, getmetatable(global_env).__index)

-- Creates a new libuix instance for a single mod.
libuix = function(modname)
	assert(minetest.get_modpath(modname), ("libuix: invalid mod name '%s'"):format(modname))
	return UIXInstance:new(modname)
end

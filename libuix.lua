local utility = dofile(modpath.."/utility.lua")
local manager = dofile(modpath.."/formspec/manager.lua")

-----------------------
-- UIXInstance Class --
-----------------------

local UIXInstance = utility.make_class("UIXInstance")

function UIXInstance:new(modname)
	utility.enforce_types({"string"}, modname)

	local instance = {modname = modname}
	setmetatable(instance, UIXInstance)
	instance.formspec = manager:new(instance)

	return instance -- TODO: This should use the static_table utility, however, it currently clashes with `make_class`.
end

-------------
-- Exports --
-------------

return UIXInstance

local types = import("types.lua")
local manager = import("formspec/manager.lua")

-----------------------
-- UIXInstance Class --
-----------------------

local UIXInstance = types.type("UIXInstance")

function UIXInstance:new(modname)
	types.force({"string"}, modname)

	local instance = {modname = modname}
	setmetatable(instance, UIXInstance)
	instance.formspec = manager:new(instance)

	return instance -- TODO: This should use the types.static utility, however, it currently clashes with types.type.
end

-------------
-- Exports --
-------------

return UIXInstance

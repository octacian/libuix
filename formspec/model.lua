local types = import("types.lua")

-----------------
-- Model Class --
-----------------

local Model = types.type("Model")

-- Creates a new Model instance.
function Model:new(data)
	types.force({"table"}, data)
	local instance = data
	setmetatable(instance, Model)
	return instance
end

-- Evaluates whatever lies within some key to an integral, boolean-comparable type.
function Model:_evaluate(key)
	if type(self[key]) == "function" then
		return self[key](self)
	else
		return self[key]
	end
end

-------------
-- Exports --
-------------

return Model

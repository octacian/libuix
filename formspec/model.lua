local utility = dofile(modpath.."/utility.lua")

-----------------
-- Model Class --
-----------------

local Model = {}
Model.__index = Model

-- Creates a new Model instance.
function Model:new(data)
	utility.enforce_types({"table"}, data)
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

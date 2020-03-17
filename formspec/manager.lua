local utility = dofile(modpath.."/utility.lua")

local Form = dofile(modpath.."/formspec/form.lua")
local Model = dofile(modpath.."/formspec/model.lua")
local Elements = dofile(modpath.."/formspec/elements.lua")

---------------------------
-- FormspecManager Class --
---------------------------

local FormspecManager = utility.make_class("FormspecManager")

-- Creates a new FormspecManager instance.
function FormspecManager:new(parent)
	utility.enforce_types({"UIXInstance"}, parent)
	local instance = { parent = parent, forms = {} }
	setmetatable(instance, FormspecManager)

	instance.elements = Elements(instance)
	setmetatable(instance.elements, { __index = _G })

	return instance
end

-- Collects formspec name, elements, and model for addition to the instance.
function FormspecManager:__call(name)
	-- Add element functions to the global environment.
	setfenv(2, self.elements)

	-- Accept options, including size and the `fixed_size` and `no_prepend` controls.
	return function(options)
		-- Accept elements table.
		return function(elements)
			-- Accept data model table.
			return function(model)
				setfenv(2, getmetatable(self.elements).__index) -- Remove Elements from the global environment.
				table.insert(self.forms, Form:new(self, name, options, elements, Model:new(model)))
			end
		end
	end
end

-- Gets a formspec by name from the instance.
function FormspecManager:get(name)
	utility.enforce_types({"string"}, name)
	for _, form in ipairs(self.forms) do
		if form.name == name then
			return form
		end
	end
end

-- Gets a formspec index by name from the instance.
function FormspecManager:get_index(name)
	utility.enforce_types({"string"}, name)
	for index, form in ipairs(self.forms) do
		if form.name == name then
			return index
		end
	end
end

-- TODO: Handle formspec submissions.

-------------
-- Exports --
-------------

return FormspecManager

local utility = import("utility.lua")
local Variation = import("formspec/element/variation.lua")

-------------------
-- Element Class --
-------------------

local Element = utility.make_class("Element")

-- Creates a new skeleton instance of the element.
function Element:new(parent, name)
	if utility.DEBUG then utility.enforce_types({"FormspecManager", "string"}, parent, name) end

	local instance = {
		parent = parent,
		name = name,
		variations = {}
	}

	setmetatable(instance, Element)
	return instance
end

-- Adds a variation to the element.
function Element:add_variation(fields, options, child_elements)
	if utility.DEBUG then utility.enforce_types({"table", "table?", "table?"}, fields, options, child_elements) end
	self.variations[#self.variations + 1] = Variation:new(self.parent, self.name, fields, options, child_elements)
end

local element_call_err = utility.ErrorBuilder:new("Element", 2)
-- Chooses a single variation based on an arbitrary definition and returns it directly.
function Element:__call(def)
	if utility.DEBUG then utility.enforce_types({"table"}, def) end

	element_call_err:set_postfix(function()
		return ("%s\n\nAvailable Variations: %s"):format(dump(def), dump(self.variations))
	end)

	-- Loop over variations and try to find one that accepts the definition as valid.
	local variation = table.foreach(self.variations, function(variation)
		local ok, variation_instance = pcall(function()
			return variation(def)
		end)

		if ok then return variation_instance end
	end)

	-- if no variation accepted the definition, throw an error
	element_call_err:assert(variation, "no variation of %s matches the definition", self.name)

	return variation
end

-------------
-- Exports --
-------------

return Element

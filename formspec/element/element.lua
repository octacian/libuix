local ErrorBuilder = import("errors.lua")
local types = import("types.lua")
local tables = import("tables.lua")
local Variation = import("formspec/element/variation.lua")

-------------------
-- Element Class --
-------------------

local Element = types.type("Element")

-- Creates a new skeleton instance of the element.
function Element:new(parent, name)
	if DEBUG then types.force({"FormspecManager", "string"}, parent, name) end

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
	if DEBUG then types.force({"table", "table?", "table?"}, fields, options, child_elements) end
	self.variations[#self.variations + 1] = Variation:new(self.parent, self.name, fields, options, child_elements)
end

local element_call_err = ErrorBuilder:new("Element", 2)
-- Chooses a single variation based on an arbitrary definition and returns it directly.
function Element:__call(def)
	if DEBUG then types.force({"table"}, def) end

	element_call_err:set_postfix(function()
		return ("%s\n\nAvailable Variations: %s"):format(tables.dump(def), tables.dump(self.variations))
	end)

	-- Loop over variations and try to find one that accepts the definition as valid.
	local variation = tables.foreach(self.variations, function(variation)
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

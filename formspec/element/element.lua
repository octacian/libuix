local utility = dofile(modpath.."/utility.lua")
local Variation = dofile(modpath.."/formspec/element/variation.lua")

-------------------
-- Element Class --
-------------------

local Element = utility.make_class("Element")

-- Creates a new instance of the element.
function Element:new(parent, name)
	utility.enforce_types({"FormspecManager", "string"}, parent, name)

	local instance = {
		parent = parent,
		name = name,
		variations = {}
	}

	setmetatable(instance, Element)
	return instance
end

-- Adds a variation to the element.
function Element:add_variation(fields, options)
	utility.enforce_types({"table", "table?"}, fields, options)
	table.insert(self.variations, Variation:new(self, fields, options))
end

-- Returns a new instance of the element, choosing the correct variation based on the
-- definition argument, or throwing an error if no variations match the definition.
function Element:__call(def)
	utility.enforce_types({"table"}, def)
	local instance = Element:new(self.parent, self.name)

	instance.variation = table.foreach(self.variations, function(variation)
		local variation_instance = variation(def)
		local ok, valid = pcall(function()
			return variation_instance:validate()
		end)

		if ok and valid then return variation_instance end
	end)

	assert(instance.variation, ("element('%s'): no variation match for definition: %s Available variations: %s"):format(
		self.name, dump(def), dump(self.variations)))

	return instance
end

-- Allows the chosen variation instance to be indexed.
function Element:__index(key)
	utility.enforce_types({"string"}, key)

	local value = rawget(Element, key); if value then
		return value
	end value = rawget(self, "variation"); if value then
		local raw_variation = rawget(self, "variation")
		local raw_value = raw_variation[key]
		if type(raw_value) == "function" then
			return function(...)
				local arg = {...}
				local include_self = false
				if #arg > 0 and tostring(arg[1]) == tostring(self) then
					include_self = true
					table.remove(arg, 1)
				end

				if include_self then
					return raw_value(raw_variation, unpack(arg))
				else
					return raw_value(unpack(arg))
				end
			end
		end

		return raw_value
	end
end

-------------
-- Exports --
-------------

return Element

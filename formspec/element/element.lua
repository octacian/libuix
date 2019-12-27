dofile(modpath.."/utility.lua")

local Variation = dofile(modpath.."/formspec/element/variation.lua")

-------------------
-- Element Class --
-------------------

local Element = {}

-- Creates a new instance of the element.
function Element:new(name)
	local instance = {
		name = name,
		variations = {}
	}

	setmetatable(instance, Element)
	return instance
end

-- Adds a variation to the element.
function Element:add_variation(fields, options)
	table.insert(self.variations, Variation:new(self.name, fields, options))
end

-- Returns a new instance of the element, choosing the correct variation based
-- on the definition argument, or throwing an error if the definition is invalid.
function Element:__call(def)
	local instance = Element:new(self.name)

	instance.instance = table.foreach(self.variations, function(variation)
		local variation_instance = variation(def)
		local ok, valid = pcall(function()
			return variation_instance:validate()
		end)
		--print("ok - " .. tostring(ok) .. "; valid - " .. tostring(valid) .. "\n")
		if ok and valid then return variation_instance end
	end)

	assert(instance.instance, ("element('%s'): no variation match for definition: %s Available variations: %s"):format(
		self.name, dump(def), dump(self.variations)))

	return instance
end

-- Allows the chosen variation instance to be indexed.
function Element:__index(key)
	-- TODO: I may need to replace my class system with separate constructor, metatable, and method definitions.
	-- self[key] and iteration cause stack overflows.
	local value = rawget(Element, key); if value then
		return value
	elseif rawget(self, key) then
		return rawget(self, key)
	elseif rawget(self, "instance") then
		return rawget(self, "instance")[key]
	end
end

-------------
-- Exports --
-------------

return Element

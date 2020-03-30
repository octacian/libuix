local utility = import("utility.lua")
local Variation = import("formspec/element/variation.lua")
local Element = import("formspec/element/element.lua")

-- Default field definitions.
local default_fields = {
	x = {"x", "number", separator = ","},
	y = {"y", "number"},
	w = {"w", "number", separator = ","},
	h = {"h", "number"},
	_if = {"_if", "string", required = false, internal = true}
}

-------------------
-- Builder Class --
-------------------

local Builder = utility.make_class("Builder")
Builder.default_fields = default_fields -- Defaults for use when defining elements

-- Creates a new builder instance with its own element store.
function Builder:new(parent)
	if utility.DEBUG then utility.enforce_types({"FormspecManager"}, parent) end

	local instance = {
		parent = parent,
		elements = {}, -- Elements manage variations; referenced by name.
	}

	setmetatable(instance, Builder)
	return instance
end

---------------------
-- Primary Builder --
---------------------

local insert = table.insert
-- Adds a generic element to the builder.
function Builder:add(name, positioned, resizable, fields, options)
	if utility.DEBUG then utility.enforce_types({"string", "boolean", "boolean", "table?", "table?"},
		name, positioned, resizable, fields, options) end

	if not fields then fields = {} end

	if positioned then
		insert(fields, 1, default_fields.x)
		insert(fields, 2, default_fields.y)
	end

	if resizable then
		local location = positioned and 3 or 1
		insert(fields, location, default_fields.w)
		insert(fields, location + 1, default_fields.h)
	end

	insert(fields, default_fields._if)

	-- if this is a new element, insert a Variation instance
	if not self.elements[name] then
		self.elements[name] = Variation:new(self.parent, name, fields, options)
		return
	-- if this element already exists but there is only a Variation entry, convert it to an Element
	elseif self.elements[name] and utility.type(self.elements[name]) == "Variation" then
		local element = Element:new(self.parent, name)
		element:add_variation(self.elements[name].fields, self.elements[name].options)
		self.elements[name] = element
	end

	self.elements[name]:add_variation(fields, options)
end

-------------
-- Aliases --
-------------

-- Creates a generic element with no defaults.
function Builder:element(name, fields, options)
	self:add(name, false, false, fields, options)
end

-- Creates an element with positioning defaults (x and y).
function Builder:positioned(name, fields, options)
	self:add(name, true, false, fields, options)
end

-- Creates an element with width and height defaults.
function Builder:resizable(name, fields, options)
	self:add(name, false, true, fields, options)
end

-- Creates an element with position, width, and height defaults.
function Builder:rect(name, fields, options)
	self:add(name, true, true, fields, options)
end

-------------
-- Exports --
-------------

return Builder

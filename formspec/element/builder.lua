local utility = dofile(modpath.."/utility.lua")
local Element = dofile(modpath.."/formspec/element/element.lua")

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
	utility.enforce_types({"FormspecManager"}, parent)

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

-- Adds a generic element to the builder.
function Builder:add(name, positioned, resizable, fields, options)
	utility.enforce_types({"string", "boolean", "boolean", "table?", "table?"},
		name, positioned, resizable, fields, options)

	if not fields then fields = {} end

	if positioned then
		table.insert(fields, 1, default_fields.x)
		table.insert(fields, 2, default_fields.y)
	end

	if resizable then
		local location = positioned and 3 or 1
		table.insert(fields, location, default_fields.w)
		table.insert(fields, location + 1, default_fields.h)
	end

	table.insert(fields, default_fields._if)

	if not self.elements[name] then
		self.elements[name] = Element:new(self.parent, name)
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

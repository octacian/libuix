local utility = import("utility.lua")

----------------
-- Form Class --
----------------

local Form = utility.make_class("Form")

-- Creates a new Form instance.
function Form:new(parent, name, options, elements, model)
	if utility.DEBUG then
		utility.enforce_types({"FormspecManager", "string", "table", "table", "Model"},
			parent, name, options, elements, model)
		utility.enforce_array(elements, "Variation")

		table.constrain(options, {
			{"formspec_version", "number", required = false},
			{"w", "number"},
			{"h", "number"},
			{"fixed_size", "boolean", required = false},
			{"position", "table", required = false},
			{"anchor", "table", required = false},
			{"no_prepend", "boolean", required = false},
			{"real_coordinates", "boolean", required = false}
		})
		if options.position then table.constrain(options.position, {{"x", "number"}, {"y", "number"}}) end
		if options.anchor then table.constrain(options.anchor, {{"x", "number"}, {"y", "number"}}) end
	end

	local instance = {
		parent = parent,
		name = name,
		options = options,
		elements = elements,
		model = model,
		last_id = -1
	}
	setmetatable(instance, Form)
	return instance
end

-- Returns a new numerical ID unique to this form.
function Form:new_id()
	self.last_id = self.last_id + 1
	return self.last_id
end

-- Renders the form, returning a Minetest-compatible formspec string.
function Form:render()
	local formstring = ""
	local options = self.options

	-- Handle formspec version option
	if options.formspec_version then
		formstring = formstring .. ("formspec_version[%d]"):format(options.formspec_version)
	end

	-- Handle size options
	formstring = formstring .. ("size[%d,%d%s]"):format(options.w, options.h, options.fixed_size and (",%s")
		:format(tostring(options.fixed_size)) or "")

	-- Handle position option
	if options.position then
		formstring = formstring .. ("position[%d,%d]"):format(options.position.x, options.position.y)
	end

	-- Handle anchor option
	if options.anchor then
		formstring = formstring .. ("anchor[%d,%d]"):format(options.anchor.x, options.anchor.y)
	end

	-- Handle no prepend option
	if options.no_prepend then
		formstring = formstring .. "no_prepend[]"
	end

	-- Handle real coordinates option
	local real_coordinates = true
	if options.real_coordinates ~= nil then real_coordinates = options.real_coordinates end
	formstring = formstring .. ("real_coordinates[%s]"):format(tostring(real_coordinates))

	-- Render all formspec elements
	for _, element in pairs(self.elements) do
		formstring = formstring .. element:render(self)
	end

	return formstring
end

local show_err = utility.ErrorBuilder:new("Form:show", 2)
-- Shows the form to a player who is identified by name.
function Form:show(player_name)
	if utility.DEBUG then utility.enforce_types({"string"}, player_name) end

	local formstring = self:render()
	show_err:assert(formstring ~= "", "formspec %s:%s contains no elements", self.parent.parent.modname, self.name)

	minetest.show_formspec(player_name, self.parent.parent.modname .. ":" .. self.name, formstring)
end

-------------
-- Exports --
-------------

return Form

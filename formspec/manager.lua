local utility = dofile(modpath.."/utility.lua")

local Model = dofile(modpath.."/formspec/model.lua")
local Elements = dofile(modpath.."/formspec/elements.lua")
setmetatable(Elements, { __index = _G })

---------------------------
-- FormspecManager Class --
---------------------------

local FormspecManager = {}
FormspecManager.__index = FormspecManager

-- Creates a new FormspecManager instance.
function FormspecManager:new(modname)
	utility.enforce_types({"string"}, modname)
	local instance = { modname = modname, forms = {} }
	setmetatable(instance, FormspecManager)
	return instance
end

-- Collects formspec name, elements, and model for addition to the instance.
function FormspecManager:__call(name)
	utility.enforce_types({"string"}, name)
	-- Add element functions to the global environment.
	setfenv(2, Elements)

	-- Accept options, including size and the `fixed_size` and `no_prepend` controls.
	return function(options)
		-- Accept elements table.
		return function(elements)
			-- Accept data model table.
			return function(model)
				utility.enforce_types({"table", "table", "table"}, options, elements, model)
				setfenv(2, getmetatable(Elements).__index) -- Remove Elements from the global environment.
				self:add(name, options, elements, model)
			end
		end
	end
end

-- Adds a formspec to the instance.
function FormspecManager:add(name, options, elements, model)
	utility.enforce_types({"string", "table", "table", "table"}, name, options, elements, model)
	assert(not self:get_index(name), ("libuix().formspec: form '%s' already exists"):format(name))
	table.constrain(options, {
		{"w", "number"},
		{"h", "number"}
	})

	table.insert(self.forms, {
		name = name,
		options = options,
		elements = elements,
		model = Model:new(model)
	})
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

-- Renders a formspec identified by name, returning a Minetest-compatible
-- formspec string unless the name refers to a non-existent formspec.
function FormspecManager:render(name, real_coordinates)
	utility.enforce_types({"string", "boolean?"}, name, real_coordinates)

	local form = self:get(name)
	if not form then return end

	local formstring = ""
	-- TODO: Move `real_coordinates` control to formspec options
	if real_coordinates ~= false then
		formstring = "real_coordinates[true]"
	end

	formstring = formstring .. "size[" .. tostring(form.options.w) .. "," .. tostring(form.options.h)
	if form.options.fixed_size then formstring = formstring .. ",true]"
	else formstring = formstring .. "]" end

	for _, element in pairs(form.elements) do
		formstring = formstring .. element:render(form.model)
	end

	if form.options.no_prepend then formstring = formstring .. "no_prepend[]" end

	return formstring
end

-- Shows a formspec to a player, both identified by name.
function FormspecManager:show(form_name, player_name)
	utility.enforce_types({"string", "string"}, form_name, player_name)

	local formstring = self:render(form_name)
	assert(formstring, ("libuix().formspec['%s']:show: formspec does not exist or contains no elements"):format(form_name))

	minetest.show_formspec(player_name, self.modname .. ":" .. form_name, formstring)
end

-- TODO: Handle formspec submissions.

-------------
-- Exports --
-------------

return FormspecManager

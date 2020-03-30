local utility = dofile(modpath.."/utility.lua")

---------------------
-- Variation Class --
---------------------

local Variation = utility.make_class("Variation")

-- Creates a new skeleton instance of the variation.
function Variation:new(parent, name, fields, options)
	if utility.DEBUG then
		utility.enforce_types({"FormspecManager", "string", "table", "table?"}, parent, name, fields, options)

		if options then
			table.constrain(options, {
				{"contains", "string", required = false},
				{"render_name", "string|function", required = false},
				{"render_append", "string|function", required = false}
			})
		end
	end

	local instance = {
		parent = parent,
		name = name,
		fields = fields,
		options = options
	}

	setmetatable(instance, Variation)
	return instance
end

-- Duplicates and populates a skeleton instance with an arbitrary definition, returning the newly created duplicate.
function Variation:populate_new(def, items)
	if utility.DEBUG then utility.enforce_types({"table", "table?"}, def, items) end
	local instance = Variation:new(self.parent, self.name, self.fields, self.options)
	instance.def = def
	instance.items = items
	instance.field_map = instance:map_fields()
	instance:validate()
	return instance
end

-- Collects definition and, if enabled, a list of contained items.
function Variation:__call(def)
	if self.options and self.options.contains then
		-- Add element functions to the global environment if contained items should be elements.
		if self.options.contains == "Variation" then
			setfenv(2, self.parent.elements)
		end

		return function(items)
			if utility.DEBUG then utility.enforce_array(items, self.options.contains) end
			setfenv(2, getmetatable(self.parent.elements).__index) -- Remove Elements from the global environment.
			return self:populate_new(def, items)
		end
	end

	return self:populate_new(def)
end

-- Returns a map of the indexes of the fields array to the indexes of the definition. Must be called before validate.
function Variation:map_fields()
	local field_map = {}
	local positional_keys_used = 0
	for index, field in pairs(self.fields) do
		local def_key = field[1]
		local def_field = self.def[def_key]

		-- if def_field is nil, the field may have been passed as a positional entry
		if def_field == nil then
			positional_keys_used = positional_keys_used + 1
			def_key = positional_keys_used
			def_field = self.def[positional_keys_used]
		end

		if def_field ~= nil then
			field_map[index] = def_key
		end
	end

	return field_map
end

-- Validates a definition table to variation constraints. Must be called after map_fields.
function Variation:validate()
	for index, field in pairs(self.fields) do
		local def_field = self.def[self.field_map[index]]

		-- if def_field is still nil, the field wasn't defined, throw an error
		if def_field == nil and field.required ~= false and field.hidden ~= true then
			error(("validate: %s property '%s' is not optional"):format(self.name, field[1]))
		end

		-- if the value of the data stored in the definition field does not match the expected type, throw an error
		if def_field ~= nil and type(def_field) ~= field[2] then
			error(("validate: %s property '%s' must be a %s (found '%s')")
				:format(self.name, field[1], field[2], type(def_field)))
		end

		-- if the variation requires a specific value, check it and throw an error if it isn't satisfied
		if field[3] and def_field ~= field[3] then
			error(("validate: %s property '%s' must be a %s with value %s (found %s with value %s)")
				:format(self.name, field[1], field[2], dump(field[3]), type(def_field), dump(def_field)))
		end
	end

	local inverted_map = table.invert(self.field_map)
	-- Loop over definition to check for extra keys
	for def_key, _ in pairs(self.def) do
		if not inverted_map[def_key] or self.fields[inverted_map[def_key]].hidden then
			error(("validate: %s does not support property '%s'"):format(self.name, def_key))
		end
	end

	return true
end

-- Renders a variation given a data model.
function Variation:render(model)
	if utility.DEBUG then utility.enforce_types({"table?"}, model) end

	-- Obey _if visibility control.
	if self.def._if and not model:_evaluate(self.def._if) then
		return ""
	end

	local fieldstring = ""
	for index, field in pairs(self.fields) do
		if field.internal ~= true then
			local def_index = self.field_map[index]
			local value = self.def[def_index]
			if value == nil then value = "" end
			local separator = field.separator
			if separator == nil then separator = ";" end
			fieldstring = fieldstring .. tostring(value) .. separator
		end
	end

	fieldstring = fieldstring:sub(1, -2)

	local contained = ""
	local name = self.name
	local append = ""
	-- if there are options defined, investigate them
	if self.options then
		-- if the element is a container, render items
		if self.options.contains then
			if self.options.contains == "Variation" then
				for _, item in ipairs(self.items) do
					contained = contained .. item:render(model)
				end
			else error("elements containing non-Variation types are not yet supported") end

			contained = contained .. self.name .. "_end[]"
		end

		-- if a custom render name is defined, evaluate it
		if self.options.render_name then
			name = utility.evaluate_string(self.options.render_name, function(value)
				error(("render: %s render_name function must return a string (found %s)"):format(self.name, type(value)))
			end, self)
		end

		-- if a string or function is defined to be appended, evaluate it
		if self.options.render_append then
			append = utility.evaluate_string(self.options.render_append, function(value)
				error(("render: %s render_append function must return a string (found %s)"):format(self.name, type(value)))
			end, self)
		end
	end

	return name .. "[" .. fieldstring .. "]" .. contained .. append
end

-------------
-- Exports --
-------------

return Variation

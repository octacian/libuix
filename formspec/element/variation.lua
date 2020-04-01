local utility = import("utility.lua")

---------------------
-- Variation Class --
---------------------

local Variation = utility.make_class("Variation")

-- Creates a new skeleton instance of the variation.
function Variation:new(parent, name, fields, options, child_elements)
	if utility.DEBUG then
		utility.enforce_types({"FormspecManager", "string", "table", "table?", "table?"},
			parent, name, fields, options, child_elements)

		if options then
			table.constrain(options, {
				{"contains", "table", required = false},
				{"render_name", "string|function", required = false},
				{"render_append", "string|function", required = false},
				{"render_raw", "boolean", required = false}
			})

			if options.contains then
				table.constrain(options.contains, {
					{"validate", "string|function"},
					{"environment", "table|function", required = false},
					{"render", "function"},
					{"render_target", "string", required = false}
				})

				if options.contains.render_target then
					local found = false
					for _, field in pairs(fields) do
						if field[1] == options.contains.render_target then
							found = true
						end
					end

					if not found then
						error(("variation: %s render_target '%s' does not exist"):format(name, options.contains.render_target))
					end
				end
			end
		end
	end

	local instance = {
		parent = parent,
		name = name,
		fields = fields,
		options = options,
		child_elements = child_elements
	}

	setmetatable(instance, Variation)
	return instance
end

-- Duplicates and populates a skeleton instance with an arbitrary definition, returning the newly created duplicate.
function Variation:populate_new(def, items)
	if utility.DEBUG then utility.enforce_types({"table", "table?"}, def, items) end
	local instance = Variation:new(self.parent, self.name, self.fields, self.options)
	instance.def = def
	instance.generated_def = {}
	setmetatable(instance.def, { __index = instance.generated_def })
	instance.items = items
	instance.field_map = instance:map_fields()
	instance:validate()
	return instance
end

-- Collects definition and, if enabled, a list of contained items.
function Variation:__call(def)
	if self.options and self.options.contains then
		-- if the environment table is actually a function, call it
		if type(self.options.contains.environment) == "function" then
			self.options.contains.environment = self.options.contains.environment(self)
		end

		-- if an environment table is provided, add it to the global environment
		if self.options.contains.environment then
			setmetatable(self.options.contains.environment, { __index = _G })
			setfenv(2, self.options.contains.environment)
		end

		return function(items)
			if utility.DEBUG then
				if type(self.options.contains.validate) == "string" then
					utility.enforce_array(items, self.options.contains.validate)
				else
					self.options.contains.validate(self, items)
				end
			end

			-- if an environment table is provided, remove it from the global environment
			if self.options.contains.environment then
				setfenv(2, getmetatable(self.options.contains.environment).__index)
			end

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
		if def_field == nil and field.required ~= false and field.hidden ~= true and field.generate ~= true then
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

-- Renders a variation given a form as context.
function Variation:render(form)
	if utility.DEBUG then utility.enforce_types({"Form"}, form) end

	-- Obey _if visibility control.
	if self.def._if and not form.model:_evaluate(self.def._if) then
		return ""
	end

	local contained = ""
	-- if the variant contains items, render them
	if self.options and self.options.contains then
		contained = self.options.contains.render(self, form)
	end

	local handle_container_target = self.options and self.options.contains and self.options.contains.render_target
	local fieldstring = ""
	for index, field in pairs(self.fields) do
		local separator = field.separator
		if separator == nil then separator = ";" end

		if handle_container_target and self.options.contains.render_target == field[1] then
			fieldstring = fieldstring .. contained .. separator
			handle_container_target = false
			contained = ""
		elseif field.internal ~= true then
			local def_index = self.field_map[index]
			local value = self.def[def_index]
			if field.generate and (field.hidden or value == nil) then
				self.generated_def[field[1]] = tostring(form:new_id())
				value = self.generated_def[field[1]]
			elseif value == nil then value = "" end
			fieldstring = fieldstring .. tostring(value) .. separator
		end
	end

	fieldstring = fieldstring:sub(1, -2)

	local name = self.name
	local append = ""
	-- if there are options defined, investigate them
	if self.options then
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

		-- if the raw render mode is enabled, return immediately
		if self.options.render_raw then
			return fieldstring .. contained .. append
		end
	end

	return name .. "[" .. fieldstring .. "]" .. contained .. append
end

-------------
-- Exports --
-------------

return Variation

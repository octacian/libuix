local utility = import("utility.lua")
local Placeholder = import("placeholder.lua")

---------------------
-- Variation Class --
---------------------

local Variation = utility.make_class("Variation")

local new_err = utility.ErrorBuilder:new("Variation:new")
-- Creates a new skeleton instance of the variation.
function Variation:new(parent, name, fields, options, child_elements)
	if options and options.contains and not options.contains.environment_namespace then
		options.contains.environment_namespace = "ui"
	end

	local instance = {
		parent = parent,
		name = name,
		fields = fields,
		options = options,
		child_elements = child_elements,
		field_names = {}
	}
	setmetatable(instance, Variation)

	if utility.DEBUG then
		utility.enforce_types({"FormspecManager", "string", "table", "table?", "table?"},
			parent, name, fields, options, child_elements)

		if options then
			table.constrain(options, {
				{"contains", "table", required = false},
				{"render_name", "string|function", required = false},
				{"render_append", "string|function", required = false},
				{"render_raw", "boolean", required = false},
				{"receive_fields", "table", required = false}
			})

			if options.receive_fields then
				table.constrain(options.receive_fields, {
					{"callback", "string|function"},
					{"pass_field", "boolean", required = false}
				})
			end

			if options.contains then
				table.constrain(options.contains, {
					{"validate", "string|function"},
					{"environment", "table|function", required = false},
					{"environment_namespace", "string", required = false},
					{"environment_ready", "boolean", required = false},
					{"render", "function"},
					{"render_target", "string", required = false},
					{"bind_model", "boolean", required = false}
				})

				if options.contains.render_target and not instance:get_field_by_name(options.contains.render_target) then
					new_err:throw("%s contains no fields matching render_target '%s'", name, options.contains.render_target)
				end
			end
		end
	end

	return instance
end

-- Returns a field by name.
function Variation:get_field_by_name(name)
	if self.field_names[name] then return self.fields[self.field_names[name]] end

	for index, field in pairs(self.fields) do
		if field[1] == name then
			self.field_names[name] = index
			return field
		end
	end
end

-- Duplicates and populates a skeleton instance with an arbitrary definition, returning the newly created duplicate.
function Variation:populate_new(def, items)
	if utility.DEBUG then utility.enforce_types({"table", "table?"}, def, items) end
	local instance = Variation:new(self.parent, self.name, self.fields, self.options)
	instance.def = def
	instance.generated_def = {}
	setmetatable(instance.def, { __index = instance.generated_def })
	instance.items = items
	instance:map_fields()
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

		local original_env
		-- if an environment table is provided, add it to the global environment
		if self.options.contains.environment then
			if not self.options.contains.environment_ready then
				-- if the environment namepsace is not disabled, nest the environment in a namespace
				if self.options.contains.environment_namespace ~= "" then
					local env = self.options.contains.environment
					self.options.contains.environment = {}
					self.options.contains.environment[self.options.contains.environment_namespace] = env
				end

				-- if model binding is not explicity disabled, add Placeholder listeners to the environment
				if self.options.contains.bind_model ~= false then
					Placeholder.new_listener(self.options.contains.environment)
				else -- otherwise, inherit the entire global environment
					setmetatable(self.options.contains.environment, { __index = _G })
				end

				self.options.contains.environment_ready = true
			end

			original_env = getfenv(2)
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
				setfenv(2, original_env)
			end

			return self:populate_new(def, items)
		end
	end

	return self:populate_new(def)
end

-- Maps field indexes to definition keys, definition keys to field indexes, and field names to field indexes. Must be
-- called before validate.
function Variation:map_fields()
	self.field_map = {}
	self.def_map = {}
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
			self.field_map[index] = def_key
			self.def_map[def_key] = index
		end

		self.field_names[field[1]] = index
	end
end

local validate_err = utility.ErrorBuilder:new("Variation:validate")
-- Validates a definition table to variation constraints. Must be called after map_fields.
function Variation:validate()
	for index, field in pairs(self.fields) do
		local def_field = self.def[self.field_map[index]]

		-- if def_field is still nil, the field wasn't defined, throw an error
		if def_field == nil and field.required ~= false and field.hidden ~= true and field.generate ~= true then
			validate_err:throw("%s property '%s' is not optional", self.name, field[1])
		end

		-- if the field was defined and it is hidden, throw an error
		if def_field ~= nil and field.hidden then
			validate_err:throw("%s property '%s' is hidden and cannot be given a value", self.name, field[1])
		end

		-- if the value is a function or Placeholder, we can just ignore it
		if not utility.check_type(def_field, "function|Placeholder") then
			-- if the value of the data stored in the definition field does not match the expected type, throw an error
			if def_field ~= nil and type(def_field) ~= field[2] then
				validate_err:throw("%s property '%s' must be a %s (found %s)", self.name, field[1], field[2], type(def_field))
			end

			-- if the variation requires a specific value, check it and throw an error if it isn't satisfied
			if field[3] and def_field ~= field[3] then
				validate_err:throw("%s property '%s' must be a %s with value %s (found %s with value %s)", self.name, field[1],
					field[2], dump(field[3]), type(def_field), dump(def_field))
			end
		end
	end

	-- Loop over definition to check for extra keys
	for def_key, _ in pairs(self.def) do
		if not self.def_map[def_key] then
			validate_err:throw("%s does not support property '%s'", self.name, def_key)
		end
	end

	return true
end

local evaluate_env = {
	eq = Placeholder.is.eq, ne = Placeholder.is.ne, lt = Placeholder.is.lt, gt = Placeholder.is.gt, le = Placeholder.is.le,
	ge = Placeholder.is.ge, land = Placeholder.logical.l_and, lor = Placeholder.logical.l_or,
	lnot = Placeholder.logical.l_not
}
local function_call_env = {}
setmetatable(evaluate_env, { __index = _G })
setmetatable(function_call_env, { __index = _G })
local evaluate_err = utility.ErrorBuilder:new("Variation:evaluate")
-- Takes the index of a field in self.fields and returns the corresponding value from the definition. If the value is a
-- placeholder or function the value is extracted and checked for validity. If the value is nil and the field is to be
-- generated, a new ID is fetched from the parent form. An error is thrown if anything is invalid.
function Variation:evaluate(form, field_index)
	if utility.DEBUG then utility.enforce_types({"Form", "number"}, form, field_index) end

	local field_def = self.fields[field_index]
	local value = self.def[self.field_map[field_index]]
	evaluate_env.model = form.model
	function_call_env.model = form.model

	-- if the value is a placeholder, evaluate it until it isn't
	while utility.type(value) == "Placeholder" do
		value = Placeholder.evaluate(evaluate_env, value, function_call_env)
	end

	-- if the value should be generated, fetch a new ID from the parent form and return immediately
	if field_def.generate and (field_def.hidden or value == nil) then
		self.generated_def[field_def[1]] = tostring(form:new_id())
		return self.generated_def[field_def[1]]
	end

	-- if the value is nil and the field is required, throw an error
	if value == nil and field_def.required ~= false and field_def.hidden ~= true then
		evaluate_err:throw("%s property '%s' evaluated to nil but the property is not optional", self.name, field_def[1])
	end

	-- if the new value does not match the expected type, throw an error
	if value ~= nil and type(value) ~= field_def[2] then
		evaluate_err:throw("%s property '%s' evaluated to a %s but the property requires a %s", self.name, field_def[1],
			type(value), field_def[2])
	end

	-- if a specific value is required, check it and throw an error if it isn't satisfied
	if field_def[3] and value ~= field_def[3] then
		evaluate_err:throw("%s property '%s' evaluated to a %s with value %s but the property requires a %s with value %s",
			self.name, field_def[1], type(value), dump(value), field_def[2], field_def[3])
	end

	if value == nil then return ""
	else return value end
end

-- Takes a field name and returns the corresponding value from the definition. Returns nil, false if the field doesn't
-- exist. If it exists, evaluate_by_name returns the value, true.
function Variation:evaluate_by_name(form, field_name)
	if utility.DEBUG then utility.enforce_types({"Form", "string"}, form, field_name) end

	for index, field in pairs(self.fields) do
		if field[1] == field_name then
			return self:evaluate(form, index), true
		end
	end

	return nil, false
end

local render_err = utility.ErrorBuilder:new("Variation:render")
-- Renders a variation given a form as context.
function Variation:render(form)
	if utility.DEBUG then utility.enforce_types({"Form"}, form) end

	-- Obey visibility control.
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
			fieldstring = fieldstring .. tostring(self:evaluate(form, index)) .. separator
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
				render_err:throw("%s render_name function must return a string (found %s)", self.name, type(value))
			end, self)
		end

		-- if a string or function is defined to be appended, evaluate it
		if self.options.render_append then
			append = utility.evaluate_string(self.options.render_append, function(value)
				render_err:throw("%s render_append function must return a string (found %s)", self.name, type(value))
			end, self)
		end

		-- if the raw render mode is enabled, return immediately
		if self.options.render_raw then
			return fieldstring .. contained .. append
		end
	end

	return name .. "[" .. fieldstring .. "]" .. contained .. append
end

-- Handle received fields.
function Variation:receive_fields(form, player, field)
	if utility.DEBUG then utility.enforce_types({"Form"}, form) end

	if self.options and self.options.receive_fields then
		if type(self.options.receive_fields.callback) == "function" then
			self.options.receive_fields.callback(self, form, player, field)
		else
			local value = self:evaluate_by_name(form, self.options.receive_fields.callback)
			if value then
				local pass_field
				if self.options.receive_fields.pass_field then pass_field = field end

				setfenv(value, _G)
				value(player, pass_field)
			end

			-- TODO: Warn if the field defined in self.options.receive_fields doesn't exist.
		end
	end
	-- TODO: If self.options.receive_fields is missing, warn of unhandled fields.
end

-------------
-- Exports --
-------------

return Variation

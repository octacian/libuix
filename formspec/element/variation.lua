local utility = dofile(modpath.."/utility.lua")

---------------------
-- Variation Class --
---------------------

local Variation = utility.make_class("Variation")

-- Creates a new skeleton instance of the variation.
function Variation:new(parent, name, fields, options)
	if utility.DEBUG then utility.enforce_types({"FormspecManager", "string", "table", "table?"},
		parent, name, fields, options) end

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
function Variation:__call(def, elements)
	if utility.DEBUG then utility.enforce_types({"table", "table?"}, def, elements) end
	local instance = Variation:new(self.parent, self.name, self.fields, self.options)
	instance.def = def
	instance.field_map = instance:map_fields()
	instance:validate()
	return instance
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
		if def_field == nil and field.required ~= false then
			error(("validate: %s property '%s' is not optional"):format(self.name, field[1]))
		end

		-- if the value of the data stored in the definition field does not match the expected type, throw an error
		if def_field ~= nil and type(def_field) ~= field[2] then
			error(("validate: %s property '%s' must be a %s (found '%s')")
				:format(self.name, field[1], field[2], type(def_field)))
		end
	end

	local inverted_map = table.invert(self.field_map)
	-- Loop over definition to check for extra keys
	for def_key, _ in pairs(self.def) do
		if not inverted_map[def_key] then
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

	return self.name .. "[" .. fieldstring .. "]"
end

-------------
-- Exports --
-------------

return Variation

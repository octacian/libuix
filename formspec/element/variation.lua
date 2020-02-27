local utility = dofile(modpath.."/utility.lua")

---------------------
-- Variation Class --
---------------------

local Variation = {}
Variation.__index = Variation

-- Creates a new instance of the variation.
function Variation:new(name, fields, options)
	utility.enforce_types({"string", "table", "table?"}, name, fields, options)

	local instance = {
		name = name,
		fields = fields,
		options = options
	}

	setmetatable(instance, Variation)
	return instance
end

-- Returns a new instance of the variation, populated with its name, fields,
-- options, and now its definition and, in some cases, elements list.
function Variation:__call(def, elements)
	utility.enforce_types({"table", "table?"}, def, elements)
	local instance = Variation:new(self.name, self.fields, self.options)
	instance.def = def
	instance.cache = {}
	return instance
end

-- Maps the fields passed via the definition to their counterparts in fields.
function Variation:map_fields()
	if self.cache.map_fields then
		--print("map_fields returning cached map for " .. self.name)
		return self.cache.map_fields
	end

	local named_keys = {}
	local positional_keys = 0

	if not self.def then return end -- TODO: Make sure this NEVER happens.
	--print("map_fields got self.def: " .. dump(self.def) .. " allowed fields: " .. dump(self.fields))
	for k, _ in pairs(self.def) do
		if type(k) == "number" then
			positional_keys = positional_keys + 1
		elseif type(k) == "string" and k:sub(1, 1) ~= "_" then
			table.insert(named_keys, k)
		end
	end

	local field_map = {}
	local positional_keys_used = 0
	for index, field in ipairs(self.fields) do
		if table.contains(named_keys, field[1]) then
			field_map[index] = field[1]
		else
			positional_keys_used = positional_keys_used + 1
			field_map[index] = positional_keys_used
		end

		-- Ensure that the field exists in the definition
		if self.def[field_map[index]] == nil then
			if field.required ~= false then
				error(("map_fields: %s property '%s' is not optional"):format(self.name, field[1]))
			else
				field_map[index] = nil
			end
		end
	end

	self.cache.map_fields = field_map
	return field_map
end

-- Validates a definition table to variation constraints.
function Variation:validate()
	local internal_properties = {"_if"}

	local field_map = self:map_fields(self.def)
	for field_key, def_key in pairs(field_map) do
		if type(self.def[def_key]) ~= self.fields[field_key][2] then
			error(("validate: %s property '%s' must be a %s (found '%s')")
				:format(self.name, self.fields[field_key][1], self.fields[field_key][2], type(self.def[def_key])))
		end
	end

	-- if the definition table has more entries than the field map, there is an extra key
	if table.count(self.def) > table.count(field_map) then
		local def = table.copy(self.def)
		-- Find name of extra key
		for _, def_key in pairs(field_map) do
			def[def_key] = nil
		end

		-- Throw error
		for key, value in pairs(def) do
			if not table.contains(internal_properties, key) then
				error(("validate: %s does not support property '%s' (has type %s)"):format(self.name, key, type(value)))
			end
		end
	end

	return true
end

-- Renders the variation given a data model.
function Variation:render(model)
	utility.enforce_types({"table?"}, model)

	-- Obey _if visibility control.
	if self.def._if and not model:_evaluate(self.def._if) then
		return ""
	end

	if not self:validate(self.def) then return end

	local field_map = self:map_fields(self.def)
	local fieldstring = ""

	for index, field in ipairs(self.fields) do
		local def_index = field_map[index]
		local value = self.def[def_index] == nil and "" or self.def[def_index]
		local separator = field.separator and field.separator or ";"
		fieldstring = fieldstring .. tostring(value) .. separator
	end

	fieldstring = fieldstring:sub(1, -2)

	return ("%s[%s]"):format(self.name, fieldstring)
end

-------------
-- Exports --
-------------

return Variation

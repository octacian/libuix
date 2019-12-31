if not table.copy then
	-- Returns a deep copy of a table including metatables.
	function table.copy(original, ignore_type, tbl_index)
		if not ignore_type then
			assert(type(original) == "table", "table.copy: argument must be a table. " .. debug.traceback())
		end

		if not tbl_index then tbl_index = {} end

		local copy
		if type(original) == "table" then
			copy = {}
			for key, value in pairs(original) do
				local value_type = type(value)
				if value_type ~= "table" or not table.contains(tbl_index, tostring(value)) then
					if value_type == "table" then
						--print("Copying " .. tostring(value))
						table.insert(tbl_index, tostring(value))
					end

					copy[table.copy(key, true, tbl_index)] = table.copy(value, true, tbl_index)
				end
			end

			-- Handle metatables
			local mt = getmetatable(original); if mt then
				setmetatable(copy, table.copy(mt, true, tbl_index))
			end
		else
			copy = original
		end

		return copy
	end
end

function table.contains(tbl, value)
	for index, tbl_value in ipairs(tbl) do
		if tbl_value == value then
			return index
		end
	end
end

function table.count(tbl)
	local count = 0
	for _ in pairs(tbl) do count = count + 1 end
	return count
end

function table.foreach(tbl, func)
	for _, item in pairs(tbl) do
		local retval = func(item)
		if retval ~= nil then return retval end
	end
end

-- Validates `rules` table used by `enforce_types` and `table.constrain`. An error is raised if invalid. If verbose is
-- enabled, a stack traceback is included in the error message as well as the rules table itself.
--[[ The required rules structure is: {
	{
		"show", -- This is the name of a table key.
		"boolean", -- This is the name of the type expected. If nil any type is allowed.
		required = false, -- Overrides the default of true to make the key optional.
	}
} ]]
local function validate_rules(rules, verbose)
	local error_prefix = "libuix->validate_rules: "
	assert(verbose == nil or type(verbose) == "boolean", error_prefix
		.. ("'verbose' argument (no. 2) must be a boolean (found %s); %s"):format(type(verbose), debug.traceback()))

	local error_postfix = ""
	if verbose then
		error_postfix = "; rules = " .. dump(rules) .. "; " .. debug.traceback()
	end

	assert(type(rules) == "table", error_prefix .. ("'rules' argument (no. 1) must be a table (found %s)")
		:format(type(rules)) .. error_postfix)

	assert(table.count(rules) > 0, error_prefix .. ("'rules' argument (no. 1), a table, must contain at least one rule")
		.. error_postfix)

	-- Verify that rules are valid
	for index, rule in ipairs(rules) do
		assert(type(rule) == "table", error_prefix .. ("rule[%d] must be a table (found %s)"):format(index, type(rule))
			.. error_postfix)
		assert(type(rule[1]) == "string", error_prefix .. ("rule[%d][1] must be a string (found %s)")
			:format(index, type(rule[1])) .. error_postfix)
		assert(rule[2] == nil or type(rule[2]) == "string", error_prefix .. ("rule[%d][2] must be a string or nil (found %s)")
			:format(index, type(rule[2])) .. error_postfix)
		assert(rule.required == nil or type(rule.required) == "boolean", error_prefix
			.. ("rule[%d].required must be a boolean or nil (found %s)"):format(index, type(rule.required)) .. error_postfix)
	end
end

-- Enforces a specific set of types for function arguments.
local function enforce_types(rules, verbose, ...)
	table.constrain(arg, rules, verbose)
end

-- Constrains the keys within a table to meet specific requirements. Unless strict is false, an error is thrown if any
-- keys are found that are not in the rules table. If verbose is true a string representation of the table and rules is
-- included in the error message.
function table.constrain(tbl, rules, strict, verbose)
	-- Returns a rule by key name.
	local function get_rule(key)
		for _, rule in ipairs(rules) do
			if rule[1] == key then
				return rule
			end
		end
	end

	local error_prefix = "libuix->table.constrain: "
	local error_postfix = ""
	if verbose then
		error_postfix = "; table = " .. dump(tbl) .. "; rules = " .. dump(rules) .. " strict = " .. tostring(strict)
	end

	assert(type(tbl) == "table", error_prefix .. ("'tbl' argument (no. 1) must be a table (found %s)"):format(type(tbl)))
	assert(strict == nil or type(strict) == "boolean", error_prefix .. ("'strict' argument must be a boolean (found %s)")
		:format(type(strict)))
	assert(verbose == nil or type(verbose) == "boolean", error_prefix .. ("'verbose' argument must be a boolean (found %s)"
		):format(type(verbose)))

	-- Validate rules
	validate_rules(rules, verbose)

	-- Compare table to rules
	for key, value in pairs(tbl) do
		local rule = get_rule(key)
		-- if no rule exists for this key and strict mode hasn't been disabled, error
		if not rule and strict ~= false then
			error(error_prefix .. ("key '%s' is not allowed in strict mode"):format(key) .. error_postfix)
		end

		-- if rule exists, make comparison
		if rule then
			local value_type = type(value)
			-- if the type is controlled and it is not valid, error
			if rule[2] and value_type ~= rule[2] then
				error(error_prefix .. ("key '%s' must be of type %s (found %s)"):format(key, rule[2], value_type))
			end
		end
	end

	-- if the rules table contains more entries than the table we are processing, check which keys are required
	if table.count(rules) > table.count(tbl) then
		local missing_keys = ""
		for _, rule in ipairs(rules) do
			if rule.required then
				missing_keys = missing_keys .. (rule[2] == nil and "" or rule[2] .. " ") .. rule[1] .. ", "
			end
		end

		if missing_keys ~= "" then
			missing_keys = missing_keys:sub(1, -3)
			error(error_prefix .. "key(s) " .. missing_keys .. " are required" .. error_postfix)
		end
	end
end

if not _G["dump"] then
	-- [function] Dump
	function dump(val, indent)
		if type(val) == "string" then
			return "\""..val.."\""
		elseif type(val) == "table" then
			local res = ""
			indent = indent or 4 -- Use existing indent or start at 4

			if indent == 4 then
				res = "{\n"
			end

			for key, value in pairs(val) do
				-- Indent, unless the current table is an array.
				res = res .. string.rep(" ", indent)

				if type(value) == "table" then
						res = res .. string.format("%s = {\n%s\n%s}\n", tostring(key),
								dump(value, (indent + 4)), string.rep(" ", indent))
				else
					res = res .. string.format("%s = %s\n", tostring(key), dump(value))
				end
			end

			if indent == 4 then
				res = res .. "}"
			else
				res = res:sub(1, -2)
			end

			return res
		else
			return tostring(val)
		end
	end

--[[ 	-- Converts non-string types to strings, returning the result.
	function dump(value, force_index, indent)
		indent = indent or 0
		local indentstr = (" "):rep(indent)

		local value_type = type(value)
		if value_type == "string" then
			return indentstr .. '"' .. value .. '"'
		elseif value_type == "table" then
			local output = "{\n"
			indent = indent + 4
			indentstr = (" "):rep(indent)

			for key, item in pairs(value) do
				if type(item) == "table" then
					output = output .. ("%s = {\n%s\n%s}"):format(key, dump(item, force_index, indent), indentstr)
				else
					output = output .. ("%s%s = %s\n"):format(indentstr, key, dump(item, force_index))
				end
			end

			output = output .. "}"

			return output
		else
			return indentstr .. tostring(value)
		end
	end ]]
end

----------------------------
-- Static Table Generator --
----------------------------

function static_table(table, meta, ctrl)
	if not meta then meta = {} end

	local abstract = {}

	-- Prevent modifying the table directly.
	function meta.__newindex(tbl, key, value)
		error(("libuix: attempt to modify read-only table '%s'"):format(table))
	end

	local old_index = meta.__index
	-- Forward access attempts to the real table.
	function meta.__index(tbl, key)
		local raw_value = table[key]
		if old_index and type(old_index) == "function" then
			raw_value = old_index(tbl, key)
		end

		if not ctrl then
			return raw_value
		end

		assert(ctrl._mode == "whitelist" or ctrl._mode == "blacklist",
			("libuix!static_table: invalid control mode '%s'"):format(ctrl._mode))

		-- Loop over control table, ignoring the mode.
		for ctrl_key, value in pairs(ctrl) do
			if ctrl_key ~= "_mode" and key == value then
				return ctrl._mode == "whitelist" and raw_value or nil
			end
		end

		-- if we reach this point and the mode is blacklist, the key is allowed
		if ctrl._mode == "blacklist" then
			return raw_value
		end
	end

	setmetatable(abstract, meta)

	return abstract
end

return {
	static_table = static_table,
	dump = dump,
	enforce_types = enforce_types,
	constrain = table.constrain
}

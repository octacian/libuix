---------------------
-- Table Utilities --
---------------------

if not table.copy then
	-- Returns a deep copy of a table including metatables.
	function table.copy(original, ignore_type, _tbl_index)
		if not ignore_type then
			assert(type(original) == "table", "table.copy: argument must be a table. " .. debug.traceback())
		end

		if not _tbl_index then _tbl_index = {} end

		local copy
		if type(original) == "table" then
			copy = {}
			for key, value in pairs(original) do
				local value_type = type(value)
				if value_type ~= "table" or not table.contains(_tbl_index, tostring(value)) then
					if value_type == "table" then
						--print("Copying " .. tostring(value))
						table.insert(_tbl_index, tostring(value))
					end

					copy[table.copy(key, true, _tbl_index)] = table.copy(value, true, _tbl_index)
				end
			end

			-- Handle metatables
			local mt = getmetatable(original); if mt then
				setmetatable(copy, table.copy(mt, true, _tbl_index))
			end
		else
			copy = original
		end

		return copy
	end
end

-- Returns index if an array-equivalent table contains some value.
function table.contains(tbl, value)
	for index, tbl_value in ipairs(tbl) do
		if tbl_value == value then
			return index
		end
	end
end

-- Returns the number of items in a table.
function table.count(tbl)
	local count = 0
	for _ in pairs(tbl) do count = count + 1 end
	return count
end

-- Executes a function for every item in a table, passing the item as an argument.
function table.foreach(tbl, func)
	for _, item in pairs(tbl) do
		local retval = func(item)
		if retval ~= nil then return retval end
	end
end

-- Returns the type of some value, giving classes first-level types.
local function get_type(value)
	if type(value) == "table" and getmetatable(value)
		and type(getmetatable(value).__class_name) == "string" then
			return getmetatable(value).__class_name
	end

	return type(value)
end

-- Checks if some value has the expected type.
local function check_type(value, expected)
	if type(value) == expected or get_type(value) == expected then return true
	else return false end
end

-- Enforces a specific set of types for function arguments. `types` is an array-equivalent and should include then names
-- of valid types. Arguments may be made optional by appending `?` (a question mark) to the type name. Setting `verbose`
-- to false prevents stack traces and rule and argument dumps from being included in error messages. Arguments to check
-- are passed to the end of the function. The order of items in `types` corresponds to the order of the function
-- arguments passed to this function.
local function enforce_types(verbose, rules, ...)
	local args = table.copy(arg)
	args.n = nil
	if type(verbose) == "table" then
		table.insert(args, 1, rules)
		rules = verbose
		verbose = true
	end

	local error_prefix = "libuix->enforce_types: "
	-- Returns the error postfix only if verbose is not disabled.
	local function error_postfix()
		if verbose then
			return "; rules = " .. dump(rules) .. "; arguments = " .. dump(args) .. "\n\n" .. debug.traceback()
		else return "" end
	end

	-- Check if argument is required
	local function is_required(rule)
		local required = true
		-- Check for optional marker
		if rule:sub(-1, -1) == "?" then
			required = false
			rule = rule:sub(0, -2)
		end

		return rule, required
	end

	-- Check rules
	for key, raw_rule in ipairs(rules) do
		-- Validate rule structure
		assert(type(key) == "number", error_prefix .. ("table must be array-equivalent, only numbers may be used as rule " ..
			"keys (found %s '%s')"):format(type(key), key) .. error_postfix())
		assert(type(raw_rule) == "string", error_prefix .. ("expected rules value to be a string (found rules[%s] = '%s')")
			:format(key, raw_rule) .. error_postfix())

		local value = args[key]
		local rule, required = is_required(raw_rule)

		-- if the argument is required and nil, error
		if required and value == nil then
			error(error_prefix .. ("argument #%d is required"):format(key) .. error_postfix())
		-- elseif the argument is not nil and does not match the rule, error
		elseif value ~= nil and not check_type(value, rule) then
			error(error_prefix .. ("argument #%d must be a %s (found '%s')"):format(key, rule, dump(value)) .. error_postfix())
		end
	end

	-- if there are more arguments than rules, error
	if table.count(args) > table.count(rules) then
		error(error_prefix .. ("found %d argument(s) and only %d rule(s)"):format(table.count(args), table.count(rules))
			.. error_postfix())
	end
end

-- Ensures that a table contains only numerical indexes and optionally checks the type of each item within the table.
local function enforce_array(verbose, tbl, expected)
	if type(verbose) == "table" then
		expected = tbl
		tbl = verbose
		verbose = true
	end

	enforce_types({"boolean", "table", "string?"}, verbose, tbl, expected)

	local error_prefix = "libuix->enforce_array: "
	-- Returns the error postfix only if verbose is not disabled.
	local function error_postfix()
		if verbose then
			if expected then
				return "; expected item type = '" .. expected .. "'; table = " .. dump(tbl) .. "\n\n" .. debug.traceback()
			else
				return "; table = " .. dump(tbl) .. "\n\n" .. debug.traceback()
			end
		else return "" end
	end

	-- Check table
	for key, value in pairs(tbl) do
		if type(key) ~= "number" then
			error(error_prefix .. ("found non-numerically indexed entry at %s (contains: %s)"):format(dump(key), dump(value))
				.. error_postfix())
		end

		if expected and not check_type(value, expected) then
			error(error_prefix .. ("entry #%d must be a %s (found %s)"):format(key, expected, dump(value)) .. error_postfix())
		end
	end
end

-- Validates `rules` table used by `enforce_types` and `table.constrain`. An error is raised if invalid. Unless verbose
-- is disabled, a dump of the rules table and the stack traceback is included in the error message.
--[[ Rules Example Structure: {
	{
		"show", -- This is the name of a table key.
		"boolean", -- This is the name of the type expected. If nil any type is allowed.
		required = false, -- Overrides the default of true to make the key optional.
	}
} ]]
local function validate_rules(rules, verbose)
	enforce_types({"table", "boolean?"}, rules, verbose)
	if verbose == nil then verbose = true end

	local error_prefix = "libuix->validate_rules: "
	-- Returns the error postfix only if verbose is not disabled.
	local function error_postfix()
		if verbose then
			return "; rules = " .. dump(rules) .. "; " .. "\n\n" .. debug.traceback()
		else return "" end
	end

	assert(table.count(rules) > 0, error_prefix .. ("'rules' argument (no. 1), a table, must contain at least one rule")
		.. error_postfix())

	-- Verify that rules are valid
	for index, rule in ipairs(rules) do
		assert(type(rule) == "table", error_prefix .. ("rule[%d] must be a table (found %s)"):format(index, type(rule))
			.. error_postfix())
		assert(type(rule[1]) == "string", error_prefix .. ("rule[%d][1] must be a string (found %s)")
			:format(index, type(rule[1])) .. error_postfix())
		assert(rule[2] == nil or type(rule[2]) == "string", error_prefix .. ("rule[%d][2] must be a string or nil (found %s)")
			:format(index, type(rule[2])) .. error_postfix())
		assert(rule.required == nil or type(rule.required) == "boolean", error_prefix
			.. ("rule[%d].required must be a boolean or nil (found %s)"):format(index, type(rule.required)) .. error_postfix())
	end
end

-- Constrains the keys within a table to meet specific requirements. Unless strict is false, an error is thrown if any
-- keys are found that are not in the rules table. Unless verbose is false a dump of the target table, the rules table,
-- and the stack traceback is included in the error message.
function table.constrain(tbl, rules, strict, verbose)
	enforce_types({"table", "table", "boolean?", "boolean?"}, tbl, rules, strict, verbose)
	if verbose == nil then verbose = true end

	-- Returns a rule by key name.
	local function get_rule(key)
		for _, rule in ipairs(rules) do
			if rule[1] == key then
				return rule
			end
		end
	end

	local error_prefix = "libuix->table.constrain: "
	-- Returns the error postfix only if verbose is not disabled.
	local function error_postfix()
		if verbose then
			return "; table = " .. dump(tbl) .. "; rules = " .. dump(rules) .. " strict mode = " .. tostring(strict) .. "\n\n"
				.. debug.traceback()
		else return "" end
	end

	-- Validate rules
	validate_rules(rules, verbose)

	-- Compare table to rules
	for key, value in pairs(tbl) do
		local rule = get_rule(key)
		-- if no rule exists for this key and strict mode hasn't been disabled, error
		if not rule and strict ~= true then
			error(error_prefix .. ("key '%s' is not allowed in strict mode"):format(key) .. error_postfix())
		end

		-- if rule exists, make comparison
		if rule then
			-- if the type is controlled and it is not valid, error
			if rule[2] and not check_type(value, rule[2]) then
				error(error_prefix .. ("key '%s' must be of type %s (found %s)"):format(key, rule[2], get_type(value))
					.. error_postfix())
			end
		end
	end

	-- if the rules table contains more entries than the table we are processing, check which keys are required
	if table.count(rules) > table.count(tbl) then
		local missing_keys = ""
		for _, rule in ipairs(rules) do
			if rule.required ~= false and not tbl[rule[1]] then
				missing_keys = missing_keys .. "(" .. rule[1] .. (rule[2] == nil and "" or ": " .. rule[2]) .. "), "
			end
		end

		if missing_keys ~= "" then
			missing_keys = missing_keys:sub(1, -3)
			error(error_prefix .. "key(s) " .. missing_keys .. " are required" .. error_postfix())
		end
	end
end

-- Removes index gaps from an array.
function table.reorder(tbl)
	enforce_array(tbl)
	local out = {}
	for _, val in pairs(tbl) do
		table.insert(out, val)
	end
	return out
end

if not _G["dump"] then
	-- [function] Dump
	function dump(val, indent, tables_printed)
		if not tables_printed then tables_printed = {} end

		if type(val) == "string" then
			return "\""..val.."\""
		elseif type(val) == "table" then
			if table.contains(tables_printed, tostring(val)) then
				return string.rep(" ", indent) .. tostring(val)
			else table.insert(tables_printed, tostring(val)) end

			local res = ""
			indent = indent or 4 -- Use existing indent or start at 4

			if indent == 4 then
				res = "{\n"
			end

			for key, value in pairs(val) do
				-- Indent, unless the current table is an array.
				res = res .. string.rep(" ", indent)

				if type(value) == "table" then
					res = res .. string.format("%s (%s) = {\n%s\n%s}\n", tostring(key), tostring(value), dump(value, (indent + 4),
						tables_printed), string.rep(" ", indent))
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
end

-- Modifies the metatable of a table to make it read-only or to otherwise control access.
local function static_table(table, meta, ctrl)
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

-- Returns a new class with name attached.
local function make_class(name)
	local class = {}
	class.__index = class
	class.__class_name = name
	return class
end

-----------------
-- Queue Class --
-----------------

local Queue = make_class("Queue")

-- Queue records function calls on an object for later execution on any object.
function Queue:new()
	local instance = {}
	setmetatable(instance, Queue)
	return instance
end

function Queue:__index(key)
	for k, v in pairs(Queue) do
		if k == key then
			return v
		end
	end

	return function(...)
		local args = table.copy(arg)
		local include_self = false
		if arg.n > 0 and tostring(arg[1]) == tostring(self) then
			include_self = true
			args[1] = nil
		end
		args.n = nil
		table.insert(self, {key = key, include_self = include_self, args = table.reorder(args)})
	end
end

function Queue:_start(target)
	enforce_types({"table"}, target)
	for key, item in ipairs(self) do
		if not target[item.key] then
			error(("libuix->Queue:_start(): attempt to call field '%s' (a nil value)"):format(item.key))
		end

		if item.include_self then
			target[item.key](target, unpack(item.args))
		else
			target[item.key](unpack(item.args))
		end
		self[key] = nil
	end
end

-------------
-- Exports --
-------------

return {
	copy = table.copy,
	contains = table.contains,
	count = table.count,
	foreach = table.foreach,
	type = get_type,
	check_type = check_type,
	constrain = table.constrain,
	enforce_types = enforce_types,
	enforce_array = enforce_array,
	reorder = table.reorder,
	dump = dump,
	static_table = static_table,
	make_class = make_class,
	Queue = Queue
}

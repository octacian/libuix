local MODE = os.getenv("MODE")
local DEBUG = os.getenv("DEBUG")

if DEBUG == "TRUE" then DEBUG = true else DEBUG = false end

------------------------
-- ErrorBuilder Class --
------------------------

local ErrorBuilder = {}
ErrorBuilder.__index = ErrorBuilder
ErrorBuilder.__class_name = "ErrorBuilder"

-- Creates a new ErrorBuilder instance.
function ErrorBuilder:new(func_identifier, blame_level, verbose, include_traceback)
	if type(func_identifier) ~= "string" then
		error(("libuix->ErrorBuilder:new(): argument 1 must be a string (found %s)\n\n"):format(type(func_identifier))
			.. debug.traceback(), 2)
	end

	if blame_level ~= nil and type(blame_level) ~= "number" then
		error(("libuix->ErrorBuilder:new(): argument 2 must be a number or nil (found %s)"):format(type(blame_level))
			.. debug.traceback(), 2)
	end

	if verbose ~= nil and type(verbose) ~= "boolean" then
		error(("libuix->ErrorBuilder:new(): argument 3 must be a boolean or nil (found %s)\n\n"):format(type(verbose))
			.. debug.traceback(), 2)
	end

	if include_traceback ~= nil and type(include_traceback) ~= "boolean" then
		error(("libuix->ErrorBuilder:new(): argument 4 must be a boolean or nil (found %s)\n\n")
			:format(type(include_traceback)) .. debug.traceback(), 2)
	end

	if verbose == nil then
		if MODE == "UNIT_TEST" then
			verbose = false
		else verbose = true end
	end

	if include_traceback == nil then include_traceback = true end
	if blame_level == nil then blame_level = 2
	else blame_level = blame_level + 1 end

	local instance = {
		identifier = func_identifier,
		level = blame_level,
		verbose = verbose,
		traceback = include_traceback
	}
	setmetatable(instance, ErrorBuilder)

	return instance
end

-- Sets the postfix string.
function ErrorBuilder:set_postfix(fn)
	if type(fn) ~= "function" then
		error(("libuix->ErrorBuilder:set_postfix(): argument 1 must be a function (found %s)\n\n"):format(type(fn))
			.. debug.traceback(), 2)
	end

	self.postfix = fn
end

-- Throws an error, passing additional arguments to `string.format`.
function ErrorBuilder:throw(msg, ...)
	if type(msg) ~= "string" then
		error(("libuix->ErrorBuilder:throw(): argument 1 must be a string (found %s)\n\n"):format(type(msg))
			.. debug.traceback(), 2)
	end

	if select("#", ...) > 0 then msg = msg:format(...) end

	local postfix = ""
	if self.verbose then
		if self.traceback then postfix = "\n\n" .. debug.traceback() end

		if self.postfix then
			local postfix_msg = self.postfix()

			if type(postfix_msg) ~= "string" then
				error(("libuix->ErrorBuilder:set_postfix(fn): fn return value must be a string (found %s)\n\n")
					:format(type(postfix_msg)) .. debug.traceback(), 2)
			end

			postfix = "\n\n" .. postfix_msg  .. postfix
		end
	end

	error(("libuix->%s: %s%s"):format(self.identifier, msg, postfix), self.level)
end

-- Makes an assertion and throws an error if it fails.
function ErrorBuilder:assert(assertion, msg, ...)
	if not assertion then self:throw(msg, ...) end
end

---------------------
-- Table Utilities --
---------------------

if not table.copy then
	local err = ErrorBuilder:new("table.copy", 2)
	-- Returns a deep copy of a table including metatables.
	function table.copy(original, ignore_type, _tbl_index)
		if not ignore_type then
			err:assert(type(original) == "table", "argument must be a table (found %s)", type(original))
		end

		if not _tbl_index then _tbl_index = {} end

		local copy
		if type(original) == "table" then
			copy = {}
			for key, value in pairs(original) do
				local value_type = type(value)
				if value_type ~= "table" or not table.contains(_tbl_index, tostring(value)) then
					if value_type == "table" then
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
	for index, tbl_value in pairs(tbl) do
		if tbl_value == value then
			return index
		end
	end
end

-- Inverts a table.
function table.invert(tbl)
	local inverted = {}
	for key, value in pairs(tbl) do
		inverted[value] = key
	end
	return inverted
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

-- TODO: Optimize by not calling stuff like getmetatable repeatedly
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
	-- if a `|` character is found the in expected string, this is a complex comparison
	if expected:find("|") then
		for str in expected:gmatch("([^|]+)") do
			if type(value) == str or get_type(value) == str then return true end
		end
	-- otherwise, we can assume that this is a simple comparison
	elseif type(value) == expected or get_type(value) == expected then return true end

	return false
end

local enforce_types_err = ErrorBuilder:new("enforce_types", 3)
-- Enforces a specific set of types for function arguments. `types` is an array-equivalent and should include then names
-- of valid types. Arguments may be made optional by appending `?` (a question mark) to the type name. Arguments to
-- check are passed to the end of the function. The order of items in `types` corresponds to the order of the function
-- arguments passed to this function.
local function enforce_types(rules, ...)
	if not DEBUG then return end

	local arg = {...}
	enforce_types_err:set_postfix(function() return ("Rules = %s; Arguments = %s"):format(dump(rules), dump(arg)) end)

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
		enforce_types_err:assert(type(key) == "number", "table must be array-equivalent, only numbers may be used as rule "
			.. "keys (found %s '%s')", type(key), key)
		enforce_types_err:assert(type(raw_rule) == "string", "expected rules value to be a string (found rules[%s] = '%s')",
			key, raw_rule)

		local value = arg[key]
		local rule, required = is_required(raw_rule)

		-- if the argument is required and nil, error
		if required and value == nil then
			enforce_types_err:throw("argument #%d is required", key)
		-- elseif the argument is not nil and does not match the rule, error
		elseif value ~= nil and not check_type(value, rule) then
			enforce_types_err:throw("argument #%d must be a %s (found %s)", key, rule, get_type(value))
		end
	end

	-- if there are more arguments than rules, error
	if #arg > #rules then
		enforce_types_err:throw("found %d argument(s) and only %d rule(s)", #arg, #rules)
	end
end

local enforce_array_err = ErrorBuilder:new("enforce_array", 2)
-- Ensures that a table contains only numerical indexes and optionally checks the type of each item within the table.
local function enforce_array(tbl, expected)
	if not DEBUG then return end
	enforce_types({"table", "string?"}, tbl, expected)

	if expected then
		enforce_array_err:set_postfix(function() return ("Expected Item Type = %s; Table = %s")
			:format(expected, dump(tbl)) end)
	else
		enforce_array_err:set_postfix(function() return ("Table = %s"):format(dump(tbl)) end)
	end

	-- Check table
	for key, value in pairs(tbl) do
		if type(key) ~= "number" then
			enforce_array_err:throw("found non-numerically indexed entry at %s (contains: %s)", dump(key), dump(value))
		end

		if expected and not check_type(value, expected) then
			enforce_array_err:throw("entry #%d must be a %s (found %s)", key, expected, get_type(value))
		end
	end
end

local validate_rules_err = ErrorBuilder:new("validate_rules", 3)
-- Validates `rules` table used by `enforce_types` and `table.constrain`. An error is raised if invalid.
--[[ Rules Example Structure: {
	{
		"show", -- This is the name of a table key.
		"boolean", -- This is the name of the type expected. If nil any type is allowed.
		required = false, -- Overrides the default of true to make the key optional.
	}
} ]]
local function validate_rules(rules)
	enforce_types({"table"}, rules)

	validate_rules_err:set_postfix(function() return ("Rules = %s"):format(dump(rules)) end)
	validate_rules_err:assert(table.count(rules) > 0, "'rules' argument (no. 1), a table, must contain at least one rule")

	-- Verify that rules are valid
	for index, rule in ipairs(rules) do
		validate_rules_err:assert(type(rule) == "table", "rule[%d] must be a table (found %s)", index, type(rule))
		validate_rules_err:assert(type(rule[1]) == "string", "rule[%d][1] must be a string (found %s)", index, type(rule[1]))
		validate_rules_err:assert(rule[2] == nil or type(rule[2]) == "string", "rule[%d][2] must be a string or nil "
			.. "(found %s)", index, type(rule[2]))
		validate_rules_err:assert(rule.required == nil or type(rule.required) == "boolean",
			"rule[%d].required must be a boolean or nil (found %s)", index, type(rule.required))
	end
end

local table_constrain_err = ErrorBuilder:new("table.constrain", 2)
-- Constrains the keys within a table to meet specific requirements. Unless strict is false, an error is thrown if any
-- keys are found that are not in the rules table.
function table.constrain(tbl, rules, strict)
	if not DEBUG then return end
	enforce_types({"table", "table", "boolean?"}, tbl, rules, strict)

	-- Returns a rule by key name.
	local function get_rule(key)
		for _, rule in ipairs(rules) do
			if rule[1] == key then
				return rule
			end
		end
	end

	table_constrain_err:set_postfix(function()
		return ("Table = %s; Rules = %s; Strict Mode = %s"):format(dump(tbl), dump(rules), tostring(strict))
	end)

	-- Validate rules
	validate_rules(rules)

	-- Compare table to rules
	for key, value in pairs(tbl) do
		local rule = get_rule(key)
		-- if no rule exists for this key and strict mode hasn't been disabled, error
		if not rule and strict ~= true then
			table_constrain_err:throw("key '%s' is not allowed in strict mode", key)
		end

		-- if rule exists, make comparison
		if rule then
			-- if the type is controlled and it is not valid, error
			if rule[2] and not check_type(value, rule[2]) then
				table_constrain_err:throw("key '%s' must be of type %s (found %s)", key, rule[2], get_type(value))
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
			table_constrain_err:throw("key(s) %s are required", missing_keys)
		end
	end
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

local static_table_err = ErrorBuilder:new("static_table", 2)
-- Modifies the metatable of a table to make it read-only or to otherwise control access.
local function static_table(table, meta, ctrl)
	if not meta then meta = {} end

	local abstract = {}

	-- Prevent modifying the table directly.
	function meta.__newindex(tbl, key, value)
		static_table_err:throw("attempt to modify read-only table '%s'", table)
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

		static_table_err:assert(ctrl._mode == "whitelist" or ctrl._mode == "blacklist", "invalid control mode '%s'",
			ctrl._mode)

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

-- Converts some value to a string. Additional arguments are forwarded if the value happens to be a function. If the
-- value is a function and it returns something other than a string and err is not nil, err is called with the return
-- value as an argument.
local function evaluate_string(value, err, ...)
	if DEBUG then enforce_types({"function?"}, err) end
	local value_type = type(value)
	if value_type == "string" then return value
	elseif value_type == "function" then
		value = value(...)

		if type(value) ~= "string" then
			if err then err(value) end
			return evaluate_string(value)
		end

		return value
	else return tostring(value) end
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

-- WARNING: Do not pass non-trailing nil arguments to Queue; unpack will stop at the first nil and all following
-- arguments will never be passed to the queued function.
function Queue:__index(key)
	for k, v in pairs(Queue) do
		if k == key then
			return v
		end
	end

	return function(...)
		local arg = {...}
		local include_self = false
		if #arg > 0 and tostring(arg[1]) == tostring(self) then
			include_self = true
			table.remove(arg, 1)
		end
		table.insert(self, {key = key, include_self = include_self, arg = arg})
	end
end

function Queue:_start(target)
	if DEBUG then enforce_types({"table"}, target) end
	for key, item in ipairs(self) do
		if not target[item.key] then
			error(("libuix->Queue:_start(): attempt to call field '%s' (a nil value)"):format(item.key))
		end

		if item.include_self then
			target[item.key](target, unpack(item.arg))
		else
			target[item.key](unpack(item.arg))
		end
		self[key] = nil
	end
end

-------------
-- Exports --
-------------

return {
	MODE = MODE,
	DEBUG = DEBUG,
	ErrorBuilder = ErrorBuilder,
	copy = table.copy,
	invert = table.invert,
	contains = table.contains,
	count = table.count,
	foreach = table.foreach,
	type = get_type,
	check_type = check_type,
	constrain = table.constrain,
	enforce_types = enforce_types,
	enforce_array = enforce_array,
	dump = dump,
	static_table = static_table,
	make_class = make_class,
	evaluate_string = evaluate_string,
	Queue = Queue
}

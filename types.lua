local ErrorBuilder = import("errors.lua")
local tables = import("tables.lua")

--------------------
-- Type Utilities --
--------------------

-- TODO: Optimize by not calling stuff like getmetatable repeatedly
-- Returns the type of some value, giving classes first-level types.
local function get(value)
	if type(value) == "table" and getmetatable(value)
		and type(getmetatable(value).__class_name) == "string" then
			return getmetatable(value).__class_name
	end

	return type(value)
end

-- Checks if some value has the expected type.
local function check(value, expected)
	-- if a `|` character is found the in expected string, this is a complex comparison
	if expected:find("|") then
		for str in expected:gmatch("([^|]+)") do
			if type(value) == str or get(value) == str then return true end
		end
	-- otherwise, we can assume that this is a simple comparison
	elseif type(value) == expected or get(value) == expected then return true end

	return false
end

local force_err = ErrorBuilder:new("types->force", 3)
-- Forces a specific set of types for function arguments. `types` is an array-equivalent and should include then names
-- of valid types. Arguments may be made optional by appending `?` (a question mark) to the type name. Arguments to
-- check are passed to the end of the function. The order of items in `types` corresponds to the order of the function
-- arguments passed to this function.
local function force(rules, ...)
	if not DEBUG then return end

	local arg = {...}
	force_err:set_postfix(function()
		return ("Rules = %s; Arguments = %s"):format(tables.dump(rules), tables.dump(arg))
	end)

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
		force_err:assert(type(key) == "number", "table must be array-equivalent, only numbers may be used as rule "
			.. "keys (found %s '%s')", type(key), key)
		force_err:assert(type(raw_rule) == "string", "expected rules value to be a string (found rules[%s] = '%s')",
			key, raw_rule)

		local value = arg[key]
		local rule, required = is_required(raw_rule)

		-- if the argument is required and nil, error
		if required and value == nil then
			force_err:throw("argument #%d is required", key)
		-- elseif the argument is not nil and does not match the rule, error
		elseif value ~= nil and not check(value, rule) then
			force_err:throw("argument #%d must be a %s (found %s)", key, rule, get(value))
		end
	end

	-- if there are more arguments than rules, error
	if #arg > #rules then
		force_err:throw("found %d argument(s) and only %d rule(s)", #arg, #rules)
	end
end

local force_array_err = ErrorBuilder:new("types->force_array", 2)
-- Ensures that a table contains only numerical indexes and optionally checks the type of each item within the table.
local function force_array(tbl, expected)
	if not DEBUG then return end
	force({"table", "string?"}, tbl, expected)

	if expected then
		force_array_err:set_postfix(function() return ("Expected Item Type = %s; Table = %s")
			:format(expected, tables.dump(tbl)) end)
	else
		force_array_err:set_postfix(function() return ("Table = %s"):format(tables.dump(tbl)) end)
	end

	-- Check table
	for key, value in pairs(tbl) do
		if type(key) ~= "number" then
			force_array_err:throw("found non-numerically indexed entry at %s (contains: %s)", tables.dump(key),
				tables.dump(value))
		end

		if expected and not check(value, expected) then
			force_array_err:throw("entry #%d must be a %s (found %s)", key, expected, get(value))
		end
	end
end

local validate_rules_err = ErrorBuilder:new("types->validate_rules", 3)
-- Validates `rules` table used by `types.constrain`. An error is raised if invalid.
--[[ Rules Example Structure: {
	{
		"show", -- This is the name of a table key.
		"boolean", -- This is the name of the type expected. If nil any type is allowed.
		required = false, -- Overrides the default of true to make the key optional.
	}
} ]]
local function validate_rules(rules)
	force({"table"}, rules)

	validate_rules_err:set_postfix(function() return ("Rules = %s"):format(tables.dump(rules)) end)
	validate_rules_err:assert(tables.count(rules) > 0, "'rules' argument (no. 1), a table, must contain at least one rule")

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

local constrain_err = ErrorBuilder:new("types->constrain", 2)
-- Constrains the keys within a table to meet specific requirements. Unless strict is false, an error is thrown if any
-- keys are found that are not in the rules table.
local function constrain(tbl, rules, strict)
	if not DEBUG then return end
	force({"table", "table", "boolean?"}, tbl, rules, strict)

	-- Returns a rule by key name.
	local function get_rule(key)
		for _, rule in ipairs(rules) do
			if rule[1] == key then
				return rule
			end
		end
	end

	constrain_err:set_postfix(function()
		return ("Table = %s; Rules = %s; Strict Mode = %s"):format(tables.dump(tbl), tables.dump(rules), tostring(strict))
	end)

	-- Validate rules
	validate_rules(rules)

	-- Compare table to rules
	for key, value in pairs(tbl) do
		local rule = get_rule(key)
		-- if no rule exists for this key and strict mode hasn't been disabled, error
		if not rule and strict ~= true then
			constrain_err:throw("key '%s' is not allowed in strict mode", key)
		end

		-- if rule exists, make comparison
		if rule then
			-- if the type is controlled and it is not valid, error
			if rule[2] and not check(value, rule[2]) then
				constrain_err:throw("key '%s' must be of type %s (found %s)", key, rule[2], get(value))
			end
		end
	end

	-- if the rules table contains more entries than the table we are processing, check which keys are required
	if tables.count(rules) > tables.count(tbl) then
		local missing_keys = ""
		for _, rule in ipairs(rules) do
			if rule.required ~= false and not tbl[rule[1]] then
				missing_keys = missing_keys .. "(" .. rule[1] .. (rule[2] == nil and "" or ": " .. rule[2]) .. "), "
			end
		end

		if missing_keys ~= "" then
			missing_keys = missing_keys:sub(1, -3)
			constrain_err:throw("key(s) %s are required", missing_keys)
		end
	end
end

-- Returns a new type with name attached.
local function new_type(name)
	local class = {}
	class.__index = class
	class.__class_name = name
	return class
end

-------------
-- Exports --
--------------------

return {
	get = get,
	check = check,
	force = force,
	force_array = force_array,
	constrain = constrain,
	type = new_type
}

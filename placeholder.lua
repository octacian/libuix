local ErrorBuilder = import("errors.lua")
local types = import("types.lua")

-----------------------
-- Placeholder Class --
-----------------------

local mt = { __class_name = "Placeholder" }

-- Returns the event from a placeholder object.
local function get_event(obj)
	return getmetatable(obj).event
end

-- Returns the event furthest down the chain of events stored in a placeholder object.
local function get_youngest_event(obj)
	local event = get_event(obj)
	while true do
		if not event.after then return event end
		event = get_event(event.after)
	end
end

-- Creates an empty placeholder.
local function new()
	local instance = {}
	setmetatable(instance, {
		__index = mt.__index, __newindex = mt.__newindex, __call = mt.__call, __unm = mt.__unm, __add = mt.__add,
		__sub = mt.__sub, __mul = mt.__mul, __div = mt.__div, __mod = mt.__mod, __pow = mt.__pow, __concat = mt.__concat,
		__eq = mt.__eq, __lt = mt.__lt, __le = mt.__le, __class_name = mt.__class_name, event = {}
	})

	return instance
end

-- Creates an access placeholder for <name>.
local function index(name)
	local instance = new()
	local event = get_event(instance)
	event.type = "access"
	event.error_desc = "index"
	event.name = name
	return instance
end

-- Creates an access and assignment placeholder for <name> to be given <value>.
local function new_index(name, value)
	local after = new(); local event = get_event(after)
	event.type = "assign"
	event.error_desc = "newindex"
	event.modifier = value
	local instance = index(name)
	get_event(instance).after = after
	return instance
end

local new_listener_err = ErrorBuilder:new("Placeholder.new_listener")
-- Modifies an arbitrary environment to listen for index and newindex events..
local function new_listener(env)
	setmetatable(env, {
		__index = function(_, key)
			return index(key)
		end,
		-- At this point in time we don't want to allow newindex events, throw an error.
		__newindex = function(_, key, _)
			new_listener_err:throw("attempt to assign value to key '%s' in access listener", key)
		end
	})
end

local set_err = ErrorBuilder:new("Placeholder.set", 2)
-- Uses a placeholder as a key to set a value in an arbitrary environment table.
local function set(env, obj, value)
	local key = ""
	while env do
		local event = get_event(obj)
		if event.type ~= "access" then
			set_err:throw("assignment key cannot contain a %s event", event.type)
		end

		if not event.after or get_event(event.after).type == "assign" then
			env[event.name] = value
			return
		end

		obj = event.after
		env = env[event.name]
		key = key .. event.name .. "."
	end

	set_err:throw("attempt to index environment key '%s' (a nil value)", key:sub(1, -2))
end

local evaluate_err = ErrorBuilder:new("Placeholder.evaluate")
-- Evaluates a placeholder down to a raw value given an arbitrary environment table.
local function evaluate(env, obj, func_env, previous_env, previous_obj, global_env, global_obj, blame_level)
	if DEBUG then types.force({"table|function|number|string|userdata?", "Placeholder"}, env, obj) end
	if not global_env then global_env = env end
	if not global_obj then global_obj = obj end
	if not blame_level then blame_level = 2 end
	evaluate_err.level = blame_level

	local function check_modifier(value)
		if types.get(value) == "Placeholder" then
			return evaluate(global_env, value, func_env)
		else return value end
	end

	local event = get_event(obj)
	local value

	-- if event is assignment, do it and return immediately
	if event.type == "assign" then
		set(global_env, global_obj, event.modifier)
		return
	end

	-- if env is nil an error will occur, throw one gracefully
	if env == nil then
		local name = event.name
		if not name then name = get_event(previous_obj).name end
		evaluate_err:throw("attempt to %s environment key '%s' (a nil value)", event.error_desc, name)
	end

	-- Handle events
	if event.type == "access" then
		value = env[event.name]
	elseif event.type == "call" then
		-- Check for placeholder arguments
		for key, arg in pairs(event.arg) do
			if types.get(arg) == "Placeholder" then
				event.arg[key] = evaluate(global_env, arg, func_env)
			end
		end

		-- if the function call environment is defined, update the function env
		if func_env then
			setfenv(env, func_env)
		end

		if event.with_self then value = env(previous_env, unpack(event.arg))
		else value = env(unpack(event.arg)) end
	elseif event.type == "unm" then
		value = -env
	elseif event.type == "add" then
		value = env + check_modifier(event.modifier)
	elseif event.type == "sub" then
		value = env - check_modifier(event.modifier)
	elseif event.type == "mul" then
		value = env * check_modifier(event.modifier)
	elseif event.type == "div" then
		value = env / check_modifier(event.modifier)
	elseif event.type == "mod" then
		value = env % check_modifier(event.modifier)
	elseif event.type == "pow" then
		value = env ^ check_modifier(event.modifier)
	elseif event.type == "concat" then
		value = env .. check_modifier(event.modifier)
	else
		evaluate_err:throw("bad event type '%s'", event.type)
	end

	if event.after then
		value = evaluate(value, event.after, func_env, env, obj, global_env, global_obj, blame_level + 1)
	end

	return value
end

-- Record access attempts.
function mt:__index(key)
	local event = get_youngest_event(self)
	event.after = index(key)
	return self
end

-- Record assignment events.
function mt:__newindex(key, value)
	local after = new_index(key, value)
	get_youngest_event(self).after = after
	return self
end

local remove = table.remove
-- Record function call attempts.
function mt:__call(...)
	local after = new(); local event = get_event(after)
	event.type = "call"
	event.error_desc = "call"
	event.arg = {...}

	-- if the first argument is this table, the function should be called with self
	if tostring(self) == tostring(event.arg[1]) then
		event.with_self = true
		remove(event.arg, 1)
	end

	get_youngest_event(self).after = after
	return self
end

local arithmetic_error_desc = "perform arithmetic on"

-- Record uses of the unary minus operator.
function mt.__unm(placeholder)
	local after = new(); local event = get_event(after)
	event.type = "unm"
	event.error_desc = arithmetic_error_desc
	get_youngest_event(placeholder).after = after
	return placeholder
end

-- Registers a method to record a math operation.
local function register_math_op(name, error_desc)
	mt["__" .. name] = function(left, right)
		local placeholder = left
		local value = right
		if types.get(placeholder) ~= "Placeholder" then
			placeholder = right
			value = left
		end

		local after = new(); local event = get_event(after)
		event.type = name
		event.error_desc = error_desc or arithmetic_error_desc
		event.modifier = value
		get_youngest_event(placeholder).after = after
		return placeholder
	end
end

register_math_op("add")
register_math_op("sub")
register_math_op("mul")
register_math_op("div")
register_math_op("mod")
register_math_op("pow")
register_math_op("concat", "concatenate")

-- Registers a method to record equality check.
local function register_equality_op(name)
	local equality_op_err = ErrorBuilder:new("Placeholder:__" .. name)
	mt["__" .. name] = function(left, right)
		equality_op_err:throw("comparison operators are not allowed, use 'is.%s()' instead", name)
	end
end

register_equality_op("eq")
register_equality_op("lt")
register_equality_op("le")

--------------------------
-- Comparison Functions --
--------------------------

local is = {}

function is.eq(left, right)
	return left == right
end

function is.ne(left, right)
	return left ~= right
end

function is.lt(left, right)
	return left < right
end

function is.gt(left, right)
	return left > right
end

function is.le(left, right)
	return left <= right
end

function is.ge(left, right)
	return left >= right
end

--------------------------------
-- Logical Operator Functions --
--------------------------------

local logical = {}

function logical.l_and(left, right)
	return left and right
end

function logical.l_or(left, right)
	return left or right
end

function logical.l_not(obj)
	return not obj
end

-------------
-- Exports --
-------------

return {
	new = new,
	index = index,
	new_index = new_index,
	new_listener = new_listener,
	set = set,
	evaluate = evaluate,
	is = is,
	logical = logical,
}

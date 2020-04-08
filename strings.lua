local types = import("types.lua")

----------------------
-- String Utilities --
----------------------

-- Converts some value to a string. Additional arguments are forwarded if the value happens to be a function. If the
-- value is a function and it returns something other than a string and err is not nil, err is called with the return
-- value as an argument.
local function evaluate(value, err, ...)
	if DEBUG then types.force({"function?"}, err) end
	local value_type = type(value)
	if value_type == "string" then return value
	elseif value_type == "function" then
		value = value(...)

		if type(value) ~= "string" then
			if err then err(value) end
			return evaluate(value)
		end

		return value
	else return tostring(value) end
end

-- Splits a string and returns a table. Based on https://gist.github.com/jaredallard/ddb152179831dd23b230.
local function split(str, delimiter)
	local result = {}
	local from = 1
	local delim_from, delim_to = string.find(str, delimiter, from)
	while delim_from do
		table.insert( result, string.sub(str, from , delim_from-1))
		from = delim_to + 1
		delim_from, delim_to = string.find(str, delimiter, from)
	end
	table.insert(result, string.sub(str, from))
	return result
end

-------------
-- Exports --
-------------

return {
	evaluate = evaluate,
	split = split
}

local ErrorBuilder = import("errors.lua")

---------------------
-- Table Utilities --
---------------------

-- Returns index if an array-equivalent table contains some value.
local function contains(tbl, value)
	for index, tbl_value in pairs(tbl) do
		if tbl_value == value then
			return index
		end
	end
end

local copy_err = ErrorBuilder:new("tables->copy", 2)
-- Returns a deep copy of a table including metatables.
local function copy(original, ignore_type, _tbl_index)
	if not ignore_type then
		copy_err:assert(type(original) == "table", "argument must be a table (found %s)", type(original))
	end

	if not _tbl_index then _tbl_index = {} end

	local clone
	if type(original) == "table" then
		clone = {}
		for key, value in pairs(original) do
			local value_type = type(value)
			if value_type ~= "table" or not contains(_tbl_index, tostring(value)) then
				if value_type == "table" then
					table.insert(_tbl_index, tostring(value))
				end

				clone[copy(key, true, _tbl_index)] = copy(value, true, _tbl_index)
			end
		end

		-- Handle metatables
		local mt = getmetatable(original); if mt then
			setmetatable(clone, copy(mt, true, _tbl_index))
		end
	else
		clone = original
	end

	return clone
end

-- Inverts a table.
local function invert(tbl)
	local inverted = {}
	for key, value in pairs(tbl) do
		inverted[value] = key
	end
	return inverted
end

-- Returns the number of items in a table.
local function count(tbl)
	local number = 0
	for _ in pairs(tbl) do number = number + 1 end
	return number
end

-- Executes a function for every item in a table, passing the item as an argument.
local function foreach(tbl, func)
	for _, item in pairs(tbl) do
		local retval = func(item)
		if retval ~= nil then return retval end
	end
end

-- Prints the contents of a table.
local function dump(val, indent, tables_printed)
	if not tables_printed then tables_printed = {} end

	if type(val) == "string" then
		return "\""..val.."\""
	elseif type(val) == "table" then
		if contains(tables_printed, tostring(val)) then
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

local static_err = ErrorBuilder:new("tables->static", 2)
-- Modifies the metatable of a table to make it read-only or to otherwise control access.
local function static(table, meta, ctrl)
	if not meta then meta = {} end

	local abstract = {}

	-- Prevent modifying the table directly.
	function meta.__newindex(tbl, key, value)
		static_err:throw("attempt to modify read-only table '%s'", table)
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

		static_err:assert(ctrl._mode == "whitelist" or ctrl._mode == "blacklist", "invalid control mode '%s'",
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

-------------
-- Exports --
-------------

return {
	copy = copy,
	contains = contains,
	invert = invert,
	count = count,
	foreach = foreach,
	dump = dump,
	static = static
}

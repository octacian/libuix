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
	dump = dump
}

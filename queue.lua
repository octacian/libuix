local types = import("types.lua")

-----------------
-- Queue Class --
-----------------

local Queue = types.type("Queue")

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
	if DEBUG then types.force({"table"}, target) end
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

return Queue

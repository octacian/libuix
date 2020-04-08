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
		if UNIT_TEST then verbose = false
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

-------------
-- Exports --
-------------

return ErrorBuilder

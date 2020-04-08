package.path = "../?.lua;" .. package.path

require("tests/mock")
local ErrorBuilder = require("errors")

describe("ErrorBuilder", function()
	it("populates error message with repetitive fields", function()
		local err = ErrorBuilder:new("error_spec()", nil, true, false)
		assert.has_error(function() err:throw("got message %s %s", "hello", "world") end,
			"libuix->error_spec(): got message hello world")
		assert.has_error(function() err:assert(true == false, "failure %s", "is known") end,
			"libuix->error_spec(): failure is known")
		assert.has_no.error(function() err:assert(21 == 21, "oof") end)
		err:set_postfix(function() return "postfix info" end)
		assert.has_error(function() err:throw("new %s", "user") end, "libuix->error_spec(): new user\n\npostfix info")
	end)
end)

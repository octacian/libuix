package.path = "../?.lua;" .. package.path

require("tests/mock")
local strings = require("strings")

describe("evaluate_string", function()
	it("converts some value to a string", function()
		assert.are.same("Hello", strings.evaluate("Hello"))
		assert.are.same("World", strings.evaluate(function(str) return str end, nil, "World"))
		assert.are.same("28", strings.evaluate(28))
		assert.are.same("32", strings.evaluate(function() return 32 end))
		assert.has_error(function()
			strings.evaluate(function() return 32 end, function(val) error("found " .. type(val)) end)
		end, "found number")
	end)
end)

describe("string.split", function()
	it("uses a delimiter to split a string and returns a table", function()
		local result = strings.split("hello:world", ":")
		assert.are.same({"hello", "world"}, result)
	end)
end)

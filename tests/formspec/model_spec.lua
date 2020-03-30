package.path = "../?.lua;" .. package.path
_G.libuix = {}
_G.modpath = "."
require("tests/mock")
local Model = require("formspec/model")

describe("Model", function()
	it("only accepts a table for data", function()
		assert.has_no.error(function() Model:new({favourite_number = 10}) end)
		assert.has_error(function() Model:new(305) end)
	end)

	describe("_evaluate", function()
		it("evaluates whatever lies within some key to an integral, boolean-comparable type", function()
			local instance = Model:new({
				hello = function()
					return true
				end,
				message = "What's up?",
				visible = true,
				useful = false
			})

			assert.are.equal(true, instance:_evaluate("hello"))
			assert.are.equal("What's up?", instance:_evaluate("message"))
			assert.are.equal(true, instance:_evaluate("visible"))
			assert.are.equal(false, instance:_evaluate("useful"))
		end)
	end)
end)

package.path = "../?.lua;" .. package.path
_G.libuix = {}
_G.modpath = "."
local Variation = require("formspec/element/variation")
local Example = Variation:new("variation_spec", {
	{ "x",  "number", separator = "," },
	{ "name", "string" },
	{ "y", "number", required = false },
})

describe("Variation", function()
	local instance = Example({ 20, name = "Example * 9.8", 32 })

	describe("map_fields", function()
		it("maps definition fields to those defined at the creation of the variation", function()
			local field_map = instance:map_fields()
			assert.are.same({1, "name", 2}, field_map)
		end)

		it("errors if any required fields are missing", function()
			assert.has_error(function() Example({ 20, y = 84 }):map_fields() end)
			assert.has_no.error(function() Example({ 20, name = "Yay! It's broken somewhere else!" }) end)
		end)
	end)

	describe("validate", function()
		it("checks the types of the values of definition fields", function()
			assert.has_no.errors(function() instance:validate() end)
			assert.has_error(function() Example({ 20, name = true, 32 }):validate() end)
			assert.has_error(function() Example({ false, name = "Ayo", 32 }):validate() end)
			assert.has_error(function() Example({ false, name = 20, "Woah" }):validate() end)
		end)

		it("catches fields not defined at the creation of the variation", function()
			assert.has_error(function() Example({ 20, nothing = true, name = "Yeah! This broke something!" }):validate() end)
		end)
	end)

	describe("render", function()
		it("outputs a string compatible with Minetest formspecs", function()
			assert.are.equal("variation_spec[20,Example * 9.8;32]", instance:render({}))
		end)

		it("inserts extra separators for optional fields", function()
			assert.are.equal("variation_spec[20,Will this break?;]", Example({ 20, name = "Will this break?" }):render())
		end)
	end)

	it("correctly handles boolean fields", function()
		Example = Variation:new("boolean_spec", {
			{ "option", "boolean" }
		})

		assert.are.equal("boolean_spec[true]", Example({ option = true }):render())
		assert.are.equal("boolean_spec[false]", Example({ option = false }):render())
	end)
end)

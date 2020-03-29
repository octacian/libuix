package.path = "../?.lua;" .. package.path
_G.libuix = {}
_G.modpath = "."
local manager = require("tests/mock").FormspecManager:new(nil, require("formspec/elements"))
local Variation = require("formspec/element/variation")
local Model = require("formspec/model")

local Example = Variation:new(manager, "variation_spec", {
	{ "x",  "number", separator = "," },
	{ "name", "string" },
	{ "y", "number", required = false },
	{ "_if", "string", required = false, internal = true },
})

describe("Variation", function()
	local instance = Example({ 20, name = "Example * 9.8", 32 })

	describe("map_fields", function()
		it("maps definition fields to those defined at the creation of the variation", function()
			local field_map = instance:map_fields()
			assert.are.same({1, "name", 2}, field_map)
		end)
	end)

	describe("validate", function()
		it("errors if any required fields are missing", function()
			assert.has_error(function() Example({ 20, y = 84 }):validate() end,
				"validate: variation_spec property 'name' is not optional")
			assert.has_no.error(function() Example({ 20, name = "Yay! It's broken somewhere else!" }):validate() end)
		end)

		it("checks the types of the values of definition fields", function()
			assert.has_no.errors(function() instance:validate() end)
			assert.has_error(function() Example({ 20, name = true, 32 }):validate() end,
				"validate: variation_spec property 'name' must be a string (found 'boolean')")
			assert.has_error(function() Example({ false, name = "Ayo", 32 }):validate() end,
				"validate: variation_spec property 'x' must be a number (found 'boolean')")
			assert.has_error(function() Example({ 45.2, name = 20, "Woah" }):validate() end,
				"validate: variation_spec property 'name' must be a string (found 'number')")
		end)

		it("catches fields not defined at the creation of the variation", function()
			assert.has_error(function() Example({ 20, nothing = true, name = "Yeah! This broke something!" }):validate() end,
				"validate: variation_spec does not support property 'nothing'")
		end)
	end)

	describe("render", function()
		it("outputs a string compatible with Minetest formspecs", function()
			assert.are.equal("variation_spec[20,Example * 9.8;32]", instance:render({}))
		end)

		it("inserts extra separators for optional fields", function()
			assert.are.equal("variation_spec[20,Will this break?;]", Example({ 20, name = "Will this break?" }):render())
		end)

		it("obeys visibility rules", function()
			assert.are.equal("", Example({20, name = "Invisible", _if = "show"}):render(Model:new {show = false}))
			assert.are.equal("variation_spec[20,Visible;]",
				Example({20, name = "Visible", _if = "show"}):render(Model:new {show = true}))
		end)
	end)

	it("correctly handles boolean fields", function()
		Example = Variation:new(manager, "boolean_spec", {
			{ "option", "boolean" }
		})

		assert.are.equal("boolean_spec[true]", Example({ option = true }):render())
		assert.are.equal("boolean_spec[false]", Example({ option = false }):render())
	end)

	it("supports container elements", function()
		Example = Variation:new(manager, "container_spec", {
			{"x", "number", separator = ","},
			{"y", "number"}
		}, {contains = "Variation"})

		local populated
		assert.has_no.error(function()
			populated = Example { x = 15, y = 7 } {
				label { x = 0, y = 0, label = "Hello!" }
			}
		end)
		assert.are.equal("container_spec[15,7]label[0,0;Hello!]container_spec_end[]", populated:render())
	end)
end)

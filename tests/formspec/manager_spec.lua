package.path = "../?.lua;" .. package.path
_G.libuix = {}
_G.modpath = "."
_G.minetest = {}
local utility = require("utility")
local UIXInstance = require("tests/mock").UIXInstance
local FormspecManager = require("formspec/manager")

describe("FormspecManager", function()
	local instance = FormspecManager:new(UIXInstance:new("unit_test"))

	it("collects formspec name, options, elements, and model for addition to the instance", function()
		-- assert.has_no.error(function()
			instance("manager_spec") { w = 5, h = 10 } {
				ui.text { x = 0, y = model.text_y, text = "Hello!" }
			} { text_y = 0 }
		-- end)

		assert.are.equal("Placeholder", utility.type(instance.forms[1].elements[1].def.y))
		assert.are.equal("Hello!", instance.forms[1].elements[1].def.text)
	end)

	describe("get", function()
		it("returns a formspec by name from the instance", function()
			assert.are.equal("manager_spec", instance:get("manager_spec").name)
			assert.are.equal("Form", utility.type(instance:get("manager_spec")))
			assert.falsy(instance:get("invalid"))
		end)
	end)

	describe("get_index", function()
		it("returns a formspec index by name from the instance", function()
			assert.are.equal(1, instance:get_index("manager_spec"))
			assert.falsy(instance:get_index("invalid"))
		end)
	end)
end)

package.path = "../?.lua;" .. package.path
_G.libuix = {}
_G.modpath = "."
local FormspecManager = require("formspec/manager")

-- TODO: Test that formspec options are all correctly handled.

describe("FormspecManager", function()
	local instance = FormspecManager:new("unit_test")

	it("collects formspec name, elements, and model for addition to the instance", function()
		assert.has_no.error(function()
			instance("manager_spec") { w = 5, h = 10 } {
				anchor { x = 0, y = 0 }
			} {}
		end)
	end)

	it("renders a registered formspec, returning a Minetest-compatible formspec string", function()
		assert.are.equal("real_coordinates[true]size[5,10]anchor[0,0]", instance:render("manager_spec"))
	end)
end)

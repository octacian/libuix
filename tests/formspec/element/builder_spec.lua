package.path = "../?.lua;" .. package.path
_G.libuix = {}
_G.modpath = "."
local Builder = require("formspec/element/builder")

describe("Builder", function()
	local instance = Builder:new()

	describe("add", function()
		it("adds a generic element to the builder", function()
			assert.are.equal(0, table.count(instance.elements))
			instance:add("builder_spec", false, false, {
				{ "x", "number" },
				{ "name", "string" }
			})
			assert.are.equal(1, table.count(instance.elements))
			assert.are.equal("builder_spec[20;bork]", instance.elements.builder_spec({ x = 20, name = "bork" }):render())
		end)

		it("allows multiple variations of the same element", function()
			instance:add("builder_spec", false, false, {
				{ "x", "number" },
				{ "y", "number" }
			})
			assert.are.same({ "x", "name" }, instance.elements.builder_spec({ x = 20, name = "Johnny" }):map_fields())
			assert.are.same({ "x", "y" }, instance.elements.builder_spec({ x = 20, y = 30 }):map_fields())
			assert.are.equal("builder_spec[20;Johnny]", instance.elements.builder_spec({ x = 20, name = "Johnny" }):render())
			assert.are.equal("builder_spec[20;32]", instance.elements.builder_spec({ x = 20, y = 32 }):render())
		end)
	end)

	describe("element", function()
		it("adds a generic element with no default fields to the builder", function()
			instance = Builder:new()
			instance:element("builder_element", {})
		end)
	end)
end)

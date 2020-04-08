package.path = "../?.lua;" .. package.path
_G.libuix = {}
_G.modpath = "."
local on_player_receive_fields = {}
_G.minetest = {
	register_on_player_receive_fields = function(func) table.insert(on_player_receive_fields, func) end
}
local UIXInstance = require("tests/mock").UIXInstance
local types = require("types")
local FormspecManager = require("formspec/manager")

describe("FormspecManager", function()
	local instance = FormspecManager:new(UIXInstance:new("unit_test"))

	it("collects formspec name, options, elements, and model for addition to the instance", function()
		assert.has_no.error(function()
			instance("manager_spec") { w = 5, h = 10 } {
				ui.text { x = 0, y = model.text_y, text = "Hello!" }
			} { text_y = 0 }
		end)

		assert.are.equal("Placeholder", types.get(instance.forms[1].elements[1].def.y))
		assert.are.equal("Hello!", instance.forms[1].elements[1].def.text)
	end)

	describe("get", function()
		it("returns a formspec by name from the instance", function()
			assert.are.equal("manager_spec", instance:get("manager_spec").name)
			assert.are.equal("Form", types.get(instance:get("manager_spec")))
			assert.falsy(instance:get("invalid"))
		end)
	end)

	describe("get_index", function()
		it("returns a formspec index by name from the instance", function()
			assert.are.equal(1, instance:get_index("manager_spec"))
			assert.falsy(instance:get_index("invalid"))
		end)
	end)

	describe("receive_fields", function()
		it("passes received fields to the corresponding form", function()
			local output = ""
			getmetatable(instance.forms[1]).receive_fields = function(_, player, _)
				output = "Received input from " .. player
			end

			instance:receive_fields("John", "unit_test:invalid", {})
			assert.are.equal("", output)
			instance:receive_fields("John", "other:manager_spec", {})
			assert.are.equal("", output)
			instance:receive_fields("John", "unit_test:manager_spec", {})
			assert.are.equal("Received input from John", output)

			on_player_receive_fields[1]("Nathan", "unit_test:manager_spec", {})
			assert.are.equal("Received input from Nathan", output)
		end)
	end)
end)

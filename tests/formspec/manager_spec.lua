package.path = "../?.lua;" .. package.path
_G.libuix = {}
_G.modpath = "."
_G.minetest = {}
local FormspecManager = require("formspec/manager")

-- show_formspec mock function
local last_show_formspec_call = {}
function minetest.show_formspec(player_name, form_name, formstring)
	last_show_formspec_call = {player_name, form_name, formstring}
end

local expected_form = {
	name = "manager_spec",
	options = {w = 5, h = 10},
	elements = {
		{
			variations = {},
			name = "anchor",
			variation = {
				name = "anchor",
				cache = {
					map_fields = {"x", "y"},
				},
				fields = {
					{"x", "number", separator = ","},
					{"y", "number"}
				},
				def = {x = 0, y = 0}
			}
		}
	},
	model = {}
}

describe("FormspecManager", function()
	local instance = FormspecManager:new("unit_test")

	it("collects formspec name, options, elements, and model for addition to the instance", function()
		assert.has_no.error(function()
			instance("manager_spec") { w = 5, h = 10 } {
				anchor { x = 0, y = 0 }
			} {}
		end)
		assert.are.same(expected_form, instance.forms[1])
	end)

	describe("get", function()
		it("returns a formspec by name from the instance", function()
			assert.are.same(expected_form, instance:get("manager_spec"))
			assert.falsy(instance:get("invalid"))
		end)
	end)

	describe("get_index", function()
		it("returns a formspec index by name from the instance", function()
			assert.are.equal(1, instance:get_index("manager_spec"))
			assert.falsy(instance:get_index("invalid"))
		end)
	end)

	describe("render", function()
		it("returns a Minetest-compatible formspec string", function()
			assert.are.equal("real_coordinates[true]size[5,10]anchor[0,0]", instance:render("manager_spec"))
			assert.falsy(instance:render("invalid"))
		end)
	end)

	describe("show", function()
		it("shows a formspec to an in-game player", function()
			assert.has_no.error(function() instance:show("manager_spec", "singleplayer") end)
			assert.are.same({"singleplayer", "unit_test:manager_spec", "real_coordinates[true]size[5,10]anchor[0,0]"},
				last_show_formspec_call)
			assert.has_error(function() instance:show("invalid", "singleplayer") end,
				"libuix().formspec['invalid']:show: formspec does not exist or contains no elements")
		end)
	end)
end)

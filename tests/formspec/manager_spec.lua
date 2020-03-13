package.path = "../?.lua;" .. package.path
_G.libuix = {}
_G.modpath = "."
_G.minetest = {}
local UIXInstance = require("tests/mock").UIXInstance
local FormspecManager = require("formspec/manager")

-- show_formspec mock function
local last_show_formspec_call = {}
function minetest.show_formspec(player_name, form_name, formstring)
	last_show_formspec_call = {player_name, form_name, formstring}
end

describe("FormspecManager", function()
	local instance = FormspecManager:new(UIXInstance:new("unit_test"))

	it("collects formspec name, options, elements, and model for addition to the instance", function()
		assert.has_no.error(function()
			instance("manager_spec") { w = 5, h = 10 } {
				label { x = 0, y = 0, label = "Hello!" }
			} {}
		end)

		assert.are.equal("Hello!", instance.forms[1].elements[1].def.label)
	end)

	describe("formspec options include", function()
		it("formspec_version", function()
			(function() instance("formspec_version") {formspec_version = 2, w = 5, h = 10} {} {} end)()
			assert.are.equal("formspec_version[2]size[5,10]real_coordinates[true]", instance:render("formspec_version"))
		end)

		it("sizing", function()
			(function() instance("sizing") {w = 5, h = 10, fixed_size = true} {} {} end)()
			assert.are.equal("size[5,10,true]real_coordinates[true]", instance:render("sizing"))
			assert.has_error(function() instance("broken_sizing") {w = 5, h = "Hello!"} {} {} end)
		end)

		it("position", function()
			(function() instance("position") {w = 5, h = 10, position = {x = 5, y = 5}} {} {} end)()
			assert.are.equal("size[5,10]position[5,5]real_coordinates[true]", instance:render("position"))
			assert.has_error(function() instance("broken_position") {w = 5, h = 10, position = {x = "Hello!", y = 5}} {} {} end)
		end)

		it("anchor", function()
			(function() instance("anchor") {w = 5, h = 10, anchor = {x = 5, y = 5}} {} {} end)()
			assert.are.equal("size[5,10]anchor[5,5]real_coordinates[true]", instance:render("anchor"))
			assert.has_error(function() instance("broken_anchor") {w = 5, h = 10, anchor = {x = "Hello!", y = 5}} {} {} end)
		end)

		it("no_prepend", function()
			(function()
				instance("no_prepend") {no_prepend = true, w = 5, h = 10} {} {};
			end)();
			assert.are.equal("size[5,10]no_prepend[]real_coordinates[true]", instance:render("no_prepend"));
			-- NOTE: Semicolon at the end of the previous line is necessary to prevent an ambiguous syntax error.
			(function()
				instance("do_prepend") {no_prepend = false, w = 5, h = 10} {} {};
			end)();
			assert.are.equal("size[5,10]real_coordinates[true]", instance:render("do_prepend"))
		end)

		it("real_coordinates", function()
			(function() instance("real_coordinates") {real_coordinates = false, w = 5, h = 10} {} {} end)()
			assert.are.equal("size[5,10]real_coordinates[false]", instance:render("real_coordinates"))
		end)
	end)

	describe("get", function()
		it("returns a formspec by name from the instance", function()
			assert.are.equal("manager_spec", instance:get("manager_spec").name)
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
			assert.are.equal("size[5,10]real_coordinates[true]label[0,0;Hello!]", instance:render("manager_spec"))
			assert.falsy(instance:render("invalid"))
		end)
	end)

	describe("show", function()
		it("shows a formspec to an in-game player", function()
			assert.has_no.error(function() instance:show("manager_spec", "singleplayer") end)
			assert.are.same({"singleplayer", "unit_test:manager_spec", "size[5,10]real_coordinates[true]label[0,0;Hello!]"},
				last_show_formspec_call)
			assert.has_error(function() instance:show("invalid", "singleplayer") end,
				"libuix().formspec['invalid']:show: formspec does not exist or contains no elements")
		end)
	end)
end)

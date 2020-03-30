package.path = "../?.lua;" .. package.path
_G.libuix = {}
_G.modpath = "."
_G.minetest = {}
local manager = require("tests/mock").FormspecManager:new("form_spec")
manager.parent = {modname = "form_spec"}

local model = require("formspec/model"):new({})
local Form = require("formspec/form")

-- show_formspec mock function
local last_show_formspec_call = {}
function minetest.show_formspec(player_name, form_name, formstring)
	last_show_formspec_call = {player_name, form_name, formstring}
end

describe("Form", function()
	local form

	describe("formspec options include", function()
		it("formspec_version", function()
			(function() form = Form:new(manager, "formspec_version", {formspec_version = 2, w = 5, h = 10}, {}, model) end)()
			assert.are.equal("formspec_version[2]size[5,10]real_coordinates[true]", form:render())
		end)

		it("sizing", function()
			(function() form = Form:new(manager, "sizing", {w = 5, h = 10, fixed_size = true}, {}, model) end)()
			assert.are.equal("size[5,10,true]real_coordinates[true]", form:render())
			assert.has_error(function() form = Form:new(manager, "broken_sizing", {w = 5, h = "Hello!"}, {}, model) end)
		end)

		it("position", function()
			(function() form = Form:new(manager, "position", {w = 5, h = 10, position = {x = 5, y = 5}}, {}, model) end)()
			assert.are.equal("size[5,10]position[5,5]real_coordinates[true]", form:render())
			assert.has_error(function() form = Form:new(manager, "broken_position",
				{w = 5, h = 10, position = {x = "Hello!", y = 5}}, {}, model) end)
		end)

		it("anchor", function()
			(function() form = Form:new(manager, "anchor", {w = 5, h = 10, anchor = {x = 5, y = 5}}, {}, model) end)()
			assert.are.equal("size[5,10]anchor[5,5]real_coordinates[true]", form:render())
			assert.has_error(function() form = Form:new(manager, "broken_anchor",
				{w = 5, h = 10, anchor = {x = "Hello!", y = 5}}, {}, model) end)
		end)

		it("no_prepend", function()
			(function()
				form = Form:new(manager, "no_prepend", {no_prepend = true, w = 5, h = 10}, {}, model)
			end)();
			assert.are.equal("size[5,10]no_prepend[]real_coordinates[true]", form:render());
			-- NOTE: Semicolon at the end of the previous line is necessary to prevent an ambiguous syntax error.
			(function()
				form = Form:new(manager, "do_prepend", {no_prepend = false, w = 5, h = 10}, {}, model)
			end)();
			assert.are.equal("size[5,10]real_coordinates[true]", form:render())
		end)

		it("real_coordinates", function()
			(function() form = Form:new(manager, "real_coordinates", {real_coordinates = false, w = 5, h = 10}, {}, model) end)()
			assert.are.equal("size[5,10]real_coordinates[false]", form:render())
		end)
	end)

	describe("render", function()
		it("returns a Minetest-compatible formspec string", function()
			form = Form:new(manager, "form_render", {w = 5, h = 10}, {}, model)
			assert.are.equal("size[5,10]real_coordinates[true]", form:render())
		end)
	end)

	describe("show", function()
		it("shows a formspec to an in-game player", function()
			assert.has_no.error(function() form:show("singleplayer") end)
			assert.are.same({"singleplayer", "form_spec:form_render", "size[5,10]real_coordinates[true]"},
				last_show_formspec_call)
		end)
	end)
end)

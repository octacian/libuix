package.path = "../?.lua;" .. package.path
_G.libuix = {}
_G.modpath = "."

local mock = require("tests/mock")
local manager = mock.FormspecManager:new(nil, require("formspec/elements"))
local form = mock.Form:new()
local Variation = require("formspec/element/variation")
local Model = require("formspec/model")
local Placeholder = require("placeholder")
local types = require("types")

local field_name = { "name", "string" }
local Example = Variation:new(manager, "variation_spec", {
	{ "x",  "number", separator = "," },
	field_name,
	{ "y", "number", required = false },
	{ "_if", "string", required = false, internal = true },
	{ "ignore", "boolean", hidden = true, internal = true }
})

local AutoGen = Variation:new(manager, "auto_gen_spec", {
	{ "name", "string", generate = true }
})

-----------------------------------------------------------------------------------------------------------------------

describe("Variation", function()
	local instance = Example({ 20, name = "Example * 9.8", 32 })

	describe("get_field_by_name", function()
		it("returns a field given its name", function()
			local field = Example:get_field_by_name("name")
			assert.are.same(field_name, field)
		end)
	end)

	describe("map_fields", function()
		it("maps definition fields to those defined at the creation of the variation", function()
			instance:map_fields()
			assert.are.same({1, "name", 2}, instance.field_map)
			assert.are.same({[1] = 1, [2] = 3, name = 2}, instance.def_map)
			assert.are.same({x = 1, name = 2, y = 3, _if = 4, ignore = 5}, instance.field_names)
		end)
	end)

	describe("validate", function()
		it("errors if any required fields are missing unless they can be generated", function()
			assert.has_error(function() Example({ 20, y = 84 }):validate() end,
				"libuix->Variation:validate: variation_spec property 'name' is not optional")
			assert.has_no.error(function() Example({ 20, name = "Yay! It's broken somewhere else!" }):validate() end)
			assert.has_no.error(function() AutoGen({}):validate() end)
		end)

		it("checks the types of the values of definition fields", function()
			assert.has_no.errors(function() instance:validate() end)
			assert.has_error(function() Example({ 20, name = true, 32 }):validate() end,
				"libuix->Variation:validate: variation_spec property 'name' must be a string (found boolean)")
			assert.has_error(function() Example({ false, name = "Ayo", 32 }):validate() end,
				"libuix->Variation:validate: variation_spec property 'x' must be a number (found boolean)")
			assert.has_error(function() Example({ 45.2, name = 20, "Woah" }):validate() end,
				"libuix->Variation:validate: variation_spec property 'name' must be a string (found number)")
		end)

		it("can force key-type-value conformity", function()
			local ValueConform = Variation:new(manager, "value_conform_spec", {
				{ "control", "boolean", true, internal = true },
				field_name
			})

			local conform_instance
			assert.has_no.errors(function() conform_instance = ValueConform({ control = true, name = "John" }) end)
			assert.are.same("value_conform_spec[John]", conform_instance:render(form))

			assert.has_error(function() ValueConform({ control = false, name = "John" }) end, "libuix->Variation:validate: "
				.. "value_conform_spec property 'control' must be a boolean with value true (found boolean with value false)")
			assert.has_error(function() ValueConform({ control = true, name = 28 }) end,
				"libuix->Variation:validate: value_conform_spec property 'name' must be a string (found number)")
		end)

		it("catches fields not defined at the creation of the variation", function()
			assert.has_error(function() Example({ 20, nothing = true, name = "Yeah! This broke something!" }):validate() end,
				"libuix->Variation:validate: variation_spec does not support property 'nothing'")
			assert.has_error(function() Example({ 20, name = "John", ignore = true }):validate() end,
				"libuix->Variation:validate: variation_spec property 'ignore' is hidden and cannot be given a value")
		end)
	end)

	describe("evaluate", function()
		local Evaluate = Variation:new(manager, "evaluate_spec", {
			{ "type", "number", 1 },
			{ "x", "number" },
			{ "name", "string", hidden = true, generate = true },
			{ "text", "string" },
			{ "visible", "boolean", required = false }
		})

		local env = mock.Form:new(nil, {
			type = 2, another = true, show = Placeholder.index("model").another
		})

		it("returns a field from the definition table", function()
			local populated = Evaluate {
				type = 1, x = 10, text = "Hello!", visible = Placeholder.index("model").show
			}

			assert.are.equal(1, populated:evaluate(env, 1))
			assert.are.equal(10, populated:evaluate(env, 2))
			assert.are.equal("0", populated:evaluate(env, 3))
			assert.are.equal("Hello!", populated:evaluate(env, 4))
			assert.is_true(populated:evaluate(env, 5))
		end)

		it("throws an error when values do not conform to variant rules", function()
			local populated = Evaluate {
				type = Placeholder.index("model").type, x = Placeholder.index("model").show,
				text = Placeholder.index("model").control
			}

			assert.has_error(function() populated:evaluate(env, 1) end, "libuix->Variation:evaluate: evaluate_spec property "
				.. "'type' evaluated to a number with value 2 but the property requires a number with value 1")
			assert.has_error(function() populated:evaluate(env, 2) end, "libuix->Variation:evaluate: evaluate_spec property 'x' "
				.. "evaluated to a boolean but the property requires a number")
			assert.has_error(function() populated:evaluate(env, 4) end, "libuix->Variation:evaluate: evaluate_spec property "
				.. "'text' evaluated to nil but the property is not optional")
			assert.are.equal("", populated:evaluate(env, 5))
		end)
	end)

	describe("evaluate_by_name", function()
		it("returns a field, identified by name, from the definition table", function()
			local EvaluateByName = Variation:new(manager, "evaluate_by_name_spec", {
				{"x", "number"}
			})

			local populated = EvaluateByName { 28 }
			local x, x_exists = populated:evaluate_by_name(form, "x")
			assert.are.equal(28, x)
			assert.is_true(x_exists)

			local y, y_exists = populated:evaluate_by_name(form, "y")
			assert.is_nil(y)
			assert.is_false(y_exists)
		end)
	end)

	describe("render", function()
		it("autogenerates necessary fields", function()
			local last_id = form.last_id + 1
			assert.are.equal("auto_gen_spec[" .. last_id .. "]", AutoGen({}):render(form))
			assert.are.equal("auto_gen_spec[45]", AutoGen({ name = "45" }):render(form))
		end)

		it("outputs a string compatible with Minetest formspecs", function()
			assert.are.equal("variation_spec[20,Example * 9.8;32]", instance:render(form))
		end)

		it("inserts extra separators for optional fields", function()
			assert.are.equal("variation_spec[20,Will this break?;]", Example({ 20, name = "Will this break?" }):render(form))
		end)

		it("obeys visibility rules", function()
			assert.are.equal("",
				Example({20, name = "Invisible", _if = "show"}):render(mock.Form:new(nil, Model:new {show = false})))
			assert.are.equal("variation_spec[20,Visible;]",
				Example({20, name = "Visible", _if = "show"}):render(mock.Form:new(nil, Model:new {show = true})))
		end)

		it("obeys options that affect render output", function()
			local RenderName = Variation:new(manager, "render_name_spec", {field_name}, { render_name = "custom_render_name" })
			assert.are.same("custom_render_name[John]", RenderName({ name = "John" }):render(form))

			local RenderAppend = Variation:new(manager, "render_append_spec", {field_name}, { render_append = "label[0,0;Hi]" })
			assert.are.same("render_append_spec[John]label[0,0;Hi]", RenderAppend({ name = "John" }):render(form))

			local RenderRaw = Variation:new(manager, "render_raw_spec", {field_name, {"x", "number"}}, { render_raw = true })
			assert.are.same("John;10", RenderRaw({ name = "John", x = 10 }):render(form))
		end)
	end)

	it("correctly handles boolean fields", function()
		Example = Variation:new(manager, "boolean_spec", {
			{ "option", "boolean" }
		})

		assert.are.equal("boolean_spec[true]", Example({ option = true }):render(form))
		assert.are.equal("boolean_spec[false]", Example({ option = false }):render(form))
	end)

	describe("supports container elements", function()
		it("encapsulating other elements", function()
			Example = Variation:new(manager, "container_spec", {
				{"x", "number", separator = ","},
				{"y", "number"}
			}, {contains = {
				validate = "Variation",
				environment = function(self)
					return self.parent.elements
				end,
				render = function(self, render_form)
					local contained = ""
					for _, item in ipairs(self.items) do
						contained = contained .. item:render(render_form)
					end
					return contained .. self.name .. "_end[]"
				end
			}})

			local populated
			assert.has_no.error(function()
				populated = Example { x = 15, y = 7 } {
					ui.text { x = 0, y = model.text_y, text = "Hello!" }
				}
			end)

			assert.are.equal("Placeholder", types.get(populated.items[1].def.y))
			local env = mock.Form:new(nil, { text_y = 0 })
			assert.are.equal("container_spec[15,7]label[0,0;Hello!]container_spec_end[]", populated:render(env))
		end)

		it("encapsulating custom structures", function()
			Example = Variation:new(manager, "custom_container_spec", {
				{"x", "number"},
				{"items", "string", hidden = true }
			}, {contains = {
				validate = function(self, items)
					for _, item in pairs(items) do
						if type(item) ~= "string" then
							error("Expected string!")
						end
					end
				end,
				render = function(self, _)
					return table.concat(self.items, ",")
				end,
				render_target = "items"
			}})

			local populated
			assert.has_no.error(function()
				populated = Example { x = 10 } {
					"hello", "world"
				}
			end)
			assert.are.equal("custom_container_spec[10;hello,world]", populated:render(form))
		end)
	end)

	describe("receive_fields", function()
		it("handles formspec input and runs callbacks", function()
			local output = ""
			local receive_fields_def = {
				{"name", "string", hidden = true, generate = true},
				{"click", "function", required = false}
			}
			local on_click = function(player, field)
				output = "Received click from " .. player .. " with field " .. tostring(field)
			end

			local ReceiveFields = Variation:new(manager, "receive_fields_spec", receive_fields_def,
				{receive_fields = {callback = "click"}})

			local populated = ReceiveFields { click = on_click }
			populated:receive_fields(form, "oct", true)
			assert.are.equal("Received click from oct with field nil", output)

			local ReceiveFieldsFunc = Variation:new(manager, "receive_fields_func_spec", receive_fields_def, {
				receive_fields = { callback = function(_, _, player, field)
					output = "Received input from " .. player
				end }
			})

			populated = ReceiveFieldsFunc {}
			populated:receive_fields(form, "oct", true)
			assert.are.equal("Received input from oct", output)

			local ReceiveFieldsWithField = Variation:new(manager, "receive_fields_with_field_spec", receive_fields_def, {
				receive_fields = {callback = "click", pass_field = true}
			})

			populated = ReceiveFieldsWithField { click = on_click }
			populated:receive_fields(form, "oct", true)
			assert.are.equal("Received click from oct with field true", output)
		end)
	end)
end)

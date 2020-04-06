package.path = "../?.lua;" .. package.path
_G.libuix = {}
_G.modpath = "."
local form = require("tests/mock").Form:new()
local FormspecManager = require("tests/mock").FormspecManager
local Builder = require("formspec/element/builder")
local utility = require("utility")

describe("Builder", function()
	local instance = Builder:new(FormspecManager:new("builder_spec"))

	describe("add", function()
		it("adds a generic element to the builder", function()
			assert.are.equal(0, table.count(instance.elements))
			instance:add("builder_spec", false, false, {
				{ "x", "number" },
				{ "name", "string" }
			})
			assert.are.equal(1, table.count(instance.elements))
			assert.are.equal("builder_spec[20;bork]", instance.elements.builder_spec({ x = 20, name = "bork" }):render(form))
		end)

		it("allows multiple variations of the same element", function()
			instance:add("builder_spec", false, false, {
				{ "x", "number" },
				{ "y", "number" }
			})
			assert.are.equal("builder_spec[20;Johnny]", instance.elements.builder_spec({ x = 20, name = "Johnny" }):render(form))
			assert.are.equal("builder_spec[20;32]", instance.elements.builder_spec({ x = 20, y = 32 }):render(form))
		end)

		it("can generate a sub-table of child elements", function()
			instance:add("child_elements_spec", false, false, { "x", "number" }, {
				child_elements = function(builder)
					builder:add("item", false, false, { "label", "string" })
				end
			})
			assert.are.equal("Variation", utility.type(instance.elements.child_elements_spec.child_elements.item))
		end)
	end)

	describe("element", function()
		it("adds a generic element with no default fields to the builder", function()
			instance = Builder:new(FormspecManager:new("builder_spec"))
			instance:element("builder_element", {})
			local expected = {
				builder_element = {
					field_names = {},
					parent = {modname = "builder_spec"},
					name = "builder_element",
					fields = {instance.default_fields._if},
				}
			}

			assert.are.same(expected, instance.elements)
		end)
	end)

	describe("positioned", function()
		it("adds an element with default fields (x, y: number) to the builder", function()
			instance = Builder:new(FormspecManager:new("builder_spec"))
			instance:positioned("builder_element", {})
			assert.are.same({instance.default_fields.x, instance.default_fields.y, instance.default_fields._if},
				instance.elements.builder_element.fields)
		end)
	end)

	describe("resizable", function()
		it("adds an element with default fields (w, h: number) to the builder", function()
			instance = Builder:new(FormspecManager:new("builder_spec"))
			instance:resizable("builder_element", {})
			assert.are.same({instance.default_fields.w, instance.default_fields.h, instance.default_fields._if},
				instance.elements.builder_element.fields)
		end)
	end)

	describe("rect", function()
		it("adds an element with default fields (x, y, w, h: number) to the builder", function()
			instance = Builder:new(FormspecManager:new("builder_spec"))
			instance:rect("builder_element", {})
			assert.are.same({
				instance.default_fields.x, instance.default_fields.y, instance.default_fields.w, instance.default_fields.h,
				instance.default_fields._if
			}, instance.elements.builder_element.fields)
		end)
	end)
end)

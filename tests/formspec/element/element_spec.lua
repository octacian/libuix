package.path = "../?.lua;" .. package.path
_G.libuix = {}
_G.modpath = "."
local form = require("tests/mock").Form:new()
local FormspecManager = require("tests/mock").FormspecManager
local Element = require("formspec/element/element")

local element = Element:new(FormspecManager:new(), "element_spec")
element:add_variation({
	{ "x", "number" }
})
element:add_variation({
	{ "show", "boolean" }
})
element:add_variation({
	{ "name", "string" }
})
element:add_variation({
	{ "example", "number" },
	{ "option", "boolean", required = false }
})

describe("Element", function()
	it("chooses the correct variation given a definition", function()
		assert.are.equal("element_spec[20]", element({ x = 20 }):render(form))
		assert.are.equal("element_spec[true]", element({ true }):render(form))
		assert.are.equal("element_spec[Yo!]", element({ name = "Yo!" }):render(form))
		assert.has.error(function() element({ x = 20, name = "You done messed up" }) end)
	end)

	it("does not interfere with optional fields", function()
		assert.are.equal("element_spec[10;]", element({ example = 10 }):render(form))
		assert.are.equal("element_spec[10;true]", element({ example = 10, option = true }):render(form))
		assert.are.equal("element_spec[10;false]", element({ example = 10, option = false }):render(form))
	end)
end)

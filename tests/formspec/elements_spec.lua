package.path = "../?.lua;" .. package.path
_G.libuix = {}
_G.modpath = "."
local manager = require("tests/mock").FormspecManager:new(nil, require("formspec/elements"))

function test(name, expected, fields)
	local message = "takes "
	if fields == nil or table.count(fields) == 0 then
		message = "has no fields"
	else
		local types = {}
		for _, field in pairs(fields) do
			local type_name = type(field)
			if not types[type_name] then types[type_name] = 0
			else types[type_name] = types[type_name] + 1 end
		end

		for type_name, count in pairs(types) do
			message = message .. ("%d %ss "):format(count, type_name)
		end

		message = message:sub(1, -2)
	end

	describe(("'%s' element"):format(name), function()
		it(message, function()
			assert.are.equal(("%s[%s]"):format(name, expected), manager.elements[name](fields):render())
		end)
	end)
end

describe("'container' element", function()
	it("takes (x, y: number) and contains an arbitrary number of sub-elements", function()
		local populated
		(function()
			populated = manager.elements.container { x = 2, y = 2 } {
				label { x = 0, y = 0, label = "Hello!" }
			}
		end)()
		assert.are.equal("container[2,2]label[0,0;Hello!]container_end[]", populated:render())
	end)
end)

test("list", "location;name;2,3;5,5;",
	{ inventory_location = "location", list_name = "name", x = 2, y = 3, w = 5, h = 5 })
test("list", "location;name;2,3;5,5;0",
	{ inventory_location = "location", list_name = "name", x = 2, y = 3, w = 5, h = 5, starting_item_index = 0 })
test("listring", "location;name", { inventory_location = "location", list_name = "name" })
test("listring", "", {})
test("listcolors", "one;two", { slot_bg_normal = "one", slot_bg_hover = "two" })
test("listcolors", "one;two;three", { slot_bg_normal = "one", slot_bg_hover = "two", slot_border = "three" })
test("listcolors", "one;two;three;four;five", {
	slot_bg_normal = "one", slot_bg_hover = "two", slot_border = "three",
	tooltip_bgcolor = "four", tooltip_fontcolor = "five"
})
-- TODO: tooltip element, implemented as a field for any elements supporting `name`.
test("image", "0,0;5,5;img.png", { x = 0, y = 0, w = 5, h = 5, texture_name = "img.png" })

test("label", "0,0;Hello world!", { x = 0, y = 0, label = "Hello world!" })

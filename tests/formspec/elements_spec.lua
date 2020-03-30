package.path = "../?.lua;" .. package.path
_G.libuix = {}
_G.modpath = "."
local manager = require("tests/mock").FormspecManager:new(nil, require("formspec/elements"))

function test(name, expected_name, expected, fields, append_str)
	if not expected_name then expected_name = name end
	if not append_str then append_str = "" end

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

		if expected_name ~= name then
			message = message .. (" and should render as '%s'"):format(expected_name)
		end

		if append_str ~= "" then
			if expected_name == name then
				message = message .. " and should render"
			end

			message = message .. " with a string appended"
		end
	end

	describe(("'%s' element"):format(name), function()
		it(message, function()
			assert.are.equal(("%s[%s]%s"):format(expected_name, expected, append_str), manager.elements[name](fields):render())
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

test("list", nil, "location;name;2,3;5,5;",
	{ inventory_location = "location", list_name = "name", x = 2, y = 3, w = 5, h = 5 })
test("list", nil, "location;name;2,3;5,5;0",
	{ inventory_location = "location", list_name = "name", x = 2, y = 3, w = 5, h = 5, starting_item_index = 0 })
test("listring", nil, "location;name", { inventory_location = "location", list_name = "name" })
test("listring", nil, "", {})
test("listcolors", nil, "one;two", { slot_bg_normal = "one", slot_bg_hover = "two" })
test("listcolors", nil, "one;two;three", { slot_bg_normal = "one", slot_bg_hover = "two", slot_border = "three" })
test("listcolors", nil, "one;two;three;four;five", {
	slot_bg_normal = "one", slot_bg_hover = "two", slot_border = "three",
	tooltip_bgcolor = "four", tooltip_fontcolor = "five"
})
-- TODO: tooltip element, implemented as a field for any elements supporting `name`.
test("image", nil, "0,0;5,5;img.png", { x = 0, y = 0, w = 5, h = 5, texture_name = "img.png" })
test("image", nil, "0,0;5,5;img.png", { x = 0, y = 0, w = 5, h = 5, type = "standard", texture_name = "img.png" })
test("image", "animated_image", "0,0;5,5;anim;anim.png;10;500;", { x = 0, y = 0, w = 5, h = 5, type = "animated",
	name = "anim", texture_name = "anim.png", frame_count = 10, frame_duration = 500 })
test("image", "animated_image", "0,0;5,5;anim;anim.png;10;500;2", { x = 0, y = 0, w = 5, h = 5, type = "animated",
	name = "anim", texture_name = "anim.png", frame_count = 10, frame_duration = 500, frame_start = 2 })
test("image", "item_image", "0,0;5,5;default:stick", { x = 0, y = 0, w = 5, h = 5, type = "item",
	item_name = "default:stick" })
test("button", nil, "0,0;2,1;btn;Press Me!", { x = 0, y = 0, w = 2, h = 1, name = "btn", label = "Press Me!" })
test("button", "button_exit", "0,0;2,1;btn;Press Me!", { x = 0, y = 0, w = 2, h = 1, name = "btn", label = "Press Me!",
	exit = true })
test("button", nil, "0,0;2,1;btn;Press Me!", { x = 0, y = 0, w = 2, h = 1, type = "standard", name = "btn",
	label = "Press Me!" })
test("button", "button_exit", "0,0;2,1;btn;Press Me!", { x = 0, y = 0, w = 2, h = 1, type = "standard", name = "btn",
	label = "Press Me!", exit = true })
test("button", "image_button", "0,0;2,1;btn.png;btn;Press Me!", { x = 0, y = 0, w = 2, h = 1, type = "image",
	texture_name = "btn.png", name = "btn", label = "Press Me!"})
test("button", "image_button", "0,0;2,1;btn.png;btn;Press Me!;true;true;pressed.png", { x = 0, y = 0, w = 2, h = 1,
	type = "image", texture_name = "btn.png", name = "btn", label = "Press Me!", noclip = true, drawborder = true,
	pressed_texture_name = "pressed.png"})
test("button", "image_button_exit", "0,0;2,1;btn.png;btn;Press Me!", { x = 0, y = 0, w = 2, h = 1, type = "image",
	texture_name = "btn.png", name = "btn", label = "Press Me!", exit = true})
test("button", "image_button_exit", "0,0;2,1;btn.png;btn;Press Me!;true;true;pressed.png", { x = 0, y = 0, w = 2, h = 1,
	type = "image", texture_name = "btn.png", name = "btn", label = "Press Me!", noclip = true, drawborder = true,
	pressed_texture_name = "pressed.png", exit = true})
test("button", "item_image_button", "0,0;1,1;default:stick;btn;Press Me!", { x = 0, y = 0, w = 1, h = 1, type = "item",
	item_name = "default:stick", name = "btn", label = "Press Me!"})
test("field", "pwdfield", "0,0;2,1;pwd;", { x = 0, y = 0, w = 2, h = 1, type = "password", name = "pwd" })
test("field", "pwdfield", "0,0;2,1;pwd;Password", { x = 0, y = 0, w = 2, h = 1, type = "password", name = "pwd",
	label = "Password" })
test("field", "pwdfield", "0,0;2,1;pwd;Password", { x = 0, y = 0, w = 2, h = 1, type = "password", name = "pwd",
	label = "Password", close_on_enter = false }, "field_close_on_enter[pwd;false]")
test("field", nil, "0,0;2,1;input;;", { x = 0, y = 0, w = 2, h = 1, name = "input" })
test("field", nil, "0,0;2,1;input;Input;", { x = 0, y = 0, w = 2, h = 1, name = "input", label = "Input" })
test("field", nil, "0,0;2,1;input;;abcdef", { x = 0, y = 0, w = 2, h = 1, name = "input", default = "abcdef" })
test("field", nil, "0,0;2,1;input;;", { x = 0, y = 0, w = 2, h = 1, name = "input", close_on_enter = false },
	"field_close_on_enter[input;false]")
test("field", nil, "0,0;2,1;input;;", { x = 0, y = 0, w = 2, h = 1, type = "text", name = "input" })
test("field", nil, "0,0;2,1;input;;", { x = 0, y = 0, w = 2, h = 1, type = "text", name = "input",
	close_on_enter = false }, "field_close_on_enter[input;false]")
test("textarea", nil, "0,0;5,5;text;;", { x = 0, y = 0, w = 5, h = 5, name = "text" })
test("textarea", nil, "0,0;5,5;text;Text;", { x = 0, y = 0, w = 5, h = 5, name = "text", label = "Text" })
test("textarea", nil, "0,0;5,5;text;;abcdefg", { x = 0, y = 0, w = 5, h = 5, name = "text", default = "abcdefg" })

test("label", nil, "0,0;Hello world!", { x = 0, y = 0, label = "Hello world!" })

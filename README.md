MVVM Formspec UI Library [libuix]
=================================

libuix is a user interface library for Minetest, designed to replace the messy, error-prone combination of string-based formspec definitions and catch-all `on_receive_fields` callbacks with a simplistic [Model-view-viewmodel \(MVVM\)](https://en.wikipedia.org/wiki/Model%E2%80%93view%E2%80%93viewmodel) approach inspired by [Vue.js](https://vuejs.org/).

**Wait!** This library is in super-early developmental stages. It can't be used at all yet in the real world. But do not fear! There is not much more to be done.

In the meantime, **contributors would be greatly appreciated**. There is no public todo list at the moment, so if you are interested please contact [octacian](https://github.com/octacian).

## Example

Let's create and show a very simple formspec with just three elements:
- A field that takes an arbitrary message.
- A button that prints to the log when it is clicked.
- A label repeating back the message entered, as long as it is not blank.

```lua
uix:formspec("example") { w = 5, h = 5 } {
	ui.field { x = 0, y = 1, w = 5, h = 1, label = "Message:", bind = model.message },
	ui.button { x = 0, y = 2.5, w = 5, h = 1, label = "Submit", click = model.submit },
	ui.text { x = 0, y = 4, visible = ne(model.message, ""), text = "You said: " .. model.message }
} {
	message = "",
	submit = function()
		print("Hey! " .. model._player_name .. " submitted our form!")
	end
}

uix:formspec("example"):show("singleplayer")
```

And just in case you're not a fan of having to type the name of each property, you don't have to:

```lua
{
	ui.field { 0, 1, 5, 1, "Message:", bind = model.message }
}
```

## Comparison

The formspec we created above seems very simple, and that's because it is! But what does it look like using just core Minetest APIs?

```lua
local function render(player, message)
	local formstring = [[
		size[5,5]
		real_coordinates[true]
		field[0,1;5,1;message;Message;]
		button[0,2.5;5,1;submit;Submit]
	]]

	if message ~= "" then
		formstring = formstring .. "label[0,4;You said: " .. message .. "]"
	end

	minetest.show_formspec(player, "example:example", formstring)
end

minetest.register_on_player_receive_fields(function(player, formname, fields)
	if formname == "example:example" then
		if fields.submit then
			print("Hey! " .. player .. " submitted our form!")
		end

		if fields.message then
			render(player, message)
		end
	end
end)

render("singleplayer", "")
```

With such a simple formspec it is not at all complex to achieve the same result with the core Minetest APIs, however, it is without question much more logically complex than is the libuix iteration, besides requiring more code and being less concise.

For those of you more numerically inclined, here are some raw lines-of-code statistics (warning: they may be somewhat biased due to stylization).

| Task                   | libuix | Minetest | % less code necessary |
| ---------------------- | ------ | -------- | --------------------- |
| Showing the formspec   | 5      | 12       | 41.6%                 |
| Handling submissions   | 4      | 10       | 40%                   |
| Overall                | 11     | 23       | 47.8%                 |

And this is just with a very simple formspec. As an interface scales and becomes more complex with many pages and interactive elements, the differences observed above will become more established and a greater gap in lines-of-code will quickly materialize. On top of all this is the increased quality-of-life for the developer: libuix allows complex tasks to be achieved with only the absolutely necessary logic, leaving fewer things to go wrong and decreasing overall complexity.

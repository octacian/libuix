local Queue = import("queue.lua")
local Builder = import("formspec/element/builder.lua")

local fields = Builder.default_fields
local queue = Queue:new()

--------------
-- Elements --
--------------

queue:positioned("container", {}, {contains = {
	validate = "Variation",
	environment = function(self)
		return self.parent.elements
	end,
	render = function(self, form)
		local contained = ""
		for _, item in ipairs(self.items) do
			contained = contained .. item:render(form)
		end
		return contained .. self.name .. "_end[]"
	end
}})

queue:element("list", {
	{ "inventory_location", "string" },
	{ "list_name", "string" },
	fields.x, fields.y, fields.w, fields.h,
	{ "starting_item_index", "number", required = false }
})

queue:element("listring", {
	{ "inventory_location", "string" },
	{ "list_name", "string" }
})

queue:element("listring")

queue:element("listcolors", {
	{ "slot_bg_normal", "string" },
	{ "slot_bg_hover", "string" }
})

queue:element("listcolors", {
	{ "slot_bg_normal", "string" },
	{ "slot_bg_hover", "string" },
	{ "slot_border", "string" }
})

queue:element("listcolors", {
	{ "slot_bg_normal", "string" },
	{ "slot_bg_hover", "string" },
	{ "slot_border", "string" },
	{ "tooltip_bgcolor", "string" },
	{ "tooltip_fontcolor", "string" }
})

queue:rect("image", {
	{ "texture_name", "string" }
})

queue:rect("image", {
	{ "type", "string", "standard", internal = true },
	{ "texture_name", "string" }
})

queue:rect("image", {
	{ "type", "string", "animated", internal = true },
	{ type = "name" },
	{ "texture_name", "string" },
	{ "frame_count", "number" },
	{ "frame_duration", "number" },
	{ "frame_start", "number", required = false },
	{ type = "callback", "update" },
}, { render_name = "animated_image", receive_fields = { callback = "update", pass_field = true } })

queue:rect("image", {
	{ "type", "string", "item", internal = true },
	{ "item_name", "string" }
}, { render_name = "item_image" })

queue:positioned("text", {
	{ "text", "string" },
}, { render_name = "label" })

queue:positioned("text", {
	{ "type", "string", "horizontal", internal = true },
	{ "text", "string" }
}, { render_name = "label" })

queue:positioned("text", {
	{ "type", "string", "vertical", internal = true },
	{ "text", "string" }
}, { render_name = "vertlabel" })

queue:rect("text", {
	{ "type", "string", "plain", internal = true },
	{ "name", "string", hidden = true },
	{ "label", "string", hidden = true },
	{ "text", "string" }
}, { render_name = "textarea" })

queue:rect("text", {
	{ "type", "string", "markup", internal = true },
	{ type = "name" },
	{ "text", "string" }
}, { render_name = "hypertext" })

local button_render_name_modifier = function(base_render_name)
	return function(self)
		if self.def.exit == true then
			return base_render_name .. "_exit"
		else return base_render_name end
	end
end

queue:rect("button", {
	{ type = "name" },
	{ "label", "string" },
	{ "exit", "boolean", required = false, internal = true },
	{ type = "callback", "click" }
}, { render_name = button_render_name_modifier("button"), receive_fields = { callback = "click" } })

queue:rect("button", {
	{ "type", "string", "standard", internal = true },
	{ type = "name" },
	{ "label", "string" },
	{ "exit", "boolean", required = false, internal = true },
	{ type = "callback", "click" }
}, { render_name = button_render_name_modifier("button"), receive_fields = { callback = "click" } })

queue:rect("button", {
	{ "type", "string", "image", internal = true },
	{ "texture_name", "string" },
	{ type = "name" },
	{ "label", "string" },
	{ "exit", "boolean", required = false, internal = true },
	{ type = "callback", "click" }
}, { render_name = button_render_name_modifier("image_button"), receive_fields = { callback = "click" } })

queue:rect("button", {
	{ "type", "string", "image", internal = true },
	{ "texture_name", "string" },
	{ type = "name" },
	{ "label", "string" },
	{ "noclip", "boolean" },
	{ "drawborder", "boolean" },
	{ "pressed_texture_name", "string" },
	{ "exit", "boolean", required = false, internal = true },
	{ type = "callback", "click" }
}, { render_name = button_render_name_modifier("image_button"), receive_fields = { callback = "click" } })

queue:rect("button", {
	{ "type", "string", "item", internal = true },
	{ "item_name", "string" },
	{ type = "name" },
	{ "label", "string" },
	{ "exit", "boolean", required = false, internal = true },
	{ type = "callback", "click" }
}, { render_name = "item_image_button", receive_fields = { callback = "click" } })

local field_append_modifier = function(self)
	if self.def.close_on_enter == false then
		return "field_close_on_enter[" .. self.def.name .. ";false]"
	else return "" end
end

local field_receive_fields = {
	callback = "enter",
	pass_field = true
}

queue:rect("field", {
	{ "type", "string", "password", internal = true },
	{ type = "name" },
	{ "label", "string", required = false },
	{ "close_on_enter", "boolean", required = false, internal = true },
	{ type = "callback", "enter" },
}, { render_name = "pwdfield", render_append = field_append_modifier, receive_fields = field_receive_fields })

queue:rect("field", {
	{ type = "name" },
	{ "label", "string", required = false },
	{ "default", "string", required = false },
	{ "close_on_enter", "boolean", required = false, internal = true },
	{ type = "callback", "enter" }
}, { render_append = field_append_modifier, receive_fields = field_receive_fields })

queue:rect("field", {
	{ "type", "string", "text", internal = true },
	{ type = "name" },
	{ "label", "string", required = false },
	{ "default", "string", required = false },
	{ "close_on_enter", "boolean", required = false, internal = true },
	{ type = "callback", "enter" }
}, { render_append = field_append_modifier, receive_fields = field_receive_fields })

queue:rect("textarea", {
	{ type = "name" },
	{ "label", "string", required = false },
	{ "default", "string", required = false },
	{ type = "callback", "enter" }
}, { receive_fields = field_receive_fields })

queue:rect("dropdown", {
	{ type = "name" },
	{ "items", "string", hidden = true },
	{ "selected", "number" }
}, {
	receive_fields = { callback = function(self, form, player, field)
		for _, item in pairs(self.items) do
			if item:evaluate_by_name(form, "label") == field then
				item:receive_fields(form, player, field)
				break
			end
		end
	end },
	child_elements = function(builder)
		builder:element("item", {
			{ "label", "string" },
			{ type = "callback", "select" }
		}, { render_raw = true, receive_fields = { callback = "select" } })
	end,
	contains = {
		validate = function(self, items)
			for index, item in pairs(items) do
				if type(item) == "string" then
					items[index] = self.child_elements.item({ label = item })
				elseif type(item) == "table" then
					items[index] = self.child_elements.item(item)
				end
			end
		end,
		render = function(self, form)
			local contained = ""
			for _, item in pairs(self.items) do
				contained = contained .. item:render(form) .. ";"
			end
			return contained:sub(1, -2)
		end,
		render_target = "items"
	}
})

-------------
-- Exports --
-------------

return function(parent)
	local builder = Builder:new(parent)
	queue:_start(builder)
	return builder.elements
end

local utility = dofile(modpath.."/utility.lua")
local Builder = dofile(modpath.."/formspec/element/builder.lua")

local field = Builder.default_fields
local queue = utility.Queue:new()

--------------
-- Elements --
--------------

queue:positioned("container", {}, {contains = "Variation"})

queue:element("list", {
	{ "inventory_location", "string" },
	{ "list_name", "string" },
	field.x, field.y, field.w, field.h,
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
	{ "name", "string" },
	{ "texture_name", "string" },
	{ "frame_count", "number" },
	{ "frame_duration", "number" },
	{ "frame_start", "number", required = false }
}, { render_name = "animated_image" })

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
	{ "name", "string" },
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
	{ "name", "string" },
	{ "label", "string" },
	{ "exit", "boolean", required = false, internal = true }
}, { render_name = button_render_name_modifier("button") })

queue:rect("button", {
	{ "type", "string", "standard", internal = true },
	{ "name", "string" },
	{ "label", "string" },
	{ "exit", "boolean", required = false, internal = true }
}, { render_name = button_render_name_modifier("button") })

queue:rect("button", {
	{ "type", "string", "image", internal = true },
	{ "texture_name", "string" },
	{ "name", "string" },
	{ "label", "string" },
	{ "exit", "boolean", required = false, internal = true }
}, { render_name = button_render_name_modifier("image_button") })

queue:rect("button", {
	{ "type", "string", "image", internal = true },
	{ "texture_name", "string" },
	{ "name", "string" },
	{ "label", "string" },
	{ "noclip", "boolean" },
	{ "drawborder", "boolean" },
	{ "pressed_texture_name", "string" },
	{ "exit", "boolean", required = false, internal = true }
}, { render_name = button_render_name_modifier("image_button") })

queue:rect("button", {
	{ "type", "string", "item", internal = true },
	{ "item_name", "string" },
	{ "name", "string" },
	{ "label", "string" },
	{ "exit", "boolean", required = false, internal = true }
}, { render_name = "item_image_button" })

local field_append_modifier = function(self)
	if self.def.close_on_enter == false then
		return "field_close_on_enter[" .. self.def.name .. ";false]"
	else return "" end
end

queue:rect("field", {
	{ "type", "string", "password", internal = true },
	{ "name", "string" },
	{ "label", "string", required = false },
	{ "close_on_enter", "boolean", required = false, internal = true }
}, { render_name = "pwdfield", render_append = field_append_modifier })

queue:rect("field", {
	{ "name", "string" },
	{ "label", "string", required = false },
	{ "default", "string", required = false },
	{ "close_on_enter", "boolean", required = false, internal = true }
}, { render_append = field_append_modifier })

queue:rect("field", {
	{ "type", "string", "text", internal = true },
	{ "name", "string" },
	{ "label", "string", required = false },
	{ "default", "string", required = false },
	{ "close_on_enter", "boolean", required = false, internal = true }
}, { render_append = field_append_modifier })

queue:rect("textarea", {
	{ "name", "string" },
	{ "label", "string", required = false },
	{ "default", "string", required = false }
})

-------------
-- Exports --
-------------

return function(parent)
	local builder = Builder:new(parent)
	queue:_start(builder)
	return builder.elements
end

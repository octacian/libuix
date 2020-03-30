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

queue:positioned("label", {
	{ "label", "string" }
})

-------------
-- Exports --
-------------

return function(parent)
	local builder = Builder:new(parent)
	queue:_start(builder)
	return builder.elements
end

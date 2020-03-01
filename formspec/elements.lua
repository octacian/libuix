local Builder = dofile(modpath.."/formspec/element/builder.lua")
local builder = Builder:new()

local field = builder.default_fields

--------------
-- Elements --
--------------

-- TODO: Container element.

builder:element("list", {
	{ "inventory_location", "string" },
	{ "list_name", "string" },
	field.x, field.y, field.w, field.h,
	{ "starting_item_index", "number", required = false }
})

builder:element("listring", {
	{ "inventory_location", "string" },
	{ "list_name", "string" }
})

builder:element("listring")

builder:element("listcolors", {
	{ "slot_bg_normal", "string" },
	{ "slot_bg_hover", "string" }
})

builder:element("listcolors", {
	{ "slot_bg_normal", "string" },
	{ "slot_bg_hover", "string" },
	{ "slot_border", "string" }
})

builder:element("listcolors", {
	{ "slot_bg_normal", "string" },
	{ "slot_bg_hover", "string" },
	{ "slot_border", "string" },
	{ "tooltip_bgcolor", "string" },
	{ "tooltip_fontcolor", "string" }
})

builder:rect("image", {
	{ "texture_name", "string" }
})

builder:positioned("label", {
	{ "label", "string" }
})

-------------
-- Exports --
-------------

return builder.elements

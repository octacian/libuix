local utility = dofile(modpath.."/utility.lua")
local Builder = dofile(modpath.."/formspec/element/builder.lua")

local field = Builder.default_fields
local queue = utility.Queue:new()

--------------
-- Elements --
--------------

-- TODO: Container element.

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

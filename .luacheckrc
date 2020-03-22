unused_args = false
allow_defined_top = true

globals = {
	"table",
	"minetest"
}

read_globals = {
	string = {fields = {"split"}},
	--table = {fields = {"copy", "getn"}},

	-- Builtin
	"vector", "ItemStack",
	"dump", "DIR_DELIM", "VoxelArea", "Settings",

	"modpath",

	-- libuix elements
	"list", "listring", "listcolors", "image", "label",
}

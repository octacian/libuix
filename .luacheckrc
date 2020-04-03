unused_args = false
allow_defined_top = true

globals = {
	"table",
	"minetest",
	"model"
}

read_globals = {
	string = {fields = {"split"}},
	--table = {fields = {"copy", "getn"}},

	-- Builtin
	"vector", "ItemStack",
	"dump", "DIR_DELIM", "VoxelArea", "Settings",

	"libuix", "import", "ui",

	-- libuix operator replacement functions
	"eq", "ne", "lt", "gt", "le", "ge", "land", "lor", "lnot"
}

unused_args = false
allow_defined_top = true

globals = {
	"table",
	"string",
	"minetest",
	"model"
}

read_globals = {
	--string = {fields = {"split"}},
	--table = {fields = {"copy", "getn"}},

	-- Builtin
	"vector", "ItemStack",
	"DIR_DELIM", "VoxelArea", "Settings",

	"libuix", "import", "ui", "UNIT_TEST", "DEBUG",

	-- libuix operator replacement functions
	"eq", "ne", "lt", "gt", "le", "ge", "land", "lor", "lnot"
}

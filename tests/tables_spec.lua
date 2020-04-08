package.path = "../?.lua;" .. package.path

require("tests/mock")
local tables = require("tables")

local HELLO_MSG = "Hello!"
local WORLD_MSG = "What up world!"

-----------------------------------------------------------------------------------------------------------------------

describe("copy", function()
	it("returns a deep copy of a table including any metatables", function()
		assert.has_error(function() tables.copy(true) end)
		assert.has_no.error(function() tables.copy(true, true) end)
		assert.are.same(tables.copy({hello = true}), {hello = true})
		assert.are.same(tables.copy({{another = "world"}}), {{another = "world"}})

		local tbl = {}
		local mt = {
			__index = function()
				return "Hi!"
			end
		}
		setmetatable(tbl, mt)

		assert.are.same(tables.copy(tbl), tbl)
		assert.are.same(getmetatable(tables.copy(tbl)), mt)
	end)
end)

describe("contains", function()
	it("returns index if an array-equivalent table contains some value", function()
		local tbl = {"hello", 10, true}
		assert.are.equal(2, tables.contains(tbl, 10))
		assert.falsy(tables.contains(tbl, 109))
	end)
end)

describe("invert", function()
	it("inverts the key-value pairs of a table", function()
		assert.are.same({[true] = 2, [38] = "hello"}, tables.invert({[2] = true, hello = 38}))
	end)
end)

describe("count", function()
	it("returns the number of items in a table", function()
		assert.are.equal(2, tables.count({10, 83}))
		assert.are.equal(0, tables.count({}))
		assert.are.equal(3, tables.count({5, hello = false, "Hello"}))
	end)
end)

describe("foreach", function()
	it("executes a function for every item in a table", function()
		local tbl = {"Hello,", "how", "are", "you?"}
		local output = ""

		tables.foreach(tbl, function(item)
			output = output .. (output == "" and "" or " ") .. item
		end)

		assert.are.equal(table.concat(tbl, " "), output)
	end)
end)

describe("dump", function()
	it("does not trigger a stack overflow with cyclical tables", function()
		local one = {name = "John Doe"}
		local two = {visible = false}
		one.child = two
		two.parent = one

		assert.has_no.error(function() tables.dump(one) end)
	end)
end)

describe("static", function()
	local function real_tbl()
		return { hello = HELLO_MSG, world = WORLD_MSG }
	end

	local function base_tbl()
		return { hello = "world", world = "hello" }
	end

	local function meta_tbl()
		return {
			__index = function(tbl, key)
				return real_tbl()[key]
			end
		}
	end

	it("returns a read-only table", function()
		local table = tables.static(real_tbl())

		assert.has_error(function() table.new_key = HELLO_MSG end)
		assert.are.equal(HELLO_MSG, table.hello)
	end)

	it("can have a custom metatable", function()
		local table = tables.static(base_tbl(), {
			__call = function(self)
				return HELLO_MSG
			end,

			__index = meta_tbl().__index
		})

		assert.are.equal(HELLO_MSG, table())
		assert.are.equal(HELLO_MSG, table.hello)
	end)

	it("can have whitelisted keys", function()
		local table = tables.static(base_tbl(), meta_tbl(), { _mode = "whitelist", "hello" })

		assert.are.equal(HELLO_MSG, table.hello)
		assert.are.equal(nil, table.world)
	end)

	it("can have blacklisted keys", function()
		local table = tables.static(base_tbl(), meta_tbl(), { _mode = "blacklist", "hello" })

		assert.are.equal(nil, table.hello)
		assert.are.equal(WORLD_MSG, table.world)
	end)
end)

package.path = "../?.lua;" .. package.path
_G.libuix = {}
local static_table = require("utility").static_table
local dump = require("utility").dump

local HELLO_MSG = "Hello!"
local WORLD_MSG = "What up world!"

--[[ describe("dump", function()
	it("converts tables to string", function()
		assert.are.equal("{\n    1 = true\n    2 = false\n}", dump({ true, false }))
		assert.are.equal("{\n    {\n        1 = true\n        2 = false\n    }\n}", dump({ { true, false } }))
	end)
end) ]]

describe("static_table", function()
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
		local table = static_table(real_tbl())

		assert.has_error(function() table.new_key = HELLO_MSG end)
		assert.are.equal(HELLO_MSG, table.hello)
	end)

	it("can have a custom metatable", function()
		local table = static_table(base_tbl(), {
			__call = function(self)
				return HELLO_MSG
			end,

			__index = meta_tbl().__index
		})

		assert.are.equal(HELLO_MSG, table())
		assert.are.equal(HELLO_MSG, table.hello)
	end)

	it("can have whitelisted keys", function()
		local table = static_table(base_tbl(), meta_tbl(), { _mode = "whitelist", "hello" })

		assert.are.equal(HELLO_MSG, table.hello)
		assert.are.equal(nil, table.world)
	end)

	it("can have blacklisted keys", function()
		local table = static_table(base_tbl(), meta_tbl(), { _mode = "blacklist", "hello" })

		assert.are.equal(nil, table.hello)
		assert.are.equal(WORLD_MSG, table.world)
	end)
end)

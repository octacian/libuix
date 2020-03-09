package.path = "../?.lua;" .. package.path
_G.libuix = {}

local copy = require("utility").copy
local contains = require("utility").contains
local count = require("utility").count
local foreach = require("utility").foreach
local get_type = require("utility").type
local constrain = require("utility").constrain
local static_table = require("utility").static_table
local enforce_types = require("utility").enforce_types
local enforce_array = require("utility").enforce_array
local make_class = require("utility").make_class

local HELLO_MSG = "Hello!"
local WORLD_MSG = "What up world!"

local TestClass = make_class("TestClass")

function TestClass:new()
	local instance = {}
	setmetatable(instance, TestClass)
	return instance
end

-----------------------------------------------------------------------------------------------------------------------

describe("table.copy", function()
	it("returns a deep copy of a table including any metatables", function()
		assert.has_error(function() copy(true) end)
		assert.has_no.error(function() copy(true, true) end)
		assert.are.same(copy({hello = true}), {hello = true})
		assert.are.same(copy({{another = "world"}}), {{another = "world"}})

		local tbl = {}
		local mt = {
			__index = function()
				return "Hi!"
			end
		}
		setmetatable(tbl, mt)

		assert.are.same(copy(tbl), tbl)
		assert.are.same(getmetatable(copy(tbl)), mt)
	end)
end)

describe("table.contains", function()
	it("returns index if an array-equivalent table contains some value", function()
		local tbl = {"hello", 10, true}
		assert.are.equal(2, contains(tbl, 10))
		assert.falsy(contains(tbl, 109))
	end)
end)

describe("table.count", function()
	it("returns the number of items in a table", function()
		assert.are.equal(2, count({10, 83}))
		assert.are.equal(0, count({}))
		assert.are.equal(3, count({5, hello = false, "Hello"}))
	end)
end)

describe("table.foreach", function()
	it("executes a function for every item in a table", function()
		local tbl = {"Hello,", "how", "are", "you?"}
		local output = ""

		foreach(tbl, function(item)
			output = output .. (output == "" and "" or " ") .. item
		end)

		assert.are.equal(table.concat(tbl, " "), output)
	end)
end)

describe("check_type", function()
	it("checks if a variable is of the expected type, checking class IDs as well", function()
		assert.are.equal("number", get_type(28))
		assert.are.equal("boolean", get_type(true))
		assert.are.equal("table", get_type({123}))
		assert.are.equal("TestClass", get_type(TestClass:new()))
	end)
end)

describe("table.constrain", function()
	it("takes a table to inspect, a table of rules, and two booleans", function()
		assert.has_error(function() constrain(nil, {}, nil, true) end)
		assert.has_error(function() constrain({}, nil, nil, true) end)
		assert.has_error(function() constrain({}, {}, "hello", true) end)
		assert.has_error(function() constrain({}, {}, nil, "hello") end)
		assert.has_error(function() constrain({}, {}) end)
	end)

	it("constrains the keys within a table to meet specific requirements", function()
		assert.has_error(function() constrain({hello = "world"}, {{"hello", "boolean"}}) end)
		assert.has_no.error(function() constrain({hello = "world"}, {{"hello", "string"}}) end)
		assert.has_error(function() constrain({hello = "world", world = "hello"}, {{"hello", "string"}}) end)
		assert.has_error(function() constrain({hello = "world"}, {{"enable", "boolean"}}, false) end)
		assert.has_error(function() constrain({hello = "world"}, {{"world", "string"}, {"enable", "boolean"}}) end)
		assert.has_no.error(function()
			constrain({hello = "world"}, {{"hello", "string"}, {"optional", "boolean", required = false}})
		assert.has_no.error(function() constrain({instance = TestClass:new()}, {{"instance", "TestClass"}}) end)
		end)

		-- Confirm that missing keys error message is correct
		assert.has_error(function() constrain({}, {{"hello", "string"}}, nil, false) end,
			"libuix->table.constrain: key(s) (hello: string) are required")
	end)
end)

describe("enforce_types", function()
	local function test_func(name, verbose)
		enforce_types(false, {"string", "boolean?"}, name, verbose)
	end

	it("checks the types of function arguments", function()
		assert.has_no.error(function() test_func("John Doe") end)
		assert.has_no.error(function() test_func("John Doe", true) end)
		assert.has_no.error(function() enforce_types(true, {"string"}, "Hello") end)
		assert.has_no.error(function() enforce_types({"TestClass"}, TestClass:new()) end)
		assert.has_error(function() test_func(81) end, "libuix->enforce_types: argument #1 must be a string (found '81')")
		assert.has_error(function() test_func("John Doe", 15) end,
			"libuix->enforce_types: argument #2 must be a boolean (found '15')")
		assert.has_error(function() test_func(nil, 15) end, "libuix->enforce_types: argument #1 is required")
		assert.has_error(function() enforce_types(false, {"string", "number"}, "Hello") end,
			"libuix->enforce_types: argument #2 is required")
		assert.has_error(function() enforce_types(false, {"string"}, "Hello", 85) end,
			"libuix->enforce_types: found 2 argument(s) and only 1 rule(s)")
	end)
end)

describe("enforce_array", function()
	it("makes sure a table contains only numerically-indexed entries", function()
		assert.has_no.error(function() enforce_array({"hello", 28, true}) end)
		assert.has_error(function() enforce_array(false, {"world", false, name = "John Doe"}) end,
			"libuix->enforce_array: found non-numerically indexed entry at \"name\" (contains: \"John Doe\")")
		assert.has_error(function() enforce_array({show = false}) end)
	end)

	it("conforms array entries to a single type", function()
		assert.has_no.error(function() enforce_array({1, 4, 8}, "number") end)
		assert.has_no.error(function() enforce_array({TestClass:new()}, "TestClass") end)
		assert.has_error(function() enforce_array(false, {"hello", true, 12.8}, "string") end,
			"libuix->enforce_array: entry #2 must be a string (found true)")
		assert.has_error(function() enforce_array({2}, "string") end)
	end)
end)

describe("dump", function()
	it("does not trigger a stack overflow with cyclical tables", function()
		local one = {name = "John Doe"}
		local two = {visible = false}
		one.child = two
		two.parent = one

		assert.has_no.error(function() dump(one) end)
	end)
end)

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

describe("make_class", function()
	it("creates a class and attaches a name", function()
		assert.is_truthy(TestClass.__class_name)

		local instance = TestClass:new()
		assert.are.equal(TestClass.__class_name, getmetatable(instance).__class_name)
		assert.are.equal("function", type(instance.new))
	end)
end)

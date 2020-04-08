package.path = "../?.lua;" .. package.path

require("tests/mock")
local types = require("types")

local TestClass = types.type("TestClass")

function TestClass:new()
	local instance = {}
	setmetatable(instance, TestClass)
	return instance
end

-----------------------------------------------------------------------------------------------------------------------

describe("get", function()
	it("checks if a variable is of the expected type, giving custom types first-level status", function()
		assert.are.equal("number", types.get(28))
		assert.are.equal("boolean", types.get(true))
		assert.are.equal("table", types.get({123}))
		assert.are.equal("TestClass", types.get(TestClass:new()))
	end)
end)

describe("check", function()
	it("checks if some value has the expected type", function()
		assert.is_true(types.check(28, "number"))
		assert.is_true(types.check(TestClass:new(), "table"))
		assert.is_true(types.check(TestClass:new(), "TestClass"))
		assert.is_false(types.check(false, "string"))
	end)

	it("can check if some value is one of many types", function()
		assert.is_true(types.check(32, "string|number"))
		assert.is_true(types.check(TestClass:new(), "string|number|TestClass|function"))
		assert.is_false(types.check(true, "number|function|string"))
	end)
end)

describe("constrain", function()
	it("takes a table to inspect, a table of rules, and two booleans", function()
		assert.has_error(function() types.constrain(nil, {}, nil, true) end)
		assert.has_error(function() types.constrain({}, nil, nil, true) end)
		assert.has_error(function() types.constrain({}, {}, "hello", true) end)
		assert.has_error(function() types.constrain({}, {}, nil, "hello") end)
		assert.has_error(function() types.constrain({}, {}) end)
	end)

	it("constrains the keys within a table to meet specific requirements", function()
		assert.has_error(function() types.constrain({hello = "world"}, {{"hello", "boolean"}}) end)
		assert.has_no.error(function() types.constrain({hello = "world"}, {{"hello", "string"}}) end)
		assert.has_error(function() types.constrain({hello = "world", world = "hello"}, {{"hello", "string"}}) end)
		assert.has_error(function() types.constrain({hello = "world"}, {{"enable", "boolean"}}, false) end)
		assert.has_error(function() types.constrain({hello = "world"}, {{"world", "string"}, {"enable", "boolean"}}) end)
		assert.has_no.error(function()
			types.constrain({hello = "world"}, {{"hello", "string"}, {"optional", "boolean", required = false}})
		assert.has_no.error(function() types.constrain({instance = TestClass:new()}, {{"instance", "TestClass"}}) end)
		end)

		-- Confirm that missing keys error message is correct
		assert.has_error(function() types.constrain({}, {{"hello", "string"}}, nil, false) end, "libuix->types->constrain: "
			.. "key(s) (hello: string) are required")
	end)
end)

describe("force", function()
	local function test_func(name, verbose)
		types.force({"string", "boolean?"}, name, verbose)
	end

	it("checks the types of function arguments", function()
		assert.has_no.error(function() test_func("John Doe") end)
		assert.has_no.error(function() test_func("John Doe", true) end)
		assert.has_no.error(function() types.force({"string"}, "Hello") end)
		assert.has_no.error(function() types.force({"TestClass"}, TestClass:new()) end)
		assert.has_error(function() test_func(81) end, "libuix->types->force: argument #1 must be a string (found number)")
		assert.has_error(function() test_func("John Doe", 15) end,
			"libuix->types->force: argument #2 must be a boolean (found number)")
		assert.has_error(function() test_func(nil, 15) end, "libuix->types->force: argument #1 is required")
		assert.has_error(function() types.force({"string", "number"}, "Hello") end,
			"libuix->types->force: argument #2 is required")
		assert.has_error(function() types.force({"string"}, "Hello", 85) end,
			"libuix->types->force: found 2 argument(s) and only 1 rule(s)")
	end)
end)

describe("force_array", function()
	it("makes sure a table contains only numerically-indexed entries", function()
		assert.has_no.error(function() types.force_array({"hello", 28, true}) end)
		assert.has_error(function() types.force_array({"world", false, name = "John Doe"}) end,
			"libuix->types->force_array: found non-numerically indexed entry at \"name\" (contains: \"John Doe\")")
		assert.has_error(function() types.force_array({show = false}) end)
	end)

	it("conforms array entries to a single type", function()
		assert.has_no.error(function() types.force_array({1, 4, 8}, "number") end)
		assert.has_no.error(function() types.force_array({TestClass:new()}, "TestClass") end)
		assert.has_error(function() types.force_array({"hello", true, 12.8}, "string") end,
			"libuix->types->force_array: entry #2 must be a string (found boolean)")
		assert.has_error(function() types.force_array({2}, "string") end)
	end)
end)

describe("type", function()
	it("creates a custom type and attaches a name", function()
		assert.is_truthy(TestClass.__class_name)

		local instance = TestClass:new()
		assert.are.equal(TestClass.__class_name, getmetatable(instance).__class_name)
		assert.are.equal("function", type(instance.new))
	end)
end)

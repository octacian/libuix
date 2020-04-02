package.path = "../?.lua;" .. package.path

require("tests/mock")
local utility = require("utility")
local Placeholder = require("placeholder")

describe("Placeholder", function()
	describe("new_listener", function()
		it("modifies an environment to return placeholders for missing and new values", function()
			local temp_env = {}
			Placeholder.new_listener(temp_env)

			local name = temp_env.person.name()
			assert.are.equal("Placeholder", utility.type(name))

			assert.has_error(function() temp_env.name = "John" end, "libuix->Placeholder.new_listener: attempt to assign value "
				.. "to key 'name' in access listener")
		end)
	end)

	describe("set", function()
		it("can assign a value", function()
			local tbl = {}
			local key = Placeholder.index("name")
			Placeholder.set(tbl, key, "John")
			assert.are.equal(tbl.name, "John")
		end)

		it("can assign a sub-level value", function()
			local tbl = {person = {name = {}}}
			local key = Placeholder.index("person").name.first
			Placeholder.set(tbl, key, "John")
			assert.are.equal(tbl.person.name.first, "John")

			local bad_key = Placeholder.index("name").first
			assert.has_error(function() Placeholder.set(tbl, bad_key, "John") end,
				"libuix->Placeholder.set: attempt to index environment key 'name' (a nil value)")
		end)

		it("throws an error if any events other than access and assign are found in the key", function()
			local env = {name = ""}
			local key = Placeholder.index("name")()
			assert.has_error(function() Placeholder.set(env, key, "John") end,
				"libuix->Placeholder.set: assignment key cannot contain a call event")

			key = Placeholder.new_index("name")
			assert.has_no.error(function() Placeholder.set(env, key, "John") end)
		end)
	end)

	describe("evaluate", function()
		it("can access a top-level value", function()
			local instance = Placeholder.index("name")
			local tbl = {name = "John"}
			assert.are.equal("John", Placeholder.evaluate(tbl, instance))
		end)

		it("can access a sub-level value", function()
			local instance = Placeholder.index("name").first
			local tbl = {name = {first = "John"}}
			assert.are.equal("John", Placeholder.evaluate(tbl, instance))

			local bad_key = Placeholder.index("name").last.firstChar
			assert.has_error(function() Placeholder.evaluate(tbl, bad_key) end,
				"libuix->Placeholder.evaluate: attempt to index environment key 'firstChar' (a nil value)")

			instance = Placeholder.index("person").name.first
			tbl = {person = {name = {first = "John"}}}
			assert.are.equal("John", Placeholder.evaluate(tbl, instance))

			instance = Placeholder.index(1).about.name.first
			tbl = {{about = {name = {first = "John"}}}}
			assert.are.equal("John", Placeholder.evaluate(tbl, instance))
		end)

		it("can assign values", function()
			local tbl = {person = {name = {}}}
			local name = Placeholder.index("person").name
			name.first = "John"
			Placeholder.evaluate(tbl, name)
			assert.are.equal(tbl.person.name.first, "John")
		end)

		it("can call functions with or without self and with or without a custom environment", function()
			local tbl = { say = {
				name = "John",
				hello = function(self, to)
					return self.name .. " says hello to " .. to .. "!"
				end
			}, goodbye = function()
				return "Goodbye!"
			end,
			assign = function()
				model.message = "Hello!"
			end }

			local with_self = Placeholder.index("say"):hello("oct")
			assert.are.equal("John says hello to oct!", Placeholder.evaluate(tbl, with_self))

			local without_self = Placeholder.index("goodbye")()
			assert.are.equal("Goodbye!", Placeholder.evaluate(tbl, without_self))

			local with_placeholder_arg = Placeholder.index("say"):hello(Placeholder.index("say").name)
			assert.are.equal("John says hello to John!", Placeholder.evaluate(tbl, with_placeholder_arg))

			local env = { model = {} }
			local with_env = Placeholder.index("assign")()
			Placeholder.evaluate(tbl, with_env, env)
			assert.are.equal("Hello!", env.model.message)
		end)

		it("can return the result of the unary minus operator", function()
			local tbl = {age = 16}
			local unm = -Placeholder.index("age")
			assert.are.equal(-16, Placeholder.evaluate(tbl, unm))
		end)

		it("can return the result of math operations", function()
			local tbl = {count = 2, incrementor = 2}
			local add = Placeholder.index("count") + Placeholder.index("incrementor") + 1
			assert.are.equal(5, Placeholder.evaluate(tbl, add))

			local sub = Placeholder.index("count") - Placeholder.index("incrementor") - 1
			assert.are.equal(-1, Placeholder.evaluate(tbl, sub))

			local mul = Placeholder.index("count") * (Placeholder.index("incrementor") * 2)
			assert.are.equal(8, Placeholder.evaluate(tbl, mul))

			local div = Placeholder.index("count") / (Placeholder.index("incrementor") / 0.5)
			assert.are.equal(0.5, Placeholder.evaluate(tbl, div))

			local mod = (Placeholder.index("count") + 1) % Placeholder.index("incrementor")
			assert.are.equal(1, Placeholder.evaluate(tbl, mod))

			local pow = Placeholder.index("count") ^ Placeholder.index("incrementor")
			assert.are.equal(4, Placeholder.evaluate(tbl, pow))
		end)

		it("can return the result of string concatenation", function()
			local tbl = {one = "Hello"}
			local concat = Placeholder.index("one") .. " world!"
			assert.are.equal("Hello world!", Placeholder.evaluate(tbl, concat))
		end)

		it("does not care about order in mathematical operations", function()
			local tbl = {multiplier = 10}
			local mul = 2 * Placeholder.index("multiplier")
			assert.are.equal(20, Placeholder.evaluate(tbl, mul))
		end)

		it("allows function calls to be mixed into mathematical operations", function()
			local tbl = {start = 5, get_incrementor = function() return 2 end}
			local add = Placeholder.index("start") + Placeholder.index("get_incrementor")()
			assert.are.equal(7, Placeholder.evaluate(tbl, add))
		end)

		it("throws an error if an equality check is attempted", function()
			assert.has_error(function() return Placeholder.index("one") <= Placeholder.index("two") end,
				"libuix->Placeholder:__le: comparison operators are not allowed, use 'is.le()' instead")
			assert.has_error(function() return Placeholder.index("one") == Placeholder.index("two") end,
				"libuix->Placeholder:__eq: comparison operators are not allowed, use 'is.eq()' instead")
		end)

		it("throws the correct error message for each event", function()
			local call = Placeholder.index("one")()
			assert.has_error(function() Placeholder.evaluate({}, call) end,
				"libuix->Placeholder.evaluate: attempt to call environment key 'one' (a nil value)")

			local arithmetic_error_msg = "libuix->Placeholder.evaluate: attempt to perform arithmetic on environment key 'one' "
				.. "(a nil value)"

			local unm = -Placeholder.index("one")
			assert.has_error(function() Placeholder.evaluate({}, unm) end, arithmetic_error_msg)

			local add = Placeholder.index("one") + Placeholder.index("two")
			assert.has_error(function() Placeholder.evaluate({}, add) end, arithmetic_error_msg)

			local sub = Placeholder.index("one") - Placeholder.index("two")
			assert.has_error(function() Placeholder.evaluate({}, sub) end, arithmetic_error_msg)

			local mul = Placeholder.index("one") * Placeholder.index("two")
			assert.has_error(function() Placeholder.evaluate({}, mul) end, arithmetic_error_msg)

			local div = Placeholder.index("one") / Placeholder.index("two")
			assert.has_error(function() Placeholder.evaluate({}, div) end, arithmetic_error_msg)

			local mod = Placeholder.index("one") % Placeholder.index("two")
			assert.has_error(function() Placeholder.evaluate({}, mod) end, arithmetic_error_msg)

			local pow = Placeholder.index("one") ^ Placeholder.index("two")
			assert.has_error(function() Placeholder.evaluate({}, pow) end, arithmetic_error_msg)

			local concat = Placeholder.index("one") .. Placeholder.index("two")
			assert.has_error(function() Placeholder.evaluate({}, concat) end,
				"libuix->Placeholder.evaluate: attempt to concatenate environment key 'one' (a nil value)")
		end)
	end)

	describe("provides custom comparison operator", function()
		local env = {is = Placeholder.is, one = 28, two = 28, three = 14}

		it("is.eq (is equal)", function()
			local eq = Placeholder.index("is").eq(Placeholder.index("one"), Placeholder.index("two"))
			assert.is_true(Placeholder.evaluate(env, eq))
			eq = Placeholder.index("is").eq(Placeholder.index("one"), Placeholder.index("three"))
			assert.is_false(Placeholder.evaluate(env, eq))
		end)

		it("is.ne (is not equal)", function()
			local ne = Placeholder.index("is").ne(Placeholder.index("one"), Placeholder.index("three"))
			assert.is_true(Placeholder.evaluate(env, ne))
			ne = Placeholder.index("is").ne(Placeholder.index("one"), Placeholder.index("two"))
			assert.is_false(Placeholder.evaluate(env, ne))
		end)

		it("is.lt (is less than)", function()
			local lt = Placeholder.index("is").lt(Placeholder.index("three"), Placeholder.index("two"))
			assert.is_true(Placeholder.evaluate(env, lt))
			lt = Placeholder.index("is").lt(Placeholder.index("one"), Placeholder.index("two"))
			assert.is_false(Placeholder.evaluate(env, lt))
		end)

		it("is.gt (is greater than)", function()
			local gt = Placeholder.index("is").gt(Placeholder.index("two"), Placeholder.index("three"))
			assert.is_true(Placeholder.evaluate(env, gt))
			gt = Placeholder.index("is").gt(Placeholder.index("three"), Placeholder.index("two"))
			assert.is_false(Placeholder.evaluate(env, gt))
		end)

		it("is.le (is less than or equal)", function()
			local le = Placeholder.index("is").le(Placeholder.index("one"), Placeholder.index("two"))
			assert.is_true(Placeholder.evaluate(env, le))
			le = Placeholder.index("is").le(Placeholder.index("three"), Placeholder.index("two"))
			assert.is_true(Placeholder.evaluate(env, le))
			le = Placeholder.index("is").le(Placeholder.index("two"), Placeholder.index("three"))
			assert.is_false(Placeholder.evaluate(env, le))
		end)

		it("is.ge (is greater than or equal)", function()
			local ge = Placeholder.index("is").ge(Placeholder.index("one"), Placeholder.index("two"))
			assert.is_true(Placeholder.evaluate(env, ge))
			ge = Placeholder.index("is").ge(Placeholder.index("two"), Placeholder.index("three"))
			assert.is_true(Placeholder.evaluate(env, ge))
			ge = Placeholder.index("is").ge(Placeholder.index("three"), Placeholder.index("two"))
			assert.is_false(Placeholder.evaluate(env, ge))
		end)
	end)

	describe("provides custom logical operator", function()
		local env = {logical = Placeholder.logical, one = true, two = false}

		it("logical.l_and (logical and)", function()
			local l_and = Placeholder.index("logical").l_and(Placeholder.index("one"), true)
			assert.is_true(Placeholder.evaluate(env, l_and))
			l_and = Placeholder.index("logical").l_and(Placeholder.index("one"), Placeholder.index("two"))
			assert.is_false(Placeholder.evaluate(env, l_and))
		end)

		it("logical.l_or (logical or)", function()
			local l_or = Placeholder.index("logical").l_or(Placeholder.index("one"), false)
			assert.is_true(Placeholder.evaluate(env, l_or))
			l_or = Placeholder.index("logical").l_or(false, Placeholder.index("two"))
			assert.is_false(Placeholder.evaluate(env, l_or))
		end)

		it("logical.l_not (logical not)", function()
			local l_not = Placeholder.index("logical").l_not(Placeholder.index("two"))
			assert.is_true(Placeholder.evaluate(env, l_not))
			l_not = Placeholder.index("logical").l_not(Placeholder.index("one"))
			assert.is_false(Placeholder.evaluate(env, l_not))
		end)
	end)
end)

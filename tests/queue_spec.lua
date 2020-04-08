package.path = "../?.lua;" .. package.path

require("tests/mock")
local Queue = require("queue")

describe("Queue", function()
	it("records function calls on an object for later execution on any object", function()
		local queue = Queue:new()
		queue:say_hello("John")

		local output = ""
		local target = {
			say_hello = function(self, name)
				output = "Hello " .. name .. "!"
			end,
			say_goodbye = function(name)
				output = "Goodbye " .. name .. "!"
			end
		}

		queue:_start(target)
		assert.are.equal("Hello John!", output)
		assert.are.same({}, queue)

		queue.say_goodbye("John")
		queue:_start(target)
		assert.are.equal("Goodbye John!", output)

		assert.has_error(function() queue.invalid(); queue:_start(target) end,
			"libuix->Queue:_start(): attempt to call field 'invalid' (a nil value)")
	end)
end)

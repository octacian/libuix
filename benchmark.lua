#! /usr/bin/luajit

local socket = require('socket')

Benchmark = {}
Benchmark.__index = Benchmark

setmetatable(Benchmark, {
	__call = function(self, desc, iterations, fn, ...)
		if iterations > 0 and iterations < 1 then iterations = 1 end
		local start = socket.gettime()
		for i = 1, iterations do fn(...) end
		local stop = socket.gettime() - start
		print(desc .. "\t" .. string.format("%.6f", stop / iterations))
	end
})

function Benchmark:start(desc)
	local instance = {desc = desc}
	setmetatable(instance, Benchmark)
	instance.start = socket.gettime()
	return instance
end

function Benchmark:stop()
	local stop = socket.gettime() - self.start
	print(self.desc .. "\t" .. string.format("%.6f", stop))
end

local utility = require("./utility")

Benchmark("Print Message:\t", 1, function()
	print("Hello world! " .. 4 * 90)
end)
print("Formspec in Minetest:\t0.000021")

local variation_fields = {
	{ "x",  "number", separator = "," },
	{ "name", "string" },
	{ "y", "number", required = false },
}

local RENDER_COUNT = 1
local BENCHMARK_COUNT = 100
local benchmark = {}

------------
--  Mocks --
------------

local mock = require("tests/mock")

minetest = {}
function minetest.get_modpath()
	return "."
end

local shared_form = import("formspec/form.lua"):new(mock.FormspecManager:new(), "shared_form", {}, {},
	import("formspec/model.lua"):new({}))

------------------------
-- ErrorBuilder Class --
------------------------

function benchmark.errorbuilder()
	Benchmark("Create ErrorBuilder:", BENCHMARK_COUNT, function()
		for i = 1, RENDER_COUNT do
			utility.ErrorBuilder:new("benchmark.errorbuilder")
		end
	end)

	print()
end

benchmark.errorbuilder()

-----------------------
-- Placeholder Class --
-----------------------

function benchmark.placeholder()
	local Placeholder = import("placeholder.lua")

	local key
	Benchmark("Create placeholder:", BENCHMARK_COUNT, function()
		for i = 1, RENDER_COUNT do
			key = Placeholder.index("name")
		end
	end)

	local env = {person = {}}
	Benchmark("Set value:\t", BENCHMARK_COUNT, function()
		for i = 1, RENDER_COUNT do
			Placeholder.set(env, key, "John Doe")
		end
	end)

	Benchmark("Evaluate placeholder:", BENCHMARK_COUNT, function()
		for i = 1, RENDER_COUNT do
			Placeholder.evaluate(env, key)
		end
	end)

	Benchmark("Create deep index:", BENCHMARK_COUNT, function()
		for i = 1, RENDER_COUNT do
			key = Placeholder.index("person").name
		end
	end)

	Benchmark("Set deep value:\t", BENCHMARK_COUNT, function()
		for i = 1, RENDER_COUNT do
			Placeholder.set(env, key, "John")
		end
	end)

	Benchmark("Evaluate deep index:", BENCHMARK_COUNT, function()
		for i = 1, RENDER_COUNT do
			Placeholder.index(env, key)
		end
	end)

	print()
end

benchmark.placeholder()

---------------------
-- Variation Class --
---------------------

function benchmark.variation()
	local FormspecManager = mock.FormspecManager
	local Variation = import("formspec/element/variation.lua")

	local parent = FormspecManager:new("variation_benchmark")
	local Example
	Benchmark("Create variation:", BENCHMARK_COUNT, function()
		for i = 1, RENDER_COUNT do
			Example = Variation:new(parent, "variation_benchmark", variation_fields)
		end
	end)

	local populated
	Benchmark("Insert def:\t", BENCHMARK_COUNT, function()
		for i = 1, RENDER_COUNT do
			populated = Example { x = 0, y = 0, name = "test" }
		end
	end)

	Benchmark("Render variation:", BENCHMARK_COUNT, function()
		for i = 1, RENDER_COUNT do
		populated:render(shared_form)
		end
	end)

	print()
end

benchmark.variation()

-------------------
-- Element Class --
-------------------

function benchmark.element()
	local FormspecManager = mock.FormspecManager
	local Element = import("formspec/element/element.lua")

	local parent = FormspecManager:new("benchmark")
	local Example
	Benchmark("Initialize element:", BENCHMARK_COUNT, function()
		Example = Element:new(parent, "benchmark_spec")
	end)

	Benchmark("Add variation:\t", 1, function()
		Example:add_variation(variation_fields)
	end)

	local populated
	Benchmark("Insert def:\t", BENCHMARK_COUNT, function()
		for i = 1, RENDER_COUNT do
			populated = Example { x = 0, y = 0, name = "test" }
		end
	end)

	Benchmark("Render element:\t", BENCHMARK_COUNT, function()
		for i = 1, RENDER_COUNT do
			populated:render(shared_form)
		end
	end)

	print()
end

benchmark.element()

-------------------------
-- Elements Generation --
-------------------------

local Elements
function benchmark.elements()
	local manager = mock.FormspecManager:new("benchmark_elements")
	local ElementsClass = import("formspec/elements.lua")

	Benchmark("Generate elements:", 1, function()
		Elements = ElementsClass(manager)
	end)

	manager.elements = Elements
	setmetatable(manager.elements, { __index = _G })

	print()
end

benchmark.elements()

---------------------------------
-- Complex Elements Benchmarks --
---------------------------------

-- Container Element
function benchmark.container_element()
	local populated
	Benchmark("Prepare container:", BENCHMARK_COUNT, function()
		populated = Elements.container { x = 0, y = 0 } {
			ui.text { x = 0, y = 0, text = "Hello world!" }
		}
	end)

	Benchmark("Render container:", BENCHMARK_COUNT, function()
		for i = 1, RENDER_COUNT do
			populated:render(shared_form)
		end
	end)

	print()
end

benchmark.container_element()

----------------
-- Form Class --
----------------

function benchmark.form()
	local manager = mock.FormspecManager:new("benchmark")
	local Model = import("formspec/model.lua")
	local Form = import("formspec/form.lua")

	local form_elements
	Benchmark("Prepare elements:", BENCHMARK_COUNT, function()
		form_elements = {}
		for i = 1, RENDER_COUNT do
			form_elements[#form_elements + 1] = Elements["text"] { x = 0, y = 0, text = "Hello!" }
		end
	end)

	local Example
	Benchmark("Initialize form:", BENCHMARK_COUNT, function()
		Example = Form:new(manager, "form_bench", { w = 5, h = 5 }, form_elements, Model:new {})
	end)

	Benchmark("Render form:\t", BENCHMARK_COUNT, function()
		Example:render(shared_form)
	end)

	print()
end

benchmark.form()

---------------------------
-- FormspecManager Class --
---------------------------

function benchmark.formspecmanager()
	local parent = require("tests/mock").UIXInstance:new("benchmark")
	local FormspecManager = import("formspec/manager.lua")

	local instance
	Benchmark("Initialize manager:", BENCHMARK_COUNT, function()
	instance = FormspecManager:new(parent)
	end)

	local form_elements
	Benchmark("Prepare elements:", BENCHMARK_COUNT, function()
		form_elements = {}
		for i = 1, RENDER_COUNT do
			form_elements[#form_elements + 1] = Elements["text"] { x = 0, y = 0, text = "Hello!" }
		end
	end)

	Benchmark("Add form:\t", BENCHMARK_COUNT, function()
	instance("bench_form") { w = 5, h = 5 } (form_elements) ({})
	end)

	local form = instance:get("bench_form")
	Benchmark("Render form:\t", BENCHMARK_COUNT, function()
		form:render(shared_form)
	end)

	print()
end

benchmark.formspecmanager()

---------
-- API --
---------

function benchmark.api()
	import("init.lua")

	local uix
	Benchmark("Initialize Everything:", BENCHMARK_COUNT / 4, function()
		uix = libuix("benchmark_api")
	end)

	Benchmark("Add form:\t", BENCHMARK_COUNT / 4, function()
		local form_elements = {}
		for i = 1, RENDER_COUNT do
			form_elements[#form_elements + 1] = Elements["text"] { x = 0, y = 0, text = "Hello!" }
		end
		uix.formspec("bench_form") { w = 5, h = 5 } (form_elements) ({})
	end)

	local form = uix.formspec:get("bench_form")
	Benchmark("Render form:\t", BENCHMARK_COUNT, function()
		form:render(shared_form)
	end)
end

benchmark.api()

#! /usr/bin/luajit

_G.modpath = "."
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

require("./utility")

Benchmark("Print Message:\t", 1, function()
	print("Hello world! " .. 4 * 90)
end)
print("Formspec in Minetest:\t0.000021")
print()

local variation_fields = {
	{ "x",  "number", separator = "," },
	{ "name", "string" },
	{ "y", "number", required = false },
}

local RENDER_COUNT = 1
local BENCHMARK_COUNT = 100
local benchmark = {}

--------------------
-- Minetest Mocks --
--------------------

minetest = {}

function minetest.get_modpath()
	return "."
end

---------------------
-- Variation Class --
---------------------

function benchmark.variation()
	local FormspecManager = dofile("./tests/mock.lua").FormspecManager
	local Variation = dofile("./formspec/element/variation.lua")

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
		populated:render()
		end
	end)

	print()
end

benchmark.variation()

-------------------
-- Element Class --
-------------------

function benchmark.element()
	local FormspecManager = dofile("./tests/mock.lua").FormspecManager
	local Element = dofile("./formspec/element/element.lua")

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
			populated:render()
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
	local manager = dofile("./tests/mock.lua").FormspecManager:new("benchmark_elements")
	local ElementsClass = dofile("./formspec/elements.lua")

	Benchmark("Generate elements:", 1, function()
		Elements = ElementsClass(manager)
	end)

	manager.elements = Elements
	setmetatable(manager.elements, { __index = _G })

	print()
end

benchmark.elements()

----------------
-- Form Class --
----------------

function benchmark.form()
	local manager = dofile("./tests/mock.lua").FormspecManager:new("benchmark")
	local Model = dofile("./formspec/model.lua")
	local Form = dofile("./formspec/form.lua")

	local form_elements
	Benchmark("Prepare elements:", BENCHMARK_COUNT, function()
		form_elements = {}
		for i = 1, RENDER_COUNT do
			form_elements[#form_elements + 1] = Elements["label"] { x = 0, y = 0, label = "Hello!" }
		end
	end)

	local Example
	Benchmark("Initialize form:", BENCHMARK_COUNT, function()
		Example = Form:new(manager, "form_bench", { w = 5, h = 5 }, form_elements, Model:new {})
	end)

	Benchmark("Render form:\t", BENCHMARK_COUNT, function()
		Example:render()
	end)

	print()
end

benchmark.form()

---------------------------
-- FormspecManager Class --
---------------------------

function benchmark.formspecmanager()
	local parent = require("tests/mock").UIXInstance:new("benchmark")
	local FormspecManager = dofile("./formspec/manager.lua")

	local instance
	Benchmark("Initialize manager:", BENCHMARK_COUNT, function()
	instance = FormspecManager:new(parent)
	end)

	local form_elements
	Benchmark("Prepare elements:", BENCHMARK_COUNT, function()
		form_elements = {}
		for i = 1, RENDER_COUNT do
			form_elements[#form_elements + 1] = Elements["label"] { x = 0, y = 0, label = "Hello!" }
		end
	end)

	Benchmark("Add form:\t", BENCHMARK_COUNT, function()
	instance("bench_form") { w = 5, h = 5 } (form_elements) ({})
	end)

	local form = instance:get("bench_form")
	Benchmark("Render form:\t", BENCHMARK_COUNT, function()
		form:render()
	end)

	print()
end

benchmark.formspecmanager()

---------
-- API --
---------

function benchmark.api()
	dofile("./init.lua")

	local uix
	Benchmark("Initialize Everything:", BENCHMARK_COUNT / 4, function()
		uix = libuix("benchmark_api")
	end)

	Benchmark("Add form:\t", BENCHMARK_COUNT / 4, function()
		local form_elements = {}
		for i = 1, RENDER_COUNT do
			form_elements[#form_elements + 1] = Elements["label"] { x = 0, y = 0, label = "Hello!" }
		end
		uix.formspec("bench_form") { w = 5, h = 5 } (form_elements) ({})
	end)

	local form = uix.formspec:get("bench_form")
	Benchmark("Render form:\t", BENCHMARK_COUNT, function()
		form:render()
	end)
end

benchmark.api()

--- Global Controls ---

local UNIT_TEST = os.getenv("UNIT_TEST")
local DEBUG = os.getenv("DEBUG")

if UNIT_TEST == "TRUE" then _G.UNIT_TEST = true else _G.UNIT_TEST = false end
if DEBUG == "TRUE" then _G.DEBUG = true else _G.DEBUG = false end

--- Import Function ---

function import(name)
	local f, err = loadfile("./" .. name)
	if not f then error(err, 2) end
	setfenv(f, getfenv(2))
	return f()
end

-- Imports ---

local types = require("types")

--- FormspecManager Class ---

local FormspecManager = types.type("FormspecManager")

function FormspecManager:new(modname, elements)
	local instance = {modname = modname}
	setmetatable(instance, FormspecManager)

	if elements then
		instance.elements = elements(instance)
		setmetatable(instance.elements, { __index = _G })
	end

	return instance
end

--- Form Class ---

local Form = types.type("Form")

function Form:new(name, model)
	local instance = {name = name, model = model, last_id = -1}
	setmetatable(instance, Form)
	return instance
end

function Form:new_id()
	self.last_id = self.last_id + 1
	return self.last_id
end

--- UIXInstance Class ---

local UIXInstance = types.type("UIXInstance")

function UIXInstance:new(modname)
	local instance = {modname = modname}
	setmetatable(instance, UIXInstance)
	return instance
end

--- Element Class ---

local Element = types.type("Element")

function Element:new(parent, name)
	local instance = {parent = parent, name = name}
	setmetatable(instance, Element)
	return instance
end

-------------
-- Exports --
-------------

return {
	import = import,
	UIXInstance = UIXInstance,
	FormspecManager = FormspecManager,
	Form = Form,
	Element = Element
}

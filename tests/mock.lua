local utility = require("utility")

--- FormspecManager Class ---

local FormspecManager = utility.make_class("FormspecManager")

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

local Form = utility.make_class("Form")

function Form:new(name)
	local instance = {name = name}
	setmetatable(instance, Form)
	return instance
end

--- UIXInstance Class ---

local UIXInstance = utility.make_class("UIXInstance")

function UIXInstance:new(modname)
	local instance = {modname = modname}
	setmetatable(instance, UIXInstance)
	return instance
end

--- Element Class ---

local Element = utility.make_class("Element")

function Element:new(parent, name)
	local instance = {parent = parent, name = name}
	setmetatable(instance, Element)
	return instance
end

-------------
-- Exports --
-------------

return {
	UIXInstance = UIXInstance,
	FormspecManager = FormspecManager,
	Form = Form,
	Element = Element
}

local utility = require("utility")

--- Element Class ---

local Element = utility.make_class("Element")

function Element:new(name)
	local instance = {name = name}
	setmetatable(instance, Element)
	return instance
end

--- FormspecManager Class ---

local FormspecManager = utility.make_class("FormspecManager")

function FormspecManager:new(modname)
	local instance = {modname = modname}
	setmetatable(instance, FormspecManager)
	return instance
end

--- UIXInstance Class ---

local UIXInstance = utility.make_class("UIXInstance")

function UIXInstance:new(modname)
	local instance = {modname = modname}
	setmetatable(instance, UIXInstance)
	return instance
end

-------------
-- Exports --
-------------

return {
	Element = Element,
	FormspecManager = FormspecManager,
	UIXInstance = UIXInstance
}

local types = import("types.lua")
local strings = import("strings.lua")

local Form = import("formspec/form.lua")
local Model = import("formspec/model.lua")
local Elements = import("formspec/elements.lua")
local Placeholder = import("placeholder.lua")

local on_receive_fields = {}

---------------------------
-- FormspecManager Class --
---------------------------

local FormspecManager = types.type("FormspecManager")

-- Creates a new FormspecManager instance.
function FormspecManager:new(parent)
	if DEBUG then types.force({"UIXInstance"}, parent) end
	local instance = { parent = parent, forms = {} }
	setmetatable(instance, FormspecManager)

	local elements = Elements(instance)
	instance.elements = { ui = elements }
	Placeholder.new_listener(instance.elements)
	instance.original_env = getfenv(2)

	on_receive_fields[#on_receive_fields + 1] = instance
	return instance
end

-- Collects formspec name, elements, and model for addition to the instance.
function FormspecManager:__call(name)
	-- Add element functions to the global environment.
	setfenv(2, self.elements)

	-- Accept options, including size and the `fixed_size` and `no_prepend` controls.
	return function(options)
		-- Accept elements table.
		return function(elements)
			-- Accept data model table.
			return function(model)
				setfenv(2, self.original_env) -- Remove Elements from the global environment.
				self.forms[#self.forms + 1] = Form:new(self, name, options, elements, Model:new(model))
			end
		end
	end
end

-- Gets a formspec by name from the instance.
function FormspecManager:get(name)
	if DEBUG then types.force({"string"}, name) end
	for _, form in pairs(self.forms) do
		if form.name == name then
			return form
		end
	end
end

-- Gets a formspec index by name from the instance.
function FormspecManager:get_index(name)
	if DEBUG then types.force({"string"}, name) end
	for index, form in pairs(self.forms) do
		if form.name == name then
			return index
		end
	end
end

-- Handle received fields.
function FormspecManager:receive_fields(player, formname, fields)
	local split = strings.split(formname, ":")
	if #split == 2 and split[1] == self.parent.modname then
		local form = self:get(split[2])
		if form then
			form:receive_fields(player, fields)
			return true
		end
	end
end

---------------------------------
-- Handle Formspec Submissions --
---------------------------------

minetest.register_on_player_receive_fields(function(player, formname, fields)
	for _, manager in pairs(on_receive_fields) do
		if manager:receive_fields(player, formname, fields) then
			break
		end
	end
end)

-------------
-- Exports --
-------------

return FormspecManager

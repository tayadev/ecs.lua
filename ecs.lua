--[[
	ecs.lua
	An Entity-Component-System (ECS) framework for Lua.
	By Taya Crystals
]]

--#region World

---A world is a container for entities, systems and resources
---@class World
---@field resources Resource[]
---@field entities Entity[]
---@field schedules table<string, System[]>
local World = {}

---@return World
function World:new()
	local self = setmetatable({}, { __index = self })
	self.resources = {}
	self.entities = {}
	self.systems = {}
	self.schedules = {}
	return self
end

---@param resource Resource
function World:addResource(resource)
	table.insert(self.resources, resource)
end

---@param entity Entity
function World:addEntity(entity)
	table.insert(self.entities, entity)
end

---@param entity Entity
function World:removeEntity(entity)
	for i, e in ipairs(self.entities) do
		if e == entity then
			table.remove(self.entities, i)
			break
		end
	end
end

---@param schedule string
---@param system System
function World:addSystem(schedule, system)
	if not self.schedules[schedule] then
		self.schedules[schedule] = {}
	end
	table.insert(self.schedules[schedule], system)
end

---@param schedule string
---@param ... System
function World:addSystems(schedule, ...)
	for _, system in ipairs({ ... }) do
		self:addSystem(schedule, system)
	end
end

---@param schedule string
---@param system System
function World:removeSystem(schedule, system)
	if not self.schedules[schedule] then
		return
	end
	for i, s in ipairs(self.schedules[schedule]) do
		if s == system then
			table.remove(self.schedules[schedule], i)
			break
		end
	end
end

---@param schedule string
function World:emit(schedule)
	if not self.schedules[schedule] then
		return
	end
	for _, system in ipairs(self.schedules[schedule]) do
		local results = system.query:apply(self)

		for _, data in ipairs(results) do
			system.func(unpack(data))
		end
	end
end

--#endregion

--#region Entity

---Entities are the objects in the world, they hold components
---@class Entity
---@field components Component[]
local Entity = {}

---@param ... Component
---@return Entity
function Entity:new(...)
	local self = setmetatable({}, { __index = self })
	self.components = {}
	for _, component in ipairs({ ... }) do
		table.insert(self.components, component)
	end
	return self
end

---Check if the entity has a component of the given type
---@param componentType table
---@return boolean
function Entity:has(componentType)
	for _, component in ipairs(self.components) do
		if component._type == componentType then
			return true
		end
	end
	return false
end

---Get a component of the given type
---@param componentType table
---@return Component|nil
function Entity:get(componentType)
	for _, component in ipairs(self.components) do
		if component._type == componentType then
			return component
		end
	end
	return nil
end

---Add a component to the entity
---@param component Component
---@return Entity
function Entity:add(component)
	table.insert(self.components, component)
	return self
end

---Remove a component of the given type
---@param componentType table
---@return Entity
function Entity:remove(componentType)
	for i, component in ipairs(self.components) do
		if component._type == componentType then
			table.remove(self.components, i)
			break
		end
	end
	return self
end

--#endregion

--#region Resource

---Resources are global data, they are not tied to any entity
---@class Resource
---@field data any The data associated with the resource
local Resource = {}

---Creates a new resource type with the provided data
---@param data any Initial data for the resource
---@return Resource The resource instance ready to be added to a world
function Resource:new(data)
	local instance = setmetatable({}, { __index = self })
	instance.data = data or {}
	return instance
end

--#endregion

--#region Query

---Queries are used to find entities that match a set of components
---@class Query
---@field elements {item: Component|Resource, required: boolean, excluded: boolean, hidden: boolean}[] Elements in the query and their properties
local Query = {}

---@return Query
function Query:new()
	local self = setmetatable({}, { __index = self })
	self.elements = {}
	return self
end

---Check if a given entity satisfies the query
---@param entity Entity
---@return boolean
function Query:match(entity)
	for _, element in ipairs(self.elements) do
		if element.is_resource then
			goto continue
		end

		local has_component = entity:has(element.item)
		if element.required and not has_component then
			return false
		end

		if element.excluded and has_component then
			return false
		end

		:: continue ::
	end

	return true
end

---Requires a component to be present on the entity
---@param component Component
---@return Query
function Query:with(component)
	table.insert(self.elements, { item = component, required = true })
	return self
end

---Requires a component to be absent on the entity
---@param component Component
---@return Query
function Query:without(component)
	table.insert(self.elements, { item = component, excluded = true })
	return self
end

---Requires a component to be present on the entity, but does not add it to the query output
---@param component Component
---@return Query
function Query:with_hidden(component)
	table.insert(self.elements, { item = component, required = true, hidden = true })
	return self
end

---Adds a component to the query output, but does not require it to be present on the entity
---@param component Component
---@return Query
function Query:optional(component)
	table.insert(self.elements, { item = component })
	return self
end

---Adds a resource to the query output
---@param resource Resource
---@return Query
function Query:res(resource)
	table.insert(self.elements, { item = resource, is_resource = true })
	return self
end

---Applies the query to the world
---@param world World
---@return (any[])[] -- Matched data for each entity that satisfies the query
function Query:apply(world)
	local results = {}

	for _, entity in ipairs(world.entities) do
		if self:match(entity) then
			local data = {}
			for _, element in ipairs(self.elements) do
				if not element.excluded and not element.hidden then
					if element.is_resource then
						table.insert(data, element.item.data)
					else
						local component = entity:get(element.item)
						local value = component and component.data or nil
						table.insert(data, value)
					end
				end
			end
			table.insert(results, data)
		end
	end

	return results
end

--#endregion

--#region Component

---Components are data containers, they do not have behavior
---@class Component
local Component = {}

---Creates a component, returns a table with a new() constructor function
---@param defaults any|nil
---@return table
function Component:new(defaults)
	local componentType = {}
	function componentType:new(data)
		local instance = {}
		instance._type = componentType

		if type(defaults) == "table" and type(data) == "table" then
			instance.data = {}
			for k, v in pairs(defaults) do
				instance.data[k] = v
			end
			for k, v in pairs(data) do
				instance.data[k] = v
			end
		else
			instance.data = data or defaults
		end

		return setmetatable(instance, { __index = Component })
	end

	return setmetatable(componentType, { __index = Component })
end

--#endregion

--#region System

--- Systems are functions that operate on entities, based on their components
---@class System
---@field query Query
---@field func fun(...: any)
local System = {}

---@param query Query
---@param func fun(...: any)
---@return System
function System:new(query, func)
	local system = setmetatable({}, { __index = System })
	system.query = query
	system.func = func
	return system
end

--#endregion

return {
	World = World,
	Entity = Entity,
	Query = Query,
	Component = Component,
	Resource = Resource,
	System = System,
}

local test = require "luatest"
local ecs = require "ecs"

local Entity = ecs.Entity
local Component = ecs.Component
local World = ecs.World
local Query = ecs.Query
local System = ecs.System
local Resource = ecs.Resource

-- Component

test('create component', function(t)
	local Name = Component:new('default')

	local nameinstance = Name:new("Taya")

	t:is(getmetatable(nameinstance).__index, Component)
	t:is(nameinstance.data, "Taya")
end)

test('create component with default', function(t)
	local Name = Component:new('default')

	local nameinstance = Name:new()

	t:is(getmetatable(nameinstance).__index, Component)
	t:is(nameinstance.data, "default")
end)

test('create component with table data', function(t)
	local Position = Component:new({ x = 1, y = 2 })
	local posinstance = Position:new({ key = "value" })

	t:is(getmetatable(posinstance).__index, Component)
	t:is(posinstance.data.x, 1)
	t:is(posinstance.data.y, 2)
end)

test('create tag component', function(t)
	local Tag = Component:new('tag')
	local taginstance = Tag:new()

	t:is(getmetatable(taginstance).__index, Component)
end)

-- Resource

test('create simple resource', function(t)
	local window_name = Resource:new("window")

	t:is(getmetatable(window_name).__index, Resource)
	t:is(window_name.data, "window")

	window_name.data = "new window"
	t:is(window_name.data, "new window")
end)

test('create table resource', function(t)
	local window_name = Resource:new({ width = 800, height = 600 })

	t:is(getmetatable(window_name).__index, Resource)
	t:is(window_name.data.width, 800)
	t:is(window_name.data.height, 600)
end)

test('modify resource data', function(t)
	local window_name = Resource:new({ width = 800, height = 600 })

	t:is(getmetatable(window_name).__index, Resource)
	t:is(window_name.data.width, 800)
	t:is(window_name.data.height, 600)

	window_name.data.width = 1024
	t:is(window_name.data.width, 1024)
end)

-- Entity

test('create entity', function(t)
	local entity = Entity:new()

	t:is(getmetatable(entity).__index, Entity)
end)

test('create entity with components', function(t)
	local Name = Component:new('default')
	local Position = Component:new({ x = 1, y = 2 })
	local Animal = Component:new()

	local entity = Entity:new(
		Name:new("Taya"),
		Position:new({ x = 10, y = 20 })
	)

	t:is(getmetatable(entity).__index, Entity)

	t:isTrue(entity:has(Name))
	t:isTrue(entity:has(Position))
	t:isFalse(entity:has(Animal))

	t:is(entity:get(Name).data, "Taya")
	t:is(entity:get(Position).data, { x = 10, y = 20 })
end)

test('remove component from entity', function(t)
	local Tag = Component:new()

	local entity = Entity:new(
		Tag:new()
	)

	entity:remove(Tag)
	t:isFalse(entity:has(Tag))
end)

test('add component to entity', function(t)
	local Tag = Component:new()

	local entity = Entity:new()

	t:isFalse(entity:has(Tag))
	entity:add(Tag:new())
	t:isTrue(entity:has(Tag))
end)

test('modify component data', function(t)
	local Name = Component:new("default")
	local entity = Entity:new(
		Name:new("Taya")
	)

	t:is(entity:get(Name).data, "Taya")

	entity:get(Name).data = "Evee"

	t:is(entity:get(Name).data, "Evee")
end)

-- System
test('create system', function(t)
	local query = Query:new()
	local func = function() end
	local system = System:new(query, func)

	t:is(getmetatable(system).__index, System)
	t:is(getmetatable(system.query).__index, Query)
	t:is(system.query, query)
	t:is(system.func, func)
end)

-- World

test('create world', function(t)
	local world = World:new()
	t:is(getmetatable(world).__index, World)
end)

test('add entity to world', function(t)
	local world = World:new()
	local entity = Entity:new()

	world:addEntity(entity)

	t:is(world.entities[1], entity)
end)

test('remove entity from world', function(t)
	local world = World:new()
	local entity = Entity:new()

	world:addEntity(entity)
	t:is(world.entities[1], entity)

	world:removeEntity(entity)
	t:is(#world.entities, 0)
end)

test('add system to world', function(t)
	local world = World:new()
	local query = Query:new()
	local func = function() end
	local system = System:new(query, func)

	world:addSystem('update', system)

	t:is(world.schedules.update[1], system)
end)

test('remove system from world', function(t)
	local world = World:new()

	local system = System:new(Query:new(), function() end)

	world:addSystem('update', system)
	t:is(world.schedules.update[1], system)

	world:removeSystem('update', system)
	t:is(#world.schedules.update, 0)
end)

test('add multiple systems to world', function(t)
	local world = World:new()

	local system1 = System:new(Query:new(), function() end)
	local system2 = System:new(Query:new(), function() end)

	world:addSystems('update', system1, system2)

	t:is(world.schedules.update[1], system1)
	t:is(world.schedules.update[2], system2)
end)

test('simple query', function(t)
	local world = World:new()

	local Name = Component:new('default')

	local entity1 = Entity:new(Name:new("Taya"))
	local entity2 = Entity:new(Name:new("Evee"))

	world:addEntity(entity1)
	world:addEntity(entity2)

	local query = Query:new():with(Name)

	local results = query:apply(world)
	t:is(results, {
		{ "Taya" },
		{ "Evee" }
	})
end)

test('query with optional component', function(t)
	local world = World:new()
	local Name = Component:new('default')
	local Nickname = Component:new('default')

	local entity1 = Entity:new(Name:new("Samantha"), Nickname:new("Sam"))
	local entity2 = Entity:new(Name:new("John"))

	world:addEntity(entity1)
	world:addEntity(entity2)

	local query = Query:new():with(Name):optional(Nickname)

	local results = query:apply(world)
	t:is(results, {
		{ "Samantha", "Sam" },
		{ "John",     nil }
	})
end)

test('query with tag component', function(t)
	local world = World:new()
	local Name = Component:new('default')
	local Tag = Component:new()

	local entity1 = Entity:new(Name:new("Taya"), Tag:new())
	local entity2 = Entity:new(Name:new("Evee"))

	world:addEntity(entity1)
	world:addEntity(entity2)

	local query = Query:new():with(Tag):with(Name)

	local results = query:apply(world)
	t:is(results, {
		{ "Taya" }
	})
end)

test('query with hidden component', function(t)
	local world = World:new()
	local Name = Component:new('default')
	local Hidden = Component:new('hidden')
	local Color = Component:new('red')

	local entity1 = Entity:new(Name:new("Taya"), Hidden:new(), Color:new())
	local entity2 = Entity:new(Name:new("Evee"))

	world:addEntity(entity1)
	world:addEntity(entity2)

	local query = Query:new():with(Name):with_hidden(Hidden):with(Color)

	local results = query:apply(world)
	t:is(results, {
		{ "Taya", "red" }
	})
end)

test('query with resource', function(t)
	local world = World:new()
	local Name = Component:new('default')
	local Color = Component:new('red')

	local window_name = Resource:new("window")

	local entity1 = Entity:new(Name:new("Taya"), Color:new())
	local entity2 = Entity:new(Name:new("Evee"), Color:new('pink'))

	world:addEntity(entity1)
	world:addEntity(entity2)

	world:addResource(window_name)

	local query = Query:new():with(Name):res(window_name):with(Color)

	local results = query:apply(world)

	t:is(results, {
		{ "Taya", "window", "red" },
		{ "Evee", "window", "pink" }
	})
end)

test.run()

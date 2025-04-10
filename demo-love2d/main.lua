local IS_DEBUG = os.getenv("LOCAL_LUA_DEBUGGER_VSCODE") == "1" and arg[2] == "debug"
if IS_DEBUG then
	require("lldebugger").start()

	function love.errorhandler(msg)
		error(msg, 2)
	end
end

print('Running ECS demo...')

local ecs = require 'ecs'
local Entity = ecs.Entity
local Component = ecs.Component
local World = ecs.World
local Query = ecs.Query
local System = ecs.System
local Resource = ecs.Resource

-- World
-- A world is a container for entities, systems and resources
local overworld = World:new()

-- Components
-- Components are data containers, they do not have behavior
local Position = Component:new({ x = 0, y = 0 })
local Velocity = Component:new({ x = 0, y = 0 })
local Name = Component:new('DefaultName')

-- Tag components
-- Tag components are components that do not have data, they are used to mark entities
local Renderable = Component:new()
local PlayerControlled = Component:new()


-- Resources
-- Resources are global data

---@class TimeResource : Resource
---@field dt number
local Time = Resource:new({ dt = 0 })
overworld:addResource(Time)

-- Entities
-- Entities hold components, they are the objects in the world
local player = Entity:new(
	Position:new { x = 100, y = 100 },
	Renderable:new(),
	Name:new('Player'),
	PlayerControlled:new()
)

local box = Entity:new(
	Position:new { x = 200, y = 100 },
	Velocity:new { x = 0, y = 100 },
	Renderable:new()
)

overworld:addEntity(player)
overworld:addEntity(box)

-- Systems
-- Systems are functions that operate on entities, based on their components
local moveSystem = System:new(
	Query:new():with(Position):with(Velocity):res(Time),
	function(pos, vel, time)
		pos.x = pos.x + vel.x * time.dt
		pos.y = pos.y + vel.y * time.dt
	end
)

local renderSystem = System:new(
	Query:new():with(Position):with(Renderable),
	function(pos)
		love.graphics.setColor(1, 1, 1) -- Set color to white
		love.graphics.circle('fill', pos.x, pos.y, 10)
	end
)

local nameRenderSystem = System:new(
	Query:new():with(Name):with(Position),
	function(name, pos)
		love.graphics.print(name, pos.x, pos.y - 30)
	end
)

local playerControlledSysytem = System:new(
	Query:new():with(PlayerControlled):with(Position),
	function(pos)
		if love.keyboard.isDown('w') then
			pos.y = pos.y - 100 * Time.data.dt
		end
		if love.keyboard.isDown('s') then
			pos.y = pos.y + 100 * Time.data.dt
		end
		if love.keyboard.isDown('a') then
			pos.x = pos.x - 100 * Time.data.dt
		end
		if love.keyboard.isDown('d') then
			pos.x = pos.x + 100 * Time.data.dt
		end
	end
)

-- Schedules
-- Schedules are used to run systems in groups, and a specific order (systems run in registration order)
overworld:addSystems('update', moveSystem, playerControlledSysytem)
overworld:addSystems('draw', renderSystem, nameRenderSystem)

-- Main loop
function love.update(dt)
	Time.data.dt = dt
	overworld:emit('update')
end

function love.draw()
	overworld:emit('draw')
end

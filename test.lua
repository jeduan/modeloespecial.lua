local model = require 'orm'
local class = require 'vendor.middleclass.middleclass'

describe('Model', function()
	it('subclasses', function()

		local Fruit = model:extend('fruits')
		local orange = Fruit:new()

		assert.truthy(Fruit:isSubclassOf(model))
		assert.truthy(orange:isInstanceOf(Fruit))

	end)

	it('creates a table', function()
		local Player = model:extend 'players'
		assert.truty(Player)
	end)
end)

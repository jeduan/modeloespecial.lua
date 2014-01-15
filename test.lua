package.preload['sqlite3'] = require 'lsqlite3'
local log = require 'vendor.log.log'

local model = require 'model'
local class = require 'vendor.middleclass.middleclass'

describe('Model', function()
	describe('Subclassing', function()
		it('works', function()
			local Fruit = model:extend('fruits', {
				'name',
			})
			local orange = Fruit:new()

			assert.truthy(Fruit:isSubclassOf(model))
			assert.truthy(orange:isInstanceOf(Fruit))
		end)

	end)

	describe('Creating classes', function()
		setup(function()
			Player = model:extend('players', {
				name = 'string'
			})
		end)

		teardown(function()
			Player = nil
		end)

		it('creates an instance', function()
			assert.truthy(Player)

			local player = Player:new {
				name = 'Jeduan'
			}

		end)

		it('get works', function()
			local player = Player:new {
				name = 'Jeduan'
			}
			assert.equal(player:get('name'), 'Jeduan')
		end)

		it('set works', function()
			local player = Player:new {
				name = 'Jeduan'
			}
			player:set('name', 'Manolo')
			assert.equal(player:get('name'), 'Manolo')
		end)

	end)
end)

package.preload['sqlite3'] = require 'lsqlite3'
package.path = package.path .. ';mocks/?.lua'
_G.Runtime = require 'runtime'
local log = require 'vendor.log.log'

local Db = require 'db'
local model = Db.Model
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

		it('setting multiple keys works', function()
			local player = Player:new {
				name = 'Jeduan'
			}
			player:set {name = 'Manolo', company = 'Yogome'}
			assert.equal(player:get('name'), 'Manolo')
			assert.equal(player:get('company'), 'Yogome')
		end)
	end)

	describe('Database', function()
		it('shoud be instantiated', function()
			local db = Db:new {location = 'memory'}
			assert.truthy(db)
		end)
	end)

	describe('Database migrations', function()
		setup(function()
			db = Db:new {location = 'memory'}
		end)

		it('returns 0 as first version', function()
			assert.equal(db:migrate(), 0)
		end)
	end)
end)

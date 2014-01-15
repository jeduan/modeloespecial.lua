package.preload['sqlite3'] = require 'lsqlite3'
_G.Runtime = require 'mocks.runtime'
local log = require 'vendor.log.log'

local Db = require 'db'
local model = Db.Model
local class = require 'vendor.middleclass.middleclass'
local sqlite = require 'sqlite3'

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

	describe('Saves documents', function()
		setup(function()
			local function createPlayers(schemaVersion, exec)
				if schemaVersion < 1 then
					exec "CREATE TABLE players(name VARCHAR)"
				end
				return 1
			end
			db = Db:new {location = 'memory', migration = createPlayers}
			Player = model:extend('players', {
				'name'
			})
			local sql = 'SELECT COUNT(*) FROM players WHERE name=:name'
			stmt = db.db:prepare(sql)
		end)

		teardown(function()
			db = nil
			Player = nil
			stmt:finalize()
			stmt = nil
		end)

		it('saves a document', function()
			stmt:bind_names {name = 'Jeduan'}
			assert.equal(stmt:step(), sqlite.ROW)
			assert.equal(stmt:get_value(0), 0)
			stmt:reset()

			local player = Player:new {name = 'Jeduan'}
			player:save()

			assert.equal(stmt:step(), sqlite.ROW)
			assert.equal(stmt:get_value(0), 1)
		end)

	end)
end)

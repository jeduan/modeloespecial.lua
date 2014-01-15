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

	describe('Database', function()
		setup(function()
			db = Db:new {location = 'memory'}
		end)

		teardown(function()
			db = nil
		end)

		it('shoud be instantiated', function()
			assert.truthy(db)
		end)

		it('models have access to the db object', function()
			assert.truthy(model.db)
			local Player = model:extend('players', {name = true})
			assert.truthy(Player.db)
		end)
	end)

	describe('Database migrations', function()
		setup(function()
			db = Db:new {location = 'memory'}
			sql = 'SELECT count(*) FROM sqlite_master WHERE type="table" AND name="players"'
			tableExists = db.db:prepare(sql)
		end)

		teardown(function()
			db = nil
			tableExists:finalize()
			tableExists = nil
			sql = nil
		end)

		it('returns 0 as first version', function()
			assert.equal(db:schemaVersion(), 0)
		end)

		it('table doesnt exist beforehand', function()
			assert.equal(tableExists:step(), sqlite.ROW)
			assert.equal(tableExists:get_value(0), 0)
			tableExists:reset()
		end)

		it('migrates a table', function()
			local function migration(currentVersion, exec)
				if currentVersion < 1 then
					exec 'CREATE TABLE players(name VARCHAR)'
				end
				return 1
			end
			db:migrate(migration)

			assert.equal(db:schemaVersion(), 1)
			assert.equal(tableExists:step(), sqlite.ROW)
			assert.equal(tableExists:get_value(0), 1)
			tableExists:reset()
		end)

		it('Can create a db with a migration', function()
			local function migration(currentVersion, exec)
				if currentVersion < 1 then
					exec 'CREATE TABLE players(name VARCHAR)'
				end
				return 1
			end
			local test = Db:new {
				location = 'memory',
				migration = migration
			}

			local stmt = test.db:prepare(sql)
			assert.equal(test:schemaVersion(), 1)
			assert.equal(stmt:step(), sqlite.ROW)
			assert.equal(stmt:get_value(0), 1)
			stmt:finalize()
			stmt = nil
		end)
	end)
end)

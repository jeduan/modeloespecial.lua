package.preload['sqlite3'] = require 'lsqlite3'
_G.Runtime = require 'mocks.runtime'
local log = require 'vendor.log.log'

local ModeloEspecial = require 'modeloespecial'
local model = ModeloEspecial.Model
local sqlite = require 'sqlite3'

describe('Database', function()
	setup(function()
		db = ModeloEspecial:new {location = 'memory'}
	end)

	teardown(function()
		db = nil
	end)

	it('shoud be instantiated', function()
		assert.truthy(db)
	end)

	it('models have access to the db object', function()
		assert.truthy(model.db)
		local Player = db.Model:extend {table = 'players'}
		assert.truthy(Player.db)
	end)
end)

describe('Database migrations', function()
	setup(function()
		db = ModeloEspecial:new {location = 'memory'}
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
		local test = ModeloEspecial:new {
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

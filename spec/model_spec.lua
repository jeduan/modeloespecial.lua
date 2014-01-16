package.preload['sqlite3'] = require 'lsqlite3'
_G.Runtime = require 'mocks.runtime'
local log = require 'vendor.log.log'

local ModeloEspecial = require 'modeloespecial'
local Model = ModeloEspecial.Model
local class = require 'vendor.middleclass.middleclass'
local sqlite = require 'sqlite3'

describe('Model', function()
	describe('Subclassing', function()
		it('works', function()
			local Fruit = Model:extend {table = 'fruits'}
			local orange = Fruit:new()

			assert.truthy(Fruit:isSubclassOf(Model))
			assert.truthy(orange:isInstanceOf(Fruit))
		end)

	end)

	describe('Creating classes', function()
		setup(function()
			Player = Model:extend {table = 'players'}
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
			db = ModeloEspecial:new {location = 'memory', migration = createPlayers}
			Player = Model:extend {table = 'players'}
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
			assert.truthy(player:save())

			assert.equal(stmt:step(), sqlite.ROW)
			assert.equal(stmt:get_value(0), 1)
		end)

	end)

	describe('Updates and fetches documents', function()
		setup(function()
			local function createPlayers(schemaVersion, exec)
				if schemaVersion < 1 then
					exec "CREATE TABLE players(name VARCHAR)"
				end
				return 1
			end
			db = ModeloEspecial:new {location = 'memory', migration = createPlayers}
			Player = Model:extend {table = 'players'}
			local sql = 'SELECT COUNT(*) FROM players WHERE name=:name'
			stmt = db.db:prepare(sql)

			player = Player:new {name = 'Jeduan'}
			playerId = player:save()
		end)

		teardown(function()
			db = nil
			Player = nil
			stmt:finalize()
			stmt = nil
			player = nil
			playerId = nil
		end)

		it('updates a document', function()
			stmt:bind_names {name = 'Jeduan'}
			assert.equal(stmt:step(), sqlite.ROW)
			assert.equal(stmt:get_value(0), 1)
			stmt:reset()
			stmt:bind_names {name = 'Manolo'}
			assert.equal(stmt:step(), sqlite.ROW)
			assert.equal(stmt:get_value(0), 0)
			stmt:reset()

			assert.truthy(player.id)
			player:set {name = 'Manolo'}
			assert.True(player:save())

			stmt:bind_names {name = 'Jeduan'}
			assert.equal(stmt:step(), sqlite.ROW)
			assert.equal(stmt:get_value(0), 0)
			stmt:reset()
			stmt:bind_names {name = 'Manolo'}
			assert.equal(stmt:step(), sqlite.ROW)
			assert.equal(stmt:get_value(0), 1)
			stmt:reset()
		end)

		--[[
		it('can change a document id', function()
			pending('Cant do this right now')
		end)
		--]]

		it('fetches a document', function()
			stmt:bind_names {name = 'Manolo'}
			assert.equal(stmt:step(), sqlite.ROW)
			assert.equal(stmt:get_value(0), 1)
			assert.truthy(playerId)
			stmt:reset()

			local p = Player:fetchById(1)
			assert.equal('Manolo', p:get('name'))
			assert.equal(1, p.id)

		end)

		it('returns nil when document does not exist', function()
			local _ = Player:fetchById(20)
			assert.equal(_, nil)
		end)

	end)

	describe('Model functionalities', function()
		setup(function()
			local function createPlayers(schemaVersion, exec)
				if schemaVersion < 1 then
					local sql = [[CREATE TABLE players (
firstName VARCHAR,
lastName VARCHAR,
age INTEGER)]]
					exec(sql)
				end
				return 1
			end
			local db = ModeloEspecial:new {
				location = 'memory',
				migration = createPlayers,
			}
			Player = Model:extend {table = 'players'}
			function Player:fullName()
				return self:get'firstName' .. ' ' .. self:get'lastName'
			end

			player = Player:new {
				firstName = 'Jeduan',
				lastName = 'Cornejo'
			}
			function Player:getFullName()
				return self:get'firstName' .. ' ' .. self:get'lastName'
			end
		end)

		teardown(function()
			Player = nil
			player = nil
		end)

		it('methods work', function()
			assert.equal('Jeduan Cornejo', player:getFullName())
		end)

		it('defaults work', function()
			Player.defaults = {
				lastName = 'Lopez'
			}

			local p = Player:new {firstName = 'Juan'}

			assert.equal(p:get'firstName', 'Juan')
			assert.equal(p:get'lastName', 'Lopez')
			assert.equal(p:getFullName(), 'Juan Lopez')
		end)
	end)
end)

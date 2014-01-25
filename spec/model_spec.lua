package.preload['sqlite3'] = require 'lsqlite3'
_G.Runtime = require 'mocks.runtime'
_G.timer = require 'mocks.timer'
local log = require 'vendor.log.log'
local ev = require 'ev'

local ModeloEspecial = require 'modeloespecial'
local Model = ModeloEspecial.Model
local class = require 'vendor.middleclass.middleclass'
local sqlite = require 'sqlite3'

setloop'ev'
local function nextTick(onTimeout)
	ev.Timer.new(function()
		onTimeout()
	end, 2^-40):start(ev.Loop.default)
end

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

		it('emits saving, creating and updating events', function(done)
			nextTick(async(function()
				local c = {
					saved = 0,
					created = false,
					updated = false
				}
				local v = {
					saved   = function(i) c.saved   = c.saved + 1 end,
					created = function(i) c.created = true end,
					updated = function(i) c.updated = true end,
				}
				Player:on('saved',   v.saved)
				Player:on('created', v.created)
				Player:on('updated', v.updated)

				local p = Player:new {firstName = 'Alberto'}
				p:save()
				p:set {firstName = 'Tino'}
				p:save()

				timer.performWithDelay(1, function()
					assert.equals(c.saved, 2)
					assert.True(c.created)
					assert.True(c.updated)
					Player:off('saved')
					Player:off('created')
					Player:off('updated')
					done()
				end)

			end))
		end)

		it('can abort saving if an error is thown on saving', function(done)
			nextTick(async(function()
				local p = Player:new { firstName = 'Tino' }
				local function checkAdult(self)
					local age = self:get'age'
					if not age or age < 18 then
						error 'User is not an adult'
					end
				end
				Player:on('saving', checkAdult)
				p:save()
				assert.falsy(p.id, 'Did create a player without age')
				p:set {age = 30}
				p:save()
				assert.truthy(p.id)
				Player:off('saving')
				done()
			end))
		end)

		it('can change a model with events', function(done)
			nextTick(async(function()
				local p = Player:new { firstName = 'Tino' }
				local function checkAdult(self)
					local age = self:get'age'
					local lastName = self:get'lastName'
					if not age then
						self:set {age = 33}
					end
					if lastName == 'Lopez' then
						self:set {lastName = 'Tello'}
					end
				end
				Player:on('creating', checkAdult)
				p:save()
				assert.equals(p:get'age', 33)
				assert.equals(p:get'lastName', 'Tello')
				Player:off('creating')
				done()
			end))
		end)

	end)
end)

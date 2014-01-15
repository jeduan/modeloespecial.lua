local class  = require 'vendor.middleclass.middleclass'
local vent   = require 'vendor.vent.vent'
local log    = require 'vendor.log.log'
local sqlite = require 'sqlite3'

local Db = class('Db')
Db.Model = require 'model'

function Db:initialize(options)
	options = options or {}
	assert(type(self) == 'table', 'called .new instead of :new')
	assert(type(options) == 'table', 'Expected options to be a table')

	if options.location == 'memory' then
		-- for testing purposes
		self.db = sqlite.open_memory()
	else
		options.name = options.name or 'db'
		options.location = options.location or system.DocumentsDirectory

		local path = system.pathForFile(options.name .. '.sqlite', options.location)
		self.db = sqlite3.open(path)
	end

	if options.debug then
		self.db:trace(function(udata, sql)
			log('[SQL] ' .. sql)
		end, {})
	end

	self:_registerOnExit()
	self:migrate()
end

function Db:_registerOnExit()
	if self.closeOnExit then
		return
	end
	Runtime:addEventListener('system', function(event)
		if event.type == "applicationExit"  then
			if self.db and self.db:isopen() then
				self.db:close()
				self.db = nil
			end
		end
	end)
	self.closeOnExit = true
end

function Db:migrate()
	local stmt = self.db:prepare 'PRAGMA user_version'
	assert(stmt, 'Failed to prepare statement')

	local step = stmt:step()
	assert(step == sqlite3.ROW, 'Error while getting version')

	local version = stmt:get_value(0)
	assert(version, 'Failed to get version')

	stmt:finalize()
	return version
end

return Db

local log = require 'vendor.log.log'
local class = require 'vendor.middleclass.middleclass'
local vent = require 'vendor.vent.vent'
local sqlite = require 'sqlite3'

local Model = class('Model')

function Model:initialize(attributes, options)
	assert(type(self) == 'table', 'Called .get instead of :get')
	self.changed = {}

	self.attributes = attributes or {}
	assert(type(self.attributes) == 'table', 'Expected attributes to be a table')

	-- TODO aqui se pueden poner los defaults
	self.isNew = true
end

function Model:save()
	assert(Model.db, 'The database is closed')
	assert(Model.db:isopen(), 'The database is closed')
	if not self.id then
		return self:insert()
	else
		-- update()
	end
end

function Model:get(attribute)
	assert(type(self) == 'table', 'Called .get instead of :get')
	return self.attributes[attribute]
end

function Model:set(key, val, options)
	assert(type(self) == 'table', 'Called .set instead of :set')

	local attrs, prev, current
	local changes = {}

	if key == nil then
		return self
	end

	if type(key) == 'table' then
		attrs = key
		options = val
	else
		attrs = {}
		attrs[key] = val
	end

	-- TODO validate
	current = self.attributes
	for key, val in pairs(attrs) do
		-- TODO hacer que compare tablas
		if current[key] ~= val then
			changes[key] = true
			self.changed[key] = true
		end
		current[key] = val
	end
	return self
end

function Model:fetch()
	assert(type(self) == 'table', 'self')
end

function Model:insert()
	assert(not self.id, 'Tried to run insert on a model with id')
	local sql = 'INSERT INTO %s (%s) VALUES (%s)'
	local storedAttributes = {}
	local preparedAttributes = {}

	-- TODO validate object beforehand
	for k, v in pairs(self.class.static.attrs) do
		if self.attributes[k] ~= nil then
			table.insert(storedAttributes, k)
			table.insert(preparedAttributes, ':' .. k)
		end
	end

	sql = sql:format(self.tableName,
	table.concat(storedAttributes, ','),
	table.concat(preparedAttributes, ','))

	local stmt = Model.db:prepare(sql)
	assert(stmt, 'Failed to prepare insert-statement')
	stmt:bind_names(self.attributes)
	assert(stmt:step() == sqlite.DONE, 'Failed to insert insert-statement '.. Model.db:errmsg())

	self.id = Model.db:last_insert_rowid()
	assert(self.id ~= 0, 'Insert failed')

	return self
end

function Model.static:extend(tableName, attributes, options)
	assert(type(self) == 'table', 'Ensure you are calling model:extend and not model.extend')
	assert(tableName, 'model:extend should be called with tableName')
	local klass = class(tableName, Model)
	klass.tableName = tableName

	assert(attributes, 'model:extend should be called with attributes')
	klass.static.attrs = {}
	for i, k in ipairs(attributes) do
		klass.static.attrs[k] = true
	end

	return klass
end


return Model

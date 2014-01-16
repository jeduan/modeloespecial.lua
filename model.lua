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
	assert(self.class.db, 'The database is closed')
	assert(self.class.db:isopen(), 'The database is closed')
	if not self.id then
		return self:insert()
	else
		return self:update()
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

	sql = sql:format(self.class.static.tableName,
		table.concat(storedAttributes, ','),
		table.concat(preparedAttributes, ','))

	local stmt = self.class.db:prepare(sql)
	assert(stmt, 'Failed to prepare insert-statement')
	assert(stmt:bind_names(self.attributes) == sqlite.OK, 'Failed to bind values')
	local step = stmt:step()
	if step ~= sqlite.DONE then
		stmt:finalize()
		return nil, self.class.db:errmsg()
	end

	stmt:finalize()
	stmt = nil
	self.id = self.class.db:last_insert_rowid()
	assert(self.id ~= 0, 'Insert failed')

	return self.id
end

function Model:update()
	assert(self.id, 'Tried to run update on not inserted model')

	local sql = 'UPDATE %s SET %s WHERE %s=:modelId'
	-- TODO validate object first

	local values = {modelId = self.id}
	local changes = {}

	for k, v in pairs(self.class.static.attrs) do
		if self.changed[k] then
			table.insert(changes, k .. '=:' .. k)
			values[k] = self.attributes[k]
			shouldUpdate = true
		end
	end

	if #changes == 0 then
		return true
	end

	sql = sql:format(self.class.static.tableName,
		table.concat(changes, ', '),
		self.class.static.idAttribute)

	local stmt = self.class.db:prepare(sql)
	assert(stmt, 'Failed to prepare update-model statement')

	assert(stmt:bind_names(values) == sqlite.OK, 'Failed to bind values')
	local step = stmt:step()
	stmt:finalize()
	stmt = nil

	if step == sqlite.DONE then
		return true
	else
		return nil, self.class.db:errmsg()
	end
end

function Model.static:extend(tableName, attributes, options)
	assert(type(self) == 'table', 'Ensure you are calling model:extend and not model.extend')

	if type(tableName) == 'table' then
		options = tableName
		tableName = options.tableName or options.name
		options.tableName = nil
		attributes = options.attributes or options.attrs
		options.attributes = nil
	end
	assert(tableName, 'model:extend should be called with tableName')
	options = options or {}

	-- TODO classify tableName
	local klass = class(tableName, Model)
	klass.static.tableName = tableName
	klass.static.idAttribute = options.idAttribute or 'ROWID'

	assert(attributes, 'model:extend should be called with attributes')
	klass.static.attrs = {}
	for i, k in ipairs(attributes) do
		klass.static.attrs[k] = true
	end

	return klass
end


return Model

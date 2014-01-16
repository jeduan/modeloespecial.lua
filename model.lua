local log = require 'vendor.log.log'
local class = require 'vendor.middleclass.middleclass'
local vent = require 'vendor.vent.vent'
local sqlite = require 'sqlite3'

local Model = class('Model')

function Model:initialize(attributes, options)
	assert(type(self) == 'table', 'Called .new instead of :new')
	attributes = attributes or {}
	options    = options or {}
	assert(type(attributes) == 'table', 'Expected attributes to be a table')
	self.changed    = {}
	self.attributes = {}
	for k, v in pairs(attributes) do
		if string.lower(k) == string.lower(self.class.idAttribute) then
			self.id = v
		elseif string.lower(k) == 'id' then
			self.id = v
		end
		self.attributes[k] = attributes[k]
	end

	self.synced = options.synced

	-- TODO aqui se pueden poner los defaults
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

function Model.static:fetchById(id)
	assert(type(self) == 'table', 'Tried to call .fetchById() instead of :fetchById()')
	assert(type(id) == 'number', 'Expected arg to be a number')

	local attrs = {self.idAttribute}
	for k, v in pairs(self.attrs) do
		table.insert(attrs, k)
	end

	local sql = string.format('SELECT %s FROM %s WHERE %s=?1',
		table.concat(attrs, ', '),
		self.tableName,
		self.idAttribute
	)

	local stmt = self.db:prepare(sql)
	assert(stmt, 'Failed to prepare select-id statement')

	assert(stmt:bind_values(id) == sqlite.OK, 'Failed to bind parameters')
	local step = stmt:step()

	if step == sqlite.ROW then
		local attributes = stmt:get_named_values()
		return self:new(attributes, {synced = true})
	elseif step == sqlite.DONE then
		stmt:finalize()
		stmt = nil
		return nil
	end

end

function Model:insert()
	assert(not self.id, 'Tried to run insert on a model with id')
	local sql = 'INSERT INTO %s (%s) VALUES (%s)'
	local storedAttributes = {}
	local preparedAttributes = {}

	-- TODO validate object beforehand
	for k, v in pairs(self.class.attrs) do
		if self.attributes[k] ~= nil then
			table.insert(storedAttributes, k)
			table.insert(preparedAttributes, ':' .. k)
		end
	end

	sql = sql:format(self.class.tableName,
		table.concat(storedAttributes, ','),
		table.concat(preparedAttributes, ','))

	local stmt = self.class.db:prepare(sql)
	assert(stmt, 'Failed to prepare insert-statement ' .. self.class.db:errmsg())
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

	for k, v in pairs(self.changed or {}) do
		if self.class.attrs[k] then
			table.insert(changes, k .. '=:' .. k)
			values[k] = self.attributes[k]
		end
	end

	if #changes == 0 then
		return true
	end

	sql = sql:format(self.class.tableName,
		table.concat(changes, ', '),
		self.class.idAttribute)

	local stmt = self.class.db:prepare(sql)
	assert(stmt, 'Failed to prepare update-model statement')

	assert(stmt:bind_names(values) == sqlite.OK, 'Failed to bind values')
	local step = stmt:step()
	stmt:finalize()
	stmt = nil

	if step == sqlite.DONE then
		self.changed = {}
		return true
	else
		return nil, self.class.db:errmsg()
	end
end

function Model.static:extend(options)
	assert(type(self) == 'table', 'Ensure you are calling model:extend and not model.extend')

	options = options or {}
	assert(options.table, 'model:extend should specify a table')

	if not options.attrs then
		if self.db then
			options.attrs = {}
			for row in self.db:nrows('PRAGMA table_info('.. options.table ..')') do
				options.attrs[row.name] = row.type
			end
		else
			options.attrs = {}
		end
	end

	-- TODO classify tableName
	local klass = class(options.table, self)
	klass.tableName = options.table
	klass.idAttribute = options.idAttribute or 'ROWID'
	klass.attrs = options.attrs

	return klass
end


return Model

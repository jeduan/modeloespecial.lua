local log = require 'vendor.log.log'
local class = require 'vendor.middleclass.middleclass'
local vent = require 'vendor.vent.vent'
local sqlite = require 'sqlite3'

local Model = class('Model')

function Model:initialize(attributes, options)
	self.changedAttributes = {}

	self.attributes = attributes or {}
	assert(type(self.attributes) == 'table', 'Expected attributes to be a table')

	if options.requiredAttributes then
		for i, k in pairs(options.requiredAttributes) do
			self.attributes[k] = true
		end
	end
	self.isNew = true
end

function Model:save()
	if self.isNew then
		-- insert()
		self.isNew = false
	else
		-- update()
	end
end

function Model:get(attribute)
	return self.attributes[attribute]
end

function Model:set(attribute, value)
	self.attributes[attribute] = value
	table.insert(self.changedAttributes, attribute)
end

function Model:fetch()
	assert(type(self) == 'table', 'self')
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

	function klass.initialize(self, attributes, options)
		options = options or {}
		options.requiredAttributes = klass.static.attrs
		klass.super.initialize(self, attributes, options)
	end

	return klass
end


return Model

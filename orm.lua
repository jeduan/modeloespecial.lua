local log = require 'vendor.log.log'
local class = require 'vendor.middleclass.middleclass'
local vent = require 'vendor.vent.vent'

local Model = class('Model')

function Model:initialize(tableName)

end

function Model:migrate(version)

end

Model.idAttribute = 'id'

function Model:save()
	if self.isNew then
		insert()
	else
		update()
	end
end

function Model:fetch()
end

function Model:extend(tableName)
	assert(type(self) == 'table', 'Ensure you are calling model:extend and not model.extend')
	local klass = class(tableName, Model)

	assert(type(tableName) == 'string', 'Expected tableName to be a string')
	klass.tableName = tableName
	return klass
end


return Model

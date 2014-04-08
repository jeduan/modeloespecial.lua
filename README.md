# modeloespecial.lua

An ORM for Corona SDK based on Backbone.js

![](http://d.pr/i/EGRS+)

```lua
local User = Model:extend {table = 'users'}
function User:fullName()
  return self:get('firstName') .. ' ' .. self:get('lastName')
end

local user = User:new {firstName = 'John', lastName = 'Doe'}
user:fullName() -- John Doe
user:save()

user:set {firstName = 'Foo', lastName = 'White'}
user:save()
```

Fair warning: This is a work in progress, but expect fast updates as we use this on our games.

## Installing

### With bower

Generate a project using [corona-bower](http://github.com/jeduan/generator-corona-bower) and then install this library with

    bower install --save modeloespecial

### Manually

Download the zip containing all files on the [Releases tab](https://github.com/jeduan/modeloespecial.lua/releases)

## Initialize

Instantiate a ModeloEspecial instance

```lua
local ModeloEspecial = require 'vendor.modeloespecial.modeloespecial'
local Model = ModeloEspecial.Model

local db = ModeloEspecial:new {name = 'database'}
```

`ModeloEspecial:new` receives the following parameters

 - `name` (required) the name of the database
 - `location` (default: `system.DocumentsDirectory`) the location of the database
 - `debug` (default: false) log to the database all executed sql queries
 - `migration` see below.

A special case is when `location` equals `"memory"`. This will create an in-memory instance of sqlite.

## Migrations

You can create tables and version the schema of the database.

This way, even if a game user has an old version of the database, we can get it to the current version.

```lua
local function createUsers(schemaVersion, exec)
  if schemaVersion < 1 then
    exec('CREATE TABLE users(name VARCHAR, color INTEGER)')
  end
  return 1
end
db:migrate(createUsers)
```

Migration functions receive the following parameters

 - `schemaVersion` (number) the current schema version
 - `exec` (function(sql)) a function to execute the given `sql`.

## Models

### Model:extend()

Create a new model

```lua
local User = Model:extend {table = 'users'}
```

`Model:extend` receives an table with the following possible parameters

 - `table` (required) The name of the table
 - `attrs` The attributes that this table has. By default ModeloEspecial will explore the table and get all columns
 - `idAttribute` The name of the unique identifier in the table. default: 'ROWID'

### model:save()

saves or updates a model to the database

```lua
local user = User:new {name = 'Foo', color = 'orange'}
user:save() -- executes: INSERT INTO users(name, color) VALUES ('Foo', 'orange')

user:set('name', 'Bar')
user:save() -- executes: UPDATE users SET name='Bar' WHERE ROWID=1
```

### model:get()

gets an attribute from a model

```lua
local user = User:new {name = 'Foo'}
user:get 'name' -- 'Foo'
```

It receives

 - `attribute` - name of the attribute

### model:set()

sets and attribute for a model and marks it to change on the next update

```lua
local user = User:new()
user:set('name', 'Foo')
user:set {color = 'red'}
```

It can receive either

 - `attribute` name of the attribute
 - `value` value of the attribute

or

 - `changes` a table with the desired attribute changes

### Model:fetchById()

Finds a user by the id

```lua
local user = User.fetchById(1)
```

### Model:fetchBy()

Finds a user by the specified params

```lua
local user = User.fetchBy {name = 'Foo'}
```

### Model.defaults

Sets default values for attributes

```lua
User.defaults = {
  color = 'red'
}
local user = User:new()

user:get'color' -- 'red'
```

### Model events

Before persisting changes, a `saving` event is emitted. Also, either an `updating` or `creating` event will be emitted.

If a listener to this events throws an `error` then the model will not be persisted and `Model:save()` will return false

```lua
local function hasLastName(self)
  if not self:get('lastName') then
    error('No last name was specified')
  end
end
User:on('saving', hasLastName)
```

Also any changes done to self on the event handlers are persisted
```lua
local function validateStates(self)
  local state = self:get('state')
  if state == 'CA' then
    self:set {state = 'California'}
  end
end
```

## Changelog

 * 0.0.3 Adds `creating`, `created`, `saving`, `saved`, `updating` and `updated` events
 * 0.0.2 Adds defaults

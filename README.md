# Modelo Especial

An ORM for Corona SDK based on Backbone.js

```lua
local User = Model:extend {table = 'users'}
function User:fullName()
  return self:get('firstName') .. ' ' .. self:get('lastName')
end

local user = User:new {firstName = 'John', lastName = 'Doe'}
user:save()

user:get('name') -- Foo

user:set {name = 'Bar', color = 'white'}
user:save()
```

## Installing

### With bower

Generate a project using [corona-bower](http://github.com/jeduan/generator-corona-bower) and then install this library with

    bower install --save modeloespecial

### Manually

Drag `modeloespecial.lua`, `model.lua`, `middleclass.lua`, `vent.lua` and `log.lua` to your project.

Then fix the `require` directives at the top of the project

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
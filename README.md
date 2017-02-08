# SchemaValidations

SchemaValidations is an ActiveRecord extension that keeps your model class
definitions simpler and more DRY, by automatically defining validations based
on the database schema.

[![Gem Version](https://badge.fury.io/rb/schema_validations.svg)](http://badge.fury.io/rb/schema_validations)
[![Build Status](https://secure.travis-ci.org/SchemaPlus/schema_validations.svg)](http://travis-ci.org/SchemaPlus/schema_validations)
[![Coverage Status](https://coveralls.io/repos/SchemaPlus/schema_validations/badge.svg?branch=master&service=github)](https://coveralls.io/github/SchemaPlus/schema_validations)


## Overview

One of the great things about Rails (ActiveRecord, in particular) is that it
inspects the database and automatically defines accessors for all your
columns, keeping your model class definitions simple and DRY.  That's great
for simple data columns, but where it falls down is when your table contains
constraints.

```ruby
create_table :users do |t|
    t.string :email, null: false, limit: 30
    t.boolean :confirmed, null: false
end
```

In that case the constraints `null: false`, `limit: 30` and `:boolean` must be validated on the model level, to avoid ugly database exceptions:

```ruby
class User < ActiveRecord::Base
    validates :email, presence: true, length: { maximum: 30 }
    validates :confirmed, presence: true, inclusion: { in: [true, false] }
end
```

...which isn't the most DRY approach.

SchemaValidations aims to DRY up your models, doing that boring work for you. It inspects the database and automatically creates validations based on the schema. After installing it your model is as simple as it can be.

```ruby
class User < ActiveRecord::Base
end
```

Validations are there but they are created by schema_validations under the
hood.

## Installation

Simply add schema_validations to your Gemfile.

```ruby
gem "schema_validations"
```
    
## Which validations are covered?

Constraints:

|      Constraint     |                     Validation                    |
|---------------------|---------------------------------------------------|
| `null: false`    | `validates ... presence: true`                       |
| `limit: 100`     | `validates ... length: { maximum: 100 }`             |
| `unique: true`   | `validates ... uniqueness: true`                     |
| `unique: true, case_sensitive: false` <br>(If [schema_plus_pg_indexes](https://github.com/SchemaPlus/schema_plus_pg_indexes) is also in use) | `validates ... uniqueness: { case_sensitive: false }` |

Data types:

|         Type       |                      Validation                                                                      |
|--------------------|------------------------------------------------------------------------------------------------------|
| `:boolean`         | `:validates ... inclusion: { in: [true, false] }`                                                    |
| `:float`           | `:validates ... numericality: true`                                                                  |
| `:integer`         | `:validates ... numericality: { only_integer: true, greater_than_or_equal_to: ..., less_than: ... }` |
| `:decimal, precision: ...`         | `:validates ... numericality: { greater_than: ..., less_than: ... }`                                |


## What if I want something special?

SchemaValidations' behavior can be configured globally and per-model.

### Global configuration

In an initializer, such as `config/initializers/schema_validations.rb`, you can set any of these options.  The default values are shown.

```ruby
SchemaValidations.setup do |config|

    # Whether to automatically create validations based on database constraints.
    # (Can be set false globally to disable the gem by default, and set true per-model to enable.)
    config.auto_create = true
    
    # Restricts the set of field names to include in automatic validation.
    # Value is a single name, an array of names, or nil.
    config.only = nil

    # Restricts the set of validation types to include in automatic validation.
    # Value is a single type, an array of types, or nil.
    # A type is specified as, e.g., `:validates_presence_of` or simply `:presence`.
    config.only_type = nil
    
    # A list of field names to exclude from automatic validation.
    # Value is a single name, an array of names, or nil.
    # (Providing a value per-model will completely replace a globally-configured list)
    config.except = nil
    
    # A list of validation types to exclude from automatic validation.
    # Value is a single type, an array of types, or nil.
    # (Providing a value per-model will completely replace a globally-configured list)
    config.except_type = nil
       
    # The base set of field names to always exclude from automatic validation.
    # Value is a single name, an array of names, or nil.
    # (This whitelist applies after all other considerations, global or per-model)
    config.whitelist = [:created_at, :updated_at, :created_on, :updated_on]
       
    # The base set of validation types to always exclude from automatic validation.
    # Value is a single type, an array of types, or nil.
    # (This whitelist applies after all other considerations, global or per-model)
    config.whitelist_type = nil
end
```    

### Per-model validation

You can override the global configuration per-model, using the `schema_validations` class method.  All global configuration options are available as keyword options.  For example:

##### Disable per model:
```ruby
class User < ActiveRecord::Base
    schema_validations auto_create: false
end
```

##### Use a custom validation rather than schema_validations automatic default:
```ruby
class User < ActiveRecord::Base
    schema_validations except: :email  # don't create default validation for email
    validates :email, presence: true, length: { in: 5..30 }
end
```

##### Include validations every field, without a whitelist:

```ruby
class User < ActiveRecord::Base
    schema_validations whitelist: nil
end
```



## How do I know what it did?
If you're curious (or dubious) about what validations SchemaValidations
defines, you can check the log file.  For every assocation that
SchemaValidations defines, it generates a debug entry in the log such as

```
[schema_validations] Article.validates_length_of :title, :allow_nil=>true, :maximum=>50
```

which shows the exact validation definition call.


SchemaValidations defines the validations lazily for each class, only creating
them when they are needed (in order to validate a record of the class, or in response
to introspection on the class).  So you may need to search through the log
file for "schema_validations" to find all the validations, and some classes'
validations may not be defined at all if they were never needed for the logged
use case.

## Compatibility

As of version 1.2.0, SchemaValidations supports and is tested on:

<!-- SCHEMA_DEV: MATRIX - begin -->
<!-- These lines are auto-generated by schema_dev based on schema_dev.yml -->
* ruby **2.3.1** with activerecord **4.2**, using **mysql2**, **postgresql** or **sqlite3**
* ruby **2.3.1** with activerecord **5.0**, using **mysql2**, **postgresql** or **sqlite3**

<!-- SCHEMA_DEV: MATRIX - end -->

Earlier versions of SchemaValidations supported:

*   rails 3.2, 4.1, and 4.2.0
*   MRI ruby 1.9.3 and 2.1.5


## Release Notes

### 2.2.1

* Bug fix: don't create presence validation for `null: false` with a
  default defined (#18, #49)

### 2.2.0

* Works with AR 5.0.  Thanks to [@plicjo](https://github.coms/plicjo).
* Works with `:money` type
* Bug fix when logger is nil.  Thanks to [@gamecreature](https://github.com/gamecreature).

### 2.1.1

* Bug fix for `:decimal` when `precision` is nil (#37)

### 2.1.0

* Added `:decimal` range validation.  Thanks to [@felixbuenemann](https://github.com/felixbuenemann)

### 2.0.2

* Use schema_monkey rather than Railties

### 2.0.1

* Bug fix: Don't crash when optimistic locking is in use (#8)

### 2.0.0

This major version is backwards compatible for most uses.  Only those who specified a per-model `:except` clause would be affected.

* Add whitelist configuration option (thanks to [@allenwq](https://github.com/allenwq)). Previously, overriding `:except` per-model would clobber the default values.  E.g. using the documented example `except: :mail` would accidentally cause validations to be issued `updated_at` to be validated.  Now `:except` works more naturally.  This is however technically a breaking change, hence the version bump.

### 1.4.0

* Add support for case-insensitive uniqueness.  Thanks to [allenwq](https://github.com/allenwq)

### 1.3.1

* Change log level from 'info' to 'debug', since there's no need to clutter production logs with this sort of development info.  Thanks to [@obduk](https://github.com/obduk)

### 1.3.0

* Add range checks to integer validations.  Thanks to [@lowjoel](https://github.com/lowjoel)

### 1.2.0

* No longer pull in schema_plus's auto-foreign key behavior. Limited to AR >= 4.2.1

### 1.1.0

* Works with Rails 4.2.

### 1.0.1

* Fix enums in Rails 4.1.  Thanks to [@lowjoel](https://github.com/lowjoel)

### 1.0.0

* Works with Rails 4.0.  Thanks to [@davll](https://github.com/davll)
* No longer support Rails < 3.2 or Ruby < 1.9.3

### 0.2.2

* Rails 2.3 compatibility (check for Rails::Railties symbol).  thanks to https://github.com/thehappycoder

### 0.2.0

* New feature: ActiveRecord#validators and ActiveRecord#validators_on now ensure schema_validations are loaded

## History

*   SchemaValidations is derived from the "Red Hill On Rails" plugin
    schema_validations originally created by harukizaemon
    (https://github.com/harukizaemon)

*   SchemaValidations was created in 2011 by Michał Łomnicki and Ronen Barzel


## Testing

Are you interested in contributing to schema_validations?  Thanks!  Please follow
the standard protocol: fork, feature branch, develop, push, and issue pull request.

Some things to know about to help you develop and test:

<!-- SCHEMA_DEV: TEMPLATE USES SCHEMA_DEV - begin -->
<!-- These lines are auto-inserted from a schema_dev template -->
* **schema_dev**:  SchemaValidations uses [schema_dev](https://github.com/SchemaPlus/schema_dev) to
  facilitate running rspec tests on the matrix of ruby, activerecord, and database
  versions that the gem supports, both locally and on
  [travis-ci](http://travis-ci.org/SchemaPlus/schema_validations)

  To to run rspec locally on the full matrix, do:

        $ schema_dev bundle install
        $ schema_dev rspec

  You can also run on just one configuration at a time;  For info, see `schema_dev --help` or the [schema_dev](https://github.com/SchemaPlus/schema_dev) README.

  The matrix of configurations is specified in `schema_dev.yml` in
  the project root.


<!-- SCHEMA_DEV: TEMPLATE USES SCHEMA_DEV - end -->

Code coverage results will be in coverage/index.html -- it should be at 100% coverage.

## License

This gem is released under the MIT license.

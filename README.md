# Clearly Query

A library for constructing an sql query from a hash.

From a hash, validate, construct, and execute a query or create Arel conditions.
There are no assumptions or opinions on what is done with the results from the query.

Uses [Arel](https://github.com/rails/arel) and [ActiveRecord](https://github.com/rails/rails/tree/master/activerecord).

## Project Status

[![Build Status](https://travis-ci.org/cofiem/clearly-query.svg?branch=master)](https://travis-ci.org/cofiem/clearly-query)
[![Dependency Status](https://gemnasium.com/cofiem/clearly-query.svg)](https://gemnasium.com/cofiem/clearly-query)
[![Code Climate](https://codeclimate.com/github/cofiem/clearly-query/badges/gpa.svg)](https://codeclimate.com/github/cofiem/clearly-query)
[![Test Coverage](https://codeclimate.com/github/cofiem/clearly-query/badges/coverage.svg)](https://codeclimate.com/github/cofiem/clearly-query/coverage)
[![Documentation Status](https://inch-ci.org/github/cofiem/clearly-query.svg?branch=master)](https://inch-ci.org/github/cofiem/clearly-query)
[![Documentation](https://img.shields.io/badge/docs-rdoc.info-blue.svg)](http://www.rubydoc.info/github/cofiem/clearly-query)
[![Join the chat at https://gitter.im/cofiem/clearly-query](https://badges.gitter.im/Join%20Chat.svg)](https://gitter.im/cofiem/clearly-query?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)
[![Gem Version](https://badge.fury.io/rb/clearly-query.svg)](https://badge.fury.io/rb/clearly-query)


Compatible with ActiveRecord 4.2 and 5, and Arel 6 & 7.

## Installation

Add this line to your application's Gemfile:

    gem 'clearly-query'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install clearly-query

## Usage

There are two main public classes in this gem. 
The Definition class makes use of settings declared in a model.
The Composer converts a hash of options into an Arel query.

### [Clearly::Query::Definition](./lib/clearly/query/definition.rb)

Contains the query specification for ActiveRecord models.

For example:

    Clearly::Query::Definition.new(Customer, Customer.clearly_query_def)

and

    # model/customer.rb
        def self.clearly_query_def
        {
            fields: {
                valid: [:name, :last_contact_at],
                text: [:name],
                mappings: [ # these mappings are built in the database, and are only used for comparison, not projection
                    {
                        name: :title,
                        value: Clearly::Query::Helper.string_concat(
                            Customer.arel_table[:name],
                            Clearly::Query::Helper.sql_quoted(' title'))
                    }
                ]
            },
            associations: [
                {
                    join: Order,
                    on: Order.arel_table[:customer_id].eq(Customer.arel_table[:id]),
                    available: true,
                    associations: []
                }
            ]
        }
      end

The available specification keys are detailed below.

All field names that are available to include in a query hash:

    {fields: { valid: [<Symbols>, ...] } }

All fields that contain text (e.g. `varchar`, `text`) that are available to include in a query hash. 
This must be a subset (or equal) to the `valid` field array:

    {fields: { text:  [<Symbols>, ...] } }

Field mappings that specify a calculated value:

    {fields: { mappings: [{ name: <Symbol>, value: <Arel::Nodes::Node, String, Arel::Attribute, others...> }, ... ]  } }

Associations between tables, and whether the association is available in queries or not:

    {
        associations: [
            { 
                join: <Model or Arel Table>,
                on: <Arel fragment>,
                available: <true or false>, # is this association available to be used in queries?
                associations: [ <further associations for this table>,  ... ]
            }
    }

### [Clearly::Query::Composer](./lib/clearly/query/composer.rb)

Use the Composer to Construct an Arel query from a hash of options.
See the [query hash specification](SPEC.md) for a comprehensive overview.

There are two ways to do this. Either compose an ActiveRecord query or compose the Arel conditions.

    composer = Clearly::Query::Composer.from_active_record
    query_hash = {and: {name: {contains: 'test'}}} # from e.g. HTTP request
    model = Customer
    arel_conditions = composer.conditions(model, query_hash)
    # or
    query = composer.query(model, query_hash)

### Building custom Arel queries

There is also a class to aid in building Arel queries yourself.

Have a look at the [Clearly::Query::Compose::Custom](./lib/clearly/query/compose/custom.rb) class and the
[tests](./spec/lib/clearly/query/compose/custom_spec.rb)
for more details.

## Helper methods and classes

There are a number of helper methods and classes available to make working with Arel, hashes, and ActiveRecord easier.

[Clearly::Query::Cleaner](./lib/clearly/query/cleaner.rb) validates a hash to make sure all hash keys are symbols (even in nested hashes and arrays):
 
    cleaned_query_hash = Clearly::Query::Cleaner.new.do(hash)

This library uses the custom error `Clearly::Query::QueryArgumentError` (it inherits from `ArgumentError`).

There are a bunch of validation methods in the `Clearly::Query::Validate` module. Sometimes duck typing is not that great :/

There is also the `Clearly::Query::Graph` class, currently used only for constructing root to leaf routes for building joins.

Class methods in the `Clearly::Query::Helper` class provide abstractions over differences in database string concatenation,
help construct Arel infix operators, EXISTS clauses, literals, and SQL fragments. 
These helper methods are mostly a result of obscure or odd functionality. 
It's a collection of Arel experience that will probably be helpful.

## More Information about Arel

 - [Using Arel to Compose SQL Queries](http://robots.thoughtbot.com/using-arel-to-compose-sql-queries)
 - [The definitive guide to Arel, the SQL manager for Ruby](http://jpospisil.com/2014/06/16/the-definitive-guide-to-arel-the-sql-manager-for-ruby.html)

## Contributing

1. [Fork this repo](https://github.com/cofiem/clearly-query/fork)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new [pull request](https://github.com/cofiem/clearly-query/compare)
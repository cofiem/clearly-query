# Clearly Query

A library for constructing an sql query from a hash.

Uses [Arel](https://github.com/rails/arel) and [ActiveRecord](https://github.com/rails/rails/tree/master/activerecord).

[![Dependency Status](https://gemnasium.com/cofiem/clearly-query.svg)](https://gemnasium.com/cofiem/clearly-query)
[![Code Climate](https://codeclimate.com/github/cofiem/clearly-query/badges/gpa.svg)](https://codeclimate.com/github/cofiem/clearly-query)
[![Test Coverage](https://codeclimate.com/github/cofiem/clearly-query/badges/coverage.svg)](https://codeclimate.com/github/cofiem/clearly-query/coverage)
[![Documentation Status](https://inch-ci.org/github/cofiem/clearly-query.svg?branch=master)](https://inch-ci.org/github/cofiem/clearly-query)

## Installation

Add this line to your application's Gemfile:

    gem 'clearly-query'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install clearly-query

## Usage

There are two main public classes in this gem. 
The Definition class makes use of a settings declared in a model.
The Composer converts a hash of options into an Arel query.

### [ClearlyQuery::Definition](lib/clearly-query/definition.rb)

Contains the query specification for ActiveRecord models.

For example:

    ClearlyQuery::Definition.new(Customer, Customer.clearly_query_def)

and

    # model/customer.rb
      def self.clearly_query_def
        {
            fields: {
                valid: [:name, :last_contact_at],
                text: [:name],
                mappings: []
            },
            associations: [
                {
                    join: Order,
                    on: Order.arel_table[:customer_id].eq(Customer.arel_table[:id]),
                    available: true,
                    associations: []
                }
            ],
            defaults: {
                order_by: :created_at,
                direction: :desc
            }
        }
      end

### [ClearlyQuery::Composer](lib/clearly-query/composer.rb)

Used to construct an Arel query from a hash of options.

For example:

    composer = ClearlyQuery::Composer.from_active_record
    composer.query(Customer, {name: {contains: 'test'}})

## Contributing

1. [Fork this repo](https://github.com/cofiem/clearly-query/fork)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new [pull request](https://github.com/cofiem/clearly-query/compare)

## More Information about Arel

 - [Using Arel to Compose SQL Queries](http://robots.thoughtbot.com/using-arel-to-compose-sql-queries)
 - [The definitive guide to Arel, the SQL manager for Ruby](http://jpospisil.com/2014/06/16/the-definitive-guide-to-arel-the-sql-manager-for-ruby.html)

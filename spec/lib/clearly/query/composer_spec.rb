require 'spec_helper'

describe Clearly::Query::Composer do
  include_context 'shared_setup'

  it 'can be instantiated' do
    Clearly::Query::Composer.new(all_defs)
  end

  it 'matches test setup' do
    composer_definitions = Clearly::Query::Composer.from_active_record.definitions.reject{ |d| d.model.nil? }.map { |d| d.model.name }
    test_definitions = all_defs.map { |d| d.model.name }
    expect(test_definitions).to eq(composer_definitions)
  end

  it 'finds all active record models' do
    definitions = Clearly::Query::Composer.from_active_record.definitions.reject{ |d| d.model.nil? }.map { |d| d.model.name }
    expect([Customer.name, Order.name, Part.name, Product.name]).to eq(definitions)
  end

  it 'finds all habtm tables' do
    definitions = Clearly::Query::Composer.from_active_record.definitions.reject{ |d| !d.model.nil? }.map { |d| d.table.name }
    expect(definitions).to eq(['orders_products', 'parts_products'])
  end

  context 'test query' do
    context 'fails when it' do
      it 'is given an empty query' do
        query = cleaner.do({})
        expect {
          composer.query(Customer, query)
        }.to raise_error(Clearly::Query::QueryArgumentError, "filter hash must have at least 1 entry, got '0'")
      end

      it 'uses a regex operator using sqlite' do
        expect {
          conditions = composer.query(Product, {name: {regex: 'test'}})
          query = Product.all
          conditions.each { |c| query = query.where(c) }
          expect(query.to_a).to eq([])
        }.to raise_error(NotImplementedError, "~ not implemented for this db")
      end

      # TODO
      # fail FilterArgumentError.new("'Not' must have a single combiner or field name, got #{filter_hash.size}", {hash: filter_hash}) if filter_hash.size != 1
      #fail FilterArgumentError.new("'Not' must have a single filter, got #{hash.size}.", {hash: filter_hash}) if result.size != 1

        it 'contains an unrecognised filter' do
          expect {
            composer.query(Customer, {
                        or: {
                            name: {
                                not_a_real_filter: 'Hello'
                            }
                        }
                    })
          }.to raise_error(Clearly::Query::QueryArgumentError, "unrecognised operator 'not_a_real_filter'")
        end

        it 'has only 1 entry' do
          expect {
            composer.query(Customer, {
                        or: {
                            name: {
                                contains: 'Hello'
                            }
                        }
                    })
          }.to raise_error(Clearly::Query::QueryArgumentError, "must have at least 2 conditions, got '1'")
        end

        it 'has not with no entries' do
          expect {
            composer.query(Customer, {
                        not: {
                        }
                    })
          }.to raise_error(Clearly::Query::QueryArgumentError, "filter hash must have at least 1 entry, got '0'")
        end

        it 'has or with no entries' do
          expect {
            composer.query(Customer, {
                        or: {
                        }
                    })
          }.to raise_error(Clearly::Query::QueryArgumentError, "filter hash must have at least 1 entry, got '0'")
        end

        it 'has not with more than one field' do
          expect {
            composer.query(Product, {
                        not: {
                            name: {
                                contains: 'Hello'
                            },
                            code: {
                                contains: 'Hello'
                            }
                        }
                    })
          }.to_not raise_error
        end

        it 'has not with more than one filter' do
          expect {
            composer.query(Product, {
                        not: {
                            name: {
                                contains: 'Hello',
                                eq: 2
                            }
                        }
                    })
          }.to_not raise_error
        end

        it 'has a combiner that is not recognised with valid filters' do
          expect {
            composer.query(Product, {
                        not_a_valid_combiner: {
                            name: {
                                contains: 'Hello'
                            },
                            code: {
                                contains: 'Hello'
                            }
                        }
                    })
          }.to raise_error(Clearly::Query::QueryArgumentError, "unrecognised logical operator 'not_a_valid_combiner'")
        end

        it "has a range missing 'from'" do
          expect {
            composer.query(Customer, {
                        and: {
                            name: {
                                range: {
                                    to: 200
                                }
                            }
                        }
                    })
          }.to raise_error(Clearly::Query::QueryArgumentError, "range filter missing 'from'")
        end

        it "has a range missing 'to'" do
          expect {
            composer.query(Product, {
                        and: {
                            code: {
                                range: {
                                    from: 200
                                }
                            }
                        }
                    })
          }.to raise_error(Clearly::Query::QueryArgumentError, "range filter missing 'to'")
        end

        it 'has a range with from/to and interval' do
          expect {
            composer.query(Customer, {
                        and: {
                            name: {
                                range: {
                                    from: 200,
                                    to: 200,
                                    interval: '[1,2]'
                                }
                            }}
                    })
          }.to raise_error(Clearly::Query::QueryArgumentError, "range filter must use either ('from' and 'to') or ('interval'), not both")
        end

        it 'has a range with no recognised properties' do
          expect {
            composer.query(Customer, {
                        and: {
                            name: {
                                range: {
                                    ignored_in_a_range: '[34,34]'
                                }
                            }
                        }
                    })
          }.to raise_error(Clearly::Query::QueryArgumentError, "range filter did not contain ('from' and 'to') or ('interval'), got '{:ignored_in_a_range=>\"[34,34]\"}'")
        end

        it 'has a property that has no filters' do
          expect {
            composer.query(Customer, {
                        or: {
                            name: {
                            }
                        }
                    })
          }.to raise_error(Clearly::Query::QueryArgumentError, "filter hash must have at least 1 entry, got '0'")
        end

        it "occurs with a deformed 'in' filter" do
          filter_params = {'name' => {'in' => [
              {'blah1' => nil, 'blah2' => nil, 'blah3' => nil, 'id' => 508, 'blah4' => true, 'name' => 'blah blah',
               'blah5' => [397], 'links' => ['blah']},
              {'blah1' => nil, 'blah2' => nil, 'blah3' => nil, 'id' => 400, 'blah4' => true, 'name' => 'blah blah',
               'blah5' => [397], 'links' => ['blah']}
          ]}}

          expect {
            query = cleaner.do(filter_params)
            composer.query(Customer, query)
          }.to raise_error(Clearly::Query::QueryArgumentError, 'array values cannot be hashes')
        end

        it 'occurs for an invalid range filter' do
          filter_params = {"name" => {"inRange" => "(5,6)"}}
          expect {
            query = cleaner.do(filter_params)
            composer.query(Customer, query)
          }.to raise_error(Clearly::Query::QueryArgumentError, "range filter must be {'from': 'value', 'to': 'value'} or {'interval': '(|[.*,.*]|)'} got '(5,6)'")
        end


    end
    context 'succeeds when it' do
      it 'is given a valid query without combiners' do
        hash = cleaner.do({name: {contains: 'test'}})
        conditions = composer.query(Customer, hash)
        expect(conditions.size).to eq(1)

        # sqlite only supports LIKE
        expect(conditions.first.to_sql).to eq("\"customers\".\"name\" LIKE '%test%'")

        query = Customer.all
        conditions.each { |c| query = query.where(c) }
        expect(query.to_a).to eq([])
      end

      it 'is given a valid query with or combiner' do
        hash = cleaner.do({or: {name: {contains: 'test'}, code: {eq: 4}}})
        conditions = composer.query(Product, hash)
        expect(conditions.size).to eq(1)

        expect(conditions.first.to_sql).to eq("(\"products\".\"name\" LIKE '%test%' OR \"products\".\"code\" = '4')")

        query = Product.all
        conditions.each { |c| query = query.where(c) }
        expect(query.to_a).to eq([])
      end

      it 'is given a valid query with camel cased keys' do
        hash = cleaner.do({name: {does_not_start_with: 'test'}})
        conditions = composer.query(Customer, hash)
        expect(conditions.size).to eq(1)

        expect(conditions.first.to_sql).to eq("\"customers\".\"name\" NOT LIKE 'test%'")

        query = Customer.all
        conditions.each { |c| query = query.where(c) }
        expect(query.to_a).to eq([])
      end

      it 'is given a valid range query that excludes the start and includes the end' do
        hash = cleaner.do({name: {notInRange: {interval: '(2,5]'}}})
        conditions = composer.query(Customer, hash)
        expect(conditions.size).to eq(1)
        
        expect(conditions.first.to_sql).to eq("(\"customers\".\"name\" <= '2' OR \"customers\".\"name\" > '5')")

        query = Customer.all
        conditions.each { |c| query = query.where(c) }
        expect(query.to_a).to eq([])
      end

      it 'is given a valid query that uses a table one step away' do
        hash = cleaner.do({and: {name: {contains: 'test'}, 'orders.shipped_at' => {lt: '2015-10-24'}}})
        conditions = composer.query(Customer, hash)
        expect(conditions.size).to eq(1)

        expected = "\"customers\".\"name\" LIKE '%test%' AND EXISTS (SELECT 1 FROM \"orders\" WHERE \"orders\".\"shipped_at\" < '2015-10-24' AND \"orders\".\"customer_id\" = \"customers\".\"id\")"
        expect(conditions.first.to_sql).to eq(expected)

        query = Customer.all
        conditions.each { |c| query = query.where(c) }
        expect(query.to_a).to eq([])
      end

      it 'is given a valid query that uses a table two steps away' do
        # TODO: requires rewriting Composer#parse_filter to use definitions for table.field field names
        # instead of the hash in Definition#parse_table_field

        hash = cleaner.do({and: {name: {contains: 'test'}, 'orders.shipped_at' => {lt: '2015-10-24'}}})
        conditions = composer.query(Part, hash)
        expect(conditions.size).to eq(1)

        expected = "\"parts\".\"name\" LIKE '%test%' AND EXISTS (SELECT 1 FROM \"orders\" INNER JOIN \"parts_products\" ON \"products\".\"id\" = \"parts_products\".\"product_id\" INNER JOIN \"products\" ON \"products\".\"id\" = \"orders_products\".\"product_id\" INNER JOIN \"orders_products\" ON \"orders\".\"id\" = \"orders_products\".\"order_id\" WHERE \"orders\".\"shipped_at\" < '2015-10-24' AND \"orders\".\"customer_id\" = \"customers\".\"id\")"
        expect(conditions.first.to_sql).to eq(expected)

        query = Part.all
        conditions.each { |c| query = query.where(c) }
        expect(query.to_a).to eq([])
      end

      it 'is given a valid query that uses a custom field mapping' do
        hash = cleaner.do({and: {shipped_at: {lt: '2015-10-24'}, title: {does_not_start_with: 'alice'}}})
        conditions = composer.query(Order, hash)
        expect(conditions.size).to eq(1)

        expected = "\"orders\".\"shipped_at\" < '2015-10-24' AND (SELECT \"customers\".\"name\" FROM \"customers\" WHERE \"customers\".\"id\" = \"orders\".\"customer_id\") || ' (' || CASE WHEN \"orders\".\"shipped_at\" IS NULL THEN 'not shipped' ELSE \"orders\".\"shipped_at\" END || ')' NOT LIKE 'alice%'"
        expect(conditions.first.to_sql).to eq(expected)

        query = Order.all
        conditions.each { |c| query = query.where(c) }
        expect(query.to_a).to eq([])
      end

      it 'is given a valid query that uses all possible comparisons' do

        operator_value = 'test'
        column = '"products"."name"'

        not_implemented_sqlite = Clearly::Query::Compose::Conditions::OPERATORS_REGEX
        skip_in_test = []
        operator_hash = {}
        Clearly::Query::Compose::Conditions::OPERATORS
            .reject { |o| not_implemented_sqlite.include?(o) }
            .reject { |o| skip_in_test.include?(o) }
            .each do |o|
          op_value_mod = "#{operator_value}_#{o.to_s}"
          operator_value1 = "#{op_value_mod}_1"
          operator_value2 = "#{op_value_mod}_2"
          operator_hash[o] =
              case o
                when :range, :not_range, :not_in_range
                  {from: operator_value1, to: operator_value2}
                when :in_range
                  {interval: "(#{operator_value1},#{operator_value2}]"}
                when :in, :not_in, :is_in, :in_not_in
                  [op_value_mod]
                when :null
                  true
                when :is_null
                  false
                else
                  op_value_mod
              end
        end

        hash = cleaner.do({and: {name: operator_hash}})
        conditions = composer.query(Product, hash)
        expect(conditions.size).to eq(1)

        expected = {
            eq: "#{column} = '#{operator_value}'",
            equal: "#{column} = '#{operator_value}'",
            not_eq: "#{column} != '#{operator_value}'",
            not_equal: "#{column} != '#{operator_value}'",
            lt: "#{column} < '#{operator_value}'",
            less_than: "#{column} < '#{operator_value}'",
            not_lt: "#{column} >= '#{operator_value}'",
            not_less_than: "#{column} >= '#{operator_value}'",
            gt: "#{column} > '#{operator_value}'",
            greater_than: "#{column} > '#{operator_value}'",
            not_gt: "#{column} <= '#{operator_value}'",
            not_greater_than: "#{column} <= '#{operator_value}'",
            lteq: "#{column} <= '#{operator_value}'",
            less_than_or_equal: "#{column} <= '#{operator_value}'",
            not_lteq: "#{column} > '#{operator_value}'",
            not_less_than_or_equal: "#{column} > '#{operator_value}'",
            gteq: "#{column} >= '#{operator_value}'",
            grester_than_or_equal: "#{column} >= '#{operator_value}'",
            not_gteq: "#{column} < '#{operator_value}'",
            not_greater_than_or_equal: "#{column} < '#{operator_value}'",

            range: "#{column} >= '#{operator_value}1' AND #{column} < '#{operator_value}2'",
            in_range: "#{column} > '#{operator_value}1' AND #{column} <= '#{operator_value}2'",
            not_range: "(#{column} < '#{operator_value}1' OR #{column} >= '#{operator_value}2')",
            not_in_range: "(#{column} < '#{operator_value}1' OR #{column} >= '#{operator_value}2')",
            in: "#{column} IN ('#{operator_value}')",
            not_in: "#{column} NOT IN ('#{operator_value}')",
            contains: "#{column} LIKE '%#{operator_value}%'",
            contain: "#{column} LIKE '%#{operator_value}%'",
            not_contains: "#{column} NOT LIKE '%#{operator_value}%'",
            not_contain: "#{column} NOT LIKE '%#{operator_value}%'",
            does_not_contain: "#{column} NOT LIKE '%#{operator_value}%'",
            starts_with: "#{column} LIKE '#{operator_value}%'",
            start_with: "#{column} LIKE '#{operator_value}%'",
            not_starts_with: "#{column} NOT LIKE '#{operator_value}%'",
            not_start_with: "#{column} NOT LIKE '#{operator_value}%'",
            does_not_start_with: "#{column} NOT LIKE '#{operator_value}%'",
            ends_with: "#{column} LIKE '%#{operator_value}'",
            end_with: "#{column} LIKE '%#{operator_value}'",
            not_ends_with: "#{column} NOT LIKE '%#{operator_value}'",
            not_end_with: "#{column} NOT LIKE '%#{operator_value}'",
            does_not_end_with: "#{column} NOT LIKE '%#{operator_value}'",

            null: "#{column} IS NULL",
            is_null: "#{column} IS NOT NULL"
        }

        expect(conditions.first.to_sql).to eq(expected.values.join(' AND '))

        query = Product.all
        conditions.each { |c| query = query.where(c) }
        expect(query.to_a).to eq([])
      end
    end

  end


end

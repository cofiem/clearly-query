require 'spec_helper'

describe ClearlyQuery::Composer do
  include_context 'shared_setup'

  it 'can be instantiated' do
    ClearlyQuery::Composer.new(all_defs)
  end

  it 'matches test setup' do
    composer_definitions = ClearlyQuery::Composer.from_active_record.definitions.map { |d| d.model.name }
    test_definitions = all_defs.map { |d| d.model.name }
    expect(test_definitions).to eq(composer_definitions)
  end

  it 'finds all active record classes' do
    definitions = ClearlyQuery::Composer.from_active_record.definitions.map { |d| d.model.name }
    expect([Customer.name, Order.name, Part.name, Product.name]).to eq(definitions)
  end


  context 'test query' do
    context 'fails when it' do
      it 'is given an empty query' do
        query = cleaner.do({})
        expect {
          composer.query(Customer, query)
        }.to raise_error(ClearlyQuery::FilterArgumentError, "filter hash must have at least 1 entry, got '0'")
      end
    end
    context 'succeeds when it' do
      it 'is given a valid simple query' do
        hash = cleaner.do({name: {contains: 'test'}})
        conditions = composer.query(Customer, hash)
        expect(conditions.size).to eq(1)

        # sqlite only supports LIKE
        expect(conditions.first.to_sql).to eq("\"customers\".\"name\" LIKE '%test%'")

        query = Customer.all
        conditions.each { |c| query = query.where(c) }
        expect(query.to_a).to eq([])
      end

      it 'is given a valid query that uses another table' do
        hash = cleaner.do({and: {name: {contains: 'test'}, 'orders.shipped_at' => {lt: '2015-10-24'}}})
        conditions = composer.query(Customer, hash)
        expect(conditions.size).to eq(1)

        expected = "\"customers\".\"name\" LIKE '%test%' AND \"orders\".\"id\" IN (SELECT \"orders\".\"id\" FROM \"orders\" LEFT OUTER JOIN \"orders\" ON \"orders\".\"customer_id\" = \"customers\".\"id\" WHERE \"orders\".\"shipped_at\" < '2015-10-24')"
        expect(conditions.first.to_sql).to eq(expected)

        query = Customer.all
        conditions.each { |c| query = query.where(c) }
        expect(query.to_a).to eq([])
      end

      it 'is given a valid query that uses a custom field mapping' do
        hash = cleaner.do({and: {shipped_at: {lt: '2015-10-24'}, title: {does_not_start_with: 'alice'}}})
        conditions = composer.query(Order, hash)
        expect(conditions.size).to eq(1)

        expected = "\"customers\".\"name\" LIKE '%test%' AND \"orders\".\"id\" IN (SELECT \"orders\".\"id\" FROM \"orders\" WHERE \"orders\".\"shipped_at\" < '2015-10-24')"
        expect(conditions.first.to_sql).to eq(expected)

        query = Order.all
        conditions.each { |c| query = query.where(c) }
        expect(query.to_a).to eq([])
      end

      it 'is given a valid query that uses all possible comparisons' do
        hash = cleaner.do({and: {}})
        conditions = composer.query(Product, hash)
        expect(conditions.size).to eq(1)

        expected = ""
        expect(conditions.first.to_sql).to eq(expected)

        query = Customer.all
        conditions.each { |c| query = query.where(c) }
        expect(query.to_a).to eq([])
      end
    end

  end


end

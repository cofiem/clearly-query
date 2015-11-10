require 'spec_helper'

describe Clearly::Query::Composer do
  include_context 'shared_setup'
  let(:product_attributes) {
    {
        name: 'plastic cup',
        code: '000475PC',
        brand: 'Generic',
        introduced_at: '2015-01-01 00:00:00',
        discontinued_at: nil
    }
  }

  let(:customer_attributes) {
    {
        name: 'first last',
        last_contact_at: '2015-11-09 10:00:00'
    }
  }

  let(:order_attributes) {
    {

    }
  }

  it 'finds the only product' do
    product = Product.create!(product_attributes)
    query_hash = cleaner.do({name: {contains: 'cup'}})
    query_ar = composer.query(Product, query_hash)

    expect(query_ar.count).to eq(1)

    result_item = query_ar.to_a[0]
    expect(result_item.name).to eq(product_attributes[:name])
    expect(result_item.code).to eq(product_attributes[:code])
    expect(result_item.brand).to eq(product_attributes[:brand])
    expect(result_item.introduced_at).to eq(product_attributes[:introduced_at])
    expect(result_item.discontinued_at).to eq(product_attributes[:discontinued_at])
  end

  it 'finds the matching product' do
    (1..10).each do |i|
      attrs = product_attributes.dup
      attrs[:name] = attrs[:name] + i.to_s
      attrs[:code] = attrs[:code] + i.to_s
      Product.create!(attrs)
    end

    query_hash = cleaner.do({name: {contains: '5'}})
    query_ar = composer.query(Product, query_hash)

    expect(query_ar.count).to eq(1)

    result_item = query_ar.to_a[0]
    expect(result_item.name).to eq(product_attributes[:name] + '5')
    expect(result_item.code).to eq(product_attributes[:code] + '5')
    expect(result_item.brand).to eq(product_attributes[:brand])
    expect(result_item.introduced_at).to eq(product_attributes[:introduced_at])
    expect(result_item.discontinued_at).to eq(product_attributes[:discontinued_at])
  end

  it 'finds the matching order using mapped field' do
    customer = Customer.create!(customer_attributes)
    order_pending = Order.create!(customer: customer)
    order_shipped = Order.create!(customer: customer, shipped_at: '2015-11-09 11:00:00')

    query_hash = cleaner.do({title: {contains: 'not shipped'}})
    query_ar = composer.query(Order, query_hash)

    expect(query_ar.count).to eq(1)

    result_item = query_ar.to_a[0]
    expect(result_item.shipped_at).to eq(order_pending.shipped_at)
    expect(result_item.customer_id).to eq(order_pending.customer_id)
  end

end

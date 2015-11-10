require 'active_record'

class Product < ActiveRecord::Base

  has_and_belongs_to_many :parts
  has_and_belongs_to_many :orders

  def self.clearly_query_def
    {
        fields: {
            valid: [:title, :name, :code, :brand, :introduced_at, :discontinued_at],
            text: [:title, :name, :code, :brand],
            mappings: [
                {
                    name: :title,
                    value: Clearly::Query::Helper.string_concat(
                        Product.arel_table[:brand],
                        Clearly::Query::Helper.sql_quoted(' '),
                        Product.arel_table[:name],
                        Clearly::Query::Helper.sql_quoted(' ('),
                        Product.arel_table[:code],
                        Clearly::Query::Helper.sql_quoted(')'))
                }
            ]
        },
        associations: [
            {
                join: Arel::Table.new(:orders_products),
                on: Order.arel_table[:id].eq(Arel::Table.new(:orders_products)[:order_id]),
                available: false,
                associations: [
                    {
                        join: Order,
                        on: Order.arel_table[:customer_id].eq(Customer.arel_table[:id]),
                        available: true,
                        associations: [
                            {
                                join: Customer,
                                on: Customer.arel_table[:id].eq(Order.arel_table[:customer_id]),
                                available: true,
                                associations: []
                            }
                        ]
                    }
                ]
            },
            {
                join: Arel::Table.new(:parts_products),
                on: Product.arel_table[:id].eq(Arel::Table.new(:parts_products)[:product_id]),
                available: false,
                associations: [
                    {
                        join: Part,
                        on: Part.arel_table[:id].eq(Arel::Table.new(:parts_products)[:part_id]),
                        available: true,
                        associations: []
                    }
                ]
            }
        ]
    }
  end
end
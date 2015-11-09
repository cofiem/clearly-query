require 'active_record'

class Order < ActiveRecord::Base

  belongs_to :customer, inverse_of: :orders
  has_and_belongs_to_many :products

  def self.clearly_query_def
    {
        fields: {
            valid: [:title, :shipped_at],
            text: [:title],
            mappings: [
                {
                    name: :title,
                    value: Clearly::Query::Helper.string_concat(
                        Customer.arel_table
                            .where(Customer.arel_table[:id].eq(Order.arel_table[:customer_id]))
                            .project(Customer.arel_table[:name]),
                        Clearly::Query::Helper.sql_quoted(' ('),
                        Clearly::Query::Helper.sql_literal('CASE WHEN "orders"."shipped_at" IS NULL THEN \'not shipped\' ELSE "orders"."shipped_at" END'),
                        Clearly::Query::Helper.sql_quoted(')'))
                }
            ]
        },
        associations: [
            {
                join: Customer,
                on: Customer.arel_table[:id].eq(Order.arel_table[:customer_id]),
                available: true
            },
            {
                join: Arel::Table.new(:orders_products),
                on: Order.arel_table[:id].eq(Arel::Table.new(:orders_products)[:order_id]),
                available: false,
                associations: [
                    {
                        join: Product,
                        on: Product.arel_table[:id].eq(Arel::Table.new(:orders_products)[:product_id]),
                        available: true,
                        associations: [
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
                ]
            }
        ],
        defaults: {
            order_by: :created_at,
            direction: :desc
        }
    }
  end
end
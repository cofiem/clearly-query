require 'active_record'

class Customer < ActiveRecord::Base

  has_many :orders, inverse_of: :customer

  def self.clearly_query_def
    {
        fields: {
            valid: [:name, :last_contact_at],
            text: [:name],
            mappings: [
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
                associations: [
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
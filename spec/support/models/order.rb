require 'active_record'

class Order < ActiveRecord::Base

  def self.filter_definition
    {
        fields: {
            valid: [:title, :shipped_at],
            text: [:title],
            mappings: [
                {
                    name: :name,
                    value: ClearlyQuery::Helper.string_concat(Order.arel_table[:name], ' (name)')
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
                                join: Arel::Table.new(:products_parts),
                                on: Product.arel_table[:id].eq(Arel::Table.new(:products_parts)[:product_id]),
                                available: false,
                                associations: [
                                    {
                                        join: Part,
                                        on: Part.arel_table[:id].eq(Arel::Table.new(:products_parts)[:part_id]),
                                        available: true,

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
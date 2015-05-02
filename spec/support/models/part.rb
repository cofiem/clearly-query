require 'active_record'

class Part < ActiveRecord::Base

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
                join: Arel::Table.new(:products_parts),
                on: Product.arel_table[:id].eq(Arel::Table.new(:products_parts)[:product_id]),
                available: false,
                associations: [
                    {
                        join: Product,
                        on: Product.arel_table[:id].eq(Arel::Table.new(:orders_products)[:product_id]),
                        available: true,
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
            order_by: :name,
            direction: :asc
        }
    }
  end
end
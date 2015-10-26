require 'active_record'

class Part < ActiveRecord::Base

  has_and_belongs_to_many :products

  def self.clearly_query_def
    {
        fields: {
            valid: [:title, :name, :code, :manufacturer],
            text: [:title, :name, :code, :manufacturer],
            mappings: [
                {
                    name: :title,
                    value: Clearly::Query::Helper.string_concat(
                        Part.arel_table[:code],
                        Arel::Nodes.build_quoted(' '),
                        Part.arel_table[:manufacturer])
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
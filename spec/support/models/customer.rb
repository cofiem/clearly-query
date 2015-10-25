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
                    value: ClearlyQuery::Helper.string_concat(
                        Customer.arel_table[:name],
                        Arel::Nodes.build_quoted(' title'))
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
                                        join: Arel::Table.new(:products_parts),
                                        on: Product.arel_table[:id].eq(Arel::Table.new(:products_parts)[:product_id]),
                                        available: false,
                                        associations: [
                                            {
                                                join: Part,
                                                on: Part.arel_table[:id].eq(Arel::Table.new(:products_parts)[:part_id]),
                                                available: true
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
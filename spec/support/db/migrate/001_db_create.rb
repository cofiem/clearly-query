class DbCreate < ActiveRecord::Migration
  def change
    create_table :customers do |t|
      t.string        :name,            null: false
      t.datetime      :last_contact_at, null: false
      t.timestamps null: false
    end

    create_table :orders do |t|
      t.datetime      :shipped_at,  null: true
      t.integer       :customer_id, null: false
      t.timestamps null: false
    end

    add_foreign_key :orders, :customers

    create_table :products do |t|
      t.string        :name,            null: false
      t.string        :code,            null: false
      t.string        :brand,           null: false
      t.datetime      :introduced_at,   null: false
      t.datetime      :discontinued_at, null: true
      t.timestamps null: false
    end

    create_table :orders_products, id: false do |t|
      t.integer :order_id, null: false
      t.integer :product_id, null: false
      t.timestamps null: false
    end

    add_foreign_key :orders_products, :customers
    add_foreign_key :orders_products, :orders

    create_table :parts do |t|
      t.string        :name,            null: false
      t.string        :code,            null: false
      t.string        :manufacturer,    null: false
      t.timestamps null: false
    end

    create_table :parts_products, id: false do |t|
      t.integer :product_id, null: false
      t.integer :part_id,    null: false
      t.timestamps null: false
    end

    add_foreign_key :parts_products, :products
    add_foreign_key :parts_products, :parts

    add_index :customers, :name, unique: true

    add_index :products, :name, unique: true
    add_index :products, :code, unique: true

    add_index :parts, :name, unique: true
    add_index :parts, :code, unique: true

    add_index :parts_products, [:product_id, :part_id], unique: true

  end
end

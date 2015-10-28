RSpec.shared_context 'shared_setup' do

  let(:customer_def) { Clearly::Query::Definition.new({model: Customer, hash: Customer.clearly_query_def}) }
  let(:order_def) { Clearly::Query::Definition.new({model: Order, hash: Order.clearly_query_def}) }
  let(:part_def) { Clearly::Query::Definition.new({model: Part, hash: Part.clearly_query_def}) }
  let(:product_def) { Clearly::Query::Definition.new({model: Product, hash: Product.clearly_query_def}) }
  let(:all_defs) { [customer_def, order_def, part_def, product_def] }

  let(:composer) { Clearly::Query::Composer.from_active_record }

  let(:cleaner) { Clearly::Query::Cleaner.new }

end
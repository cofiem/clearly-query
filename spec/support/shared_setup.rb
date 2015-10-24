RSpec.shared_context 'shared_setup' do

  let(:customer_def) { ClearlyQuery::Definition.new(Customer, Customer.clearly_query_def)}
  let(:order_def) { ClearlyQuery::Definition.new(Order, Order.clearly_query_def)}
  let(:part_def) { ClearlyQuery::Definition.new(Part, Part.clearly_query_def)}
  let(:product_def) {ClearlyQuery::Definition.new(Product, Product.clearly_query_def)}
  let(:all_defs) {[customer_def, order_def, part_def, product_def]}

  let(:composer) { ClearlyQuery::Composer.from_active_record }

  let(:cleaner) { ClearlyQuery::Cleaner.new }

end
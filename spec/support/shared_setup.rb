RSpec.shared_context 'shared_setup' do
  let(:customer_def) { ClearlyQuery::Definition.new(Customer, Customer.filter_definition)}
  let(:order_def) { ClearlyQuery::Definition.new(Order, Order.filter_definition)}
  let(:part_def) { ClearlyQuery::Definition.new(Part, Part.filter_definition)}
  let(:product_def) {ClearlyQuery::Definition.new(Product, Product.filter_definition)}
  let(:all_defs) {[customer_def, order_def, product_def, part_def]}
end
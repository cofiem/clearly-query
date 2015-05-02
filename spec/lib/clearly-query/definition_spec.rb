require 'spec_helper'

describe ClearlyQuery::Definition do
  include_context 'shared_setup'

  it 'can be instantiated' do
    ClearlyQuery::Definition.new(Customer, Customer.filter_definition)
  end
end
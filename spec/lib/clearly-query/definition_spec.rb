require 'spec_helper'

describe ClearlyQuery::Definition do
  it 'can be instantiated' do
    ClearlyQuery::Definition.new(Customer.new, {})
  end
end
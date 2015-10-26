require 'spec_helper'

describe Clearly::Query::Definition do
  include_context 'shared_setup'

  it 'is not valid with nil model' do
    expect {
      Clearly::Query::Definition.new(nil, Customer.clearly_query_def)
    }.to raise_error(Clearly::Query::FilterArgumentError, "value must not be empty, got ''")
  end

  it 'is not valid with nil hash' do
    expect {
      Clearly::Query::Definition.new(Customer, nil)
    }.to raise_error(Clearly::Query::FilterArgumentError, "value must not be empty, got ''")
  end

  it 'can be instantiated' do
    Clearly::Query::Definition.new(Customer, Customer.clearly_query_def)
  end


end
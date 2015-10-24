require 'spec_helper'

describe ClearlyQuery::Definition do
  include_context 'shared_setup'

  it 'is not valid with nil model' do
    expect {
      ClearlyQuery::Definition.new(nil, Customer.clearly_query_def)
    }.to raise_error(ClearlyQuery::FilterArgumentError, "value must not be empty, got ''")
  end

  it 'is not valid with nil hash' do
    expect {
      ClearlyQuery::Definition.new(Customer, nil)
    }.to raise_error(ClearlyQuery::FilterArgumentError, "value must not be empty, got ''")
  end

  it 'can be instantiated' do
    ClearlyQuery::Definition.new(Customer, Customer.clearly_query_def)
  end



end
require 'spec_helper'

describe Clearly::Query::Helper do
  include_context 'shared_setup'

  it 'raises error with one argument for infix operator' do
    expect {
      Clearly::Query::Helper.string_concat_infix('+', 'test')
    }.to raise_error(ArgumentError,"string concatenation requires operator and two or more arguments, given '1'")
  end

  it 'raises error with no arguments for infix operator' do
    expect {
      Clearly::Query::Helper.string_concat_infix('+')
    }.to raise_error(ArgumentError,"string concatenation requires operator and two or more arguments, given '0'")
  end
end

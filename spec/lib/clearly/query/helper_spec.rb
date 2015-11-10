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

  it 'builds a SQL function' do
    format_date = 'YYYY-MM-DD'
    format_date_quoted = Arel::Nodes.build_quoted(format_date)
    table = Order.arel_table
    column =:shipped_at
    alias_name = 'as_alias'

    query = Clearly::Query::Helper.named_function('to_char', [table[column], format_date_quoted], alias_name)
    expect(query.to_sql).to eq("to_char(\"orders\".\"shipped_at\", 'YYYY-MM-DD') AS as_alias")
  end

  it 'builds a SQL EXISTS condition' do
    table = Order.arel_table
    column =:shipped_at

    query = Clearly::Query::Helper.exists(table[column])
    expect(query.to_sql).to eq("EXISTS (\"orders\".\"shipped_at\")")
  end
end

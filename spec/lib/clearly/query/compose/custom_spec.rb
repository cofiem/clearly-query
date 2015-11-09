require 'spec_helper'

describe Clearly::Query::Compose::Custom do
  include_context 'shared_setup'
  include Clearly::Query::Compose::Core

  it 'can be instantiated' do
    Clearly::Query::Compose::Custom.new
  end

  it 'build expected sql' do
    custom = Clearly::Query::Compose::Custom.new

    table = product_def.table
    column_name = :name
    allowed = product_def.all_fields
    value = 'test'
    values = [value]
    value_bool = true
    value_range = {interval: '(test1,test2]'}

    combined = self.send(
        :compose_and,
        custom.compose_eq(table, column_name, allowed, value),
        custom.compose_not_eq(table, column_name, allowed, value),
        custom.compose_lt(table, column_name, allowed, value),
        custom.compose_not_lt(table, column_name, allowed, value),
        custom.compose_gt(table, column_name, allowed, value),
        custom.compose_not_gt(table, column_name, allowed, value),
        custom.compose_lteq(table, column_name, allowed, value),
        custom.compose_not_lteq(table, column_name, allowed, value),
        custom.compose_gteq(table, column_name, allowed, value),
        custom.compose_not_gteq(table, column_name, allowed, value),
        custom.compose_contains(table, column_name, allowed, value),
        custom.compose_not_contains(table, column_name, allowed, value),
        custom.compose_starts_with(table, column_name, allowed, value),
        custom.compose_not_starts_with(table, column_name, allowed, value),
        custom.compose_ends_with(table, column_name, allowed, value),
        custom.compose_not_ends_with(table, column_name, allowed, value),
        custom.compose_in(table, column_name, allowed, values),
        custom.compose_not_in(table, column_name, allowed, values),
        #custom.compose_regex(table, column_name, allowed, value),
        #custom.compose_not_regex(table, column_name, allowed, value),
        custom.compose_null(table, column_name, allowed, value_bool),
        custom.compose_range(table, column_name, allowed, value_range),
        custom.compose_not_range(table, column_name, allowed, value_range),
    )

    expected_sql = [
        "\"products\".\"name\" = 'test'",
        "\"products\".\"name\" != 'test'",
        "\"products\".\"name\" < 'test'",
        "\"products\".\"name\" >= 'test'",
        "\"products\".\"name\" > 'test'",
        "\"products\".\"name\" <= 'test'",
        "\"products\".\"name\" <= 'test'",
        "\"products\".\"name\" > 'test'",
        "\"products\".\"name\" >= 'test'",
        "\"products\".\"name\" < 'test'",
        "\"products\".\"name\" LIKE '%test%'",
        "\"products\".\"name\" NOT LIKE '%test%'",
        "\"products\".\"name\" LIKE 'test%'",
        "\"products\".\"name\" NOT LIKE 'test%'",
        "\"products\".\"name\" LIKE '%test'",
        "\"products\".\"name\" NOT LIKE '%test'",
        "\"products\".\"name\" IN ('test')",
        "\"products\".\"name\" NOT IN ('test')",
        "\"products\".\"name\" IS NULL",
        "\"products\".\"name\" > 'test1' AND \"products\".\"name\" <= 'test2'",
        "(\"products\".\"name\" <= 'test1' OR \"products\".\"name\" > 'test2')"
    ]
    expect(combined.to_sql).to eq(expected_sql.join(' AND '))
  end

end

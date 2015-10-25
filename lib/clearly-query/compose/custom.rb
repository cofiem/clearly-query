module ClearlyQuery
  module Compose

    # Public class for creating custom queries.
    class Custom
      include ClearlyQuery::Compose::Comparison
      include ClearlyQuery::Compose::Core
      include ClearlyQuery::Compose::Range
      include ClearlyQuery::Compose::Subset
      include ClearlyQuery::Compose::Special
      include ClearlyQuery::Validate

      # Create equals condition.
      # @param [Arel::Table] table
      # @param [Symbol] column_name
      # @param [Array<Symbol>] allowed
      # @param [Object] value
      # @return [Arel::Nodes::Node] condition
      def compose_eq(table, column_name, allowed, value)
        validate_table_column(table, column_name, allowed)
        compose_eq_node(table[column_name], value)
      end

      # Create not equals condition.
      # @param [Arel::Table] table
      # @param [Symbol] column_name
      # @param [Array<Symbol>] allowed
      # @param [Object] value
      # @return [Arel::Nodes::Node] condition
      def compose_not_eq(table, column_name, allowed, value)
        validate_table_column(table, column_name, allowed)
        compose_not_eq_node(table[column_name], value)
      end

      # Create less than condition.
      # @param [Arel::Table] table
      # @param [Symbol] column_name
      # @param [Array<Symbol>] allowed
      # @param [Object] value
      # @return [Arel::Nodes::Node] condition
      def compose_lt(table, column_name, allowed, value)
        validate_table_column(table, column_name, allowed)
        compose_lt_node(table[column_name], value)
      end

      # Create not less than condition.
      # @param [Arel::Table] table
      # @param [Symbol] column_name
      # @param [Array<Symbol>] allowed
      # @param [Object] value
      # @return [Arel::Nodes::Node] condition
      def compose_not_lt(table, column_name, allowed, value)
        compose_gteq(table, column_name, allowed, value)
      end

      # Create greater than condition.
      # @param [Arel::Table] table
      # @param [Symbol] column_name
      # @param [Array<Symbol>] allowed
      # @param [Object] value
      # @return [Arel::Nodes::Node] condition
      def compose_gt(table, column_name, allowed, value)
        validate_table_column(table, column_name, allowed)
        compose_gt_node(table[column_name], value)
      end

      # Create not greater than condition.
      # @param [Arel::Table] table
      # @param [Symbol] column_name
      # @param [Array<Symbol>] allowed
      # @param [Object] value
      # @return [Arel::Nodes::Node] condition
      def compose_not_gt(table, column_name, allowed, value)
        compose_lteq(table, column_name, allowed, value)
      end

      # Create less than or equal condition.
      # @param [Arel::Table] table
      # @param [Symbol] column_name
      # @param [Array<Symbol>] allowed
      # @param [Object] value
      # @return [Arel::Nodes::Node] condition
      def compose_lteq(table, column_name, allowed, value)
        validate_table_column(table, column_name, allowed)
        compose_lteq_node(table[column_name], value)
      end

      # Create not less than or equal condition.
      # @param [Arel::Table] table
      # @param [Symbol] column_name
      # @param [Array<Symbol>] allowed
      # @param [Object] value
      # @return [Arel::Nodes::Node] condition
      def compose_not_lteq(table, column_name, allowed, value)
        compose_gt(table, column_name, allowed, value)
      end

      # Create greater than or equal condition.
      # @param [Arel::Table] table
      # @param [Symbol] column_name
      # @param [Array<Symbol>] allowed
      # @param [Object] value
      # @return [Arel::Nodes::Node] condition
      def compose_gteq(table, column_name, allowed, value)
        validate_table_column(table, column_name, allowed)
        compose_gteq_node(table[column_name], value)
      end

      # Create not greater than or equal condition.
      # @param [Arel::Table] table
      # @param [Symbol] column_name
      # @param [Array<Symbol>] allowed
      # @param [Object] value
      # @return [Arel::Nodes::Node] condition
      def compose_not_gteq(table, column_name, allowed, value)
        compose_lt(table, column_name, allowed, value)
      end

      # Create contains condition.
      # @param [Arel::Table] table
      # @param [Symbol] column_name
      # @param [Array<Symbol>] allowed
      # @param [Object] value
      # @return [Arel::Nodes::Node] condition
      def compose_contains(table, column_name, allowed, value)
        validate_table_column(table, column_name, allowed)
        compose_contains_node(table[column_name], value)
      end

      # Create not contains condition.
      # @param [Arel::Table] table
      # @param [Symbol] column_name
      # @param [Array<Symbol>] allowed
      # @param [Object] value
      # @return [Arel::Nodes::Node] condition
      def compose_not_contains(table, column_name, allowed, value)
        validate_table_column(table, column_name, allowed)
        compose_not_contains_node(table[column_name], value)
      end

      # Create starts_with condition.
      # @param [Arel::Table] table
      # @param [Symbol] column_name
      # @param [Array<Symbol>] allowed
      # @param [Object] value
      # @return [Arel::Nodes::Node] condition
      def compose_starts_with(table, column_name, allowed, value)
        validate_table_column(table, column_name, allowed)
        compose_starts_with_node(table[column_name], value)
      end

      # Create not starts_with condition.
      # @param [Arel::Table] table
      # @param [Symbol] column_name
      # @param [Array<Symbol>] allowed
      # @param [Object] value
      # @return [Arel::Nodes::Node] condition
      def compose_not_starts_with(table, column_name, allowed, value)
        validate_table_column(table, column_name, allowed)
        compose_not_starts_with_node(table[column_name], value)
      end

      # Create ends_with condition.
      # @param [Arel::Table] table
      # @param [Symbol] column_name
      # @param [Array<Symbol>] allowed
      # @param [Object] value
      # @return [Arel::Nodes::Node] condition
      def compose_ends_with(table, column_name, allowed, value)
        validate_table_column(table, column_name, allowed)
        compose_ends_with_node(table[column_name], value)
      end

      # Create not ends_with condition.
      # @param [Arel::Table] table
      # @param [Symbol] column_name
      # @param [Array<Symbol>] allowed
      # @param [Object] value
      # @return [Arel::Nodes::Node] condition
      def compose_not_ends_with(table, column_name, allowed, value)
        validate_table_column(table, column_name, allowed)
        compose_not_ends_with_node(table[column_name], value)
      end

      # Create IN condition.
      # @param [Arel::Table] table
      # @param [Symbol] column_name
      # @param [Array<Symbol>] allowed
      # @param [Array] values
      # @return [Arel::Nodes::Node] condition
      def compose_in(table, column_name, allowed, values)
        validate_table_column(table, column_name, allowed)
        compose_in_node(table[column_name], values)
      end

      # Create NOT IN condition.
      # @param [Arel::Table] table
      # @param [Symbol] column_name
      # @param [Array<Symbol>] allowed
      # @param [Array] values
      # @return [Arel::Nodes::Node] condition
      def compose_not_in(table, column_name, allowed, values)
        validate_table_column(table, column_name, allowed)
        compose_not_in_node(table[column_name], values)
      end

      # Create regular expression condition.
      # @param [Arel::Table] table
      # @param [Symbol] column_name
      # @param [Array<Symbol>] allowed
      # @param [Object] value
      # @return [Arel::Nodes::Node] condition
      def compose_regex(table, column_name, allowed, value)
        validate_table_column(table, column_name, allowed)
        compose_regex_node(table[column_name], value)
      end

      # Create negated regular expression condition.
      # Not available just now, maybe in Arel 6?
      # @param [Arel::Table] table
      # @param [Symbol] column_name
      # @param [Array<Symbol>] allowed
      # @param [Object] value
      # @return [Arel::Nodes::Node] condition
      def compose_not_regex(table, column_name, allowed, value)
        validate_table_column(table, column_name, allowed)
        compose_not_regex_node(table[column_name], value)
      end

      # Create null comparison.
      # @param [Arel::Table] table
      # @param [Symbol] column_name
      # @param [Array<Symbol>] allowed
      # @param [Boolean] value
      # @return [Arel::Nodes::Node] condition
      def compose_null(table, column_name, allowed, value)
        validate_table_column(table, column_name, allowed)
        validate_boolean(value)
        compose_null_node(table[column_name], value)
      end

      # Create IN condition using from (inclusive) and to (exclusive).
      # @param [Arel::Table] table
      # @param [Symbol] column_name
      # @param [Array<Symbol>] allowed
      # @param [Object] value
      # @return [Arel::Nodes::Node] condition
      def compose_range(table, column_name, allowed, value)
        validate_table_column(table, column_name, allowed)
        compose_range_node(table[column_name], value)
      end

      # Create NOT IN condition using from (inclusive) and to (exclusive).
      # @param [Arel::Table] table
      # @param [Symbol] column_name
      # @param [Array<Symbol>] allowed
      # @param [Object] value
      # @return [Arel::Nodes::Node] condition
      def compose_not_range(table, column_name, allowed, value)
        validate_table_column(table, column_name, allowed)
        compose_not_range_node(table[column_name], value)
      end

    end
  end
end
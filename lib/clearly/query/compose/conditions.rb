module Clearly
  module Query
    module Compose

      # Methods for building conditions.
      module Conditions
        include Clearly::Query::Compose::Comparison
        include Clearly::Query::Compose::Core
        include Clearly::Query::Compose::Range
        include Clearly::Query::Compose::Subset
        include Clearly::Query::Compose::Special
        include Clearly::Query::Validate

        # Logical query operators
        OPERATORS_LOGICAL = [:and, :or, :not]

        # Comparison query operators
        OPERATORS_COMPARISON = [
            :eq, :equal,
            :not_eq, :not_equal,
            :lt, :less_than,
            :not_lt, :not_less_than,
            :gt, :greater_than,
            :not_gt, :not_greater_than,
            :lteq, :less_than_or_equal,
            :not_lteq, :not_less_than_or_equal,
            :gteq, :greater_than_or_equal,
            :not_gteq, :not_greater_than_or_equal]

        # range query operators
        OPERATORS_RANGE = [
            :range, :in_range,
            :not_range, :not_in_range]

        # Subset query operators
        OPERATORS_SUBSET = [
            :in, :is_in,
            :not_in, :is_not_in,
            :contains, :contain,
            :not_contains, :not_contain, :does_not_contain,
            :starts_with, :start_with,
            :not_starts_with, :not_start_with, :does_not_start_with,
            :ends_with, :end_with,
            :not_ends_with, :not_end_with, :does_not_end_with]

        # Regex query operators
        OPERATORS_REGEX = [
            :regex, :regex_match, :matches,
            :not_regex, :not_regex_match, :does_not_match, :not_match]

        # Special query operators (null)
        OPERATORS_SPECIAL = [:null, :is_null]

        # All query operators except logical operators
        # All query operators except logical operators
        OPERATORS =
            OPERATORS_COMPARISON +
                OPERATORS_RANGE +
                OPERATORS_SUBSET +
                OPERATORS_REGEX +
                OPERATORS_SPECIAL

        # Add conditions to a query.
        # @param [ActiveRecord::Relation] query
        # @param [Array<Arel::Nodes::Node>, Arel::Nodes::Node] conditions
        # @return [ActiveRecord::Relation] the modified query
        def condition_apply(query, conditions)
          conditions = [conditions].flatten
          validate_array(conditions)

          conditions.each do |condition|
            validate_condition(condition)
            query = query.where(condition)
          end

          query
        end

        # Combine multiple conditions.
        # @param [Symbol] combiner
        # @param [Arel::Nodes::Node, Array<Arel::Nodes::Node>] conditions
        # @return [Arel::Nodes::Node] condition
        def condition_combine(combiner, *conditions)
          conditions = [conditions].flatten
          validate_array(conditions)
          validate_condition(conditions[0])
          validate_array_items(conditions)

          combined_conditions = nil
          conditions.each do |condition|
            combined_conditions = condition_combine_new(combiner, combined_conditions, condition)
          end
          combined_conditions
        end

        # Combine multiple conditions with a new condition.
        # @param [Symbol] combiner
        # @param [Arel::Nodes::Node, Array<Arel::Nodes::Node>] conditions
        # @param [Arel::Nodes::Node] new_condition
        # @return [Arel::Nodes::Node] condition
        def condition_combine_new(combiner, conditions, new_condition)
          case combiner
            when :and
              conditions.nil? ? new_condition : compose_and(conditions, new_condition)
            when :or
             conditions.nil? ? new_condition : compose_or(conditions, new_condition)
            when :not
              not_condition = compose_not(new_condition)
              conditions.nil? ? not_condition : compose_and(conditions, not_condition)
            else
              fail Clearly::Query::QueryArgumentError.new("unrecognised logical operator '#{combiner}'")
          end
        end


        # Build a condition.
        # @param [Symbol] operator
        # @param [Arel::Table] table
        # @param [Symbol] column_name
        # @param [Array<symbol>] valid_fields
        # @param [Object] value
        # @return [Arel::Nodes::Node] condition
        def condition_components(operator, table, column_name, valid_fields, value)
          validate_table_column(table, column_name, valid_fields)
          condition_node(operator, table[column_name], value)
        end

        # Build a condition.
        # @param [Symbol] operator
        # @param [Arel::Nodes::Node, Arel::Attributes::Attribute, String] node
        # @param [Object] value
        # @return [Arel::Nodes::Node] condition
        def condition_node(operator, node, value)
          new_condition = condition_node_comparison(operator, node, value)
          new_condition = condition_node_subset(operator, node, value) if new_condition.nil?
          new_condition = compose_null_node(node, value) if new_condition.nil? && [:null, :is_null].include?(operator)

          fail Clearly::Query::QueryArgumentError.new("unrecognised operator '#{operator}'") if new_condition.nil?
          new_condition
        end

        # Build a comparison condition.
        # @param [Symbol] operator
        # @param [Arel::Nodes::Node, Arel::Attributes::Attribute, String] node
        # @param [Object] value
        # @return [Arel::Nodes::Node] condition
        def condition_node_comparison(operator, node, value)
          case operator
            when :eq, :equal
              compose_eq_node(node, value)
            when :not_eq, :not_equal
              compose_not_eq_node(node, value)
            when :lt, :less_than
              compose_lt_node(node, value)
            when :not_lt, :not_less_than
              compose_not_lt_node(node, value)
            when :gt, :greater_than
              compose_gt_node(node, value)
            when :not_gt, :not_greater_than
              compose_not_gt_node(node, value)
            when :lteq, :less_than_or_equal
              compose_lteq_node(node, value)
            when :not_lteq, :not_less_than_or_equal
              compose_not_lteq_node(node, value)
            when :gteq, :greater_than_or_equal
              compose_gteq_node(node, value)
            when :not_gteq, :not_greater_than_or_equal
              compose_not_gteq_node(node, value)
            else
              nil
          end
        end

        # Build a range or subset condition.
        # @param [Symbol] operator
        # @param [Arel::Nodes::Node, Arel::Attributes::Attribute, String] node
        # @param [Object] value
        # @return [Arel::Nodes::Node] condition
        def condition_node_subset(operator, node, value)
          case operator
            when :range, :in_range
              compose_range_node(node, value)
            when :not_range, :not_in_range
              compose_not_range_node(node, value)
            when :in, :is_in
              compose_in_node(node, value)
            when :not_in, :is_not_in
              compose_not_in_node(node, value)
            when :contains, :contain
              compose_contains_node(node, value)
            when :not_contains, :not_contain, :does_not_contain
              compose_not_contains_node(node, value)
            when :starts_with, :start_with
              compose_starts_with_node(node, value)
            when :not_starts_with, :not_start_with, :does_not_start_with
              compose_not_starts_with_node(node, value)
            when :ends_with, :end_with
              compose_ends_with_node(node, value)
            when :not_ends_with, :not_end_with, :does_not_end_with
              compose_not_ends_with_node(node, value)
            when :regex, :regex_match, :matches
              compose_regex_node(node, value)
            when :not_regex, :not_regex_match, :does_not_match, :not_match
              compose_not_regex_node(node, value)
            else
              nil
          end
        end

      end
    end
  end
end
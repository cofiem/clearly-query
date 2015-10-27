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

        # filter operators
        OPERATORS = [
            # combiners
            :and, :or, :not,

            # comparison
            :eq, :equal,
            :not_eq, :not_equal,
            :lt, :less_than,
            :not_lt, :not_less_than,
            :gt, :greater_than,
            :not_gt, :not_greater_than,
            :lteq, :less_than_or_equal,
            :not_lteq, :not_less_than_or_equal,
            :gteq, :greater_than_or_equal,
            :not_gteq, :not_greater_than_or_equal,

            # range
            :range, :in_range,
            :not_range, :not_in_range,

            # subset
            :in, :is_in,
            :not_in, :is_not_in,
            :contains, :contain,
            :not_contains, :not_contain, :does_not_contain,
            :starts_with, :start_with,
            :not_starts_with, :not_start_with, :does_not_start_with,
            :ends_with, :end_with,
            :not_ends_with, :not_end_with, :does_not_end_with,
            :regex, :regex_match, :matches,
            :not_regex, :not_regex_match, :does_not_match, :not_match,

            # special
            :null, :is_null
        ]

        # Combine multiple conditions.
        # @param [Symbol] combiner
        # @param [Arel::Nodes::Node, Array<Arel::Nodes::Node>] conditions
        # @return [Arel::Nodes::Node] condition
        def condition_combine(combiner, *conditions)
          conditions = [conditions].flatten
          validate_array(conditions)
          validate_condition(conditions[0])
          fail Clearly::Query::FilterArgumentError.new("must have at least 2 conditions, got '#{conditions.size}'") if conditions.size < 2
          validate_array_items(conditions)

          combined_conditions = nil
          conditions.each do |condition|
            if combined_conditions.blank?
              combined_conditions = condition
            else
              case combiner
                when :and
                  combined_conditions = compose_and(combined_conditions, condition)
                when :or
                  combined_conditions = compose_or(combined_conditions, condition)
                else
                  fail Clearly::Query::FilterArgumentError.new("unrecognised combiner '#{combiner}'")
              end
            end
          end

          combined_conditions
        end

        # Build a condition.
        # @param [Symbol] filter_name
        # @param [Arel::Table] table
        # @param [Symbol] column_name
        # @param [Array<symbol>] valid_fields
        # @param [Object] filter_value
        # @return [Arel::Nodes::Node] condition
        def condition_components(filter_name, table, column_name, valid_fields, filter_value)
          validate_table_column(table, column_name, valid_fields)
          condition_node(filter_name, table[column_name], filter_value)
        end

        # Build a condition.
        # @param [Symbol] filter_name
        # @param [Arel::Nodes::Node, Arel::Attributes::Attribute, String] node
        # @param [Object] filter_value
        # @return [Arel::Nodes::Node] condition
        def condition_node(filter_name, node, filter_value)
          new_condition = condition_node_comparison(filter_name, node, filter_value)
          new_condition = condition_node_subset(filter_name, node, filter_value) if new_condition.nil?
          new_condition = compose_null_node(new_condition, filter_value) if new_condition.nil? && [:null, :is_null].include?(filter_name)

          fail Clearly::Query::FilterArgumentError.new("unrecognised condition node '#{filter_name}'") if new_condition.nil?
          new_condition
        end

        # Build a comparison condition.
        # @param [Symbol] filter_name
        # @param [Arel::Nodes::Node, Arel::Attributes::Attribute, String] node
        # @param [Object] filter_value
        # @return [Arel::Nodes::Node] condition
        def condition_node_comparison(filter_name, node, filter_value)
          case filter_name
            when :eq, :equal
              compose_eq_node(node, filter_value)
            when :not_eq, :not_equal
              compose_not_eq_node(node, filter_value)
            when :lt, :less_than
              compose_lt_node(node, filter_value)
            when :not_lt, :not_less_than
              compose_not_lt_node(node, filter_value)
            when :gt, :greater_than
              compose_gt_node(node, filter_value)
            when :not_gt, :not_greater_than
              compose_not_gt_node(node, filter_value)
            when :lteq, :less_than_or_equal
              compose_lteq_node(node, filter_value)
            when :not_lteq, :not_less_than_or_equal
              compose_not_lteq_node(node, filter_value)
            when :gteq, :greater_than_or_equal
              compose_gteq_node(node, filter_value)
            when :not_gteq, :not_greater_than_or_equal
              compose_not_gteq_node(node, filter_value)
            else
              nil
          end
        end

        # Build a range or subset condition.
        # @param [Symbol] filter_name
        # @param [Arel::Nodes::Node, Arel::Attributes::Attribute, String] node
        # @param [Object] filter_value
        # @return [Arel::Nodes::Node] condition
        def condition_node_subset(filter_name, node, filter_value)
          case filter_name
            when :range, :in_range
              compose_range_node(node, filter_value)
            when :not_range, :not_in_range
              compose_not_range_node(node, filter_value)
            when :in, :is_in
              compose_in_node(node, filter_value)
            when :not_in, :is_not_in
              compose_not_in_node(node, filter_value)
            when :contains, :contain
              compose_contains_node(node, filter_value)
            when :not_contains, :not_contain, :does_not_contain
              compose_not_contains_node(node, filter_value)
            when :starts_with, :start_with
              compose_starts_with_node(node, filter_value)
            when :not_starts_with, :not_start_with, :does_not_start_with
              compose_not_starts_with_node(node, filter_value)
            when :ends_with, :end_with
              compose_ends_with_node(node, filter_value)
            when :not_ends_with, :not_end_with, :does_not_end_with
              compose_not_ends_with_node(node, filter_value)
            when :regex, :regex_match, :matches
              compose_regex_node(node, filter_value)
            when :not_regex, :not_regex_match, :does_not_match, :not_match
              compose_not_regex_node(node, filter_value)
            else
              nil
          end
        end

      end
    end
  end
end
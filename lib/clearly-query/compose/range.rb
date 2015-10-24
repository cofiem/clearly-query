module ClearlyQuery
  module Compose

    # Methods for composing range queries.
    module Range
      include ClearlyQuery::Validate

      # Create IN condition using range.
      # @param [Arel::Table] table
      # @param [Symbol] column_name
      # @param [Array<Symbol>] allowed
      # @param [Hash] hash
      # @return [Arel::Nodes::Node] condition
      def compose_range_options(table, column_name, allowed, hash)
        validate_table_column(table, column_name, allowed)
        compose_range_options_node(table[column_name], hash)
      end


      # Create IN condition using range.
      # @param [Arel::Nodes::Node, Arel::Attributes::Attribute, String] node
      # @param [Hash] hash
      # @return [Arel::Nodes::Node] condition
      def compose_range_options_node(node, hash)
        fail ClearlyQuery::FilterArgumentError.new("range filter must be {'from': 'value', 'to': 'value'} or {'interval': 'value'} got '#{hash}'") unless hash.is_a?(Hash)

        from = hash[:from]
        to = hash[:to]
        interval = hash[:interval]

        if !from.blank? && !to.blank? && !interval.blank?
          fail ClearlyQuery::FilterArgumentError.new("range filter must use either ('from' and 'to') or ('interval'), not both", {hash: hash})
        elsif from.blank? && !to.blank?
          fail ClearlyQuery::FilterArgumentError.new("range filter missing 'from'", {hash: hash})
        elsif !from.blank? && to.blank?
          fail ClearlyQuery::FilterArgumentError.new("range filter missing 'to'", {hash: hash})
        elsif !from.blank? && !to.blank?
          compose_range_node(node, from, to)
        elsif !interval.blank?
          compose_range_string_node(node, interval)
        else
          fail ClearlyQuery::FilterArgumentError.new("range filter did not contain ('from' and 'to') or ('interval'), got '#{hash}'", {hash: hash})
        end
      end

      # Create NOT IN condition using range.
      # @param [Arel::Table] table
      # @param [Symbol] column_name
      # @param [Array<Symbol>] allowed
      # @param [Hash] hash
      # @return [Arel::Nodes::Node] condition
      def compose_not_range_options(table, column_name, allowed, hash)
        compose_range_options(table, column_name, allowed, hash).not
      end

      # Create NOT IN condition using range.
      # @param [Arel::Nodes::Node, Arel::Attributes::Attribute, String] node
      # @param [Hash] hash
      # @return [Arel::Nodes::Node] condition
      def compose_not_range_options_node(node, hash)
        compose_range_options_node(node, hash).not
      end

      # Create IN condition using range.
      # @param [Arel::Table] table
      # @param [Symbol] column_name
      # @param [Array<Symbol>] allowed
      # @param [String] range_string
      # @return [Arel::Nodes::Node] condition
      def compose_range_string(table, column_name, allowed, range_string)
        validate_table_column(table, column_name, allowed)
        compose_range_string_node(table[column_name], range_string)
      end

      # Create IN condition using range.
      # @param [Arel::Nodes::Node, Arel::Attributes::Attribute, String] node
      # @param [String] range_string
      # @return [Arel::Nodes::Node] condition
      def compose_range_string_node(node, range_string)
        validate_node_or_attribute(node)

        range_regex = /(\[|\()(.*),(.*)(\)|\])/i
        matches = range_string.match(range_regex)
        fail ClearlyQuery::FilterArgumentError.new("range string must be in the form (|[.*,.*]|), got '#{range_string}'") unless matches

        captures = matches.captures

        # get ends spec's and values
        start_exclude = captures[0] == ')'
        start_value = captures[1]
        end_value = captures[2]
        end_exclude = captures[3] == ')'

        # build using gt, lt, gteq, lteq
        if start_exclude
          start_condition = node.gt(start_value)
        else
          start_condition = node.gteq(start_value)
        end

        if end_exclude
          end_condition = node.lt(end_value)
        else
          end_condition = node.lteq(end_value)
        end

        start_condition.and(end_condition)
      end

      # Create NOT IN condition using range.
      # @param [Arel::Table] table
      # @param [Symbol] column_name
      # @param [Array<Symbol>] allowed
      # @param [String] range_string
      # @return [Arel::Nodes::Node] condition
      def compose_not_range_string(table, column_name, allowed, range_string)
        compose_range_string(table, column_name, allowed, range_string).not
      end

      # Create NOT IN condition using range.
      # @param [Arel::Nodes::Node, Arel::Attributes::Attribute, String] node
      # @param [String] range_string
      # @return [Arel::Nodes::Node] condition
      def compose_not_range_string_node(node, range_string)
        compose_range_string_node(node, range_string).not
      end

      # Create IN condition using from (inclusive) and to (exclusive).
      # @param [Arel::Table] table
      # @param [Symbol] column_name
      # @param [Array<Symbol>] allowed
      # @param [Object] from
      # @param [Object] to
      # @return [Arel::Nodes::Node] condition
      def compose_range(table, column_name, allowed, from, to)
        validate_table_column(table, column_name, allowed)
        compose_range_node(table[column_name], from, to)
      end

      # Create IN condition using from (inclusive) and to (exclusive).
      # @param [Arel::Nodes::Node, Arel::Attributes::Attribute, String] node
      # @param [Object] from
      # @param [Object] to
      # @return [Arel::Nodes::Node] condition
      def compose_range_node(node, from, to)
        validate_node_or_attribute(node)
        range = ::Range.new(from, to, true)
        node.in(range)
      end

      # Create NOT IN condition using from (inclusive) and to (exclusive).
      # @param [Arel::Table] table
      # @param [Symbol] column_name
      # @param [Array<Symbol>] allowed
      # @param [Object] from
      # @param [Object] to
      # @return [Arel::Nodes::Node] condition
      def compose_not_range(table, column_name, allowed, from, to)
        compose_range(table, column_name, allowed, from, to).not
      end

      # Create NOT IN condition using from (inclusive) and to (exclusive).
      # @param [Arel::Nodes::Node, Arel::Attributes::Attribute, String] node
      # @param [Object] from
      # @param [Object] to
      # @return [Arel::Nodes::Node] condition
      def compose_not_range_node(node, from, to)
        compose_range_node(node, from, to).not
      end

    end
  end
end

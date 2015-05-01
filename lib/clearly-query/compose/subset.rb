require 'active_support/concern'

module ClearlyQuery
  module Compose

    # Methods for composing subset queries.
    module Subset
      extend ActiveSupport::Concern
      include ClearlyQuery::Validate

      # Create contains condition.
      # @param [Arel::Table] table
      # @param [Symbol] column_name
      # @param [Array<Symbol>] allowed
      # @param [Object] value
      # @return [Arel::Nodes::Node] condition
      def compose_contains(table, column_name, allowed, value)
        validate_table_column(table, column_name, allowed)
        compose_contains_node(table[column_name],value)
      end

      # Create contains condition.
      # @param [Arel::Nodes::Node, Arel::Attributes::Attribute, String] node
      # @param [Object] value
      # @return [Arel::Nodes::Node] condition
      def compose_contains_node(node, value)
        validate_node_or_attribute(node)
        sanitized_value = sanitize_like_value(value)
        contains_value = "%#{sanitized_value}%"
        node.matches(contains_value)
      end

      # Create not contains condition.
      # @param [Arel::Table] table
      # @param [Symbol] column_name
      # @param [Array<Symbol>] allowed
      # @param [Object] value
      # @return [Arel::Nodes::Node] condition
      def compose_not_contains(table, column_name, allowed, value)
        compose_contains(table, column_name, allowed, value).not
      end

      # Create not contains condition.
      # @param [Arel::Nodes::Node, Arel::Attributes::Attribute, String] node
      # @param [Object] value
      # @return [Arel::Nodes::Node] condition
      def compose_not_contains_node(node, value)
        compose_contains_node(node, value).not
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

      # Create starts_with condition.
      # @param [Arel::Nodes::Node, Arel::Attributes::Attribute, String] node
      # @param [Object] value
      # @return [Arel::Nodes::Node] condition
      def compose_starts_with_node(node, value)
        validate_node_or_attribute(node)
        sanitized_value = sanitize_like_value(value)
        contains_value = "#{sanitized_value}%"
        node.matches(contains_value)
      end

      # Create not starts_with condition.
      # @param [Arel::Table] table
      # @param [Symbol] column_name
      # @param [Array<Symbol>] allowed
      # @param [Object] value
      # @return [Arel::Nodes::Node] condition
      def compose_not_starts_with(table, column_name, allowed, value)
        compose_starts_with(table, column_name, allowed, value).not
      end

      # Create not starts_with condition.
      # @param [Arel::Nodes::Node, Arel::Attributes::Attribute, String] node
      # @param [Object] value
      # @return [Arel::Nodes::Node] condition
      def compose_not_starts_with_node(node, value)
        compose_starts_with_node(node, value).not
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

      # Create ends_with condition.
      # @param [Arel::Nodes::Node, Arel::Attributes::Attribute, String] node
      # @param [Object] value
      # @return [Arel::Nodes::Node] condition
      def compose_ends_with_node(node, value)
        validate_node_or_attribute(node)
        sanitized_value = sanitize_like_value(value)
        contains_value = "%#{sanitized_value}"
        node.matches(contains_value)
      end

      # Create not ends_with condition.
      # @param [Arel::Table] table
      # @param [Symbol] column_name
      # @param [Array<Symbol>] allowed
      # @param [Object] value
      # @return [Arel::Nodes::Node] condition
      def compose_not_ends_with(table, column_name, allowed, value)
        compose_ends_with(table, column_name, allowed, value).not
      end

      # Create not ends_with condition.
      # @param [Arel::Nodes::Node, Arel::Attributes::Attribute, String] node
      # @param [Object] value
      # @return [Arel::Nodes::Node] condition
      def compose_not_ends_with_node(node, value)
        compose_ends_with_node(node, value).not
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

      # Create IN condition.
      # @param [Arel::Nodes::Node, Arel::Attributes::Attribute, String] node
      # @param [Array] values
      # @return [Arel::Nodes::Node] condition
      def compose_in_node(node, values)
        validate_node_or_attribute(node)
        validate_array(values)
        validate_array_items(values) if values.is_a?(Array)
        node.in(values)
      end

      # Create NOT IN condition.
      # @param [Arel::Table] table
      # @param [Symbol] column_name
      # @param [Array<Symbol>] allowed
      # @param [Array] values
      # @return [Arel::Nodes::Node] condition
      def compose_not_in(table, column_name, allowed, values)
        compose_in(table, column_name, allowed, values).not
      end

      # Create NOT IN condition.
      # @param [Arel::Nodes::Node, Arel::Attributes::Attribute, String] node
      # @param [Array] values
      # @return [Arel::Nodes::Node] condition
      def compose_not_in_node(node, values)
        compose_in_node(node, values).not
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

      # Create regular expression condition.
      # @param [Arel::Nodes::Node, Arel::Attributes::Attribute, String] node
      # @param [Object] value
      # @return [Arel::Nodes::Node] condition
      def compose_regex_node(node, value)
        validate_node_or_attribute(node)
        Arel::Nodes::Regexp.new(node, Arel::Nodes.build_quoted(value))
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

      # Create negated regular expression condition.
      # Not available just now, maybe in Arel 6?
      # @param [Arel::Nodes::Node, Arel::Attributes::Attribute, String] node
      # @param [Object] value
      # @return [Arel::Nodes::Node] condition
      def compose_not_regex_node(node, value)
        validate_node_or_attribute(node)
        Arel::Nodes::NotRegexp.new(node, Arel::Nodes.build_quoted(value))
      end

    end
  end
end
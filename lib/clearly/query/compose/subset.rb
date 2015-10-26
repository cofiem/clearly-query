module Clearly
  module Query
    module Compose

      # Methods for composing subset queries.
      module Subset
        include Clearly::Query::Validate

        private

        # Create contains condition.
        # @param [Arel::Nodes::Node, Arel::Attributes::Attribute, String] node
        # @param [Object] value
        # @return [Arel::Nodes::Node] condition
        def compose_contains_node(node, value)
          validate_node_or_attribute(node)
          node.matches(like_syntax(value, {start: true, end: true}))
        end

        # Create not contains condition.
        # @param [Arel::Nodes::Node, Arel::Attributes::Attribute, String] node
        # @param [Object] value
        # @return [Arel::Nodes::Node] condition
        def compose_not_contains_node(node, value)
          validate_node_or_attribute(node)
          node.does_not_match(like_syntax(value, {start: true, end: true}))
        end

        # Create starts_with condition.
        # @param [Arel::Nodes::Node, Arel::Attributes::Attribute, String] node
        # @param [Object] value
        # @return [Arel::Nodes::Node] condition
        def compose_starts_with_node(node, value)
          validate_node_or_attribute(node)
          node.matches(like_syntax(value, {start: false, end: true}))
        end

        # Create not starts_with condition.
        # @param [Arel::Nodes::Node, Arel::Attributes::Attribute, String] node
        # @param [Object] value
        # @return [Arel::Nodes::Node] condition
        def compose_not_starts_with_node(node, value)
          validate_node_or_attribute(node)
          node.does_not_match(like_syntax(value, {start: false, end: true}))
        end

        # Create ends_with condition.
        # @param [Arel::Nodes::Node, Arel::Attributes::Attribute, String] node
        # @param [Object] value
        # @return [Arel::Nodes::Node] condition
        def compose_ends_with_node(node, value)
          validate_node_or_attribute(node)
          node.matches(like_syntax(value, {start: true, end: false}))
        end

        # Create not ends_with condition.
        # @param [Arel::Nodes::Node, Arel::Attributes::Attribute, String] node
        # @param [Object] value
        # @return [Arel::Nodes::Node] condition
        def compose_not_ends_with_node(node, value)
          validate_node_or_attribute(node)
          node.does_not_match(like_syntax(value, {start: true, end: false}))
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
        # @param [Arel::Nodes::Node, Arel::Attributes::Attribute, String] node
        # @param [Array] values
        # @return [Arel::Nodes::Node] condition
        def compose_not_in_node(node, values)
          validate_node_or_attribute(node)
          validate_array(values)
          validate_array_items(values) if values.is_a?(Array)
          node.not_in(values)
        end

        # Create regular expression condition.
        # @param [Arel::Nodes::Node, Arel::Attributes::Attribute, String] node
        # @param [Object] value
        # @return [Arel::Nodes::Node] condition
        def compose_regex_node(node, value)
          validate_node_or_attribute(node)
          sanitized_value = sanitize_similar_to_value(value)
          Arel::Nodes::Regexp.new(node, Arel::Nodes.build_quoted(sanitized_value))
        end

        # Create negated regular expression condition.
        # Not available just now, maybe in Arel 6?
        # @param [Arel::Nodes::Node, Arel::Attributes::Attribute, String] node
        # @param [Object] value
        # @return [Arel::Nodes::Node] condition
        def compose_not_regex_node(node, value)
          validate_node_or_attribute(node)
          sanitized_value = sanitize_similar_to_value(value)
          Arel::Nodes::NotRegexp.new(node, Arel::Nodes.build_quoted(sanitized_value))
        end

      end
    end
  end
end

module ClearlyQuery
  module Compose

    # Methods for composing queries containing spacial comparisons.
    module Special
      include ClearlyQuery::Validate

      private

      # Create null comparison node.
      # @param [Arel::Nodes::Node, Arel::Attributes::Attribute, String] node
      # @param [Boolean] value
      # @return [Arel::Nodes::Node] condition
      def compose_null_node(node, value)
        validate_node_or_attribute(node)
        validate_boolean(value)
        value ? node.eq(nil) : node.not_eq(nil)
      end

    end
  end
end
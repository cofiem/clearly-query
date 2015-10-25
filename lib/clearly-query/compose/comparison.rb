module ClearlyQuery

  # Arel helper methods used by Composer and Definition
  module Compose

    # Provides comparisons for composing queries.
    module Comparison
      include ClearlyQuery::Validate

      private

      # Create equals condition.
      # @param [Arel::Nodes::Node] node
      # @param [Object] value
      # @return [Arel::Nodes::Node] condition
      def compose_eq_node(node, value)
        validate_node_or_attribute(node)
        node.eq(value)
      end

      # Create not equals condition.
      # @param [Arel::Nodes::Node] node
      # @param [Object] value
      # @return [Arel::Nodes::Node] condition
      def compose_not_eq_node(node, value)
        validate_node_or_attribute(node)
        node.not_eq(value)
      end

      # Create less than condition.
      # @param [Arel::Nodes::Node] node
      # @param [Object] value
      # @return [Arel::Nodes::Node] condition
      def compose_lt_node(node, value)
        validate_node_or_attribute(node)
        node.lt(value)
      end

      # Create not less than condition.
      # @param [Arel::Nodes::Node, Arel::Attributes::Attribute, String] node
      # @param [Object] value
      # @return [Arel::Nodes::Node] condition
      def compose_not_lt_node(node, value)
        compose_gteq_node(node, value)
      end

      # Create greater than condition.
      # @param [Arel::Nodes::Node, Arel::Attributes::Attribute, String] node
      # @param [Object] value
      # @return [Arel::Nodes::Node] condition
      def compose_gt_node(node, value)
        validate_node_or_attribute(node)
        node.gt(value)
      end

      # Create not greater than condition.
      # @param [Arel::Nodes::Node, Arel::Attributes::Attribute, String] node
      # @param [Object] value
      # @return [Arel::Nodes::Node] condition
      def compose_not_gt_node(node, value)
        compose_lteq_node(node, value)
      end

      # Create less than or equal condition.
      # @param [Arel::Nodes::Node, Arel::Attributes::Attribute, String] node
      # @param [Object] value
      # @return [Arel::Nodes::Node] condition
      def compose_lteq_node(node, value)
        validate_node_or_attribute(node)
        node.lteq(value)
      end

      # Create not less than or equal condition.
      # @param [Arel::Nodes::Node, Arel::Attributes::Attribute, String] node
      # @param [Object] value
      # @return [Arel::Nodes::Node] condition
      def compose_not_lteq_node(node, value)
        compose_gt_node(node, value)
      end

      # Create greater than or equal condition.
      # @param [Arel::Nodes::Node, Arel::Attributes::Attribute, String] node
      # @param [Object] value
      # @return [Arel::Nodes::Node] condition
      def compose_gteq_node(node, value)
        validate_node_or_attribute(node)
        node.gteq(value)
      end

      # Create not greater than or equal condition.
      # @param [Arel::Nodes::Node, Arel::Attributes::Attribute, String] node
      # @param [Object] value
      # @return [Arel::Nodes::Node] condition
      def compose_not_gteq_node(node, value)
        compose_lt_node(node, value)
      end

    end
  end
end
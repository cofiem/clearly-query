module Clearly
  module Query

    # Stores a graph and provides methods to operate on the graph.
    # Graph nodes are a hash, and one special key contains an array of child nodes.
    class Graph

      # root node
      attr_reader :root_node

      # name of the hash key that holds the child nodes
      attr_reader :child_key

      # Create a new Graph.
      # @param [Array] root_node
      # @param [Symbol] child_key
      # @return [Clearly::Query::DepthFirstSearch]
      def initialize(root_node, child_key)
        @root_node = root_node
        @child_key = child_key

        @discovered_nodes = []
        @paths = []

        self
      end

      # build an array that contains paths from the root to all leaves
      # @return [Array] paths from root to leaf
      def branches
        if @discovered_nodes.blank? && @paths.blank?
          traverse_branches(@root_node, nil)
        end
        @paths
      end

      private

      def traverse_branches(current_node, current_path)
        child_nodes = current_node.include?(@child_key) ? current_node[@child_key] : []

        current_node_no_children = current_node.dup.except(@child_key)

        @discovered_nodes.push(current_node_no_children)


        if child_nodes.size > 0
          current_node[@child_key].each do |node|
            child_node_no_children = node.dup.except(@child_key)

            unless @discovered_nodes.include?(child_node_no_children)
              node_path = current_path.nil? ? [] : current_path.dup
              node_path.push(current_node_no_children)
              traverse_branches(node, node_path)
            end

          end
        else
          node_path = current_path.nil? ? [] : current_path.dup
          node_path.push(current_node_no_children)
          @paths.push(node_path)
        end
      end

    end
  end
end
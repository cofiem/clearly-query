module Clearly
  module Query
    module Compose

      # Methods for composing range queries.
      module Range
        include Clearly::Query::Validate

        # Parse an interval.
        # @param [String] value
        # @return [Array<String>] captures
        def parse_interval(value)
          range_regex = /(\[|\()(.*),(.*)(\)|\])/i
          matches = value.match(range_regex)
          fail Clearly::Query::QueryArgumentError.new(
                   "range string must be in the form (|[.*,.*]|), got '#{value}'") unless matches

          captures = matches.captures
          {
              start_include: captures[0] == '[',
              start_value: captures[1],
              end_value: captures[2],
              end_include: captures[3] == ']'
          }
        end

        # Validate a range.
        # @param [Hash] hash
        # @return [Hash]
        def parse_range(hash)
          unless hash.is_a?(Hash)
            fail Clearly::Query::QueryArgumentError.new(
                     "range filter must be {'from': 'value', 'to': 'value'} " +
                         "or {'interval': '(|[.*,.*]|)'} got '#{hash}'", {hash: hash})

          end

          from = hash[:from]
          to = hash[:to]
          interval = hash[:interval]

          if !from.blank? && !to.blank? && !interval.blank?
            fail Clearly::Query::QueryArgumentError.new(
                     "range filter must use either ('from' and 'to') or ('interval'), not both", {hash: hash})
          elsif from.blank? && !to.blank?
            fail Clearly::Query::QueryArgumentError.new(
                     "range filter missing 'from'", {hash: hash})
          elsif !from.blank? && to.blank?
            fail Clearly::Query::QueryArgumentError.new(
                     "range filter missing 'to'", {hash: hash})
          elsif !from.blank? && !to.blank?
            parse_interval("[#{from},#{to})")
          elsif !interval.blank?
            parse_interval(interval)
          else
            fail Clearly::Query::QueryArgumentError.new(
                     "range filter did not contain ('from' and 'to') or ('interval'), got '#{hash}'", {hash: hash})
          end
        end

        private

        # Create IN condition using from (inclusive) and to (exclusive).
        # @param [Arel::Nodes::Node, Arel::Attributes::Attribute, String] node
        # @param [Object] value
        # @return [Arel::Nodes::Node] condition
        def compose_range_node(node, value)
          validate_node_or_attribute(node)
          range_info = parse_range(value)

          # build using gt, lt, gteq, lteq
          if range_info[:start_include]
            start_condition = node.gteq(range_info[:start_value])
          else
            start_condition = node.gt(range_info[:start_value])
          end

          if range_info[:end_include]
            end_condition = node.lteq(range_info[:end_value])
          else
            end_condition = node.lt(range_info[:end_value])
          end

          start_condition.and(end_condition)
        end

        # Create NOT IN condition using from (inclusive) and to (exclusive).
        # @param [Arel::Nodes::Node, Arel::Attributes::Attribute, String] node
        # @param [Object] value
        # @return [Arel::Nodes::Node] condition
        def compose_not_range_node(node, value)
          validate_node_or_attribute(node)
          range_info = parse_range(value)

          # build using gt, lt, gteq, lteq
          if range_info[:start_include]
            start_condition = node.lt(range_info[:start_value])
          else
            start_condition = node.lteq(range_info[:start_value])
          end

          if range_info[:end_include]
            end_condition = node.gt(range_info[:end_value])
          else
            end_condition = node.gteq(range_info[:end_value])
          end

          start_condition.or(end_condition)
        end

      end
    end
  end
end

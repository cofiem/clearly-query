module Clearly
  module Query

    # Parses a query hash, and uses +Clearly::Query::Composer+ to create the query.
    class Parser

      # filter operators
      OPERATORS = [
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

          # subset
          :range, :in_range,
          :not_range, :not_in_range,
          :in,
          :not_in,
          :contains, :contain,
          :not_contains, :not_contain, :does_not_contain,
          :starts_with, :start_with,
          :not_starts_with, :not_start_with, :does_not_start_with,
          :ends_with, :end_with,
          :not_ends_with, :not_end_with, :does_not_end_with,
          :regex,

          # special
          :null, :is_null
      ]

      # @return [Clearly::Query::Composer] composer
      attr_reader :composer

      # Create an instance of Parser.
      # @param [Clearly::Query::Definition] composer
      # @return [Clearly::Query::Parser]
      def initialize(composer = nil)
        composer.nil? ? @composer = Composer.new : @composer = composer
        self
      end

      # Parse a query hash.
      def do(hash)
        # choose the parser method based on the hash key
      end

    end
  end
end
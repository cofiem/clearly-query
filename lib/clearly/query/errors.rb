module Clearly
  module Query

    # Generic error from Clearly Query
    class QueryArgumentError < ArgumentError

      # @return [Hash] partial filter hash
      attr_reader :filter_segment

      # Create a Filter Argument Error
      # @param [String] message
      # @param [Hash] filter_segment
      # @return [QueryArgumentError]
      def initialize(message = nil, filter_segment = nil)
        @message = message
        @filter_segment = filter_segment
        self
      end

      # Show a string representation of this error
      # @return [String]
      def to_s
        @message
      end
    end
  end
end

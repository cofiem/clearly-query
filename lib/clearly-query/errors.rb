module ClearlyQuery

  # Generic error from Clearly Query
  class FilterArgumentError < ArgumentError

    # @return [Hash] partial filter hash
    attr_reader :filter_segment

    # Create a Filter Argument Error
    # @param [String] message
    # @param [Hash] filter_segment
    # @return [FilterArgumentError]
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
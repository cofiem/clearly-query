module ClearlyQuery

  # Generic error from Clearly Query
  class FilterArgumentError < ArgumentError
    attr_reader :filter_segment

    # Create a Filter Argument Error
    def initialize(message = nil, filter_segment = nil)
      @message = message
      @filter_segment = filter_segment
    end

    # Show a string representation of this error
    def to_s
      @message
    end
  end
end
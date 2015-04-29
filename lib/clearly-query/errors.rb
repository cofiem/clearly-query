module ClearlyQuery
  class FilterArgumentError < ArgumentError
    attr_reader :filter_segment
    def initialize(message = nil, filter_segment = nil)
      @message = message
      @filter_segment = filter_segment
    end

    def to_s
      @message
    end
  end
end
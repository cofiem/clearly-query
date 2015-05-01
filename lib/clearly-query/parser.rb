module ClearlyQuery

  # Parses a filter hash so it is ready to be built using the Composer.
  class Parser

    # Create a parser for a filter hash.
    # @param [Hash] hash
    # @return [void]
    def initialize(hash)
      @hash = hash
      @cleaned_hash = nil
    end

    # Get the cleaned filter hash.
    # @return [Hash]
    def cleaned
      @cleaned_hash = clean(hash) if @cleaned_hash.nil?
      @cleaned_hash
    end

    private

    # Clean an object.
    # @param [Object] value
    # @return [Object]
    def clean(value)
      if value.is_a?(Hash)
        clean_hash(value)
      elsif value.is_a?(Array)
        clean_array(value)
      else
        value
      end
    end

    # Clean a hash.
    # @param [Hash] hash
    # @return [Hash] Cleaned hash
    def clean_hash(hash)
      cleaned_hash = Hash.new
      hash.each do |key, value|
        new_key = clean_value(key)
        cleaned_hash[new_key] = clean(value)
      end
      cleaned_hash
    end

    # Clean an array.
    # @param [Array] array
    # @return [Array]
    def clean_array(array)
      cleaned_array = []
      array.each do |item|
        cleaned_array.push(clean(item))
      end
      cleaned_array
    end

    # Convert to a snake case symbol
    # @param [Object] value
    # @return [Symbol]
    def clean_value(value)
      value.to_s.underscore.to_sym
    end

  end

end
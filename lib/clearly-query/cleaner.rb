module ClearlyQuery

  # Cleans a filter hash so it is ready to be built using the Composer.
  class Cleaner

    # Create a cleaner for a filter hash.
    # @return [ClearlyQuery::Cleaner]
    def initialize
      self
    end

    # Get the cleaned filter hash.
    # @param [Hash] hash
    # @return [Hash]
    def do(hash)
      clean(hash)
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
      array.map { |item| clean(item) }
    end

    # Convert to a snake case symbol
    # @param [Object] value
    # @return [Symbol]
    def clean_value(value)
      value.to_s.underscore.to_sym
    end

  end

end
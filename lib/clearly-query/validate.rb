module ClearlyQuery

  # Provides common validations for composing queries.
  module Validate

    # validate an integer
    # @param [Object] value
    # @param [Integer] min
    # @param [Integer] max
    # @return [void]
    def validate_integer(value, min = nil, max = nil)
      validate_not_blank(value)
      fail ClearlyQuery::FilterArgumentError, "value must be an integer, got '#{value}'" if value != value.to_i

      value_i = value.to_i

      fail ClearlyQuery::FilterArgumentError, "value must be '#{min}' or greater, got '#{value_i}'" if !min.blank? && value_i < min
      fail ClearlyQuery::FilterArgumentError, "value must be '#{max}' or less, got '#{value_i}'" if !max.blank? && value_i > max
    end


    # Validate query, table, and column values.
    # @param [Arel::Query] query
    # @param [Arel::Table] table
    # @param [Symbol] column_name
    # @param [Array<Symbol>] allowed
    # @return [void]
    def validate_query_table_column(query, table, column_name, allowed)
      validate_query(query)
      validate_table(table)
      validate_name(column_name, allowed)
    end

    # Validate table and column values.
    # @param [Arel::Table] table
    # @param [Symbol] column_name
    # @param [Array<Symbol>] allowed
    # @return [void]
    def validate_table_column(table, column_name, allowed)
      validate_table(table)
      validate_name(column_name, allowed)
    end

    # Validate model association.
    # @param [ActiveRecord::Base] model
    # @param [Array<ActiveRecord::Base>] models_allowed
    # @return [void]
    def validate_association(model, models_allowed)
      validate_model(model)
      validate_array(models_allowed)

      fail ClearlyQuery::FilterArgumentError, "models allowed must be an Array, got '#{models_allowed}'" unless models_allowed.is_a?(Array)
      fail ClearlyQuery::FilterArgumentError, "model must be in '#{models_allowed}', got '#{model}'" unless models_allowed.include?(model)
    end

    # Validate query and hash values.
    # @param [ActiveRecord::Relation] query
    # @param [Hash] hash
    # @return [void]
    def validate_query_hash(query, hash)
      validate_query(query)
      validate_hash(hash)
    end

    # Validate table value.
    # @param [Arel::Table] table
    # @raise [FilterArgumentError] if table is not an Arel::Table
    # @return [void]
    def validate_table(table)
      fail ClearlyQuery::FilterArgumentError, "table must be Arel::Table, got '#{table.class}'" unless table.is_a?(Arel::Table)
    end

    # Validate table value.
    # @param [ActiveRecord::Relation] query
    # @raise [FilterArgumentError] if query is not an Arel::Query
    # @return [void]
    def validate_query(query)
      fail ClearlyQuery::FilterArgumentError, "query must be ActiveRecord::Relation, got '#{query.class}'" unless query.is_a?(ActiveRecord::Relation)
    end

    # Validate condition value.
    # @param [Arel::Nodes::Node] condition
    # @raise [FilterArgumentError] if condition is not an Arel::Nodes::Node
    # @return [void]
    def validate_condition(condition)
      if !condition.is_a?(Arel::Nodes::Node) && !condition.is_a?(String)
        fail ClearlyQuery::FilterArgumentError, "condition must be Arel::Nodes::Node or String, got '#{condition}'"
      end
    end

    # Validate projection value.
    # @param [Arel::Attributes::Attribute] projection
    # @raise [FilterArgumentError] if projection is not an Arel::Attributes::Attribute
    # @return [void]
    def validate_projection(projection)
      fail ClearlyQuery::FilterArgumentError, "condition must be Arel::Attributes::Attribute, got '#{projection}'" unless projection.is_a?(Arel::Attributes::Attribute)
    end

    # Validate value is a node or attribute
    # @param [Arel::Nodes::Node, Arel::Attributes::Attribute, String] value
    # @return [void]
    def validate_node_or_attribute(value)
      check = value.is_a?(Arel::Nodes::Node) || value.is_a?(String) || value.is_a?(Arel::Attributes::Attribute)
      fail ClearlyQuery::FilterArgumentError, "value must be Arel::Nodes::Node or String or Arel::Attributes::Attribute, got '#{value}'" unless check
    end

    # Validate name value.
    # @param [Symbol] name
    # @param [Array<Symbol>] allowed
    # @raise [FilterArgumentError] if name is not a symbol in allowed
    # @return [void]
    def validate_name(name, allowed)
      validate_not_blank(name)
      fail ClearlyQuery::FilterArgumentError, "name must be a symbol, got '#{name}'" unless name.is_a?(Symbol)
      fail ClearlyQuery::FilterArgumentError, "allowed must be an Array, got '#{allowed}'" unless allowed.is_a?(Array)
      fail ClearlyQuery::FilterArgumentError, "name must be in '#{allowed}', got '#{name}'" unless allowed.include?(name)
    end

    # Validate model value.
    # @param [ActiveRecord::Base] model
    # @raise [FilterArgumentError] if model is not an ActiveRecord::Base
    # @return [void]
    def validate_model(model)
      validate_not_blank(model)
      fail ClearlyQuery::FilterArgumentError, "model must be an ActiveRecord::Base, got '#{model.base_class}'" unless model < ActiveRecord::Base
    end

    # Validate an array.
    # @param [Array, Arel::SelectManager] value
    # @raise [FilterArgumentError] if value is not a valid Array.
    # @return [void]
    def validate_array(value)
      validate_not_blank(value)
      fail ClearlyQuery::FilterArgumentError, "value must be an Array or Arel::SelectManager, got '#{value.class}'" unless value.is_a?(Array) || value.is_a?(Arel::SelectManager)
    end

    # Validate array items. Do not validate if value is not an Array.
    # @param [Array] value
    # @raise [FilterArgumentError] if Array contents are not valid.
    # @return [void]
    def validate_array_items(value)
      # must be a collection of items
      if !value.respond_to?(:each) || !value.respond_to?(:all?) || !value.respond_to?(:any?) || !value.respond_to?(:count)
        fail ClearlyQuery::FilterArgumentError, "must be a collection of items, got '#{value.class}'"
      end

      # if there are no items, let it through
      if value.count > 0
        # all items must be the same type. Assume the first item is the correct type.
        type_compare_item = value[0].class
        type_compare = value.all? { |item| item.is_a?(type_compare_item) }
        fail ClearlyQuery::FilterArgumentError, 'array values must be a single consistent type' unless type_compare

        # restrict length of strings
        if type_compare_item.is_a?(String)
          max_string_length = 120
          string_length = value.all? { |item| item.size <= max_string_length }
          fail ClearlyQuery::FilterArgumentError, "array values that are strings must be '#{max_string_length}' characters or less" unless string_length
        end

        # array contents cannot be Arrays or Hashes
        array_check = value.any? { |item| item.is_a?(Array) }
        fail ClearlyQuery::FilterArgumentError, 'array values cannot be arrays' if array_check

        hash_check = value.any? { |item| item.is_a?(Hash) }
        fail ClearlyQuery::FilterArgumentError, 'array values cannot be hashes' if hash_check

      end
    end

    # Validate a hash.
    # @param [Array] value
    # @raise [FilterArgumentError] if value is not a valid Hash.
    # @return [void]
    def validate_hash(value)
      validate_not_blank(value)
      fail ClearlyQuery::FilterArgumentError, "value must be a Hash, got '#{value}'" unless value.is_a?(Hash)
    end

    # Validate a symbol.
    # @param [Symbol] value
    # @raise [FilterArgumentError] if value is not a Symbol.
    # @return [void]
    def validate_symbol(value)
      validate_not_blank(value)
      fail ClearlyQuery::FilterArgumentError, "value must be a Symbol, got '#{value}'" unless value.is_a?(Symbol)
    end

    # Validate value is not blank
    # @param [Object] value
    # @return [void]
    def validate_not_blank(value)
      fail ClearlyQuery::FilterArgumentError, "value must not be empty, got '#{value}'" if value.blank?
    end

    # Validate value is a boolean
    # @param [Boolean] value
    # @return [void]
    def validate_boolean(value)
      fail ClearlyQuery::FilterArgumentError, "value must be a boolean, got '#{value}'" if !value.is_a?(TrueClass) && !value.is_a?(FalseClass)
    end

    # Validate Extract field for timestamp, time, interval, date.
    # @param [String] value
    # @raise [FilterArgumentError] if value is not a valid field value.
    # @return [void]
    def validate_projection_extract(value)
      valid = [
          :century, :day, :decade, :dow, :epoch, :hour,
          :isodow, :isoyear, :microseconds, :millennium,
          :milliseconds, :minute, :month, :quarter,
          :second, :timezone, :timezone_hour, :timezone_minute,
          :week, :year
      ]
      validate_not_blank(value)
      fail ClearlyQuery::FilterArgumentError, "value for extract must be in '#{valid}', got '#{value}'" unless valid.include?(value.downcase.to_sym)
    end

    # Escape wildcards in like value..
    # @param [String] value
    # @return [String] sanitized value
    def sanitize_like_value(value)
      value.gsub(/[\\_%\|]/) { |x| "\\#{x}" }
    end

    # Escape meta-characters in SIMILAR TO value.
    # see http://www.postgresql.org/docs/9.3/static/functions-matching.html
    # @param [String] value
    # @return [String] sanitized value
    def sanitize_similar_to_value(value)
      value.gsub(/[\\_%\|\*\+\?\{\}\(\)\[\]]/) { |x| "\\#{x}" }
    end

    # Remove all except 0-9, a-z, _ from projection alias
    # @param [String] value
    # @return [String] sanitized value
    def sanitize_projection_alias(value)
      value.gsub(/[^0-9a-zA-Z_]/) { |_| '' }
    end

    # Check that value is a float.
    # @param [Object] value
    # @raise [FilterArgumentError] if value is not a float
    # @return [void]
    def validate_float(value)
      validate_not_blank(value)

      filtered = value.to_s.tr('^0-9.', '')
      fail ClearlyQuery::FilterArgumentError, "value must be a float, got '#{filtered}'" if filtered != value
      fail ClearlyQuery::FilterArgumentError, "value must be a float after conversion, got '#{filtered}'" if filtered != value.to_f

      value_f = filtered.to_f
      fail ClearlyQuery::FilterArgumentError, "value must be greater than 0, got '#{value_f}'" if value_f <= 0

    end

    # Validate definition specification
    # @param [Hash] value
    # @return [void]
    def validate_definition(value)
      validate_hash(value)

      # fields
      validate_hash(value[:fields])

      validate_array(value[:fields][:valid])
      validate_array_items(value[:fields][:valid])

      validate_array(value[:fields][:text])
      validate_array_items(value[:fields][:text])

      validate_array(value[:fields][:mappings])

      value[:fields][:mappings].each do |mapping|
        validate_hash(mapping)
        validate_symbol(mapping[:name])
        validate_not_blank(mapping[:value])
      end

      # associations
      validate_spec_association(value[:associations])

      # defaults
      validate_hash(value[:defaults])
    end

    # Validate association specification
    # @param [Array] value
    # @return [void]
    def validate_spec_association(value)
      validate_array(value)

      value.each do |association|
        validate_hash(association)
        validate_not_blank(association[:join])
        validate_not_blank(association[:on])
        validate_boolean(association[:available])
        validate_spec_association(association[:associations]) if association.include?(:associations)
      end
    end

  end
end
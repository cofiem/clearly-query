module ClearlyQuery

  # Validates and represents a model query specification definition.
  class Definition
    include ClearlyQuery::Compose::Comparison
    include ClearlyQuery::Compose::Core
    include ClearlyQuery::Compose::Range
    include ClearlyQuery::Compose::Subset
    include ClearlyQuery::Validate


    # @return [ActiveRecord::Base] active record model for this definition
    attr_reader :model

    # @return [Arel::Table] arel table for this definition
    attr_reader :table

    # @return [Array<Symbol>] available model fields
    attr_reader :all_fields

    # @return [Array<Symbol>] available text model fields
    attr_reader :text_fields

    # @return [Array<Hash>] mapped model fields
    attr_reader  :mapped_fields

    # @return [Array<Hash>] model associations
    attr_reader :associations

    # @return [Hash] defaults
    attr_reader :defaults

    # Create a Definition
    # @param [ActiveRecord::Base] model
    # @param [Hash] hash
    # @return [ClearlyQuery::Definition]
    def initialize(model, hash)
      validate_model(model)
      validate_definition(hash)
      @raw = hash

      @model = model
      @table = relation_table(model)

      @all_fields = hash[:fields][:valid]
      @text_fields = hash[:fields][:text]

      mappings = {}
      hash[:fields][:mappings].each { |m| mappings[m[:name]] = m[:value] }
      @mapped_fields = mappings

      @associations = build_associations(hash[:associations], @table)
      @defaults = hash[:defaults]

      self
    end

    # Build table field from field symbol.
    # @param [Symbol] field
    # @return [Arel::Table, Symbol, Hash] table, field, filter_settings
    def parse_table_field(field)
      fail ClearlyQuery::FilterArgumentError.new('field name must be a symbol') unless field.is_a?(Symbol)

      field_s = field.to_s

      if field_s.include?('.')
        dot_index = field.to_s.index('.')
        parsed_table = field[0, dot_index].to_sym
        parsed_field = field[(dot_index + 1)..field.length].to_sym

        models = @associations.map { |a| a[:join] }
        table_names = @associations.map { |a| a[:join].table_name.to_sym }

        validate_name(parsed_table, table_names)

        model = parsed_table.to_s.classify.constantize

        validate_association(model, models)

        model_filter_settings = model.clearly_query_def
        model_valid_fields = model_filter_settings[:fields][:valid].map(&:to_sym)
        arel_table = relation_table(model)

        validate_table_column(arel_table, parsed_field, model_valid_fields)

        {
            table_name: parsed_table,
            field_name: parsed_field,
            arel_table: arel_table,
            model: model,
            filter_settings: model_filter_settings
        }
      else
        {
            table_name: @table.name,
            field_name: field,
            arel_table: @table,
            model: @model,
            filter_settings: @raw
        }
      end

    end

    # Parse association to get names.
    # @param [Hash, Array] valid_associations
    # @param [Arel::Table] table
    # @return [Arel::Table, Symbol, Hash] table, field, filter_settings
    def build_associations(valid_associations, table)

      associations = []
      if valid_associations.is_a?(Array)
        more_associations = valid_associations.map { |i| build_associations(i, table) }
        associations.push(*more_associations.flatten.compact) if more_associations.size > 0
      elsif valid_associations.is_a?(Hash)

        join = valid_associations[:join]
        on = valid_associations[:on]
        available = valid_associations[:available]

        more_associations = build_associations(valid_associations[:associations], join)
        associations.push(*more_associations.flatten.compact) if more_associations.size > 0

        if available
          associations.push(
              {
                  join: join,
                  on: on
              })
        end

      end

      associations
    end

    # Get only the relevant joins
    # @param [ActiveRecord::Base] model
    # @param [Hash] associations
    # @param [Array<Hash>] joins
    # @return [Array<Hash>, Boolean] joins, match
    def build_joins(model, associations, joins = [])

      associations.each do |a|
        model_join = a[:join]
        model_on = a[:on]

        join = {join: model_join, on: model_on}

        return [[join], true] if model == model_join

        if a.include?(:associations)
          assoc = a[:associations]
          assoc_joins, match = build_joins(model, assoc, joins + [join])

          return [[join] + assoc_joins, true] if match
        end

      end

      [[], false]
    end

    # Build custom field from model mappings
    # @param [Symbol] column_name
    # @return [Arel::Nodes::Node, Arel::Attributes::Attribute, String]
    def build_custom_field(column_name)

      mappings = {}
      unless @field_mappings.blank?
        @field_mappings.each { |m| mappings[m[:name]] = m[:value] }
      end

      value = mappings[column_name]
      if mappings.keys.include?(column_name) && !value.blank?
        value
      else
        nil
      end
    end

  end
end
module Clearly
  module Query

    # Validates and represents a model query specification definition.
    class Definition
      include Clearly::Query::Compose::Comparison
      include Clearly::Query::Compose::Core
      include Clearly::Query::Compose::Range
      include Clearly::Query::Compose::Subset
      include Clearly::Query::Compose::Special
      include Clearly::Query::Validate

      # @return [ActiveRecord::Base] active record model for this definition
      attr_reader :model

      # @return [Arel::Table] arel table for this definition
      attr_reader :table

      # @return [Array<Symbol>] available model fields
      attr_reader :all_fields

      # @return [Array<Symbol>] available text model fields
      attr_reader :text_fields

      # @return [Array<Hash>] mapped model fields
      attr_reader :field_mappings

      # @return [Array<Hash>] model associations hierarchy
      attr_reader :associations

      # @return [Array<Hash>] model associations flat array
      attr_reader :associations_flat

      # @return [Array<Array<Hash>>] associations organised to calculate joins
      attr_reader :joins

      # @return [Hash] defaults
      attr_reader :defaults

      # Create a Definition
      # @param [Hash] opts the options to create a message with.
      # @option opts [ActiveRecord::Base] :model (nil) the ActiveRecord model
      # @option opts [Hash] :hash (nil) the model definition hash
      # @option opts [Arel::Table] :table (nil) the arel table
      # @return [Clearly::Query::Definition]
      def initialize(opts)
        opts = {model: nil, hash: nil, table: nil}.merge(opts)

        # two ways to go: model and hash, or table and joins
        result = nil
        result = create_from_model(opts[:model], opts[:hash]) unless opts[:model].nil?
        result = create_from_table(opts[:table]) if result.nil? && !opts[:table].nil?

        fail Clearly::Query::QueryArgumentError.new('could not build definition from options') if result.nil?
        result
      end

      # Build custom field from model mappings
      # @param [Symbol] column_name
      # @return [Arel::Nodes::Node, Arel::Attributes::Attribute, String]
      def get_field_mapping(column_name)
        value = @field_mappings[column_name]
        if @field_mappings.keys.include?(column_name) && !value.blank?
          value
        else
          nil
        end
      end

      private

      # Create a Definition from an ActiveRecord model.
      # @param [ActiveRecord::Base] model the ActiveRecord model
      # @param [Hash] hash the model definition hash
      # @return [Clearly::Query::Definition]
      def create_from_model(model, hash)
        validate_model(model)
        validate_definition(hash)

        @model = model
        @table = relation_table(model)

        @all_fields = hash[:fields][:valid]
        @text_fields = hash[:fields][:text]

        mappings = {}
        hash[:fields][:mappings].each { |m| mappings[m[:name]] = m[:value] }
        @field_mappings = mappings

        @associations = hash[:associations]
        @associations_flat = build_associations_flat(@associations)

        if @associations.size > 0
          node = {join: model, on: nil, associations: hash[:associations]}
          graph = Clearly::Query::Graph.new(node, :associations)
          @joins = graph.branches
        else
          @joins = []
        end

        @defaults = hash[:defaults]

        self
      end

      # Create a Definition for a has and belongs to many table.
      # @param [Arel::Table] table the arel table
      # @return [Clearly::Query::Definition]
      def create_from_table(table)
        validate_table(table)

        @model = nil
        @table = table
        @all_fields = []
        @text_fields = []
        @field_mappings = []
        @associations = []
        @associations_flat = []
        @joins = []
        @defaults = {}

        table_name = table.name
        associated_table_names = table_name.split('_')

        # assumes associated tables primary key is 'id'
        # assumes associated table names are the plural version of HABTM _id columns
        associated_table_names.each do |t|
          arel_table = Arel::Table.new(t.to_sym)
          id_column = "#{t.singularize}_id"
          join = {join: arel_table, on: arel_table[:id].eq(table[id_column]), available: true}

          @all_fields.push(id_column)
          @associations.push(join)
          @associations_flat.push(join)
          @joins.push([join])
        end

        self
      end

      # Create a flat array of joins.
      # @param [Array<Hash>] associations
      # @return [Array<Hash>] associations
      def build_associations_flat(associations)
        joins = []

        if associations.is_a?(Array)
          more_associations = associations.map { |i| build_associations_flat(i) }
          joins.push(*more_associations.flatten.compact) if more_associations.size > 0

        elsif associations.is_a?(Hash)
          joins.push(associations.except(:associations))

          if associations[:associations] && associations[:associations].size > 0
            more_associations = build_associations_flat(associations[:associations])
            joins.push(*more_associations.compact) if more_associations.size > 0
          end
        end

        joins.uniq
      end

    end
  end
end

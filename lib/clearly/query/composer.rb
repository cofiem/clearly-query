module Clearly
  module Query

    # Class that composes a query from a filter hash.
    class Composer
      include Clearly::Query::Compose::Conditions
      include Clearly::Query::Validate

      # @return [Array<Clearly::Query::Definition>] available definitions
      attr_reader :definitions

      # Create an instance of Composer using a set of model query spec definitions.
      # @param [Array<Clearly::Query::Definition>] definitions
      # @return [Clearly::Query::Composer]
      def initialize(definitions)
        validate_array(definitions)
        validate_definition_instance(definitions[0])
        validate_array_items(definitions)
        @definitions = definitions
        self
      end

      # Create an instance of Composer from all ActiveRecord models.
      # @return [Clearly::Query::Composer]
      def self.from_active_record
        models = ActiveRecord::Base
                     .descendants
                     .reject { |d| d.name == 'ActiveRecord::SchemaMigration' }
                     .sort { |a, b| a.name <=> b.name }
                     .uniq { |d| d.arel_table.name }

        definitions = models.map do |d|
          if d.name.include?('HABTM_')
            Clearly::Query::Definition.new({table: d.arel_table})
          else
            Clearly::Query::Definition.new({model: d, hash: d.clearly_query_def})
          end
        end

        Composer.new(definitions)
      end

      # Composes a query from a parsed filter hash.
      # @param [ActiveRecord::Base] model
      # @param [Hash] hash
      # @return [Arel::Nodes::Node, Array<Arel::Nodes::Node>]
      def query(model, hash)
        definition = select_definition_from_model(model)
        # default combiner is :and
        parse_query(definition, :and, hash)
      end

      private

      # figure out which model spec to use as the base from the table
      # select from available definitions
      # @param [Arel::Table] table
      # @return [Clearly::Query::Definition]
      def select_definition_from_table(table)
        validate_table(table)
        matches = @definitions.select { |definition| definition.table.name == table.name }
        if matches.size != 1
          fail Clearly::Query::QueryArgumentError, "exactly one definition must match, found '#{matches.size}'"
        end

        matches.first
      end

      # figure out which model spec to use as the base from the model
      # select rom available definitions
      # @param [ActiveRecord::Base] model
      # @return [Clearly::Query::Definition]
      def select_definition_from_model(model)
        validate_model(model)
        select_definition_from_table(model.arel_table)
      end

      # Parse a filter hash.
      # @param [Clearly::Query::Definition] definition
      # @param [Symbol] query_key
      # @param [Hash] query_value
      # @return [Array<Arel::Nodes::Node>]
      def parse_query(definition, query_key, query_value)
        if query_value.blank? || query_value.size < 1
          msg = "filter hash must have at least 1 entry, got '#{query_value.size}'"
          fail Clearly::Query::QueryArgumentError.new(msg, {hash: query_value})
        end

        logical_operators = Clearly::Query::Compose::Conditions::OPERATORS_LOGICAL
        standard_fields = definition.all_fields
        mapped_fields = definition.field_mappings.keys

        conditions = []

        if logical_operators.include?(query_key)
          # first deal with logical operators
          condition = parse_logical_operator(definition, query_key, query_value)
          conditions.push(condition)

        elsif standard_fields.include?(query_key)
          # then cater for standard fields
          field_conditions = parse_standard_field(definition, query_key, query_value)
          conditions.push(*field_conditions)

        elsif mapped_fields.include?(query_key)
          # then deal with mapped fields
          field_conditions = parse_mapped_field(definition, query_key, query_value)
          conditions.push(*field_conditions)

        else
          # finally deal with fields from other tables
          field_conditions = parse_custom(definition, query_key, query_value)
          conditions.push(*field_conditions)
        end

        conditions

      end

      # Parse a logical operator and it's value.
      # @param [Clearly::Query::Definition] definition
      # @param [Symbol] logical_operator
      # @param [Hash] value
      # @return [Arel::Nodes::Node]
      def parse_logical_operator(definition, logical_operator, value)
        validate_definition_instance(definition)
        validate_symbol(logical_operator)
        validate_hash(value)
        conditions = value.map { |key, value| parse_query(definition, key, value) }
        condition_combine(logical_operator, *conditions)
      end

      # Parse a standard field and it's conditions.
      # @param [Clearly::Query::Definition] definition
      # @param [Symbol] field
      # @param [Hash] value
      # @return [Array<Arel::Nodes::Node>]
      def parse_standard_field(definition, field, value)
        validate_definition_instance(definition)
        validate_symbol(field)
        validate_hash(value)
        value.map do |operator, operation_value|
          condition_components(operator, definition.table, field, definition.all_fields, operation_value)
        end
      end

      # Parse a mapped field and it's conditions.
      # @param [Clearly::Query::Definition] definition
      # @param [Symbol] field
      # @param [Hash] value
      # @return [Array<Arel::Nodes::Node>]
      def parse_custom(definition, field, value)
        validate_definition_instance(definition)
        validate_symbol(field)
        fail Clearly::Query::QueryArgumentError.new('field name must contain a dot (.)') unless field.to_s.include?('.')

        validate_hash(value)

        # extract table and field
        dot_index = field.to_s.index('.')

        other_table = field[0, dot_index].to_sym
        other_model = other_table.to_s.classify.constantize
        other_field = field[(dot_index + 1)..field.length].to_sym

        table_names = definition.joins.map { |a| a[:join].table_name.to_sym }
        validate_name(other_table, table_names)

        models = definition.joins.map { |a| a[:join] }
        validate_association(other_model, models)

        other_definition = select_definition_from_model(other_model)

        conditions = parse_standard_field(other_definition, other_field, value)
        subquery(definition, other_definition, conditions)
      end

      def parse_mapped_field(definition, field, value)

      end

      # Build a subquery
      # @param [Clearly::Query::Definition] definition
      # @param [Clearly::Query::Definition] other_definition
      # @param [Array<Arel::Nodes::Node>] conditions
      # @return [Array<Arel::Nodes::Node>]
      def subquery(definition, other_definition, conditions)
        validate_definition_instance(definition)
        validate_definition_instance(other_definition)
        [conditions].flatten.each { |c| validate_node_or_attribute(c) }

        table = definition.table
        model = definition.model
        joins = definition.joins


          # build an exist subquery to apply conditions that
          # refer to another table

          subquery = other_definition.table

          # add conditions to subquery
          [conditions].flatten.each do |c|
            subquery = subquery.where(c)
          end

          # add joins to get access to the relevant tables
          # using the associations from the model definition being used for the subquery
          relevant_joins = joins.select { |j| j[:join] == model}

        relevant_joins.each do |j|
            join_table = j[:join]
            join_condition = j[:on]
            # assume this is an arel_table if it doesn't respond to .arel_table
            arel_table = join_table.respond_to?(:arel_table) ? join_table.arel_table : join_table

            if arel_table.name == table.name
              # add join as condition if this is the main table in the subquery
              subquery = subquery.where(join_condition)
            else
              # add full join if this is not the main table in the subquery
              subquery = subquery.join(arel_table).on(join_condition)
            end

          end

          subquery.project(1).exists
      end

    end
  end
end

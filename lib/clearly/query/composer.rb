module Clearly
  module Query

    # Class that composes a query from a filter hash.
    class Composer
      include Clearly::Query::Compose::Conditions
      include Clearly::Query::Validate

      # All text fields operator.
      OPERATOR_ALL_TEXT = :all_text_fields

      # @return [Array<Clearly::Query::Definition>] available definitions
      attr_reader :definitions

      # Create an instance of Composer using a set of model query spec definitions.
      # @param [Array<Clearly::Query::Definition>] definitions
      # @return [Clearly::Query::Composer]
      def initialize(definitions)
        validate_not_blank(definitions)
        validate_array(definitions)
        validate_definition_instance(definitions[0])
        validate_array_items(definitions)
        @definitions = definitions
        @table_names = definitions.map { |d| d.table.name }
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
          if d.name.include?('::InternalMetadata')
            # ignore the AR metadata
          elsif d.name.include?('HABTM_')
            Clearly::Query::Definition.new({table: d.arel_table})
          else
            Clearly::Query::Definition.new({model: d, hash: d.clearly_query_def})
          end
        end

        Composer.new(definitions.compact)
      end

      # Composes a query from a parsed filter hash.
      # @param [ActiveRecord::Base] model
      # @param [Hash] hash
      # @return [ActiveRecord::Relation]
      def query(model, hash)
        conditions = conditions(model, hash)
        query = model.all
        validate_query(query)
        conditions.each do |condition|
          validate_condition(condition)
          query = query.where(condition)
        end
        query
      end

      # Composes Arel conditions from a parsed filter hash.
      # @param [ActiveRecord::Base] model
      # @param [Hash] hash
      # @return [Array<Arel::Nodes::Node>]
      def conditions(model, hash)
        validate_model(model)
        validate_hash(hash)

        definition = select_definition_from_model(model)
        cleaned_query_hash = Clearly::Query::Cleaner.new.do(hash)

        # default combiner is :and
        parse_conditions(definition, :and, cleaned_query_hash)
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
      def parse_conditions(definition, query_key, query_value)
        if query_value.blank? || query_value.size < 1
          msg = "filter hash must have at least 1 entry, got '#{query_value.size}'"
          fail Clearly::Query::QueryArgumentError.new(msg, {hash: query_value})
        end

        logical_operators = Clearly::Query::Compose::Conditions::OPERATORS_LOGICAL
        mapped_fields = definition.field_mappings.keys
        standard_fields = definition.all_fields - mapped_fields
        conditions = []

        if logical_operators.include?(query_key)
          # first deal with logical operators
          condition = parse_logical_operator(definition, query_key, query_value)
          conditions.push(condition)

        elsif standard_fields.include?(query_key)
          # then cater for standard fields
          field_conditions = parse_standard_field(definition, query_key, query_value)
          conditions.push(*field_conditions)

        elsif OPERATOR_ALL_TEXT == query_key
          # build conditions for all text fields combined with or
          field_condition = parse_all_text_fields(definition, query_value)
          conditions.push(field_condition)

        elsif mapped_fields.include?(query_key)
          # then deal with mapped fields
          field_conditions = parse_mapped_field(definition, query_key, query_value)
          conditions.push(*field_conditions)

        elsif @table_names.any? { |tn| query_key.to_s.downcase.start_with?(tn) }
          # finally deal with fields from other tables
          field_conditions = parse_custom(definition, query_key, query_value)
          conditions.push(field_conditions)

        else
          fail Clearly::Query::QueryArgumentError.new("unrecognised operator or field '#{query_key}'")
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
        validate_not_blank(value)
        validate_hash(value)
        conditions = value.map { |key, value| parse_conditions(definition, key, value) }
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
        validate_not_blank(value)
        validate_hash(value)
        value.map do |operator, operation_value|
          condition_components(operator, definition.table, field, definition.all_fields, operation_value)
        end
      end

      # Parse the conditions for all text fields.
      # @param [Clearly::Query::Definition] definition
      # @param [Hash] value
      # @return [Array<Arel::Nodes::Node>]
      def parse_all_text_fields(definition, value)
        validate_definition_instance(definition)
        validate_not_blank(value)
        validate_hash(value)

        # build conditions for all text fields
        conditions = definition.text_fields.map do |text_field|
          value.map do |operator, operation_value|
            # cater for standard fields and mapped fields
            mapping = definition.get_field_mapping(text_field)
            if mapping.nil?
              condition_components(operator, definition.table, text_field, definition.text_fields, operation_value)
            else
              validate_node_or_attribute(mapping)
              condition_node(operator, mapping, operation_value)
            end
          end
        end

        # combine conditions using :or
        condition_combine(:or, conditions)
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

        validate_not_blank(value)
        validate_hash(value)

        # extract table and field
        dot_index = field.to_s.index('.')

        other_table = field[0, dot_index].to_sym
        other_model = other_table.to_s.classify.constantize
        other_field = field[(dot_index + 1)..field.length].to_sym

        table_names = definition.associations_flat.map { |a| a[:join].table_name.to_sym }
        validate_name(other_table, table_names)

        models = definition.associations_flat.map { |a| a[:join] }
        validate_association(other_model, models)

        other_definition = select_definition_from_model(other_model)

        conditions = parse_standard_field(other_definition, other_field, value)
        subquery(definition, other_definition, conditions)
      end

      # Parse a mapped field
      # @param [Clearly::Query::Definition] definition
      # @param [Symbol] field mapped field
      # @param [Hash] value
      # @return [Array<Arel::Nodes::Node>]
      def parse_mapped_field(definition, field, value)
        validate_definition_instance(definition)
        mapping = definition.get_field_mapping(field)
        validate_node_or_attribute(mapping)
        validate_not_blank(value)
        validate_hash(value)
        value.map do |operator, operation_value|
          condition_node(operator, mapping, operation_value)
        end
      end

      # Build a subquery restricting definition to conditions on other_definition.
      # @param [Clearly::Query::Definition] definition
      # @param [Clearly::Query::Definition] other_definition
      # @param [Array<Arel::Nodes::Node>] conditions
      # @return [Array<Arel::Nodes::Node>]
      def subquery(definition, other_definition, conditions)
        validate_definition_instance(definition)
        validate_definition_instance(other_definition)
        [conditions].flatten.each { |c| validate_node_or_attribute(c) }

        current_model = definition.model
        #current_table = definition.table
        current_joins = definition.joins

        other_table = other_definition.table
        other_model = other_definition.model
        #other_joins = other_definition.joins

        # build an exist subquery to apply conditions that
        # refer to another table

        subquery = other_definition.table

        # add conditions to subquery
        [conditions].flatten.each do |c|
          subquery = subquery.where(c)
        end

        # add joins that provide other table access to current table


        which_joins = current_joins
        join_paths_index = nil
        join_path_current_index = nil
        join_path_other_index = nil
        which_joins.each_with_index do |item, index|
          join_path_current_index = item.find_index { |j| j[:join] == current_model }
          join_path_other_index = item.find_index { |j| j[:join] == other_model }
          if !join_path_current_index.nil? && !join_path_other_index.nil?
            join_paths_index = index
            break
          end
        end

        first_index = [join_path_current_index, join_path_other_index].min
        last_index = [join_path_current_index, join_path_other_index].max
        relevant_joins = which_joins[join_paths_index][first_index..last_index]


        relevant_joins.each do |j|
          join_table = j[:join]
          join_condition = j[:on]

          # assume this is an arel_table if it doesn't respond to .arel_table
          arel_table = join_table.respond_to?(:arel_table) ? join_table.arel_table : join_table

          if arel_table.name == other_table.name && !join_condition.nil?
            # add join as condition if this is the main table in the subquery
            subquery = subquery.where(join_condition)
          elsif arel_table.name != other_table.name && !join_condition.nil?
            # add full join if this is not the main table in the subquery
            subquery = subquery.join(arel_table).on(join_condition)
          end

        end

        subquery.project(1).exists
      end

    end
  end
end

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
        definitions =
            ActiveRecord::Base.descendants
                .reject { |d| d.name == 'ActiveRecord::SchemaMigration' }
                .reject { |d| d.name.include?('HABTM_') }
                .sort { |a, b| a.name <=> b.name }
                .map { |d| Clearly::Query::Definition.new(d, d.clearly_query_def) }
        Composer.new(definitions)
      end

      # Composes a query from a parsed filter hash.
      # @param [ActiveRecord::Base] model
      # @param [Hash] hash
      # @return [Arel::Nodes::Node, Array<Arel::Nodes::Node>]
      def query(model, hash)
        definition = select_definition_from_model(model)
        parse_filter(definition, hash)
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
          fail Clearly::Query::FilterArgumentError, "exactly one definition must match, found '#{matches.size}'"
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
      # @param [Hash, Symbol] primary
      # @param [Hash, Object] secondary
      # @param [nil, Hash] extra
      # @return [Arel::Nodes::Node, Array<Arel::Nodes::Node>]
      def parse_filter(definition, primary, secondary = nil, extra = nil)

        if primary.is_a?(Hash)
          fail Clearly::Query::FilterArgumentError.new("filter hash must have at least 1 entry, got '#{primary.size}'", {hash: primary}) if primary.blank? || primary.size < 1
          fail Clearly::Query::FilterArgumentError.new("extra must be null when processing a hash, got '#{extra}'", {hash: primary}) unless extra.blank?

          conditions = []

          primary.each do |key, value|
            result = parse_filter(definition, key, value, secondary)
            if result.is_a?(Array)
              conditions.push(*result)
            else
              conditions.push(result)
            end
          end

          conditions

        elsif primary.is_a?(Symbol)

          case primary
            when :and, :or
              combiner = primary
              filter_hash = secondary
              result = parse_filter(definition, filter_hash)
              condition_combine(combiner, result)
            when :not
              #combiner = primary
              filter_hash = secondary

              #fail CustomErrors::FilterArgumentError.new("'Not' must have a single combiner or field name, got #{filter_hash.size}", {hash: filter_hash}) if filter_hash.size != 1

              result = parse_filter(definition, filter_hash)

              #fail CustomErrors::FilterArgumentError.new("'Not' must have a single filter, got #{hash.size}.", {hash: filter_hash}) if result.size != 1

              negated_conditions = [result].flatten.map { |c| compose_not(c) }

              negated_conditions

            when *definition.all_fields.dup.push(/\./)
              field = primary
              field_conditions = secondary
              info = definition.parse_table_field(field)
              result = parse_filter(definition, field_conditions, info)

              build_subquery(definition, info, result)

            when *OPERATORS
              filter_name = primary
              filter_value = secondary
              info = extra

              table = info[:arel_table]
              column_name = info[:field_name]
              valid_fields = info[:filter_settings][:fields][:valid]

              custom_field = definition.build_custom_field(column_name)

              if custom_field.blank?
                condition_components(filter_name, table, column_name, valid_fields, filter_value)
              else
                condition_node(filter_name, custom_field, filter_value)
              end

            else
              fail Clearly::Query::FilterArgumentError.new("unrecognised combiner or field name '#{primary}'")
          end
        else
          fail Clearly::Query::FilterArgumentError.new("unrecognised filter component '#{primary}'")
        end
      end

      # Build a subquery
      # @param [Clearly::Query::Definition] definition
      # @param [Hash] info
      # @param [Arel::Nodes::Node, Array<Arel::Nodes::Node>] conditions
      # @return [Arel::Nodes::Node, Array<Arel::Nodes::Node>]
      def build_subquery(definition, info, conditions)
        validate_hash(info)

        # ensure each condition is valid
        [conditions].flatten.each { |c| validate_node_or_attribute(c) }

        current_table = info[:arel_table]
        model = info[:model]

        current_definition = select_definition_from_table(current_table)

        if current_table.name == definition.table.name
          # don't need to build a subquery if the tables
          # are the same, just use the conditions
          conditions
        else
          # build an exist subquery to apply conditions that
          # refer to another table

          subquery = current_table

          # add conditions to subquery
          [conditions].flatten.each do |c|
            subquery = subquery.where(c)
          end

          # add joins to get access to the relevant tables
          # using the associations from the model definition being used for the subquery
          joins, _ = current_definition.build_joins(model, definition.associations)

          joins.each do |j|
            join_table = j[:join]
            join_condition = j[:on]
            # assume this is an arel_table if it doesn't respond to .arel_table
            arel_table = join_table.respond_to?(:arel_table) ? join_table.arel_table : join_table

            if arel_table.name == current_table.name
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

      # Add conditions to a query.
      # @param [ActiveRecord::Relation] query
      # @param [Array<Arel::Nodes::Node>] conditions
      # @return [ActiveRecord::Relation] the modified query
      def apply_conditions(query, conditions)
        conditions.each do |condition|
          query = apply_condition(query, condition)
        end
        query
      end

      # Add condition to a query.
      # @param [ActiveRecord::Relation] query
      # @param [Arel::Nodes::Node] condition
      # @return [ActiveRecord::Relation] the modified query
      def apply_condition(query, condition)
        validate_query(query)
        validate_condition(condition)
        query.where(condition)
      end

    end
  end
end

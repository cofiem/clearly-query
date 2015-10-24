module ClearlyQuery

  # Class that composes a query from a filter hash.
  class Composer
    include ClearlyQuery::Compose::Comparison
    include ClearlyQuery::Compose::Core
    include ClearlyQuery::Compose::Range
    include ClearlyQuery::Compose::Subset
    include ClearlyQuery::Validate

    # filter operators
    OPERATORS = [
        # comparison
        :eq, :equal,
        :not_eq, :not_equal,
        :lt, :less_than,
        :not_lt, :not_less_than,
        :gt, :greater_than,
        :not_gt, :not_greater_than,
        :lteq, :less_than_or_equal,
        :not_lteq, :not_less_than_or_equal,
        :gteq, :greater_than_or_equal,
        :not_gteq, :not_greater_than_or_equal,

        # subset
        :range, :in_range,
        :not_range, :not_in_range,
        :in,
        :not_in,
        :contains, :contain,
        :not_contains, :not_contain, :does_not_contain,
        :starts_with, :start_with,
        :not_starts_with, :not_start_with, :does_not_start_with,
        :ends_with, :end_with,
        :not_ends_with, :not_end_with, :does_not_end_with,
        :regex
    ]

    attr_reader :definitions

    # Create an instance of Composer using a set of model query spec definitions.
    # @param [Array<ClearlyQuery::Definition>] definitions
    # @return [void]
    def initialize(definitions)
      validate_array(definitions)
      validate_array_items(definitions)
      @definitions = definitions
    end

    # Create an instance of Composer from all ActiveRecord models.
    # @return [ClearlyQuery::Composer]
    def self.from_active_record
      definitions = ActiveRecord::Base.descendants
          .reject { |d| d.name == 'ActiveRecord::SchemaMigration' }
          .reject { |d| d.name.include?('HABTM_') }
          .sort { |a, b| a.name <=> b.name }
          .map{ |d| Definition.new(d, d.clearly_query_def)}
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
    # @return [ClearlyQuery::Definition]
    def select_definition_from_table(table)
      validate_table(table)
      matches = @definitions.select { |definition| definition.table.name == table.name }
      if matches.size != 1
        fail ArgumentError, "exactly one definition must match, found '#{matches.size}'"
      end

      matches.first
    end

    # figure out which model spec to use as the base from the model
    # select rom available definitions
    # @param [ActiveRecord::Base] model
    # @return [ClearlyQuery::Definition]
    def select_definition_from_model(model)
      validate_model(model)
      select_definition_from_table(model.arel_table)
    end

    # Parse a filter hash.
    # @param [ClearlyQuery::Definition] definition
    # @param [Hash, Symbol] primary
    # @param [Hash, Object] secondary
    # @param [nil, Hash] extra
    # @return [Arel::Nodes::Node, Array<Arel::Nodes::Node>]
    def parse_filter(definition, primary, secondary = nil, extra = nil)

      if primary.is_a?(Hash)
        fail ClearlyQuery::FilterArgumentError.new("filter hash must have at least 1 entry, got '#{primary.size}'", {hash: primary}) if primary.blank? || primary.size < 1
        fail ClearlyQuery::FilterArgumentError.new("extra must be null when processing a hash, got '#{extra}'", {hash: primary}) unless extra.blank?

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
            combine_all(combiner, result)
          when :not
            #combiner = primary
            filter_hash = secondary

            #fail CustomErrors::FilterArgumentError.new("'Not' must have a single combiner or field name, got #{filter_hash.size}", {hash: filter_hash}) if filter_hash.size != 1

            result = parse_filter(definition, filter_hash)

            #fail CustomErrors::FilterArgumentError.new("'Not' must have a single filter, got #{hash.size}.", {hash: filter_hash}) if result.size != 1

            if result.respond_to?(:map)
              negated_conditions = result.map { |c| compose_not(c) }
            else
              negated_conditions = [compose_not(result)]
            end
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
              condition(filter_name, table, column_name, valid_fields, filter_value)
            else
              condition_node(filter_name, custom_field, filter_value)
            end

          else
            fail ClearlyQuery::FilterArgumentError.new("unrecognised combiner or field name '#{primary}'")
        end
      else
        fail ClearlyQuery::FilterArgumentError.new("unrecognised filter component '#{primary}'")
      end
    end

    # Build a subquery
    # @param [ClearlyQuery::Definition] definition
    # @param [Hash] info
    # @param [Arel::Nodes::Node, Array<Arel::Nodes::Node>] conditions
    # @return [Arel::Nodes::Node, Array<Arel::Nodes::Node>]
    def build_subquery(definition, info, conditions)

      current_table = info[:arel_table]
      current_definition = select_definition_from_table(current_table)
      model = info[:model]

      # TODO: turn this into an EXISTS query
      # e.g.
=begin
SELECT *
FROM sites
WHERE
    EXISTS
        (SELECT 1
        FROM projects_sites
        WHERE
            "sites"."id" = "projects_sites"."site_id"
            AND EXISTS (
                (SELECT 1
                FROM "projects"
                WHERE
                    "projects"."deleted_at" IS NULL
                    AND "projects"."creator_id" = 7
                    AND "projects_sites"."project_id" = "projects"."id"
                )
                UNION ALL
                (SELECT 1
                FROM "permissions"
                WHERE
                    "permissions"."user_id" = 7
                    AND "permissions"."level" IN ('reader', 'writer', 'owner')
                    AND "projects_sites"."project_id" = "permissions"."project_id"
                )
            )
        )
OR
    EXISTS
        (SELECT 1
        FROM "audio_events" ae1
        WHERE
            ae1."deleted_at" IS NULL
            AND ae1."is_reference" = TRUE
            AND "audio_events"."id" = ae1.id
        )
=end


      if current_table != definition.table
        subquery = current_table.project(current_table[:id])

        # add conditions to subquery
        if conditions.respond_to?(:each)
          conditions.each { |c| subquery = subquery.where(c) }
        else
          subquery = subquery.where(result)
        end

        # add relevant joins
        joins, match = current_definition.build_joins(model, definition.associations)

        joins.each do |j|
          table = j[:join]
          # assume this is an arel_table if it doesn't respond to .arel_table
          arel_table = table.respond_to?(:arel_table) ? table.arel_table : table
          subquery = subquery.join(arel_table, Arel::Nodes::OuterJoin).on(j[:on])
        end

        compose_in(current_table, :id, [:id], subquery)
      else
        conditions
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

    # Combine two conditions.
    # @param [Symbol] combiner
    # @param [Arel::Nodes::Node] condition1
    # @param [Arel::Nodes::Node] condition2
    # @return [Arel::Nodes::Node] condition
    def combine(combiner, condition1, condition2)
      case combiner
        when :and
          compose_and(condition1, condition2)
        when :or
          compose_or(condition1, condition2)
        else
          fail ClearlyQuery::FilterArgumentError.new("unrecognised combiner '#{combiner}'")
      end
    end

    # Combine multiple conditions.
    # @param [Symbol] combiner
    # @param [Array<Arel::Nodes::Node>] conditions
    # @return [Arel::Nodes::Node] condition
    def combine_all(combiner, conditions)
      fail ClearlyQuery::FilterArgumentError.new("combiner '#{combiner}' must have at least 2 entries, got '#{conditions.size}'") if conditions.blank? || conditions.size < 2
      combined_conditions = nil

      conditions.each do |condition|

        if combined_conditions.blank?
          combined_conditions = condition
        else
          combined_conditions = combine(combiner, combined_conditions, condition)
        end

      end

      combined_conditions
    end

    # Build a condition.
    # @param [Symbol] filter_name
    # @param [Arel::Table] table
    # @param [Symbol] column_name
    # @param [Array<symbol>] valid_fields
    # @param [Object] filter_value
    # @return [Arel::Nodes::Node] condition
    def condition(filter_name, table, column_name, valid_fields, filter_value)
      case filter_name

        # comparisons
        when :eq, :equal
          compose_eq(table, column_name, valid_fields, filter_value)
        when :not_eq, :not_equal
          compose_not_eq(table, column_name, valid_fields, filter_value)
        when :lt, :less_than
          compose_lt(table, column_name, valid_fields, filter_value)
        when :not_lt, :not_less_than
          compose_not_lt(table, column_name, valid_fields, filter_value)
        when :gt, :greater_than
          compose_gt(table, column_name, valid_fields, filter_value)
        when :not_gt, :not_greater_than
          compose_not_gt(table, column_name, valid_fields, filter_value)
        when :lteq, :less_than_or_equal
          compose_lteq(table, column_name, valid_fields, filter_value)
        when :not_lteq, :not_less_than_or_equal
          compose_not_lteq(table, column_name, valid_fields, filter_value)
        when :gteq, :greater_than_or_equal
          compose_gteq(table, column_name, valid_fields, filter_value)
        when :not_gteq, :not_greater_than_or_equal
          compose_not_gteq(table, column_name, valid_fields, filter_value)

        # subsets
        when :range, :in_range
          compose_range_options(table, column_name, valid_fields, filter_value)
        when :not_range, :not_in_range
          compose_not_range_options(table, column_name, valid_fields, filter_value)
        when :in
          compose_in(table, column_name, valid_fields, filter_value)
        when :not_in
          compose_not_in(table, column_name, valid_fields, filter_value)
        when :contains, :contain
          compose_contains(table, column_name, valid_fields, filter_value)
        when :not_contains, :not_contain, :does_not_contain
          compose_not_contains(table, column_name, valid_fields, filter_value)
        when :starts_with, :start_with
          compose_starts_with(table, column_name, valid_fields, filter_value)
        when :not_starts_with, :not_start_with, :does_not_start_with
          compose_not_starts_with(table, column_name, valid_fields, filter_value)
        when :ends_with, :end_with
          compose_ends_with(table, column_name, valid_fields, filter_value)
        when :not_ends_with, :not_end_with, :does_not_end_with
          compose_not_ends_with(table, column_name, valid_fields, filter_value)
        when :regex, :regex_match, :matches
          compose_regex(table, column_name, valid_fields, filter_value)
        when :not_regex, :not_regex_match, :does_not_match, :not_match
          compose_not_regex(table, column_name, valid_fields, filter_value)

        # unknown
        else
          fail ClearlyQuery::FilterArgumentError.new("unrecognised condition' #{filter_name}'")
      end
    end

    # Build a condition.
    # @param [Symbol] filter_name
    # @param [Arel::Nodes::Node, Arel::Attributes::Attribute, String] node
    # @param [Object] filter_value
    # @return [Arel::Nodes::Node] condition
    def condition_node(filter_name, node, filter_value)
      case filter_name

        # comparisons
        when :eq, :equal
          compose_eq_node(node, filter_value)
        when :not_eq, :not_equal
          compose_not_eq_node(node, filter_value)
        when :lt, :less_than
          compose_lt_node(node, filter_value)
        when :not_lt, :not_less_than
          compose_not_lt_node(node, filter_value)
        when :gt, :greater_than
          compose_gt_node(node, filter_value)
        when :not_gt, :not_greater_than
          compose_not_gt_node(node, filter_value)
        when :lteq, :less_than_or_equal
          compose_lteq_node(node, filter_value)
        when :not_lteq, :not_less_than_or_equal
          compose_not_lteq_node(node, filter_value)
        when :gteq, :greater_than_or_equal
          compose_gteq_node(node, filter_value)
        when :not_gteq, :not_greater_than_or_equal
          compose_not_gteq_node(node, filter_value)

        # subsets
        when :range, :in_range
          compose_range_options_node(node, filter_value)
        when :not_range, :not_in_range
          compose_not_range_options_node(node, filter_value)
        when :in
          compose_in_node(node, filter_value)
        when :not_in
          compose_not_in_node(node, filter_value)
        when :contains, :contain
          compose_contains_node(node, filter_value)
        when :not_contains, :not_contain, :does_not_contain
          compose_not_contains_node(node, filter_value)
        when :starts_with, :start_with
          compose_starts_with_node(node, filter_value)
        when :not_starts_with, :not_start_with, :does_not_start_with
          compose_not_starts_with_node(node, filter_value)
        when :ends_with, :end_with
          compose_ends_with_node(node, filter_value)
        when :not_ends_with, :not_end_with, :does_not_end_with
          compose_not_ends_with_node(node, filter_value)
        when :regex, :regex_match, :matches
          compose_regex_node(node, filter_value)
        when :not_regex, :not_regex_match, :does_not_match, :not_match
          compose_not_regex_node(node, filter_value)

        # unknown
        else
          fail ClearlyQuery::FilterArgumentError.new("unrecognised condition node '#{filter_name}'")
      end
    end

  end
end
module ClearlyQuery

  # Class that composes a query from a filter hash.
  class Composer
    include ClearlyQuery::Compose::Comparison
    include ClearlyQuery::Compose::Core
    include ClearlyQuery::Compose::Range
    include ClearlyQuery::Compose::Subset
    include ClearlyQuery::Validate

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

    # Create an instance of Composer using a set of model query spec definitions.
    # @param [Array<ClearlyQuery::Definition>] definitions
    # @return [void]
    def initialize(definitions)
      validate_array(definitions)
      validate_array_items(definitions)
      @definitions = definitions


    end

    # Composes a query from a parsed filter hash.
    # @param [ActiveRecord::Base] model
    # @param [ClearlyQuery::Parser] parser
    def query(model, parser)

      # figure out which model spec to use as the base from the model
      # select the base model spec from @definitions

      matching_definitions = @definitions.select { |definition| definition.model == model }
      fail ArgumentError, "Exactly one definition must match model, found #{matching_definitions.inspect}" if matching_definitions.size != 1

      current_definition = matching_definitions.first

      # from model config
      # @table = table
      # @filter_settings = filter_settings
      #
      # @valid_fields = filter_settings[:valid_fields].map(&:to_sym)
      # @render_fields = filter_settings[:render_fields].map(&:to_sym)
      # @text_fields = filter_settings[:text_fields].map(&:to_sym)
      # @valid_associations = filter_settings[:valid_associations]
      # @field_mappings = filter_settings[:field_mappings]


      parse_filter(parser.cleaned)
    end

    private

    # Parse a filter hash.
    # @param [Hash, Symbol] primary
    # @param [Hash, Object] secondary
    # @param [nil, Hash] extra
    # @return [Arel::Nodes::Node, Array<Arel::Nodes::Node>]
    def parse_filter(primary, secondary = nil, extra = nil)

      if primary.is_a?(Hash)
        fail ClearlyQuery::FilterArgumentError.new("Filter hash must have at least 1 entry, got #{primary.size}.", {hash: primary}) if primary.blank? || primary.size < 1
        fail ClearlyQuery::FilterArgumentError.new("Extra must be null when processing a hash, got #{extra}.", {hash: primary}) unless extra.blank?

        conditions = []

        primary.each do |key, value|
          result = parse_filter(key, value, secondary)
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
            result = parse_filter(filter_hash)
            combine_all(combiner, result)
          when :not
            #combiner = primary
            filter_hash = secondary

            #fail CustomErrors::FilterArgumentError.new("'Not' must have a single combiner or field name, got #{filter_hash.size}", {hash: filter_hash}) if filter_hash.size != 1

            result = parse_filter(filter_hash)

            #fail CustomErrors::FilterArgumentError.new("'Not' must have a single filter, got #{hash.size}.", {hash: filter_hash}) if result.size != 1

            if result.respond_to?(:map)
              negated_conditions = result.map { |c| compose_not(c) }
            else
              negated_conditions = [compose_not(result)]
            end
            negated_conditions

          when *current_definition.all_fields.dup.push(/\./)
            field = primary
            field_conditions = secondary
            info = parse_table_field(@table, field, @filter_settings)
            result = parse_filter(field_conditions, info)

            build_subquery(info, result)

          when *OPERATORS
            filter_name = primary
            filter_value = secondary
            info = extra

            table = info[:arel_table]
            column_name = info[:field_name]
            valid_fields = info[:filter_settings].all_fields

            custom_field = build_custom_field(column_name)

            if custom_field.blank?
              condition(filter_name, table, column_name, valid_fields, filter_value)
            else
              condition_node(filter_name, custom_field, filter_value)
            end

          else
            fail ClearlyQuery::FilterArgumentError.new("Unrecognised combiner or field name: #{primary}.")
        end
      else
        fail ClearlyQuery::FilterArgumentError.new("Unrecognised filter component: #{primary}.")
      end
    end

    def build_subquery(info, conditions)

      current_table = info[:arel_table]
      model = info[:model]

      if current_table != current_definition.table
        subquery = @table.project(@table[:id])

        # add conditions to subquery
        if conditions.respond_to?(:each)
          conditions.each { |c| subquery = subquery.where(c) }
        else
          subquery = subquery.where(result)
        end

        # add relevant joins
        joins, match = build_joins(model, @valid_associations)

        joins.each do |j|
          table = j[:join]
          # assume this is an arel_table if it doesn't respond to .arel_table
          arel_table = table.respond_to?(:arel_table) ? table.arel_table : table
          subquery = subquery.join(arel_table, Arel::Nodes::OuterJoin).on(j[:on])
        end

        compose_in(@table, :id, [:id], subquery)
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
          fail ClearlyQuery::FilterArgumentError.new("Unrecognised filter combiner #{combiner}.")
      end
    end

    # Combine multiple conditions.
    # @param [Symbol] combiner
    # @param [Array<Arel::Nodes::Node>] conditions
    # @return [Arel::Nodes::Node] condition
    def combine_all(combiner, conditions)
      fail ClearlyQuery::FilterArgumentError.new("Combiner '#{combiner}' must have at least 2 entries, got #{conditions.size}.") if conditions.blank? || conditions.size < 2
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
          fail ClearlyQuery::FilterArgumentError.new("Unrecognised filter #{filter_name}.")
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
          fail ClearlyQuery::FilterArgumentError.new("Unrecognised filter #{filter_name}.")
      end
    end

  end
end
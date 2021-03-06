module Clearly
  module Query
    module Compose

      # Provides 'and', and 'or' for composing queries.
      module Core
        include Clearly::Query::Validate

        private

        # Get the ActiveRecord::Relation that represents zero records.
        # @param [ActiveRecord::Base] model
        # @return [ActiveRecord::Relation] query that will get zero records
        def relation_none(model)
          validate_model(model)
          model.none
        end

        # Get the ActiveRecord::Relation that represents all records.
        # @param [ActiveRecord::Base] model
        # @return [ActiveRecord::Relation] query that will get all records
        def relation_all(model)
          validate_model(model)
          model.all
        end

        # Get the Arel::Table for this model.
        # @param [ActiveRecord::Base] model
        # @return [Arel::Table] arel table
        def relation_table(model)
          validate_model(model)
          model.arel_table
        end

        # Join conditions using or.
        # @param [Arel::Nodes::Node] first_condition
        # @param [Arel::Nodes::Node] second_condition
        # @return [Arel::Nodes::Node] condition
        def compose_or(first_condition, second_condition)
          validate_condition(first_condition)
          validate_condition(second_condition)
          first_condition.or(second_condition)
        end

        # Join conditions using and.
        # @param [Arel::Nodes::Node] first_condition
        # @param [Arel::Nodes::Node] second_condition
        # @param [Array<Arel::Nodes::Node>] conditions
        # @return [Arel::Nodes::Node] condition
        def compose_and(first_condition, second_condition, *conditions)
          validate_condition(first_condition)
          validate_condition(second_condition)
          combined = first_condition.and(second_condition)

          unless conditions.blank?
            conditions.each do |condition|
              combined = combined.and(condition)
            end
          end

          combined
        end

        # Join conditions using not.
        # @param [Arel::Nodes::Node] condition
        # @return [Arel::Nodes::Node] condition
        def compose_not(condition)
          validate_condition(condition)
          condition.not
        end

      end
    end
  end
end

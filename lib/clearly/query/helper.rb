module Clearly
  module Query

    # Utility methods for working with Arel.
    class Helper
      class << self

        # Concatenate one or more strings
        # @param [Array<String>] args strings to concatenate
        # @return [Arel::Nodes::Node]
        def string_concat(*args)
          adapter = ActiveRecord::Base.connection.adapter_name.underscore.downcase

          case adapter
            when 'mysql'
              Arel::Nodes::NamedFunction.new('concat', *args)
            when 'sqlserver'
              string_concat_infix('+', *args)
            when 'postgres'
            when 'sq_lite'
              string_concat_infix('||', *args)
            else
              fail ArgumentError, "unsupported database adapter '#{adapter}'"
          end
        end

        # Concatenate strings using an operator
        # @param [Object] operator infix operator
        # @param [Array<String>] args strings to concatenate
        # @return [Arel::Nodes::Node]
        def string_concat_infix(operator, *args)
          if args.blank? || args.size < 2
            fail ArgumentError, "string concatenation requires operator and two or more arguments, given '#{args.size}'"
          end

          result = Arel::Nodes::InfixOperation.new(operator, args[0], args[1])

          if args.size > 2
            args.drop(2).each do |a|
              result = Arel::Nodes::InfixOperation.new(operator, result, a)
            end
          end

          result
        end

      end
    end
  end
end

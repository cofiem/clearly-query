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
              named_function('concat', args)
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

        # Construct a SQL literal.
        # This is useful for sql that is too complex for Arel.
        # @param [String] value
        # @return [Arel::Nodes::Node]
        def sql_literal(value)
          Arel::Nodes::SqlLiteral.new(value)
        end

        # Construct a SQL quoted string.
        # This is used for fragments of SQL.
        # @param [String] value
        # @return [Arel::Nodes::Node]
        def sql_quoted(value)
          Arel::Nodes.build_quoted(value)
        end

        # Construct a SQL EXISTS clause.
        # @param [Arel::Nodes::Node] node
        # @return [Arel::Nodes::Node]
        def exists(node)
          Arel::Nodes::Exists.new(node)
        end

        def named_function(name, expression, function_alias = nil)
          Arel::Nodes::NamedFunction.new(name, expression, function_alias)
        end

      end
    end
  end
end

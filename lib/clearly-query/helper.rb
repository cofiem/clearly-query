module ClearlyQuery
  class Helper
    class << self
      def string_concat(*args)
        adapter = ActiveRecord::Base.connection.adapter_name.underscore.downcase

        case adapter
          when 'mysql'
            Arel::Nodes::NamedFunction.new('concat', *args)
          when 'sqlserver'
            string_concat_infix('+', *args)
          else
            string_concat_infix('||', *args)
        end
      end

      def string_concat_infix(operator, *args)
        fail ArgumentError, "String concatenation requires two or more arguments, given #{args.size}" if args.size < 2

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
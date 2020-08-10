module Gammo
  module XPath
    module AST
      # Class for representing any value in Gammo::XPath internally.
      # This should not referred from end users, should be converted to
      # primitive classes or Gammo::XPath::NodeSet.
      # @!visibility private
      class Value
        attr_reader :value

        def initialize(value)
          @value = value
        end

        def evaluate(context)
          self
        end

        def node_set?
          false
        end

        def number?
          false
        end

        def string?
          false
        end

        def bool?
          false
        end

        def to_node_set_value(context)
          Value::NodeSet.new(to_node_set(context))
        end

        def to_node_set(context)
          XPath::NodeSet.new
        end

        # @!visibility private
        class VariableReference < Value
          def evaluate(context)
            variables = context.variables
            # TODO: Is this correct?
            return String.new('') unless variables.key?(value.to_sym)
            ret = variables[value.to_sym]
            ret = ret.call if ret.respond_to?(:call)
            case ret
            when Integer, Float then Number.new(ret)
            else String.new(ret)
            end
          end
        end

        # @!visibility private
        class NodeSet < Value
          def to_node_set(context)
            value
          end

          def to_bool
            !value.empty?
          end

          def to_number
            to_s.to_i
          end

          def to_s
            return '' if value.empty?
            value.first.to_s
          end

          def node_set?
            true
          end
        end

        # @!visibility private
        class Boolean < Value
          def to_bool
            value
          end

          def to_number
            value ? 1 : 0
          end

          def to_s
            value.to_s
          end

          def bool?
            true
          end
        end

        # @!visibility private
        class Number < Value
          def to_bool
            !value.zero?
          end

          def to_number
            value
          end

          def to_s
            value.to_s
          end

          def number?
            true
          end
        end

        # @!visibility private
        class String < Value
          def initialize(value)
            super
            # TODO: Get rid of these slices. These should be taken care by
            # the parsing layer.
            @value = @value.slice(1..-1) if value.start_with?(?")
            @value = @value.slice(0..-2) if value.end_with?(?")
          end

          def to_bool
            !value.empty?
          end

          def to_number
            # TODO
            value.to_i
          end

          def to_s
            value
          end

          def string?
            true
          end
        end
      end
    end
  end
end

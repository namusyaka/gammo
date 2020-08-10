require 'gammo/xpath/ast/subclassify'
require 'gammo/xpath/ast/value'

module Gammo
  module XPath
    module AST
      # Class for representing XPath core function library.
      # https://www.w3.org/TR/1999/REC-xpath-19991116/#corelib
      class Function
        extend Subclassify

        # @!visibility private
        def initialize(*arguments)
          @arguments = arguments
        end

        # @!visibility private
        def evaluate(context)
          raise NotImplementedError, '#evaluate must be implemented'
        end

        private

        # @!visibility private
        def number(val)
          return val if val.instance_of?(Value::Number)
          Value::Number.new(val)
        end

        # @!visibility private
        def bool(val)
          return val if val.instance_of?(Value::Boolean)
          Value::Boolean.new(val)
        end

        # @!visibility private
        def string(val)
          return val if val.instance_of?(Value::String)
          Value::String.new(val)
        end

        attr_reader :arguments

        # @!visibility private
        class Boolean < Function
          declare :boolean

          def evaluate(context)
            bool arguments[0].evaluate(context)
          end
        end

        # @!visibility private
        class Not < Function
          declare :not

          def evaluate(context)
            bool !arguments[0].evaluate(context)
          end
        end

        # @!visibility private
        class True < Function
          declare :true

          def evaluate(context)
            bool true
          end
        end

        # @!visibility private
        class False < Function
          declare :false

          def evaluate(context)
            bool false
          end
        end

        # @!visibility private
        class Ceiling < Function
          declare :ceiling

          def evaluate(context)
            number arguments[0].evaluate(context).value.ceil
          end
        end

        # @!visibility private
        class String < Function
          declare :string

          def evaluate(context)
            return string context.node.to_s if arguments.length.zero?
            string arguments[0].evaluate(context).to_s
          end
        end

        # @!visibility private
        class Concat < Function
          declare :concat

          def evaluate(context)
            string arguments.each_with_object(::String.new) { |argument, s|
              s << argument.evaluate(context.clone).to_s
            }
          end
        end

        # @!visibility private
        class StartsWith < Function
          declare :'starts-with'

          def evaluate(context)
            s1 = arguments[0].evaluate(context).to_s
            s2 = arguments[1].evaluate(context.clone).to_s
            return bool(true) if s2.empty?
            bool s1.start_with?(s2)
          end
        end

        # @!visibility private
        class Contains < Function
          declare :contains

          def evaluate(context)
            substr = arguments[1].evaluate(context).to_s
            return bool(true) if substr.empty?
            bool arguments[0].evaluate(context).to_s.include?(substr)
          end
        end

        # @!visibility private
        class SubstringBefore < Function
          declare :'substring-before'

          def evaluate(context)
            s1 = arguments[0].evaluate(context).to_s
            s2 = arguments[1].evaluate(context.clone).to_s
            return string '' if s2.empty?
            return string '' unless pos = s1.index(s2)
            string s1[0...pos]
          end
        end

        # @!visibility private
        class SubstringAfter < Function
          declare :'substring-after'

          def evaluate(context)
            s1 = arguments[0].evaluate(context).to_s
            s2 = arguments[1].evaluate(context.clone).to_s
            return string '' if s2.empty?
            return string '' unless pos = s1.rindex(s2)
            string s1[(pos + s2.length)..-1]
          end
        end

        # @!visibility private
        class Last < Function
          declare :last

          def evaluate(context)
            number context.size
          end
        end

        # @!visibility private
        class Position < Function
          declare :position

          def evaluate(context)
            number context.position
          end
        end
      end
    end
  end
end

module Gammo
  module CSSSelector
    module AST
      module Selector
        class Pseudo
          attr_accessor :value

          extend Subclassify

          def initialize(*args)
            @arguments = args
          end

          def match?(context)
            raise NotImplemented, "#match? must be implemented by sub class"
          end

          class Enabled < Pseudo
            declare :enabled

            def match?(context)
              # Return true if attributes do not have the key, or value is not
              # nil or the same with the key.
              !context.node.attributes.key?(:disabled) || (!context.node.attributes[:disabled].nil? &&
                                                           context.node.attributes[:disabled] != 'disabled')
            end
          end

          class Disabled < Pseudo
            declare :disabled

            def match?(context)
              # Return true if attributes have the key but nil, or value is the
              # same with the key.
              (context.node.attributes.key?(:disabled) && context.node.attributes[:disabled].nil?) ||
                context.node.attributes[:disabled] == 'disabled'
            end
          end

          class Checked < Pseudo
            declare :checked

            def match?(context)
              # Return true if attributes have the key but nil, or value is the
              # same with the key.
              (context.node.attributes.key?(:checked) && context.node.attributes[:checked].nil?) ||
                context.node.attributes[:checked] == 'checked'
            end
          end

          class Root < Pseudo
            declare :root

            def match?(context)
              # TODO:
              context.node.tag == Tags::Html
            end
          end

          class NthChild < Pseudo
            declare :'nth-child'

            InvalidExpression = Class.new(ArgumentError)

            CONVERT_TABLE = {
              'odd'  => ['2n+1'], #'2n+1',
              'even' => ['2n']
            }.freeze

            # TODO: AST-style
            def match?(context)
              exprs = @arguments[0]
              exprs = CONVERT_TABLE[exprs[0]] if CONVERT_TABLE[exprs[0]]

              case value = exprs.join
              when /\A\s*([\+\-])?([0-9]+)?\s*\z/ then
                # Raises an error if given value is not integer, but basically unreachable.
                context.position == Integer(value)
              when match = /\A\s*([\-\+])?([0-9]+)?(#{Parser::N})(?:\s*([\-\+])\s*([0-9]+))?\s*\z/
                d = (context.position - "#{$6}#{$7}".to_f) / "#{$1}#{$2 || 1}".to_f
                # Converts the value into integer in order to ignore float numbers.
                d >= 0 && d == d.to_i
              else
                raise InvalidExpression, 'invalid expression = %s' % value
              end
            end
          end
        end
      end
    end
  end
end

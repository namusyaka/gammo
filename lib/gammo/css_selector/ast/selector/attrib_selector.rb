module Gammo
  module CSSSelector
    module AST
      module Selector
        class Attrib
          attr_accessor :value

          extend Subclassify

          def initialize(key:, value:, namespace_prefix: nil)
            @key = key
            @value = value
            @namespace_prefix = namespace_prefix
          end

          def match?(context)
            raise NotImplemented, "#match? must be implemented by sub class"
          end

          private

          def attrib_value(node)
            node.attributes[@key.to_sym]
          end

          class Equal < Attrib
            declare :equal

            def match?(context)
              attrib_value(context.node) == @value
            end
          end

          class PrefixMatch < Attrib
            declare :prefix_match

            def match?(context)
              return false if !@value || @value.empty?
              return false unless val = attrib_value(context.node)
              val.start_with?(@value)
            end
          end

          class SuffixMatch < Attrib
            declare :suffix_match

            def match?(context)
              return false if !@value || @value.empty?
              return false unless val = attrib_value(context.node)
              val.end_with?(@value)
            end
          end

          class SubstringMatch < Attrib
            declare :substring_match

            def match?(context)
              return false if !@value || @value.empty?
              return false unless val = attrib_value(context.node)
              val.include?(@value)
            end
          end

          class DashMatch < Attrib
            declare :dash_match

            def match?(context)
              val = attrib_value(context.node) || ''
              val == @value || (val.start_with?(@value) && val[@value.length] == ?-)
            end
          end

          class Includes < Attrib
            declare :includes

            def match?(context)
              return false if !@value || @value.empty?
              val = attrib_value(context.node) || ''
              val == @value || (val.split(/\s/).include?(@value))
            end
          end
        end
      end
    end
  end
end

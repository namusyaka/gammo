require 'set'
require 'gammo/css_selector/node_set'
require 'gammo/modules/subclassify'

module Gammo
  module CSSSelector
    module AST
      # Class for representing combinator defined in the CSS selector specification.
      # @!visibility private
      class Combinator
        extend Subclassify

        def initialize(selector)
          @selector = selector
        end

        def evaluate(context)
          strain context, NodeSet.new
        end

        # Class for representing the descendant combinator.
        # @!visibility private
        class Descendant < Combinator
          declare :descendant

          def strain(context, node_set)
            @selector.search_descendant(context.dup, node_set)
            node_set
          end
        end

        # Class for representing the child combinator.
        # @!visibility private
        class Child < Combinator
          declare :child

          def strain(context, node_set)
            context.node.children.inject(0) do |i, child|
              next i unless child.kind_of?(Node::Element)
              i += 1
              node_set << child if @selector.match?(Context.new(node: child, position: i))
              i
            end
            node_set
          end
        end

        # Class for representing the next-sibling combinator.
        # @!visibility private
        class NextSibling < Combinator
          declare :next_sibling

          def strain(context, node_set)
            node = context.node
            context_position = context.position
            context_node = context.node
            while node = node.next_sibling
              context.position += 1
              context.node = node
              next unless node.is_a?(Node::Element)
              node_set << node if @selector.match?(context)
              break
            end
            context.position = context_position
            context.node = context_node
            node_set
          end
        end

        # Class for representing the subsequent-sibling combinator.
        # @!visibility private
        class SubsequentSibling < Combinator
          declare :subsequent_sibling

          def strain(context, node_set)
            node = context.node
            context_node = context.node
            position = context.position
            while node = node.next_sibling
              context.position += 1
              context.node = node
              node_set << node if @selector.match?(context)
            end
            context.position = position
            context.node = context_node
            node_set
          end
        end
      end
    end
  end
end

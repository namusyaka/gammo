require 'gammo/xpath/node_set'
require 'gammo/modules/subclassify'
require 'gammo/tags'

module Gammo
  module XPath
    module AST
      # Class for representing Axes.
      # https://www.w3.org/TR/1999/REC-xpath-19991116/#axes
      # @!visibility private
      class Axis
        attr_reader :node_test, :predicates

        extend Subclassify

        def initialize(node_test:, predicates: [])
          @node_test = node_test
          @predicates = Array(predicates)
        end

        def evaluate_context_node_with_node_set(context, context_node, node_set)
          context.position = 0
          # Strain nodes from context node for each axis.
          strain(context, context_node, node_set)
          # After straining try to filter by given predicates.
          predicates.each do |predicate|
            new_nodes = Gammo::XPath::NodeSet.new
            node_set.each_with_index do |node, i|
              context.node = node
              context.size = node_set.size
              context.position = i + 1
              new_nodes << node if predicate.evaluate(context)
            end
            node_set.replace(new_nodes)
          end
        end

        private

        class Ancestor < Axis
          declare :ancestor

          def strain(context, context_node, node_set)
            if context_node.instance_of?(Gammo::Attribute)
              context_node = context_node.owner_element
              node_set << context_node if node_test.match?(context_node)
            end
            node = context_node
            while node = node.parent
              node_set << node if node_test.match?(node)
            end
          end
        end

        class AncestorOrSelf < Axis
          declare :ancestor_or_self

          def strain(context, context_node, node_set)
            node_set << context_node if node_test.match?(context_node)
            if context_node.instance_of?(Gammo::Attribute)
              context_node = context_node.owner_element
              node_set << context_node if node_test.match?(context_node)
            end
            node = context_node
            while node = node.parent
              node_set << node if node_test.match?(node)
            end
          end
        end

        class Attribute < Axis
          declare :attribute

          def strain(context, context_node, node_set)
            if node_test.instance_of?(NodeTest::Name) && node_test.local != ?*
              attribute =
                if !node_test.namespace
                  context_node.get_attribute_node(node_test.local)
                else
                  # TODO: Test this properly.
                  context_node.get_attribute_node(node_test.local, namespace: node_test.namespace)
                end
              if attribute && attribute.namespace != 'http://www.w3.org/XML/1998/namespace'
                node_set << attribute if node_test.match?(attribute)
              end
              return
            end

            node_set.concat(context_node.attributes.select { |attribute|
              node_test.match?(attribute)
            })
          end
        end

        class Child < Axis
          declare :child

          def strain(context, context_node, node_set)
            return if context_node.instance_of?(Gammo::Attribute)
            node = context_node.first_child
            while node
              node_set << node if node_test.match?(node)
              node = node.next_sibling
            end
          end
        end

        class Descendant < Axis
          declare :descendant

          def strain(context, context_node, node_set)
            return if context_node.instance_of?(Gammo::Attribute)
            context_node.each_descendant do |node|
              node_set << node if node_test.match?(node)
            end
          end
        end

        class DescendantOrSelf < Axis
          declare :descendant_or_self

          def strain(context, context_node, node_set)
            node_set << context_node if node_test.match?(context_node)
            return if context_node.instance_of?(Gammo::Attribute)
            context_node.each_descendant do |node|
              node_set << node if node_test.match?(node)
            end
          end
        end

        class Following < Axis
          declare :following

          def strain(context, context_node, node_set)
            context_node = context_node.owner_element if context_node.instance_of?(Gammo::Attribute)
            while node = context_node.next_sibling
              each_following(node) do |node|
                node_set << node if node_test.match?(node)
              end
              break if context_node.parent.tag != Gammo::Tags::Html
            end
          end

          def each_following(context_node)
            stack = [context_node]
            until stack.empty?
              node = stack.pop
              yield node unless node == context_node
              stack << node.next_sibling if node.next_sibling
              stack << node.first_child if node.first_child
            end
          end
        end

        class FollowingSibling < Axis
          declare :following_sibling

          def strain(context, context_node, node_set)
            return if context_node.instance_of?(Gammo::Attribute)
            node = context_node
            while node = node.next_sibling
              node_set << node if node_test.match?(node)
            end
          end
        end

        class Namespace < Axis
          declare :namespace

          def strain(context, context_node, node_set)
            # Not implemented
          end
        end

        class Parent < Axis
          declare :parent

          def strain(context, context_node, node_set)
            context_node = context_node.instance_of?(Gammo::Attribute) ?
              context_node.owner_element : context_node.parent
            node_set << context_node if node_test.match?(context_node)
          end
        end

        class Preceding < Axis
          declare :preceding

          def strain(context, context_node, node_set)
            context_node = context_node.owner_element if context_node.instance_of?(Gammo::Attribute)
            each_preceding(context_node) do |node|
              node_set << node if node_test.match?(node)
            end
          end

          private

          def each_preceding(context_node)
            node = context_node
            while parent = node.parent
              while node = node.previous_sibling
                yield node
                break if node == parent
              end
              node = parent
            end
          end
        end

        class PrecedingSibling < Axis
          declare :preceding_sibling

          def strain(context, context_node, node_set)
            return if context_node.instance_of?(Gammo::Attribute)
            node = context_node
            while node = node.previous_sibling
              node_set << node if node_test.match?(node)
            end
          end
        end

        class Self < Axis
          declare :self

          def strain(context, context_node, node_set)
            node_set << context_node if node_test.match?(context_node)
          end
        end
      end
    end
  end
end

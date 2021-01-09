require 'set'
require 'delegate'
require 'gammo/modules/subclassify'
require 'gammo/css_selector/node_set'
require 'gammo/css_selector/ast/selector/id_selector'
require 'gammo/css_selector/ast/selector/attrib_selector'
require 'gammo/css_selector/ast/selector/class_selector'
require 'gammo/css_selector/ast/selector/pseudo_class'
require 'gammo/css_selector/ast/selector/negation'

module Gammo
  module CSSSelector
    module AST
      # Class for representing selectors group defined in the CSS selector specification.
      # @!visibility private
      class SelectorsGroup < DelegateClass(Array)
        def initialize
          super([])
        end

        def evaluate(context)
          map { |selector| selector.evaluate(context.dup) }.inject(:+)
        end
      end

      # @!visibility private
      module Selector
        class Base
          attr_accessor :selectors

          def initialize(namespace_prefix: nil, selectors: [])
            @namespace_prefix = namespace_prefix
            @selectors = selectors
            @combinations = []
          end

          def evaluate(context)
            node_set = NodeSet.new
            search_descendant(context, node_set)

            @combinations.inject(node_set) do |ns, combination|
              duplicates = Set.new
              ns.each_with_object(NodeSet.new) do |node, ret|
                context.node = node
                # TODO: #concat
                combination.evaluate(context).each do |matched|
                  ret << matched if duplicates.add?(matched)
                end
              end
            end
          end

          def search_descendant(context, node_set)
            queue = [context]
            until queue.empty?
              current_context = queue.shift
              node_set << current_context.node if match?(current_context)
              current_context.node.children.inject(0) do |i, child|
                next i unless child.kind_of?(Node::Element)
                i += 1
                queue << Context.new(node: child, position: i)
                i
              end
            end
          end

          def combine(selector)
            @combinations << selector
          end

          def match?(context)
            @selectors.all? { |matcher| matcher.match?(context) }
          end
        end

        class Universal < Base
          def initialize(**opts)
            super
          end

          def match?(context)
            super && context.node.kind_of?(Gammo::Node::Element)
          end
        end

        class Type < Base
          def initialize(element_name:, **opts)
            @element_name = element_name
            super(**opts)
          end

          def match?(context)
            return false if @element_name != context.node.tag
            super
          end
        end
      end
    end
  end
end

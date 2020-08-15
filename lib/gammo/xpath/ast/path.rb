require 'gammo/xpath/node_set'

module Gammo
  module XPath
    module AST
      # @!visibility private
      class Filter
        attr_reader :expr, :predicates

        def initialize(expr, predicates: [])
          @expr = expr
          @predicates = predicates
        end

        def evaluate(context)
          value = expr.evaluate(context).to_node_set_value(context)
          node_set = value.to_node_set(context)
          predicates.each do |predicate|
            new_node_set = NodeSet.new
            node_set.each do |node|
              context.node = node
              context.position += 1
              new_node_set << node if predicate.evaluate(context)
            end
            node_set.replace(new_node_set)
          end
          value
        end
      end

      # @!visibility private
      class LocationPath
        attr_accessor :absolute, :steps

        def initialize
          @absolute = false
          @steps    = []
        end

        def evaluate(context)
          # If this location path needs to be absolute and given context
          # is not document, this gets owner document node at first.
          cloned = context.dup
          context_node = context.node
          context_node = context_node.owner_document if absolute && !context_node.document?

          node_set = NodeSet.new
          node_set << context_node
          evaluate_with_node_set(cloned, node_set)
          Value::NodeSet.new(node_set)
        end

        def insert_first_step(step)
          steps.unshift(step)
        end

        def append_step(step)
          steps << step
        end

        def evaluate_with_node_set(context, node_set)
          steps.each do |step|
            duplicates = Set.new([])
            new_nodes = NodeSet.new
            includes_duplicate_nodes = (!node_set.subtrees_are_disjoint? || (!step.instance_of?(Axis::Child) && !step.instance_of?(Axis::Self) && !step.instance_of?(Axis::Descendant) && !step.instance_of?(Axis::DescendantOrSelf) && !step.instance_of?(Axis::Attribute)))

            if node_set.subtrees_are_disjoint? && (step.instance_of?(Axis::Child) || step.instance_of?(Axis::Self))
              new_nodes.disjoint = true
            end

            node_set.dup.each_with_index do |node, i|
              matches = NodeSet.new
              step.evaluate_context_node_with_node_set(context, node, matches)
              matches.each do |node|
                new_nodes << node if !includes_duplicate_nodes || duplicates.add?(node)
              end
            end
            node_set.replace(new_nodes)
          end
        end
      end

      # @!visibility private
      class Path
        attr_reader :filter, :location_path

        def initialize(filter, location_path)
          @filter = filter
          @location_path = location_path
        end

        def evaluate(context)
          node_set = filter.evaluate(context).to_node_set(context)
          location_path.evaluate_with_node_set(context, node_set)
          Value::NodeSet.new(node_set)
        end
      end
    end
  end
end

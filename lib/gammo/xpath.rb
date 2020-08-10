require 'gammo/xpath/parser'
require 'gammo/xpath/context'

module Gammo
  module XPath
    # Result types
    # But features related to snapshot and ordered node are not supported.
    # TODO: Support official result types.
    #   - ORDERED_NODE_ITERATOR_TYPE
    #   - UNORDERED_NODE_SNAPSHOT_TYPE
    #   - ORDERED_NODE_SNAPSHOT_TYPE
    ANY_TYPE                     = 0
    NUMBER_TYPE                  = 1
    STRING_TYPE                  = 2
    BOOLEAN_TYPE                 = 3
    UNORDERED_NODE_ITERATOR_TYPE = 4
    ANY_UNORDERED_NODE_TYPE      = 8
    FIRST_ORDERED_NODE_TYPE      = 9

    # Class for traversing DOM tree built by Gammo::Parser by a given expression.
    # @!visibility private
    class Traverser
      # Constructs an instance of Gammo::XPath::Traverser.
      # @param [String] expr
      # @param [Integer] result_type
      # @!visibility private
      def initialize(expr:, result_type:)
        @expr = expr
        @result_type = result_type
      end

      # Evaluates a given expression and returns value according to the
      # result type.
      # @param [Gammo::XPath::Context] context
      # @return [String, Integer, TrueClass, FalseClass, Gammo::XPath::NodeSet]
      # @!visibility private
      def evaluate(context)
        convert_value context, Parser.new(@expr).parse.evaluate(context)
      end

      private

      # @!visibility private
      def convert_value(context, value)
        case @result_type
        when ANY_TYPE then return value.value
        when NUMBER_TYPE then return value.to_number
        when STRING_TYPE then return value.to_s
        when BOOLEAN_TYPE then return value.to_bool
        when UNORDERED_NODE_ITERATOR_TYPE
          fail TypeError, 'the result is not a node set' unless value.node_set?
          value.to_node_set(context)
        when ANY_UNORDERED_NODE_TYPE, FIRST_UNORDERED_NODE_TYPE
          fail TypeError, 'the result is not a node set' unless value.node_set?
          value.to_node_set(context).first
        end
      end
    end

    # Traverses DOM tree by a given expression, and returns a result according
    # to the result type.
    # @param [String] expr
    # @param [Hash{Symbol => String, Symbol, Integer, TrueClass, FalseClass, #call}] variables
    # @param [Integer] result_type
    # @param [Gammo::Node] context_node
    # @return [String, Integer, TrueClass, FalseClass, Gammo::XPath::NodeSet]
    def xpath(expr, variables: {}, result_type: UNORDERED_NODE_ITERATOR_TYPE, context_node: self)
      Traverser.new(
        expr: expr,
        result_type: result_type,
      ).evaluate(Context.new(node: context_node, variables: variables))
    end
  end
end

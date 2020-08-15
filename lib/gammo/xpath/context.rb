module Gammo
  module XPath
    # Class for representing a context
    # https://www.w3.org/TR/1999/REC-xpath-19991116/#section-Introduction
    # @!visibility private
    class Context
      # Defines context node, context position and context size.
      attr_accessor :node, :position, :size

      # Variables to be expanded in placeholders.
      attr_reader :variables

      # @param [Gammo::Node] node
      # @param [Hash{Symbol => String, Symbol, Integer, TrueClass, FalseClass, #call}] variables
      def initialize(node:, variables: {})
        @node      = node
        @position  = 1
        @size      = 1
        @variables = variables
      end
    end
  end
end

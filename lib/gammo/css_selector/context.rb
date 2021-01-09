module Gammo
  module CSSSelector
    # Class for representing a context at traversing DOM.
    # @!visibility private
    class Context
      # Defines context node, context position and context size.
      attr_accessor :node, :position, :size

      # @param [Gammo::Node] node
      # @param [Integer] position
      def initialize(node:, position: 1)
        @node     = node
        @position = position
      end
    end
  end
end

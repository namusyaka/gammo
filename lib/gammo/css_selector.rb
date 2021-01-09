require 'gammo/css_selector/context'
require 'gammo/css_selector/parser'

module Gammo
  module CSSSelector
    # Class for traversing DOM tree built by Gammo::Parser by a given expresison.
    # @!visibility private
    class Traverser
      # Constructs an instance of Gammo::CSSSelector::Traverser.
      # @param [String] expr
      # @!visibility private
      def initialize(expr)
        @expr = expr
      end

      # Evaluates a given expression and returns a node set.
      # @param [Gammo::CSSSelector::Context] context
      # @return [Gammo::CSSSelector::NodeSet]
      # @!visibility private
      def evaluate(context)
        Parser.new(@expr).parse.evaluate(context)
      end
    end

    # Traverses DOM tree by a given expression, and returns a node set.
    # @param [String] expr
    # @return [Gammo::CSSSelector::NodeSet]
    def query_selector_all(expr)
      Traverser.new(expr).evaluate(Context.new(node: self))
    end
    alias_method :css, :query_selector_all
  end
end

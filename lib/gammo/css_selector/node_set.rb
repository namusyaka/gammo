require 'forwardable'

module Gammo
  module CSSSelector
    # Class for representing node set
    # Especially this class will be used for expressing the result of evaluation
    # of a given CSS selector.
    class NodeSet
      extend Forwardable
      def_delegators :@nodes, :<<, :each, :each_with_object, :each_with_index, :length, :size,
        :map, :[], :first, :last, :concat, :all?, :any?, :empty?

      attr_reader :nodes

      attr_accessor :disjoint

      # Constructs a new instance of Gammo::CSSSelector::NodeSet.
      # @return [Gammo::CSSSelector::NodeSet]
      def initialize
        @nodes    = []
        @disjoint = false
      end

      # Replaces self nodes with an other node set destructively.
      # @param [Gammo::CSSSelector::NodeSet] other
      # @return [Gammo::CSSSelector::NodeSet]
      # @!visibility private
      def replace(other)
        @nodes.replace(other.nodes)
      end

      def +(other)
        ns = NodeSet.new
        ns.nodes.concat(@nodes | other.nodes)
        ns
      end

      # @!visibility private
      def to_s
        first.to_s
      end
    end
  end
end

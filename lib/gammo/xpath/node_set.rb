require 'forwardable'

module Gammo
  module XPath
    # Class for representing node set
    # Especially this class will be used for expressing the result of evaluation
    # of a given XPath expressions.
    class NodeSet
      extend Forwardable
      def_delegators :@nodes, :<<, :each, :each_with_index, :length, :size,
        :map, :[], :first, :last, :concat, :all?, :any?, :empty?

      attr_reader :nodes

      attr_accessor :disjoint

      # Constructs a new instance of Gammo::XPath::NodeSet.
      # @return [Gammo::XPath::NodeSet]
      def initialize
        @nodes    = []
        @disjoint = false
      end

      # Replaces self nodes with an other node set destructively.
      # @param [Gammo::XPath::NodeSet] other
      # @return [Gammo::XPath::NodeSet]
      # @!visibility private
      def replace(other)
        @nodes.replace(other.nodes)
      end

      # @!visibility private
      def subtrees_are_disjoint?
        !!@disjoint
      end

      # @!visibility private
      def to_s
        first.to_s
      end
    end
  end
end

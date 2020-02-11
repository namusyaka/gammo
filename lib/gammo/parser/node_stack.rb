require 'delegate'

module Gammo
  class Parser
    # @!visibility private
    class NodeStack < DelegateClass(Array)
      def initialize(array)
        super(array)
      end

      def slice(*args)
        self.class.new(super)
      end

      def reverse_each_with_index
        len = length - 1
        self.reverse.each_with_index do |elm, index|
          yield(elm, len)
          len -= 1
        end
      end
    end
  end
end

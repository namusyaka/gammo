require 'gammo/xpath/errors'

module Gammo
  module XPath
    module AST
      # Class for making subclass declarable/fetchable
      # @!visibility private
      module Subclassify
        # @!visibility private
        def map
          @map ||= {}
        end

        # @!visibility private
        def declare(key)
          look_for_superclass.map[key] = self
        end

        # @!visibility private
        def fetch(key)
          fail NotFoundError, "%s not found" % key unless klass = map[key.to_sym]
          klass
        end

        private

        # @!visibility private
        def look_for_superclass
          klass = superclass
          ancestors.find { |ancestor| ancestor == klass }
        end
      end
    end
  end
end

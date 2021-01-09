module Gammo
  module CSSSelector
    module AST
      module Selector
        class Negation
          attr_accessor :value

          extend Subclassify

          def initialize(*args)
            @arguments = args
          end

          def match?(context)
            !@arguments[0].match?(context)
          end
        end
      end
    end
  end
end

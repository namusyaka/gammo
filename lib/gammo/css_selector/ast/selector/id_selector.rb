module Gammo
  module CSSSelector
    module AST
      module Selector
        class ID
          def initialize(id)
            @id = id
          end

          def match?(context)
            return false unless val = context.node.attributes[:id]
            val == @id || (val.split(/\s/).include?(@id))
          end
        end
      end
    end
  end
end

module Gammo
  module CSSSelector
    module AST
      module Selector
        class Class
          def initialize(class_name)
            @class_name = class_name
          end

          def match?(context)
            # TODO: prefer using class_name
            return false unless val = context.node.attributes[:class]
            val == @class_name || (val.split(/\s/).include?(@class_name))
          end
        end
      end
    end
  end
end

require 'gammo/modules/subclassify'
require 'gammo/xpath/errors'

module Gammo
  module XPath
    module AST
      # @!visibility private
      class NodeTest
        extend Subclassify

        def match?(node)
          fail NotImplementedError, "#match must be implemented"
        end

        class Name < NodeTest
          declare :name

          attr_reader :local, :namespace

          def initialize(local: nil, namespace: nil)
            @local = local
            @namespace = namespace
          end

          def xml_namespace?
            namespace == 'http://www.w3.org/XML/1998/namespace'
          end

          def match?(node)
            return false unless node
            return false if xml_namespace?
            return !namespace || namespace == node.namespace if local == ?*
            # TODO: investigate
            if node.instance_of?(Gammo::Attribute)
              # TODO: need to work
              node.key == local && node.namespace == namespace
            else
              if document = node.owner_document
                # TODO: ignoring ascii case
                return node.tag == local && (!namespace || node.namespace == namespace) if node.instance_of?(Gammo::Node::Element)
                return node.tag == local && node.namespace == namespace && namespace
              end
              node.tag == local && node.namespace == namespace
            end
          end
        end

        # @!visibility private
        class Any < NodeTest
          declare :node

          def match?(node)
            true
          end
        end

        # @!visibility private
        class Text < NodeTest
          declare :text

          def match?(node)
            node.instance_of?(Gammo::Node::Text)
          end
        end

        # @!visibility private
        class Comment < NodeTest
          declare :comment

          def match?(node)
            node.instance_of?(Gammo::Node::Comment)
          end
        end

        # @!visibility private
        class ProcessingInstruction < NodeTest
          declare :'processing-instruction'

          def initialize
            fail NotImplementedError, 'processing-instruction is not supported'
          end
        end
      end
    end
  end
end

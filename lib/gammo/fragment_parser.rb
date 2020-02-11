require 'gammo/parser'

module Gammo
  # Class for parsing a fragment of an HTML input and building an HTML tree.
  class FragmentParser < ::Gammo::Parser
    # Constructs a parser instance for fragment parsing algorithm. 
    # @see https://html.spec.whatwg.org/multipage/parsing.html#html-fragment-parsing-algorithm
    # @param [String] input
    # @param [Gammo::Node] context
    # @raise [Gammo::ParseError] raises if context is not valid.
    # @return Gammo::FragmentParser
    def initialize(input, context:, **options)
      validate_context(context)
      super(input, context: context, **options)
      @root          = Node::Element.new(tag: Tags::Html, data: Tags::Html.to_s)
      @tokenizer     = Tokenizer.new(input, context: !context.namespace && context.tag.to_s)
      @open_elements = NodeStack.new([@root])
      document.append_child(@root)
      template_stack << InTemplate if context.tag == Tags::Template
      reset_insertion_mode
      while context
        if context.instance_of?(Node::Element) && context.tag == Tags::Form
          @form = context
          break
        end
        context = context.parent
      end
    end

    # Parses a fragment of the current input and builds HTML tree from it.
    # @raise [Gammo::ParseError] Raised if the parser gets error while parsing.
    # @return [Array<Gammo::Node>]
    def parse
      super
      parent     = context ? @root : document
      child      = parent.first_child
      collection = []
      while child
        node = child.next_sibling
        parent.remove_child(child)
        collection << child
        child = node
      end
      collection
    end

    # Always returns true.
    # @return [TrueClass]
    # @!visibility private
    def fragment?
      true
    end

    # Validates given context. Raises {Gammo::ParseError} if context is not
    # {Gammo::Node}.
    # @param [Gammo::Node] context
    # @raise [Gammo::ParseError]
    def validate_context(context)
      fail ParseError, 'given non-element node in "context"' unless context.instance_of?(Node::Element)
      unless context.tag == Tags.lookup(context.data)
        fail ParseError, "inconsistent context node, tag = #{context.tag}, data = #{Tags.lookup(context.data)}"
      end
    end
  end
end

require 'gammo/xpath'
require 'gammo/attributes'

module Gammo
  # Class for representing Node.
  # https://html.spec.whatwg.org/multipage/parsing.html#tokenization
  class Node
    # Raised if uncaught node is given for particular operations.
    # @!visibility private
    UncaughtTypeError = Class.new(ArgumentError)

    # Raised if anything goes wrong on hierarchy while node operations.
    # @!visibility private
    HierarchyRequestError = Class.new(ArgumentError)

    # `parent` is the pointer for the parent node.
    attr_accessor :parent

    # `first_child` and `last_child` are pointers for the first and the last nodes.
    attr_accessor :first_child, :last_child

    # `previous_sibling` and `next_sibling` are pointers for the previous and next sibling nodes.
    attr_accessor :previous_sibling, :next_sibling

    # Properties required to represent node.
    attr_accessor :tag, :data, :namespace

    # Reader for attributes associated with this node.
    attr_reader :attributes

    # Represents the error token.
    Error = Class.new(Node)

    def text_content
      nil
    end

    def get_attribute_node(key, namespace: nil)
      attributes.find { |attr| attr.key == key && attr.namespace == namespace }
    end

    def each_descendant
      stack = [self]
      until stack.empty?
        node = stack.pop
        yield node unless node == self
        stack << node.next_sibling if node != self && node.next_sibling
        stack << node.first_child if node.first_child
      end
    end

    # Represents the text token.
    class Text < Node
      alias_method :text_content, :data
      alias_method :to_s, :text_content
    end

    # Represents the root document token.
    class Document < Node
      include XPath
    end

    # Represents the element token including start, end and self-closing token.
    class Element < Node

      # TODO: The current innerText() implementation does not conform to WHATWG spec.
      # https://html.spec.whatwg.org/multipage/dom.html#the-innertext-idl-attribute
      def inner_text
        text = ''
        each_descendant { |node| text << node.data if node.instance_of?(Text) }
        text
      end

      def to_s
        s = "<#{tag}"
        attrs = attributes_to_string
        s << ' ' unless attrs.empty?
        s << "#{attrs}>"
      end

      private

      def attributes_to_string
        attributes.each_with_object([]) { |attr, attrs|
          attrs << "#{attr.key}=#{attr.value}"
        }.join(?\s)
      end
    end

    # Represents the comment token like "<!-- foo -->".
    Comment = Class.new(Node) 

    # Represents the document type token.
    Doctype = Class.new(Node) 

    # Represents the marker defined in 12.2.4.3.
    # https://html.spec.whatwg.org/multipage/parsing.html#tokenization
    ScopeMarker = Class.new(Node)

    # Default scope marker is inserted when entering applet,
    # object, marquee, template, td, th, and caption elements, and are used
    # to prevent formatting from "leaking" into applet, object, marquee,
    # template, td, th, and caption elements"
    DEFAULT_SCOPE_MARKER = Node::ScopeMarker.new

    # Constructs a node which represents HTML element node.
    # @param [String] tag
    # @param [String] data
    # @param [String, NilClass] namespace
    # @param [Gammo::Attributes] attributes
    # @return [Gammo::Node]
    def initialize(tag: nil, data: nil, namespace: nil, attributes: Attributes.new([]))
      @tag        = tag
      @data       = data
      @namespace  = namespace
      @attributes = Attributes.new(attributes, owner_element: self)
    end

    # Sets attributes in self.
    # @param [Gammo::Attributes] attrs
    def attributes=(attrs)
      cloned = attrs.dup
      cloned.each { |attr| attr.owner_element = self }
      @attributes = cloned
    end

    # Inserts a node before a reference node as a child of a specified parent node.
    # @param [Gammo::Node] node
    # @param [Gammo::Node] ref
    # @raise [HierarchyRequestError] Raised if given node is already attached to the self node.
    # @return [Gammo::Node] A node inserted before the reference node.
    def insert_before(node, ref)
      raise HierarchyRequestError,
        'insert_before called for an attached child node' if attached?(node)
      if ref
        previous_sibling, next_sibling = ref.previous_sibling, ref
      else
        previous_sibling = last_child
      end
      if previous_sibling
        previous_sibling.next_sibling = node
      else
        @first_child = node
      end
      if next_sibling
        next_sibling.previous_sibling = node
      else
        @last_child = node
      end
      node.parent = self
      node.previous_sibling = previous_sibling
      node.next_sibling = next_sibling
      node
    end

    # Appends given `child` into self node.
    # @param [Gammo::Node] child
    # @raise [HierarchyRequestError] Raised if given node is already attached to the self node.
    # @return [Gammo::Node] A node appended into the self node.
    def append_child(child)
      raise HierarchyRequestError,
        'append_child called for an attached child node' if attached?(child)
      if last = last_child
        last.next_sibling = child
      else
        @first_child = child
      end
      @last_child = child
      child.parent = self
      child.previous_sibling = last
      child
    end

    # Removes given `child` from self node.
    # @param [Gammo::Node] child
    # @raise [UncaughtTypeError] Raised unless given node is not child of the self node.
    # @return [Gammo::Node] A node removed from the self node.
    def remove_child(child)
      raise UncaughtTypeError,
        'remove_child called for a non-child node' unless child?(child)
      @first_child = child.next_sibling if first_child == child
      child.next_sibling.previous_sibling = child.previous_sibling if child.next_sibling
      @last_child = child.previous_sibling if last_child == child
      child.previous_sibling.next_sibling = child.next_sibling if child.previous_sibling
      child.parent = child.previous_sibling = child.next_sibling = nil
      child
    end

    # Clones self into a new node.
    # @return [Gammo::Node]
    # @!visibility private
    def clone
      self.class.new(tag: self.tag, data: self.data, attributes: self.attributes.dup)
    end

    # @!visibility private
    def to_h
      {
        tag: tag,
        data: data,
        attributes: attributes,
        type: self.class
      }
    end

    # Select all nodes whose the evaluation of a given block is true.
    def select(&block)
      nodes = []
      stack = [self]
      until stack.empty?
        node = stack.pop
        nodes << node if block.call(node)
        stack << node.next_sibling if node.next_sibling
        stack << node.first_child if node.first_child
      end
      nodes
    end

    def children
      ret = []
      child = first_child
      while child
        ret << child
        child = child.next_sibling
      end
      ret
    end

    def owner_document
      node = self
      node = node.parent until node.document?
      node
    end

    def document?
      self.instance_of?(Document)
    end

    private

    # @!visibility private
    def attached?(node)
      node.parent || node.previous_sibling || node.next_sibling
    end

    # @!visibility private
    def child?(node)
      node.parent == self
    end
  end
end

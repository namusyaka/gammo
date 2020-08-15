module Gammo
  # Class for representing an attribute.
  class Attribute
    attr_accessor :key, :value, :namespace

    # @!visibility private
    attr_accessor :owner_element

    # Constructs an attribute with the key-value pair.
    # @param [String] key
    # @param [String] value
    # @param [String] namespace
    # @param [Gammo::Element] owner_element
    # @return [Attribute]
    def initialize(key:, value:, namespace: nil, owner_element: nil)
      @key           = key
      @value         = value
      @namespace     = namespace
      @owner_element = owner_element
    end

    def to_s
      "<Gammo::Attribute #{key}='#{value}'>"
    end
  end
end

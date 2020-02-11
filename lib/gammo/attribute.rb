module Gammo
  # Class for representing an attribute.
  class Attribute
    attr_accessor :key, :value, :namespace

    # Constructs an attribute with the key-value pair.
    # @param [String] key
    # @param [String] value
    # @param [String] namespace
    # @return [Attribute]
    def initialize(key:, value:, namespace: nil)
      @key       = key
      @value     = value
      @namespace = namespace
    end
  end
end

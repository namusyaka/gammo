require 'delegate'

module Gammo
  # Class for representing attributes.
  class Attributes < DelegateClass(Array)
    attr_accessor :owner_element

    def initialize(array, owner_element: nil)
      super(array)
      array.each { |attr| attr.owner_element = owner_element }
      @owner_element = owner_element
      @attributes_hash = attributes_to_hash(array)
    end

    def <<(attr)
      super
      @attributes_hash[attr.key] = attr.value
    end

    def [](key)
      @attributes_hash[key.to_s]
    end

    def []=(key, value)
      self << Attribute.new(key: key.to_s, value: value, owner_element: owner_element)
    end

    def prepend(*attrs)
      prepended = super
      attrs.each { |attr| @attributes_hash[attr.key.to_s] = attr.value }
      prepended
    end
    alias_method :unshift, :prepend

    def shift(n = nil)
      original = self.dup
      ret = n ? super : super()
      (original - self).each { |attr| @attributes_hash.delete(attr.key.to_s) }
      ret
    end

    def pop(n = nil)
      original = self.dup
      ret = n ? super : super()
      (original - self).each { |attr| @attributes_hash.delete(attr.key.to_s) }
      ret
    end

    def append(*attrs)
      super
      attrs.each { |attr| @attributes_hash[attr.key.to_s] = attr.value }
    end
    alias_method :push, :append

    def delete(attr)
      deleted = super
      @attributes_hash.delete(deleted.key) if deleted
      deleted
    end

    def reject!
      original = self.dup
      rejected = super
      (original - self).each { |attr| @attributes_hash.delete(attr.key.to_s) }
      rejected
    end

    def delete_if
      original = self.dup
      super
      (original - self).each { |attr| @attributes_hash.delete(attr.key.to_s) }
      self
    end

    def delete_at(pos)
      deleted = super
      deleted.each { |attr| @attributes_hash.delete(attr.key.to_s) }
      deleted
    end

    def to_h
      @attributes_hash.dup
    end

    def to_s
      @attributes_hash.to_s
    end

    private

    def attributes_to_hash(attrs)
      attrs.each_with_object({}) { |attr, h| h[attr.key.to_s] = attr.value }
    end
  end
end

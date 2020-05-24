require 'delegate'

module Gammo
  # Class for representing attributes.
  class Attributes < DelegateClass(Array)
    def initialize(array)
      super(array)
      @attributes_hash = attributes_to_hash(array)
    end

    def <<(attr)
      super
      @attributes_hash[attr.key] = attr.value
    end

    def [](key)
      @attributes_hash[key]
    end

    def []=(key, value)
      self << Attribute.new(key: key, value: value)
    end

    def prepend(*attrs)
      prepended = super
      attrs.each { |attr| @attributes_hash[attr.key] = attr.value }
      prepended
    end
    alias_method :unshift, :prepend

    def shift(n = nil)
      original = self.dup
      ret = n ? super : super()
      (original - self).each { |attr| @attributes_hash.delete(attr.key) }
      ret
    end

    def pop(n = nil)
      original = self.dup
      ret = n ? super : super()
      (original - self).each { |attr| @attributes_hash.delete(attr.key) }
      ret
    end

    def append(*attrs)
      super
      attrs.each { |attr| @attributes_hash[attr.key] = attr.value }
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
      (original - self).each { |attr| @attributes_hash.delete(attr.key) }
      rejected
    end

    def delete_if
      original = self.dup
      super
      (original - self).each { |attr| @attributes_hash.delete(attr.key) }
      self
    end

    def delete_at(pos)
      deleted = super
      deleted.each { |attr| @attributes_hash.delete(attr.key) }
      deleted
    end

    private

    def attributes_to_hash(attrs)
      attrs.each_with_object({}) { |attr, h| h[attr.key] = attr.value }
    end
  end
end

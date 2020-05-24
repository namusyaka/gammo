require "test_helper"

class AttributesTest < Test::Unit::TestCase

  def setup
    @attributes = Gammo::Attributes.new([Gammo::Attribute.new(key: :a, value: :b)])
  end

  def test_reference
    assert_equal :b, @attributes[:a]
  end

  def test_setter
    @attributes[:c] = :d
    assert_equal :d, @attributes[:c]
  end

  def test_append
    @attributes.append(Gammo::Attribute.new(key: :c, value: :d)) 
    assert_equal :d, @attributes[:c]
  end

  def test_prepend
    ret = @attributes.prepend(Gammo::Attribute.new(key: :c, value: :d), Gammo::Attribute.new(key: :e, value: :f))
    assert_equal @attributes, ret
    assert_equal :d, @attributes[:c]
    assert_equal :f, @attributes[:e]
  end

  def test_pop
    @attributes << Gammo::Attribute.new(key: :c, value: :d)
    last = @attributes.last
    ret = @attributes.pop
    assert_nil @attributes[:c]
    assert_equal last, ret
    assert_equal 1, @attributes.length
  end

  def test_shift
    @attributes << Gammo::Attribute.new(key: :c, value: :d)
    first = @attributes.first
    ret = @attributes.shift
    assert_nil @attributes[:a]
    assert_equal first, ret
    assert_equal 1, @attributes.length
  end

  def test_delete
    first = @attributes.first
    assert_equal first, @attributes.delete(first)
    assert_equal 0, @attributes.length
  end

  def test_delete_if
    ret = @attributes.delete_if { |x| x.key == :a }
    assert_equal 0, @attributes.length
    assert_equal @attributes, ret
  end

  def test_reject!
    ret = @attributes.reject! { |x| x.key == :e }
    assert_nil ret
    ret = @attributes.reject! { |x| x.key == :a }
    assert_equal 0, @attributes.length
    assert_equal @attributes, ret
  end
end

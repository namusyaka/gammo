require "test_helper"

class AttributesTest < Test::Unit::TestCase
  setup do
    @attributes = Gammo::Attributes.new([Gammo::Attribute.new(key: :a, value: :b)])
  end

  test 'reference' do
    assert_equal :b, @attributes[:a]
  end

  test 'setter' do
    @attributes[:c] = :d
    assert_equal :d, @attributes[:c]
  end

  test 'append' do
    @attributes.append(Gammo::Attribute.new(key: :c, value: :d)) 
    assert_equal :d, @attributes[:c]
  end

  test 'prepend' do
    ret = @attributes.prepend(Gammo::Attribute.new(key: :c, value: :d), Gammo::Attribute.new(key: :e, value: :f))
    assert_equal @attributes, ret
    assert_equal :d, @attributes[:c]
    assert_equal :f, @attributes[:e]
  end

  test 'pop' do
    @attributes << Gammo::Attribute.new(key: :c, value: :d)
    last = @attributes.last
    ret = @attributes.pop
    assert_nil @attributes[:c]
    assert_equal last, ret
    assert_equal 1, @attributes.length
  end

  test 'shift' do
    @attributes << Gammo::Attribute.new(key: :c, value: :d)
    first = @attributes.first
    ret = @attributes.shift
    assert_nil @attributes[:a]
    assert_equal first, ret
    assert_equal 1, @attributes.length
  end

  test 'delete' do
    first = @attributes.first
    assert_equal first, @attributes.delete(first)
    assert_equal 0, @attributes.length
  end

  test 'delete_if' do
    ret = @attributes.delete_if { |x| x.key == :a }
    assert_equal 0, @attributes.length
    assert_equal @attributes, ret
  end

  test 'reject!' do
    ret = @attributes.reject! { |x| x.key == :e }
    assert_nil ret
    ret = @attributes.reject! { |x| x.key == :a }
    assert_equal 0, @attributes.length
    assert_equal @attributes, ret
  end
end

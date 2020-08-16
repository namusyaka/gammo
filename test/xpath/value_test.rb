$LOAD_PATH.unshift  File.join(__dir__, '..')
require 'test_helper'

class XPath::ValueTest < Test::Unit::TestCase
  setup do
    @doc = Gammo.new('').parse
  end

  test '#evaluate' do
    b = Gammo::XPath::AST::Value::Boolean.new(true)
    assert_equal b, b.evaluate(nil)
  end

  test 'node set' do
    ns = Gammo::XPath::AST::Value::NodeSet.new([])
    assert_equal false, ns.to_bool
    assert_equal 0, ns.to_number
    assert_equal '', ns.to_s
    assert_equal true, ns.node_set?
    refute ns.bool?
    refute ns.number?
    refute ns.string?
  end

  test 'nodeset with node' do
    ns = Gammo::XPath::NodeSet.new
    ns << Gammo::Node::Element.new(tag: 'a', data: 'hello')
    ns << Gammo::Node::Element.new(tag: 'a', data: 'world')
    nsv = Gammo::XPath::AST::Value::NodeSet.new(ns)
    assert_equal true, nsv.to_bool
    assert_equal 0, nsv.to_number
    assert_equal '<a>', nsv.to_s
    assert_equal true, nsv.node_set?
    refute nsv.bool?
    refute nsv.number?
    refute nsv.string?
  end

  test 'boolean' do
    b = Gammo::XPath::AST::Value::Boolean.new(true)
    assert_equal 'true', b.to_s
    assert_equal 1, b.to_number
    assert_equal true, b.to_bool
    assert b.bool?
    refute b.node_set?
    refute b.number?
    refute b.string?
  end

  test 'string' do
    s = Gammo::XPath::AST::Value::String.new('hello')
    assert_equal 'hello', s.to_s
    assert_equal 0, s.to_number
    assert_equal true, s.to_bool
    assert s.string?
    refute s.node_set?
    refute s.number?
    refute s.bool?
  end

  test 'string with empty' do
    s = Gammo::XPath::AST::Value::String.new('')
    assert_equal '', s.to_s
    assert_equal 0, s.to_number
    assert_equal false, s.to_bool
    assert s.string?
    refute s.node_set?
    refute s.number?
    refute s.bool?
  end

  test 'number' do
    n = Gammo::XPath::AST::Value::Number.new(1)
    assert_equal '1', n.to_s
    assert_equal 1, n.to_number
    assert_equal true, n.to_bool
    assert n.number?
    refute n.string?
    refute n.node_set?
    refute n.bool?
  end

  test 'number with zero' do
    n = Gammo::XPath::AST::Value::Number.new(0)
    assert_equal '0', n.to_s
    assert_equal 0, n.to_number
    assert_equal false, n.to_bool
    assert n.number?
    refute n.string?
    refute n.node_set?
    refute n.bool?
  end

  test 'variable reference' do
    v = Gammo::XPath::AST::Value::VariableReference.new('var')
    s = v.evaluate(Gammo::XPath::Context.new(node: nil, variables: {var: 'hello'}))
    assert s.instance_of?(Gammo::XPath::AST::Value::String)
    assert_equal 'hello', s.to_s
  end

  test 'variable reference with number' do
    v = Gammo::XPath::AST::Value::VariableReference.new('var')
    n = v.evaluate(Gammo::XPath::Context.new(node: nil, variables: {var: 1}))
    assert n.instance_of?(Gammo::XPath::AST::Value::Number)
    assert_equal 1, n.to_number
  end

  test '#to_node_set' do
    ns = Gammo::XPath::NodeSet.new
    ns << Gammo::Node::Element.new(tag: 'a', data: 'hello')
    ns << Gammo::Node::Element.new(tag: 'a', data: 'world')
    ctx = Gammo::XPath::Context.new(node: nil)
    nsv = Gammo::XPath::AST::Value::NodeSet.new(ns)
    assert_equal ns, nsv.to_node_set(ctx)
  end

  test '#to_node_set with boolean' do
    b = Gammo::XPath::AST::Value::Boolean.new(true)
    ctx = Gammo::XPath::Context.new(node: nil)
    assert b.to_node_set(ctx).empty?
  end
end

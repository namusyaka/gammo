$LOAD_PATH.unshift  File.join(__dir__, '..')
require 'test_helper'

class XPath::OperatorTest < Test::Unit::TestCase
  def setup
    @doc = Gammo.new(<<-EOS).parse
<!DOCTYPE html>
<html>
<head>
<title>hello</title>
<meta charset="utf8">
</head>
<body>
<div id="foo">world</div>
<div id="bar">baz</div>
<select>
<option name="one" value="1">
<option name="two" value="2">
<option name="three" value="3">
<option name="four" value="4">
</select>
</body>
</html>
    EOS
  end

  def test_eq
    ns = @doc.xpath('//*[@id = "foo"]')
    assert_equal 1, ns.length
    assert_equal Gammo::Tags::Div, ns.first.tag
    assert_equal 'world', ns.first.inner_text
  end

  def test_neq
    ns = @doc.xpath('//div[@id != "foo"]')
    assert_equal 1, ns.length
    assert_equal Gammo::Tags::Div, ns.first.tag
    assert_equal 'baz', ns.first.inner_text
  end

  def test_lt
    ns = @doc.xpath('//option[@value < 3]')
    assert_equal 2, ns.length
    assert ns.all? { |node| node.tag == Gammo::Tags::Option }
    assert_equal '1', ns[0].attributes[:value]
    assert_equal '2', ns[1].attributes[:value]
  end

  def test_gt
    ns = @doc.xpath('//option[@value > 2]')
    assert_equal 2, ns.length
    assert ns.all? { |node| node.tag == Gammo::Tags::Option }
    assert_equal '3', ns[0].attributes[:value]
    assert_equal '4', ns[1].attributes[:value]
  end

  def test_lte
    ns = @doc.xpath('//option[@value <= 3]')
    assert_equal 3, ns.length
    assert ns.all? { |node| node.tag == Gammo::Tags::Option }
    assert_equal '1', ns[0].attributes[:value]
    assert_equal '2', ns[1].attributes[:value]
    assert_equal '3', ns[2].attributes[:value]
  end

  def test_gte
    ns = @doc.xpath('//option[@value >= 2]')
    assert_equal 3, ns.length
    assert ns.all? { |node| node.tag == Gammo::Tags::Option }
    assert_equal '2', ns[0].attributes[:value]
    assert_equal '3', ns[1].attributes[:value]
    assert_equal '4', ns[2].attributes[:value]
  end

  def test_plus
    ns = @doc.xpath('//option[@value=1+2]')
    assert_equal 1, ns.length
    assert_equal '3', ns[0].attributes[:value]
  end

  def test_minus
    ns = @doc.xpath('//option[@value=2-1]')
    assert_equal 1, ns.length
    assert_equal '1', ns[0].attributes[:value]
  end

  def test_multiply
    ns = @doc.xpath('//option[@value=2*2]')
    assert_equal 1, ns.length
    assert_equal '4', ns[0].attributes[:value]
  end

  def test_divided
    ns = @doc.xpath('//option[@value=2 div 2]')
    assert_equal 1, ns.length
    assert_equal '1', ns[0].attributes[:value]
  end

  def test_mod
    ns = @doc.xpath('//option[@value=3 mod 2]')
    assert_equal 1, ns.length
    assert_equal '1', ns[0].attributes[:value]
  end
end

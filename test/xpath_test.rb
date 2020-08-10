require 'test_helper'

class XPathTest < Test::Unit::TestCase
  setup do
    @doc = Gammo.new(<<-EOS).parse
<!DOCTYPE html>
<html>
<head>
<title>hello</title>
<meta charset="utf8">
</head>
<body>
<div><div><img src="hoge.jpg">A</div></div>
<ul class="container">
<li>foo</li>
</ul>
    EOS
  end

  test 'traverses DOM tree built by Gammo' do
    assert_equal 'hello', @doc.xpath('//title').first.inner_text
  end

  test 'evaluates xpath expression according to the result type' do
    assert_equal 'a', @doc.xpath('string("a")', result_type: Gammo::XPath::STRING_TYPE)
    assert_equal 1, @doc.xpath('1', result_type: Gammo::XPath::NUMBER_TYPE)
    assert_equal true, @doc.xpath('true()', result_type: Gammo::XPath::BOOLEAN_TYPE)
  end

  test 'returns a value having any type if specifying ANY_TYPE in the result type' do
    assert_equal true, @doc.xpath('true()', result_type: Gammo::XPath::ANY_TYPE)
    assert_equal 'hello', @doc.xpath('//title', result_type: Gammo::XPath::ANY_TYPE).first.inner_text
  end
end

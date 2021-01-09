$LOAD_PATH.unshift  File.join(__dir__, '..')
require 'test_helper'

class CSSSelector::CombinatorTest < Test::Unit::TestCase
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
<li class="a"><font>foo<font>baz</font></font><font>world</font></li>
<li class="b"><font>bar<font>baz</font></font><font>world</font></li>
<li class="c"><font>baz<font>baz</font></font><font>world</font></li>
</ul>
    EOS
  end

  sub_test_case 'descendant' do
    test 'nested case' do
      ns = @doc.css('ul li font')
      assert_nil ns.map(&:tag).find { |x| x != Gammo::Tags::Font }
      assert_equal ["foobaz", "world", "baz", "barbaz", "world", "baz", "bazbaz", "world", "baz"], ns.map(&:inner_text)
    end

    test 'combined with child selector' do
      ns = @doc.css('ul > li font')
      assert_nil ns.map(&:tag).find { |x| x != Gammo::Tags::Font }
      assert_equal ["foobaz", "world", "baz", "barbaz", "world", "baz", "bazbaz", "world", "baz"], ns.map(&:inner_text)
    end
  end

  sub_test_case 'child' do
    test 'nested case' do
      ns = @doc.css('ul > li > font')
      assert_nil ns.map(&:tag).find { |x| x != Gammo::Tags::Font }
      assert_equal ["foobaz", "world", "barbaz", "world", "bazbaz", "world"], ns.map(&:inner_text)
    end

    test 'nested case without whitespaces' do
      ns = @doc.css('ul>li>font')
      assert_nil ns.map(&:tag).find { |x| x != Gammo::Tags::Font }
      assert_equal ["foobaz", "world", "barbaz", "world", "bazbaz", "world"], ns.map(&:inner_text)
    end
  end

  sub_test_case 'next sibling' do
    test 'nested case' do
      ns = @doc.css('ul > li + li')
      assert_nil ns.map(&:tag).find { |x| x != Gammo::Tags::Li }
      assert_equal ["barbazworld", "bazbazworld"], ns.map(&:inner_text)
    end

    test 'nested case without whitespaces' do
      ns = @doc.css('ul>li+li')
      assert_nil ns.map(&:tag).find { |x| x != Gammo::Tags::Li }
      assert_equal ["barbazworld", "bazbazworld"], ns.map(&:inner_text)
    end
  end

  sub_test_case 'subsequent sibling' do
    test 'nested case' do
      ns = @doc.css('ul > li ~ li')
      assert_nil ns.map(&:tag).find { |x| x != Gammo::Tags::Li }
      assert_equal ["barbazworld", "bazbazworld"], ns.map(&:inner_text)
    end

    test 'nested case without whitespaces' do
      ns = @doc.css('ul>li~li')
      assert_nil ns.map(&:tag).find { |x| x != Gammo::Tags::Li }
      assert_equal ["barbazworld", "bazbazworld"], ns.map(&:inner_text)
    end
  end
end

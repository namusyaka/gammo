$LOAD_PATH.unshift  File.join(__dir__, '..')
require 'test_helper'

class CSSSelector::PredicateTest < Test::Unit::TestCase
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
<li id="a" class="a"><font>foo<font>baz</font></font><font>world</font></li>
<li id="b c" class="b"><font>bar<font>baz</font></font><font>world</font></li>
<li class="c"><font>baz<font>baz</font></font><font>world</font></li>
<li class="d">bomb</li>
<li class="abcd"><font>namu<font>sya</font></font><font>ka</font></li>
<li class="ja">japan</li>
<li class="ja-JP">japan2</li>
<li class="x y z a">including</li>
</ul>
<textarea class="enabling"></textarea>
<textarea class="disabling" disabled></textarea>
<textarea class="disabling" disabled="disabled"></textarea>
<input type="radio" value="a" checked="checked">
<input type="radio" value="b">
<input type="radio" value="c">
<input type="radio" value="d" checked>
<ul class="nth-test">
<li>1</li>
<li>2</li>
<li>3</li>
<li>4</li>
<li>5</li>
<li>6</li>
<li>7</li>
<li>8</li>
<li>9</li>
<li>10</li>
<li>11</li>
<li>12</li>
<li>13</li>
<li>14</li>
<li>15</li>
<li>16</li>
<li>17</li>
</ul>
<dl>
<dt>a</dt>
<dd>b</dd>
</dl>
    EOS
  end

  sub_test_case 'selector groups' do
    test 'simple' do
      ns = @doc.css('title, .ja')
      assert_equal 2, ns.length
      assert_equal ['hello', 'japan'], ns.map(&:inner_text)
    end

    test 'duplicates' do
      ns = @doc.css('title, .ja, title')
      assert_equal 2, ns.length
      assert_equal ['hello', 'japan'], ns.map(&:inner_text)
    end
  end

  sub_test_case 'universal' do
    test '*' do
      ns = @doc.css('dl > *')
      assert_equal 2, ns.length
      assert_equal ['a', 'b'], ns.map(&:inner_text)
    end
  end

  sub_test_case 'hash' do
    test 'single id' do
      ns = @doc.css('#a')
      assert_equal 1, ns.length
      assert_equal 'foobazworld', ns.first.inner_text
    end

    test 'multiple ids' do
      ns = @doc.css('#b#c')
      assert_equal 1, ns.length
      assert_equal 'barbazworld', ns.first.inner_text
    end
  end

  sub_test_case 'class' do
    test 'a class' do
      ns = @doc.css('ul > li.a')
      assert_equal 2, ns.length
      assert_equal ['foobazworld', 'including'], ns.map(&:inner_text)
      ns = @doc.css('ul > li.a')
      assert_equal 2, ns.length
      assert_equal ['foobazworld', 'including'], ns.map(&:inner_text)
    end

    test 'multiple classes' do
      ns = @doc.css('ul > li.x.y.z')
      assert_equal 1, ns.length
      assert_equal 'including', ns.first.inner_text
      ns = @doc.css('ul > .x.y.z')
      assert_equal 1, ns.length
      assert_equal 'including', ns.first.inner_text
    end
  end

  sub_test_case 'attrib' do
    test 'equal' do
      ns = @doc.css('ul > li[class="a"]')
      assert_equal 1, ns.length
      assert_equal 'foobazworld', ns.first.inner_text

      ns = @doc.css('ul > li[class = "a"]')
      assert_equal 1, ns.length
      assert_equal 'foobazworld', ns.first.inner_text

      ns = @doc.css('ul > [class = "a"]')
      assert_equal 1, ns.length
      assert_equal 'foobazworld', ns.first.inner_text

      ns = @doc.css('ul > [class="unexisting"]')
      assert_equal 0, ns.length
    end

    test 'prefix_match' do
      ns = @doc.css('ul > li[class^="a"]')
      assert_equal 2, ns.length
      assert_equal ['foobazworld', 'namusyaka'], ns.map(&:inner_text)

      ns = @doc.css('ul > li[class ^= "abc"]')
      assert_equal 1, ns.length
      assert_equal 'namusyaka', ns.first.inner_text

      ns = @doc.css('ul > [class^="unexisting"]')
      assert_equal 0, ns.length
    end

    test 'suffix_match' do
      ns = @doc.css('ul > li[class$="d"]')
      assert_equal 2, ns.length
      assert_equal ['bomb', 'namusyaka'], ns.map(&:inner_text)

      ns = @doc.css('ul > li[class $= "bcd"]')
      assert_equal 1, ns.length
      assert_equal 'namusyaka', ns.first.inner_text

      ns = @doc.css('ul > [class$="unexisting"]')
      assert_equal 0, ns.length
    end

    test 'substring_match' do
      ns = @doc.css('ul > li[class*="c"]')
      assert_equal 2, ns.length
      assert_equal ['bazbazworld', 'namusyaka'], ns.map(&:inner_text)

      ns = @doc.css('ul > li[class *= "bc"]')
      assert_equal 1, ns.length
      assert_equal 'namusyaka', ns.first.inner_text

      # empty string does not represent anything
      ns = @doc.css('ul > li[class *= ""]')
      assert_equal 0, ns.length

      ns = @doc.css('ul > [class*="unexisting"]')
      assert_equal 0, ns.length
    end

    test 'dash_match' do
      ns = @doc.css('ul > li[class|="ja"]')
      assert_equal 2, ns.length
      assert_equal ['japan', 'japan2'], ns.map(&:inner_text)

      ns = @doc.css('ul > li[class |= "ja"]')
      assert_equal 2, ns.length
      assert_equal ['japan', 'japan2'], ns.map(&:inner_text)

      ns = @doc.css('ul > [class|="unexisting"]')
      assert_equal 0, ns.length
    end

    test 'includes' do
      ns = @doc.css('ul > li[class~="a"]')
      assert_equal 2, ns.length
      assert_equal ['foobazworld', 'including'], ns.map(&:inner_text)

      ns = @doc.css('ul > li[class ~= "a"]')
      assert_equal 2, ns.length
      assert_equal ['foobazworld', 'including'], ns.map(&:inner_text)

      ns = @doc.css('ul > [class~="unexisting"]')
      assert_equal 0, ns.length
    end
  end

  sub_test_case 'pseudo' do
    test 'enabled' do
      ns = @doc.css('textarea:enabled')
      assert_equal 1, ns.length
      assert_equal 'enabling', ns.first.attributes[:class]
    end

    test 'disabled' do
      ns = @doc.css('textarea:disabled')
      assert_equal 2, ns.length
      assert_equal ['disabling', 'disabling'], ns.map { |node| node.attributes[:class] }
    end

    test 'checked' do
      ns = @doc.css('input[type="radio"]:checked')
      assert_equal 2, ns.length
      assert_equal ['a', 'd'], ns.map { |node| node.attributes[:value] }
    end

    sub_test_case 'nth-child(n)' do
      test '1' do
        ns = @doc.css('.nth-test li:nth-child(1)')
        assert_equal 1, ns.length
        assert_equal [1], ns.map { |node| node.inner_text.to_i }
      end

      test '2' do
        ns = @doc.css('.nth-test li:nth-child(2)')
        assert_equal 1, ns.length
        assert_equal [2], ns.map { |node| node.inner_text.to_i }
      end

      test 'odd' do
        ns = @doc.css('.nth-test li:nth-child(odd)')
        assert_equal 9, ns.length
        assert_equal [1, 3, 5, 7, 9, 11, 13, 15, 17], ns.map { |node| node.inner_text.to_i }
      end

      test 'even' do
        ns = @doc.css('.nth-test li:nth-child(even)')
        assert_equal 8, ns.length
        assert_equal [2, 4, 6, 8, 10, 12, 14, 16], ns.map { |node| node.inner_text.to_i }
      end

      test '5n' do
        ns = @doc.css('.nth-test li:nth-child(5n)')
        assert_equal 3, ns.length
        assert_equal [5, 10, 15], ns.map { |node| node.inner_text.to_i }
      end

      test 'n+7' do
        ns = @doc.css('.nth-test li:nth-child(n+7)')
        assert_equal 11, ns.length
        assert_equal [7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17], ns.map { |node| node.inner_text.to_i }
      end

      test '3n+4' do
        ns = @doc.css('.nth-test li:nth-child(3n+4)')
        assert_equal 5, ns.length
        assert_equal [4, 7, 10, 13, 16], ns.map { |node| node.inner_text.to_i }
      end

      test '-n+3' do
        ns = @doc.css('.nth-test li:nth-child(-n+3)')
        assert_equal 3, ns.length
        assert_equal [1, 2, 3], ns.map { |node| node.inner_text.to_i }
      end

      test '10n-1' do
        ns = @doc.css('.nth-test li:nth-child(10n-1)')
        assert_equal 1, ns.length
        assert_equal [9], ns.map { |node| node.inner_text.to_i }
      end
    end

    sub_test_case 'not()' do
      test 'not(element_name)' do
        ns = @doc.css('dl > :not(dt)')
        assert_equal 1, ns.length
        assert_equal ['b'], ns.map { |node| node.inner_text }
      end

      test 'not(*)' do
        ns = @doc.css('head > :not(*)')
        assert_equal 0, ns.length
      end

      test 'not(#id)' do
        ns = @doc.css('.container > li:not(#a)')
        assert_equal 7, ns.length
        assert_equal ['barbazworld', 'bazbazworld', 'bomb', 'namusyaka', 'japan', 'japan2', 'including'], ns.map { |node| node.inner_text }
      end

      test 'not(.class_name)' do
        ns = @doc.css('.container li:not(.a)')
        assert_equal 6, ns.length
        assert_equal ['barbazworld', 'bazbazworld', 'bomb', 'namusyaka', 'japan', 'japan2'], ns.map { |node| node.inner_text }
      end

      test 'not([attrib])' do
        ns = @doc.css('.container > li:not([class~="a"])')
        assert_equal 6, ns.length
        assert_equal ['barbazworld', 'bazbazworld', 'bomb', 'namusyaka', 'japan', 'japan2'], ns.map { |node| node.inner_text }
      end

      test 'not(:pseudo)' do
        ns = @doc.css('input:not(:checked)')
        #assert_equal 2, ns.length
        assert_equal ['b', 'c'], ns.map { |node| node.attributes[:value] }
      end

      test 'not():not()' do
        ns = @doc.css('dl > :not(dt):not(dd)')
        assert_equal 0, ns.length
      end
    end
  end
end

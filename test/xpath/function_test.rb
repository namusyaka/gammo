$LOAD_PATH.unshift  File.join(__dir__, '..')
require 'test_helper'

class XPath::FunctionTest < Test::Unit::TestCase
  def setup
    @doc = Gammo.new(<<-EOS).parse
    <!DOCTYPE html lang="ja">
    <html>
    <head>
    <title>a</title>
    </head>
    <body>
    <ul>
    <li>a</li>
    <li>b</li>
    <li>c</li>
    </ul>
    <p id="description">hello namusyaka, namusyaka world</p>
    </body>
    </html>
    EOS
  end

  def test_ceiling
    ns = @doc.xpath('//li[ceiling(2.4)]')
    assert_equal 'c', ns.first.inner_text
  end

  def test_concat
    ret = @doc.xpath('concat(//li[1]/text(), //li[2]/text(), //li[3]/text())', result_type: Gammo::XPath::STRING_TYPE)
    assert_equal 'abc', ret
  end

  def test_contains
    assert @doc.xpath('contains("asdf", "a")', result_type: Gammo::XPath::BOOLEAN_TYPE)
    assert !@doc.xpath('contains("asdf", "c")', result_type: Gammo::XPath::BOOLEAN_TYPE)
  end

  def test_last
    assert_equal 'c', @doc.xpath('//li[last()]').first.inner_text
  end

  def test_position
    assert_equal 'b', @doc.xpath('//li[position()=2]').first.inner_text
  end

  def test_string
    assert_equal 'title', @doc.xpath('//title[string()="<title>"]').first.tag
    assert_equal '<title>', @doc.xpath('string(//title)', result_type: Gammo::XPath::STRING_TYPE)
  end

  def test_starts_with
    assert @doc.xpath('starts-with(//title/text(), "a")', result_type: Gammo::XPath::BOOLEAN_TYPE)
    refute @doc.xpath('starts-with(//title/text(), "b")', result_type: Gammo::XPath::BOOLEAN_TYPE)
  end

  def test_substring_before
    assert_equal 'hello ', @doc.xpath('substring-before(//p[@id="description"]/text(), "namusyaka")', result_type: Gammo::XPath::STRING_TYPE)
  end

  def test_substring_after
    assert_equal ' world', @doc.xpath('substring-after(//p[@id="description"]/text(), "namusyaka")', result_type: Gammo::XPath::STRING_TYPE)
  end
end

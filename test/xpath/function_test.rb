$LOAD_PATH.unshift  File.join(__dir__, '..')
require 'test_helper'

class XPath::FunctionTest < Test::Unit::TestCase
  setup do
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

  test 'ceiling' do
    ns = @doc.xpath('//li[ceiling(2.4)]')
    assert_equal 'c', ns.first.inner_text
  end

  test 'concat' do
    ret = @doc.xpath('concat(//li[1]/text(), //li[2]/text(), //li[3]/text())', result_type: Gammo::XPath::STRING_TYPE)
    assert_equal 'abc', ret
  end

  test 'contains' do
    assert @doc.xpath('contains("asdf", "a")', result_type: Gammo::XPath::BOOLEAN_TYPE)
    assert !@doc.xpath('contains("asdf", "c")', result_type: Gammo::XPath::BOOLEAN_TYPE)
  end

  test 'last' do
    assert_equal 'c', @doc.xpath('//li[last()]').first.inner_text
  end

  test 'position' do
    assert_equal 'b', @doc.xpath('//li[position()=2]').first.inner_text
  end

  test 'string' do
    assert_equal 'title', @doc.xpath('//title[string()="<title>"]').first.tag
    assert_equal '<title>', @doc.xpath('string(//title)', result_type: Gammo::XPath::STRING_TYPE)
  end

  test 'starts_with' do
    assert @doc.xpath('starts-with(//title/text(), "a")', result_type: Gammo::XPath::BOOLEAN_TYPE)
    refute @doc.xpath('starts-with(//title/text(), "b")', result_type: Gammo::XPath::BOOLEAN_TYPE)
  end

  test 'substring_before' do
    assert_equal 'hello ', @doc.xpath('substring-before(//p[@id="description"]/text(), "namusyaka")', result_type: Gammo::XPath::STRING_TYPE)
  end

  test 'substring_after' do
    assert_equal ' world', @doc.xpath('substring-after(//p[@id="description"]/text(), "namusyaka")', result_type: Gammo::XPath::STRING_TYPE)
  end
end

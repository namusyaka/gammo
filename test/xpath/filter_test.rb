$LOAD_PATH.unshift  File.join(__dir__, '..')
require 'test_helper'

class XPath::FilterTest < Test::Unit::TestCase
  def setup
    @doc = Gammo.new(<<-EOS).parse
    <!DOCTYPE html lang="ja">
    <html>
    <head>
    <title>a</title>
    </head>
    <body>
    <p class="foo" id="foo">hello</p>
    <p class="foo" id="foo2">world</p>
    <ul class="hello" id="world">
    <li>hello</li>
    <li>world</li>
    </ul>
    </body>
    </html>
    EOS
  end

  def test_filter
    ns = @doc.xpath('(//p)[@class="foo"][@id="foo"]')
    assert_equal 1, ns.length
    assert_equal 'p', ns.first.tag
  end

  def test_path
    ns = @doc.xpath('(//ul)[@class="hello"][@id="world"]/li')
    assert_equal 2, ns.length
    assert_equal 'hello,world', ns.map(&:inner_text).join(?,)
  end
end

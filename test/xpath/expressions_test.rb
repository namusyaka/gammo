$LOAD_PATH.unshift  File.join(__dir__, '..')
require 'test_helper'

class XPath::ExpressionsTest < Test::Unit::TestCase
  setup do
    @doc = Gammo.new(<<-EOS).parse
<!DOCTYPE html>
<html>
<head>
<title>hello</title>
<meta charset="utf8">
</head>
<body>
<li>hello</li>
<ul>
</ul>
<p>world</p>
</body>
</html>
    EOS
  end

  test 'union' do
    s = ''
    @doc.xpath('//li/text()|//p/text()').each do |node|
      s << node.text_content
    end
    assert_equal 'helloworld', s
  end

  test 'unary_expr' do
    assert_equal (-1), @doc.xpath('-contains("asdf", "a")', result_type: Gammo::XPath::NUMBER_TYPE)
  end
end

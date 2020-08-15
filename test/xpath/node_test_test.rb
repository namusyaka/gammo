$LOAD_PATH.unshift  File.join(__dir__, '..')
require 'test_helper'

class XPath::NodeTestTest < Test::Unit::TestCase
  def setup
    @doc = Gammo.new(<<-EOS).parse
<!DOCTYPE html>
<html>
<head>
<!-- comment! -->
<title>hello</title>
</head>
<body>
</body>
</html>
    EOS
  end

  def test_node
    ns = @doc.xpath('//title/node()')
    assert_equal 1, ns.length
    assert_equal 'hello', ns.first.data
  end

  def test_text
    ns = @doc.xpath('//title/text()')
    assert_equal 1, ns.length
    assert_equal 'hello', ns.first.data
  end

  def test_comment
    ns = @doc.xpath('//head/comment()')
    assert_equal 1, ns.length
    assert_equal ' comment! ', ns.first.data
  end

  def test_processing_instruction
    assert_raise(NotImplementedError) { @doc.xpath('//processing-instruction()') }
  end
end

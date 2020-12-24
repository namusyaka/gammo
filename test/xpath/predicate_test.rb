$LOAD_PATH.unshift  File.join(__dir__, '..')
require 'test_helper'

class XPath::PredicateTest < Test::Unit::TestCase
  setup do
    @doc = Gammo.new(<<-EOS).parse
<ul>
<li>a</li>
<li>b</li>
<li>c</li>
</ul>
    EOS
  end

  test 'predicate' do
    assert_equal 'abc', 3.times.map { |n| @doc.xpath("//li[#{n + 1}]").first.inner_text }.join
  end

  test 'avoids aborting even if node_set does not match with right side' do
    assert_equal 0, @doc.xpath('//li[class=foo]').length
  end
end

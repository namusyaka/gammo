require 'test_helper'

class CSSSelectorTest < Test::Unit::TestCase
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
    assert_equal 'hello', @doc.css('title').first.inner_text
  end
end

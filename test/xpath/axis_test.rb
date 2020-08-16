$LOAD_PATH.unshift  File.join(__dir__, '..')
require 'test_helper'

class XPath::AxisTest < Test::Unit::TestCase
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
<li><a href="google.com">google.com</a></li>
<li><a href="namusyaka.com">foo</a></li>
<li class="testing-list">
  <ul>
    <li><span class="testing">hello</span></li>
  </ul>
</li>
</ul>
<div class="foo1">
  <div class="foo1">
  </div>
  <div class="foo2">
  </div>
</div>
    EOS
  end

  test 'ancestor' do
    ns = @doc.xpath('//*[@class="foo1"]/ancestor::div')
    assert_nil ns.map(&:tag).find { |x| x != Gammo::Tags::Div }
    assert_equal 1, ns.length
    assert_equal 'foo1', ns[0].attributes[:class]
    ns2 = @doc.xpath('//@class/ancestor::div')
    ns.to_s == ns2.to_s
  end

  test 'ancestor_or_self' do
    ns = @doc.xpath('//*[@class="foo1"]/ancestor-or-self::div')
    assert_equal 2, ns.length
    assert_nil ns.map(&:tag).find { |x| x != Gammo::Tags::Div }
    assert_equal 'foo1', ns[0].attributes[:class]
    assert_equal 'foo1', ns[1].attributes[:class]
    ns2 = @doc.xpath('//@class/ancestor-or-self::div')
    ns.to_s == ns2.to_s
  end

  test 'attribute' do
    ns = @doc.xpath('//span[@class="testing"]')
    assert_equal 1, ns.length
    assert_equal 'hello', ns[0].first_child.data
    ns = @doc.xpath('//a[@*="google.com"]')
    assert_equal 1, ns.length
    assert_equal 'google.com', ns[0].attributes[:href]
  end

  test 'child' do
    ns = @doc.xpath('//ul/li/a')
    assert_equal 2, ns.length
    assert_equal 'google.com', ns[0].attributes[:href]
    assert_equal 'namusyaka.com', ns[1].attributes[:href]
  end

  test 'descendant' do
    ns = @doc.xpath('//body/div[@class="foo1"]/descendant::div')
    assert_equal 2, ns.length
    assert_equal 'foo1', ns[0].attributes[:class]
    assert_equal 'foo2', ns[1].attributes[:class]
  end

  test 'descendant_or_self' do
    ns = @doc.xpath('//body/div[@class="foo1"]/descendant-or-self::div')
    assert_equal 3, ns.length
    assert_equal 'foo1', ns[0].attributes[:class]
    assert_equal 'foo1', ns[1].attributes[:class]
    assert_equal 'foo2', ns[2].attributes[:class]
  end

  test 'following' do
    ns = @doc.xpath('//li/following::span')
    assert_equal 1, ns.length
    assert_equal 'hello', ns[0].first_child.data
  end

  test 'following_sibling' do
    ns = @doc.xpath('//div/following-sibling::ul')
    assert_equal 1, ns.length
    assert_equal Gammo::Tags::Ul, ns[0].tag
  end

  test 'parent' do
    ns = @doc.xpath('//*[@class="testing"]/..')
    assert_equal 1, ns.length
    assert_equal Gammo::Tags::Li, ns[0].tag
  end

  test 'preceding' do
    ns = @doc.xpath('//*[@class="foo1"]/preceding::div')
    assert_equal 1, ns.length
    assert_equal Gammo::Tags::Div, ns[0].tag
  end

  test 'preceding_sibling' do
    ns = @doc.xpath('//*[@class="foo2"]/preceding-sibling::div')
    assert_equal 1, ns.length
    assert_equal Gammo::Tags::Div, ns[0].tag
    assert_equal 'foo1', ns[0].attributes[:class]
  end

  test 'self' do
    ns = @doc.xpath('//*[@class="foo2"]/self::div')
    assert_equal 1, ns.length
    assert_equal Gammo::Tags::Div, ns[0].tag
    assert_equal 'foo2', ns[0].attributes[:class]
  end
end

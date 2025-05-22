require 'test_helper'

class SelectScopeTest < Test::Unit::TestCase
  include Support::Dump

  test 'option and optgroup nesting' do
    html = '<select><option>One<optgroup><option>Two</option></optgroup></select>'
    doc = Gammo.new(html).parse
    assert_equal(<<~OUT, dump_for(doc))
| <html>
|   <head>
|   <body>
|     <select>
|       <option>
|         "One"
|       <optgroup>
|         <option>
|           "Two"
    OUT
    )
  end
end


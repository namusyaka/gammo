require "test_helper"

class GammoTest < Test::Unit::TestCase
  test 'has a version number' do
    refute_nil ::Gammo::VERSION
  end

  test '#new constructs a parser' do
    assert Gammo::Parser.new('</').instance_of?(Gammo::Parser)
  end
end

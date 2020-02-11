require "test_helper"

class GammoTest < Test::Unit::TestCase
  def test_that_it_has_a_version_number
    refute_nil ::Gammo::VERSION
  end

  def test_that_new_constructs_parser
    assert Gammo::Parser.new('</').instance_of?(Gammo::Parser)
  end
end

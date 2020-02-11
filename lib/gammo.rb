require "gammo/version"
require "gammo/parser"
require "gammo/fragment_parser"

module Gammo
  # Constructs a parser based on the input.
  #
  # @param [String] input
  # @param [TrueClass, FalseClass] fragment
  # @param [Hash] options
  # @return [Gammo::Parser]
  def self.new(input, fragment: false, **options)
    (fragment ? FragmentParser : Parser).new(input, **options)
  end
end

require 'simplecov'

SimpleCov.start do
  project_name 'gammo'
  minimum_coverage 95
  coverage_dir '.coverage'

  add_filter '/test/'
end

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
$LOAD_PATH.unshift  __dir__
require "test/unit"
require "gammo"

module XPath end

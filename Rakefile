require "bundler/gem_tasks"
require "rake/testtask"
require 'yaml'
require 'erubi'

Rake::TestTask.new(:test) do |t|
  t.libs << "test"
  t.libs << "lib"
  t.test_files = FileList["test/**/*_test.rb"]
end

task default: :test

def camelize(str)
  str.sub(/^[a-z\d]*/) { $&.capitalize }.sub(/\-[a-z]*/) { $&.slice(1..-1).capitalize }
end

task default: :test

task :generate do
  data = YAML.load(File.read('misc/html.yaml'), symbolize_names: true)
  @tags = data.each_value.inject(:+).uniq
  table = eval(Erubi::Engine.new(File.read('misc/table.erubi')).src, binding)
  File.write('lib/gammo/tags/table.rb', table)
end

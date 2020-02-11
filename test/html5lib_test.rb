$LOAD_PATH.unshift File.expand_path(__dir__)
require 'test_helper'
require 'support/dump'

class HTML5LibTest < Test::Unit::TestCase
  include Support::Dump

  def message_for(path, got, want, input, i)
    msg = "#{path} ##{i} '#{input}', got vs want:\n"
    msg << ?- * 5 << ?\n
    msg << got
    msg << ?- * 5 << ?\n
    msg << want
    msg << ?- * 5
  end

  def parse(input, context: nil, scripting: true)
    if context
      namespace, context = context.split(' ')
      unless context
        context   = namespace
        namespace = nil
      end
      Gammo.new(
        input,
        fragment: true,
        scripting: scripting,
        context: Gammo::Node::Element.new(
          data: context,
          namespace: namespace,
          tag: Gammo::Tags.lookup(context)
        )
      ).parse.each_with_object(Gammo::Node::Document.new) { |node, doc|
        doc.append_child(node)
      }
    else
      parser = Gammo.new(input, scripting: scripting)
      parser.parse
      parser.document
    end
  end

  class << self
    def parser_test(lines)
      c = lines.shift.chomp
      i = 0
      while c == '#data'
        # given data
        input = ''
        line = lines.shift
        while !line.start_with?(?#)
          input << line
          line = lines.shift
        end
        input = input.chomp
        errors = line
        if errors != "#errors\n"
          raise 'expected "#errors" but got %s' % errors 
        end
        # skip error assertion
        doc = lines.shift.chomp
        doc = lines.shift.chomp while !doc.start_with?(?#)

        scripting = true
        if doc.start_with?('#script-')
          scripting =
            if doc.end_with?('-on')
              true
            elsif doc.end_with?('-off')
              false
            else
              raise 'expect #script-on or #script-off, but got %s' % doc
            end
          doc = lines.shift.chomp
          doc = lines.shift.chomp until doc.start_with?(?#)
        end

        context = nil
        if doc == '#document-fragment'
          context = lines.shift.chomp.strip
          doc = lines.shift.chomp
        end
        if doc != '#document'
          raise 'expecte4d "#document", but got %s' % doc
        end
        line = lines.shift
        in_quote = false
        want = []
        while line
          trimmed = line.chomp
          break if line.empty?
          trimmed = line.gsub(/\A[| \n]*/, '').gsub(/[| \n]*?\z/, '')
          unless trimmed.empty?
            in_quote = true if line[0] == ?| && trimmed[0] == '"'
            in_quote = false if trimmed[-1] == '"' && !(line[0] == ?| && trimmed.length == 1)
          end
          break if line.empty? || line.length == 1 && line[0] == ?\n && !in_quote
          want << line
          line = lines.shift
        end
        want = want.join
        yield input, want: want, context: context, scripting: scripting, index: i
        c = lines.shift
        break unless c
        c = c.chomp
        i += 1
      end
    end
  end

  Dir.glob(File.join(__dir__, 'html5lib-tests/*.dat')) do |path|
    basename = File.basename(path)
    sub_test_case basename do
      parser_test File.open(path).readlines do |input, want: nil, context: nil, scripting: true, index: 0|
        test "#{path}/#{input}:(context: #{context}, scripting: #{scripting}, index: #{index})" do
          got =
            begin
              dump_for(parse(input, context: context, scripting: scripting))
            rescue => evar
              evar.inspect
            end
          assert_block(message_for(path, got, want, input, index)) { want == got }
        end
      end
    end
  end
end

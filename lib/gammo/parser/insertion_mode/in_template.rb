module Gammo
  class Parser
    # Section 12.2.6.4.18.
    class InTemplate < InsertionMode
      def text_token(token)
        halt InBody.new(parser).process
      end

      def comment_token(token)
        halt InBody.new(parser).process
      end

      def doctype_token(token)
        halt InBody.new(parser).process
      end

      def start_tag_token(token)
        case token.tag
        when Tags::Base, Tags::Basefont, Tags::Bgsound, Tags::Link, Tags::Meta, Tags::Noframes, Tags::Script, Tags::Style, Tags::Template, Tags::Title
          halt InHead.new(parser).process
        when Tags::Caption, Tags::Colgroup, Tags::Tbody, Tags::Tfoot, Tags::Thead
          parser.template_stack.pop
          parser.template_stack << InTable
          parser.insertion_mode = InTable
          halt false
        when Tags::Col
          parser.template_stack.pop
          parser.template_stack << InColumnGroup
          parser.insertion_mode = InColumnGroup
          halt false
        when Tags::Tr
          parser.template_stack.pop
          parser.template_stack << InTableBody
          parser.insertion_mode = InTableBody
          halt false
        when Tags::Td, Tags::Th
          parser.template_stack.pop
          parser.template_stack << InRow
          parser.insertion_mode = InRow
          halt false
        else
          parser.template_stack.pop
          parser.template_stack << InBody
          parser.insertion_mode = InBody
          halt false
        end
      end

      def end_tag_token(token)
        case token.tag
        when Tags::Template
          halt InHead.new(parser).process
        else
          # ignore the token
          halt true
        end
      end

      def error_token(token)
        halt true unless parser.open_elements.any? {|elm| elm.tag == Tags::Template }
        # remove this divergence from the html5 spec
        parser.generate_implied_end_tags
        parser.open_elements.reverse_each_with_index do |elm, index|
          if !elm.namespace && elm.tag == Tags::Template
            parser.open_elements = parser.open_elements.slice(0, index)
            break
          end
        end
        parser.clear_active_formatting_elements
        parser.template_stack.pop
        parser.reset_insertion_mode
        halt false
      end

      def default(_)
        halt false
      end
    end
  end
end

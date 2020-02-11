module Gammo
  class Parser
    # Section 12.2.6.4.9.
    class InTable < InsertionMode
      def text_token(token)
        token.data = token.data.gsub("\x00", "")
        case parser.open_elements.last.tag
        when Tags::Table, Tags::Tbody, Tags::Tfoot, Tags::Thead, Tags::Tr
          if token.data.strip == ""
            parser.add_text token.data
            halt true
          end
        end
      end

      def start_tag_token(token)
        case token.tag
        when Tags::Caption
          parser.clear_stack_to_context(TABLE_SCOPE)
          parser.active_formatting_elements << Node::DEFAULT_SCOPE_MARKER
          parser.add_element
          parser.insertion_mode = InCaption
          halt true
        when Tags::Colgroup
          parser.clear_stack_to_context(TABLE_SCOPE)
          parser.add_element
          parser.insertion_mode = InColumnGroup
          halt true
        when Tags::Col
          parser.parse_implied_token(Tokenizer::StartTagToken, Tags::Colgroup, Tags::Colgroup.to_s)
          halt false
        when Tags::Tbody, Tags::Tfoot, Tags::Thead
          parser.clear_stack_to_context(TABLE_SCOPE)
          parser.add_element
          parser.insertion_mode = InTableBody
          halt true
        when Tags::Td, Tags::Th, Tags::Tr
          parser.parse_implied_token(Tokenizer::StartTagToken, Tags::Tbody, Tags::Tbody.to_s)
          halt false
        when Tags::Table
          if parser.pop_until(TABLE_SCOPE, Tags::Table)
            parser.reset_insertion_mode
            halt false
          end
          # ignore the token
          halt true
        when Tags::Style, Tags::Script, Tags::Template
          halt InHead.new(parser).process
        when Tags::Input
          token.attributes.each do |attr|
            # skip setting frameset_ok = false
            if attr.key == 'type' && attr.value.downcase == 'hidden'
              parser.add_element
              parser.open_elements.pop
              halt true
            end
          end
        when Tags::Form
          # ignore the token
          halt true if parser.form || parser.open_elements.any? { |open_element| open_element.tag == Tags::Template }
          parser.add_element
          parser.form = parser.open_elements.pop
        when Tags::Select
          parser.reconstruct_active_formatting_elements
          case parser.top.tag
          when Tags::Table, Tags::Tbody, Tags::Tfoot, Tags::Thead, Tags::Tr
            parser.foster_parenting = true
          end
          parser.add_element
          parser.foster_parenting = false
          parser.frameset_ok = true
          parser.insertion_mode = InSelectInTable
          halt true
        end
      end

      def end_tag_token(token)
        case token.tag
        when Tags::Table
          parser.reset_insertion_mode if parser.pop_until(TABLE_SCOPE, Tags::Table)
          # Ignore the token
          halt true
        when Tags::Body, Tags::Caption, Tags::Col, Tags::Colgroup, Tags::Html,
          Tags::Tbody, Tags::Td, Tags::Tfoot, Tags::Th, Tags::Thead, Tags::Tr
          # Ignore the token
          halt true
        when Tags::Template
          halt InHead.new(parser).process
        end
      end

      def comment_token(token)
        parser.add_child(Node::Comment.new(data: token.data))
        halt true
      end

      def doctype_token(token)
        # Ignore the token
        halt true
      end

      def error_token(token)
        InBody.new(parser).process
      end

      def default(_)
        parser.foster_parenting = true
        result = InBody.new(parser).process
        parser.foster_parenting = false
        halt result
      end
    end
  end
end

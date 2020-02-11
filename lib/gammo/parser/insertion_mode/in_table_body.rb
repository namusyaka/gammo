module Gammo
  class Parser
    # Section 12.2.6.4.13.
    class InTableBody < InsertionMode
      def start_tag_token(token)
        case token.tag
        when Tags::Tr
          parser.clear_stack_to_context(TABLE_BODY_SCOPE)
          parser.add_element
          parser.insertion_mode = InRow
          halt true
        when Tags::Td, Tags::Th
          parser.parse_implied_token(Tokenizer::StartTagToken, Tags::Tr, Tags::Tr.to_s)
          halt false
        when Tags::Caption, Tags::Col, Tags::Colgroup, Tags::Tbody, Tags::Tfoot, Tags::Thead
          # ignore the token
          halt true unless parser.pop_until(TABLE_SCOPE, Tags::Tbody, Tags::Thead, Tags::Tfoot)
          parser.insertion_mode = InTable
          halt false
        end
      end

      def end_tag_token(token)
        case token.tag
        when Tags::Tbody, Tags::Tfoot, Tags::Thead
          if parser.element_in_scope?(TABLE_SCOPE, token.tag)
            parser.clear_stack_to_context(TABLE_BODY_SCOPE)
            parser.open_elements.pop
            parser.insertion_mode = InTable
          end
          halt true
        when Tags::Table
          if parser.pop_until(TABLE_SCOPE, Tags::Tbody, Tags::Thead, Tags::Tfoot)
            parser.insertion_mode = InTable
            halt false
          end
          # ignore the token
          halt true
        when Tags::Body, Tags::Caption, Tags::Colgroup, Tags::Html, Tags::Td, Tags::Th, Tags::Tr
          # ignore the token
          halt true
        end
      end

      def comment_token(token)
        parser.add_child(Node::Comment.new(data: token.data))
        halt true
      end

      def default(_)
        halt InTable.new(parser).process
      end
    end
  end
end

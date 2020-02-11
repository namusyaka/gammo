module Gammo
  class Parser
    # Section 12.2.6.4.14.
    class InRow < InsertionMode
      def start_tag_token(token)
        case token.tag
        when Tags::Td, Tags::Th
          parser.clear_stack_to_context(TABLE_ROW_SCOPE)
          parser.add_element
          parser.active_formatting_elements << Node::DEFAULT_SCOPE_MARKER
          parser.insertion_mode = InCell
          halt true
        when Tags::Caption, Tags::Col, Tags::Colgroup, Tags::Tbody, Tags::Tfoot, Tags::Thead, Tags::Tr
          # ignore the token
          halt true unless parser.pop_until(TABLE_SCOPE, Tags::Tr)
          parser.insertion_mode = InTableBody
          halt false
        end
      end

      def end_tag_token(token)
        case token.tag
        when  Tags::Tr
          # ignore the token
          halt true unless parser.pop_until(TABLE_SCOPE, Tags::Tr)
          parser.insertion_mode = InTableBody
          halt true
        when Tags::Table
          if parser.pop_until(TABLE_SCOPE, Tags::Tr)
            parser.insertion_mode = InTableBody
            halt false
          end
          # ignore the token
          halt true
        when Tags::Tbody, Tags::Tfoot, Tags::Thead
          if parser.element_in_scope?(TABLE_SCOPE, token.tag)
            parser.parse_implied_token(Tokenizer::EndTagToken, Tags::Tr, Tags::Tr.to_s)
            halt false
          end
          # ignore the token
          halt true
        when Tags::Body, Tags::Caption, Tags::Col, Tags::Colgroup, Tags::Html, Tags::Td, Tags::Th
          # ignore the token
          halt true
        end
      end

      def default(_)
        halt InTable.new(parser).process
      end
    end
  end
end

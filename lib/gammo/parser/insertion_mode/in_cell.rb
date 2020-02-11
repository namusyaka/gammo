module Gammo
  class Parser
    # Section 12.2.6.4.15.
    class InCell < InsertionMode
      def start_tag_token(token)
        case token.tag
        when Tags::Caption, Tags::Col, Tags::Colgroup, Tags::Tbody, Tags::Td, Tags::Tfoot, Tags::Th, Tags::Thead, Tags::Tr
          halt true unless parser.pop_until(TABLE_SCOPE, Tags::Td, Tags::Th)
          parser.clear_active_formatting_elements
          parser.insertion_mode = InRow
          halt false
        when Tags::Select
          parser.reconstruct_active_formatting_elements
          parser.add_element
          parser.frameset_ok = false
          parser.insertion_mode = InSelectInTable
          halt true
        end
      end

      def end_tag_token(token)
        case token.tag
        when Tags::Td, Tags::Th
          # ignore the token
          halt true unless parser.pop_until(TABLE_SCOPE, token.tag)
          parser.clear_active_formatting_elements
          parser.insertion_mode = InRow
          halt true
        when Tags::Body, Tags::Caption, Tags::Col, Tags::Colgroup, Tags::Html
          # ignore the token
          halt true
        when Tags::Table, Tags::Tbody, Tags::Tfoot, Tags::Thead, Tags::Tr
          # ignore the token
          halt true unless parser.element_in_scope?(TABLE_SCOPE, token.tag)
          parser.clear_active_formatting_elements if parser.pop_until(TABLE_SCOPE, Tags::Td, Tags::Th)
          parser.insertion_mode = InRow
          halt false
        end
      end

      def default(_)
        halt InBody.new(parser).process
      end
    end
  end
end

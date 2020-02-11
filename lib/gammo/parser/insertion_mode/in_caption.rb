module Gammo
  class Parser
    # Section 12.2.6.4.10.
    class InCaption < InsertionMode
      def start_tag_token(token)
        case token.tag
        when Tags::Caption, Tags::Col, Tags::Colgroup, Tags::Tbody, Tags::Td, Tags::Tfoot, Tags::Thead, Tags::Tr
          # ignore the token
          halt true unless parser.pop_until(TABLE_SCOPE, Tags::Caption)
          parser.clear_active_formatting_elements
          parser.insertion_mode = InTable
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
        when Tags::Caption
          if parser.pop_until(TABLE_SCOPE, Tags::Caption)
            parser.clear_active_formatting_elements
            parser.insertion_mode = InTable
          end
          halt true
        when Tags::Table
          # ignore the token
          halt true unless parser.pop_until(TABLE_SCOPE, Tags::Caption)
          parser.clear_active_formatting_elements
          parser.insertion_mode = InTable
          halt false
        when Tags::Body, Tags::Col, Tags::Colgroup, Tags::Html, Tags::Tbody, Tags::Td, Tags::Tfoot, Tags::Th, Tags::Thead, Tags::Tr
          # ignore the token
          halt true
        end
      end

      def default(_)
        halt InBody.new(parser).process
      end
    end
  end
end

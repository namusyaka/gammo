module Gammo
  class Parser
    # Section 12.2.6.4.17.
    class InSelectInTable < InsertionMode
      def start_tag_token(token)
        case token.tag
        when Tags::Caption, Tags::Table, Tags::Tbody, Tags::Tfoot, Tags::Thead, Tags::Tr, Tags::Td, Tags::Th
          if token.instance_of?(Tokenizer::EndTagToken) && parser.element_in_scope?(TABLE_SCOPE, token.tag)
            # ignore the token
            halt true
          end
          parser.open_elements.reverse_each_with_index do |elm, i|
            if elm.tag == Tags::Select
              parser.open_elements = parser.open_elements.slice(0, i)
              break
            end
          end
          parser.reset_insertion_mode
          halt false
        end
      end

      def end_tag_token(token)
        case token.tag
        when Tags::Caption, Tags::Table, Tags::Tbody, Tags::Tfoot, Tags::Thead, Tags::Tr, Tags::Td, Tags::Th
          if token.instance_of?(Tokenizer::EndTagToken) && !parser.element_in_scope?(TABLE_SCOPE, token.tag)
            # ignore the token
            halt true
          end
          parser.open_elements.reverse_each_with_index do |elm, i|
            if elm.tag == Tags::Select
              parser.open_elements = parser.open_elements.slice(0, i)
              break
            end
          end
          parser.reset_insertion_mode
          halt false
        end
      end

      def default(_)
        halt InSelect.new(parser).process
      end
    end
  end
end

module Gammo
  class Parser
    # Section 12.2.6.4.16.
    class InSelect < InsertionMode
      def character_token(token)
        parser.add_text token.data.gsub("\x00",'')
      end

      def start_tag_token(token)
        case token.tag
        when Tags::Html
          halt InBody.new(parser).process
        when Tags::Option
          parser.open_elements.pop if parser.top.tag == Tags::Option
          parser.add_element
        when Tags::Optgroup
          parser.open_elements.pop if parser.top.tag == Tags::Option
          parser.open_elements.pop if parser.top.tag == Tags::Optgroup
          parser.add_element
        when Tags::Select
          # ignore the token
          halt true unless parser.pop_until(SELECT_SCOPE, Tags::Select)
          parser.reset_insertion_mode
        when Tags::Input, Tags::Keygen, Tags::Textarea
          if parser.element_in_scope?(SELECT_SCOPE, Tags::Select)
            parser.parse_implied_token(Tokenizer::EndTagToken, Tags::Select, Tags::Select.to_s)
            halt false
          end
          parser.tokenizer.next_is_not_raw_text!
          # ignore the token
          halt true
        when Tags::Script, Tags::Template
          halt InHead.new(parser).process
        end
      end

      def end_tag_token(token)
        case token.tag
        when Tags::Option
          parser.open_elements.pop if parser.top.tag == Tags::Option
          nil
        when Tags::Optgroup
          i = parser.open_elements.length - 1
          i -= 1 if parser.open_elements[i].tag == Tags::Option
          if parser.open_elements[i].tag == Tags::Optgroup
            parser.open_elements = parser.open_elements.slice(0, i)
          end
          nil
        when Tags::Select
          # ignore the token
          halt true unless parser.pop_until(SELECT_SCOPE, Tags::Select)
          parser.reset_insertion_mode
          nil
        when Tags::Template
          halt InHead.new(parser).process
        end
      end

      def comment_token(token)
        parser.add_child(Node::Comment.new(data: token.data))
      end

      def doctype_token(_)
        # ignore the token.
        halt true
      end

      def error_token(_)
        halt InBody.new(parser).process
      end

      def default(_)
        halt true
      end
    end
  end
end

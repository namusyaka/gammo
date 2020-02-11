module Gammo
  class Parser
    # Section 12.2.6.4.3
    class BeforeHead < InsertionMode
      def text_token(token)
        token.data = token.data.lstrip
        halt true if token.data.length.zero?
      end

      def start_tag_token(token)
        case token.tag
        when Tags::Head
          parser.add_element
          parser.head = parser.top
          parser.insertion_mode = InHead
          halt true
        when Tags::Html
          halt InBody.new(parser).process
        end
      end

      def end_tag_token(token)
        case token.tag
        when Tags::Head, Tags::Body, Tags::Html, Tags::Br
          parser.parse_implied_token Tokenizer::StartTagToken, Tags::Head, Tags::Head.to_s
          halt false
        else
          # ignore the token.
          halt true
        end
      end

      def comment_token(token)
        parser.add_child(Node::Comment.new(data: token.data))
        halt true
      end

      def doctype_token(token)
        # ignore the token.
        halt true
      end

      def default(_)
        parser.parse_implied_token Tokenizer::StartTagToken, Tags::Head, Tags::Head.to_s
        halt false
      end
    end
  end
end
